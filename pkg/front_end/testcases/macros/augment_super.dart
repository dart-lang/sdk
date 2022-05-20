// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import augment 'augment_super_lib.dart';

void topLevelMethod() {}
void topLevelMethodErrors() {}
List<int> get topLevelProperty => [42];
void set topLevelProperty(List<int> value) {}

class Class {
  void instanceMethod() {}
  void instanceMethodErrors() {}
  int get instanceProperty => 42;
  void set instanceProperty(int value) {}
}

main() {}