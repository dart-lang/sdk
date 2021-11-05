// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int? classField1;
  int classField2 = 0;
  int? classMethod(int i) {}
}

mixin Mixin {
  int? mixinField1;
  int mixinField2 = 0;
  int? mixinMethod(int i) {
    super.toString();
  }
}
