// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

Future<String> foo(bool x) async => x ? "foo" : null;

Future<String> bar(bool x) async {
  return ((await foo(x)) ?? "bar").toUpperCase();
}

main() async {
  Expect.equals(await bar(true), "FOO");
  Expect.equals(await bar(false), "BAR");
}
