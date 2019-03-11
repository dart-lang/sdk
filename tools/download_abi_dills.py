# Downloads dill files from CIPD for each supported ABI version.

import os
import subprocess
import sys
import utils


def main():
  abi_version = int(utils.GetAbiVersion())
  oldest_abi_version = int(utils.GetOldestSupportedAbiVersion())
  cmd = ['cipd', 'ensure', '-root', 'tools/abiversions', '-ensure-file', '-']
  ensure_file = ''
  for i in xrange(oldest_abi_version, abi_version):
    ensure_file += '@Subdir %d\ndart/abiversions/%d latest\n\n' % (i, i)
  p = subprocess.Popen(cmd,
                       stdin = subprocess.PIPE,
                       shell = utils.IsWindows(),
                       cwd = utils.DART_DIR)
  p.communicate(ensure_file)
  p.stdin.close()
  return p.wait()


if __name__ == '__main__':
  sys.exit(main())
