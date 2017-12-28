// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/deferred_class_library.dart' deferred as lib;

/*element: isError:OutputUnit(main, {})*/
bool isError(e) => e is Error;

/*element: main:OutputUnit(main, {})*/
main() {
  lib.loadLibrary().then((_) {
    return new lib.MyClass().foo(87);
  });
}
