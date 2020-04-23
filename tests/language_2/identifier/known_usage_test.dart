// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The identifiers listed below are mentioned in the grammar, but none of
// them is a reserved word or a built-in identifier. Such an identifier can
// be used just like all other identifiers, with a few exceptions. Here are
// said 'known' identifiers:
//
//   `async`, `await`, `hide`, `of`, `on`, `show`, `sync`, `yield`
//
// This test contains various declarations of entities whose name is one of
// these known identifiers.

// Top level.

var async; //# 01: ok
var await; //# 01: continued
var hide; //# 01: continued
var of; //# 01: continued
var on; //# 01: continued
var show; //# 01: continued
var sync; //# 01: continued
var yield; //# 01: continued

int async; //# 02: ok
int await; //# 02: continued
int hide; //# 02: continued
int of; //# 02: continued
int on; //# 02: continued
int show; //# 02: continued
int sync; //# 02: continued
int yield; //# 02: continued

final String async = ""; //# 03: ok
final String await = ""; //# 03: continued
final String hide = ""; //# 03: continued
final String of = ""; //# 03: continued
final String on = ""; //# 03: continued
final String show = ""; //# 03: continued
final String sync = ""; //# 03: continued
final String yield = ""; //# 03: continued

const async = null; //# 04: ok
const await = null; //# 04: continued
const hide = null; //# 04: continued
const of = null; //# 04: continued
const on = null; //# 04: continued
const show = null; //# 04: continued
const sync = null; //# 04: continued
const yield = null; //# 04: continued

void async() {} //# 05: ok
void await() {} //# 05: continued
void hide() {} //# 05: continued
void of() {} //# 05: continued
void on() {} //# 05: continued
void show() {} //# 05: continued
void sync() {} //# 05: continued
void yield() {} //# 05: continued

void f1(async, await, hide, of, on, show, sync, yield) {}
void f2([async, await, hide, of, on, show, sync, yield]) {}
void f3({async, await, hide, of, on, show, sync, yield}) {}

void f4(
  int async,
  int await,
  int hide,
  int of,
  int on,
  int show,
  int sync,
  int yield,
) {}

void f5([
  int async,
  int await,
  int hide,
  int of,
  int on,
  int show,
  int sync,
  int yield,
]) {}

void f6({
  int async,
  int await,
  int hide,
  int of,
  int on,
  int show,
  int sync,
  int yield,
}) {}

class A {
  var async; //# 01: continued
  var await; //# 01: continued
  var hide; //# 01: continued
  var of; //# 01: continued
  var on; //# 01: continued
  var show; //# 01: continued
  var sync; //# 01: continued
  var yield; //# 01: continued

  num async; //# 02: continued
  num await; //# 02: continued
  num hide; //# 02: continued
  num of; //# 02: continued
  num on; //# 02: continued
  num show; //# 02: continued
  num sync; //# 02: continued
  num yield; //# 02: continued

  final String async = ""; //# 03: continued
  final String await = ""; //# 03: continued
  final String hide = ""; //# 03: continued
  final String of = ""; //# 03: continued
  final String on = ""; //# 03: continued
  final String show = ""; //# 03: continued
  final String sync = ""; //# 03: continued
  final String yield = ""; //# 03: continued

  String get async => ""; //# 04: continued
  String get await => ""; //# 04: continued
  String get hide => ""; //# 04: continued
  String get of => ""; //# 04: continued
  String get on => ""; //# 04: continued
  String get show => ""; //# 04: continued
  String get sync => ""; //# 04: continued
  String get yield => ""; //# 04: continued

  void async() {} //# 05: ok
  void await() {} //# 05: continued
  void hide() {} //# 05: continued
  void of() {} //# 05: continued
  void on() {} //# 05: continued
  void show() {} //# 05: continued
  void sync() {} //# 05: continued
  void yield() {} //# 05: continued

  A();

  A.c1( //# 01: continued
    this.async, //# 01: continued
    this.await, //# 01: continued
    this.hide, //# 01: continued
    this.of, //# 01: continued
    this.on, //# 01: continued
    this.show, //# 01: continued
    this.sync, //# 01: continued
    this.yield, //# 01: continued
  ) {} //# 01: continued

  A.c2([ //# 01: continued
    this.async, //# 01: continued
    this.await, //# 01: continued
    this.hide, //# 01: continued
    this.of, //# 01: continued
    this.on, //# 01: continued
    this.show, //# 01: continued
    this.sync, //# 01: continued
    this.yield, //# 01: continued
  ]) {} //# 01: continued

  A.c3({ //# 01: continued
    this.async, //# 01: continued
    this.await, //# 01: continued
    this.hide, //# 01: continued
    this.of, //# 01: continued
    this.on, //# 01: continued
    this.show, //# 01: continued
    this.sync, //# 01: continued
    this.yield, //# 01: continued
  }) {} //# 01: continued

  A.c4( //# 02: continued
    int this.async, //# 02: continued
    int this.await, //# 02: continued
    int this.hide, //# 02: continued
    int this.of, //# 02: continued
    int this.on, //# 02: continued
    int this.show, //# 02: continued
    int this.sync, //# 02: continued
    int this.yield, //# 02: continued
  ) {} //# 02: continued

