// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String getHtmlContents(String title, String scriptType, String scriptPath) {
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
  <script type="$scriptType" src="$scriptPath"
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
String dartdevcHtml(String testName, String testJSDir) => """
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
  // TODO(29923): Add paths to the packages that are used in tests once they
  // are being built. Right now, they are compiled into the test module itself.
  paths: {
    "dart_sdk": "/root_dart/pkg/dev_compiler/lib/js/amd/dart_sdk",
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
requirejs(["$testName", "dart_sdk"],
    function($testName, dart_sdk) {  
  dart_sdk._isolate_helper.startRootIsolate(function() {}, []);
  dartMainRunner($testName.$testName.main);
});
</script>
</body>
</html>
""";

String dartTestWrapper(String libraryPathComponent) {
  return """
import '$libraryPathComponent' as test;

main() {
  print("dart-calling-main");
  test.main();
  print("dart-main-done");
}
""";
}
