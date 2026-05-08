// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

import "dart:typed_data" show Uint32List;

@patch
class _BigIntImpl {
  @patch
  static _DivRemResult get _cachedDivRemResult => _cachedDivRemResultValue;

  @patch
  static RegExp get _parseRE => _parseREValue;

  static final _cachedDivRemResultValue = _DivRemResult();

  static final RegExp _parseREValue = RegExp(
    r'^\s*([+-]?)((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$',
    caseSensitive: false,
  );
}
