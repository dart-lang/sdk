// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--omit-implicit-checks --lax-runtime-type-to-string

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

class Class<T> {
  Class();
}

main() {
  // Since the type argument of `Class` is only needed for
  // `.runtimeType.toString()`, it is not reified, and the toString is therefore
  // 'Class<erased>' (when dart2js RTI optimizations are enabled).
  String className = (Class).toString();
  className = className.substring(0, className.indexOf('<'));
  final defaultTypeToString = new Class().runtimeType.toString();
  final instantiatedToString = new Class<int>().runtimeType.toString();
  if (!rtiOptimizationsDisabled) {
    String erasedName = '$className<erased>';
    Expect.equals(erasedName, defaultTypeToString);
    Expect.equals(erasedName, instantiatedToString);
  } else {
    Expect.equals('$className<dynamic>', defaultTypeToString);
    Expect.equals('$className<int>', instantiatedToString);
  }
}
