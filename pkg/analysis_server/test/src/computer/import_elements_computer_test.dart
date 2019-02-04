// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/import_elements_computer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
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
    expect(sourceFileEdit, isNull);
  }

  Future<void> computeChanges(List<ImportedElements> importedElements) async {
    SourceChange change = await computer.createEdits(importedElements);
    expect(change, isNotNull);
    List<SourceFileEdit> edits = change.edits;
    if (edits.length == 1) {
      sourceFileEdit = edits[0];
      expect(sourceFileEdit, isNotNull);
    } else {
      sourceFileEdit = null;
    }
  }

  Future<void> createBuilder(String content) async {
    originalContent = content;
    newFile(path, content: content);
    ResolvedUnitResult result = await session.getResolvedUnit(path);
    computer = new ImportElementsComputer(resourceProvider, result);
  }

  void setUp() {
    super.setUp();
    path = convertPath('/home/test/lib/test.dart');
  }

  test_createEdits_addImport_noDirectives() async {
    await createBuilder('''
main() {
  // paste here
}
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(
          convertPath('/sdk/lib/math/math.dart'), '', <String>['Random'])
    ]);
    assertChanges('''
import 'dart:math';

main() {
  // paste here
}
''');
  }

  test_createEdits_addImport_noPrefix() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' as foo;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' as foo;
import 'package:pkg/foo.dart';
''');
  }

  test_createEdits_addImport_prefix() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart';
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, 'foo', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart';
import 'package:pkg/foo.dart' as foo;
''');
  }

  test_createEdits_addShow_multipleNames() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show B;
import 'package:pkg/foo.dart' as foo;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A', 'C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show B, A, C;
import 'package:pkg/foo.dart' as foo;
''');
  }

  test_createEdits_addShow_removeHide() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show A, B hide C, D;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show A, B, C hide D;
''');
  }

  test_createEdits_addShow_singleName_noPrefix() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show B;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show B, A;
''');
  }

  test_createEdits_addShow_singleName_prefix() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show C;
import 'package:pkg/foo.dart' as foo show B;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, 'foo', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show C;
import 'package:pkg/foo.dart' as foo show B, A;
''');
  }

  test_createEdits_alreadyImported_noCombinators() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart';
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A', 'B'])
    ]);
    assertNoChanges();
  }

  test_createEdits_alreadyImported_withPrefix() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' as foo;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, 'foo', <String>['A', 'B'])
    ]);
    assertNoChanges();
  }

  test_createEdits_alreadyImported_withShow() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' show A;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A'])
    ]);
    assertNoChanges();
  }

  test_createEdits_importSelf() async {
    await createBuilder('''
class A {
  A parent;
}
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(path, '', <String>['A'])
    ]);
    assertNoChanges();
  }

  test_createEdits_invalidUri() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'pakage:pkg/foo.dart';
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A'])
    ]);
    assertChanges('''
import 'pakage:pkg/foo.dart';
import 'package:pkg/foo.dart';
''');
  }

  test_createEdits_noElements() async {
    await createBuilder('');
    await computeChanges(<ImportedElements>[]);
    assertNoChanges();
  }

  test_createEdits_removeHide_firstInCombinator() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide B, C;
''');
  }

  test_createEdits_removeHide_lastInCombinator() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A, B;
''');
  }

  test_createEdits_removeHide_middleInCombinator() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A, C;
''');
  }

  test_createEdits_removeHide_multipleCombinators() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C hide A, B, C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A, C hide A, C;
''');
  }

  test_createEdits_removeHide_multipleNames() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C hide D, E, F hide G, H, I;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A', 'E', 'I'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide B, C hide D, F hide G, H;
''');
  }

  test_createEdits_removeHideCombinator_first() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A hide B hide C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide B hide C;
''');
  }

  test_createEdits_removeHideCombinator_last() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A hide B hide C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A hide B;
''');
  }

  test_createEdits_removeHideCombinator_middle() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A hide B hide C;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A hide C;
''');
  }

  test_createEdits_removeHideCombinator_only() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart';
''');
  }

  test_createEdits_removeHideCombinator_only_multiple() async {
    var fooFile = addPackageFile('pkg', 'foo.dart', '');
    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B;
''');
    await computeChanges(<ImportedElements>[
      new ImportedElements(fooFile.path, '', <String>['A', 'B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart';
''');
  }
}
