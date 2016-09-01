// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ErrorRefMock implements M.ErrorRef {
  final String id;
  final M.ErrorKind kind;
  final String message;

  const ErrorRefMock({this.id: 'error-ref',
                      this.kind: M.ErrorKind.internalError,
                      this.message: 'Error Message'});
}

class ErrorMock implements M.Error {
  final String id;
  final M.ClassRef clazz;
  final String vmName;
  final int size;
  final M.ErrorKind kind;
  final String message;

  const ErrorMock({this.id: 'error-id', this.vmName: 'error-vmName',
                   this.clazz: const ClassMock(), this.size: 0,
                   this.kind: M.ErrorKind.internalError,
                   this.message: 'Error Message'});
}
