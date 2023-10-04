// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:compiler/src/js/js.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' as ir;
import 'package:kernel/binary/ast_to_binary.dart' as ir;
import 'package:front_end/src/fasta/util/bytes_sink.dart';
import '../../compiler_api.dart' as api;
import '../commandline_options.dart' show Flags;
import '../common/codegen.dart';
import '../common/tasks.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../dump_info.dart';
import '../elements/entities.dart';
import '../environment.dart';
import '../inferrer/abstract_value_strategy.dart';
import '../inferrer/types.dart';
import '../io/source_information.dart';
import '../ir/modular.dart';
import '../js_backend/codegen_inputs.dart';
import '../js_backend/inferred_data.dart';
import '../js_model/element_map_impl.dart';
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

/// A data class holding some data [T] and the associated [DataSourceIndices].
class DataAndIndices<T> {
  final T? data;
  final DataSourceIndices? indices;

  DataAndIndices(this.data, this.indices);
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
      // TODO(sigmund): remove entirely: we will do this immediately as soon as
      // we get the component in the kernel/loader.dart task once we refactor
      // how we apply our modular kernel transformation for super mixin calls.
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

  void serializeModuleData(
      ModuleData data, ir.Component component, Set<Uri> includedLibraries) {
    measureSubtask('serialize transformed dill', () {
      _reporter.log('Writing dill to ${_options.outputUri}');
      var dillOutput = _outputProvider.createBinarySink(_options.outputUri!);
      ir.BinaryPrinter printer = ir.BinaryPrinter(dillOutput,
          libraryFilter: (ir.Library l) =>
              includedLibraries.contains(l.importUri));
      printer.writeComponentFile(component);
      dillOutput.close();
    });

    measureSubtask('serialize module data', () {
      final outputUri =
          _options.dataOutputUriForStage(Dart2JSStage.modularAnalysis);
      _reporter.log('Writing data to $outputUri');
      api.BinaryOutputSink dataOutput =
          _outputProvider.createBinarySink(outputUri);
      DataSinkWriter sink =
          DataSinkWriter(BinaryDataSink(dataOutput), _options);
      data.toDataSink(sink);
      sink.close();
    });
  }

  void testModuleSerialization(ModuleData data, ir.Component component) {
    if (_options.testMode) {
      // TODO(joshualitt):
      // Consider using a strategy like we do for the global data, so we can also
      // test it with the objectSink/objectSource:
      //   List<Object> encoding = [];
      //   DataSink sink = ObjectSink(encoding, useDataKinds: true);
      //   data.toDataSink(sink);
      //   DataSource source = ObjectSource(encoding, useDataKinds: true);
      //   source.registerComponentLookup(new ComponentLookup(component));
      //   ModuleData.fromDataSource(source);
      BytesSink bytes = BytesSink();
      DataSinkWriter binarySink =
          DataSinkWriter(BinaryDataSink(bytes), _options, useDataKinds: true);
      data.toDataSink(binarySink);
      binarySink.close();
      var source = DataSourceReader(
          BinaryDataSource(bytes.builder.toBytes()), _options,
          useDataKinds: true, interner: _valueInterner);
      source.registerComponentLookup(ComponentLookup(component));
      ModuleData.fromDataSource(source);
    }
  }

  Future<ModuleData> deserializeModuleData(ir.Component component) async {
    return await measureIoSubtask('deserialize module data', () async {
      _reporter.log('Reading data from ${_options.modularAnalysisInputs}');
      final results = ModuleData();
      for (Uri uri in _options.modularAnalysisInputs!) {
        final dataInput =
            await _provider.readFromUri(uri, inputKind: api.InputKind.binary);
        DataSourceReader source = DataSourceReader(
            BinaryDataSource(dataInput.data), _options,
            interner: _valueInterner);
        source.registerComponentLookup(ComponentLookup(component));
        results.readMoreFromDataSource(source);
      }
      return results;
    });
  }

