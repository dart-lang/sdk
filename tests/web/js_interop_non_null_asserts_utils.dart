// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:js/js.dart';

const dart2js = const bool.fromEnvironment('dart.library._dart2js_only');
const ddc = const bool.fromEnvironment('dart.library._ddc_only');

dynamic obj;

@JS()
external dynamic eval(String code);

@JS()
@pragma('dart2js:never-inline')
external String returnsNull();

@JS()
@pragma('dart2js:prefer-inline')
external String returnsNullInlined();

@JS()
@pragma('dart2js:never-inline')
external String returnsUndefined();

@JS()
@pragma('dart2js:prefer-inline')
external String returnsUndefinedInlined();

@JS()
@pragma('dart2js:never-inline')
external int get getsNull;

@JS()
@pragma('dart2js:prefer-inline')
external int get getsNullInlined;

@JS()
@pragma('dart2js:never-inline')
external int get undefinedGetter;

@JS()
@pragma('dart2js:prefer-inline')
external int get undefinedGetterInlined;

@JS()
@pragma('dart2js:never-inline')
external double Function() get getterFunctionReturnsNull;

@JS()
@pragma('dart2js:prefer-inline')
external double Function() get getterFunctionReturnsNullInlined;

@JS()
@pragma('dart2js:never-inline')
external double Function() get getterFunctionReturnsUndefined;

@JS()
@pragma('dart2js:prefer-inline')
external double Function() get getterFunctionReturnsUndefinedInlined;

@JS()
@pragma('dart2js:never-inline')
external bool nullField;

@JS()
@pragma('dart2js:prefer-inline')
external bool nullFieldInlined;

@JS()
@pragma('dart2js:never-inline')
external bool undefinedField;

@JS()
@pragma('dart2js:prefer-inline')
external bool undefinedFieldInlined;

@JS()
@pragma('dart2js:never-inline')
external int? nullableFunction();

@JS()
@pragma('dart2js:prefer-inline')
external int? nullableFunctionInlined();

@JS()
@pragma('dart2js:never-inline')
external int? get nullableGetter;

@JS()
@pragma('dart2js:prefer-inline')
external int? get nullableGetterInlined;

@JS()
@pragma('dart2js:never-inline')
external int? nullableField;

@JS()
@pragma('dart2js:prefer-inline')
external int? nullableFieldInlined;

@JS()
@anonymous
class SomeClass {
  @pragma('dart2js:never-inline')
  external String returnsNull();

  @pragma('dart2js:prefer-inline')
  external String returnsNullInlined();

  @pragma('dart2js:never-inline')
  external String returnsUndefined();

  @pragma('dart2js:prefer-inline')
  external String returnsUndefinedInlined();

  @pragma('dart2js:never-inline')
  external int get getsNull;

  @pragma('dart2js:prefer-inline')
  external int get getsNullInlined;

  @pragma('dart2js:never-inline')
  external int get undefinedGetter;

  @pragma('dart2js:prefer-inline')
  external int get undefinedGetterInlined;

  @pragma('dart2js:never-inline')
  external double Function() get getterFunctionReturnsNull;

  @pragma('dart2js:prefer-inline')
  external double Function() get getterFunctionReturnsNullInlined;

  @pragma('dart2js:never-inline')
  external double Function() get getterFunctionReturnsUndefined;

  @pragma('dart2js:prefer-inline')
  external double Function() get getterFunctionReturnsUndefinedInlined;

  @pragma('dart2js:never-inline')
  external bool nullField;

  @pragma('dart2js:prefer-inline')
  external bool nullFieldInlined;

  @pragma('dart2js:never-inline')
  external bool undefinedField;

  @pragma('dart2js:prefer-inline')
  external bool undefinedFieldInlined;

  @pragma('dart2js:never-inline')
  external int? nullableFunction();

  @pragma('dart2js:prefer-inline')
  external int? nullableFunctionInlined();

  @pragma('dart2js:never-inline')
  external int? get nullableGetter;

