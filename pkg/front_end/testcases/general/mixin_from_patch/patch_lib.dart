// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
class Class {
  Class._internal({bool value = false});

  @patch
  Class.patched() : this._internal();
}

@patch
class SubClass {
  SubClass._internal() : super._internal(value: true);

  @patch
  SubClass.patched() : this._internal();
}