  A.c5([ //# 02: continued
    int this.async, //# 02: continued
    int this.await, //# 02: continued
    int this.hide, //# 02: continued
    int this.of, //# 02: continued
    int this.on, //# 02: continued
    int this.show, //# 02: continued
    int this.sync, //# 02: continued
    int this.yield, //# 02: continued
  ]) {} //# 02: continued

  A.c6({ //# 02: continued
    int this.async, //# 02: continued
    int this.await, //# 02: continued
    int this.hide, //# 02: continued
    int this.of, //# 02: continued
    int this.on, //# 02: continued
    int this.show, //# 02: continued
    int this.sync, //# 02: continued
    int this.yield, //# 02: continued
  }) {} //# 02: continued

  void method1(
    covariant int async,
    covariant int await,
    covariant int hide,
    covariant int of,
    covariant int on,
    covariant int show,
    covariant int sync,
    covariant int yield,
  ) {}

  void method2([
    covariant int async,
    covariant int await,
    covariant int hide,
    covariant int of,
    covariant int on,
    covariant int show,
    covariant int sync,
    covariant int yield,
  ]) {}

  void method3({
    covariant int async,
    covariant int await,
    covariant int hide,
    covariant int of,
    covariant int on,
    covariant int show,
    covariant int sync,
    covariant int yield,
  }) {}
}

class B {
  static var async; //# 01: continued
  static var await; //# 01: continued
  static var hide; //# 01: continued
  static var of; //# 01: continued
  static var on; //# 01: continued
  static var show; //# 01: continued
  static var sync; //# 01: continued
  static var yield; //# 01: continued

  static num async; //# 02: continued
  static num await; //# 02: continued
  static num hide; //# 02: continued
  static num of; //# 02: continued
  static num on; //# 02: continued
  static num show; //# 02: continued
  static num sync; //# 02: continued
  static num yield; //# 02: continued

  static final String async = ""; //# 03: continued
  static final String await = ""; //# 03: continued
  static final String hide = ""; //# 03: continued
  static final String of = ""; //# 03: continued
  static final String on = ""; //# 03: continued
  static final String show = ""; //# 03: continued
  static final String sync = ""; //# 03: continued
  static final String yield = ""; //# 03: continued

  static const async = null; //# 04: continued
  static const await = null; //# 04: continued
  static const hide = null; //# 04: continued
  static const of = null; //# 04: continued
  static const on = null; //# 04: continued
  static const show = null; //# 04: continued
  static const sync = null; //# 04: continued
  static const yield = null; //# 04: continued

  static get async => null; //# 05: continued
  static get await => null; //# 05: continued
  static get hide => null; //# 05: continued
  static get of => null; //# 05: continued
  static get on => null; //# 05: continued
  static get show => null; //# 05: continued
  static get sync => null; //# 05: continued
  static get yield => null; //# 05: continued
}

main() {
  /* //# none: ok

  // Except none: Use a top-level declaration.
  var top_async = async;
  var top_await = await;
  var top_hide = hide;
  var top_of = of;
  var top_on = on;
  var top_show = show;
  var top_sync = sync;
  var top_yield = yield;

  // Except none: Use an instance member of A.
  A a = new A();
  var instance_async = a.async;
  var instance_await = a.await;
  var instance_hide = a.hide;
  var instance_of = a.of;
  var instance_on = a.on;
  var instance_show = a.show;
  var instance_sync = a.sync;
  var instance_yield = a.yield;

  // Except none: Use a static member of B.

  var static_async = B.async;
  var static_await = B.await;
  var static_hide = B.hide;
  var static_of = B.of;
  var static_on = B.on;
  var static_show = B.show;
  var static_sync = B.sync;
  var static_yield = B.yield;

  */ //# none: continued

  var a1 = new A.c1(1, 1, 1, 1, 1, 1, 1, 1); //# 01: continued
  var a2 = new A.c2(); //# 01: continued
  var a3 = new A.c3( //# 01: continued
    async: 1, //# 01: continued
    await: 1, //# 01: continued
    hide: 1, //# 01: continued
    of: 1, //# 01: continued
    on: 1, //# 01: continued
    show: 1, //# 01: continued
    sync: 1, //# 01: continued
    yield: 1, //# 01: continued
  ); //# 01: continued

  var a4 = new A.c4(1, 1, 1, 1, 1, 1, 1, 1); //# 02: continued
  var a5 = new A.c5(); //# 02: continued
  var a6 = new A.c6( //# 02: continued
    async: 1, //# 02: continued
    await: 1, //# 02: continued
    hide: 1, //# 02: continued
    of: 1, //# 02: continued
    on: 1, //# 02: continued
    show: 1, //# 02: continued
    sync: 1, //# 02: continued
    yield: 1, //# 02: continued
  ); //# 02: continued

  var aa = new A();
  aa.method1(1, 1, 1, 1, 1, 1, 1, 1);
  aa.method2();
  aa.method3(
    async: 1,
    await: 1,
    hide: 1,
    of: 1,
    on: 1,
    show: 1,
    sync: 1,
    yield: 1,
  );
}
