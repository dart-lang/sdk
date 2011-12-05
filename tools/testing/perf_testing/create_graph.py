#!/usr/bin/python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import datetime
import math
try:
  from matplotlib.font_manager import FontProperties
  import matplotlib.pyplot as plt
except ImportError:
  print 'Warning: no matplotlib. ' + \
      'Please ignore if you are running buildbot smoketests.'
import optparse
import os
import platform
import shutil
import subprocess
import time
import traceback

"""This script runs to track performance and correctness progress of 
different svn revisions. It tests to see if there a newer version of the code on
the server, and will sync and run the performance tests if so."""

DART_INSTALL_LOCATION = os.path.join(os.path.dirname(os.path.abspath(__file__)),
    '..', '..', '..')
V8_MEAN = 'V8 Mean'
FROG_MEAN = 'frog Mean'
COMMAND_LINE = 'commandline'
V8 = 'v8'
FROG = 'frog'
V8_AND_FROG = [V8, FROG]
CORRECTNESS = 'Percent passing'
BENCHMARKS = ['Mandelbrot', 'DeltaBlue', 'Richards', 'NBody', 
    'BinaryTrees', 'Fannkuch', 'Meteor', 'BubbleSort', 'Fibonacci', 
    'Loop', 'Permute', 'Queens', 'QuickSort', 'Recurse', 'Sieve', 'Sum', 
    'Tak', 'Takl', 'Towers', 'TreeSort']
COLORS = ['blue', 'green', 'red', 'cyan', 'magenta', 'black']
GRAPH_OUT_DIR = 'graphs'
SLEEP_TIME = 200
PERFBOT_MODE = False
VERBOSE = False

"""First, some utility methods."""

def RunCmd(cmd_list, outfile=None, append=False):
  """Run the specified command and print out any output to stdout.
  Args:
    cmd_list a list of strings that make up the command to run
    outfile a string indicating the name of the file that we should write stdout
       to 
    append True if we want to append to the file instead of overwriting it"""
  if VERBOSE:
    print ' '.join(cmd_list)
  out = subprocess.PIPE
  if outfile:
    mode = 'w'
    if append:
      mode = 'a'
    out = open(outfile, mode)
  p = subprocess.Popen(cmd_list, stdout = out, 
      stderr = subprocess.PIPE, close_fds=True)
  output, not_used = p.communicate();
  if output:
    print output
  return output

def TimeCmd(cmd):
  """Determine the amount of (real) time it takes to execute a given command."""
  start = time.time()
  RunCmd(cmd)
  return time.time() - start

def SyncAndBuild(failed_once=False):
  """Make sure we have the latest version of of the repo, and build it. We
  begin and end standing in DART_INSTALL_LOCATION.
  Args:
    failed_once True if we have attempted to build this once before, and we've
      failed, indicating the build is broken."""
  os.chdir(DART_INSTALL_LOCATION)
  #Revert our newly built minfrog to prevent conflicts when we update
  RunCmd(['svn', 'revert',  os.path.join(os.getcwd(), 'frog', 'minfrog')])

  RunCmd(['gclient', 'sync'])
  lines = RunCmd([os.path.join('.', 'tools', 'build.py'), '-m', 'release'])
  os.chdir('frog')
  lines += RunCmd([os.path.join('..', 'tools', 'build.py'), '-m', 
      'debug,release'])
  os.chdir('..')
  
  for line in lines:
    if 'BUILD FAILED' in lines:
      if failed_once:
        # Someone checked in a broken build! Just stop trying to make it work
        # and wait for the next hour to try again.
        print 'Broken Build'
        sys.exit(0)
      #Remove the xcode directory and attempt to build again. If it still
      #fails, abort, and try again next hour.
      out_dir = 'out'
      if platform.system() == 'Darwin':
        out_dir = 'xcodebuild'
      shutil.rmtree(os.path.join(os.getcwd(), out_dir, 'Release_ia32'))
      shutil.rmtree(os.path.join(os.getcwd(), 'frog', out_dir, 
          'Debug_ia32'))
      shutil.rmtree(os.path.join(os.getcwd(), 'frog', out_dir, 
          'Release_ia32'))
      SyncAndBuild(True)

