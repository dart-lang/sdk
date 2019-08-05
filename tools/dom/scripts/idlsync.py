# Upgrading Dart's SDK for HTML (blink IDLs).
#
# Typically this is done using the Dart WebCore branch (as it has to be
# staged to get most things working).
#
# Enlist in third_party/WebCore:
#      > cd src/dart/third_party
#      > rm -rf WebCore    (NOTE: Normally detached head using gclient sync)
#      > git clone https://github.com/dart-lang/webcore.git WebCore
#
# To update all *.idl, *.py, LICENSE files, and IDLExtendedAttributes.txt:
#      > cd sdk
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

import errno
import optparse
import os.path
import re
import requests
import subprocess
import sys
import time

from shutil import copyfile

# Dart DEPS file checked into the dart-lang/sdk master.
DEPS_GIT = "https://raw.githubusercontent.com/dart-lang/sdk/master/DEPS"
CHROME_TRUNK = "https://chromium.googlesource.com"
WEBKIT_SHA_PATTERN = r'"WebCore_rev": "(\S+)",'

# Chromium remote (GIT repository)
GIT_REMOTES_CHROMIUM = 'https://chromium.googlesource.com/chromium/src.git'

# location of this file
SOURCE_FILE_DIR = 'tools/dom/scripts'

WEBKIT_SOURCE = 'src/third_party/WebKit/Source'
WEBCORE_SOURCE = 'third_party/WebCore'

WEBKIT_BLINK_SOURCE = 'src/third_party/blink'
WEBCORE_BLINK_SOURCE = 'third_party/WebCore/blink'

# Never automatically git add bindings/IDLExtendedAttributes.txt this file has
# been modified by Dart but is usually changed by WebKit blink too.
IDL_EXTENDED_ATTRIBUTES_FILE = 'IDLExtendedAttributes.txt'

# Don't automatically update, delete or add anything in this directory:
#      bindings/dart/scripts
# The scripts in the above directory is the source for our Dart generators that
# is driven from the blink IDL parser AST
DART_SDK_GENERATOR_SCRIPTS = 'bindings/dart/scripts'

# The __init__.py files allow Python to treat directories as packages. Used to
# allow Dart's Python scripts to interact with Chrome's IDL parsing scripts.
PYTHON_INITS = '__init__.py'

# sub directories containing IDLs (core and modules) from the base directory
# src/third_party/WebKit/Source
SUBDIRS = [
    'bindings',
    'core',
    'modules',
]
IDL_EXT = '.idl'
PY_EXT = '.py'
LICENSE_FILE_PREFIX = 'LICENSE'  # e.g., LICENSE-APPLE, etc.

# Look in any file in WebCore we copy from WebKit if this comment is in the file
# then flag this as a special .py or .idl file that needs to be looked at.
DART_CHANGES = ' FIXMEDART: '

# application options passed in.
options = None

warning_messages = []


# Is --dry_run passed in.
def isDryRun():
    global options
    return options['dry_run'] is not None


# Is --verbose passed in.
def isVerbose():
    global options
    return options['verbose'] is not None


# If --WebKit= is specified then compute the directory of the Chromium
# source.
def chromiumDirectory():
    global options
    if options['chromium_dir'] is not None:
        return os.path.expanduser(options['chromium_dir'])
    return os.cwd()


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
            break
    return dir_portion


