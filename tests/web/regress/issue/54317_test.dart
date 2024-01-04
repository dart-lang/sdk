// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

void main() async {
  final value = await fn();
  Expect.equals(42, value);
}

FutureOr<Object> fn() async => 42;
