// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

part of 'interface_class_part_test.dart';

class A extends InterfaceClass {}

class B implements InterfaceClass {
  @override
  int foo = 1;
}
