//@dart = 2.9

/*library: 
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
  "id": "constant/B.JSInt_methods = J.JSInt.prototype;\n",
  "kind": "constant",
  "name": "",
  "size": 37,
  "outputUnit": "outputUnit/main",
  "code": "B.JSInt_methods = J.JSInt.prototype;\n"
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
},
  {
  "id": "constant/B.Type_Object_xQ6 = A.typeLiteral(\"Object\");\n",
  "kind": "constant",
  "name": "",
  "size": 45,
  "outputUnit": "outputUnit/main",
  "code": "B.Type_Object_xQ6 = A.typeLiteral(\"Object\");\n"
},
  {
  "id": "constant/B.Type_dynamic_0Rz = A.typeLiteral(\"@\");\n",
  "kind": "constant",
  "name": "",
  "size": 41,
  "outputUnit": "outputUnit/main",
  "code": "B.Type_dynamic_0Rz = A.typeLiteral(\"@\");\n"
}],
 deferredFiles=[{}],
 dependencies=[{}],
 library=[{
  "id": "library/memory:sdk/tests/web/native/main.dart::",
  "kind": "library",
  "name": "memory:sdk/tests/web/native/main.dart",
  "size": 842,
  "children": [
    "class/memory:sdk/tests/web/native/main.dart::Clazz",
    "class/memory:sdk/tests/web/native/main.dart::Mixin",
    "class/memory:sdk/tests/web/native/main.dart::Subclass",
    "class/memory:sdk/tests/web/native/main.dart::Super",
    "function/memory:sdk/tests/web/native/main.dart::main"
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

import 'package:expect/expect.dart';

/*class: Super:class=[{
  "id": "class/memory:sdk/tests/web/native/main.dart::Super",
  "kind": "class",
  "name": "Super",
  "size": 62,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": []
}]*/
class Super<T> {
  void method(T t) {}
}

/*class: Mixin:class=[{
  "id": "class/memory:sdk/tests/web/native/main.dart::Mixin",
  "kind": "class",
  "name": "Mixin",
  "size": 89,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": [
    "function/memory:sdk/tests/web/native/main.dart::Mixin.method"
  ]
}]*/
class Mixin {
  /*member: Mixin.method:
   function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Mixin.method",
  "kind": "function",
  "name": "method",
  "size": 81,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Mixin",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "void",
  "inferredReturnType": "[null]",
  "parameters": [
    {
      "name": "t",
      "type": "[exact=JSUInt31]",
      "declaredType": "int*"
    }
  ],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "method$1(t) {\n    }\nvar _ = A.Mixin.prototype;\n\n_.super$Mixin$method = _.method$1;\n",
  "type": "void Function(int*)*",
  "functionKind": 2
}],
   holding=[
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
  void method(int t) {}
}

/*class: Clazz:class=[{
  "id": "class/memory:sdk/tests/web/native/main.dart::Clazz",
  "kind": "class",
  "name": "Clazz",
  "size": 192,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": [
    "function/memory:sdk/tests/web/native/main.dart::Clazz.method"
  ]
}]*/
/*member: Clazz.method:
 function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Clazz.method",
  "kind": "function",
  "name": "method",
  "size": 162,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Clazz",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "void",
  "inferredReturnType": "[null]",
  "parameters": [
    {
      "name": "t",
      "type": "Union([exact=JSString], [exact=JSUInt31])",
      "declaredType": "int*"
    }
  ],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "method$1(t) {\n      return this.super$Mixin$method(A._asIntS(t));\n    }\n_instance(A.Clazz.prototype, \"get$method\", 0, 1, null, [\"call$1\"], [\"method$1\"], 0, 0, 1);\n",
  "type": "void Function(int*)*",
  "functionKind": 2
}],
 holding=[
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
  {"id":"function/dart:_rti::instanceType","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Mixin.method","mask":null}]
*/
class Clazz = Super<int> with Mixin;

/*class: Subclass:class=[{
  "id": "class/memory:sdk/tests/web/native/main.dart::Subclass",
  "kind": "class",
  "name": "Subclass",
  "size": 95,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": [
    "function/memory:sdk/tests/web/native/main.dart::Subclass.Subclass",
    "function/memory:sdk/tests/web/native/main.dart::Subclass.test"
  ]
}]*/
/*member: Subclass.:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Subclass.Subclass",
  "kind": "function",
  "name": "Subclass",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Subclass",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Subclass*",
  "inferredReturnType": "[exact=Subclass]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "",
  "type": "Subclass* Function()*",
  "functionKind": 3
}]*/
class Subclass extends Clazz {
  /*member: Subclass.test:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::Subclass.test",
  "kind": "function",
  "name": "test",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::Subclass",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "void",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 1,
  "code": "",
  "type": "void Function()*",
  "functionKind": 2
}]*/
  void test() {
    void Function(int) f = super.method;
    f(0);
  }
}

/*member: main:
 closure=[{
  "id": "closure/memory:sdk/tests/web/native/main.dart::main.main_closure",
  "kind": "closure",
  "name": "main_closure",
  "size": 237,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::main",
  "function": "function/memory:sdk/tests/web/native/main.dart::main.main_closure.call"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::main",
  "kind": "function",
  "name": "main",
  "size": 404,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [
    "closure/memory:sdk/tests/web/native/main.dart::main.main_closure"
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
  "code": "main() {\n      var s = new A.Subclass();\n      A.Clazz.prototype.get$method.call(s).call$1(0);\n      A.Expect_throws(new A.main_closure(s), type$.legacy_Object);\n    }",
  "type": "dynamic Function()*",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::main.main_closure.call",
  "kind": "function",
  "name": "call",
  "size": 71,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::main.main_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "void",
  "inferredReturnType": "[null]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "call$0() {\n      return this.s.super$Mixin$method(A._asIntS(\"\"));\n    }",
  "type": "void Function()",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_js_helper::closureFromTearOff","mask":null},
  {"id":"function/dart:_rti::_setArrayType","mask":null},
  {"id":"function/dart:_rti::findType","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Clazz.method","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Subclass.Subclass","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Subclass.Subclass","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Subclass.test","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::Subclass.test","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::main.main_closure.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::main.main_closure.call","mask":null},
  {"id":"function/package:expect/expect.dart::Expect.throws","mask":null}]
*/
main() {
  Super<Object> s = new Subclass()..test();
  Expect.throws(() => s.method(''));
}
