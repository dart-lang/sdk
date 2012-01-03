Setup to run all performance tests:

TODO(efortuna): run through these steps again on a clean machine to make sure I
didn't leave anything out!

Overview:
 These are the instructions to run a wide variety of performance tests using 
 dart/tools/testing/perf_testing/create_graph.py. Currently the results are 
 uploaded to https://dartperf.googleplex.com/. 
 
 A variant of these tests are running on our buildbots to test Chrome and 
 Firefox (since the buildbots are Linux) that simply ensure that no changes to
 frog have broken updating the dom, but not for testing performance.

 This file details how to set up configurations for each setup. It is long,
 because there are many variants depending on what platform you're on, and what
 you want to set up.

============ Windows Installation =============

Setting up Windows on Mac hardware:
  If you need to install Windows 7 via dual-boot mac, use BootCamp to install 
  Windows 7 Professional. You can obtain a copy of Windows 7 (Google internal) 
  by getting an MSDN subscription via GUTS. When installing via BootCamp, don't 
  forget to also install the "WindowsSupport" drivers that are optional -- 
  you'll need them to be able to connect to any wireless network in Windows.

Great! You have a shiny dual-booting machine!

Use the following instructions to set up for Windows builds:
http://www.chromium.org/developers/how-tos/build-instructions-windows

NOTE: DO NOT USE Visual Studio 2010 to try to build the project!! Right now Dart
only builds with VS2008 versions!

Then:
1) Download installer for OpenSSL for Windows via 
   http://openssl.org/related/binaries.html
2) Install OpenSSL
3) Copy the directory OpenSSL-Win32/include/openssl to 
   C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\include
4) Copy the ***contents*** of the directory OpenSSL-Win32/lib/VC/static/ to 
   C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\lib

============= All Platforms ================

1) Ensure Python 2.7 is installed and in your path.

2) Install selenium library python bindings
     (http://pypi.python.org/pypi/selenium)

3) Mac only:
     Download and install xcode 3.2: 
     https://developer.apple.com/devcenter/download.action?path=/Developer_Tools/xcode_3.2.6_and_ios_sdk_4.3__final/xcode_3.2.6_and_ios_sdk_4.3.dmg
       a) Mount dmg
       b) LION only: At a terminal type:
       TODO(efortuna): verify
          $> export COMMAND_LINE_INSTALL=1
          $> open "/Volumes/Xcode and iOS SDK/Xcode and iOS SDK.mpkg"
       c) Install.

4) (Mac OS Lion only) Install xcode 4.0 and then run:
   $> xcode-select -switch /path/to/xcode3.2.6/

5) Ensure Firefox is installed.

If you only want to run the smoketests, you're done! 
While standing in dart/tools/testing/perf_testing, run 
$> python create_graph.py -b
If everything goes well, you'll see it print out "PASS" at the command line.

To continue on to run the performance tests:

6) Ensure Java is installed and in your path. If not, install the  Java jdk 
   (so that we can run the webdriver server from its jar)

7) Add the following to your DEPS file in all.deps in the "deps = {" section:
  # Copy of Python appengine latest release version		
  "dart/third_party/appengine-python/1.5.4":		
    "http://googleappengine.googlecode.com/svn/trunk/python@199",

8) Download selenium-server-standalone-2.15.0.jar (only to run Safari) 
   http://selenium.googlecode.com/files/selenium-server-standalone-2.15.0.jar 
   and run it:
   $> java -jar selenium-server-standalone-2.15.0.jar

9) Ensure that Chrome, Safari and IE (Windows only) are installed.

10)Download the Chrome Driver: http://code.google.com/p/chromium/downloads/list
   and make sure it is in your path.

10)Disable pop-up blocking in Safari: 
   Preferences -> Security -> (unselect) Block pop-up windows.

11)TODO(efortuna): Deal with appengine check in! Run 
   '../../../third_party/appengine-python/1.5.4/appcfg.py update appengine/' 
   while standing in dart/tools/testing/perf_tests.

12)Install matplotlib http://matplotlib.sourceforge.net/

13)Pull down benchmarks from internal repo (Google only): 
   http://chromegw.corp.google.com/viewvc/dash/trunk/internal/browserBenchmarks/README.txt?view=markup

14) Run the tests! While standing in dart/tools/testing/perf_testing, run 
    $> python create_graph.py --forever --verbose --perfbot 
    to run all the tests (browser performance, language correctness in the
    browser, command line performance, and self-hosted compile time and compiled
    code size). 
    
    You can run individual tests by adding the particular option (such as 
    --language) when running create_graph.py. Type "create_graph.py -h" for a 
    full list of the options.
