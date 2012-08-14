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
        mode = 'a'
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

  def get_archive(archive_name):
    """Wrapper around the pulling down a specific archive from Google Storage.
    Adds a specific revision argument as needed.
    Returns: The stderr from running this command."""
    cmd = ['python', os.path.join(DART_REPO_LOC, 'tools', 'get_archive.py'),
           archive_name]
    if self.current_revision_num != -1:
      cmd += ['-r', revision_num]
    _, stderr = self.test.test_runner.run_cmd(cmd)
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
      revision_num = search_for_revision(['svn', 'info'])
      if revision_num == -1:
        revision_num = search_for_revision(['git', 'svn', 'info'])

    self.current_revision_num = revision_num
    stderr = get_archive('sdk')
    if not os.path.exists(get_archive_path) or 'InvalidUriError' in stderr:
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

  def has_new_code(self):
    """Tests if there are any newer versions of files on the server."""
    if not os.path.exists(DART_REPO_LOC):
      return True
    os.chdir(DART_REPO_LOC)
    # Pass 'p' in if we have a new certificate for the svn server, we want to
    # (p)ermanently accept it.
    results, _ = self.run_cmd(['svn', 'st', '-u'], std_in='p\r\n')
    for line in results:
      if '*' in line:
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
      revision = search_for_revision(['svn', 'info'])
      if revision == -1:
        revision = search_for_revision(['git', 'svn', 'info'])
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
    """Calculate the aggregate geometric mean for JS and frog benchmark sets,
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
        'browser', ['js', 'frog', 'dart2js'],
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
    return ['js', 'dart2js_dom', 'dart2js_html']


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
      self.test.test_runner.run_cmd(['python', os.path.join(
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


class DromaeoSizeTest(Test):
  """Run tests to determine the compiled file output size of Dromaeo."""
  def __init__(self, test_runner):
    super(DromaeoSizeTest, self).__init__(
        self.name(),
        ['commandline'], ['dart', 'frog_dom', 'frog_html',
         'frog_htmlidiomatic'],
        DromaeoTester.DROMAEO_BENCHMARKS.keys(), test_runner, 
        self.DromaeoSizeTester(self),
        self.DromaeoSizeProcessor(self), extra_metrics=['sum'])
  
  @staticmethod
  def name():
    return 'dromaeo-size'


  class DromaeoSizeTester(DromaeoTester):
    def run_tests(self):
      # Build tests.
      dromaeo_path = os.path.join('samples', 'third_party', 'dromaeo')
      current_path = os.getcwd()
      os.chdir(dromaeo_path)
      self.test.test_runner.run_cmd(
          ['python', os.path.join('generate_dart2js_tests.py')])
      self.test.test_runner.get_archive('dartium')
      os.chdir(current_path)

      self.test.trace_file = os.path.join(TOP_LEVEL_DIR,
          'tools', 'testing', 'perf_testing', self.test.result_folder_name,
          self.test.result_folder_name + self.test.cur_time)
      self.add_svn_revision_to_trace(self.test.trace_file)

      variants = [
          ('frog_dom', ''),
          ('frog_html', '-html'),
          ('frog_htmlidiomatic', '-htmlidiomatic')]

      test_path = os.path.join(dromaeo_path, 'tests')
      frog_path = os.path.join(test_path, 'frog')
      total_size = {}
      for (variant, _) in variants:
        total_size[variant] = 0
      total_dart_size = 0
      for suite in DromaeoTester.DROMAEO_BENCHMARKS.keys():
        dart_size = 0
        try:
          dart_size = os.path.getsize(os.path.join(test_path,
                                                   'dom-%s.dart' % suite))
        except OSError:
          pass #If compilation failed, continue on running other tests.

        total_dart_size += dart_size
        self.test.test_runner.run_cmd(
            ['echo', 'Size (dart, %s): %s' % (suite, str(dart_size))],
            self.test.trace_file, append=True)

        for (variant, suffix) in variants:
          name = 'dom-%s%s.dart.js' % (suite, suffix)
          js_size = 0
          try:
            # TODO(vsm): Strip comments at least.  Consider compression.
            js_size = os.path.getsize(os.path.join(frog_path, name))
          except OSError:
            pass #If compilation failed, continue on running other tests.

          total_size[variant] += js_size
          self.test.test_runner.run_cmd(
              ['echo', 'Size (%s, %s): %s' % (variant, suite, str(js_size))],
              self.test.trace_file, append=True)

      self.test.test_runner.run_cmd(
          ['echo', 'Size (dart, %s): %s' % (total_dart_size,
                                            self.test.extra_metrics[0])],
          self.test.trace_file, append=True)
      for (variant, _) in variants:
        self.test.test_runner.run_cmd(
            ['echo', 'Size (%s, %s): %s' % (variant, self.test.extra_metrics[0],
                                            total_size[variant])],
            self.test.trace_file, append=True)


  class DromaeoSizeProcessor(Processor):
    def process_file(self, afile, should_post_file):
      """Pull all the relevant information out of a given tracefile.

      Args:
        afile: is the filename string we will be processing.
      Returns: True if we successfully posted our data to storage."""
      os.chdir(os.path.join(TOP_LEVEL_DIR, 'tools',
          'testing', 'perf_testing'))
      f = self.open_trace_file(afile, should_post_file)
      tabulate_data = False
      revision_num = 0
      revision_pattern = r'Revision: (\d+)'
      result_pattern = r'Size \((\w+), ([a-zA-Z0-9-]+)\): (\d+)'

      upload_success = True
      for line in f.readlines():
        rev = re.match(revision_pattern, line.strip())
        if rev:
          revision_num = int(rev.group(1))
          continue

        result = re.match(result_pattern, line.strip())
        if result:
          variant = result.group(1)
          metric = result.group(2)
          num = result.group(3)
          if num.find('.') == -1:
            num = int(num)
          else:
            num = float(num)
          self.test.values_dict['commandline'][variant][metric] += [num]
          self.test.revision_dict['commandline'][variant][metric] += \
              [revision_num]
          if not self.test.test_runner.no_upload and should_post_file:
            upload_success = upload_success and self.report_results(
                metric, num, 'commandline', variant, revision_num,
                self.get_score_type(metric))
          else:
            upload_success = False

      f.close()
      return upload_success
    
    def get_score_type(self, metric):
      return self.CODE_SIZE


class CompileTimeAndSizeTest(Test):
  """Run tests to determine how long frogc takes to compile, and the compiled
  file output size of some benchmarking files.
  Note: This test is now 'deprecated' since frog is no longer in the sdk. We
  just return the last numbers found for frog."""
  def __init__(self, test_runner):
    """Reference to the test_runner object that notifies us when to begin
    testing."""
    super(CompileTimeAndSizeTest, self).__init__(
        self.name(), ['commandline'], ['dart2js'], ['swarm'],
        test_runner, self.CompileTester(self),
        self.CompileProcessor(self))
    self.dart_compiler = os.path.join(
        DART_REPO_LOC, utils.GetBuildRoot(utils.GuessOS(),
        'release', 'ia32'), 'dart-sdk', 'bin', 'dart2js')
    _suffix = ''
    if platform.system() == 'Windows':
      _suffix = '.exe'
    self.failure_threshold = {'swarm' : 100}

  @staticmethod
  def name():
    return 'time-size'

  class CompileTester(Tester):
    def run_tests(self):
      self.test.trace_file = os.path.join(TOP_LEVEL_DIR,
          'tools', 'testing', 'perf_testing', 
          self.test.result_folder_name,
          self.test.result_folder_name + self.test.cur_time)

      self.add_svn_revision_to_trace(self.test.trace_file)

      self.test.test_runner.run_cmd(
          ['./xcodebuild/ReleaseIA32/dart-sdk/dart2js', '-c', '-o',
           'swarm-result', os.path.join('samples', 'swarm', 'swarm.dart')])
      swarm_size = 0
      try:
        swarm_size = os.path.getsize('swarm-result')
      except OSError:
        pass #If compilation failed, continue on running other tests.

      self.test.test_runner.run_cmd(
          ['echo', '%d Generated checked swarm size' % swarm_size],
          self.test.trace_file, append=True)

  class CompileProcessor(Processor):
    def process_file(self, afile, should_post_file):
      """Pull all the relevant information out of a given tracefile.

      Args:
        afile: is the filename string we will be processing.
      Returns: True if we successfully posted our data to storage."""
      os.chdir(os.path.join(TOP_LEVEL_DIR, 'tools',
          'testing', 'perf_testing'))
      f = self.open_trace_file(afile, should_post_file)
      tabulate_data = False
      revision_num = 0
      upload_success = True
      for line in f.readlines():
        tokens = line.split()
        if 'Revision' in line:
          revision_num = int(line.split()[1])
        else:
          for metric in self.test.values_list:
            if metric in line:
              num = tokens[0]
              if num.find('.') == -1:
                num = int(num)
              else:
                num = float(num)
              self.test.values_dict['commandline']['dart2js'][metric] += [num]
              self.test.revision_dict['commandline']['dart2js'][metric] += \
                  [revision_num]
              score_type = self.get_score_type(metric)
              if not self.test.test_runner.no_upload and should_post_file:
                if num < self.test.failure_threshold[metric]:
                  num = 0
                upload_success = upload_success and self.report_results(
                    metric, num, 'commandline', 'dart2js', revision_num,
                    score_type)
              else:
                upload_success = False
      if revision_num != 0:
        for metric in self.test.values_list:
          try:
            self.test.revision_dict['commandline']['dart2js'][metric].pop()
            self.test.revision_dict['commandline']['dart2js'][metric] += \
                [revision_num]
            # Fill in 0 if compilation failed.
            if self.test.values_dict['commandline']['dart2js'][metric][-1] < \
                self.test.failure_threshold[metric]:
              self.test.values_dict['commandline']['dart2js'][metric] += [0]
              self.test.revision_dict['commandline']['dart2js'][metric] += \
                  [revision_num]
          except IndexError:
            # We tried to pop from an empty list. This happens if the first
            # trace file we encounter is incomplete.
            pass

      f.close()
      return upload_success

    def get_score_type(self, metric):
      if 'Compiling' in metric or 'Bootstrapping' in metric:
        return self.COMPILE_TIME
      return self.CODE_SIZE

class TestBuilder(object):
  """Construct the desired test object."""
  available_suites = dict((suite.name(), suite) for suite in [
      CompileTimeAndSizeTest, CommonBrowserTest, DromaeoTest, DromaeoSizeTest])

  @staticmethod
  def make_test(test_name, test_runner):
    return TestBuilder.available_suites[test_name](test_runner)

  @staticmethod
  def available_suite_names():
    return TestBuilder.available_suites.keys()

def search_for_revision(svn_info_command):
  p = subprocess.Popen(svn_info_command, stdout = subprocess.PIPE,
                       stderr = subprocess.STDOUT,
                       shell = (platform.system() == 'Windows'))
  output, _ = p.communicate()
  for line in output.split('\n'):
    if 'Revision' in line:
      return line.split()[1]
  return -1

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
      if runner.has_new_code():
        runner.run_test_sequence()
      else:
        # Try to get up to 10 runs of each CL, starting with the most recent CL
        # that does not yet have 10 runs. But only perform a set of extra runs
        # at most 10 at a time (get all the extra runs for one CL) before
        # checking to see if new code has been checked in.
        has_run_extra = False
        revision_num = int(search_for_revision(['svn', 'info']))
        if revision_num == -1:
          revision_num = int(search_for_revision(['git', 'svn', 'info']))
        
        # No need to track the performance before revision 3000. That's way in
        # the past.
        while revision_num > 3000 and not has_run_extra:
          if revision_num not in results_set:
            a_test = TestBuilder.make_test(runner.suite_names[0], runner)
            benchmark_name = a_test.values_list[0]
            platform_name = a_test.platform_list[0]
            variant = a_test.values_dict[platform_name].keys()[0]
            number_of_results = post_results.get_num_results(benchmark_name,
                platform_name, variant, revision_num,
                a_test.file_processor.get_score_type(benchmark_name))
            if number_of_results < 10 and number_of_results >= 0:
              run = runner.run_test_sequence(revision_num=str(revision_num),
                  num_reruns=(10-number_of_results))
              if run == 0:
                has_run_extra = True
                results_set = update_set_of_done_cls(revision_num)
          revision_num -= 1
        # No more extra back-runs to do (for now). Wait for new code.
        time.sleep(200)
  else:
    runner.run_test_sequence()

if __name__ == '__main__':
  main()
