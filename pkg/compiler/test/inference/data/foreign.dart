// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper';

/// ignore: IMPORT_INTERNAL_LIBRARY, UNUSED_IMPORT
import 'dart:_interceptors';

/*member: main:[null|powerset={null}]*/
main() {
  jsCallInt();
  jsCallEmpty();
  jsCallVoid();
  jsCallUnion();

  jsStringConcat();
}

/*member: jsCallEmpty:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
jsCallEmpty() => JS('', '#', 0);

/*member: jsCallInt:[subclass=JSInt|powerset={I}{O}{N}]*/
jsCallInt() => JS('int', '#', 0);

/*member: jsCallVoid:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
jsCallVoid() => JS('void', '#', 0);

/*member: jsCallUnion:Union([exact=JSString|powerset={I}{O}{I}], [subclass=JSInt|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
jsCallUnion() => JS('int|String', '#', 0);

/*member: jsStringConcat:[exact=JSString|powerset={I}{O}{I}]*/
jsStringConcat() => JS_STRING_CONCAT('a', 'b');
