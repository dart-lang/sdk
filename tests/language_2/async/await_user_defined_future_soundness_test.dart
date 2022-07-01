// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Verifies that user-define Future cannot provide a value of incorrect
// type by casting 'onValue' callback.
// Regression test for https://github.com/dart-lang/sdk/issues/49345.

import 'dart:async';

import "package:expect/expect.dart";

import 'dart:async';

bool checkpoint1 = false;
bool checkpoint2 = false;
bool checkpoint3 = false;
bool checkpoint4 = false;

Future<void> foo(Future<String> f) async {
  checkpoint1 = true;
  final String result = await f;
  checkpoint3 = true;
  print(result.runtimeType);
}

class F implements Future<String> {
  Future<R> then<R>(FutureOr<R> Function(String) onValue, {Function onError}) {
    checkpoint2 = true;
    final result = (onValue as FutureOr<R> Function(dynamic))(10);
    checkpoint4 = true;
    return Future.value(result);
  }

  @override
  dynamic noSuchMethod(i) => throw 'Unimplimented';
}

void main() {
  bool seenError = false;
  runZoned(() {
    foo(F());
  }, onError: (e, st) {
    seenError = true;
  });
  Expect.isTrue(checkpoint1);
  Expect.isTrue(checkpoint2);
  Expect.isFalse(checkpoint3);
  Expect.isFalse(checkpoint4);
  Expect.isTrue(seenError);
}
