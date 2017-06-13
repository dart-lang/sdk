// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Output provider that collects the output in string buffers.

library output_collector;

import 'dart:async';
import 'package:compiler/compiler_new.dart';

class BufferedOutputSink implements OutputSink {
  StringBuffer sb = new StringBuffer();
  String text;

  void add(String event) {
    sb.write(event);
  }

  void close() {
    text = sb.toString();
    sb = null;
  }

  String toString() {
    return text ?? sb.toString();
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

  /// `true` if any output has been collected.
  bool get hasOutput => !outputMap.isEmpty;

  /// `true` if any output other than main output has been collected.
  bool get hasExtraOutput {
    for (OutputType type in outputMap.keys) {
      for (String name in outputMap[type].keys) {
        if (name != '') return true;
      }
    }
    return false;
  }

  @override
  OutputSink createOutputSink(String name, String extension, OutputType type) {
    Map<String, BufferedOutputSink> sinkMap =
        outputMap.putIfAbsent(type, () => {});
    return sinkMap.putIfAbsent(name, () => new BufferedOutputSink());
  }
}
