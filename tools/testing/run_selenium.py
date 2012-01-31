#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""Script to actually open a browser and perform the test, and reports back with
the result.
"""

import os
import optparse
import platform
import selenium
from selenium.webdriver.support.ui import WebDriverWait
import shutil
import socket
import sys
import time

def perf_test_done(driver):
  """Checks if the performance test has completed."""
  return perf_test_done_helper(driver.page_source)

def perf_test_done_helper(source):
  """Tests to see if our performance test is done by printing a score."""
  #This code is written this way to work around a current instability in the
  # python webdriver bindings if you call driver.get_element_by_id.
  #TODO(efortuna): Access these elements in a nicer way using DOM parser.
  string = '<div id="status">'
  index = source.find(string)
  end_index = source.find('</div>', index+1)
  source = source[index + len(string):end_index]
  return 'Score:' in source

def run_test_in_browser(browser, html_out, timeout, is_perf):
  """Run the desired test in the browser using Selenium 2.0 WebDriver syntax, 
  and wait for the test to complete. This is the newer syntax, that currently
  supports Firefox, Chrome, IE, Opera (and some mobile browsers)."""
  browser.get("file://" + html_out) 
  source = ''
  try:
    if is_perf:
      # We're running a performance test.
      element = WebDriverWait(browser, float(timeout)).until(perf_test_done)
    else:
      element = WebDriverWait(browser, float(timeout)).until(
          lambda driver : ('PASS' in driver.page_source) or
          ('FAIL' in driver.page_source))
    source = browser.page_source
  except selenium.common.exceptions.TimeoutException:
    source = 'FAIL (timeout)'
  finally: 
    # A timeout exception is thrown if nothing happens within the time limit.
    if browser != 'chrome':
      browser.close()
    try:
      browser.quit()
    except selenium.common.exceptions.WebDriverException:
      #TODO(efortuna): figure out why this crashes.... and avoid?
      pass
  return source

def run_test_in_browser_selenium1(sel, html_out, timeout, is_perf):
  """ Run the desired test in the browser using Selenium 1.0 syntax, and wait
  for the test to complete. This is used for Safari, since it is not currently
  supported on Selenium 2.0."""
  sel.open('file://' + html_out)
  source = sel.get_html_source()
  def end_condition(source): 
    return 'PASS' in source or 'FAIL' in source
  if is_perf:
    end_condition = perf_test_done_helper

  elapsed = 0
  while (not end_condition(source)) and elapsed <= timeout:
    sec = .25
    time.sleep(sec)
    elapsed += sec
    source = sel.get_html_source()
  sel.stop()
  return source

def parse_args():
  parser = optparse.OptionParser()
  parser.add_option('--out', dest='out', 
      help = 'The path for html output file that we will running our test from', 
      action = 'store', default = '') 
  parser.add_option('--browser', dest='browser', 
      help = 'The browser type (default = chrome)', 
      action = 'store', default = 'chrome') 
  parser.add_option('--timeout', dest = 'timeout', 
      help = 'Amount of time (seconds) to wait before timeout', type = 'int', 
      action = 'store', default=40)
  parser.add_option('--perf', dest = 'is_perf', 
      help = 'Add this flag if we are running a browser performance test', 
      action = 'store_true', default=False)
  args, ignored = parser.parse_args()
  return args.out, args.browser, args.timeout, args.is_perf

def Main():
  # Note: you need ChromeDriver *in your path* to run Chrome, in addition to 
  # installing Chrome.
  browser = None
  html_out, browser, timeout, is_perf = parse_args()

  if browser == 'chrome':
    browser = selenium.webdriver.Chrome()
  elif browser == 'ff':
    browser = selenium.webdriver.Firefox()
  elif browser == 'ie' and platform.system() == 'Windows':
    browser = selenium.webdriver.Ie()
  elif browser == 'safari' and platform.system() == 'Darwin':
    # TODO(efortuna): Ensure our preferences (no pop-up blocking) file is the 
    # same (Safari auto-deletes when it has too many "crashes," or in our case, 
    # timeouts). Come up with a less hacky way to do this.
    shutil.copy(os.path.dirname(__file__) + '/com.apple.Safari.plist', 
        '/Library/Preferences/com.apple.Safari.plist')
    sel = selenium.selenium('localhost', 4444, "*safari", 'file://' + html_out)
    try:
      sel.start()
    except socket.error:
      print 'ERROR: Could not connect to Selenium RC server. Are you running' +\
          ' java -jar selenium-server-standalone-2.15.0.jar? If not, start ' + \
          'it before running this test.'
      return 1
  else:
    raise Exception('Incompatible browser and platform combination.')
  source = ''
  if browser == 'safari':
    source = run_test_in_browser_selenium1(sel, html_out, timeout, is_perf)
  else:
    source = run_test_in_browser(browser, html_out, timeout, is_perf)

  if is_perf:
    # We're running a performance test.
    print source
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
      print source[index : end_index]
      return 1


if __name__ == "__main__":
  sys.exit(Main())
