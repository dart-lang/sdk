// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

/*element: main:[null]*/
main() {
  createRectangle();
}

/*strong.element: createRectangle:[null|subclass=DomRectReadOnly]*/
/*omit.element: createRectangle:[null|subclass=DomRectReadOnly]*/
// TODO(johnniwinther): Support native behavior from CFE constants:
/*strongConst.element: createRectangle:[null]*/
/*omitConst.element: createRectangle:[null]*/
Rectangle createRectangle()
    // ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
    native;
