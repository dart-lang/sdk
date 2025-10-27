// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class Child extends Base {}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  return Child().publicMethod(Child());
}
