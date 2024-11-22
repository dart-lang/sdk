// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/dart-lang/language/issues/2809.

class A {
  int? _value;

  int? get neverGoBack => _value;
  set neverGoBack(int newValue) => _value = newValue;
}
