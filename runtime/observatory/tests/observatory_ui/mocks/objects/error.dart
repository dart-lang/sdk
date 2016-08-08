// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ErrorRefMock implements M.ErrorRef {
  final String id;
  final M.ErrorKind kind;
  final String message;
  const ErrorRefMock({this.id, this.kind, this.message});
}

class ErrorMock implements M.Error {
  final String id;
  final M.ErrorKind kind;
  final String message;
  final int size;
  const ErrorMock({this.id, this.kind, this.message, this.size});
}
