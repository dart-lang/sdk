/*spec.library: 
 constant=[
  {
  "id": "constant/B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n",
  "kind": "constant",
  "name": "",
  "size": 131,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n"
},
  {
  "id": "constant/B.Interceptor_methods = J.Interceptor.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 49,
  "outputUnit": "outputUnit/main",
  "code": "B.Interceptor_methods = J.Interceptor.prototype;\n"
},
  {
  "id": "constant/B.JSArray_methods = J.JSArray.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 41,
  "outputUnit": "outputUnit/main",
  "code": "B.JSArray_methods = J.JSArray.prototype;\n"
},
  {
  "id": "constant/B.JavaScriptObject_methods = J.JavaScriptObject.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 59,
  "outputUnit": "outputUnit/main",
  "code": "B.JavaScriptObject_methods = J.JavaScriptObject.prototype;\n"
}],
 deferredFiles=[{}],
 dependencies=[{}],
 library=[{
  "id": "library/memory:sdk/tests/web/native/main.dart::",
  "kind": "library",
  "name": "<unnamed>",
  "size": 12352,
  "children": [
    "class/memory:sdk/tests/web/native/main.dart::Class1",
    "function/memory:sdk/tests/web/native/main.dart::main",
    "function/memory:sdk/tests/web/native/main.dart::nested",
    "function/memory:sdk/tests/web/native/main.dart::nested2",
    "function/memory:sdk/tests/web/native/main.dart::siblings",
    "function/memory:sdk/tests/web/native/main.dart::topLevelMethod1",
    "function/memory:sdk/tests/web/native/main.dart::topLevelMethod2",
    "function/memory:sdk/tests/web/native/main.dart::topLevelMethod3",
    "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4",
    "function/memory:sdk/tests/web/native/main.dart::twoLocals"
  ],
  "canonicalUri": "memory:sdk/tests/web/native/main.dart"
}],
 outputUnits=[{
  "id": "outputUnit/main",
  "kind": "outputUnit",
  "name": "main",
  "filename": "out",
  "imports": []
}]
*/
/*kernel.library: 
 constant=[
  {
  "id": "constant/B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n",
  "kind": "constant",
  "name": "",
  "size": 131,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n"
},
  {
  "id": "constant/B.Interceptor_methods = J.Interceptor.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 49,
  "outputUnit": "outputUnit/main",
  "code": "B.Interceptor_methods = J.Interceptor.prototype;\n"
},
  {
  "id": "constant/B.JSArray_methods = J.JSArray.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 41,
  "outputUnit": "outputUnit/main",
  "code": "B.JSArray_methods = J.JSArray.prototype;\n"
},
  {
  "id": "constant/B.JSString_methods = J.JSString.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 43,
  "outputUnit": "outputUnit/main",
  "code": "B.JSString_methods = J.JSString.prototype;\n"
},
  {
  "id": "constant/B.JavaScriptObject_methods = J.JavaScriptObject.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 59,
  "outputUnit": "outputUnit/main",
  "code": "B.JavaScriptObject_methods = J.JavaScriptObject.prototype;\n"
}],
 deferredFiles=[{}],
 dependencies=[{}],
 library=[{
  "id": "library/memory:sdk/tests/web/native/main.dart::",
  "kind": "library",
  "name": "<unnamed>",
  "size": 12431,
  "children": [
    "class/memory:sdk/tests/web/native/main.dart::Class1",
    "function/memory:sdk/tests/web/native/main.dart::main",
    "function/memory:sdk/tests/web/native/main.dart::nested",
    "function/memory:sdk/tests/web/native/main.dart::nested2",
    "function/memory:sdk/tests/web/native/main.dart::siblings",
    "function/memory:sdk/tests/web/native/main.dart::topLevelMethod1",
    "function/memory:sdk/tests/web/native/main.dart::topLevelMethod2",
    "function/memory:sdk/tests/web/native/main.dart::topLevelMethod3",
    "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4",
    "function/memory:sdk/tests/web/native/main.dart::twoLocals"
  ],
  "canonicalUri": "memory:sdk/tests/web/native/main.dart"
}],
 outputUnits=[{
  "id": "outputUnit/main",
  "kind": "outputUnit",
  "name": "main",
  "filename": "out",
  "imports": []
}]
*/
/*class: Class1:class=[{
  "id": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "kind": "class",
  "name": "Class1",
  "size": 6151,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": [
    "field/memory:sdk/tests/web/native/main.dart::Class1.field",
    "field/memory:sdk/tests/web/native/main.dart::Class1.funcField",
    "function/memory:sdk/tests/web/native/main.dart::Class1.Class1",
    "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact",
    "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2",
    "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.setFunc",
    "function/memory:sdk/tests/web/native/main.dart::Class1.method1",
    "function/memory:sdk/tests/web/native/main.dart::Class1.method2",
    "function/memory:sdk/tests/web/native/main.dart::Class1.method3",
    "function/memory:sdk/tests/web/native/main.dart::Class1.method4",
    "function/memory:sdk/tests/web/native/main.dart::Class1.method5",
    "function/memory:sdk/tests/web/native/main.dart::Class1.method6",
    "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod1",
    "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2",
    "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3",
    "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4"
  ],
  "supers": []
}]*/
class Class1<T> {
  /*member: Class1.field:
   closure=[{
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure",
  "kind": "closure",
  "name": "Class1_field_closure",
  "size": 242,
  "outputUnit": "outputUnit/main",
  "parent": "field/memory:sdk/tests/web/native/main.dart::Class1.field",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call"
}],
   function=[
    {
  "id": "field/memory:sdk/tests/web/native/main.dart::Class1.field",
  "kind": "field",
  "name": "field",
  "size": 318,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure"
  ],
  "inferredType": "[subclass=Closure]",
  "code": "set$field(field) {\n      this.field = type$.Type_Function._as(field);\n    }",
  "type": "Type Function()"
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call",
  "kind": "function",
  "name": "call",
  "size": 58,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.T);\n    }",
  "type": "Type Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"field/memory:sdk/tests/web/native/main.dart::Class1.field"},
    {"id":"function/dart:_js_helper::throwCyclicInit"},
    {"id":"function/dart:_late_helper::throwLateFieldADI"},
    {"id":"function/dart:_rti::Rti._bind"},
    {"id":"function/dart:_rti::Rti._eval"},
    {"id":"function/dart:_rti::_arrayInstanceType"},
    {"id":"function/dart:_rti::_asBool"},
    {"id":"function/dart:_rti::_asBoolQ"},
    {"id":"function/dart:_rti::_asBoolS"},
    {"id":"function/dart:_rti::_asDouble"},
    {"id":"function/dart:_rti::_asDoubleQ"},
    {"id":"function/dart:_rti::_asDoubleS"},
    {"id":"function/dart:_rti::_asInt"},
    {"id":"function/dart:_rti::_asIntQ"},
    {"id":"function/dart:_rti::_asIntS"},
    {"id":"function/dart:_rti::_asNum"},
    {"id":"function/dart:_rti::_asNumQ"},
    {"id":"function/dart:_rti::_asNumS"},
    {"id":"function/dart:_rti::_asObject"},
    {"id":"function/dart:_rti::_asString"},
    {"id":"function/dart:_rti::_asStringQ"},
    {"id":"function/dart:_rti::_asStringS"},
    {"id":"function/dart:_rti::_asTop"},
    {"id":"function/dart:_rti::_generalAsCheckImplementation"},
    {"id":"function/dart:_rti::_generalIsTestImplementation"},
    {"id":"function/dart:_rti::_generalNullableAsCheckImplementation"},
    {"id":"function/dart:_rti::_generalNullableIsTestImplementation"},
    {"id":"function/dart:_rti::_installSpecializedAsCheck"},
    {"id":"function/dart:_rti::_installSpecializedIsTest"},
    {"id":"function/dart:_rti::_instanceType"},
    {"id":"function/dart:_rti::_isBool"},
    {"id":"function/dart:_rti::_isInt"},
    {"id":"function/dart:_rti::_isNum"},
    {"id":"function/dart:_rti::_isObject"},
    {"id":"function/dart:_rti::_isString"},
    {"id":"function/dart:_rti::_isTop"},
    {"id":"function/dart:_rti::findType"},
    {"id":"function/dart:_rti::instanceType"}]
  */
  var field = () => T;
  /*member: Class1.funcField:
   function=[{
  "id": "field/memory:sdk/tests/web/native/main.dart::Class1.funcField",
  "kind": "field",
  "name": "funcField",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [],
  "inferredType": "[null|subclass=Closure]",
  "code": "",
  "type": "dynamic"
}],
   holding=[
    {"id":"field/memory:sdk/tests/web/native/main.dart::Class1.funcField"},
    {"id":"function/dart:_js_helper::throwCyclicInit"},
    {"id":"function/dart:_late_helper::throwLateFieldADI"}]
  */
  var funcField;

