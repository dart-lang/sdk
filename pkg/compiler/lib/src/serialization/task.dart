// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' as ir;
import 'package:kernel/binary/ast_to_binary.dart' as ir;
import '../../compiler_api.dart' as api;
import '../commandline_options.dart' show Flags;
import '../common/codegen.dart';
import '../common/tasks.dart';
import '../deferred_load/output_unit.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../dump_info.dart';
import '../elements/entities.dart';
import '../environment.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/abstract_value_strategy.dart';
import '../inferrer/types.dart';
import '../io/source_information.dart';
import '../js_backend/codegen_inputs.dart';
import '../js_backend/inferred_data.dart';
import '../js_model/js_world.dart';
import '../js_model/js_strategy.dart';
import '../js_model/locals.dart';
import '../options.dart';
import 'deferrable.dart';
import 'serialization.dart';

class _StringInterner implements ir.StringInterner, StringInterner {
  final Map<String, String> _map = {};

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
  final ValueInterner? _valueInterner;

  SerializationTask(this._options, this._reporter, this._provider,
      this._outputProvider, Measurer measurer)
      : _valueInterner =
            _options.features.internValues.isEnabled ? ValueInterner() : null,
        super(measurer);

  @override
  String get name => 'Serialization';

  void serializeComponent(ir.Component component,
      {bool includeSourceBytes = true}) {
    measureSubtask('serialize dill', () {
      _reporter.log('Writing dill to ${_options.outputUri}');
      api.BinaryOutputSink dillOutput =
          _outputProvider.createBinarySink(_options.outputUri!);
      ir.BinaryPrinter printer =
          ir.BinaryPrinter(dillOutput, includeSourceBytes: includeSourceBytes);
      printer.writeComponentFile(component);
      dillOutput.close();
    });
  }

