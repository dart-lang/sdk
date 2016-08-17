// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ClassRefMock implements M.ClassRef {
  final String id;
  final String name;
  const ClassRefMock({this.id, this.name});
}

class ClassMock implements M.Class {
  final String id;
  final String name;
  final M.ClassRef clazz;
  final int size;
  final M.ErrorRef error;
  final bool isAbstract;
  final bool isConst;
  final bool isPatch;
  final M.LibraryRef library;
  final M.SourceLocation location;
  final M.ClassRef superclass;
  final M.InstanceRef superType;
  final Iterable<M.InstanceRef> interfaces;
  final M.InstanceRef mixin;
  final Iterable<M.ClassRef> subclasses;
  const ClassMock({this.id: 'c-id', this.name: 'c-name', this.clazz, this.size,
      this.error, this.isAbstract: false, this.isConst: false,
      this.isPatch: false, this.library, this.location, this.superclass,
      this.superType, this.interfaces: const [], this.mixin,
      this.subclasses: const []});
}
