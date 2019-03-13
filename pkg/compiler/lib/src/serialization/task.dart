// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' as ir;
import 'package:kernel/binary/ast_to_binary.dart' as ir;
import '../../compiler_new.dart' as api;
import '../common/tasks.dart';
import '../compiler.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../environment.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../js_backend/inferred_data.dart';
import '../js_model/js_world.dart';
import '../options.dart';
import '../util/sink_adapter.dart';
import 'serialization.dart';

void serializeGlobalTypeInferenceResults(
    GlobalTypeInferenceResults results, DataSink sink) {
  JsClosedWorld closedWorld = results.closedWorld;
  InferredData inferredData = results.inferredData;
  closedWorld.writeToDataSink(sink);
  inferredData.writeToDataSink(sink);
  results.writeToDataSink(sink);
  sink.close();
}

GlobalTypeInferenceResults deserializeGlobalTypeInferenceResults(
    CompilerOptions options,
    DiagnosticReporter reporter,
    Environment environment,
    AbstractValueStrategy abstractValueStrategy,
    ir.Component component,
    DataSource source) {
  JsClosedWorld newClosedWorld = new JsClosedWorld.readFromDataSource(
      options, reporter, environment, abstractValueStrategy, component, source);
  InferredData newInferredData =
      new InferredData.readFromDataSource(source, newClosedWorld);
  return new GlobalTypeInferenceResults.readFromDataSource(
      source, newClosedWorld, newInferredData);
}

class SerializationTask extends CompilerTask {
  final Compiler compiler;

  SerializationTask(this.compiler, Measurer measurer) : super(measurer);

  @override
  String get name => 'Serialization';

  void serialize(GlobalTypeInferenceResults results) {
    measureSubtask('serialize dill', () {
      // TODO(sigmund): remove entirely: we will do this immediately as soon as
      // we get the component in the kernel/loader.dart task once we refactor
      // how we apply our modular kernel transformation for super mixin calls.
      compiler.reporter.log('Writing dill to ${compiler.options.outputUri}');
      api.BinaryOutputSink dillOutput =
          compiler.outputProvider.createBinarySink(compiler.options.outputUri);
      JsClosedWorld closedWorld = results.closedWorld;
      ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
      BinaryOutputSinkAdapter irSink = new BinaryOutputSinkAdapter(dillOutput);
      ir.BinaryPrinter printer = new ir.BinaryPrinter(irSink);
      printer.writeComponentFile(component);
      irSink.close();
    });

    measureSubtask('serialize data', () {
      compiler.reporter.log('Writing data to ${compiler.options.writeDataUri}');
      api.BinaryOutputSink dataOutput = compiler.outputProvider
          .createBinarySink(compiler.options.writeDataUri);
      DataSink sink = new BinarySink(new BinaryOutputSinkAdapter(dataOutput));
      serializeGlobalTypeInferenceResults(results, sink);
    });
  }

  Future<GlobalTypeInferenceResults> deserialize() async {
    ir.Component component =
        await measureIoSubtask('deserialize dill', () async {
      compiler.reporter.log('Reading dill from ${compiler.options.entryPoint}');
      api.Input<List<int>> dillInput = await compiler.provider.readFromUri(
          compiler.options.entryPoint,
          inputKind: api.InputKind.binary);
      ir.Component component = new ir.Component();
      new ir.BinaryBuilder(dillInput.data).readComponent(component);
      return component;
    });

    return await measureIoSubtask('deserialize data', () async {
      compiler.reporter
          .log('Reading data from ${compiler.options.readDataUri}');
      api.Input<List<int>> dataInput = await compiler.provider.readFromUri(
          compiler.options.readDataUri,
          inputKind: api.InputKind.binary);
      DataSource source = new BinarySourceImpl(dataInput.data);
      return deserializeGlobalTypeInferenceResults(
          compiler.options,
          compiler.reporter,
          compiler.environment,
          compiler.abstractValueStrategy,
          component,
          source);
    });
  }
}
