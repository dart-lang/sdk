// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*library: 
 constant=[
  {
  "id": "constant/B.C_Deferred = A.lib__funky$closure();\n",
  "kind": "constant",
  "name": "",
  "size": 39,
  "outputUnit": "outputUnit/1",
  "code": "B.C_Deferred = A.lib__funky$closure();\n"
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
  "id": "constant/B.C__RootZone = new A._RootZone();\n",
  "kind": "constant",
  "name": "",
  "size": 35,
  "outputUnit": "outputUnit/main",
  "code": "B.C__RootZone = new A._RootZone();\n"
},
  {
  "id": "constant/B.C__StringStackTrace = new A._StringStackTrace();\n",
  "kind": "constant",
  "name": "",
  "size": 51,
  "outputUnit": "outputUnit/main",
  "code": "B.C__StringStackTrace = new A._StringStackTrace();\n"
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
}],
 deferredFiles=[{
  "main.dart": {
    "name": "<unnamed>",
    "imports": {
      "lib": [
        "out_1.part.js"
      ]
    }
  }
}],
 dependencies=[{}],
 library=[{
  "id": "library/memory:sdk/tests/web/native/main.dart::",
  "kind": "library",
  "name": "<unnamed>",
  "size": 304,
  "children": [
    "function/memory:sdk/tests/web/native/main.dart::main"
  ],
  "canonicalUri": "memory:sdk/tests/web/native/main.dart"
}],
 outputUnits=[
  {
  "id": "outputUnit/1",
  "kind": "outputUnit",
  "name": "1",
  "size": 1230,
  "filename": "out_1.part.js",
  "imports": [
    "lib"
  ]
},
  {
  "id": "outputUnit/main",
  "kind": "outputUnit",
  "name": "main",
  "filename": "out",
  "imports": []
}]
*/

import 'lib.dart' deferred as lib;

/*member: main:
 closure=[{
  "id": "closure/memory:sdk/tests/web/native/main.dart::main.main_closure",
  "kind": "closure",
  "name": "main_closure",
  "size": 201,
  "outputUnit": "outputUnit/main",
  "parent": "function/memory:sdk/tests/web/native/main.dart::main",
  "function": "function/memory:sdk/tests/web/native/main.dart::main.main_closure.call"
}],
 function=[
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::main",
  "kind": "function",
  "name": "main",
  "size": 304,
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
  "inferredReturnType": "[exact=_Future]",
  "parameters": [],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "main() {\n      return A.loadDeferredLibrary(\"lib\", 0).then$1$1(new A.main_closure(), type$.Null);\n    }",
  "type": "dynamic Function()",
  "functionKind": 0
},
  {
  "id": "function/memory:sdk/tests/web/native/main.dart::main.main_closure.call",
  "kind": "function",
  "name": "call",
  "size": 84,
  "outputUnit": "outputUnit/main",
  "parent": "closure/memory:sdk/tests/web/native/main.dart::main.main_closure",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "Null",
  "inferredReturnType": "[null]",
  "parameters": [
    {
      "name": "_",
      "type": "[null|subclass=Object]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "call$1(_) {\n      A.checkDeferredIsLoaded(\"lib\");\n      C.C_Deferred.call$0();\n    }",
  "type": "Null Function(dynamic)",
  "functionKind": 2
}],
 holding=[
  {"id":"function/dart:_js_helper::loadDeferredLibrary"},
  {"id":"function/dart:_rti::_setArrayType"},
  {"id":"function/dart:_rti::findType"},
  {"id":"function/dart:async::_Future.then","mask":"[exact=_Future]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::main.main_closure.call"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::main.main_closure.call"}]
*/
main() => lib.loadLibrary().then((_) {
      (lib.funky)();
    });
