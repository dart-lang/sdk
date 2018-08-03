// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import 'dart:developer';
import 'package:expect/expect.dart';

// Test that the default tag is set.
testDefault() {
  Expect.isTrue(identical(UserTag.defaultTag, getCurrentTag()));
}

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
  var defaultLabel = 'Default';
  var defaultTag = new UserTag(defaultLabel);
  Expect.isTrue(identical(UserTag.defaultTag, defaultTag));
}

// Test that we made the tag current.
void testMakeCurrent(tag) {
  tag.makeCurrent();
  Expect.isTrue(identical(tag, getCurrentTag()));
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

var callerTag = new UserTag('caller');
var calleeTag = new UserTag('callee');

void callee() {
  var old = calleeTag.makeCurrent();
  Expect.isTrue(identical(calleeTag, getCurrentTag()));
  old.makeCurrent();
}

void testCallerPattern() {
  Expect.isTrue(identical(UserTag.defaultTag, getCurrentTag()));
  var old = callerTag.makeCurrent();
  Expect.isTrue(identical(callerTag, getCurrentTag()));
  callee();
  Expect.isTrue(identical(callerTag, getCurrentTag()));
  old.makeCurrent();
  Expect.isTrue(identical(UserTag.defaultTag, getCurrentTag()));
}

main() {
  testDefault();
  testCallerPattern();
  var label = 'Global Tag';
  var tag = new UserTag(label);
  testLabel();
  testCanonicalize(tag);
  for (var i = 0; i < 2000; i++) {
    testMakeCurrent(tag);
  }
  Expect.throws(testExhaust);
}
