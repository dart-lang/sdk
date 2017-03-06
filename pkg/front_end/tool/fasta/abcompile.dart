import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'standard_deviation.dart';

const String bRootPath = const String.fromEnvironment("bRoot");
const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

/// Compare the performance of two different fast implementations
/// by alternately launching the compile application in this directory
/// and the compile application location in the repo specified by "bRoot"
/// via -DbRoot=/absolute/path/to/other/sdk/repo
main(List<String> args) async {
  print(args);
  if (bRootPath == null) {
    print('Expected -DbRoot=/absolute/path/to/other/sdk/repo');
    exit(1);
  }

  // The root of this Dart SDK repo "A"
  Uri aRoot = Platform.script.resolve('../../../..');

  // The root of the other Dart SDK repo "B"
  Uri bRoot = new Uri.directory(bRootPath);

  // Sanity check
  String relPath = 'pkg/front_end/tool/fasta/compile.dart';
  Uri aCompile = aRoot.resolve(relPath);
  if (!new File(aCompile.toFilePath()).existsSync()) {
    print('Failed to find $aCompile');
    exit(1);
  }
  Uri bCompile = bRoot.resolve(relPath);
  if (!new File(bCompile.toFilePath()).existsSync()) {
    print('Failed to find $bCompile');
    exit(1);
  }

  print('Comparing:');
  print('A: $aCompile');
  print('B: $bCompile');
  print('');

  List<double> aCold = <double>[];
  List<double> aWarm = <double>[];
  List<double> bCold = <double>[];
  List<double> bWarm = <double>[];
  for (int count = 0; count < 15; ++count) {
    await run(aRoot, aCompile, args, aCold, aWarm);
    await run(bRoot, bCompile, args, bCold, bWarm);
  }

  print('');
  print('Raw data:');
  print('A cold, A warm, B cold, B warm');
  for (int index = 0; index < aCold.length; ++index) {
    print('${aCold[index]}, ${aWarm[index]}, ${bCold[index]}, ${bWarm[index]}');
  }

  double aColdMean = average(aCold);
  double aWarmMean = average(aWarm);
  double bColdMean = average(bCold);
  double bWarmMean = average(bWarm);

  print('');
  print('Average:');
  print('$aColdMean, $aWarmMean, $bColdMean, $bWarmMean');

  double aColdStdDev = standardDeviation(aColdMean, aCold);
  double aWarmStdDev = standardDeviation(aWarmMean, aWarm);
  double bColdStdDev = standardDeviation(bColdMean, bCold);
  double bWarmStdDev = standardDeviation(bWarmMean, bWarm);

  double aColdStdDevMean = standardDeviationOfTheMean(aCold, aColdStdDev);
  double aWarmStdDevMean = standardDeviationOfTheMean(aWarm, aWarmStdDev);
  double bColdStdDevMean = standardDeviationOfTheMean(bCold, bColdStdDev);
  double bWarmStdDevMean = standardDeviationOfTheMean(bWarm, bWarmStdDev);

  print('');
  print('Uncertainty:');
  print(
      '$aColdStdDevMean, $aWarmStdDevMean, $bColdStdDevMean, $bWarmStdDevMean');

  double coldDelta = aColdMean - bColdMean;
  double coldStdDevMean =
      sqrt(pow(aColdStdDevMean, 2) + pow(bColdStdDevMean, 2));
  double warmDelta = aWarmMean - bWarmMean;
  double warmStdDevMean =
      sqrt(pow(aWarmStdDevMean, 2) + pow(bWarmStdDevMean, 2));

  print('');
  print('Summary:');
  print('  A cold start - B cold start : $coldDelta');
  print('  Uncertainty                 : $coldStdDevMean');
  print('');
  print('  A warm runs - B warm runs   : $warmDelta');
  print('  Uncertainty                 : $warmStdDevMean');
}

const String _wroteProgram = 'Wrote program to';
const String _coldStart = 'Cold start (first run):';
const String _warmRun = 'Warm run average (runs #4';

/// Launch the specified dart program, forwarding all arguments and environment
/// that was passed to this program
Future<Null> run(Uri workingDir, Uri dartApp, List<String> args,
    List<double> cold, List<double> warm) async {
  print('Running $dartApp');

  void processLine(String line) {
    if (line.contains(_wroteProgram)) {
      // Show progress
      stdout
        ..write('.')
        ..flush();
      return;
    }
    int index = line.indexOf(_coldStart);
    if (index >= 0) {
      cold.add(double.parse(line.substring(index + _coldStart.length)));
      print('\ncold: ${cold.last}');
      return;
    }
    index = line.indexOf(_warmRun);
    if (index >= 0) {
      index = line.indexOf(':', index + _warmRun.length);
      warm.add(double.parse(line.substring(index + 1)));
      print('warm: ${warm.last}');
      return;
    }
  }

  String workingDirPath = workingDir.toFilePath();
  List<String> procArgs = <String>[
    '-Diterations=$iterations',
    dartApp.toFilePath()
  ];
  procArgs.addAll(args);

  Process process = await Process.start(Platform.executable, procArgs,
      workingDirectory: workingDirPath);
  stderr.addStream(process.stderr);
  StreamSubscription<String> stdOutSubscription;
  stdOutSubscription = process.stdout
      .transform(UTF8.decoder)
      .transform(new LineSplitter())
      .listen(processLine, onDone: () {
    stdOutSubscription.cancel();
  }, onError: (e) {
    print('Error: $e');
    stdOutSubscription.cancel();
  });
  int code = await process.exitCode;
  if (code != 0) {
    throw 'fail: $code';
  }
  print('');
}
