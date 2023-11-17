// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method(int? a, int? b) {
  int j = a ??= 0;
  b ??= 0;
}
