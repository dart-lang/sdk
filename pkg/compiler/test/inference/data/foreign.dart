// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper';

/// ignore: IMPORT_INTERNAL_LIBRARY, UNUSED_IMPORT
import 'dart:_interceptors';

/*member: main:[null]*/
main() {
  jsCallInt();
  jsCallEmpty();
  jsCallVoid();
  jsCallUnion();

  jsStringConcat();
}

/*member: jsCallEmpty:[null|subclass=Object]*/
jsCallEmpty() => JS('', '#', 0);

/*member: jsCallInt:[subclass=JSInt]*/
jsCallInt() => JS('int', '#', 0);

/*member: jsCallVoid:[null|subclass=Object]*/
jsCallVoid() => JS('void', '#', 0);

/*member: jsCallUnion:Union([exact=JSString], [subclass=JSInt])*/
jsCallUnion() => JS('int|String', '#', 0);

/*member: jsStringConcat:[exact=JSString]*/
jsStringConcat() => JS_STRING_CONCAT('a', 'b');