def EnsureOutputDirectory(dir_name):
  """Test that the listed directory name exists, and if not, create one for
  our output to be placed.
  Args:
    dir_name the directory we will create if it does not exist."""
  dir_path = os.path.join(DART_INSTALL_LOCATION, 'tools', 'testing',
      'perf_testing', dir_name)
  if not os.path.exists(dir_path):
    os.mkdir(dir_path)
    print 'Creating output directory ', dir_path

def HasNewCode():
  """Tests if there are any newer versions of files on the server."""
  os.chdir(DART_INSTALL_LOCATION)    
  results = RunCmd(['svn', 'st', '-u'])
  for line in results:
    if '*' in line:
      return True
  return False

def GetBrowsers():
  if not PERFBOT_MODE:
    # Only Firefox (and Chrome, but we have Dump Render Tree) works in Linux
    return ['ff']
  browsers = ['ff', 'chrome']
  if platform.system() == 'Windows':
    browsers += ['ie']
  return browsers

def GetVersions():
  if not PERFBOT_MODE:
    return [FROG]
  else:
    return V8_AND_FROG

class TestRunner(object):
  """The base clas to provide shared code for different tests we will run and
  graph."""

  def __init__(self, result_folder_name, platform_list, v8_and_or_frog_list, 
      values_list):
    """Args:
         result_folder_name the name of the folder where a tracefile of
         performance results will be stored.
         platform_list a list containing the platform(s) that our data has been
            run on. (command line, firefox, chrome, etc)
         v8_and_or_frog_list a list specifying whether we hold data about Frog
            generated code, plain JS code (v8), or a combination of both.
         values_list a list containing the type of data we will be graphing
            (benchmarks, percentage passing, etc)"""
    self.result_folder_name = result_folder_name
    # cur_time is used as a timestamp of when this performance test was run.
    self.cur_time = str(time.mktime(datetime.datetime.now().timetuple()))
    self.browser_color = {'chrome': 'green', 'ie': 'blue', 'ff': 'red'}
    self.values_list = values_list
    self.platform_list = platform_list
    self.revision_dict = dict()
    self.values_dict = dict()
    self.color_index = 0
    for platform in platform_list:
      self.revision_dict[platform] = dict()
      self.values_dict[platform] = dict()
      for f in v8_and_or_frog_list:
        self.revision_dict[platform][f] = dict()
        self.values_dict[platform][f] = dict()
        for val in values_list:
          self.revision_dict[platform][f][val] = []
          self.values_dict[platform][f][val] = []
      if V8 in v8_and_or_frog_list:
        self.revision_dict[platform][V8][V8_MEAN] = []
        self.values_dict[platform][V8][V8_MEAN] = []
      if FROG in v8_and_or_frog_list:
        self.revision_dict[platform][FROG][FROG_MEAN] = []
        self.values_dict[platform][FROG][FROG_MEAN] = []
 
  def GetColor(self):
    color = COLORS[self.color_index]
    self.color_index = (self.color_index + 1) % len(COLORS)
    return color

  def StyleAndSavePerfPlot(self, chart_title, y_axis_label, size_x, size_y, 
      legend_loc, filename, platform_list, v8_and_or_frog_list, values_list, 
      should_clear_axes=True):
    """Sets style preferences for chart boilerplate that is consistent across 
    all charts, and saves the chart as a png.
    Args:
      size_x the size of the printed chart, in inches, in the horizontal 
        direction
      size_y the size of the printed chart, in inches in the vertical direction
      legend_loc the location of the legend in on the chart. See suitable
        arguments for the loc argument in matplotlib
      filename the filename that we want to save the resulting chart as
      platform_list a list containing the platform(s) that our data has been run
        on. (command line, firefox, chrome, etc)
      values_list a list containing the type of data we will be graphing
        (performance, percentage passing, etc)
      should_clear_axes True if we want to create a fresh graph, instead of
        plotting additional lines on the current graph."""
    if should_clear_axes:
      plt.cla() # cla = clear current axes
    for platform in platform_list:
      for f in v8_and_or_frog_list:
        for val in values_list:
          plt.plot(self.revision_dict[platform][f][val],
              self.values_dict[platform][f][val], 
              color=self.GetColor(), label='%s-%s-%s' % (platform, f, val))

    plt.xlabel('Revision Number')
    plt.ylabel(y_axis_label)
    plt.title(chart_title)
    fontP = FontProperties()
    fontP.set_size('small')
    plt.legend(loc=legend_loc, prop = fontP)

    fig = plt.gcf()
    fig.set_size_inches(size_x, size_y)
    fig.savefig(os.path.join(GRAPH_OUT_DIR, filename))

  def AddSvnRevisionToTrace(self, outfile):
    """Add the svn version number to the provided tracefile."""
    p = subprocess.Popen(['svn', 'info'], stdout = subprocess.PIPE, 
      stderr = subprocess.STDOUT, close_fds=True)
    output, not_used = p.communicate()
    for line in output.split('\n'):
      if 'Revision' in line:
        RunCmd(['echo', line.strip()], outfile)

  def WriteHtml(self, delimiter, rev_nums, label_1, dict_1, label_2, dict_2, 
      cleanFile=False):
    """Adds an html table to the webpage to display the data values. This method
    will be removed when we have a nicer way to display data values."""
    #TODO(efortuna): fix this.
    return
    #TODO(efortuna): Take this method out when have finalized where the data is
    # going to be displayed.
    f = ''
    out = ''
    if cleanFile:
      f = open('template.html')
    else:
      shutil.copy('index.html', 'temp.html')
      f = open('temp.html')
    out = open('index.html', 'w')
    inTable = False
    for line in f.readlines():
      if not inTable:
        out.write(line)
      if delimiter in line:
        inTable = not inTable
        if inTable:
          out.write('<table border="1"> <tr> <td> svn revision </td>')
          for revision in rev_nums:
            out.write('<td>%d</td>' % revision)
          out.write('</tr>\n<tr><td> %s</td>' % label_1)
          for perf in dict_1:
            out.write('<td>%f</td>' % perf)
          out.write('</tr>\n<tr><td> %s</td>' % label_2)
          for perf in dict_2:
            out.write('<td>%f</td>' % perf)
          out.write('</tr> </table>')

  def CalculateGeometricMean(self, platform, frog_or_v8, svn_revision):
    """Calculate the aggregate geometric mean for V8 and frog benchmark sets,
    given two benchmark dictionaries."""
    geo_mean = 0
    for benchmark in BENCHMARKS:
      geo_mean += math.log(self.values_dict[platform][frog_or_v8][benchmark][
          len(self.values_dict[platform][frog_or_v8][benchmark]) - 1])
 
    mean = V8_MEAN
    if frog_or_v8 == FROG:
       mean = FROG_MEAN
    self.values_dict[platform][frog_or_v8][mean] += \
        [math.pow(math.e, geo_mean / len(BENCHMARKS))]
    self.revision_dict[platform][frog_or_v8][mean] += [svn_revision]

  def Cleanup(self):
      pass

  def Run(self):
    """Run the benchmarks/tests from the command line and plot the 
    results."""
    plt.cla() # cla = clear current axes
    os.chdir(DART_INSTALL_LOCATION)
    EnsureOutputDirectory(self.result_folder_name)
    EnsureOutputDirectory(GRAPH_OUT_DIR)
    self.RunTests()
    os.chdir(os.path.join('tools', 'testing', 'perf_testing'))
    
    # TODO(efortuna): You will want to make this only use a subset of the files
    # eventually.
    files = os.listdir(self.result_folder_name)

    for afile in files:
      if not afile.startswith('.'):
        self.ProcessFile(afile)

    if PERFBOT_MODE:
      self.PlotResults('%s.png' % self.result_folder_name)
    self.Cleanup();

