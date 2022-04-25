// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
class Class<T> {
  @patch
  Class({bool defaultValue: true, required T value}) {
    print('patch Class');
  }

  @patch
  factory Class.fact({bool defaultValue: true, required T value}) =>
      new ClassImpl<T>(defaultValue: defaultValue, value: value);

  @patch
  factory Class.redirect({bool defaultValue, required T value}) = ClassImpl<T>;

  @patch
  factory Class.redirect2({bool defaultValue, required T value}) =
      ClassImpl<T>.patched;
}

@patch
class ClassImpl<T> implements Class<T> {
  @patch
  ClassImpl.patched({bool defaultValue: true, required T value}) {
    print('patch ClassImpl');
  }
}
