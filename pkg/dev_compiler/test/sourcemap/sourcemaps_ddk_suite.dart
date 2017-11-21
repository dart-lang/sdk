import 'dart:io';
import 'package:testing/testing.dart';
import 'package:path/path.dart' as path;
import 'common.dart';
import 'ddc_common.dart';

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new SourceMapContext();
}

class SourceMapContext extends ChainContextWithCleanupHelper {
  final List<Step> steps = <Step>[
    const Setup(),
    const Compile(const RunDdc()),
    const StepWithD8(),
    const CheckSteps(),
  ];
}

class RunDdc implements DdcRunner {
  const RunDdc();

  ProcessResult runDDC(String ddcDir, String inputFile, String outputFile,
      String outWrapperPath) {
    var outDir = path.dirname(outWrapperPath);
    var jsSdkPath = new File(path.relative(
            path.join(ddcDir, "lib/js/es6/dart_sdk.js"),
            from: outDir))
        .uri;
    var outFileRelative = new File(path.relative(outputFile, from: outDir)).uri;
    // TODO(jensj): This path will e.g. not work on Mac.
    var ddcSdkSummary = path.join(
        ddcDir, "../../out/ReleaseX64/gen/utils/dartdevc/ddc_sdk.dill");
    var ddc = path.join(ddcDir, "bin/dartdevk.dart");

    ProcessResult runResult = Process.runSync(dartExecutable, [
      ddc,
      "--modules=es6",
      "--dart-sdk-summary=$ddcSdkSummary",
      "-o",
      "$outputFile",
      "$inputFile"
    ]);
    if (runResult.exitCode != 0) {
      print(runResult.stderr);
      print(runResult.stdout);
      throw "Exit code: ${runResult.exitCode} from ddc";
    }

    var jsContent = new File(outputFile).readAsStringSync();
    new File(outputFile).writeAsStringSync(
        jsContent.replaceFirst("from 'dart_sdk'", "from '$jsSdkPath'"));

    var inputFileName = path.basenameWithoutExtension(inputFile);
    new File(outWrapperPath).writeAsStringSync(
        getWrapperContent(jsSdkPath, inputFileName, outFileRelative));

    return runResult;
  }
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
