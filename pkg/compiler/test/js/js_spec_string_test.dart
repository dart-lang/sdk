// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Unit test of the [NativeBehavior.processSpecString] method.

import 'package:compiler/src/common.dart';
import 'package:compiler/src/native/behavior.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/universe/side_effects.dart' show SideEffects;
import 'package:expect/expect.dart';
import '../helpers/type_test_helper.dart';

const OBJECT = 'Object';
const NULL = 'Null';

class Listener implements DiagnosticReporter {
  String? errorMessage;

  @override
  internalError(spannable, message) {
    errorMessage = message as String;
    throw "error";
  }

  @override
  reportError(message, [infos = const <DiagnosticMessage>[]]) {
    errorMessage =
        '${message.message.arguments}'; // E.g.  "{text: Duplicate tag 'new'.}"
    throw "error";
  }

  @override
  reportErrorMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
    reportError(createMessage(spannable, messageKind, arguments));
  }

  @override
  DiagnosticMessage createMessage(spannable, messageKind,
      [arguments = const {}]) {
    return DiagnosticMessage(SourceSpan.unknown(), spannable,
        MessageTemplate.TEMPLATES[messageKind]!.message(arguments, null));
  }

  @override
  noSuchMethod(_) => null;
}

void test(DartTypes dartTypes, String specString,
    {List<Object>? returns,
    List<Object>? creates,
    SideEffects? expectedSideEffects,
    NativeThrowBehavior? expectedThrows,
    bool? expectedNew,
    bool? expectedGvn,
    bool expectError = false}) {
  List<Object> actualReturns = [];
  List<Object> actualCreates = [];
  SideEffects? actualSideEffects;
  NativeThrowBehavior? actualThrows;
  bool? actualNew;
  bool? actualGvn;
  Listener listener = Listener();
  try {
    NativeBehavior.processSpecString(
        dartTypes, listener, NO_LOCATION_SPANNABLE, specString,
        setSideEffects: (effects) => actualSideEffects = effects,
        setThrows: (b) => actualThrows = b,
        setIsAllocation: (b) => actualNew = b,
        setUseGvn: (b) => actualGvn = b,
        lookupType: (t, {bool? required}) => t,
        typesReturned: actualReturns,
        typesInstantiated: actualCreates,
        objectType: OBJECT,
        nullType: NULL);
  } catch (e) {
    Expect.isTrue(expectError, 'Unexpected error "$specString"');
    Expect.isNotNull(listener.errorMessage, 'Error message expected.');
    return;
  }
  Expect.isFalse(expectError, 'Missing error for "$specString".');
  Expect.isNull(listener.errorMessage, 'Unexpected error.');
  if (returns != null) {
    Expect.listEquals(returns, actualReturns, 'Unexpected returns.');
  }
  if (creates != null) {
    Expect.listEquals(creates, actualCreates, 'Unexpected creates.');
  }
  Expect.equals(expectedSideEffects, actualSideEffects);
  Expect.equals(expectedThrows, actualThrows);
  Expect.equals(expectedNew, actualNew);
  Expect.equals(expectedGvn, actualGvn);
}

