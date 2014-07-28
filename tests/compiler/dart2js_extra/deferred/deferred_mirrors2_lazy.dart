// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lazy;

import 'deferred_mirrors2_lib3.dart';

@MirrorsUsed(metaTargets: const [Reflectable],
    override: 'lazy')
import 'dart:mirrors';

class Reflectable {
  const Reflectable();
}
