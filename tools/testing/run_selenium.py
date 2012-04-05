#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""Script to actually open a browser and perform the test, and reports back with
the result. It uses Selenium WebDriver when possible for running the tests. It
uses Selenium RC for Safari.

If started with --batch this script runs a batch of in-browser tests in
the same browser process.

Normal mode:
$ python run_selenium.py --browser=ff --timeout=60 path/to/test.html

Exit code indicates pass or fail

Batch mode:
$ python run_selenium.py --batch
stdin:  --browser=ff --timeout=60 path/to/test.html
stdout: >>> TEST PASS
stdin:  --browser=ff --timeout=60 path/to/test2.html
stdout: >>> TEST FAIL
stdin:  --terminate
$
"""

import os
import optparse
import platform
import selenium
from selenium.webdriver.support.ui import WebDriverWait
import shutil
import signal
import socket
import sys
import time

TIMEOUT_ERROR_MSG = 'FAIL (timeout)'

def correctness_test_done(source):
  """Checks if test has completed."""
  return ('PASS' in source) or ('FAIL' in source)

def perf_test_done(source):
  """Tests to see if our performance test is done by printing a score."""
  #This code is written this way to work around a current instability in the
  # python webdriver bindings if you call driver.get_element_by_id.
  #TODO(efortuna): Access these elements in a nicer way using DOM parser.
  string = '<div id="status">'
  index = source.find(string)
  end_index = source.find('</div>', index+1)
  source = source[index + len(string):end_index]
  return 'Score:' in source

def dromaeo_test_done(source):
  """Tests to see if our performance test is done by printing a score."""
  #TODO(efortuna): Access these elements in a nicer way using DOM parser.
  string = '<span class="left">'
  index = source.find(string)
  end_index = source.find('</span>', index+1)
  source = source[index + len(string):end_index]
  return '0:00' in source

# TODO(vsm): Ideally, this wouldn't live in this file.
CONFIGURATIONS = {
    'correctness': correctness_test_done,
    'perf': perf_test_done,
    'dromaeo': dromaeo_test_done
}

def run_test_in_browser(browser, html_out, timeout, mode):
  """Run the desired test in the browser using Selenium 2.0 WebDriver syntax,
  and wait for the test to complete. This is the newer syntax, that currently
  supports Firefox, Chrome, IE, Opera (and some mobile browsers)."""
  if isinstance(browser, selenium.selenium):
    return run_test_in_browser_selenium_rc(browser, html_out, timeout, mode)

  browser.get("file://" + html_out)
  source = ''
  try:
    test_done = CONFIGURATIONS[mode]
    element = WebDriverWait(browser, float(timeout)).until(
        lambda driver: test_done(driver.page_source))
    source = browser.page_source
  except selenium.common.exceptions.TimeoutException:
    source = TIMEOUT_ERROR_MSG
  return source

def run_test_in_browser_selenium_rc(sel, html_out, timeout, mode):
  """ Run the desired test in the browser using Selenium 1.0 syntax, and wait
  for the test to complete. This is used for Safari, since it is not currently
  supported on Selenium 2.0."""
  sel.open('file://' + html_out)
  source = sel.get_html_source()
  end_condition = CONFIGURATIONS[mode]

  elapsed = 0
  while (not end_condition(source)) and elapsed <= timeout:
    sec = .25
    time.sleep(sec)
    elapsed += sec
    source = sel.get_html_source()
  return source

def parse_args(args=None):
  parser = optparse.OptionParser()
  parser.add_option('--out', dest='out',
      help = 'The path for html output file that we will running our test from',
      action = 'store', default = '')
  parser.add_option('--browser', dest='browser',
      help = 'The browser type (default = chrome)',
      action = 'store', default = 'chrome')
  # TODO(efortuna): Put this back up to be more than the default timeout in
  # test.dart. Right now it needs to be less than 60 so that when test.dart
  # times out, this script also closes the browser windows.
  parser.add_option('--timeout', dest = 'timeout',
      help = 'Amount of time (seconds) to wait before timeout', type = 'int',
      action = 'store', default=58)
  parser.add_option('--mode', dest = 'mode',
      help = 'The type of test we are running',
      action = 'store', default='correctness')
  args, ignored = parser.parse_args(args=args)
  return args.out, args.browser, args.timeout, args.mode

def start_browser(browser, html_out):
  if browser == 'chrome':
    # Note: you need ChromeDriver *in your path* to run Chrome, in addition to
    # installing Chrome. Also note that the build bot runs have a different path
    # from a normal user -- check the build logs.
    return selenium.webdriver.Chrome()
  elif browser == 'ff':
    profile = selenium.webdriver.firefox.firefox_profile.FirefoxProfile()
    profile.set_preference('dom.max_script_run_time', 0)
    profile.set_preference('dom.max_chrome_script_run_time', 0)
    return selenium.webdriver.Firefox(firefox_profile=profile)
  elif browser == 'ie' and platform.system() == 'Windows':
    return selenium.webdriver.Ie()
  elif browser == 'safari' and platform.system() == 'Darwin':
    # TODO(efortuna): Ensure our preferences (no pop-up blocking) file is the
    # same (Safari auto-deletes when it has too many "crashes," or in our case,
    # timeouts). Come up with a less hacky way to do this.
    backup_safari_prefs = os.path.dirname(__file__) + '/com.apple.Safari.plist'
    if os.path.exists(backup_safari_prefs):
      shutil.copy(backup_safari_prefs,
           '/Library/Preferences/com.apple.Safari.plist')
    sel = selenium.selenium('localhost', 4444, "*safari", 'file://' + html_out)
    try:
      sel.start()
      return sel
    except socket.error:
      print 'ERROR: Could not connect to Selenium RC server. Are you running' +\
          ' java -jar selenium-server-standalone-*.jar? If not, start ' + \
          'it before running this test.'
      sys.exit(1)
  else:
    raise Exception('Incompatible browser and platform combination.')

def close_browser(browser):
  if browser is None:
    return
  if isinstance(browser, selenium.selenium):
    browser.stop()
    return

  # A timeout exception is thrown if nothing happens within the time limit.
  if browser != 'chrome':
    browser.close()
  try:
    browser.quit()
  except selenium.common.exceptions.WebDriverException:
    # TODO(efortuna): Figure out why this crashes.... and avoid?
    pass

def report_results(mode, source):
  # TODO(vsm): Add a failure check for Dromaeo.
  if mode != 'correctness':
    # We're running a performance test.
    print source.encode('utf8')
    sys.stdout.flush()
    if 'NaN' in source:
      return 1
    else:
      return 0
  else:
    # We're running a correctness test. Mark test as passing if all individual
    # test cases pass.
    if 'FAIL' not in source and 'PASS' in source:
      print 'Content-Type: text/plain\nPASS'
      return 0
    else:
      #The hacky way to get document.getElementById('body').innerHTML for this
      # webpage, without the JavaScript.
      #TODO(efortuna): Access these elements in a nicer way using DOM parser.
      index = source.find('<body>')
      index += len('<body>')
      end_index = source.find('<script')
      print unicode(source[index : end_index]).encode("utf-8")
      return 1


def run_batch_tests():
  '''
  Runs a batch of in-browser tests in the same browser process. Batching
  gives faster throughput and makes tests less subject to browser starting
  flakiness, issues with too many browser processes running, etc.

  When running this function, stdin/stdout is used to communicate with the test
  framework. See BatchRunnerProcess in test_runner.dart for the other side of
  this communication channel

  Example of usage:
  $ python run_selenium.py --batch
  stdin:  --browser=ff --timeout=60 path/to/test.html
  stdout: >>> TEST PASS
  stdin:  --browser=ff --timeout=60 path/to/test2.html
  stdout: >>> TEST FAIL
  stdin:  --terminate
  $
  '''

  print '>>> BATCH START'
  browser = None
  current_browser_name = None

  # TODO(jmesserly): It'd be nice to shutdown gracefully in the event of a
  # SIGTERM. Unfortunately dart:io cannot send SIGTERM, see dartbug.com/1756.
  signal.signal(signal.SIGTERM, lambda number, frame: close_browser(browser))

  try:
    while True:
      line = sys.stdin.readline()
      if line == '--terminate\n':
        break

      html_out, browser_name, timeout, mode = parse_args(line.split())

      # Sanity checks that test.dart is passing flags we can handle.
      if mode != 'correctness':
        print 'Batch test runner not compatible with perf testing'
        return 1
      if browser and current_browser_name != browser_name:
        print('Batch test runner got multiple browsers: %s and %s'
            % (current_browser_name, browser_name))
        return 1

      # Start the browser on the first run
      if browser is None:
        current_browser_name = browser_name
        browser = start_browser(browser_name, html_out)

      source = run_test_in_browser(browser, html_out, timeout, mode)

      # Test is done. Write end token to stderr and flush.
      sys.stderr.write('>>> EOF STDERR\n')
      sys.stderr.flush()

      # print one of:
      # >>> TEST {PASS, FAIL, OK, CRASH, FAIL, TIMEOUT}
      status = report_results(mode, source)
      if status == 0:
        print '>>> TEST PASS'
      elif source == TIMEOUT_ERROR_MSG:
        print '>>> TEST TIMEOUT'
      else:
        print '>>> TEST FAIL'
      sys.stdout.flush()
  finally:
    close_browser(browser)


def main(args):
  # Run in batch mode if the --batch flag is passed.
  # TODO(jmesserly): reconcile with the existing args parsing
  if '--batch' in args:
    return run_batch_tests()

  # Run a single test
  html_out, browser_name, timeout, mode = parse_args()
  browser = start_browser(browser_name, html_out)

  try:
    output = run_test_in_browser(browser, html_out, timeout, mode)
    return report_results(mode, output)
  finally:
    close_browser(browser)

if __name__ == "__main__":
  sys.exit(main(sys.argv))
