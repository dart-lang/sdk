#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import datetime
import getpass
import math
try:
  from matplotlib.font_manager import FontProperties
  import matplotlib.pyplot as plt
except ImportError:
  pass # Only needed if we want to make graphs.
import optparse
import os
from os.path import dirname, abspath
import platform
import re
import shutil
import stat
import subprocess
import sys
import time
import traceback

TOOLS_PATH = os.path.join(dirname(dirname(dirname(abspath(__file__)))))
DART_INSTALL_LOCATION = abspath(os.path.join(dirname(abspath(__file__)),
                                             '..', '..', '..'))
sys.path.append(TOOLS_PATH)
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
    output, stderr = p.communicate(std_in);
    if output:
      print output
    if stderr:
      print stderr
    return output

  def time_cmd(self, cmd):
    """Determine the amount of (real) time it takes to execute a given 
    command."""
    start = time.time()
    self.run_cmd(cmd)
    return time.time() - start

  @staticmethod
  def get_build_targets(suites):
    """Loop through a set of tests that we want to run and find the build
    targets that are necessary.
    
    Args:
      suites: The test suites that we wish to run."""
    build_targets = set()
    for test in suites:
      if test.build_targets is not None:
        for target in test.build_targets:
          build_targets.add(target)
    return build_targets

  def sync_and_build(self, suites):
    """Make sure we have the latest version of of the repo, and build it. We
    begin and end standing in DART_INSTALL_LOCATION.

    Args:
      suites: The set of suites that we wish to build.

    Returns:
      err_code = 1 if there was a problem building."""
    os.chdir(DART_INSTALL_LOCATION)

    self.run_cmd(['gclient', 'sync'])

    # On Windows, the output directory is marked as "Read Only," which causes an
    # error to be thrown when we use shutil.rmtree. This helper function changes
    # the permissions so we can still delete the directory.
    def on_rm_error(func, path, exc_info):
      if os.path.exists(path):
        os.chmod(path, stat.S_IWRITE)
        os.unlink(path)
    # TODO(efortuna): building the sdk locally is a band-aid until all build
    # platform SDKs are hosted in Google storage. Pull from https://sandbox.
    # google.com/storage/?arg=dart-dump-render-tree#dart-dump-render-tree%2Fsdk
    # eventually.
    # TODO(efortuna): Currently always building ia32 architecture because we 
    # don't have test statistics for what's passing on x64. Eliminate arch 
    # specification when we have tests running on x64, too.
    shutil.rmtree(os.path.join(os.getcwd(),
                  utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32')),
                  onerror=on_rm_error)

    for target in TestRunner.get_build_targets(suites):
      lines = self.run_cmd([os.path.join('.', 'tools', 'build.py'), '-m', 
                            'release', '--arch=ia32', target])

      for line in lines:
        if 'BUILD FAILED' in lines:
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
    dir_path = os.path.join(DART_INSTALL_LOCATION, 'tools', 
                            'testing', 'perf_testing', dir_name)
    if not os.path.exists(dir_path):
      os.mkdir(dir_path)
      print 'Creating output directory ', dir_path

  def has_new_code(self):
    """Tests if there are any newer versions of files on the server."""
    os.chdir(DART_INSTALL_LOCATION)
    # Pass 'p' in if we have a new certificate for the svn server, we want to
    # (p)ermanently accept it.
    results = self.run_cmd(['svn', 'st', '-u'], std_in='p')
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

  def upload_to_app_engine(self, suite_names):
    """Upload our results to our appengine server.
    Arguments:
      suite_names: Directories to upload data from (should match directory 
        names)."""
    # TODO(efortuna): This is the most basic way to get the data up
    # for others to view. Revisit this once we're serving nicer graphs (Google
    # Chart Tools) and from multiple perfbots and once we're in a position to
    # organize the data in a useful manner(!!).
    os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools', 'testing',
                          'perf_testing'))
    for data in suite_names:
      path = os.path.join('appengine', 'static', 'data', data, utils.GuessOS())
      shutil.rmtree(path, ignore_errors=True)
      os.makedirs(path)
      files = []
      # Copy the 1000 most recent trace files to be uploaded.
      for f in os.listdir(data):
        files += [(os.path.getmtime(os.path.join(data, f)), f)]
      files.sort()
      for f in files[-1000:]:
        shutil.copyfile(os.path.join(data, f[1]), 
                        os.path.join(path, f[1]+'.txt'))
    # Generate directory listing.
    for data in suite_names:
      path = os.path.join('appengine', 'static', 'data', data, utils.GuessOS())
      out = open(os.path.join('appengine', 'static',
                 '%s-%s.html' % (data, utils.GuessOS())), 'w')
      out.write('<html>\n  <body>\n    <ul>\n')
      for f in os.listdir(path):
        if not f.startswith('.'):
          out.write('      <li><a href=data' + \
                    '''/%(data)s/%(os)s/%(file)s>%(file)s</a></li>\n''' % \
                    {'data': data, 'os': utils.GuessOS(), 'file': f})
      out.write('    </ul>\n  </body>\n</html>')
      out.close()

    shutil.rmtree(os.path.join('appengine', 'static', 'graphs'),
                  ignore_errors=True)
    shutil.copytree('graphs', os.path.join('appengine', 'static', 'graphs'))
    shutil.copyfile('index.html', os.path.join('appengine', 'static',
                    'index.html'))
    shutil.copyfile('dromaeo.html', os.path.join('appengine', 'static',
                    'dromaeo.html'))
    shutil.copyfile('data.html', os.path.join('appengine', 'static',
                    'data.html'))
    self.run_cmd([os.path.join('..', '..', '..', 'third_party',
                               'appengine-python', 'appcfg.py'), '--oauth2', 
                               'update', 'appengine/'])

  def parse_args(self):
    parser = optparse.OptionParser()
    parser.add_option('--suites', '-s', dest='suites', help='Run the specified '
                      'comma-separated test suites from set: %s' % \
                      ','.join(TestBuilder.available_suite_names()), 
                      action='store', default=None)
    parser.add_option('--forever', '-f', dest='continuous', help='Run this scri'
                      'pt forever, always checking for the next svn checkin',
                      action='store_true', default=False)
    parser.add_option('--graph-only', '-g', dest='graph_only', default=False,
                      help='Do not run tests, only regenerate graphs', 
                      action='store_true')
    parser.add_option('--nobuild', '-n', dest='no_build', action='store_true',
                      help='Do not sync with the repository and do not '
                      'rebuild.', default=False)
    parser.add_option('--upload', '-u', dest='upload', help='Upload data to '
                      'app engine (will require authentication).', 
                      action='store_true', default=False)
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
    self.graph_only = args.graph_only
    self.upload = args.upload
    self.verbose = args.verbose
    return args.continuous

  def run_test_sequence(self):
    """Run the set of commands to (possibly) build, run, and graph the results
    of our tests.

    Args:
      suite_names: The "display name" the user enters to specify which
          benchmark(s) to run.
      no_build: True if we should not check the repository and build the latest
          version.
      graph_only: True if we should not run the tests, just (re)generate graphs.
      upload: True if we should upload our results to appengine."""
    suites = []
    for name in self.suite_names:
      suites += [TestBuilder.make_test(name, self)]

    if not self.no_build and self.sync_and_build(suites) == 1:
      return # The build is broken.

    for test in suites:
      test.run(self.graph_only)

    if self.upload:
      self.upload_to_app_engine(TestBuilder.available_suite_names())


