# Downloads dill files from CIPD for each supported ABI version.

import subprocess
import sys
import utils


def main():
  abi_version = int(utils.GetAbiVersion())
  oldest_abi_version = int(utils.GetOldestSupportedAbiVersion())
  for i in xrange(oldest_abi_version, abi_version):
    cmd = ['cipd', 'install', 'dart/abiversions/%d' % i, 'latest']
    result = subprocess.call(cmd)
    if result != 0:
      return 1
  return 0


if __name__ == '__main__':
  sys.exit(main())