void testWithSideEffects(DartTypes dartTypes, String specString,
    {List<Object>? returns, List<Object>? creates, bool expectError = false}) {
  void sideEffectsTest(String newSpecString, SideEffects expectedSideEffects,
      {bool? sideEffectsExpectError}) {
    test(dartTypes, newSpecString,
        returns: returns,
        creates: creates,
        expectedSideEffects: expectedSideEffects,
        expectError: sideEffectsExpectError ?? expectError);
  }

  SideEffects emptySideEffects = SideEffects.empty();
  sideEffectsTest(specString + "effects:none;depends:none;", emptySideEffects);
  sideEffectsTest(specString + "depends:none;effects:none;", emptySideEffects);
  sideEffectsTest("effects:none;depends:none;" + specString, emptySideEffects);
  sideEffectsTest("depends:none;effects:none;" + specString, emptySideEffects);

  SideEffects effects = SideEffects();
  effects.clearChangesIndex();
  effects.clearAllDependencies();
  sideEffectsTest(specString + "effects:no-index;depends:none;", effects);

  effects = SideEffects();
  effects.clearAllSideEffects();
  effects.clearDependsOnIndexStore();
  sideEffectsTest(specString + "effects:none;depends:no-index;", effects);

  effects = SideEffects();
  effects.clearChangesInstanceProperty();
  effects.clearChangesStaticProperty();
  effects.clearAllDependencies();
  sideEffectsTest(
      specString + "effects:no-instance,no-static;depends:none;", effects);

  effects = SideEffects();
  effects.clearAllSideEffects();
  effects.clearDependsOnInstancePropertyStore();
  effects.clearDependsOnStaticPropertyStore();
  sideEffectsTest(
      specString + "effects:none;depends:no-instance,no-static;", effects);

  effects = SideEffects();
  effects.clearChangesInstanceProperty();
  effects.clearChangesStaticProperty();
  effects.clearDependsOnIndexStore();
  sideEffectsTest(
      specString + "effects:no-instance,no-static;depends:no-index;", effects);

  effects = SideEffects();
  effects.clearChangesIndex();
  effects.clearDependsOnInstancePropertyStore();
  effects.clearDependsOnStaticPropertyStore();
  sideEffectsTest(
      specString + "effects:no-index;depends:no-instance,no-static;", effects);

  effects = SideEffects();
  effects.clearChangesIndex();
  sideEffectsTest(specString + "effects:no-index;depends:all;", effects);

  effects = SideEffects();
  effects.clearDependsOnIndexStore();
  sideEffectsTest(specString + "effects:all;depends:no-index;", effects);

  effects = SideEffects();
  effects.clearChangesInstanceProperty();
  effects.clearChangesStaticProperty();
  sideEffectsTest(
      specString + "effects:no-instance,no-static;depends:all;", effects);

  effects = SideEffects();
  effects.clearDependsOnInstancePropertyStore();
  effects.clearDependsOnStaticPropertyStore();
  sideEffectsTest(
      specString + "effects:all;depends:no-instance,no-static;", effects);

  sideEffectsTest(specString + "effects:no-instance,no-static;", effects,
      sideEffectsExpectError: true);

  sideEffectsTest(specString + "depends:no-instance,no-static;", effects,
      sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:none;", effects,
      sideEffectsExpectError: true);

  sideEffectsTest(specString + "depends:all;", effects,
      sideEffectsExpectError: true);

  sideEffectsTest(
      specString + "effects:no-instance,no-static;depends:foo;", effects,
      sideEffectsExpectError: true);

  sideEffectsTest(
      specString + "effects:foo;depends:no-instance,no-static;", effects,
      sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:all;depends:foo", effects,
      sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:foo;depends:none;", effects,
      sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:;depends:none;", effects,
      sideEffectsExpectError: true);

  sideEffectsTest(specString + "effects:all;depends:;", effects,
      sideEffectsExpectError: true);
}

