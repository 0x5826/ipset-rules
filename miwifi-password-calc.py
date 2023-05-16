#!/usr/bin/env python3

from hashlib import md5
from sys import argv, exit

salt = {
    'r1d': 'A2E371B0-B34B-48A5-8C40-A7133F3B5D88',
    'others': '6d2df50a-250f-4a30-a5e6-d44fb0960aa0',
}


def get_salt(sn):
    if "/" not in sn:
        return salt["r1d"]
    else:
        return salt["others"]


def calc_passwd(sn):
    passwd = sn + get_salt(sn)
    m = md5(passwd.encode())
    return m.hexdigest()[:8]


if __name__ == "__main__":
    if len(argv) < 2:
        print("Usage: calc.py <SN>")
        exit(-1)
    sn = argv[1]
    password = calc_passwd(sn)
    print(f'{password}')