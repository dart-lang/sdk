// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method({int a, required int b, required final int c}) {}

class Class {
  method({int a, required int b, required final int c, required covariant final int d}) {}
}

// TODO(johnniwinther): Pass the required property to the function types.
typedef Typedef1 = Function({int a, required int b});

typedef Typedef2({int a, required int b});

Function({int a, required int b}) field;

main() {}