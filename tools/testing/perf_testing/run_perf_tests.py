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
sys.path.append(TOOLS_PATH)
import utils

"""This script runs to track performance and size progress of
different svn revisions. It tests to see if there a newer version of the code on
the server, and will sync and run the performance tests if so."""

DART_INSTALL_LOCATION = abspath(os.path.join(dirname(abspath(__file__)),
                                             '..', '..', '..'))
_suffix = ''
if platform.system() == 'Windows':
  _suffix = '.exe'
DART_VM = os.path.join(DART_INSTALL_LOCATION,
                       utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32'),
                       'dart-sdk',
                       'bin',
                       'dart' + _suffix)
DART_COMPILER = os.path.join(DART_INSTALL_LOCATION,
                             utils.GetBuildRoot(utils.GuessOS(),
                                                'release', 'ia32'),
                             'dart-sdk',
                             'bin',
                             'frogc')

GEO_MEAN = 'Geo-Mean'
COMMAND_LINE = 'commandline'
JS = 'js'
FROG = 'frog'
JS_AND_FROG = [JS, FROG]
COLORS = ['blue', 'green', 'red', 'cyan', 'magenta', 'black']
GRAPH_OUT_DIR = 'graphs'

BROWSER_PERF = 'browser-perf'
TIME_SIZE = 'time-size'
CL_PERF = 'cl-perf'
# TODO(vsm): Merge these?
DROMAEO = 'dromaeo'
DROMAEO_SIZE = 'dromaeo-size'

SLEEP_TIME = 200
VERBOSE = False
HAS_SHELL = False
if platform.system() == 'Windows':
  # On Windows, shell must be true to get the correct environment variables.
  HAS_SHELL = True

"""First, some utility methods."""

def run_cmd(cmd_list, outfile=None, append=False, std_in=''):
  """Run the specified command and print out any output to stdout.

  Args:
    cmd_list: a list of strings that make up the command to run
    outfile: a string indicating the name of the file that we should write
       stdout to
    append: True if we want to append to the file instead of overwriting it"""
  if VERBOSE:
    print ' '.join(cmd_list)
  out = subprocess.PIPE
  if outfile:
    mode = 'w'
    if append:
      mode = 'a'
    out = open(outfile, mode)
    if append:
      # Annoying Windows "feature" -- append doesn't actually append unless you
      # explicitly go to the end of the file.
      # http://mail.python.org/pipermail/python-list/2009-October/1221859.html
      out.seek(0, os.SEEK_END)
  p = subprocess.Popen(cmd_list, stdout = out, stderr=subprocess.PIPE,
      stdin=subprocess.PIPE, shell=HAS_SHELL)
  output, not_used = p.communicate(std_in);
  if output:
    print output
  return output

def time_cmd(cmd):
  """Determine the amount of (real) time it takes to execute a given command."""
  start = time.time()
  run_cmd(cmd)
  return time.time() - start

