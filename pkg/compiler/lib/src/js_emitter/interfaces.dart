// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Facades for pieces of the js_emitter used from other parts of the compiler.
// TODO(48820): delete after the migration is complete.
library compiler.src.js_emitter.interfaces;

import '../elements/entities.dart';

abstract class CodeEmitterTask {
  NativeEmitter get nativeEmitter;
}

abstract class NativeEmitter {
  Map<ClassEntity, List<ClassEntity>> get subtypes;
  Map<ClassEntity, List<ClassEntity>> get directSubtypes;
}