  @pragma('dart2js:prefer-inline')
  external int? get nullableGetterInlined;

  @pragma('dart2js:never-inline')
  external int? nullableField;

  @pragma('dart2js:prefer-inline')
  external int? nullableFieldInlined;
}

@JS()
@anonymous
class AnotherClass {
  @pragma('dart2js:never-inline')
  external static String staticReturnsNull();

  @pragma('dart2js:prefer-inline')
  external static String staticReturnsNullInlined();

  @pragma('dart2js:never-inline')
  external static String staticReturnsUndefined();

  @pragma('dart2js:prefer-inline')
  external static String staticReturnsUndefinedInlined();

  @pragma('dart2js:never-inline')
  external static int get staticGetsNull;

  @pragma('dart2js:prefer-inline')
  external static int get staticGetsNullInlined;

  @pragma('dart2js:never-inline')
  external static int get staticUndefinedGetter;

  @pragma('dart2js:prefer-inline')
  external static int get staticUndefinedGetterInlined;

  @pragma('dart2js:never-inline')
  external static double Function() get staticGetterFunctionReturnsNull;

  @pragma('dart2js:prefer-inline')
  external static double Function() get staticGetterFunctionReturnsNullInlined;

  @pragma('dart2js:never-inline')
  external static double Function() get staticGetterFunctionReturnsUndefined;

  @pragma('dart2js:prefer-inline')
  external static double Function()
      get staticGetterFunctionReturnsUndefinedInlined;

  @pragma('dart2js:never-inline')
  external static bool staticNullField;

  @pragma('dart2js:prefer-inline')
  external static bool staticNullFieldInlined;

  @pragma('dart2js:never-inline')
  external static bool staticUndefinedField;

  @pragma('dart2js:prefer-inline')
  external static bool staticUndefinedFieldInlined;

  @pragma('dart2js:never-inline')
  external static int? staticNullableFunction();

  @pragma('dart2js:prefer-inline')
  external static int? staticNullableFunctionInlined();

  @pragma('dart2js:never-inline')
  external static int? get staticNullableGetter;

  @pragma('dart2js:prefer-inline')
  external static int? get staticNullableGetterInlined;

  @pragma('dart2js:never-inline')
  external static int? staticNullableField;

  @pragma('dart2js:prefer-inline')
  external static int? staticNullableFieldInlined;
}

@JS()
class NamedClass {
  @pragma('dart2js:never-inline')
  external String returnsNull();

  @pragma('dart2js:prefer-inline')
  external String returnsNullInlined();

  @pragma('dart2js:never-inline')
  external String returnsUndefined();

  @pragma('dart2js:prefer-inline')
  external String returnsUndefinedInlined();

  @pragma('dart2js:never-inline')
  external static String staticReturnsNull();

  @pragma('dart2js:prefer-inline')
  external static String staticReturnsNullInlined();

  @pragma('dart2js:never-inline')
  external static String staticReturnsUndefined();

  @pragma('dart2js:prefer-inline')
  external static String staticReturnsUndefinedInlined();

  @pragma('dart2js:never-inline')
  external int get getsNull;

  @pragma('dart2js:prefer-inline')
  external int get getsNullInlined;

  @pragma('dart2js:never-inline')
  external int get undefinedGetter;

  @pragma('dart2js:prefer-inline')
  external int get undefinedGetterInlined;

  @pragma('dart2js:never-inline')
  external static int get staticGetsNull;

  @pragma('dart2js:prefer-inline')
  external static int get staticGetsNullInlined;

  @pragma('dart2js:never-inline')
  external static int get staticUndefinedGetter;

  @pragma('dart2js:prefer-inline')
  external static int get staticUndefinedGetterInlined;

  @pragma('dart2js:never-inline')
  external double Function() get getterFunctionReturnsNull;

  @pragma('dart2js:prefer-inline')
  external double Function() get getterFunctionReturnsNullInlined;

