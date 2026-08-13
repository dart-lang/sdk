// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib1.dart';

main() {
  0.instanceProperty = 1.instanceProperty;
  2.instanceMethod();
  3.instanceMethod;
  Extension.staticField = Extension.staticConstField;
  3.instanceProperty = Extension.staticFinalField;
  Extension.staticProperty = Extension.staticProperty;
  Extension.staticMethod();
  Extension.staticMethod;
}
