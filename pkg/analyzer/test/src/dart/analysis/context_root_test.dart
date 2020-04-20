// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextRootTest);
  });
}

@reflectiveTest
class ContextRootTest with ResourceProviderMixin {
  String rootPath;
  Folder rootFolder;
  ContextRootImpl contextRoot;

  void setUp() {
    rootPath = convertPath('/test/root');
    rootFolder = newFolder(rootPath);
    contextRoot = ContextRootImpl(resourceProvider, rootFolder);
    contextRoot.included.add(rootFolder);
  }

  test_analyzedFiles() {
    String optionsPath = convertPath('/test/root/analysis_options.yaml');
    String readmePath = convertPath('/test/root/README.md');
    String aPath = convertPath('/test/root/lib/a.dart');
    String bPath = convertPath('/test/root/lib/src/b.dart');
    String excludePath = convertPath('/test/root/exclude');
    String cPath = convertPath('/test/root/exclude/c.dart');

    newFile(optionsPath);
    newFile(readmePath);
    newFile(aPath);
    newFile(bPath);
    newFile(cPath);
    contextRoot.excluded.add(newFolder(excludePath));

    expect(contextRoot.analyzedFiles(),
        unorderedEquals([optionsPath, readmePath, aPath, bPath]));
  }

  test_isAnalyzed_explicitlyExcluded() {
    String excludePath = convertPath('/test/root/exclude');
    String filePath = convertPath('/test/root/exclude/root.dart');
    contextRoot.excluded.add(newFolder(excludePath));
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_explicitlyExcluded_same() {
    String aPath = convertPath('/test/root/lib/a.dart');
    String bPath = convertPath('/test/root/lib/b.dart');
    File aFile = getFile(aPath);

    contextRoot.excluded.add(aFile);

    expect(contextRoot.isAnalyzed(aPath), isFalse);
    expect(contextRoot.isAnalyzed(bPath), isTrue);
  }

  test_isAnalyzed_implicitlyExcluded_dot_analysisOptions() {
    String filePath = convertPath('/test/root/lib/.analysis_options');
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_implicitlyExcluded_dot_packages() {
    String filePath = convertPath('/test/root/lib/.packages');
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_included() {
    String filePath = convertPath('/test/root/lib/root.dart');
    expect(contextRoot.isAnalyzed(filePath), isTrue);
  }

  test_isAnalyzed_included_same() {
    String aPath = convertPath('/test/root/lib/a.dart');
    String bPath = convertPath('/test/root/lib/b.dart');
    File aFile = getFile(aPath);

    contextRoot = ContextRootImpl(resourceProvider, rootFolder);
    contextRoot.included.add(aFile);

    expect(contextRoot.isAnalyzed(aPath), isTrue);
    expect(contextRoot.isAnalyzed(bPath), isFalse);
  }

  test_isAnalyzed_packagesDirectory_analyzed() {
    String folderPath = convertPath('/test/root/lib/packages');
    newFolder(folderPath);
    expect(contextRoot.isAnalyzed(folderPath), isTrue);
  }
}
