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

/*element: jsCallEmpty:Depends on nothing, Changes nothing.*/
jsCallEmpty() => JS('', '#', 0);

/*element: jsCallInt:Depends on nothing, Changes nothing.*/
jsCallInt() => JS('int', '#', 0);

/*element: jsCallEffectsAllDependsNoIndex:Depends on field store static store, Changes [] field static.*/
jsCallEffectsAllDependsNoIndex() => JS('effects:all;depends:no-index', '#', 0);

/*element: jsCallEffectsNoInstanceDependsNoStatic:Depends on [] field store, Changes [] static.*/
jsCallEffectsNoInstanceDependsNoStatic() =>
    JS('effects:no-instance;depends:no-static', '#', 0);

/*element: jsBuiltin_createFunctionTypeRti:Depends on static store, Changes nothing.*/
jsBuiltin_createFunctionTypeRti() {
  // TODO(johnniwinther): Why doesn't this have `Depends on nothing`?
  return JS_BUILTIN('returns:=Object;effects:none;depends:none',
      JsBuiltin.createFunctionTypeRti);
}

/*element: jsBuiltin_rawRtiToJsConstructorName:Depends on [] field store static store, Changes [] field static.*/
jsBuiltin_rawRtiToJsConstructorName() {
  return JS_BUILTIN('String', JsBuiltin.rawRtiToJsConstructorName, null);
}

/*element: jsEmbeddedGlobal_getTypeFromName:Depends on static store, Changes nothing.*/
jsEmbeddedGlobal_getTypeFromName() {
  return JS_EMBEDDED_GLOBAL('', GET_TYPE_FROM_NAME);
}

/*element: jsEmbeddedGlobal_libraries:Depends on static store, Changes nothing.*/
jsEmbeddedGlobal_libraries() {
  return JS_EMBEDDED_GLOBAL('JSExtendableArray|Null', LIBRARIES);
}

/*element: jsStringConcat:Depends on nothing, Changes nothing.*/
jsStringConcat() => JS_STRING_CONCAT('a', 'b');

/*element: jsGetStaticState:Depends on nothing, Changes [] field static.*/
jsGetStaticState() => JS_GET_STATIC_STATE();

/*element: main:Depends on [] field store static store, Changes [] field static.*/
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
