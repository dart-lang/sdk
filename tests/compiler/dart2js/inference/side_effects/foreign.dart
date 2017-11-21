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

/*element: jsCallEmpty:Reads nothing; writes nothing.*/
jsCallEmpty() => JS('', '#', 0);

/*element: jsCallInt:Reads nothing; writes nothing.*/
jsCallInt() => JS('int', '#', 0);

/*element: jsCallEffectsAllDependsNoIndex:Reads field, static; writes anything.*/
jsCallEffectsAllDependsNoIndex() => JS('effects:all;depends:no-index', '#', 0);

/*element: jsCallEffectsNoInstanceDependsNoStatic:Reads index, field; writes index, static.*/
jsCallEffectsNoInstanceDependsNoStatic() =>
    JS('effects:no-instance;depends:no-static', '#', 0);

/*element: jsBuiltin_createFunctionTypeRti:Reads static; writes nothing.*/
jsBuiltin_createFunctionTypeRti() {
  // TODO(johnniwinther): Why doesn't this have `Depends on nothing`?
  return JS_BUILTIN('returns:=Object;effects:none;depends:none',
      JsBuiltin.createFunctionTypeRti);
}

/*element: jsBuiltin_rawRtiToJsConstructorName:Reads anything; writes anything.*/
jsBuiltin_rawRtiToJsConstructorName() {
  return JS_BUILTIN('String', JsBuiltin.rawRtiToJsConstructorName, null);
}

/*element: jsEmbeddedGlobal_getTypeFromName:Reads static; writes nothing.*/
jsEmbeddedGlobal_getTypeFromName() {
  return JS_EMBEDDED_GLOBAL('', GET_TYPE_FROM_NAME);
}

/*element: jsEmbeddedGlobal_libraries:Reads static; writes nothing.*/
jsEmbeddedGlobal_libraries() {
  return JS_EMBEDDED_GLOBAL('JSExtendableArray|Null', LIBRARIES);
}

/*element: jsStringConcat:Reads nothing; writes nothing.*/
jsStringConcat() => JS_STRING_CONCAT('a', 'b');

/*element: jsGetStaticState:Reads nothing; writes anything.*/
jsGetStaticState() => JS_GET_STATIC_STATE();

/*element: main:Reads anything; writes anything.*/
main() {
  jsCallInt();
  jsCallEmpty();
  jsCallEffectsAllDependsNoIndex();
  jsCallEffectsNoInstanceDependsNoStatic();

  jsBuiltin_createFunctionTypeRti();
  jsBuiltin_rawRtiToJsConstructorName();

  jsEmbeddedGlobal_getTypeFromName();
  jsEmbeddedGlobal_libraries();

  jsStringConcat();

  jsGetStaticState();
}
