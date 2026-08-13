// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

void main() {
  const a = SomeEnum.value;
  final b = SomeEnum.value;

  print('a == b: ${a == b}');
  print('a hash: ${a.hashCode}');
  print('b hash: ${b.hashCode}');
}
