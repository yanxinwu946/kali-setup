#!/usr/bin/env python3
import re
import sys

def parse_smb_output(file_path):
    # Default exclusions
    default_users = {'Administrator', 'Guest', 'krbtgt'}
    default_groups = {
        # Core Active Directory groups
        'Domain Admins', 'Domain Users', 'Domain Guests', 'Domain Computers',
        'Domain Controllers', 'Enterprise Admins', 'Schema Admins',
        'Group Policy Creator Owners', 'Read-only Domain Controllers',
        # Common built-in groups
        'Administrators', 'Users', 'Guests', 'Print Operators', 'Backup Operators',
        'Replicator', 'Remote Desktop Users', 'Network Configuration Operators',
        'Account Operators', 'Server Operators', 'Pre-Windows 2000 Compatible Access',
        # Security and privilege groups
        'Cert Publishers', 'RAS and IAS Servers', 'Allowed RODC Password Replication Group',
        'Denied RODC Password Replication Group', 'Enterprise Read-only Domain Controllers',
        # Distribution and other common groups
        'DnsAdmins', 'DnsUpdateProxy', 'IIS_IUSRS'
    }

    # Regex patterns
    patterns = {
        'user': re.compile(r'\d+: [^\s\\]+\\([^\\]+)\s+\(SidTypeUser\)'),
        'group': re.compile(r'\d+: [^\s\\]+\\([^\$]+?)\s+\(SidType(Group|Alias)\)')
    }

    regular_users, computer_users, groups = [], [], []

    # Parse file
    with open(file_path) as file:
        for line in file:
            if match := patterns['user'].search(line):
                user = match.group(1)
                if user not in default_users:
                    if user.endswith('$'):
                        computer_users.append(user)
                    else:
                        regular_users.append(user)
            elif match := patterns['group'].search(line):
                if match.group(1) not in default_groups:
                    groups.append(match.group(1))

    # Output results
    print("[+]Regular Users:", *regular_users, sep='\n')
    print("\n[+]Computer Users:", *computer_users, sep='\n')
    print("\n[+]Groups:", *groups, sep='\n')

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <input_file>")
        sys.exit(1)
    parse_smb_output(sys.argv[1])