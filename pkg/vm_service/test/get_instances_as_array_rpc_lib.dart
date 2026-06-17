// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

@pragma('vm:entry-point')
class Class {}

@pragma('vm:entry-point')
class Subclass extends Class {}

@pragma('vm:entry-point')
class Implementor implements Class {}

@pragma('vm:entry-point')
late final Class aClass;
@pragma('vm:entry-point')
late final Subclass aSubclass;
@pragma('vm:entry-point')
late final Implementor anImplementor;

@pragma('vm:entry-point')
void allocate() {
  aClass = Class();
  aSubclass = Subclass();
  anImplementor = Implementor();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest();
}
