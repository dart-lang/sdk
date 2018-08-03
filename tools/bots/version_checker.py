#!/usr/bin/python

# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import json
import re
import sys

import bot
import bot_utils

utils = bot_utils.GetUtils()

VERSION_BUILDER = r'versionchecker'

def VersionConfig(name, is_buildbot):
  version_pattern = re.match(VERSION_BUILDER, name)
  if not version_pattern:
      return None
  # We don't really use this, but we create it anyway to use the standard
  # bot execution model.
  return bot.BuildInfo('none', 'none', 'release', 'linux')

def GetLatestVersionFromGCS(channel):
  namer = bot_utils.GCSNamer(channel=channel)
  gsutil = bot_utils.GSUtil()
  gcs_version_path = namer.version_filepath('latest')
  print 'Getting latest version from: %s' % gcs_version_path
  version_json = gsutil.cat(gcs_version_path)
  version_map = json.loads(version_json)
  return version_map['version']

def ValidateChannelVersion(latest_version, channel):
  repo_version = utils.ReadVersionFile()
  assert repo_version.channel == channel
  if channel == bot_utils.Channel.STABLE:
    assert int(repo_version.prerelease) == 0
    assert int(repo_version.prerelease_patch) == 0

  version_re = r'(\d+)\.(\d+)\.(\d+)(-dev\.(\d+)\.(\d+))?'

  latest_match = re.match(version_re, latest_version)
  latest_major = int(latest_match.group(1))
  latest_minor = int(latest_match.group(2))
  latest_patch = int(latest_match.group(3))
  # We don't use these on stable.
  latest_prerelease = int(latest_match.group(5) or 0)
  latest_prerelease_patch = int(latest_match.group(6) or 0)

  if latest_major < int(repo_version.major):
    return True
  if latest_minor < int(repo_version.minor):
    return True
  if latest_patch < int(repo_version.patch):
    return True
  if latest_prerelease < int(repo_version.prerelease):
    return True
  if latest_prerelease_patch < int(repo_version.prerelease_patch):
    return True
  return False

def VersionSteps(build_info):
  with bot.BuildStep('Version file sanity checking'):
    bot_name, _ = bot.GetBotName()
    channel = bot_utils.GetChannelFromName(bot_name)
    if channel == bot_utils.Channel.BLEEDING_EDGE:
      print 'No sanity checking on bleeding edge'
    else:
      assert (channel == bot_utils.Channel.STABLE or
              channel == bot_utils.Channel.DEV)
      latest_version = GetLatestVersionFromGCS(channel)
      version = utils.GetVersion()
      print 'Latests version on GCS: %s' % latest_version
      print 'Version currently building: %s' % version
      if not ValidateChannelVersion(latest_version, channel):
        print "Validation failed"
        sys.exit(1)
      else:
        print 'Version file changed, sanity checks passed'

if __name__ == '__main__':
  # We pass in None for build_step to avoid building.
  bot.RunBot(VersionConfig, VersionSteps, build_step=None)
