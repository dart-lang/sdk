// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.test.sourcemap.ddc_common;

import 'dart:io';
import 'dart:mirrors' show currentMirrorSystem;

import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:front_end/src/testing/annotated_code_helper.dart';
import 'package:path/path.dart' as p;
import 'package:sourcemap_testing/src/stacktrace_helper.dart';
import 'package:sourcemap_testing/src/stepping_helper.dart';
import 'package:testing/testing.dart';

import 'common.dart';

abstract class CompilerRunner {
  Future<Null> run(Uri inputFile, Uri outputFile, Uri outWrapperPath);
}

abstract class WithCompilerState {
  fe.InitializedCompilerState compilerState;
}

class Compile extends Step<Data, Data, ChainContext> {
  final CompilerRunner runner;

  const Compile(this.runner);

  @override
  String get name => "compile";

  @override
  Future<Result<Data>> run(Data data, ChainContext context) async {
    var dartScriptAbsolute = File.fromUri(data.uri).absolute;
    var inputFile = dartScriptAbsolute.path;

    data.outDir = await Directory.systemTemp.createTemp("ddc_step_test");
    data.code = AnnotatedCode.fromText(
        File(inputFile).readAsStringSync(), commentStart, commentEnd);
    var outDirUri = data.outDir.uri;
    var testFile = outDirUri.resolve("test.dart");
    File.fromUri(testFile).writeAsStringSync(data.code.sourceCode);
    var outputFilename = "js.js";
    var outputFile = outDirUri.resolve(outputFilename);
    var outWrapperPath = outDirUri.resolve("wrapper.js");

    await runner.run(testFile, outputFile, outWrapperPath);

    return pass(data);
  }
}

class TestStackTrace extends Step<Data, Data, ChainContext> {
  final CompilerRunner runner;
  final String marker;
  final List<String> knownMarkers;

  const TestStackTrace(this.runner, this.marker, this.knownMarkers);

  @override
  String get name => "TestStackTrace";

  @override
  Future<Result<Data>> run(Data data, ChainContext context) async {
    data.outDir = await Directory.systemTemp.createTemp("stacktrace-test");
    String code = await File.fromUri(data.uri).readAsString();
    Test test = processTestCode(code, knownMarkers);
    await testStackTrace(test, marker, _compile,
        jsPreambles: _getPreambles,
        useJsMethodNamesOnAbsence: true,
        jsNameConverter: _convertName,
        forcedTmpDir: data.outDir,
        verbose: true);
    return pass(data);
  }

  Future<bool> _compile(String input, String output) async {
    var outWrapperPath = _getWrapperPathFromDirectoryFile(Uri.file(input));
    await runner.run(Uri.file(input), Uri.file(output), outWrapperPath);
    return true;
  }

  List<String> _getPreambles(String input, String output) {
    return [
      '--module',
      _getWrapperPathFromDirectoryFile(Uri.file(input)).toFilePath(),
      '--'
    ];
  }

  Uri _getWrapperPathFromDirectoryFile(Uri input) {
    return input.resolve("wrapper.js");
  }

  String _convertName(String name) {
    if (name == null) return null;
    // Hack for DDC naming scheme.
    String result = name;
    if (result.startsWith("new ")) result = result.substring(4);
    if (result.startsWith("Object.")) result = result.substring(7);
    String inputName =
        INPUT_FILE_NAME.substring(0, INPUT_FILE_NAME.indexOf(".") + 1);
    if (result.startsWith(inputName)) {
      result = result.substring(inputName.length);
    }
    return result;
  }
}

Directory _cachedDdcDir;
Directory getDdcDir() {
  Directory search() {
    Directory dir = File.fromUri(Platform.script).parent;
    Uri dirUrl = dir.uri;
    if (dirUrl.pathSegments.contains("dev_compiler")) {
      for (int i = dirUrl.pathSegments.length - 2; i >= 0; --i) {
        // Directory uri ends in empty string
        if (dirUrl.pathSegments[i] == "dev_compiler") break;
        dir = dir.parent;
      }
      return dir;
    }
    throw "Cannot find DDC directory.";
  }

  return _cachedDdcDir ??= search();
}

String getWrapperContent(
    Uri jsSdkPath, String inputFileNameNoExt, String outputFilename) {
  assert(jsSdkPath.isAbsolute);
  return """
    import { dart, _isolate_helper } from '${uriPathForwardSlashed(jsSdkPath)}';
    import { $inputFileNameNoExt } from '$outputFilename';

    let global = new Function('return this;')();
    $d8Preambles

    // d8 does not seem to print the `.stack` property like
    // node.js and browsers do, so include that.
    Error.prototype.toString = function() {
      // Note: on d8, the stack property includes the error message too.
      return this.stack;
    };

    global.scheduleImmediate = function(callback) {
      // Ensure unhandled promise rejections get printed.
      Promise.resolve(null).then(callback).catch(e => console.error(e));
    };

    let main = $inputFileNameNoExt.main;
    try {
      dartMainRunner(main, []);
    } catch(e) {
      console.error(e);
    }
    """;
}

void createHtmlWrapper(File sdkJsFile, Uri outputFile, String jsContent,
    String outputFilename, Uri outDir) {
  // For debugging via HTML, Chrome and ./pkg/test_runner/bin/http_server.dart.
  var sdkFile = File(p.relative(sdkJsFile.path, from: sdkRoot.path));
  String jsRootDart = "/root_dart/${sdkFile.uri}";
  File.fromUri(outputFile.resolve("$outputFilename.html.js")).writeAsStringSync(
      jsContent.replaceFirst("from 'dart_sdk.js'", "from '$jsRootDart'"));
  File.fromUri(outputFile.resolve("$outputFilename.html.html"))
      .writeAsStringSync(getWrapperHtmlContent(
          jsRootDart, "/root_build/$outputFilename.html.js"));

  print("You should now be able to run\n\n"
      "dart ${sdkRoot.path}/pkg/test_runner/bin/http_server.dart -p 39550 "
      "--network 127.0.0.1 "
      "--build-directory=${outDir.toFilePath()}"
      "\n\nand go to\n\n"
      "http://127.0.0.1:39550/root_build/$outputFilename.html.html"
      "\n\nto step through via the browser.");
}

String getWrapperHtmlContent(String jsRootDart, String outFileRootBuild) {
  return """
<!DOCTYPE html>
<html>
  <head>
    <title>ddc test</title>
    <script type="module">
    import { dart, _isolate_helper } from '$jsRootDart';
    import { test } from '$outFileRootBuild';
    let main = test.main;
    main();
    </script>
  </head>
  <body>
    <h1>ddc test</h1>
  </body>
</html>
""";
}

Uri selfUri = currentMirrorSystem()
    .findLibrary(#dev_compiler.test.sourcemap.ddc_common)
    .uri;
String d8Preambles = File.fromUri(selfUri.resolve(
        '../../../../sdk/lib/_internal/js_dev_runtime/private/preambles/d8.js'))
    .readAsStringSync();