  /*member: Class1.:
   closure=[{
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.Class1.Class1_closure",
  "kind": "closure",
  "name": "Class1_closure",
  "size": 204,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.Class1_closure.call"
}],
   function=[
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1",
  "kind": "function",
  "name": "Class1",
  "size": 355,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.Class1.Class1_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[exact=Class1]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes field)",
  "inlinedCount": 0,
  "code": "Class1$($T) {\n      var t1 = new A.Class1(new A.Class1_field_closure($T), null, $T._eval$1(\"Class1<0>\"));\n      t1.Class1$0($T);\n      return t1;\n    }",
  "type": "dynamic Function()",
  "functionKind": 3
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.Class1_closure.call",
  "kind": "function",
  "name": "call",
  "size": 58,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.Class1.Class1_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.T);\n    }",
  "type": "Type Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"function/dart:_rti::Rti._eval"},
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call"}]
  */
  Class1() {
    field = () => T;
  }

  /*member: Class1.setFunc:
   function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.setFunc",
  "kind": "function",
  "name": "Class1.setFunc",
  "size": 132,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[exact=Class1]",
  "parameters": [
    {
      "name": "funcField",
      "type": "[subclass=Closure]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "Class1$setFunc(funcField, $T) {\n      return new A.Class1(new A.Class1_field_closure($T), funcField, $T._eval$1(\"Class1<0>\"));\n    }",
  "type": "dynamic Function(dynamic)",
  "functionKind": 3
}],
   holding=[
    {"id":"function/dart:_rti::Rti._eval"},
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call"}]
  */
  Class1.setFunc(this.funcField);
  /*member: Class1.fact:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact",
  "kind": "function",
  "name": "Class1.fact",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": true,
    "external": false
  },
  "returnType": "Class1<#Afree>",
  "inferredReturnType": "[exact=Class1]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes field)",
  "inlinedCount": 1,
  "code": "",
  "type": "Class1<#A> Function<#A extends Object?>()",
  "functionKind": 3
}]*/
  factory Class1.fact() => new Class1<T>();
  /*member: Class1.fact2:
   closure=[{
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2.Class1_Class1$fact2_closure",
  "kind": "closure",
  "name": "Class1_Class1$fact2_closure",
  "size": 314,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2.Class1_Class1$fact2_closure.call"
}],
   function=[
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2",
  "kind": "function",
  "name": "Class1.fact2",
  "size": 419,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2.Class1_Class1$fact2_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": true,
    "external": false
  },
  "returnType": "Class1<#Afree>",
  "inferredReturnType": "[exact=Class1]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "Class1_Class1$fact2($T) {\n      return A.Class1$setFunc(new A.Class1_Class1$fact2_closure($T), $T);\n    }",
  "type": "Class1<#A> Function<#A extends Object?>()",
  "functionKind": 3
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2.Class1_Class1$fact2_closure.call",
  "kind": "function",
  "name": "call",
  "size": 68,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2.Class1_Class1$fact2_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Set<Class1.T>",
  "inferredReturnType": "[subclass=_LinkedHashSet]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.LinkedHashSet_LinkedHashSet(this.T);\n    }",
  "type": "Set<Class1.T> Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2.Class1_Class1$fact2_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2.Class1_Class1$fact2_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.setFunc"}]
  */
  factory Class1.fact2() => Class1.setFunc(() => Set<T>());

