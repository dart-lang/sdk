// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import 'dart:ffi';

void main() {
  print('done');
}

@Native(isLeaf: true)
external void _library_version(Pointer<version> arg0);

void library_version_wrapper(version arg0) => _library_version(arg0.address);

final class version extends Struct {
  @Int64()
  external int major;
}
