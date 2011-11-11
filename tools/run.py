#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""
Runs a Dart unit test in different configurations: dartium, chromium, ia32, x64,
arm, simarm, and dartc. Example:

run.py --arch=dartium --mode=release --test=Test.dart
"""

import optparse
import sys

from testing import architecture
import utils


def AreOptionsValid(options):
  if not options.arch in ['ia32', 'x64', 'arm', 'simarm', 'dartc', 'dartium',
                          'chromium', 'frogium']:
    print 'Unknown arch %s' % options.arch
    return None

  return options.test


def Flags():
  result = optparse.OptionParser()
  result.add_option("-v", "--verbose",
      help="Print messages",
      default=False,
      action="store_true")
  result.add_option("-t", "--test",
      help="App or Dart file containing the test",
      type="string",
      action="store",
      default=None)
  result.add_option("--arch",
      help="The architecture to run tests for",
      metavar="[ia32,x64,arm,simarm,dartc,chromium,dartium]",
      default=utils.GuessArchitecture())
  result.add_option("-m", "--mode",
      help="The test modes in which to run",
      metavar='[debug,release]',
      default='debug')
  result.set_usage("run.py --arch ARCH --mode MODE -t TEST")
  return result


def Main():
  parser = Flags()
  (options, args) = parser.parse_args()
  if not AreOptionsValid(options):
    parser.print_help()
    return 1

  return architecture.GetArchitecture(options.arch, options.mode,
      options.test).RunTest(options.verbose)


if __name__ == '__main__':
  sys.exit(Main())
