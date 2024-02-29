// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:kernel/kernel.dart';
import 'macro_serializer.dart';

/// [MacroSerializer] that uses blobs registered with the current [Isolate] to
/// give access to precompiled macro [Component]s.
///
/// This can only be used with the [Isolate]-based macro executor.
class IsolateMacroSerializer implements MacroSerializer {
  final List<Uri> _createdUris = [];

  @override
  Future<void> close() {
    for (Uri uri in _createdUris) {
      (Isolate.current as dynamic).unregisterKernelBlobUri(uri);
    }
    _createdUris.clear();
    return new Future.value();
  }

  @override
  Future<Uri> createUriForComponent(Component component) {
    Uri uri = (Isolate.current as dynamic)
        .createUriForKernelBlob(writeComponentToBytes(component));
    _createdUris.add(uri);
    return new Future.value(uri);
  }
}
