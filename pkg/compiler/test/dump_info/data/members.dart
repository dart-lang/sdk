/*library: 
 constant=[
  {
  "id": "constant/B.C_A = new A.A();\n",
  "kind": "constant",
  "name": "",
  "size": 19,
  "outputUnit": "outputUnit/main",
  "code": "B.C_A = new A.A();\n"
},
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
},
  {
  "id": "constant/B.List_A = A._setArrayType(makeConstList([B.C_A]), A.findType(\"JSArray<A>\"));\n",
  "kind": "constant",
  "name": "",
  "size": 78,
  "outputUnit": "outputUnit/main",
  "code": "B.List_A = A._setArrayType(makeConstList([B.C_A]), A.findType(\"JSArray<A>\"));\n"
}],
 deferredFiles=[{}],
 dependencies=[{}],
 library=[{
  "id": "library/memory:sdk/tests/web/native/main.dart::",
  "kind": "library",
  "name": "<unnamed>",
  "size": 475,
  "children": [
    "class/memory:sdk/tests/web/native/main.dart::A",
    "class/memory:sdk/tests/web/native/main.dart::C",
    "classType/memory:sdk/tests/web/native/main.dart::A",
    "field/memory:sdk/tests/web/native/main.dart::constList",
    "function/memory:sdk/tests/web/native/main.dart::F",
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
/*class: C:class=[{
  "id": "class/memory:sdk/tests/web/native/main.dart::C",
  "kind": "class",
  "name": "C",
  "size": 46,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": [
    "field/memory:sdk/tests/web/native/main.dart::C.counter",
    "field/memory:sdk/tests/web/native/main.dart::C.value",
    "field/memory:sdk/tests/web/native/main.dart::C.y",
    "function/memory:sdk/tests/web/native/main.dart::C.C._default",
    "function/memory:sdk/tests/web/native/main.dart::C.C.create",
    "function/memory:sdk/tests/web/native/main.dart::C.compute"
  ]
}]*/
class C {
  /*member: C.value:
   function=[{
  "id": "field/memory:sdk/tests/web/native/main.dart::C.value",
  "kind": "field",
  "name": "value",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::C",
  "children": [],
  "inferredType": "[exact=Error]",
  "code": "",
  "type": "dynamic"
}],
   holding=[
    {"id":"function/dart:_js_helper::throwCyclicInit","mask":null},
    {"id":"function/dart:_late_helper::throwLateFieldADI","mask":null}]
  */
  final value;
  /*member: C.counter:function=[{
  "id": "field/memory:sdk/tests/web/native/main.dart::C.counter",
  "kind": "field",
  "name": "counter",
  "size": 18,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::C",
  "children": [],
  "inferredType": "[subclass=JSPositiveInt]",
  "code": "$.C_counter = 0;\n",
  "type": "int"
}]*/
  static int counter = 0;
  /*member: C.y:
   function=[{
  "id": "field/memory:sdk/tests/web/native/main.dart::C.y",
  "kind": "field",
  "name": "y",
  "size": 124,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::C",
  "children": [],
  "inferredType": "[null|exact=JSBool]",
  "code": "_lazy($, \"C_y\", \"$get$C_y\", () => {\n      var t1 = $.C_counter + 1;\n      $.C_counter = t1;\n      return t1 === 4;\n    });\n",
  "type": "bool"
}],
   holding=[
    {"id":"field/memory:sdk/tests/web/native/main.dart::C.counter","mask":null},
    {"id":"field/memory:sdk/tests/web/native/main.dart::C.counter","mask":null},
    {"id":"function/dart:_js_helper::throwCyclicInit","mask":null},
    {"id":"function/dart:_late_helper::throwLateFieldADI","mask":null},
    {"id":"function/memory:sdk/tests/web/native/main.dart::C.compute","mask":"inlined"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::C.compute","mask":null}]
  */
  static bool y = C.compute();
  /*member: C.compute:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::C.compute",
  "kind": "function",
  "name": "compute",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::C",
  "children": [],
  "modifiers": {
    "static": true,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "bool",
  "inferredReturnType": "[exact=JSBool]",
  "parameters": [],
  "sideEffects": "SideEffects(reads static; writes static)",
  "inlinedCount": 1,
  "code": "",
  "type": "bool Function()",
  "functionKind": 0
}]*/
  static bool compute() {
    C.counter += 1;
    return counter == 4;
  }

