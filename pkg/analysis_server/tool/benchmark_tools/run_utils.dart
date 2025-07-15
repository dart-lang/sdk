// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'language_server_benchmark.dart';

String formatDuration(Duration duration) {
  int seconds = duration.inSeconds;
  int ms = duration.inMicroseconds - seconds * Duration.microsecondsPerSecond;
  return '$seconds.${ms.toString().padLeft(6, '0')}';
}

String formatKb(int kb) {
  if (kb > 1024) {
    return '${kb ~/ 1024} MB';
  } else {
    return '$kb KB';
  }
}

Future<void> runHelper<E, F, G>(
  List<String> args,
  DartLanguageServerBenchmark Function(
    List<String> args,
    Uri rootUri,
    Uri cacheFolder,
    E runDetails,
  )
  benchmarkCreator,
  E Function(
    Uri packageDirUri,
    Uri outerDirForAdditionalData,
    int size,
    F? extraIterationData,
    List<String> args, {
    required G? extraInformation,
  })
  createDataAndCreateRunDetails, {
  required bool runAsLsp,
  List<int> sizeOptions = const [16, 32, 64, 128, 256, 512, 1024],
  required List<F?> Function(List<String> args) extraIterations,
  G? extraInformation,
}) async {
  int verbosity = 0;
  bool jsonOutput = false;
  for (String arg in args) {
    if (arg.startsWith('--sizes=')) {
      sizeOptions =
          arg.substring('--sizes='.length).split(',').map(int.parse).toList();
    } else if (arg.startsWith('--verbosity=')) {
      verbosity = int.parse(arg.substring('--verbosity='.length));
    } else if (arg == '--json') {
      jsonOutput = true;
    }
  }
  if (jsonOutput) {
    verbosity = -1;
  }
  StringBuffer sb = StringBuffer();
  Map<String, int> jsonData = {};
  for (F? extraIteration in extraIterations(args)) {
    for (int size in sizeOptions) {
      var caption = 'size $size / $extraIteration';
      if (extraIteration == null) {
        caption = 'size $size';
      }
      try {
        Directory tmpDir = Directory.systemTemp.createTempSync(
          'analysisServer_benchmark',
        );
        try {
          Directory cacheDir = Directory.fromUri(tmpDir.uri.resolve('cache/'))
            ..createSync(recursive: true);
          Directory dartDir = Directory.fromUri(tmpDir.uri.resolve('dart/'))
            ..createSync(recursive: true);
          var runDetails = createDataAndCreateRunDetails(
            dartDir.uri,
            tmpDir.uri,
            size,
            extraIteration,
            args,
            extraInformation: extraInformation,
          );
          var benchmark = benchmarkCreator(
            args,
            dartDir.uri,
            cacheDir.uri,
            runDetails,
          );
          try {
            benchmark.verbosity = verbosity;
            await benchmark.run();
          } finally {
            benchmark.exit();
          }

          if (jsonOutput) {
            for (var durationInfo in benchmark.durationInfo) {
              var key = '$caption: ${durationInfo.name} (ms)';
              if (jsonData.containsKey(key)) {
                throw 'Already contains data for $key';
              }
              jsonData[key] = durationInfo.duration.inMilliseconds;
            }
            for (var memoryInfo in benchmark.memoryInfo) {
              jsonData['$caption: ${memoryInfo.name} (kb)'] = memoryInfo.kb;
            }
          } else {
            if (verbosity >= 0) print('====================');
            if (verbosity >= 0) print('$caption:');
            sb.writeln('$caption:');
            for (var durationInfo in benchmark.durationInfo) {
              if (verbosity >= 0) {
                print(
                  '${durationInfo.name}: '
                  '${formatDuration(durationInfo.duration)}',
                );
              }
              sb.writeln(
                '${durationInfo.name}: '
                '${formatDuration(durationInfo.duration)}',
              );
            }
            for (var memoryInfo in benchmark.memoryInfo) {
              if (verbosity >= 0) {
                print(
                  '${memoryInfo.name}: '
                  '${formatKb(memoryInfo.kb)}',
                );
              }
              sb.writeln(
                '${memoryInfo.name}: '
                '${formatKb(memoryInfo.kb)}',
              );
            }
            if (verbosity >= 0) print('====================');
            sb.writeln();
          }
        } finally {
          try {
            tmpDir.deleteSync(recursive: true);
          } catch (e) {
            // Wait a little and retry.
            sleep(const Duration(milliseconds: 42));
            try {
              tmpDir.deleteSync(recursive: true);
            } catch (e) {
              if (verbosity >= 0) print('Warning: $e');
            }
          }
        }
      } catch (e) {
        stderr.writeln('Error while processing $caption: $e');
      }
    }
  }

  if (jsonOutput) {
    print(json.encode(jsonData));
  } else {
    print('==================================');
    print(sb.toString().trim());
    print('==================================');
  }
}
