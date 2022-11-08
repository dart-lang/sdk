// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Facades for pieces of the js_emitter used from other parts of the compiler.
// TODO(48820): delete after the migration is complete.
library compiler.src.js_emitter.interfaces;

import '../constants/values.dart';
import '../deferred_load/output_unit.dart' show OutputUnit;
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;

import 'metadata_collector.dart' show MetadataCollector;
import 'startup_emitter/fragment_merger.dart';

abstract class CodeEmitterTask {
  Set<ClassEntity> get neededClasses;
  Set<ClassEntity> get neededClassTypes;
  NativeEmitter get nativeEmitter;
  Emitter get emitter;
  MetadataCollector get metadataCollector;
}

abstract class NativeEmitter {
  Map<ClassEntity, List<ClassEntity>> get subtypes;
  Map<ClassEntity, List<ClassEntity>> get directSubtypes;
  Set<FunctionEntity> get nativeMethods;
  List<jsAst.Statement> generateParameterStubStatements(
      FunctionEntity member,
      bool isInterceptedMethod,
      jsAst.Name invocationName,
      List<jsAst.Parameter> stubParameters,
      List<jsAst.Expression> argumentsBuffer,
      int indexOfLastOptionalArgumentInParameters);
}

abstract class ModularEmitter {
  jsAst.Expression constructorAccess(ClassEntity e);
  jsAst.Expression constantReference(ConstantValue constant);
  jsAst.Expression isolateLazyInitializerAccess(covariant FieldEntity element);
  jsAst.Expression prototypeAccess(ClassEntity e);
  jsAst.Expression staticClosureAccess(covariant FunctionEntity element);
  jsAst.Expression staticFieldAccess(FieldEntity element);
  jsAst.Expression staticFunctionAccess(FunctionEntity element);
  jsAst.Name typeVariableAccessNewRti(TypeVariableEntity element);
  jsAst.Name typeAccessNewRti(ClassEntity element);
}

abstract class Emitter extends ModularEmitter {
  Map<String, List<FinalizedFragment>> get finalizedFragmentsToLoad;
  FragmentMerger get fragmentMerger;
  int generatedSize(OutputUnit unit);
  jsAst.Expression interceptorPrototypeAccess(ClassEntity e);
  jsAst.Expression generateEmbeddedGlobalAccess(String global);
  int compareConstants(ConstantValue a, ConstantValue b);
  jsAst.Expression interceptorClassAccess(ClassEntity e);
}
