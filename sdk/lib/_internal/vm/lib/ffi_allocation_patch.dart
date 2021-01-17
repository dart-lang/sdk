// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// All imports must be in all FFI patch files to not depend on the order
// the patches are applied.
import "dart:_internal" show patch;
import 'dart:typed_data';
import 'dart:isolate';

extension AllocatorAlloc on Allocator {
  // TODO(http://dartbug.com/38721): Implement this in the CFE to remove the
  // invocation of sizeOf<T> to enable tree shaking.
  // TODO(http://dartbug.com/39964): Add `alignmentOf<T>()` call.
  @patch
  Pointer<T> call<T extends NativeType>([int count = 1]) {
    return this.allocate(sizeOf<T>() * count);
  }
}
