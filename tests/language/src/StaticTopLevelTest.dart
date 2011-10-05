// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

static method() { }                  /// 00: compile-time error
static var field;                    /// 01: compile-time error
static final constant = 42;          /// 02: compile-time error

static int typedMethod() => 87;      /// 03: compile-time error
static int typedField;               /// 04: compile-time error
static final int typedConstant = 99; /// 05: compile-time error

void main() {
}
