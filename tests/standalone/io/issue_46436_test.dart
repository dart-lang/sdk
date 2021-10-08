// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Checks that _WindowsCodePageEncoder.convert() throws an exception on
// platforms other than Windows.

import "dart:io";
import 'dart:mirrors';

import "package:expect/expect.dart";

ClassMirror findWindowsCodePageEncoder() {
  final dartIo =
      currentMirrorSystem().libraries[Uri(scheme: "dart", path: "io")];
  if (dartIo == null) {
    throw StateError("dart:io not present");
  }

  final classes = dartIo.declarations.values
      .where((d) =>
          d is ClassMirror &&
          d.simpleName.toString().contains('"_WindowsCodePageEncoder"'))
      .map((d) => d as ClassMirror)
      .toList();

  Expect.equals(
      1, classes.length, "Expected exactly one _WindowsCodePageEncoder");
  return classes[0];
}

test() {
  final winCodePageEncoder = findWindowsCodePageEncoder();
  final encoder = winCodePageEncoder.newInstance(Symbol(""), List.empty());
  try {
    encoder.invoke(Symbol("convert"), List.of(["test"]));
    Expect.isTrue(Platform.isWindows,
        "expected UnsupportedError on ${Platform.operatingSystem}");
  } on UnsupportedError catch (e) {
    Expect.isFalse(
        Platform.isWindows, "unexpected UnsupportedError on Windows: $e");
  }
}

void main() {
  test();
}
