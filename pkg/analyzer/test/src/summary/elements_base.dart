// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';
import 'element_text.dart';

/// A base for testing building elements.
@reflectiveTest
abstract class ElementsBaseTest extends PubPackageResolutionTest {
  final ElementTextConfiguration configuration = ElementTextConfiguration();

  /// We need to test both cases - when we keep linking libraries (happens for
  /// new or invalidated libraries), and when we load libraries from bytes
  /// (happens internally in Blaze or when we have cached summaries).
  bool get keepLinkingLibraries;

  void addSource(String path, String contents) {
    newFile(path, contents);
  }

  Future<LibraryElementImpl> buildLibrary(String text) async {
    final file = newFile(testFile.path, text);
    final analysisContext = contextFor(file);
    final analysisSession = analysisContext.currentSession;

    final uriStr = 'package:test/test.dart';
    final libraryResult = await analysisSession.getLibraryByUri(uriStr);

    if (keepLinkingLibraries) {
      return libraryResult.element;
    } else {
      analysisContext.changeFile(file.path);
      await analysisContext.applyPendingFileChanges();
      // Ask again, should be read from bytes.
      return testContextLibrary(uriStr);
    }
  }

  void checkElementText(LibraryElementImpl library, String expected) {
    final actual = getLibraryText(
      library: library,
      configuration: configuration,
    );
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  Future<LibraryElementImpl> testContextLibrary(String uriStr) async {
    final analysisContext = contextFor(testFile);
    final analysisSession = analysisContext.currentSession;
    final libraryResult = await analysisSession.getLibraryByUri(uriStr);
    return libraryResult.element;
  }
}

extension on SomeLibraryElementResult {
  LibraryElementImpl get element {
    return (this as LibraryElementResult).element as LibraryElementImpl;
  }
}