void main() async {
  var env = await TypeEnvironment.create('');
  var types = env.types;
  test(types, 'void', returns: [], creates: []);
  test(types, '', returns: [OBJECT, NULL], creates: []);
  test(types, 'var', returns: [OBJECT, NULL], creates: []);
  test(types, 'A', returns: ['A'], creates: ['A']);
  test(types, 'A|B', returns: ['A', 'B'], creates: ['A', 'B']);
  test(types, 'A|B|C', returns: ['A', 'B', 'C'], creates: ['A', 'B', 'C']);

  test(types, 'returns:void;', returns: [], creates: []);
  test(types, 'returns:;', returns: [OBJECT, NULL], creates: []);
  test(types, 'returns:var;', returns: [OBJECT, NULL], creates: []);
  test(types, 'returns:A;', returns: ['A'], creates: ['A']);
  test(types, 'returns:A|B;', returns: ['A', 'B'], creates: ['A', 'B']);
  test(types, 'returns:A|B|C;',
      returns: ['A', 'B', 'C'], creates: ['A', 'B', 'C']);

  test(types, 'creates:void;', expectError: true);
  test(types, 'creates:;', creates: []);
  test(types, 'creates:var;', creates: []);
  test(types, 'creates:A;', returns: [], creates: ['A']);
  test(types, 'creates:A|B;', returns: [], creates: ['A', 'B']);
  test(types, 'creates:A|B|C;', returns: [], creates: ['A', 'B', 'C']);

  test(types, 'returns:void;creates:', returns: [], creates: []);
  test(types, 'returns:;creates:', returns: [OBJECT, NULL], creates: []);
  test(types, 'returns:var;creates:', returns: [OBJECT, NULL], creates: []);
  test(types, 'returns:A;creates:', returns: ['A'], creates: []);
  test(types, 'returns:A|B;creates:;', returns: ['A', 'B'], creates: []);
  test(types, 'returns:A|B|C;creates:;', returns: ['A', 'B', 'C'], creates: []);

  test(types, 'returns:void;creates:A;', returns: [], creates: ['A']);
  test(types, 'returns:;creates:A|B;',
      returns: [OBJECT, NULL], creates: ['A', 'B']);
  test(types, 'returns:var;creates:A|B|C;',
      returns: [OBJECT, NULL], creates: ['A', 'B', 'C']);
  test(types, 'returns:A; creates:A|B|C; ',
      returns: ['A'], creates: ['A', 'B', 'C']);
  test(types, ' returns:A|B;  creates:A|C;',
      returns: ['A', 'B'], creates: ['A', 'C']);
  test(types, ' returns:A|B|C;   creates:A;  ',
      returns: ['A', 'B', 'C'], creates: ['A']);

  testWithSideEffects(types, 'returns:void;', returns: [], creates: []);
  testWithSideEffects(types, 'returns:void;', returns: [], creates: []);
  testWithSideEffects(types, 'returns:;', returns: [OBJECT, NULL], creates: []);
  testWithSideEffects(types, 'returns:var;',
      returns: [OBJECT, NULL], creates: []);
  testWithSideEffects(types, 'returns:A;', returns: ['A'], creates: ['A']);
  testWithSideEffects(types, 'returns:A|B;',
      returns: ['A', 'B'], creates: ['A', 'B']);
  testWithSideEffects(types, 'returns:A|B|C;',
      returns: ['A', 'B', 'C'], creates: ['A', 'B', 'C']);
  testWithSideEffects(types, 'returns: A| B |C ;',
      returns: ['A', 'B', 'C'], creates: ['A', 'B', 'C']);

  testWithSideEffects(types, 'creates:void;', expectError: true);
  testWithSideEffects(types, 'creates:;', creates: []);
  testWithSideEffects(types, 'creates:var;', creates: []);
  testWithSideEffects(types, 'creates:A;', returns: [], creates: ['A']);
  testWithSideEffects(types, 'creates:A|B;', returns: [], creates: ['A', 'B']);
  testWithSideEffects(types, 'creates:A|B|C;',
      returns: [], creates: ['A', 'B', 'C']);

  testWithSideEffects(types, 'returns:void;creates:;',
      returns: [], creates: []);
  testWithSideEffects(types, 'returns:;creates:;',
      returns: [OBJECT, NULL], creates: []);
  testWithSideEffects(types, 'returns:var;creates:;',
      returns: [OBJECT, NULL], creates: []);
  testWithSideEffects(types, 'returns:A;creates:;',
      returns: ['A'], creates: []);
  testWithSideEffects(types, 'returns:A|B;creates:;',
      returns: ['A', 'B'], creates: []);
  testWithSideEffects(types, 'returns:A|B|C;creates:;',
      returns: ['A', 'B', 'C'], creates: []);

  testWithSideEffects(types, 'returns:void;creates:A;',
      returns: [], creates: ['A']);
  testWithSideEffects(types, 'returns:;creates:A|B;',
      returns: [OBJECT, NULL], creates: ['A', 'B']);
  testWithSideEffects(types, 'returns:var;creates:A|B|C;',
      returns: [OBJECT, NULL], creates: ['A', 'B', 'C']);
  testWithSideEffects(types, 'returns:A; creates:A|B|C; ',
      returns: ['A'], creates: ['A', 'B', 'C']);
  testWithSideEffects(types, ' returns:A|B;  creates:A|C;',
      returns: ['A', 'B'], creates: ['A', 'C']);
  testWithSideEffects(types, ' returns:A|B|C;   creates:A;  ',
      returns: ['A', 'B', 'C'], creates: ['A']);

  test(types, 'throws:may', expectedThrows: NativeThrowBehavior.may);
  test(types, 'throws:never', expectedThrows: NativeThrowBehavior.never);
  test(types, 'throws:null(1)', expectedThrows: NativeThrowBehavior.nullNsm);
  test(types, 'throws:null(1)+may',
      expectedThrows: NativeThrowBehavior.nullNsmThenMay);

  test(types, 'new:true', expectedNew: true);
  test(types, 'new:false', expectedNew: false);
  test(types, 'returns:A;new:true', returns: ['A'], expectedNew: true);
  test(types, ' new : true ;  returns:A;', returns: ['A'], expectedNew: true);
  test(types, 'new:true;returns:A;new:true', expectError: true);

  test(types, 'gvn:true', expectedGvn: true);
  test(types, 'gvn:false', expectedGvn: false);
  test(types, 'returns:A;gvn:true', returns: ['A'], expectedGvn: true);
  test(types, ' gvn : true ;  returns:A;', returns: ['A'], expectedGvn: true);
  test(types, 'gvn:true;returns:A;gvn:true', expectError: true);

  test(types, 'gvn: true; new: true', expectError: true);
  test(types, 'gvn: true; new: false', expectedGvn: true, expectedNew: false);
  test(types, 'gvn: false; new: true', expectedGvn: false, expectedNew: true);
  test(types, 'gvn: false; new: false', expectedGvn: false, expectedNew: false);
}
