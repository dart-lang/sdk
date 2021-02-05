// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong --omit-implicit-checks --lax-runtime-type-to-string --experiment-new-rti

import 'package:expect/expect.dart';

class Class<T> {
  Class();
}

main() {
  // Since the type argument of `Class` is only needed for
  // `.runtimeType.toString()`, it is not reified, and the toString is therefore
  // 'Class<erased>'.
  String className = (Class).toString();
  className = className.substring(0, className.indexOf('<'));
  String erasedName = '$className<erased>';
  Expect.equals(erasedName, new Class().runtimeType.toString());
  Expect.equals(erasedName, new Class<int>().runtimeType.toString());
}
