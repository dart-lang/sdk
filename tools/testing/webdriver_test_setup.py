#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Run to install the necessary components to run webdriver on the buildbots or
# on your local machine. 
# Note: The setup steps can be done fairly easily by hand. This script is 
# intended to simply and reduce the time for setup since there are a fair number
# of steps.
 
# TODO(efortuna): Rewrite this script in Dart when the Process module has a
# better high level API.
import HTMLParser
import optparse
import os
import platform
import re
import shutil
import string
import subprocess
import sys
import urllib
import urllib2
import zipfile

def run_cmd(cmd, stdin=None):
  """Run the command on the command line in the shell. We print the output of
  the command.
  """
  print cmd
  p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, 
      stdin=subprocess.PIPE, shell=True)
  output, stderr = p.communicate(input=stdin)
  if output:
    print output
  if stderr:
    print stderr

def parse_args():
  parser = optparse.OptionParser()
  parser.add_option('--firefox', '-f', dest='firefox',
      help="Don't install Firefox", action='store_true', default=False)
  parser.add_option('--opera', '-o', dest='opera', default=False,
      help="Don't install Opera", action='store_true')
  parser.add_option('--chromedriver', '-c', dest='chromedriver',
      help="Don't install chromedriver.", action='store_true', default=False)
  parser.add_option('--iedriver', '-i', dest='iedriver',
      help="Don't install iedriver (only used on Windows).",
      action='store_true', default=False)
  parser.add_option('--seleniumrc', '-s', dest='seleniumrc', 
      help="Don't install the Selenium RC server (used for Safari and Opera "
           "tests).", action='store_true', default=False)
  parser.add_option('--python', '-p', dest='python',
      help="Don't install Selenium python bindings.", action='store_true',
      default=False)
  parser.add_option('--buildbot', '-b', dest='buildbot', action='store_true',
      help='Perform a buildbot selenium setup (buildbots have a different' +
      'location for their python executable).', default=False)
  args, _ = parser.parse_args()
  return args

def find_depot_tools_location(is_buildbot):
  """Depot_tools is our default install location for chromedriver, so we find
  its location on the filesystem.
  Arguments:
  is_buildbot - True if we are running buildbot machine setup (we can't detect
      this automatically because this script is not run at build time).
  """
  if is_buildbot:
    depot_tools = os.sep + os.path.join('b', 'depot_tools')
    if 'win32' in sys.platform or 'cygwin' in sys.platform:
      depot_tools = os.path.join('e:', depot_tools)
    return depot_tools
  else:
    path = os.environ['PATH'].split(os.pathsep)
    for loc in path:
      if 'depot_tools' in loc:
        return loc
  raise Exception("Could not find depot_tools in your path.")


