// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library generics_helper;

import 'package:expect/expect.dart';

typeParameters(mirror, parameterNames) {
  print(mirror.typeVariables.map((v) => v.simpleName).toList());
  Expect.listEquals(
      parameterNames, mirror.typeVariables.map((v) => v.simpleName).toList());
}

typeArguments(mirror, argumentMirrors) {
  Expect.listEquals(argumentMirrors, mirror.typeArguments);
}
