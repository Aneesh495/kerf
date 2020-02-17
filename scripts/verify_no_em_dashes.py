#!/usr/bin/env python3
"""
Verification script to ensure no em dashes (U+2014) or en dashes (U+2013)
exist in any file within the repository.
"""

import os
import sys

FORBIDDEN_CHARS = {
    '\u2014': 'EM DASH (U+2014)',
    '\u2013': 'EN DASH (U+2013)',
}

EXCLUDED_DIRS = {
    '.git',
    'node_modules',
    'dist',
    '.system_generated',
}

def scan_file(filepath):
    errors = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            for line_idx, line in enumerate(f, 1):
                for char, name in FORBIDDEN_CHARS.items():
                    if char in line:
                        col_idx = line.index(char) + 1
                        errors.append((line_idx, col_idx, name, line.strip()))
    except Exception as e:
        # Ignore binary files or unreadable files
        pass
    return errors

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    total_violations = 0
    scanned_files = 0

    print(f"Scanning repository for forbidden dash characters: {repo_root}")

    for root, dirs, files in os.walk(repo_root):
        dirs[:] = [d for d in dirs if d not in EXCLUDED_DIRS]
        for file in sorted(files):
            # Skip binary extensions
            if file.endswith(('.png', '.jpg', '.jpeg', '.stl', '.obj', '.wasm', '.node')):
                continue
            filepath = os.path.join(root, file)
            rel_path = os.path.relpath(filepath, repo_root)
            scanned_files += 1
            violations = scan_file(filepath)
            if violations:
                print(f"\n[VIOLATION] in {rel_path}:")
                for line, col, name, text in violations:
                    print(f"  Line {line}, Col {col}: {name} -> {text[:80]}")
                total_violations += len(violations)

    print(f"\nSummary: Scanned {scanned_files} files.")
    if total_violations == 0:
        print("SUCCESS: Zero em dashes and zero en dashes detected across codebase.")
        return 0
    else:
        print(f"FAILURE: Detected {total_violations} forbidden character violations.")
        return 1

if __name__ == '__main__':
    sys.exit(main())
