// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/navigation_tree_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/web/navigation_tree.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'nnbd_migration_test_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NavigationTreeRendererTest);
  });
}

const isNavigationTreeNode = TypeMatcher<NavigationTreeNode>();

@reflectiveTest
class NavigationTreeRendererTest extends NnbdMigrationTestBase {
  /// Render the navigation tree view for [files].
  Future<List<NavigationTreeNode>> renderNavigationTree(
      Map<String, String> files) async {
    var packageRoot = convertPath('/project');
    await buildInfoForTestFiles(files, includedRoot: packageRoot);
    var migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, packageRoot);
    return NavigationTreeRenderer(migrationInfo, PathMapper(resourceProvider))
        .render();
  }

  Future<void> test_containsEditCounts() async {
    var response = await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = 1;',
      convertPath('/project/lib/b.dart'): 'int b = null;',
      convertPath('/project/lib/c.dart'): 'int c = null;\nint d = null;',
    });

    var libNode = response[0];
    expect(
        libNode,
        isNavigationTreeNode.havingSubtree([
          isNavigationTreeNode.havingEditCount(0),
          isNavigationTreeNode.havingEditCount(1),
          isNavigationTreeNode.havingEditCount(2)
        ]));
  }

  Future<void> test_containsHrefs() async {
    var response = await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/src/b.dart'): 'int b = null;',
      convertPath('/project/tool.dart'): 'int c = null;',
    });

    var libNode = response[0];
    expect(
        libNode,
        isNavigationTreeNode.named('lib').havingSubtree([
          isNavigationTreeNode.named('src').havingSubtree(
              [isNavigationTreeNode.havingHref('/project/lib/src/b.dart')]),
          isNavigationTreeNode.havingHref('/project/lib/a.dart')
        ]));

    var toolNode = response[1];
    expect(toolNode.href, '/project/tool.dart');
  }

  Future<void> test_containsMultipleLinks_multipleDepths() async {
    var response = await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/src/b.dart'): 'int b = null;',
      convertPath('/project/tool.dart'): 'int c = null;',
    });
    expect(response, hasLength(2));

    var libNode = response[0];
    expect(
        libNode,
        isNavigationTreeNode.named('lib').havingSubtree([
          isNavigationTreeNode
              .named('src')
              .havingSubtree([isNavigationTreeNode.named('b.dart')]),
          isNavigationTreeNode.named('a.dart')
        ]));

    var toolNode = response[1];
    expect(toolNode.name, 'tool.dart');
  }

  Future<void> test_containsMultipleLinks_multipleRoots() async {
    var response = await renderNavigationTree({
      convertPath('/project/bin/bin.dart'): 'int c = null;',
      convertPath('/project/lib/a.dart'): 'int a = null;',
    });
    expect(response, hasLength(2));

    var binNode = response[0];
    expect(binNode.type, equals(NavigationTreeNodeType.directory));
    expect(binNode.name, equals('bin'));
    expect(binNode.subtree, hasLength(1));

    var libNode = response[1];
    expect(libNode.type, equals(NavigationTreeNodeType.directory));
    expect(libNode.name, equals('lib'));
    expect(libNode.subtree, hasLength(1));
  }

  Future<void> test_containsMultipleLinks_sameDepth() async {
    var response = await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/b.dart'): 'int b = null;',
    });
    expect(response, hasLength(1));

    var libNode = response[0];
    expect(
        libNode,
        isNavigationTreeNode.named('lib').havingSubtree([
          isNavigationTreeNode
              .named('a.dart')
              .havingPath(convertPath('lib/a.dart'))
              .havingHref('/project/lib/a.dart'),
          isNavigationTreeNode
              .named('b.dart')
              .havingPath(convertPath('lib/b.dart'))
              .havingHref('/project/lib/b.dart')
        ]));
  }

  Future<void> test_containsPaths() async {
    var response = await renderNavigationTree({
      convertPath('/project/lib/a.dart'): 'int a = null;',
      convertPath('/project/lib/src/b.dart'): 'int b = null;',
      convertPath('/project/tool.dart'): 'int c = null;',
    });

    var libNode = response[0];
    expect(
        libNode,
        isNavigationTreeNode.named('lib').havingSubtree([
          isNavigationTreeNode.named('src').havingSubtree(
              [isNavigationTreeNode.havingPath(convertPath('lib/src/b.dart'))]),
          isNavigationTreeNode.havingPath(convertPath('lib/a.dart'))
        ]));

    var toolNode = response[1];
    expect(toolNode.path, 'tool.dart');
  }

  Future<void> test_containsSingleLink_deep() async {
    var response = await renderNavigationTree({
      convertPath('/project/lib/src/a.dart'): 'int a = null;',
    });
    expect(response, hasLength(1));

    var libNode = response[0];
    expect(
        libNode,
        isNavigationTreeNode.named('lib').havingSubtree([
          isNavigationTreeNode.named('src').havingSubtree([
            isNavigationTreeNode
                .named('a.dart')
                .havingPath(convertPath('lib/src/a.dart'))
                .havingHref('/project/lib/src/a.dart')
          ])
        ]));
  }

  Future<void> test_containsSingleLink_shallow() async {
    var response = await renderNavigationTree({
      convertPath('/project/a.dart'): 'int a = null;',
    });
    expect(response, hasLength(1));

    var aNode = response[0];
    expect(aNode.name, 'a.dart');
    expect(aNode.path, 'a.dart');
    expect(aNode.href, '/project/a.dart');
  }
}

extension on TypeMatcher<NavigationTreeNode> {
  TypeMatcher<NavigationTreeNode> havingSubtree(dynamic matcher) =>
      having((node) => node.subtree, 'subtree', matcher);

  TypeMatcher<NavigationTreeNode> havingEditCount(dynamic matcher) =>
      having((node) => node.editCount, 'editCount', matcher);

  TypeMatcher<NavigationTreeNode> named(dynamic matcher) =>
      having((node) => node.name, 'name', matcher);

  TypeMatcher<NavigationTreeNode> havingHref(dynamic matcher) =>
      having((node) => node.href, 'href', matcher);

  TypeMatcher<NavigationTreeNode> havingPath(dynamic matcher) =>
      having((node) => node.path, 'path', matcher);
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
