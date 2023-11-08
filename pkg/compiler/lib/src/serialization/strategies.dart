// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/fasta/kernel/utils.dart' as ir
    show serializeComponent;
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import '../diagnostics/diagnostic_listener.dart';
import '../environment.dart';
import '../inferrer/abstract_value_strategy.dart';
import '../inferrer/types.dart';
import '../js_model/js_world.dart';
import '../options.dart';
import '../source_file_provider.dart';
import '../util/sink_adapter.dart';
import 'serialization.dart';
import 'task.dart';

abstract class SerializationStrategy<T> {
  const SerializationStrategy();

  List<int> unpackAndSerializeComponent(GlobalTypeInferenceResults results) {
    JClosedWorld closedWorld = results.closedWorld;
    ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
    return serializeComponent(component);
  }

  List<T> serializeGlobalTypeInferenceResults(DataSourceIndices? indices,
      GlobalTypeInferenceResults results, CompilerOptions options);

  List<int> serializeComponent(ir.Component component) {
    return ir.serializeComponent(component);
  }

  ir.Component deserializeComponent(List<int> data) {
    ir.Component component = ir.Component();
    BinaryBuilder(data).readComponent(component);
    return component;
  }

  DataAndIndices<GlobalTypeInferenceResults>
      deserializeGlobalTypeInferenceResults(
          CompilerOptions options,
          DiagnosticReporter reporter,
          Environment environment,
          AbstractValueStrategy abstractValueStrategy,
          ir.Component component,
          JClosedWorld closedWorld,
          DataSourceIndices? indices,
          List<T> globalTypeInferenceResultsData);

  List<T> serializeClosedWorld(
      JClosedWorld closedWorld, CompilerOptions options);

  DataAndIndices<JClosedWorld> deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<T> data);
}

class BytesInMemorySerializationStrategy extends SerializationStrategy<int> {
  final bool useDataKinds;

  const BytesInMemorySerializationStrategy({this.useDataKinds = false});

  @override
  List<int> serializeGlobalTypeInferenceResults(DataSourceIndices? indices,
      GlobalTypeInferenceResults results, CompilerOptions options) {
    ByteSink byteSink = ByteSink();
    DataSinkWriter sink = DataSinkWriter(BinaryDataSink(byteSink), options,
        useDataKinds: useDataKinds, importedIndices: indices);
    serializeGlobalTypeInferenceResultsToSink(results, sink);
    return byteSink.builder.takeBytes();
  }

  @override
  DataAndIndices<GlobalTypeInferenceResults>
      deserializeGlobalTypeInferenceResults(
          CompilerOptions options,
          DiagnosticReporter reporter,
          Environment environment,
          AbstractValueStrategy abstractValueStrategy,
          ir.Component component,
          JClosedWorld closedWorld,
          DataSourceIndices? indices,
          List<int> globalTypeInferenceResultsData) {
    DataSourceReader globalTypeInferenceResultsSource = DataSourceReader(
        BinaryDataSource(globalTypeInferenceResultsData), options,
        useDataKinds: useDataKinds, importedIndices: indices);
    final results = deserializeGlobalTypeInferenceResultsFromSource(
        options,
        reporter,
        environment,
        abstractValueStrategy,
        component,
        closedWorld,
        globalTypeInferenceResultsSource);
    return DataAndIndices(
        results, globalTypeInferenceResultsSource.exportIndices());
  }

  @override
  List<int> serializeClosedWorld(
      JClosedWorld closedWorld, CompilerOptions options) {
    ByteSink byteSink = ByteSink();
    DataSinkWriter sink = DataSinkWriter(BinaryDataSink(byteSink), options,
        useDataKinds: useDataKinds);
    serializeClosedWorldToSink(closedWorld, sink);
    return byteSink.builder.takeBytes();
  }

  @override
  DataAndIndices<JClosedWorld> deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<int> data) {
    DataSourceReader source = DataSourceReader(BinaryDataSource(data), options,
        useDataKinds: useDataKinds);
    var closedWorld = deserializeClosedWorldFromSource(options, reporter,
        environment, abstractValueStrategy, component, source);
    return DataAndIndices<JClosedWorld>(closedWorld, source.exportIndices());
  }
}

class BytesOnDiskSerializationStrategy extends SerializationStrategy<int> {
  final bool useDataKinds;

  const BytesOnDiskSerializationStrategy({this.useDataKinds = false});

