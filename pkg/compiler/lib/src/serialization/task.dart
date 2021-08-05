// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' as ir;
import 'package:kernel/binary/ast_to_binary.dart' as ir;
import '../../compiler_new.dart' as api;
import '../backend_strategy.dart';
import '../commandline_options.dart' show Flags;
import '../common/codegen.dart';
import '../common/tasks.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../elements/entities.dart';
import '../environment.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../js_backend/backend.dart';
import '../js_backend/inferred_data.dart';
import '../js_model/js_world.dart';
import '../js_model/element_map_impl.dart';
import '../js_model/locals.dart';
import '../options.dart';
import '../util/sink_adapter.dart';
import '../world.dart';
import 'serialization.dart';

void serializeGlobalTypeInferenceResultsToSink(
    GlobalTypeInferenceResults results, DataSink sink) {
  JsClosedWorld closedWorld = results.closedWorld;
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
    JsClosedWorld closedWorld,
    DataSource source) {
  source.registerComponentLookup(ComponentLookup(component));
  source.registerEntityLookup(ClosedEntityLookup(closedWorld.elementMap));
  GlobalLocalsMap globalLocalsMap = GlobalLocalsMap.readFromDataSource(
      closedWorld.closureDataLookup.getEnclosingMember, source);
  InferredData inferredData =
      InferredData.readFromDataSource(source, closedWorld);
  return GlobalTypeInferenceResults.readFromDataSource(source,
      closedWorld.elementMap, closedWorld, globalLocalsMap, inferredData);
}

void serializeGlobalTypeInferenceResultsToSinkLegacy(
    GlobalTypeInferenceResults results, DataSink sink) {
  JsClosedWorld closedWorld = results.closedWorld;
  GlobalLocalsMap globalLocalsMap = results.globalLocalsMap;
  InferredData inferredData = results.inferredData;
  closedWorld.writeToDataSink(sink);
  globalLocalsMap.writeToDataSink(sink);
  inferredData.writeToDataSink(sink);
  results.writeToDataSink(sink, closedWorld.elementMap);
  sink.close();
}

GlobalTypeInferenceResults
    deserializeGlobalTypeInferenceResultsFromSourceLegacy(
        CompilerOptions options,
        DiagnosticReporter reporter,
        Environment environment,
        AbstractValueStrategy abstractValueStrategy,
        ir.Component component,
        DataSource source) {
  JsClosedWorld newClosedWorld = new JsClosedWorld.readFromDataSource(
      options, reporter, environment, abstractValueStrategy, component, source);
  GlobalLocalsMap newGlobalLocalsMap = GlobalLocalsMap.readFromDataSource(
      newClosedWorld.closureDataLookup.getEnclosingMember, source);
  InferredData newInferredData =
      new InferredData.readFromDataSource(source, newClosedWorld);
  return new GlobalTypeInferenceResults.readFromDataSource(
      source,
      newClosedWorld.elementMap,
      newClosedWorld,
      newGlobalLocalsMap,
      newInferredData);
}

void serializeClosedWorldToSink(JsClosedWorld closedWorld, DataSink sink) {
  closedWorld.writeToDataSink(sink);
  sink.close();
}

JsClosedWorld deserializeClosedWorldFromSource(
    CompilerOptions options,
    DiagnosticReporter reporter,
    Environment environment,
    AbstractValueStrategy abstractValueStrategy,
    ir.Component component,
    DataSource source) {
  return new JsClosedWorld.readFromDataSource(
      options, reporter, environment, abstractValueStrategy, component, source);
}

class _StringInterner implements ir.StringInterner, StringInterner {
  Map<String, String> _map = {};

  @override
  String internString(String string) {
    return _map[string] ??= string;
  }
}

class SerializationTask extends CompilerTask {
  final CompilerOptions _options;
  final DiagnosticReporter _reporter;
  final api.CompilerInput _provider;
  final api.CompilerOutput _outputProvider;
  final _stringInterner = _StringInterner();

  SerializationTask(this._options, this._reporter, this._provider,
      this._outputProvider, Measurer measurer)
      : super(measurer);

  @override
  String get name => 'Serialization';

  void serializeComponent(ir.Component component) {
    measureSubtask('serialize dill', () {
      // TODO(sigmund): remove entirely: we will do this immediately as soon as
      // we get the component in the kernel/loader.dart task once we refactor
      // how we apply our modular kernel transformation for super mixin calls.
      _reporter.log('Writing dill to ${_options.outputUri}');
      api.BinaryOutputSink dillOutput =
          _outputProvider.createBinarySink(_options.outputUri);
      BinaryOutputSinkAdapter irSink = new BinaryOutputSinkAdapter(dillOutput);
      ir.BinaryPrinter printer = new ir.BinaryPrinter(irSink);
      printer.writeComponentFile(component);
      irSink.close();
    });
  }

