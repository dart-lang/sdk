/*library: 
 constant=[
  {
  "id": "constant/B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n",
  "kind": "constant",
  "name": null,
  "size": 131,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n"
},
  {
  "id": "constant/B.Interceptor_methods = J.Interceptor.prototype;\n",
  "kind": "constant",
  "name": null,
  "size": 49,
  "outputUnit": "outputUnit/main",
  "code": "B.Interceptor_methods = J.Interceptor.prototype;\n"
},
  {
  "id": "constant/B.JSArray_methods = J.JSArray.prototype;\n",
  "kind": "constant",
  "name": null,
  "size": 41,
  "outputUnit": "outputUnit/main",
  "code": "B.JSArray_methods = J.JSArray.prototype;\n"
},
  {
  "id": "constant/B.JSString_methods = J.JSString.prototype;\n",
  "kind": "constant",
  "name": null,
  "size": 43,
  "outputUnit": "outputUnit/main",
  "code": "B.JSString_methods = J.JSString.prototype;\n"
},
  {
  "id": "constant/B.JavaScriptObject_methods = J.JavaScriptObject.prototype;\n",
  "kind": "constant",
  "name": null,
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
  "size": 10341,
  "children": [
    "class/memory:sdk/tests/web/native/main.dart::Class1",
    "function/memory:sdk/tests/web/native/main.dart::main",
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
  "size": 107495,
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
  ]
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
   function=[{
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
}],
   holding=[
    {"id":"field/memory:sdk/tests/web/native/main.dart::Class1.field","mask":null},
    {"id":"function/dart:_js_helper::throwCyclicInit","mask":null},
    {"id":"function/dart:_late_helper::throwLateFieldADI","mask":null},
    {"id":"function/dart:_rti::Rti._bind","mask":null},
    {"id":"function/dart:_rti::Rti._eval","mask":null},
    {"id":"function/dart:_rti::_arrayInstanceType","mask":null},
    {"id":"function/dart:_rti::_asBool","mask":null},
    {"id":"function/dart:_rti::_asBoolQ","mask":null},
    {"id":"function/dart:_rti::_asBoolS","mask":null},
    {"id":"function/dart:_rti::_asDouble","mask":null},
    {"id":"function/dart:_rti::_asDoubleQ","mask":null},
    {"id":"function/dart:_rti::_asDoubleS","mask":null},
    {"id":"function/dart:_rti::_asInt","mask":null},
    {"id":"function/dart:_rti::_asIntQ","mask":null},
    {"id":"function/dart:_rti::_asIntS","mask":null},
    {"id":"function/dart:_rti::_asNum","mask":null},
    {"id":"function/dart:_rti::_asNumQ","mask":null},
    {"id":"function/dart:_rti::_asNumS","mask":null},
    {"id":"function/dart:_rti::_asObject","mask":null},
    {"id":"function/dart:_rti::_asString","mask":null},
    {"id":"function/dart:_rti::_asStringQ","mask":null},
    {"id":"function/dart:_rti::_asStringS","mask":null},
    {"id":"function/dart:_rti::_asTop","mask":null},
    {"id":"function/dart:_rti::_generalAsCheckImplementation","mask":null},
    {"id":"function/dart:_rti::_generalIsTestImplementation","mask":null},
    {"id":"function/dart:_rti::_generalNullableAsCheckImplementation","mask":null},
    {"id":"function/dart:_rti::_generalNullableIsTestImplementation","mask":null},
    {"id":"function/dart:_rti::_installSpecializedAsCheck","mask":null},
    {"id":"function/dart:_rti::_installSpecializedIsTest","mask":null},
    {"id":"function/dart:_rti::_instanceType","mask":null},
    {"id":"function/dart:_rti::_isBool","mask":null},
    {"id":"function/dart:_rti::_isInt","mask":null},
    {"id":"function/dart:_rti::_isNum","mask":null},
    {"id":"function/dart:_rti::_isObject","mask":null},
    {"id":"function/dart:_rti::_isString","mask":null},
    {"id":"function/dart:_rti::_isTop","mask":null},
    {"id":"function/dart:_rti::findType","mask":null},
    {"id":"function/dart:_rti::instanceType","mask":null}]
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
    {"id":"field/memory:sdk/tests/web/native/main.dart::Class1.funcField","mask":null},
    {"id":"function/dart:_js_helper::throwCyclicInit","mask":null},
    {"id":"function/dart:_late_helper::throwLateFieldADI","mask":null}]
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
   function=[{
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
  "type": "dynamic Function()"
}],
   holding=[
    {"id":"function/dart:_rti::Rti._eval","mask":null},
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call","mask":null}]
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
  "type": "dynamic Function(dynamic)"
}],
   holding=[
    {"id":"function/dart:_rti::Rti._eval","mask":null},
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.field.Class1_field_closure.call","mask":null}]
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
  "type": "Class1<#A> Function<#A extends Object?>()"
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
   function=[{
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
  "type": "Class1<#A> Function<#A extends Object?>()"
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2.Class1_Class1$fact2_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2.Class1_Class1$fact2_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.setFunc","mask":null}]
  */
  factory Class1.fact2() => new Class1.setFunc(() => new Set<T>());

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
  "type": "dynamic Function()"
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
   function=[{
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
  "type": "dynamic Function()"
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method2.Class1_method2_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method2.Class1_method2_closure.call","mask":null}]
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
  "type": "dynamic Function<#A extends Object?>()"
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
   function=[{
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
  "type": "dynamic Function<#A extends Object?>()"
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method4.Class1_method4_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method4.Class1_method4_closure.call","mask":null}]
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
   function=[{
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
  "type": "dynamic Function()"
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/dart:_rti::findType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method5.Class1_method5_local.call","mask":null}]
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
   function=[{
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
  "type": "dynamic Function<#A extends Object?>()"
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/dart:_rti::findType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6.Class1_method6_local.call","mask":null}]
  */
  method6<S>() {
    local<U>() {
      return () => '$S$U';
    }

    var local2 = (o) {
      return () => new Map<T, S>();
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
  "type": "dynamic Function<#A extends Object?>()"
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
   function=[{
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
  "type": "dynamic Function<#A extends Object?>()"
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2.Class1_staticMethod2_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2.Class1_staticMethod2_closure.call","mask":null}]
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
   function=[{
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
  "type": "dynamic Function()"
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/dart:_rti::findType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3.Class1_staticMethod3_local.call","mask":null}]
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
   function=[{
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
  "type": "dynamic Function<#A extends Object?>()"
}],
   holding=[
    {"id":"function/dart:_rti::_setArrayType","mask":null},
    {"id":"function/dart:_rti::findType","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_closure.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local.call","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4.Class1_staticMethod4_local.call","mask":null}]
  */
  static staticMethod4<S>() {
    local<U>() {
      return () => '$S$U';
    }

    var local2 = (o) {
      return () => new Set<S>();
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
  "type": "dynamic Function<#A extends Object?>()"
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
 function=[{
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
  "type": "dynamic Function<#A extends Object?>()"
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod2.topLevelMethod2_closure.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod2.topLevelMethod2_closure.call","mask":null}]
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
 function=[{
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
  "type": "dynamic Function()"
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType","mask":null},
  {"id":"function/dart:_rti::findType","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod3.topLevelMethod3_local.call","mask":null}]
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
 function=[{
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
  "type": "dynamic Function<#A extends Object?>()"
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType","mask":null},
  {"id":"function/dart:_rti::findType","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_closure.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_closure.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4.topLevelMethod4_local.call","mask":null}]
*/
topLevelMethod4<S>() {
  local<U>() {
    return () => '$S$U';
  }

  var local2 = (o) {
    return () => new Set<S>();
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
 function=[{
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
  "type": "dynamic Function()"
}],
 holding=[
  {"id":"function/dart:_rti::_setArrayType","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local1.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local1.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local2.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals.twoLocals_local2.call","mask":null}]
*/
dynamic twoLocals() {
  local1() {}
  local2() => local1();
  return local2;
}

/*member: main:
 function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::main",
  "kind": "function",
  "name": "main",
  "size": 649,
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
  "code": "main() {\n      var t2,\n        t1 = type$.int;\n      A.createRuntimeType(A.Class1$(t1).$ti._precomputed1);\n      A.Class1$(t1).method2$0();\n      A.Class1_Class1$fact2(t1).funcField.call$0();\n      A.Class1$(t1);\n      t2 = type$.double;\n      A.createRuntimeType(t2);\n      A.Class1$(t1).method4$1$0(t2);\n      A.Class1$(t1).method5$0();\n      A.Class1$(t1).method6$1$0(t2);\n      A.createRuntimeType(t2);\n      A.Class1_staticMethod2(t2);\n      A.Class1_staticMethod3();\n      A.Class1_staticMethod4(t2);\n      A.createRuntimeType(t2);\n      A.topLevelMethod2(t2);\n      A.topLevelMethod3();\n      A.topLevelMethod4(t2);\n      A.twoLocals();\n    }",
  "type": "dynamic Function()"
}],
 holding=[
  {"id":"field/dart:_rti::Rti._precomputed1","mask":null},
  {"id":"field/memory:sdk/tests/web/native/main.dart::Class1.funcField","mask":null},
  {"id":"function/dart:_rti::createRuntimeType","mask":null},
  {"id":"function/dart:_rti::findType","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.Class1.fact2","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method1","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method1","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method2","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method3","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method3","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method4","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method5","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.method6","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod1","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod1","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod2","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod3","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Class1.staticMethod4","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod1","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod1","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod2","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod3","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::topLevelMethod4","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::twoLocals","mask":null}]
*/
main() {
  new Class1<int>().method1();
  new Class1<int>.fact().method2();
  new Class1<int>.fact2().funcField() is Set;
  new Class1<int>().method3<double>();
  new Class1<int>().method4<double>();
  new Class1<int>().method5();
  new Class1<int>().method6<double>();
  Class1.staticMethod1<double>();
  Class1.staticMethod2<double>();
  Class1.staticMethod3();
  Class1.staticMethod4<double>();
  topLevelMethod1<double>();
  topLevelMethod2<double>();
  topLevelMethod3();
  topLevelMethod4<double>();
  twoLocals();
}
