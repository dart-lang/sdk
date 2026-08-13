// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart' hide SdkLibrariesReader;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartUriResolverTest);
    defineReflectiveTests(DiagnosticSeverityTest);
    defineReflectiveTests(ResolveRelativeUriTest);
  });
}

@reflectiveTest
class DartUriResolverTest extends _SimpleDartSdkTest {
  late final DartUriResolver resolver;

  @override
  setUp() {
    super.setUp();
    resolver = DartUriResolver(sdk);
  }

  void test_creation() {
    expect(DartUriResolver(sdk), isNotNull);
  }

  void test_isDartUri_null_scheme() {
    Uri uri = Uri.parse("foo.dart");
    expect('', uri.scheme);
    expect(DartUriResolver.isDartUri(uri), isFalse);
  }

  void test_pathToUri_library() {
    var path = convertPath('/sdk/lib/core/core.dart');
    var dartUri = resolver.pathToUri(path);
    expect(dartUri.toString(), 'dart:core');
  }

  void test_pathToUri_part() {
    var path = convertPath('/sdk/lib/core/int.dart');
    var dartUri = resolver.pathToUri(path);
    expect(dartUri.toString(), 'dart:core/int.dart');
  }

  void test_resolve_dart_library() {
    var source = resolver.resolveAbsolute(Uri.parse('dart:core'));
    expect(source, isNotNull);
  }

  void test_resolve_dart_nonExistingLibrary() {
    var result = resolver.resolveAbsolute(Uri.parse("dart:cor"));
    expect(result, isNull);
  }

  void test_resolve_dart_part() {
    var source = resolver.resolveAbsolute(Uri.parse('dart:core/int.dart'));
    expect(source, isNotNull);
  }

  void test_resolve_nonDart() {
    var result = resolver.resolveAbsolute(Uri.parse("package:some/file.dart"));
    expect(result, isNull);
  }
}

@reflectiveTest
class DiagnosticSeverityTest {
  test_max_error_error() async {
    expect(
      DiagnosticSeverity.ERROR.max(DiagnosticSeverity.ERROR),
      same(DiagnosticSeverity.ERROR),
    );
  }

  test_max_error_none() async {
    expect(
      DiagnosticSeverity.ERROR.max(DiagnosticSeverity.NONE),
      same(DiagnosticSeverity.ERROR),
    );
  }

  test_max_error_warning() async {
    expect(
      DiagnosticSeverity.ERROR.max(DiagnosticSeverity.WARNING),
      same(DiagnosticSeverity.ERROR),
    );
  }

  test_max_none_error() async {
    expect(
      DiagnosticSeverity.NONE.max(DiagnosticSeverity.ERROR),
      same(DiagnosticSeverity.ERROR),
    );
  }

  test_max_none_none() async {
    expect(
      DiagnosticSeverity.NONE.max(DiagnosticSeverity.NONE),
      same(DiagnosticSeverity.NONE),
    );
  }

  test_max_none_warning() async {
    expect(
      DiagnosticSeverity.NONE.max(DiagnosticSeverity.WARNING),
      same(DiagnosticSeverity.WARNING),
    );
  }

  test_max_warning_error() async {
    expect(
      DiagnosticSeverity.WARNING.max(DiagnosticSeverity.ERROR),
      same(DiagnosticSeverity.ERROR),
    );
  }

  test_max_warning_none() async {
    expect(
      DiagnosticSeverity.WARNING.max(DiagnosticSeverity.NONE),
      same(DiagnosticSeverity.WARNING),
    );
  }

  test_max_warning_warning() async {
    expect(
      DiagnosticSeverity.WARNING.max(DiagnosticSeverity.WARNING),
      same(DiagnosticSeverity.WARNING),
    );
  }
}

@reflectiveTest
class ResolveRelativeUriTest {
  test_resolveRelative_dart_dartUri() async {
    _assertResolve('dart:foo', 'dart:bar', 'dart:bar');
  }

  test_resolveRelative_dart_fileName() async {
    _assertResolve('dart:test', 'lib.dart', 'dart:test/lib.dart');
  }

  test_resolveRelative_dart_filePath() async {
    _assertResolve('dart:test', 'c/lib.dart', 'dart:test/c/lib.dart');
  }

  test_resolveRelative_dart_filePathWithParent() async {
    _assertResolve(
      'dart:test/b/test.dart',
      '../c/lib.dart',
      'dart:test/c/lib.dart',
    );
  }

  test_resolveRelative_package_dartUri() async {
    _assertResolve('package:foo/bar.dart', 'dart:test', 'dart:test');
  }

  test_resolveRelative_package_emptyPath() async {
    _assertResolve('package:foo/bar.dart', '', 'package:foo/bar.dart');
  }

  test_resolveRelative_package_fileName() async {
    _assertResolve('package:b/test.dart', 'lib.dart', 'package:b/lib.dart');
  }

  test_resolveRelative_package_fileNameWithoutPackageName() async {
    _assertResolve('package:test.dart', 'lib.dart', 'package:lib.dart');
  }

  test_resolveRelative_package_filePath() async {
    _assertResolve('package:b/test.dart', 'c/lib.dart', 'package:b/c/lib.dart');
  }

  test_resolveRelative_package_filePathWithParent() async {
    _assertResolve(
      'package:a/b/test.dart',
      '../c/lib.dart',
      'package:a/c/lib.dart',
    );
  }

  void _assertResolve(String baseStr, String containedStr, String expectedStr) {
    Uri base = Uri.parse(baseStr);
    Uri contained = Uri.parse(containedStr);
    Uri result = resolveRelativeUri(base, contained);
    expect(result, isNotNull);
    expect(result.toString(), expectedStr);
  }
}

class _SimpleDartSdkTest with ResourceProviderMixin {
  late final DartSdk sdk;

  void setUp() {
    newFile('/sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart', '''
const Map<String, LibraryInfo> libraries = const {
  "core": const LibraryInfo("core/core.dart")
};
''');

    newFile('/sdk/lib/core/core.dart', '''
library dart.core;
part 'int.dart';
''');

    newFile('/sdk/lib/core/int.dart', '''
part of dart.core;
''');

    Folder sdkFolder = newFolder('/sdk');
    sdk = FolderBasedDartSdk(resourceProvider, sdkFolder);
  }
}
