// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/uri_contributor.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriContributorTest);
    defineReflectiveTests(UriContributorWindowsTest);
  });
}

@reflectiveTest
class UriContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new UriContributor();
  }

  test_after_import() async {
    addTestSource('import "p"^');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions();
  }

  test_after_import_raw() async {
    addTestSource('import r"p"^');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions();
  }

  test_before_import() async {
    addTestSource('import ^"p"');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions();
  }

  test_before_import_raw() async {
    addTestSource('import ^r"p"');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions();
  }

  test_before_import_raw2() async {
    addTestSource('import r^"p"');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions();
  }

  test_export_package2() async {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('export "package:foo/baz/^" import');
    await computeSuggestions();
    assertSuggest('package:foo/baz/too.dart',
        csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import() async {
    addTestSource('import "^"');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import2() async {
    addTestSource('import "^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import3() async {
    addTestSource('import "^ import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 7);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_dart() async {
    addTestSource('import "d^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('dart:core',
        csKind: CompletionSuggestionKind.IMPORT, relevance: DART_RELEVANCE_LOW);
    assertNotSuggested('dart:_internal');
    assertSuggest('dart:async', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('dart:math', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_dart2() async {
    addTestSource('import "dart:async"; import "d^"');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('dart:core',
        csKind: CompletionSuggestionKind.IMPORT, relevance: DART_RELEVANCE_LOW);
    assertNotSuggested('dart:_internal');
    assertSuggest('dart:async', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('dart:math', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_file() async {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('import "^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_import_file2() async {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('import "..^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_import_file_child() async {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('import "foo/^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 4);
    expect(replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertSuggest('foo/bar.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('../blat.dart');
  }

  test_import_file_outside_lib() async {
    testFile = '/proj/lib/completion.dart';
    addSource('/proj/lib/other.dart', 'library other;');
    addSource('/proj/lib/foo/bar.dart', 'library bar;');
    addSource('/proj/blat.dart', 'library blat;');
    addSource('/proj/bin/boo.dart', 'library boo;');
    addTestSource('import "../^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../bin');
    assertNotSuggested('../bin/');
    assertNotSuggested('../blat.dart');
  }

  test_import_file_parent() async {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addSource('/proj2/boo.dart', 'library boo;');
    addTestSource('import "../^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('../proj2/', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_file_parent2() async {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('import "../b^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 4);
    expect(replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_package() async {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('import "p^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
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

  test_import_package2() async {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('import "package:foo/baz/^" import');
    await computeSuggestions();
    assertSuggest('package:foo/baz/too.dart',
        csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_package2_raw() async {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('import r"package:foo/baz/^" import');
    await computeSuggestions();
    assertSuggest('package:foo/baz/too.dart',
        csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_package2_with_trailing() async {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('import "package:foo/baz/^.dart" import');
    await computeSuggestions();
    assertSuggest('package:foo/baz/too.dart',
        csKind: CompletionSuggestionKind.IMPORT);
    expect(replacementOffset, completionOffset - 16);
    expect(replacementLength, 5 + 16);
  }

  test_import_package_missing_lib() async {
    var pkgSrc = addPackageSource('bar', 'bar.dart', 'library bar;');
    provider.deleteFolder(dirname(pkgSrc.fullName));
    addTestSource('import "p^" class');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:bar/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('package:bar/bar.dart');
  }

  test_import_package_raw() async {
    addPackageSource('foo', 'foo.dart', 'library foo;');
    addPackageSource('foo', 'baz/too.dart', 'library too;');
    addPackageSource('bar', 'bar.dart', 'library bar;');
    addTestSource('import r"p^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
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

  test_import_raw() async {
    addTestSource('import r"^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_without_any_quotes() async {
    addTestSource('import ^ import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions();
  }

  test_import_without_any_quotes_eof() async {
    addTestSource('import ^');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions();
  }

  test_import_without_closing_quote_eof() async {
    addTestSource('import "^');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_without_closing_quote_eof2() async {
    addTestSource('import "^d');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 1);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_without_closing_quote_eof3() async {
    addTestSource('import "d^');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_without_closing_quote_eof4() async {
    addTestSource('import "d^"');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggest('dart:', csKind: CompletionSuggestionKind.IMPORT);
    assertSuggest('package:', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_outside_import() async {
    addTestSource('import ^"d" import');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_outside_import2() async {
    addTestSource('import "d"^ import');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_part_file() async {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('library x; part "^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_part_file2() async {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('library x; part "..^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_part_file_child() async {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('library x; part "foo/^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 4);
    expect(replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertSuggest('foo/bar.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('../blat.dart');
  }

  test_part_file_parent() async {
    testFile = '/proj/completion.dart';
    addSource('/proj/other.dart', 'library other;');
    addSource('/proj/foo/bar.dart', 'library bar;');
    addSource('/blat.dart', 'library blat;');
    addTestSource('library x; part "../^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }
}

@reflectiveTest
class UriContributorWindowsTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new UriContributor();
  }

  @override
  void setupResourceProvider() {
    provider = new _TestWinResourceProvider();
  }

  test_import_file() async {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_import_file2() async {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "..^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_import_file_child() async {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "foo/^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 4);
    expect(replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertSuggest('foo/bar.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('../blat.dart');
  }

  test_import_file_parent() async {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "../^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_import_file_parent2() async {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('import "../b^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 4);
    expect(replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertNotSuggested('foo/bar.dart');
    assertSuggest('../blat.dart', csKind: CompletionSuggestionKind.IMPORT);
  }

  test_part_file() async {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('library x; part "^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_part_file2() async {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('library x; part "..^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);
    assertNotSuggested('completion.dart');
    assertSuggest('other.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo');
    assertSuggest('foo/', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  test_part_file_child() async {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('library x; part "foo/^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 4);
    expect(replacementLength, 4);
    assertNotSuggested('completion.dart');
    assertNotSuggested('other.dart');
    assertNotSuggested('foo');
    assertNotSuggested('foo/');
    assertSuggest('foo/bar.dart', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('../blat.dart');
  }

  test_part_file_parent() async {
    testFile = '\\proj\\completion.dart';
    addSource('\\proj\\other.dart', 'library other;');
    addSource('\\proj\\foo\\bar.dart', 'library bar;');
    addSource('\\blat.dart', 'library blat;');
    addTestSource('library x; part "../^" import');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
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
