Overview:
 These are the instructions to run a wide variety of browser tests using 
 test.dart or dart/tools/testing/perf_testing/run_perf_tests.py. Currently 
 the results of run_perf_tests are uploaded to
 https://dartperf.googleplex.com/. 
 
========= General Browser Setup ==========

See instructions on:
https://code.google.com/p/dart/wiki/BrowserTestSetup

========= Proceed further only if you also want to run performance tests.======

1) Download appengine for Python and place it in third_party (http://code.google.com/appengine/downloads.html#Google_App_Engine_SDK_for_Python):
  "dart/third_party/appengine-python/"

2) Install matplotlib http://matplotlib.sourceforge.net/

3) Pull down benchmarks from internal repo (Google only): 
   http://chromegw.corp.google.com/viewvc/dash/trunk/internal/browserBenchmarks/README.txt?view=markup

4) Create a directory in called appengine-python in third_party. Download and 
   install App Engine in the directory you just created. 
   http://code.google.com/appengine/downloads.html

5) Run the tests! While standing in dart/tools/testing/perf_testing, run 
   $> python run_perf_tests.py --forever --verbose 
   to run all the tests (browser performance, language correctness in the
   browser, command line performance, and self-hosted compile time and compiled
   code size). 

   You can run individual tests by adding the particular option (such as 
   --language) when running create_graph.py. Type "create_graph.py -h" for a 
   full list of the options.
