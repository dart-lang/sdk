// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/import_elements_computer.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';
import '../../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportElementsComputerTest);
  });
}

@reflectiveTest
class ImportElementsComputerTest extends AbstractContextTest {
  late String path;
  late String originalContent;
  late ImportElementsComputer computer;
  late SourceFileEdit? sourceFileEdit;

  void assertChanges(String expectedContent) {
    var resultCode =
        SourceEdit.applySequence(originalContent, sourceFileEdit!.edits);
    expect(resultCode, expectedContent);
  }

  void assertNoChanges() {
    expect(sourceFileEdit, isNull);
  }

  Future<void> computeChanges(List<ImportedElements> importedElements) async {
    var change = await computer.createEdits(importedElements);
    expect(change, isNotNull);
    var edits = change.edits;
    if (edits.length == 1) {
      sourceFileEdit = edits[0];
      expect(sourceFileEdit, isNotNull);
    } else {
      sourceFileEdit = null;
    }
  }

  Future<void> createBuilder(String content) async {
    originalContent = content;
    final file = newFile(path, content);
    var result = await getResolvedUnit(file);
    computer = ImportElementsComputer(resourceProvider, result);
  }

  @override
  void setUp() {
    super.setUp();
    path = convertPath('$testPackageLibPath/test.dart');
  }

  Future<void> test_createEdits_addImport_doubleQuotes() async {
    registerLintRules();
    var config = AnalysisOptionsFileConfig(
      lints: ['prefer_double_quotes'],
    );
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      config.toContent(),
    );

    await createBuilder('''
void f() {
  // paste here
}
''');
    await computeChanges([
      ImportedElements(convertPath('/sdk/lib/math/math.dart'), '', ['Random'])
    ]);
    assertChanges('''
import "dart:math";

void f() {
  // paste here
}
''');
  }

  Future<void> test_createEdits_addImport_noDirectives() async {
    await createBuilder('''
void f() {
  // paste here
}
''');
    await computeChanges([
      ImportedElements(convertPath('/sdk/lib/math/math.dart'), '', ['Random'])
    ]);
    assertChanges('''
import 'dart:math';

void f() {
  // paste here
}
''');
  }

  Future<void> test_createEdits_addImport_noPrefix() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' as foo;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' as foo;
import 'package:pkg/foo.dart';
''');
  }

  Future<void> test_createEdits_addImport_prefix() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart';
''');
    await computeChanges([
      ImportedElements(fooFile.path, 'foo', ['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart';
import 'package:pkg/foo.dart' as foo;
''');
  }

  Future<void> test_createEdits_addShow_multipleNames() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' show B;
import 'package:pkg/foo.dart' as foo;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A', 'C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show B, A, C;
import 'package:pkg/foo.dart' as foo;
''');
  }

  Future<void> test_createEdits_addShow_removeHide() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' show A, B hide C, D;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show A, B, C hide D;
''');
  }

  Future<void> test_createEdits_addShow_singleName_noPrefix() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' show B;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show B, A;
''');
  }

  Future<void> test_createEdits_addShow_singleName_prefix() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' show C;
import 'package:pkg/foo.dart' as foo show B;
''');
    await computeChanges([
      ImportedElements(fooFile.path, 'foo', ['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' show C;
import 'package:pkg/foo.dart' as foo show B, A;
''');
  }

  Future<void> test_createEdits_alreadyImported_noCombinators() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart';
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A', 'B'])
    ]);
    assertNoChanges();
  }

  Future<void> test_createEdits_alreadyImported_withPrefix() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' as foo;
''');
    await computeChanges([
      ImportedElements(fooFile.path, 'foo', ['A', 'B'])
    ]);
    assertNoChanges();
  }

  Future<void> test_createEdits_alreadyImported_withShow() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' show A;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A'])
    ]);
    assertNoChanges();
  }

  Future<void> test_createEdits_importSelf() async {
    await createBuilder('''
class A {
  A parent;
}
''');
    await computeChanges([
      ImportedElements(path, '', ['A'])
    ]);
    assertNoChanges();
  }

  Future<void> test_createEdits_invalidUri() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'pakage:pkg/foo.dart';
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A'])
    ]);
    assertChanges('''
import 'pakage:pkg/foo.dart';
import 'package:pkg/foo.dart';
''');
  }

  Future<void> test_createEdits_noElements() async {
    await createBuilder('');
    await computeChanges([]);
    assertNoChanges();
  }

  Future<void> test_createEdits_removeHide_firstInCombinator() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide B, C;
''');
  }

  Future<void> test_createEdits_removeHide_lastInCombinator() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A, B;
''');
  }

  Future<void> test_createEdits_removeHide_middleInCombinator() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A, C;
''');
  }

  Future<void> test_createEdits_removeHide_multipleCombinators() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C hide A, B, C;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A, C hide A, C;
''');
  }

  Future<void> test_createEdits_removeHide_multipleNames() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B, C hide D, E, F hide G, H, I;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A', 'E', 'I'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide B, C hide D, F hide G, H;
''');
  }

  Future<void> test_createEdits_removeHideCombinator_first() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A hide B hide C;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide B hide C;
''');
  }

  Future<void> test_createEdits_removeHideCombinator_last() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A hide B hide C;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['C'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A hide B;
''');
  }

  Future<void> test_createEdits_removeHideCombinator_middle() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A hide B hide C;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart' hide A hide C;
''');
  }

  Future<void> test_createEdits_removeHideCombinator_only() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart';
''');
  }

  Future<void> test_createEdits_removeHideCombinator_only_multiple() async {
    var fooFile = newFile('$workspaceRootPath/pkg/lib/foo.dart', '');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'pkg', rootPath: '$workspaceRootPath/pkg'),
    );

    await createBuilder('''
import 'package:pkg/foo.dart' hide A, B;
''');
    await computeChanges([
      ImportedElements(fooFile.path, '', ['A', 'B'])
    ]);
    assertChanges('''
import 'package:pkg/foo.dart';
''');
  }
}