  /*member: Class1.method1:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method1",
  "kind": "function",
  "name": "method1",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "",
  "type": "dynamic Function()",
  "functionKind": 2
}]*/
  method1() => T;
  /*member: Class1.method2:
   closure=[{
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.method2.Class1_method2_closure",
  "kind": "closure",
  "name": "Class1_method2_closure",
  "size": 262,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.method2",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.method2.Class1_method2_closure.call"
}],
   function=[
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method2",
  "kind": "function",
  "name": "method2",
  "size": 330,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.method2.Class1_method2_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "method2$0() {\n      return new A.Class1_method2_closure(this);\n    }",
  "type": "dynamic Function()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method2.Class1_method2_closure.call",
  "kind": "function",
  "name": "call",
  "size": 80,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.method2.Class1_method2_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.$this.$ti._precomputed1);\n    }",
  "type": "Type Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method2.Class1_method2_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method2.Class1_method2_closure.call"}]
  */
  method2() {
    return () => T;
  }

  /*member: Class1.method3:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method3",
  "kind": "function",
  "name": "method3",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "",
  "type": "dynamic Function<#A extends Object?>()",
  "functionKind": 2
}]*/
  method3<S>() => S;
  /*member: Class1.method4:
   closure=[{
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.method4.Class1_method4_closure",
  "kind": "closure",
  "name": "Class1_method4_closure",
  "size": 236,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.method4",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.method4.Class1_method4_closure.call"
}],
   function=[
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method4",
  "kind": "function",
  "name": "method4",
  "size": 306,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.method4.Class1_method4_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "method4$1$0($S) {\n      return new A.Class1_method4_closure($S);\n    }",
  "type": "dynamic Function<#A extends Object?>()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method4.Class1_method4_closure.call",
  "kind": "function",
  "name": "call",
  "size": 58,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.method4.Class1_method4_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.S);\n    }",
  "type": "Type Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method4.Class1_method4_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method4.Class1_method4_closure.call"}]
  */
  method4<S>() {
    return () => S;
  }

