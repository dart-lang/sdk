// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Class {
  Class();
  factory Class.redirect() = ClassImpl;
}

class ClassImpl implements Class {}

typedef F<T> = Class;

test() {
  Class.new; // Error
  Class.redirect; // Ok
  F.new; // Error
  F.redirect; // Ok
}
