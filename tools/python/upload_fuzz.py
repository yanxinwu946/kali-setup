#!/usr/bin/env python3
import os
import argparse
import sys
from typing import List, Dict

# File extensions organized by language type
EXTENSIONS: Dict[str, List[str]] = {
    "php": [".php", ".php2", ".php3", ".php4", ".php5", ".php6", ".php7", ".phps", 
            ".pht", ".phtm", ".phtml", ".pgif", ".shtml", ".htaccess", ".phar", ".inc"],
    "asp": [".asp", ".aspx", ".config", ".ashx", ".asmx", ".aspq", ".axd", ".cshtm", 
            ".cshtml", ".rem", ".soap", ".vbhtm", ".vbhtml", ".asa", ".cer", ".shtml"],
    "jsp": [".jsp", ".jspx", ".jsw", ".jsv", ".jspf", ".wss", ".do", ".action"],
    "coldfusion": [".cfm", ".cfml", ".cfc", ".dbm"],
    "flash": [".swf"],
    "perl": [".pl", ".cgi"],
    "yaws": [".yaws"],
}

# Common image and text extensions
COMMON_EXTENSIONS = [
    # Image formats
    ".jpg", ".png", ".gif",
    # Text format
    ".txt"
]

DEFAULT_PAYLOAD = "FUZZ TEST"

def generate_fuzz_files(langs: List[str], output_dir: str = "fuzz_files", 
                      payload: str = DEFAULT_PAYLOAD, case_variations: bool = False) -> None:
    """Generate fuzzing files for testing file upload vulnerabilities."""
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    created_count = 0
    
    # Process each language
    for lang in langs:
        lang = lang.lower()
        if lang not in EXTENSIONS:
            print(f"[!] Unsupported language: {lang}")
            continue
        
        # Generate files for language extensions
        for ext in EXTENSIONS[lang]:
            filename = f"fuzz{ext}"
            filepath = os.path.join(output_dir, filename)
            
            try:
                with open(filepath, "w") as f:
                    f.write(payload)
                print(f"[+] Created: {filepath}")
                created_count += 1
            except Exception as e:
                print(f"[-] Failed to create {filepath}: {e}")
            
            # Generate uppercase variant if requested
            if case_variations:
                upper_ext = ext.upper()
                if upper_ext != ext:  # Only if actually different
                    upper_filepath = os.path.join(output_dir, f"fuzz{upper_ext}")
                    try:
                        with open(upper_filepath, "w") as f:
                            f.write(payload)
                        print(f"[+] Created: {upper_filepath}")
                        created_count += 1
                    except Exception as e:
                        print(f"[-] Failed to create {upper_filepath}: {e}")
    
    # Add common image and text extensions
    for ext in COMMON_EXTENSIONS:
        filename = f"fuzz{ext}"
        filepath = os.path.join(output_dir, filename)
        
        try:
            with open(filepath, "w") as f:
                f.write(payload)
            print(f"[+] Created: {filepath}")
            created_count += 1
        except Exception as e:
            print(f"[-] Failed to create {filepath}: {e}")
    
    print(f"[*] Total files created: {created_count}")

def main() -> None:
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(description="File upload fuzzing extension generator")
    
    parser.add_argument('-l', '--langs', nargs='+', required=True, 
                       help='Language types to include (e.g., php asp jsp)')
    parser.add_argument('-o', '--output', default='fuzz_files', 
                       help='Output directory for generated files')
    parser.add_argument('-p', '--payload', default=DEFAULT_PAYLOAD,
                       help='Custom payload to include in the generated files')
    parser.add_argument('-c', '--case-variations', action='store_true',
                       help='Generate case variations of extensions (e.g., .PHP, .PhP)')
    parser.add_argument('-a', '--all', action='store_true',
                       help='Generate files for all supported languages')
    
    args = parser.parse_args()
    
    # Use all languages if requested
    if args.all:
        langs = list(EXTENSIONS.keys())
    else:
        langs = args.langs
    
    print(f"[*] Generating fuzz files for: {', '.join(langs)}")
    print(f"[*] Also generating common extensions: {', '.join(COMMON_EXTENSIONS)}")
    
    # Generate the files
    generate_fuzz_files(langs, args.output, args.payload, args.case_variations)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[!] Process interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"[!] Error: {e}")
        sys.exit(1)