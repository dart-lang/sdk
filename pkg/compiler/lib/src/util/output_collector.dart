// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Output provider that collects the output in string buffers.

library output_collector;

import 'package:compiler/compiler_api.dart' as api;

class BufferedOutputSink implements api.OutputSink {
  StringBuffer? sb = StringBuffer();
  String? text;

  @override
  void add(String event) {
    sb!.write(event);
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

class BufferedBinaryOutputSink implements api.BinaryOutputSink {
  final Uri uri;

  List<int> list = <int>[];

  BufferedBinaryOutputSink(this.uri);

  @override
  void add(List<int> buffer, [int start = 0, int? end]) {
    list.addAll(buffer.sublist(start, end));
  }

  @override
  void close() {}

  @override
  String toString() {
    return 'BufferedBinaryOutputSink($uri)';
  }
}

class CloningOutputSink implements api.OutputSink {
  final List<api.OutputSink> sinks;

  CloningOutputSink(this.sinks);

  @override
  void add(String event) {
    sinks.forEach((api.OutputSink sink) => sink.add(event));
  }

  @override
  void close() {
    sinks.forEach((api.OutputSink sink) => sink.close());
  }
}

class OutputCollector implements api.CompilerOutput {
  Map<api.OutputType, Map<String, BufferedOutputSink>> outputMap = {};
  Map<Uri, BufferedBinaryOutputSink> binaryOutputMap = {};

  String? getOutput(String name, api.OutputType type) {
    Map<String, BufferedOutputSink>? sinkMap = outputMap[type];
    if (sinkMap == null) {
      print("No output available for $type.");
      return null;
    }
    BufferedOutputSink? sink = sinkMap[name];
    if (sink == null) {
      print("Output '$name' not found for $type. Available: ${sinkMap.keys}");
      return null;
    } else {
      return sink.text;
    }
  }

  @override
  api.BinaryOutputSink createBinarySink(Uri uri) {
    return binaryOutputMap.putIfAbsent(
        uri, () => BufferedBinaryOutputSink(uri));
  }

  /// `true` if any output has been collected.
  bool get hasOutput => outputMap.isNotEmpty || binaryOutputMap.isNotEmpty;

  /// `true` if any output other than main output has been collected.
  bool get hasExtraOutput {
    for (Map<String, BufferedOutputSink> output in outputMap.values) {
      for (String name in output.keys) {
        if (name != '') return true;
      }
    }
    return binaryOutputMap.isNotEmpty;
  }

  @override
  api.OutputSink createOutputSink(
      String name, String extension, api.OutputType type) {
    Map<String, BufferedOutputSink> sinkMap =
        outputMap.putIfAbsent(type, () => {});
    return sinkMap.putIfAbsent(name, () => BufferedOutputSink());
  }

  Map<api.OutputType, Map<String, String>> clear() {
    Map<api.OutputType, Map<String, String>> outputMapResult = {};
    outputMap.forEach(
        (api.OutputType outputType, Map<String, BufferedOutputSink> sinkMap) {
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