  @pragma('dart2js:never-inline')
  external double Function() get getterFunctionReturnsUndefined;

  @pragma('dart2js:prefer-inline')
  external double Function() get getterFunctionReturnsUndefinedInlined;

  @pragma('dart2js:never-inline')
  external static double Function() get staticGetterFunctionReturnsNull;

  @pragma('dart2js:prefer-inline')
  external static double Function() get staticGetterFunctionReturnsNullInlined;

  @pragma('dart2js:never-inline')
  external static double Function() get staticGetterFunctionReturnsUndefined;

  @pragma('dart2js:prefer-inline')
  external static double Function()
      get staticGetterFunctionReturnsUndefinedInlined;

  @pragma('dart2js:never-inline')
  external bool nullField;

  @pragma('dart2js:prefer-inline')
  external bool nullFieldInlined;

  @pragma('dart2js:never-inline')
  external bool undefinedField;

  @pragma('dart2js:prefer-inline')
  external bool undefinedFieldInlined;

  @pragma('dart2js:never-inline')
  external int? nullableFunction();

  @pragma('dart2js:prefer-inline')
  external int? nullableFunctionInlined();

  @pragma('dart2js:never-inline')
  external int? get nullableGetter;

  @pragma('dart2js:prefer-inline')
  external int? get nullableGetterInlined;

  @pragma('dart2js:never-inline')
  external int? nullableField;

  @pragma('dart2js:prefer-inline')
  external int? nullableFieldInlined;

  @pragma('dart2js:never-inline')
  external static bool staticNullField;

  @pragma('dart2js:prefer-inline')
  external static bool staticNullFieldInlined;

  @pragma('dart2js:never-inline')
  external static bool staticUndefinedField;

  @pragma('dart2js:prefer-inline')
  external static bool staticUndefinedFieldInlined;

  @pragma('dart2js:never-inline')
  external static int? staticNullableFunction();

  @pragma('dart2js:prefer-inline')
  external static int? staticNullableFunctionInlined();

  @pragma('dart2js:never-inline')
  external static int? get staticNullableGetter;

  @pragma('dart2js:prefer-inline')
  external static int? get staticNullableGetterInlined;

  @pragma('dart2js:never-inline')
  external static int? staticNullableField;

  @pragma('dart2js:prefer-inline')
  external static int? staticNullableFieldInlined;

  external factory NamedClass.createNamedClass();
}

@JS()
external SomeClass createSomeClass();

void topLevelMemberTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

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

  eval(r'self.nullableFunction = function() { return null; };');
  Expect.isNull(nullableFunction());

  eval(r'self.nullableGetter = null;');
  Expect.isNull(nullableGetter);

  eval(r'self.nullableField = null;');
  Expect.isNull(nullableField);
}

void inlinedTopLevelMemberTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  eval(r'self.returnsNullInlined = function() { return null; }');
  Expect.throwsTypeErrorWhen(checksEnabled, () => returnsNullInlined());

  eval(r'self.returnsUndefinedInlined = function() { return void 0; }');
  Expect.throwsTypeErrorWhen(checksEnabled, () => returnsUndefinedInlined());

  var functionTearoff = returnsNullInlined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  functionTearoff = returnsUndefinedInlined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());

  eval(r'self.getsNullInlined = null;');
  Expect.throwsTypeErrorWhen(checksEnabled, () => getsNullInlined);
  Expect.throwsTypeErrorWhen(checksEnabled, () => undefinedGetterInlined);

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  eval(r'self.getterFunctionReturnsNullInlined = function() { return null; };');
  Expect.isNull(getterFunctionReturnsNullInlined());
  var getterFunction = getterFunctionReturnsNullInlined;
  Expect.isNull(getterFunction());

  eval(r'self.getterFunctionReturnsUndefinedInlined = function() { '
      'return void 0; };');
  Expect.isNull(getterFunctionReturnsUndefinedInlined());
  getterFunction = getterFunctionReturnsUndefinedInlined;
  Expect.isNull(getterFunction());

  eval(r'self.nullFieldInlined = null;');
  Expect.throwsTypeErrorWhen(checksEnabled, () => nullFieldInlined);
  Expect.throwsTypeErrorWhen(checksEnabled, () => undefinedFieldInlined);

  eval(r'self.nullableFunctionInlined = function() { return null; };');
  Expect.isNull(nullableFunctionInlined());

  eval(r'self.nullableGetterInlined = null;');
  Expect.isNull(nullableGetterInlined);

  eval(r'self.nullableFieldInlined = null;');
  Expect.isNull(nullableFieldInlined);
}

