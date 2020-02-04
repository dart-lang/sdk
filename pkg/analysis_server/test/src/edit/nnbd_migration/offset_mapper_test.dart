// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/offset_mapper.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OffsetMapperTest);
  });
}

@reflectiveTest
class OffsetMapperTest extends AbstractAnalysisTest {
  void test_identity() {
    OffsetMapper mapper = OffsetMapper.identity;
    expect(mapper.map(0), 0);
    expect(mapper.map(20), 20);
    expect(mapper.map(0xFFFFFF), 0xFFFFFF);
  }

  void test_multipleEdits() {
    OffsetMapper mapper = OffsetMapper.forEdits([
      SourceEdit(13, 0, '?'),
      SourceEdit(21, 0, '!'),
      SourceEdit(32, 0, '?'),
    ]);
    expect(mapper.map(0), 0);
    expect(mapper.map(13), 13);
    expect(mapper.map(14), 15);
    expect(mapper.map(21), 22);
    expect(mapper.map(22), 24);
    expect(mapper.map(32), 34);
    expect(mapper.map(33), 36);
    expect(mapper.map(55), 58);
  }

  void test_singleEdit() {
    OffsetMapper mapper = OffsetMapper.forEdits([
      SourceEdit(13, 0, '?'),
    ]);
    expect(mapper.map(0), 0);
    expect(mapper.map(13), 13);
    expect(mapper.map(14), 15);
  }
}