class Test(object):
  """The base class to provide shared code for different tests we will run and
  graph. At a high level, each test has three visitors (the tester, the
  file_processor, and the grapher) that perform operations on the test 
  object."""

  def __init__(self, result_folder_name, platform_list, variants,
               values_list, test_runner, tester, file_processor, grapher,
               extra_metrics=['Geo-Mean'], build_targets=['create_sdk']):
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
         grapher: The visitor that generates graphs given our test result data.
         extra_metrics: A list of any additional measurements we wish to keep
             track of (such as the geometric mean of a set, the sum, etc).
         build_targets: The targets necessary to build to run these tests
             (default target is create_sdk)."""
    self.result_folder_name = result_folder_name
    # cur_time is used as a timestamp of when this performance test was run.
    self.cur_time = str(time.mktime(datetime.datetime.now().timetuple()))
    self.values_list = values_list
    self.platform_list = platform_list
    self.revision_dict = dict()
    self.values_dict = dict()
    self.test_runner = test_runner
    self.tester = tester
    self.file_processor = file_processor
    self.grapher = grapher
    self.extra_metrics = extra_metrics
    self.build_targets = build_targets
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
  
  def run(self, graph_only):
    """Run the benchmarks/tests from the command line and plot the
    results.
    
    Args:
      graph_only: True if we should just graph the results instead of also
          running tests."""
    for visitor in [self.tester, self.file_processor, self.grapher]:
      visitor.prepare()
    
    os.chdir(DART_INSTALL_LOCATION)
    self.test_runner.ensure_output_directory(self.result_folder_name)
    if not graph_only:
      self.tester.run_tests()

    os.chdir(os.path.join('tools', 'testing', 'perf_testing'))

    # TODO(efortuna): You will want to make this only use a subset of the files
    # eventually.
    files = os.listdir(self.result_folder_name)

    for afile in files:
      if not afile.startswith('.'):
        self.file_processor.process_file(afile)

    if 'plt' in globals():
      # Only run Matplotlib if it is installed.
      self.grapher.plot_results('%s.png' % self.result_folder_name)


class Tester(object):
  """The base level visitor class that runs tests. It contains convenience 
  methods that many Tester objects use. Any class that would like to be a
  TesterVisitor must implement the run_tests() method."""

  def __init__(self, test):
    self.test = test

  def prepare(self):
    """Perform any initial setup required before the test is run."""
    pass

  def add_svn_revision_to_trace(self, outfile):
    """Add the svn version number to the provided tracefile."""
    def search_for_revision(svn_info_command):
      p = subprocess.Popen(svn_info_command, stdout = subprocess.PIPE,
                           stderr = subprocess.STDOUT, shell =
                           self.test.test_runner.has_shell)
      output, _ = p.communicate()
      for line in output.split('\n'):
        if 'Revision' in line:
          self.test.test_runner.run_cmd(['echo', line.strip()], outfile)
          return True
      return False

    if not search_for_revision(['svn', 'info']):
      if not search_for_revision(['git', 'svn', 'info']):
        self.test.test_runner.run_cmd(['echo', 'Revision: unknown'], outfile)


class Processor(object):
  """The base level vistor class that processes tests. It contains convenience 
  methods that many File Processor objects use. Any class that would like to be
  a ProcessorVisitor must implement the process_file() method."""

  def __init__(self, test):
    self.test = test

  def prepare(self):
    """Perform any initial setup required before the test is run."""
    pass

  def calculate_geometric_mean(self, platform, variant, svn_revision):
    """Calculate the aggregate geometric mean for JS and frog benchmark sets,
    given two benchmark dictionaries."""
    geo_mean = 0
    for benchmark in self.test.values_list:
      geo_mean += math.log(self.test.values_dict[platform][variant][benchmark][
          len(self.test.values_dict[platform][variant][benchmark]) - 1])

    self.test.values_dict[platform][variant]['Geo-Mean'] += \
        [math.pow(math.e, geo_mean / len(self.test.values_list))]
    self.test.revision_dict[platform][variant]['Geo-Mean'] += [svn_revision]


class Grapher(object):
  """The base level visitor class that generates graphs for data. It contains 
  convenience methods that many Grapher objects use. Any class that would like
  to be a GrapherVisitor must implement the plot_results() method."""
  
  graph_out_dir = 'graphs'
  
  def __init__(self, test):
    self.color_index = 0
    self.test = test
  
  def prepare(self):
    """Perform any initial setup required before the test is run."""
    if 'plt' in globals():
      plt.cla() # cla = clear current axes
    else:
      print 'Unable to import Matplotlib and therefore unable to generate ' + \
          'graphs. Please install it for this version of Python.'
    self.test.test_runner.ensure_output_directory(Grapher.graph_out_dir)

  def style_and_save_perf_plot(self, chart_title, y_axis_label, size_x, size_y,
                               legend_loc, filename, platform_list, variants, 
                               values_list, should_clear_axes=True):
    """Sets style preferences for chart boilerplate that is consistent across
    all charts, and saves the chart as a png.

    Args:
      size_x: the size of the printed chart, in inches, in the horizontal
        direction
      size_y: the size of the printed chart, in inches in the vertical direction
      legend_loc: the location of the legend in on the chart. See suitable
        arguments for the loc argument in matplotlib
      filename: the filename that we want to save the resulting chart as
      platform_list: a list containing the platform(s) that our data has been
        run on. (command line, firefox, chrome, etc)
      values_list: a list containing the type of data we will be graphing
        (performance, percentage passing, etc)
      should_clear_axes: True if we want to create a fresh graph, instead of
        plotting additional lines on the current graph."""
    if should_clear_axes:
      plt.cla() # cla = clear current axes
    for platform in platform_list:
      for f in variants:
        for val in values_list:
          plt.plot(self.test.revision_dict[platform][f][val],
              self.test.values_dict[platform][f][val],
              color=self.get_color(), label='%s-%s-%s' % (platform, f, val))

    plt.xlabel('Revision Number')
    plt.ylabel(y_axis_label)
    plt.title(chart_title)
    fontP = FontProperties()
    fontP.set_size('small')
    plt.legend(loc=legend_loc, prop = fontP)

    fig = plt.gcf()
    fig.set_size_inches(size_x, size_y)
    fig.savefig(os.path.join(Grapher.graph_out_dir, filename))
  
  def get_color(self):
    # Just a bunch of distinct colors for a potentially large number of values
    # we wish to graph.
    colors = [
        'blue', 'green', 'red', 'cyan', 'magenta', 'black', '#3366CC',
        '#DC3912', '#FF9900', '#109618', '#990099', '#0099C6', '#DD4477',
        '#66AA00', '#B82E2E', '#316395', '#994499', '#22AA99', '#AAAA11',
        '#6633CC', '#E67300', '#8B0707', '#651067', '#329262', '#5574A6',
        '#3B3EAC', '#B77322', '#16D620', '#B91383', '#F4359E', '#9C5935',
        '#A9C413', '#2A778D', '#668D1C', '#BEA413', '#0C5922', '#743411',
        '#45AFE2', '#FF3300', '#FFCC00', '#14C21D', '#DF51FD', '#15CBFF',
        '#FF97D2', '#97FB00', '#DB6651', '#518BC6', '#BD6CBD', '#35D7C2',
        '#E9E91F', '#9877DD', '#FF8F20', '#D20B0B', '#B61DBA', '#40BD7E',
        '#6AA7C4', '#6D70CD', '#DA9136', '#2DEA36', '#E81EA6', '#F558AE',
        '#C07145', '#D7EE53', '#3EA7C6', '#97D129', '#E9CA1D', '#149638',
        '#C5571D']
    color = colors[self.color_index]
    self.color_index = (self.color_index + 1) % len(colors)
    return color


class RuntimePerformanceTest(Test):
  """Super class for all runtime performance testing."""

  def __init__(self, result_folder_name, platform_list, platform_type,
               versions, benchmarks, test_runner, tester, file_processor,
               build_targets=['create_sdk']):
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
        grapher: The visitor that generates graphs given our test result data.
        extra_metrics: A list of any additional measurements we wish to keep
            track of (such as the geometric mean of a set, the sum, etc).
        build_targets: The targets necessary to build to run these tests
            (default target is create_sdk)."""
    super(RuntimePerformanceTest, self).__init__(result_folder_name,
          platform_list, versions, benchmarks, test_runner, tester,
          file_processor, self.RuntimePerfGrapher(self),
          build_targets=build_targets)
    self.platform_list = platform_list
    self.platform_type = platform_type
    self.versions = versions
    self.benchmarks = benchmarks 
 
  class RuntimePerfGrapher(Grapher):
    def plot_all_perf(self, png_filename):
      """Create a plot that shows the performance changes of individual
      benchmarks run by JS and generated by frog, over svn history."""
      for benchmark in self.test.benchmarks:
        self.style_and_save_perf_plot(
            'Performance of %s over time on the %s on %s' % (benchmark,
            self.test.platform_type, utils.GuessOS()), 
            'Speed (bigger = better)', 16, 14, 'lower left',
            benchmark + png_filename, self.test.platform_list,
            self.test.versions, [benchmark])

    def plot_avg_perf(self, png_filename):
      """Generate a plot that shows the performance changes of the geomentric
      mean of JS and frog benchmark performance over svn history."""
      (title, y_axis, size_x, size_y, loc, filename) = \
          ('Geometric Mean of benchmark %s performance on %s ' %
          (self.test.platform_type, utils.GuessOS()), 'Speed (bigger = better)',
          16, 5, 'lower left', 'avg'+png_filename)
      clear_axis = True
      for platform in self.test.platform_list:
        for version in self.test.versions:
          for metric in self.test.extra_metrics:
            self.style_and_save_perf_plot(title, y_axis, size_x, size_y, loc,
                                          filename, [platform], [version],
                                          [metric], clear_axis)
            clear_axis = False

    def plot_results(self, png_filename):
      self.plot_all_perf(png_filename)
      self.plot_avg_perf('2' + png_filename)


