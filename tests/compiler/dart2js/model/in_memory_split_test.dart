// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/js_backend/inferred_data.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:compiler/src/types/types.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/fasta/kernel/utils.dart' as ir
    show serializeComponent;
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;
import '../helpers/memory_compiler.dart';

main(List<String> args) {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('debug', abbr: 'd', defaultsTo: false);
  argParser.addFlag('object', abbr: 'o', defaultsTo: false);
  argParser.addFlag('kinds', abbr: 'k', defaultsTo: false);
  ArgResults argResults = argParser.parse(args);

  bool useObjectSink = argResults['object'] || argResults['debug'];
  bool useDataKinds = argResults['kinds'] || argResults['debug'];

  asyncTest(() async {
    Uri entryPoint;
    if (argResults.rest.isEmpty) {
      entryPoint = Uri.base.resolve('samples-dev/swarm/swarm.dart');
    } else {
      entryPoint = Uri.base.resolve(nativeToUriPath(argResults.rest.last));
    }

    CompilationResult result = await runCompiler(
        entryPoint: entryPoint,
        beforeRun: (Compiler compiler) {
          compiler.stopAfterTypeInference = true;
        });
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    GlobalTypeInferenceResults globalInferenceResults = cloneInferenceResults(
        compiler, compiler.globalInference.resultsForTesting,
        useObjectSink: useObjectSink, useDataKinds: useDataKinds);
    compiler.generateJavaScriptCode(globalInferenceResults);
  });
}

GlobalTypeInferenceResults cloneInferenceResults(
    Compiler compiler, GlobalTypeInferenceResults results,
    {bool useObjectSink: false, bool useDataKinds}) {
  JsClosedWorld closedWorld = results.closedWorld;
  InferredData inferredData = results.inferredData;
  ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
  List<int> irData = ir.serializeComponent(component);

  Function() getData;

  DataSink sink;
  if (useObjectSink) {
    List data = [];
    sink = new ObjectSink(data, useDataKinds: useDataKinds);
    getData = () => data;
  } else {
    ByteSink byteSink = new ByteSink();
    sink = new BinarySink(byteSink, useDataKinds: useDataKinds);
    getData = () => byteSink.builder.takeBytes();
  }
  closedWorld.writeToDataSink(sink);
  inferredData.writeToDataSink(sink);
  results.writeToDataSink(sink);
  sink.close();
  var worldData = getData();
  print('data size: ${worldData.length}');

  ir.Component newComponent = new ir.Component();
  new BinaryBuilder(irData).readComponent(newComponent);
  DataSource source = useObjectSink
      ? new ObjectSource(worldData, useDataKinds: useDataKinds)
      : new BinarySourceImpl(worldData, useDataKinds: useDataKinds);
  closedWorld = new JsClosedWorld.readFromDataSource(
      compiler.options,
      compiler.reporter,
      compiler.environment,
      compiler.abstractValueStrategy,
      newComponent,
      source);
  inferredData = new InferredData.readFromDataSource(source, closedWorld);
  results = new GlobalTypeInferenceResults.readFromDataSource(
      source, closedWorld, inferredData);
  return results;
}
