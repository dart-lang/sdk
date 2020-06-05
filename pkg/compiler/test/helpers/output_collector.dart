// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Output provider that collects the output in string buffers.

library output_collector;

import 'package:compiler/compiler_new.dart';

class BufferedOutputSink implements OutputSink {
  StringBuffer sb = new StringBuffer();
  String text;

  @override
  void add(String event) {
    sb.write(event);
  }

  @override
  void close() {
    text = sb.toString();
    sb = null;
  }

  @override
  String toString() {
    return text ?? sb.toString();
  }
}

class BufferedBinaryOutputSink implements BinaryOutputSink {
  final Uri uri;

  List<int> list = <int>[];

  BufferedBinaryOutputSink(this.uri);

  @override
  void write(List<int> buffer, [int start = 0, int end]) {
    list.addAll(buffer.sublist(start, end));
  }

  @override
  void close() {}

  @override
  String toString() {
    return 'BufferedBinaryOutputSink($uri)';
  }
}

class CloningOutputSink implements OutputSink {
  final List<OutputSink> sinks;

  CloningOutputSink(this.sinks);

  @override
  void add(String event) {
    sinks.forEach((OutputSink sink) => sink.add(event));
  }

  @override
  void close() {
    sinks.forEach((OutputSink sink) => sink.close());
  }
}

class OutputCollector implements CompilerOutput {
  Map<OutputType, Map<String, BufferedOutputSink>> outputMap = {};
  Map<Uri, BufferedBinaryOutputSink> binaryOutputMap = {};

  String getOutput(String name, OutputType type) {
    Map<String, BufferedOutputSink> sinkMap = outputMap[type];
    if (sinkMap == null) {
      print("No output available for $type.");
      return null;
    }
    BufferedOutputSink sink = sinkMap[name];
    if (sink == null) {
      print("Output '$name' not found for $type. Available: ${sinkMap.keys}");
      return null;
    } else {
      return sink.text;
    }
  }

  @override
  BinaryOutputSink createBinarySink(Uri uri) {
    return binaryOutputMap.putIfAbsent(
        uri, () => new BufferedBinaryOutputSink(uri));
  }

  /// `true` if any output has been collected.
  bool get hasOutput => outputMap.isNotEmpty || binaryOutputMap.isNotEmpty;

  /// `true` if any output other than main output has been collected.
  bool get hasExtraOutput {
    for (OutputType type in outputMap.keys) {
      for (String name in outputMap[type].keys) {
        if (name != '') return true;
      }
    }
    return binaryOutputMap.isNotEmpty;
  }

  @override
  OutputSink createOutputSink(String name, String extension, OutputType type) {
    Map<String, BufferedOutputSink> sinkMap =
        outputMap.putIfAbsent(type, () => {});
    return sinkMap.putIfAbsent(name, () => new BufferedOutputSink());
  }

  Map<OutputType, Map<String, String>> clear() {
    Map<OutputType, Map<String, String>> outputMapResult = {};
    outputMap.forEach(
        (OutputType outputType, Map<String, BufferedOutputSink> sinkMap) {
      Map<String, String> sinkMapResult = outputMapResult[outputType] = {};
      sinkMap.forEach((String name, BufferedOutputSink sink) {
        sinkMapResult[name] = sink.toString();
      });
    });
    outputMap.clear();
    binaryOutputMap.clear();
    return outputMapResult;
  }
}
