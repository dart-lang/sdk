// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
class Class {
  final bool defaultValue;

  @patch
  Class.generative({this.defaultValue = true});

  @patch
  const Class.constGenerative({this.defaultValue = true});

  @patch
  Class._private() : defaultValue = true;

  Class._privateInjected() : defaultValue = false;

  Class.redirect() : this._private(); // Ok

  Class.redirectInjected() : this._privateInjected(); // Ok
}

@patch
class Class2 {
  final int injectedField;

  @patch
  Class2(this.field) : injectedField = field;
}
