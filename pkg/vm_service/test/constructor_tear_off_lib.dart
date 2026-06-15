// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

class Foo {
  Foo();
  Foo.named();
}

class Generic<T> {
  Generic();
}

@pragma('vm:entry-point')
Function getNamedConstructorTearoff() => Foo.named;

@pragma('vm:entry-point')
Function getDefaultConstructorTearoff() => Foo.new;

@pragma('vm:entry-point')
Function getGenericConstructorTearoff() => Generic<int>.new;

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest();
}
