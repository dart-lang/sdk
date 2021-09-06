// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9
// Requirements=nnbd-weak


import 'infer_aliased_factory_invocation_08_lib.dart';

void main() {
  T<int> x1 = T(int);
  C<int> x2 = T(int);
}
