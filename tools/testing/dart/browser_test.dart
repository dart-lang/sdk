// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String getHtmlContents(String title,
                       Path controllerScript,
                       Path dartJsScript,
                       String scriptType,
                       Path sourceScript) =>
"""
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
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
  <script type="$scriptType" src="$sourceScript"></script>
  <script type="text/javascript" src="$dartJsScript"></script>
</body>
</html>
""";

String getHtmlLayoutContents(String scriptType, String sourceScript) =>
"""
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
</head>
<body>
  <script type="text/javascript">
    if (navigator.webkitStartDart) navigator.webkitStartDart();
  </script>
  <script type="$scriptType" src="$sourceScript"></script>
</body>
</html>
""";

String wrapDartTestInLibrary(Path test) =>
"""
library libraryWrapper;
part '$test';
""";

String dartTestWrapper(Path dartHome, Path library) =>
"""
library test;

import '${dartHome.append('pkg/unittest/unittest.dart')}' as unittest;
import '${dartHome.append('pkg/unittest/html_config.dart')}' as config;
import '${library}' as Test;

main() {
  config.useHtmlConfiguration();
  unittest.group('', Test.main);
}
""";

