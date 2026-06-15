// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

class Base<T> {
  String field;

  Base(this.field);
  String foo() => 'Base-$field';
}

class Sub<T> extends Base<T> {
  @override
  // ignore: overridden_fields
  String field;

  Sub(this.field) : super(field);
  @override
  String foo() {
    debugger();
    return 'Sub-$field';
  }
}

class ISub<T> implements Base<T> {
  @override
  String field;

  ISub(this.field);
  @override
  String foo() => 'ISub-$field';
}

class Box<T> {
  late T value;

  @pragma('vm:never-inline')
  void setValue(T value) {
    this.value = value;
  }
}

final objects = <Base>[Base<int>('b'), Sub<double>('a'), ISub<bool>('c')];

String triggerTypeTestingStubGeneration() {
  final Box<Object> box = Box<Base>();
  for (int i = 0; i < 1000000; ++i) {
    box.setValue(objects.last);
  }
  return 'tts-generated';
}

void testFunction() {
  // Triggers the debugger, which will evaluate an expression in the context of
  // [Sub<double>], which will make a subclass of [Base<T>].
  print(objects[1].foo());

  triggerTypeTestingStubGeneration();

  // Triggers the debugger, which will evaluate an expression in the context of
  // [Sub<double>], which will make a subclass of [Base<T>].
  print(objects[1].foo());
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
