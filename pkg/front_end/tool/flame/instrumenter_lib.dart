// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

Stopwatch stopwatch = new Stopwatch();
List<int> data = [];
bool _doReportCandidates = false;
late List<Sum> _sum;
List<int> _activeStack = [];
List<DelayedReportData> delayedReportData = [];

void initialize(int count, bool reportCandidates) {
  _sum = new List.generate(count, (_) => new Sum(), growable: false);
  stopwatch.start();
  _doReportCandidates = reportCandidates;
}

@pragma("vm:prefer-inline")
void enter(int i) {
  data.add(1); // enter
  data.add(i); // what
  data.add(stopwatch.elapsedTicks); // time
}

@pragma("vm:prefer-inline")
void exit(int i) {
  data.add(0); // exit
  data.add(i); // what
  data.add(stopwatch.elapsedTicks); // time

  if (_doReportCandidates && data.length > 100000000) {
    // We're reporting everything which can use a lot of ram. Try to trim it.
    _trim();
  }
}

void _trim() {
  stopwatch.stop();
  print("Trimming...");
  int factorForMicroSeconds = stopwatch.frequency ~/ 1000000;
  _processData(null, factorForMicroSeconds);
  stopwatch.start();
}

void report(List<String> names) {
  int factorForMicroSeconds = stopwatch.frequency ~/ 1000000;

  File f = new File("cfe_compile_trace.txt");
  RandomAccessFile randomAccessFile = f.openSync(mode: FileMode.writeOnly);
  StringBuffer sb = new StringBuffer();
  sb.write("[");

  WithOutputInfo withOutputInfo =
      new WithOutputInfo(names, sb, randomAccessFile);

  // Report previously delayed data.
  for (DelayedReportData data in delayedReportData) {
    _writeFlameOutputToBuffer(withOutputInfo, data.procedureNumber,
        data.enterMicroseconds, data.duration);
  }

  // Report "new" data.
  _processData(withOutputInfo, factorForMicroSeconds);
  sb.write("\n]");
  randomAccessFile.writeStringSync(sb.toString());
  sb.clear();
  randomAccessFile.closeSync();
  print("Write to $f");

  _reportCandidates(factorForMicroSeconds, names);
}

class WithOutputInfo {
  final List<String> names;
  final StringBuffer sb;
  String separator = "\n";
  final RandomAccessFile randomAccessFile;

  WithOutputInfo(this.names, this.sb, this.randomAccessFile);
}

void _processData(WithOutputInfo? withOutputInfo, int factorForMicroSeconds) {
  for (int i = 0; i < data.length; i += 3) {
    int enterOrExit = data[i];
    int procedureNumber = data[i + 1];
    int ticks = data[i + 2];
    if (enterOrExit == 1) {
      // Enter.
      _activeStack.add(procedureNumber);
      _activeStack.add(ticks);
    } else if (enterOrExit == 0) {
      // Exit
      int enterTicks = _activeStack.removeLast();
      int enterProcedureNumber = _activeStack.removeLast();
      if (enterProcedureNumber != procedureNumber) {
        if (withOutputInfo != null) {
          print("DEBUG: Now exiting "
              "${withOutputInfo.names[procedureNumber]}.");
          print("DEBUG: Latest entering "
              "${withOutputInfo.names[enterProcedureNumber]}.");
        }
        bool foundMatch = false;
        int steps = 1;
        for (int i = _activeStack.length - 2; i >= 0; i -= 2) {
          steps++;
          if (_activeStack[i] == procedureNumber) {
            foundMatch = true;
            break;
          }
        }
        if (foundMatch) {
          _activeStack.add(enterProcedureNumber);
          _activeStack.add(enterTicks);
          enterProcedureNumber =
              _activeStack.removeAt(_activeStack.length - steps * 2);
          enterTicks = _activeStack.removeAt(_activeStack.length - steps * 2);
          assert(enterProcedureNumber != procedureNumber);
        } else {
          throw "Mismatching enter/exit with no matching "
              "enter found for this exit.";
        }
      }

      double enterMicroseconds = enterTicks / factorForMicroSeconds;
      double duration = (ticks - enterTicks) / factorForMicroSeconds;
      _sum[procedureNumber].addTick(ticks - enterTicks);

      // Avoid outputting too much data.
      if (_doReportCandidates) {
        // If collecting all, don't output everything as that will simply be
        // too much data.
        if (duration < 1000) continue;
      }
      if (withOutputInfo != null) {
        _writeFlameOutputToBuffer(
            withOutputInfo, procedureNumber, enterMicroseconds, duration);
      } else {
        // Save for later output.
        delayedReportData.add(new DelayedReportData(
            procedureNumber, enterMicroseconds, duration));
      }
    } else {
      throw "Error: $enterOrExit expected to be 0 or 1.";
    }
    if (withOutputInfo != null && withOutputInfo.sb.length > 1024 * 1024) {
      withOutputInfo.randomAccessFile
          .writeStringSync(withOutputInfo.sb.toString());
      withOutputInfo.sb.clear();
    }
  }
  data.clear();
}

void _writeFlameOutputToBuffer(WithOutputInfo withOutputInfo,
    int procedureNumber, double enterMicroseconds, double duration) {
  withOutputInfo.sb.write(withOutputInfo.separator);
  withOutputInfo.separator = ",\n";
  String name = withOutputInfo.names[procedureNumber];

  String displayName = name.substring(name.indexOf("|") + 1);
  String file = name.substring(0, name.indexOf("|"));
  withOutputInfo.sb
      .write('{"ph": "X", "ts": $enterMicroseconds, "dur": $duration, '
          '"name": "$displayName", "cat": "$file", "pid": 1, "tid": 1}');
}

void _reportCandidates(int factorForMicroSeconds, List<String> names) {
  StringBuffer sb = new StringBuffer();
  StringBuffer sbDebug = new StringBuffer();
  final int leastRuntime = _doReportCandidates ? 500 : 50;
  for (int i = 0; i < _sum.length; i++) {
    Sum sum = _sum[i];
    double averageMicroseconds = sum.average / factorForMicroSeconds;
    if (averageMicroseconds >= leastRuntime) {
      // Average call time is >= 0.5 or 0.05 ms.
      String name = names[i];
      sb.writeln(name);
      sbDebug.writeln(name);
      sbDebug.writeln(" => ${sum.count}, ${sum.totalTicks}, "
          "${sum.average}, $averageMicroseconds");
    }
  }
  if (sb.length > 0) {
    String extra = _doReportCandidates ? "" : "_subsequent";
    File f = new File("cfe_compile_trace_candidates$extra.txt");
    f.writeAsStringSync(sb.toString());
    print("Wrote candidates to $f");
    f = new File("cfe_compile_trace_candidates${extra}_debug.txt");
    f.writeAsStringSync(sbDebug.toString());
    print("Wrote candidates debug data to $f");
  }
}

class Sum {
  int count = 0;
  int totalTicks = 0;
  double get average => totalTicks / count;
  void addTick(int tick) {
    count++;
    totalTicks += tick;
  }
}

class DelayedReportData {
  final int procedureNumber;
  final double enterMicroseconds;
  final double duration;

  DelayedReportData(
      this.procedureNumber, this.enterMicroseconds, this.duration);
}
