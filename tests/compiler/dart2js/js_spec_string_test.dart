// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Unit test of the [NativeBehavior.processSpecString] method.

import 'package:expect/expect.dart';
import 'package:compiler/implementation/native/native.dart';
import 'package:compiler/implementation/dart2jslib.dart'
    show DiagnosticListener;

const OBJECT = 'Object';
const NULL = 'Null';

class Listener implements DiagnosticListener {
  String errorMessage;
  internalError(spannable, message) => errorMessage = message;

  noSuchMethod(_) => null;
}

void test(String specString,
          {List returns,
           List creates,
           bool expectError: false}) {
  List actualReturns = [];
  List actualCreates = [];
  Listener listener = new Listener();
  NativeBehavior.processSpecString(
      listener,
      null,
      specString,
      resolveType: (t) => t,
      typesReturned: actualReturns, typesInstantiated: actualCreates,
      objectType: OBJECT, nullType: NULL);
  if (expectError) {
    Expect.isNotNull(listener.errorMessage, 'Internal error expected.');
  } else {
    Expect.isNull(listener.errorMessage, 'Unexpected internal error.');
    Expect.listEquals(returns, actualReturns, 'Unexpected returns.');
    Expect.listEquals(creates, actualCreates, 'Unexpected creates.');
  }
}

void main() {
  test('void', returns: [], creates: []);
  test('', returns: [OBJECT, NULL], creates: []);
  test('var', returns: [OBJECT, NULL], creates: []);
  test('A', returns: ['A'], creates: ['A']);
  test('A|B', returns: ['A', 'B'], creates: ['A', 'B']);
  test('A|B|C', returns: ['A', 'B', 'C'], creates: ['A', 'B', 'C']);

  test('returns:void;', returns: [], creates: []);
  test('returns:;', returns: [OBJECT, NULL], creates: []);
  test('returns:var;', returns: [OBJECT, NULL], creates: []);
  test('returns:A;', returns: ['A'], creates: []);
  test('returns:A|B;', returns: ['A', 'B'], creates: []);
  test('returns:A|B|C;', returns: ['A', 'B', 'C'], creates: []);

  test('creates:void;', expectError: true);
  test('creates:;', expectError: true);
  test('creates:var;', expectError: true);
  test('creates:A;', returns: [], creates: ['A']);
  test('creates:A|B;', returns: [], creates: ['A', 'B']);
  test('creates:A|B|C;', returns: [], creates: ['A', 'B', 'C']);

  test('returns:void;creates:A;', returns: [], creates: ['A']);
  test('returns:;creates:A|B;', returns: [OBJECT, NULL], creates: ['A', 'B']);
  test('returns:var;creates:A|B|C;',
      returns: [OBJECT, NULL], creates: ['A', 'B', 'C']);
  test('returns:A; creates:A|B|C; ', returns: ['A'], creates: ['A', 'B', 'C']);
  test(' returns:A|B;  creates:A|C;',
      returns: ['A', 'B'], creates: ['A', 'C']);
  test(' returns:A|B|C;   creates:A;  ',
      returns: ['A', 'B', 'C'], creates: ['A']);
}