  Future<ir.Component> deserializeComponent() async {
    return measureIoSubtask('deserialize dill', () async {
      _reporter.log('Reading dill from ${_options.entryPoint}');
      api.Input<List<int>> dillInput = await _provider
          .readFromUri(_options.entryPoint, inputKind: api.InputKind.binary);
      ir.Component component = new ir.Component();
      // Not using growable lists saves memory.
      ir.BinaryBuilder(dillInput.data,
              useGrowableLists: false, stringInterner: _stringInterner)
          .readComponent(component);
      return component;
    });
  }

  void updateOptionsFromComponent(ir.Component component) {
    var isStrongDill =
        component.mode == ir.NonNullableByDefaultCompiledMode.Strong;
    var incompatibleNullSafetyMode =
        isStrongDill ? NullSafetyMode.unsound : NullSafetyMode.sound;
    if (_options.nullSafetyMode == incompatibleNullSafetyMode) {
      var dillMode = isStrongDill ? 'sound' : 'unsound';
      var option =
          isStrongDill ? Flags.noSoundNullSafety : Flags.soundNullSafety;
      throw ArgumentError("${_options.entryPoint} was compiled with $dillMode "
          "null safety and is incompatible with the '$option' option");
    }

    _options.nullSafetyMode =
        component.mode == ir.NonNullableByDefaultCompiledMode.Strong
            ? NullSafetyMode.sound
            : NullSafetyMode.unsound;
  }

  Future<ir.Component> deserializeComponentAndUpdateOptions() async {
    ir.Component component = await deserializeComponent();
    updateOptionsFromComponent(component);
    return component;
  }

  void serializeClosedWorld(JsClosedWorld closedWorld) {
    measureSubtask('serialize closed world', () {
      _reporter.log('Writing closed world to ${_options.writeClosedWorldUri}');
      api.BinaryOutputSink dataOutput =
          _outputProvider.createBinarySink(_options.writeClosedWorldUri);
      DataSink sink = new BinarySink(new BinaryOutputSinkAdapter(dataOutput));
      serializeClosedWorldToSink(closedWorld, sink);
    });
  }

  Future<JsClosedWorld> deserializeClosedWorld(
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component) async {
    return await measureIoSubtask('deserialize closed world', () async {
      _reporter.log('Reading data from ${_options.readClosedWorldUri}');
      api.Input<List<int>> dataInput = await _provider.readFromUri(
          _options.readClosedWorldUri,
          inputKind: api.InputKind.binary);
      DataSource source =
          BinarySourceImpl(dataInput.data, stringInterner: _stringInterner);
      return deserializeClosedWorldFromSource(_options, _reporter, environment,
          abstractValueStrategy, component, source);
    });
  }

  void serializeGlobalTypeInference(GlobalTypeInferenceResults results) {
    JsClosedWorld closedWorld = results.closedWorld;
    ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
    serializeComponent(component);

    measureSubtask('serialize data', () {
      _reporter.log('Writing data to ${_options.writeDataUri}');
      api.BinaryOutputSink dataOutput =
          _outputProvider.createBinarySink(_options.writeDataUri);
      DataSink sink = new BinarySink(new BinaryOutputSinkAdapter(dataOutput));
      serializeGlobalTypeInferenceResultsToSink(results, sink);
    });
  }

  Future<GlobalTypeInferenceResults> deserializeGlobalTypeInferenceResults(
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      JsClosedWorld closedWorld) async {
    return await measureIoSubtask('deserialize data', () async {
      _reporter.log('Reading data from ${_options.readDataUri}');
      api.Input<List<int>> dataInput = await _provider
          .readFromUri(_options.readDataUri, inputKind: api.InputKind.binary);
      DataSource source =
          BinarySourceImpl(dataInput.data, stringInterner: _stringInterner);
      return deserializeGlobalTypeInferenceResultsFromSource(
          _options,
          _reporter,
          environment,
          abstractValueStrategy,
          component,
          closedWorld,
          source);
    });
  }

  // TODO(joshualitt) get rid of legacy functions after Google3 roll.
  void serializeGlobalTypeInferenceLegacy(GlobalTypeInferenceResults results) {
    JsClosedWorld closedWorld = results.closedWorld;
    ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
    serializeComponent(component);

    measureSubtask('serialize data', () {
      _reporter.log('Writing data to ${_options.writeDataUri}');
      api.BinaryOutputSink dataOutput =
          _outputProvider.createBinarySink(_options.writeDataUri);
      DataSink sink = new BinarySink(new BinaryOutputSinkAdapter(dataOutput));
      serializeGlobalTypeInferenceResultsToSinkLegacy(results, sink);
    });
  }

