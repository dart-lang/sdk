// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import '32997b_lib.dart' deferred as b; //# 01: compile-time error

main() async {
  await b.loadLibrary(); //# 01: continued
  print(b.m<int>(3)); //# 01: continued
}
