// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_void_async`
import 'dart:async';

void main() {
  () {}; // OK
  () => null; // OK
  () async {}; // OK
  () async => null; // OK
}

void a() async {} // LINT
void b() {} // OK
Future<void> c() async {} // OK
void d() async => null; // LINT
void e() => null; // OK
Future<void> f() async => null; // OK

void g() async* {} // LINT
void h() sync* {} // LINT
Stream<void> i() async* {} // OK
Iterable<void> j() sync* {} // OK

void get k => null; // OK
void get l async => null; // LINT

void set m(_) => null; // OK
set n(_) => null; // OK

typedef void f1(int x); // OK

typedef Future<void> f2(int x); // OK

class Foo {
  static void statica() async {} // LINT
  static void staticb() {} // OK
  static Future<void> staticc() async {} // OK

  void a() async {} // LINT
  void b() {} // OK
  Future<void> c() async {} // OK
  void d() async => null; // LINT
  void e() => null; // OK
  Future<void> f() async => null; // OK

  void g() async* {} // LINT
  void h() sync* {} // LINT
  Stream<void> i() async* {} // OK
  Iterable<void> j() sync* {} // OK

  void get k => null; // OK
  void get l async => null; // LINT

  void operator |(_) async => null; // LINT
  void operator &(_) => null; // OK
}
