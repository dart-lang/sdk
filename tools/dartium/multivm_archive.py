#!/usr/bin/python

# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Archive builds from the multivm and dartium perf builders

Archive dartium, content_shell, and chromedriver to the old cloud storage bucket
gs://dartium-archive.
"""

import os
import platform
import re
import subprocess
import sys

import dartium_bot_utils
import upload_steps

SRC_PATH = dartium_bot_utils.srcPath()

def main():
  if (upload_steps.BuildInfo('', '').channel == 'be'):
    revision = sys.argv[1]
  else:
    multivm_deps = os.path.join(os.path.dirname(SRC_PATH), 'multivm.deps')
    revision_directory = (multivm_deps if (os.path.isdir(multivm_deps))
                                       else os.path.join(SRC_PATH, 'dart'))
    output, _ = subprocess.Popen(['svn', 'info'],
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT,
                                 shell=(platform.system() == 'Windows'),
                                 cwd=revision_directory).communicate()
    revision = re.search('Last Changed Rev: (\d+)', output).group(1)

  version = revision + '.0'
  info = upload_steps.BuildInfo(version, revision)
  if info.is_build:
    upload_steps.ArchiveAndUpload(info, archive_latest=False)

if __name__ == '__main__':
  sys.exit(main())
