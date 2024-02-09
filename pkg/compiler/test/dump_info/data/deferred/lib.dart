// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: library=[{
  "id": "library/memory:sdk/tests/web/native/lib.dart::",
  "kind": "library",
  "name": "<unnamed>",
  "size": 289,
  "children": [
    "function/memory:sdk/tests/web/native/lib.dart::defaultArg",
    "function/memory:sdk/tests/web/native/lib.dart::funky"
  ],
  "canonicalUri": "memory:sdk/tests/web/native/lib.dart"
}]*/

// @dart = 2.7

/*member: defaultArg:function=[{
  "id": "function/memory:sdk/tests/web/native/lib.dart::defaultArg",
  "kind": "function",
  "name": "defaultArg",
  "size": 95,
  "outputUnit": "outputUnit/1",
  "parent": "library/memory:sdk/tests/web/native/lib.dart::",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "Value([exact=JSString], value: \"\")",
  "parameters": [],
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 0,
  "code": "defaultArg() {\n      return \"\";\n    }\n_static_0(A, \"lib__defaultArg$closure\", \"defaultArg\", 0);\n",
  "type": "dynamic Function()",
  "functionKind": 0
}]*/
defaultArg() => "";

/*member: funky:function=[{
  "id": "function/memory:sdk/tests/web/native/lib.dart::funky",
  "kind": "function",
  "name": "funky",
  "size": 194,
  "outputUnit": "outputUnit/1",
  "parent": "library/memory:sdk/tests/web/native/lib.dart::",
  "children": [],
  "modifiers": {
    "static": false,
    "const": false,
    "factory": false,
    "external": false
  },
  "returnType": "dynamic",
  "inferredReturnType": "[null|subclass=Object]",
  "parameters": [
    {
      "name": "x",
      "type": "[subclass=Closure]",
      "declaredType": "dynamic"
    }
  ],
  "sideEffects": "SideEffects(reads anything; writes anything)",
  "inlinedCount": 0,
  "code": "funky(x) {\n      return x.call$0();\n    }\n_static(A, \"lib__funky$closure\", 0, null, [\"call$1\", \"call$0\"], [\"funky\", function() {\n      return A.funky(A.lib__defaultArg$closure());\n    }], 1, 0);\n",
  "type": "dynamic Function([dynamic])",
  "functionKind": 0
}]*/
funky([x = defaultArg]) => x();

final int notUsed = 3;