class CommonCommandLineTest(RuntimePerformanceTest):
  """Run the basic performance tests (Benchpress, some V8 benchmarks) from the
  command line."""

  def __init__(self, test_runner):
    """Args:
      test_runner: Reference to the object that notfies this test when to
          run."""
    super(CommonCommandLineTest, self).__init__(
          self.name(), ['commandline'], 
          'command line', ['js', 'frog'], self.get_standalone_benchmarks(), 
          test_runner, self.CommonCommandLineTester(self),
          self.CommonCommandLineFileProcessor(self),
          build_targets=['create_sdk', 'dart2js'])

  @staticmethod
  def name():
    return 'cl-perf'

  @staticmethod
  def get_standalone_benchmarks():
    return ['Mandelbrot', 'DeltaBlue', 'Richards', 'NBody', 'BinaryTrees',
    'Fannkuch', 'Meteor', 'BubbleSort', 'Fibonacci', 'Loop', 'Permute',
    'Queens', 'QuickSort', 'Recurse', 'Sieve', 'Sum', 'Tak', 'Takl', 'Towers',
    'TreeSort']

  class CommonCommandLineTester(Tester):
    def run_tests(self):
      """Run a performance test on our updated system."""
      os.chdir('frog')
      self.test.trace_file = os.path.join(
          '..', 'tools', 'testing', 'perf_testing', 
          self.test.result_folder_name, 'result' + self.test.cur_time)
      self.test.test_runner.run_cmd(['python', os.path.join('benchmarks', 
                                     'perf_tests.py')], self.test.trace_file)
      os.chdir('..')

  class CommonCommandLineFileProcessor(Processor):
    def process_file(self, afile):
      """Pull all the relevant information out of a given tracefile.

      Args:
        afile: The filename string we will be processing."""
      os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools',
          'testing', 'perf_testing'))
      f = open(os.path.join(self.test.result_folder_name, afile))
      tabulate_data = False
      revision_num = 0
      for line in f.readlines():
        if 'Revision' in line:
          revision_num = int(line.split()[1])
        elif 'Benchmark' in line:
          tabulate_data = True
        elif tabulate_data:
          tokens = line.split()
          if len(tokens) < 4 or tokens[0] not in self.test.benchmarks:
            #Done tabulating data.
            break
          js_value = float(tokens[1])
          frog_value = float(tokens[3])
          if js_value == 0 or frog_value == 0:
            #Then there was an error when this performance test was run. Do not
            #count it in our numbers.
            return
          benchmark = tokens[0]
          self.test.revision_dict['commandline']['js'][benchmark] += \
              [revision_num]
          self.test.values_dict['commandline']['js'][benchmark] += [js_value]
          self.test.revision_dict['commandline']['frog'][benchmark] += \
              [revision_num]
          self.test.values_dict['commandline']['frog'][benchmark] += \
              [frog_value]
      f.close()

      self.calculate_geometric_mean('commandline', 'frog', revision_num)
      self.calculate_geometric_mean('commandline', 'js', revision_num)