class PerformanceTestRunner(TestRunner):
  """Super class for all performance testing."""
  def __init__(self, result_folder_name, platform_list, platform_type):
    super(PerformanceTestRunner, self).__init__(result_folder_name, 
        platform_list, GetVersions(), BENCHMARKS)
    self.platform_list = platform_list
    self.platform_type = platform_type

  def PlotAllPerf(self, png_filename):
    """Create a plot that shows the performance changes of individual benchmarks
    run by V8 and generated by frog, over svn history."""
    for benchmark in BENCHMARKS:
      self.StyleAndSavePerfPlot(
          'Performance of %s over time on the %s' % (benchmark,
          self.platform_type), 'Speed (bigger = better)', 16, 14, 'lower left', 
          benchmark + png_filename, self.platform_list, GetVersions(), 
          [benchmark])

  def PlotAvgPerf(self, png_filename):
    """Generate a plot that shows the performance changes of the geomentric mean
    of V8 and frog benchmark performance over svn history."""
    (title, y_axis, size_x, size_y, loc, filename) = \
        ('Geometric Mean of benchmark %s performance' % self.platform_type, 
        'Speed (bigger = better)', 16, 5, 'center', 'avg'+png_filename)
    for platform in self.platform_list:
      self.StyleAndSavePerfPlot(title, y_axis, size_x, size_y, loc, filename, 
          [platform], [V8], [V8_MEAN], True)
      self.StyleAndSavePerfPlot(title, y_axis, size_x, size_y, loc, filename, 
          [platform], [FROG], [FROG_MEAN], False)
      self.WriteHtml('table', 
          self.revision_dict[platform][V8], 
          'V8 mean', self.values_dict[platform][V8][V8_MEAN],
          'Frog mean', self.values_dict[platform][FROG][FROG_MEAN], 
          True)

  def PlotResults(self, png_filename):
    self.PlotAllPerf(png_filename)
    self.PlotAvgPerf('2' + png_filename)

  
