// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

class A implements Future<Future<A>> {
  @override
  noSuchMethod(Invocation _) {}
}

void main() {
  Expect.notSubtype<A, Future<A>>();
  Expect.subtype<FutureOr<A>, FutureOr<Future<A>>>();
}
