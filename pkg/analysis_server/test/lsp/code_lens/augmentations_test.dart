// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../tool/lsp_spec/matchers.dart';
import '../../utils/lsp_protocol_extensions.dart';
import '../../utils/test_code_extensions.dart';
import '../server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationCodeLensTest);
    defineReflectiveTests(AugmentedCodeLensTest);
  });
}

abstract class AbstractAugmentationCodeLensTest
    extends AbstractLspAnalysisServerTest {
  late TestCode libraryCode;
  late TestCode augmentationCode;

  /// The name of the setting to control whether [codeLensTitle] CodeLenses
  /// are enabled.
  ///
  /// ```js
  /// "dart.codeLens": {
  ///   "augmented": true
  ///    ^^^^^^^^^
  /// }
  /// ```
  String get codeLensSettingName;

  /// The title of the [Command] in the [CodeLens]es being tested.
  String get codeLensTitle;

  /// The range in [sourceUri] that the CodeLens should appear for.
  Range get sourceRange;

  /// The document for which the CodeLens request will be sent.
  Uri get sourceUri;

  /// The range in [targetUri] where the CodeLens should navigate to.
  Range get targetRange;

  /// The document that the CodeLens should navigate to.
  Uri get targetUri;

  /// Expects a CodeLens in [sourceUri] at [sourceRange] with the title
  /// [codeLensTitle] that navigates to [targetRange] in [targetUri].
  Future<void> expectNavigationCodeLens({
    Uri? sourceUri,
    Range? sourceRange,
    Uri? targetUri,
    Range? targetRange,
  }) async {
    sourceUri ??= this.sourceUri;
    sourceRange ??= this.sourceRange;
    targetUri ??= this.targetUri;
    targetRange ??= this.targetRange;

    var documentCodeLenses = (await getCodeLens(sourceUri)) ?? [];
    var matchingCodeLenses = documentCodeLenses.where((codeLens) =>
        codeLens.command?.title == codeLensTitle &&
        codeLens.range.containsPosition(sourceRange!.start));

    if (matchingCodeLenses.isEmpty) {
      var debugText = documentCodeLenses
          .map((codeLens) => '  ${codeLens.command?.title} (${codeLens.range})')
          .join('\n');
      fail(
          'Did not find "$codeLensTitle" ($sourceRange) CodeLens in $sourceUri.\n'
          'Found:\n$debugText');
    } else if (matchingCodeLenses.length > 1) {
      var debugText = matchingCodeLenses
          .map((codeLens) => '  ${codeLens.command?.title} (${codeLens.range})')
          .join('\n');
      fail(
          'Found multiple "$codeLensTitle" ($sourceRange) CodeLens in $sourceUri.\n'
          'Found:\n$debugText');
    }

    var codeLens = matchingCodeLenses.single;
    expect(codeLens.range, sourceRange);

    // Verify the command/args match what's documented in the our LSP readme.
    // Clients will need to provide this command and will implement it as
    // documented.
    expect(codeLens.command!.command, ClientCommands.goToLocation);
    expect(
      codeLens.command?.arguments,
      [
        Location(
          uri: targetUri,
          range: targetRange,
        ).toJson() // Args are untyped, so toJson() to compare the Map.
      ],
    );
  }

  /// Expects no CodeLens in [uri]/[sourceUri] with the title [codeLensTitle].
  Future<void> expectNoCodeLenses([Uri? uri]) async {
    var documentCodeLenses = (await getCodeLens(uri ?? sourceUri)) ?? [];
    var matchingCodeLenses = documentCodeLenses
        .where((codeLens) => codeLens.command?.title == codeLensTitle);
    expect(matchingCodeLenses, isEmpty);
  }

  void setAugmentationContent(String content) {
    augmentationCode = TestCode.parse('''
augment library 'main.dart';

$content
''');
    newFile(mainFileAugmentationPath, augmentationCode.code);
  }

  void setLibraryContent(String content) {
    libraryCode = TestCode.parse('''
import augment 'main_augmentation.dart';

$content
''');
    newFile(mainFilePath, libraryCode.code);
  }

  @override
  void setUp() {
    super.setUp();

    setClientSupportedCommands([ClientCommands.goToLocation]);
  }

  test_available_class() async {
    setLibraryContent(r'''
class [!A!] {}
''');
    setAugmentationContent(r'''
augment class [!A!] {}
''');

    await initialize();
    await expectNavigationCodeLens();
  }

  test_available_class_getter() async {
    setLibraryContent(r'''
class A {
  String get [!g!] => '';
}
''');
    setAugmentationContent(r'''
augment class A {
  augment String get [!g!] => '';
}
''');

    await initialize();
    await expectNavigationCodeLens();
  }

  test_available_class_method() async {
    setLibraryContent(r'''
class A {
  void [!m!]() {}
}
''');
    setAugmentationContent(r'''
augment class A {
  augment void [!m!]() {}
}
''');

    await initialize();
    await expectNavigationCodeLens();
  }

  test_available_class_setter() async {
    setLibraryContent(r'''
class A {
  set [!g!](String value) {}
}
''');
    setAugmentationContent(r'''
augment class A {
  augment set [!g!](String value) {}
}
''');

    await initialize();
    await expectNavigationCodeLens();
  }

  test_available_enum() async {
    setLibraryContent(r'''
enum [!A!] {
  one,
}
''');
    setAugmentationContent(r'''
augment enum [!A!] {
  one,
}
''');

    await initialize();
    await expectNavigationCodeLens();
  }

  test_available_enum_member() async {
    setLibraryContent(r'''
enum A {
  [!one!],
}
''');
    setAugmentationContent(r'''
augment enum A {
  augment [!one!],
}
''');

    await initialize();
    await expectNavigationCodeLens();
  }

  test_available_topLevel_function() async {
    setLibraryContent(r'''
void [!f!]() {}
''');
    setAugmentationContent(r'''
augment void [!f!]() {}
''');

    await initialize();
    await expectNavigationCodeLens();
  }

  test_error_nonExistentFile() async {
    await initialize();

    await expectLater(
      expectNoCodeLenses(nonExistentFileUri),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath,
          message: 'File does not exist')),
    );
  }

  test_unavailable_disabledEntirely() async {
    useSimpleClassAugmentation();

    await provideConfig(initialize, {
      'codeLens': false,
    });
    await expectNoCodeLenses();
  }

  test_unavailable_disabledIndividually() async {
    useSimpleClassAugmentation();

    await provideConfig(initialize, {
      'codeLens': {codeLensSettingName: false},
    });
    await expectNoCodeLenses();
  }

  test_unavailable_noClientCommand() async {
    setClientSupportedCommands(null);

    useSimpleClassAugmentation();

    await initialize();
    await expectNoCodeLenses();
  }

  /// Sets up a simple class with augmentation that can be used by tests where
  /// the specifics are not important.
  void useSimpleClassAugmentation() {
    setLibraryContent(r'''
class A {}
''');
    setAugmentationContent(r'''
augment class A {}
''');
  }
}

