// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

String Function(String s, {int i})? _localTopLevelClosure;

@pragma('dyn-module:entry-point')
void dynamicModuleEntrypoint() {
  String f<T>(T s, {int? i}) => 'dynamic module 1: $s';
  String g(String s, {int? i}) => 'dynamic module 2: $s';
  _localTopLevelClosure = f<String>;
  topLevelClosure = _localTopLevelClosure;
  _localTopLevelClosure!('a', i: 1);
  _localTopLevelClosure = g;
  _localTopLevelClosure!('b', i: 2);
}
