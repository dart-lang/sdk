#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""Script to actually open a browser and perform the test, and reports back with
the result.
Expects:
  sys.argv[1] = html output file
  sys.argv[2] = browser type (default = chrome)
"""

import platform
import selenium
from selenium.webdriver.support.ui import WebDriverWait
import sys


def runTestInBrowser(browser):
  """Run the desired test in the browser, and wait for the test to complete."""
  browser.get("file://" + sys.argv[1]) 
  source = ''
  try:
    element = WebDriverWait(browser, 10).until( \
        lambda driver : ('PASS' in driver.page_source) or \
        ('FAIL' in driver.page_source))
    source = browser.page_source
  finally: 
    # A timeout exception is thrown if nothing happens within the time limit.
    browser.close()
  return source

def Main():
  # Note: you need ChromeDriver *in your path* to run Chrome, in addition to 
  # installing Chrome.
  browser = None
  if sys.argv[2] == 'chrome':
    browser = selenium.webdriver.Chrome() 
  elif sys.argv[2] == 'ff': 
    browser = selenium.webdriver.Firefox() 
  elif sys.argv[2] == 'ie' and platform.system() == 'Windows':
    browser = selenium.webdriver.Ie()
  else:
    raise Exception('Incompatible browser and platform combination.')
  source = runTestInBrowser(browser)

  if ('PASS' in source): 
    print 'Content-Type: text/plain\nPASS'
    return 0
  else:
    index = source.find('<body>')
    index += len('<body>')
    end_index = source.find('<script')
    print source[index : end_index]
    return 1


if __name__ == "__main__":
  sys.exit(Main())
