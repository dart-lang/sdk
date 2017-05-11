# Upgrading Dart's SDK for HTML (blink IDLs).
#
# Typically this is done using the Dart integration branch (as it has to be
# staged to get most things working).
#
# Enlist in third_party/WebCore:
#      > cd src/dart/third_party
#      > rm -rf WebCore    (NOTE: Normally detached head using gclient sync)
#      > git clone https://github.com/dart-lang/webcore.git WebCore
#
# To update all *.idl, *.py, LICENSE files, and IDLExtendedAttributes.txt:
#      > cd src/dart
#      > python tools/dom/scripts/idlsync.py
#
# Display blink files to delete, copy, update, and collisions to review:
#      > python tools/dom/scripts/idlsync.py --check
#
# Bring over all blink files to dart/third_party/WebCore (*.py, *.idl, and
# IDLExtendedAttributes.txt):
#      > python tools/dom/scripts/idlsync.py
#
# Update the DEPS file SHA for "WebCore_rev" with the committed changes of files
# in WebCore e.g.,   "WebCore_rev": "@NNNNNNNNNNNNNNNNNNNNNNNNN"
#
# Generate the sdk/*.dart files from the new IDLs and PYTHON IDL parsing code
# copied to in dart/third_party/WebCore from src/third_party/WebKit (blink).
#
#      > cd src/dart/tools/dom/script
#      > ./go.sh
#
# Finally, commit the files in dart/third_party/WebCore.

import optparse
import os.path
import re
import requests
import subprocess
import sys
import time

from shutil import copyfile

# Dartium DEPS file from the DEPS file checked into the dart-lang/sdk integration
# branch.
DEPS_GIT = ('https://raw.githubusercontent.com/dart-lang/sdk/integration/'
            'tools/deps/dartium.deps/DEPS')
CHROME_TRUNK = "https://chromium.googlesource.com"
WEBKIT_URL_PATTERN = r'"dartium_chromium_commit": "(\S+)",'
DEPS_PATTERNS = {
    'webkit': (CHROME_TRUNK, WEBKIT_URL_PATTERN),
}

# Dartium/Chromium remote (GIT repository)
GIT_REMOTES_CHROMIUM = 'https://chromium.googlesource.com/dart/dartium/src.git'

# location of this file
SOURCE_FILE_DIR = 'src/dart/tools/dom/scripts'

WEBKIT_SOURCE = 'src/third_party/WebKit/Source'
WEBCORE_SOURCE = 'src/dart/third_party/WebCore'

# Never automatically git add bindings/IDLExtendedAttributes.txt this file has
# been modified by Dart but is usually changed by WebKit blink too.
IDL_EXTENDED_ATTRIBUTES_FILE = 'IDLExtendedAttributes.txt'

# Don't automatically update, delete or add anything in this directory:
#      bindings/dart/scripts
# The scripts in the above directory is the source for our Dart generators that
# is driven from the blink IDL parser AST
DART_SDK_GENERATOR_SCRIPTS = 'bindings/dart/scripts'

# sub directories containing IDLs (core and modules) from the base directory
# src/third_party/WebKit/Source
SUBDIRS = [
    'bindings',
    'core',
    'modules',
]
IDL_EXT = '.idl'
PY_EXT = '.py'
LICENSE_FILE_PREFIX = 'LICENSE'    # e.g., LICENSE-APPLE, etc.

# Look in any file in WebCore we copy from WebKit if this comment is in the file
# then flag this as a special .py or .idl file that needs to be looked at.
DART_CHANGES = ' FIXMEDART: '

# application options passed in.
options = None

warning_messages = []

# Is --check passed in.
def isChecked():
  global options
  return options['check'] is not None

# Is --verbose passed in.
def isVerbose():
  global options
  return options['verbose'] is not None

def RunCommand(cmd, valid_exits=[0]):
  """Executes a shell command and return its stdout."""
  if isVerbose():
    print ' '.join(cmd)
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output = pipe.communicate()
  if pipe.returncode in valid_exits:
    return output[0]
  else:
    print output[1]
    print 'FAILED. RET_CODE=%d' % pipe.returncode
    sys.exit(pipe.returncode)

