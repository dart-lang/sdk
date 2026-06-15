// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? i = null;

void main() {
  i?.(p) => 1;
  i?.(p) => p;
  i?.(p) => p.isEven;
}
