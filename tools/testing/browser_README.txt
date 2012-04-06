Overview:
 These are the instructions to run a wide variety of browser tests using 
 test.dart --component=webdriver or 
 dart/tools/testing/perf_testing/run_perf_tests.py. Currently the results of
 run_perf_tests are uploaded to https://dartperf.googleplex.com/. 
 
============== Windows Setup ==============

Open Internet Explorer. Open the Internet Options dialog, and move to the
"Security" tab. Click through Internet, Local Intranet, Trusted sites, and
Restricted site and ensure the "Enable Protected Mode" is checked for all zones
or unchecked for all zones. Then click to the "Advanced" tab, scroll down to the
"Security" section, and check the checkbox "Allow active content to run in files
on My Computer."

================ Mac Setup ================

1) Ensure Java is installed and in your path (if you want to run Safari). If 
   not, install the  Java jdk (so that we can run the webdriver server from its 
  jar)

2) a) Disable pop-up blocking in Safari: 
      Preferences -> Security -> (unselect) Block pop-up windows.
   b) copy the file in /Library/Preferences/com.apple.Safari.plist to 
      $DARTDIR/tools/testing/com.apple.Safari.plist
      (We do this because Safari deletes our preferences (on no pop-up 
      blocking) if it crashes (aka times out) two times in a row.)

============= All Platforms ================

THE EASISET WAY:
1) Ensure Python 2.7 is installed and in your path.
2) Download and install Chrome in the default location if you haven't done so
   already.
3) Run the following script as root/administrator while standing in this
   directory:
   $> [sudo] python dart/tools/testing/perf_testing/webdriver_test_setup.py
4) Profit!

Example Run:
$> tools/test.py --component=webdriver --report --timeout=20 --mode=release 
--browser=[ff | safari | chrome | ie] 
[--frog=path/to/frog/executable/like/Release_ia32/dart-sdk/frogc
--froglib=path/to/frog/lib/like/dart/frog/lib] test_to_run(like "language" or
"corelib")

(If you don't specify frog and froglib arguments, we default to using frog with
the VM.)


============================================
Okay, so you're still here? Here's the long version of what that script does if
it didn't work for you:
a) Install selenium library python bindings
   (http://pypi.python.org/pypi/selenium)

b) Ensure that Firefox is installed in the default location.

c) Download the Chrome Driver: http://code.google.com/p/chromium/downloads/list
   and make sure it is in your path.

d) Download the selenium server (version 2.15 or newer) and place it in this 
   directory: 
    http://selenium.googlecode.com/files/selenium-server-standalone-2.15.0.jar


========= Proceed further only if you also want to run performance tests.======

10)Download appengine for Python and place it in third_party (http://code.google.com/appengine/downloads.html#Google_App_Engine_SDK_for_Python):
  "dart/third_party/appengine-python/"

11)Install matplotlib http://matplotlib.sourceforge.net/

12)Pull down benchmarks from internal repo (Google only): 
   http://chromegw.corp.google.com/viewvc/dash/trunk/internal/browserBenchmarks/README.txt?view=markup

13)Create a directory in called appengine-python in third_party. Download and 
   install App Engine in the directory you just created. 
   http://code.google.com/appengine/downloads.html

14) Run the tests! While standing in dart/tools/testing/perf_testing, run 
    $> python run_perf_tests.py --forever --verbose 
    to run all the tests (browser performance, language correctness in the
    browser, command line performance, and self-hosted compile time and compiled
    code size). 
    
    You can run individual tests by adding the particular option (such as 
    --language) when running create_graph.py. Type "create_graph.py -h" for a 
    full list of the options.
