// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library malformed_test;

// This part includes the actual tests.
part 'malformed2_lib.dart'; /// 00: static type warning

bool inCheckedMode() {
  try {
    var i = 42;
    String s = i;
  } on TypeError catch (e) {
    return true;
  }
  return false;
}

bool hasFailed = false;

void fail(String message) {
  try {
    throw message;
  } catch (e, s) {
    print(e);
    print(s);
  }
  hasFailed = true;
}

void checkFailures() {
  if (hasFailed) throw 'Test failed.';
}

test(bool expectTypeError, f(), [String message]) {
  message = message != null ? ' for $message' : '';
  try {
    f();
    if (expectTypeError) {
      fail('Missing type error$message.');
    }
  } on TypeError catch (e) {
    if (expectTypeError) {
      print('Type error$message: $e');
    } else {
      fail('Unexpected type error$message: $e');
    }
  }
}

const Unresolved c1 = 0; /// 01: static type warning, checked mode compile-time error

void main() {
  print(c1); /// 01: continued
  testValue(new List<String>()); /// 00: continued
  testValue(null); /// 00: continued
  checkFailures();
}
