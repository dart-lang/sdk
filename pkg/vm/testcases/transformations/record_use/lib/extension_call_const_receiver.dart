// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

extension Ext on String {
  @RecordUse()
  void foo(String s) {
    print(this + s);
  }
}

void main() {
  const c = '42';
  c.foo('arg'); // Call with const receiver
  Ext(c).foo('arg'); // Static call with const receiver
}
