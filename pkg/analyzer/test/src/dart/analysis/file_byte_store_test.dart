// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/file_byte_store.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileByteStoreValidatorTest);
  });
}

@reflectiveTest
class FileByteStoreValidatorTest {
  final validator = FileByteStoreValidator();

  test_get_bad_notEnoughBytes() {
    List<int> bytes = <int>[1, 2, 3];
    List<int> data = validator.getData(bytes);
    expect(data, isNull);
  }

  test_get_bad_notEnoughBytes_zero() {
    List<int> bytes = <int>[];
    List<int> data = validator.getData(bytes);
    expect(data, isNull);
  }

  test_get_bad_wrongChecksum() {
    List<int> data = <int>[1, 2, 3];
    List<int> bytes = validator.wrapData(data);

    // Damage the checksum.
    expect(bytes[bytes.length - 1], isNot(42));
    bytes[bytes.length - 1] = 42;

    List<int> data2 = validator.getData(bytes);
    expect(data2, isNull);
  }

  test_get_bad_wrongVersion() {
    List<int> bytes = <int>[0xBA, 0xDA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
    List<int> data = validator.getData(bytes);
    expect(data, isNull);
  }

  test_get_good() {
    List<int> data = <int>[1, 2, 3];
    List<int> bytes = validator.wrapData(data);
    List<int> data2 = validator.getData(bytes);
    expect(data2, hasLength(3));
    expect(data2, data);
  }

  test_get_good_zeroBytesData() {
    List<int> data = <int>[];
    List<int> bytes = validator.wrapData(data);
    List<int> data2 = validator.getData(bytes);
    expect(data2, hasLength(0));
    expect(data2, data);
  }
}
