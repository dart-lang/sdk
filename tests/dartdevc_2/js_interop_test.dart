// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

@JS()
library js_interop_test;

import 'dart:_foreign_helper' as helper show JS;
import 'dart:_runtime' as dart;
import 'dart:js' show context;

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
class Console {
  @JS()
  external void log(arg);
}

@JS('console')
external Console get console;

@JS('console.log')
external void log(String s);

String dartStaticMethod() => 'hello';

@JS('jsStaticVariable')
external set _jsStaticVariable(Function f);

@JS('jsStaticVariable')
external void jsStaticVariable(String s);

@JS('jsStaticFunction')
external set _jsStaticFunction(Function f);

@JS('jsStaticFunction')
external void jsStaticFunction(String Function() f);

@JS()
class SomeClass {
  external factory SomeClass(String Function() f);
  external set jsFunctionFieldSetter(String Function() f);
  external void Function(String Function() f) get jsFunctionFieldGetter;
  external String jsInstanceMethod(String Function() f);

  external NestedJs get jsNonFunctionField;
}

@JS()
@anonymous
class NestedJs {
  external factory NestedJs({String Function() constructorArg});
  external String get stringField;
}

@JS('someClass')
external set _someClass(dynamic s);
@JS('someClass')
external SomeClass get someClass;

