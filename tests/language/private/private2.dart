// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for testing access to private fields.

part of PrivateTest.dart;

String _private2() {
  return "private2";
}

const String _private2Field = "private2Field";

accessFieldA2(_A a) {
  return a.fieldA;
}

accessFieldB2(B b) {
  return b._fieldB;
}
