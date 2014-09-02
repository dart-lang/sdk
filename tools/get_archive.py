#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Gets or updates a content shell (a nearly headless build of chrome). This is
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
    'gs://dartium-archive/latest/drt-%(osname)s-%(bot)s-*.zip')
DRT_PERMANENT_PATTERN = ('gs://dartium-archive/drt-%(osname)s-%(bot)s/drt-'
                         '%(osname)s-%(bot)s-%(num1)s.%(num2)s.zip')

DARTIUM_DIR = os.path.join('client', 'tests', 'dartium')
DARTIUM_VERSION = os.path.join(DARTIUM_DIR, 'LAST_VERSION')
DARTIUM_LATEST_PATTERN = (
    'gs://dartium-archive/latest/dartium-%(osname)s-%(bot)s-*.zip')
DARTIUM_PERMANENT_PATTERN = ('gs://dartium-archive/dartium-%(osname)s-%(bot)s/'
                             'dartium-%(osname)s-%(bot)s-%(num1)s.%(num2)s.zip')

SDK_DIR = os.path.join(utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32'),
    'dart-sdk')
SDK_VERSION = os.path.join(SDK_DIR, 'LAST_VERSION')
SDK_LATEST_PATTERN = 'gs://dart-archive/channels/dev/raw/latest/VERSION'
# TODO(efortuna): Once the x64 VM also is optimized, select the version
# based on whether we are running on a 32-bit or 64-bit system.
SDK_PERMANENT = ('gs://dart-archive/channels/dev/raw/%(version_num)s/sdk/' +
    'dartsdk-%(osname)s-ia32-release.zip')

# Dictionary storing the earliest revision of each download we have stored.
LAST_VALID = {'dartium': 4285, 'chromedriver': 7823, 'sdk': 9761, 'drt': 5342}

sys.path.append(os.path.join(GSUTIL_DIR, 'third_party', 'boto'))
import boto


def ExecuteCommand(*cmd):
  """Execute a command in a subprocess."""
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output, error = pipe.communicate()
  return pipe.returncode, output


def ExecuteCommandVisible(*cmd):
  """Execute a command in a subprocess, but show stdout/stderr."""
  result = subprocess.call(cmd, stdout=sys.stdout, stderr=sys.stderr,
                           stdin=sys.stdin)
  if result != 0:
    raise Exception('Execution of "%s" failed' % ' '.join(cmd))


def Gsutil(*cmd):
  return ExecuteCommand('python', GSUTIL, *cmd)


def GsutilVisible(*cmd):
  ExecuteCommandVisible('python', GSUTIL, *cmd)


def HasBotoConfig():
  """Returns true if boto config exists."""

  config_paths = boto.pyami.config.BotoConfigLocations
  if 'AWS_CREDENTIAL_FILE' in os.environ:
    config_paths.append(os.environ['AWS_CREDENTIAL_FILE'])
  for config_path in config_paths:
    if os.path.exists(config_path):
      return True

  return False


def InRunhooks():
  """True if this script was called by "gclient runhooks" or "gclient sync\""""
  return 'runhooks' in sys.argv