  /*member: Class1.method5:
   closure=[
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local",
  "kind": "closure",
  "name": "Class1_method5_local",
  "size": 287,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.method5",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local.call"
},
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local_closure",
  "kind": "closure",
  "name": "Class1_method5_local_closure",
  "size": 260,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.method5",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local_closure.call"
}],
   function=[
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method5",
  "kind": "function",
  "name": "method5",
  "size": 632,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local",
    "closure/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "method5$0() {\n      return new A.Class1_method5_local().call$1$0(type$.double);\n    }",
  "type": "dynamic Function()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local.call",
  "kind": "function",
  "name": "call",
  "size": 132,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$1$0($S) {\n      return new A.Class1_method5_local_closure($S);\n    }\ncall$0() {\n      return this.call$1$0(type$.dynamic);\n    }",
  "type": "Type Function() Function<#A extends Object?>()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local_closure.call",
  "kind": "function",
  "name": "call",
  "size": 58,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.S);\n    }",
  "type": "Type Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/dart:_rti::findType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local.call"}]
  */
  method5() {
    local<S>() {
      return () => S;
    }

    return local<double>();
  }

  /*member: Class1.method6:
   closure=[
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6__closure",
  "kind": "closure",
  "name": "Class1_method6__closure",
  "size": 415,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.method6",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6__closure.call"
},
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_closure",
  "kind": "closure",
  "name": "Class1_method6_closure",
  "size": 363,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.method6",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_closure.call"
},
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local",
  "kind": "closure",
  "name": "Class1_method6_local",
  "size": 316,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.method6",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local.call"
},
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local_closure",
  "kind": "closure",
  "name": "Class1_method6_local_closure",
  "size": 341,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.method6",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local_closure.call"
}],
   function=[
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method6",
  "kind": "function",
  "name": "method6",
  "size": 1573,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6__closure",
    "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_closure",
    "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local",
    "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "method6$1$0($S) {\n      return new A.Class1_method6_closure(this, $S).call$1(new A.Class1_method6_local($S).call$1$0(type$.double));\n    }",
  "type": "dynamic Function<#A extends Object?>()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6__closure.call",
  "kind": "function",
  "name": "call",
  "size": 132,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6__closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Map<Class1.T,method6.S>",
  "inferredReturnType": "[exact=JsLinkedHashMap]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return new A.JsLinkedHashMap(this.$this.$ti._eval$1(\"@<1>\")._bind$1(this.S)._eval$1(\"JsLinkedHashMap<1,2>\"));\n    }",
  "type": "Map<Class1.T,method6.S> Function()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_closure.call",
  "kind": "function",
  "name": "call",
  "size": 81,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Map<Class1.T,method6.S> Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [
    {
      "name": "o",
      "type": "[subclass=Closure]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$1(o) {\n      return new A.Class1_method6__closure(this.$this, this.S);\n    }",
  "type": "Map<Class1.T,method6.S> Function() Function(dynamic)",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local.call",
  "kind": "function",
  "name": "call",
  "size": 140,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "String Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$1$0($U) {\n      return new A.Class1_method6_local_closure(this.S, $U);\n    }\ncall$0() {\n      return this.call$1$0(type$.dynamic);\n    }",
  "type": "String Function() Function<#A extends Object?>()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local_closure.call",
  "kind": "function",
  "name": "call",
  "size": 116,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "String",
  "inferredReturnType": "[exact=JSString]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.S).toString$0(0) + A.createRuntimeType(this.U).toString$0(0);\n    }",
  "type": "String Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/dart:_rti::findType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local.call"}]
  */
  method6<S>() {
    local<U>() {
      return () => '$S$U';
    }

    var local2 = (o) {
      return () => Map<T, S>();
    };
    return local2(local<double>());
  }

  /*member: Class1.staticMethod1:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod1",
  "kind": "function",
  "name": "staticMethod1",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [],
  "modifiers": {
    "static": true,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "",
  "type": "dynamic Function<#A extends Object?>()",
  "functionKind": 0
}]*/
  static staticMethod1<S>() => S;
  /*member: Class1.staticMethod2:
   closure=[{
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2.Class1_staticMethod2_closure",
  "kind": "closure",
  "name": "Class1_staticMethod2_closure",
  "size": 260,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2.Class1_staticMethod2_closure.call"
}],
   function=[
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2",
  "kind": "function",
  "name": "staticMethod2",
  "size": 345,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2.Class1_staticMethod2_closure"
  ],
  "modifiers": {
    "static": true,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "Class1_staticMethod2($S) {\n      return new A.Class1_staticMethod2_closure($S);\n    }",
  "type": "dynamic Function<#A extends Object?>()",
  "functionKind": 0
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2.Class1_staticMethod2_closure.call",
  "kind": "function",
  "name": "call",
  "size": 58,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2.Class1_staticMethod2_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.S);\n    }",
  "type": "Type Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2.Class1_staticMethod2_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2.Class1_staticMethod2_closure.call"}]
  */
  static staticMethod2<S>() {
    return () => S;
  }