void main() {
  Function(String) jsFunc = helper.JS('', '(x) => {}');
  Expect.equals(dart.assertInterop(jsFunc), jsFunc);

  Expect.equals(dart.assertInterop(log), log);
  Expect.equals(dart.assertInterop(console.log), console.log);
  Expect.throws(() => dart.assertInterop(dartStaticMethod));

  Expect.isNull(jsStaticVariable);
  _jsStaticVariable = jsFunc;
  Expect.isNotNull(jsStaticVariable);
  Expect.equals(dart.assertInterop(jsStaticVariable), jsStaticVariable);

  final dynamic wrappedDartStaticMethod = allowInterop(dartStaticMethod);

  final Function localNonNullLegacy = () => 'hello';
  final String Function() localNonNull = () => 'hello';

  // Assigment to JS static field.
  Expect.throws(() {
    _jsStaticVariable = () => 'hello';
  });
  Expect.throws(() {
    _jsStaticVariable = dartStaticMethod;
  });
  Expect.throws(() {
    _jsStaticVariable = localNonNullLegacy;
  });
  Expect.throws(() {
    _jsStaticVariable = localNonNull;
  });
  _jsStaticVariable = allowInterop(dartStaticMethod);
  _jsStaticVariable = wrappedDartStaticMethod;

  // Argument to static JS function.
  Function(Function(String), String) jsFunc2 = helper.JS('', '(f) => f()');
  _jsStaticFunction = jsFunc2;
  Expect.throws(() {
    jsStaticFunction(() => 'hello');
  });
  Expect.throws(() {
    jsStaticFunction(dartStaticMethod);
  });
  Expect.throws(() {
    jsStaticFunction(localNonNullLegacy);
  });
  Expect.throws(() {
    jsStaticFunction(localNonNull);
  });
  jsStaticFunction(allowInterop(() => 'hello'));
  jsStaticFunction(wrappedDartStaticMethod);

  // Argument to torn off static JS function
  dynamic method = jsStaticFunction;
  Expect.throws(() {
    method(() => 'hello');
  });
  Expect.throws(() {
    method(dartStaticMethod);
  });
  Expect.throws(() {
    method(localNonNullLegacy);
  });
  Expect.throws(() {
    method(localNonNull);
  });
  method(allowInterop(() => 'hello'));
  method(wrappedDartStaticMethod);

  // Assignment to instance field.
  _someClass = helper.JS(
      '',
      '{"jsInstanceMethod": function(f) {return f();}, '
          '"jsNonFunctionField": {"stringField":"hello js"}, '
          '"jsFunctionFieldGetter": function(f) {return f();}}');
  Expect.throws((() {
    someClass.jsFunctionFieldSetter = () => 'hello';
  }));
  Expect.throws((() {
    someClass.jsFunctionFieldSetter = dartStaticMethod;
  }));
  Expect.throws((() {
    someClass.jsFunctionFieldSetter = localNonNullLegacy;
  }));
  Expect.throws((() {
    someClass.jsFunctionFieldSetter = localNonNull;
  }));
  someClass.jsFunctionFieldSetter = allowInterop(() => 'hello');
  someClass.jsFunctionFieldSetter = wrappedDartStaticMethod;

  // Argument to instance method.
  Expect.throws(() {
    someClass.jsInstanceMethod(() => 'hello');
  });
  Expect.throws(() {
    someClass.jsInstanceMethod(dartStaticMethod);
  });
  Expect.throws(() {
    someClass.jsInstanceMethod(localNonNullLegacy);
  });
  Expect.throws(() {
    someClass.jsInstanceMethod(localNonNull);
  });
  someClass.jsInstanceMethod(allowInterop(() => 'hello'));
  someClass.jsInstanceMethod(wrappedDartStaticMethod);

  // Argument to  constructor.
  context.callMethod('eval', ['function SomeClass(a) { a(); }']);
  Expect.throws(() {
    SomeClass(() => 'hello');
  });
  Expect.throws(() {
    SomeClass(dartStaticMethod);
  });
  Expect.throws(() {
    SomeClass(localNonNullLegacy);
  });
  Expect.throws(() {
    SomeClass(localNonNull);
  });
  SomeClass(allowInterop(() => 'hello'));
  SomeClass(wrappedDartStaticMethod);

  // Argument to anonymous constructor.
  Expect.throws(() {
    NestedJs(constructorArg: () => 'hello');
  });
  Expect.throws(() {
    NestedJs(constructorArg: dartStaticMethod);
  });
  Expect.throws(() {
    NestedJs(constructorArg: localNonNullLegacy);
  });
  Expect.throws(() {
    NestedJs(constructorArg: localNonNull);
  });
  NestedJs(constructorArg: allowInterop(() => 'hello'));
  NestedJs(constructorArg: wrappedDartStaticMethod);

  // Argument to torn off instance method.
  method = someClass.jsInstanceMethod;
  Expect.throws(() {
    method(() => 'hello');
  });
  Expect.throws(() {
    method(dartStaticMethod);
  });
  Expect.throws(() {
    method(localNonNullLegacy);
  });
  Expect.throws(() {
    method(localNonNull);
  });
  method(allowInterop(() => 'hello'));
  method(wrappedDartStaticMethod);

  // Function typed getter
  Expect.throws(() {
    someClass.jsFunctionFieldGetter(() => 'hello');
  });
  Expect.throws(() {
    someClass.jsFunctionFieldGetter(dartStaticMethod);
  });
  Expect.throws(() {
    someClass.jsFunctionFieldGetter(localNonNullLegacy);
  });
  Expect.throws(() {
    someClass.jsFunctionFieldGetter(localNonNull);
  });
  someClass.jsFunctionFieldGetter(allowInterop(() => 'hello'));
  someClass.jsFunctionFieldGetter(wrappedDartStaticMethod);

  // Stored Function typed getter
  method = someClass.jsFunctionFieldGetter;
  // We lose safety after calling a getter that returns a function, which takes
  // a function as an argument. Since this can be modeled with a method, isntead
  // of a getter returning a function, we don't expect this is a pattern likely
  // to show up in real code.
  //Expect.throws(() {
  //  method(() => 'hello');
  //});
  //Expect.throws(() {
  //  method(dartStaticMethod);
  //});
  //Expect.throws(() {
  //  method(localNonNullLegacy);
  //});
  //Expect.throws(() {
  //  method(localNonNull);
  //});
  method(allowInterop(() => 'hello'));
  method(wrappedDartStaticMethod);

  // Non-function fields
  Expect.equals('hello js', someClass.jsNonFunctionField.stringField,
      'Does not wrap access to a field');
}
