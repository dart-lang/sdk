// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

Stopwatch stopwatch = new Stopwatch();

List<int> data = [];

void initialize(int count) {
  stopwatch.start();
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
}

void report(List<String> names, bool reportCandidates) {
  Map<String, Sum>? sum = {};
  int factorForMicroSeconds = stopwatch.frequency ~/ 1000000;

  File f = new File("cfe_compile_trace.txt");
  RandomAccessFile randomAccessFile = f.openSync(mode: FileMode.writeOnly);
  StringBuffer sb = new StringBuffer();
  sb.write("[");
  List<int> activeStack = [];
  String separator = "\n";
  for (int i = 0; i < data.length; i += 3) {
    int enterOrExit = data[i];
    int procedureNumber = data[i + 1];
    int ticks = data[i + 2];
    if (enterOrExit == 1) {
      // Enter.
      activeStack.add(procedureNumber);
      activeStack.add(ticks);
    } else if (enterOrExit == 0) {
      // Exit
      int enterTicks = activeStack.removeLast();
      int enterProcedureNumber = activeStack.removeLast();
      if (enterProcedureNumber != procedureNumber) {
        print("DEBUG: Now exiting ${names[procedureNumber]}.");
        print("DEBUG: Latest entering ${names[enterProcedureNumber]}.");
        bool foundMatch = false;
        int steps = 1;
        for (int i = activeStack.length - 2; i >= 0; i -= 2) {
          steps++;
          if (activeStack[i] == procedureNumber) {
            foundMatch = true;
            break;
          }
        }
        if (foundMatch) {
          activeStack.add(enterProcedureNumber);
          activeStack.add(enterTicks);
          enterProcedureNumber =
              activeStack.removeAt(activeStack.length - steps * 2);
          enterTicks = activeStack.removeAt(activeStack.length - steps * 2);
          assert(enterProcedureNumber != procedureNumber);
        } else {
          throw "Mismatching enter/exit with no matching "
              "enter found for this exit.";
        }
      }

      double enterMicroseconds = enterTicks / factorForMicroSeconds;
      String name = names[procedureNumber];
      double duration = (ticks - enterTicks) / factorForMicroSeconds;
      Sum s = sum[name] ??= new Sum();
      s.addTick(ticks - enterTicks);

      // Avoid outputting too much data.
      if (reportCandidates) {
        // If collecting all, don't output everything as that will simply be
        // too much data.
        if (duration < 1000) continue;
      }
      sb.write(separator);
      separator = ",\n";

      String displayName = name.substring(name.indexOf("|") + 1);
      String file = name.substring(0, name.indexOf("|"));
      sb.write('{"ph": "X", "ts": $enterMicroseconds, "dur": $duration, '
          '"name": "$displayName", "cat": "$file", "pid": 1, "tid": 1}');
    } else {
      throw "Error: $enterOrExit expected to be 0 or 1.";
    }
    if (sb.length > 1024 * 1024) {
      randomAccessFile.writeStringSync(sb.toString());
      sb.clear();
    }
  }
  sb.write("\n]");
  randomAccessFile.writeStringSync(sb.toString());
  sb.clear();
  randomAccessFile.closeSync();
  print("Write to $f");

  _reportCandidates(sum, factorForMicroSeconds, reportCandidates);
}

void _reportCandidates(
    Map<String, Sum> sum, int factorForMicroSeconds, bool reportCandidates) {
  StringBuffer sb = new StringBuffer();
  StringBuffer sbDebug = new StringBuffer();
  final int leastRuntime = reportCandidates ? 500 : 50;
  for (MapEntry<String, Sum> entry in sum.entries) {
    double averageMicroseconds = entry.value.average / factorForMicroSeconds;
    if (averageMicroseconds >= leastRuntime) {
      // Average call time is >= 0.5 or 0.05 ms.
      sb.writeln(entry.key);
      sbDebug.writeln(entry.key);
      sbDebug.writeln(" => ${entry.value.count}, ${entry.value.totalTicks}, "
          "${entry.value.average}, $averageMicroseconds");
    }
  }
  if (sb.length > 0) {
    String extra = reportCandidates ? "" : "_subsequent";
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
