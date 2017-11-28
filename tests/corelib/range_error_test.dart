// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test for testing out of range exceptions on arrays, and the content
// of range_error toString().

void main() {
  testRead();
  testWrite();
  testToString();
}

void testRead() {
  testListRead([], 0);
  testListRead([], -1);
  testListRead([], 1);

  var list = [1];
  testListRead(list, -1);
  testListRead(list, 1);

  list = new List(1);
  testListRead(list, -1);
  testListRead(list, 1);

  list = new List();
  testListRead(list, -1);
  testListRead(list, 0);
  testListRead(list, 1);
}

void testWrite() {
  testListWrite([], 0);
  testListWrite([], -1);
  testListWrite([], 1);

  var list = [1];
  testListWrite(list, -1);
  testListWrite(list, 1);

  list = new List(1);
  testListWrite(list, -1);
  testListWrite(list, 1);

  list = new List();
  testListWrite(list, -1);
  testListWrite(list, 0);
  testListWrite(list, 1);
}

void testToString() {
  for (var name in [null, "THENAME"]) {
    for (var message in [null, "THEMESSAGE"]) {
      var value = 37;
      for (var re in [
        new ArgumentError.value(value, name, message),
        new RangeError.value(value, name, message),
        new RangeError.index(value, [], name, message),
        new RangeError.range(value, 0, 24, name, message)
      ]) {
        var str = re.toString();
        if (name != null) Expect.isTrue(str.contains(name), "$name in $str");
        if (message != null)
          Expect.isTrue(str.contains(message), "$message in $str");
        Expect.isTrue(str.contains("$value"), "$value in $str");
        // No empty ':' separated parts - in that case the colon is omitted too.
        Expect.isFalse(str.contains(new RegExp(":\s*:")));
      }
    }
  }
}

void testListRead(list, index) {
  var exception = null;
  try {
    var e = list[index];
  } on RangeError catch (e) {
    exception = e;
  }
  Expect.equals(true, exception != null);
}

void testListWrite(list, index) {
  var exception = null;
  try {
    list[index] = null;
  } on RangeError catch (e) {
    exception = e;
  }
  Expect.equals(true, exception != null);
}
