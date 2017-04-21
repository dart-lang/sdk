// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.round_trip;

import 'dart:async';
import 'dart:io';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart';

const String usage = '''
Usage: round_trip.dart FILE.dill

Deserialize and serialize the given program and check that the resulting byte
sequence is identical to the original.
''';

void main(List<String> args) {
  if (args.length != 1) {
    print(usage);
    exit(1);
  }
  testRoundTrip(new File(args[0]).readAsBytesSync());
}

void testRoundTrip(List<int> bytes) {
  var program = new Program();
  new BinaryBuilder(bytes).readSingleFileProgram(program);
  new BinaryPrinterWithExpectedOutput(bytes).writeProgramFile(program);
}

class DummyStreamConsumer extends StreamConsumer<List<int>> {
  @override
  Future addStream(Stream<List<int>> stream) async => null;

  @override
  Future close() async => null;
}

/// Variant of the binary serializer that compares the output against an
/// existing buffer.
///
/// As opposed to comparing binary files directly, when this fails, the stack
/// trace shows what the serializer was doing when the output started to differ.
class BinaryPrinterWithExpectedOutput extends BinaryPrinter {
  final List<int> expectedBytes;
  int offset = 0;

  static const int eof = -1;

  BinaryPrinterWithExpectedOutput(this.expectedBytes)
      : super(new IOSink(new DummyStreamConsumer()));

  String show(int byte) {
    if (byte == eof) return 'EOF';
    return '$byte (0x${byte.toRadixString(16).padLeft(2, "0")})';
  }

  @override
  void writeByte(int byte) {
    if (offset == expectedBytes.length || expectedBytes[offset] != byte) {
      int expected =
          (offset >= expectedBytes.length) ? eof : expectedBytes[offset];
      throw 'At offset $offset: '
          'Expected ${show(expected)} but found ${show(byte)}';
    }
    ++offset;
  }

  @override
  void writeBytes(List<int> bytes) {
    bytes.forEach(writeByte);
  }
}
