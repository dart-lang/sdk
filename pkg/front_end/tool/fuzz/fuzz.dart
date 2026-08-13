// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Directory, File, sleep, stdin;

import '../../test/utils/io_utils.dart' show computeRepoDirUri;

import 'analyzer_helper.dart';
import 'compile_helper.dart';
import "gReader.dart" as gReader;
import 'stacktrace_utils.dart';

final Uri repoDir = computeRepoDirUri();
int _worldNum = 0;
int _cfeCrashes = 0;
int _analyzerCrashes = 0;
Stopwatch _stopwatch = new Stopwatch();
Stopwatch _createStopwatch = new Stopwatch();
Stopwatch _cfeStopwatch = new Stopwatch();
Stopwatch _analyzerStopwatch = new Stopwatch();

Future<void> main() async {
  _setupStdin();
  try {
    _stopwatch.start();
    Helper helper = new Helper();
    await helper.setup();
    AnalyzerHelper analyzerHelper = new AnalyzerHelper();
    Directory root = Directory.systemTemp.createTempSync("fuzzer");
    File analyzerFileHelper = new File.fromUri(
      root.uri.resolve("testfile.dart"),
    );
    analyzerFileHelper.writeAsStringSync("");
    await analyzerHelper.setup(root.uri);
    gReader.initialize(repoDir.resolve("pkg/front_end/tool/fuzz/Dart.g"));
    while (!_quit) {
      _worldNum++;
      if (_worldNum > 100000) break;
      print("----------------");
      print("World #$_worldNum");
      print("----------------");

      _createStopwatch.start();
      String data = gReader.createRandomProgram(includeWhy: false);
      _createStopwatch.stop();

      _cfeStopwatch.start();
      (Object, StackTrace)? result = await helper.compile(data);
      _cfeStopwatch.stop();
      if (result != null) {
        _cfeCrashes++;
        var (Object e, StackTrace st) = result;
        String category = categorize(st);
        Directory d = new Directory.fromUri(
          repoDir.resolve("fuzzDumps/$category/"),
        );
        d.createSync(recursive: true);
        File f = new File.fromUri(
          repoDir.resolve("fuzzDumps/$category/$_worldNum.input"),
        );
        f.writeAsStringSync(data);
        print("Crashed on input. Input dumped into $f");
      }

      _analyzerStopwatch.start();
      (Object, StackTrace)? resultAnalyzer = await compileWithAnalyzer(
        analyzerHelper,
        data,
        analyzerFileHelper.uri,
        _worldNum,
      );
      _analyzerStopwatch.stop();
      if (resultAnalyzer != null) {
        _analyzerCrashes++;
        var (Object e, StackTrace st) = resultAnalyzer;
        String category = categorize(st);
        Directory d = new Directory.fromUri(
          repoDir.resolve("fuzzDumps/$category/"),
        );
        d.createSync(recursive: true);
        File f = new File.fromUri(
          repoDir.resolve("fuzzDumps/$category/$_worldNum.analyzerinput"),
        );
        f.writeAsStringSync(data);
        print("Analyzer crashed on input. Input dumped into $f");

        analyzerHelper = new AnalyzerHelper();
        await analyzerHelper.setup(root.uri);
      }
    }
    print("Done.");
    analyzerHelper.shutdown();
    printInfo(false);
  } finally {
    await _resetStdin();
  }
}

void printInfo(bool addSleep) {
  int countWorlds = _worldNum - 1;
  print("Processed $countWorlds random programs in ${_stopwatch.elapsed}.");
  if (countWorlds > 0) {
    print(
      "CFE crashes: $_cfeCrashes "
      "(${((_cfeCrashes * 100) / countWorlds).toStringAsFixed(2)}%)",
    );
    print(
      "Analyzer crashes: $_analyzerCrashes "
      "(${((_analyzerCrashes * 100) / countWorlds).toStringAsFixed(2)}%)",
    );
  }
  print("Spend ${_createStopwatch.elapsed} creating random programs.");
  print("Spend ${_cfeStopwatch.elapsed} compiling with the CFE.");
  print("Spend ${_analyzerStopwatch.elapsed} compiling with the Analyzer.");
  if (addSleep) sleep(const Duration(seconds: 3));
}

bool? _oldEchoMode;
bool? _oldLineMode;
StreamSubscription<List<int>>? _stdinSubscription;
bool _quit = false;

Future<void> _resetStdin() async {
  try {
    stdin.echoMode = _oldEchoMode!;
  } catch (e) {}
  try {
    stdin.lineMode = _oldLineMode!;
  } catch (e) {}
  await _stdinSubscription!.cancel();
}

void _setupStdin() {
  try {
    _oldEchoMode = stdin.echoMode;
    _oldLineMode = stdin.lineMode;
    stdin.echoMode = false;
    stdin.lineMode = false;
  } catch (e) {
    print(
      "Trying to setup 'stdin' failed. Continuing anyway, "
      "but 'q' and 'i' might not work.",
    );
  }
  _stdinSubscription = stdin.listen((List<int> event) {
    if (event.length == 1 && event.single == "q".codeUnits.single) {
      print("\n\nGot told to quit!\n\n");
      _quit = true;
    } else if (event.length == 1 && event.single == "i".codeUnits.single) {
      printInfo(true);
    } else {
      print("\n\nGot stdin input: $event\n\n");
    }
  });
}