class CommandLinePerformanceTestRunner(PerformanceTestRunner):
  """Run performance tests from the command line."""

  def __init__(self, result_folder_name):
    super(CommandLinePerformanceTestRunner, self).__init__(result_folder_name, 
        [COMMAND_LINE], 'command line')

  def ProcessFile(self, afile):
    """Pull all the relevant information out of a given tracefile.

    Args:
      afile is the filename string we will be processing."""
    f = open(os.path.join(self.result_folder_name, afile))
    tabulate_data = False
    revision_num = 0
    for line in f.readlines():
      if 'Revision' in line:
        revision_num = int(line.split()[1])
      elif 'Benchmark' in line:
        tabulate_data = True
      elif tabulate_data:
        tokens = line.split()
        if len(tokens) < 4 or tokens[0] not in BENCHMARKS:
          #Done tabulating data.
          break
        v8_value = float(tokens[1])
        frog_value = float(tokens[3])
        if v8_value == 0 or frog_value == 0:
          #Then there was an error when this performance test was run. Do not 
          #count it in our numbers.
          return
        benchmark = tokens[0]
        self.revision_dict[COMMAND_LINE][V8][benchmark] += [revision_num]
        self.values_dict[COMMAND_LINE][V8][benchmark] += [v8_value]
        self.revision_dict[COMMAND_LINE][FROG][benchmark] += [revision_num]
        self.values_dict[COMMAND_LINE][FROG][benchmark] += [frog_value]
    f.close()

    self.CalculateGeometricMean(COMMAND_LINE, FROG, revision_num)
    self.CalculateGeometricMean(COMMAND_LINE, V8, revision_num)
  
  def RunTests(self):
    """Run a performance test on our updated system."""
    os.chdir('frog')
    self.trace_file = os.path.join('..', 'tools', 'testing', 'perf_testing',
        self.result_folder_name, 'result' + self.cur_time)
    RunCmd(['python', os.path.join('benchmarks', 'perf_tests.py')],
        self.trace_file)
    os.chdir('..')


