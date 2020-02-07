// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/navigation_tree_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'nnbd_migration_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(JsonMapTypeMatcherTest);
    defineReflectiveTests(NavigationTreeRendererTest);
  });
}

const isJsonMap = TypeMatcher<Map<String, dynamic>>();

@reflectiveTest
class JsonMapTypeMatcherTest {
  void test_containing_doesNotMatch_invalidMatchers() {
    expect(
        isJsonMap.containing({'a': isJsonMap}).matches({
          'a': [1, 2, 3]
        }, {}),
        isFalse);
  }

  void test_containing_doesNotMatch_invalidMatchers_list() {
    expect(
        isJsonMap.containing({
          'a': isJsonMap.containing({
            'b': [1, 2, 3]
          })
        }).matches({
          'a': {
            'b': [1, 2, 3, 4]
          }
        }, {}),
        isFalse);
  }

  void test_containing_doesNotMatch_invalidValues() {
    expect(isJsonMap.containing({'a': 1}).matches({'a': 2}, {}), isFalse);
  }

  void test_containing_matches_validMatchers() {
    expect(
        isJsonMap.containing({'a': isJsonMap}).matches(
            {'a': <String, dynamic>{}}, {}),
        isTrue);
  }

  void test_containing_matches_validMatchers_list() {
    expect(
        isJsonMap.containing({
          'a': isJsonMap.containing({
            'b': [1, 2, 3]
          })
        }).matches({
          'a': {
            'b': [1, 2, 3]
          }
        }, {}),
        isTrue);
  }

  void test_containing_matches_validValues() {
    expect(isJsonMap.containing({'a': 1}).matches({'a': 1}, {}), isTrue);
  }

  void test_isJsonMap_doesNotMatch_nonMaps() {
    expect(isJsonMap.matches([], {}), isFalse);
  }

  void test_isJsonMap_doesNotMatch_nonStringKeyedMaps() {
    expect(isJsonMap.matches(<int, int>{}, {}), isFalse);
  }

  void test_isJsonMap_matchesStringKeyedMaps() {
    expect(isJsonMap.matches(<String, dynamic>{}, {}), isTrue);
  }
}

