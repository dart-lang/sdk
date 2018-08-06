// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_void_to_null`

// TODO(mfairhurst) test void with a prefix, except that causes bugs.
// TODO(mfairhurst) test defining a class named Null (requires a 2nd file)

import 'dart:async';
import 'dart:core';
import 'dart:core' as core;

void void_; // OK
Null null_; // LINT
core.Null core_null; // LINT
Future<void> future_void; // OK
Future<Null> future_null; // LINT
Future<core.Null> future_core_null; // LINT

void void_f() {} // OK
Null null_f() {} // LINT
core.Null core_null_f() {} // LINT
f_void(void x) {} // OK
f_null(Null x) {} // LINT
f_core_null(core.Null x) {} // LINT

void Function(Null) voidFunctionNull; // OK
Null Function() nullFunctionVoid; // OK
Future<Null> Function() FutureNullFunction; // LINT
void Function(Future<Null>) voidFunctionFutureNull; // LINT

usage() {
  void void_; // OK
  Null null_; // LINT
  core.Null core_null; // LINT
  Future<void> future_void; // OK
  Future<Null> future_null; // LINT
  Future<core.Null> future_core_null; // LINT

  future_void.then<Null>((_) {}); // LINT
  future_void.then<void>((_) {}); // OK
}

void inference() {
  final _null = null; // OK
  final nullReturnInferred = () {}; // OK
  final nullInferred = nullReturnInferred(); // OK
}

void emptyLiterals() {
  <Null>[]; // OK
  <Null>[null]; // LINT
  <void>[]; // OK
  <void>[null]; // OK
  <int, Null>{}; // OK
  <String, Null>{}; // OK
  <Object, Null>{}; // OK
  <Null, int>{}; // OK
  <Null, String>{}; // OK
  <Null, Object>{}; // OK
  <Null, Null>{}; // OK
  <int, Null>{1: null}; // LINT
  <String, Null>{"foo": null}; // LINT
  <Object, Null>{null: null}; // LINT
  <Null, int>{null: 1}; // LINT
  <Null, String>{null: "foo"}; // LINT
  <Null, Object>{null: null}; // LINT
  <Null, // LINT
      Null>{null: null}; // LINT
  <int, void>{}; // OK
  <String, void>{}; // OK
  <Object, void>{}; // OK
  <void, int>{}; // OK
  <void, String>{}; // OK
  <void, Object>{}; // OK
  <void, void>{}; // OK
  <int, void>{1: null}; // OK
  <String, void>{"foo": null}; // OK
  <Object, void>{null: null}; // OK
  <void, int>{null: 1}; // OK
  <void, String>{null: "foo"}; // OK
  <void, Object>{null: null}; // OK
  <void, void>{null: null}; // OK

  // TODO(mfairhurst): is it worth handling more complex literals?
}

variableNamedNull() {
  var Null; // OK
  return Null; // OK
}

parameterNamedNull(Object Null) {
  Null; // OK
}

class AsMembers {
  void void_; // OK
  Null null_; // LINT
  core.Null core_null; // LINT
  Future<void> future_void; // OK
  Future<Null> future_null; // LINT
  Future<core.Null> future_core_null; // LINT

  void void_f() {} // OK
  Null null_f() {} // LINT
  core.Null core_null_f() {} // LINT
  f_void(void x) {} // OK
  f_null(Null x) {} // LINT
  f_core_null(core.Null x) {} // LINT

  void usage() {
    void void_; // OK
    Null null_; // LINT
    core.Null core_null; // LINT
    Future<void> future_void; // OK
    Future<Null> future_null; // LINT
    Future<core.Null> future_core_null; // LINT

    future_void.then<Null>((_) {}); // LINT
    future_void.then<void>((_) {}); // OK
  }

  parameterNamedNull(Object Null) {
    Null; // OK
  }

  variableNamedNull() {
    var Null; // OK
    return Null; // OK
  }
}

class MemberNamedNull {
  final Null = null; // OK
}
