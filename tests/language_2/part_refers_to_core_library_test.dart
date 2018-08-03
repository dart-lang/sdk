// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test reproduces https://github.com/dart-lang/sdk/issues/29709.

library dart.async;

part 'dart:async/future.dart'; //# 01: compile-time error

main() {}
