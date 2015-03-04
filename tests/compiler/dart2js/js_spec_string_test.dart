// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Unit test of the [NativeBehavior.processSpecString] method.

import 'package:expect/expect.dart';
import 'package:compiler/src/native/native.dart';
import 'package:compiler/src/dart2jslib.dart'
    show DiagnosticListener;
import 'package:compiler/src/universe/universe.dart'
    show SideEffects;

const OBJECT = 'Object';
const NULL = 'Null';

class Listener implements DiagnosticListener {
  String errorMessage;
  internalError(spannable, message) {
    errorMessage = message;
    throw "error";
  }

  noSuchMethod(_) => null;
}

void test(String specString,
          {List returns,
           List creates,
           SideEffects expectedSideEffects,
           bool expectError: false}) {
  List actualReturns = [];
  List actualCreates = [];
  SideEffects actualSideEffects;
  Listener listener = new Listener();
  try {
    NativeBehavior.processSpecString(
        listener,
        null,
        specString,
        setSideEffects: (effects) { actualSideEffects = effects; },
        resolveType: (t) => t,
        typesReturned: actualReturns, typesInstantiated: actualCreates,
        objectType: OBJECT, nullType: NULL);
  } catch (e) {
    Expect.isTrue(expectError);
    Expect.isNotNull(listener.errorMessage, 'Internal error expected.');
    return;
  }
  Expect.isNull(listener.errorMessage, 'Unexpected internal error.');
  Expect.listEquals(returns, actualReturns, 'Unexpected returns.');
  Expect.listEquals(creates, actualCreates, 'Unexpected creates.');
  Expect.equals(expectedSideEffects, actualSideEffects);
}

void testWithSideEffects(String specString,
                          {List returns,
                           List creates,
                           bool expectError: false}) {

  void sideEffectsTest(String newSpecString, SideEffects expectedSideEffects,
                       {bool sideEffectsExpectError}) {
    test(newSpecString,
         returns: returns,
         creates: creates,
         expectedSideEffects: expectedSideEffects,
         expectError: sideEffectsExpectError == null
             ? expectError
             : sideEffectsExpectError);
  }

  SideEffects emptySideEffects = new SideEffects.empty();
  sideEffectsTest(specString + "effects:none;depends:none;",
                  emptySideEffects);
  sideEffectsTest(specString + "depends:none;effects:none;",
                  emptySideEffects);
  sideEffectsTest("effects:none;depends:none;" + specString,
                  emptySideEffects);
  sideEffectsTest("depends:none;effects:none;" + specString,
                  emptySideEffects);

  SideEffects effects = new SideEffects();
  effects.clearChangesIndex();
  effects.clearAllDependencies();
  sideEffectsTest(specString + "effects:no-index;depends:none;", effects);

  effects = new SideEffects();
  effects.clearAllSideEffects();
  effects.clearDependsOnIndexStore();
  sideEffectsTest(specString + "effects:none;depends:no-index;", effects);

  effects = new SideEffects();
  effects.clearChangesInstanceProperty();
  effects.clearChangesStaticProperty();
  effects.clearAllDependencies();
  sideEffectsTest(specString + "effects:no-instance,no-static;depends:none;",
                  effects);

  effects = new SideEffects();
  effects.clearAllSideEffects();
  effects.clearDependsOnInstancePropertyStore();
  effects.clearDependsOnStaticPropertyStore();
  sideEffectsTest(specString + "effects:none;depends:no-instance,no-static;",
                  effects);

  effects = new SideEffects();
  effects.clearChangesInstanceProperty();
  effects.clearChangesStaticProperty();
  effects.clearDependsOnIndexStore();
  sideEffectsTest(
      specString + "effects:no-instance,no-static;depends:no-index;", effects);

  effects = new SideEffects();
  effects.clearChangesIndex();
  effects.clearDependsOnInstancePropertyStore();
  effects.clearDependsOnStaticPropertyStore();
  sideEffectsTest(
      specString + "effects:no-index;depends:no-instance,no-static;", effects);

  effects = new SideEffects();
  effects.clearChangesIndex();
  sideEffectsTest(specString + "effects:no-index;depends:all;", effects);

  effects = new SideEffects();
  effects.clearDependsOnIndexStore();
  sideEffectsTest(specString + "effects:all;depends:no-index;", effects);

  effects = new SideEffects();
  effects.clearChangesInstanceProperty();
  effects.clearChangesStaticProperty();
  sideEffectsTest(specString + "effects:no-instance,no-static;depends:all;",
                  effects);

  effects = new SideEffects();
  effects.clearDependsOnInstancePropertyStore();
  effects.clearDependsOnStaticPropertyStore();
  sideEffectsTest(specString + "effects:all;depends:no-instance,no-static;",
                  effects);

  sideEffectsTest(specString + "effects:no-instance,no-static;",
                  effects,
                  sideEffectsExpectError: true);

  sideEffectsTest(specString + "depends:no-instance,no-static;",
                  effects,
                  sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:none;",
                  effects,
                  sideEffectsExpectError: true);

  sideEffectsTest(specString + "depends:all;",
                  effects,
                  sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:no-instance,no-static;depends:foo;",
                  effects,
                  sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:foo;depends:no-instance,no-static;",
                  effects,
                  sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:all;depends:foo",
                  effects,
                  sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:foo;depends:none;",
                  effects,
                  sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:;depends:none;",
                  effects,
                  sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:all;depends:;",
                  effects,
                  sideEffectsExpectError: true);
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

  testWithSideEffects('returns:void;', returns: [], creates: []);
  testWithSideEffects('returns:void;', returns: [], creates: []);
  testWithSideEffects('returns:;', returns: [OBJECT, NULL], creates: []);
  testWithSideEffects('returns:var;', returns: [OBJECT, NULL], creates: []);
  testWithSideEffects('returns:A;', returns: ['A'], creates: []);
  testWithSideEffects('returns:A|B;', returns: ['A', 'B'], creates: []);
  testWithSideEffects('returns:A|B|C;', returns: ['A', 'B', 'C'], creates: []);

  testWithSideEffects('creates:void;', expectError: true);
  testWithSideEffects('creates:;', expectError: true);
  testWithSideEffects('creates:var;', expectError: true);
  testWithSideEffects('creates:A;', returns: [], creates: ['A']);
  testWithSideEffects('creates:A|B;', returns: [], creates: ['A', 'B']);
  testWithSideEffects('creates:A|B|C;', returns: [], creates: ['A', 'B', 'C']);

  testWithSideEffects('returns:void;creates:A;', returns: [], creates: ['A']);
  testWithSideEffects('returns:;creates:A|B;',
      returns: [OBJECT, NULL], creates: ['A', 'B']);
  testWithSideEffects('returns:var;creates:A|B|C;',
      returns: [OBJECT, NULL], creates: ['A', 'B', 'C']);
  testWithSideEffects('returns:A; creates:A|B|C; ',
      returns: ['A'], creates: ['A', 'B', 'C']);
  testWithSideEffects(' returns:A|B;  creates:A|C;',
      returns: ['A', 'B'], creates: ['A', 'C']);
  testWithSideEffects(' returns:A|B|C;   creates:A;  ',
      returns: ['A', 'B', 'C'], creates: ['A']);
}