def sync_and_build():
  """Make sure we have the latest version of of the repo, and build it. We
  begin and end standing in DART_INSTALL_LOCATION.

  Returns:
    err_code = 1 if there was a problem building."""
  os.chdir(DART_INSTALL_LOCATION)
  #Revert our newly built minfrog to prevent conflicts when we update
  run_cmd(['svn', 'revert',  os.path.join(os.getcwd(), 'frog', 'minfrog')])

  run_cmd(['gclient', 'sync'])

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
  # TODO(efortuna): Currently always building ia32 architecture because we don't
  # have test statistics for what's passing on x64. Eliminate arch specification
  # when we have tests running on x64, too.
  shutil.rmtree(os.path.join(os.getcwd(),
      utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32')),
      onerror=on_rm_error)
  lines = run_cmd([os.path.join('.', 'tools', 'build.py'), '-m', 'release',
      '--arch=ia32', 'create_sdk'])
  lines = run_cmd([os.path.join('.', 'tools', 'build.py'), '-m', 'release',
      '--arch=ia32', 'dart2js']) #Built only for the v8 target for CL tests.

  for line in lines:
    if 'BUILD FAILED' in lines:
      # Someone checked in a broken build! Just stop trying to make it work
      # and wait to try again.
      print 'Broken Build'
      return 1
  return 0

def ensure_output_directory(dir_name):
  """Test that the listed directory name exists, and if not, create one for
  our output to be placed.

  Args:
    dir_name: the directory we will create if it does not exist."""
  dir_path = os.path.join(DART_INSTALL_LOCATION, 'tools', 'testing',
      'perf_testing', dir_name)
  if not os.path.exists(dir_path):
    os.mkdir(dir_path)
    print 'Creating output directory ', dir_path

def has_new_code():
  """Tests if there are any newer versions of files on the server."""
  os.chdir(DART_INSTALL_LOCATION)
  # Pass 'p' in if we have a new certificate for the svn server, we want to
  # (p)ermanently accept it.
  results = run_cmd(['svn', 'st', '-u'], std_in='p')
  for line in results:
    if '*' in line:
      return True
  return False

# TODO(vsm): Add Dartium.
def get_browsers():
  browsers = ['ff', 'chrome']
  if platform.system() == 'Darwin':
    browsers += ['safari']
  if platform.system() == 'Windows':
    browsers += ['ie']
  return browsers

# TODO(vsm): Factor benchmark specific code to a better location.
def get_standalone_benchmarks():
  return ['Mandelbrot', 'DeltaBlue', 'Richards', 'NBody', 'BinaryTrees',
  'Fannkuch', 'Meteor', 'BubbleSort', 'Fibonacci', 'Loop', 'Permute',
  'Queens', 'QuickSort', 'Recurse', 'Sieve', 'Sum', 'Tak', 'Takl', 'Towers',
  'TreeSort']

def get_os_directory():
  """Specifies the name of the directory for the testing build of dart, which
  has yet a different naming convention from utils.getBuildRoot(...)."""
  if platform.system() == 'Windows':
    return 'windows'
  elif platform.system() == 'Darwin':
    return 'macos'
  else:
    return 'linux'

def upload_to_app_engine(suite_names):
  """Upload our results to our appengine server.
  Arguments:
    suite_names: Directories to upload data from (should match suite names)
  """
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
  run_cmd([os.path.join('..', '..', '..', 'third_party',
      'appengine-python', 'appcfg.py'), '--oauth2', 'update',
      'appengine/'])


class TestRunner(object):
  """The base class to provide shared code for different tests we will run and
  graph."""

  def __init__(self, result_folder_name, platform_list, variants,
               values_list):
    """Args:
         result_folder_name the name of the folder where a tracefile of
         performance results will be stored.
         platform_list a list containing the platform(s) that our data has been
            run on. (command line, firefox, chrome, etc)
         variants a list specifying whether we hold data about Frog
            generated code, plain JS code (js), or a combination of both.
         values_list a list containing the type of data we will be graphing
            (benchmarks, percentage passing, etc)"""
    self.result_folder_name = result_folder_name
    # cur_time is used as a timestamp of when this performance test was run.
    self.cur_time = str(time.mktime(datetime.datetime.now().timetuple()))
    # TODO(vsm): Factor out.
    self.browser_color = {'chrome': 'green', 'ie': 'blue', 'ff': 'red',
        'safari':'black'}
    self.values_list = values_list
    self.platform_list = platform_list
    self.revision_dict = dict()
    self.values_dict = dict()
    self.color_index = 0
    for platform in platform_list:
      self.revision_dict[platform] = dict()
      self.values_dict[platform] = dict()
      for f in variants:
        self.revision_dict[platform][f] = dict()
        self.values_dict[platform][f] = dict()
        for val in values_list:
          self.revision_dict[platform][f][val] = []
          self.values_dict[platform][f][val] = []
        self.revision_dict[platform][f][GEO_MEAN] = []
        self.values_dict[platform][f][GEO_MEAN] = []

  def get_color(self):
    color = COLORS[self.color_index]
    self.color_index = (self.color_index + 1) % len(COLORS)
    return color

  def style_and_save_perf_plot(self, chart_title, y_axis_label, size_x, size_y,
      legend_loc, filename, platform_list, variants, values_list,
      should_clear_axes=True):
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
          plt.plot(self.revision_dict[platform][f][val],
              self.values_dict[platform][f][val],
              color=self.get_color(), label='%s-%s-%s' % (platform, f, val))

    plt.xlabel('Revision Number')
    plt.ylabel(y_axis_label)
    plt.title(chart_title)
    fontP = FontProperties()
    fontP.set_size('small')
    plt.legend(loc=legend_loc, prop = fontP)

    fig = plt.gcf()
    fig.set_size_inches(size_x, size_y)
    fig.savefig(os.path.join(GRAPH_OUT_DIR, filename))

  def add_svn_revision_to_trace(self, outfile):
    """Add the svn version number to the provided tracefile."""
    def search_for_revision(svn_info_command):
      p = subprocess.Popen(svn_info_command, stdout = subprocess.PIPE,
                           stderr = subprocess.STDOUT, shell = HAS_SHELL)
      output, _ = p.communicate()
      for line in output.split('\n'):
        if 'Revision' in line:
          run_cmd(['echo', line.strip()], outfile)
          return True
      return False

    if not search_for_revision(['svn', 'info']):
      if not search_for_revision(['git', 'svn', 'info']):
        run_cmd(['echo', 'Revision: unknown'], outfile)

  def calculate_geometric_mean(self, platform, variant, svn_revision):
    """Calculate the aggregate geometric mean for JS and frog benchmark sets,
    given two benchmark dictionaries."""
    geo_mean = 0
    for benchmark in self.values_list:
      geo_mean += math.log(self.values_dict[platform][variant][benchmark][
          len(self.values_dict[platform][variant][benchmark]) - 1])

    self.values_dict[platform][variant][GEO_MEAN] += \
        [math.pow(math.e, geo_mean / len(self.values_list))]
    self.revision_dict[platform][variant][GEO_MEAN] += [svn_revision]

  def run(self, graph_only):
    """Run the benchmarks/tests from the command line and plot the
    results."""
    plt.cla() # cla = clear current axes
    os.chdir(DART_INSTALL_LOCATION)
    ensure_output_directory(self.result_folder_name)
    ensure_output_directory(GRAPH_OUT_DIR)
    if not graph_only:
      self.run_tests()

    os.chdir(os.path.join('tools', 'testing', 'perf_testing'))

    # TODO(efortuna): You will want to make this only use a subset of the files
    # eventually.
    files = os.listdir(self.result_folder_name)

    for afile in files:
      if not afile.startswith('.'):
        self.process_file(afile)

    if 'plt' in globals():
      # Only run Matplotlib if it is installed.
      self.plot_results('%s.png' % self.result_folder_name)
    else:
      print 'Unable to import Matplotlib and therefore unable to generate ' + \
          'graphs. Please install it for this version of Python.'

class PerformanceTest(TestRunner):
  """Super class for all performance testing."""
  def __init__(self, result_folder_name, platform_list, platform_type,
               versions, benchmarks):
    super(PerformanceTest, self).__init__(result_folder_name,
        platform_list, versions, benchmarks)
    self.platform_list = platform_list
    self.platform_type = platform_type
    self.versions = versions
    self.benchmarks = benchmarks

  def plot_all_perf(self, png_filename):
    """Create a plot that shows the performance changes of individual benchmarks
    run by JS and generated by frog, over svn history."""
    for benchmark in self.benchmarks:
      self.style_and_save_perf_plot(
          'Performance of %s over time on the %s on %s' % (benchmark,
          self.platform_type, utils.GuessOS()), 'Speed (bigger = better)', 16,
          14, 'lower left', benchmark + png_filename, self.platform_list,
          self.versions, [benchmark])

  def plot_avg_perf(self, png_filename):
    """Generate a plot that shows the performance changes of the geomentric mean
    of JS and frog benchmark performance over svn history."""
    (title, y_axis, size_x, size_y, loc, filename) = \
        ('Geometric Mean of benchmark %s performance on %s ' %
        (self.platform_type, utils.GuessOS()), 'Speed (bigger = better)', 16, 5,
        'lower left', 'avg'+png_filename)
    clear_axis = True
    for platform in self.platform_list:
      for version in self.versions:
        self.style_and_save_perf_plot(title, y_axis, size_x, size_y, loc,
                                      filename, [platform], [version],
                                      [GEO_MEAN], clear_axis)
        clear_axis = False

  def plot_results(self, png_filename):
    self.plot_all_perf(png_filename)
    self.plot_avg_perf('2' + png_filename)


class CommandLinePerformanceTest(PerformanceTest):
  """Run performance tests from the command line."""

  def __init__(self):
    super(CommandLinePerformanceTest, self).__init__(
        CL_PERF, [COMMAND_LINE], 'command line',
        JS_AND_FROG, get_standalone_benchmarks())

  def process_file(self, afile):
    """Pull all the relevant information out of a given tracefile.

    Args:
      afile: The filename string we will be processing."""
    os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools', 'testing',
        'perf_testing'))
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
        if len(tokens) < 4 or tokens[0] not in self.benchmarks:
          #Done tabulating data.
          break
        js_value = float(tokens[1])
        frog_value = float(tokens[3])
        if js_value == 0 or frog_value == 0:
          #Then there was an error when this performance test was run. Do not
          #count it in our numbers.
          return
        benchmark = tokens[0]
        self.revision_dict[COMMAND_LINE][JS][benchmark] += [revision_num]
        self.values_dict[COMMAND_LINE][JS][benchmark] += [js_value]
        self.revision_dict[COMMAND_LINE][FROG][benchmark] += [revision_num]
        self.values_dict[COMMAND_LINE][FROG][benchmark] += [frog_value]
    f.close()

    self.calculate_geometric_mean(COMMAND_LINE, FROG, revision_num)
    self.calculate_geometric_mean(COMMAND_LINE, JS, revision_num)

  def run_tests(self):
    """Run a performance test on our updated system."""
    os.chdir('frog')
    self.trace_file = os.path.join('..', 'tools', 'testing', 'perf_testing',
        self.result_folder_name, 'result' + self.cur_time)
    run_cmd(['python', os.path.join('benchmarks', 'perf_tests.py')],
        self.trace_file)
    os.chdir('..')