  /*member: C._default:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::C.C._default",
  "kind": "function",
  "name": "C._default",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::C",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[exact=C]",
  "parameters": [
    {
      "name": "message",
      "type": "[exact=Error]",
      "declaredType": "Object"
    }
  ],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "",
  "type": "dynamic Function(Object)",
  "functionKind": 3
}]*/
  C._default(Object message) : value = message;

  /*member: C.create:
   function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::C.C.create",
  "kind": "function",
  "name": "C.create",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::C",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": true,
    "external": false
  },
  "returnType": "C",
  "inferredReturnType": "[exact=C]",
  "parameters": [
    {
      "name": "object",
      "type": "[exact=JSUInt31]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "",
  "type": "C Function(dynamic)",
  "functionKind": 3
}],
   holding=[
    {"id":"function/dart:core::Error.Error","mask":"inlined"},
    {"id":"function/memory:sdk/tests/web/native/main.dart::C.C._default","mask":"inlined"}]
  */
  factory C.create(object) {
    return C._default(Error());
  }
}

/*member: F:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::F",
  "kind": "function",
  "name": "F",
  "size": 52,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
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
  "code": "F() {\n    }\n_static_0(A, \"main__F$closure\", \"F\", 0);\n",
  "type": "void Function()",
  "functionKind": 0
}]*/
void F() {}

/*class: A:
 class=[{
  "id": "class/memory:sdk/tests/web/native/main.dart::A",
  "kind": "class",
  "name": "A",
  "size": 46,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": [
    "field/memory:sdk/tests/web/native/main.dart::A.a",
    "function/memory:sdk/tests/web/native/main.dart::A.A"
  ]
}],
 classType=[{
  "id": "classType/memory:sdk/tests/web/native/main.dart::A",
  "kind": "classType",
  "name": "A",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::"
}]
*/
class A {
  /*member: A.a:function=[{
  "id": "field/memory:sdk/tests/web/native/main.dart::A.a",
  "kind": "field",
  "name": "a",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::A",
  "children": [],
  "inferredType": "Value([exact=JSString], value: \"hello\")",
  "code": "",
  "type": "dynamic"
}]*/
  final a;

  /*member: A.:function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::A.A",
  "kind": "function",
  "name": "A",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "class/memory:sdk/tests/web/native/main.dart::A",
  "children": [],
  "modifiers": {
    "static": false,
    "const": true,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[exact=A]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "",
  "type": "dynamic Function()",
  "functionKind": 3
}]*/
  const A() : a = "hello";
}

/*member: constList:function=[{
  "id": "field/memory:sdk/tests/web/native/main.dart::constList",
  "kind": "field",
  "name": "constList",
  "size": 0,
  "outputUnit": "outputUnit/main",
  "parent": "library/memory:sdk/tests/web/native/main.dart::",
  "children": [],
  "inferredType": "Container([exact=JSUnmodifiableArray], element: [exact=A], length: 1)",
  "code": "",
  "type": "List<A>"
}]*/
final constList = const [
  const A(),
];

/*member: main:
 function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::main",
  "kind": "function",
  "name": "main",
  "size": 191,
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
  "code": "main() {\n      var r = [];\n      r.push([B.List_A, B.C_A, A.main__F$closure(), $.$get$C_y(), false, \"hello\"]);\n      r.push(B.C_A);\n      r.push(new A.C());\n      A.printString(A.S(r));\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
}],
 holding=[
  {"id":"field/memory:sdk/tests/web/native/main.dart::C.y","mask":null},
  {"id":"function/dart:_internal::printToConsole","mask":null},
  {"id":"function/dart:_js_helper::S","mask":null},
  {"id":"function/dart:_js_primitives::printString","mask":null},
  {"id":"function/dart:_rti::findType","mask":null},
  {"id":"function/dart:core::Error.Error","mask":null},
  {"id":"function/dart:core::print","mask":"inlined"},
  {"id":"function/dart:core::print","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::A.A","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::A.A","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::C.C._default","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::C.C.create","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::C.C.create","mask":null}]
*/
main() {
  dynamic l = [constList, const A(), F, C.y, false, A().a];
  dynamic r = [];
  r.add(l);
  r.add(const A());
  r.add(C.create(10));
  print(r);
}
