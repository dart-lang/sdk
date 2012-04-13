#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Gets or updates a DumpRenderTree (a nearly headless build of chrome). This is
# used for running browser tests of client applications.

import optparse
import os
import platform
import shutil
import subprocess
import sys
import tempfile

def NormJoin(path1, path2):
  return os.path.normpath(os.path.join(path1, path2))

# Change into the dart directory as we want the project to be rooted here.
dart_src = NormJoin(os.path.dirname(sys.argv[0]), os.pardir)
os.chdir(dart_src)

GSUTIL_DIR = 'third_party/gsutil/20110627'
GSUTIL = GSUTIL_DIR + '/gsutil'

DRT_DIR = 'client/tests/drt'
DRT_VERSION = DRT_DIR + '/LAST_VERSION'
DRT_LATEST_PATTERN = (
    'gs://dartium-archive/latest/drt-%(osname)s-inc-*.zip')
DRT_PERMANENT_PREFIX = 'gs://dartium-archive/drt-%(osname)s-inc'

DARTIUM_DIR = 'client/tests/dartium'
DARTIUM_VERSION = DARTIUM_DIR + '/LAST_VERSION'
DARTIUM_LATEST_PATTERN = (
    'gs://dartium-archive/latest/dartium-%(osname)s-inc-*.zip')
DARTIUM_PERMANENT_PREFIX = 'gs://dartium-archive/dartium-%(osname)s-inc'

sys.path.append(GSUTIL_DIR + '/boto')
import boto


def execute_command(*cmd):
  """Execute a command in a subprocess."""
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output, error = pipe.communicate()
  return pipe.returncode, output


def execute_command_visible(*cmd):
  """Execute a command in a subprocess, but show stdout/stderr."""
  result = subprocess.call(cmd, stdout=sys.stdout, stderr=sys.stderr,
                           stdin=sys.stdin)
  if result != 0:
    raise Exception('Execution of "%s" failed' % ' '.join(cmd))


def gsutil(*cmd):
  return execute_command(GSUTIL, *cmd)


def gsutil_visible(*cmd):
  execute_command_visible(GSUTIL, *cmd)


def has_boto_config():
  """Returns true if boto config exists."""

  config_paths = boto.pyami.config.BotoConfigLocations
  if 'AWS_CREDENTIAL_FILE' in os.environ:
    config_paths.append(os.environ['AWS_CREDENTIAL_FILE'])
  for config_path in config_paths:
    if os.path.exists(config_path):
      return True

  return False


def in_runhooks():
  '''True if this script was called by "gclient runhooks" or "gclient sync"'''
  return 'runhooks' in sys.argv


def ensure_config():
  # If ~/.boto doesn't exist, tell the user to run "gsutil config"
  if not has_boto_config():
    print >>sys.stderr, '''
*******************************************************************************
* WARNING: Can't download DumpRenderTree! This is required to test client apps.
* You need to do a one-time configuration step to access Google Storage.
* Please run this command and follow the instructions:
*     %s config
*
* NOTE: When prompted you can leave "project-id" blank. Just hit enter.
*******************************************************************************
''' % GSUTIL
    sys.exit(1)


def get_latest(name, directory, version_file, latest_pattern, permanent_prefix):
  """Get the latest DumpRenderTree or Dartium binary depending on arguments.

  Args:
    directory: target directory (recreated) to install binary
    version_file: name of file with the current version stamp
    latest_pattern: the google store url pattern pointing to the latest binary
    permanent_prefix: stable google store folder used to download versions
  """
  system = platform.system()
  if system == 'Darwin':
    osname = 'mac'
  elif system == 'Linux':
    osname = 'lucid64'
  else:
    print >>sys.stderr, ('WARNING: platform "%s" does not support'
        '%s for tests') % (system, name)
    return 0

  ensure_config()

  # Query for the lastest version
  pattern = latest_pattern  % { 'osname' : osname }
  result, out = gsutil('ls', pattern)
  if result == 0:
    latest = out.split()[-1]
    # use permanent link instead, just in case the latest zip entry gets deleted
    # while we are downloading it.
    latest = (permanent_prefix % { 'osname' : osname }
              + latest[latest.rindex('/'):])
  else: # e.g. no access
    print "Couldn't download %s: %s\n%s" % (name, pattern, out)
    if not os.path.exists(version_file):
      print "Tests using %s will not work. Please try again later." % name
    return 0

  # Check if we need to update the file
  if os.path.exists(version_file):
    v = open(version_file, 'r').read()
    if v == latest:
      if not in_runhooks():
        print name + ' is up to date.\nVersion: ' + latest
      return 0 # up to date

  if os.path.exists(directory):
    print 'Removing old %s tree %s' % (name, directory)
    shutil.rmtree(directory)

  # download the zip file to a temporary path, and unzip to the target location
  temp_dir = tempfile.mkdtemp()
  try:
    temp_zip = temp_dir + '/drt.zip'
    # It's nice to show download progress
    gsutil_visible('cp', latest, temp_zip)

    result, out = execute_command('unzip', temp_zip, '-d', temp_dir)
    if result != 0:
      raise Exception('Execution of "unzip %s -d %s" failed: %s' %
                      (temp_zip, temp_dir, str(out)))
    unzipped_dir = temp_dir + '/' + os.path.basename(latest)[:-4] # remove .zip
    shutil.move(unzipped_dir, directory)
  finally:
    shutil.rmtree(temp_dir)

  # create the version stamp
  v = open(version_file, 'w')
  v.write(latest)
  v.close()

  print 'Successfully downloaded to %s' % directory
  return 0


def main():
  parser = optparse.OptionParser()
  parser.add_option('--dartium', dest='dartium',
                    help='Get latest Dartium', action='store_true',
                    default=False)
  args, _ = parser.parse_args()

  if args.dartium:
    get_latest('Dartium', DARTIUM_DIR, DARTIUM_VERSION,
               DARTIUM_LATEST_PATTERN, DARTIUM_PERMANENT_PREFIX)
  else:
    get_latest('DumpRenderTree', DRT_DIR, DRT_VERSION,
               DRT_LATEST_PATTERN, DRT_PERMANENT_PREFIX)

if __name__ == '__main__':
  sys.exit(main())
