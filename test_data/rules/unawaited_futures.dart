// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N unawaited_futures`

import 'dart:async';

Future fut() => Future.value(0);

foo1() {
  fut();
}

foo2() async {
  fut(); //LINT

  // ignore: unawaited_futures
  fut();
}

foo3() async {
  await fut();
}

foo4() async {
  var x = fut();
  return x;
}

foo5() async {
  Duration d = Duration();
  new Future.delayed(d); //LINT
}

foo6() async {
  var map = <String, Future>{};
  map.putIfAbsent('foo', () => fut());
}

foo7() async {
  _Foo()
    ..doAsync() //LINT
    ..doSync();
}

foo8() {
  // Fire and forget should not be reported per existing functionality
  _Foo()
    ..doAsync()
    ..doSync();
}

foo9() async {
  _Foo()
    ..futureField = fut();
}

foo10() async {
  _Foo()
    ..futureListField?[0] = fut();
}

foo11() async {
  _Foo()
    ..bar?.futureField = fut();
}

foo12() async {
  final x = [fut()];
  x..[0] = fut();
}

foo13() async {
  var y = '${fut()}'; //LINT
}

class _Bar {
  Future<void>? futureField;
}

class _Foo {
  Future<void>? futureField;
  List<Future<void>>? futureListField = [];
  _Bar? bar;
  Future<void> doAsync() async {}
  void doSync() => null;
  Future<void> get asyncProperty => doAsync();
  List<Future<void>> get futures => [doAsync()];
}

/// https://github.com/dart-lang/linter/issues/2211
class Future2 implements Future {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future2 fut2() => Future2();

f2() async {
  fut2(); //LINT
}
