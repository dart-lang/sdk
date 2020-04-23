// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error if a required named parameter has a default value.
main() {}

void log1({String message: 'no message'}) {}
void log2({String? message}) {}
void log3({required String? message: 'no message'}) {} //# 01: compile-time error
void log4({required String message}) {}
