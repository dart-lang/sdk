#!/usr/bin/env python
#
# Copyright 2010 Google Inc. All Rights Reserved.

# This file is used by the buildbot.

import optparse
import os.path
import utils

ALL_TARGETS = [
    'content_shell',
    'chrome',
    'blink_tests',
    'chromedriver'
]

def main():
  parser = optparse.OptionParser()
  parser.add_option('--target', dest='target',
                    default='all',
                    action='store', type='string',
                    help='Target (%s)' % ', '.join(ALL_TARGETS))
  parser.add_option('--mode', dest='mode',
                    action='store', type='string',
                    help='Build mode (Debug or Release)')
  parser.add_option('--clobber', dest='clobber',
                    action='store_true',
                    help='Clobber the output directory')
  parser.add_option('-j', '--jobs', dest='jobs',
                    action='store',
                    help='Number of jobs')
  (options, args) = parser.parse_args()
  mode = options.mode
  if options.jobs:
    jobs = options.jobs
  else:
    jobs = utils.guessCpus()
  if not (mode in ['Debug', 'Release']):
    raise Exception('Invalid build mode')

  if options.target == 'all':
    targets = ALL_TARGETS
  else:
    targets = [options.target]

  if options.clobber:
    utils.runCommand(['rm', '-rf', 'out'])

  utils.runCommand(['ninja',
                    '-j%s' % jobs,
                    '-C',
                    os.path.join('out', mode)]
                    + targets)

if __name__ == '__main__':
  main()
