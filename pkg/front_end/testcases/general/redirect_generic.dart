// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {
  factory Class(void Function(T) f) = ClassImpl<T>;
}

class ClassImpl<T> implements Class<T> {
  ClassImpl(void Function(T) f);
}
