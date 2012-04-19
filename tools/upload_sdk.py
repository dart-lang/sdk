#!/usr/bin/python

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This zips the SDK and uploads it to Google Storage when run on a buildbot.
#
# Usage: upload_sdk.py path_to_sdk

import os
import os.path
import platform
import subprocess
import sys
import utils


GSUTIL = '/b/build/scripts/slave/gsutil'
HAS_SHELL = False
if platform.system() == 'Windows':
  GSUTIL = 'e:\\\\b\\build\\scripts\\slave\\gsutil'
  HAS_SHELL = True
GS_SITE = 'gs://'
GS_DIR = 'dart-dump-render-tree'
GS_SDK_DIR = 'sdk'
SDK_LOCAL_ZIP = "dart-sdk.zip"

def ExecuteCommand(cmd):
  """Execute a command in a subprocess.
  """
  print 'Executing: ' + ' '.join(cmd)
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
      shell=HAS_SHELL)
  output = pipe.communicate()
  if pipe.returncode != 0:
    print 'Execution failed: ' + str(output)
  return (pipe.returncode, output)


def UploadArchive(source, target):
  """Upload an archive zip file to Google storage.
  """
  # Upload file.
  cmd = [GSUTIL, 'cp', source, target]
  (status, output) = ExecuteCommand(cmd)
  if status != 0:
    return status
  print 'Uploaded: ' + output[0]

  cmd = [GSUTIL, 'setacl', 'public-read', target]
  (status, output) = ExecuteCommand(cmd)
  return status


def Usage(progname):
  sys.stderr.write('Usage: %s path_to_sdk\n' % progname)


def main(argv):
  #allow local editor builds to deploy to a different bucket
  if os.environ.has_key('DART_LOCAL_BUILD'):
    gsdir = os.environ['DART_LOCAL_BUILD']
  else:
    gsdir = GS_DIR
    
  if not os.path.exists(argv[1]):
    sys.stderr.write('Path not found: %s\n' % argv[1])
    Usage(argv[0])
    return 1
  if not os.path.exists(GSUTIL):
    #TODO: Determine where we are running, if we're running on a buildbot we
    #should fail with a message.  
    #If we are not on a buildbot then fail silently. 
    exit(0)
  revision = utils.GetSVNRevision()
  if revision is None:
    sys.stderr.write('Unable to find SVN revision.\n')
    return 1
  os.chdir(os.path.dirname(argv[1]))

  if (os.path.basename(os.path.dirname(argv[1])) ==
      utils.GetBuildConf('release', 'ia32')):
    sdk_suffix = ''
  else:
    sdk_suffix = '-debug'
  # TODO(dgrove) - deal with architectures that are not ia32.
  sdk_file = 'dart-%s-%s%s.zip' % (utils.GuessOS(), revision, sdk_suffix)
  if (os.path.exists(SDK_LOCAL_ZIP)):
    os.remove(SDK_LOCAL_ZIP)
  if platform.system() == 'Windows':
    # Windows does not have zip. We use the 7 zip utility in third party.
    ExecuteCommand([os.path.join('..', 'third_party', '7zip', '7za'), 'a',
        '-tzip', SDK_LOCAL_ZIP, os.path.basename(argv[1])])
  else:
    ExecuteCommand(['zip', '-yr', SDK_LOCAL_ZIP, os.path.basename(argv[1])])
  UploadArchive(SDK_LOCAL_ZIP,
                GS_SITE + '/'.join([gsdir, GS_SDK_DIR, sdk_file]))
  latest_name = 'dart-%s-latest%s.zip' % (utils.GuessOS(), sdk_suffix)
  UploadArchive(SDK_LOCAL_ZIP,
                GS_SITE + '/'.join([gsdir, GS_SDK_DIR, latest_name]))


if __name__ == '__main__':
  sys.exit(main(sys.argv))
