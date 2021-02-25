// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextLocatorImplTest);
  });
}

@reflectiveTest
class ContextLocatorImplTest with ResourceProviderMixin {
  late final ContextLocatorImpl contextLocator;

  ContextRoot findRoot(List<ContextRoot> roots, Resource rootFolder) {
    for (ContextRoot root in roots) {
      if (root.root == rootFolder) {
        return root;
      }
    }
    StringBuffer buffer = StringBuffer();
    buffer.write('Could not find "');
    buffer.write(rootFolder.path);
    buffer.write('" in');
    for (ContextRoot root in roots) {
      buffer.writeln();
      buffer.write('  ');
      buffer.write(root.root);
    }
    fail(buffer.toString());
  }

  void setUp() {
    contextLocator = ContextLocatorImpl(resourceProvider: resourceProvider);
  }

  void test_locateRoots_link_file_toOutOfRoot() {
    Folder rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart');
    newFile('/home/b.dart');
    resourceProvider.newLink(
      convertPath('/home/test/lib/c.dart'),
      convertPath('/home/b.dart'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles(root, [
      '/home/test/lib/a.dart',
      '/home/test/lib/c.dart',
    ]);
  }

  void test_locateRoots_link_file_toSiblingInRoot() {
    Folder rootFolder = newFolder('/test');
    newFile('/test/lib/a.dart');
    resourceProvider.newLink(
      convertPath('/test/lib/b.dart'),
      convertPath('/test/lib/a.dart'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles(root, [
      '/test/lib/a.dart',
      '/test/lib/b.dart',
    ]);
  }

  void test_locateRoots_link_folder_toParentInRoot() {
    Folder rootFolder = newFolder('/test');
    newFile('/test/lib/a.dart');
    resourceProvider.newLink(
      convertPath('/test/lib/foo'),
      convertPath('/test/lib'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles(root, ['/test/lib/a.dart']);

    _assertAnalyzed(root, [
      '/test/lib/a.dart',
      '/test/lib/foo/b.dart',
    ]);
  }

  void test_locateRoots_link_folder_toParentOfRoot() {
    Folder rootFolder = newFolder('/home/test');
    newFile('/home/test/lib/a.dart');
    newFile('/home/b.dart');
    newFile('/home/other/c.dart');
    resourceProvider.newLink(
      convertPath('/home/test/lib/foo'),
      convertPath('/home'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    // The set of analyzed files includes everything in `/home`,
    // but does not repeat `/home/test/lib/a.dart` and does not cycle.
    _assertAnalyzedFiles(root, [
      '/home/test/lib/a.dart',
      '/home/test/lib/foo/b.dart',
      '/home/test/lib/foo/other/c.dart',
    ]);
  }

  void test_locateRoots_link_folder_toSiblingInRoot() {
    Folder rootFolder = newFolder('/test');
    newFile('/test/lib/a.dart');
    newFile('/test/lib/foo/b.dart');
    resourceProvider.newLink(
      convertPath('/test/lib/bar'),
      convertPath('/test/lib/foo'),
    );

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, isNull);
    expect(root.packagesFile, isNull);

    _assertAnalyzedFiles(root, [
      '/test/lib/a.dart',
      '/test/lib/foo/b.dart',
      '/test/lib/bar/b.dart',
    ]);
  }

  void test_locateRoots_multiple_dirAndNestedDir() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path, innerRootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_multiple_dirAndNestedFile() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    File testFile = newFile('/test/outer/examples/inner/test.dart');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [outerRootFolder.path, testFile.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_multiple_dirAndSiblingDir() {
    Folder outer1RootFolder = newFolder('/test/outer1');
    File outer1OptionsFile = newAnalysisOptionsYamlFile('/test/outer1');
    File outer1PackagesFile = newDotPackagesFile('/test/outer1');

    Folder outer2RootFolder = newFolder('/test/outer2');
    File outer2OptionsFile = newAnalysisOptionsYamlFile('/test/outer2');
    File outer2PackagesFile = newDotPackagesFile('/test/outer2');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outer1RootFolder.path, outer2RootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outer1Root = findRoot(roots, outer1RootFolder);
    expect(outer1Root.includedPaths, unorderedEquals([outer1RootFolder.path]));
    expect(outer1Root.excludedPaths, isEmpty);
    expect(outer1Root.optionsFile, outer1OptionsFile);
    expect(outer1Root.packagesFile, outer1PackagesFile);

    ContextRoot outer2Root = findRoot(roots, outer2RootFolder);
    expect(outer2Root.includedPaths, unorderedEquals([outer2RootFolder.path]));
    expect(outer2Root.excludedPaths, isEmpty);
    expect(outer2Root.optionsFile, outer2OptionsFile);
    expect(outer2Root.packagesFile, outer2PackagesFile);
  }

  void test_locateRoots_multiple_dirAndSiblingFile() {
    Folder outer1RootFolder = newFolder('/test/outer1');
    File outer1OptionsFile = newAnalysisOptionsYamlFile('/test/outer1');
    File outer1PackagesFile = newDotPackagesFile('/test/outer1');

    File outer2OptionsFile = newAnalysisOptionsYamlFile('/test/outer2');
    File outer2PackagesFile = newDotPackagesFile('/test/outer2');
    File testFile = newFile('/test/outer2/test.dart');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [outer1RootFolder.path, testFile.path]);
    expect(roots, hasLength(2));

    ContextRoot outer1Root = findRoot(roots, outer1RootFolder);
    expect(outer1Root.includedPaths, unorderedEquals([outer1RootFolder.path]));
    expect(outer1Root.excludedPaths, isEmpty);
    expect(outer1Root.optionsFile, outer1OptionsFile);
    expect(outer1Root.packagesFile, outer1PackagesFile);

    ContextRoot outer2Root = findRoot(roots, testFile.parent2);
    expect(outer2Root.includedPaths, unorderedEquals([testFile.path]));
    expect(outer2Root.excludedPaths, isEmpty);
    expect(outer2Root.optionsFile, outer2OptionsFile);
    expect(outer2Root.packagesFile, outer2PackagesFile);
  }

  void test_locateRoots_multiple_fileAndSiblingFile() {
    ContextRoot findRootFromIncluded(
        List<ContextRoot> roots, String includedPath) {
      for (ContextRoot root in roots) {
        if (root.includedPaths.contains(includedPath)) {
          return root;
        }
      }
      StringBuffer buffer = StringBuffer();
      buffer.write('Could not find "');
      buffer.write(includedPath);
      buffer.write('" in');
      for (ContextRoot root in roots) {
        buffer.writeln();
        buffer.write('  ');
        buffer.write(root.root);
      }
      fail(buffer.toString());
    }

    File optionsFile = newAnalysisOptionsYamlFile('/test/root');
    File packagesFile = newDotPackagesFile('/test/root');
    File testFile1 = newFile('/test/root/test1.dart');
    File testFile2 = newFile('/test/root/test2.dart');

    List<ContextRoot> roots = contextLocator
        .locateRoots(includedPaths: [testFile1.path, testFile2.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRootFromIncluded(roots, testFile1.path);
    expect(
        root.includedPaths, unorderedEquals([testFile1.path, testFile2.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);
  }

  void test_locateRoots_nested_excluded_dot() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    Folder excludedFolder = newFolder('/test/outer/.examples');
    newAnalysisOptionsYamlFile('/test/outer/.examples/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([excludedFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_excluded_explicit() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    Folder excludedFolder = newFolder('/test/outer/examples');
    newAnalysisOptionsYamlFile('/test/outer/examples/inner');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        excludedPaths: [excludedFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([excludedFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_multiple() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    Folder inner1RootFolder = newFolder('/test/outer/examples/inner1');
    File inner1OptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/examples/inner1');
    Folder inner2RootFolder = newFolder('/test/outer/examples/inner2');
    File inner2PackagesFile = newDotPackagesFile('/test/outer/examples/inner2');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(3));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths,
        unorderedEquals([inner1RootFolder.path, inner2RootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot inner1Root = findRoot(roots, inner1RootFolder);
    expect(inner1Root.includedPaths, unorderedEquals([inner1RootFolder.path]));
    expect(inner1Root.excludedPaths, isEmpty);
    expect(inner1Root.optionsFile, inner1OptionsFile);
    expect(inner1Root.packagesFile, outerPackagesFile);

    ContextRoot inner2Root = findRoot(roots, inner2RootFolder);
    expect(inner2Root.includedPaths, unorderedEquals([inner2RootFolder.path]));
    expect(inner2Root.excludedPaths, isEmpty);
    expect(inner2Root.optionsFile, outerOptionsFile);
    expect(inner2Root.packagesFile, inner2PackagesFile);
  }

  void test_locateRoots_nested_options() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerOptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/examples/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_options_overriddenOptions() {
    Folder outerRootFolder = newFolder('/test/outer');
    newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    newFolder('/test/outer/examples/inner');
    newAnalysisOptionsYamlFile('/test/outer/examples/inner');
    File overrideOptionsFile = newAnalysisOptionsYamlFile('/test/override');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        optionsFile: overrideOptionsFile.path);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, overrideOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_nested_options_overriddenPackages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    newDotPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerOptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/examples/inner');
    File overridePackagesFile = newDotPackagesFile('/test/override');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        packagesFile: overridePackagesFile.path);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, overridePackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, overridePackagesFile);
  }

  void test_locateRoots_nested_optionsAndPackages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerOptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/examples/inner');
    File innerPackagesFile = newDotPackagesFile('/test/outer/examples/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, innerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_nested_optionsAndPackages_overriddenBoth() {
    Folder outerRootFolder = newFolder('/test/outer');
    newAnalysisOptionsYamlFile('/test/outer');
    newDotPackagesFile('/test/outer');
    newFolder('/test/outer/examples/inner');
    newAnalysisOptionsYamlFile('/test/outer/examples/inner');
    newDotPackagesFile('/test/outer/examples/inner');
    File overrideOptionsFile = newAnalysisOptionsYamlFile('/test/override');
    File overridePackagesFile = newDotPackagesFile('/test/override');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        optionsFile: overrideOptionsFile.path,
        packagesFile: overridePackagesFile.path);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, overrideOptionsFile);
    expect(outerRoot.packagesFile, overridePackagesFile);
  }

  void test_locateRoots_nested_packageConfigJson() {
    var outerRootFolder = newFolder('/test/outer');
    var outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    var outerPackagesFile = _newPackageConfigFile('/test/outer');
    var innerRootFolder = newFolder('/test/outer/examples/inner');
    var innerPackagesFile = _newPackageConfigFile('/test/outer/examples/inner');

    var roots = contextLocator.locateRoots(
      includedPaths: [outerRootFolder.path],
    );
    expect(roots, hasLength(2));

    var outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(
      outerRoot.excludedPaths,
      unorderedEquals([
        outerPackagesFile.parent2.path,
        innerRootFolder.path,
      ]),
    );
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    var innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(
      innerRoot.excludedPaths,
      unorderedEquals([
        innerPackagesFile.parent2.path,
      ]),
    );
    expect(innerRoot.optionsFile, outerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_nested_packages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerPackagesFile = newDotPackagesFile('/test/outer/examples/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, outerOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_nested_packages_overriddenOptions() {
    Folder outerRootFolder = newFolder('/test/outer');
    newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    Folder innerRootFolder = newFolder('/test/outer/examples/inner');
    File innerPackagesFile = newDotPackagesFile('/test/outer/examples/inner');
    File overrideOptionsFile = newAnalysisOptionsYamlFile('/test/override');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        optionsFile: overrideOptionsFile.path);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, unorderedEquals([innerRootFolder.path]));
    expect(outerRoot.optionsFile, overrideOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);

    ContextRoot innerRoot = findRoot(roots, innerRootFolder);
    expect(innerRoot.includedPaths, unorderedEquals([innerRootFolder.path]));
    expect(innerRoot.excludedPaths, isEmpty);
    expect(innerRoot.optionsFile, overrideOptionsFile);
    expect(innerRoot.packagesFile, innerPackagesFile);
  }

  void test_locateRoots_nested_packages_overriddenPackages() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    newDotPackagesFile('/test/outer');
    newFolder('/test/outer/examples/inner');
    newDotPackagesFile('/test/outer/examples/inner');
    File overridePackagesFile = newDotPackagesFile('/test/override');

    List<ContextRoot> roots = contextLocator.locateRoots(
        includedPaths: [outerRootFolder.path],
        packagesFile: overridePackagesFile.path);
    expect(roots, hasLength(1));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths, isEmpty);
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, overridePackagesFile);
  }

  void test_locateRoots_nested_packagesDirectory_included() {
    Folder outerRootFolder = newFolder('/test/outer');
    File outerOptionsFile = newAnalysisOptionsYamlFile('/test/outer');
    File outerPackagesFile = newDotPackagesFile('/test/outer');
    File innerOptionsFile =
        newAnalysisOptionsYamlFile('/test/outer/packages/inner');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [outerRootFolder.path]);
    expect(roots, hasLength(2));

    ContextRoot outerRoot = findRoot(roots, outerRootFolder);
    expect(outerRoot.includedPaths, unorderedEquals([outerRootFolder.path]));
    expect(outerRoot.excludedPaths,
        unorderedEquals([innerOptionsFile.parent2.path]));
    expect(outerRoot.optionsFile, outerOptionsFile);
    expect(outerRoot.packagesFile, outerPackagesFile);
  }

  void test_locateRoots_options_withExclude_someFiles() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', content: '''
analyzer:
  exclude:
    - data/**.g.dart
''');
    File packagesFile = newDotPackagesFile('/test/root');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/f.g.dart',
      '/test/root/data/foo/f.g.dart',
      '/test/root/data/foo/bar/f.g.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.g.dart',
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
      '/test/root/data/foo/bar/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_someFolders() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', content: '''
analyzer:
  exclude:
    - data/**/foo/**
''');
    File packagesFile = newDotPackagesFile('/test/root');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, isEmpty);
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/aaa/foo/f.dart',
      '/test/root/data/aaa/foo/bar/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
      '/test/root/data/aaa/bar/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_wholeFolder() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', content: '''
analyzer:
  exclude:
    - data/**
''');
    File packagesFile = newDotPackagesFile('/test/root');
    Folder dataFolder = newFolder('/test/root/data');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, unorderedEquals([dataFolder.path]));
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_wholeFolder_includedOptions() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', content: '''
include: has_excludes.yaml
''');
    newFile('/test/root/has_excludes.yaml', content: '''
analyzer:
  exclude:
    - data/**
''');

    File packagesFile = newDotPackagesFile('/test/root');
    Folder dataFolder = newFolder('/test/root/data');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, unorderedEquals([dataFolder.path]));
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_wholeFolder_includedOptionsMerge() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', content: '''
include: has_excludes.yaml
analyzer:
  exclude:
    - bar/**
''');
    newFile('/test/root/has_excludes.yaml', content: '''
analyzer:
  exclude:
    - foo/**
''');

    File packagesFile = newDotPackagesFile('/test/root');
    Folder fooFolder = newFolder('/test/root/foo');
    Folder barFolder = newFolder('/test/root/bar');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(
      root.excludedPaths,
      unorderedEquals([fooFolder.path, barFolder.path]),
    );
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/foo/f.dart',
      '/test/root/foo/aaa/f.dart',
      '/test/root/bar/f.dart',
      '/test/root/bar/aaa/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
      '/test/root/baz/f.dart',
    ]);
  }

  void test_locateRoots_options_withExclude_wholeFolder_withItsOptions() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root', content: '''
analyzer:
  exclude:
    - data/**
''');
    File packagesFile = newDotPackagesFile('/test/root');
    Folder dataFolder = newFolder('/test/root/data');
    newAnalysisOptionsYamlFile('/test/root/data', content: '');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot root = findRoot(roots, rootFolder);
    expect(root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(root.excludedPaths, unorderedEquals([dataFolder.path]));
    expect(root.optionsFile, optionsFile);
    expect(root.packagesFile, packagesFile);

    _assertNotAnalyzed(root, [
      '/test/root/data/f.dart',
      '/test/root/data/foo/f.dart',
    ]);

    _assertAnalyzed(root, [
      '/test/root/f.dart',
    ]);
  }

  void test_locateRoots_single_dir_directOptions_directPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root');
    File packagesFile = newDotPackagesFile('/test/root');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_directOptions_inheritedPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test/root');
    File packagesFile = newDotPackagesFile('/test');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_inheritedOptions_directPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test');
    File packagesFile = newDotPackagesFile('/test/root');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_inheritedOptions_inheritedPackages() {
    Folder rootFolder = newFolder('/test/root');
    File optionsFile = newAnalysisOptionsYamlFile('/test');
    File packagesFile = newDotPackagesFile('/test');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, rootFolder);
    expect(package1Root.includedPaths, unorderedEquals([rootFolder.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void test_locateRoots_single_dir_prefer_packageConfigJson() {
    var rootFolder = newFolder('/test');
    var optionsFile = newAnalysisOptionsYamlFile('/test');
    newDotPackagesFile('/test'); // the file is not used
    var packageConfigJsonFile = _newPackageConfigFile('/test');

    var roots = contextLocator.locateRoots(includedPaths: [rootFolder.path]);
    expect(roots, hasLength(1));

    var contentRoot = findRoot(roots, rootFolder);
    expect(contentRoot.includedPaths, unorderedEquals([rootFolder.path]));
    expect(
      contentRoot.excludedPaths,
      unorderedEquals(
        [packageConfigJsonFile.parent2.path],
      ),
    );
    expect(contentRoot.optionsFile, optionsFile);
    expect(contentRoot.packagesFile, packageConfigJsonFile);
  }

  void test_locateRoots_single_file_inheritedOptions_directPackages() {
    File optionsFile = newAnalysisOptionsYamlFile('/test');
    File packagesFile = newDotPackagesFile('/test/root');
    File testFile = newFile('/test/root/test.dart');

    List<ContextRoot> roots =
        contextLocator.locateRoots(includedPaths: [testFile.path]);
    expect(roots, hasLength(1));

    ContextRoot package1Root = findRoot(roots, testFile.parent2);
    expect(package1Root.includedPaths, unorderedEquals([testFile.path]));
    expect(package1Root.excludedPaths, isEmpty);
    expect(package1Root.optionsFile, optionsFile);
    expect(package1Root.packagesFile, packagesFile);
  }

  void _assertAnalyzed(ContextRoot root, List<String> posixPathList) {
    for (var posixPath in posixPathList) {
      var path = convertPath(posixPath);
      expect(root.isAnalyzed(path), isTrue, reason: path);
    }
  }

  void _assertAnalyzedFiles(ContextRoot root, List<String> posixPathList) {
    var analyzedFiles = root.analyzedFiles().toList();
    var pathList = posixPathList.map(convertPath).toList();
    expect(analyzedFiles, unorderedEquals(pathList));
  }

  void _assertNotAnalyzed(ContextRoot root, List<String> posixPathList) {
    for (var posixPath in posixPathList) {
      var path = convertPath(posixPath);
      expect(root.isAnalyzed(path), isFalse, reason: path);
    }
  }

  File _newPackageConfigFile(String directoryPath) {
    String path = join(
      directoryPath,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    return newFile(path);
  }
}
