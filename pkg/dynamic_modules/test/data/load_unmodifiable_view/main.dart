// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

/// Dynamic module can be loaded from unmodifiable view.
main() async {
  final result = await helper.load('entry1.dart',
      transformBytes: (Uint8List bytes) => bytes.buffer
          .asUint8List(0, bytes.lengthInBytes)
          .asUnmodifiableView());
  Expect.equals(42, result);
  helper.done();
}
