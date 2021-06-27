// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper';

/// ignore: IMPORT_INTERNAL_LIBRARY, UNUSED_IMPORT
import 'dart:_interceptors';

/*member: jsCallEmpty:SideEffects(reads nothing; writes nothing)*/
jsCallEmpty() => JS('', '#', 0);

/*member: jsCallInt:SideEffects(reads nothing; writes nothing)*/
jsCallInt() => JS('int', '#', 0);

/*member: jsCallEffectsAllDependsNoIndex:SideEffects(reads field, static; writes anything)*/
jsCallEffectsAllDependsNoIndex() => JS('effects:all;depends:no-index', '#', 0);

/*member: jsCallEffectsNoInstanceDependsNoStatic:SideEffects(reads index, field; writes index, static)*/
jsCallEffectsNoInstanceDependsNoStatic() =>
    JS('effects:no-instance;depends:no-static', '#', 0);

/*member: jsStringConcat:SideEffects(reads nothing; writes nothing)*/
jsStringConcat() => JS_STRING_CONCAT('a', 'b');

/*member: main:SideEffects(reads anything; writes anything)*/
main() {
  jsCallInt();
  jsCallEmpty();
  jsCallEffectsAllDependsNoIndex();
  jsCallEffectsNoInstanceDependsNoStatic();

  jsStringConcat();
}
