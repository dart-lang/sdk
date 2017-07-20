// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'utils.dart';

String dart2jsHtml(String title, String scriptPath) {
  return """
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="dart.unittest" content="full-stack-traces">
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
  <script type="text/javascript"
          src="/root_dart/tools/testing/dart/test_controller.js">
  </script>
  <script type="text/javascript" src="$scriptPath"
          onerror="scriptTagOnErrorCallback(null)"
          defer>
  </script>
  <script type="text/javascript"
          src="/root_dart/pkg/browser/lib/dart.js"></script>
</body>
</html>""";
}

/// Generates the HTML template file needed to load and run a dartdevc test in
/// the browser.
///
/// The [testName] is the short name of the test without any subdirectory path
/// or extension, like "math_test". The [testJSDir] is the relative path to the
/// build directory where the dartdevc-generated JS file is stored.
String dartdevcHtml(String testName, String testJSDir, String buildDir) {
  var packagePaths = testPackages
      .map((package) => '    "$package": "/root_dart/$buildDir/gen/utils/'
          'dartdevc/pkg/$package",')
      .join("\n");

  return """
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="dart.unittest" content="full-stack-traces">
  <title>Test $testName</title>
  <style>
     .unittest-table { font-family:monospace; border:1px; }
     .unittest-pass { background: #6b3;}
     .unittest-fail { background: #d55;}
     .unittest-error { background: #a11;}
  </style>
</head>
<body>
<h1>Running $testName</h1>
<script type="text/javascript"
        src="/root_dart/tools/testing/dart/test_controller.js">
</script>
<script>
var require = {
  baseUrl: "/root_dart/$testJSDir",
  paths: {
    "dart_sdk": "/root_dart/pkg/dev_compiler/lib/js/amd/dart_sdk",
$packagePaths
  }
};

// Don't try to bring up the debugger on a runtime error.
window.ddcSettings = {
  trapRuntimeErrors: false
};
</script>
<script type="text/javascript"
        src="/root_dart/third_party/requirejs/require.js"></script>
<script type="text/javascript">
requirejs(["$testName", "dart_sdk", "async_helper"],
    function($testName, dart_sdk, async_helper) {  
  function finish() {
    // dev_compiler's test runner (language_test.js) uses this to notify the
    // test results, but it isn't needed for test.dart.
  }
  
  // TODO(rnystrom): This uses DDC's forked version of async_helper. Unfork
  // these packages when possible.
  async_helper.async_helper.asyncTestInitialize(finish);
  
  dart_sdk._isolate_helper.startRootIsolate(function() {}, []);
  dartMainRunner($testName.$testName.main);
});
</script>
</body>
</html>
""";
}
