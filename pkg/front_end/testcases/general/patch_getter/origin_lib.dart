// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

external int get topLevelGetter;

class Class {
  Class();

  external int get instanceGetter;

  external static int get staticGetter;
}

extension Extension on int {
  external int get instanceGetter;

  external static int get staticGetter;
}

methodInOrigin() {
  topLevelGetter;
  Class.staticGetter;
  Extension.staticGetter;
  Class c = new Class();
  c.instanceGetter;
  0.instanceGetter;
}
