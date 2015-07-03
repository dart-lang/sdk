// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Output provider that collects the output in string buffers.

library output_collector;

import 'dart:async';

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

class OutputCollector {
  Map<String, Map<String, BufferedEventSink>> outputMap = {};

  EventSink<String> call(String name, String extension) {
    Map<String, BufferedEventSink> sinkMap =
        outputMap.putIfAbsent(extension, () => {});
    return sinkMap.putIfAbsent(name, () => new BufferedEventSink());
  }

  String getOutput(String name, String extension) {
    Map<String, BufferedEventSink> sinkMap = outputMap[extension];
    if (sinkMap == null) return null;
    BufferedEventSink sink = sinkMap[name];
    return sink != null ? sink.text : null;
  }
}
