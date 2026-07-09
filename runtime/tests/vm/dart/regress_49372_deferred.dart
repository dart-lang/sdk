// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/49372.
// Verifies that dedup optimization doesn't merge Code from different unit.

@pragma('vm:never-inline')
int foo() => 10;

@pragma('vm:never-inline')
int bar() => foo() + 2;
