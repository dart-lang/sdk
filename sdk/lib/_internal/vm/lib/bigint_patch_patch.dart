// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

import 'dart:_vm' show FinalThreadLocal, ThreadLocal;

import "dart:typed_data" show Uint32List;

@patch
class _BigIntImpl {
  @patch
  static _DivRemResult get _cachedDivRemResult =>
      _cachedDivRemResultValue.value;

  @patch
  static RegExp get _parseRE => _parseREThreadLocal.value;

  @pragma('vm:shared')
  static final _cachedDivRemResultValue = FinalThreadLocal<_DivRemResult>(
    () => _DivRemResult(),
  );

  @pragma('vm:shared')
  static final _parseREThreadLocal = FinalThreadLocal<RegExp>(
    () => RegExp(
      r'^\s*([+-]?)((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$',
      caseSensitive: false,
    ),
  );
}
