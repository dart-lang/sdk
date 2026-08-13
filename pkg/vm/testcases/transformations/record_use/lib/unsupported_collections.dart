// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  // 1. Unsupported in list
  recorded(const [someStaticMethod]);

  // 2. Unsupported in map
  recorded(const {'key': someStaticMethod});
}

void someStaticMethod() {}

@RecordUse()
void recorded(Object arg) {}