class GoogleCodeInstaller(object):
  """Install code that is being hosted on Google Code."""

  def __init__(self, project_name, download_location, download_name_func):
    """ Create a object that will install code from a Google Code site.
    Arguments:
    project_name - The GoogleCode project name such as "selenium" or
    "chromedriver."
    download_location - Where to download the desired file on our filesystem.
    download_name_func - A function that takes a dictionary (currently with keys
    "os" and "version", but more can be added) that calculates the string
    representing the name of the download we want.
     """
    self.project_name = project_name
    self.download_location = download_location
    self.download_name_func = download_name_func
    self.download_regex_str = self.download_name_func({'os': self.get_os_str,
        'version': '.+'})

  def google_code_downloads_page(self):
    return 'http://code.google.com/p/%s/downloads/list' % self.project_name

  def google_code_download(self):
    return 'http://%s.googlecode.com/files/' % self.project_name

  def find_latest_version(self):
    """Find the latest version number of some code available for download on a
    Google code page. This was unfortunately done in an ad hoc manner because
    Google Code does not seem to have an API for their list of current 
    downloads(!).
    """
    google_code_site = self.google_code_downloads_page()
    f = urllib2.urlopen(google_code_site)
    latest = ''
    for line in f.readlines():
      if re.search(self.download_regex_str, line):
        suffix_index = line.find(
            self.download_regex_str[self.download_regex_str.rfind('.'):])
        name_end = self.download_regex_str.rfind('.+')
        name = self.download_name_func({'os': self.get_os_str, 'version': ''})
        name = name[:name.rfind('.')]
        version_str = line[line.find(name) + len(name) : suffix_index]
        orig_version_str = version_str
	if version_str.count('.') == 0:
          version_str = version_str.replace('_', '.')
	  version_str = re.compile(r'[^\d.]+').sub('', version_str)
        if latest == '':
          latest = '0.' * version_str.count('.')
          latest += '0'
	  orig_latest_str = latest
	else:
	  orig_latest_str = latest
          latest = latest.replace('_', '.')
	  latest = re.compile(r'[^\d.]+').sub('', latest)
        nums = version_str.split('.')
        latest_nums = latest.split('.')
        for (num, latest_num) in zip(nums, latest_nums):
          if int(num) > int(latest_num):
            latest = orig_version_str
            break
          else:
            latest = orig_latest_str
    if latest == '':
      raise Exception("Couldn't find the desired download on " + \
          ' %s.' % google_code_site)
    return latest

  def run(self):
    """Download and install the Google Code."""
    print 'Installing from %s' % self.project_name
    os_str = self.get_os_str
    version = self.find_latest_version()
    download_name = self.download_name_func({'os': os_str, 'version': version})
    urllib.urlretrieve(self.google_code_download() + '/' + download_name,
        os.path.join(self.download_location, download_name))
    if download_name.endswith('.zip'):
      if platform.system() != 'Windows':
        # The Python zip utility does not preserve executable permissions, but
        # this does not seem to be a problem for Windows, which does not have a
        # built in zip utility. :-/
        run_cmd('unzip -u %s -d %s' % (os.path.join(self.download_location,
                download_name), self.download_location), stdin='y')
      else:
        z = zipfile.ZipFile(os.path.join(self.download_location, download_name))
        z.extractall(self.download_location)
        z.close()
      os.remove(os.path.join(self.download_location, download_name))
    chrome_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
        'orig-chromedriver')
    if self.project_name == 'chromedriver' and os.path.exists(chrome_path):
      # We have one additional location to make sure chromedriver is updated.
      # TODO(efortuna): Remove this. See move_chrome_driver_if_needed in
      # perf_testing/run_perf_tests.py
      driver = 'chromedriver'
      if platform.system() == 'Windows':
        driver += '.exe'
      shutil.copy(os.path.join(self.download_location, driver),
          os.path.join(chrome_path, driver))

  @property
  def get_os_str(self):
    """The strings to indicate what OS a download is for as used on Google Code.
    """
    os_str = 'win'
    if 'darwin' in sys.platform:
      os_str = 'mac'
    elif 'linux' in sys.platform:
      os_str = 'linux32'
      if '64bit' in platform.architecture()[0]:
        os_str = 'linux64'
    return os_str


