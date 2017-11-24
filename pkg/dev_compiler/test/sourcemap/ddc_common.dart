// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sourcemap_testing/src/annotated_code_helper.dart';
import 'package:sourcemap_testing/src/stacktrace_helper.dart';
import 'package:testing/testing.dart';

import 'common.dart';

abstract class DdcRunner {
  ProcessResult runDDC(String ddcDir, String inputFile, String outputFile,
      String outWrapperPath);
}

class Compile extends Step<Data, Data, ChainContext> {
  final DdcRunner ddcRunner;

  const Compile(this.ddcRunner);

  String get name => "compile";

  Future<Result<Data>> run(Data data, ChainContext context) async {
    var dartScriptAbsolute = new File.fromUri(data.uri).absolute;
    var inputFile = dartScriptAbsolute.path;

    data.outDir = await Directory.systemTemp.createTemp("ddc_step_test");
    data.code = new AnnotatedCode.fromText(
        new File(inputFile).readAsStringSync(), commentStart, commentEnd);
    var testFile = "${data.outDir.path}/test.dart";
    new File(testFile).writeAsStringSync(data.code.sourceCode);
    var outputPath = data.outDir.path;
    var outputFilename = "js.js";
    var outputFile = path.join(outputPath, outputFilename);
    var outWrapperPath = path.join(outputPath, "wrapper.js");

    ddcRunner.runDDC(getDdcDir().path, testFile, outputFile, outWrapperPath);

    return pass(data);
  }
}

class TestStackTrace extends Step<Data, Data, ChainContext> {
  final DdcRunner ddcRunner;
  final String marker;

  const TestStackTrace(this.ddcRunner, this.marker);

  String get name => "TestStackTrace";

  Future<Result<Data>> run(Data data, ChainContext context) async {
    data.outDir = await Directory.systemTemp.createTemp("stacktrace-test");
    String code = await new File.fromUri(data.uri).readAsString();
    Test test = processTestCode(code, [marker]);
    await testStackTrace(test, marker, _compile,
        jsPreambles: _getPreambles,
        useJsMethodNamesOnAbsence: true,
        jsNameConverter: _convertName,
        forcedTmpDir: data.outDir);
    return pass(data);
  }

  Future<bool> _compile(String input, String output) async {
    var outWrapperPath = _getWrapperPathFromDirectoryFile(input);
    ddcRunner.runDDC(getDdcDir().path, input, output, outWrapperPath);
    return true;
  }

  List<String> _getPreambles(input, output) {
    return ['--module', _getWrapperPathFromDirectoryFile(input), '--'];
  }

  String _getWrapperPathFromDirectoryFile(input) {
    return new File.fromUri(new File(input).uri.resolve("wrapper.js")).path;
  }

  String _convertName(String name) {
    if (name == null) return null;
    // Hack for DDC naming scheme.
    String result = name;
    if (result.startsWith("Object.")) result = result.substring(7);
    String inputName =
        INPUT_FILE_NAME.substring(0, INPUT_FILE_NAME.indexOf(".") + 1);
    if (result.startsWith(inputName))
      result = result.substring(inputName.length);
    return result;
  }
}

Directory _cachedDdcDir;
Directory getDdcDir() {
  Directory search() {
    Directory dir = new File.fromUri(Platform.script).parent;
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

String getWrapperContent(Uri jsSdkPath, String inputFileName, Uri outputFile) {
  assert(!jsSdkPath.isAbsolute);
  assert(!outputFile.isAbsolute);
  return """
    import { dart, _isolate_helper } from '$jsSdkPath';
    import { $inputFileName } from '$outputFile';
    let main = $inputFileName.main;
    dart.ignoreWhitelistedErrors(false);
    try {
      _isolate_helper.startRootIsolate(main, []);
    } catch(e) {
      console.error(e.toString(), dart.stackTrace(e).toString());
    }
    """;
}

void createHtmlWrapper(String ddcDir, File sdkJsFile, String outputFile,
    String jsContent, Uri outFileRelative, String outDir) {
  // For debugging via HTML, Chrome and ./tools/testing/dart/http_server.dart.
  String sdkPath = new File(ddcDir).parent.parent.path;
  String jsRootDart =
      "/root_dart/${new File(path.relative(sdkJsFile.path, from: sdkPath))
      .uri}";
  new File(outputFile + ".html.js").writeAsStringSync(
      jsContent.replaceFirst("from 'dart_sdk'", "from '$jsRootDart'"));
  new File(outputFile + ".html.html").writeAsStringSync(getWrapperHtmlContent(
      jsRootDart, "/root_build/$outFileRelative.html.js"));

  print("You should now be able to run\n\n"
      "dart $sdkPath/tools/testing/dart/http_server.dart -p 39550 "
      "--build-directory=$outDir"
      "\n\nand go to\n\n"
      "http://localhost:39550/root_build/$outFileRelative.html.html"
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
    dart.ignoreWhitelistedErrors(false);
    _isolate_helper.startRootIsolate(() => {}, []);
    main();
    </script>
  </head>
  <body>
    <h1>ddc test</h1>
  </body>
</html>
""";
}