def GetDartiumRevision(name, bot, directory, version_file, latest_pattern,
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

  def FindPermanentUrl(out, osname, the_revision_num):
    output_lines = out.split()
    latest = output_lines[-1]
    if not the_revision_num:
      latest = (permanent_prefix[:permanent_prefix.rindex('/')] % { 'osname' :
          osname, 'bot' : bot } + latest[latest.rindex('/'):])
    else:
      latest = (permanent_prefix % { 'osname' : osname, 'num1' : the_revision_num,
          'num2' : the_revision_num, 'bot' : bot })
      foundURL = False
      while not foundURL:
        # Test to ensure this URL exists because the dartium-archive builds can
        # have unusual numbering (a range of CL numbers) sometimes.
        result, out = Gsutil('ls', permanent_prefix % {'osname' : osname,
            'num1': the_revision_num, 'num2': '*', 'bot': bot })
        if result == 0:
          # First try to find one with the the second number the same as the
          # requested number.
          latest = out.split()[0]
          # Now test that the permissions are correct so you can actually
          # download it.
          temp_dir = tempfile.mkdtemp()
          temp_zip = os.path.join(temp_dir, 'foo.zip')
          returncode, out = Gsutil('cp', latest, 'file://' + temp_zip)
          if returncode == 0:
            foundURL = True
          else:
            # Unable to download this item (most likely because something went
            # wrong on the upload and the permissions are bad). Keep looking for
            # a different URL.
            the_revision_num = int(the_revision_num) - 1
          shutil.rmtree(temp_dir)
        else:
          # Now try to find one with a nearby CL num.
          the_revision_num = int(the_revision_num) - 1
          if the_revision_num <= 0:
            TooEarlyError()
    return latest

  GetFromGsutil(name, directory, version_file, latest_pattern, osdict,
                  FindPermanentUrl, revision_num, bot)


def GetSdkRevision(name, directory, version_file, latest_pattern,
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
  def FindPermanentUrl(out, osname, not_used):
    rev_num = revision_num
    if not rev_num:
      temp_file = tempfile.NamedTemporaryFile(delete=False)
      temp_file.close()
      temp_file_url = 'file://' + temp_file.name
      Gsutil('cp', latest_pattern % {'osname' : osname }, temp_file_url)
      temp_file = open(temp_file.name)
      temp_file.seek(0)
      version_info = temp_file.read()
      temp_file.close()
      os.unlink(temp_file.name)
      if version_info != '':
        rev_num = json.loads(version_info)['revision']
      else:
        print 'Unable to get latest version information.'
        return ''
    latest = (permanent_prefix % { 'osname' : osname, 'version_num': rev_num})
    return latest

  GetFromGsutil(name, directory, version_file, latest_pattern, osdict,
                  FindPermanentUrl, revision_num)


def GetFromGsutil(name, directory, version_file, latest_pattern,
    os_name_dict, get_permanent_url, revision_num = '', bot = None):
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

  # Query for the latest version
  pattern = latest_pattern  % { 'osname' : osname, 'bot' : bot }
  result, out = Gsutil('ls', pattern)
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
      if not InRunhooks():
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
    GsutilVisible('cp', latest, temp_zip_url)

    if platform.system() != 'Windows':
      # The Python zip utility does not preserve executable permissions, but
      # this does not seem to be a problem for Windows, which does not have a
      # built in zip utility. :-/
      result, out = ExecuteCommand('unzip', temp_zip, '-d', temp_dir)
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
    if os.path.exists(directory):
      raise Exception(
          'Removal of directory %s failed. Is the executable running?' %
          directory)
    shutil.move(unzipped_dir, directory)
  finally:
    shutil.rmtree(temp_dir)

  # create the version stamp
  v = open(version_file, 'w')
  v.write(latest)
  v.close()

  print 'Successfully downloaded to %s' % directory
  return 0


def TooEarlyError():
  """Quick shortcutting function, to return early if someone requests a revision
  that is smaller than the earliest stored. This saves us from doing repeated
  requests until we get down to 0."""
  print ('Unable to download requested revision because it is earlier than the '
      'earliest revision stored.')
  sys.exit(1)


def CopyDrtFont(drt_dir):
  if platform.system() != 'Windows':
    return
  shutil.copy('third_party/drt_resources/AHEM____.TTF', drt_dir)


def main():
  parser = optparse.OptionParser(usage='usage: %prog [options] download_name')
  parser.add_option('-r', '--revision', dest='revision',
                    help='Desired revision number to retrieve for the SDK. If '
                    'unspecified, retrieve the latest SDK build.',
                    action='store', default=None)
  parser.add_option('-d', '--debug', dest='debug',
                    help='Download a debug archive instead of a release.',
                    action='store_true', default=False)
  args, positional = parser.parse_args()

  if args.revision and int(args.revision) < LAST_VALID[positional[0]]:
    return TooEarlyError()

  # Use the incremental release bot ('dartium-*-inc-be') by default.
  # Issue 13399 Quick fix, update with channel support.
  bot = 'inc-be'
  if args.debug:
    bot = 'debug-be'

  if positional[0] == 'dartium':
    GetDartiumRevision('Dartium', bot, DARTIUM_DIR, DARTIUM_VERSION,
                         DARTIUM_LATEST_PATTERN, DARTIUM_PERMANENT_PATTERN,
                         args.revision)
  elif positional[0] == 'sdk':
    GetSdkRevision('sdk', SDK_DIR, SDK_VERSION, SDK_LATEST_PATTERN,
        SDK_PERMANENT, args.revision)
  elif positional[0] == 'drt':
    GetDartiumRevision('content_shell', bot, DRT_DIR, DRT_VERSION,
                         DRT_LATEST_PATTERN, DRT_PERMANENT_PATTERN,
                         args.revision)
    CopyDrtFont(DRT_DIR)
  else:
    print ('Please specify the target you wish to download from Google Storage '
        '("drt", "dartium", "chromedriver", or "sdk")')

if __name__ == '__main__':
  sys.exit(main())
