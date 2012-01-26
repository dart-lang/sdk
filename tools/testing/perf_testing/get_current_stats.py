#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

from create_graph import BROWSER_CORRECTNESS
from create_graph import BrowserCorrectnessTest
from create_graph import BROWSER_PERF
from create_graph import BrowserPerformanceTest
from create_graph import CL_PERF
from create_graph import CommandLinePerformanceTest
from create_graph import CompileTimeAndSizeTest
from create_graph import TIME_SIZE

import os
from os.path import dirname, abspath
import pickle
import re
import sys

"""Find the most recent performance files, and store the stats."""

# TODO(efortuna): turn these into proper appengine tasks, using the app engine 
# datastore instead of files.

DIRECTORIES = [BROWSER_CORRECTNESS, BROWSER_PERF, CL_PERF, TIME_SIZE]
PICKLE_FILENAME = 'start_stats.txt'

def find_latest_data_files(directory):
  """Given a directory, find the files with the latest timestamp, indicating the
  latest results.

  Args:
    directory: name of the directory we should look inside.

  Returns:
    A list of the most recent files in the particular directory."""
  path = dirname(abspath(__file__))
  files = os.listdir(os.path.join(path, directory))
  files.sort()
  f = files.pop()
  match = re.search('[1-9]', f)
  trace_name = f[:match.start()]
  timestamp_and_data = f[match.start():]
  latest_files = [f]
  if trace_name == 'correctness' or trace_name == 'perf-':
    index = timestamp_and_data.find('-')
    timestamp = timestamp_and_data[:index]
    f = files.pop()
    while f[match.start() : match.start() + index] == timestamp:
      latest_files.append(f)
      f = files.pop()
  return latest_files

def populate_stats_dict(test_runner_dict = None):
  """Find the latest files in each directory, and process those latest files
  using the appropriate TestRunner.

  Args:
    test_runner_dict: Optional agument storing previous data in runners to which
    we should add our data."""
  cur_runner_dict = dict()
  if test_runner_dict:
    cur_runner_dict = test_runner_dict
  for directory in DIRECTORIES:
    test_runner = None
    latest_files = find_latest_data_files(directory)
    
    if test_runner_dict:
      test_runner = cur_runner_dict[directory]
    else:
      if directory == BROWSER_CORRECTNESS:
        test_runner = BrowserCorrectnessTest('language', directory)
      elif directory == BROWSER_PERF:
        test_runner = BrowserPerformanceTest(directory)
      elif directory == TIME_SIZE:
        test_runner = CompileTimeAndSizeTest(directory)
      elif directory == CL_PERF:
        test_runner = CommandLinePerformanceTest(directory)
      cur_runner_dict[directory] = test_runner
    
    for f in latest_files:
      test_runner.process_file(f)
  return cur_runner_dict

def main():
  test_runner_dict = populate_stats_dict()
  f = open(PICKLE_FILENAME, 'w')
  pickle.dump(test_runner_dict, f)
  f.close()

if __name__ == '__main__':
  main()
