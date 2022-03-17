// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Const(2)
import 'dart:async';

@Const(3)
import augment 'multiple_imports_lib.dart';

FutureOr<void> main() {
  method();
}