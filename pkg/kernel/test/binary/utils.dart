// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show BytesBuilder;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/kernel.dart';
export 'package:kernel/kernel.dart';

Library libRoundTrip(Library lib) {
  return serializationRoundTrip([lib])[0];
}

List<Library> serializationRoundTrip(List<Library> libraries) {
  Component c = new Component(libraries: libraries)
    ..setMainMethodAndMode(
        null, false, libraries.first.nonNullableByDefaultCompiledMode);
  List<int> bytes = serializeComponent(c);
  Component c2 = loadComponentFromBytes(bytes);
  return c2.libraries;
}

List<int> serializeComponent(Component c) {
  ByteSink byteSink = new ByteSink();
  BinaryPrinter printer = new BinaryPrinter(byteSink);
  printer.writeComponentFile(c);
  return byteSink.builder.takeBytes();
}

/// A [Sink] that directly writes data into a byte builder.
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {}
}
