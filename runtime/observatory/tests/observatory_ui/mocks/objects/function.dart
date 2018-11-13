// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class FunctionRefMock implements M.FunctionRef {
  final String id;
  final String name;
  final M.ObjectRef dartOwner;
  final bool isStatic;
  final bool isConst;
  final M.FunctionKind kind;

  const FunctionRefMock(
      {this.id,
      this.name,
      this.dartOwner,
      this.isStatic: false,
      this.isConst: false,
      this.kind});
}

class FunctionMock implements M.ServiceFunction {
  final String id;
  final String name;
  final M.ClassRef clazz;
  final int size;
  final M.ObjectRef dartOwner;
  final bool isStatic;
  final bool isConst;
  final M.FunctionKind kind;
  final M.SourceLocation location;
  final M.CodeRef code;
  final M.CodeRef unoptimizedCode;
  final M.FieldRef field;
  final int usageCounter;
  final M.InstanceRef icDataArray;
  final int deoptimizations;
  final bool isOptimizable;
  final bool isInlinable;
  final bool hasIntrinsic;
  final bool isRecognized;
  final bool isNative;
  final String vmName;
  const FunctionMock({
    this.id,
    this.name,
    this.clazz,
    this.size,
    this.dartOwner,
    this.isStatic: false,
    this.isConst: false,
    this.kind,
    this.location,
    this.code,
    this.unoptimizedCode,
    this.field,
    this.usageCounter: 0,
    this.icDataArray: const InstanceRefMock(),
    this.deoptimizations: 0,
    this.isOptimizable: false,
    this.isInlinable: false,
    this.hasIntrinsic: false,
    this.isRecognized: false,
    this.isNative: false,
    this.vmName: 'function-vm-name',
  });
}
