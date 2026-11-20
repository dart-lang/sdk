// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// ignore: invalid_language_version_override
// @dart = 3.6

import 'common/test_helper.dart';

part 'library_dependency_shared_prefix_part1.dart';

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: usePrefixes);
}
