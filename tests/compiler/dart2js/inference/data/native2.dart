// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_foreign_helper' as foreign show JS;
import 'dart:html';

/*element: main:[null]*/
main() {
  createElement();
  createRectangle();
}

/*strong.element: createElement:[null|subclass=Element]*/
/*omit.element: createElement:[null|subclass=Element]*/
// TODO(johnniwinther): Support native behavior from CFE constants:
/*strongConst.element: createElement:[null]*/
/*omitConst.element: createElement:[null]*/
Element createElement()
    // ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
    native;

/*element: createRectangle:[subclass=DomRectReadOnly]*/
createRectangle() => foreign.JS('Rectangle', "#", null);
