// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_utilities/src/api_summary/src/unique_namer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utilities.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UniqueNamerTest);
  });
}

@reflectiveTest
class UniqueNamerTest extends ApiSummaryTest {
  Future<void> test_collidingNamesAreDisambiguated() async {
    var f1 = (await analyzeLibrary(
      pathWithinLib: 'file1.dart',
      'f() {}',
    )).getTopLevelFunction('f')!;
    var f2 = (await analyzeLibrary(
      pathWithinLib: 'file2.dart',
      'f() {}',
    )).getTopLevelFunction('f')!;
    var uniqueNamer = UniqueNamer();
    var f1Name = uniqueNamer.name(f1);
    var f2Name = uniqueNamer.name(f2);
    expect(f1Name.toString(), 'f@1');
    expect(f2Name.toString(), 'f@2');
  }

  Future<void> test_name_returnsSameNameOnSuccessiveCalls() async {
    var f = (await analyzeLibrary('f() {}')).getTopLevelFunction('f')!;
    var uniqueNamer = UniqueNamer();
    var name1 = uniqueNamer.name(f);
    var name2 = uniqueNamer.name(f);
    expect(name1, same(name2));
  }

  Future<void> test_nonCollidingNamesAreNotDisambiguated() async {
    var f = (await analyzeLibrary(
      pathWithinLib: 'file1.dart',
      'f() {}',
    )).getTopLevelFunction('f')!;
    var g = (await analyzeLibrary(
      pathWithinLib: 'file2.dart',
      'g() {}',
    )).getTopLevelFunction('g')!;
    var uniqueNamer = UniqueNamer();
    var fName = uniqueNamer.name(f);
    var gName = uniqueNamer.name(g);
    expect(fName.toString(), 'f');
    expect(gName.toString(), 'g');
  }

  Future<void> test_three_collisions() async {
    var f1 = (await analyzeLibrary(
      pathWithinLib: 'file1.dart',
      'f() {}',
    )).getTopLevelFunction('f')!;
    var f2 = (await analyzeLibrary(
      pathWithinLib: 'file2.dart',
      'f() {}',
    )).getTopLevelFunction('f')!;
    var f3 = (await analyzeLibrary(
      pathWithinLib: 'file3.dart',
      'f() {}',
    )).getTopLevelFunction('f')!;
    var uniqueNamer = UniqueNamer();
    var f1Name = uniqueNamer.name(f1);
    var f2Name = uniqueNamer.name(f2);
    var f3Name = uniqueNamer.name(f3);
    expect(f1Name.toString(), 'f@1');
    expect(f2Name.toString(), 'f@2');
    expect(f3Name.toString(), 'f@3');
  }
}
