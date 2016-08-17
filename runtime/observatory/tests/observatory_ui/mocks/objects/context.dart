// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ContextRefMock implements M.ContextRef {
  final String id;
  final int length;

  const ContextRefMock({this.id, this.length: 0});
}

class ContextMock implements M.Context {
  final String id;
  final M.ClassRef clazz;
  final int size;
  final int length;
  final M.Context parentContext;

  const ContextMock({this.id, this.clazz, this.size, this.length: 0,
                     this.parentContext});
}