  void serializeClosedWorld(JClosedWorld closedWorld) {
    measureSubtask('serialize closed world', () {
      final outputUri =
          _options.dataOutputUriForStage(Dart2JSStage.closedWorld);
      _reporter.log('Writing closed world to $outputUri');
      api.BinaryOutputSink dataOutput =
          _outputProvider.createBinarySink(outputUri);
      DataSinkWriter sink =
          DataSinkWriter(BinaryDataSink(dataOutput), _options);
      serializeClosedWorldToSink(closedWorld, sink);
    });
  }

  Future<DataAndIndices<JClosedWorld>> deserializeClosedWorld(
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      bool useDeferredSourceReads) async {
    return await measureIoSubtask('deserialize closed world', () async {
      final uri = _options.dataInputUriForStage(Dart2JSStage.closedWorld);
      _reporter.log('Reading data from $uri');
      api.Input<List<int>> dataInput =
          await _provider.readFromUri(uri, inputKind: api.InputKind.binary);
      DataSourceReader source = DataSourceReader(
          BinaryDataSource(dataInput.data, stringInterner: _stringInterner),
          _options,
          interner: _valueInterner,
          useDeferredStrategy: useDeferredSourceReads);
      var closedWorld = deserializeClosedWorldFromSource(_options, _reporter,
          environment, abstractValueStrategy, component, source);
      return DataAndIndices(closedWorld, source.exportIndices());
    });
  }

  void serializeGlobalTypeInference(
      GlobalTypeInferenceResults results, DataSourceIndices indices) {
    measureSubtask('serialize data', () {
      final outputUri =
          _options.dataOutputUriForStage(Dart2JSStage.globalInference);
      _reporter.log('Writing data to $outputUri');
      api.BinaryOutputSink dataOutput =
          _outputProvider.createBinarySink(outputUri);
      DataSinkWriter sink = DataSinkWriter(BinaryDataSink(dataOutput), _options,
          importedIndices: indices);
      serializeGlobalTypeInferenceResultsToSink(results, sink);
    });
  }

  Future<DataAndIndices<GlobalTypeInferenceResults>>
      deserializeGlobalTypeInferenceResults(
          Environment environment,
          AbstractValueStrategy abstractValueStrategy,
          ir.Component component,
          DataAndIndices<JClosedWorld> closedWorldAndIndices,
          bool useDeferredSourceReads) async {
    return await measureIoSubtask('deserialize data', () async {
      final uri = _options.dataInputUriForStage(Dart2JSStage.globalInference);
      _reporter.log('Reading data from $uri');
      api.Input<List<int>> dataInput =
          await _provider.readFromUri(uri, inputKind: api.InputKind.binary);
      DataSourceReader source = DataSourceReader(
          BinaryDataSource(dataInput.data, stringInterner: _stringInterner),
          _options,
          interner: _valueInterner,
          importedIndices: closedWorldAndIndices.indices,
          useDeferredStrategy: useDeferredSourceReads);
      return DataAndIndices(
          deserializeGlobalTypeInferenceResultsFromSource(
              _options,
              _reporter,
              environment,
              abstractValueStrategy,
              component,
              closedWorldAndIndices.data!,
              source),
          source.exportIndices());
    });
  }