  /*member: Class1.staticMethod3:
   closure=[
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local",
  "kind": "closure",
  "name": "Class1_staticMethod3_local",
  "size": 317,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local.call"
},
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local_closure",
  "kind": "closure",
  "name": "Class1_staticMethod3_local_closure",
  "size": 284,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local_closure.call"
}],
   function=[
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3",
  "kind": "function",
  "name": "staticMethod3",
  "size": 703,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local",
    "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local_closure"
  ],
  "modifiers": {
    "static": true,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "Class1_staticMethod3() {\n      return new A.Class1_staticMethod3_local().call$1$0(type$.double);\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local.call",
  "kind": "function",
  "name": "call",
  "size": 138,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$1$0($S) {\n      return new A.Class1_staticMethod3_local_closure($S);\n    }\ncall$0() {\n      return this.call$1$0(type$.dynamic);\n    }",
  "type": "Type Function() Function<#A extends Object?>()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local_closure.call",
  "kind": "function",
  "name": "call",
  "size": 58,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.S);\n    }",
  "type": "Type Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/dart:_rti::findType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local.call"}]
  */
  static staticMethod3() {
    local<S>() {
      return () => S;
    }

    return local<double>();
  }

  /*member: Class1.staticMethod4:
   closure=[
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4__closure",
  "kind": "closure",
  "name": "Class1_staticMethod4__closure",
  "size": 322,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4__closure.call"
},
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_closure",
  "kind": "closure",
  "name": "Class1_staticMethod4_closure",
  "size": 328,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_closure.call"
},
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local",
  "kind": "closure",
  "name": "Class1_staticMethod4_local",
  "size": 346,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local.call"
},
    {
  "id": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local_closure",
  "kind": "closure",
  "name": "Class1_staticMethod4_local_closure",
  "size": 365,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4",
  "function": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local_closure.call"
}],
   function=[
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4",
  "kind": "function",
  "name": "staticMethod4",
  "size": 1514,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Class1",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4__closure",
    "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_closure",
    "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local",
    "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local_closure"
  ],
  "modifiers": {
    "static": true,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "Class1_staticMethod4($S) {\n      return new A.Class1_staticMethod4_closure($S).call$1(new A.Class1_staticMethod4_local($S).call$1$0(type$.double));\n    }",
  "type": "dynamic Function<#A extends Object?>()",
  "functionKind": 0
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4__closure.call",
  "kind": "function",
  "name": "call",
  "size": 68,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4__closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Set<staticMethod4.S>",
  "inferredReturnType": "[subclass=_LinkedHashSet]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.LinkedHashSet_LinkedHashSet(this.S);\n    }",
  "type": "Set<staticMethod4.S> Function()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_closure.call",
  "kind": "function",
  "name": "call",
  "size": 75,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Set<staticMethod4.S> Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [
    {
      "name": "o",
      "type": "[subclass=Closure]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$1(o) {\n      return new A.Class1_staticMethod4__closure(this.S);\n    }",
  "type": "Set<staticMethod4.S> Function() Function(dynamic)",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local.call",
  "kind": "function",
  "name": "call",
  "size": 146,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "String Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$1$0($U) {\n      return new A.Class1_staticMethod4_local_closure(this.S, $U);\n    }\ncall$0() {\n      return this.call$1$0(type$.dynamic);\n    }",
  "type": "String Function() Function<#A extends Object?>()",
  "functionKind": 2
},
    {
  "id": "function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local_closure.call",
  "kind": "function",
  "name": "call",
  "size": 116,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "String",
  "inferredReturnType": "[exact=JSString]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.S).toString$0(0) + A.createRuntimeType(this.U).toString$0(0);\n    }",
  "type": "String Function()",
  "functionKind": 2
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType"},
    {"id":"function/dart:_rti::findType"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_closure.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local.call"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local.call"}]
  */
  static staticMethod4<S>() {
    local<U>() {
      return () => '$S$U';
    }

    var local2 = (o) {
      return () => Set<S>();
    };
    return local2(local<double>());
  }
}

/*member: topLevelMethod1:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod1",
  "kind": "function",
  "name": "topLevelMethod1",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "",
  "type": "dynamic Function<#A extends Object?>()",
  "functionKind": 0
}]*/
topLevelMethod1<S>() => S;

