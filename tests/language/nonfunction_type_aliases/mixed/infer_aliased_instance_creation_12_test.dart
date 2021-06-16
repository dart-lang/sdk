// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9
// Requirements=nnbd-weak


import 'infer_aliased_instance_creation_12_lib.dart';

void main() {
  T<int, String> x1 = T(String, int);
  C<String, int> x2 = T(String, int);
}
