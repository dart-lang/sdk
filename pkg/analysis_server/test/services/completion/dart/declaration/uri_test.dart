// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriTest);
  });
}

@reflectiveTest
class UriTest extends AbstractCompletionDriverTest with UriTestCases {}

mixin UriTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  @override
  Future<void> setUp() async {
    await super.setUp();
    allowedKinds = {CompletionSuggestionKind.IMPORT};
  }

  Future<void> test_after_import() async {
    await computeSuggestions('''
import "p"^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_after_import_raw() async {
    await computeSuggestions('''
import r"p"^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_before_import() async {
    await computeSuggestions('''
import ^"p"
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_before_import_raw() async {
    await computeSuggestions('''
import ^r"p"
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_before_import_raw2() async {
    await computeSuggestions('''
import r^"p"
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_export_package2() async {
    var fooRootPath = '$workspaceRootPath/foo';
    var barRootPath = '$workspaceRootPath/bar';
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: fooRootPath)
        ..add(name: 'bar', rootPath: barRootPath),
    );
    newFile('$fooRootPath/lib/foo.dart', '''
library foo;
''');
    newFile('$fooRootPath/lib/baz/too.dart', '''
library too;
''');
    newFile('$barRootPath/lib/bar.dart', '''
library bar;
''');
    await computeSuggestions('''
export "package:foo/baz/^" import
''');
    assertResponse(r'''
replacement
  left: 16
suggestions
  package:foo/baz/
    kind: import
  package:foo/baz/too.dart
    kind: import
''');
  }

  Future<void> test_import() async {
    await computeSuggestions('''
import "^"
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import2() async {
    await computeSuggestions('''
import "^" import
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import3() async {
    await computeSuggestions('''
import "^ import
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_configuration() async {
    await computeSuggestions('''
import "" if (dart.library.io) "^"
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_configuration_without_closing_quote_eof() async {
    await computeSuggestions('''
import "" if (dart.library.io) "^
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_configuration_without_closing_quote_eof2() async {
    await computeSuggestions('''
import "" if (dart.library.io) "^d
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_configuration_without_closing_quote_eof3() async {
    await computeSuggestions('''
import "" if (dart.library.io) "d^
''');
    // TODO(brianwilkerson): We should be suggesting `dart:` and `package:`. The
    //  test used to include those before being converted, but no longer does.
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_import_configuration_without_closing_quote_eof4() async {
    await computeSuggestions('''
import "" if (dart.library.io) "d^"
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_dart() async {
    await computeSuggestions('''
import "d^" import
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_dart2() async {
    await computeSuggestions('''
import "dart:async"; import "d^"
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_file() async {
    newFile('$testPackageRootPath/other.dart', '');
    newFile('$testPackageRootPath/foo/bar.dart', '');
    newFile('$workspaceRootPath/blat.dart', '');
    await computeSuggestions('''
import "^" import
''');
    // TODO(brianwilkerson): Before being converted, this test used to produce
    //  'other.dart' and 'foo/'.
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_file2() async {
    newFile('$testPackageRootPath/other.dart', '');
    newFile('$testPackageRootPath/foo/bar.dart', '');
    newFile('$workspaceRootPath/blat.dart', '');
    await computeSuggestions('''
import "..^" import
''');
    // TODO(brianwilkerson): Before being converted, this test used to produce
    //  'other.dart' and 'foo/'.
    assertResponse(r'''
replacement
  left: 2
suggestions
''');
  }

  Future<void> test_import_file_child() async {
    newFile('$testPackageRootPath/other.dart', '');
    newFile('$testPackageRootPath/foo/bar.dart', '');
    newFile('$workspaceRootPath/blat.dart', '');
    await computeSuggestions('''
import "foo/^" import
''');
    // TODO(brianwilkerson): Before being converted, this test used to produce
    //  'foo/bar.dart'.
    assertResponse(r'''
replacement
  left: 4
suggestions
''');
  }

  Future<void> test_import_file_outside_lib() async {
    newFile('$testPackageLibPath/other.dart', '''

''');
    newFile('$testPackageLibPath/foo/bar.dart', '''

''');
    newFile('$testPackageRootPath/blat.dart', '''

''');
    newFile('$testPackageRootPath/bin/boo.dart', '''

''');
    await computeSuggestions('''
import "../^" import
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
''');
  }

  Future<void> test_import_file_parent() async {
    newFile('$testPackageRootPath/other.dart', '');
    newFile('$testPackageRootPath/foo/bar.dart', '');
    newFile('$workspaceRootPath/blat.dart', '');
    newFile('$workspaceRootPath/aaa/boo.dart', '');
    await computeSuggestions('''
import "../^" import
''');
    // TODO(brianwilkerson): Before being converted this test used to produce
    //  '../blat.dart' and '../aaa/'.
    assertResponse(r'''
replacement
  left: 3
suggestions
''');
  }

  Future<void> test_import_file_parent2() async {
    newFile('$testPackageRootPath/other.dart', '');
    newFile('$testPackageRootPath/foo/bar.dart', '');
    newFile('$workspaceRootPath/blat.dart', '');
    await computeSuggestions('''
import "../b^" import
''');
    // TODO(brianwilkerson): Before being converted, this test used to produce
    //  '../blat.dart'.
    assertResponse(r'''
replacement
  left: 4
suggestions
''');
  }

  Future<void> test_import_no_dot_folders() async {
    newFolder('$testPackageRootPath/.foo');
    await computeSuggestions('''
import "package:^";
''');
    assertResponse(r'''
replacement
  left: 8
suggestions
  package:
    kind: import
  package:test/
    kind: import
''');
  }

  Future<void> test_import_only_dart_files() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '');
    newFile('$testPackageRootPath/other.dart', '');
    await computeSuggestions('''
import "package:^";
''');
    assertResponse(r'''
replacement
  left: 8
suggestions
  package:
    kind: import
  package:test/
    kind: import
''');
  }

  Future<void> test_import_package() async {
    var fooRootPath = '$workspaceRootPath/foo';
    var barRootPath = '$workspaceRootPath/bar';
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: fooRootPath)
        ..add(name: 'bar', rootPath: barRootPath),
    );
    newFile('$fooRootPath/lib/foo.dart', '''

''');
    newFile('$fooRootPath/lib/baz/too.dart', '''

''');
    newFile('$barRootPath/lib/bar.dart', '''

''');
    await computeSuggestions('''
import "p^" import
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  package:
    kind: import
  package:bar/
    kind: import
  package:foo/
    kind: import
  package:test/
    kind: import
''');
  }

  Future<void> test_import_package2() async {
    var fooRootPath = '$workspaceRootPath/foo';
    var barRootPath = '$workspaceRootPath/bar';
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: fooRootPath)
        ..add(name: 'bar', rootPath: barRootPath),
    );
    newFile('$fooRootPath/lib/foo.dart', '''

''');
    newFile('$fooRootPath/lib/baz/too.dart', '''

''');
    newFile('$barRootPath/lib/bar.dart', '''

''');
    await computeSuggestions('''
import "package:foo/baz/^" import
''');
    assertResponse(r'''
replacement
  left: 16
suggestions
  package:foo/baz/
    kind: import
  package:foo/baz/too.dart
    kind: import
''');
  }

  Future<void> test_import_package2_raw() async {
    var fooRootPath = '$workspaceRootPath/foo';
    var barRootPath = '$workspaceRootPath/bar';
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: fooRootPath)
        ..add(name: 'bar', rootPath: barRootPath),
    );
    newFile('$fooRootPath/lib/foo.dart', '''

''');
    newFile('$fooRootPath/lib/baz/too.dart', '''

''');
    newFile('$barRootPath/lib/bar.dart', '''

''');
    await computeSuggestions('''
import r"package:foo/baz/^" import
''');
    assertResponse(r'''
replacement
  left: 16
suggestions
  package:foo/baz/
    kind: import
  package:foo/baz/too.dart
    kind: import
''');
  }

  Future<void> test_import_package2_with_trailing() async {
    var fooRootPath = '$workspaceRootPath/foo';
    var barRootPath = '$workspaceRootPath/bar';
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: fooRootPath)
        ..add(name: 'bar', rootPath: barRootPath),
    );
    newFile('$fooRootPath/lib/foo.dart', '''

''');
    newFile('$fooRootPath/lib/baz/too.dart', '''

''');
    newFile('$barRootPath/lib/bar.dart', '''

''');
    await computeSuggestions('''
import "package:foo/baz/^.dart" import
''');
    assertResponse(r'''
replacement
  left: 16
  right: 5
suggestions
  package:foo/baz/
    kind: import
  package:foo/baz/too.dart
    kind: import
''');
  }

  Future<void> test_import_package_missing_lib() async {
    var barRootPath = '$workspaceRootPath/bar';
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'bar', rootPath: barRootPath),
    );
    await computeSuggestions('''
import "p^" class
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  package:
    kind: import
  package:bar/
    kind: import
  package:test/
    kind: import
''');
  }

  Future<void> test_import_package_raw() async {
    var fooRootPath = '$workspaceRootPath/foo';
    var barRootPath = '$workspaceRootPath/bar';
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: fooRootPath)
        ..add(name: 'bar', rootPath: barRootPath),
    );
    newFile('$fooRootPath/lib/foo.dart', '''

''');
    newFile('$fooRootPath/lib/baz/too.dart', '''

''');
    newFile('$barRootPath/lib/bar.dart', '''

''');
    await computeSuggestions('''
import r"p^" import
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  package:
    kind: import
  package:bar/
    kind: import
  package:foo/
    kind: import
  package:test/
    kind: import
''');
  }

  Future<void> test_import_raw() async {
    await computeSuggestions('''
import r"^" import
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_without_any_quotes() async {
    await computeSuggestions('''
import ^ import
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_import_without_any_quotes_eof() async {
    await computeSuggestions('''
import ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_import_without_closing_quote_eof() async {
    await computeSuggestions('''
import "^
''');
    assertResponse(r'''
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_without_closing_quote_eof2() async {
    await computeSuggestions('''
import "^d
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_import_without_closing_quote_eof3() async {
    await computeSuggestions('''
import "d^
''');
    // TODO(brianwilkerson): Before being converted, this test used to produce
    //  'dart:' and 'package:'.
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_import_without_closing_quote_eof4() async {
    await computeSuggestions('''
import "d^"
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:js
    kind: import
  dart:js_interop
    kind: import
  dart:math
    kind: import
  dart:typed_data
    kind: import
  dart:core
    kind: import
''');
  }

  Future<void> test_outside_import() async {
    await computeSuggestions('''
import ^"d" import
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_outside_import2() async {
    await computeSuggestions('''
import "d"^ import
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_part_file() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/foo/b.dart', '');
    await computeSuggestions('''
part '^'
''');
    assertResponse(r'''
suggestions
  a.dart
    kind: import
  foo/
    kind: import
''');
  }

  Future<void> test_part_file_child() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/foo/b.dart', '');
    await computeSuggestions('''
part 'foo/^'
''');
    assertResponse(r'''
replacement
  left: 4
suggestions
  foo/b.dart
    kind: import
''');
  }

  Future<void> test_part_file_parent() async {
    testFilePath = getFile('$testPackageLibPath/foo/test.dart').path;
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/bar/b.dart', '');
    await computeSuggestions('''
part '../^'
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  ../a.dart
    kind: import
  ../bar/
    kind: import
  ../foo/
    kind: import
''');
  }

  Future<void> test_partOf_file() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/foo/b.dart', '');
    await computeSuggestions('''
part of '^'
''');
    assertResponse(r'''
suggestions
  a.dart
    kind: import
  foo/
    kind: import
''');
  }
}
