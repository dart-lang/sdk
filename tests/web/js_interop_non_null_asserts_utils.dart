// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
external dynamic eval(String code);

@JS()
external String returnsNull();

@JS()
external String returnsUndefined();

@JS()
external int get getsNull;

@JS()
external int get undefinedGetter;

@JS()
external double Function() get getterFunctionReturnsNull;

@JS()
external double Function() get getterFunctionReturnsUndefined;

@JS()
external bool nullField;

@JS()
external bool undefinedField;

@JS()
@anonymous
class SomeClass {
  external String returnsNull();
  external String returnsUndefined();
  external int get getsNull;
  external int get undefinedGetter;
  external double Function() get getterFunctionReturnsNull;
  external double Function() get getterFunctionReturnsUndefined;
  external bool nullField;
  external bool undefinedField;
}

@JS()
@anonymous
class AnotherClass {
  external static String staticReturnsNull();
  external static String staticReturnsUndefined();
  external static int get staticGetsNull;
  external static int get staticUndefinedGetter;
  external static double Function() get staticGetterFunctionReturnsNull;
  external static double Function() get staticGetterFunctionReturnsUndefined;
  external static bool staticNullField;
  external static bool staticUndefinedField;
}

@JS()
class NamedClass {
  external String returnsNull();
  external String returnsUndefined();
  external static String staticReturnsNull();
  external static String staticReturnsUndefined();
  external int get getsNull;
  external int get undefinedGetter;
  external static int get staticGetsNull;
  external static int get staticUndefinedGetter;
  external double Function() get getterFunctionReturnsNull;
  external double Function() get getterFunctionReturnsUndefined;
  external static double Function() get staticGetterFunctionReturnsNull;
  external static double Function() get staticGetterFunctionReturnsUndefined;
  external bool nullField;
  external bool undefinedField;
  external static bool staticNullField;
  external static bool staticUndefinedField;

  external factory NamedClass.createNamedClass();
}

@JS()
external SomeClass createSomeClass();

void topLevelMemberTests({required bool checksEnabled}) {
  eval(r'self.returnsNull = function() { return null; }');
  Expect.throwsTypeErrorWhen(checksEnabled, () => returnsNull());

  eval(r'self.returnsUndefined = function() { return void 0; }');
  Expect.throwsTypeErrorWhen(checksEnabled, () => returnsUndefined());

  var functionTearoff = returnsNull;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  functionTearoff = returnsUndefined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());

  eval(r'self.getsNull = null;');
  Expect.throwsTypeErrorWhen(checksEnabled, () => getsNull);
  Expect.throwsTypeErrorWhen(checksEnabled, () => undefinedGetter);

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  eval(r'self.getterFunctionReturnsNull = function() { return null; };');
  Expect.isNull(getterFunctionReturnsNull());
  var getterFunction = getterFunctionReturnsNull;
  Expect.isNull(getterFunction());

  eval(r'self.getterFunctionReturnsUndefined = function() { '
      'return void 0; };');
  Expect.isNull(getterFunctionReturnsUndefined());
  getterFunction = getterFunctionReturnsUndefined;
  Expect.isNull(getterFunction());

  eval(r'self.nullField = null;');
  Expect.throwsTypeErrorWhen(checksEnabled, () => nullField);
  Expect.throwsTypeErrorWhen(checksEnabled, () => undefinedField);
}

