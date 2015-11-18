// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.contributor.dart.importuri;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/uri_contributor.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:path/path.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'completion_test_util.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(UriContributorTest);
  defineReflectiveTests(UriContributorWindowsTest);
}

@reflectiveTest
class UriContributorTest extends AbstractCompletionTest {
  @override
  void setUpContributor() {
    contributor = new UriContributor();
  }

  test_after_import() {
    addTestSource('import "p"^');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertNoSuggestions();
  }

  test_after_import_raw() {
    addTestSource('import r"p"^');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertNoSuggestions();
  }

  test_before_import() {
    addTestSource('import ^"p"');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertNoSuggestions();
  }

  test_before_import_raw() {
    addTestSource('import ^r"p"');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertNoSuggestions();
  }

  test_before_import_raw2() {
    addTestSource('import r^"p"');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertNoSuggestions();
  }

  test_export_package2() {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('export "package:foo/baz/^" import');
    computeFast();
    assertSuggest('package:foo/baz/too.dart',
        csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import() {
    addTestSource('import "^"');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import2() {
    addTestSource('import "^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_dart() {
    addTestSource('import "d^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 1);
    expect(request.replacementLength, 1);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('dart:core',
        csKind: CompletionSuggestionKind.IMPORT, relevance: DART_RELEVANCE_LOW);
    assertNotSuggested('dart:_internal');
    assertSuggest('dart:async', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('dart:math', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_dart2() {
    addTestSource('import "dart:async"; import "d^"');
    computeFast();
    expect(request.replacementOffset, completionOffset - 1);
    expect(request.replacementLength, 1);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('dart:core',
        csKind: CompletionSuggestionKind.IMPORT, relevance: DART_RELEVANCE_LOW);
    assertNotSuggested('dart:_internal');
    assertSuggest('dart:async', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('dart:math', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_file() {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('import "^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_import_file2() {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('import "..^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 2);
    expect(request.replacementLength, 2);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_import_file_child() {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('import "foo/^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 4);
    expect(request.replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertSuggest('foo/bar.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('../blat.dart');
  }

  test_import_file_parent() {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('import "../^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 3);
    expect(request.replacementLength, 3);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_file_parent2() {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('import "../b^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 4);
    expect(request.replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_package() {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('import "p^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 1);
    expect(request.replacementLength, 1);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:foo/foo.dart',
        csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:foo/baz/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('package:foo/baz/too.dart');
    assertSuggest('package:bar/', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:bar/bar.dart',
        csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_package2() {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('import "package:foo/baz/^" import');
    computeFast();
    assertSuggest('package:foo/baz/too.dart',
        csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_package2_raw() {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('import r"package:foo/baz/^" import');
    computeFast();
    assertSuggest('package:foo/baz/too.dart',
        csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_package_missing_lib() {
    var pkgSrc = addPackageSource('bar', 'bar.dart', 'library bar;');
    provider.deleteFolder(dirname(pkgSrc.fullName));
    addTestSource('import "p^" class');
    computeFast();
    expect(request.replacementOffset, completionOffset - 1);
    expect(request.replacementLength, 1);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:bar/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('package:bar/bar.dart');
  }

  test_import_package_raw() {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('import r"p^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 1);
    expect(request.replacementLength, 1);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:foo/foo.dart',
        csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:foo/baz/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('package:foo/baz/too.dart');
    assertSuggest('package:bar/', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:bar/bar.dart',
        csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_raw() {
    addTestSource('import r"^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_outside_import() {
    addTestSource('import ^"d" import');
    computeFast();
    computeFull((_) {
      assertNoSuggestions();
    });
  }

  test_outside_import2() {
    addTestSource('import "d"^ import');
    computeFast();
    computeFull((_) {
      assertNoSuggestions();
    });
  }

  test_part_file() {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('library x; part "^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_part_file2() {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('library x; part "..^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 2);
    expect(request.replacementLength, 2);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_part_file_child() {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('library x; part "foo/^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 4);
    expect(request.replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertSuggest('foo/bar.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('../blat.dart');
  }

  test_part_file_parent() {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('library x; part "../^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 3);
    expect(request.replacementLength, 3);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }
}

@reflectiveTest
class UriContributorWindowsTest extends AbstractCompletionTest {
  @override
  void setUpContributor() {
    contributor = new UriContributor();
  }

  @override
  void setupResourceProvider() {
    provider = new _TestWinResourceProvider();
  }

  test_import_file() {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_import_file2() {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "..^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 2);
    expect(request.replacementLength, 2);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_import_file_child() {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "foo/^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 4);
    expect(request.replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertSuggest('foo/bar.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('../blat.dart');
  }

  test_import_file_parent() {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "../^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 3);
    expect(request.replacementLength, 3);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_file_parent2() {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "../b^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 4);
    expect(request.replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_part_file() {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('library x; part "^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset);
    expect(request.replacementLength, 0);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_part_file2() {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('library x; part "..^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 2);
    expect(request.replacementLength, 2);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_part_file_child() {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('library x; part "foo/^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 4);
    expect(request.replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertSuggest('foo/bar.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('../blat.dart');
  }

  test_part_file_parent() {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('library x; part "../^" import');
    computeFast();
    expect(request.replacementOffset, completionOffset - 3);
    expect(request.replacementLength, 3);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }
}

class _TestWinResourceProvider extends MemoryResourceProvider {
  @override
  Context get pathContext => windows;
}
