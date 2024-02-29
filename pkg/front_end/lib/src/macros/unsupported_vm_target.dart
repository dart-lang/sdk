// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/target/targets.dart' show Target, TargetFlags;

class VmTarget implements Target {
  VmTarget(TargetFlags _) {
    throw new UnsupportedError('This platform does not support VmTarget.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
