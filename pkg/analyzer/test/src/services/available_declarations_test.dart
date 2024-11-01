// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartdocInfoTest);
  });
}

class AbstractContextTest with ResourceProviderMixin {
  final byteStore = MemoryByteStore();

  late AnalysisContextCollection analysisContextCollection;

  late AnalysisContext testAnalysisContext;

  /// The file system specific `/home/test/analysis_options.yaml` path.
  String get analysisOptionsPath =>
      convertPath('/home/test/analysis_options.yaml');

  Folder get sdkRoot => newFolder('/sdk');

  /// Create all analysis contexts in `/home`.
  void createAnalysisContexts() {
    createAnalysisContexts0('/home', '/home/test');
  }

  void createAnalysisContexts0(String rootPath, String testPath) {
    analysisContextCollection = AnalysisContextCollectionImpl(
      includedPaths: [convertPath(rootPath)],
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );

    var testPath_ = convertPath(testPath);
    testAnalysisContext = getContext(testPath_);
  }

  /// Create an analysis options file based on the given arguments.
  void createAnalysisOptionsFile({List<String>? experiments}) {
    var buffer = StringBuffer();
    if (experiments != null) {
      buffer.writeln('analyzer:');
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }
    newFile(analysisOptionsPath, buffer.toString());

    createAnalysisContexts();
  }

  /// Return the existing analysis context that should be used to analyze the
  /// given [path], or throw [StateError] if the [path] is not analyzed in any
  /// of the created analysis contexts.
  AnalysisContext getContext(String path) {
    path = convertPath(path);
    return analysisContextCollection.contextFor(path);
  }

  setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    newFolder('/home/test');
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
    );

    createAnalysisContexts();
  }

  void writePackageConfig(
    String directoryPath,
    PackageConfigFileBuilder config,
  ) {
    newPackageConfigJsonFile(
      directoryPath,
      config.toContent(
        toUriStr: toUriStr,
      ),
    );
    createAnalysisContexts();
  }

  void writeTestPackageConfig(PackageConfigFileBuilder config) {
    config = config.copy();

    config.add(
      name: 'test',
      rootPath: '/home/test',
    );

    writePackageConfig('/home/test', config);
  }
}

@reflectiveTest
class DartdocInfoTest extends _Base {
  expectDocumentation(
      String templateDefinition, String macroReference, String expected) async {
    File file = newFile('/home/aaa/lib/definition.dart', templateDefinition);

    createAnalysisContexts();

    var context = analysisContextCollection.contextFor(file.path);

    tracker.addContext(context);
    await _doAllTrackerWork();

    var declarationsContext = tracker.getContext(context)!;
    var result = declarationsContext.dartdocDirectiveInfo.processDartdoc('''
/// Before macro.
/// $macroReference
/// After macro.''');
    expect(result.full, '''
Before macro.
$expected
After macro.''');
  }

  test_class() async {
    var definition = '''
/// {@template foo}
/// Body of the template.
/// {@endtemplate}
class A {}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_class_getter() async {
    var definition = '''
class A {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  String get f => '';
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_class_method() async {
    var definition = '''
class A {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  void f() {}
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_class_setter() async {
    var definition = '''
class A {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  set f(String value) {}
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_enum_constant() async {
    var definition = '''
enum E {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  one,
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_enum_member() async {
    var definition = '''
enum E {
  one;
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  void f() {}
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_extension() async {
    var definition = '''
class A {}

/// {@template foo}
/// Body of the template.
/// {@endtemplate}
extension on A {}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_extension_getter() async {
    var definition = '''
class A {}

extension on A {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  String get f => '';
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_extension_method() async {
    var definition = '''
class A {}

extension on A {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  void f() {}
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_extension_setter() async {
    var definition = '''
class A {}

extension on A {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  set f(String value) {}
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_extensionType() async {
    var definition = '''
/// {@template foo}
/// Body of the template.
/// {@endtemplate}
extension type IdNumber(int id) {}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_extensionType_getter() async {
    var definition = '''
extension type IdNumber(int id) {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  String get f => '';
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_extensionType_method() async {
    var definition = '''
extension type IdNumber(int id) {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  void f() {}
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_extensionType_setter() async {
    var definition = '''
extension type IdNumber(int id) {
  /// {@template foo}
  /// Body of the template.
  /// {@endtemplate}
  set f(String value) {}
}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_samePackage() async {
    var definition = '''
/// {@template foo}
/// Body of the template.
/// {@endtemplate}
class A {}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_topLevel_function() async {
    var definition = '''
/// {@template foo}
/// Body of the template.
/// {@endtemplate}
void f() {}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_topLevel_getter() async {
    var definition = '''
/// {@template foo}
/// Body of the template.
/// {@endtemplate}
String get f => '';
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_topLevel_setter() async {
    var definition = '''
/// {@template foo}
/// Body of the template.
/// {@endtemplate}
set f(String value) {}
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }

  test_topLevel_variable() async {
    var definition = '''
/// {@template foo}
/// Body of the template.
/// {@endtemplate}
var x = 0;
''';

    await expectDocumentation(
      definition,
      '{@macro foo}',
      'Body of the template.',
    );
  }
}

class _Base extends AbstractContextTest {
  late DeclarationsTracker tracker;

  @override
  setUp() {
    super.setUp();
    _createTracker();
  }

  void _createTracker() {
    tracker = DeclarationsTracker(byteStore, resourceProvider);
  }

  Future<void> _doAllTrackerWork() async {
    while (tracker.hasWork) {
      tracker.doWork();
    }
    await pumpEventQueue();
  }
}
