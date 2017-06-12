// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to ensure that StringBuffer and string interpolation behaves
// the same and fail fast.

import "package:expect/expect.dart";

class ToStringWrapper {
  final value;

  ToStringWrapper(this.value);

  toString() => value;
}

wrap(value) => new ToStringWrapper(value);

final bool checkedMode = computeCheckedMode();
bool computeCheckedMode() {
  try {
    var i = 42;
    String s = i;
  } on TypeError catch (e) {
    return true;
  }
  return false;
}

main() {
  interpolate(object) {
    var result;
    if (checkedMode && object != null) {
      try {
        result = '${wrap(object)}';
      } on TypeError {
        return 'Error';
      } on ArgumentError {
        return 'Error'; // Checked mode.
      }
    } else {
      try {
        result = '${wrap(object)}';
      } on ArgumentError {
        return 'Error';
      }
    }
    Expect.isTrue(result is String);
    return 'Success';
  }

  buffer(object) {
    var sb;
    if (checkedMode && object != null) {
      try {
        sb = new StringBuffer()..write(wrap(object));
      } on TypeError {
        return 'Error';
      } on ArgumentError {
        return 'Error'; // Checked mode.
      }
    } else {
      try {
        sb = new StringBuffer()..write(wrap(object));
      } on ArgumentError {
        return 'Error';
      }
      Expect.isTrue(sb.toString() is String);
    }
    return 'Success';
  }

  initBuffer(object) {
    var sb;
    if (checkedMode && object != null) {
      try {
        sb = new StringBuffer(wrap(object));
      } on TypeError {
        return 'Error';
      } on ArgumentError {
        return 'Error'; // Checked mode.
      }
    } else {
      try {
        sb = new StringBuffer(wrap(object));
      } on ArgumentError {
        return 'Error';
      }
      Expect.isTrue(sb.toString() is String);
    }
    return 'Success';
  }

  Expect.equals('Error', interpolate(null));
  Expect.equals('Success', interpolate(""));
  Expect.equals('Success', interpolate("string"));
  Expect.equals('Error', interpolate([]));
  Expect.equals('Error', interpolate([1]));
  Expect.equals('Error', interpolate(new Object()));

  Expect.equals('Error', buffer(null));
  Expect.equals('Success', buffer(""));
  Expect.equals('Success', buffer("string"));
  Expect.equals('Error', buffer([]));
  Expect.equals('Error', buffer([1]));
  Expect.equals('Error', buffer(new Object()));

  Expect.equals('Error', initBuffer(null));
  Expect.equals('Success', initBuffer(""));
  Expect.equals('Success', initBuffer("string"));
  Expect.equals('Error', initBuffer([]));
  Expect.equals('Error', initBuffer([1]));
  Expect.equals('Error', initBuffer(new Object()));
}