  Future<ir.Component> deserializeComponent() async {
    return measureIoSubtask('deserialize dill', () async {
      _reporter.log('Reading dill from ${_options.inputDillUri}');
      final dillInput = await _provider.readFromUri(_options.inputDillUri!,
          inputKind: api.InputKind.binary);
      ir.Component component = ir.Component();
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
      throw ArgumentError("${_options.inputDillUri} was compiled with "
          "$dillMode null safety and is incompatible with the '$option' "
          "option");
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

  void serializeClosedWorld(
      JClosedWorld closedWorld, SerializationIndices indices) {
    measureSubtask('serialize closed world', () {
      final outputUri =
          _options.dataOutputUriForStage(Dart2JSStage.closedWorld);
      _reporter.log('Writing closed world to $outputUri');
      api.BinaryOutputSink dataOutput =
          _outputProvider.createBinarySink(outputUri);
      DataSinkWriter sink =
          DataSinkWriter(BinaryDataSink(dataOutput), _options, indices);
      serializeClosedWorldToSink(closedWorld, sink);
    });
  }

  Future<JClosedWorld> deserializeClosedWorld(
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      bool useDeferredSourceReads,
      SerializationIndices indices) async {
    return await measureIoSubtask('deserialize closed world', () async {
      final uri = _options.dataInputUriForStage(Dart2JSStage.closedWorld);
      _reporter.log('Reading data from $uri');
      api.Input<List<int>> dataInput =
          await _provider.readFromUri(uri, inputKind: api.InputKind.binary);
      DataSourceReader source = DataSourceReader(
          BinaryDataSource(dataInput.data, stringInterner: _stringInterner),
          _options,
          indices,
          interner: _valueInterner,
          useDeferredStrategy: useDeferredSourceReads);
      var closedWorld = deserializeClosedWorldFromSource(_options, _reporter,
          environment, abstractValueStrategy, component, source);
      return closedWorld;
    });
  }

  void serializeGlobalTypeInference(
      GlobalTypeInferenceResults results, SerializationIndices indices) {
    measureSubtask('serialize data', () {
      final outputUri =
          _options.dataOutputUriForStage(Dart2JSStage.globalInference);
      _reporter.log('Writing data to $outputUri');
      api.BinaryOutputSink dataOutput =
          _outputProvider.createBinarySink(outputUri);
      DataSinkWriter sink =
          DataSinkWriter(BinaryDataSink(dataOutput), _options, indices);
      serializeGlobalTypeInferenceResultsToSink(results, sink);
    });
  }

  Future<GlobalTypeInferenceResults> deserializeGlobalTypeInferenceResults(
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      JClosedWorld closedWorld,
      bool useDeferredSourceReads,
      SerializationIndices indices) async {
    return await measureIoSubtask('deserialize data', () async {
      final uri = _options.dataInputUriForStage(Dart2JSStage.globalInference);
      _reporter.log('Reading data from $uri');
      api.Input<List<int>> dataInput =
          await _provider.readFromUri(uri, inputKind: api.InputKind.binary);
      DataSourceReader source = DataSourceReader(
          BinaryDataSource(dataInput.data, stringInterner: _stringInterner),
          _options,
          indices,
          interner: _valueInterner,
          useDeferredStrategy: useDeferredSourceReads);
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

  void serializeCodegen(
      JsBackendStrategy backendStrategy,
      AbstractValueDomain domain,
      CodegenResults codegenResults,
      SerializationIndices indices) {
    int shard = _options.codegenShard!;
    int shards = _options.codegenShards!;
    Map<MemberEntity, CodegenResult> results = {};
    int index = 0;
    final lazyMemberBodies =
        backendStrategy.forEachCodegenMember((MemberEntity member) {
      if (index % shards == shard) {
        CodegenResult codegenResult = codegenResults.getCodegenResults(member);
        results[member] = codegenResult;
      }
      index++;
    });
    measureSubtask('serialize codegen', () {
      final outputUri =
          _options.dataOutputUriForStage(Dart2JSStage.codegenSharded);
      Uri uri = Uri.parse('$outputUri$shard');
      api.BinaryOutputSink dataOutput = _outputProvider.createBinarySink(uri);
      DataSinkWriter sink =
          DataSinkWriter(BinaryDataSink(dataOutput), _options, indices);
      _reporter.log('Writing data to ${uri}');
      sink.writeMembers(lazyMemberBodies);
      sink.registerAbstractValueDomain(domain);
      sink.writeMemberMap(results, (MemberEntity member, CodegenResult result) {
        sink.writeDeferrable(() => result.writeToDataSink(sink));
      });
      sink.close();
    });
  }

  Future<CodegenResults> deserializeCodegen(
      JsBackendStrategy backendStrategy,
      JClosedWorld closedWorld,
      CodegenInputs codegenInputs,
      bool useDeferredSourceReads,
      SourceLookup sourceLookup,
      SerializationIndices indices) async {
    int shards = _options.codegenShards!;
    Map<MemberEntity, Deferrable<CodegenResult>> results = {};
    for (int shard = 0; shard < shards; shard++) {
      Uri uri = Uri.parse(
          '${_options.dataInputUriForStage(Dart2JSStage.codegenSharded)}$shard');
      await measureIoSubtask('deserialize codegen', () async {
        _reporter.log('Reading data from ${uri}');
        api.Input<List<int>> dataInput =
            await _provider.readFromUri(uri, inputKind: api.InputKind.binary);
        // TODO(36983): This code is extracted because there appeared to be a
        // memory leak for large buffer held by `source`.
        _deserializeCodegenInput(backendStrategy, closedWorld, uri, dataInput,
            results, useDeferredSourceReads, sourceLookup, indices);
        dataInput.release();
      });
    }
    return DeserializedCodegenResults(
        codegenInputs, DeferrableValueMap(results));
  }

  void _deserializeCodegenInput(
      JsBackendStrategy backendStrategy,
      JClosedWorld closedWorld,
      Uri uri,
      api.Input<List<int>> dataInput,
      Map<MemberEntity, Deferrable<CodegenResult>> results,
      bool useDeferredSourceReads,
      SourceLookup sourceLookup,
      SerializationIndices indices) {
    DataSourceReader source = DataSourceReader(
        BinaryDataSource(dataInput.data, stringInterner: _stringInterner),
        _options,
        indices,
        interner: _valueInterner,
        useDeferredStrategy: useDeferredSourceReads);
    backendStrategy.prepareCodegenReader(source);
    source.registerSourceLookup(sourceLookup);
    final lazyMemberBodies = source.readMembers();
    closedWorld.elementMap.registerLazyMemberBodies(lazyMemberBodies);
    source.registerAbstractValueDomain(closedWorld.abstractValueDomain);
    Map<MemberEntity, Deferrable<CodegenResult>> codegenResults =
        source.readMemberMap((MemberEntity member) {
      return source.readDeferrable(CodegenResult.readFromDataSource,
          cacheData: false);
    });
    _reporter.log('Read ${codegenResults.length} members from ${uri}');
    results.addAll(codegenResults);
  }

  void serializeDumpInfoProgramData(
      JsBackendStrategy backendStrategy,
      DumpInfoProgramData dumpInfoProgramData,
      AbstractValueDomain abstractValueDomain,
      SerializationIndices indices) {
    final outputUri = _options.dumpInfoWriteUri!;
    api.BinaryOutputSink dataOutput =
        _outputProvider.createBinarySink(outputUri);
    final sink = DataSinkWriter(BinaryDataSink(dataOutput), _options, indices);
    sink.registerAbstractValueDomain(abstractValueDomain);
    dumpInfoProgramData.writeToDataSink(sink);
    sink.close();
  }

  Future<DumpInfoProgramData> deserializeDumpInfoProgramData(
      JsBackendStrategy backendStrategy,
      AbstractValueDomain abstractValueDomain,
      OutputUnitData outputUnitData,
      SerializationIndices indices) async {
    final inputUri = _options.dumpInfoReadUri!;
    final dataInput =
        await _provider.readFromUri(inputUri, inputKind: api.InputKind.binary);
    final source = DataSourceReader(
        BinaryDataSource(dataInput.data, stringInterner: _stringInterner),
        _options,
        indices);
    backendStrategy.prepareCodegenReader(source);
    source.registerAbstractValueDomain(abstractValueDomain);
    return DumpInfoProgramData.readFromDataSource(source, outputUnitData,
        includeCodeText: !_options.useDumpInfoBinaryFormat);
  }
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