/*member: topLevelMethod2:
 closure=[{
  "id": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod2.topLevelMethod2_closure",
  "kind": "closure",
  "name": "topLevelMethod2_closure",
  "size": 240,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod2",
  "function": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod2.topLevelMethod2_closure.call"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod2",
  "kind": "function",
  "name": "topLevelMethod2",
  "size": 315,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod2.topLevelMethod2_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "topLevelMethod2($S) {\n      return new A.topLevelMethod2_closure($S);\n    }",
  "type": "dynamic Function<#A extends Object?>()",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod2.topLevelMethod2_closure.call",
  "kind": "function",
  "name": "call",
  "size": 58,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod2.topLevelMethod2_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.S);\n    }",
  "type": "Type Function()",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod2.topLevelMethod2_closure.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod2.topLevelMethod2_closure.call"}]
*/
topLevelMethod2<S>() {
  return () => S;
}

/*member: topLevelMethod3:
 closure=[
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local",
  "kind": "closure",
  "name": "topLevelMethod3_local",
  "size": 292,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod3",
  "function": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local_closure",
  "kind": "closure",
  "name": "topLevelMethod3_local_closure",
  "size": 264,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod3",
  "function": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local_closure.call"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod3",
  "kind": "function",
  "name": "topLevelMethod3",
  "size": 648,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local",
    "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "topLevelMethod3() {\n      return new A.topLevelMethod3_local().call$1$0(type$.double);\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local.call",
  "kind": "function",
  "name": "call",
  "size": 133,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$1$0($S) {\n      return new A.topLevelMethod3_local_closure($S);\n    }\ncall$0() {\n      return this.call$1$0(type$.dynamic);\n    }",
  "type": "Type Function() Function<#A extends Object?>()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local_closure.call",
  "kind": "function",
  "name": "call",
  "size": 58,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Type",
  "inferredReturnType": "[exact=_Type]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.S);\n    }",
  "type": "Type Function()",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType"},
  {"id":"function/dart:_rti::findType"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local.call"}]
*/
topLevelMethod3() {
  local<S>() {
    return () => S;
  }

  return local<double>();
}

/*member: topLevelMethod4:
 closure=[
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4__closure",
  "kind": "closure",
  "name": "topLevelMethod4__closure",
  "size": 302,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4",
  "function": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4__closure.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_closure",
  "kind": "closure",
  "name": "topLevelMethod4_closure",
  "size": 303,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4",
  "function": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_closure.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local",
  "kind": "closure",
  "name": "topLevelMethod4_local",
  "size": 321,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4",
  "function": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local_closure",
  "kind": "closure",
  "name": "topLevelMethod4_local_closure",
  "size": 345,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4",
  "function": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local_closure.call"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4",
  "kind": "function",
  "name": "topLevelMethod4",
  "size": 1409,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4__closure",
    "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_closure",
    "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local",
    "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "topLevelMethod4($S) {\n      return new A.topLevelMethod4_closure($S).call$1(new A.topLevelMethod4_local($S).call$1$0(type$.double));\n    }",
  "type": "dynamic Function<#A extends Object?>()",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4__closure.call",
  "kind": "function",
  "name": "call",
  "size": 68,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4__closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Set<topLevelMethod4.S>",
  "inferredReturnType": "[subclass=_LinkedHashSet]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.LinkedHashSet_LinkedHashSet(this.S);\n    }",
  "type": "Set<topLevelMethod4.S> Function()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_closure.call",
  "kind": "function",
  "name": "call",
  "size": 70,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Set<topLevelMethod4.S> Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [
    {
      "name": "o",
      "type": "[subclass=Closure]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$1(o) {\n      return new A.topLevelMethod4__closure(this.S);\n    }",
  "type": "Set<topLevelMethod4.S> Function() Function(dynamic)",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local.call",
  "kind": "function",
  "name": "call",
  "size": 141,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "String Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$1$0($U) {\n      return new A.topLevelMethod4_local_closure(this.S, $U);\n    }\ncall$0() {\n      return this.call$1$0(type$.dynamic);\n    }",
  "type": "String Function() Function<#A extends Object?>()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local_closure.call",
  "kind": "function",
  "name": "call",
  "size": 116,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "String",
  "inferredReturnType": "[exact=JSString]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return A.createRuntimeType(this.S).toString$0(0) + A.createRuntimeType(this.U).toString$0(0);\n    }",
  "type": "String Function()",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType"},
  {"id":"function/dart:_rti::findType"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_closure.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_closure.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local.call"}]
*/
topLevelMethod4<S>() {
  local<U>() {
    return () => '$S$U';
  }

  var local2 = (o) {
    return () => Set<S>();
  };
  return local2(local<double>());
}

