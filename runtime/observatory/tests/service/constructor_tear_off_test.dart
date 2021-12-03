// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.15

import 'package:observatory/service_common.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

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

Future<void> invokeConstructorTearoff(
  Isolate isolate,
  String name,
  String expectedType,
) async {
  final lib = await isolate.rootLibrary.load() as Library;
  final tearoff = await isolate.invokeRpc('invoke', {
    'targetId': lib.id,
    'selector': name,
    'argumentIds': [],
  });
  final result = await isolate.invokeRpc('invoke', {
    'targetId': tearoff.id,
    'selector': 'call',
    'argumentIds': [],
  }) as Instance;
  expect(result.clazz!.name, expectedType);
}

final tests = <IsolateTest>[
  (Isolate isolate) => invokeConstructorTearoff(
        isolate,
        'getNamedConstructorTearoff',
        'Foo',
      ),
  (Isolate isolate) => invokeConstructorTearoff(
        isolate,
        'getDefaultConstructorTearoff',
        'Foo',
      ),
  (Isolate isolate) => invokeConstructorTearoff(
        isolate,
        'getGenericConstructorTearoff',
        'Generic',
      ),
];

void main(List<String> args) => runIsolateTests(
      args,
      tests,
    );
