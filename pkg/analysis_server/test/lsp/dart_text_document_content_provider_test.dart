// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/test_macros.dart';
import 'package:analysis_server/src/utilities/client_uri_converter.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartTextDocumentContentProviderTest);
  });
}

@reflectiveTest
class DartTextDocumentContentProviderTest extends AbstractLspAnalysisServerTest
    with TestMacros {
  @override
  AnalysisServerOptions get serverOptions => AnalysisServerOptions()
    ..enabledExperiments = [
      ...super.serverOptions.enabledExperiments,
      EnableString.macros,
    ];

  @override
  void setUp() {
    super.setUp();
    setDartTextDocumentContentProviderSupport();
  }

  Future<void> test_invalid_badScheme() async {
    await initialize();

    await expectLater(
      getDartTextDocumentContent(Uri.parse('abcde:foo/bar.dart')),
      throwsA(
        isResponseError(
          ErrorCodes.InvalidParams,
          message: "Fetching content for scheme 'abcde' is not supported. "
              "Supported schemes are '$macroClientUriScheme'.",
        ),
      ),
    );
  }

  Future<void> test_invalid_fileScheme() async {
    await initialize();

    await expectLater(
      getDartTextDocumentContent(mainFileUri),
      throwsA(
        isResponseError(
          ErrorCodes.InvalidParams,
          message: "Fetching content for scheme 'file' is not supported. "
              "Supported schemes are '$macroClientUriScheme'.",
        ),
      ),
    );
  }

  Future<void> test_support_notSupported() async {
    setDartTextDocumentContentProviderSupport(false);
    await initialize();
    expect(
      experimentalServerCapabilities['dartTextDocumentContentProvider'],
      isNull,
    );
  }

  Future<void> test_supported_static() async {
    await initialize();
    expect(
      experimentalServerCapabilities['dartTextDocumentContentProvider'],
      {
        'schemes': [macroClientUriScheme],
      },
    );
  }

  Future<void> test_valid_content() async {
    writePackageConfig(projectFolderPath, temporaryMacroSupport: true);

    newFile(
        join(projectFolderPath, 'lib', 'with_foo.dart'), withFooMethodMacro);

    var content = '''
import 'with_foo.dart';

f() {
  A().foo();
}

@WithFoo()
class A {
  void bar() {}
}
''';

    await initialize();
    await Future.wait([
      openFile(mainFileUri, content),
      waitForAnalysisComplete(),
    ]);

    var macroGeneratedContent =
        await getDartTextDocumentContent(mainFileMacroUri);

    // Verify the contents appear correct without doing an exact string
    // check that might make this text fragile.
    expect(
      macroGeneratedContent!.content,
      allOf([
        contains('augment class A'),
        contains('void foo() {'),
      ]),
    );
  }

  Future<void> test_valid_eventAndModifiedContent() async {
    writePackageConfig(projectFolderPath, temporaryMacroSupport: true);

    var macroImplementationFilePath =
        join(projectFolderPath, 'lib', 'with_foo.dart');
    newFile(macroImplementationFilePath, withFooMethodMacro);

    var content = '''
import 'with_foo.dart';

f() {
  A().foo();
}

@WithFoo()
class A {
  void bar() {}
}
''';

    await initialize();
    await Future.wait([
      openFile(mainFileUri, content),
      waitForAnalysisComplete(),
    ]);

    // Verify initial contents of the macro.
    var macroGeneratedContent =
        await getDartTextDocumentContent(mainFileMacroUri);
    expect(macroGeneratedContent!.content, contains('void foo() {'));

    // Modify the macro and expect a change event.
    await Future.wait([
      dartTextDocumentContentDidChangeNotifications
          .firstWhere((notification) => notification.uri == mainFileMacroUri),
      // Replace the macro implementation to produce a `foo2()` method instead
      // of `foo()`.
      openFile(
        toUri(macroImplementationFilePath),
        withFooMethodMacro.replaceAll('void foo() {', 'void foo2() {'),
      )
    ]);

    // Verify updated contents of the macro.
    macroGeneratedContent = await getDartTextDocumentContent(mainFileMacroUri);
    expect(macroGeneratedContent!.content, contains('void foo2() {'));
  }
}