class BrowserStandalonePerformanceTest(PerformanceTest):
  """Runs standalone performance tests, in the browser."""

  def __init__(self):
    super(BrowserStandalonePerformanceTest, self).__init__(
        BROWSER_PERF, get_browsers(), 'browser',
        JS_AND_FROG, get_standalone_benchmarks())

  def run_tests(self):
    """Run a performance test in the browser."""

    os.chdir('frog')
    run_cmd(['python', os.path.join('benchmarks', 'make_web_benchmarks.py')])
    os.chdir('..')

    for browser in get_browsers():
      for version in self.versions:
        self.trace_file = os.path.join('tools', 'testing', 'perf_testing',
            self.result_folder_name,
            'perf-%s-%s-%s' % (self.cur_time, browser, version))
        self.add_svn_revision_to_trace(self.trace_file)
        file_path = os.path.join(os.getcwd(), 'internal', 'browserBenchmarks',
            'benchmark_page_%s.html' % version)
        run_cmd(['python', os.path.join('tools', 'testing', 'run_selenium.py'),
            '--out', file_path, '--browser', browser,
            '--timeout', '600', '--mode', 'perf'], self.trace_file, append=True)

  def process_file(self, afile):
    """Comb through the html to find the performance results."""
    os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools', 'testing',
        'perf_testing'))
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
      if version == JS or version == 'v8':
        version = JS
        bench_dict = self.values_dict[browser][JS]
      else:
        bench_dict = self.values_dict[browser][FROG]
      bench_dict[name] += [float(score)]
      self.revision_dict[browser][version][name] += [revision_num]

    f.close()
    self.calculate_geometric_mean(browser, version, revision_num)


