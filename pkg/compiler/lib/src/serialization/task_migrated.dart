// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../diagnostics/diagnostic_listener.dart';
import '../inferrer/abstract_value_strategy.dart';
import '../inferrer/types.dart';
import '../js_backend/inferred_data.dart';
import '../js_model/element_map_impl.dart';
import '../js_model/js_world.dart';
import '../js_model/locals.dart';
import '../options.dart';
import '../environment.dart';
import 'serialization.dart';

/// A data class holding some data [T] and the associated [DataSourceIndices].
class DataAndIndices<T> {
  final T data;
  final DataSourceIndices indices;

  DataAndIndices(this.data, this.indices);
}

void serializeGlobalTypeInferenceResultsToSink(
    GlobalTypeInferenceResults results, DataSinkWriter sink) {
  final closedWorld = results.closedWorld;
  GlobalLocalsMap globalLocalsMap = results.globalLocalsMap;
  InferredData inferredData = results.inferredData;
  globalLocalsMap.writeToDataSink(sink);
  inferredData.writeToDataSink(sink);
  results.writeToDataSink(sink, closedWorld.elementMap);
  sink.close();
}

GlobalTypeInferenceResults deserializeGlobalTypeInferenceResultsFromSource(
    CompilerOptions options,
    DiagnosticReporter reporter,
    Environment environment,
    AbstractValueStrategy abstractValueStrategy,
    ir.Component component,
    JClosedWorld closedWorld,
    DataSourceReader source) {
  source.registerComponentLookup(ComponentLookup(component));
  source.registerEntityLookup(ClosedEntityLookup(closedWorld.elementMap));
  GlobalLocalsMap globalLocalsMap = GlobalLocalsMap.readFromDataSource(
      closedWorld.closureDataLookup.getEnclosingMember, source);
  InferredData inferredData =
      InferredData.readFromDataSource(source, closedWorld);
  return GlobalTypeInferenceResults.readFromDataSource(source,
      closedWorld.elementMap, closedWorld, globalLocalsMap, inferredData);
}

void serializeClosedWorldToSink(JClosedWorld closedWorld, DataSinkWriter sink) {
  closedWorld.writeToDataSink(sink);
  sink.close();
}

JClosedWorld deserializeClosedWorldFromSource(
    CompilerOptions options,
    DiagnosticReporter reporter,
    Environment environment,
    AbstractValueStrategy abstractValueStrategy,
    ir.Component component,
    DataSourceReader source) {
  return JClosedWorld.readFromDataSource(
      options, reporter, environment, abstractValueStrategy, component, source);
}
