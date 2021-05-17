// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that private names exported via public typedefs can be used in a try
// catch.

import "package:expect/expect.dart";

import "private_name_library.dart";

class Derived extends PublicClass {}

void test1() {
  try {
    throw Derived();
  } on PublicClass catch (e) {}

  try {
    throw Derived();
  } on Derived catch (e) {}

  try {
    throw PublicClass();
  } on PublicClass catch (e) {}

  try {
    throw PublicClass();
  } on AlsoPublicClass catch (e) {}

  Expect.throws(() {
    try {
      throw PublicClass();
    } on Derived catch (e) {}
  });
}

void main() {
  test1();
}
