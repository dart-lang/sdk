// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'part_import_augment.dart';

import augment 'part_import_augment_lib.dart';

void method() {}
int get getter => 42;
void set setter(int value) {}

class Class {
  void method() {}
  int get getter => 42;
  void set setter(int value) {}
}