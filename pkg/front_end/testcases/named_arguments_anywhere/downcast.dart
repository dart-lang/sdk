// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void foo(String x, {required bool y, required num z}) {
}

void main() {
  final v = <String, dynamic>{'y': true, 'x': '', 'z': 1.0};
  foo(z: v['z'], y: v['y'], v['x']);
}
