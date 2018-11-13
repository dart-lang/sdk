// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextRootTest);
  });
}

@reflectiveTest
class ContextRootTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();
  String rootPath;
  Folder rootFolder;
  ContextRootImpl contextRoot;

  void setUp() {
    rootPath = provider.convertPath('/test/root');
    rootFolder = provider.newFolder(rootPath);
    contextRoot = new ContextRootImpl(provider, rootFolder);
    contextRoot.included.add(rootFolder);
  }

  test_analyzedFiles() {
    String optionsPath =
        provider.convertPath('/test/root/analysis_options.yaml');
    String readmePath = provider.convertPath('/test/root/README.md');
    String aPath = provider.convertPath('/test/root/lib/a.dart');
    String bPath = provider.convertPath('/test/root/lib/src/b.dart');
    String excludePath = provider.convertPath('/test/root/exclude');
    String cPath = provider.convertPath('/test/root/exclude/c.dart');

    provider.newFile(optionsPath, '');
    provider.newFile(readmePath, '');
    provider.newFile(aPath, '');
    provider.newFile(bPath, '');
    provider.newFile(cPath, '');
    contextRoot.excluded.add(provider.newFolder(excludePath));

    expect(contextRoot.analyzedFiles(),
        unorderedEquals([optionsPath, readmePath, aPath, bPath]));
  }

  test_isAnalyzed_explicitlyExcluded() {
    String excludePath = provider.convertPath('/test/root/exclude');
    String filePath = provider.convertPath('/test/root/exclude/root.dart');
    contextRoot.excluded.add(provider.newFolder(excludePath));
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_explicitlyExcluded_same() {
    String aPath = provider.convertPath('/test/root/lib/a.dart');
    String bPath = provider.convertPath('/test/root/lib/b.dart');
    File aFile = provider.getFile(aPath);

    contextRoot.excluded.add(aFile);

    expect(contextRoot.isAnalyzed(aPath), isFalse);
    expect(contextRoot.isAnalyzed(bPath), isTrue);
  }

  test_isAnalyzed_implicitlyExcluded_dot_analysisOptions() {
    String filePath = provider.convertPath('/test/root/lib/.analysis_options');
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_implicitlyExcluded_dot_packages() {
    String filePath = provider.convertPath('/test/root/lib/.packages');
    expect(contextRoot.isAnalyzed(filePath), isFalse);
  }

  test_isAnalyzed_included() {
    String filePath = provider.convertPath('/test/root/lib/root.dart');
    expect(contextRoot.isAnalyzed(filePath), isTrue);
  }

  test_isAnalyzed_included_same() {
    String aPath = provider.convertPath('/test/root/lib/a.dart');
    String bPath = provider.convertPath('/test/root/lib/b.dart');
    File aFile = provider.getFile(aPath);

    contextRoot = new ContextRootImpl(provider, rootFolder);
    contextRoot.included.add(aFile);

    expect(contextRoot.isAnalyzed(aPath), isTrue);
    expect(contextRoot.isAnalyzed(bPath), isFalse);
  }

  test_isAnalyzed_packagesDirectory_analyzed() {
    String folderPath = provider.convertPath('/test/root/lib/packages');
    provider.newFolder(folderPath);
    expect(contextRoot.isAnalyzed(folderPath), isTrue);
  }
}
