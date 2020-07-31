// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that stack traces are properly demangled in constructors (#28740).
// Regression test for http://dartbug.com/28740

import "package:expect/expect.dart";

class SomeClass {
  SomeClass.namedConstructor() {
    throw Exception();
  }

  SomeClass() {
    throw Exception();
  }

  factory SomeClass.useFactory() {
    throw Exception();
  }
}

class OnlyHasFactory {
  factory OnlyHasFactory() {
    throw Exception();
  }
}

void main() {
  try {
    SomeClass();
  } on Exception catch (e, st) {
    final stString = st.toString();
    Expect.isTrue(stString.contains("new SomeClass"));
    Expect.isFalse(stString.contains("SomeClass."));
  }

  try {
    SomeClass.namedConstructor();
  } on Exception catch (e, st) {
    final stString = st.toString();
    Expect.isTrue(stString.contains("new SomeClass.namedConstructor"));
  }

  try {
    OnlyHasFactory();
  } on Exception catch (e, st) {
    final stString = st.toString();
    Expect.isTrue(stString.contains("new OnlyHasFactory"));
    Expect.isFalse(stString.contains("OnlyHasFactory."));
  }

  try {
    SomeClass.useFactory();
  } on Exception catch (e, st) {
    final stString = st.toString();
    Expect.isTrue(stString.contains("new SomeClass.useFactory"));
  }
}
