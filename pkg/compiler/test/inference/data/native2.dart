// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper' as foreign show JS;
import 'dart:html';

/*member: main:[null|powerset={null}]*/
main() {
  createElement();
  createRectangle();
}

/*member: createElement:[subclass=Element|powerset={I}{O}{N}]*/
Element createElement()
// ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
native;

/*member: createRectangle:[subclass=DomRectReadOnly|powerset={I}{O}{N}]*/
createRectangle() => foreign.JS('Rectangle', "#", null);