class BrowserTester(Tester):
  # TODO(vsm): Add Dartium.
  @staticmethod
  def get_browsers():
    browsers = ['ff', 'chrome']
    if platform.system() == 'Darwin':
      browsers += ['safari']
    if platform.system() == 'Windows':
      browsers += ['ie']
    return browsers


class CommonBrowserTest(RuntimePerformanceTest):
  """Runs this basic performance tests (Benchpress, some V8 benchmarks) in the
  browser."""

  def __init__(self, test_runner):
    """Args:
      test_runner: Reference to the object that notifies us when to run."""
    super(CommonBrowserTest, self).__init__(
        self.name(), BrowserTester.get_browsers(),
        'browser', ['js', 'frog'],
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
      os.chdir('frog')
      self.test.test_runner.run_cmd(['python', os.path.join('benchmarks', 
                                     'make_web_benchmarks.py')])
      os.chdir('..')

      for browser in BrowserTester.get_browsers():
        for version in self.test.versions:
          self.test.trace_file = os.path.join(
              'tools', 'testing', 'perf_testing', self.test.result_folder_name,
              'perf-%s-%s-%s' % (self.test.cur_time, browser, version))
          self.add_svn_revision_to_trace(self.test.trace_file)
          file_path = os.path.join(
              os.getcwd(), 'internal', 'browserBenchmarks',
              'benchmark_page_%s.html' % version)
          self.test.test_runner.run_cmd(
              ['python', os.path.join('tools', 'testing', 'run_selenium.py'),
              '--out', file_path, '--browser', browser,
              '--timeout', '600', '--mode', 'perf'], self.test.trace_file, 
              append=True)

  class CommonBrowserFileProcessor(Processor):
    def process_file(self, afile):
      """Comb through the html to find the performance results."""
      os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools',
                            'testing', 'perf_testing'))
      parts = afile.split('-')
      browser = parts[2]
      version = parts[3]
      f = open(os.path.join(self.test.result_folder_name, afile))
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
        return

      line = lines[i]
      i += 1
      results = []
      if line.find('<br>') > -1:
        results = line.split('<br>')
      else:
        results = line.split('<br />')
      for result in results:
        name_and_score = result.split(':')
        if len(name_and_score) < 2:
          break
        name = name_and_score[0].strip()
        score = name_and_score[1].strip()
        if version == 'js' or version == 'v8':
          version = 'js'
          bench_dict = self.test.values_dict[browser]['js']
        else:
          bench_dict = self.test.values_dict[browser]['frog']
        bench_dict[name] += [float(score)]
        self.test.revision_dict[browser][version][name] += [revision_num]

      f.close()
      self.calculate_geometric_mean(browser, version, revision_num)

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

  # Use legal appengine filenames for benchmark names.
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
  # failure properly.  The modify suite fails on 32-bit chrome on
  # the mac.
  @staticmethod
  def get_valid_dromaeo_tags():
    tags = [tag for (tag, _) in DromaeoTester.DROMAEO_BENCHMARKS.values()]
    if platform.system() == 'Darwin':
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
    return ['js', 'frog_dom', 'frog_html']


