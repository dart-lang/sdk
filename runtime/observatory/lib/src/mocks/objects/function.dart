// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class FunctionRefMock implements M.FunctionRef {
  final String id;
  final String name;
  final M.ObjectRef dartOwner;
  final bool isStatic;
  final bool isConst;
  final M.FunctionKind kind;

  const FunctionRefMock({this.id, this.name, this.dartOwner,
      this.isStatic : false, this.isConst : false, this.kind});
}

class FunctionMock implements M.Function {
  final String id;
  final String name;
  final M.ObjectRef dartOwner;
  final bool isStatic;
  final bool isConst;
  final M.FunctionKind kind;
  final M.SourceLocation location;
  final M.CodeRef code;
  const FunctionMock({this.id, this.name, this.dartOwner,
      this.isStatic : false, this.isConst : false, this.kind, this.location,
      this.code});
}
