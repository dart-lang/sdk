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

  List<int> serializeComponent(GlobalTypeInferenceResults results) {
    JsClosedWorld closedWorld = results.closedWorld;
    ir.Component component = closedWorld.elementMap.programEnv.mainComponent;
    return ir.serializeComponent(component);
  }

  List<T> serializeData(GlobalTypeInferenceResults results);

  ir.Component deserializeComponent(List<int> data) {
    ir.Component component = new ir.Component();
    new BinaryBuilder(data).readComponent(component);
    return component;
  }

  GlobalTypeInferenceResults deserializeData(
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
  List<int> serializeData(GlobalTypeInferenceResults results) {
    ByteSink byteSink = new ByteSink();
    DataSink sink = new BinarySink(byteSink, useDataKinds: useDataKinds);
    serializeGlobalTypeInferenceResults(results, sink);
    return byteSink.builder.takeBytes();
  }

  @override
  GlobalTypeInferenceResults deserializeData(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<int> data) {
    DataSource source = new BinarySourceImpl(data, useDataKinds: useDataKinds);
    return deserializeGlobalTypeInferenceResults(options, reporter, environment,
        abstractValueStrategy, component, source);
  }
}

class BytesOnDiskSerializationStrategy extends SerializationStrategy<int> {
  final bool useDataKinds;

  const BytesOnDiskSerializationStrategy({this.useDataKinds: false});

  @override
  List<int> serializeData(GlobalTypeInferenceResults results) {
    Uri uri = Uri.base.resolve('world.data');
    DataSink sink = new BinarySink(
        new BinaryOutputSinkAdapter(new RandomAccessBinaryOutputSink(uri)),
        useDataKinds: useDataKinds);
    serializeGlobalTypeInferenceResults(results, sink);
    return new File.fromUri(uri).readAsBytesSync();
  }

  @override
  GlobalTypeInferenceResults deserializeData(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<int> data) {
    DataSource source = new BinarySourceImpl(data, useDataKinds: useDataKinds);
    return deserializeGlobalTypeInferenceResults(options, reporter, environment,
        abstractValueStrategy, component, source);
  }
}

class ObjectsInMemorySerializationStrategy
    extends SerializationStrategy<Object> {
  final bool useDataKinds;

  const ObjectsInMemorySerializationStrategy({this.useDataKinds: true});

  @override
  List<Object> serializeData(GlobalTypeInferenceResults results) {
    List<Object> data = [];
    DataSink sink = new ObjectSink(data, useDataKinds: useDataKinds);
    serializeGlobalTypeInferenceResults(results, sink);
    return data;
  }

  @override
  GlobalTypeInferenceResults deserializeData(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      List<Object> data) {
    DataSource source = new ObjectSource(data, useDataKinds: useDataKinds);
    return deserializeGlobalTypeInferenceResults(options, reporter, environment,
        abstractValueStrategy, component, source);
  }
}
