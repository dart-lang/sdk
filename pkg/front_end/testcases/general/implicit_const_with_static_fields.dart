// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const constTopLevelField = 42;

class C {
  const C(x);
  static const constField = 87;
}

main() {
  C(C.constField);
  C(constTopLevelField);
}
