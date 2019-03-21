// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  nativeMethod();
}

/*strong.element: nativeMethod:[null|subclass=Object]*/
/*omit.element: nativeMethod:[null|subclass=Object]*/
// TODO(johnniwinther): Support native behavior from CFE constants:
/*strongConst.element: nativeMethod:[null]*/
/*omitConst.element: nativeMethod:[null]*/
nativeMethod()
    // ignore: NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE
    native;
