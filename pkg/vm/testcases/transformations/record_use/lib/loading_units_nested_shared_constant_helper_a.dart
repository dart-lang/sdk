// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'loading_units_nested_shared_constant_helper_class.dart';

void runA() {
  const myInstance = MyClass(42);
  const largeInstance = WrapperClass(myInstance);
  print(largeInstance);
}
