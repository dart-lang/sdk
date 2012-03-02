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

2) Run the following command while standing in this directory:
     $> sudo buildbot_browser_test_setup.sh
     
     If that doesn't work, or you're running Windows, here are the manual steps:
     a) Install selenium library python bindings
        (http://pypi.python.org/pypi/selenium)
     b) Ensure Firefox is installed.

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

5) Ensure Java is installed and in your path. If not, install the  Java jdk 
   (so that we can run the webdriver server from its jar)

6) Download selenium-server-standalone-2.15.0.jar (only to run Safari) 
   http://selenium.googlecode.com/files/selenium-server-standalone-2.15.0.jar 
   and run it:
   $> java -jar selenium-server-standalone-2.15.0.jar

7) Ensure that Chrome, Safari and IE (Windows only) are installed.

8)Download the Chrome Driver: http://code.google.com/p/chromium/downloads/list
   and make sure it is in your path.

9) a) Disable pop-up blocking in Safari: 
       Preferences -> Security -> (unselect) Block pop-up windows.
    b) copy the file in /Library/Preferences/com.apple.Safari.plist to 
       $DARTDIR/tools/testing/com.apple.Safari.plist
       (We do this because Safari deletes our preferences (on no pop-up 
       blocking) if it crashes (aka times out) two times in a row.)

If you just want smoketests, you're done! Run them by typing:

$> tools/testing/bin/$YOUR_OS_DIR/dart tools/test.dart --component=webdriver
--report --timeout=20 --mode=release --browser=[ff | safari | chrome | ie]
[--frog=path/to/frog/executable/like/Release_ia32/dart-sdk/frogc
--froglib=path/to/frog/lib/like/dart/frog/lib] test_to_run(like "language" or
"corelib")

(If you don't specify frog and froglib arguments, we default to using the frogsh
living in your frog directory.)

========= Proceed further only if you also want to run performance tests.======

10)Download appengine for Python and place it in third_party (http://code.google.com/appengine/downloads.html#Google_App_Engine_SDK_for_Python):
  "dart/third_party/appengine-python/"

11)Install matplotlib http://matplotlib.sourceforge.net/

12)Pull down benchmarks from internal repo (Google only): 
   http://chromegw.corp.google.com/viewvc/dash/trunk/internal/browserBenchmarks/README.txt?view=markup

13)TODO(efortuna): Deal with appengine check in! Run 
   '../../../third_party/appengine-python/1.5.4/appcfg.py update appengine/' 
   while standing in dart/tools/testing/perf_tests.

14) Run the tests! While standing in dart/tools/testing/perf_testing, run 
    $> python create_graph.py --forever --verbose 
    to run all the tests (browser performance, language correctness in the
    browser, command line performance, and self-hosted compile time and compiled
    code size). 
    
    You can run individual tests by adding the particular option (such as 
    --language) when running create_graph.py. Type "create_graph.py -h" for a 
    full list of the options.
