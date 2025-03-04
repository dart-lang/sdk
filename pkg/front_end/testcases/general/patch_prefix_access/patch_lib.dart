// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';
import 'main_lib.dart' as prefix;

@patch
class Class {
  int _field = prefix.value;

  @patch
  int method() => prefix.value;
}

@patch
extension Extension on int {
  static int _field = prefix.value;

  @patch
  int method() => prefix.value;
}
