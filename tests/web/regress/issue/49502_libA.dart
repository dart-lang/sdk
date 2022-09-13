// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library libA;

import '49502_libM.dart' show FooM;

class FooA with FooM {
  FooA();
  String toString() => "A: $bar";
}
