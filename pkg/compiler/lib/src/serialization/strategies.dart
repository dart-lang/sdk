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
import 'serialization.dart';
import 'task.dart';

abstract class SerializationStrategy<T> {
  const SerializationStrategy();

  List<int> unpackAndSerializeComponent(GlobalTypeInferenceResults results) {
    JClosedWorld closedWorld = results.closedWorld;
    ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
    return serializeComponent(component);
  }

  List<T> serializeGlobalTypeInferenceResults(
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      SerializationIndices indices);

  List<int> serializeComponent(ir.Component component) {
    return ir.serializeComponent(component);
  }

  ir.Component deserializeComponent(List<int> data) {
    ir.Component component = ir.Component();
    BinaryBuilder(data).readComponent(component);
    return component;
  }

  GlobalTypeInferenceResults deserializeGlobalTypeInferenceResults(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      JClosedWorld closedWorld,
      List<T> globalTypeInferenceResultsData,
      SerializationIndices indices);

  List<T> serializeClosedWorld(JClosedWorld closedWorld,
      CompilerOptions options, SerializationIndices indices);

  JClosedWorld deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<T> data,
      SerializationIndices indices);
}

class BytesInMemorySerializationStrategy extends SerializationStrategy<int> {
  final bool useDataKinds;

  const BytesInMemorySerializationStrategy({this.useDataKinds = false});

  @override
  List<int> serializeGlobalTypeInferenceResults(
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      SerializationIndices indices) {
    ByteSink byteSink = ByteSink();
    DataSinkWriter sink = DataSinkWriter(
        BinaryDataSink(byteSink), options, indices,
        useDataKinds: useDataKinds);
    serializeGlobalTypeInferenceResultsToSink(results, sink);
    return byteSink.builder.takeBytes();
  }

  @override
  GlobalTypeInferenceResults deserializeGlobalTypeInferenceResults(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      JClosedWorld closedWorld,
      List<int> globalTypeInferenceResultsData,
      SerializationIndices indices) {
    DataSourceReader globalTypeInferenceResultsSource = DataSourceReader(
        BinaryDataSource(globalTypeInferenceResultsData), options, indices,
        useDataKinds: useDataKinds);
    final results = deserializeGlobalTypeInferenceResultsFromSource(
        options,
        reporter,
        environment,
        abstractValueStrategy,
        component,
        closedWorld,
        globalTypeInferenceResultsSource);
    return results;
  }

  @override
  List<int> serializeClosedWorld(JClosedWorld closedWorld,
      CompilerOptions options, SerializationIndices indices) {
    ByteSink byteSink = ByteSink();
    DataSinkWriter sink = DataSinkWriter(
        BinaryDataSink(byteSink), options, indices,
        useDataKinds: useDataKinds);
    serializeClosedWorldToSink(closedWorld, sink);
    return byteSink.builder.takeBytes();
  }

  @override
  JClosedWorld deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<int> data,
      SerializationIndices indices) {
    DataSourceReader source = DataSourceReader(
        BinaryDataSource(data), options, indices,
        useDataKinds: useDataKinds);
    var closedWorld = deserializeClosedWorldFromSource(options, reporter,
        environment, abstractValueStrategy, component, source);
    return closedWorld;
  }
}

class BytesOnDiskSerializationStrategy extends SerializationStrategy<int> {
  final bool useDataKinds;

  const BytesOnDiskSerializationStrategy({this.useDataKinds = false});

  @override
  List<int> serializeGlobalTypeInferenceResults(
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      SerializationIndices indices) {
    Uri uri = Uri.base.resolve('world.data');
    DataSinkWriter sink = DataSinkWriter(
        BinaryDataSink(RandomAccessBinaryOutputSink(uri)), options, indices,
        useDataKinds: useDataKinds);
    serializeGlobalTypeInferenceResultsToSink(results, sink);
    return File.fromUri(uri).readAsBytesSync();
  }

  @override
  GlobalTypeInferenceResults deserializeGlobalTypeInferenceResults(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      JClosedWorld closedWorld,
      List<int> globalTypeInferenceResultsData,
      SerializationIndices indices) {
    DataSourceReader globalTypeInferenceResultsSource = DataSourceReader(
      BinaryDataSource(globalTypeInferenceResultsData),
      options,
      indices,
      useDataKinds: useDataKinds,
    );
    return deserializeGlobalTypeInferenceResultsFromSource(
        options,
        reporter,
        environment,
        abstractValueStrategy,
        component,
        closedWorld,
        globalTypeInferenceResultsSource);
  }

  @override
  List<int> serializeClosedWorld(JClosedWorld closedWorld,
      CompilerOptions options, SerializationIndices indices) {
    Uri uri = Uri.base.resolve('closed_world.data');
    DataSinkWriter sink = DataSinkWriter(
        BinaryDataSink(RandomAccessBinaryOutputSink(uri)), options, indices,
        useDataKinds: useDataKinds);
    serializeClosedWorldToSink(closedWorld, sink);
    return File.fromUri(uri).readAsBytesSync();
  }

  @override
  JClosedWorld deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<int> data,
      SerializationIndices indices) {
    DataSourceReader source = DataSourceReader(
        BinaryDataSource(data), options, indices,
        useDataKinds: useDataKinds);
    var closedWorld = deserializeClosedWorldFromSource(options, reporter,
        environment, abstractValueStrategy, component, source);
    return closedWorld;
  }
}

class ObjectsInMemorySerializationStrategy
    extends SerializationStrategy<Object> {
  final bool useDataKinds;

  const ObjectsInMemorySerializationStrategy({this.useDataKinds = true});

  @override
  List<Object> serializeGlobalTypeInferenceResults(
      GlobalTypeInferenceResults results,
      CompilerOptions options,
      SerializationIndices indices) {
    List<Object> data = [];
    DataSinkWriter sink = DataSinkWriter(ObjectDataSink(data), options, indices,
        useDataKinds: useDataKinds);
    serializeGlobalTypeInferenceResultsToSink(results, sink);
    return data;
  }

  @override
  GlobalTypeInferenceResults deserializeGlobalTypeInferenceResults(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      JClosedWorld closedWorld,
      List<Object> globalTypeInferenceResultsData,
      SerializationIndices indices) {
    DataSourceReader globalTypeInferenceResultsSource = DataSourceReader(
        ObjectDataSource(globalTypeInferenceResultsData), options, indices,
        useDataKinds: useDataKinds);
    return deserializeGlobalTypeInferenceResultsFromSource(
        options,
        reporter,
        environment,
        abstractValueStrategy,
        component,
        closedWorld,
        globalTypeInferenceResultsSource);
  }

  @override
  List<Object> serializeClosedWorld(JClosedWorld closedWorld,
      CompilerOptions options, SerializationIndices indices) {
    List<Object> data = [];
    DataSinkWriter sink = DataSinkWriter(ObjectDataSink(data), options, indices,
        useDataKinds: useDataKinds);
    serializeClosedWorldToSink(closedWorld, sink);
    return data;
  }

  @override
  JClosedWorld deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<Object> data,
      SerializationIndices indices) {
    DataSourceReader source = DataSourceReader(
        ObjectDataSource(data), options, indices,
        useDataKinds: useDataKinds);
    var closedWorld = deserializeClosedWorldFromSource(options, reporter,
        environment, abstractValueStrategy, component, source);
    return closedWorld;
  }
}
