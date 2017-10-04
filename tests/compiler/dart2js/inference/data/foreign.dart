// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper';

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_embedded_names';

/// ignore: IMPORT_INTERNAL_LIBRARY
/// ignore: UNUSED_IMPORT
import 'dart:_interceptors';

/*element: main:[null]*/
main() {
  jsCallInt();
  jsCallEmpty();
  jsCallVoid();
  jsCallUnion();

  jsBuiltin_createFunctionTypeRti();
  jsBuiltin_rawRtiToJsConstructorName();

  jsEmbeddedGlobal_getTypeFromName();
  jsEmbeddedGlobal_libraries();

  jsStringConcat();

  jsGetStaticState();
}

/*element: jsCallEmpty:[null|subclass=Object]*/
jsCallEmpty() => JS('', '#', 0);

/*element: jsCallInt:[subclass=JSInt]*/
jsCallInt() => JS('int', '#', 0);

/*element: jsCallVoid:[null|subclass=Object]*/
jsCallVoid() => JS('void', '#', 0);

/*element: jsCallUnion:Union of [[exact=JSString], [subclass=JSInt]]*/
jsCallUnion() => JS('int|String', '#', 0);

/*element: jsBuiltin_createFunctionTypeRti:[exact=Object]*/
jsBuiltin_createFunctionTypeRti() {
  return JS_BUILTIN('returns:=Object;effects:none;depends:none',
      JsBuiltin.createFunctionTypeRti);
}

/*element: jsBuiltin_rawRtiToJsConstructorName:[exact=JSString]*/
jsBuiltin_rawRtiToJsConstructorName() {
  return JS_BUILTIN('String', JsBuiltin.rawRtiToJsConstructorName, null);
}

/*element: jsEmbeddedGlobal_getTypeFromName:[null|subclass=Object]*/
jsEmbeddedGlobal_getTypeFromName() {
  return JS_EMBEDDED_GLOBAL('', GET_TYPE_FROM_NAME);
}

/*element: jsEmbeddedGlobal_libraries:[null|exact=JSExtendableArray]*/
jsEmbeddedGlobal_libraries() {
  return JS_EMBEDDED_GLOBAL('JSExtendableArray|Null', LIBRARIES);
}

/*element: jsStringConcat:[exact=JSString]*/
jsStringConcat() => JS_STRING_CONCAT('a', 'b');

/*element: jsGetStaticState:[null|subclass=Object]*/
jsGetStaticState() => JS_GET_STATIC_STATE();
