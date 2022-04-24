// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: library=[{
  "id": "library/memory:sdk/tests/web/native/lib2.dart::",
  "kind": "library",
  "name": "<unnamed>",
  "size": 68,
  "children": [
    "class/memory:sdk/tests/web/native/lib2.dart::A"
  ],
  "canonicalUri": "memory:sdk/tests/web/native/lib2.dart"
}]*/

// @dart = 2.7

/*class: A:class=[{
  "id": "class/memory:sdk/tests/web/native/lib2.dart::A",
  "kind": "class",
  "name": "A",
  "size": 68,
  "outputUnit": "outputUnit/1",
  "parent": "library/memory:sdk/tests/web/native/lib2.dart::",
  "modifiers": {
    "abstract": false
  },
  "children": [
    "function/memory:sdk/tests/web/native/lib2.dart::A.method"
  ]
}]*/
class A {
  const A();

  /*member: A.method:function=[{
  "id": "function/memory:sdk/tests/web/native/lib2.dart::A.method",
  "kind": "function",
  "name": "method",
  "size": 0,
  "outputUnit": "outputUnit/1",
  "parent": "class/memory:sdk/tests/web/native/lib2.dart::A",
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
  "sideEffects": "SideEffects(reads nothing; writes nothing)",
  "inlinedCount": 1,
  "code": "",
  "type": "dynamic Function()"
}]*/
  method() {}
}
