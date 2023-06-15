// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  switchSingleCase();
  ifCase();
  sharedCaseUseInBody();
  sharedCaseOnlyGuards();
}

/// Guard and body use same variables when cases are not shared.
void switchSingleCase() {
  _closures.clear();
  switch (['one', 'two']) {
    case [var a, var b] when _capture(() => a) && _capture(() => b):
      Expect.equals('one two', _runClosures());
      Expect.equals('one', a);
      Expect.equals('two', b);

      a = 'after';
      b = 'then';
      Expect.equals('after', a);
      Expect.equals('then', b);

      // Guard closures see update.
      Expect.equals('after then', _runClosures());
  }
}

/// Guard and body use same variables in if-case statements.
void ifCase() {
  _closures.clear();
  if (['one', 'two']
      case [var a, var b] when _capture(() => a) && _capture(() => b)) {
    Expect.equals('one two', _runClosures());
    Expect.equals('one', a);
    Expect.equals('two', b);

    a = 'after';
    b = 'then';
    Expect.equals('after', a);
    Expect.equals('then', b);

    // Guard closures see update.
    Expect.equals('after then', _runClosures());
  }
}

/// Guards and body get separate variable when cases are shared.
void sharedCaseUseInBody() {
  _closures.clear();
  switch (['one', 'two', 'three']) {
    case [var a, _, _] when _capture(() => a, false):
    case [_, var a, _] when _capture(() => a, false):
    case [_, _, var a] when _capture(() => a, true):
      Expect.equals('three', a);
      Expect.equals('one two three', _runClosures());

      a = 'after';
      Expect.equals('after', a);

      // Guard closures are unaffected.
      Expect.equals('one two three', _runClosures());
  }
}

/// Guards each have their own separate variables even when the variable isn't
/// used in the body.
void sharedCaseOnlyGuards() {
  _closures.clear();
  switch (['one', 'two', 'three']) {
    case [var a, _, _] when _capture(() => a, false):
    case [_, var a, _] when _capture(() => a, false):
    case [_, _, var a] when _capture(() => a, true):
      Expect.equals('one two three', _runClosures());
  }
}

final _closures = <Object Function()>[];

bool _capture(Object Function() closure, [bool result = true]) {
  _closures.add(closure);
  return result;
}

String _runClosures() => _closures.map((closure) => closure()).join(' ');