# TODO(vsm): This should not be hardcoded here if possible.
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
def get_valid_dromaeo_tags():
  tags = [tag for (tag, _) in DROMAEO_BENCHMARKS.values()]
  if platform.system() == 'Darwin':
    tags.remove('modify')
  return tags

def get_dromaeo_benchmarks():
  valid = get_valid_dromaeo_tags()
  benchmarks = reduce(lambda l1,l2: l1+l2,
                      [tests for (tag, tests) in
                       DROMAEO_BENCHMARKS.values() if tag in valid])
  return map(legalize_filename, benchmarks)

def get_dromaeo_versions():
  return ['js', 'frog_dom', 'frog_html']

def get_dromaeo_url_query(version):
  version = version.replace('_','&')
  tags = get_valid_dromaeo_tags()
  return '|'.join([ '%s&%s' % (version, tag) for tag in tags])

class DromaeoTest(PerformanceTest):
  """Runs Dromaeo tests, in the browser."""
  def __init__(self):
    super(DromaeoTest, self).__init__(
        DROMAEO, get_browsers(), 'browser',
        get_dromaeo_versions(), get_dromaeo_benchmarks())

  def run_tests(self):
    """Run dromaeo in the browser."""

    # Build tests.
    dromaeo_path = os.path.join('samples', 'third_party', 'dromaeo')
    current_path = os.getcwd()
    os.chdir(dromaeo_path)
    run_cmd(['python', 'generate_frog_tests.py'])
    os.chdir(current_path)

    versions = get_dromaeo_versions()

    for browser in get_browsers():
      for version_name in versions:
        version = get_dromaeo_url_query(version_name)
        self.trace_file = os.path.join('tools', 'testing', 'perf_testing',
            self.result_folder_name,
            'dromaeo-%s-%s-%s' % (self.cur_time, browser, version_name))
        self.add_svn_revision_to_trace(self.trace_file)
        file_path = os.path.join(os.getcwd(), dromaeo_path,
            'index-js.html?%s' % version)
        run_cmd(['python', os.path.join('tools', 'testing', 'run_selenium.py'),
                 '--out', file_path, '--browser', browser,
                 '--timeout', '200', '--mode', 'dromaeo'], self.trace_file,
                append=True)

  def process_file(self, afile):
    """Comb through the html to find the performance results."""
    parts = afile.split('-')
    browser = parts[2]
    version = parts[3]

    bench_dict = self.values_dict[browser][version]

    f = open(os.path.join(self.result_folder_name, afile))
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
              name = legalize_filename(r.group(1).strip(':'))
              score = float(r.group(2))
              bench_dict[name] += [float(score)]
              self.revision_dict[browser][version][name] += [revision_num]

    f.close()
    self.calculate_geometric_mean(browser, version, revision_num)


