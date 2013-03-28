#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import optparse
import os
import os.path
import re
import shutil
import subprocess
import sys
import tempfile

SCRIPT_PATH = os.path.abspath(os.path.dirname(__file__))
DART_PATH = os.path.abspath(os.path.join(SCRIPT_PATH, '..', '..', '..'))

# Dartium DEPS file with Chrome and WebKit revisions.
DEPS = ('http://dart.googlecode.com/svn/branches/'
        'bleeding_edge/deps/dartium.deps/DEPS')

# Whitelist of files to keep.
WHITELIST = [
    r'LICENSE(\S+)',
    r'(\S+)\.idl',
    r'(\S+)\.json',
    r'(\S+)\.py',
    ]

# WebKit / WebCore info.
WEBKIT_URL_PATTERN = r'"dartium_webkit_trunk": "(\S+)",'
WEBKIT_REV_PATTERN = r'"dartium_webkit_revision": "(\d+)",'
WEBCORE_SUBPATH = 'Source/WebCore'
LOCAL_WEBKIT_IDL_PATH = os.path.join(DART_PATH, 'third_party', 'WebCore')
LOCAL_WEBKIT_README = """\
This directory contains a copy of WebKit/WebCore IDL files.
See the attached LICENSE-* files in this directory.

Please do not modify the files here.  They are periodically copied
using the script: $DART_ROOT/sdk/lib/html/scripts/%(script)s

The current version corresponds to:
URL: %(url)s
Current revision: %(revision)s
"""

# Chrome info.
CHROME_URL_PATTERN = r'"chromium_url": "(\S+)",'
CHROME_REV_PATTERN = r'"chromium_revision": "(\d+)",'
CHROME_IDL_SUBPATH = 'trunk/src/chrome/common/extensions/api'
CHROME_TOOLS_SUBPATH = 'trunk/src/tools'
CHROME_COMPILER_SUBPATH = 'trunk/src/tools/json_schema_compiler'
CHROME_IDL_PARSER_SUBPATH = 'trunk/src/ppapi/generators'
CHROME_PLY_SUBPATH = 'trunk/src/third_party/ply'
LOCAL_CHROME_IDL_PATH = os.path.join(DART_PATH, 'third_party', 'chrome', 'idl')
LOCAL_CHROME_TOOLS_PATH = os.path.join(DART_PATH, 'third_party', 'chrome',
                                       'tools')
LOCAL_CHROME_COMPILER_PATH = os.path.join(DART_PATH, 'third_party', 'chrome',
                                          'tools', 'json_schema_compiler')
LOCAL_CHROME_IDL_PARSER_PATH = os.path.join(DART_PATH, 'third_party', 'chrome',
                                            'ppapi', 'generators')
LOCAL_CHROME_PLY_PATH = os.path.join(DART_PATH, 'third_party', 'chrome',
                                     'third_party', 'ply')
LOCAL_CHROME_README = """\
This directory contains a copy of Chromium IDL and generation scripts
used to generate Dart APIs for Chrome Apps.

The original files are from:
URL: %(url)s
Current revision: %(revision)s

Please see the corresponding LICENSE file at
%(url)s/trunk/src/LICENSE.
"""
DEPTH_FILES = 'files'
DEPTH_INFINITY = 'infinity'

# Regular expressions corresponding to URL/revision patters in the
# DEPS file.
DEPS_PATTERNS = {
    'webkit': (WEBKIT_URL_PATTERN, WEBKIT_REV_PATTERN),
    'chrome': (CHROME_URL_PATTERN, CHROME_REV_PATTERN),
    }

# List of components to update.
UPDATE_LIST = [
    # (component, remote subpath, local path, local readme file, depth)

    # WebKit IDL.
    ('webkit', WEBCORE_SUBPATH, LOCAL_WEBKIT_IDL_PATH, LOCAL_WEBKIT_README,
     DEPTH_INFINITY),
    # Chrome IDL.
    ('chrome', CHROME_IDL_SUBPATH, LOCAL_CHROME_IDL_PATH, LOCAL_CHROME_README,
     DEPTH_INFINITY),
    # Chrome PPAPI generators. Contains idl_parser.py which is used by the
    # Chrome IDL compiler.
    ('chrome', CHROME_IDL_PARSER_SUBPATH, LOCAL_CHROME_IDL_PARSER_PATH,
     LOCAL_CHROME_README, DEPTH_FILES),
    # ply files.
    ('chrome', CHROME_PLY_SUBPATH, LOCAL_CHROME_PLY_PATH, LOCAL_CHROME_README,
     DEPTH_INFINITY),
    # Top level Chrome tools folder. Contains json_comment_eater.py which is
    # needed by the Chrome IDL compiler.
    ('chrome', CHROME_TOOLS_SUBPATH, LOCAL_CHROME_TOOLS_PATH,
     LOCAL_CHROME_README, DEPTH_FILES),
    # Chrome IDL compiler files.
    ('chrome', CHROME_COMPILER_SUBPATH, LOCAL_CHROME_COMPILER_PATH,
     LOCAL_CHROME_README, DEPTH_INFINITY),
    ]


