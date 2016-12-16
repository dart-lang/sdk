// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.contributor.dart.importuri;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/uri_contributor.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriContributorTest);
    defineReflectiveTests(UriContributorWindowsTest);
    defineReflectiveTests(UriContributorTest_Driver);
    defineReflectiveTests(UriContributorWindowsTest_Driver);
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
class UriContributorTest_Driver extends UriContributorTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  @override
  test_import_file() {
//    expected other.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file();
  }

  @failingTest
  @override
  test_import_file2() {
//    expected other.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file2();
  }

  @failingTest
  @override
  test_import_file_child() {
//    expected foo/bar.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file_child();
  }

  @failingTest
  @override
  test_import_file_parent() {
//    expected ../blat.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file_parent();
  }

  @failingTest
  @override
  test_import_file_parent2() {
//    expected ../blat.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file_parent2();
  }

  @failingTest
  @override
  test_part_file() {
//    NoSuchMethodError: The getter 'uri' was called on null.
//    Receiver: null
//    Tried calling: uri
//    dart:core                                                       Object.noSuchMethod
//    package:analyzer/src/summary/resynthesize.dart 233:40           SummaryResynthesizer.getLibraryElement.<fn>
//    dart:collection                                                 _HashVMBase&MapMixin&&_LinkedHashMapMixin.putIfAbsent
//    package:analyzer/src/summary/resynthesize.dart 209:36           SummaryResynthesizer.getLibraryElement
//    package:analyzer/src/summary/package_bundle_reader.dart 206:27  ResynthesizerResultProvider.compute
//    package:analyzer/src/context/context.dart 573:52                AnalysisContextImpl.aboutToComputeResult.<fn>
//    package:analyzer/src/generated/utilities_general.dart 189:15    _PerformanceTagImpl.makeCurrentWhile
//    package:analyzer/src/context/context.dart 571:42                AnalysisContextImpl.aboutToComputeResult
//    package:analyzer/src/task/driver.dart 746:21                    WorkItem.gatherInputs
//    package:analyzer/src/task/driver.dart 879:17                    _WorkOrderDependencyWalker.getNextInput
//    package:analyzer/src/task/driver.dart 414:35                    CycleAwareDependencyWalker.getNextStronglyConnectedComponent
//    package:analyzer/src/task/driver.dart 845:31                    WorkOrder.moveNext.<fn>
//    package:analyzer/src/generated/utilities_general.dart 189:15    _PerformanceTagImpl.makeCurrentWhile
//    package:analyzer/src/task/driver.dart 837:44                    WorkOrder.moveNext
//    package:analyzer/src/task/driver.dart 108:30                    AnalysisDriver.computeResult
//    package:analyzer/src/context/context.dart 723:14                AnalysisContextImpl.computeResult
//    package:analyzer/src/context/context.dart 1292:12               AnalysisContextImpl.resolveCompilationUnit2
//    package:analyzer/src/dart/analysis/driver.dart 656:56           AnalysisDriver._computeAnalysisResult.<fn>
//    package:analyzer/src/dart/analysis/driver.dart 1427:15          PerformanceLog.run
//    package:analyzer/src/dart/analysis/driver.dart 643:20           AnalysisDriver._computeAnalysisResult
//    package:analyzer/src/dart/analysis/driver.dart 910:33           AnalysisDriver._performWork.<async>
    return super.test_part_file();
  }

  @failingTest
  @override
  test_part_file2() {
//    Task failed: BuildCompilationUnitElementTask for source /
//    Unexpected exception while performing BuildCompilationUnitElementTask for source /
//    #0      AnalysisTask._safelyPerform (package:analyzer/task/model.dart:333:7)
//    #1      AnalysisTask.perform (package:analyzer/task/model.dart:220:7)
//    #2      AnalysisDriver.performWorkItem (package:analyzer/src/task/driver.dart:284:10)
//    #3      AnalysisDriver.computeResult (package:analyzer/src/task/driver.dart:109:22)
//    #4      AnalysisContextImpl.computeResult (package:analyzer/src/context/context.dart:723:14)
//    #5      AnalysisContextImpl.computeErrors (package:analyzer/src/context/context.dart:665:12)
//    #6      AnalysisDriver._computeAnalysisResult.<anonymous closure> (package:analyzer/src/dart/analysis/driver.dart:658:54)
//    #7      PerformanceLog.run (package:analyzer/src/dart/analysis/driver.dart:1427:15)
//    #8      AnalysisDriver._computeAnalysisResult (package:analyzer/src/dart/analysis/driver.dart:643:20)
//    #9      AnalysisDriver._performWork.<_performWork_async_body> (package:analyzer/src/dart/analysis/driver.dart:910:33)
//    #10     Future.Future.microtask.<anonymous closure> (dart:async/future.dart:184)
//    #11     _rootRun (dart:async/zone.dart:1146)
//    #12     _CustomZone.run (dart:async/zone.dart:1026)
//    #13     _CustomZone.runGuarded (dart:async/zone.dart:924)
//    #14     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:951)
//    #15     _rootRun (dart:async/zone.dart:1150)
//    #16     _CustomZone.run (dart:async/zone.dart:1026)
//    #17     _CustomZone.runGuarded (dart:async/zone.dart:924)
//    #18     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:951)
//    #19     _microtaskLoop (dart:async/schedule_microtask.dart:41)
//    #20     _startMicrotaskLoop (dart:async/schedule_microtask.dart:50)
//    #21     _Timer._runTimers (dart:isolate-patch/timer_impl.dart:394)
//    #22     _Timer._handleMessage (dart:isolate-patch/timer_impl.dart:414)
//    #23     _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:148)
//
//    Caused by Exception: Unit element not found in summary: file:///proj/completion.dart;file:///
//    #0      SummaryResynthesizer.getElement (package:analyzer/src/summary/resynthesize.dart:124:9)
//    #1      ResynthesizerResultProvider.compute (package:analyzer/src/summary/package_bundle_reader.dart:265:53)
//    #2      AnalysisContextImpl.aboutToComputeResult.<anonymous closure> (package:analyzer/src/context/context.dart:573:52)
//    #3      _PerformanceTagImpl.makeCurrentWhile (package:analyzer/src/generated/utilities_general.dart:189:15)
//    #4      AnalysisContextImpl.aboutToComputeResult (package:analyzer/src/context/context.dart:571:42)
//    #5      BuildCompilationUnitElementTask.internalPerform (package:analyzer/src/task/dart.dart:1071:27)
//    #6      AnalysisTask._safelyPerform (package:analyzer/task/model.dart:321:9)
//    #7      AnalysisTask.perform (package:analyzer/task/model.dart:220:7)
//    #8      AnalysisDriver.performWorkItem (package:analyzer/src/task/driver.dart:284:10)
//    #9      AnalysisDriver.computeResult (package:analyzer/src/task/driver.dart:109:22)
//    #10     AnalysisContextImpl.computeResult (package:analyzer/src/context/context.dart:723:14)
//    #11     AnalysisContextImpl.computeErrors (package:analyzer/src/context/context.dart:665:12)
//    #12     AnalysisDriver._computeAnalysisResult.<anonymous closure> (package:analyzer/src/dart/analysis/driver.dart:658:54)
//    #13     PerformanceLog.run (package:analyzer/src/dart/analysis/driver.dart:1427:15)
//    #14     AnalysisDriver._computeAnalysisResult (package:analyzer/src/dart/analysis/driver.dart:643:20)
//    #15     AnalysisDriver._performWork.<_performWork_async_body> (package:analyzer/src/dart/analysis/driver.dart:910:33)
//    #16     Future.Future.microtask.<anonymous closure> (dart:async/future.dart:184)
//    #17     _rootRun (dart:async/zone.dart:1146)
//    #18     _CustomZone.run (dart:async/zone.dart:1026)
//    #19     _CustomZone.runGuarded (dart:async/zone.dart:924)
//    #20     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:951)
//    #21     _rootRun (dart:async/zone.dart:1150)
//    #22     _CustomZone.run (dart:async/zone.dart:1026)
//    #23     _CustomZone.runGuarded (dart:async/zone.dart:924)
//    #24     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:951)
//    #25     _microtaskLoop (dart:async/schedule_microtask.dart:41)
//    #26     _startMicrotaskLoop (dart:async/schedule_microtask.dart:50)
//    #27     _Timer._runTimers (dart:isolate-patch/timer_impl.dart:394)
//    #28     _Timer._handleMessage (dart:isolate-patch/timer_impl.dart:414)
//    #29     _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:148)
//    return super.test_part_file2();
    fail('Throws background exception.');
  }

  @failingTest
  @override
  test_part_file_child() {
//    expected foo/bar.dart CompletionSuggestionKind.IMPORT null
//    found
    return super.test_part_file_child();
  }

  @failingTest
  @override
  test_part_file_parent() {
//    expected foo/bar.dart CompletionSuggestionKind.IMPORT null
//    found
    return super.test_part_file_parent();
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

@reflectiveTest
class UriContributorWindowsTest_Driver extends UriContributorWindowsTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  @override
  test_import_file() {
//    expected other.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file();
  }

  @failingTest
  @override
  test_import_file2() {
//    expected other.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file2();
  }

  @failingTest
  @override
  test_import_file_child() {
//    expected foo/bar.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file_child();
  }

  @failingTest
  @override
  test_import_file_parent() {
//    expected ../blat.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file_parent();
  }

  @failingTest
  @override
  test_import_file_parent2() {
//    expected ../blat.dart CompletionSuggestionKind.IMPORT null
//    found
//    dart: -> {"kind":"IMPORT","relevance":1000,"completion":"dart:","selectionOffset":5,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:async -> {"kind":"IMPORT","relevance":1000,"completion":"dart:async","selectionOffset":10,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:collection -> {"kind":"IMPORT","relevance":1000,"completion":"dart:collection","selectionOffset":15,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:convert -> {"kind":"IMPORT","relevance":1000,"completion":"dart:convert","selectionOffset":12,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:core -> {"kind":"IMPORT","relevance":500,"completion":"dart:core","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:html -> {"kind":"IMPORT","relevance":1000,"completion":"dart:html","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    dart:math -> {"kind":"IMPORT","relevance":1000,"completion":"dart:math","selectionOffset":9,"selectionLength":0,"isDeprecated":false,"isPotential":false}
//    package: -> {"kind":"IMPORT","relevance":1000,"completion":"package:","selectionOffset":8,"selectionLength":0,"isDeprecated":false,"isPotential":false}
    return super.test_import_file_parent2();
  }

  @failingTest
  @override
  test_part_file() {
//    NoSuchMethodError: The getter 'uri' was called on null.
//    Receiver: null
//    Tried calling: uri
//    dart:core                                                       Object.noSuchMethod
//    package:analyzer/src/summary/resynthesize.dart 233:40           SummaryResynthesizer.getLibraryElement.<fn>
//    dart:collection                                                 _HashVMBase&MapMixin&&_LinkedHashMapMixin.putIfAbsent
//    package:analyzer/src/summary/resynthesize.dart 209:36           SummaryResynthesizer.getLibraryElement
//    package:analyzer/src/summary/package_bundle_reader.dart 206:27  ResynthesizerResultProvider.compute
//    package:analyzer/src/context/context.dart 573:52                AnalysisContextImpl.aboutToComputeResult.<fn>
//    package:analyzer/src/generated/utilities_general.dart 189:15    _PerformanceTagImpl.makeCurrentWhile
//    package:analyzer/src/context/context.dart 571:42                AnalysisContextImpl.aboutToComputeResult
//    package:analyzer/src/task/driver.dart 746:21                    WorkItem.gatherInputs
//    package:analyzer/src/task/driver.dart 879:17                    _WorkOrderDependencyWalker.getNextInput
//    package:analyzer/src/task/driver.dart 414:35                    CycleAwareDependencyWalker.getNextStronglyConnectedComponent
//    package:analyzer/src/task/driver.dart 845:31                    WorkOrder.moveNext.<fn>
//    package:analyzer/src/generated/utilities_general.dart 189:15    _PerformanceTagImpl.makeCurrentWhile
//    package:analyzer/src/task/driver.dart 837:44                    WorkOrder.moveNext
//    package:analyzer/src/task/driver.dart 108:30                    AnalysisDriver.computeResult
//    package:analyzer/src/context/context.dart 723:14                AnalysisContextImpl.computeResult
//    package:analyzer/src/context/context.dart 1292:12               AnalysisContextImpl.resolveCompilationUnit2
//    package:analyzer/src/dart/analysis/driver.dart 656:56           AnalysisDriver._computeAnalysisResult.<fn>
//    package:analyzer/src/dart/analysis/driver.dart 1427:15          PerformanceLog.run
//    package:analyzer/src/dart/analysis/driver.dart 643:20           AnalysisDriver._computeAnalysisResult
//    package:analyzer/src/dart/analysis/driver.dart 910:33           AnalysisDriver._performWork.<async>
    return super.test_part_file();
  }

  @failingTest
  @override
  test_part_file2() {
//    Task failed: BuildCompilationUnitElementTask for source /
//    Unexpected exception while performing BuildCompilationUnitElementTask for source /
//    #0      AnalysisTask._safelyPerform (package:analyzer/task/model.dart:333:7)
//    #1      AnalysisTask.perform (package:analyzer/task/model.dart:220:7)
//    #2      AnalysisDriver.performWorkItem (package:analyzer/src/task/driver.dart:284:10)
//    #3      AnalysisDriver.computeResult (package:analyzer/src/task/driver.dart:109:22)
//    #4      AnalysisContextImpl.computeResult (package:analyzer/src/context/context.dart:723:14)
//    #5      AnalysisContextImpl.computeErrors (package:analyzer/src/context/context.dart:665:12)
//    #6      AnalysisDriver._computeAnalysisResult.<anonymous closure> (package:analyzer/src/dart/analysis/driver.dart:658:54)
//    #7      PerformanceLog.run (package:analyzer/src/dart/analysis/driver.dart:1427:15)
//    #8      AnalysisDriver._computeAnalysisResult (package:analyzer/src/dart/analysis/driver.dart:643:20)
//    #9      AnalysisDriver._performWork.<_performWork_async_body> (package:analyzer/src/dart/analysis/driver.dart:910:33)
//    #10     Future.Future.microtask.<anonymous closure> (dart:async/future.dart:184)
//    #11     _rootRun (dart:async/zone.dart:1146)
//    #12     _CustomZone.run (dart:async/zone.dart:1026)
//    #13     _CustomZone.runGuarded (dart:async/zone.dart:924)
//    #14     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:951)
//    #15     _rootRun (dart:async/zone.dart:1150)
//    #16     _CustomZone.run (dart:async/zone.dart:1026)
//    #17     _CustomZone.runGuarded (dart:async/zone.dart:924)
//    #18     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:951)
//    #19     _microtaskLoop (dart:async/schedule_microtask.dart:41)
//    #20     _startMicrotaskLoop (dart:async/schedule_microtask.dart:50)
//    #21     _Timer._runTimers (dart:isolate-patch/timer_impl.dart:394)
//    #22     _Timer._handleMessage (dart:isolate-patch/timer_impl.dart:414)
//    #23     _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:148)
//
//    Caused by Exception: Unit element not found in summary: file:///proj/completion.dart;file:///
//    #0      SummaryResynthesizer.getElement (package:analyzer/src/summary/resynthesize.dart:124:9)
//    #1      ResynthesizerResultProvider.compute (package:analyzer/src/summary/package_bundle_reader.dart:265:53)
//    #2      AnalysisContextImpl.aboutToComputeResult.<anonymous closure> (package:analyzer/src/context/context.dart:573:52)
//    #3      _PerformanceTagImpl.makeCurrentWhile (package:analyzer/src/generated/utilities_general.dart:189:15)
//    #4      AnalysisContextImpl.aboutToComputeResult (package:analyzer/src/context/context.dart:571:42)
//    #5      BuildCompilationUnitElementTask.internalPerform (package:analyzer/src/task/dart.dart:1071:27)
//    #6      AnalysisTask._safelyPerform (package:analyzer/task/model.dart:321:9)
//    #7      AnalysisTask.perform (package:analyzer/task/model.dart:220:7)
//    #8      AnalysisDriver.performWorkItem (package:analyzer/src/task/driver.dart:284:10)
//    #9      AnalysisDriver.computeResult (package:analyzer/src/task/driver.dart:109:22)
//    #10     AnalysisContextImpl.computeResult (package:analyzer/src/context/context.dart:723:14)
//    #11     AnalysisContextImpl.computeErrors (package:analyzer/src/context/context.dart:665:12)
//    #12     AnalysisDriver._computeAnalysisResult.<anonymous closure> (package:analyzer/src/dart/analysis/driver.dart:658:54)
//    #13     PerformanceLog.run (package:analyzer/src/dart/analysis/driver.dart:1427:15)
//    #14     AnalysisDriver._computeAnalysisResult (package:analyzer/src/dart/analysis/driver.dart:643:20)
//    #15     AnalysisDriver._performWork.<_performWork_async_body> (package:analyzer/src/dart/analysis/driver.dart:910:33)
//    #16     Future.Future.microtask.<anonymous closure> (dart:async/future.dart:184)
//    #17     _rootRun (dart:async/zone.dart:1146)
//    #18     _CustomZone.run (dart:async/zone.dart:1026)
//    #19     _CustomZone.runGuarded (dart:async/zone.dart:924)
//    #20     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:951)
//    #21     _rootRun (dart:async/zone.dart:1150)
//    #22     _CustomZone.run (dart:async/zone.dart:1026)
//    #23     _CustomZone.runGuarded (dart:async/zone.dart:924)
//    #24     _CustomZone.bindCallback.<anonymous closure> (dart:async/zone.dart:951)
//    #25     _microtaskLoop (dart:async/schedule_microtask.dart:41)
//    #26     _startMicrotaskLoop (dart:async/schedule_microtask.dart:50)
//    #27     _Timer._runTimers (dart:isolate-patch/timer_impl.dart:394)
//    #28     _Timer._handleMessage (dart:isolate-patch/timer_impl.dart:414)
//    #29     _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:148)
//    return super.test_part_file2();
    fail('Throws background exception.');
  }

  @failingTest
  @override
  test_part_file_child() {
//    expected foo/bar.dart CompletionSuggestionKind.IMPORT null
//    found
    return super.test_part_file_child();
  }

  @failingTest
  @override
  test_part_file_parent() {
//    expected foo/bar.dart CompletionSuggestionKind.IMPORT null
//    found
    return super.test_part_file_parent();
  }
}

class _TestWinResourceProvider extends MemoryResourceProvider {
  @override
  Context get pathContext => windows;
}
