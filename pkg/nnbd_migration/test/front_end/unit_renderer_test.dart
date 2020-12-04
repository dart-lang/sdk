// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/path_mapper.dart';
import 'package:nnbd_migration/src/front_end/unit_renderer.dart';
import 'package:nnbd_migration/src/front_end/web/file_details.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'nnbd_migration_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnitRendererTest);
  });
}

@reflectiveTest
class UnitRendererTest extends NnbdMigrationTestBase {
  /// Render [libraryInfo], using a [MigrationInfo] which knows only about this
  /// library.
  List<FileDetails> renderUnits() {
    var packageRoot = convertPath('/package');
    var migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, packageRoot);

    var contents = <FileDetails>[];
    for (var unitInfo in infos) {
      contents.add(UnitRenderer(unitInfo, migrationInfo,
              PathMapper(resourceProvider), 'AUTH_TOKEN')
          .render());
    }
    return contents;
  }

  void test_conditionFalseInStrongMode() async {
    await buildInfoForSingleTestFile('''
int f(String s) {
  if (s == null) {
    return 0;
  } else {
    return s.length;
  }
}
''', migratedContent: '''
int  f(String  s) {
  if (s == null /* == false */) {
    return 0;
  } else {
    return s.length;
  }
}
''', warnOnWeakCode: true);
    var output = renderUnits()[0];
    expect(
        _stripDataAttributes(output.regions),
        contains(
            '<span class="region informative-region">/* == false */</span>'));
    expect(output.edits.keys,
        contains('1 condition will be false in strong checking mode'));
  }

  void test_conditionTrueInStrongMode() async {
    await buildInfoForSingleTestFile('''
int f(String s) {
  if (s != null) {
    return s.length;
  } else {
    return 0;
  }
}
''', migratedContent: '''
int  f(String  s) {
  if (s != null /* == true */) {
    return s.length;
  } else {
    return 0;
  }
}
''', warnOnWeakCode: true);
    var output = renderUnits()[0];
    expect(
        _stripDataAttributes(output.regions),
        contains(
            '<span class="region informative-region">/* == true */</span>'));
    expect(output.edits.keys,
        contains('1 condition will be true in strong checking mode'));
  }

  Future<void> test_editList_containsCount() async {
    await buildInfoForSingleTestFile('''
int a = null;
bool b = a.isEven;
''', migratedContent: '''
int? a = null;
bool  b = a!.isEven;
''');
    var output = renderUnits()[0];
    var editList = output.edits;
    expect(editList, hasLength(2));
  }

  Future<void> test_editList_containsEdits() async {
    await buildInfoForSingleTestFile('''
int a = null;
bool b = a.isEven;
''', migratedContent: '''
int? a = null;
bool  b = a!.isEven;
''');
    var output = renderUnits()[0];
    // The null checks are higher priority than the assertions.
    expect(output.edits.keys,
        orderedEquals(['1 null check added', '1 type made nullable']));
    var typesMadeNullable = output.edits['1 type made nullable'];
    expect(typesMadeNullable, hasLength(1));
    var typeMadeNullable = typesMadeNullable.single;
    expect(typeMadeNullable.line, equals(1));
    expect(typeMadeNullable.offset, equals(3));
    expect(typeMadeNullable.explanation,
        equals("Changed type 'int' to be nullable"));
    var nullChecks = output.edits['1 null check added'];
    expect(nullChecks, hasLength(1));
    var nullCheck = nullChecks.single;
    expect(nullCheck.line, equals(2));
    expect(nullCheck.offset, equals(26));
    expect(nullCheck.explanation,
        equals('Added a non-null assertion to nullable expression'));
  }

  Future<void> test_editList_countsHintAcceptanceSingly() async {
    await buildInfoForSingleTestFile('int f(int/*?*/ x) => x/*!*/;',
        migratedContent: 'int  f(int/*?*/ x) => x/*!*/;');
    var output = renderUnits()[0];
    expect(
        output.edits.keys,
        unorderedEquals([
          '1 null check hint converted to null check',
          '1 nullability hint converted to ?'
        ]));
  }

  Future<void> test_editList_countsHintAcceptanceSingly_late() async {
    await buildInfoForSingleTestFile('/*late*/ int x = 0;',
        migratedContent: '/*late*/ int  x = 0;');
    var output = renderUnits()[0];
    expect(output.edits.keys,
        unorderedEquals(['1 late hint converted to late keyword']));
  }

  Future<void> test_editList_countsHintAcceptanceSingly_lateFinal() async {
    await buildInfoForSingleTestFile('/*late final*/ int x = 0;',
        migratedContent: '/*late final*/ int  x = 0;');
    var output = renderUnits()[0];
    expect(
        output.edits.keys,
        unorderedEquals(
            ['1 late final hint converted to late and final keywords']));
  }

  Future<void> test_editList_countsWhereOrNullSingly() async {
    await buildInfoForSingleTestFile(
        '''
import 'package:collection/collection.dart';

int firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
''',
        removeViaComments: false,
        migratedContent: '''
import 'package:collection/collection.dart';

int? firstEven(Iterable<int >  x)
    => x.firstWherefirstWhereOrNull((x) => x.isEven, orElse: () => null);
''');
    var output = renderUnits()[0];
    expect(output.edits.keys,
        unorderedEquals(['1 method name changed', '1 type made nullable']));
  }

  Future<void> test_editList_pluralHeader() async {
    await buildInfoForSingleTestFile('''
int a = null;
int b = null;
''', migratedContent: '''
int? a = null;
int? b = null;
''');
    var output = renderUnits()[0];
    expect(output.edits.keys.toList(), ['2 types made nullable']);
  }

  Future<void> test_handle_large_deleted_region_near_top_of_file() async {
    await buildInfoForSingleTestFile('''
class C {
  int hash(Iterable<int> elements) {
    if (elements == null) {
      return null.hashCode;
    }
    return 0;
  }
}

List<int> x = [null];
''', migratedContent: '''
class C {
  int  hash(Iterable<int >  elements) {
    if (elements == null) {
      return null.hashCode;
    }
    return 0;
  }
}

List<int?>  x = [null];
''', removeViaComments: false);
    renderUnits();
    // No assertions necessary; we are checking to make sure there is no crash.
  }

  Future<void> test_info_within_deleted_code() async {
    await buildInfoForSingleTestFile('''
class C {
  int hash(Iterable<int> elements) {
    if (elements == null) {
      return null.hashCode;
    }
    return 0;
  }
}

List<int> x = [null];
''', migratedContent: '''
class C {
  int  hash(Iterable<int >  elements) {
    if (elements == null) {
      return null.hashCode;
    }
    return 0;
  }
}

List<int?>  x = [null];
''', removeViaComments: false);
    var output = renderUnits()[0];
    // Strip out URLs and span IDs; they're not being tested here.
    var navContent = output.navigationContent
        .replaceAll(RegExp('href="[^"]*"'), 'href="..."')
        .replaceAll(RegExp('id="[^"]*"'), 'id="..."');
    expect(navContent, '''
class <span id="...">C</span> {
  <a href="..." class="nav-link">int</a>  <span id="...">hash</span>(<a href="..." class="nav-link">Iterable</a>&lt;<a href="..." class="nav-link">int</a> &gt;  <span id="...">elements</span>) {
    if (<a href="..." class="nav-link">elements</a> <a href="..." class="nav-link">==</a> null) {
      return null.<a href="..." class="nav-link">hashCode</a>;
    }
    return 0;
  }
}

<a href="..." class="nav-link">List</a>&lt;<a href="..." class="nav-link">int</a>?&gt;  <span id="...">x</span> = [null];
''');
  }

  Future<void> test_inserted_lines() async {
    await buildInfoForSingleTestFile('''
int f(List<int> values)
    => values.firstWhere((i) => i.isEven, orElse: () => null);
''', migratedContent: '''
import 'package:collection/collection.dart' show IterableExtension;

int? f(List<int >  values)
    => values.firstWherefirstWhereOrNull((i) => i.isEven/* , orElse: () => null */);
''');
    var output = renderUnits()[0];
    var regions = output.regions;
    // We're not testing the correctness of the data path, so drop it.
    regions = regions.replaceAll(RegExp(' data-path="[^"]*"'), '');
    // Split the output into table rows.
    var rows = regions.split(RegExp('(?=<tr)'));
    // The table should begin with an added region for the added import; since
    // adding the import involves adding 2 lines, the second and third lines
    // should have a line number of "(new)", and then lines should resume
    // counting at 2 after that.
    expect(rows[0], '<table><tbody>');
    expect(
        rows[1],
        '<tr><td class="line-no">1</td>'
        '<td class="line-1">'
        '<span class="region added-region" data-offset="0" data-line="1">'
        "import 'package:collection/collection.dart' show IterableExtension;"
        '</span></td></tr>');
    expect(rows[2], '<tr><td class="line-no">(new)</td><td></td></tr>');
    expect(rows[3], startsWith('<tr><td class="line-no">(new)</td><td>int'));
    expect(rows[4],
        startsWith('<tr><td class="line-no">2</td><td class="line-2">'));
  }

  void test_kindPriorityOrder() {
    var nonDisplayedKinds = NullabilityFixKind.values.toSet();
    for (var kind in UnitRenderer.kindPriorityOrder) {
      expect(nonDisplayedKinds.remove(kind), isTrue);
    }
    // The only kinds that should not be displayed are those associated with a
    // place where nothing interesting occurred.
    expect(nonDisplayedKinds, {
      NullabilityFixKind.typeNotMadeNullable,
      NullabilityFixKind.typeNotMadeNullableDueToHint
    });
  }

  Future<void> test_method_name_change() async {
    addPackageFile('collection', 'collection.dart', '');
    await buildInfoForSingleTestFile(
        '''
import 'package:collection/collection.dart';

int f(List<int> values)
    => values.firstWhere((i) => i.isEven, orElse: () => null);
''',
        removeViaComments: false,
        migratedContent: '''
import 'package:collection/collection.dart';

int? f(List<int >  values)
    => values.firstWherefirstWhereOrNull((i) => i.isEven, orElse: () => null);
''');
    var output = renderUnits()[0];
    var regions = output.regions;
    // We aren't testing data-offset or data-line behaviors.
    regions = regions.replaceAll(RegExp(' data-offset="[^"]*"'), '');
    regions = regions.replaceAll(RegExp(' data-line="[^"]*"'), '');
    expect(
        regions,
        contains('<span class="region removed-region">firstWhere</span>'
            '<span class="region added-region">firstWhereOrNull</span>('));
  }

  Future<void> test_navContentContainsEscapedHtml() async {
    await buildInfoForSingleTestFile('List<String> a = null;',
        migratedContent: 'List<String >? a = null;');
    var output = renderUnits()[0];
    // Strip out URLs which will change; not being tested here.
    var navContent =
        output.navigationContent.replaceAll(RegExp('href=".*?"'), 'href="..."');
    expect(
        navContent,
        contains(r'<a href="..." class="nav-link">List</a>'
            r'&lt;<a href="..." class="nav-link">String</a> &gt;? '
            r'<span id="o13">a</span> = null;'));
  }

  void test_nullAwarenessUnnecessaryInStrongMode() async {
    await buildInfoForSingleTestFile('''
int f(String s) => s?.length;
''', migratedContent: '''
int  f(String  s) => s?.length;
''', warnOnWeakCode: true);
    var output = renderUnits()[0];
    expect(_stripDataAttributes(output.regions),
        contains('s<span class="region informative-region">?</span>.length'));
    expect(
        output.edits.keys,
        contains(
            '1 null-aware access will be unnecessary in strong checking mode'));
  }

  Future<void> test_outputContains_addedType() async {
    await buildInfoForSingleTestFile('''
void f() {
  final a = <List<int>>[];
  a.add([null]);
}
''', migratedContent: '''
void f() {
  final List<List<int?>> a = <List<int > >[];
  a.add([null]);
}
''');
    var output = renderUnits()[0];
    var regions = _stripDataAttributes(output.regions);
    expect(
        regions,
        contains('final '
            '<span class="region added-region">List&lt;List&lt;int?&gt;&gt;</span>'
            ' a = &lt;List&lt;int'
            '<span class="region informative-region"> </span>'
            '&gt;'
            '<span class="region informative-region"> </span>'
            '&gt;[];'));
  }

  Future<void> test_outputContains_replacedVar() async {
    await buildInfoForSingleTestFile('''
void f() {
  var a = <List<int>>[];
  a.add([null]);
}
''', migratedContent: '''
void f() {
  varList<List<int?>> a = <List<int > >[];
  a.add([null]);
}
''');
    var output = renderUnits()[0];
    var regions = _stripDataAttributes(output.regions);
    expect(
        regions,
        contains('<span class="region removed-region">var</span>'
            '<span class="region added-region">List&lt;List&lt;int?&gt;&gt;</span>'
            ' a = &lt;List&lt;int'
            '<span class="region informative-region"> </span>'
            '&gt;'
            '<span class="region informative-region"> </span>'
            '&gt;[];'));
  }

  Future<void> test_outputContainsModifiedAndUnmodifiedRegions() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var output = renderUnits()[0];
    var regions = _stripDataAttributes(output.regions);
    expect(regions,
        contains('int<span class="region added-region">?</span> a = null;'));
  }

  Future<void> test_project_with_parts() async {
    // In this test, we migrate a library and its part file.  Both files require
    // addition of a `?`, but at different offsets.  We make sure the `?`s get
    // added at the correct locations in each file.
    var files = {
      convertPath('$projectPath/lib/a.dart'): '''
part 'b.dart';

int f() => null;
''',
      convertPath('$projectPath/lib/b.dart'): '''
part of 'a.dart';

int g() => null;
''',
    };
    await buildInfoForTestFiles(files, includedRoot: projectPath);
    var output = renderUnits();
    expect(output[0].sourceCode, contains('int?'));
    expect(output[1].sourceCode, contains('int?'));
  }

  Future<void> test_reference_to_sdk_file_with_parts() async {
    await buildInfoForSingleTestFile('''
import 'dart:async';
Future<int> f(Future<int> x) {
  return x.whenComplete(() {});
}
''', migratedContent: '''
import 'dart:async';
Future<int >  f(Future<int >  x) {
  return x.whenComplete(() {});
}
''');
    renderUnits();
    // No assertions; we're just making sure there's no crash.
  }

  Future<void> test_regionsContainsEscapedHtml_ampersand() async {
    await buildInfoForSingleTestFile('bool a = true && false;',
        migratedContent: 'bool  a = true && false;');
    var output = renderUnits()[0];
    expect(
        output.regions,
        contains('bool<span class="region informative-region" data-offset="4" '
            'data-line="1"> </span> a = true &amp;&amp; false;'));
  }

  Future<void> test_regionsContainsEscapedHtml_betweenRegions() async {
    await buildInfoForSingleTestFile('List<String> a = null;',
        migratedContent: 'List<String >? a = null;');
    var output = renderUnits()[0];
    var regions = _stripDataAttributes(output.regions);
    expect(
        regions,
        contains(
            'List&lt;String<span class="region informative-region"> </span>&gt;'
            '<span class="region added-region">?</span> a = null;'));
  }

  Future<void> test_regionsContainsEscapedHtml_region() async {
    await buildInfoForSingleTestFile('f(List<String> a) => a.join(",");',
        migratedContent: 'f(List<String >  a) => a.join(",");');
    var output = renderUnits()[0];
    var regions = _stripDataAttributes(output.regions);
    expect(
        regions,
        contains(
            'List&lt;String<span class="region informative-region"> </span>'
            '&gt;<span class="region informative-region"> </span>'));
  }

  UnitInfo unit(String path, String content, {List<RegionInfo> regions}) {
    return UnitInfo(convertPath(path))
      ..content = content
      ..regions.addAll(regions);
  }

  /// Strip out data attributes which are not being tested here.
  String _stripDataAttributes(String html) =>
      html.replaceAll(RegExp(' data-[^=]+="[^"]+"'), '');
}
