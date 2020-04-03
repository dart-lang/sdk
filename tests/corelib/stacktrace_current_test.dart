// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert" show LineSplitter;

import "package:expect/expect.dart";

void main() {
  var st0;
  var st1;
  // Primitive way to get stack trace,.
  try {
    throw 0;
  } catch (_, s) {
    st0 = s;
  }
  st1 = StackTrace.current;

  var st0s = findMain(st0);
  var st1s = findMain(st1);
  // Stack traces are not equal (contains at least a different line number,
  // and possible different frame numbers).
  // They are *similar*, so check that they agree on everything but numbers.
  var digits = new RegExp(r"\d+");
  Expect.equals(st0s.replaceAll(digits, "0"), st1s.replaceAll(digits, "0"));
}

String findMain(StackTrace stack) {
  var string = "$stack";
  var lines = LineSplitter.split(string).toList();
  while (lines.isNotEmpty && !lines.first.contains("main")) {
    lines.removeAt(0);
  }
  return lines.join("\n");
}