@reflectiveTest
class NavigationTreeRendererTest extends NnbdMigrationTestBase {
  /// Render the navigation tree view for [files].
  Future<String> renderNavigationTree(Map<String, String> files) async {
    var packageRoot = convertPath('/project');
    await buildInfoForTestFiles(files, includedRoot: packageRoot);
    MigrationInfo migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, packageRoot);
    return NavigationTreeRenderer(migrationInfo, PathMapper(resourceProvider))
        .render();
  }

  Future<void> test_containsEditCounts() async {
    var response = jsonDecode(await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = 1;',
      convertPath('/project/lib/b.dart'): 'int b = null;',
      convertPath('/project/lib/c.dart'): 'int c = null;\nint d = null;',
    }));

    var libNode = response[0];
    expect(
        libNode,
        isJsonMap.containing({
          'subtree': [
            isJsonMap.containing({'editCount': 0}),
            isJsonMap.containing({'editCount': 1}),
            isJsonMap.containing({'editCount': 2})
          ]
        }));
  }

  Future<void> test_containsHrefs() async {
    var response = jsonDecode(await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/src/b.dart'): 'int b = null;',
      convertPath('/project/tool.dart'): 'int c = null;',
    }));

    var libNode = response[0];
    expect(
        libNode,
        isJsonMap.containing({
          'name': 'lib',
          'subtree': [
            isJsonMap.containing({
              'name': 'src',
              'subtree': [
                isJsonMap.containing({'href': '/project/lib/src/b.dart'})
              ]
            }),
            isJsonMap.containing({'href': '/project/lib/a.dart'})
          ]
        }));

    var toolNode = response[1];
    expect(toolNode['href'], '/project/tool.dart');
  }

  Future<void> test_containsMultipleLinks_multipleDepths() async {
    var response = jsonDecode(await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/src/b.dart'): 'int b = null;',
      convertPath('/project/tool.dart'): 'int c = null;',
    }));
    expect(response, hasLength(2));

    var libNode = response[0];
    expect(
        libNode,
        isJsonMap.containing({
          'name': 'lib',
          'subtree': [
            isJsonMap.containing({
              'name': 'src',
              'subtree': [
                isJsonMap.containing({'name': 'b.dart'})
              ]
            }),
            isJsonMap.containing({'name': 'a.dart'})
          ]
        }));

    var toolNode = response[1];
    expect(toolNode['name'], 'tool.dart');
  }

  Future<void> test_containsMultipleLinks_multipleRoots() async {
    var response = jsonDecode(await renderNavigationTree({
      convertPath('/project/bin/bin.dart'): 'int c = null;',
      convertPath('/project/lib/a.dart'): 'int a = null;',
    }));
    expect(response, hasLength(2));

    var binNode = response[0];
    expect(binNode['type'], equals('directory'));
    expect(binNode['name'], equals('bin'));
    expect(binNode['subtree'], hasLength(1));

    var libNode = response[1];
    expect(libNode['type'], equals('directory'));
    expect(libNode['name'], equals('lib'));
    expect(libNode['subtree'], hasLength(1));
  }

  Future<void> test_containsMultipleLinks_sameDepth() async {
    var response = jsonDecode(await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/b.dart'): 'int b = null;',
    }));
    expect(response, hasLength(1));

    var libNode = response[0];
    expect(
        libNode,
        isJsonMap.containing({
          'name': 'lib',
          'subtree': [
            isJsonMap.containing({
              'name': 'a.dart',
              'path': convertPath('lib/a.dart'),
              'href': '/project/lib/a.dart'
            }),
            isJsonMap.containing({
              'name': 'b.dart',
              'path': convertPath('lib/b.dart'),
              'href': '/project/lib/b.dart'
            })
          ]
        }));
  }

  Future<void> test_containsPaths() async {
    var response = jsonDecode(await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/src/b.dart'): 'int b = null;',
      convertPath('/project/tool.dart'): 'int c = null;',
    }));

    var libNode = response[0];
    expect(
        libNode,
        isJsonMap.containing({
          'name': 'lib',
          'subtree': [
            isJsonMap.containing({
              'name': 'src',
              'subtree': [
                isJsonMap.containing({'path': convertPath('lib/src/b.dart')})
              ]
            }),
            isJsonMap.containing({'path': convertPath('lib/a.dart')})
          ]
        }));

    var toolNode = response[1];
    expect(toolNode['path'], 'tool.dart');
  }

  Future<void> test_containsSingleLink_deep() async {
    var response = jsonDecode(await renderNavigationTree({
      convertPath('/project/lib/src/a.dart'): 'int a = null;',
    }));
    expect(response, hasLength(1));

    var libNode = response[0];
    expect(
        libNode,
        isJsonMap.containing({
          'name': 'lib',
          'subtree': [
            isJsonMap.containing({
              'name': 'src',
              'subtree': [
                isJsonMap.containing({
                  'name': 'a.dart',
                  'path': convertPath('lib/src/a.dart'),
                  'href': '/project/lib/src/a.dart'
                })
              ]
            })
          ]
        }));
  }

  Future<void> test_containsSingleLink_shallow() async {
    var response = jsonDecode(await renderNavigationTree({
      convertPath('/project/a.dart'): 'int a = null;',
    }));
    expect(response, hasLength(1));

    var aNode = response[0];
    expect(aNode['name'], 'a.dart');
    expect(aNode['path'], 'a.dart');
    expect(aNode['href'], '/project/a.dart');
  }
}

extension _E<T, U> on TypeMatcher<Map<T, U>> {
  TypeMatcher<Map<T, U>> containing(Map<T, dynamic> matchers) {
    var result = this;
    for (var entry in matchers.entries) {
      result = result.having(
          (map) => map[entry.key], entry.key.toString(), entry.value);
    }
    return result;
  }
}
