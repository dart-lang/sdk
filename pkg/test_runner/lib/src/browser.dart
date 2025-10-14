// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

import 'configuration.dart' show Compiler;
import 'utils.dart';

// The native JavaScript Object prototype is sealed before loading the Dart
// SDK module to guard against prototype pollution.
final _sealNativeObjectScript =
    '/root_dart/sdk/lib/_internal/js_runtime/lib/preambles/'
    'seal_native_object.js';

String dart2jsHtml(String title, String scriptPath) {
  return """
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta charset="utf-8">
  <meta name="dart.unittest" content="full-stack-traces">
  <title> Test $title </title>
  <style>
     .unittest-table { font-family:monospace; border:1px; }
     .unittest-pass { background: #6b3;}
     .unittest-fail { background: #d55;}
     .unittest-error { background: #a11;}
  </style>
  <script type="text/javascript" src="$_sealNativeObjectScript"></script>
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

final _digitPattern = RegExp(r'\d');

/// Escape [name] to make it into a valid identifier.
String _toJSIdentifier(String name) {
  if (name.isEmpty) return r'$';

  // Escape any invalid characters
  var result = name.replaceAllMapped(
      _invalidCharInIdentifier, (match) => '\$${match[0]!.codeUnits.join("")}');

  // Ensure the identifier first character is not numeric and that the whole
  // identifier is not a keyword.
  if (result.startsWith(_digitPattern) || _invalidVariableName(result)) {
    return '\$$result';
  }
  return result;
}

// Invalid characters for identifiers, which would need to be escaped.
final _invalidCharInIdentifier = RegExp(r'[^A-Za-z_\d]');

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

/// Generates the HTML template file needed to load and run a ddc test in
/// the browser.
///
/// [testName] is the short name of the test without any subdirectory path
/// or extension, like "math_test". [testNameAlias] is the alias of the
/// test variable used for import/export (usually relative to its module root).
/// [testJSDir] is the relative path to the build directory where the
/// ddc-generated JS file is stored. [ddcModuleFormat] determines whether to
/// emit a template that works with the DDC module format or one that works with
/// the AMD module format. [canaryMode] is whether DDC is running in canary
/// mode. If this flag and [ddcModuleFormat] is enabled, a template that works
/// with the DDC hot reload format will be emitted.
String ddcHtml(
    String testName,
    String testNameAlias,
    String testJSDir,
    Compiler compiler,
    String genDir,
    bool nativeNonNullAsserts,
    bool jsInteropNonNullAsserts,
    {bool ddcModuleFormat = false,
    bool canaryMode = false}) {
  var testId = pathToJSIdentifier(testName);
  var testIdAlias = pathToJSIdentifier(testNameAlias);
  var ddcGenDir = '/root_build/$genDir';
  var hotReloadFormat = ddcModuleFormat && canaryMode;

  var sdkAndAsyncHelperSetup = """
_debugger.registerDevtoolsFormatter();

testErrorToStackTrace = function(error) {
  var stackTrace = getStackTraceString(error);

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
""";

  var sdkFlagSetup = """
runtime.nativeNonNullAsserts($nativeNonNullAsserts);
runtime.jsInteropNonNullAsserts($jsInteropNonNullAsserts);
""";

  String script;
  if (ddcModuleFormat) {
    var appName = '/root_dart/$testJSDir';
    // Used in the DDC module system for multi-app workflows, and are simply
    // placeholder values here.
    var uuid = '00000000-0000-0000-0000-000000000000';
    var loadPackagesScript = [
      for (var p in testPackages)
        """<script defer type="text/javascript"
                src="$ddcGenDir/pkg/ddc/$p.js"></script>"""
    ].join('\n');
    String libraryImports;
    String startCode;
    if (hotReloadFormat) {
      libraryImports = """
        let _debugger = dartDevEmbedder.debugger;
        let getStackTraceString = function(error) {
          return _debugger.stackTrace(error);
        }
      """;
      sdkFlagSetup = """
        let sdkOptions = {
          nativeNonNullAsserts: $nativeNonNullAsserts,
          jsInteropNonNullAsserts: $jsInteropNonNullAsserts,
        };
      """;
      startCode =
          """dartDevEmbedder.runMain("org-dartlang-app:/$testNameAlias.dart",
          sdkOptions);""";
    } else {
      libraryImports = """
        let sdk = dart_library.import("dart_sdk", "$appName");
        let runtime = sdk.dart;
        let getStackTraceString = function(error) {
          return runtime.stackTrace(error).toString();
        }
        let _debugger = sdk._debugger;
      """;
      startCode = """dart_library.start("$appName", "$uuid", "$testName",
          "$testIdAlias", false)""";
    }
    script = """
<script defer type="text/javascript"
src="/root_dart/pkg/dev_compiler/lib/js/ddc/ddc_module_loader.js"></script>
<script defer type="text/javascript" src="$ddcGenDir/sdk/ddc/dart_sdk.js"></script>
$loadPackagesScript
<script defer type="text/javascript" src="$appName/$testName.js"></script>
<script type="text/javascript">"""
// DDC module format doesn't defer the execution until the document is finished
// parsing. We can defer scripts, but only if they are in separate files and not
// inline JS like below. In order to make sure everything is loaded and be
// consistent with the AMD module format, we should wait until a
// `DOMContentLoaded` event is fired. Other options are using `type = "module"`
// or putting this in a separate JS file, but this is the simplest solution.
        """
document.addEventListener("DOMContentLoaded", (e) => {
  $libraryImports
  $sdkAndAsyncHelperSetup
  $sdkFlagSetup

  dartMainRunner(function () {
    return $startCode;
  });
});
</script>
    """;
  } else {
    var packagePaths = [
      for (var p in testPackages) '    "$p": "$ddcGenDir/pkg/amd/$p",'
    ].join("\n");
    script = """
<script>
var require = {
  baseUrl: "/root_dart/$testJSDir",
  paths: {
    "dart_sdk": "$ddcGenDir/sdk/amd/dart_sdk",
$packagePaths
  },
  waitSeconds: 45,
};
</script>
<script type="text/javascript"
        src="/root_dart/third_party/requirejs/require.js"></script>
<script type="text/javascript">
requirejs(["$testName", "dart_sdk"], function($testId, sdk) {
  let runtime = sdk.dart;
  let getStackTraceString = function(error) {
    return runtime.stackTrace(error).toString();
  }
  let _debugger = sdk._debugger;

  $sdkAndAsyncHelperSetup
  $sdkFlagSetup

  dartMainRunner(function testMainWrapper() {
    return $testId.$testIdAlias.main();
  });
});
</script>
    """;
  }
  return """
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta charset="utf-8">
  <meta name="dart.unittest" content="full-stack-traces">
  <title>Test $testName</title>
  <style>
     .unittest-table { font-family:monospace; border:1px; }
     .unittest-pass { background: #6b3;}
     .unittest-fail { background: #d55;}
     .unittest-error { background: #a11;}
  </style>
  <script type="text/javascript" src="$_sealNativeObjectScript"></script>
</head>
<body>
<h1>Running $testName</h1>
<script type="text/javascript"
        src="/root_dart/pkg/test_runner/lib/src/test_controller.js">
</script>
$script
</body>
</html>
""";
}

String dart2wasmHtml(
    String title, String wasmPath, String mjsPath, String supportJsPath) {
  return """
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta charset="utf-8">
  <meta name="dart.unittest" content="full-stack-traces">
  <title> Test $title </title>
  <link rel="preload" href="$wasmPath" as="fetch" crossorigin>
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
  <script type="module">
  async function loadAndRun(mjsPath, wasmPath, supportJsPath) {
    const supportJSExpression = await (await fetch(supportJsPath)).text();
    const support = eval(supportJSExpression);
    if (support !== true) {
      dartMainRunner(() => {
        throw 'This browser does not support the required features to run the dart2wasm compiled app!';
      });
      return;
    }

    const mjs = await import(mjsPath);
    const compiledApp = await mjs.compileStreaming(fetch(wasmPath));
    window.loadData = async (relativeToWasmFileUri) => {
      const path = '$wasmPath'.slice(0, wasmPath.lastIndexOf('/'));
      const response = await fetch(`\${path}/\${relativeToWasmFileUri}`);
      return response.arrayBuffer();
    };
    const appInstance = await compiledApp.instantiate({}, {
      loadDeferredModule: fetch
    });
    dartMainRunner(() => {
      appInstance.invokeMain();
    });
  }

  loadAndRun('$mjsPath', '$wasmPath', '$supportJsPath');
  </script>
</body>
</html>""";
}
