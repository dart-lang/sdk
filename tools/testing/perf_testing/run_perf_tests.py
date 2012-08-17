#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import datetime
import math		
import optparse
import os
from os.path import dirname, abspath
import pickle
import platform
import random
import re
import shutil
import stat
import subprocess
import sys
import time

TOOLS_PATH = os.path.join(dirname(dirname(dirname(abspath(__file__)))))
TOP_LEVEL_DIR = abspath(os.path.join(dirname(abspath(__file__)), '..', '..',
                                             '..'))
DART_REPO_LOC = abspath(os.path.join(dirname(abspath(__file__)), '..', '..',
                                             '..', '..', '..',
                                             'dart_checkout_for_perf_testing',
                                             'dart'))
sys.path.append(TOOLS_PATH)
sys.path.append(os.path.join(TOP_LEVEL_DIR, 'internal', 'tests'))
import post_results
import utils

"""This script runs to track performance and size progress of
different svn revisions. It tests to see if there a newer version of the code on
the server, and will sync and run the performance tests if so."""
class TestRunner(object):

  def __init__(self):
    self.verbose = False
    self.has_shell = False
    if platform.system() == 'Windows':
      # On Windows, shell must be true to get the correct environment variables.
      self.has_shell = True

  def run_cmd(self, cmd_list, outfile=None, append=False, std_in=''):
    """Run the specified command and print out any output to stdout.

    Args:
      cmd_list: a list of strings that make up the command to run
      outfile: a string indicating the name of the file that we should write
         stdout to
      append: True if we want to append to the file instead of overwriting it
      std_in: a string that should be written to the process executing to
         interact with it (if needed)"""
    if self.verbose:
      print ' '.join(cmd_list)
    out = subprocess.PIPE
    if outfile:
      mode = 'w'
      if append:
        mode = 'a+'
      out = open(outfile, mode)
      if append:
        # Annoying Windows "feature" -- append doesn't actually append unless
        # you explicitly go to the end of the file.
        # http://mail.python.org/pipermail/python-list/2009-October/1221859.html
        out.seek(0, os.SEEK_END)
    p = subprocess.Popen(cmd_list, stdout = out, stderr=subprocess.PIPE,
                         stdin=subprocess.PIPE, shell=self.has_shell)
    output, stderr = p.communicate(std_in)
    if output:
      print output
    if stderr:
      print stderr
    return output, stderr

  def time_cmd(self, cmd):
    """Determine the amount of (real) time it takes to execute a given 
    command."""
    start = time.time()
    self.run_cmd(cmd)
    return time.time() - start

  def clear_out_unversioned_files(self):
    """Remove all files that are unversioned by svn."""
    if os.path.exists(DART_REPO_LOC):
      os.chdir(DART_REPO_LOC)
      results, _ = self.run_cmd(['svn', 'st'])
      for line in results.split('\n'):
        if line.startswith('?'):
          to_remove = line.split()[1]
          if os.path.isdir(to_remove):
            shutil.rmtree(to_remove)#, ignore_errors=True)
          else:
            os.remove(to_remove)

  def get_archive(self, archive_name):
    """Wrapper around the pulling down a specific archive from Google Storage.
    Adds a specific revision argument as needed.
    Returns: The stderr from running this command."""
    cmd = ['python', os.path.join(DART_REPO_LOC, 'tools', 'get_archive.py'),
           archive_name]
    if self.current_revision_num != -1:
      cmd += ['-r', self.current_revision_num]
    _, stderr = self.run_cmd(cmd)
    return stderr

  def sync_and_build(self, suites, revision_num=''):
    """Make sure we have the latest version of of the repo, and build it. We
    begin and end standing in DART_REPO_LOC.

    Args:
      suites: The set of suites that we wish to build.

    Returns:
      err_code = 1 if there was a problem building."""
    os.chdir(dirname(DART_REPO_LOC))
    self.clear_out_unversioned_files()
    if revision_num == '':
      self.run_cmd(['gclient', 'sync'])
    else:
      self.run_cmd(['gclient', 'sync', '-r', revision_num, '-t'])
    
    shutil.copytree(os.path.join(TOP_LEVEL_DIR, 'internal'),
                    os.path.join(DART_REPO_LOC, 'internal'))
    shutil.copy(os.path.join(TOP_LEVEL_DIR, 'tools', 'get_archive.py'),
                    os.path.join(DART_REPO_LOC, 'tools', 'get_archive.py'))
    shutil.copy(
        os.path.join(TOP_LEVEL_DIR, 'tools', 'testing', 'run_selenium.py'),
        os.path.join(DART_REPO_LOC, 'tools', 'testing', 'run_selenium.py'))

    if revision_num == '':
      revision_num = search_for_revision()

    self.current_revision_num = revision_num
    stderr = self.get_archive('sdk')
    if not os.path.exists(os.path.join(
        DART_REPO_LOC, 'tools', 'get_archive.py')) \
        or 'InvalidUriError' in stderr:
      # Couldn't find the SDK on Google Storage. Build it locally.

      # On Windows, the output directory is marked as "Read Only," which causes
      # an error to be thrown when we use shutil.rmtree. This helper function
      # changes the permissions so we can still delete the directory.
      def on_rm_error(func, path, exc_info):
        if os.path.exists(path):
          os.chmod(path, stat.S_IWRITE)
          os.unlink(path)
      # TODO(efortuna): Currently always building ia32 architecture because we 
      # don't have test statistics for what's passing on x64. Eliminate arch 
      # specification when we have tests running on x64, too.
      shutil.rmtree(os.path.join(os.getcwd(),
                    utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32')),
                    onerror=on_rm_error)
      lines = self.run_cmd([os.path.join('.', 'tools', 'build.py'), '-m', 
                            'release', '--arch=ia32', 'create_sdk'])

      for line in lines:
        if 'BUILD FAILED' in line:
          # Someone checked in a broken build! Stop trying to make it work
          # and wait to try again.
          print 'Broken Build'
          return 1
    return 0

  def ensure_output_directory(self, dir_name):
    """Test that the listed directory name exists, and if not, create one for
    our output to be placed.

    Args:
      dir_name: the directory we will create if it does not exist."""
    dir_path = os.path.join(TOP_LEVEL_DIR, 'tools', 
                            'testing', 'perf_testing', dir_name)
    if not os.path.exists(dir_path):
      os.makedirs(dir_path)
      print 'Creating output directory ', dir_path

  def has_interesting_code(self, past_revision_num=None):
    """Tests if there are any versions of files that might change performance
    results on the server."""
    if not os.path.exists(DART_REPO_LOC):
      return True
    os.chdir(DART_REPO_LOC)
    no_effect = ['client', 'compiler', 'editor', 'pkg', 'samples', 'tests',
                 'third_party', 'tools', 'utils']
    # Pass 'p' in if we have a new certificate for the svn server, we want to
    # (p)ermanently accept it.
    if past_revision_num:
      # TODO(efortuna): This assumes you're using svn. Have a git fallback as
      # well.
      results, _ = self.run_cmd(['svn', 'log', '-v', '-r',
                                 str(past_revision_num)], std_in='p\r\n')
      results = results.split('\n')
      if len(results) <= 3:
        results = []
      else:
        # Trim off the details about revision number and commit message. We're
        # only interested in the files that are changed.
        results = results[3:]
        changed_files = []
        for result in results:
          if result == '':
            break
          changed_files += [result.replace('/branches/bleeding_edge/dart/', '')]
        results = changed_files
    else:
      results, _ = self.run_cmd(['svn', 'st', '-u'], std_in='p\r\n')
      results = results.split('\n')
    for line in results:
      tokens = line.split()
      if past_revision_num or len(tokens) >= 3 and '*' in tokens[-3]:
        # Loop through the changed files to see if it contains any files that
        # are NOT listed in the no_effect list (directories not listed in
        # the "no_effect" list are assumed to potentially affect performance.
        if not reduce(lambda x, y: x or y, 
            [tokens[-1].startswith(item) for item in no_effect], False):
          return True
    return False
    
  def get_os_directory(self):
    """Specifies the name of the directory for the testing build of dart, which
    has yet a different naming convention from utils.getBuildRoot(...)."""
    if platform.system() == 'Windows':
      return 'windows'
    elif platform.system() == 'Darwin':
      return 'macos'
    else:
      return 'linux'

  def parse_args(self):
    parser = optparse.OptionParser()
    parser.add_option('--suites', '-s', dest='suites', help='Run the specified '
                      'comma-separated test suites from set: %s' % \
                      ','.join(TestBuilder.available_suite_names()), 
                      action='store', default=None)
    parser.add_option('--forever', '-f', dest='continuous', help='Run this scri'
                      'pt forever, always checking for the next svn checkin',
                      action='store_true', default=False)
    parser.add_option('--nobuild', '-n', dest='no_build', action='store_true',
                      help='Do not sync with the repository and do not '
                      'rebuild.', default=False)
    parser.add_option('--noupload', '-u', dest='no_upload', action='store_true',
                      help='Do not post the results of the run.', default=False)
    parser.add_option('--notest', '-t', dest='no_test', action='store_true',
                      help='Do not run the tests.', default=False)
    parser.add_option('--verbose', '-v', dest='verbose', help='Print extra '
                      'debug output', action='store_true', default=False)

    args, ignored = parser.parse_args()

    if not args.suites:
      suites = TestBuilder.available_suite_names()
    else:
      suites = []
      suitelist = args.suites.split(',')
      for name in suitelist:
        if name in TestBuilder.available_suite_names():
          suites.append(name)
        else:
          print ('Error: Invalid suite %s not in ' % name) + \
              '%s' % ','.join(TestBuilder.available_suite_names())
          sys.exit(1)
    self.suite_names = suites
    self.no_build = args.no_build
    self.no_upload = args.no_upload
    self.no_test = args.no_test
    self.verbose = args.verbose
    return args.continuous

  def run_test_sequence(self, revision_num='', num_reruns=1):
    """Run the set of commands to (possibly) build, run, and post the results
    of our tests. Returns 0 on a successful run, 1 if we fail to post results or
    the run failed, -1 if the build is broken.
    """
    suites = []
    success = True
    if not self.no_build and self.sync_and_build(suites, revision_num) == 1:
      return -1 # The build is broken.

    for name in self.suite_names:
      for run in range(num_reruns):
        suites += [TestBuilder.make_test(name, self)]

    for test in suites:
      success = success and test.run()
    if success:
      return 0
    else:
      return 1


class Test(object):
  """The base class to provide shared code for different tests we will run and
  post. At a high level, each test has three visitors (the tester and the
  file_processor) that perform operations on the test object."""

  def __init__(self, result_folder_name, platform_list, variants,
               values_list, test_runner, tester, file_processor,
               extra_metrics=['Geo-Mean']):
    """Args:
         result_folder_name: The name of the folder where a tracefile of
             performance results will be stored.
         platform_list: A list containing the platform(s) that our data has been
             run on. (command line, firefox, chrome, etc)
         variants: A list specifying whether we hold data about Frog
             generated code, plain JS code, or a combination of both, or
             Dart depending on the test.
         values_list: A list containing the type of data we will be graphing
             (benchmarks, percentage passing, etc).
         test_runner: Reference to the parent test runner object that notifies a
             test when to run.
         tester: The visitor that actually performs the test running mechanics.
         file_processor: The visitor that processes files in the format
             appropriate for this test.
         extra_metrics: A list of any additional measurements we wish to keep
             track of (such as the geometric mean of a set, the sum, etc)."""
    self.result_folder_name = result_folder_name
    # cur_time is used as a timestamp of when this performance test was run.
    self.cur_time = str(time.mktime(datetime.datetime.now().timetuple()))
    self.values_list = values_list
    self.platform_list = platform_list
    self.test_runner = test_runner
    self.tester = tester
    self.file_processor = file_processor
    self.revision_dict = dict()
    self.values_dict = dict()
    self.extra_metrics = extra_metrics
    # Initialize our values store.		
    for platform in platform_list:		
      self.revision_dict[platform] = dict()		
      self.values_dict[platform] = dict()		
      for f in variants:		
        self.revision_dict[platform][f] = dict()		
        self.values_dict[platform][f] = dict()		
        for val in values_list:		
          self.revision_dict[platform][f][val] = []		
          self.values_dict[platform][f][val] = []		
        for extra_metric in extra_metrics:		
          self.revision_dict[platform][f][extra_metric] = []		
          self.values_dict[platform][f][extra_metric] = []

  def is_valid_combination(self, platform, variant):
    """Check whether data should be captured for this platform/variant
    combination.
    """
    return True

  def run(self):
    """Run the benchmarks/tests from the command line and plot the
    results.
    """
    for visitor in [self.tester, self.file_processor]:
      visitor.prepare()
    
    os.chdir(TOP_LEVEL_DIR)
    self.test_runner.ensure_output_directory(self.result_folder_name)
    self.test_runner.ensure_output_directory(os.path.join(
        'old', self.result_folder_name))
    os.chdir(DART_REPO_LOC)
    if not self.test_runner.no_test:
      self.tester.run_tests()

    os.chdir(os.path.join(TOP_LEVEL_DIR, 'tools', 'testing', 'perf_testing'))

    files = os.listdir(self.result_folder_name)
    post_success = True
    for afile in files:
      if not afile.startswith('.'):
        should_move_file = self.file_processor.process_file(afile, True)
        if should_move_file:
          shutil.move(os.path.join(self.result_folder_name, afile),
                      os.path.join('old', self.result_folder_name, afile))
        else:
          post_success = False

    return post_success


class Tester(object):
  """The base level visitor class that runs tests. It contains convenience 
  methods that many Tester objects use. Any class that would like to be a
  TesterVisitor must implement the run_tests() method."""

  def __init__(self, test):
    self.test = test

  def prepare(self):
    """Perform any initial setup required before the test is run."""
    pass

  def add_svn_revision_to_trace(self, outfile, browser = None):
    """Add the svn version number to the provided tracefile."""
    def get_dartium_revision():
      version_file_name = os.path.join(DART_REPO_LOC, 'client', 'tests',
                                       'dartium', 'LAST_VERSION')
      version_file = open(version_file_name, 'r')
      version = version_file.read().split('.')[-2]
      version_file.close()
      return version

    if browser and browser == 'dartium':
      revision = get_dartium_revision()
      self.test.test_runner.run_cmd(['echo', 'Revision: ' + revision], outfile)
    else:
      revision = search_for_revision()
      self.test.test_runner.run_cmd(['echo', 'Revision: ' + revision], outfile)


class Processor(object):
  """The base level vistor class that processes tests. It contains convenience 
  methods that many File Processor objects use. Any class that would like to be
  a ProcessorVisitor must implement the process_file() method."""

  SCORE = 'Score'
  COMPILE_TIME = 'CompileTime'
  CODE_SIZE = 'CodeSize'

  def __init__(self, test):
    self.test = test

  def prepare(self):
    """Perform any initial setup required before the test is run."""
    pass

  def open_trace_file(self, afile, not_yet_uploaded):
    """Find the correct location for the trace file, and open it.
    Args: 
      afile: The tracefile name.
      not_yet_uploaded: True if this file is to be found in a directory that
         contains un-uploaded data.
    Returns: A file object corresponding to the given file name."""
    file_path = os.path.join(self.test.result_folder_name, afile)
    if not not_yet_uploaded:
      file_path = os.path.join('old', file_path)
    return open(file_path)

  def report_results(self, benchmark_name, score, platform, variant, 
                     revision_number, metric):
    """Store the results of the benchmark run.
    Args:
      benchmark_name: The name of the individual benchmark.
      score: The numerical value of this benchmark.
      platform: The platform the test was run on (firefox, command line, etc).
      variant: Specifies whether the data was about generated Frog, js, a
          combination of both, or Dart depending on the test.
      revision_number: The revision of the code (and sometimes the revision of
          dartium).
  
    Returns: True if the post was successful file."""
    return post_results.report_results(benchmark_name, score, platform, variant,
                                       revision_number, metric)

  def calculate_geometric_mean(self, platform, variant, svn_revision):
    """Calculate the aggregate geometric mean for JS and dart2js benchmark sets,
    given two benchmark dictionaries."""
    geo_mean = 0		
    if self.test.is_valid_combination(platform, variant):
      for benchmark in self.test.values_list:
        geo_mean += math.log(
            self.test.values_dict[platform][variant][benchmark][
                len(self.test.values_dict[platform][variant][benchmark]) - 1])

    self.test.values_dict[platform][variant]['Geo-Mean'] += \
        [math.pow(math.e, geo_mean / len(self.test.values_list))]
    self.test.revision_dict[platform][variant]['Geo-Mean'] += [svn_revision]

  def get_score_type(self, benchmark_name):
    """Determine the type of score for posting -- default is 'Score' (aka
    Runtime), other options are CompileTime and CodeSize."""
    return self.SCORE


class RuntimePerformanceTest(Test):
  """Super class for all runtime performance testing."""

  def __init__(self, result_folder_name, platform_list, platform_type,
               versions, benchmarks, test_runner, tester, file_processor):
    """Args:
        result_folder_name: The name of the folder where a tracefile of
            performance results will be stored.
        platform_list: A list containing the platform(s) that our data has been
            run on. (command line, firefox, chrome, etc)
        variants: A list specifying whether we hold data about Frog
            generated code, plain JS code, or a combination of both, or
            Dart depending on the test.
        values_list: A list containing the type of data we will be graphing
            (benchmarks, percentage passing, etc).
        test_runner: Reference to the parent test runner object that notifies a
            test when to run.
        tester: The visitor that actually performs the test running mechanics.
        file_processor: The visitor that processes files in the format
            appropriate for this test.
        extra_metrics: A list of any additional measurements we wish to keep
            track of (such as the geometric mean of a set, the sum, etc)."""
    super(RuntimePerformanceTest, self).__init__(result_folder_name,
          platform_list, versions, benchmarks, test_runner, tester,
          file_processor)
    self.platform_list = platform_list
    self.platform_type = platform_type
    self.versions = versions
    self.benchmarks = benchmarks 


class BrowserTester(Tester):
  @staticmethod
  def get_browsers(add_dartium=True):
    browsers = ['ff', 'chrome']
    if add_dartium:
      browsers += ['dartium']
    has_shell = False
    if platform.system() == 'Darwin':
      browsers += ['safari']
    if platform.system() == 'Windows':
      browsers += ['ie']
      has_shell = True
    return browsers


class CommonBrowserTest(RuntimePerformanceTest):
  """Runs this basic performance tests (Benchpress, some V8 benchmarks) in the
  browser."""

  def __init__(self, test_runner):
    """Args:
      test_runner: Reference to the object that notifies us when to run."""
    super(CommonBrowserTest, self).__init__(
        self.name(), BrowserTester.get_browsers(False),
        'browser', ['js', 'dart2js'],
        self.get_standalone_benchmarks(), test_runner, 
        self.CommonBrowserTester(self),
        self.CommonBrowserFileProcessor(self))
  
  @staticmethod
  def name():
    return 'browser-perf'

  @staticmethod
  def get_standalone_benchmarks():
    return ['Mandelbrot', 'DeltaBlue', 'Richards', 'NBody', 'BinaryTrees',
    'Fannkuch', 'Meteor', 'BubbleSort', 'Fibonacci', 'Loop', 'Permute',
    'Queens', 'QuickSort', 'Recurse', 'Sieve', 'Sum', 'Tak', 'Takl', 'Towers',
    'TreeSort']

  class CommonBrowserTester(BrowserTester):
    def run_tests(self):
      """Run a performance test in the browser."""
      os.chdir(DART_REPO_LOC)
      self.test.test_runner.run_cmd([
          'python', os.path.join('internal', 'browserBenchmarks',
          'make_web_benchmarks.py')])

      for browser in self.test.platform_list:
        for version in self.test.versions:
          if not self.test.is_valid_combination(browser, version):
            continue
          self.test.trace_file = os.path.join(TOP_LEVEL_DIR,
              'tools', 'testing', 'perf_testing', self.test.result_folder_name,
              'perf-%s-%s-%s' % (self.test.cur_time, browser, version))
          self.add_svn_revision_to_trace(self.test.trace_file, browser)
          file_path = os.path.join(
              os.getcwd(), 'internal', 'browserBenchmarks',
              'benchmark_page_%s.html' % version)
          self.test.test_runner.run_cmd(
              ['python', os.path.join('tools', 'testing', 'run_selenium.py'),
              '--out', file_path, '--browser', browser,
              '--timeout', '600', '--mode', 'perf'], self.test.trace_file, 
              append=True)

  class CommonBrowserFileProcessor(Processor):

    def process_file(self, afile, should_post_file):
      """Comb through the html to find the performance results.
      Returns: True if we successfully posted our data to storage and/or we can
          delete the trace file."""
      os.chdir(os.path.join(TOP_LEVEL_DIR, 'tools',
                            'testing', 'perf_testing'))
      parts = afile.split('-')
      browser = parts[2]
      version = parts[3]
      f = self.open_trace_file(afile, should_post_file)
      lines = f.readlines()
      line = ''
      i = 0
      revision_num = 0
      while '<div id="results">' not in line and i < len(lines):
        if 'Revision' in line:
          revision_num = int(line.split()[1].strip('"'))
        line = lines[i]
        i += 1

      if i >= len(lines) or revision_num == 0:
        # Then this run did not complete. Ignore this tracefile.
        return True

      line = lines[i]
      i += 1
      results = []
      if line.find('<br>') > -1:
        results = line.split('<br>')
      else:
        results = line.split('<br />')
      if results == []:
        return True
      upload_success = True
      for result in results:
        name_and_score = result.split(':')
        if len(name_and_score) < 2:
          break
        name = name_and_score[0].strip()
        score = name_and_score[1].strip()
        if version == 'js' or version == 'v8':
          version = 'js'
        bench_dict = self.test.values_dict[browser][version]
        bench_dict[name] += [float(score)]
        self.test.revision_dict[browser][version][name] += [revision_num]
        if not self.test.test_runner.no_upload and should_post_file:
          upload_success = upload_success and self.report_results(
              name, score, browser, version, revision_num,
              self.get_score_type(name))
        else:
          upload_success = False

      f.close()
      self.calculate_geometric_mean(browser, version, revision_num)
      return upload_success


class DromaeoTester(Tester):
  DROMAEO_BENCHMARKS = {
      'attr': ('attributes', [
          'getAttribute',
          'element.property',
          'setAttribute',
          'element.property = value']),
      'modify': ('modify', [
          'createElement',
          'createTextNode',
          'innerHTML',
          'cloneNode',
          'appendChild',
          'insertBefore']),
      'query': ('query', [
          'getElementById',
          'getElementById (not in document)',
          'getElementsByTagName(div)',
          'getElementsByTagName(p)',
          'getElementsByTagName(a)',
          'getElementsByTagName(*)',
          'getElementsByTagName (not in document)',
          'getElementsByName',
          'getElementsByName (not in document)']),
      'traverse': ('traverse', [
          'firstChild',
          'lastChild',
          'nextSibling',
          'previousSibling',
          'childNodes'])
  }

  # Use filenames that don't have unusual characters for benchmark names.	
  @staticmethod	
  def legalize_filename(str):	
    remap = {	
        ' ': '_',	
        '(': '_',	
        ')': '_',	
        '*': 'ALL',	
        '=': 'ASSIGN',	
        }	
    for (old, new) in remap.iteritems():	
      str = str.replace(old, new)
    return str

  # TODO(vsm): This is a hack to skip breaking tests.  Triage this
  # failure properly.  The modify suite fails on 32-bit chrome, which
  # is the default on mac and win.
  @staticmethod
  def get_valid_dromaeo_tags():
    tags = [tag for (tag, _) in DromaeoTester.DROMAEO_BENCHMARKS.values()]
    if platform.system() == 'Darwin' or platform.system() == 'Windows':
      tags.remove('modify')
    return tags

  @staticmethod
  def get_dromaeo_benchmarks():
    valid = DromaeoTester.get_valid_dromaeo_tags()
    benchmarks = reduce(lambda l1,l2: l1+l2,
                        [tests for (tag, tests) in
                         DromaeoTester.DROMAEO_BENCHMARKS.values() 
                         if tag in valid])
    return map(DromaeoTester.legalize_filename, benchmarks)

  @staticmethod
  def get_dromaeo_versions():
    return ['js', 'dart2js_html']


class DromaeoTest(RuntimePerformanceTest):
  """Runs Dromaeo tests, in the browser."""
  def __init__(self, test_runner):
    super(DromaeoTest, self).__init__(
        self.name(),
        BrowserTester.get_browsers(True),
        'browser',
        DromaeoTester.get_dromaeo_versions(), 
        DromaeoTester.get_dromaeo_benchmarks(), test_runner,
        self.DromaeoPerfTester(self),
        self.DromaeoFileProcessor(self))

  @staticmethod
  def name():
    return 'dromaeo'

  def is_valid_combination(self, browser, version):
    # TODO(vsm): This avoids a bug in 32-bit Chrome (dartium)
    # running JS dromaeo.
    if browser == 'dartium' and version == 'js':
      return False
    # dart:dom has been removed from Dartium.
    if browser == 'dartium' and 'dom' in version:
      return False
    return True


  class DromaeoPerfTester(DromaeoTester):
    def move_chrome_driver_if_needed(self, browser):
      """Move the appropriate version of ChromeDriver onto the path. 
      TODO(efortuna): This is a total hack because the latest version of Chrome
      (Dartium builds) requires a different version of ChromeDriver, that is
      incompatible with the release or beta Chrome and vice versa. Remove these
      shenanigans once we're back to both versions of Chrome using the same
      version of ChromeDriver. IMPORTANT NOTE: This assumes your chromedriver is
      in the default location (inside depot_tools).
      """
      current_dir = os.getcwd()
      self.test.test_runner.get_archive('chromedriver')
      path = os.environ['PATH'].split(os.pathsep)
      orig_chromedriver_path = os.path.join(DART_REPO_LOC, 'tools', 'testing',
                                            'orig-chromedriver')
      dartium_chromedriver_path = os.path.join(DART_REPO_LOC, 'tools',
                                               'testing',
                                               'dartium-chromedriver')
      extension = ''
      if platform.system() == 'Windows':
        extension = '.exe'

      def move_chromedriver(depot_tools, copy_to_depot_tools_dir=True,
                            from_path=None):
        if from_path:
          from_dir = from_path + extension
        else:
          from_dir =  os.path.join(orig_chromedriver_path,
                                   'chromedriver' + extension)
        to_dir = os.path.join(depot_tools, 'chromedriver' + extension)
        if not copy_to_depot_tools_dir:
          tmp = to_dir
          to_dir = from_dir
          from_dir = tmp
        print >> sys.stderr, from_dir
        print >> sys.stderr, to_dir
        if not os.path.exists(os.path.dirname(to_dir)):
          os.makedirs(os.path.dirname(to_dir))
        shutil.copyfile(from_dir, to_dir)

      for loc in path:
        if 'depot_tools' in loc:
          if browser == 'chrome':
            if os.path.exists(orig_chromedriver_path):
              move_chromedriver(loc)
          elif browser == 'dartium':
            if not os.path.exists(dartium_chromedriver_path):
              self.test.test_runner.get_archive('chromedriver')
            # Move original chromedriver for storage.
            if not os.path.exists(orig_chromedriver_path):
              move_chromedriver(loc, copy_to_depot_tools_dir=False)
            # Copy Dartium chromedriver into depot_tools
            move_chromedriver(loc, from_path=os.path.join(
                              dartium_chromedriver_path, 'chromedriver'))
      os.chdir(current_dir)

    def run_tests(self):
      """Run dromaeo in the browser."""
      
      self.test.test_runner.get_archive('dartium')

      # Build tests.
      dromaeo_path = os.path.join('samples', 'third_party', 'dromaeo')
      current_path = os.getcwd()
      os.chdir(dromaeo_path)
      self.test.test_runner.run_cmd(['python', 'generate_dart2js_tests.py'])
      os.chdir(current_path)

      versions = DromaeoTester.get_dromaeo_versions()

      for browser in BrowserTester.get_browsers():
        self.move_chrome_driver_if_needed(browser)
        for version_name in versions:
          if not self.test.is_valid_combination(browser, version_name):
            continue
          version = DromaeoTest.DromaeoPerfTester.get_dromaeo_url_query(
              browser, version_name)
          self.test.trace_file = os.path.join(TOP_LEVEL_DIR,
              'tools', 'testing', 'perf_testing', self.test.result_folder_name,
              'dromaeo-%s-%s-%s' % (self.test.cur_time, browser, version_name))
          self.add_svn_revision_to_trace(self.test.trace_file, browser)
          file_path = '"%s"' % os.path.join(os.getcwd(), dromaeo_path,
              'index-js.html?%s' % version)
          if platform.system() == 'Windows':
            file_path = file_path.replace('&', '^&')
            file_path = file_path.replace('?', '^?')
            file_path = file_path.replace('|', '^|')
          self.test.test_runner.run_cmd(
              ['python', os.path.join('tools', 'testing', 'run_selenium.py'),
               '--out', file_path, '--browser', browser,
               '--timeout', '900', '--mode', 'dromaeo'], self.test.trace_file,
               append=True)
      # Put default Chromedriver back in.
      self.move_chrome_driver_if_needed('chrome')

    @staticmethod
    def get_dromaeo_url_query(browser, version):
      if browser == 'dartium':
        version = version.replace('frog', 'dart')
      version = version.replace('_','&')
      tags = DromaeoTester.get_valid_dromaeo_tags()
      return '|'.join([ '%s&%s' % (version, tag) for tag in tags])


  class DromaeoFileProcessor(Processor):
    def process_file(self, afile, should_post_file):
      """Comb through the html to find the performance results.
      Returns: True if we successfully posted our data to storage."""
      parts = afile.split('-')
      browser = parts[2]
      version = parts[3]

      bench_dict = self.test.values_dict[browser][version]

      f = self.open_trace_file(afile, should_post_file)
      lines = f.readlines()
      i = 0
      revision_num = 0
      revision_pattern = r'Revision: (\d+)'
      suite_pattern = r'<div class="result-item done">(.+?)</ol></div>'
      result_pattern = r'<b>(.+?)</b>(.+?)<small> runs/s(.+)'

      upload_success = True
      for line in lines:
        rev = re.match(revision_pattern, line.strip())
        if rev:
          revision_num = int(rev.group(1))
          continue

        suite_results = re.findall(suite_pattern, line)
        if suite_results:
          for suite_result in suite_results:
            results = re.findall(r'<li>(.*?)</li>', suite_result)
            if results:
              for result in results:
                r = re.match(result_pattern, result)
                name = DromaeoTester.legalize_filename(r.group(1).strip(':'))
                score = float(r.group(2))
                bench_dict[name] += [float(score)]
                self.test.revision_dict[browser][version][name] += \
                    [revision_num]
                if not self.test.test_runner.no_upload and should_post_file:
                  upload_success = upload_success and self.report_results(
                      name, score, browser, version, revision_num,
                      self.get_score_type(name))
                else:
                  upload_success = False

      f.close()
      self.calculate_geometric_mean(browser, version, revision_num)
      return upload_success

class TestBuilder(object):
  """Construct the desired test object."""
  available_suites = dict((suite.name(), suite) for suite in [
      CommonBrowserTest, DromaeoTest])

  @staticmethod
  def make_test(test_name, test_runner):
    return TestBuilder.available_suites[test_name](test_runner)

  @staticmethod
  def available_suite_names():
    return TestBuilder.available_suites.keys()

def search_for_revision(directory = None):
  """Find the current revision number in the desired directory. If directory is
  None, find the revision number in the current directory."""
  def find_revision(svn_info_command):
    p = subprocess.Popen(svn_info_command, stdout = subprocess.PIPE,
                         stderr = subprocess.STDOUT,
                         shell = (platform.system() == 'Windows'))
    output, _ = p.communicate()
    for line in output.split('\n'):
      if 'Revision' in line:
        return int(line.split()[1])
    return -1

  cwd = os.getcwd()
  if not directory:
    directory = cwd
  os.chdir(directory)
  revision_num = int(find_revision(['svn', 'info']))
  if revision_num == -1:
    revision_num = int(find_revision(['git', 'svn', 'info']))
  os.chdir(cwd)
  return str(revision_num)

def update_set_of_done_cls(revision_num=None):
  """Update the set of CLs that do not need additional performance runs.
  Args:
  revision_num: an additional number to be added to the 'done set'
  """
  filename = os.path.join(TOP_LEVEL_DIR, 'cached_results.txt')
  if not os.path.exists(filename):
    f = open(filename, 'w')
    results = set()
    pickle.dump(results, f)
    f.close()
  f = open(filename, 'r+')
  result_set = pickle.load(f)
  if revision_num:
    f.seek(0)
    result_set.add(revision_num)
    pickle.dump(result_set, f)
  f.close()
  return result_set

def fill_in_back_history(results_set, runner):
  """Fill in back history performance data. This is done one of two ways, with
  equal probability of trying each way (falling back on the sequential version
  as our data becomes more densely populated)."""
  has_run_extra = False
  revision_num = int(search_for_revision(DART_REPO_LOC))

  def try_to_run_additional(revision_number):
    """Determine the number of results we have stored for a particular revision
    number, and if it is less than 10, run some extra tests.
    Args: 
      - revision_number: the revision whose performance we want to potentially
        test.
    Returns: True if we successfully ran some additional tests."""
    if not runner.has_interesting_code(revision_number):
      results_set = update_set_of_done_cls(revision_number)
      return False
    a_test = TestBuilder.make_test(runner.suite_names[0], runner)
    benchmark_name = a_test.values_list[0]
    platform_name = a_test.platform_list[0]
    variant = a_test.values_dict[platform_name].keys()[0]
    num_results = post_results.get_num_results(benchmark_name,
        platform_name, variant, revision_number,
        a_test.file_processor.get_score_type(benchmark_name))
    if num_results < 10:
      # Run at most two more times.
      if num_results > 8:
        reruns = 10 - num_results
      else:
        reruns = 2
      run = runner.run_test_sequence(revision_num=str(revision_number),
          num_reruns=reruns)
    if num_results >= 10 or run == 0 and num_results + reruns >= 10:
      results_set = update_set_of_done_cls(revision_number)
    else:
      return False
    return True

  if random.choice([True, False]):
    # Select a random CL number, with greater likelihood of selecting a CL in
    # the more recent history than the distant past (using a simplified weighted
    # bucket algorithm). If that CL has less than 10 runs, run additional. If it
    # already has 10 runs, look for another CL number that is not yet have all
    # of its additional runs (do this up to 15 times).
    tries = 0
    # Select which "thousands bucket" we're going to run additional tests for.
    bucket_size = 1000
    thousands_list = range(1, int(revision_num)/bucket_size + 1)
    weighted_total = sum(thousands_list)
    generated_random_number = random.randint(0, weighted_total - 1)
    for i in list(reversed(thousands_list)):
      thousands = thousands_list[i - 1]
      weighted_total -= thousands_list[i - 1]
      if weighted_total <= generated_random_number:
        break
    while tries < 15 and not has_run_extra:
      # Now select a particular revision in that bucket.
      if thousands == int(revision_num)/bucket_size:
        max_range = 1 + revision_num % bucket_size
      else:
        max_range = bucket_size
      rev = thousands * bucket_size + random.randrange(0, max_range)
      if rev not in results_set:
        has_run_extra = try_to_run_additional(rev)
      tries += 1

  if not has_run_extra:
    # Try to get up to 10 runs of each CL, starting with the most recent
    # CL that does not yet have 10 runs. But only perform a set of extra
    # runs at most 2 at a time before checking to see if new code has been
    # checked in.
    while revision_num > 0 and not has_run_extra:
      if revision_num not in results_set:
        has_run_extra = try_to_run_additional(revision_num)
      revision_num -= 1
  if not has_run_extra:
    # No more extra back-runs to do (for now). Wait for new code.
    time.sleep(200)
  return results_set

def main():
  runner = TestRunner()
  continuous = runner.parse_args()

  if not os.path.exists(DART_REPO_LOC):
    os.mkdir(dirname(DART_REPO_LOC))
    os.chdir(dirname(DART_REPO_LOC))
    p = subprocess.Popen('gclient config https://dart.googlecode.com/svn/' +
                         'branches/bleeding_edge/deps/all.deps',
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                         shell=True)
    p.communicate()
  if continuous:
    while True:
      results_set = update_set_of_done_cls()
      if runner.has_interesting_code():
        runner.run_test_sequence()
      else:
        results_set = fill_in_back_history(results_set, runner)
  else:
    runner.run_test_sequence()

if __name__ == '__main__':
  main()
