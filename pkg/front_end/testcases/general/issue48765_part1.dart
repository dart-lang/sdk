// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'issue48765.dart';

abstract class _A {}

class _Ac implements _A {}

extension on _A {
  static int field = 0;
  void method() {
    field++;
  }
}