class DromaeoTest(RuntimePerformanceTest):
  """Runs Dromaeo tests, in the browser."""
  def __init__(self, test_runner):
    super(DromaeoTest, self).__init__(
        self.name(), BrowserTester.get_browsers(), 'browser',
        DromaeoTester.get_dromaeo_versions(), 
        DromaeoTester.get_dromaeo_benchmarks(), test_runner,
        self.DromaeoPerfTester(self),
        self.DromaeoFileProcessor(self))

  @staticmethod
  def name():
    return 'dromaeo'

  class DromaeoPerfTester(DromaeoTester):
    def run_tests(self):
      """Run dromaeo in the browser."""

      # Build tests.
      dromaeo_path = os.path.join('samples', 'third_party', 'dromaeo')
      current_path = os.getcwd()
      os.chdir(dromaeo_path)
      self.test.test_runner.run_cmd(['python', 'generate_frog_tests.py'])
      os.chdir(current_path)

      versions = DromaeoTester.get_dromaeo_versions()

      for browser in BrowserTester.get_browsers():
        for version_name in versions:
          version = DromaeoTest.DromaeoPerfTester.get_dromaeo_url_query(
              version_name)
          self.test.trace_file = os.path.join(
              'tools', 'testing', 'perf_testing', self.test.result_folder_name,
              'dromaeo-%s-%s-%s' % (self.test.cur_time, browser, version_name))
          self.add_svn_revision_to_trace(self.test.trace_file)
          file_path = '"%s"' % os.path.join(os.getcwd(), dromaeo_path,
              'index-js.html?%s' % version)
          self.test.test_runner.run_cmd(
              ['python', os.path.join('tools', 'testing', 'run_selenium.py'),
               '--out', file_path, '--browser', browser,
               '--timeout', '600', '--mode', 'dromaeo'], self.test.trace_file,
               append=True)

    @staticmethod
    def get_dromaeo_url_query(version):
      version = version.replace('_','&')
      tags = DromaeoTester.get_valid_dromaeo_tags()
      return '|'.join([ '%s&%s' % (version, tag) for tag in tags])


  class DromaeoFileProcessor(Processor):
    def process_file(self, afile):
      """Comb through the html to find the performance results."""
      parts = afile.split('-')
      browser = parts[2]
      version = parts[3]

      bench_dict = self.test.values_dict[browser][version]

      f = open(os.path.join(self.test.result_folder_name, afile))
      lines = f.readlines()
      i = 0
      revision_num = 0
      revision_pattern = r'Revision: (\d+)'
      suite_pattern = r'<div class="result-item done">(.+?)</ol></div>'
      result_pattern = r'<b>(.+?)</b>(.+?)<small> runs/s(.+)'

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
                name = DromaeoTester.legalize_filename(
                    r.group(1).strip(':'))
                score = float(r.group(2))
                bench_dict[name] += [float(score)]
                self.test.revision_dict[browser][version][name] += \
                    [revision_num]

      f.close()
      self.calculate_geometric_mean(browser, version, revision_num)


