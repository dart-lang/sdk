// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9
// Requirements=nnbd-weak


import 'infer_aliased_instance_creation_04_lib.dart';

Type typeOf<X>() => X;

void main() {
  T<num> x1 = T(typeOf<List<num>>());
  C<Iterable<num>> x2 = T(typeOf<List<num>>());
}
