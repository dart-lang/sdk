// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'dart:async';

Future<T> foo<T>(T x) async => x;

main() async {
  Expect.equals(1, await foo<int>(1));
}