  Future<GlobalTypeInferenceResults> deserializeGlobalTypeInferenceLegacy(
      Environment environment,
      AbstractValueStrategy abstractValueStrategy) async {
    ir.Component component = await deserializeComponentAndUpdateOptions();

    return await measureIoSubtask('deserialize data', () async {
      _reporter.log('Reading data from ${_options.readDataUri}');
      api.Input<List<int>> dataInput = await _provider
          .readFromUri(_options.readDataUri, inputKind: api.InputKind.binary);
      DataSource source =
          BinarySourceImpl(dataInput.data, stringInterner: _stringInterner);
      return deserializeGlobalTypeInferenceResultsFromSourceLegacy(_options,
          _reporter, environment, abstractValueStrategy, component, source);
    });
  }

  void serializeCodegen(
      BackendStrategy backendStrategy, CodegenResults codegenResults) {
    GlobalTypeInferenceResults globalTypeInferenceResults =
        codegenResults.globalTypeInferenceResults;
    JClosedWorld closedWorld = globalTypeInferenceResults.closedWorld;
    int shard = _options.codegenShard;
    int shards = _options.codegenShards;
    Map<MemberEntity, CodegenResult> results = {};
    int index = 0;
    EntityWriter entityWriter =
        backendStrategy.forEachCodegenMember((MemberEntity member) {
      if (index % shards == shard) {
        CodegenResult codegenResult = codegenResults.getCodegenResults(member);
        results[member] = codegenResult;
      }
      index++;
    });
    measureSubtask('serialize codegen', () {
      Uri uri = Uri.parse('${_options.writeCodegenUri}$shard');
      api.BinaryOutputSink dataOutput = _outputProvider.createBinarySink(uri);
      DataSink sink = new BinarySink(new BinaryOutputSinkAdapter(dataOutput));
      _reporter.log('Writing data to ${uri}');
      sink.registerEntityWriter(entityWriter);
      sink.registerCodegenWriter(new CodegenWriterImpl(closedWorld));
      sink.writeMemberMap(
          results,
          (MemberEntity member, CodegenResult result) =>
              result.writeToDataSink(sink));
      sink.close();
    });
  }

  Future<CodegenResults> deserializeCodegen(
      BackendStrategy backendStrategy,
      GlobalTypeInferenceResults globalTypeInferenceResults,
      CodegenInputs codegenInputs) async {
    int shards = _options.codegenShards;
    JClosedWorld closedWorld = globalTypeInferenceResults.closedWorld;
    Map<MemberEntity, CodegenResult> results = {};
    for (int shard = 0; shard < shards; shard++) {
      Uri uri = Uri.parse('${_options.readCodegenUri}$shard');
      await measureIoSubtask('deserialize codegen', () async {
        _reporter.log('Reading data from ${uri}');
        api.Input<List<int>> dataInput =
            await _provider.readFromUri(uri, inputKind: api.InputKind.binary);
        // TODO(36983): This code is extracted because there appeared to be a
        // memory leak for large buffer held by `source`.
        _deserializeCodegenInput(
            backendStrategy, closedWorld, uri, dataInput, results);
        dataInput.release();
      });
    }
    return new DeserializedCodegenResults(
        globalTypeInferenceResults, codegenInputs, results);
  }

  void _deserializeCodegenInput(
      BackendStrategy backendStrategy,
      JClosedWorld closedWorld,
      Uri uri,
      api.Input<List<int>> dataInput,
      Map<MemberEntity, CodegenResult> results) {
    DataSource source =
        BinarySourceImpl(dataInput.data, stringInterner: _stringInterner);
    backendStrategy.prepareCodegenReader(source);
    Map<MemberEntity, CodegenResult> codegenResults =
        source.readMemberMap((MemberEntity member) {
      List<ModularName> modularNames = [];
      List<ModularExpression> modularExpressions = [];
      CodegenReader reader =
          new CodegenReaderImpl(closedWorld, modularNames, modularExpressions);
      source.registerCodegenReader(reader);
      CodegenResult result = CodegenResult.readFromDataSource(
          source, modularNames, modularExpressions);
      source.deregisterCodegenReader(reader);
      return result;
    });
    _reporter.log('Read ${codegenResults.length} members from ${uri}');
    results.addAll(codegenResults);
  }
}
