// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*library: library=[{
  "id": "library/memory:sdk/tests/web/native/main.dart::",
  "kind": "library",
  "name": "<unnamed>",
  "size": 301,
  "children": [
    "function/memory:sdk/tests/web/native/main.dart::main"
  ],
  "canonicalUri": "memory:sdk/tests/web/native/main.dart"
}]*/

import 'lib.dart' deferred as lib;

/*member: main:
 function=[{
  "id": "function/memory:sdk/tests/web/native/main.dart::main",
  "kind": "function",
  "name": "main",
  "size": 301,
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
  "code": "main() {\n      return A.loadDeferredLibrary(\"lib\").then$1$1(new A.main_closure(), type$.Null);\n    }",
  "type": "dynamic Function()"
}],
 holding=[
  {"id":"function/dart:_js_helper::loadDeferredLibrary","mask":null},
  {"id":"function/dart:_rti::_setArrayType","mask":null},
  {"id":"function/dart:_rti::findType","mask":null},
  {"id":"function/dart:async::_Future.then","mask":"[exact=_Future]"},
  {"id":"function/memory:sdk/tests/web/native/main.dart::main.main_closure.call","mask":null},
  {"id":"function/memory:sdk/tests/web/native/main.dart::main.main_closure.call","mask":null}]
*/
main() => lib.loadLibrary().then((_) {
      (lib.funky)();
    });
