#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Dart Editor promote tools.

import imp
import optparse
import os
import subprocess
import sys
import time
import urllib
import bots.bot_utils as bot_utils

from os.path import join

DART_PATH = os.path.abspath(os.path.join(__file__, '..', '..'))
DRY_RUN = False

def BuildOptions():
  usage = """usage: %prog promote [options]
  where:
    promote - Will promote builds from raw/signed locations to release
              locations.

    Example: Promote revision r29962 on dev channel:
        python editor/build/promote.py promote --channel=dev --revision=29962
  """

  result = optparse.OptionParser(usage=usage)

  group = optparse.OptionGroup(
      result, 'Promote', 'options used to promote code')
  group.add_option(
      '--revision', help='The svn revision to promote', action='store')
  group.add_option(
      '--channel', type='string', help='Channel to promote.', default=None)
  group.add_option("--dry", help='Dry run', default=False, action="store_true")
  result.add_option_group(group)

  return result


def main():
  parser = BuildOptions()
  (options, args) = parser.parse_args()

  def die(msg):
    print msg
    parser.print_help()
    sys.exit(1)

  if not args:
    die('At least one command must be specified')

  if args[0] == 'promote':
    command = 'promote'
    if options.revision is None:
      die('You must specify a --revision to specify which revision to promote')

    # Make sure options.channel is a valid
    if not options.channel:
      die('Specify --channel=be/dev/stable')
    if options.channel not in bot_utils.Channel.ALL_CHANNELS:
      die('You must supply a valid channel to --channel to promote')
  else:
    die('Invalid command specified: {0}.  See help below'.format(args[0]))

  if options.dry:
    global DRY_RUN
    DRY_RUN = True
  if command == 'promote':
    _PromoteDartArchiveBuild(options.channel, options.revision)


def UpdateDocs():
  try:
    print 'Updating docs'
    url = "http://api.dartlang.org/docs/releases/latest/?force_reload=true"
    f = urllib.urlopen(url)
    f.read()
    print 'Successfully updated api docs'
  except Exception as e:
    print 'Could not update api docs, please manually update them'
    print 'Failed with: %s' % e


def _PromoteDartArchiveBuild(channel, revision):
  # These namer objects will be used to create GCS object URIs. For the
  # structure we use, please see tools/bots/bot_utils.py:GCSNamer
  raw_namer = bot_utils.GCSNamer(channel, bot_utils.ReleaseType.RAW)
  signed_namer = bot_utils.GCSNamer(channel, bot_utils.ReleaseType.SIGNED)
  release_namer = bot_utils.GCSNamer(channel, bot_utils.ReleaseType.RELEASE)

  def promote(to_revision):
    def safety_check_on_gs_path(gs_path, revision, channel):
      if not (revision != None
              and len(channel) > 0
              and ('%s' % revision) in gs_path
              and channel in gs_path):
        raise Exception(
            "InternalError: Sanity check failed on GS URI: %s" % gs_path)

    # Google cloud storage has read-after-write, read-after-update,
    # and read-after-delete consistency, but not list after delete consistency.
    # Because gsutil uses list to figure out if it should do the unix styly
    # copy to or copy into, this means that if the directory is reported as
    # still being there (after it has been deleted) gsutil will copy
    # into the directory instead of to the directory.
    def wait_for_delete_to_be_consistent_with_list(gs_path):
      while True:
        if DRY_RUN:
          break
        (_, _, exit_code) = Gsutil(['ls', gs_path], throw_on_error=False)
        # gsutil will exit 1 if the "directory" does not exist
        if exit_code != 0:
          break
        time.sleep(1)

    def remove_gs_directory(gs_path):
      safety_check_on_gs_path(gs_path, to_revision, channel)
      Gsutil(['-m', 'rm', '-R', '-f', gs_path])
      wait_for_delete_to_be_consistent_with_list(gs_path)

    # Copy sdk directory.
    from_loc = raw_namer.sdk_directory(revision)
    to_loc = release_namer.sdk_directory(to_revision)
    remove_gs_directory(to_loc)
    Gsutil(['-m', 'cp', '-a', 'public-read', '-R', from_loc, to_loc])

    # Copy api-docs zipfile.
    from_loc = raw_namer.apidocs_zipfilepath(revision)
    to_loc = release_namer.apidocs_zipfilepath(to_revision)
    Gsutil(['-m', 'cp', '-a', 'public-read', from_loc, to_loc])

    # Copy wheezy linux deb and src packages.
    from_loc = raw_namer.linux_packages_directory(revision)
    to_loc = release_namer.linux_packages_directory(to_revision)
    remove_gs_directory(to_loc)
    Gsutil(['-m', 'cp', '-a', 'public-read', '-R', from_loc, to_loc])

    # Copy VERSION file.
    from_loc = raw_namer.version_filepath(revision)
    to_loc = release_namer.version_filepath(to_revision)
    Gsutil(['cp', '-a', 'public-read', from_loc, to_loc])

  promote(revision)
  promote('latest')

def Gsutil(cmd, throw_on_error=True):
  gsutilTool = join(DART_PATH, 'third_party', 'gsutil', 'gsutil')
  command = [sys.executable, gsutilTool] + cmd
  if DRY_RUN:
    print "DRY runnning: %s" % command
    return
  return bot_utils.run(command, throw_on_error=throw_on_error)


if __name__ == '__main__':
  sys.exit(main())