class DromaeoSizeTest(TestRunner):
  """Run tests to determine the compiled file output size of Dromaeo."""
  def __init__(self):
    super(DromaeoSizeTest, self).__init__(
        DROMAEO_SIZE,
        ['browser'], ['dart', 'frog_dom', 'frog_html', 'frog_htmlidiomatic'],
        DROMAEO_BENCHMARKS.keys())

  def run_tests(self):
    # Build tests.
    dromaeo_path = os.path.join('samples', 'third_party', 'dromaeo')
    current_path = os.getcwd()
    os.chdir(dromaeo_path)
    run_cmd(['python', os.path.join('generate_frog_tests.py')])
    os.chdir(current_path)

    self.trace_file = os.path.join('tools', 'testing', 'perf_testing',
        self.result_folder_name, self.result_folder_name + self.cur_time)
    self.add_svn_revision_to_trace(self.trace_file)

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
    for suite in DROMAEO_BENCHMARKS.keys():
      dart_size = 0
      try:
        dart_size = os.path.getsize(os.path.join(test_path,
                                                 'dom-%s.dart' % suite))
      except OSError:
        pass #If compilation failed, continue on running other tests.

      total_dart_size += dart_size
      run_cmd(['echo', 'Size (dart, %s): %s' % (suite, str(dart_size))],
              self.trace_file, append=True)

      for (variant, suffix) in variants:
        name = 'dom-%s%s.dart.js' % (suite, suffix)
        js_size = 0
        try:
          # TODO(vsm): Strip comments at least.  Consider compression.
          js_size = os.path.getsize(os.path.join(frog_path, name))
        except OSError:
          pass #If compilation failed, continue on running other tests.

        total_size[variant] += js_size
        run_cmd(['echo', 'Size (%s, %s): %s' % (variant, suite,
                                                str(js_size))],
                self.trace_file, append=True)

    # TODO(vsm): Change GEO_MEAN to sum.  The base class assumes
    # GEO_MEAN right now.
    run_cmd(['echo', 'Size (dart, %s): %s' % (total_dart_size, GEO_MEAN)],
            self.trace_file, append=True)
    for (variant, _) in variants:
      run_cmd(['echo', 'Size (%s, %s): %s' % (variant, GEO_MEAN,
                                              total_size[variant])],
              self.trace_file, append=True)


  def process_file(self, afile):
    """Pull all the relevant information out of a given tracefile.

    Args:
      afile: is the filename string we will be processing."""
    os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools', 'testing',
        'perf_testing'))
    f = open(os.path.join(self.result_folder_name, afile))
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
        self.values_dict['browser'][variant][metric] += [num]
        self.revision_dict['browser'][variant][metric] += [revision_num]

    f.close()

  def plot_results(self, png_filename):
    self.style_and_save_perf_plot(
        'Compiled Dromaeo Sizes',
        'Size (in bytes)', 10, 10, 'lower left', png_filename,
        ['browser'], ['dart', 'frog_dom', 'frog_html', 'frog_htmlidiomatic'],
        DROMAEO_BENCHMARKS.keys())

    self.style_and_save_perf_plot(
        'Compiled Dromaeo Sizes',
        'Size (in bytes)', 10, 10, 'lower left', '2' + png_filename,
        ['browser'], ['dart', 'frog_dom', 'frog_html', 'frog_htmlidiomatic'],
        [GEO_MEAN])