/*member: twoLocals:
 closure=[
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local1",
  "kind": "closure",
  "name": "twoLocals_local1",
  "size": 149,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::twoLocals",
  "function": "function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local1.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local2",
  "kind": "closure",
  "name": "twoLocals_local2",
  "size": 210,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::twoLocals",
  "function": "function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local2.call"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::twoLocals",
  "kind": "function",
  "name": "twoLocals",
  "size": 441,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local1",
    "closure/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local2"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "twoLocals() {\n      return new A.twoLocals_local2(new A.twoLocals_local1());\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local1.call",
  "kind": "function",
  "name": "call",
  "size": 16,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local1",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Null",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n    }",
  "type": "Null Function()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local2.call",
  "kind": "function",
  "name": "call",
  "size": 51,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local2",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Null",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return this.local1.call$0();\n    }",
  "type": "Null Function()",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local1.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local1.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local2.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local2.call"}]
*/
dynamic twoLocals() {
  local1() {}
  local2() => local1();
  return local2;
}

/*member: nested:
 closure=[
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::nested.nested_nested1",
  "kind": "closure",
  "name": "nested_nested1",
  "size": 225,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::nested",
  "function": "function/memory:sdk/tests/web/native/main.dart::nested.nested_nested1.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::nested.nested_nested1_nested2",
  "kind": "closure",
  "name": "nested_nested1_nested2",
  "size": 227,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::nested",
  "function": "function/memory:sdk/tests/web/native/main.dart::nested.nested_nested1_nested2.call"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested",
  "kind": "function",
  "name": "nested",
  "size": 568,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::nested.nested_nested1",
    "closure/memory:sdk/tests/web/native/main.dart::nested.nested_nested1_nested2"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "nested() {\n      var t1 = {};\n      t1.x = null;\n      new A.nested_nested1(t1).call$0();\n      t1.x.call$0();\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested.nested_nested1.call",
  "kind": "function",
  "name": "call",
  "size": 74,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::nested.nested_nested1",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Null",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      this._box_0.x = new A.nested_nested1_nested2(this);\n    }",
  "type": "Null Function()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested.nested_nested1_nested2.call",
  "kind": "function",
  "name": "call",
  "size": 43,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::nested.nested_nested1_nested2",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic Function()",
  "inferredReturnType": "[subclass=Closure]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return this.nested1;\n    }",
  "type": "dynamic Function() Function()",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::nested.nested_nested1.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::nested.nested_nested1.call"}]
*/
dynamic nested() {
  dynamic x;
  nested1() {
    nested2() => nested1;
    x = nested2;
  }

  nested1();
  x();
}

/*spec.member: nested2:
 closure=[
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1",
  "kind": "closure",
  "name": "nested2_local1",
  "size": 195,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::nested2",
  "function": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure",
  "kind": "closure",
  "name": "nested2_local1__closure",
  "size": 193,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::nested2",
  "function": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure",
  "kind": "closure",
  "name": "nested2_local1_closure",
  "size": 232,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::nested2",
  "function": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure.call"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested2",
  "kind": "function",
  "name": "nested2",
  "size": 685,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1",
    "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure",
    "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "nested2() {\n      A.print(new A.nested2_local1().call$0());\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1.call",
  "kind": "function",
  "name": "call",
  "size": 70,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "int",
  "inferredReturnType": "[subclass=JSInt]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return new A.nested2_local1_closure().call$0();\n    }",
  "type": "int Function()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure.call",
  "kind": "function",
  "name": "call",
  "size": 32,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "int",
  "inferredReturnType": "[exact=JSUInt31]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return 2;\n    }",
  "type": "int Function()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure.call",
  "kind": "function",
  "name": "call",
  "size": 75,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "int",
  "inferredReturnType": "[subclass=JSInt]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return 1 + new A.nested2_local1__closure().call$0();\n    }",
  "type": "int Function()",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType"},
  {"id":"function/dart:core::print"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1.call"}]
*/
/*kernel.member: nested2:
 closure=[
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1",
  "kind": "closure",
  "name": "nested2_local1",
  "size": 195,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::nested2",
  "function": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure",
  "kind": "closure",
  "name": "nested2_local1__closure",
  "size": 193,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::nested2",
  "function": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure",
  "kind": "closure",
  "name": "nested2_local1_closure",
  "size": 311,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::nested2",
  "function": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure.call"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested2",
  "kind": "function",
  "name": "nested2",
  "size": 764,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1",
    "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure",
    "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "nested2() {\n      A.print(new A.nested2_local1().call$0());\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1.call",
  "kind": "function",
  "name": "call",
  "size": 70,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "int",
  "inferredReturnType": "[subclass=JSInt]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return new A.nested2_local1_closure().call$0();\n    }",
  "type": "int Function()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure.call",
  "kind": "function",
  "name": "call",
  "size": 32,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1__closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "int",
  "inferredReturnType": "[exact=JSUInt31]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return 2;\n    }",
  "type": "int Function()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure.call",
  "kind": "function",
  "name": "call",
  "size": 154,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "int",
  "inferredReturnType": "[subclass=JSInt]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      var t1 = new A.nested2_local1__closure().call$0();\n      if (typeof t1 !== \"number\")\n        return A.iae(t1);\n      return 1 + t1;\n    }",
  "type": "int Function()",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType"},
  {"id":"function/dart:core::print"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::nested2.nested2_local1.call"}]
*/
dynamic nested2() {
  dynamic y;
  int local1() {
    return (() => 1 + (() => 2)())();
  }

  y = local1();
  print(y);
}

