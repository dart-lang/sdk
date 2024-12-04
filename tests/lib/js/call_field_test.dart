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

@JS()
class NamedClass {
  external int Function(String s) call;
}

@JS('jsFunction')
external NamedClass get jsFunctionAsNamedClass;

@JS('jsObject')
external NamedClass get jsObjectAsNamedClass;

@JS('jsClass')
external NamedClass get jsClassAsNamedClass;

@JS()
class NamedClass2 {
  external Function call;
}

@JS('jsFunction')
external NamedClass2 get functionAsNamedClass2;

@JS('jsObject')
external NamedClass2 get jsObjectAsNamedClass2;

@JS('jsClass')
external NamedClass2 get jsClassAsNamedClass2;

@JS()
@anonymous
class SomeClass {
  external int Function(String s) call;
}

@JS('jsFunction')
external SomeClass get functionAsSomeClass;

@JS('jsObject')
external SomeClass get jsObjectAsSomeClass;

@JS('jsClass')
external SomeClass get jsClassAsSomeClass;

@JS()
@anonymous
class SomeClass2 {
  external Function call;
}

@JS('jsFunction')
external SomeClass2 get functionAsSomeClass2;

@JS('jsObject')
external SomeClass2 get jsObjectAsSomeClass2;

@JS('jsClass')
external SomeClass2 get jsClassAsSomeClass2;

void main() {
  injectJS();
  testNamedClass();
  testNamedClass2();
  testAnonymous();
  testAnonymous2();
  testDynamic();
}

void testNamedClass() {
  var obj = jsFunctionAsNamedClass;
  Expect.equals('C', obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.equals('C', (obj.call)('Cello'));
  }

  obj = jsObjectAsNamedClass;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }

  obj = jsClassAsNamedClass;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
}

void testNamedClass2() {
  var obj = functionAsNamedClass2;
  Expect.equals('C', obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.equals('C', (obj.call)('Cello'));
  }

  obj = jsObjectAsNamedClass2;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }

  obj = jsClassAsNamedClass2;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
}

void testAnonymous() {
  var obj = functionAsSomeClass;
  Expect.equals('C', obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.equals('C', (obj.call)('Cello'));
  }

  obj = jsObjectAsSomeClass;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }

  obj = jsClassAsSomeClass;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
}

void testAnonymous2() {
  var obj = functionAsSomeClass2;
  Expect.equals('C', obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.equals('C', (obj.call)('Cello'));
  }

  obj = jsObjectAsSomeClass2;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }

  obj = jsClassAsSomeClass2;
  Expect.throwsNoSuchMethodError(() => obj.call('Cello'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => obj.call);
  } else {
    Expect.throwsNoSuchMethodError(() => (obj.call)('Cello'));
  }
}

void testDynamic() {
  var d = confuse(jsFunctionAsNamedClass);
  Expect.equals('F', d.call('Fosse'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => d.call);
  } else {
    Expect.equals('F', (d.call)('Fosse'));
  }
  Expect.equals('F', d('Fosse'));

  d = confuse(jsObjectAsNamedClass);
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => d.call);
  } else {
    Expect.equals('F', (d.call)('Fosse'));
  }
  Expect.throwsNoSuchMethodError(() => d('Fosse'));

  d = confuse(jsClassAsNamedClass);
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  if (dart2js) {
    Expect.throwsNoSuchMethodError(() => d.call);
  } else {
    Expect.throws(() => (d.call)('Fosse'), jsThisIsNullCheck);
  }
  Expect.throwsNoSuchMethodError(() => d('Fosse'));
}