class BrowserPerformanceTestRunner(PerformanceTestRunner):
  """Runs performance tests, in the browser."""

  def __init__(self, result_folder_name):
    super(BrowserPerformanceTestRunner, self).__init__(
        result_folder_name, GetBrowsers(), 'browser')

  def RunTests(self):
    """Run a performance test in the browser."""
    os.chdir('frog')
    RunCmd(['python', os.path.join('benchmarks', 'make_web_benchmarks.py')])
    os.chdir('..')

    for browser in GetBrowsers():
      for version in GetVersions():
        self.trace_file = os.path.join('tools', 'testing', 'perf_testing', 
            self.result_folder_name,
            'perf-%s-%s-%s' % (self.cur_time, browser, version))
        self.AddSvnRevisionToTrace(self.trace_file)
        RunCmd(['python', os.path.join('tools', 'testing', 'run_selenium.py'), 
            '--out', os.path.join(os.getcwd(), 'internal', 'browserBenchmarks',
            'benchmark_page_%s.html' % version), '--browser', browser, 
            '--timeout', '600', '--perf'], self.trace_file, append=True)

  def ProcessFile(self, afile):
    """Comb through the html to find the performance results."""
    parts = afile.split('-')
    browser = parts[2] 
    version = parts[3]
    f = open(os.path.join(self.result_folder_name, afile))
    lines = f.readlines()
    line = ''
    i = 0
    revision_num = 0
    while '<div id="results">' not in line and i < len(lines):
      if 'Revision' in line:
        revision_num = int(line.split()[1])
      line = lines[i]
      i += 1

    if i >= len(lines) or revision_num == 0:
      # Then this run did not complete. Ignore this tracefile. or in the case of
      # the smoke test, report an error.
      if not PERFBOT_MODE:
        print 'FAIL %s %s' % (browser, version)
        os.remove(os.path.join(self.result_folder_name, afile))
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
      if version == V8:
        bench_dict = self.values_dict[browser][V8]
      else:
        bench_dict = self.values_dict[browser][FROG]
      bench_dict[name] += [float(score)]
      self.revision_dict[browser][version][name] += [revision_num]

    f.close()
    if not PERFBOT_MODE:
      print 'PASS'
      os.remove(os.path.join(self.result_folder_name, afile))
    else:
      self.CalculateGeometricMean(browser, version, revision_num)

  def WriteHtml(self, delimiter, rev_nums, label_1, dict_1, label_2, dict_2, 
      cleanFile=False):
      #TODO(efortuna)
      pass

      
  def Cleanup(self):
    # Kill the zombie chromedriver processes.
    RunCmd(['killall', 'chromedriver'])


class BrowserCorrectnessTestRunner(TestRunner):
  def __init__(self, test_type, result_folder_name):
    super(BrowserCorrectnessTestRunner, self).__init__(result_folder_name,
        GetBrowsers(), [FROG], [CORRECTNESS])
    self.test_type = test_type

  def RunTests(self):
    """Run a test of the latest svn revision."""
    for browser in GetBrowsers():
      current_file = 'correctness%s-%s' % (self.cur_time, browser)
      self.trace_file = os.path.join('tools', 'testing',
          'perf_testing', self.result_folder_name, current_file)
      self.AddSvnRevisionToTrace(self.trace_file)
      RunCmd([os.path.join('.', 'tools', 'test.py'),
          '--component=webdriver', '--flag=%s' % browser, '--report', 
          '--timeout=20', '--progress=color', '--mode=release', '-j1',
          self.test_type], self.trace_file, append=True)

  def ProcessFile(self, afile):
    """Given a trace file, extract all the relevant information out of it to
    determine the number of correctly passing tests.
    
    Arguments:
      afile the filename string"""
    browser = afile.rpartition('-')[2]
    f = open(os.path.join(self.result_folder_name, afile))
    revision_num = 0
    lines = f.readlines()
    total_tests = 0
    num_failed = 0
    expect_fail = 0
    for line in lines:
      if 'Total:' in line:
        total_tests = int(line.split()[1])
      if 'will be skipped' in line:
        total_tests -= int(line.split()[1])
      if 'we should fix' in line:
        expect_fail += int(line.split()[1])
      if 'Revision' in line:
        revision_num = int(line.split()[1])
      if '--- TIMEOUT ---' in line or 'FAIL:' in line or 'PASS' in line:
        # (A printed out 'PASS' indicates we incorrectly passed a negative
        # test.)
        num_failed += 1
    
    self.revision_dict[browser][FROG][CORRECTNESS] += [revision_num]
    self.values_dict[browser][FROG][CORRECTNESS] += [100.0 * 
        (((float)(total_tests - (expect_fail + num_failed))) /total_tests)]
    f.close()

  def PlotResults(self, png_filename):
    first_time = True
    for browser in GetBrowsers():
      self.StyleAndSavePerfPlot('Percentage of language tests passing in '
          'different browsers', '% of tests passed', 8, 8, 'lower left', 
          png_filename, [browser], [FROG], [CORRECTNESS], first_time) 
      first_time = False

  def Cleanup(self):
    # Kill the zombie chromedriver processes.
    RunCmd(['killall', 'chromedriver'])