void anonymousClassSetup() {
  eval(r'''self.createSomeClass = function() {
        return {
          "returnsNull": function() { return null; },
          "returnsNullInlined": function() { return null; },
          "returnsUndefined": function() { return void 0; },
          "returnsUndefinedInlined": function() { return void 0; },
          "getsNull" : null,
          "getsNullInlined" : null,
          "jsGetsNull": { get: function() { return null; } },
          "jsGetsNullInlined": { get: function() { return null; } },
          "jsGetsUndefined": { get: function() { return void 0; } },
          "jsGetsUndefinedInlined": { get: function() { return void 0; } },
          "getterFunctionReturnsNull": function() { return null; },
          "getterFunctionReturnsNullInlined": function() { return null; },
          "getterFunctionReturnsUndefined": function() { return void 0; },
          "getterFunctionReturnsUndefinedInlined": function() { return void 0; },
          "nullField" : null,
          "nullFieldInlined" : null,
          "nullableFunction": function() { return null; },
          "nullableFunctionInlined": function() { return null; },
          "nullableGetter": null,
          "nullableGetterInlined": null,
          "nullableField": null,
          "nullableFieldInlined": null,
        };
      };
      ''');

  eval(r'''self.AnotherClass = class AnotherClass {
          static staticReturnsNull() { return null; }
          static staticReturnsNullInlined() { return null; }
          static staticReturnsUndefined() { return void 0; }
          static staticReturnsUndefinedInlined() { return void 0; }
          static get staticGetsNull() { return null; }
          static get staticGetsNullInlined() { return null; }
          static get staticGetterFunctionReturnsNull() {
            return function() { return null; };
          }
          static get staticGetterFunctionReturnsNullInlined() {
            return function() { return null; };
          }
          static get staticGetterFunctionReturnsUndefined() {
            return function() { return void 0; };
          }
          static get staticGetterFunctionReturnsUndefinedInlined() {
            return function() { return void 0; };
          }
          static staticNullableFunction() { return null; }
          static staticNullableFunctionInlined() { return null; }
          static get staticNullableGetter() { return null; }
          static get staticNullableGetterInlined() { return null; }
          static staticNullableField = null;
          static staticNullableFieldInlined = null;
      };''');
}

void anonymousClassTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  var x = createSomeClass();
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.returnsNull());
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.returnsUndefined());

  // In dart2js, a tearoff of an interop method is indistinguishable from a
  // getter returning the underlying function.
  var functionTearoff = x.returnsNull;
  Expect.throwsTypeErrorWhen(ddc && checksEnabled, () => functionTearoff());
  functionTearoff = x.returnsUndefined;
  Expect.throwsTypeErrorWhen(ddc && checksEnabled, () => functionTearoff());

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

  Expect.isNull(x.nullableFunction());
  Expect.isNull(x.nullableGetter);
  Expect.isNull(x.nullableField);

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

  Expect.isNull(AnotherClass.staticNullableFunction());
  Expect.isNull(AnotherClass.staticNullableGetter);
  Expect.isNull(AnotherClass.staticNullableField);
}

void inlinedAnonymousClassTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  var x = createSomeClass();
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.returnsNullInlined());
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.returnsUndefinedInlined());

  // In dart2js, a tearoff of an interop method is indistinguishable from a
  // getter returning the underlying function.
  var functionTearoff = x.returnsNullInlined;
  Expect.throwsTypeErrorWhen(ddc && checksEnabled, () => functionTearoff());
  functionTearoff = x.returnsUndefinedInlined;
  Expect.throwsTypeErrorWhen(ddc && checksEnabled, () => functionTearoff());

  Expect.throwsTypeErrorWhen(checksEnabled, () => x.getsNullInlined);
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.undefinedGetterInlined);

  // Immediate invocations of instance getters are seen as function calls so
  // the results get checked.
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => x.getterFunctionReturnsNullInlined());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => x.getterFunctionReturnsUndefinedInlined());

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  var getterFunction = x.getterFunctionReturnsNullInlined;
  Expect.isNull(getterFunction());
  getterFunction = x.getterFunctionReturnsUndefinedInlined;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(checksEnabled, () => x.nullFieldInlined);
  Expect.throwsTypeErrorWhen(checksEnabled, () => x.undefinedFieldInlined);

  Expect.isNull(x.nullableFunctionInlined());
  Expect.isNull(x.nullableGetterInlined);
  Expect.isNull(x.nullableFieldInlined);

  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticReturnsNullInlined());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticReturnsUndefinedInlined());
  functionTearoff = AnotherClass.staticReturnsNullInlined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  functionTearoff = AnotherClass.staticReturnsUndefinedInlined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticGetsNullInlined);
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticUndefinedGetterInlined);

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  Expect.isNull(AnotherClass.staticGetterFunctionReturnsNullInlined());
  Expect.isNull(AnotherClass.staticGetterFunctionReturnsUndefinedInlined());
  getterFunction = AnotherClass.staticGetterFunctionReturnsNullInlined;
  Expect.isNull(getterFunction());
  getterFunction = AnotherClass.staticGetterFunctionReturnsUndefinedInlined;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticNullFieldInlined);
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => AnotherClass.staticUndefinedFieldInlined);

  Expect.isNull(AnotherClass.staticNullableFunctionInlined());
  Expect.isNull(AnotherClass.staticNullableGetterInlined);
  Expect.isNull(AnotherClass.staticNullableFieldInlined);
}

// DDC does not perform checks for dynamic invocations.
void dynamicAnonymousClassTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  obj = createSomeClass();
  Expect.throwsTypeErrorWhen(dart2js && checksEnabled, () => obj.returnsNull());
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.returnsUndefined());

  // In dart2js, a tearoff of an interop method is indistinguishable from a
  // getter returning the underlying function.
  var functionTearoff = obj.returnsNull;
  Expect.throwsTypeErrorWhen(false, () => functionTearoff());
  functionTearoff = obj.returnsUndefined;
  Expect.throwsTypeErrorWhen(false, () => functionTearoff());

  Expect.throwsTypeErrorWhen(dart2js && checksEnabled, () => obj.getsNull);
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.undefinedGetter);

  // Immediate invocations of instance getters are seen as function calls so
  // the results get checked.
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.getterFunctionReturnsNull());
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.getterFunctionReturnsUndefined());

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  var getterFunction = obj.getterFunctionReturnsNull;
  Expect.isNull(getterFunction());
  getterFunction = obj.getterFunctionReturnsUndefined;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(dart2js && checksEnabled, () => obj.nullField);
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.undefinedField);

  Expect.isNull(obj.nullableFunction());
  Expect.isNull(obj.nullableGetter);
  Expect.isNull(obj.nullableField);
}

