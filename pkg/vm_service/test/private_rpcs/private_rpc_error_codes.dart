// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum PrivateRpcErrorCodes {
  kFileSystemAlreadyExists(code: 1001),
  kFileSystemDoesNotExist(code: 1002),
  kFileDoesNotExist(code: 1003);

  const PrivateRpcErrorCodes({required this.code});
  final int code;
}
