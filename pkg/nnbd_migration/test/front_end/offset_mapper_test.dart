// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/src/front_end/offset_mapper.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OffsetMapperTest);
  });
}

@reflectiveTest
class OffsetMapperTest extends AbstractAnalysisTest {
  void test_identity() {
    var mapper = OffsetMapper.identity;
    expect(mapper.map(0), 0);
    expect(mapper.map(20), 20);
    expect(mapper.map(0xFFFFFF), 0xFFFFFF);
  }

  void test_insertMapper() {
    var mapper = OffsetMapper.forInsertion(10, 5);
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), 15);
    expect(mapper.map(11), 16);
    expect(mapper.map(20), 25);
  }

  void test_multipleEdits() {
    var mapper = OffsetMapper.forEdits([
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

  void test_rebase_deletionRebasingInsertion() {
    var mapper = OffsetMapper.rebase(OffsetMapper.forReplacement(5, 2, ''),
        OffsetMapper.forInsertion(10, 5));
    expect(mapper.map(0), 0);
    expect(mapper.map(4), 4);
    expect(mapper.map(5), null);
    expect(mapper.map(6), null);
    expect(mapper.map(7), 5);
    expect(mapper.map(8), 6);
    expect(mapper.map(11), 14);
    expect(mapper.map(12), 15);
  }

  void test_rebase_insertionRebasingDeletion() {
    var mapper = OffsetMapper.rebase(OffsetMapper.forInsertion(5, 5),
        OffsetMapper.forReplacement(10, 5, ''));
    expect(mapper.map(0), 0);
    expect(mapper.map(4), 4);
    expect(mapper.map(5), 10);
    expect(mapper.map(6), 11);
    expect(mapper.map(9), 14);
    expect(mapper.map(10), null);
    expect(mapper.map(14), null);
    expect(mapper.map(15), 15);
    expect(mapper.map(16), 16);
  }

  void test_rebase_insertMapper() {
    var mapper = OffsetMapper.rebase(
        OffsetMapper.forInsertion(5, 5), OffsetMapper.forInsertion(10, 5));
    expect(mapper.map(0), 0);
    expect(mapper.map(4), 4);
    expect(mapper.map(5), 10);
    expect(mapper.map(6), 11);
    expect(mapper.map(9), 14);
    expect(mapper.map(10), 20);
    expect(mapper.map(11), 21);
    expect(mapper.map(12), 22);
  }

  void test_replacementMapper_effectivelyDeletes() {
    var mapper = OffsetMapper.forReplacement(10, 5, '');
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), null);
    expect(mapper.map(11), null);
    expect(mapper.map(14), null);
    expect(mapper.map(15), 10);
  }

  void test_replacementMapper_effectivelyDeletesAndInserts() {
    var mapper = OffsetMapper.forReplacement(10, 5, 'foo');
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), null);
    expect(mapper.map(11), null);
    expect(mapper.map(14), null);
    expect(mapper.map(15), 13);
    expect(mapper.map(16), 14);
  }

  void test_replacementMapper_effectivelyInserts() {
    var mapper = OffsetMapper.forReplacement(10, 0, 'five ');
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), 15);
    expect(mapper.map(11), 16);
    expect(mapper.map(20), 25);
  }

  void test_sequence_insertMappers() {
    var mapper = OffsetMapper.sequence(
        OffsetMapper.forInsertion(30, 10), OffsetMapper.forInsertion(10, 10));
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), 20);
    expect(mapper.map(11), 21);
    expect(mapper.map(29), 39);
    expect(mapper.map(30), 50);
    expect(mapper.map(31), 51);
  }

  void test_sequence_insertMappers_firstBeforeSecond() {
    var mapper = OffsetMapper.sequence(
        OffsetMapper.forInsertion(10, 10), OffsetMapper.forInsertion(30, 10));
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), 20);
    expect(mapper.map(11), 21);
    expect(mapper.map(19), 29);
    expect(mapper.map(20), 40);
    expect(mapper.map(21), 41);
  }

  void test_sequence_insertMappers_overlapping() {
    // by inserting into the middle of a previous insertion, we just effectively
    // make the first insertion longer.
    var mapper = OffsetMapper.sequence(
        OffsetMapper.forInsertion(10, 10), OffsetMapper.forInsertion(15, 5));
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), 25);
    expect(mapper.map(11), 26);
    expect(mapper.map(20), 35);
  }

  void test_sequence_replacementMappers_deleteAmidInsert() {
    // Deleting in the middle of an insertion is equivalent to originally making
    // a smaller insertion.
    var mapper = OffsetMapper.sequence(
        OffsetMapper.forReplacement(10, 0, 'five '),
        OffsetMapper.forReplacement(12, 3, ''));
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), 12);
    expect(mapper.map(11), 13);
  }

  void test_sequence_replacementMappers_deleteAroundInsert() {
    // Deleting around an insertion is equivalent to originally making a smaller
    // deletion.
    var mapper = OffsetMapper.sequence(
        OffsetMapper.forReplacement(15, 0, 'five '),
        OffsetMapper.forReplacement(10, 15, ''));
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), null);
    expect(mapper.map(11), null);
    expect(mapper.map(19), null);
    expect(mapper.map(20), 10);
    expect(mapper.map(21), 11);
  }

  void test_sequence_replacementMappers_deleteIntoInsert() {
    // A deletion starting before an insertion that goes into the middle of an
    // insertion is equivalent to a smaller deletion + a smaller insertion.
    var mapper = OffsetMapper.sequence(
        OffsetMapper.forReplacement(10, 0, 'five '),
        OffsetMapper.forReplacement(5, 7, ''));
    expect(mapper.map(0), 0);
    expect(mapper.map(4), 4);
    expect(mapper.map(5), null);
    expect(mapper.map(6), null);
    expect(mapper.map(10), 8);
    expect(mapper.map(11), 9);
  }

  void test_sequence_replacementMappers_deletePastInsert() {
    // A deletion starting in the middle of an insertion that goes past the end
    // is equivalent to a smaller insertion + a smaller deletion.
    var mapper = OffsetMapper.sequence(
        OffsetMapper.forReplacement(10, 0, 'five '),
        OffsetMapper.forReplacement(12, 10, ''));
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), null);
    expect(mapper.map(11), null);
    expect(mapper.map(16), null);
    expect(mapper.map(17), 12);
    expect(mapper.map(18), 13);
  }

  void test_sequence_replacementMappers_insertAmidDeletion() {
    // Inserting at a deletion offset is equivalent to inserting after the
    // deletion.
    var mapper = OffsetMapper.sequence(OffsetMapper.forReplacement(10, 5, ''),
        OffsetMapper.forReplacement(10, 0, 'foo'));
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), null);
    expect(mapper.map(11), null);
    expect(mapper.map(14), null);
    expect(mapper.map(15), 13);
    expect(mapper.map(16), 14);
  }

  void test_sequence_replacementMappers_twoDeletions_consecutive() {
    var mapper = OffsetMapper.sequence(OffsetMapper.forReplacement(10, 5, ''),
        OffsetMapper.forReplacement(10, 5, ''));
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), null);
    expect(mapper.map(11), null);
    expect(mapper.map(19), null);
    expect(mapper.map(20), 10);
    expect(mapper.map(21), 11);
  }

  void test_sequence_replacementMappers_twoDeletions_separate() {
    var mapper = OffsetMapper.sequence(OffsetMapper.forReplacement(10, 5, ''),
        OffsetMapper.forReplacement(15, 5, ''));
    expect(mapper.map(0), 0);
    expect(mapper.map(9), 9);
    expect(mapper.map(10), null);
    expect(mapper.map(11), null);
    expect(mapper.map(14), null);
    expect(mapper.map(15), 10);
    expect(mapper.map(16), 11);
    expect(mapper.map(19), 14);
    expect(mapper.map(20), null);
    expect(mapper.map(21), null);
    expect(mapper.map(24), null);
    expect(mapper.map(25), 15);
    expect(mapper.map(26), 16);
  }

  void test_singleEdit() {
    var mapper = OffsetMapper.forEdits([
      SourceEdit(13, 0, '?'),
    ]);
    expect(mapper.map(0), 0);
    expect(mapper.map(13), 13);
    expect(mapper.map(14), 15);
  }
}