class CompileTimeAndSizeTest(TestRunner):
  """Run tests to determine how long minfrog takes to compile, and the compiled
  file output size of some benchmarking files."""
  def __init__(self):
    super(CompileTimeAndSizeTest, self).__init__(TIME_SIZE,
        [COMMAND_LINE], [FROG], ['Compiling on Dart VM', 'Bootstrapping',
        'minfrog', 'swarm', 'total'])
    self.failure_threshold = {'Compiling on Dart VM' : 1, 'Bootstrapping' : .5,
        'minfrog' : 100, 'swarm' : 100, 'total' : 100}

  def run_tests(self):
    os.chdir('frog')
    self.trace_file = os.path.join('..', 'tools', 'testing', 'perf_testing',
        self.result_folder_name, self.result_folder_name + self.cur_time)

    self.add_svn_revision_to_trace(self.trace_file)

    elapsed = time_cmd([DART_VM, os.path.join('.', 'minfrogc.dart'),
        '--out=minfrog', 'minfrog.dart'])
    run_cmd(['echo', '%f Compiling on Dart VM in production mode in seconds'
        % elapsed], self.trace_file, append=True)
    elapsed = time_cmd([os.path.join('.', 'minfrog'), '--out=minfrog',
        'minfrog.dart', os.path.join('tests', 'hello.dart')])
    if elapsed < self.failure_threshold['Bootstrapping']:
      #minfrog didn't compile correctly. Stop testing now, because subsequent
      #numbers will be meaningless.
      return
    size = os.path.getsize('minfrog')
    run_cmd(['echo', '%f Bootstrapping time in seconds in production mode' %
        elapsed], self.trace_file, append=True)
    run_cmd(['echo', '%d Generated checked minfrog size' % size],
        self.trace_file, append=True)

    run_cmd([DART_COMPILER, '--out=swarm-result',
        os.path.join('..', 'samples', 'swarm',
        'swarm.dart')])
    swarm_size = 0
    try:
      swarm_size = os.path.getsize('swarm-result')
    except OSError:
      pass #If compilation failed, continue on running other tests.

    run_cmd([DART_COMPILER, '--out=total-result',
        os.path.join('..', 'samples', 'total',
        'client', 'Total.dart')])
    total_size = 0
    try:
      total_size = os.path.getsize('total-result')
    except OSError:
      pass #If compilation failed, continue on running other tests.

    run_cmd(['echo', '%d Generated checked swarm size' % swarm_size],
        self.trace_file, append=True)

    run_cmd(['echo', '%d Generated checked total size' % total_size],
        self.trace_file, append=True)
    os.chdir('..')

  def process_file(self, afile):
    """Pull all the relevant information out of a given tracefile.

    Args:
      afile: is the filename string we will be processing."""
    os.chdir(os.path.join(DART_INSTALL_LOCATION, 'tools', 'testing',
        'perf_testing'))
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
        # Fill in 0 if compilation failed.
        if self.values_dict[COMMAND_LINE][FROG][metric][-1] < \
            self.failure_threshold[metric]:
          self.values_dict[COMMAND_LINE][FROG][metric] += [0]
          self.revision_dict[COMMAND_LINE][FROG][metric] += [revision_num]

    f.close()

  def plot_results(self, png_filename):
    self.style_and_save_perf_plot('Compiled minfrog Sizes',
        'Size (in bytes)', 10, 10, 'lower left', png_filename, [COMMAND_LINE],
        [FROG], ['swarm', 'total', 'minfrog'])

    self.style_and_save_perf_plot('Time to compile and bootstrap',
        'Seconds', 10, 10, 'lower left', '2' + png_filename, [COMMAND_LINE],
        [FROG], ['Bootstrapping', 'Compiling on Dart VM'])