# returns True if // FIXMEDART: is in the file.
def anyDartFixMe(filepath):
  if os.path.exists(filepath):
    data = open(filepath, 'r').read()
    return data.find(DART_CHANGES) != -1
  else:
    return False

# Give a base_dir compute the trailing directory after base_dir
# returns the subpath from base_dir for the path passed in.
def subpath(path, base_dir):
  dir_portion = ''
  head = path
  while True:
    head, tail = os.path.split(head)
    dir_portion = os.path.join(tail, dir_portion)
    if head == base_dir or tail == '':
      break;
  return dir_portion

# Copy any file in source_dir (WebKit) to destination_dir (dart/third_party/WebCore)
# source_dir is the src/third_party/WebKit/Source location (blink)
# destination_dir is the src/dart/third_party/WebCore location
# returns idls_copied, py_copied, other_copied
def copy_files(source_dir, destination_dir):
  original_cwd = os.getcwd()
  os.chdir(destination_dir)

  idls = 0                  # *.idl files copied
  pys = 0                   # *.py files copied
  others = 0                # all other files copied

  for (root, _, files) in os.walk(source_dir, topdown=False):
    dir_portion = subpath(root, source_dir)
    for f in files:
      # Never automatically add any Dart generator scripts (these are the original
      # sources in WebCore) from WebKit to WebCore.
      if dir_portion != DART_SDK_GENERATOR_SCRIPTS:
        if (f.endswith(IDL_EXT) or
            f == IDL_EXTENDED_ATTRIBUTES_FILE or
            f.endswith(PY_EXT) or
            f.startswith(LICENSE_FILE_PREFIX)):
          if f.endswith(IDL_EXT):
            idls += 1
          elif f.endswith(PY_EXT):
            pys += 1
          else:
            others += 1
          src_file = os.path.join(root, f)
          dst_root = root.replace(WEBKIT_SOURCE, WEBCORE_SOURCE)
          dst_file = os.path.join(dst_root, f)

          destination = os.path.dirname(dst_file)
          if not os.path.exists(destination):
            os.makedirs(destination)

          has_Dart_fix_me = anyDartFixMe(dst_file)

          if not isChecked():
            copyfile(src_file, dst_file)
          if isVerbose():
            print('...copying %s' % os.path.split(dst_file)[1])
          if f == IDL_EXTENDED_ATTRIBUTES_FILE:
            warning_messages.append(dst_file)
          else:
            if has_Dart_fix_me:
              warning_messages.append(dst_file)
            if not (isChecked() or has_Dart_fix_me):
              # git add the file
              RunCommand(['git', 'add', dst_file])

  os.chdir(original_cwd)

  return [idls, pys, others]

# Remove any file in webcore_dir that no longer exist in the webkit_dir
# webcore_dir src/dart/third_party/WebCore location
# webkit_dir src/third_party/WebKit/Source location (blink)
# only check if the subdir off from webcore_dir
# return list of files deleted
def remove_obsolete_webcore_files(webcore_dir, webkit_dir, subdir):
  files_to_delete = []

  original_cwd = os.getcwd()
  os.chdir(webcore_dir)

  for (root, _, files) in os.walk(os.path.join(webcore_dir, subdir), topdown=False):
    dir_portion = subpath(root, webcore_dir)
    for f in files:
      # Never automatically deleted any Dart generator scripts (these are the
      # original sources in WebCore).
      if dir_portion != DART_SDK_GENERATOR_SCRIPTS:
        check_file = os.path.join(dir_portion, f)
        check_file_full_path = os.path.join(webkit_dir, check_file)
        if not os.path.exists(check_file_full_path):
          if not isChecked():
            # Remove the file using git
            RunCommand(['git', 'rm', check_file])
          files_to_delete.append(check_file)

  os.chdir(original_cwd)

  return files_to_delete