class FirefoxInstaller(object):
  """Installs the latest version of Firefox on the machine."""

  def ff_download_site(self, os_name):
    return 'http://releases.mozilla.org/pub/mozilla.org/firefox/releases/' + \
        'latest/%s/en-US/' % os_name

  @property
  def get_os_str(self):
    """Returns the string that Mozilla uses to denote which operating system a
    Firefox binary is for."""
    os_str = ('win32', '.exe')
    if 'darwin' in sys.platform:
      os_str = ('mac', '.dmg')
    elif 'linux' in sys.platform:
      os_str = ('linux-i686', '.tar.bz2')
      if '64bit' in platform.architecture()[0]:
        os_str = ('linux-x86_64', '.tar.bz2')
    return os_str

  def get_download_url(self):
    """Parse the html on the page to determine what is the latest download
    appropriate for our system."""
    f = urllib2.urlopen(self.ff_download_site(self.get_os_str[0]))
    download_name = ''
    for line in f.readlines():
      suffix = self.get_os_str[1]
      if (suffix + '"') in line:
        link_str = '<a href="'
        download_name = line[line.find(link_str) + len(link_str) : \
            line.find(suffix) + len(suffix)]
        break
    return '%s%s' % (self.ff_download_site(self.get_os_str[0]), download_name)

  def run(self):
    print 'Installing Firefox'
    if 'darwin' in sys.platform:
      urllib.urlretrieve(self.get_download_url(), 'firefox.dmg')
      run_cmd('hdiutil mount firefox.dmg')
      run_cmd('sudo cp -R /Volumes/firefox/Firefox.app /Applications')
      run_cmd('hdiutil unmount /Volumes/firefox/')
    elif 'win' in sys.platform:
      urllib.urlretrieve(self.get_download_url(), 'firefox_install.exe')
      run_cmd('firefox_install.exe -ms')
    else:
      run_cmd('wget -O - %s | tar -C ~ -jxv' % self.get_download_url())


class SeleniumBindingsInstaller(object):
  """Install the Selenium Webdriver bindings for Python."""

  SETUPTOOLS_SITE = 'http://python-distribute.org/distribute_setup.py'
  PIP_SITE = 'https://raw.github.com/pypa/pip/master/contrib/get-pip.py'
  def __init__(self, is_buildbot):
    self.is_buildbot = is_buildbot

  def run(self): 
    print 'Installing Selenium Python Bindings'
    admin_keyword = ''
    python_cmd = 'python'
    pip_cmd = 'pip'
    if 'win32' not in sys.platform and 'cygwin' not in sys.platform:
      admin_keyword = 'sudo'
      pip_cmd = '/usr/local/bin/pip'
    else:
      # The python installation is "special" on Windows buildbots.
      if self.is_buildbot:
        python_loc = os.path.join(
            find_depot_tools_location(self.is_buildbot), 'python_bin')
        python_cmd = os.path.join(python_loc, 'python')
        pip_cmd = os.path.join(python_loc, 'Scripts', pip_cmd)
      else:
        path = os.environ['PATH'].split(os.pathsep)
        for loc in path:
          if 'python' in loc or 'Python' in loc:
            pip_cmd = os.path.join(loc, 'Scripts', pip_cmd)
            break
    page = urllib2.urlopen(self.SETUPTOOLS_SITE)
    run_cmd('%s %s' % (admin_keyword, python_cmd), page.read())
    page = urllib2.urlopen(self.PIP_SITE)
    run_cmd('%s %s' % (admin_keyword, python_cmd), page.read())
    run_cmd('%s %s install -U selenium' % (admin_keyword, pip_cmd))

class OperaHtmlParser(HTMLParser.HTMLParser):
  """A helper class to parse Opera pages listing available downloads to find the
  correct download we want."""

  def initialize(self, rejection_func, accept_func):
    """Initialize some state for our parser.
    Arguments:
    rejection_func: A function that accepts the value of the URL and determines
      if it is of the type we are looking for.
    accept_func: A function that takes the URL and the "current best" URL and 
      determines if it is better than our current download url."""
    self.latest = 0
    self.rejection_func = rejection_func
    self.accept_func = accept_func

  def handle_starttag(self, tag, attrs):
    """Find the latest version."""
    if (tag == 'a' and attrs[0][0] == 'href' and
        self.rejection_func(attrs[0][1])):
      self.latest = self.better_func(attrs[0][1], self.latest)

