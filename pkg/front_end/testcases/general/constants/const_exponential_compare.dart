// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  final Class? next1;
  final Class? next2;
  const Class([Class? next])
      : next1 = next,
        next2 = next;
}

const Class test = const Class(Class(Class(Class(Class(Class(Class(Class(Class(
    Class(Class(Class(Class(Class(
        Class(Class(Class(Class(Class(Class(Class(Class())))))))))))))))))))));
