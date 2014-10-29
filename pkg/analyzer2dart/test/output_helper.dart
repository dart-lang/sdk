// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper classes for testing compiler output.
library test.output_helper;

import 'dart:async';


class CollectingOutputProvider {
  StringBufferSink output;

  EventSink<String> call(String name, String extension) {
    return output = new StringBufferSink();
  }
}

class StringBufferSink implements EventSink<String> {
  StringBuffer sb = new StringBuffer();

  void add(String text) {
    sb.write(text);
  }

  void addError(errorEvent, [StackTrace stackTrace]) {}

  void close() {}

  String get text => sb.toString();
}

