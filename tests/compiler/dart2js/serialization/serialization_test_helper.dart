// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'dart:io';
import 'package:compiler/src/compiler.dart';
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

runTest(
    {Uri entryPoint,
    Map<String, String> memorySourceFiles: const <String, String>{},
    Uri packageConfig,
    Uri libraryRoot,
    List<String> options,
    SerializationStrategy strategy: SerializationStrategy.bytesInMemory,
    bool useDataKinds: false}) async {
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      packageConfig: packageConfig,
      libraryRoot: libraryRoot,
      options: options,
      beforeRun: (Compiler compiler) {
        compiler.stopAfterTypeInference = true;
      });
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  GlobalTypeInferenceResults globalInferenceResults = cloneInferenceResults(
      compiler, compiler.globalInference.resultsForTesting,
      strategy: strategy, useDataKinds: useDataKinds);
  compiler.generateJavaScriptCode(globalInferenceResults);
}

enum SerializationStrategy {
  bytesInMemory,
  bytesOnDisk,
  objectsInMemory,
}

List createWorldData(
    SerializationStrategy strategy, GlobalTypeInferenceResults results,
    {bool useDataKinds: false}) {
  JsClosedWorld closedWorld = results.closedWorld;
  InferredData inferredData = results.inferredData;

  List Function() getData;

  DataSink sink;
  switch (strategy) {
    case SerializationStrategy.bytesInMemory:
      ByteSink byteSink = new ByteSink();
      sink = new BinarySink(byteSink, useDataKinds: useDataKinds);
      getData = () => byteSink.builder.takeBytes();
      break;
    case SerializationStrategy.bytesOnDisk:
      Uri uri = Uri.base.resolve('world.data');
      sink =
          new BinarySink(new BufferedFileSink(uri), useDataKinds: useDataKinds);
      getData = () => new File.fromUri(uri).readAsBytesSync();
      break;
    case SerializationStrategy.objectsInMemory:
      List data = [];
      sink = new ObjectSink(data, useDataKinds: useDataKinds);
      getData = () => data;
      break;
  }
  closedWorld.writeToDataSink(sink);
  inferredData.writeToDataSink(sink);
  results.writeToDataSink(sink);
  sink.close();
  return getData();
}

GlobalTypeInferenceResults cloneInferenceResults(
    Compiler compiler, GlobalTypeInferenceResults results,
    {SerializationStrategy strategy: SerializationStrategy.bytesInMemory,
    bool useDataKinds}) {
  JsClosedWorld closedWorld = results.closedWorld;
  ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
  List<int> irData = ir.serializeComponent(component);

  List worldData =
      createWorldData(strategy, results, useDataKinds: useDataKinds);
  print('data size: ${worldData.length}');
  ir.Component newComponent = new ir.Component();
  new BinaryBuilder(irData).readComponent(newComponent);
  DataSource source;
  switch (strategy) {
    case SerializationStrategy.bytesInMemory:
    case SerializationStrategy.bytesOnDisk:
      source = new BinarySourceImpl(worldData, useDataKinds: useDataKinds);
      break;
    case SerializationStrategy.objectsInMemory:
      source = new ObjectSource(worldData, useDataKinds: useDataKinds);
      break;
  }
  JsClosedWorld newClosedWorld = new JsClosedWorld.readFromDataSource(
      compiler.options,
      compiler.reporter,
      compiler.environment,
      compiler.abstractValueStrategy,
      newComponent,
      source);
  InferredData newInferredData =
      new InferredData.readFromDataSource(source, newClosedWorld);
  GlobalTypeInferenceResults newResults =
      new GlobalTypeInferenceResults.readFromDataSource(
          source, newClosedWorld, newInferredData);
  List newWorldData =
      createWorldData(strategy, newResults, useDataKinds: useDataKinds);
  Expect.equals(worldData.length, newWorldData.length,
      "Reserialization data length mismatch.");
  for (int i = 0; i < worldData.length; i++) {
    if (worldData[i] != newWorldData[i]) {
      print('Reserialization data mismatch at offset $i:');
      for (int j = i - 50; j < i + 50; j++) {
        if (0 <= j && j <= worldData.length) {
          String text;
          if (worldData[j] == newWorldData[j]) {
            text = '${worldData[j]}';
          } else {
            text = '${worldData[j]} <> ${newWorldData[j]}';
          }
          print('${j == i ? '> ' : '  '}$j: $text');
        }
      }
      break;
    }
  }
  Expect.listEquals(worldData, newWorldData);

  return newResults;
}

class BufferedFileSink implements Sink<List<int>> {
  int offset = 0;
  List<int> buffer = new Uint8List(10000000);
  RandomAccessFile output;

  BufferedFileSink(Uri uri) {
    output = new File.fromUri(uri).openSync(mode: FileMode.write);
  }

  @override
  void add(List<int> data) {
    if (data.length > buffer.length) {
      output.writeFromSync(buffer, 0, offset);
      offset = 0;
      output.writeFromSync(data);
    } else if (offset + data.length > buffer.length) {
      output.writeFromSync(buffer, 0, offset);
      offset = data.length;
      buffer.setRange(0, offset, data);
    } else {
      buffer.setRange(offset, offset + data.length, data);
      offset += data.length;
    }
  }

  @override
  void close() {
    if (offset > 0) {
      output.writeFromSync(buffer, 0, offset);
      offset = 0;
    }
    output.closeSync();
  }
}
