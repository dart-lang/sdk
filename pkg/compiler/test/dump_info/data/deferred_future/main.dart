// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 constant=[
  {
  "id": "constant/B.C_A = new A.A();\n",
  "kind": "constant",
  "name": null,
  "size": 19,
  "outputUnit": "outputUnit/1",
  "code": "B.C_A = new A.A();\n"
},
  {
  "id": "constant/B.C_Deferred = B.C_A;\n",
  "kind": "constant",
  "name": null,
  "size": 22,
  "outputUnit": "outputUnit/1",
  "code": "B.C_Deferred = B.C_A;\n"
},
  {
  "id": "constant/B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n",
  "kind": "constant",
  "name": null,
  "size": 131,
  "outputUnit": "outputUnit/main",
  "code": "B.C_JS_CONST = function getTagFallback(o) {\n  var s = Object.prototype.toString.call(o);\n  return s.substring(8, s.length - 1);\n};\n"
},
  {
  "id": "constant/B.C__RootZone = new A._RootZone();\n",
  "kind": "constant",
  "name": null,
  "size": 35,
  "outputUnit": "outputUnit/main",
  "code": "B.C__RootZone = new A._RootZone();\n"
},
  {
  "id": "constant/B.C__StringStackTrace = new A._StringStackTrace();\n",
  "kind": "constant",
  "name": null,
  "size": 51,
  "outputUnit": "outputUnit/main",
  "code": "B.C__StringStackTrace = new A._StringStackTrace();\n"
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
  "id": "constant/B.JSInt_methods = J.JSInt.prototype;\n",
  "kind": "constant",
  "name": null,
  "size": 37,
  "outputUnit": "outputUnit/main",
  "code": "B.JSInt_methods = J.JSInt.prototype;\n"
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
 deferredFiles=[{
  "main.dart": {
    "name": "<unnamed>",
    "imports": {
      "lib1": [
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
  "size": 857,
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
  "size": 846,
  "filename": "out_1.part.js",
  "imports": [
    "lib1"
  ]
},
  {
  "id": "outputUnit/main",
  "kind": "outputUnit",
  "name": "main",
  "size": 190176,
  "filename": "out",
  "imports": []
}]
*/

// @dart = 2.7

import 'dart:async';
import 'lib1.dart' deferred as lib1;
import 'lib2.dart' as lib2;

/*member: main:
 function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::main",
  "kind": "function",
  "name": "main",
  "size": 857,
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
  "inferredReturnType": "[exact=_Future]",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "main() {\n      var $async$goto = 0,\n        $async$completer = A._makeAsyncAwaitCompleter(type$.dynamic);\n      var $async$main = A._wrapJsFunctionForAsync(function($async$errorCode, $async$result) {\n        if ($async$errorCode === 1)\n          return A._asyncRethrow($async$result, $async$completer);\n        while (true)\n          switch ($async$goto) {\n            case 0:\n              // Function start\n              $async$goto = 2;\n              return A._asyncAwait(A.loadDeferredLibrary(\"lib1\"), $async$main);\n            case 2:\n              // returning from await.\n              A.checkDeferredIsLoaded(\"lib1\");\n              A.checkDeferredIsLoaded(\"lib1\");\n              // implicit return\n              return A._asyncReturn(null, $async$completer);\n          }\n      });\n      return A._asyncStartSync($async$main, $async$completer);\n    }",
  "type": "dynamic Function()"
}],
 holding=[
  {"id":"function/dart:_js_helper::checkDeferredIsLoaded","mask":null},
  {"id":"function/dart:_js_helper::loadDeferredLibrary","mask":null},
  {"id":"function/dart:_rti::findType","mask":null},
  {"id":"function/dart:async::StreamIterator.StreamIterator","mask":null},
  {"id":"function/dart:async::_asyncAwait","mask":null},
  {"id":"function/dart:async::_asyncRethrow","mask":null},
  {"id":"function/dart:async::_asyncReturn","mask":null},
  {"id":"function/dart:async::_asyncStartSync","mask":null},
  {"id":"function/dart:async::_makeAsyncAwaitCompleter","mask":null},
  {"id":"function/dart:async::_wrapJsFunctionForAsync","mask":null},
  {"id":"function/memory:sdk/tests/web/native/lib2.dart::A.method","mask":"inlined"},
  {"id":"function/memory:sdk/tests/web/native/lib2.dart::A.method","mask":null}]
*/
main() async {
  await lib1.loadLibrary();
  lib1.field is FutureOr<lib2.A>;
  lib1.field.method();
}
