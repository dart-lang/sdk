// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../inferrer/types.dart';
import '../inferrer_experimental/types.dart' as experimentalInferrer;
import '../js_backend/inferred_data.dart';
import '../js_emitter/interfaces.dart' show CodeEmitterTask;
import '../world_interfaces.dart';
import 'locals.dart';

abstract class JsBackendStrategy {
  CodeEmitterTask get emitterTask;
  TypesInferrer createTypesInferrer(JClosedWorld closedWorld,
      GlobalLocalsMap globalLocalsMap, InferredDataBuilder inferredDataBuilder);
  experimentalInferrer.TypesInferrer createExperimentalTypesInferrer(
      JClosedWorld closedWorld,
      GlobalLocalsMap globalLocalsMap,
      InferredDataBuilder inferredDataBuilder);
}
