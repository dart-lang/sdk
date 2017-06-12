// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:front_end/src/base/library_info.dart';
import 'package:front_end/src/libraries_reader.dart';
import 'package:front_end/src/scanner/errors.dart';
import 'package:front_end/src/scanner/reader.dart';
import 'package:front_end/src/scanner/scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibrariesReaderTest);
  });
}

/// Generic URI resolver tests which do not depend on the particular path
/// context in use.
@reflectiveTest
class LibrariesReaderTest {
  test_categoriesClient() {
    var info =
        _computeSingleInfo('const LibraryInfo("", categories: "Client")');
    expect(info.categories, [Category.client]);
    expect(info.categoriesString, 'Client');
  }

  test_categoriesDefault() {
    var info = _computeSingleInfo('const LibraryInfo("")');
    expect(info.categories, isEmpty);
    expect(info.categoriesString, '');
  }

  test_categoriesMultiple() {
    var info = _computeSingleInfo(
        'const LibraryInfo("", categories: "Client,Server")');
    expect(
        info.categories, unorderedEquals([Category.client, Category.server]));
    expect(info.categoriesString, 'Client,Server');
  }

  test_categoriesNone() {
    var info = _computeSingleInfo('const LibraryInfo("", categories: "")');
    expect(info.categories, isEmpty);
    expect(info.categoriesString, '');
  }

  test_categoriesSingle() {
    var info =
        _computeSingleInfo('const LibraryInfo("", categories: "Client")');
    expect(info.categories, [Category.client]);
    expect(info.categoriesString, 'Client');
  }

  test_complex() {
    var info = _computeSingleInfo(
        '''
const LibraryInfo(
    "async/async.dart",
    categories: "Client,Server",
    maturity: Maturity.STABLE,
    dart2jsPatchPath: "_internal/js_runtime/lib/async_patch.dart"))
''',
        additionalDeclarations: '''
class Maturity {
  final int level;
  final String name;
  final String description;

  const Maturity(this.level, this.name, this.description);

  static const Maturity STABLE = const Maturity(4, "Stable", "Stable description");
}
''');
    expect(info.path, 'async/async.dart');
    expect(
        info.categories, unorderedEquals([Category.client, Category.server]));
    expect(info.maturity.name, 'Stable');
    expect(info.dart2jsPatchPath, '_internal/js_runtime/lib/async_patch.dart');
  }

  test_dart2jsPatchPathDefault() {
    var info = _computeSingleInfo('const LibraryInfo("")');
    expect(info.dart2jsPatchPath, null);
  }

  test_dart2jsPatchPathString() {
    var info = _computeSingleInfo('''
const LibraryInfo(
    "",
    dart2jsPatchPath: "_internal/js_runtime/lib/async_patch.dart")
''');
    expect(info.dart2jsPatchPath, '_internal/js_runtime/lib/async_patch.dart');
  }

  test_dart2jsPathDefault() {
    var info = _computeSingleInfo('const LibraryInfo("")');
    expect(info.dart2jsPath, null);
  }

  test_dart2jsPathString() {
    var info = _computeSingleInfo(
        'const LibraryInfo("", dart2jsPath: "html/dart2js/html_dart2js.dart"');
    expect(info.dart2jsPath, 'html/dart2js/html_dart2js.dart');
  }

  test_documentedDefault() {
    var info = _computeSingleInfo('const LibraryInfo("")');
    expect(info.documented, true);
  }

  test_documentedFalse() {
    var info = _computeSingleInfo('const LibraryInfo("", documented: false)');
    expect(info.documented, false);
  }

  test_documentedTrue() {
    var info = _computeSingleInfo('const LibraryInfo("", documented: true)');
    expect(info.documented, true);
  }

  test_implementationDefault() {
    var info = _computeSingleInfo('const LibraryInfo("")');
    expect(info.implementation, false);
  }

  test_implementationFalse() {
    var info =
        _computeSingleInfo('const LibraryInfo("", implementation: false)');
    expect(info.implementation, false);
  }

  test_implementationTrue() {
    var info =
        _computeSingleInfo('const LibraryInfo("", implementation: true)');
    expect(info.implementation, true);
  }

  test_maturityDefault() {
    var info = _computeSingleInfo('const LibraryInfo("")');
    expect(info.maturity, Maturity.UNSPECIFIED);
  }

  test_maturityStable() {
    var info =
        _computeSingleInfo('const LibraryInfo("", maturity: Maturity.FOO)',
            additionalDeclarations: '''
class Maturity {
  final int level;
  final String name;
  final String description;

  const Maturity(this.level, this.name, this.description);

  static const Maturity FOO = const Maturity(10, "Foo", "Foo description");
}
''');
    expect(info.maturity.level, 10);
    expect(info.maturity.name, 'Foo');
    expect(info.maturity.description, 'Foo description');
  }

  test_multipleLibraries() {
    var info = _computeLibraries('''
const Map<String, LibraryInfo> libraries = const {
  "async": const LibraryInfo("async/async.dart"),
  "core": const LibraryInfo("core/core.dart")
}
''');
    expect(info.keys, unorderedEquals(['async', 'core']));
    expect(info['async'].path, 'async/async.dart');
    expect(info['core'].path, 'core/core.dart');
  }

  test_path() {
    var info = _computeSingleInfo('const LibraryInfo("core/core.dart")');
    expect(info.path, 'core/core.dart');
  }

  test_platformsDefault() {
    var info = _computeSingleInfo('const LibraryInfo("")');
    expect(info.platforms, DART2JS_PLATFORM | VM_PLATFORM);
  }

  test_platformsMultiple() {
    var info = _computeSingleInfo(
        'const LibraryInfo("", platforms: VM_PLATFORM | DART2JS_PLATFORM)',
        additionalDeclarations: '''
const int DART2JS_PLATFORM = 1;
const int VM_PLATFORM = 2;
''');
    expect(info.platforms, 1 | 2);
  }

  test_platformsSingle() {
    var info =
        _computeSingleInfo('const LibraryInfo("", platforms: VM_PLATFORM)',
            additionalDeclarations: '''
const int VM_PLATFORM = 2;
''');
    expect(info.platforms, 2);
  }

  Map<String, LibraryInfo> _computeLibraries(String text,
      {String additionalDeclarations: ''}) {
    var fullText = '$text\n$additionalDeclarations';
    var scanner = new _Scanner(fullText);
    var token = scanner.tokenize();
    var parser = new Parser(null, AnalysisErrorListener.NULL_LISTENER);
    var compilationUnit = parser.parseCompilationUnit(token);
    var unlinkedUnit = serializeAstUnlinked(compilationUnit);
    return readLibraries(unlinkedUnit);
  }

  LibraryInfo _computeSingleInfo(String text,
      {String additionalDeclarations: ''}) {
    var libraries = _computeLibraries(
        'const Map<String, LibraryInfo> libraries = const { "x": $text };',
        additionalDeclarations: additionalDeclarations);
    return libraries['x'];
  }
}

class _Scanner extends Scanner {
  _Scanner(String contents) : super.create(new CharSequenceReader(contents)) {
    preserveComments = false;
  }

  @override
  void reportError(
      ScannerErrorCode errorCode, int offset, List<Object> arguments) {
    fail('Unexpected error($errorCode, $offset, $arguments)');
  }
}