# Copy any file in source_dir (WebKit) to destination_dir (dart/third_party/WebCore)
# source_dir is the src/third_party/WebKit/Source location (blink)
# destination_dir is the src/dart/third_party/WebCore location
# returns idls_copied, py_copied, other_copied
def copy_files(source_dir, src_prefix, destination_dir):
    original_cwd = os.getcwd()
    try:
        os.makedirs(destination_dir)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise
    os.chdir(destination_dir)

    idls = 0  # *.idl files copied
    pys = 0  # *.py files copied
    others = 0  # all other files copied

    for (root, _, files) in os.walk(source_dir, topdown=False):
        dir_portion = subpath(root, source_dir)
        for f in files:
            # Never automatically add any Dart generator scripts (these are the original
            # sources in WebCore) from WebKit to WebCore.
            if dir_portion != DART_SDK_GENERATOR_SCRIPTS:
                if (f.endswith(IDL_EXT) or f == IDL_EXTENDED_ATTRIBUTES_FILE or
                        f.endswith(PY_EXT) or
                        f.startswith(LICENSE_FILE_PREFIX)):
                    if f.endswith(IDL_EXT):
                        idls += 1
                    elif f.endswith(PY_EXT):
                        pys += 1
                    else:
                        others += 1
                    src_file = os.path.join(root, f)

                    # Compute the destination path using sdk/third_party/WebCore
                    subdir_root = src_file[src_file.rfind(src_prefix) +
                                           len(src_prefix):]
                    if subdir_root.startswith(os.path.sep):
                        subdir_root = subdir_root[1:]
                    dst_file = os.path.join(destination_dir, subdir_root)

                    # Need to make src/third_party/WebKit/Source/* to sdk/third_party/WebCore/*

                    destination = os.path.dirname(dst_file)
                    if not os.path.exists(destination):
                        os.makedirs(destination)

                    has_Dart_fix_me = anyDartFixMe(dst_file)

                    if not isDryRun():
                        copyfile(src_file, dst_file)
                    if isVerbose():
                        #print('...copying %s' % os.path.split(dst_file)[1])
                        print('...copying %s' % dst_file)
                    if f == IDL_EXTENDED_ATTRIBUTES_FILE:
                        warning_messages.append(dst_file)
                    else:
                        if has_Dart_fix_me:
                            warning_messages.append(dst_file)
                        if not (isDryRun() or has_Dart_fix_me):
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

    if os.path.exists(webcore_dir):
        os.chdir(webcore_dir)

        for (root, _, files) in os.walk(
                os.path.join(webcore_dir, subdir), topdown=False):
            dir_portion = subpath(root, webcore_dir)
            for f in files:
                # Never automatically deleted any Dart generator scripts (these are the
                # original sources in WebCore).
                if dir_portion != DART_SDK_GENERATOR_SCRIPTS:
                    check_file = os.path.join(dir_portion, f)
                    check_file_full_path = os.path.join(webkit_dir, check_file)
                    if not os.path.exists(check_file_full_path) and \
                       not(check_file_full_path.endswith(PYTHON_INITS)):
                        if not isDryRun():
                            # Remove the file using git
                            RunCommand(['git', 'rm', check_file])
                        files_to_delete.append(check_file)

    os.chdir(original_cwd)

    return files_to_delete


def ParseOptions():
    parser = optparse.OptionParser()
    parser.add_option(
        '--chromium',
        '-c',
        dest='chromium_dir',
        action='store',
        type='string',
        help='WebKit Chrome directory (e.g., --chromium=~/chrome63',
        default=None)
    parser.add_option(
        '--verbose',
        '-v',
        dest='verbose',
        action='store_true',
        help='Dump all information',
        default=None)
    parser.add_option(
        '--dry_run',
        '-d',
        dest='dry_run',
        action='store_true',
        help='Display results without adding, updating or deleting any files',
        default=None)
    args, _ = parser.parse_args()

    argOptions = {}
    argOptions['chromium_dir'] = args.chromium_dir
    argOptions['verbose'] = args.verbose
    argOptions['dry_run'] = args.dry_run
    return argOptions


# Fetch the DEPS file in src/dart/tools/deps/dartium.deps/DEPS from the GIT repro.
def GetDepsFromGit():
    req = requests.get(DEPS_GIT)
    return req.text


def ValidateGitRemotes():
    #origin  https://chromium.googlesource.com/dart/dartium/src.git (fetch)
    remotes_list = RunCommand(['git', 'remote', '--verbose']).split()
    if (len(remotes_list) > 2 and remotes_list[0] == 'origin' and
            remotes_list[1] == GIT_REMOTES_CHROMIUM):
        return True

    print 'ERROR: Unable to find dart/dartium/src repository %s' % GIT_REMOTES_CHROMIUM
    return False


def getChromiumSHA():
    cwd = os.getcwd()
    chromiumDir = chromiumDirectory()

    webkit_dir = os.path.join(chromiumDir, WEBKIT_SOURCE)
    os.chdir(webkit_dir)

    if ValidateGitRemotes():
        chromium_sha = RunCommand(['git', 'log', '--format=format:%H', '-1'])
    else:
        chromium_sha = -1

    os.chdir(cwd)
    return chromium_sha


