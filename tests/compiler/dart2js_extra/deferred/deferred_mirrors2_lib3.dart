// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib3;

import 'deferred_mirrors2_lib4.dart';

@MirrorsUsed(targets: const [
    'lib3'
])
import 'dart:mirrors';

class R {
  void bind(Type type) {
    ClassMirror classMirror = _reflectClass(type);
    MethodMirror ctor = classMirror.declarations[classMirror.simpleName];
    int length = ctor.parameters.length;
    Function create = classMirror.newInstance;
  }
}
