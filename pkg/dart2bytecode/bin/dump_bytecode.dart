// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart2bytecode/bytecode_serialization.dart'
    show LinkReader, BufferedReader;
import 'package:dart2bytecode/declarations.dart' show Component;

final String _usage = '''
Usage: dump_bytecode input.bytecode
Dumps bytecode file.
''';

main(List<String> arguments) async {
  if (arguments.length != 1) {
    print(_usage);
    exit(1);
  }

  final input = arguments[0];

  final List<int> bytes = File(input).readAsBytesSync();

  final linkReader = LinkReader();
  final reader = BufferedReader(linkReader, bytes);
  final bytecodeComponent = Component.read(reader);
  print(bytecodeComponent.toString());
}
