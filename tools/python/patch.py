#!/usr/bin/env python3

import sys
import struct
import argparse

def main():
    """
    A command-line tool to calculate the 32-bit relative offset for a call instruction.
    """
    # 1. Set up the argument parser
    parser = argparse.ArgumentParser(
        description='Calculates the 32-bit relative offset for a CALL instruction.',
        formatter_class=argparse.RawTextHelpFormatter
    )

    # 2. Add arguments for the target and current addresses
    parser.add_argument(
        'target_address',
        help='The hexadecimal address of the target function (e.g., 0x1473).'
    )
    parser.add_argument(
        'current_address',
        help='The hexadecimal address of the current CALL instruction (e.g., 0x160d).'
    )

    # 3. Parse the arguments
    args = parser.parse_args()
    
    try:
        # 4. Convert hexadecimal string inputs to integers
        target_addr = int(args.target_address, 16)
        current_addr = int(args.current_address, 16)
        
        # 5. Calculate the next instruction's address
        # A CALL rel32 instruction is 5 bytes long.
        next_addr = current_addr + 5
        
        # 6. Calculate the relative offset
        # Offset = Target Address - Next Instruction Address
        offset = target_addr - next_addr
        
        # 7. Pack the offset as a 32-bit signed integer in little-endian format
        # '<i' -> little-endian (<), signed 32-bit integer (i)
        rel32_bytes = struct.pack('<i', offset)
        
        # 8. Convert the bytes to a space-separated uppercase hex string
        hex_opcode = rel32_bytes.hex().upper()
        formatted_output = ' '.join(hex_opcode[i:i+2] for i in range(0, len(hex_opcode), 2))
        
        # 9. Print the final result
        print(formatted_output)

    except ValueError:
        print("\n[ERROR] Invalid hexadecimal address provided.")
        print("Please ensure addresses start with '0x' if not a pure hex string.")
        sys.exit(1)
    except struct.error:
        print("\n[ERROR] The calculated offset is outside the range of a 32-bit integer.")
        print("Please check the provided addresses.")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nScript terminated.")
        sys.exit(0)

if __name__ == "__main__":
    main()
