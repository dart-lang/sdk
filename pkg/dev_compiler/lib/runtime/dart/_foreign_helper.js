dart_library.library('dart/_foreign_helper', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  function JS(typeDescription, codeTemplate, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11) {
    if (arg0 === void 0) arg0 = null;
    if (arg1 === void 0) arg1 = null;
    if (arg2 === void 0) arg2 = null;
    if (arg3 === void 0) arg3 = null;
    if (arg4 === void 0) arg4 = null;
    if (arg5 === void 0) arg5 = null;
    if (arg6 === void 0) arg6 = null;
    if (arg7 === void 0) arg7 = null;
    if (arg8 === void 0) arg8 = null;
    if (arg9 === void 0) arg9 = null;
    if (arg10 === void 0) arg10 = null;
    if (arg11 === void 0) arg11 = null;
  }
  dart.fn(JS, dart.dynamic, [core.String, core.String], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]);
  class JSExportName extends core.Object {
    JSExportName(name) {
      this.name = name;
    }
  }
  dart.setSignature(JSExportName, {
    constructors: () => ({JSExportName: [JSExportName, [core.String]]})
  });
  function JS_CURRENT_ISOLATE_CONTEXT() {
  }
  dart.fn(JS_CURRENT_ISOLATE_CONTEXT, () => dart.definiteFunctionType(IsolateContext, []));
  class IsolateContext extends core.Object {}
  function JS_CALL_IN_ISOLATE(isolate, func) {
  }
  dart.fn(JS_CALL_IN_ISOLATE, dart.dynamic, [dart.dynamic, core.Function]);
  function JS_SET_CURRENT_ISOLATE(isolate) {
  }
  dart.fn(JS_SET_CURRENT_ISOLATE, dart.void, [dart.dynamic]);
  function JS_CREATE_ISOLATE() {
  }
  dart.fn(JS_CREATE_ISOLATE);
  function JS_DART_OBJECT_CONSTRUCTOR() {
  }
  dart.fn(JS_DART_OBJECT_CONSTRUCTOR);
  function JS_INTERCEPTOR_CONSTANT(type) {
  }
  dart.fn(JS_INTERCEPTOR_CONSTANT, dart.dynamic, [core.Type]);
  function JS_OPERATOR_IS_PREFIX() {
  }
  dart.fn(JS_OPERATOR_IS_PREFIX, core.String, []);
  function JS_OPERATOR_AS_PREFIX() {
  }
  dart.fn(JS_OPERATOR_AS_PREFIX, core.String, []);
  function JS_OBJECT_CLASS_NAME() {
  }
  dart.fn(JS_OBJECT_CLASS_NAME, core.String, []);
  function JS_NULL_CLASS_NAME() {
  }
  dart.fn(JS_NULL_CLASS_NAME, core.String, []);
  function JS_FUNCTION_CLASS_NAME() {
  }
  dart.fn(JS_FUNCTION_CLASS_NAME, core.String, []);
  function JS_IS_INDEXABLE_FIELD_NAME() {
  }
  dart.fn(JS_IS_INDEXABLE_FIELD_NAME, core.String, []);
  function JS_CURRENT_ISOLATE() {
  }
  dart.fn(JS_CURRENT_ISOLATE);
  function JS_SIGNATURE_NAME() {
  }
  dart.fn(JS_SIGNATURE_NAME, core.String, []);
  function JS_TYPEDEF_TAG() {
  }
  dart.fn(JS_TYPEDEF_TAG, core.String, []);
  function JS_FUNCTION_TYPE_TAG() {
  }
  dart.fn(JS_FUNCTION_TYPE_TAG, core.String, []);
  function JS_FUNCTION_TYPE_VOID_RETURN_TAG() {
  }
  dart.fn(JS_FUNCTION_TYPE_VOID_RETURN_TAG, core.String, []);
  function JS_FUNCTION_TYPE_RETURN_TYPE_TAG() {
  }
  dart.fn(JS_FUNCTION_TYPE_RETURN_TYPE_TAG, core.String, []);
  function JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG() {
  }
  dart.fn(JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG, core.String, []);
  function JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG() {
  }
  dart.fn(JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG, core.String, []);
  function JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG() {
  }
  dart.fn(JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG, core.String, []);
  function JS_GET_NAME(name) {
  }
  dart.fn(JS_GET_NAME, core.String, [core.String]);
  function JS_EMBEDDED_GLOBAL(typeDescription, name) {
  }
  dart.fn(JS_EMBEDDED_GLOBAL, dart.dynamic, [core.String, core.String]);
  function JS_GET_FLAG(name) {
  }
  dart.fn(JS_GET_FLAG, core.bool, [core.String]);
  function JS_EFFECT(code) {
    dart.dcall(code, null);
  }
  dart.fn(JS_EFFECT, dart.void, [core.Function]);
  class JS_CONST extends core.Object {
    JS_CONST(code) {
      this.code = code;
    }
  }
  dart.setSignature(JS_CONST, {
    constructors: () => ({JS_CONST: [JS_CONST, [core.String]]})
  });
  function JS_STRING_CONCAT(a, b) {
    return a + b;
  }
  dart.fn(JS_STRING_CONCAT, core.String, [core.String, core.String]);
  class _Rest extends core.Object {
    _Rest() {
    }
  }
  dart.setSignature(_Rest, {
    constructors: () => ({_Rest: [_Rest, []]})
  });
  const rest = dart.const(new _Rest());
  function spread(args) {
    dart.throw(new core.StateError('The spread function cannot be called, ' + 'it should be compiled away.'));
  }
  dart.fn(spread);
  // Exports:
  exports.JS = JS;
  exports.JSExportName = JSExportName;
  exports.JS_CURRENT_ISOLATE_CONTEXT = JS_CURRENT_ISOLATE_CONTEXT;
  exports.IsolateContext = IsolateContext;
  exports.JS_CALL_IN_ISOLATE = JS_CALL_IN_ISOLATE;
  exports.JS_SET_CURRENT_ISOLATE = JS_SET_CURRENT_ISOLATE;
  exports.JS_CREATE_ISOLATE = JS_CREATE_ISOLATE;
  exports.JS_DART_OBJECT_CONSTRUCTOR = JS_DART_OBJECT_CONSTRUCTOR;
  exports.JS_INTERCEPTOR_CONSTANT = JS_INTERCEPTOR_CONSTANT;
  exports.JS_OPERATOR_IS_PREFIX = JS_OPERATOR_IS_PREFIX;
  exports.JS_OPERATOR_AS_PREFIX = JS_OPERATOR_AS_PREFIX;
  exports.JS_OBJECT_CLASS_NAME = JS_OBJECT_CLASS_NAME;
  exports.JS_NULL_CLASS_NAME = JS_NULL_CLASS_NAME;
  exports.JS_FUNCTION_CLASS_NAME = JS_FUNCTION_CLASS_NAME;
  exports.JS_IS_INDEXABLE_FIELD_NAME = JS_IS_INDEXABLE_FIELD_NAME;
  exports.JS_CURRENT_ISOLATE = JS_CURRENT_ISOLATE;
  exports.JS_SIGNATURE_NAME = JS_SIGNATURE_NAME;
  exports.JS_TYPEDEF_TAG = JS_TYPEDEF_TAG;
  exports.JS_FUNCTION_TYPE_TAG = JS_FUNCTION_TYPE_TAG;
  exports.JS_FUNCTION_TYPE_VOID_RETURN_TAG = JS_FUNCTION_TYPE_VOID_RETURN_TAG;
  exports.JS_FUNCTION_TYPE_RETURN_TYPE_TAG = JS_FUNCTION_TYPE_RETURN_TYPE_TAG;
  exports.JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG = JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG;
  exports.JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG = JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG;
  exports.JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG = JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG;
  exports.JS_GET_NAME = JS_GET_NAME;
  exports.JS_EMBEDDED_GLOBAL = JS_EMBEDDED_GLOBAL;
  exports.JS_GET_FLAG = JS_GET_FLAG;
  exports.JS_EFFECT = JS_EFFECT;
  exports.JS_CONST = JS_CONST;
  exports.JS_STRING_CONCAT = JS_STRING_CONCAT;
  exports.rest = rest;
  exports.spread = spread;
});
