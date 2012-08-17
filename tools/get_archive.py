#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Gets or updates a DumpRenderTree (a nearly headless build of chrome). This is
# used for running browser tests of client applications.

import json
import optparse
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import zipfile

import utils

def NormJoin(path1, path2):
  return os.path.normpath(os.path.join(path1, path2))

# Change into the dart directory as we want the project to be rooted here.
dart_src = NormJoin(os.path.dirname(sys.argv[0]), os.pardir)
os.chdir(dart_src)

GSUTIL_DIR = os.path.join('third_party', 'gsutil')
GSUTIL = GSUTIL_DIR + '/gsutil'

DRT_DIR = os.path.join('client', 'tests', 'drt')
DRT_VERSION = os.path.join(DRT_DIR, 'LAST_VERSION')
DRT_LATEST_PATTERN = (
    'gs://dartium-archive/latest/drt-%(osname)s-inc-*.zip')
DRT_PERMANENT_PATTERN = ('gs://dartium-archive/drt-%(osname)s-inc/drt-'
                         '%(osname)s-inc-%(num1)s.%(num2)s.zip')

DARTIUM_DIR = os.path.join('client', 'tests', 'dartium')
DARTIUM_VERSION = os.path.join(DARTIUM_DIR, 'LAST_VERSION')
DARTIUM_LATEST_PATTERN = (
    'gs://dartium-archive/latest/dartium-%(osname)s-inc-*.zip')
DARTIUM_PERMANENT_PATTERN = ('gs://dartium-archive/dartium-%(osname)s-inc/'
                             'dartium-%(osname)s-inc-%(num1)s.%(num2)s.zip')

CHROMEDRIVER_DIR = os.path.join('tools', 'testing', 'dartium-chromedriver')
CHROMEDRIVER_VERSION = os.path.join(CHROMEDRIVER_DIR, 'LAST_VERSION')
CHROMEDRIVER_LATEST_PATTERN = (
    'gs://dartium-archive/latest/chromedriver-%(osname)s-inc-*.zip')
CHROMEDRIVER_PERMANENT_PATTERN = ('gs://dartium-archive/chromedriver-%(osname)s'
                                  '-inc/chromedriver-%(osname)s-inc-%(num1)s.'
                                  '%(num2)s.zip')

SDK_DIR = os.path.join(utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32'),
    'dart-sdk')
SDK_VERSION = os.path.join(SDK_DIR, 'LAST_VERSION')
SDK_LATEST_PATTERN = 'gs://dart-editor-archive-continuous/latest/VERSION'
# TODO(efortuna): Once the x64 VM also is optimized, select the version
# based on whether we are running on a 32-bit or 64-bit system.
SDK_PERMANENT = ('gs://dart-editor-archive-continuous/%(version_num)s/' + 
    'dartsdk-%(osname)s-32.zip')

sys.path.append(os.path.join(GSUTIL_DIR, 'boto'))
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
  return execute_command('python', GSUTIL, *cmd)


def gsutil_visible(*cmd):
  execute_command_visible('python', GSUTIL, *cmd)


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


def get_dartium_revision(name, directory, version_file, latest_pattern,
    permanent_prefix, revision_num=None):
  """Get the latest binary that is stored in the dartium archive.

  Args:
    name: the name of the desired download.
    directory: target directory (recreated) to install binary
    version_file: name of file with the current version stamp
    latest_pattern: the google store url pattern pointing to the latest binary
    permanent_prefix: stable google store folder used to download versions
    revision_num: The desired revision number to retrieve. If revision_num is
        None, we return the latest revision. If the revision number is specified
        but unavailable, find the nearest older revision and use that instead.
  """
  osdict = {'Darwin':'mac', 'Linux':'lucid64', 'Windows':'win'}

  def find_permanent_url(out, osname, revision_num):
    output_lines = out.split()
    latest = output_lines[-1]
    if not revision_num:
      revision_num = latest[latest.rindex('-') + 1 : latest.index('.')]
      latest = (permanent_prefix[:permanent_prefix.rindex('/')] % { 'osname' :
          osname } + latest[latest.rindex('/'):])
    else:
      latest = (permanent_prefix % { 'osname' : osname, 'num1' : revision_num,
          'num2' : revision_num })
      foundURL = False
      while not foundURL:
        # Test to ensure this URL exists because the dartium-archive builds can
        # have unusual numbering (a range of CL numbers) sometimes.
        result, out = gsutil('ls', permanent_prefix % {'osname' : osname,
            'num1': '*', 'num2': revision_num })
        if result == 0:
          # First try to find one with the the second number the same as the
          # requested number.
          latest = out.split()[0]
          foundURL = True
        else:
          # Now try to find one with a nearby CL num.
          revision_num = int(revision_num) - 1
          if revision_num <= 0:
            too_early_error()
    return latest
    
  get_from_gsutil(name, directory, version_file, latest_pattern, osdict, 
                  find_permanent_url, revision_num)

