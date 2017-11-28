// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that stack traces are properly demangled in constructors (#28740).

import "package:expect/expect.dart";

class SomeClass {
  SomeClass.namedConstructor() {
    throw new Exception();
  }

  SomeClass() {
    throw new Exception();
  }

  factory SomeClass.useFactory() {
    throw new Exception();
  }
}

class OnlyHasFactory {
  factory OnlyHasFactory() {
    throw new Exception();
  }
}

void main() {
  try {
    new SomeClass();
  } on Exception catch (e, st) {
    final stString = st.toString();
    Expect.isTrue(stString.contains("new SomeClass"));
    Expect.isFalse(stString.contains("SomeClass."));
  }

  try {
    new SomeClass.namedConstructor();
  } on Exception catch (e, st) {
    final stString = st.toString();
    Expect.isTrue(stString.contains("new SomeClass.namedConstructor"));
  }

  try {
    new OnlyHasFactory();
  } on Exception catch (e, st) {
    final stString = st.toString();
    Expect.isTrue(stString.contains("new OnlyHasFactory"));
    Expect.isFalse(stString.contains("OnlyHasFactory."));
  }

  try {
    new SomeClass.useFactory();
  } on Exception catch (e, st) {
    final stString = st.toString();
    Expect.isTrue(stString.contains("new SomeClass.useFactory"));
  }
}
