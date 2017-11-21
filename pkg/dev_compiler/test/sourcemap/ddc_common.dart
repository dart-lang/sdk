import 'dart:io';
import 'package:testing/testing.dart';
import 'package:path/path.dart' as path;
import 'annotated_code_helper.dart';
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
      _isolate_helper.startRootIsolate(() => {}, []);
      main();
    } catch(e) {
      console.error(e.toString(), dart.stackTrace(e).toString());
    }
    """;
}
