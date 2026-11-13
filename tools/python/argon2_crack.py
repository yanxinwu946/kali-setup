#!/usr/bin/env python3
import os
import time
import argparse
import sys
import mmap
from pathlib import Path
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from tqdm import tqdm
from concurrent.futures import ProcessPoolExecutor, as_completed

PH = PasswordHasher()

def verify_password(args):
    """单个进程验证密码"""
    hash_value, word = args
    try:
        PH.verify(hash_value, word)
        return word
    except VerifyMismatchError:
        return None

def mmap_wordlist(path):
    """使用 mmap 流式读取大字典"""
    with open(path, 'r', encoding='latin-1', errors='ignore') as f:
        # 映射整个文件（只读）
        with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
            for line in iter(mm.readline, b''):
                yield line.decode('latin-1', errors='ignore').strip()

class FastArgon2Cracker:
    def __init__(self, hash_value, wordlist_path, threads=None):
        self.hash = hash_value
        self.wordlist_path = wordlist_path
        self.threads = threads or min(os.cpu_count(), 16)
        self.found = None

    def crack(self):
        start_time = time.time()
        total_words = sum(1 for _ in open(self.wordlist_path, 'rb'))  # 快速统计行数
        print(f"[+] Target: {self.hash[:60]}...")
        print(f"[+] Wordlist: {Path(self.wordlist_path).name} ({total_words:,} words)")
        print(f"[+] Processes: {self.threads}")

        pbar = tqdm(total=total_words, desc="[*] Cracking", unit=" pwd", mininterval=0.5)

        with ProcessPoolExecutor(max_workers=self.threads) as executor:
            futures = {}
            for word in mmap_wordlist(self.wordlist_path):
                if not word:
                    pbar.update(1)
                    continue
                future = executor.submit(verify_password, (self.hash, word))
                futures[future] = word

                # 处理已完成的任务
                done = [f for f in futures if f.done()]
                for f in done:
                    pbar.update(1)
                    result = f.result()
                    del futures[f]
                    if result:
                        pbar.close()
                        elapsed = time.time() - start_time
                        print(f"\n[+] SUCCESS!")
                        print(f"[+] Password: {result}")
                        print(f"[+] Time: {elapsed:.1f}s")
                        executor.shutdown(cancel_futures=True)
                        self.found = result
                        return result

            pbar.close()
            elapsed = time.time() - start_time
            print(f"\n[-] Password not found")
            print(f"[+] Time: {elapsed:.1f}s")
            return None

def find_wordlist():
    paths = [
        '/usr/share/wordlists/rockyou.txt',
        '/usr/share/wordlists/fasttrack.txt',
        './rockyou.txt'
    ]
    for path in paths:
        if Path(path).exists():
            return path
    return None

def main():
    parser = argparse.ArgumentParser(description="Fast Argon2 Hash Cracker (large dict optimized)")
    parser.add_argument('-c', '--crack', required=True, help='Argon2 hash to crack')
    parser.add_argument('-w', '--wordlist', help='Wordlist file')
    parser.add_argument('-t', '--threads', type=int, help='Number of processes')
    args = parser.parse_args()

    if not args.crack.startswith('$argon2'):
        print("[-] Invalid Argon2 hash format")
        sys.exit(1)

    wordlist = args.wordlist or find_wordlist()
    if not wordlist or not Path(wordlist).exists():
        print("[-] No wordlist found")
        print("[!] Use: -w /path/to/wordlist.txt")
        sys.exit(1)

    cracker = FastArgon2Cracker(args.crack, wordlist, args.threads)
    cracker.crack()

if __name__ == '__main__':
    main()
