// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;

/// A dynamic module can use mixin with a field.
void main() async {
  final func = (await helper.load('entry1.dart')) as void Function();
  func();
  helper.done();
}
