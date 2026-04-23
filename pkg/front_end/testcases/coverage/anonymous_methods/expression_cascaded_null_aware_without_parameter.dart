// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? i = null;

void main() {
  i?..=> 1;
  i?..=> this;
  i?..=> this.isEven;
  i?..=> isEven;
}
