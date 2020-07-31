// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

void main() {
  void f1<T extends FutureOr<T>>() {}
  void f2<S extends FutureOr<S>>() {}

  Expect.equals(f1.runtimeType, f2.runtimeType);
}
