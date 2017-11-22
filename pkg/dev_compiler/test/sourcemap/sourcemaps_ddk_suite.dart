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
    var outFileRelative = new File(path.relative(outputFile, from: outDir)).uri;

    File sdkJsFile = findInOutDir("gen/utils/dartdevc/js/es6/dart_sdk.js");
    var jsSdkPath = new File(path.relative(sdkJsFile.path, from: outDir)).uri;

    File ddcSdkSummary = findInOutDir("gen/utils/dartdevc/ddc_sdk.dill");

    var ddc = path.join(ddcDir, "bin/dartdevk.dart");
    if (!new File(ddc).existsSync()) throw "Couldn't find 'bin/dartdevk.dart'";

    var args = [
      ddc,
      "--modules=es6",
      "--dart-sdk-summary=${ddcSdkSummary.path}",
      "-o",
      "$outputFile",
      "$inputFile"
    ];
    ProcessResult runResult = Process.runSync(dartExecutable, args);
    if (runResult.exitCode != 0) {
      print(runResult.stderr);
      print(runResult.stdout);
      throw "Exit code: ${runResult.exitCode} from ddc when running "
          "$dartExecutable "
          "${args.reduce((value, element) => '$value "$element"')}";
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