// DDC does not perform checks for dynamic invocations.
void dynamicInlinedAnonymousClassTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  obj = createSomeClass();
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.returnsNullInlined());
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.returnsUndefinedInlined());

  // In dart2js, a tearoff of an interop method is indistinguishable from a
  // getter returning the underlying function.
  var functionTearoff = obj.returnsNullInlined;
  Expect.throwsTypeErrorWhen(false, () => functionTearoff());
  functionTearoff = obj.returnsUndefinedInlined;
  Expect.throwsTypeErrorWhen(false, () => functionTearoff());

  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.getsNullInlined);
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.undefinedGetterInlined);

  // Immediate invocations of instance getters are seen as function calls so
  // the results get checked.
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.getterFunctionReturnsNullInlined());
  Expect.throwsTypeErrorWhen(dart2js && checksEnabled,
      () => obj.getterFunctionReturnsUndefinedInlined());

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  var getterFunction = obj.getterFunctionReturnsNullInlined;
  Expect.isNull(getterFunction());
  getterFunction = obj.getterFunctionReturnsUndefinedInlined;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.nullFieldInlined);
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.undefinedFieldInlined);

  Expect.isNull(obj.nullableFunctionInlined());
  Expect.isNull(obj.nullableGetterInlined);
  Expect.isNull(obj.nullableFieldInlined);
}

void namedClassSetup() {
  eval(r'''self.NamedClass = class NamedClass {
          returnsNull() { return null; }
          returnsNullInlined() { return null; }
          returnsUndefined() { return void 0; }
          returnsUndefinedInlined() { return void 0; }
          static staticReturnsNull() { return null; }
          static staticReturnsNullInlined() { return null; }
          static staticReturnsUndefined() { return void 0; }
          static staticReturnsUndefinedInlined() { return void 0; }
          get getsNull() { return null; }
          get getsNullInlined() { return null; }
          static get staticGetsNull() { return null; }
          static get staticGetsNullInlined() { return null; }
          get getterFunctionReturnsNull() {
            return function() { return null; };
          }
          get getterFunctionReturnsNullInlined() {
            return function() { return null; };
          }
          get getterFunctionReturnsUndefined() {
            return function() { return void 0; };
          }
          get getterFunctionReturnsUndefinedInlined() {
            return function() { return void 0; };
          }
          static get staticGetterFunctionReturnsNull() {
            return function() { return null; };
          }
          static get staticGetterFunctionReturnsNullInlined() {
            return function() { return null; };
          }
          static get staticGetterFunctionReturnsUndefined() {
            return function() { return void 0; };
          }
          static get staticGetterFunctionReturnsUndefinedInlined() {
            return function() { return void 0; };
          }
          nullableFunction() { return null; }
          nullableFunctionInlined() { return null; }
          get nullableGetter() { return null; }
          get nullableGetterInlined() { return null; }
          nullableField = null;
          nullableFieldInlined = null;
          static staticNullableFunction() { return null; }
          static staticNullableFunctionInlined() { return null; }
          static get staticNullableGetter() { return null; }
          static get staticNullableGetterInlined() { return null; }
          static staticNullableField = null;
          static staticNullableFieldInlined = null;
          static createNamedClass() { return new NamedClass(); }
      };''');
}

void namedClassTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  var y = NamedClass.createNamedClass();
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.returnsNull());
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.returnsUndefined());

  // In dart2js, a tearoff of an interop method is indistinguishable from a
  // getter returning the underlying function.
  var functionTearoff = y.returnsNull;
  Expect.throwsTypeErrorWhen(ddc && checksEnabled, () => functionTearoff());
  functionTearoff = y.returnsUndefined;
  Expect.throwsTypeErrorWhen(ddc && checksEnabled, () => functionTearoff());

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

  Expect.isNull(y.nullableFunction());
  Expect.isNull(y.nullableGetter);
  Expect.isNull(y.nullableField);
  Expect.isNull(NamedClass.staticNullableFunction());
  Expect.isNull(NamedClass.staticNullableGetter);
  Expect.isNull(NamedClass.staticNullableField);
}

void inlinedNamedClassTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  var y = NamedClass.createNamedClass();
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.returnsNullInlined());
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.returnsUndefinedInlined());

  // In dart2js, a tearoff of an interop method is indistinguishable from a
  // getter returning the underlying function.
  var functionTearoff = y.returnsNullInlined;
  Expect.throwsTypeErrorWhen(ddc && checksEnabled, () => functionTearoff());
  functionTearoff = y.returnsUndefinedInlined;
  Expect.throwsTypeErrorWhen(ddc && checksEnabled, () => functionTearoff());

  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticReturnsNullInlined());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticReturnsUndefinedInlined());
  functionTearoff = NamedClass.staticReturnsNullInlined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  functionTearoff = NamedClass.staticReturnsUndefinedInlined;
  Expect.throwsTypeErrorWhen(checksEnabled, () => functionTearoff());
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.getsNullInlined);
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.undefinedGetterInlined);
  // Immediate invocations of instance getters are seen as function calls so
  // the results get checked.
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => y.getterFunctionReturnsNullInlined());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => y.getterFunctionReturnsUndefinedInlined());
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticGetsNullInlined);
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticUndefinedGetterInlined);

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  var getterFunction = y.getterFunctionReturnsNullInlined;
  Expect.isNull(getterFunction());
  getterFunction = y.getterFunctionReturnsNullInlined;
  Expect.isNull(getterFunction());
  Expect.isNull(NamedClass.staticGetterFunctionReturnsNullInlined());
  Expect.isNull(NamedClass.staticGetterFunctionReturnsUndefinedInlined());
  getterFunction = NamedClass.staticGetterFunctionReturnsNullInlined;
  Expect.isNull(getterFunction());
  getterFunction = NamedClass.staticGetterFunctionReturnsUndefinedInlined;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(checksEnabled, () => y.nullFieldInlined);
  Expect.throwsTypeErrorWhen(checksEnabled, () => y.undefinedFieldInlined);
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticNullFieldInlined);
  Expect.throwsTypeErrorWhen(
      checksEnabled, () => NamedClass.staticUndefinedFieldInlined);

  Expect.isNull(y.nullableFunctionInlined());
  Expect.isNull(y.nullableGetterInlined);
  Expect.isNull(y.nullableFieldInlined);
  Expect.isNull(NamedClass.staticNullableFunctionInlined());
  Expect.isNull(NamedClass.staticNullableGetterInlined);
  Expect.isNull(NamedClass.staticNullableFieldInlined);
}

// DDC does not perform checks for dynamic invocations.
void dynamicNamedClassTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  obj = NamedClass.createNamedClass();
  Expect.throwsTypeErrorWhen(dart2js && checksEnabled, () => obj.returnsNull());
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.returnsUndefined());

  // In dart2js, a tearoff of an interop method is indistinguishable from a
  // getter returning the underlying function.
  var functionTearoff = obj.returnsNull;
  Expect.throwsTypeErrorWhen(false, () => functionTearoff());
  functionTearoff = obj.returnsUndefined;
  Expect.throwsTypeErrorWhen(false, () => functionTearoff());

  Expect.throwsTypeErrorWhen(dart2js && checksEnabled, () => obj.getsNull);
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.undefinedGetter);
  // Immediate invocations of instance getters are seen as function calls so
  // the results get checked.
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.getterFunctionReturnsNull());
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.getterFunctionReturnsUndefined());

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  var getterFunction = obj.getterFunctionReturnsNull;
  Expect.isNull(getterFunction());
  getterFunction = obj.getterFunctionReturnsNull;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(dart2js && checksEnabled, () => obj.nullField);
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.undefinedField);

  Expect.isNull(obj.nullableFunction());
  Expect.isNull(obj.nullableGetter);
  Expect.isNull(obj.nullableField);
}

