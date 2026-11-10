// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:my_dep/my_dep.dart' as dep;
import 'package:ws_sibling/ws_sibling.dart' as sib;

void main() {
  print('${dep.value}+${sib.value}');
}
