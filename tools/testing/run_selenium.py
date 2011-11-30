#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""Script to actually open a browser and perform the test, and reports back with
the result.
"""

import optparse
import platform
import selenium
from selenium.webdriver.support.ui import WebDriverWait
import sys

def perf_test_done(driver):
  """Checks if the performance test has completed."""
  #This code is written this way to work around a current instability in the
  # python webdriver bindings if you call driver.get_element_by_id.
  source = driver.page_source
  string = '<div id="status">'
  index = source.find(string)
  end_index = source.find('</div>', index+1)
  source = source[index + len(string):end_index]
  return 'Score:' in source

def run_test_in_browser(browser, html_out, timeout, is_perf):
  """Run the desired test in the browser, and wait for the test to complete."""
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
  finally: 
    # A timeout exception is thrown if nothing happens within the time limit.
    browser.close()
  return source

def parse_args():
  parser = optparse.OptionParser()
  parser.add_option('--out', dest='out', 
      help = 'The path for html output file that we will be writing to', 
      action = 'store', default = '') 
  parser.add_option('--browser', dest='browser', 
      help = 'The browser type (default = chrome)', 
      action = 'store', default = 'chrome') 
  parser.add_option('--timeout', dest = 'timeout', 
      help = 'Amount of time (seconds) to wait before timeout', type = 'int', 
      action = 'store', default=10)
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
  else:
    raise Exception('Incompatible browser and platform combination.')
  source = run_test_in_browser(browser, html_out, timeout, is_perf)

  if is_perf:
    # We're running a performance test.
    print source
    if 'NaN' in source:
      return 1
    else:
      return 0
  else:
    # We're running a correctness test.
    if ('PASS' in source):
      print 'Content-Type: text/plain\nPASS'
      return 0
    else: 
      #The hacky way to get document.getElementById('body').innerHTML for this
      # webpage, without the JavaScript.
      index = source.find('<body>')
      index += len('<body>')
      end_index = source.find('<script')
      print source[index : end_index]
      return 1


if __name__ == "__main__":
  sys.exit(Main())
