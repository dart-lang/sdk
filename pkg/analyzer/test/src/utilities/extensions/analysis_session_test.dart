// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer/src/utilities/extensions/analysis_session.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocateElementTest);
  });
}

/// Tests `locateElement()` on [AnalysisSession].
///
/// This extension method largely delegates to `LibraryElement.locateElement`
/// which is tested more comprehensively in
/// 'test/src/utilities/extensions/library_element_test.dart'.
@reflectiveTest
class LocateElementTest extends PubPackageResolutionTest {
  late _MockAnalysisSession session;

  File get testFile2 => getFile('$testPackageLibPath/test2.dart');

  /// Find class [name] in [library].
  ClassElement findClass(LibraryElement library, String name) {
    return library.definingCompilationUnit.getClass(name)!;
  }

  /// Locate the element referenced by [location] in [session].
  Future<Element?> getElement(ElementLocation? location) =>
      session.locateElement(location!);

  @override
  void setUp() {
    super.setUp();
    session = _MockAnalysisSession();
  }

  void test_elementInLibrary() async {
    final libraryOne = await _createLibrary(testFile, 'class C {}');
    final libraryTwo = await _createLibrary(testFile2, 'class C {}');
    final classOne = findClass(libraryOne, 'C');
    final classTwo = findClass(libraryTwo, 'C');

    expect(await getElement(classOne.location!), classOne);
    expect(await getElement(classTwo.location!), classTwo);
  }

  void test_invalid() async {
    final library =
        await _createLibrary(testFile, 'class C {}', addToSession: false);
    final class_ = findClass(library, 'C');

    expect(await getElement(class_.location!), isNull);
  }

  void test_library() async {
    final libraryOne = await _createLibrary(testFile, 'class C {}');
    final libraryTwo = await _createLibrary(testFile2, 'class C {}');

    expect(await getElement(libraryOne.location!), libraryOne);
    expect(await getElement(libraryTwo.location!), libraryTwo);
  }

  /// Create a library and (unless [addToSession] is `false`) add it to [session].
  Future<LibraryElement> _createLibrary(
    File file,
    String content, {
    bool addToSession = true,
  }) async {
    final code = TestCode.parse(content);
    newFile(file.path, code.code);
    final library = (await resolveFile(file)).libraryElement;
    if (addToSession) {
      session.addLibrary(library);
    }
    return library;
  }
}

class _MockAnalysisSession implements AnalysisSession {
  final _libraries = <String, LibraryElement>{};

  void addLibrary(LibraryElement library) =>
      _libraries[library.identifier] = library;

  @override
  Future<SomeLibraryElementResult> getLibraryByUri(String uri) async {
    final library = _libraries[uri];
    return library != null
        ? LibraryElementResultImpl(library)
        : CannotResolveUriResult();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
