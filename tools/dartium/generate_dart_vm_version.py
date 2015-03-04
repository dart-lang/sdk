import datetime
import imp
import os
import subprocess
import sys
import time

scriptpath = os.path.abspath(os.path.dirname(__file__))
utils = imp.load_source('utils', os.path.join(scriptpath, '..', 'utils.py'))

REVISION_FILE = 'src/chrome/browser/ui/webui/dartvm_revision.h'
EXPIRATION_FILE = 'src/third_party/WebKit/Source/bindings/dart/ExpirationTimeSecsSinceEpoch.time_t'

def updateFile(filename, content):
  if os.path.exists(filename):
    if file(filename, 'r').read() == content:
      return
  else:
    dir = os.path.dirname(filename)
    if not os.path.exists(dir):
      os.makedirs(dir)
  file(filename, 'w').write(content)

def main():
  dart_version = utils.GetVersion()
  version_string = '#define DART_VM_REVISION "%s"\n' % dart_version.strip()

  updateFile(REVISION_FILE, version_string)

  expiration_date = datetime.date.today() + datetime.timedelta(days=365)
  updateFile(EXPIRATION_FILE,
             "%dLL\n" % time.mktime(expiration_date.timetuple()))

if __name__ == '__main__':
  main()
