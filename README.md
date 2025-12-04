Bash Bulk Extractor - Digital Forensics Tool
Created by Garrett Fraley and Marcellus Neal

> Video Demonstration
- https://youtu.be/06YVHYUW9iI

> Overview
- bash_bulk_extractor.sh is a lightweight Linux forensic triage tool designed to mimic core functionality of bulk_extractor using only standard Bash utilities.
It extracts high-value artifacts from a target directory—such as a mounted drive, a user home folder, or a forensic image—without needing any external libraries or complex installations.

- This tool was created as part of an IT 360 Digital Forensics project to demonstrate evidence triage, pattern extraction, and integrity preservation.

> Key Features
- Email extraction using recursive regex pattern matching

- Password string detection (password/passwd/secret/credentials)

- User activity collection

- Successful logins (wtmp)

- Failed logins (btmp)

- Aggregated .bash_history collection

- Browser URL carving from Chrome/Chromium (History) and Firefox (places.sqlite)

- Automatic summary report generation

- Error log containing all warnings and failures

- SHA-256 hashing for integrity verification

- Organized output in a timestamped evidence folder
> Dependencies

Install these on the machine where you will be using this script.

This tool relies only on standard Linux utilities:

- bash

- grep

- find

- strings

- last / lastb

- sha256sum

These are typically installed by default on Ubuntu and Debian-based systems.

> *instructions for install

- git clone https://github.com/Gfraley/IT360_Project.git
- cd IT360_Project
- chmod +x bash_bulk_extractor.sh
