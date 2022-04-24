// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: library=[{
  "id": "library/memory:sdk/tests/web/native/main.dart::",
  "kind": "library",
  "name": "<unnamed>",
  "size": 857,
  "children": [
    "function/memory:sdk/tests/web/native/main.dart::main"
  ],
  "canonicalUri": "memory:sdk/tests/web/native/main.dart"
}]*/

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
