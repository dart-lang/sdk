// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class ClassRefMock implements M.ClassRef {
  final String id;
  final String name;
  const ClassRefMock({this.id, this.name});
}

class ClassMock implements M.ClassRef {
  final String id;
  final String name;
  final bool isAbstract;
  final bool isConst;
  final M.ClassRef superclass;
  final Iterable<M.ClassRef> subclasses;
  const ClassMock({this.id, this.name, this.isAbstract, this.isConst,
      this.superclass, this.subclasses: const []});
}
