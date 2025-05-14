// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper' as foreign show JS;
import 'dart:html';

/*member: main:[null|powerset=1]*/
main() {
  createElement();
  createRectangle();
}

/*member: createElement:[subclass=Element|powerset=0]*/
Element createElement()
// ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
native;

/*member: createRectangle:[subclass=DomRectReadOnly|powerset=0]*/
createRectangle() => foreign.JS('Rectangle', "#", null);