def ParseOptions():
  parser = optparse.OptionParser()
  parser.add_option('--verbose', '-v', dest='verbose', action='store_false',
                    help='Dump all information', default=None)
  parser.add_option('--check', '-c', dest='check', action='store_false',
                    help='Display results without adding, updating or deleting any files', default=None)
  args, _ = parser.parse_args()

  argOptions = {}
  argOptions['verbose'] = args.verbose
  argOptions['check'] = args.check
  return argOptions

# Fetch the DEPS file in src/dart/tools/deps/dartium.deps/DEPS from the GIT repro.
def GetDepsFromGit():
  req = requests.get(DEPS_GIT)
  return req.text

def ValidateGitRemotes():
  #origin  https://chromium.googlesource.com/dart/dartium/src.git (fetch)
  remotes_list = RunCommand(['git', 'remote', '--verbose']).split()
  if (len(remotes_list) > 2 and
      remotes_list[0] == 'origin' and remotes_list[1] == GIT_REMOTES_CHROMIUM):
    return True

  print 'ERROR: Unable to find dart/dartium/src repository %s' % GIT_REMOTES_CHROMIUM
  return False

def getCurrentDartiumSHA():
  cwd = os.getcwd()
  if cwd.endswith('dart'):
    # In src/dart 
    src_dir, _ = os.path.split(cwd)
  elif cwd.endswith('src'):
    src_dir = cwd
  else:
    src_dir = os.path.join(cwd, 'src')
  os.chdir(src_dir)

  if ValidateGitRemotes():
    dartium_sha = RunCommand(['git', 'log', '--format=format:%H', '-1'])
  else:
    dartium_sha = -1

  os.chdir(cwd)
  return dartium_sha

# Returns the SHA of the Dartium/Chromiun in the DEPS file.
def GetDEPSDartiumGitRevision(deps, component):
  """Returns a tuple with the (dartium chromium repo, latest revision)."""
  url_base, url_pattern = DEPS_PATTERNS[component]
  url = url_base + re.search(url_pattern, deps).group(1)
  # Get the SHA for the Chromium/WebKit changes for Dartium.
  revision = url[len(url_base):]
  return revision

def main():
  global options
  options = ParseOptions()

  current_dir = os.path.dirname(os.path.abspath(__file__))
  if not current_dir.endswith(SOURCE_FILE_DIR):
    print 'ERROR: idlsync.py not run in proper directory (%s)\n', current_dir

  base_directory = current_dir[:current_dir.rfind(SOURCE_FILE_DIR)]

  # Validate that the DEPS SHA matches the SHA of the chromium/dartium branch.
  deps = GetDepsFromGit()
  revision = GetDEPSDartiumGitRevision(deps, 'webkit')
  dartium_sha = getCurrentDartiumSHA()
  if not(revision == dartium_sha):
    print "ERROR: Chromium/Dartium SHA in DEPS doesn't match the GIT branch."
    return

  start_time = time.time()
  for subdir in SUBDIRS:
    webkit_dir = os.path.join(base_directory, WEBKIT_SOURCE) 
    webcore_dir = os.path.join(base_directory, WEBCORE_SOURCE)

    idls_deleted = remove_obsolete_webcore_files(webcore_dir, webkit_dir, subdir)
    print "%s files removed in WebCore %s" % (idls_deleted.__len__(), subdir)
    if isVerbose():
      for delete_file in idls_deleted:
        print "    %s" % delete_file

    idls_copied, py_copied, other_copied = copy_files(os.path.join(webkit_dir, subdir), webcore_dir)
    print "Copied %s IDLs to %s" % (idls_copied, subdir)
    print "Copied %s PYs to %s" % (py_copied, subdir)
    print "Copied %s other to %s\n" % (other_copied, subdir)

  end_time = time.time()

  print 'WARNING: File(s) contain FIXMEDART and are NOT "git add " please review:'
  for warning in warning_messages:
    print '    %s' % warning

  print '\nDone idlsync completed in %s seconds' % round(end_time - start_time, 2)

if __name__ == '__main__':
  sys.exit(main())
