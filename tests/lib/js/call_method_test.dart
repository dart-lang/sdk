// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// WARNING
///
/// Not all of the expectations in this test match the language specification.
///
/// This is part of a set of tests covering "callable objects". Please consider
/// them all together when making changes:
///
/// ```
/// tests/lib/js/call_field_test.dart
/// tests/lib/js/call_getter_test.dart
/// tests/lib/js/call_method_test.dart
/// ```
///
/// This test was created with expectations that match the current behavior to
/// make it more clear when something changes and when the results in the web
/// compilers differ.
///
/// If your change causes an expectation to fail you should decide if the
/// new result is desirable and update the expectation accordingly.

import 'package:expect/expect.dart';
import 'package:js/js.dart';

import 'call_utils.dart';

@JS('jsFunction')
external int Function(String) jsFunctionAsFunction;

@JS('jsObject')
external int Function(String) jsObjectAsFunction;

@JS('jsClass')
external int Function(String) jsClassAsFunction;

@JS('jsFunction')
external Function jsFunctionAsFunctionInterface;

@JS('jsObject')
external Function jsObjectAsFunctionInterface;

@JS('jsClass')
external Function jsClassAsFunctionInterface;

@JS()
class NamedClass {
  external int call(String s);
}

@JS('jsFunction')
external NamedClass get functionAsNamedClass;

@JS('jsObject')
external NamedClass get jsObjectAsNamedClass;

@JS('jsClass')
external NamedClass get jsClassAsNamedClass;

@JS()
@anonymous
class SomeClass {
  external int call(String s);
}

@JS('jsFunction')
external SomeClass get functionAsSomeClass;

@JS('jsObject')
external SomeClass get jsObjectAsSomeClass;

@JS('jsClass')
external SomeClass get jsClassAsSomeClass;

void main() {
  injectJS();
  testFunction();
  testFunctionInterface();
  testNamedClass();
  testAnonymous();
  testDynamic();
}

void testFunction() {
  var obj = jsFunctionAsFunction;
  Expect.equals('C', obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.equals('C', (obj.call)('Cello'));
  }
  Expect.equals('C', obj('Cello'));

  obj = jsObjectAsFunction;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
  Expect.throwsNoSuchMethodError(() => obj('Cello'));

  obj = jsClassAsFunction;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
  Expect.throwsNoSuchMethodError(() => obj('Cello'));
}

void testFunctionInterface() {
  var obj = jsFunctionAsFunctionInterface;
  Expect.equals('C', obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.equals('C', (obj.call)('Cello'));
  }
  Expect.equals('C', obj('Cello'));

  obj = jsObjectAsFunctionInterface;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.equals('C', (obj.call)('Cello'));
  }
  Expect.throwsNoSuchMethodError(() => obj('Cello'));

  obj = jsClassAsFunctionInterface;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throws(() => (obj.call)('Cello'), jsThisIsNullCheck);
  }
  Expect.throwsNoSuchMethodError(() => obj('Cello'));
}

void testNamedClass() {
  var obj = functionAsNamedClass;
  Expect.equals('C', obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.equals('C', (obj.call)('Cello'));
  }
  Expect.equals('C', obj('Cello'));

  obj = jsObjectAsNamedClass;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
  Expect.throwsNoSuchMethodError(() => obj('Cello'));

  obj = jsClassAsNamedClass;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => (obj.call));
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
  Expect.throwsNoSuchMethodError(() => obj('Cello'));
}

void testAnonymous() {
  var obj = functionAsSomeClass;
  Expect.equals('C', obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.equals('C', (obj.call)('Cello'));
  }
  Expect.equals('C', obj('Cello'));

  obj = jsObjectAsSomeClass;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
  Expect.throwsNoSuchMethodError(() => obj('Cello'));

  obj = jsClassAsSomeClass;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
  Expect.throwsNoSuchMethodError(() => obj('Cello'));
}

void testDynamic() {
  var d = confuse(jsFunctionAsFunction);
  Expect.equals('F', d.call('Fosse'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => d.call);
  } else {
    Expect.equals('F', (d.call)('Fosse'));
  }
  Expect.equals('F', d('Fosse'));

  d = confuse(jsClassAsFunction);
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => d.call);
  } else {
    Expect.throws(() => (d.call)('Fosse'), jsThisIsNullCheck);
  }
  Expect.throwsNoSuchMethodError(() => d('Fosse'));

  d = confuse(jsObjectAsFunction);
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => d.call);
  } else {
    Expect.equals('F', (d.call)('Fosse'));
  }
  Expect.throwsNoSuchMethodError(() => d('Fosse'));
}
