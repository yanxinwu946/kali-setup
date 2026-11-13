#!/usr/bin/env python3
import argparse
import sys
from dataclasses import dataclass, field
from typing import Dict, TextIO, Optional

@dataclass
class User:
    """
    Dataclass to store user credentials with type hints and default values.
    """
    name: str
    domain: str = ''
    password: str = ''
    ntlm: str = ''

class MimikatzParser:
    """
    Enhanced parser for Mimikatz sekurlsa output with improved error handling and parsing."""
    
    def __init__(self):
        """Initialize users dictionary to store parsed user credentials."""
        self.users: Dict[str, User] = {}
        self._current_user: Optional[User] = None

    def parse(self, mimikatz_output: TextIO) -> None:
        """
        Parse the Mimikatz output line by line.
        
        Args:
            mimikatz_output (TextIO): File-like object containing Mimikatz output
        """
        for line in mimikatz_output:
            self._parse_line(line.strip())

    def _parse_line(self, line: str) -> None:
        """
        Parse individual lines from Mimikatz output.
        
        Args:
            line (str): A single line from the Mimikatz output
        """
        if not line or ':' not in line:
            return

        key, value = [part.strip() for part in line.split(':', 1)]
        
        # Skip null values
        if value.lower() == '(null)':
            return

        # Dispatch parsing based on key
        parsing_map = {
            '* Username': self._parse_username,
            '* Domain': self._parse_domain,
            '* NTLM': self._parse_ntlm,
            '* Password': self._parse_password
        }
        
        parse_method = parsing_map.get(key)
        if parse_method:
            parse_method(value)

    def _parse_username(self, name: str) -> None:
        """
        Parse and process username, handling domain-prefixed usernames.
        
        Args:
            name (str): Username to parse
        """
        name = name.lower()
        domain = ''
        
        if '\\' in name:
            domain, name = name.split('\\', 1)
        
        # Create user if not exists
        if name not in self.users:
            self.users[name] = User(name=name)
        
        self._current_user = self.users[name]
        
        # Set domain if provided
        if domain:
            self._current_user.domain = domain.lower()

    def _parse_domain(self, domain: str) -> None:
        """
        Parse and set domain for current user.
        
        Args:
            domain (str): Domain name
        """
        if not self._current_user:
            return
        
        # Handle potential domain\username format
        if '\\' in domain:
            domain, _ = domain.split('\\', 1)
        
        self._current_user.domain = domain.lower()

    def _parse_ntlm(self, ntlm: str) -> None:
        """
        Set NTLM hash for current user.
        
        Args:
            ntlm (str): NTLM hash
        """
        if self._current_user:
            self._current_user.ntlm = ntlm.lower()

    def _parse_password(self, password: str) -> None:
        """
        Set password for current user.
        
        Args:
            password (str): User password
        """
        if self._current_user:
            self._current_user.password = password

def parse_args() -> argparse.Namespace:
    """
    Parse command-line arguments.
    
    Returns:
        argparse.Namespace: Parsed arguments
    """
    parser = argparse.ArgumentParser(description='Mimikatz sekurlsa Output Parser')
    parser.add_argument('files', nargs='*', type=argparse.FileType('r'), 
                        default=[sys.stdin], 
                        help='Input files (default: stdin)')
    parser.add_argument('--delimiter', '-d', default=' ', 
                        help='Delimiter between output fields (default: space)')
    return parser.parse_args()

def main() -> None:
    """
    Main function to parse Mimikatz output and print credentials.
    """
    args = parse_args()
    parser = MimikatzParser()

    # Parse all input files
    for file in args.files:
        parser.parse(file)

    # Output parsed users
    for user in parser.users.values():
        print(
            f"{user.name}{args.delimiter}"
            f"{user.domain}{args.delimiter}"
            f"{user.ntlm}{args.delimiter}"
            f"{user.password}"
        )

if __name__ == '__main__':
    main()