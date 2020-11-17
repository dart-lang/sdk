// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:smith/configuration.dart' show NnbdMode;

import 'configuration.dart' show Compiler;
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
          src="/root_dart/pkg/test_runner/lib/src/test_controller.js">
  </script>
  <script type="text/javascript" src="$scriptPath"
          onerror="scriptTagOnErrorCallback(null)"
          defer>
  </script>
</body>
</html>""";
}

/// Transforms a path to a valid JS identifier.
///
/// This logic must be synchronized with [pathToJSIdentifier] in DDC at:
/// pkg/dev_compiler/lib/src/compiler/module_builder.dart
String pathToJSIdentifier(String path) {
  path = p.normalize(path);
  if (path.startsWith('/') || path.startsWith('\\')) {
    path = path.substring(1, path.length);
  }
  return _toJSIdentifier(path
      .replaceAll('\\', '__')
      .replaceAll('/', '__')
      .replaceAll('..', '__')
      .replaceAll('-', '_'));
}

/// Escape [name] to make it into a valid identifier.
String _toJSIdentifier(String name) {
  if (name.isEmpty) return r'$';

  // Escape any invalid characters
  StringBuffer buffer;
  for (var i = 0; i < name.length; i++) {
    var ch = name[i];
    var needsEscape = ch == r'$' || _invalidCharInIdentifier.hasMatch(ch);
    if (needsEscape && buffer == null) {
      buffer = StringBuffer(name.substring(0, i));
    }
    if (buffer != null) {
      buffer.write(needsEscape ? '\$${ch.codeUnits.join("")}' : ch);
    }
  }

  var result = buffer != null ? '$buffer' : name;
  // Ensure the identifier first character is not numeric and that the whole
  // identifier is not a keyword.
  if (result.startsWith(RegExp('[0-9]')) || _invalidVariableName(result)) {
    return '\$$result';
  }
  return result;
}

// Invalid characters for identifiers, which would need to be escaped.
final _invalidCharInIdentifier = RegExp(r'[^A-Za-z_$0-9]');

bool _invalidVariableName(String keyword, {bool strictMode = true}) {
  switch (keyword) {
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    case "await":

    case "break":
    case "case":
    case "catch":
    case "class":
    case "const":
    case "continue":
    case "debugger":
    case "default":
    case "delete":
    case "do":
    case "else":
    case "enum":
    case "export":
    case "extends":
    case "finally":
    case "for":
    case "function":
    case "if":
    case "import":
    case "in":
    case "instanceof":
    case "let":
    case "new":
    case "return":
    case "super":
    case "switch":
    case "this":
    case "throw":
    case "try":
    case "typeof":
    case "var":
    case "void":
    case "while":
    case "with":
      return true;
    case "arguments":
    case "eval":
    // http://www.ecma-international.org/ecma-262/6.0/#sec-future-reserved-words
    // http://www.ecma-international.org/ecma-262/6.0/#sec-identifiers-static-semantics-early-errors
    case "implements":
    case "interface":
    case "package":
    case "private":
    case "protected":
    case "public":
    case "static":
    case "yield":
      return strictMode;
  }
  return false;
}

/// Generates the HTML template file needed to load and run a dartdevc test in
/// the browser.
///
/// [testName] is the short name of the test without any subdirectory path
/// or extension, like "math_test". [testNameAlias] is the alias of the
/// test variable used for import/export (usually relative to its module root).
/// [testJSDir] is the relative path to the build directory where the
/// dartdevc-generated JS file is stored. [nonNullAsserts] enables non-null
/// assertions for non-nullable method parameters when running with weak null
/// safety. [weakNullSafetyErrors] enables null safety type violations to throw
/// when running in weak mode.
String dartdevcHtml(
    String testName,
    String testNameAlias,
    String testJSDir,
    Compiler compiler,
    NnbdMode mode,
    bool nonNullAsserts,
    bool weakNullSafetyErrors) {
  var testId = pathToJSIdentifier(testName);
  var testIdAlias = pathToJSIdentifier(testNameAlias);
  var isNnbd = mode != NnbdMode.legacy;
  var isNnbdStrong = mode == NnbdMode.strong;
  var sdkPath = isNnbdStrong ? 'sound/amd/dart_sdk' : 'kernel/amd/dart_sdk';
  var pkgDir = isNnbdStrong ? 'pkg_sound' : 'pkg_kernel';
  var packagePaths = testPackages
      .map((p) => '    "$p": "/root_build/gen/utils/dartdevc/$pkgDir/$p",')
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
        src="/root_dart/pkg/test_runner/lib/src/test_controller.js">
</script>
<script>
var require = {
  baseUrl: "/root_dart/$testJSDir",
  paths: {
    "dart_sdk": "/root_build/gen/utils/dartdevc/$sdkPath",
$packagePaths
  },
  waitSeconds: 30,
};

</script>
<script type="text/javascript"
        src="/root_dart/third_party/requirejs/require.js"></script>
<script type="text/javascript">
requirejs(["$testName", "dart_sdk", "async_helper"],
    function($testId, sdk, async_helper) {
  sdk._isolate_helper.startRootIsolate(function() {}, []);
  sdk._debugger.registerDevtoolsFormatter();

  testErrorToStackTrace = function(error) {
    var stackTrace = sdk.dart.stackTrace(error).toString();

    var lines = stackTrace.split("\\n");

    // Remove the first line, which is just "Error".
    lines = lines.slice(1);

    // Strip off all of the lines for the bowels of the test runner.
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].indexOf("dartMainRunner") != -1) {
        lines = lines.slice(0, i);
        break;
      }
    }

    // TODO(rnystrom): It would be nice to shorten the URLs of the remaining
    // lines too.
    return lines.join("\\n");
  };

  sdk.dart.addAsyncCallback = function() {
    async_helper.async_helper.asyncStart();
  };

  sdk.dart.removeAsyncCallback = function() {
    // removeAsyncCallback() is called *before* the async operation is
    // performed, but we don't want to report the test as being done until
    // after that operation completes, so wait for that callback to run.
    setTimeout(() => {
      async_helper.async_helper.asyncEnd();
    }, 0);
  };

  if ($isNnbd) {
    sdk.dart.weakNullSafetyWarnings(!($weakNullSafetyErrors || $isNnbdStrong));
    sdk.dart.weakNullSafetyErrors($weakNullSafetyErrors);
    sdk.dart.nonNullAsserts($nonNullAsserts);
  }

  dartMainRunner(function testMainWrapper() {
    // Some callbacks are not scheduled with timers/microtasks, so they don't
    // go through our async tracking (e.g. DOM events). For those tests, check
    // if the result of calling `main()` is a Future, and if so, wait for it.
    let result = $testId.$testIdAlias.main();
    if (sdk.async.Future.is(result)) {
      sdk.dart.addAsyncCallback();
      result.whenComplete(sdk.dart.removeAsyncCallback);
    }
    return result;
  });
});
</script>
</body>
</html>
""";
}
