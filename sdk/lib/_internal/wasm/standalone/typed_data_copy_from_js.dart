// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;

// The standalone platform doesn't support interacting with JS typed array
// objects.

@patch
bool tryCopyExternalIntTypedData(
  Iterable<int> from,
  _IntListMixin to,
  int start,
  int skipCount,
  int count,
) {
  return false;
}

@patch
bool tryCopyExternalFloatTypedData(
  Iterable<double> from,
  _DoubleListMixin to,
  int start,
  int skipCount,
  int count,
) {
  return false;
}
