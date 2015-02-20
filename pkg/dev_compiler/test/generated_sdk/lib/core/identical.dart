// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

@patch
bool identical(Object a, Object b) {
  return Primitives.identicalImplementation(a, b);
}

@patch
int identityHashCode(Object object) => objectHashCode(object);
