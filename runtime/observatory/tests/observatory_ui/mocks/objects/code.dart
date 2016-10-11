// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class CodeRefMock implements M.CodeRef {
  final String id;
  final String name;
  final M.CodeKind kind;
  final bool isOptimized;

  const CodeRefMock({this.id, this.name, this.kind, this.isOptimized: false });
}

class CodeMock implements M.Code {
  final String id;
  final String name;
  final String vmName;
  final M.ClassRef clazz;
  final int size;
  final M.CodeKind kind;
  final bool isOptimized;
  final M.FunctionRef function;
  final M.ObjectPoolRef objectPool;
  final Iterable<M.FunctionRef> inlinedFunctions;

  const CodeMock({this.id: 'code-id', this.name: 'code-name',
                  this.vmName: 'code-vmName', this.clazz, this.size,
                  this.kind: M.CodeKind.dart, this.isOptimized: false,
                  this.function: const FunctionRefMock(),
                  this.objectPool: const ObjectPoolRefMock(),
                  this.inlinedFunctions: const []});
}
