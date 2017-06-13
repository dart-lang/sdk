#!/usr/bin/env python
#
# Copyright 2011 Google Inc. All Rights Reserved.

import fnmatch
import optparse
import os
import re
import shutil
import subprocess
import sys
import urllib
import utils

SCRIPT_TAG = '<script type="application/%s" src="%s"></script>\n'

DART_TEST_DIR = os.path.join('dart')

DART_VM_FLAGS = [
    ]
DART_VM_CHECKED_FLAGS = DART_VM_FLAGS + [
    '--enable_type_checks',
    '--warning_as_error',
    ]

TEST_DRT_FLAGS = [
    '--compiler=none',
    '--runtime=drt',
    '--drt=%(drt)s',
    '--mode=%(mode)s',
    '--arch=%(arch)s',
    '--build-directory=%(build_dir)s',
    '--report',
    '--time',
    ]

TEST_DRT_CHECKED_FLAGS = TEST_DRT_FLAGS + [
    '--checked',
    ]

TEST_DARTIUM_FLAGS = [
    '--compiler=none',
    '--runtime=dartium',
    '--dartium=%(dartium)s',
    '--mode=%(mode)s',
    '--build-directory=%(build_dir)s',
    '--report',
    '--time',
    ]

TEST_DARTIUM_CHECKED_FLAGS = TEST_DARTIUM_FLAGS + [
    '--checked',
    ]

TEST_INFO = {
    'dartium': {
        'core': {
            'checked': TEST_DARTIUM_CHECKED_FLAGS,
            'unchecked': TEST_DARTIUM_FLAGS,
        },
    },
    'drt': {
        'layout': {
            'checked': DART_VM_CHECKED_FLAGS,
            'unchecked': DART_VM_FLAGS,
        },
        'core': {
            'checked': TEST_DRT_CHECKED_FLAGS,
            'unchecked': TEST_DRT_FLAGS,
        },
    },
}

COMPONENTS = TEST_INFO.keys()
SUITES = [ 'layout', 'core' ]

def main():
  parser = optparse.OptionParser()
  parser.add_option('--mode', dest='mode',
                    action='store', type='string',
                    help='Test mode (Debug or Release)')
  parser.add_option('--component', dest='component',
                    default='drt',
                    action='store', type='string',
                    help='Execution mode (dartium, drt or all)')
  parser.add_option('--suite', dest='suite',
                    default='all',
                    action='store', type='string',
                    help='Test suite (layout, core, or all)')
  parser.add_option('--arch', dest='arch',
                    default='ia32',
                    action='store', type='string',
                    help='Target architecture')
  parser.add_option('--no-show-results', action='store_false',
                    default=True, dest='show_results',
                    help='Don\'t launch a browser with results '
                    'after the tests are done')
  parser.add_option('--checked', action='store_true',
                    default=False, dest='checked',
                    help='Run Dart code in checked mode')
  parser.add_option('--unchecked', action='store_true',
                    default=False, dest='unchecked',
                    help='Run Dart code in unchecked mode')
  parser.add_option('--buildbot', action='store_true',
                    default=False, dest='buildbot',
                    help='Print results in buildbot format')
  parser.add_option('--layout-test', dest='layout_test',
                    default=None,
                    action='store', type='string',
                    help='Single layout test to run if set')
  parser.add_option('--test-filter', dest='test_filter',
                    default=None,
                    action='store', type='string',
                    help='Test filter for core tests')

  (options, args) = parser.parse_args()
  mode = options.mode
  if not (mode in ['Debug', 'Release']):
    raise Exception('Invalid test mode')

  if options.component == 'all':
    components = COMPONENTS
  elif not (options.component in COMPONENTS):
    raise Exception('Invalid component %s' % options.component)
  else:
    components = [ options.component ]

  if options.suite == 'all':
    suites = SUITES
  elif not (options.suite in SUITES):
    raise Exception('Invalid suite %s' % options.suite)
  else:
    suites = [ options.suite ]

  # If --checked or --unchecked not present, run with both.
  checkmodes = ['unchecked', 'checked']
  if options.checked or options.unchecked:
    checkmodes = []
    if options.unchecked: checkmodes.append('unchecked')
    if options.checked: checkmodes.append('checked')

  # We are in src/dart/tools/dartium/test.py.
  pathname = os.path.dirname(sys.argv[0])
  fullpath = os.path.abspath(pathname)
  srcpath = os.path.normpath(os.path.join(fullpath, '..', '..', '..'))

  test_mode = ''
  timeout = 30000
  if mode == 'Debug':
    test_mode = '--debug'
    timeout = 60000

  show_results = ''
  if not options.show_results:
    show_results = '--no-show-results'

  host_os = utils.guessOS()
  build_root, drt_path, dartium_path, dart_path  = {
      'mac': (
        'out',
        os.path.join('Content Shell.app', 'Contents', 'MacOS', 'Content Shell'),
        os.path.join('Chromium.app', 'Contents', 'MacOS', 'Chromium'),
        'dart',
      ),
      'linux': ('out', 'content_shell', 'chrome', 'dart'),
      'win': ('out', 'content_shell.exe', 'chrome.exe', 'dart.exe'),
  }[host_os]

  build_dir = os.path.join(srcpath, build_root, mode)

  executable_map = {
    'mode': mode.lower(),
    'build_dir': os.path.relpath(build_dir),
    'drt': os.path.join(build_dir, drt_path),
    'dartium': os.path.join(build_dir, dartium_path),
    'dart': os.path.join(build_dir, dart_path),
    'arch': options.arch,
  }

  test_script = os.path.join(srcpath, 'third_party', 'WebKit', 'Tools', 'Scripts', 'run-webkit-tests')

  errors = False
  for component in components:
    for checkmode in checkmodes:
      # Capture errors and report at the end.
      try:
        if ('layout' in suites and
            'layout' in TEST_INFO[component] and
            checkmode in TEST_INFO[component]['layout']):
          # Run layout tests in this mode
          dart_flags = ' '.join(TEST_INFO[component]['layout'][checkmode])

          if options.layout_test:
            test = os.path.join(DART_TEST_DIR, options.layout_test)
          else:
            test = DART_TEST_DIR

          utils.runCommand(['python',
                            test_script,
                            test_mode,
                            show_results,
                            '--time-out-ms', str(timeout),
                            # Temporary hack to fix issue with svn vs. svn.bat.
                            '--builder-name', 'BuildBot',
                            '--additional-env-var',
                            'DART_FLAGS=%s' % dart_flags,
                            test])

        # Run core dart tests
        if ('core' in suites and
            'core' in TEST_INFO[component] and
            checkmode in TEST_INFO[component]['core']):
          core_flags = TEST_INFO[component]['core'][checkmode]
          core_flags = map(lambda flag: flag % executable_map, core_flags)
          if options.buildbot:
            core_flags = ['--progress=buildbot'] + core_flags
          tester = os.path.join(srcpath, 'dart', 'tools', 'test.py')
          test_filter = [options.test_filter] if options.test_filter else []
          utils.runCommand(['python', tester] + core_flags + test_filter)
      except (StandardError, Exception) as e:
        print 'Fail: '  + str(e)
        errors = True

  if errors:
    return 1
  else:
    return 0

if __name__ == '__main__':
  try:
    sys.exit(main())
  except StandardError as e:
    print 'Fail: ' + str(e)
    sys.exit(1)
