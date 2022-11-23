// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../elements/entities.dart';
import '../inferrer/types.dart';
import '../inferrer_experimental/types.dart' as experimentalInferrer;
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/custom_elements_analysis.dart';
import '../js_backend/inferred_data.dart';
import '../js_backend/runtime_types.dart';
import '../js_emitter/js_emitter.dart' show CodeEmitterTask;
import '../js_model/js_world.dart' show JClosedWorld;
import '../native/enqueue.dart';
import '../serialization/serialization.dart';
import 'locals.dart';

abstract class JsBackendStrategy {
  CodeEmitterTask get emitterTask;
  TypesInferrer createTypesInferrer(JClosedWorld closedWorld,
      GlobalLocalsMap globalLocalsMap, InferredDataBuilder inferredDataBuilder);
  experimentalInferrer.TypesInferrer createExperimentalTypesInferrer(
      JClosedWorld closedWorld,
      GlobalLocalsMap globalLocalsMap,
      InferredDataBuilder inferredDataBuilder);
  RuntimeTypesChecksBuilder get rtiChecksBuilder;
  NativeEnqueuer get nativeCodegenEnqueuer;
  SourceInformationStrategy get sourceInformationStrategy;
  CustomElementsCodegenAnalysis get customElementsCodegenAnalysis;
  Map<MemberEntity, js.Expression> get generatedCode;
  void prepareCodegenReader(DataSourceReader source);
  EntityWriter forEachCodegenMember(void Function(MemberEntity member) f);
}
