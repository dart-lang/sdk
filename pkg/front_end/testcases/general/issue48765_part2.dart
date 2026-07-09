// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'issue48765.dart';

abstract class _B {}

class _Bc implements _B {}

extension on _B {
  static int field = 0;
  void method() {
    field++;
  }
}
