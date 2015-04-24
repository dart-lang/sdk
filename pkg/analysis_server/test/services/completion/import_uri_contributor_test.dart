// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.contributor.dart.importuri;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/import_uri_contributor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  defineReflectiveTests(ImportUriContributorTest);
}

@reflectiveTest
class ImportUriContributorTest extends AbstractCompletionTest {
  fail_import_file() {
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
    assertSuggest('foo', csKind: CompletionSuggestionKind.IMPORT);
    assertNotSuggested('foo/bar.dart');
    assertNotSuggested('../blat.dart');
  }

  @override
  void setUpContributor() {
    contributor = new ImportUriContributor();
  }

  test_import() {
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
    assertNotSuggested('dart:core');
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
    assertNotSuggested('dart:core');
    assertNotSuggested('dart:_internal');
    assertNotSuggested('dart:async');
    assertSuggest('dart:math', csKind: CompletionSuggestionKind.IMPORT);
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
}
