var _foreign_helper;
(function(exports) {
  'use strict';
  // Function JS: (String, String, [dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic]) → dynamic
  function JS(typeDescription, codeTemplate, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11) {
    if (arg0 === void 0)
      arg0 = null;
    if (arg1 === void 0)
      arg1 = null;
    if (arg2 === void 0)
      arg2 = null;
    if (arg3 === void 0)
      arg3 = null;
    if (arg4 === void 0)
      arg4 = null;
    if (arg5 === void 0)
      arg5 = null;
    if (arg6 === void 0)
      arg6 = null;
    if (arg7 === void 0)
      arg7 = null;
    if (arg8 === void 0)
      arg8 = null;
    if (arg9 === void 0)
      arg9 = null;
    if (arg10 === void 0)
      arg10 = null;
    if (arg11 === void 0)
      arg11 = null;
  }
  // Function JS_CURRENT_ISOLATE_CONTEXT: () → IsolateContext
  function JS_CURRENT_ISOLATE_CONTEXT() {
  }
  class IsolateContext extends dart.Object {
  }
  // Function JS_CALL_IN_ISOLATE: (dynamic, Function) → dynamic
  function JS_CALL_IN_ISOLATE(isolate, function) {
  }
  // Function DART_CLOSURE_TO_JS: (Function) → dynamic
  function DART_CLOSURE_TO_JS(function) {
  }
  // Function RAW_DART_FUNCTION_REF: (Function) → dynamic
  function RAW_DART_FUNCTION_REF(function) {
  }
  // Function JS_SET_CURRENT_ISOLATE: (dynamic) → void
  function JS_SET_CURRENT_ISOLATE(isolate) {
  }
  // Function JS_CREATE_ISOLATE: () → dynamic
  function JS_CREATE_ISOLATE() {
  }
  // Function JS_DART_OBJECT_CONSTRUCTOR: () → dynamic
  function JS_DART_OBJECT_CONSTRUCTOR() {
  }
  // Function JS_INTERCEPTOR_CONSTANT: (Type) → dynamic
  function JS_INTERCEPTOR_CONSTANT(type) {
  }
  // Function JS_OPERATOR_IS_PREFIX: () → String
  function JS_OPERATOR_IS_PREFIX() {
  }
  // Function JS_OPERATOR_AS_PREFIX: () → String
  function JS_OPERATOR_AS_PREFIX() {
  }
  // Function JS_OBJECT_CLASS_NAME: () → String
  function JS_OBJECT_CLASS_NAME() {
  }
  // Function JS_NULL_CLASS_NAME: () → String
  function JS_NULL_CLASS_NAME() {
  }
  // Function JS_FUNCTION_CLASS_NAME: () → String
  function JS_FUNCTION_CLASS_NAME() {
  }
  // Function JS_IS_INDEXABLE_FIELD_NAME: () → String
  function JS_IS_INDEXABLE_FIELD_NAME() {
  }
  // Function JS_CURRENT_ISOLATE: () → dynamic
  function JS_CURRENT_ISOLATE() {
  }
  // Function JS_SIGNATURE_NAME: () → String
  function JS_SIGNATURE_NAME() {
  }
  // Function JS_TYPEDEF_TAG: () → String
  function JS_TYPEDEF_TAG() {
  }
  // Function JS_FUNCTION_TYPE_TAG: () → String
  function JS_FUNCTION_TYPE_TAG() {
  }
  // Function JS_FUNCTION_TYPE_VOID_RETURN_TAG: () → String
  function JS_FUNCTION_TYPE_VOID_RETURN_TAG() {
  }
  // Function JS_FUNCTION_TYPE_RETURN_TYPE_TAG: () → String
  function JS_FUNCTION_TYPE_RETURN_TYPE_TAG() {
  }
  // Function JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG: () → String
  function JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG() {
  }
  // Function JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG: () → String
  function JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG() {
  }
  // Function JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG: () → String
  function JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG() {
  }
  // Function JS_GET_NAME: (String) → String
  function JS_GET_NAME(name) {
  }
  // Function JS_EMBEDDED_GLOBAL: (String, String) → dynamic
  function JS_EMBEDDED_GLOBAL(typeDescription, name) {
  }
  // Function JS_GET_FLAG: (String) → bool
  function JS_GET_FLAG(name) {
  }
  // Function JS_EFFECT: (Function) → void
  function JS_EFFECT(code) {
    dart.dinvokef(code, null);
  }
  class JS_CONST extends dart.Object {
    JS_CONST(code) {
      this.code = code;
    }
  }
  // Function JS_STRING_CONCAT: (String, String) → String
  function JS_STRING_CONCAT(a, b) {
    return a + b;
  }
  // Exports:
  exports.JS = JS;
  exports.JS_CURRENT_ISOLATE_CONTEXT = JS_CURRENT_ISOLATE_CONTEXT;
  exports.IsolateContext = IsolateContext;
  exports.JS_CALL_IN_ISOLATE = JS_CALL_IN_ISOLATE;
  exports.DART_CLOSURE_TO_JS = DART_CLOSURE_TO_JS;
  exports.RAW_DART_FUNCTION_REF = RAW_DART_FUNCTION_REF;
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
})(_foreign_helper || (_foreign_helper = {}));
