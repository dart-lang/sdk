// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Writing to a name whose getter is ambiguous is fine when only one of the
// imported libraries declares the setter.

import 'ambiguous_getter_with_setter_lib2.dart' as p;
import 'ambiguous_getter_with_setter_lib1.dart' as p;

void main() {
  p.x = 'hello';
}
