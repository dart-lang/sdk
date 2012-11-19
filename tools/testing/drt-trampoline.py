# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# For now we have to use this trampoline to turn --dart-flags command line
# switch into env variable DART_FLAGS.  Eventually, DumpRenderTree should
# support --dart-flags and this hack may go away.
#
# Expected invocation: python drt-trampoline.py <path to DRT> <DRT command line>

import optparse
import os
import signal
import subprocess
import sys

def parse_options(argv):
  parser = optparse.OptionParser()
  parser.add_option('--dart-flags',
                    metavar='FLAGS',
                    dest='dart_flags')
  parser.add_option('--out-expectation',
                    metavar='FILE',
                    dest='out_expected_file')
  parser.add_option('--package-root',
                    metavar='DIRECTORY',
                    dest='dart_package_root')
  parser.add_option('--no-timeout',
                    action='store_true')
  return parser.parse_args(args=argv)


def main(argv):
  drt_path = argv[1]
  (options, arguments) = parse_options(argv[2:])

  cmd = [drt_path]

  env = None
  test_file = None
  dart_flags = options.dart_flags
  out_expected_file = options.out_expected_file
  dart_package_root = options.dart_package_root
  is_png = False

  if dart_flags:
    if not env:
      env = dict(os.environ.items())
    env['DART_FLAGS'] = dart_flags

  if dart_package_root:
    if not env:
      env = dict(os.environ.items())
    absolute_path = os.path.abspath(dart_package_root)
    absolute_path = absolute_path.replace(os.path.sep, '/')
    if not absolute_path.startswith('/'):
      # Happens on Windows for C:\packages
      absolute_path = '/%s' % absolute_path
    env['DART_PACKAGE_ROOT'] = 'file://%s' % absolute_path

  if out_expected_file:
    if out_expected_file.endswith('.png'):
      cmd.append('--notree')
      is_png = True
    elif not out_expected_file.endswith('.txt'):
      raise Exception(
        'Bad file expectation (%s) please specify either a .txt or a .png file'
        % out_expected_file)

  if options.no_timeout:
    cmd.append('--no-timeout')

  for arg in arguments:
    if '.html' in arg:
      test_file = arg
    else:
      cmd.append(arg)

  if is_png:
    # pixel tests are specified by running DRT "foo.html'-p"
    cmd.append(test_file + "'-p")
  else:
    cmd.append(test_file)

  stdout = subprocess.PIPE if out_expected_file else None
  p = subprocess.Popen(cmd, env=env, stdout=stdout)

  def signal_handler(signal, frame):
    p.terminate()
    sys.exit(0)

  # SIGINT is Ctrl-C.
  signal.signal(signal.SIGINT, signal_handler)
  # SIGTERM is sent by test.dart when a process times out.
  signal.signal(signal.SIGTERM, signal_handler)
  output, error = p.communicate()
  signal.signal(signal.SIGINT, signal.SIG_DFL)
  signal.signal(signal.SIGTERM, signal.SIG_DFL)

  if p.returncode != 0:
    raise Exception('Failed to run command. return code=%s' % p.returncode)

  if out_expected_file:
    # Compare output to the given expectation file.
    expectation = None
    if is_png:
      # DRT prints the image to STDOUT, but includes extra text that we trim:
      # - several header lines until a line saying 'Content-Length:'
      # - a '#EOF\n' at the end
      last_header_line = output.find('Content-Length:')
      start_pos = output.find('\n', last_header_line) + 1
      output = output[start_pos : -len('#EOF\n')]
    if os.path.exists(out_expected_file):
      with open(out_expected_file, 'r') as f:
        expectation = f.read()
    else:
      # Instructions on how to create the expectation will be printed below
      # (outout != expectation)
      print 'File %s was not found' % out_expected_file
      expectation = None

    # Report test status using the format test.dart expects to see from DRT.
    print 'Content-Type: text/plain'
    if expectation == output:
      print 'PASS'
      print 'Expectation matches'
    else:
      # Generate a temporary file in the same place as the .html file:
      out_file = test_file[:test_file.rfind('.html')] + out_expected_file[-4:]
      with open(out_file, 'w') as f:
        f.write(output)
      print 'FAIL'
      print 'Expectation didn\'t match.\n'
      if len(output) == 0:
        print ('\033[31mERROR\033[0m: DumpRenderTree generated an empty pixel '
            'output! This is commonly an error in executing DumpRenderTree, and'
            ' not that expectations are out of date.\n')
      print 'You can update expectations by running:\n'
      print 'cp %s %s\n' % (out_file, out_expected_file)
    print '#EOF'

if __name__ == '__main__':
  try:
    sys.exit(main(sys.argv))
  except StandardError as e:
    print 'Fail: ' + str(e)
    sys.exit(1)
