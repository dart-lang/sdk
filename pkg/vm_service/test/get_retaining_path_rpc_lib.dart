// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: library_private_types_in_public_api

import 'common/test_helper.dart';

class _TestClass {
  _TestClass();
  // Make sure these fields are not removed by the tree shaker.
  @pragma('vm:entry-point') // Prevent obfuscation
  dynamic x;
  @pragma('vm:entry-point') // Prevent obfuscation
  dynamic y;
}

_TestClass? target1 = _TestClass();
_TestClass? target2 = _TestClass();
_TestClass? target3 = _TestClass();
_TestClass? target4 = _TestClass();
_TestClass? target5 = _TestClass();
_TestClass? target6 = _TestClass();
_TestClass? target7 = _TestClass();
_TestClass? target8 = _TestClass();

@pragma('vm:entry-point') // Prevent obfuscation
Expando<_TestClass> expando = Expando<_TestClass>();
@pragma('vm:entry-point') // Prevent obfuscation
_TestClass globalObject = _TestClass();
@pragma('vm:entry-point') // Prevent obfuscation
dynamic globalList = List<dynamic>.filled(100, null);
@pragma('vm:entry-point') // Prevent obfuscation
dynamic globalMap1 = {};
@pragma('vm:entry-point') // Prevent obfuscation
dynamic globalMap2 = {};
@pragma('vm:entry-point') // Prevent obfuscation
_TestClass weakReachable = _TestClass();
@pragma('vm:entry-point') // Prevent obfuscation
_TestClass weakUnreachable = _TestClass();

void warmup() {
  globalObject.x = target1;
  globalObject.y = target2;
  globalList[12] = target3;
  globalMap1['key'] = target4;
  globalMap2[target5] = 'value';

  // The weak reference will be traced first in DFS, but the retaining path
  // include the strong reference.
  weakReachable.x = WeakReference<_TestClass>(target7!);
  weakReachable.y = target7;

  weakUnreachable.x = WeakReference<_TestClass>(target8!);
  weakUnreachable.y = null;
}

@pragma('vm:entry-point') // Prevent obfuscation
_TestClass getGlobalObject() => globalObject;

@pragma('vm:entry-point') // Prevent obfuscation
_TestClass? takeTarget1() {
  final tmp = target1;
  target1 = null;
  return tmp;
}

@pragma('vm:entry-point') // Prevent obfuscation
_TestClass? takeTarget2() {
  final tmp = target2;
  target2 = null;
  return tmp;
}

@pragma('vm:entry-point') // Prevent obfuscation
_TestClass? takeTarget3() {
  final tmp = target3;
  target3 = null;
  return tmp;
}

@pragma('vm:entry-point') // Prevent obfuscation
_TestClass? takeTarget4() {
  final tmp = target4;
  target4 = null;
  return tmp;
}

@pragma('vm:entry-point') // Prevent obfuscation
_TestClass? takeTarget5() {
  final tmp = target5;
  target5 = null;
  return tmp;
}

@pragma('vm:entry-point') // Prevent obfuscation
_TestClass? takeExpandoTarget() {
  final tmp = target6;
  target6 = null;
  final tmp2 = _TestClass();
  expando[tmp!] = tmp2;
  return tmp2;
}

@pragma('vm:entry-point') // Prevent obfuscation
_TestClass? takeWeakReachableTarget() {
  final tmp = target7;
  target7 = null;
  return tmp;
}

@pragma('vm:entry-point') // Prevent obfuscation
_TestClass? takeWeakUnreachableTarget() {
  final tmp = target8;
  target8 = null;
  return tmp;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: warmup);
}