/*member: siblings:
 closure=[
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1",
  "kind": "closure",
  "name": "siblings_local1",
  "size": 244,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::siblings",
  "function": "function/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure",
  "kind": "closure",
  "name": "siblings_local1_closure",
  "size": 193,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::siblings",
  "function": "function/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure.call"
},
  {
  "id": "closure/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure%0",
  "kind": "closure",
  "name": "siblings_local1_closure",
  "size": 197,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::siblings",
  "function": "function/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure.call%0"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::siblings",
  "kind": "function",
  "name": "siblings",
  "size": 701,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1",
    "closure/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure",
    "closure/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure%0"
  ],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "siblings() {\n      A.print(new A.siblings_local1().call$0());\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1.call",
  "kind": "function",
  "name": "call",
  "size": 115,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "int",
  "inferredReturnType": "[subclass=JSInt]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return new A.siblings_local1_closure().call$0() + new A.siblings_local1_closure0().call$0();\n    }",
  "type": "int Function()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure.call",
  "kind": "function",
  "name": "call",
  "size": 32,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "int",
  "inferredReturnType": "[exact=JSUInt31]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return 1;\n    }",
  "type": "int Function()",
  "functionKind": 2
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure.call%0",
  "kind": "function",
  "name": "call",
  "size": 32,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1_closure%0",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "int",
  "inferredReturnType": "[exact=JSUInt31]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return 3;\n    }",
  "type": "int Function()",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType"},
  {"id":"function/dart:core::print"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::siblings.siblings_local1.call"}]
*/
dynamic siblings() {
  int local1() {
    int a = (() => 1)();
    dynamic b = () => 2;
    int c = (() => 3)();
    return a + c;
  }

  print(local1());
}

/*member: main:
 function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::main",
  "kind": "function",
  "name": "main",
  "size": 706,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "main() {\n      var t2,\n        t1 = type$.int;\n      A.createRuntimeType(A.Class1$(t1).$ti._precomputed1);\n      A.Class1$(t1).method2$0();\n      A.Class1_Class1$fact2(t1).funcField.call$0();\n      A.Class1$(t1);\n      t2 = type$.double;\n      A.createRuntimeType(t2);\n      A.Class1$(t1).method4$1$0(t2);\n      A.Class1$(t1).method5$0();\n      A.Class1$(t1).method6$1$0(t2);\n      A.createRuntimeType(t2);\n      A.Class1_staticMethod2(t2);\n      A.Class1_staticMethod3();\n      A.Class1_staticMethod4(t2);\n      A.createRuntimeType(t2);\n      A.topLevelMethod2(t2);\n      A.topLevelMethod3();\n      A.topLevelMethod4(t2);\n      A.twoLocals();\n      A.nested();\n      A.nested2();\n      A.siblings();\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
}],
 holding=[
  {"id":"field/dart:_rti::Rti._precomputed1"},
  {"id":"field/memory:sdk/tests/web/native/main.dart::Class1.funcField"},
  {"id":"function/dart:_rti::createRuntimeType"},
  {"id":"function/dart:_rti::findType"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method1","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method1"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method2"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method3","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method3"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method4"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method5"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod1","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod1"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::nested"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::nested2"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::siblings"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod1","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod1"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod2"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod3"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals"}]
*/
main() {
  Class1<int>().method1();
  Class1<int>.fact().method2();
  Class1<int>.fact2().funcField() is Set;
  Class1<int>().method3<double>();
  Class1<int>().method4<double>();
  Class1<int>().method5();
  Class1<int>().method6<double>();
  Class1.staticMethod1<double>();
  Class1.staticMethod2<double>();
  Class1.staticMethod3();
  Class1.staticMethod4<double>();
  topLevelMethod1<double>();
  topLevelMethod2<double>();
  topLevelMethod3();
  topLevelMethod4<double>();
  twoLocals();
  nested();
  nested2();
  siblings();
}
