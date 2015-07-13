// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Output provider that collects the output in string buffers.

library output_collector;

import 'dart:async';
import 'package:compiler/compiler_new.dart';

class BufferedEventSink implements EventSink<String> {
  StringBuffer sb = new StringBuffer();
  String text;

  void add(String event) {
    sb.write(event);
  }

  void addError(errorEvent, [StackTrace stackTrace]) {
    // Do not support this.
  }

  void close() {
    text = sb.toString();
    sb = null;
  }
}

class CloningEventSink implements EventSink<String> {
  final List<EventSink<String>> sinks;

  CloningEventSink(this.sinks);

  @override
  void add(String event) {
    sinks.forEach((EventSink<String> sink) => sink.add(event));
  }

  @override
  void addError(errorEvent, [StackTrace stackTrace]) {
    sinks.forEach((EventSink<String> sink) {
      sink.addError(errorEvent, stackTrace);
    });
  }

  @override
  void close() {
    sinks.forEach((EventSink<String> sink) => sink.close());
  }
}

class OutputCollector implements CompilerOutput {
  Map<String, Map<String, BufferedEventSink>> outputMap = {};

  EventSink<String> call(String name, String extension) {
    return createEventSink(name, extension);
  }

  String getOutput(String name, String extension) {
    Map<String, BufferedEventSink> sinkMap = outputMap[extension];
    if (sinkMap == null) return null;
    BufferedEventSink sink = sinkMap[name];
    return sink != null ? sink.text : null;
  }

  /// `true` if any output has been collected.
  bool get hasOutput => !outputMap.isEmpty;

  /// `true` if any output other than main output has been collected.
  bool get hasExtraOutput {
    for (String extension in outputMap.keys) {
      for (String name in outputMap[extension].keys) {
        if (name != '') return true;
      }
    }
    return false;
  }

  @override
  EventSink<String> createEventSink(String name, String extension) {
    Map<String, BufferedEventSink> sinkMap =
        outputMap.putIfAbsent(extension, () => {});
    return sinkMap.putIfAbsent(name, () => new BufferedEventSink());
  }
}