  @override
  List<int> serializeGlobalTypeInferenceResults(DataSourceIndices? indices,
      GlobalTypeInferenceResults results, CompilerOptions options) {
    Uri uri = Uri.base.resolve('world.data');
    DataSinkWriter sink = DataSinkWriter(
        BinaryDataSink(
            BinaryOutputSinkAdapter(RandomAccessBinaryOutputSink(uri))),
        options,
        useDataKinds: useDataKinds,
        importedIndices: indices);
    serializeGlobalTypeInferenceResultsToSink(results, sink);
    return File.fromUri(uri).readAsBytesSync();
  }

  @override
  DataAndIndices<GlobalTypeInferenceResults>
      deserializeGlobalTypeInferenceResults(
          CompilerOptions options,
          DiagnosticReporter reporter,
          Environment environment,
          AbstractValueStrategy abstractValueStrategy,
          ir.Component component,
          JClosedWorld closedWorld,
          DataSourceIndices? indices,
          List<int> globalTypeInferenceResultsData) {
    DataSourceReader globalTypeInferenceResultsSource = DataSourceReader(
        BinaryDataSource(globalTypeInferenceResultsData), options,
        useDataKinds: useDataKinds, importedIndices: indices);
    return DataAndIndices(
        deserializeGlobalTypeInferenceResultsFromSource(
            options,
            reporter,
            environment,
            abstractValueStrategy,
            component,
            closedWorld,
            globalTypeInferenceResultsSource),
        globalTypeInferenceResultsSource.exportIndices());
  }

  @override
  List<int> serializeClosedWorld(
      JClosedWorld closedWorld, CompilerOptions options) {
    Uri uri = Uri.base.resolve('closed_world.data');
    DataSinkWriter sink = DataSinkWriter(
        BinaryDataSink(
            BinaryOutputSinkAdapter(RandomAccessBinaryOutputSink(uri))),
        options,
        useDataKinds: useDataKinds);
    serializeClosedWorldToSink(closedWorld, sink);
    return File.fromUri(uri).readAsBytesSync();
  }

  @override
  DataAndIndices<JClosedWorld> deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<int> data) {
    DataSourceReader source = DataSourceReader(BinaryDataSource(data), options,
        useDataKinds: useDataKinds);
    var closedWorld = deserializeClosedWorldFromSource(options, reporter,
        environment, abstractValueStrategy, component, source);
    return DataAndIndices<JClosedWorld>(closedWorld, source.exportIndices());
  }
}

class ObjectsInMemorySerializationStrategy
    extends SerializationStrategy<Object> {
  final bool useDataKinds;

  const ObjectsInMemorySerializationStrategy({this.useDataKinds = true});

  @override
  List<Object> serializeGlobalTypeInferenceResults(DataSourceIndices? indices,
      GlobalTypeInferenceResults results, CompilerOptions options) {
    List<Object> data = [];
    DataSinkWriter sink = DataSinkWriter(ObjectDataSink(data), options,
        useDataKinds: useDataKinds, importedIndices: indices);
    serializeGlobalTypeInferenceResultsToSink(results, sink);
    return data;
  }

  @override
  DataAndIndices<GlobalTypeInferenceResults>
      deserializeGlobalTypeInferenceResults(
          CompilerOptions options,
          DiagnosticReporter reporter,
          Environment environment,
          AbstractValueStrategy abstractValueStrategy,
          ir.Component component,
          JClosedWorld closedWorld,
          DataSourceIndices? indices,
          List<Object> globalTypeInferenceResultsData) {
    DataSourceReader globalTypeInferenceResultsSource = DataSourceReader(
        ObjectDataSource(globalTypeInferenceResultsData), options,
        useDataKinds: useDataKinds);
    return DataAndIndices(
        deserializeGlobalTypeInferenceResultsFromSource(
            options,
            reporter,
            environment,
            abstractValueStrategy,
            component,
            closedWorld,
            globalTypeInferenceResultsSource),
        globalTypeInferenceResultsSource.exportIndices());
  }

  @override
  List<Object> serializeClosedWorld(
      JClosedWorld closedWorld, CompilerOptions options) {
    List<Object> data = [];
    DataSinkWriter sink = DataSinkWriter(ObjectDataSink(data), options,
        useDataKinds: useDataKinds);
    serializeClosedWorldToSink(closedWorld, sink);
    return data;
  }

  @override
  DataAndIndices<JClosedWorld> deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<Object> data) {
    DataSourceReader source = DataSourceReader(ObjectDataSource(data), options,
        useDataKinds: useDataKinds);
    var closedWorld = deserializeClosedWorldFromSource(options, reporter,
        environment, abstractValueStrategy, component, source);
    return DataAndIndices<JClosedWorld>(closedWorld, source.exportIndices());
  }
}
