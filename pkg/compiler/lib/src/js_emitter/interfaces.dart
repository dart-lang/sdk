// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Facades for pieces of the js_emitter used from other parts of the compiler.
// TODO(48820): delete after the migration is complete.
library compiler.src.js_emitter.interfaces;

import '../elements/entities.dart';
import '../deferred_load/output_unit.dart' show OutputUnit;
import 'startup_emitter/fragment_merger.dart';

abstract class CodeEmitterTask {
  Set<ClassEntity> get neededClasses;
  Set<ClassEntity> get neededClassTypes;
  NativeEmitter get nativeEmitter;
  Emitter get emitter;
}

abstract class NativeEmitter {
  Map<ClassEntity, List<ClassEntity>> get subtypes;
  Map<ClassEntity, List<ClassEntity>> get directSubtypes;
}

abstract class Emitter {
  Map<String, List<FinalizedFragment>> get finalizedFragmentsToLoad;
  FragmentMerger get fragmentMerger;
  int generatedSize(OutputUnit unit);
}