def RunCommand(cmd):
  """Executes a shell command and return its stdout."""
  print ' '.join(cmd)
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output = pipe.communicate()
  if pipe.returncode == 0:
    return output[0]
  else:
    print output[1]
    print 'FAILED. RET_CODE=%d' % pipe.returncode
    sys.exit(pipe.returncode)


def GetDeps():
  """Returns the DEPS file contents with pinned revision info."""
  return RunCommand(['svn', 'cat', DEPS])


def GetSvnRevision(deps, component):
  """Returns a tuple with the (dartium webkit repo, latest revision)."""
  url_pattern, rev_pattern = DEPS_PATTERNS[component]
  url = re.search(url_pattern, deps).group(1)
  revision = re.search(rev_pattern, deps).group(1)
  return (url, revision)


def RefreshFiles(url, revision, remote_path, local_path, depth):
  """Refreshes refreshes files in the local_path to specific url /
  revision / remote_path, exporting to depth"""
  cwd = os.getcwd()
  try:
    if os.path.exists(local_path):
      shutil.rmtree(local_path)
    head, tail = os.path.split(local_path)
    if not os.path.exists(head):
      os.makedirs(head)
    os.chdir(head)
    RunCommand(['svn', 'export', '--depth', depth, '-r', revision,
                url + '/' + remote_path, tail])
  finally:
    os.chdir(cwd)


def PruneExtraFiles(local_path):
  """Removes all files that do not match the whitelist."""
  pattern = re.compile(reduce(lambda x,y: '%s|%s' % (x,y),
                              map(lambda z: '(%s)' % z, WHITELIST)))
  for (root, dirs, files) in os.walk(local_path, topdown=False):
    for f in files:
      if not pattern.match(f):
        os.remove(os.path.join(root, f))
    for d in dirs:
      dirpath = os.path.join(root, d)
      if not os.listdir(dirpath):
        shutil.rmtree(dirpath)


def GenerateReadme(local_path, template, url, revision):
  readme = template % {
    'script': os.path.basename(__file__),
    'url': url,
    'revision': revision }

  readme_path = os.path.join(local_path, 'README')
  out = open(readme_path, 'w')
  out.write(readme)
  out.close()

ZIP_ARCHIVE = 'version-control-dirs.zip'

def SaveVersionControlDir(local_path):
  RunCommand([
    'sh', '-c',
    'find %s -name .svn -or -name .git | zip -r %s -@' % (
        os.path.relpath(local_path), ZIP_ARCHIVE)
  ])


def RestoreVersionControlDir():
  RunCommand(['unzip', ZIP_ARCHIVE, '-d', '.'])
  RunCommand(['rm', ZIP_ARCHIVE])

def ParseOptions():
  parser = optparse.OptionParser()
  parser.add_option('--webkit-revision', '-w', dest='webkit_revision',
                    help='WebKit IDL revision to install', default=None)
  parser.add_option('--chrome-revision', '-c', dest='chrome_revision',
                    help='Chrome IDL revision to install', default=None)
  parser.add_option('--update', '-u', dest='update',
                    help='IDL to update (webkit | chrome | all)',
                    default='webkit')
  args, _ = parser.parse_args()
  update = {}
  if args.update == 'all' or args.update == 'chrome':
    update['chrome'] = args.chrome_revision
  if args.update == 'all' or args.update == 'webkit':
    update['webkit'] = args.webkit_revision
  return update


def main():
  deps = GetDeps()
  update = ParseOptions()
  for (component, remote_path, local_path, readme, depth) in UPDATE_LIST:
    if component in update.keys():
      revision = update[component]
      url, latest = GetSvnRevision(deps, component)
      if revision is None:
        revision = latest
      SaveVersionControlDir(local_path);
      RefreshFiles(url, revision, remote_path, local_path, depth)
      PruneExtraFiles(local_path)
      GenerateReadme(local_path, readme, url, revision)
      RestoreVersionControlDir();

if __name__ == '__main__':
  main()
