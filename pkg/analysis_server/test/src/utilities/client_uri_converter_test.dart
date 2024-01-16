// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/client_uri_converter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../tool/codebase/failing_tests.dart';
import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClientUriConverterTest);
  });
}

@reflectiveTest
class ClientUriConverterTest extends AbstractSingleUnitTest {
  Future<void> test_noop_fromUri() async {
    var converter = ClientUriConverter.noop(pathContext);

    for (var fileUri in [
      Uri.file(convertPath('/a/b.dart')),
      Uri.file(convertPath('/a/b.txt')),
      Uri.file(convertPath('/a/b.macro.dart')),
      Uri.file(convertPath('/a/b')),
      Uri.file(convertPath('/')),
    ]) {
      // For no-op, should be the same as simple fromUri on pathContext.
      expect(converter.fromClientUri(fileUri), pathContext.fromUri(fileUri));
    }
  }

  Future<void> test_noop_toUri() async {
    var converter = ClientUriConverter.noop(pathContext);

    for (var filePath in [
      convertPath('/a/b.dart'),
      convertPath('/a/b.txt'),
      convertPath('/a/b.macro.dart'),
      convertPath('/a/b'),
      convertPath('/'),
    ]) {
      // For no-op, should be the same as simple toUri on pathContext.
      expect(converter.toClientUri(filePath), pathContext.toUri(filePath));
    }
  }
}
