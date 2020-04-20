// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
class Class<T extends num> {
  @patch
  Class.patchedConstructor(int i, T j)
      : this.a = i,
        this.b = j {
    int k;
    k;
  }

  @patch
  int patchedMethod(int i) {
    int k;
    int j = i;
    return k;
  }

  int _injectedMethod(int i) {
    int k;
    int j = i;
    return k;
  }
}

@patch
int patchedMethod(int i) {
  int k;
  int j = i;
  return k;
}

int _injectedMethod(int i) {
  int k;
  int j = i;
  return k;
}
