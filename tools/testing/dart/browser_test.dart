// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of test_suite;

String getHtmlContents(String title,
                       String scriptType,
                       Path sourceScript) =>
"""
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
          src="/root_dart/pkg/unittest/lib/test_controller.js">
  </script>
  <script type="$scriptType" src="$sourceScript" onerror="externalError(null)"
          defer>
  </script>
  <script type="text/javascript"
          src="/root_dart/pkg/browser/lib/dart.js"></script>
  <script type="text/javascript"
          src="/root_dart/pkg/browser/lib/interop.js"></script>
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