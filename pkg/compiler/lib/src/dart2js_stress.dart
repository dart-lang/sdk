// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.stress;
import "dart2js.dart" as dart2js;

const ITERATIONS_FLAG_PREFIX = "--iterations=";
void main(List<String> args) {
  print("Reminder: for best performance, "
        "dart2js should be run with the VM flag --heap_growth_rate=512");
  Stopwatch sw = new Stopwatch();
  int count = 0;
  int maxCount = null;
  if (args.isNotEmpty && args[0].startsWith(ITERATIONS_FLAG_PREFIX)) {
    maxCount = int.parse(args[0].substring(ITERATIONS_FLAG_PREFIX.length));
    args = args.sublist(1);
  }
  if (maxCount == null) {
    print("Running indefinitely.\n"
          "Use '$ITERATIONS_FLAG_PREFIX<count>' to set a repetition count"
          " (as first flag).");
  }
  args = ["--suppress-warnings", "--suppress-hints"]..addAll(args);
  void iterate() {
    count++;
    sw.reset();
    sw.start();
    dart2js.internalMain(args)
      .then((_) {
        print("$count: ${sw.elapsedMilliseconds}ms");
      })
      .then((_) {
        if (maxCount == null || count < maxCount) {
          iterate();
        }
      });
  }
  iterate();
}