/// Run all tests from [AbstractAugmentationCodeLensTest] looking for
/// "Go to Augmentation" that navigates from declarations in [mainFileUri] to
/// augmentations in [mainFileAugmentationUri].
@reflectiveTest
class AugmentationCodeLensTest extends AbstractAugmentationCodeLensTest {
  @override
  String get codeLensSettingName => 'augmentation';

  @override
  String get codeLensTitle => 'Go to Augmentation';

  @override
  Range get sourceRange => libraryCode.range.range;

  @override
  Uri get sourceUri => mainFileUri;

  @override
  Range get targetRange => augmentationCode.range.range;

  @override
  Uri get targetUri => mainFileAugmentationUri;

  test_available_class_augmentationOf_augmentationOf_declarationInAugmentationFile() async {
    setLibraryContent(r'');
    setAugmentationContent(r'''
class A {}
augment class /*[0*/A/*0]*/ {}
augment class /*[1*/A/*1]*/ {}
''');

    await initialize();
    await expectNavigationCodeLens(
      sourceUri: mainFileAugmentationUri,
      sourceRange: augmentationCode.ranges[0].range,
      targetUri: mainFileAugmentationUri,
      targetRange: augmentationCode.ranges[1].range,
    );
  }

  test_available_class_augmentationOf_augmentationOf_declarationInLibraryFile() async {
    setLibraryContent(r'''
class A {}
''');
    setAugmentationContent(r'''
augment class /*[0*/A/*0]*/ {}
augment class /*[1*/A/*1]*/ {}
''');

    await initialize();
    await expectNavigationCodeLens(
      sourceUri: mainFileAugmentationUri,
      sourceRange: augmentationCode.ranges[0].range,
      targetUri: mainFileAugmentationUri,
      targetRange: augmentationCode.ranges[1].range,
    );
  }