def get_sdk_revision(name, directory, version_file, latest_pattern,
    permanent_prefix, revision_num):
  """Get a revision of the SDK from the editor build archive.

  Args:
    name: the name of the desired download
    directory: target directory (recreated) to install binary
    version_file: name of file with the current version stamp
    latest_pattern: the google store url pattern pointing to the latest binary
    permanent_prefix: stable google store folder used to download versions
    revision_num: the desired revision number, or None for the most recent
  """
  osdict = {'Darwin':'macos', 'Linux':'linux', 'Windows':'win32'}
  def find_permanent_url(out, osname, not_used):
    rev_num = revision_num
    if not rev_num:
      temp_file = tempfile.NamedTemporaryFile()
      temp_file_url = 'file://' + temp_file.name
      gsutil('cp', latest_pattern % {'osname' : osname }, temp_file_url)
      temp_file.seek(0)
      version_info = temp_file.read()
      temp_file.close()
      if version_info != '':
        rev_num = json.loads(version_info)['revision']
      else:
        print 'Unable to get latest version information.'
        return ''
    latest = (permanent_prefix % { 'osname' : osname, 'version_num': rev_num})
    return latest
    
  get_from_gsutil(name, directory, version_file, latest_pattern, osdict,
                  find_permanent_url, revision_num)

def get_from_gsutil(name, directory, version_file, latest_pattern,
    os_name_dict, get_permanent_url, revision_num = ''):
  """Download and unzip the desired file from Google Storage.
    Args:
    name: the name of the desired download
    directory: target directory (recreated) to install binary
    version_file: name of file with the current version stamp
    latest_pattern: the google store url pattern pointing to the latest binary
    os_name_dict: a dictionary of operating system names and their corresponding
        strings on the google storage site.
    get_permanent_url: a function that accepts a listing of available files
        and the os name, and returns a permanent URL for downloading.
    revision_num: the desired revision number to get (if not supplied, we get
        the latest revision)
  """
  system = platform.system()
  try:
    osname = os_name_dict[system]
  except KeyError:
    print >>sys.stderr, ('WARNING: platform "%s" does not support'
        '%s.') % (system, name)
    return 0

  ensure_config()

  # Query for the lastest version
  pattern = latest_pattern  % { 'osname' : osname }
  result, out = gsutil('ls', pattern)
  if result == 0:
    # use permanent link instead, just in case the latest zip entry gets deleted
    # while we are downloading it.
    latest = get_permanent_url(out, osname, revision_num)
  else: # e.g. no access
    print "Couldn't download %s: %s\n%s" % (name, pattern, out)
    if not os.path.exists(version_file):
      print "Using %s will not work. Please try again later." % name
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
    temp_zip = os.path.join(temp_dir, 'drt.zip')
    temp_zip_url = 'file://' + temp_zip
    # It's nice to show download progress
    gsutil_visible('cp', latest, temp_zip_url)

    if platform.system() != 'Windows':
      # The Python zip utility does not preserve executable permissions, but
      # this does not seem to be a problem for Windows, which does not have a
      # built in zip utility. :-/
      result, out = execute_command('unzip', temp_zip, '-d', temp_dir)
      if result != 0:
        raise Exception('Execution of "unzip %s -d %s" failed: %s' %
                        (temp_zip, temp_dir, str(out)))
      unzipped_dir = temp_dir + '/' + os.path.basename(latest)[:-len('.zip')]
    else:
      z = zipfile.ZipFile(temp_zip)
      z.extractall(temp_dir)
      unzipped_dir = os.path.join(temp_dir,
                                  os.path.basename(latest)[:-len('.zip')])
      z.close()
    if directory == SDK_DIR:
      unzipped_dir = os.path.join(temp_dir, 'dart-sdk')
    shutil.move(unzipped_dir, directory)
  finally:
    shutil.rmtree(temp_dir)

  # create the version stamp
  v = open(version_file, 'w')
  v.write(latest)
  v.close()

  print 'Successfully downloaded to %s' % directory
  return 0

def too_early_error():
  """Quick shortcutting function, to return early if someone requests a revision
  that is smaller than the earliest stored. This saves us from doing repeated
  requests until we get down to 0."""
  print ('Unable to download requested revision because it is earlier than the '
      'earliest revision stored.')
  sys.exit(1)

def main():
  parser = optparse.OptionParser(usage='usage: %prog [options] download_name')
  parser.add_option('-r', '--revision', dest='revision',
                    help='Desired revision number to retrieve for the SDK. If '
                    'unspecified, retrieve the latest SDK build.',
                    action='store', default=None)
  args, positional = parser.parse_args()

  if positional[0] == 'dartium':
    if args.revision and args.revision < 4285:
      return too_early_error()
    get_dartium_revision('Dartium', DARTIUM_DIR, DARTIUM_VERSION,
                         DARTIUM_LATEST_PATTERN, DARTIUM_PERMANENT_PATTERN,
                         args.revision)
  elif positional[0] == 'chromedriver':
    if args.revision and args.revision < 7823:
      return too_early_error()
    get_dartium_revision('chromedriver', CHROMEDRIVER_DIR, CHROMEDRIVER_VERSION,
                         CHROMEDRIVER_LATEST_PATTERN,
                         CHROMEDRIVER_PERMANENT_PATTERN, args.revision)
  elif positional[0] == 'sdk':
    if args.revision and args.revision < 9761:
      return too_early_error()
    get_sdk_revision('sdk', SDK_DIR, SDK_VERSION, SDK_LATEST_PATTERN,
        SDK_PERMANENT, args.revision)
  elif positional[0] == 'drt':
    if args.revision and args.revision < 5342:
      return too_early_error()
    get_dartium_revision('DumpRenderTree', DRT_DIR, DRT_VERSION,
                         DRT_LATEST_PATTERN, DRT_PERMANENT_PATTERN,
                         args.revision)
  else:
    print ('Please specify the target you wish to download from Google Storage '
        '("drt", "dartium", "chromedriver", or "sdk")')

if __name__ == '__main__':
  sys.exit(main())
