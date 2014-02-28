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
# How far back in time we want to test.
EARLIEST_REVISION = 33076
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
    self.current_revision_num = None

  def RunCmd(self, cmd_list, outfile=None, append=False, std_in=''):
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

  def TimeCmd(self, cmd):
    """Determine the amount of (real) time it takes to execute a given
    command."""
    start = time.time()
    self.RunCmd(cmd)
    return time.time() - start

  def ClearOutUnversionedFiles(self):
    """Remove all files that are unversioned by svn."""
    if os.path.exists(DART_REPO_LOC):
      os.chdir(DART_REPO_LOC)
      results, _ = self.RunCmd(['svn', 'st'])
      for line in results.split('\n'):
        if line.startswith('?'):
          to_remove = line.split()[1]
          if os.path.isdir(to_remove):
            shutil.rmtree(to_remove, onerror=TestRunner._OnRmError)
          else:
            os.remove(to_remove)
        elif any(line.startswith(status) for status in ['A', 'M', 'C', 'D']):
          self.RunCmd(['svn', 'revert', line.split()[1]])

  def GetArchive(self, archive_name):
    """Wrapper around the pulling down a specific archive from Google Storage.
    Adds a specific revision argument as needed.
    Returns: A tuple of a boolean (True if we successfully downloaded the
    binary), and the stdout and stderr from running this command."""
    num_fails = 0
    while True:
      cmd = ['python', os.path.join(DART_REPO_LOC, 'tools', 'get_archive.py'),
             archive_name]
      if int(self.current_revision_num) != -1:
        cmd += ['-r', str(self.current_revision_num)]
      stdout, stderr = self.RunCmd(cmd)
      if 'Please try again later' in stdout and num_fails < 20:
        time.sleep(100)
        num_fails += 1
      else:
        break
    return (num_fails < 20, stdout, stderr)

  def _Sync(self, revision_num=None):
    """Update the repository to the latest or specified revision."""
    os.chdir(dirname(DART_REPO_LOC))
    self.ClearOutUnversionedFiles()
    if not revision_num:
      self.RunCmd(['gclient', 'sync'])
    else:
      self.RunCmd(['gclient', 'sync', '-r', str(revision_num), '-t'])

    shutil.copytree(os.path.join(TOP_LEVEL_DIR, 'internal'),
                    os.path.join(DART_REPO_LOC, 'internal'))
    shutil.rmtree(os.path.join(DART_REPO_LOC, 'third_party', 'gsutil'),
                  onerror=TestRunner._OnRmError)
    shutil.copytree(os.path.join(TOP_LEVEL_DIR, 'third_party', 'gsutil'),
                    os.path.join(DART_REPO_LOC, 'third_party', 'gsutil'))
    shutil.copy(os.path.join(TOP_LEVEL_DIR, 'tools', 'get_archive.py'),
                    os.path.join(DART_REPO_LOC, 'tools', 'get_archive.py'))
    shutil.copy(
        os.path.join(TOP_LEVEL_DIR, 'tools', 'testing', 'run_selenium.py'),
        os.path.join(DART_REPO_LOC, 'tools', 'testing', 'run_selenium.py'))

  @staticmethod
  def _OnRmError(func, path, exc_info):
    """On Windows, the output directory is marked as "Read Only," which causes
    an error to be thrown when we use shutil.rmtree. This helper function
    changes the permissions so we can still delete the directory."""
    if os.path.exists(path):
      os.chmod(path, stat.S_IWRITE)
      os.unlink(path)

  def SyncAndBuild(self, suites, revision_num=None):
    """Make sure we have the latest version of of the repo, and build it. We
    begin and end standing in DART_REPO_LOC.

    Args:
      suites: The set of suites that we wish to build.

    Returns:
      err_code = 1 if there was a problem building."""
    self._Sync(revision_num)
    if not revision_num:
      revision_num = SearchForRevision()

    self.current_revision_num = revision_num
    success, stdout, stderr = self.GetArchive('sdk')
    if (not os.path.exists(os.path.join(
        DART_REPO_LOC, 'tools', 'get_archive.py')) or not success
        or 'InvalidUriError' in stderr or "Couldn't download" in stdout or
        'Unable to download' in stdout):
      # Couldn't find the SDK on Google Storage. Build it locally.

      # TODO(efortuna): Currently always building ia32 architecture because we
      # don't have test statistics for what's passing on x64. Eliminate arch
      # specification when we have tests running on x64, too.
      shutil.rmtree(os.path.join(os.getcwd(),
                    utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32')),
                    onerror=TestRunner._OnRmError)
      lines = self.RunCmd([os.path.join('.', 'tools', 'build.py'), '-m',
                            'release', '--arch=ia32', 'create_sdk'])

      for line in lines:
        if 'BUILD FAILED' in line:
          # Someone checked in a broken build! Stop trying to make it work
          # and wait to try again.
          print 'Broken Build'
          return 1
    return 0

  def EnsureOutputDirectory(self, dir_name):
    """Test that the listed directory name exists, and if not, create one for
    our output to be placed.

    Args:
      dir_name: the directory we will create if it does not exist."""
    dir_path = os.path.join(TOP_LEVEL_DIR, 'tools',
                            'testing', 'perf_testing', dir_name)
    if not os.path.exists(dir_path):
      os.makedirs(dir_path)
      print 'Creating output directory ', dir_path

  def HasInterestingCode(self, revision_num=None):
    """Tests if there are any versions of files that might change performance
    results on the server.

    Returns:
       (False, None): There is no interesting code to run.
       (True, revisionNumber): There is interesting code to run at revision
                              revisionNumber.
       (True, None): There is interesting code to run by syncing to the
                     tip-of-tree."""
    if not os.path.exists(DART_REPO_LOC):
      self._Sync()
    os.chdir(DART_REPO_LOC)
    no_effect = ['dart/client', 'dart/compiler', 'dart/editor',
                 'dart/lib/html/doc', 'dart/pkg', 'dart/tests', 'dart/samples',
                 'dart/lib/dartdoc', 'dart/lib/i18n', 'dart/lib/unittest',
                 'dart/tools/dartc', 'dart/tools/get_archive.py',
                 'dart/tools/test.py', 'dart/tools/testing',
                 'dart/tools/utils', 'dart/third_party', 'dart/utils']
    definitely_yes = ['dart/samples/third_party/dromaeo',
                      'dart/lib/html/dart2js', 'dart/lib/html/dartium',
                      'dart/lib/scripts', 'dart/lib/src',
                      'dart/third_party/WebCore']
    def GetFileList(revision):
      """Determine the set of files that were changed for a particular
      revision."""
      # TODO(efortuna): This assumes you're using svn. Have a git fallback as
      # well. Pass 'p' in if we have a new certificate for the svn server, we
      # want to (p)ermanently accept it.
      results, _ = self.RunCmd([
          'svn', 'log', 'http://dart.googlecode.com/svn/branches/bleeding_edge',
          '-v', '-r', str(revision)], std_in='p\r\n')
      results = results.split('\n')
      if len(results) <= 3:
        return []
      else:
        # Trim off the details about revision number and commit message. We're
        # only interested in the files that are changed.
        results = results[3:]
        changed_files = []
        for result in results:
          if len(result) <= 1:
            break
          tokens = result.split()
          if len(tokens) > 1:
            changed_files += [tokens[1].replace('/branches/bleeding_edge/', '')]
        return changed_files

    def HasPerfAffectingResults(files_list):
      """Determine if this set of changed files might effect performance
      tests."""
      def IsSafeFile(f):
        if not any(f.startswith(prefix) for prefix in definitely_yes):
          return any(f.startswith(prefix) for prefix in no_effect)
        return False
      return not all(IsSafeFile(f) for f in files_list)

    if revision_num:
      return (HasPerfAffectingResults(GetFileList(
          revision_num)), revision_num)
    else:
      latest_interesting_server_rev = None
      while not latest_interesting_server_rev:
        results, _ = self.RunCmd(['svn', 'st', '-u'], std_in='p\r\n')
        if len(results.split('\n')) >= 2:
          latest_interesting_server_rev = int(
              results.split('\n')[-2].split()[-1])
      if self.backfill:
        done_cls = list(UpdateSetOfDoneCls())
        done_cls.sort()
        if done_cls:
          last_done_cl = int(done_cls[-1])
        else:
          last_done_cl = EARLIEST_REVISION
        while latest_interesting_server_rev >= last_done_cl:
          file_list = GetFileList(latest_interesting_server_rev)
          if HasPerfAffectingResults(file_list):
            return (True, latest_interesting_server_rev)
          else:
            UpdateSetOfDoneCls(latest_interesting_server_rev)
          latest_interesting_server_rev -= 1
      else:
        last_done_cl = int(SearchForRevision(DART_REPO_LOC)) + 1
        while last_done_cl <= latest_interesting_server_rev:
          file_list = GetFileList(last_done_cl)
          if HasPerfAffectingResults(file_list):
            return (True, last_done_cl)
          else:
            UpdateSetOfDoneCls(last_done_cl)
          last_done_cl += 1
      return (False, None)

  def GetOsDirectory(self):
    """Specifies the name of the directory for the testing build of dart, which
    has yet a different naming convention from utils.getBuildRoot(...)."""
    if platform.system() == 'Windows':
      return 'windows'
    elif platform.system() == 'Darwin':
      return 'macos'
    else:
      return 'linux'

  def ParseArgs(self):
    parser = optparse.OptionParser()
    parser.add_option('--suites', '-s', dest='suites', help='Run the specified '
                      'comma-separated test suites from set: %s' % \
                      ','.join(TestBuilder.AvailableSuiteNames()),
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
    parser.add_option('--verbose', '-v', dest='verbose',
                      help='Print extra debug output', action='store_true',
                      default=False)
    parser.add_option('--backfill', '-b', dest='backfill',
                      help='Backfill earlier CLs with additional results when '
                      'there is idle time.', action='store_true',
                      default=False)

    args, ignored = parser.parse_args()

    if not args.suites:
      suites = TestBuilder.AvailableSuiteNames()
    else:
      suites = []
      suitelist = args.suites.split(',')
      for name in suitelist:
        if name in TestBuilder.AvailableSuiteNames():
          suites.append(name)
        else:
          print ('Error: Invalid suite %s not in ' % name) + \
              '%s' % ','.join(TestBuilder.AvailableSuiteNames())
          sys.exit(1)
    self.suite_names = suites
    self.no_build = args.no_build
    self.no_upload = args.no_upload
    self.no_test = args.no_test
    self.verbose = args.verbose
    self.backfill = args.backfill
    return args.continuous

  def RunTestSequence(self, revision_num=None, num_reruns=1):
    """Run the set of commands to (possibly) build, run, and post the results
    of our tests. Returns 0 on a successful run, 1 if we fail to post results or
    the run failed, -1 if the build is broken.
    """
    suites = []
    success = True
    if not self.no_build and self.SyncAndBuild(suites, revision_num) == 1:
      return -1 # The build is broken.

    if not self.current_revision_num:
      self.current_revision_num = SearchForRevision(DART_REPO_LOC)

    for name in self.suite_names:
      for run in range(num_reruns):
        suites += [TestBuilder.MakeTest(name, self)]

    for test in suites:
      success = success and test.Run()
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

  def IsValidCombination(self, platform, variant):
    """Check whether data should be captured for this platform/variant
    combination.
    """
    if variant == 'dart_html' and platform != 'dartium':
      return False
    if platform == 'dartium' and (variant == 'js' or variant == 'dart2js_html'):
      # Testing JavaScript performance on Dartium is a waste of time. Should be
      # same as Chrome.
      return False
    if (platform == 'safari' and variant == 'dart2js' and
        int(self.test_runner.current_revision_num) < 10193):
      # In revision 10193 we fixed a bug that allows Safari 6 to run dart2js
      # code. Since we can't change the Safari version on the machine, we're
      # just not running
      # for this case.
      return False
    return True

  def Run(self):
    """Run the benchmarks/tests from the command line and plot the
    results.
    """
    for visitor in [self.tester, self.file_processor]:
      visitor.Prepare()

    os.chdir(TOP_LEVEL_DIR)
    self.test_runner.EnsureOutputDirectory(self.result_folder_name)
    self.test_runner.EnsureOutputDirectory(os.path.join(
        'old', self.result_folder_name))
    os.chdir(DART_REPO_LOC)
    if not self.test_runner.no_test:
      self.tester.RunTests()

    os.chdir(os.path.join(TOP_LEVEL_DIR, 'tools', 'testing', 'perf_testing'))

    files = os.listdir(self.result_folder_name)
    post_success = True
    for afile in files:
      if not afile.startswith('.'):
        should_move_file = self.file_processor.ProcessFile(afile, True)
        if should_move_file:
          shutil.move(os.path.join(self.result_folder_name, afile),
                      os.path.join('old', self.result_folder_name, afile))
        else:
          post_success = False

    return post_success


class Tester(object):
  """The base level visitor class that runs tests. It contains convenience
  methods that many Tester objects use. Any class that would like to be a
  TesterVisitor must implement the RunTests() method."""

  def __init__(self, test):
    self.test = test

  def Prepare(self):
    """Perform any initial setup required before the test is run."""
    pass

  def AddSvnRevisionToTrace(self, outfile, browser = None):
    """Add the svn version number to the provided tracefile."""
    def get_dartium_revision():
      version_file_name = os.path.join(DART_REPO_LOC, 'client', 'tests',
                                       'dartium', 'LAST_VERSION')
      try:
        version_file = open(version_file_name, 'r')
        version = version_file.read().split('.')[-3].split('-')[-1]
        version_file.close()
        return version
      except IOError as e:
        dartium_dir = os.path.join(DART_REPO_LOC, 'client', 'tests', 'dartium')
        if (os.path.exists(os.path.join(dartium_dir, 'Chromium.app', 'Contents',
            'MacOS', 'Chromium') or os.path.exists(os.path.join(dartium_dir,
            'chrome.exe'))) or
            os.path.exists(os.path.join(dartium_dir, 'chrome'))):
          print "Error: VERSION file wasn't found."
          return SearchForRevision()
        else:
          raise

    if browser and browser == 'dartium':
      revision = get_dartium_revision()
      self.test.test_runner.RunCmd(['echo', 'Revision: ' + revision], outfile)
    else:
      revision = SearchForRevision()
      self.test.test_runner.RunCmd(['echo', 'Revision: ' + revision], outfile)


class Processor(object):
  """The base level vistor class that processes tests. It contains convenience
  methods that many File Processor objects use. Any class that would like to be
  a ProcessorVisitor must implement the ProcessFile() method."""

  SCORE = 'Score'
  COMPILE_TIME = 'CompileTime'
  CODE_SIZE = 'CodeSize'

  def __init__(self, test):
    self.test = test

  def Prepare(self):
    """Perform any initial setup required before the test is run."""
    pass

  def OpenTraceFile(self, afile, not_yet_uploaded):
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

  def ReportResults(self, benchmark_name, score, platform, variant,
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

  def CalculateGeometricMean(self, platform, variant, svn_revision):
    """Calculate the aggregate geometric mean for JS and dart2js benchmark sets,
    given two benchmark dictionaries."""
    geo_mean = 0
    if self.test.IsValidCombination(platform, variant):
      for benchmark in self.test.values_list:
        if not self.test.values_dict[platform][variant][benchmark]:
          print 'Error determining mean for %s %s %s' % (platform, variant,
                                                         benchmark)
          continue
        geo_mean += math.log(
            self.test.values_dict[platform][variant][benchmark][-1])

    self.test.values_dict[platform][variant]['Geo-Mean'] += \
        [math.pow(math.e, geo_mean / len(self.test.values_list))]
    self.test.revision_dict[platform][variant]['Geo-Mean'] += [svn_revision]

  def GetScoreType(self, benchmark_name):
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
  def GetBrowsers(add_dartium=True):
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
  def LegalizeFilename(str):
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
  def GetValidDromaeoTags():
    tags = [tag for (tag, _) in DromaeoTester.DROMAEO_BENCHMARKS.values()]
    if platform.system() == 'Darwin' or platform.system() == 'Windows':
      tags.remove('modify')
    return tags

  @staticmethod
  def GetDromaeoBenchmarks():
    valid = DromaeoTester.GetValidDromaeoTags()
    benchmarks = reduce(lambda l1,l2: l1+l2,
                        [tests for (tag, tests) in
                         DromaeoTester.DROMAEO_BENCHMARKS.values()
                         if tag in valid])
    return map(DromaeoTester.LegalizeFilename, benchmarks)

  @staticmethod
  def GetDromaeoVersions():
    return ['js', 'dart2js_html', 'dart_html']


class DromaeoTest(RuntimePerformanceTest):
  """Runs Dromaeo tests, in the browser."""
  def __init__(self, test_runner):
    super(DromaeoTest, self).__init__(
        self.Name(),
        BrowserTester.GetBrowsers(True),
        'browser',
        DromaeoTester.GetDromaeoVersions(),
        DromaeoTester.GetDromaeoBenchmarks(), test_runner,
        self.DromaeoPerfTester(self),
        self.DromaeoFileProcessor(self))

  @staticmethod
  def Name():
    return 'dromaeo'

  class DromaeoPerfTester(DromaeoTester):
    def RunTests(self):
      """Run dromaeo in the browser."""
      success, _, _ = self.test.test_runner.GetArchive('dartium')
      if not success:
        # Unable to download dartium. Try later.
        return

      # Build tests.
      dromaeo_path = os.path.join('samples', 'third_party', 'dromaeo')
      current_path = os.getcwd()
      os.chdir(dromaeo_path)
      stdout, _ = self.test.test_runner.RunCmd(
          ['python', 'generate_perf_and_dart2js_tests.py'])
      os.chdir(current_path)
      if 'Error: Compilation failed' in stdout:
        return
      versions = DromaeoTester.GetDromaeoVersions()

      for browser in BrowserTester.GetBrowsers():
        for version_name in versions:
          if not self.test.IsValidCombination(browser, version_name):
            continue
          version = DromaeoTest.DromaeoPerfTester.GetDromaeoUrlQuery(
              browser, version_name)
          self.test.trace_file = os.path.join(TOP_LEVEL_DIR,
              'tools', 'testing', 'perf_testing', self.test.result_folder_name,
              'dromaeo-%s-%s-%s' % (self.test.cur_time, browser, version_name))
          self.AddSvnRevisionToTrace(self.test.trace_file, browser)
          url_path = '/'.join(['/root_dart', dromaeo_path, 'index%s.html?%s'% (
              '-dart' if version_name == 'dart_html' else '-js',
              version)])

          # TODO(efortuna): Make this a separate function. We should do this
          # once per cycle.
          os.chdir(os.path.join(DART_REPO_LOC, 'tools', 'testing', 'dart',
              'browser_perf_testing'))
          self.test.test_runner.RunCmd([os.path.join(DART_REPO_LOC,
              utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32'),
              'dart-sdk', 'bin', 'pub'), 'install'])
          os.chdir(current_path)

          self.test.test_runner.RunCmd(
              [os.path.join(utils.GetBuildRoot(
               utils.GuessOS(), 'release', 'ia32'), 'dart-sdk', 'bin', 'dart'),
               '--package-root=%s' % os.path.join(DART_REPO_LOC, 'tools',
               'testing', 'dart', 'browser_perf_testing', 'packages'),
               os.path.join('tools', 'testing', 'dart', 'browser_perf_testing',
               'lib', 'browser_perf_testing.dart'),
               '--browser', browser, '--termination_test_file',
               '/root_dart/samples/third_party/dromaeo/dromaeo_end_condition.'
               'js', '--test_path', url_path], self.test.trace_file,
               append=True)

    @staticmethod
    def GetDromaeoUrlQuery(browser, version):
      version = version.replace('_','AND')
      tags = DromaeoTester.GetValidDromaeoTags()
      return 'OR'.join([ '%sAND%s' % (version, tag) for tag in tags])


  class DromaeoFileProcessor(Processor):
    def ProcessFile(self, afile, should_post_file):
      """Comb through the html to find the performance results.
      Returns: True if we successfully posted our data to storage."""
      parts = afile.split('-')
      browser = parts[2]
      version = parts[3]

      bench_dict = self.test.values_dict[browser][version]

      f = self.OpenTraceFile(afile, should_post_file)
      lines = f.readlines()
      i = 0
      revision_num = 0
      revision_pattern = r'Revision: (\d+)'
      suite_pattern = r'<div class="result-item done">(.+?)</ol></div>'
      result_pattern = r'<b>(.+?)</b>(.+?)<small> runs/s(.+)'

      upload_success = True
      for line in lines:
        rev = re.match(revision_pattern, line.strip().replace('"', ''))
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
                name = DromaeoTester.LegalizeFilename(r.group(1).strip(':'))
                score = float(r.group(2))
                bench_dict[name] += [float(score)]
                self.test.revision_dict[browser][version][name] += \
                    [revision_num]
                if not self.test.test_runner.no_upload and should_post_file:
                  upload_success = upload_success and self.ReportResults(
                      name, score, browser, version, revision_num,
                      self.GetScoreType(name))
                else:
                  upload_success = False

      f.close()
      self.CalculateGeometricMean(browser, version, revision_num)
      return upload_success

class TestBuilder(object):
  """Construct the desired test object."""
  available_suites = dict((suite.Name(), suite) for suite in [
      DromaeoTest])

  @staticmethod
  def MakeTest(test_name, test_runner):
    return TestBuilder.available_suites[test_name](test_runner)

  @staticmethod
  def AvailableSuiteNames():
    return TestBuilder.available_suites.keys()


def SearchForRevision(directory = None):
  """Find the current revision number in the desired directory. If directory is
  None, find the revision number in the current directory."""
  def FindRevision(svn_info_command):
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
  revision_num = int(FindRevision(['svn', 'info']))
  if revision_num == -1:
    revision_num = int(FindRevision(['git', 'svn', 'info']))
  os.chdir(cwd)
  return str(revision_num)


def UpdateSetOfDoneCls(revision_num=None):
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


def FillInBackHistory(results_set, runner):
  """Fill in back history performance data. This is done one of two ways, with
  equal probability of trying each way (falling back on the sequential version
  as our data becomes more densely populated)."""
  revision_num = int(SearchForRevision(DART_REPO_LOC))
  has_run_extra = False

  def TryToRunAdditional(revision_number):
    """Determine the number of results we have stored for a particular revision
    number, and if it is less than 10, run some extra tests.
    Args:
      - revision_number: the revision whose performance we want to potentially
        test.
    Returns: True if we successfully ran some additional tests."""
    if not runner.HasInterestingCode(revision_number)[0]:
      results_set = UpdateSetOfDoneCls(revision_number)
      return False
    a_test = TestBuilder.MakeTest(runner.suite_names[0], runner)
    benchmark_name = a_test.values_list[0]
    platform_name = a_test.platform_list[0]
    variant = a_test.values_dict[platform_name].keys()[0]
    num_results = post_results.get_num_results(benchmark_name,
        platform_name, variant, revision_number,
        a_test.file_processor.GetScoreType(benchmark_name))
    if num_results < 10:
      # Run at most two more times.
      if num_results > 8:
        reruns = 10 - num_results
      else:
        reruns = 2
      run = runner.RunTestSequence(revision_num=str(revision_number),
          num_reruns=reruns)
    if num_results >= 10 or run == 0 and num_results + reruns >= 10:
      results_set = UpdateSetOfDoneCls(revision_number)
    elif run != 0:
      return False
    return True

  # Try to get up to 10 runs of each CL, starting with the most recent
  # CL that does not yet have 10 runs. But only perform a set of extra
  # runs at most 2 at a time before checking to see if new code has been
  # checked in.
  while revision_num > EARLIEST_REVISION and not has_run_extra:
    if revision_num not in results_set:
      has_run_extra = TryToRunAdditional(revision_num)
    revision_num -= 1
  if not has_run_extra:
    # No more extra back-runs to do (for now). Wait for new code.
    time.sleep(200)
  return results_set


def main():
  runner = TestRunner()
  continuous = runner.ParseArgs()

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
      results_set = UpdateSetOfDoneCls()
      (is_interesting, interesting_rev_num) = runner.HasInterestingCode()
      if is_interesting:
        runner.RunTestSequence(interesting_rev_num)
      else:
        if runner.backfill:
          results_set = FillInBackHistory(results_set, runner)
        else:
          time.sleep(200)
  else:
    runner.RunTestSequence()

if __name__ == '__main__':
  main()
