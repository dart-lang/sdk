// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart' show Component;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

final String _usage = '''
Usage: list_libraries input.dill
Lists libraries included in a kernel binary file.
''';

main(List<String> arguments) async {
  if (arguments.length != 1) {
    print(_usage);
    exit(1);
  }

  final input = arguments[0];

  final component = new Component();

  final List<int> bytes = new File(input).readAsBytesSync();
  new BinaryBuilder(bytes).readComponent(component);

  for (final lib in component.libraries) {
    print(lib.importUri);
  }
}
