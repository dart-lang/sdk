// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'standard_deviation.dart';

const String bRootPath = const String.fromEnvironment("bRoot");
const int abIterations =
    const int.fromEnvironment("abIterations", defaultValue: 15);
const int iterations =
    const int.fromEnvironment("iterations", defaultValue: 15);

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
  String relPath = 'pkg/front_end/tool/_fasta/compile.dart';
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

  var stopwatch = new Stopwatch()..start();
  for (int count = 0; count < abIterations; ++count) {
    print('A/B iteration ${count + 1} of $abIterations ...');
    await run(aRoot, aCompile, args, aCold, aWarm);
    await run(bRoot, bCompile, args, bCold, bWarm);
  }
  stopwatch.stop();
  print('Overall run time: ${stopwatch.elapsed.inMinutes} minutes');

  print('');
  print('Raw data:');
  print('A cold, A warm, B cold, B warm');
  for (int index = 0; index < aCold.length; ++index) {
    print('${aCold[index]}, ${aWarm[index]}, ${bCold[index]}, ${bWarm[index]}');
  }

  if (aWarm.length < 1) {
    return;
  }

  double aColdMean = average(aCold);
  double aWarmMean = average(aWarm);
  double bColdMean = average(bCold);
  double bWarmMean = average(bWarm);

  print('');
  print('Average:');
  print('$aColdMean, $aWarmMean, $bColdMean, $bWarmMean');

  if (aWarm.length < 2) {
    return;
  }

  double aColdStdDev = standardDeviation(aColdMean, aCold);
  double aWarmStdDev = standardDeviation(aWarmMean, aWarm);
  double bColdStdDev = standardDeviation(bColdMean, bCold);
  double bWarmStdDev = standardDeviation(bWarmMean, bWarm);

  double aColdSDM = standardDeviationOfTheMean(aCold, aColdStdDev);
  double aWarmSDM = standardDeviationOfTheMean(aWarm, aWarmStdDev);
  double bColdSDM = standardDeviationOfTheMean(bCold, bColdStdDev);
  double bWarmSDM = standardDeviationOfTheMean(bWarm, bWarmStdDev);

  print('');
  print('Uncertainty:');
  print('$aColdSDM, $aWarmSDM, $bColdSDM, $bWarmSDM');

  double coldDelta = aColdMean - bColdMean;
  double coldUncertainty = sqrt(pow(aColdSDM, 2) + pow(bColdSDM, 2));
  double warmDelta = aWarmMean - bWarmMean;
  double warmUncertainty = sqrt(pow(aWarmSDM, 2) + pow(bWarmSDM, 2));

  double coldDeltaPercent = (coldDelta / bColdMean * 1000).round() / 10;
  double coldUncertaintyPercent =
      (coldUncertainty / bColdMean * 1000).round() / 10;
  double warmDeltaPercent = (warmDelta / bWarmMean * 1000).round() / 10;
  double warmUncertaintyPercent =
      (warmUncertainty / bWarmMean * 1000).round() / 10;

  double coldBest = coldDelta - 3 * coldUncertainty;
  double coldBestPercent = coldDeltaPercent - 3 * coldUncertaintyPercent;
  double coldWorst = coldDelta + 3 * coldUncertainty;
  double coldWorstPercent = coldDeltaPercent + 3 * coldUncertaintyPercent;

  double warmBest = warmDelta - 3 * warmUncertainty;
  double warmBestPercent = warmDeltaPercent - 3 * warmUncertaintyPercent;
  double warmWorst = warmDelta + 3 * warmUncertainty;
  double warmWorstPercent = warmDeltaPercent + 3 * warmUncertaintyPercent;

  print('');
  print('Summary:');
  print('$coldDelta, $coldDeltaPercent%, A cold start - B cold start');
  print('$coldUncertainty, $coldUncertaintyPercent%, Propagated uncertainty');
  print('$coldBest, $coldBestPercent%, 99.9% best case');
  print('$coldWorst, $coldWorstPercent%, 99.9% worst case');
  print('');
  print('$warmDelta, $warmDeltaPercent%, A warm runs - B warm runs');
  print('$warmUncertainty, $warmUncertaintyPercent%, Propagated uncertainty');
  print('$warmBest, $warmBestPercent%, 99.9% best case');
  print('$warmWorst, $warmWorstPercent%, 99.9% worst case');
}

const String _iterationTag = '=== Iteration ';
const String _summaryTag = 'Summary: {"';

/// Launch the specified dart program, forwarding all arguments and environment
/// that was passed to this program
Future<Null> run(Uri workingDir, Uri dartApp, List<String> args,
    List<double> cold, List<double> warm) async {
  print('Running $dartApp');

  void processLine(String line) {
    if (line.startsWith(_iterationTag)) {
      // Show progress
      stdout
        ..write('.')
        ..flush();
      return;
    }
    if (line.startsWith(_summaryTag)) {
      String json = line.substring(_summaryTag.length - 2);
      Map<String, dynamic> results = jsonDecode(json);
      List<double> elapsedTimes = results['elapsedTimes'];
      print('\nElapse times: $elapsedTimes');
      if (elapsedTimes.length > 0) {
        cold.add(elapsedTimes[0]);
      }
      if (elapsedTimes.length > 4) {
        // Drop the first 3 and average the remaining
        warm.add(average(elapsedTimes.sublist(3)));
      }
      return;
    }
  }

  String workingDirPath = workingDir.toFilePath();
  List<String> procArgs = <String>[
    '-Diterations=$iterations',
    '-Dsummary=true',
    dartApp.toFilePath()
  ];
  procArgs.addAll(args);

  Process process = await Process.start(Platform.executable, procArgs,
      workingDirectory: workingDirPath);
  stderr.addStream(process.stderr);
  StreamSubscription<String> stdOutSubscription;
  stdOutSubscription = process.stdout
      .transform(utf8.decoder)
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
