// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error if a top level variable with non-nullable type has
// no initializer expression.
void main() {}

int v; //# 01: compile-time error
int v = 0; //# 02: ok
int? v; //# 03: ok
int? v = 0; //# 04: ok
dynamic v; //# 05: ok
var v; //# 06: ok
void v; //# 07: ok
Never v; //# 08: compile-time error
