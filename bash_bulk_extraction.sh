​
# final draft
#!/bin/bash

# =================================================================
# SCRIPT: bash_bulk_extractor.sh
# DESCRIPTION: A lightweight forensic triage script using standard
#              linux utils to mimic bulk extraction.
# ARTIFACTS: Emails, Password patterns, Browser URLs, Login History
# =================================================================

# --- CONFIGURATION ---

# 1. TARGET DIRECTORY
# [USER CONFIG]: This defaults to "/home" if you don't provide an argument.
# If scanning a mounted drive (e.g., /media/usb/evidence), input that path when running the script.
# Example usage: sudo ./bash_bulk_extractor.sh /media/usb/evidence
TARGET_DIR="${1:-/home}"

# 2. OUTPUT DIRECTORY
# [USER CONFIG]: Currently set to create a folder in the directory where you run the script.
# Example: OUTPUT_DIR="/media/my_external_usb/evidence_collection_$TIMESTAMP"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="./evidence_collection_$TIMESTAMP"

# Log file for errors
ERROR_LOG="$OUTPUT_DIR/extraction_errors.log"

# --- PRE-FLIGHT CHECKS ---
if [[ $EUID -ne 0 ]]; then
   echo "[-] This script must be run as root to access all artifacts."
   exit 1
fi

# Check if target exists
if [ ! -d "$TARGET_DIR" ] && [ ! -f "$TARGET_DIR" ]; then
    echo "[-] Error: Target '$TARGET_DIR' does not exist."
    echo "    [NOTE] Please verify the path to your mounted image or target folder."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
echo "[*] Starting Forensic Extraction at $TIMESTAMP"
echo "[*] Scanning Target: $TARGET_DIR"
echo "[*] Evidence will be saved to: $OUTPUT_DIR"

# =================================================================
# MODULE 1: BULK EXTRACTOR MIMIC (Pattern Matching)
# =================================================================

echo "[*] Module 1: Scanning for Planted Credentials..."

# 1. EMAIL EXTRACTION
# [USER CONFIG]: If you are looking for specific planted files (e.g. only .txt files),
# you can add "--include=*.txt" to the grep command below.
echo "    > Scanning for Email patterns..."
grep -r -a -b -o -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}" "$TARGET_DIR" \
    > "$OUTPUT_DIR/bulk_emails.txt" 2>> "$ERROR_LOG"

# 2. PASSWORD PATTERN EXTRACTION

echo "    > Scanning for Password keywords..."
grep -r -a -b -i -E "(password|passwd|secret|credentials)[[:space:]]*[:=][[:space:]]*" "$TARGET_DIR" \
    > "$OUTPUT_DIR/bulk_passwords.txt" 2>> "$ERROR_LOG"

# =================================================================
# MODULE 2: USER ACTIVITY (Logs & History)
# =================================================================

echo "[*] Module 2: Collecting User Activity..."

# 3. LOGIN HISTORY
# [USER CONFIG]: The script tries to find logs inside your TARGET_DIR first (for mounted images).
# If not found, it defaults to the live system logs (/var/log).


# Define potential log paths based on target
TARGET_WTMP="$TARGET_DIR/var/log/wtmp"
TARGET_BTMP="$TARGET_DIR/var/log/btmp"

echo "    > Extracting Login History..."

# Check for wtmp (Success logs)
if [ -f "$TARGET_WTMP" ]; then
    echo "      [+] Found wtmp in target: $TARGET_WTMP"
    last -f "$TARGET_WTMP" > "$OUTPUT_DIR/system_login_history.txt" 2>> "$ERROR_LOG"
elif [ -f /var/log/wtmp ]; then
    echo "      [!] Target wtmp not found, using host system /var/log/wtmp"
    last -f /var/log/wtmp > "$OUTPUT_DIR/system_login_history.txt" 2>> "$ERROR_LOG"
else
    echo "      [-] No wtmp log found." >> "$ERROR_LOG"
fi

# Check for btmp (Failed logs)
if [ -f "$TARGET_BTMP" ]; then
    echo "      [+] Found btmp in target: $TARGET_BTMP"
    lastb -f "$TARGET_BTMP" > "$OUTPUT_DIR/system_failed_logins.txt" 2>> "$ERROR_LOG"
elif [ -f /var/log/btmp ]; then
    echo "      [!] Target btmp not found, using host system /var/log/btmp"
    lastb -f /var/log/btmp > "$OUTPUT_DIR/system_failed_logins.txt" 2>> "$ERROR_LOG"
fi

# 4. BASH HISTORY
echo "    > Aggregating Bash History in target..."
# [USER CONFIG]: If looking for history files other than .bash_history (like .zsh_history),
find "$TARGET_DIR" -name ".bash_history" -exec grep -H "" {} \; \
    > "$OUTPUT_DIR/aggregate_bash_history.txt" 2>> "$ERROR_LOG"

# =================================================================
# MODULE 3: BROWSER ARTIFACTS (Strings extraction)
# =================================================================

echo "[*] Module 3: Scraping Browser Data..."

# 5. BROWSER URLS
echo "    > Carving URLs from Browser History files in target..."

# [USER CONFIG]: This looks for standard "History" (Chrome) and "places.sqlite" (Firefox) files.
# If your planted browser data is named differently (e.g. "backup_history.db"), add "-o -name 'backup_name'" below.
find "$TARGET_DIR" -type f \( -name "History" -o -name "places.sqlite" \) -print0 | while IFS= read -r -d '' file; do
    echo "Processing: $file" >> "$OUTPUT_DIR/browser_processing_log.txt"
    strings "$file" | grep -E "https?://[a-zA-Z0-9./?=_-]+" >> "$OUTPUT_DIR/carved_urls.txt"
done 2>> "$ERROR_LOG"

# =================================================================
# MODULE 4: INTEGRITY & CLEANUP
# =================================================================

echo "[*] Module 4: Finalizing and Hashing..."

# Create a report of what was done
cat <<EOF > "$OUTPUT_DIR/report_summary.txt"
FORENSIC EXTRACTION REPORT
==========================
Date: $(date)
Hostname: $(hostname)
Target Scanned: $TARGET_DIR
==========================
FILES COLLECTED:
EOF

ls -lh "$OUTPUT_DIR" >> "$OUTPUT_DIR/report_summary.txt"

# Calculate Hashes for integrity
echo "[*] Calculating SHA256 hashes of output files..."
cd "$OUTPUT_DIR" || exit
sha256sum * > SHA256SUMS.txt

echo "[+] Extraction Complete."
echo "[+] Verify hashes: sha256sum -c SHA256SUMS.txt"
