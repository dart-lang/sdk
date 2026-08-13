// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  ExtType(0).extTypeMethod();
}

extension type const ExtType(int i) {
  @RecordUse()
  int extTypeMethod({int i = 16}) => i;
}
