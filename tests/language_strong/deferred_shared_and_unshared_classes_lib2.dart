// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib2;

import "deferred_shared_and_unshared_classes_lib_shared.dart";

foo() {
  print(new C2());
  print(new CShared());
}
