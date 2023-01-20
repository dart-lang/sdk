// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

part of 'mixin_class_part_test.dart';

class A with MixinClass {}

abstract class B with MixinClass {}

class NonMixinClass {
  int foo = 0;
}
