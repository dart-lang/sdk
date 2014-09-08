#!/usr/bin/env python
#
# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Gets a Chromium archived build, and unpacks it
   into a target directory.

  Use -r option to specify the revison number
  Use -t option to specify the directory to unzip the build into.

Usage:
  $ get_chromium_build.py -r <revision> -t <target>
"""

import logging
import optparse
import os
import platform
import shutil
import subprocess
import sys
import time
import urllib
import urllib2
import zipfile

# Example chromium build location:
# gs://chromium-browser-snapshots/Linux_x64/228977/chrome-linux.zip
CHROMIUM_URL_FMT = ('http://commondatastorage.googleapis.com/'
                    'chromium-browser-snapshots/%s/%s/%s')

class BuildUpdater(object):
  _PLATFORM_PATHS_MAP = {
      'Linux': { 'zipfiles': ['chrome-linux.zip'],
                 'folder': 'chrome_linux',
                 'archive_path': 'Linux_x64'},
      'Darwin': {'zipfiles': ['chrome-mac.zip'],
                 'folder': 'chrome_mac',
                 'archive_path': 'Mac'},
      'Windows': {'zipfiles': ['chrome-win32.zip',
                               'chrome-win32-syms.zip'],
                 'folder': 'chrome_win',
                 'archive_path': 'Win'}}

  def __init__(self, options):
    platform_data = BuildUpdater._PLATFORM_PATHS_MAP[platform.system()]
    self._zipfiles = platform_data['zipfiles']
    self._folder = platform_data['folder']
    self._archive_path = platform_data['archive_path']
    self._revision = int(options.revision)
    self._target_dir = options.target_dir
    self._download_dir = os.path.join(self._target_dir, 'downloads')

  def _GetBuildUrl(self, revision, filename):
    return CHROMIUM_URL_FMT % (self._archive_path, revision, filename)

  def _FindBuildRevision(self, revision, filename):
    MAX_REVISIONS_PER_BUILD = 100
    for revision_guess in xrange(revision, revision + MAX_REVISIONS_PER_BUILD):
      if self._DoesBuildExist(revision_guess, filename):
        return revision_guess
      else:
        time.sleep(.1)
    return None

  def _DoesBuildExist(self, revision_guess, filename):
    url = self._GetBuildUrl(revision_guess, filename)

    r = urllib2.Request(url)
    r.get_method = lambda: 'HEAD'
    try:
      urllib2.urlopen(r)
      return True
    except urllib2.HTTPError, err:
      if err.code == 404:
        return False

  def _DownloadBuild(self):
    if not os.path.exists(self._download_dir):
      os.makedirs(self._download_dir)
    for zipfile in self._zipfiles:
      build_revision = self._FindBuildRevision(self._revision, zipfile)
      if not build_revision:
        logging.critical('Failed to find %s build for r%s\n',
                         self._archive_path,
                         self._revision)
        sys.exit(1)
      url = self._GetBuildUrl(build_revision, zipfile)
      logging.info('Downloading %s', url)
      r = urllib2.urlopen(url)
      with file(os.path.join(self._download_dir, zipfile), 'wb') as f:
        f.write(r.read())

  def _UnzipFile(self, dl_file, dest_dir):
    if not zipfile.is_zipfile(dl_file):
      return False
    logging.info('Unzipping %s', dl_file)
    with zipfile.ZipFile(dl_file, 'r') as z:
      for content in z.namelist():
        dest = os.path.join(dest_dir, content[content.find('/')+1:])
        # Create dest parent dir if it does not exist.
        if not os.path.isdir(os.path.dirname(dest)):
          logging.info('Making %s', dest)
          os.makedirs(os.path.dirname(dest))
        # If dest is just a dir listing, do nothing.
        if not os.path.basename(dest):
          continue
        with z.open(content) as unzipped_content:
          logging.info('Extracting %s to %s (%s)', content, dest, dl_file)
          with file(dest, 'wb') as dest_file:
            dest_file.write(unzipped_content.read())
          permissions = z.getinfo(content).external_attr >> 16
          if permissions:
            os.chmod(dest, permissions)
    return True

  def _ClearDir(self, dir):
    """Clears all files in |dir| except for hidden files and folders."""
    for root, dirs, files in os.walk(dir):
      # Skip hidden files and folders (like .svn and .git).
      files = [f for f in files if f[0] != '.']
      dirs[:] = [d for d in dirs if d[0] != '.']

      for f in files:
        os.remove(os.path.join(root, f))

  def _ExtractBuild(self):
    dest_dir = os.path.join(self._target_dir, self._folder)
    self._ClearDir(dest_dir)
    for root, _, dl_files in os.walk(os.path.join(self._download_dir)):
      for dl_file in dl_files:
        dl_file = os.path.join(root, dl_file)
        if not self._UnzipFile(dl_file, dest_dir):
          logging.info('Copying %s to %s', dl_file, dest_dir)
          shutil.copy(dl_file, dest_dir)
    shutil.rmtree(self._download_dir)

  def DownloadAndUpdateBuild(self):
    self._DownloadBuild()
    self._ExtractBuild()


def ParseOptions(argv):
  parser = optparse.OptionParser()
  usage = 'usage: %prog <options>'
  parser.set_usage(usage)
  parser.add_option('-r', dest='revision',
                    help='Revision to download.')
  parser.add_option('-t', dest='target_dir',
                    help='Target directory for unzipped Chromium.')

  (options, _) = parser.parse_args(argv)
  if not options.revision:
    logging.critical('Must specify -r.\n')
    sys.exit(1)
  if not options.target_dir:
    logging.critical('Must specify -t.\n')
    sys.exit(1)
  return options

def main(argv):
  logging.getLogger().setLevel(logging.DEBUG)
  options = ParseOptions(argv)
  b = BuildUpdater(options)
  b.DownloadAndUpdateBuild()
  logging.info('Successfully got archived Chromium build.')

if __name__ == '__main__':
  sys.exit(main(sys.argv))