// DDC does not perform checks for dynamic invocations.
void dynamicInlinedNamedClassTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  obj = NamedClass.createNamedClass();
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.returnsNullInlined());
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.returnsUndefinedInlined());

  // In dart2js, a tearoff of an interop method is indistinguishable from a
  // getter returning the underlying function.
  var functionTearoff = obj.returnsNullInlined;
  Expect.throwsTypeErrorWhen(false, () => functionTearoff());
  functionTearoff = obj.returnsUndefinedInlined;
  Expect.throwsTypeErrorWhen(false, () => functionTearoff());

  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.getsNullInlined);
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.undefinedGetterInlined);
  // Immediate invocations of instance getters are seen as function calls so
  // the results get checked.
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.getterFunctionReturnsNullInlined());
  Expect.throwsTypeErrorWhen(dart2js && checksEnabled,
      () => obj.getterFunctionReturnsUndefinedInlined());

  // At the time this test was written, getters that return function types don't
  // get the same wrappers as function tearoffs so there isn't an opportunity to
  // check the return values so they can still leak null or undefined through
  // from the JavaScript side.
  var getterFunction = obj.getterFunctionReturnsNullInlined;
  Expect.isNull(getterFunction());
  getterFunction = obj.getterFunctionReturnsNullInlined;
  Expect.isNull(getterFunction());

  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.nullFieldInlined);
  Expect.throwsTypeErrorWhen(
      dart2js && checksEnabled, () => obj.undefinedFieldInlined);

  Expect.isNull(obj.nullableFunctionInlined());
  Expect.isNull(obj.nullableGetterInlined);
  Expect.isNull(obj.nullableFieldInlined);
}

@JS()
class CollisionA {
  @pragma('dart2js:prefer-inline')
  external String foo([int? x]);

  @pragma('dart2js:never-inline')
  external String bar([int? x]);

  external factory CollisionA.create();
}

@JS()
class CollisionB {
  @pragma('dart2js:prefer-inline')
  external String? foo();

  @pragma('dart2js:never-inline')
  external String? bar();

  external factory CollisionB.create();
}

void collisionClassSetup() {
  eval(r'''
      self.CollisionA = class CollisionA {
        foo(x) { return null; }
        bar(x) { return null; }
        static create() { return new CollisionA(); }
      };

      self.CollisionB = class CollisionB {
        foo() { return null; }
        bar() { return null; }
        static create() { return new CollisionB(); }
      };''');
}

void collisionTests({required bool checksEnabled}) {
  // Provide at least one nullable value to [Expect.isNull] so that dart2js
  // doesn't discard the branch.
  Expect.isNull(null);

  var a = CollisionA.create();
  var b = CollisionB.create();

  // In dart2js, the receiver type is erased to `LegacyJavaScriptObject`, so we
  // cannot identify which class's method is being invoked and cannot emit a
  // null check. DDC is able to identify the member being invoked.
  Expect.throwsTypeErrorWhen(checksEnabled && ddc, () => a.foo());
  Expect.throwsTypeErrorWhen(checksEnabled && ddc, () => a.bar());

  Expect.isNull(b.foo());
  Expect.isNull(b.bar());

  // Because `foo$1` and `bar$1` only exist for [CollisionA] and not
  // [CollisionB], dart2js still emits these checks in the callee.
  Expect.throwsTypeErrorWhen(checksEnabled, () => a.foo(42));
  Expect.throwsTypeErrorWhen(checksEnabled, () => a.bar(42));
}

void runTests({required bool checksEnabled}) {
  topLevelMemberTests(checksEnabled: checksEnabled);
  inlinedTopLevelMemberTests(checksEnabled: checksEnabled);

  anonymousClassSetup();
  anonymousClassTests(checksEnabled: checksEnabled);
  inlinedAnonymousClassTests(checksEnabled: checksEnabled);
  dynamicAnonymousClassTests(checksEnabled: checksEnabled);
  dynamicInlinedAnonymousClassTests(checksEnabled: checksEnabled);

  namedClassSetup();
  namedClassTests(checksEnabled: checksEnabled);
  inlinedNamedClassTests(checksEnabled: checksEnabled);
  dynamicNamedClassTests(checksEnabled: checksEnabled);
  dynamicInlinedNamedClassTests(checksEnabled: checksEnabled);

  collisionClassSetup();
  collisionTests(checksEnabled: checksEnabled);
}