class CompileTimeAndSizeTestRunner(TestRunner):
  """Run tests to determine how long minfrog takes to compile, and the compiled 
  file output size of some benchmarking files."""
  def __init__(self, result_folder_name):
    super(CompileTimeAndSizeTestRunner, self).__init__(result_folder_name,
        [COMMAND_LINE], [FROG], ['Compiling on Dart VM', 'Bootstrapping',
        'minfrog', 'swarm', 'total'])
    self.failure_threshold = {'Compiling on Dart VM' : 1, 'Bootstrapping' : .5, 
        'minfrog' : 100, 'swarm' : 100, 'total' : 100}

  def RunTests(self):
    os.chdir('frog')
    self.trace_file = os.path.join('..', 'tools', 'testing', 'perf_testing', 
        self.result_folder_name, self.result_folder_name + self.cur_time)
    
    self.AddSvnRevisionToTrace(self.trace_file)    

    elapsed = TimeCmd([os.path.join('.', 'frog.py'), '--',
        '--out=minfrog', 'minfrog.dart'])
    RunCmd(['echo', '%f Compiling on Dart VM in production mode in seconds' 
        % elapsed], self.trace_file, append=True)
    elapsed = TimeCmd([os.path.join('.', 'minfrog'), '--out=minfrog',
        '--warnings_as_errors', 'minfrog.dart', os.path.join('tests', 
        'hello.dart')])
    if elapsed < self.failure_threshold['Bootstrapping']:
      #minfrog didn't compile correctly. Stop testing now, because subsequent
      #numbers will be meaningless.
      return
    size = os.path.getsize('minfrog')
    RunCmd(['echo', '%f Bootstrapping time in seconds in production mode' % 
        elapsed], self.trace_file, append=True)
    RunCmd(['echo', '%d Generated checked minfrog size' % size],
        self.trace_file, append=True)

    RunCmd([os.path.join('.', 'minfrog'), ' --out=swarm-result ',
        '--compile-only', os.path.join('..', 'client', 'samples', 'swarm',
        'swarm.dart')])
    swarm_size = 0
    try:
      swarm_size = os.path.getsize('swarm-result')
    except OSError:
      pass #If compilation failed, continue on running other tests.

    RunCmd([os.path.join('.', 'minfrog'), '--out=total-result',
        '--compile-only', os.path.join('..', 'client', 'samples', 'total',
        'src', 'Total.dart')])
    total_size = 0
    try:
      total_size = os.path.getsize('total-result')
    except OSError:
      pass #If compilation failed, continue on running other tests.

    RunCmd(['echo', '%d Generated checked swarm size' % swarm_size], 
        self.trace_file, append=True) 
    
    RunCmd(['echo', '%d Generated checked total size' % total_size], 
        self.trace_file, append=True) 
    os.chdir('..')

  def ProcessFile(self, afile):
    """Pull all the relevant information out of a given tracefile.
    Args:
      afile is the filename string we will be processing."""
    f = open(os.path.join(self.result_folder_name, afile))
    tabulate_data = False
    revision_num = 0
    for line in f.readlines():
      tokens = line.split()
      if 'Revision' in line:
        revision_num = int(line.split()[1])
      else:
        for metric in self.values_list:
          if metric in line:
            num = tokens[0]
            if num.find('.') == -1:
              num = int(num)
            else:
              num = float(num)
            self.values_dict[COMMAND_LINE][FROG][metric] += [num]
            self.revision_dict[COMMAND_LINE][FROG][metric] += [revision_num]
   
    if revision_num != 0: 
      for metric in self.values_list:
        self.revision_dict[COMMAND_LINE][FROG][metric].pop()
        self.revision_dict[COMMAND_LINE][FROG][metric] += [revision_num]
        # Fill 0 if compilation failed.
        if self.values_dict[COMMAND_LINE][FROG][metric][-1] < \
            self.failure_threshold[metric]:
          self.values_dict[COMMAND_LINE][FROG][metric] += [0]
          self.revision_dict[COMMAND_LINE][FROG][metric] += [revision_num]

    f.close()

  def PlotResults(self, png_filename):
    self.StyleAndSavePerfPlot('Compiled minfrog Sizes', 
        'Size (in bytes)', 10, 10, 'center', png_filename, [COMMAND_LINE],
        [FROG], ['swarm', 'total', 'minfrog'])
    self.WriteHtml('bar', self.revision_dict[COMMAND_LINE][FROG]['minfrog'], 
        'minfrog size', self.values_dict[COMMAND_LINE][FROG]['minfrog'], '', [])

    self.StyleAndSavePerfPlot('Time to compile and bootstrap', 
        'Seconds', 10, 10, 'center', '2' + png_filename, [COMMAND_LINE], [FROG],
        ['Bootstrapping', 'Compiling on Dart VM'])
    self.WriteHtml('baz',
        self.revision_dict[COMMAND_LINE][FROG]['Bootstrapping'], 
        'Bootstrapping', self.values_dict[COMMAND_LINE][FROG]['Bootstrapping'],
        'Compiling on Dart VM', 
        self.values_dict[COMMAND_LINE][FROG]['Compiling on Dart VM'])


