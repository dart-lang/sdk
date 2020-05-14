// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'issue41210_lib2.dart';

mixin A implements Interface {
  String method({String s = "hello"}) => s;
}

abstract class B implements Interface {}

void main() {}