class OperaInstaller(object):
  """Install from the Opera FTP website."""

  def find_latest_version(self, download_page, rejection_func, accept_func):
    """Get the latest non-beta version.
    Arguments:
    download_page: The initial page that lists all the download options.
    rejection_func: A function that accepts the value of the URL and determines
      if it is of the type we are looking for.
    accept_func: A function that takes the URL and the "current best" URL and 
      determines if it is better than our current download url."""
    f = urllib2.urlopen(download_page)
    parser = OperaHtmlParser()
    parser.initialize(rejection_func, accept_func)
    parser.feed(f.read())
    return str(parser.latest)

  def run(self):
    """Download and install Opera."""
    print 'Installing Opera'
    os_str = self.get_os_str
    download_name = 'http://ftp.opera.com/pub/opera/%s/' % os_str

    def higher_revision(new_version_str, current):
      version_string = new_version_str[:-1]
      if int(version_string) > current:
        return int(version_string)
      return current

    version = self.find_latest_version(
        download_name,
        lambda x: x[0] in string.digits and 'b' not in x and 'rc' not in x,
        higher_revision)
    download_name += version
    if ('linux' in sys.platform and 
        platform.linux_distribution()[0] == 'Ubuntu'):
      # Last time I tried, the .deb file you download directly from opera was
      # not installing correctly on Ubuntu. This installs Opera more nicely.
      os.system("sudo sh -c 'wget -O - http://deb.opera.com/archive.key | "
          "apt-key add -'")
      os.system("""sudo sh -c 'echo "deb http://deb.opera.com/opera/ """
          """stable non-free" > /etc/apt/sources.list.d/opera.list'""")
      run_cmd('sudo apt-get update')
      run_cmd('sudo apt-get install opera', stdin='y')
    else:
      if 'darwin' in sys.platform:
        dotted_version = '%s.%s' % (version[:2], version[2:])
        download_name += '/Opera_%s_Setup_Intel.dmg' % dotted_version
        urllib.urlretrieve(download_name, 'opera.dmg')
        run_cmd('hdiutil mount opera.dmg', stdin='qY\n')
        run_cmd('sudo cp -R /Volumes/Opera/Opera.app /Applications')
        run_cmd('hdiutil unmount /Volumes/Opera/')
      elif 'win' in sys.platform:
        download_name += '/en/Opera_%s_en_Setup.exe' % version
        urllib.urlretrieve(download_name, 'opera_install.exe')
        run_cmd('opera_install.exe -ms')
      else:
        # For all other flavors of linux, download the tar.
        download_name += '/'
        extension = '.tar.bz2'
        if '64bit' in platform.architecture()[0]:
          platform_str = '.x86_64'
        else:
          platform_str = '.i386'
        def get_acceptable_file(new_version_str, current):
          return new_version_str
        latest = self.find_latest_version(
            download_name,
            lambda x: x.startswith('opera') and x.endswith(extension)
                and platform_str in x,
            get_acceptable_file)
        download_name += latest
        run_cmd('wget -O - %s | tar -C ~ -jxv' % download_name)
        print ('PLEASE MANUALLY RUN "~/%s/install" TO COMPLETE OPERA '
            'INSTALLATION' %
            download_name[download_name.rfind('/') + 1:-len(extension)])

  @property
  def get_os_str(self):
    """The strings to indicate what OS a download is."""
    os_str = 'win'
    if 'darwin' in sys.platform:
      os_str = 'mac'
    elif 'linux' in sys.platform:
      os_str = 'linux'
    return os_str

def main():
  args = parse_args()
  if not args.python:
    SeleniumBindingsInstaller(args.buildbot).run()
  if not args.chromedriver:
    GoogleCodeInstaller('chromedriver',
        find_depot_tools_location(args.buildbot),
        lambda x: 'chromedriver_%(os)s_%(version)s.zip' % x).run()
  if not args.seleniumrc:
    GoogleCodeInstaller('selenium', os.path.dirname(os.path.abspath(__file__)),
        lambda x: 'selenium-server-standalone-%(version)s.jar' % x).run()
  if not args.iedriver and platform.system() == 'Windows':
    GoogleCodeInstaller('selenium', find_depot_tools_location(args.buildbot),
        lambda x: 'IEDriverServer_Win32_%(version)s.zip' % x).run()
  if not args.firefox:
    FirefoxInstaller().run()
  if not args.opera:
    OperaInstaller().run()

if __name__ == '__main__':
  main()
