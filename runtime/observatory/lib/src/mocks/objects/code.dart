// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

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
  final M.CodeKind kind;
  final bool isOptimized;

  const CodeMock({this.id, this.name, this.kind, this.isOptimized: false });
}
