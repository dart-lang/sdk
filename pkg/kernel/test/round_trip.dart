// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.round_trip;

import 'dart:io';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart';

const String usage = '''
Usage: round_trip.dart FILE.dill [sdk.dill]

Deserialize and serialize the given component and check that the resulting byte
sequence is identical to the original.
''';

void main(List<String> args) async {
  if (args.length == 1) {
    await testRoundTrip(new File(args[0]).readAsBytesSync(), null);
  } else if (args.length == 2) {
    await testRoundTrip(new File(args[0]).readAsBytesSync(),
        new File(args[1]).readAsBytesSync());
  } else {
    print(usage);
    exit(1);
  }
}

void testRoundTrip(List<int> bytes, List<int> sdkBytes) async {
  var component = new Component();
  if (sdkBytes != null) {
    var sdk = new Component(nameRoot: component.root);
    new BinaryBuilder(sdkBytes).readSingleFileComponent(sdk);
  }
  new BinaryBuilder(bytes).readSingleFileComponent(component);
  ByteSink sink = new ByteSink();
  new BinaryPrinter(sink).writeComponentFile(component);
  List<int> writtenBytes = sink.builder.takeBytes();
  if (bytes.length != writtenBytes.length) {
    throw "Byte-lengths differ: ${bytes.length} vs ${writtenBytes.length}";
  }
  for (int i = 0; i < bytes.length; i++) {
    if (bytes[i] != writtenBytes[i]) {
      throw "Byte differs at index $i: "
          "${show(bytes[i])} vs ${show(writtenBytes[i])}";
    }
  }
  print("OK");
}

String show(int byte) {
  return '$byte (0x${byte.toRadixString(16).padLeft(2, "0")})';
}

/// A [Sink] that directly writes data into a byte builder.
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {}
}
