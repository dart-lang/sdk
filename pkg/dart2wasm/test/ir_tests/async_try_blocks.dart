// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// printSourcePositions
// functionFilter=testAsyncTryCatch
// tableFilter=NoMatch
// globalFilter=NoMatch
// typeFilter=NoMatch
// compilerOption=-O0

import 'dart:js_interop';

@JS()
external JSAny? get someJsError;

Future<void> testAsyncTryCatch() async {
  try {
    print("try");
    throw "dart error";
  } catch (e) {
    print("caught $e");
  } finally {
    print("finally");
  }
}

Future<void> testAsyncTryCatchJs() async {
  try {
    print("try js");
    // In a real test we'd trigger a JS error, but for IR testing we just want
    // to see the catch block structure.
  } on JSAny catch (e) {
    print("caught js $e");
  }
}

void main() async {
  await testAsyncTryCatch();
  await testAsyncTryCatchJs();
}
