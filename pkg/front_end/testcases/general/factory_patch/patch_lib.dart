// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
class Class {
  final bool defaultValue;

  const Class._internal({this.defaultValue: false});

  @patch
  factory Class.fact({bool defaultValue: true}) =>
      new Class._internal(defaultValue: defaultValue);

  @patch
  factory Class.constFact({bool defaultValue: true}) => throw 'unsupported';

  @patch
  const factory Class.redirect({bool defaultValue: true}) = Class._internal;
}
