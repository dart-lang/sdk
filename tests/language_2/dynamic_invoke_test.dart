// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing dynamic calls.

import "package:expect/expect.dart";

// Make this something that DDC considers side effecting.
dynamic get d => "hello";

regress29504() {
  // These forms were being incorrectly generated as dynamic invokes, which is
  // not supposed to be done for the Object members that are always present on
  // all Dart types, including `null`.
  //
  // See https://github.com/dart-lang/sdk/issues/29504
  //
  // What we're testing here is that none of these generate dynamic invokes,
  // because that will throw a NoSuchMethod error if it happens.
  Expect.equals(d.runtimeType, String);
  Expect.equals(d?.runtimeType, String);
  Expect.equals(d..runtimeType, "hello");

  Expect.equals(d.hashCode, "hello".hashCode);
  Expect.equals(d?.hashCode, "hello".hashCode);
  Expect.equals(d..hashCode, "hello");

  Expect.equals(d.toString(), "hello");
  Expect.equals(d?.toString(), "hello");
  Expect.equals(d..toString(), "hello");
}

main() {
  regress29504();
}
