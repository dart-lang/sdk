// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart' deferred as expect;

/*member: main:[null]*/
main() {
  callLoadLibrary();
}

/*member: callLoadLibrary:[null|subclass=Object]*/
callLoadLibrary() => expect.loadLibrary();
