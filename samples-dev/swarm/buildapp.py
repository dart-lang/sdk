# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

#!/usr/bin/env python
#

# This script builds a Chrome App file (.crx) for Swarm
import os
import platform
import subprocess
import sys

DART_PATH = os.path.normpath(os.path.dirname(__file__) + '/../../..')
CLIENT_PATH = os.path.normpath(DART_PATH + '/client')

# Add the tools directory so we can find utils.py.
sys.path.append(os.path.abspath(DART_PATH + '/tools'))
import utils

buildRoot = CLIENT_PATH + '/' + utils.GetBuildRoot(utils.GuessOS(), 'debug',
                                                   'dartc')


def execute(*command):
    '''
  Executes the given command in a new process. If the command fails (returns
  non-zero) halts the script and returns that exit code.
  '''
    exitcode = subprocess.call(command)
    if exitcode != 0:
        sys.exit(exitcode)


def createChromeApp(buildRoot, antTarget, resultFile):
    buildDir = os.path.join(buildRoot, 'war')

    # Use ant to create the 'war' directory
    # TODO(jmesserly): we should factor out as much as possible from the ant file
    # It's not really doing anything useful for us besides compiling Dart code
    # with DartC and copying files. But for now, it helps us share code with
    # our appengine update.py, which is good.
    execute(DART_PATH + '/third_party/apache_ant/v1_7_1/bin/ant', '-f',
            'build-appengine.xml', '-Dbuild.dir=' + buildRoot, antTarget)

    # Call Dartium (could be any Chrome--but we know Dartium will be there) and
    # ask it to create the .crx file for us using the checked in developer key.
    chrome = CLIENT_PATH + '/tests/drt/chrome'

    # On Mac Chrome is under a .app folder
    if platform.system() == 'Darwin':
        chrome = CLIENT_PATH + '/tests/drt/Chromium.app/Contents/MacOS/Chromium'

    keyFile = DART_PATH + '/samples/swarm/swarm-dev.pem'
    execute(chrome, '--pack-extension=' + buildDir,
            '--pack-extension-key=' + keyFile)

    resultFile = os.path.join(buildRoot, resultFile)
    os.rename(buildDir + '.crx', resultFile)
    return os.path.abspath(resultFile)


def main():
    # Create a DartC and Dartium app
    dartiumResult = createChromeApp(buildRoot, 'build_dart_app', 'swarm.crx')
    dartCResult = createChromeApp(buildRoot, 'build_js_app', 'swarm-js.crx')

    print '''
Successfully created Chrome apps!
  Dartium:  file://%s

  DartC/JS: file://%s

To install, open this URL in Chrome and select Continue at the bottom.
''' % (dartiumResult, dartCResult)
    return 0


if __name__ == '__main__':
    sys.exit(main())