class DromaeoSizeTest(Test):
  """Run tests to determine the compiled file output size of Dromaeo."""
  def __init__(self, test_runner):
    super(DromaeoSizeTest, self).__init__(
        self.name(),
        ['browser'], ['dart', 'frog_dom', 'frog_html', 'frog_htmlidiomatic'],
        DromaeoTester.DROMAEO_BENCHMARKS.keys(), test_runner, 
        self.DromaeoSizeTester(self),
        self.DromaeoSizeProcessor(self),
        self.DromaeoSizeGrapher(self), extra_metrics=['sum'])
  
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
          ['python', os.path.join('generate_frog_tests.py')])
      os.chdir(current_path)

      self.test.trace_file = os.path.join(
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
    def process_file(self, afile):
      """Pull all the relevant information out of a given tracefile.

      Args:
        afile: is the filename string we will be processing."""
      os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools',
          'testing', 'perf_testing'))
      f = open(os.path.join(self.test.result_folder_name, afile))
      tabulate_data = False
      revision_num = 0
      revision_pattern = r'Revision: (\d+)'
      result_pattern = r'Size \((\w+), ([a-zA-Z0-9-]+)\): (\d+)'

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
          self.test.values_dict['browser'][variant][metric] += [num]
          self.test.revision_dict['browser'][variant][metric] += [revision_num]

      f.close()
  class DromaeoSizeGrapher(Grapher):
    def plot_results(self, png_filename):
      self.style_and_save_perf_plot(
          'Compiled Dromaeo Sizes',
          'Size (in bytes)', 10, 10, 'lower left', png_filename,
          ['browser'], ['dart', 'frog_dom', 'frog_html', 'frog_htmlidiomatic'],
          DromaeoTester.DROMAEO_BENCHMARKS.keys())

      self.style_and_save_perf_plot(
          'Compiled Dromaeo Sizes',
          'Size (in bytes)', 10, 10, 'lower left', '2' + png_filename,
          ['browser'], ['dart', 'frog_dom', 'frog_html', 'frog_htmlidiomatic'],
          [self.test.extra_metrics[0]])
  

