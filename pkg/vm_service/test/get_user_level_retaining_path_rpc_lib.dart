// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: library_private_types_in_public_api

import 'common/test_helper.dart';

@pragma('vm:entry-point') // Prevent obfuscation
class _TestConst {
  const _TestConst();
}

void _topLevelClosure() {}

@pragma('vm:entry-point') // Prevent obfuscation
late final _TestConst x;
@pragma('vm:entry-point') // Prevent obfuscation
late final Function fn;

void warmup() {
  x = const _TestConst();
  fn = _topLevelClosure;
}

@pragma('vm:entry-point') // Prevent obfuscation
_TestConst getX() => x;

@pragma('vm:entry-point') // Prevent obfuscation
Function getFn() => fn;

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: warmup);
}