def getCurrentDartSHA():
    cwd = os.getcwd()

    if cwd.endswith('dart'):
        # In src/dart
        src_dir, _ = os.path.split(cwd)
    elif cwd.endswith('sdk'):
        src_dir = cwd
    else:
        src_dir = os.path.join(cwd, 'sdk')
    os.chdir(src_dir)

    if ValidateGitRemotes():
        dart_sha = RunCommand(['git', 'log', '--format=format:%H', '-1'])
    else:
        dart_sha = -1

    os.chdir(cwd)
    return dart_sha


# Returns the SHA of the Dartium/Chromiun in the DEPS file.
def GetDEPSWebCoreGitRevision(deps, component):
    """Returns a tuple with the (dartium chromium repo, latest revision)."""
    foundIt = re.search(WEBKIT_SHA_PATTERN, deps)
    #url_base, url_pattern = DEPS_PATTERNS[component]
    #url = url_base + re.search(url_pattern, deps).group(1)
    # Get the SHA for the Chromium/WebKit changes for Dartium.
    #revision = url[len(url_base):]
    revision = foundIt.group(1)[1:]
    print '%s' % revision
    return revision


def copy_subdir(src, src_prefix, dest, subdir):
    idls_deleted = remove_obsolete_webcore_files(dest, src, subdir)
    print "%s files removed in WebCore %s" % (idls_deleted.__len__(), subdir)
    if isVerbose():
        for delete_file in idls_deleted:
            print "    %s" % delete_file

    idls_copied, py_copied, other_copied = copy_files(
        os.path.join(src, subdir), src_prefix, dest)
    if idls_copied > 0:
        print "Copied %s IDLs to %s" % (idls_copied, subdir)
    if py_copied > 0:
        print "Copied %s PYs to %s" % (py_copied, subdir)
    if other_copied > 0:
        print "Copied %s other to %s\n" % (other_copied, subdir)


def main():
    global options
    options = ParseOptions()

    current_dir = os.path.dirname(os.path.abspath(__file__))
    if not current_dir.endswith(SOURCE_FILE_DIR):
        print 'ERROR: idlsync.py not run in proper directory (%s)\n', current_dir

    base_directory = current_dir[:current_dir.rfind(SOURCE_FILE_DIR)]

    # Validate DEPS WebCore_rev SHA DOES NOT match the SHA of chromium master.
    deps = GetDepsFromGit()
    webcore_revision = GetDEPSWebCoreGitRevision(deps, 'webkit')
    chromium_sha = getChromiumSHA()
    if webcore_revision == chromium_sha:
        print "ERROR: Nothing to update in WebCore, WebCore_rev SHA in DEPS " \
              "matches Chromium GIT master SHA in %s" % options['webkit_dir']
        return

    start_time = time.time()

    # Copy scripts from third_party/blink/tools to third_party/WebCore/blink/tools
    #
    # This also implies that the files:
    #     WebCore/bindings/scripts/code_generator_web_agent_api.py
    #     WebCore/bindings/scripts/utilities.py
    #
    # Need to have sys.path.append at beginning of the above files changed from:
    #
    #    sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', '..',
    #                                 'third_party', 'blink', 'tools'))
    # to
    #
    #    sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..',
    #                                 'blink', 'tools'))
    #
    webkit_blink_dir = os.path.join(chromiumDirectory(), WEBKIT_BLINK_SOURCE)
    webcore_blink_dir = os.path.join(base_directory, WEBCORE_BLINK_SOURCE)
    copy_subdir(webkit_blink_dir, WEBKIT_BLINK_SOURCE, webcore_blink_dir, "")

    chromium_webkit_dir = os.path.join(chromiumDirectory(), WEBKIT_SOURCE)
    dart_webcore_dir = os.path.join(base_directory, WEBCORE_SOURCE)
    for subdir in SUBDIRS:
        copy_subdir(chromium_webkit_dir, WEBKIT_SOURCE, dart_webcore_dir,
                    subdir)

    end_time = time.time()

    print 'WARNING: File(s) contain FIXMEDART and are NOT "git add " please review:'
    for warning in warning_messages:
        print '    %s' % warning

    print '\nDone idlsync completed in %s seconds' % round(
        end_time - start_time, 2)


if __name__ == '__main__':
    sys.exit(main())