class CompileTimeAndSizeTest(Test):
  """Run tests to determine how long minfrog takes to compile, and the compiled
  file output size of some benchmarking files."""
  def __init__(self, test_runner):
    """Reference to the test_runner object that notifies us when to begin
    testing."""
    super(CompileTimeAndSizeTest, self).__init__(
        self.name(), ['commandline'], ['frog'], 
        ['Compiling on Dart VM', 'Bootstrapping', 'minfrog', 'swarm', 'total'],
        test_runner, self.CompileTester(self),
        self.CompileProcessor(self), self.CompileGrapher(self))
    self.dart_compiler = os.path.join(
        DART_INSTALL_LOCATION, utils.GetBuildRoot(utils.GuessOS(),
        'release', 'ia32'), 'dart-sdk', 'bin', 'frogc')
    _suffix = ''
    if platform.system() == 'Windows':
      _suffix = '.exe'
    self.dart_vm = os.path.join(
        DART_INSTALL_LOCATION, utils.GetBuildRoot(utils.GuessOS(), 
        'release', 'ia32'), 'dart-sdk', 'bin','dart' + _suffix)
    self.failure_threshold = {
        'Compiling on Dart VM' : 1, 'Bootstrapping' : .5, 'minfrog' : 100, 
        'swarm' : 100, 'total' : 100}

  @staticmethod
  def name():
    return 'time-size'

  class CompileTester(Tester):
    def run_tests(self):
      os.chdir('frog')
      self.test.trace_file = os.path.join(
          '..', 'tools', 'testing', 'perf_testing', 
          self.test.result_folder_name,
          self.test.result_folder_name + self.test.cur_time)

      self.add_svn_revision_to_trace(self.test.trace_file)

      elapsed = self.test.test_runner.time_cmd(
          [self.test.dart_vm, os.path.join('.', 'minfrogc.dart'),
          '--out=minfrog', 'minfrog.dart'])
      self.test.test_runner.run_cmd(
          ['echo', '%f Compiling on Dart VM in production mode in seconds'
          % elapsed], self.test.trace_file, append=True)
      elapsed = self.test.test_runner.time_cmd(
          [os.path.join('.', 'minfrog'), '--out=minfrog', 'minfrog.dart', 
          os.path.join('tests', 'hello.dart')])
      if elapsed < self.test.failure_threshold['Bootstrapping']:
        #minfrog didn't compile correctly. Stop testing now, because subsequent
        #numbers will be meaningless.
        return
      size = os.path.getsize('minfrog')
      self.test.test_runner.run_cmd(
          ['echo', '%f Bootstrapping time in seconds in production mode' %
          elapsed], self.test.trace_file, append=True)
      self.test.test_runner.run_cmd(
          ['echo', '%d Generated checked minfrog size' % size],
          self.test.trace_file, append=True)

      self.test.test_runner.run_cmd(
          [self.test.dart_compiler, '--out=swarm-result',
          os.path.join('..', 'samples', 'swarm',
          'swarm.dart')])

      swarm_size = 0
      try:
        swarm_size = os.path.getsize('swarm-result')
      except OSError:
        pass #If compilation failed, continue on running other tests.

      self.test.test_runner.run_cmd(
          [self.test.dart_compiler, '--out=total-result',
          os.path.join('..', 'samples', 'total',
          'client', 'Total.dart')])
      total_size = 0
      try:
        total_size = os.path.getsize('total-result')
      except OSError:
        pass #If compilation failed, continue on running other tests.

      self.test.test_runner.run_cmd(
          ['echo', '%d Generated checked swarm size' % swarm_size],
          self.test.trace_file, append=True)

      self.test.test_runner.run_cmd(
          ['echo', '%d Generated checked total size' % total_size],
          self.test.trace_file, append=True)
    
      #Revert our newly built minfrog to prevent conflicts when we update
      self.test.test_runner.run_cmd(
          ['svn', 'revert',  os.path.join(os.getcwd(), 'frog', 'minfrog')])
    
      os.chdir('..')

  class CompileProcessor(Processor):
    def process_file(self, afile):
      """Pull all the relevant information out of a given tracefile.

      Args:
        afile: is the filename string we will be processing."""
      os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools',
          'testing', 'perf_testing'))
      f = open(os.path.join(self.test.result_folder_name, afile))
      tabulate_data = False
      revision_num = 0
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
              self.test.values_dict['commandline']['frog'][metric] += [num]
              self.test.revision_dict['commandline']['frog'][metric] += \
                  [revision_num]

      if revision_num != 0:
        for metric in self.test.values_list:
          self.test.revision_dict['commandline']['frog'][metric].pop()
          self.test.revision_dict['commandline']['frog'][metric] += \
              [revision_num]
          # Fill in 0 if compilation failed.
          if self.test.values_dict['commandline']['frog'][metric][-1] < \
              self.test.failure_threshold[metric]:
            self.test.values_dict['commandline']['frog'][metric] += [0]
            self.test.revision_dict['commandline']['frog'][metric] += \
                [revision_num]

      f.close()

  class CompileGrapher(Grapher):

    def plot_results(self, png_filename):
      self.style_and_save_perf_plot(
          'Compiled minfrog Sizes', 'Size (in bytes)', 10, 10, 'lower left',
          png_filename, ['commandline'], ['frog'], 
          ['swarm', 'total', 'minfrog'])

      self.style_and_save_perf_plot(
          'Time to compile and bootstrap',
          'Seconds', 10, 10, 'lower left', '2' + png_filename, ['commandline'],
          ['frog'], ['Bootstrapping', 'Compiling on Dart VM'])


class TestBuilder(object):
  """Construct the desired test object."""
  available_suites = dict((suite.name(), suite) for suite in [
      CommonCommandLineTest, CompileTimeAndSizeTest,
      CommonBrowserTest, DromaeoTest, DromaeoSizeTest])

  @staticmethod
  def make_test(test_name, test_runner):
    return TestBuilder.available_suites[test_name](test_runner)

  @staticmethod
  def available_suite_names():
    return TestBuilder.available_suites.keys()


def main():
  runner = TestRunner()
  continuous = runner.parse_args()
  if continuous:
    while True:
      if runner.has_new_code():
        runner.run_test_sequence()
      else:
        time.sleep(200)
  else:
    runner.run_test_sequence()

if __name__ == '__main__':
  main()
