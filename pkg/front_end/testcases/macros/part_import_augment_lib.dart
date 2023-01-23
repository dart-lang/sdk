// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment void method() {}
augment int get getter => 42;
augment void set setter(int value) {}

augment class Class {
  augment void method() {}
  augment int get getter => 42;
  augment void set setter(int value) {}
}