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
import '../inferrer/abstract_value_domain.dart';
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
    JsClosedWorld closedWorld = results.closedWorld;
    ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
    return serializeComponent(component);
  }

  List<T> serializeGlobalTypeInferenceResults(
      GlobalTypeInferenceResults results);

  List<int> serializeComponent(ir.Component component) {
    return ir.serializeComponent(component);
  }

  ir.Component deserializeComponent(List<int> data) {
    ir.Component component = new ir.Component();
    new BinaryBuilder(data).readComponent(component);
    return component;
  }

  GlobalTypeInferenceResults deserializeGlobalTypeInferenceResults(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<T> data);

  List<T> serializeClosedWorld(JsClosedWorld closedWorld);

  JsClosedWorld deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<T> data);
}

class BytesInMemorySerializationStrategy extends SerializationStrategy<int> {
  final bool useDataKinds;

  const BytesInMemorySerializationStrategy({this.useDataKinds: false});

  @override
  List<int> serializeGlobalTypeInferenceResults(
      GlobalTypeInferenceResults results) {
    ByteSink byteSink = new ByteSink();
    DataSink sink = new BinarySink(byteSink, useDataKinds: useDataKinds);
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
      List<int> data) {
    DataSource source = new BinarySourceImpl(data, useDataKinds: useDataKinds);
    return deserializeGlobalTypeInferenceResultsFromSource(options, reporter,
        environment, abstractValueStrategy, component, source);
  }

  @override
  List<int> serializeClosedWorld(JsClosedWorld closedWorld) {
    ByteSink byteSink = new ByteSink();
    DataSink sink = new BinarySink(byteSink, useDataKinds: useDataKinds);
    serializeClosedWorldToSink(closedWorld, sink);
    return byteSink.builder.takeBytes();
  }

  @override
  JsClosedWorld deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<int> data) {
    DataSource source = new BinarySourceImpl(data, useDataKinds: useDataKinds);
    return deserializeClosedWorldFromSource(options, reporter, environment,
        abstractValueStrategy, component, source);
  }
}

class BytesOnDiskSerializationStrategy extends SerializationStrategy<int> {
  final bool useDataKinds;

  const BytesOnDiskSerializationStrategy({this.useDataKinds: false});

  @override
  List<int> serializeGlobalTypeInferenceResults(
      GlobalTypeInferenceResults results) {
    Uri uri = Uri.base.resolve('world.data');
    DataSink sink = new BinarySink(
        new BinaryOutputSinkAdapter(new RandomAccessBinaryOutputSink(uri)),
        useDataKinds: useDataKinds);
    serializeGlobalTypeInferenceResultsToSink(results, sink);
    return new File.fromUri(uri).readAsBytesSync();
  }

  @override
  GlobalTypeInferenceResults deserializeGlobalTypeInferenceResults(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<int> data) {
    DataSource source = new BinarySourceImpl(data, useDataKinds: useDataKinds);
    return deserializeGlobalTypeInferenceResultsFromSource(options, reporter,
        environment, abstractValueStrategy, component, source);
  }

  @override
  List<int> serializeClosedWorld(JsClosedWorld closedWorld) {
    Uri uri = Uri.base.resolve('closed_world.data');
    DataSink sink = new BinarySink(
        new BinaryOutputSinkAdapter(new RandomAccessBinaryOutputSink(uri)),
        useDataKinds: useDataKinds);
    serializeClosedWorldToSink(closedWorld, sink);
    return new File.fromUri(uri).readAsBytesSync();
  }

  @override
  JsClosedWorld deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<int> data) {
    DataSource source = new BinarySourceImpl(data, useDataKinds: useDataKinds);
    return deserializeClosedWorldFromSource(options, reporter, environment,
        abstractValueStrategy, component, source);
  }
}

class ObjectsInMemorySerializationStrategy
    extends SerializationStrategy<Object> {
  final bool useDataKinds;

  const ObjectsInMemorySerializationStrategy({this.useDataKinds: true});

  @override
  List<Object> serializeGlobalTypeInferenceResults(
      GlobalTypeInferenceResults results) {
    List<Object> data = [];
    DataSink sink = new ObjectSink(data, useDataKinds: useDataKinds);
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
      List<Object> data) {
    DataSource source = new ObjectSource(data, useDataKinds: useDataKinds);
    return deserializeGlobalTypeInferenceResultsFromSource(options, reporter,
        environment, abstractValueStrategy, component, source);
  }

  @override
  List<Object> serializeClosedWorld(JsClosedWorld closedWorld) {
    List<Object> data = [];
    DataSink sink = new ObjectSink(data, useDataKinds: useDataKinds);
    serializeClosedWorldToSink(closedWorld, sink);
    return data;
  }

  @override
  JsClosedWorld deserializeClosedWorld(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<Object> data) {
    DataSource source = new ObjectSource(data, useDataKinds: useDataKinds);
    return deserializeClosedWorldFromSource(options, reporter, environment,
        abstractValueStrategy, component, source);
  }
}