def ParseArgs():
  parser = optparse.OptionParser()
  parser.add_option('--command-line', '-c', dest='cl', 
      help = 'Run the command line tests', 
      action = 'store_true', default = False) 
  parser.add_option('--size-time', '-s', dest = 'size', 
      help = 'Run the code size and timing tests', 
      action = 'store_true', default = False)
  parser.add_option('--language', '-l', dest = 'language', 
      help = 'Run the language correctness tests', 
      action = 'store_true', default = False)
  parser.add_option('--browser-perf', '-b', dest = 'perf',
      help = 'Run the browser performance tests',
      action = 'store_true', default = False)
  parser.add_option('--forever', '-f', dest = 'continuous',
      help = 'Run this script forever, always checking for the next svn '
      'checkin', action = 'store_true', default = False)
  parser.add_option('--perfbot', '-p', dest = 'perfbot',
      help = "Run in perfbot mode. (Generate plots, and remove trace files)", 
      action = 'store_true', default = False)
  parser.add_option('--verbose', '-v', dest = 'verbose',
      help = 'Print extra debug output', action = 'store_true', default = False)

  args, ignored = parser.parse_args()
  if not (args.cl or args.size or args.language or args.perf):
    args.cl = args.size = args.language = args.perf = True
  return (args.cl, args.size, args.language, args.perf, args.continuous,
      args.perfbot, args.verbose)

def RunTestSequence(cl, size, language, perf):
  if PERFBOT_MODE:
    # The buildbot already builds and syncs to a specific revision. Don't fight
    # with it or replicate work.
    SyncAndBuild()
  if cl:
    CommandLinePerformanceTestRunner('cl-results').Run()
  if size:
    CompileTimeAndSizeTestRunner('code-time-size').Run()
  if language:
    BrowserCorrectnessTestRunner('language', 'browser-correctness').Run()
  if perf:
    BrowserPerformanceTestRunner('browser-perf').Run()

def main():
  global PERFBOT_MODE, VERBOSE
  (cl, size, language, perf, continuous, perfbot, verbose) = ParseArgs()
  PERFBOT_MODE = perfbot
  VERBOSE = verbose
  if continuous:
    while True:
      if HasNewCode():
        RunTestSequence(cl, size, language, perf)
      else:
        time.sleep(SLEEP_TIME)
  else:
    RunTestSequence(cl, size, language, perf)

if __name__ == '__main__':
  main()