# TODO(vsm): Make these names consistent with BROWSER_PERF, CL_PERF,
# etc. above.
SUITES = {
    CL_PERF: CommandLinePerformanceTest,
    TIME_SIZE: CompileTimeAndSizeTest,
    BROWSER_PERF: BrowserStandalonePerformanceTest,
    DROMAEO: DromaeoTest,
    DROMAEO_SIZE: DromaeoSizeTest,
}

def parse_args():
  parser = optparse.OptionParser()
  # TODO(vsm): Change to a list to scale.
  parser.add_option('--suites', '-s', dest='suites',
      help='Run the specified comma-separated test suites from set: %s' % \
                      ','.join(SUITES.keys()),
      action='store', default=None)
  parser.add_option('--forever', '-f', dest='continuous',
      help='Run this script forever, always checking for the next svn '
      'checkin', action='store_true', default=False)
  parser.add_option('--graph-only', '-g', dest='graph_only', default=False,
      help='Do not run tests, only regenerate graphs', action='store_true')
  parser.add_option('--nobuild', '-n', dest='no_build', action='store_true',
      help='Do not sync with the repository and do not rebuild.', default=False)
  parser.add_option('--upload', '-u', dest='upload',
      help='Upload data to app engine (will require authentication).', 
      action='store_true', default=False)
  parser.add_option('--verbose', '-v', dest='verbose',
      help='Print extra debug output', action='store_true', default=False)

  args, ignored = parser.parse_args()

  if not args.suites:
    suites = SUITES.values()
  else:
    suites = []
    suitelist = args.suites.split(',')
    for name in suitelist:
      if name in SUITES:
        suites.append(SUITES[name])
      else:
        print 'Error: Invalid suite %s not in %s' % (name,
                                                     ','.join(SUITES.keys()))
        sys.exit(1)
  return (suites, args.continuous, args.verbose, args.no_build,
          args.graph_only, args.upload)

def run_test_sequence(suites, no_build, graph_only, upload):
  # The buildbot already builds and syncs to a specific revision. Don't fight
  # with it or replicate work.
  if not no_build and sync_and_build() == 1:
    return # The build is broken.

  for test in suites:
    test().run(graph_only)

  if upload:
    upload_to_app_engine(SUITES.keys())

def main():
  global VERBOSE
  (suites, continuous, verbose, no_build, graph_only, upload) = parse_args()
  VERBOSE = verbose
  if continuous:
    while True:
      if has_new_code():
        run_test_sequence(suites, no_build, graph_only, upload)
      else:
        time.sleep(SLEEP_TIME)
  else:
    run_test_sequence(suites, no_build, graph_only, upload)

if __name__ == '__main__':
  main()
