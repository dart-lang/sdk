#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""Script to actually open browsers and perform the test, and reports back with
the result"""

import platform
import selenium
from selenium.webdriver.support.ui import WebDriverWait
import sys


def runTestInBrowser(browser):
  browser.get("file://" + sys.argv[1]) 
  element = WebDriverWait(browser, 10).until( \
      lambda driver : ('PASS' in driver.page_source) or \
      ('FAIL' in driver.page_source))
  source = browser.page_source
  browser.close()
  return source

def Main():
  browser = selenium.webdriver.Firefox() # Get local session of firefox
  firefox_source = runTestInBrowser(browser)

  # Note: you need ChromeDriver in your path to run chrome, in addition to 
  #installing Chrome.
  # TODO(efortuna): Currently disabled for ease of setup for running on other
  # developer machines. Uncomment when frog is robust enough to be tested on
  # multiple platforms at once.
  #browser = selenium.webdriver.Chrome() 
  #chrome_source = runTestInBrowser(browser)

  ie_source = ''
  if platform.system() == 'Windows':
    browser = selenium.webdriver.Ie()
    ie_source = runTestInBrowser(browser)

  #TODO(efortuna): Test if all three return correct responses. If not, throw 
  #error particular to that browser.
  if ('PASS' in firefox_source): 
    print 'Content-Type: text/plain\nPASS'
    return 0
  else:
    index = firefox_source.find('<body>')
    index += len('<body>')
    end_index = firefox_source.find('<script')
    print firefox_source[index : end_index]
    return 1


if __name__ == "__main__":
  sys.exit(Main())