  test_available_class_augmentationOf_declarationInAugmentationFile() async {
    setLibraryContent('');
    setAugmentationContent(r'''
class /*[0*/A/*0]*/ {}
augment class /*[1*/A/*1]*/ {}
''');

    await initialize();
    await expectNavigationCodeLens(
      sourceUri: mainFileAugmentationUri,
      sourceRange: augmentationCode.ranges[0].range,
      targetUri: mainFileAugmentationUri,
      targetRange: augmentationCode.ranges[1].range,
    );
  }
}

/// Run all tests from [AbstractAugmentationCodeLensTest] looking for
/// "Go to Augmented" that navigates from augmentations in
/// [mainFileAugmentationUri] to the original declarations in
/// [mainFileAugmentationUri].
@reflectiveTest
class AugmentedCodeLensTest extends AbstractAugmentationCodeLensTest {
  @override
  String get codeLensSettingName => 'augmented';

  @override
  String get codeLensTitle => 'Go to Augmented';

  @override
  Range get sourceRange => augmentationCode.range.range;

  @override
  Uri get sourceUri => mainFileAugmentationUri;

  @override
  Range get targetRange => libraryCode.range.range;

  @override
  Uri get targetUri => mainFileUri;

  test_available_class_augmentationOf_augmentationOf_declarationInAugmentationFile() async {
    setLibraryContent(r'');
    setAugmentationContent(r'''
class A {}
augment class /*[0*/A/*0]*/ {}
augment class /*[1*/A/*1]*/ {}
''');

    await initialize();
    await expectNavigationCodeLens(
      sourceUri: mainFileAugmentationUri,
      sourceRange: augmentationCode.ranges[1].range,
      targetUri: mainFileAugmentationUri,
      targetRange: augmentationCode.ranges[0].range,
    );
  }

  test_available_class_augmentationOf_augmentationOf_declarationInLibraryFile() async {
    setLibraryContent(r'''
class A {}
''');
    setAugmentationContent(r'''
augment class /*[0*/A/*0]*/ {}
augment class /*[1*/A/*1]*/ {}
''');

    await initialize();
    await expectNavigationCodeLens(
      sourceUri: mainFileAugmentationUri,
      sourceRange: augmentationCode.ranges[1].range,
      targetUri: mainFileAugmentationUri,
      targetRange: augmentationCode.ranges[0].range,
    );
  }

  test_available_class_augmentationOf_declarationInAugmentationFile() async {
    setLibraryContent('');
    setAugmentationContent(r'''
class /*[0*/A/*0]*/ {}
augment class /*[1*/A/*1]*/ {}
''');

    await initialize();
    await expectNavigationCodeLens(
      sourceUri: mainFileAugmentationUri,
      sourceRange: augmentationCode.ranges[1].range,
      targetUri: mainFileAugmentationUri,
      targetRange: augmentationCode.ranges[0].range,
    );
  }
}
