// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import 'dart:profiler';
import 'package:expect/expect.dart';

// Test that the label property matches the constructor.
void testLabel() {
  var label = 'Hello World';
  var tag = new UserTag(label);
  Expect.equals(label, tag.label);
}


// Test that we canonicalize UserTag by name.
void testCanonicalize(tag1) {
  var label = 'Global Tag';
  var tag = new UserTag(label);
  Expect.isTrue(identical(tag, tag1));
}


// Test that we made the tag current.
void testMakeCurrent(tag) {
  tag.makeCurrent();
  Expect.isTrue(identical(tag, getCurrentTag()));
}


// Test clearCurrentTag.
void testClearCurrent(tag) {
  tag.makeCurrent();
  Expect.isTrue(identical(tag, getCurrentTag()));
  var old_tag = clearCurrentTag();
  Expect.isTrue(identical(tag, old_tag));
  Expect.isNull(getCurrentTag());
}


// Test that we reach a limit of tags an exception is thrown.
void testExhaust() {
  var i = 0;
  while (true) {
    var label = i.toString();
    var tag = new UserTag(label);
    i++;
  }
}


main() {
  var label = 'Global Tag';
  var tag = new UserTag(label);
  testLabel();
  testCanonicalize(tag);
  for (var i = 0; i < 2000; i++) {
    testMakeCurrent(tag);
  }
  testClearCurrent(tag);
  Expect.throws(testExhaust);
}
