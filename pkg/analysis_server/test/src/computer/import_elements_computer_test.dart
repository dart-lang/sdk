// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/import_elements_computer.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:front_end/src/base/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportElementsComputerTest);
  });
}

@reflectiveTest
class ImportElementsComputerTest extends AbstractContextTest {
  String path;
  String originalContent;
  ImportElementsComputer computer;
  SourceFileEdit sourceFileEdit;

  void assertChanges(String expectedContent) {
    String resultCode =
        SourceEdit.applySequence(originalContent, sourceFileEdit.edits);
    expect(resultCode, expectedContent);
  }

  void assertNoChanges() {
    expect(sourceFileEdit.edits, isEmpty);
  }

  Future<Null> computeChanges(List<ImportedElements> importedElements) async {
    SourceChange change = await computer.createEdits(importedElements);
    expect(change, isNotNull);
    List<SourceFileEdit> edits = change.edits;
    expect(edits, hasLength(1));
    sourceFileEdit = edits[0];
    expect(sourceFileEdit, isNotNull);
  }

  Future<Null> createBuilder(String content) async {
    originalContent = content;
    provider.newFile(path, content);
    AnalysisResult result = await driver.getResult(path);
    computer = new ImportElementsComputer(provider, result);
  }

  void setUp() {
    super.setUp();
    path = provider.convertPath('/test.dart');
  }

  test_createEdits_addImport_noPrefix() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' as foo;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' as foo;
import 'package:pkg/foo.dart';
''');
  }

  test_createEdits_addImport_prefix() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart';
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, 'foo', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart';
import 'package:pkg/foo.dart' as foo;
''');
  }

  test_createEdits_addShow_multipleNames() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show B;
import 'package:pkg/foo.dart' as foo;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A', 'C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show B, A, C;
import 'package:pkg/foo.dart' as foo;
''');
  }

  test_createEdits_addShow_removeHide() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show A, B hide C, D;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show A, B, C hide D;
''');
  }

  test_createEdits_addShow_singleName_noPrefix() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show B;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show B, A;
''');
  }

  test_createEdits_addShow_singleName_prefix() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show C;
import 'package:pkg/foo.dart' as foo show B;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, 'foo', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show C;
import 'package:pkg/foo.dart' as foo show B, A;
''');
  }

  test_createEdits_alreadyImported_noCombinators() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart';
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A', 'B'])
    ]);
    assertNoChanges();
  }

  test_createEdits_alreadyImported_withPrefix() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' as foo;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, 'foo', <String>['A', 'B'])
    ]);
    assertNoChanges();
  }

  test_createEdits_alreadyImported_withShow() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show A;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A'])
    ]);
    assertNoChanges();
  }

  test_createEdits_noElements() async {
    await createBuilder('');
    await computeChanges(<ImportedElements>[]);
    assertNoChanges();
  }

  test_createEdits_removeHide_firstInCombinator() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide B, C;
''');
  }

  test_createEdits_removeHide_lastInCombinator() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A, B;
''');
  }

  test_createEdits_removeHide_middleInCombinator() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A, C;
''');
  }

  test_createEdits_removeHide_multipleCombinators() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C hide A, B, C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A, C hide A, C;
''');
  }

  test_createEdits_removeHide_multipleNames() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C hide D, E, F hide G, H, I;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A', 'E', 'I'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide B, C hide D, F hide G, H;
''');
  }

  test_createEdits_removeHideCombinator_first() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A hide B hide C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide B hide C;
''');
  }

  test_createEdits_removeHideCombinator_last() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A hide B hide C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A hide B;
''');
  }

  test_createEdits_removeHideCombinator_middle() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A hide B hide C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A hide C;
''');
  }

  test_createEdits_removeHideCombinator_only() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart';
''');
  }

  test_createEdits_removeHideCombinator_only_multiple() async {
    Source fooSource = addPackageSource('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooSource.fullName, '', <String>['A', 'B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart';
''');
  }
}
