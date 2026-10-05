// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  final i64 = Int64List.fromList([10, 20, 30]);

  final subView = ByteData.sublistView(i64, 1, 2);
  final unmodifiableSubView = subView.asUnmodifiableView();
  Expect.equals(8, unmodifiableSubView.offsetInBytes);
  Expect.equals(8, unmodifiableSubView.lengthInBytes);
  Expect.equals(20, unmodifiableSubView.getInt64(0, Endian.host));

  final unmodifiableI64 = i64.asUnmodifiableView();
  final subViewFromUnmodifiable = ByteData.sublistView(unmodifiableI64, 1, 2);
  Expect.equals(8, subViewFromUnmodifiable.offsetInBytes);
  Expect.equals(8, subViewFromUnmodifiable.lengthInBytes);
  Expect.equals(20, subViewFromUnmodifiable.getInt64(0, Endian.host));
}