  void serializeCodegen(JsBackendStrategy backendStrategy,
      CodegenResults codegenResults, DataSourceIndices indices) {
    GlobalTypeInferenceResults globalTypeInferenceResults =
        codegenResults.globalTypeInferenceResults;
    JClosedWorld closedWorld = globalTypeInferenceResults.closedWorld;
    int shard = _options.codegenShard!;
    int shards = _options.codegenShards!;
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
      final outputUri =
          _options.dataOutputUriForStage(Dart2JSStage.codegenSharded);
      Uri uri = Uri.parse('$outputUri$shard');
      api.BinaryOutputSink dataOutput = _outputProvider.createBinarySink(uri);
      DataSinkWriter sink = DataSinkWriter(BinaryDataSink(dataOutput), _options,
          importedIndices: indices);
      _reporter.log('Writing data to ${uri}');
      sink.registerEntityWriter(entityWriter);
      sink.writeMemberMap(results, (MemberEntity member, CodegenResult result) {
        sink.registerCodegenWriter(
            CodegenWriterImpl(closedWorld, result.deferredExpressionData));
        sink.writeDeferrable(() => result.writeToDataSink(sink));
      });
      sink.close();
    });
  }

  Future<CodegenResults> deserializeCodegen(
      JsBackendStrategy backendStrategy,
      GlobalTypeInferenceResults globalTypeInferenceResults,
      CodegenInputs codegenInputs,
      DataSourceIndices indices,
      bool useDeferredSourceReads,
      SourceLookup sourceLookup) async {
    int shards = _options.codegenShards!;
    JClosedWorld closedWorld = globalTypeInferenceResults.closedWorld;
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
            indices, results, useDeferredSourceReads, sourceLookup);
        dataInput.release();
      });
    }
    return DeserializedCodegenResults(
        globalTypeInferenceResults, codegenInputs, DeferrableValueMap(results));
  }

  static CodegenResult _readCodegenResult(
      DataSourceReader source, JClosedWorld closedWorld) {
    CodegenReader reader = CodegenReaderImpl(closedWorld);
    source.registerCodegenReader(reader);
    CodegenResult result = CodegenResult.readFromDataSource(source);
    return result;
  }

  void _deserializeCodegenInput(
      JsBackendStrategy backendStrategy,
      JClosedWorld closedWorld,
      Uri uri,
      api.Input<List<int>> dataInput,
      DataSourceIndices importedIndices,
      Map<MemberEntity, Deferrable<CodegenResult>> results,
      bool useDeferredSourceReads,
      SourceLookup sourceLookup) {
    DataSourceReader source = DataSourceReader(
        BinaryDataSource(dataInput.data, stringInterner: _stringInterner),
        _options,
        interner: _valueInterner,
        importedIndices: importedIndices,
        useDeferredStrategy: useDeferredSourceReads);
    backendStrategy.prepareCodegenReader(source);
    source.registerSourceLookup(sourceLookup);
    Map<MemberEntity, Deferrable<CodegenResult>> codegenResults =
        source.readMemberMap((MemberEntity member) {
      return source.readDeferrableWithArg(_readCodegenResult, closedWorld,
          cacheData: false);
    });
    _reporter.log('Read ${codegenResults.length} members from ${uri}');
    results.addAll(codegenResults);
  }

  void serializeDumpInfoProgramData(
      JsBackendStrategy backendStrategy,
      DumpInfoProgramData dumpInfoProgramData,
      JClosedWorld closedWorld,
      DataSourceIndices? importedIndices) {
    final outputUri = _options.dumpInfoWriteUri!;
    api.BinaryOutputSink dataOutput =
        _outputProvider.createBinarySink(outputUri);
    final sink = DataSinkWriter(BinaryDataSink(dataOutput), _options,
        importedIndices: importedIndices);
    EntityWriter entityWriter = backendStrategy.forEachCodegenMember((_) {});
    sink.registerEntityWriter(entityWriter);
    sink.registerCodegenWriter(
        CodegenWriterImpl(closedWorld, DeferredExpressionData([], [])));
    dumpInfoProgramData.writeToDataSink(sink);
    sink.close();
  }

  Future<DumpInfoProgramData> deserializeDumpInfoProgramData(
      JsBackendStrategy backendStrategy,
      JClosedWorld closedWorld,
      DataSourceIndices? importedIndices) async {
    final inputUri = _options.dumpInfoReadUri!;
    final dataInput =
        await _provider.readFromUri(inputUri, inputKind: api.InputKind.binary);
    final source = DataSourceReader(
        BinaryDataSource(dataInput.data, stringInterner: _stringInterner),
        _options,
        importedIndices: importedIndices);
    backendStrategy.prepareCodegenReader(source);
    source.registerCodegenReader(CodegenReaderImpl(closedWorld));
    return DumpInfoProgramData.readFromDataSource(source, closedWorld,
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
