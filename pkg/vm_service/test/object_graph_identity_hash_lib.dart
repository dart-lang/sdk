// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

@pragma('vm:entry-point') // Prevent obfuscation
class Foo {}

@pragma('vm:entry-point') // Prevent obfuscation
class Bar {}

class Container1 {
  @pragma('vm:entry-point') // Prevent obfuscation
  final foo = Foo();
  @pragma('vm:entry-point') // Prevent obfuscation
  final bar = Bar();
}

class Container2 {
  Container2(this.foo);

  @pragma('vm:entry-point') // Prevent obfuscation
  final Foo foo;
  @pragma('vm:entry-point') // Prevent obfuscation
  final bar = Bar();
}

class Container3 {
  @pragma('vm:entry-point') // Prevent obfuscation
  final number = 42;
  @pragma('vm:entry-point') // Prevent obfuscation
  final doub = 3.14;
  @pragma('vm:entry-point') // Prevent obfuscation
  final foo = 'foobar';
  @pragma('vm:entry-point') // Prevent obfuscation
  final bar = false;
  @pragma('vm:entry-point') // Prevent obfuscation
  late final Map<String, String> baz;
  @pragma('vm:entry-point') // Prevent obfuscation
  late final List<int> list;
  @pragma('vm:entry-point') // Prevent obfuscation
  late final List<void> unmodifiableList;

  Container3() {
    baz = {
      'a': 'b',
    };
    list = [1, 2, 3];
    unmodifiableList = List<void>.empty();
  }
}

@pragma('vm:entry-point') // Prevent obfuscation
late Container1 c1;
@pragma('vm:entry-point') // Prevent obfuscation
late Container2 c2;
@pragma('vm:entry-point') // Prevent obfuscation
late Container3 c3;

void script() {
  c1 = Container1();
  c2 = Container2(c1.foo);
  c3 = Container3();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
