dart_library.library('language/type_error_test', null, /* Imports */[
  'dart_sdk'
], function load__type_error_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_error_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_error_test.MyClass = class MyClass extends core.Object {};
  type_error_test.IntTypeError = class IntTypeError extends core.Object {
    toString() {
      let value = core.int._check(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.StringTypeError = class StringTypeError extends core.Object {
    toString() {
      let value = core.String._check(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.DoubleTypeError = class DoubleTypeError extends core.Object {
    toString() {
      let value = core.double._check(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.NumTypeError = class NumTypeError extends core.Object {
    toString() {
      let value = core.num._check(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.BoolTypeError = class BoolTypeError extends core.Object {
    toString() {
      let value = core.bool._check(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.FunctionTypeError = class FunctionTypeError extends core.Object {
    toString() {
      let value = core.Function._check(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.MyClassTypeError = class MyClassTypeError extends core.Object {
    toString() {
      let value = type_error_test.MyClass._check(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.ListTypeError = class ListTypeError extends core.Object {
    toString() {
      let value = core.List._check(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.IntCastError = class IntCastError extends core.Object {
    toString() {
      core.int.as(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.StringCastError = class StringCastError extends core.Object {
    toString() {
      core.String.as(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.DoubleCastError = class DoubleCastError extends core.Object {
    toString() {
      core.double.as(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.NumCastError = class NumCastError extends core.Object {
    toString() {
      core.num.as(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.BoolCastError = class BoolCastError extends core.Object {
    toString() {
      core.bool.as(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.FunctionCastError = class FunctionCastError extends core.Object {
    toString() {
      core.Function.as(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.MyClassCastError = class MyClassCastError extends core.Object {
    toString() {
      type_error_test.MyClass.as(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.ListCastError = class ListCastError extends core.Object {
    toString() {
      core.List.as(type_error_test.wrap(this));
      return super.toString();
    }
  };
  type_error_test.wrap = function(e) {
    if (new core.DateTime.now().year == 1980) return null;
    return e;
  };
  dart.fn(type_error_test.wrap, dynamicTodynamic());
  type_error_test.checkTypeError = function(o) {
    try {
      core.print(o);
    } catch (e) {
      if (core.TypeError.is(e)) {
        core.print(e);
        if (dart.test(type_error_test.assertionsEnabled)) return;
        throw e;
      } else
        throw e;
    }

    if (dart.test(type_error_test.assertionsEnabled)) {
      dart.throw('expected TypeError');
    }
  };
  dart.fn(type_error_test.checkTypeError, dynamicTodynamic());
  type_error_test.checkAssert = function(o) {
    try {
      dart.assert(o);
    } catch (e) {
      if (core.TypeError.is(e)) {
        core.print(e);
        if (!dart.test(type_error_test.assertionsEnabled)) throw e;
      } else
        throw e;
    }

  };
  dart.fn(type_error_test.checkAssert, dynamicTodynamic());
  type_error_test.checkCastError = function(o) {
    try {
      core.print(o);
    } catch (e$) {
      if (core.TypeError.is(e$)) {
        let e = e$;
        core.print(dart.str`unexpected type error: ${core.Error.safeToString(e)}`);
        throw e;
      } else if (core.CastError.is(e$)) {
        let e = e$;
        core.print(e);
        return;
      } else
        throw e$;
    }

    dart.throw('expected CastError');
  };
  dart.fn(type_error_test.checkCastError, dynamicTodynamic());
  type_error_test.assertionsEnabled = false;
  type_error_test.main = function() {
    dart.assert(type_error_test.assertionsEnabled = true);
    type_error_test.checkTypeError(new type_error_test.IntTypeError());
    type_error_test.checkTypeError(new type_error_test.StringTypeError());
    type_error_test.checkTypeError(new type_error_test.DoubleTypeError());
    type_error_test.checkTypeError(new type_error_test.NumTypeError());
    type_error_test.checkTypeError(new type_error_test.BoolTypeError());
    type_error_test.checkTypeError(new type_error_test.FunctionTypeError());
    type_error_test.checkTypeError(new type_error_test.MyClassTypeError());
    type_error_test.checkTypeError(new type_error_test.ListTypeError());
    type_error_test.checkAssert(new type_error_test.IntTypeError());
    type_error_test.checkAssert(new type_error_test.StringTypeError());
    type_error_test.checkAssert(new type_error_test.DoubleTypeError());
    type_error_test.checkAssert(new type_error_test.NumTypeError());
    type_error_test.checkAssert(new type_error_test.BoolTypeError());
    type_error_test.checkAssert(new type_error_test.FunctionTypeError());
    type_error_test.checkAssert(new type_error_test.MyClassTypeError());
    type_error_test.checkAssert(new type_error_test.ListTypeError());
    type_error_test.checkCastError(new type_error_test.IntCastError());
    type_error_test.checkCastError(new type_error_test.StringCastError());
    type_error_test.checkCastError(new type_error_test.DoubleCastError());
    type_error_test.checkCastError(new type_error_test.NumCastError());
    type_error_test.checkCastError(new type_error_test.BoolCastError());
    type_error_test.checkCastError(new type_error_test.FunctionCastError());
    type_error_test.checkCastError(new type_error_test.MyClassCastError());
    type_error_test.checkCastError(new type_error_test.ListCastError());
  };
  dart.fn(type_error_test.main, VoidTodynamic());
  // Exports:
  exports.type_error_test = type_error_test;
});
