// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool takeBreak = false;
int iteration = 0;

void maybeThrow() {
  if (iteration == 3) throw 'exception in iteration 3';
}

void inFinally() {}

void code() {
  while (iteration++ < 3) {
    try {
      if (takeBreak) break;
      maybeThrow();
    } finally {
      inFinally(); // LINE_A
    }
  }
}

Future<void> main([List<String> args = const <String>[]]) async {
  try {
    code();
  } catch (_) {}
  print('done'); // LINE_B
}
