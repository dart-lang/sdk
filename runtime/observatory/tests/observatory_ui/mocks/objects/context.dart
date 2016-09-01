// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ContextRefMock implements M.ContextRef {
  final String id;
  final int length;

  const ContextRefMock({this.id: 'context-id', this.length});
}

class ContextMock implements M.Context {
  final String id;
  final M.ClassRef clazz;
  final String vmName;
  final int size;
  final int length;
  final M.Context parentContext;
  final Iterable<M.ContextElement> variables;

  const ContextMock({this.id: 'context-id', this.vmName: 'context-vmName',
                     this.clazz: const ClassMock(), this.size: 0, this.length,
                     this.parentContext, this.variables: const []});
}

class ContextElementMock implements M.ContextElement {
  final GuardedMock<M.InstanceRef> value;

  const ContextElementMock({this.value: const GuardedMock.fromValue(
      const InstanceRefMock())});
}
