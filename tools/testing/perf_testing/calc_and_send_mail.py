#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import create_graph
from create_graph import BROWSER_CORRECTNESS
from create_graph import BROWSER_PERF
from create_graph import CL_PERF
from create_graph import COMMAND_LINE
from create_graph import CORRECTNESS
from create_graph import FROG
from create_graph import FROG_MEAN
from create_graph import TIME_SIZE
from create_graph import V8_AND_FROG

import get_current_stats
import os
from os.path import dirname, abspath
import pickle
import sys

"""Compare the current performance statistics with the statistics 24 hours ago,
and send out an email summarizing the differences."""

def calculate_stats():
  """Compare the numbers that were available at the start of the day to what the
  current numbers are.

  Returns:
    A string providing an update on the latest perfromance numbers."""
  test_runner_dict = pickle.load(open(get_current_stats.PICKLE_FILENAME, 'r'))
  test_runner_dict = get_current_stats.populate_stats_dict(test_runner_dict)

  browser_perf = test_runner_dict[BROWSER_PERF]
  time_size = test_runner_dict[TIME_SIZE]
  cl = test_runner_dict[CL_PERF]
  correctness = test_runner_dict[BROWSER_CORRECTNESS]
  output = summary_stats(browser_perf, time_size, cl, correctness)
  output += specific_stats(browser_perf, time_size, cl)
  return output

def summary_stats(browser_perf, time_size, cl, correctness):
  """Return the summarized stats report.

  Args:
    browser_perf: BrowserPerformanceTestRunner object. Holds browser perf stats.
    time_size: CompileTimeSizeTestRunner object. 
    cl: CommandLinePerformanceTestRunner object.
    correctness: BrowserCorrectnessTestRunner object.
  """
  output = "Summary of changes in the last 24 hours: \n\nBrowser " + \
      "performance: (revision %d)\n" % \
      browser_perf.revision_dict[create_graph.get_browsers()[0]][FROG]\
      [browser_perf.values_list[0]][1]
  for browser in create_graph.get_browsers():
    geo_mean_list = browser_perf.values_dict[browser][FROG][FROG_MEAN]
    # TODO(efortuna): deal with the fact that the latest of all browsers may not
    # be available.
    output += "  %s%s\n" % ((browser + ':').ljust(25), 
        str(geo_mean_list[1] - geo_mean_list[0]).rjust(10))

  output += "\nCompile Size and Time: (revision %d)\n" % \
      time_size.revision_dict[COMMAND_LINE][FROG][time_size.values_list[0]][1]
  for metric in time_size.values_list:
    metric_list = time_size.values_dict[COMMAND_LINE][FROG][metric]
    output += "  %s%s\n" % ((metric + ':').ljust(25), 
        str(metric_list[1] - metric_list[0]).rjust(10))

  output += "\nPercentage of language tests passing (revision %d)\n" % \
      correctness.revision_dict['chrome'][FROG][correctness.values_list[0]][1]
  for browser in create_graph.get_browsers():
    num_correct = correctness.values_dict[browser][FROG][CORRECTNESS]
    output += "  %s%s%%  more passing\n" % ((browser + ':').ljust(25), 
        str(num_correct[1] - num_correct[0]).rjust(10))

  output += "\nCommandline performance: (revision %d)\n" % \
      cl.revision_dict[COMMAND_LINE][FROG][cl.values_list[0]][1]
  for benchmark in cl.values_list:
    bench_list = cl.values_dict[COMMAND_LINE][FROG][benchmark]
    output += "  %s%s\n" % ((benchmark + ':').ljust(25), 
        str(bench_list[1] - bench_list[0]).rjust(10))
  return output

def specific_stats(browser_perf, time_size, cl):
  """Return a string detailing all of the gory details and specifics on 
  benchmark numbers and individual benchmark changes.

  Args:
    browser_perf: BrowserPerformanceTestRunner object. Holds browser perf stats.
    time_size: CompileTimeSizeTestRunner object. 
    cl: CommandLinePerformanceTestRunner object.
  """
  output = "\n\n---------------------------------------------\nThe latest " + \
      "current raw numbers (and changes) for those " + \
      "interested:\nBrowser performance:\n"
  for v8_or_frog in V8_AND_FROG:
    for browser in create_graph.get_browsers():
      output += "  %s %s:\n" % (browser, v8_or_frog)
      for benchmark in create_graph.get_benchmarks():
        bench_list = browser_perf.values_dict[browser][v8_or_frog][benchmark]
        output += "    %s %s%s\n" % ((benchmark + ':').ljust(25), 
            str(bench_list[1]).rjust(10), get_amount_changed(bench_list))

  output += "\nCompile Size and Time for frog:\n" 
  for metric in time_size.values_list:
    metric_list = time_size.values_dict[COMMAND_LINE][FROG][metric]
    output += "    %s %s%s\n" % ((metric + ':').ljust(25), 
        str(metric_list[1]).rjust(10), get_amount_changed(metric_list))

  output += "\nCommandline performance:\n"
  for v8_or_frog in V8_AND_FROG:
    output += '  %s:\n' % v8_or_frog
    for benchmark in cl.values_list:
      bench_list = cl.values_dict[COMMAND_LINE][v8_or_frog][benchmark]
      output += "    %s %s%s\n" % ((benchmark + ':').ljust(25), 
          str(bench_list[1]).rjust(10), get_amount_changed(bench_list))

  return output

def get_amount_changed(values_tuple):
  """Return a formatted string indicating the amount of change (positive or
  negative) in the benchmark since the last run.

  Args:
    values_tuple: the tuple of values we are comparing the difference 
    between."""
  difference = values_tuple[1] - values_tuple[0]
  prefix = '+' 
  if difference < 0:
    prefix = '-'
  return ("(%s%s)" % (prefix, str(difference))).rjust(10)


def main():
  stats = calculate_stats()
  print stats

if __name__ == '__main__':
  main()