void anonymousClassTests({required bool checksEnabled}) {
  eval(r'''self.createSomeClass = function() {
        return {
          "returnsNull": function() { return null; },
          "returnsUndefined": function() { return void 0; },
          "getsNull" : null,
          "jsGetsNull": { get: function() { return null; } },
          "jsGetsUndefined": { get: function() { return void 0; } },
          "getterFunctionReturnsNull": function() { return null; },
          "getterFunctionReturnsUndefined": function() { return void 0; },
          "nullField" : null,
        };
      };
      ''');

  var x = createSomeClass();
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.returnsNull());
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.returnsUndefined());
  var functionTearoff = x.returnsNull;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  functionTearoff = x.returnsUndefined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.getsNull);
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.undefinedGetter);

  // Immediate invocations of instance getters are seen as function calls so
  // the results get checked.
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => x.getterFunctionReturnsNull());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => x.getterFunctionReturnsUndefined());

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  var getterFunction = x.getterFunctionReturnsNull;
  Expect.isNull(getterFunction());
  getterFunction = x.getterFunctionReturnsUndefined;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(checksEnabled, () => x.nullField);
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.undefinedField);

  eval(r'''self.AnotherClass = class AnotherClass {
          static staticReturnsNull() { return null; }
          static staticReturnsUndefined() { return void 0; }
          static get staticGetsNull() { return null; }
          static get staticGetterFunctionReturnsNull() {
            return function() { return null; };
          }
          static get staticGetterFunctionReturnsUndefined() {
            return function() { return void 0; };
          }
      };''');

  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticReturnsNull());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticReturnsUndefined());
  functionTearoff = AnotherClass.staticReturnsNull;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  functionTearoff = AnotherClass.staticReturnsUndefined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  Expect.throwsTypeErrorWhen(checksEnabled, () => AnotherClass.staticGetsNull);
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticUndefinedGetter);

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  Expect.isNull(AnotherClass.staticGetterFunctionReturnsNull());
  Expect.isNull(AnotherClass.staticGetterFunctionReturnsUndefined());
  getterFunction = AnotherClass.staticGetterFunctionReturnsNull;
  Expect.isNull(getterFunction());
  getterFunction = AnotherClass.staticGetterFunctionReturnsUndefined;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(checksEnabled, () => AnotherClass.staticNullField);
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticUndefinedField);
}

void namedClassTests({required bool checksEnabled}) {
  eval(r'''self.NamedClass = class NamedClass {
          returnsNull() { return null; }
          returnsUndefined() { return void 0; }
          static staticReturnsNull() { return null; }
          static staticReturnsUndefined() { return void 0; }
          get getsNull() { return null; }
          static get staticGetsNull() { return null; }
          get getterFunctionReturnsNull() {
            return function() { return null; };
          }
          get getterFunctionReturnsUndefined() {
            return function() { return void 0; };
          }
          static get staticGetterFunctionReturnsNull() {
            return function() { return null; };
          }
          static get staticGetterFunctionReturnsUndefined() {
            return function() { return void 0; };
          }
          static createNamedClass() { return new NamedClass(); }
      };''');

  var y = NamedClass.createNamedClass();
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.returnsNull());
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.returnsUndefined());
  var functionTearoff = y.returnsNull;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  functionTearoff = y.returnsUndefined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticReturnsNull());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticReturnsUndefined());
  functionTearoff = NamedClass.staticReturnsNull;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  functionTearoff = NamedClass.staticReturnsUndefined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.getsNull);
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.undefinedGetter);
  // Immediate invocations of instance getters are seen as function calls so
  // the results get checked.
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => y.getterFunctionReturnsNull());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => y.getterFunctionReturnsUndefined());
  Expect.throwsTypeErrorWhen(checksEnabled, () => NamedClass.staticGetsNull);
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticUndefinedGetter);

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  var getterFunction = y.getterFunctionReturnsNull;
  Expect.isNull(getterFunction());
  getterFunction = y.getterFunctionReturnsNull;
  Expect.isNull(getterFunction());
  Expect.isNull(NamedClass.staticGetterFunctionReturnsNull());
  Expect.isNull(NamedClass.staticGetterFunctionReturnsUndefined());
  getterFunction = NamedClass.staticGetterFunctionReturnsNull;
  Expect.isNull(getterFunction());
  getterFunction = NamedClass.staticGetterFunctionReturnsUndefined;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(checksEnabled, () => y.nullField);
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.undefinedField);
  Expect.throwsTypeErrorWhen(checksEnabled, () => NamedClass.staticNullField);
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticUndefinedField);
}
