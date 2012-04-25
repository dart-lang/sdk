// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String GetHtmlContents(String title,
                       String controllerScript,
                       String scriptType,
                       String sourceScript) =>
"""
<!DOCTYPE html>
<html>
<head>
  <title> Test $title </title>
  <style>
     .unittest-table { font-family:monospace; border:1px; }
     .unittest-pass { background: #6b3;}
     .unittest-fail { background: #d55;}
     .unittest-error { background: #a11;}
  </style>
</head>
<body>
  <h1> Running $title </h1>
  <script type="text/javascript" src="$controllerScript"></script>
  <script type="text/javascript">
    // If nobody intercepts the error, finish the test.
    onerror = function(message, url, lineNumber) {
       if (window.layoutTestController) {
         window.layoutTestController.notifyDone();
       }
    };

    document.onreadystatechange = function() {
      if (document.readyState != "loaded") return;
      // If 'startedDartTest' is not set, that means that the test did not have
      // a chance to load. This will happen when a load error occurs in the VM.
      // Give the machine time to start up.
      setTimeout(function() {
        // A window.postMessage might have been enqueued after this timeout.
        // Just sleep another time to give the browser the time to process the
        // posted message.
        setTimeout(function() {
          if (layoutTestController && !layoutTestController.startedDartTest) {
            layoutTestController.notifyDone();
          }
        }, 0);
      }, 50);
    };
  </script>
  <script type="$scriptType" src="$sourceScript"></script>
</body>
</html>
""";

String WrapDartTestInLibrary(String test) =>
"""
#library('libraryWrapper');
#source('$test');
""";

String DartTestWrapper(String dartHome, String library) =>
"""
#library('test');

#import('${dartHome}/lib/unittest/unittest.dart', prefix: 'unittest');
#import('${dartHome}/lib/unittest/html_config.dart', prefix: 'config');

#import('${library}', prefix: "Test");

main() {
  config.useHtmlConfiguration();
  try {
    unittest.ensureInitialized();
    Test.main();
  } catch(var e, var trace) {
    unittest.reportTestError(e.message, trace);
  }
}
""";
