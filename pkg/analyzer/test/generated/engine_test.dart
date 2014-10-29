// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.engine_test;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart' as ht;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/task_dart.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import 'all_the_rest.dart';
import 'resolver_test.dart';
import 'test_support.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisCacheTest);
  runReflectiveTests(AnalysisContextImplTest);
  runReflectiveTests(AnalysisTaskTest);
  runReflectiveTests(AnalysisOptionsImplTest);
  runReflectiveTests(DartEntryTest);
  runReflectiveTests(GenerateDartErrorsTaskTest);
  runReflectiveTests(GenerateDartHintsTaskTest);
  runReflectiveTests(GetContentTaskTest);
  runReflectiveTests(HtmlEntryTest);
  runReflectiveTests(IncrementalAnalysisCacheTest);
  runReflectiveTests(InstrumentedAnalysisContextImplTest);
  runReflectiveTests(IncrementalAnalysisTaskTest);
  runReflectiveTests(ParseDartTaskTest);
  runReflectiveTests(ParseHtmlTaskTest);
  runReflectiveTests(PartitionManagerTest);
  runReflectiveTests(ResolveDartLibraryTaskTest);
  runReflectiveTests(ResolveDartUnitTaskTest);
  runReflectiveTests(ResolveHtmlTaskTest);
  runReflectiveTests(ScanDartTaskTest);
  runReflectiveTests(SdkCachePartitionTest);
  runReflectiveTests(UniversalCachePartitionTest);
  runReflectiveTests(WorkManagerTest);
}


class AnalysisCacheTest extends EngineTestCase {
  void test_creation() {
    expect(new AnalysisCache(new List<CachePartition>(0)), isNotNull);
  }

  void test_get() {
    AnalysisCache cache = new AnalysisCache(new List<CachePartition>(0));
    TestSource source = new TestSource();
    expect(cache.get(source), isNull);
  }

  void test_iterator() {
    CachePartition partition =
        new UniversalCachePartition(null, 8, new DefaultRetentionPolicy());
    AnalysisCache cache = new AnalysisCache(<CachePartition>[partition]);
    TestSource source = new TestSource();
    DartEntry entry = new DartEntry();
    cache.put(source, entry);
    MapIterator<Source, SourceEntry> iterator = cache.iterator();
    expect(iterator.moveNext(), isTrue);
    expect(iterator.key, same(source));
    expect(iterator.value, same(entry));
    expect(iterator.moveNext(), isFalse);
  }

  void test_put_noFlush() {
    CachePartition partition =
        new UniversalCachePartition(null, 8, new DefaultRetentionPolicy());
    AnalysisCache cache = new AnalysisCache(<CachePartition>[partition]);
    TestSource source = new TestSource();
    DartEntry entry = new DartEntry();
    cache.put(source, entry);
    expect(cache.get(source), same(entry));
  }

  void test_setMaxCacheSize() {
    CachePartition partition = new UniversalCachePartition(
        null,
        8,
        new _AnalysisCacheTest_test_setMaxCacheSize());
    AnalysisCache cache = new AnalysisCache(<CachePartition>[partition]);
    int size = 6;
    for (int i = 0; i < size; i++) {
      Source source = new TestSource("/test$i.dart");
      DartEntry entry = new DartEntry();
      entry.setValue(DartEntry.PARSED_UNIT, null);
      cache.put(source, entry);
      cache.accessedAst(source);
    }
    _assertNonFlushedCount(size, cache);
    int newSize = size - 2;
    partition.maxCacheSize = newSize;
    _assertNonFlushedCount(newSize, cache);
  }

  void test_size() {
    CachePartition partition =
        new UniversalCachePartition(null, 8, new DefaultRetentionPolicy());
    AnalysisCache cache = new AnalysisCache(<CachePartition>[partition]);
    int size = 4;
    for (int i = 0; i < size; i++) {
      Source source = new TestSource("/test$i.dart");
      cache.put(source, new DartEntry());
      cache.accessedAst(source);
    }
    expect(cache.size(), size);
  }

  void _assertNonFlushedCount(int expectedCount, AnalysisCache cache) {
    int nonFlushedCount = 0;
    MapIterator<Source, SourceEntry> iterator = cache.iterator();
    while (iterator.moveNext()) {
      if (iterator.value.getState(DartEntry.PARSED_UNIT) !=
          CacheState.FLUSHED) {
        nonFlushedCount++;
      }
    }
    expect(nonFlushedCount, expectedCount);
  }
}


class AnalysisContextImplTest extends EngineTestCase {
  /**
   * An analysis context whose source factory is [sourceFactory].
   */
  AnalysisContextImpl _context;

  /**
   * The source factory associated with the analysis [context].
   */
  SourceFactory _sourceFactory;

  void fail_extractContext() {
    fail("Implement this");
  }

  void fail_mergeContext() {
    fail("Implement this");
  }

  void fail_performAnalysisTask_importedLibraryDelete_html() {
    Source htmlSource = _addSource(
        "/page.html",
        r'''
<html><body><script type="application/dart">
  import 'libB.dart';
  main() {print('hello dart');}
</script></body></html>''');
    Source libBSource = _addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedHtmlUnit(htmlSource), isNotNull, reason: "htmlUnit resolved 1");
    expect(_context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull, reason: "libB resolved 1");
    expect(!_hasAnalysisErrorWithErrorSeverity(_context.getErrors(htmlSource)), isTrue, reason: "htmlSource doesn't have errors");
    // remove libB.dart content and analyze
    _context.setContents(libBSource, null);
    _analyzeAll_assertFinished();
    expect(_context.getResolvedHtmlUnit(htmlSource), isNotNull, reason: "htmlUnit resolved 1");
    AnalysisErrorInfo errors = _context.getErrors(htmlSource);
    expect(_hasAnalysisErrorWithErrorSeverity(errors), isTrue, reason: "htmlSource has an error");
  }

  void fail_recordLibraryElements() {
    fail("Implement this");
  }

  @override
  void setUp() {
    _context = new AnalysisContextImpl();
    _sourceFactory = new SourceFactory(
        [new DartUriResolver(DirectoryBasedDartSdk.defaultSdk), new FileUriResolver()]);
    _context.sourceFactory = _sourceFactory;
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.con1(_context.analysisOptions);
    options.cacheSize = 256;
    options.enableAsync = true;
    options.enableEnum = true;
    _context.analysisOptions = options;
  }

  @override
  void tearDown() {
    _context = null;
    _sourceFactory = null;
    super.tearDown();
  }

  void test_applyChanges_add() {
    expect(_context.sourcesNeedingProcessing.isEmpty, isTrue);
    Source source = _addSource("/test.dart", "main() {}");
    expect(_context.sourcesNeedingProcessing.contains(source), isTrue);
  }

  void test_applyChanges_change_flush_element() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source librarySource = _addSource(
        "/lib.dart",
        r'''
library lib;
int a = 0;''');
    expect(_context.computeLibraryElement(librarySource), isNotNull);
    _context.setContents(
        librarySource,
        r'''
library lib;
int aa = 0;''');
    expect(_context.getLibraryElement(librarySource), isNull);
  }

  void test_applyChanges_change_multiple() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source librarySource = _addSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';
int a = 0;''');
    Source partSource = _addSource(
        "/part.dart",
        r'''
part of lib;
int b = a;''');
    _context.computeLibraryElement(librarySource);
    _context.setContents(
        librarySource,
        r'''
library lib;
part 'part.dart';
int aa = 0;''');
    _context.setContents(
        partSource,
        r'''
part of lib;
int b = aa;''');
    _context.computeLibraryElement(librarySource);
    CompilationUnit libraryUnit =
        _context.resolveCompilationUnit2(librarySource, librarySource);
    CompilationUnit partUnit =
        _context.resolveCompilationUnit2(partSource, librarySource);
    TopLevelVariableDeclaration declaration =
        libraryUnit.declarations[0] as TopLevelVariableDeclaration;
    Element declarationElement = declaration.variables.variables[0].element;
    TopLevelVariableDeclaration use =
        partUnit.declarations[0] as TopLevelVariableDeclaration;
    Element useElement =
        (use.variables.variables[0].initializer as SimpleIdentifier).staticElement;
    expect((useElement as PropertyAccessorElement).variable, same(declarationElement));
  }

  void test_applyChanges_empty() {
    _context.applyChanges(new ChangeSet());
    expect(_context.performAnalysisTask().changeNotices, isNull);
  }

  void test_applyChanges_overriddenSource() {
    // Note: addSource adds the source to the contentCache.
    Source source = _addSource("/test.dart", "library test;");
    _context.computeErrors(source);
    while (!_context.sourcesNeedingProcessing.isEmpty) {
      _context.performAnalysisTask();
    }
    // Adding the source as a changedSource should have no effect since
    // it is already overridden in the content cache.
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedSource(source);
    _context.applyChanges(changeSet);
    expect(_context.sourcesNeedingProcessing, hasLength(0));
  }

  void test_applyChanges_remove() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source libA = _addSource(
        "/libA.dart",
        r'''
library libA;
import 'libB.dart';''');
    Source libB =
        _addSource("/libB.dart", "library libB;");
    LibraryElement libAElement = _context.computeLibraryElement(libA);
    List<LibraryElement> importedLibraries = libAElement.importedLibraries;
    expect(importedLibraries, hasLength(2));
    _context.computeErrors(libA);
    _context.computeErrors(libB);
    expect(_context.sourcesNeedingProcessing, hasLength(0));
    _context.setContents(libB, null);
    _removeSource(libB);
    List<Source> sources = _context.sourcesNeedingProcessing;
    expect(sources, hasLength(1));
    expect(sources[0], same(libA));
    libAElement = _context.computeLibraryElement(libA);
    importedLibraries = libAElement.importedLibraries;
    expect(importedLibraries, hasLength(1));
  }

  void test_applyChanges_removeContainer() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source libA = _addSource(
        "/libA.dart",
        r'''
library libA;
import 'libB.dart';''');
    Source libB =
        _addSource("/libB.dart", "library libB;");
    _context.computeLibraryElement(libA);
    _context.computeErrors(libA);
    _context.computeErrors(libB);
    expect(_context.sourcesNeedingProcessing, hasLength(0));
    ChangeSet changeSet = new ChangeSet();
    changeSet.removedContainer(
        new _AnalysisContextImplTest_test_applyChanges_removeContainer(libB));
    _context.applyChanges(changeSet);
    List<Source> sources = _context.sourcesNeedingProcessing;
    expect(sources, hasLength(1));
    expect(sources[0], same(libA));
  }

  void test_computeDocumentationComment_block() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    String comment = "/** Comment */";
    Source source =
        _addSource("/test.dart", """
$comment
class A {}""");
    LibraryElement libraryElement = _context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    expect(_context.computeDocumentationComment(classElement), comment);
  }

  void test_computeDocumentationComment_none() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source =
        _addSource("/test.dart", "class A {}");
    LibraryElement libraryElement = _context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    expect(_context.computeDocumentationComment(classElement), isNull);
  }

  void test_computeDocumentationComment_null() {
    expect(_context.computeDocumentationComment(null), isNull);
  }

  void test_computeDocumentationComment_singleLine_multiple_EOL_n() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    String comment = "/// line 1\n/// line 2\n/// line 3\n";
    Source source = _addSource("/test.dart", "${comment}class A {}");
    LibraryElement libraryElement = _context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    String actual = _context.computeDocumentationComment(classElement);
    expect(actual, "/// line 1\n/// line 2\n/// line 3");
  }

  void test_computeDocumentationComment_singleLine_multiple_EOL_rn() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    String comment = "/// line 1\r\n/// line 2\r\n/// line 3\r\n";
    Source source = _addSource("/test.dart", "${comment}class A {}");
    LibraryElement libraryElement = _context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    String actual = _context.computeDocumentationComment(classElement);
    expect(actual, "/// line 1\n/// line 2\n/// line 3");
  }

  void test_computeErrors_dart_none() {
    Source source = _addSource("/lib.dart", "library lib;");
    List<AnalysisError> errors = _context.computeErrors(source);
    expect(errors, hasLength(0));
  }

  void test_computeErrors_dart_part() {
    Source librarySource =
        _addSource("/lib.dart", "library lib; part 'part.dart';");
    Source partSource = _addSource("/part.dart", "part of 'lib';");
    _context.parseCompilationUnit(librarySource);
    List<AnalysisError> errors = _context.computeErrors(partSource);
    expect(errors, isNotNull);
    expect(errors.length > 0, isTrue);
  }

  void test_computeErrors_dart_some() {
    Source source = _addSource("/lib.dart", "library 'lib';");
    List<AnalysisError> errors = _context.computeErrors(source);
    expect(errors, isNotNull);
    expect(errors.length > 0, isTrue);
  }

  void test_computeErrors_html_none() {
    Source source = _addSource("/test.html", "<html></html>");
    List<AnalysisError> errors = _context.computeErrors(source);
    expect(errors, hasLength(0));
  }

  void test_computeExportedLibraries_none() {
    Source source = _addSource("/test.dart", "library test;");
    expect(_context.computeExportedLibraries(source), hasLength(0));
  }

  void test_computeExportedLibraries_some() {
    //    addSource("/lib1.dart", "library lib1;");
    //    addSource("/lib2.dart", "library lib2;");
    Source source = _addSource(
        "/test.dart",
        "library test; export 'lib1.dart'; export 'lib2.dart';");
    expect(_context.computeExportedLibraries(source), hasLength(2));
  }

  void test_computeHtmlElement_nonHtml() {
    Source source = _addSource("/test.dart", "library test;");
    expect(_context.computeHtmlElement(source), isNull);
  }

  void test_computeHtmlElement_valid() {
    Source source = _addSource("/test.html", "<html></html>");
    HtmlElement element = _context.computeHtmlElement(source);
    expect(element, isNotNull);
    expect(_context.computeHtmlElement(source), same(element));
  }

  void test_computeImportedLibraries_none() {
    Source source = _addSource("/test.dart", "library test;");
    expect(_context.computeImportedLibraries(source), hasLength(0));
  }

  void test_computeImportedLibraries_some() {
    //    addSource("/lib1.dart", "library lib1;");
    //    addSource("/lib2.dart", "library lib2;");
    Source source = _addSource(
        "/test.dart",
        "library test; import 'lib1.dart'; import 'lib2.dart';");
    expect(_context.computeImportedLibraries(source), hasLength(2));
  }

  void test_computeKindOf_html() {
    Source source = _addSource("/test.html", "");
    expect(_context.computeKindOf(source), same(SourceKind.HTML));
  }

  void test_computeKindOf_library() {
    Source source = _addSource("/test.dart", "library lib;");
    expect(_context.computeKindOf(source), same(SourceKind.LIBRARY));
  }

  void test_computeKindOf_libraryAndPart() {
    Source source = _addSource("/test.dart", "library lib; part of lib;");
    expect(_context.computeKindOf(source), same(SourceKind.LIBRARY));
  }

  void test_computeKindOf_part() {
    Source source = _addSource("/test.dart", "part of lib;");
    expect(_context.computeKindOf(source), same(SourceKind.PART));
  }

  void test_computeLibraryElement() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", "library lib;");
    LibraryElement element = _context.computeLibraryElement(source);
    expect(element, isNotNull);
  }

  void test_computeLineInfo_dart() {
    Source source = _addSource(
        "/test.dart",
        r'''
library lib;

main() {}''');
    LineInfo info = _context.computeLineInfo(source);
    expect(info, isNotNull);
  }

  void test_computeLineInfo_html() {
    Source source = _addSource(
        "/test.html",
        r'''
<html>
  <body>
    <h1>A</h1>
  </body>
</html>''');
    LineInfo info = _context.computeLineInfo(source);
    expect(info, isNotNull);
  }

  void test_computeResolvableCompilationUnit_dart_exception() {
    TestSource source = _addSourceWithException("/test.dart");
    try {
      _context.computeResolvableCompilationUnit(source);
      fail("Expected AnalysisException");
    } on AnalysisException catch (exception) {
      // Expected
    }
  }

  void test_computeResolvableCompilationUnit_html_exception() {
    Source source = _addSource("/lib.html", "<html></html>");
    try {
      _context.computeResolvableCompilationUnit(source);
      fail("Expected AnalysisException");
    } on AnalysisException catch (exception) {
      // Expected
    }
  }

  void test_computeResolvableCompilationUnit_valid() {
    Source source = _addSource("/lib.dart", "library lib;");
    CompilationUnit parsedUnit = _context.parseCompilationUnit(source);
    expect(parsedUnit, isNotNull);
    CompilationUnit resolvedUnit =
        _context.computeResolvableCompilationUnit(source);
    expect(resolvedUnit, isNotNull);
    expect(resolvedUnit, same(parsedUnit));
  }

  void test_dispose() {
    expect(_context.isDisposed, isFalse);
    _context.dispose();
    expect(_context.isDisposed, isTrue);
  }

  void test_exists_false() {
    TestSource source = new TestSource();
    source.exists2 = false;
    expect(_context.exists(source), isFalse);
  }

  void test_exists_null() {
    expect(_context.exists(null), isFalse);
  }

  void test_exists_overridden() {
    Source source = new TestSource();
    _context.setContents(source, "");
    expect(_context.exists(source), isTrue);
  }

  void test_exists_true() {
    expect(_context.exists(new AnalysisContextImplTest_Source_exists_true()), isTrue);
  }

  void test_getAnalysisOptions() {
    expect(_context.analysisOptions, isNotNull);
  }

  void test_getContents_fromSource() {
    String content = "library lib;";
    TimestampedData<String> contents =
        _context.getContents(new TestSource('/test.dart', content));
    expect(contents.data.toString(), content);
  }

  void test_getContents_overridden() {
    String content = "library lib;";
    Source source = new TestSource();
    _context.setContents(source, content);
    TimestampedData<String> contents = _context.getContents(source);
    expect(contents.data.toString(), content);
  }

  void test_getContents_unoverridden() {
    String content = "library lib;";
    Source source = new TestSource('/test.dart', content);
    _context.setContents(source, "part of lib;");
    _context.setContents(source, null);
    TimestampedData<String> contents = _context.getContents(source);
    expect(contents.data.toString(), content);
  }

  void test_getDeclaredVariables() {
    _context = AnalysisContextFactory.contextWithCore();
    expect(_context.declaredVariables, isNotNull);
  }

  void test_getElement() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    LibraryElement core =
        _context.computeLibraryElement(_sourceFactory.forUri("dart:core"));
    expect(core, isNotNull);
    ClassElement classObject =
        _findClass(core.definingCompilationUnit, "Object");
    expect(classObject, isNotNull);
    ElementLocation location = classObject.location;
    Element element = _context.getElement(location);
    expect(element, same(classObject));
  }

  void test_getElement_constructor_named() {
    Source source = _addSource(
        "/lib.dart",
        r'''
class A {
  A.named() {}
}''');
    _analyzeAll_assertFinished();
    LibraryElement library = _context.computeLibraryElement(source);
    ClassElement classA = _findClass(library.definingCompilationUnit, "A");
    ConstructorElement constructor = classA.constructors[0];
    ElementLocation location = constructor.location;
    Element element = _context.getElement(location);
    expect(element, same(constructor));
  }

  void test_getElement_constructor_unnamed() {
    Source source = _addSource(
        "/lib.dart",
        r'''
class A {
  A() {}
}''');
    _analyzeAll_assertFinished();
    LibraryElement library = _context.computeLibraryElement(source);
    ClassElement classA = _findClass(library.definingCompilationUnit, "A");
    ConstructorElement constructor = classA.constructors[0];
    ElementLocation location = constructor.location;
    Element element = _context.getElement(location);
    expect(element, same(constructor));
  }

  void test_getElement_enum() {
    Source source = _addSource('/test.dart', 'enum MyEnum {A, B, C}');
    _analyzeAll_assertFinished();
    LibraryElement library = _context.computeLibraryElement(source);
    ClassElement myEnum = library.definingCompilationUnit.getEnum('MyEnum');
    ElementLocation location = myEnum.location;
    Element element = _context.getElement(location);
    expect(element, same(myEnum));
  }

  void test_getErrors_dart_none() {
    Source source = _addSource("/lib.dart", "library lib;");
    List<AnalysisError> errors = _context.getErrors(source).errors;
    expect(errors, hasLength(0));
    _context.computeErrors(source);
    errors = _context.getErrors(source).errors;
    expect(errors, hasLength(0));
  }

  void test_getErrors_dart_some() {
    Source source = _addSource("/lib.dart", "library 'lib';");
    List<AnalysisError> errors = _context.getErrors(source).errors;
    expect(errors, hasLength(0));
    _context.computeErrors(source);
    errors = _context.getErrors(source).errors;
    expect(errors, hasLength(1));
  }

  void test_getErrors_html_none() {
    Source source = _addSource("/test.html", "<html></html>");
    List<AnalysisError> errors = _context.getErrors(source).errors;
    expect(errors, hasLength(0));
    _context.computeErrors(source);
    errors = _context.getErrors(source).errors;
    expect(errors, hasLength(0));
  }

  void test_getErrors_html_some() {
    Source source = _addSource(
        "/test.html",
        r'''
<html><head>
<script type='application/dart' src='test.dart'/>
</head></html>''');
    List<AnalysisError> errors = _context.getErrors(source).errors;
    expect(errors, hasLength(0));
    _context.computeErrors(source);
    errors = _context.getErrors(source).errors;
    expect(errors, hasLength(1));
  }

  void test_getHtmlElement_dart() {
    Source source = _addSource("/test.dart", "");
    expect(_context.getHtmlElement(source), isNull);
    expect(_context.computeHtmlElement(source), isNull);
    expect(_context.getHtmlElement(source), isNull);
  }

  void test_getHtmlElement_html() {
    Source source = _addSource("/test.html", "<html></html>");
    HtmlElement element = _context.getHtmlElement(source);
    expect(element, isNull);
    _context.computeHtmlElement(source);
    element = _context.getHtmlElement(source);
    expect(element, isNotNull);
  }

  void test_getHtmlFilesReferencing_html() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source htmlSource = _addSource(
        "/test.html",
        r'''
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource = _addSource("/test.dart", "library lib;");
    Source secondHtmlSource = _addSource("/test.html", "<html></html>");
    _context.computeLibraryElement(librarySource);
    List<Source> result = _context.getHtmlFilesReferencing(secondHtmlSource);
    expect(result, hasLength(0));
    _context.parseHtmlUnit(htmlSource);
    result = _context.getHtmlFilesReferencing(secondHtmlSource);
    expect(result, hasLength(0));
  }

  void test_getHtmlFilesReferencing_library() {
    Source htmlSource = _addSource(
        "/test.html",
        r'''
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource = _addSource("/test.dart", "library lib;");
    List<Source> result = _context.getHtmlFilesReferencing(librarySource);
    expect(result, hasLength(0));
    _context.parseHtmlUnit(htmlSource);
    result = _context.getHtmlFilesReferencing(librarySource);
    expect(result, hasLength(1));
    expect(result[0], htmlSource);
  }

  void test_getHtmlFilesReferencing_part() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source htmlSource = _addSource(
        "/test.html",
        r'''
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource =
        _addSource("/test.dart", "library lib; part 'part.dart';");
    Source partSource = _addSource("/part.dart", "part of lib;");
    _context.computeLibraryElement(librarySource);
    List<Source> result = _context.getHtmlFilesReferencing(partSource);
    expect(result, hasLength(0));
    _context.parseHtmlUnit(htmlSource);
    result = _context.getHtmlFilesReferencing(partSource);
    expect(result, hasLength(1));
    expect(result[0], htmlSource);
  }

  void test_getHtmlSources() {
    List<Source> sources = _context.htmlSources;
    expect(sources, hasLength(0));
    Source source = _addSource("/test.html", "");
    _context.computeKindOf(source);
    sources = _context.htmlSources;
    expect(sources, hasLength(1));
    expect(sources[0], source);
  }

  void test_getKindOf_html() {
    Source source = _addSource("/test.html", "");
    expect(_context.getKindOf(source), same(SourceKind.HTML));
  }

  void test_getKindOf_library() {
    Source source = _addSource("/test.dart", "library lib;");
    expect(_context.getKindOf(source), same(SourceKind.UNKNOWN));
    _context.computeKindOf(source);
    expect(_context.getKindOf(source), same(SourceKind.LIBRARY));
  }

  void test_getKindOf_part() {
    Source source = _addSource("/test.dart", "part of lib;");
    expect(_context.getKindOf(source), same(SourceKind.UNKNOWN));
    _context.computeKindOf(source);
    expect(_context.getKindOf(source), same(SourceKind.PART));
  }

  void test_getKindOf_unknown() {
    Source source = _addSource("/test.css", "");
    expect(_context.getKindOf(source), same(SourceKind.UNKNOWN));
  }

  void test_getLaunchableClientLibrarySources() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    List<Source> sources = _context.launchableClientLibrarySources;
    expect(sources, hasLength(0));
    Source source = _addSource(
        "/test.dart",
        r'''
import 'dart:html';
main() {}''');
    _context.computeLibraryElement(source);
    sources = _context.launchableClientLibrarySources;
    expect(sources, hasLength(1));
  }

  void test_getLaunchableServerLibrarySources() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    List<Source> sources = _context.launchableServerLibrarySources;
    expect(sources, hasLength(0));
    Source source = _addSource("/test.dart", "main() {}");
    _context.computeLibraryElement(source);
    sources = _context.launchableServerLibrarySources;
    expect(sources, hasLength(1));
  }

  void test_getLibrariesContaining() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source librarySource = _addSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';''');
    Source partSource = _addSource("/part.dart", "part of lib;");
    _context.computeLibraryElement(librarySource);
    List<Source> result = _context.getLibrariesContaining(librarySource);
    expect(result, hasLength(1));
    expect(result[0], librarySource);
    result = _context.getLibrariesContaining(partSource);
    expect(result, hasLength(1));
    expect(result[0], librarySource);
  }

  void test_getLibrariesDependingOn() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source libASource = _addSource("/libA.dart", "library libA;");
    _addSource("/libB.dart", "library libB;");
    Source lib1Source = _addSource(
        "/lib1.dart",
        r'''
library lib1;
import 'libA.dart';
export 'libB.dart';''');
    Source lib2Source = _addSource(
        "/lib2.dart",
        r'''
library lib2;
import 'libB.dart';
export 'libA.dart';''');
    _context.computeLibraryElement(lib1Source);
    _context.computeLibraryElement(lib2Source);
    List<Source> result = _context.getLibrariesDependingOn(libASource);
    expect(result, unorderedEquals([lib1Source, lib2Source]));
  }

  void test_getLibrariesReferencedFromHtml() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source htmlSource = _addSource(
        "/test.html",
        r'''
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource = _addSource("/test.dart", "library lib;");
    _context.computeLibraryElement(librarySource);
    _context.parseHtmlUnit(htmlSource);
    List<Source> result = _context.getLibrariesReferencedFromHtml(htmlSource);
    expect(result, hasLength(1));
    expect(result[0], librarySource);
  }

  void test_getLibrariesReferencedFromHtml_no() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source htmlSource = _addSource(
        "/test.html",
        r'''
<html><head>
<script type='application/dart' src='test.js'/>
</head></html>''');
    _addSource("/test.dart", "library lib;");
    _context.parseHtmlUnit(htmlSource);
    List<Source> result = _context.getLibrariesReferencedFromHtml(htmlSource);
    expect(result, hasLength(0));
  }

  void test_getLibraryElement() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", "library lib;");
    LibraryElement element = _context.getLibraryElement(source);
    expect(element, isNull);
    _context.computeLibraryElement(source);
    element = _context.getLibraryElement(source);
    expect(element, isNotNull);
  }

  void test_getLibrarySources() {
    List<Source> sources = _context.librarySources;
    int originalLength = sources.length;
    Source source = _addSource("/test.dart", "library lib;");
    _context.computeKindOf(source);
    sources = _context.librarySources;
    expect(sources, hasLength(originalLength + 1));
    for (Source returnedSource in sources) {
      if (returnedSource == source) {
        return;
      }
    }
    fail("The added source was not in the list of library sources");
  }

  void test_getLineInfo() {
    Source source = _addSource(
        "/test.dart",
        r'''
library lib;

main() {}''');
    LineInfo info = _context.getLineInfo(source);
    expect(info, isNull);
    _context.parseCompilationUnit(source);
    info = _context.getLineInfo(source);
    expect(info, isNotNull);
  }

  void test_getModificationStamp_fromSource() {
    int stamp = 42;
    expect(_context.getModificationStamp(
            new AnalysisContextImplTest_Source_getModificationStamp_fromSource(stamp)), stamp);
  }

  void test_getModificationStamp_overridden() {
    int stamp = 42;
    Source source =
        new AnalysisContextImplTest_Source_getModificationStamp_overridden(stamp);
    _context.setContents(source, "");
    expect(stamp != _context.getModificationStamp(source), isTrue);
  }

  void test_getPublicNamespace_element() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", "class A {}");
    LibraryElement library = _context.computeLibraryElement(source);
    Namespace namespace = _context.getPublicNamespace(library);
    expect(namespace, isNotNull);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement,
        ClassElement,
        namespace.get("A"));
  }

  void test_getRefactoringUnsafeSources() {
    // not sources initially
    List<Source> sources = _context.refactoringUnsafeSources;
    expect(sources, hasLength(0));
    // add new source, unresolved
    Source source = _addSource("/test.dart", "library lib;");
    sources = _context.refactoringUnsafeSources;
    expect(sources, hasLength(1));
    expect(sources[0], source);
    // resolve source
    _context.computeLibraryElement(source);
    sources = _context.refactoringUnsafeSources;
    expect(sources, hasLength(0));
  }

  void test_getResolvedCompilationUnit_library() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library libb;");
    LibraryElement library = _context.computeLibraryElement(source);
    expect(_context.getResolvedCompilationUnit(source, library), isNotNull);
    _context.setContents(source, "library lib;");
    expect(_context.getResolvedCompilationUnit(source, library), isNull);
  }

  void test_getResolvedCompilationUnit_library_null() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    expect(_context.getResolvedCompilationUnit(source, null), isNull);
  }

  void test_getResolvedCompilationUnit_source_dart() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    expect(_context.getResolvedCompilationUnit2(source, source), isNull);
    _context.resolveCompilationUnit2(source, source);
    expect(_context.getResolvedCompilationUnit2(source, source), isNotNull);
  }

  void test_getResolvedCompilationUnit_source_html() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.getResolvedCompilationUnit2(source, source), isNull);
    expect(_context.resolveCompilationUnit2(source, source), isNull);
    expect(_context.getResolvedCompilationUnit2(source, source), isNull);
  }

  void test_getResolvedHtmlUnit() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.getResolvedHtmlUnit(source), isNull);
    _context.resolveHtmlUnit(source);
    expect(_context.getResolvedHtmlUnit(source), isNotNull);
  }

  void test_getSourceFactory() {
    expect(_context.sourceFactory, same(_sourceFactory));
  }

  void test_getStatistics() {
    AnalysisContextStatistics statistics = _context.statistics;
    expect(statistics, isNotNull);
    // The following lines are fragile.
    // The values depend on the number of libraries in the SDK.
//    assertLength(0, statistics.getCacheRows());
//    assertLength(0, statistics.getExceptions());
//    assertLength(0, statistics.getSources());
  }

  void test_isClientLibrary_dart() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource(
        "/test.dart",
        r'''
import 'dart:html';

main() {}''');
    expect(_context.isClientLibrary(source), isFalse);
    expect(_context.isServerLibrary(source), isFalse);
    _context.computeLibraryElement(source);
    expect(_context.isClientLibrary(source), isTrue);
    expect(_context.isServerLibrary(source), isFalse);
  }

  void test_isClientLibrary_html() {
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.isClientLibrary(source), isFalse);
  }

  void test_isServerLibrary_dart() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource(
        "/test.dart",
        r'''
library lib;

main() {}''');
    expect(_context.isClientLibrary(source), isFalse);
    expect(_context.isServerLibrary(source), isFalse);
    _context.computeLibraryElement(source);
    expect(_context.isClientLibrary(source), isFalse);
    expect(_context.isServerLibrary(source), isTrue);
  }

  void test_isServerLibrary_html() {
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.isServerLibrary(source), isFalse);
  }

  void test_parseCompilationUnit_errors() {
    Source source = _addSource("/lib.dart", "library {");
    CompilationUnit compilationUnit = _context.parseCompilationUnit(source);
    expect(compilationUnit, isNotNull);
    List<AnalysisError> errors = _context.getErrors(source).errors;
    expect(errors, isNotNull);
    expect(errors.length > 0, isTrue);
  }

  void test_parseCompilationUnit_exception() {
    Source source = _addSourceWithException("/test.dart");
    try {
      _context.parseCompilationUnit(source);
      fail("Expected AnalysisException");
    } on AnalysisException catch (exception) {
      // Expected
    }
  }

  void test_parseCompilationUnit_html() {
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.parseCompilationUnit(source), isNull);
  }

  void test_parseCompilationUnit_noErrors() {
    Source source = _addSource("/lib.dart", "library lib;");
    CompilationUnit compilationUnit = _context.parseCompilationUnit(source);
    expect(compilationUnit, isNotNull);
    expect(_context.getErrors(source).errors, hasLength(0));
  }

  void test_parseCompilationUnit_nonExistentSource() {
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    try {
      _context.parseCompilationUnit(source);
      fail("Expected AnalysisException because file does not exist");
    } on AnalysisException catch (exception) {
      // Expected result
    }
  }

  void test_parseHtmlUnit_noErrors() {
    Source source = _addSource("/lib.html", "<html></html>");
    ht.HtmlUnit unit = _context.parseHtmlUnit(source);
    expect(unit, isNotNull);
  }

  void test_parseHtmlUnit_resolveDirectives() {
    Source libSource = _addSource(
        "/lib.dart",
        r'''
library lib;
class ClassA {}''');
    Source source = _addSource(
        "/lib.html",
        r'''
<html>
<head>
  <script type='application/dart'>
    import 'lib.dart';
    ClassA v = null;
  </script>
</head>
<body>
</body>
</html>''');
    ht.HtmlUnit unit = _context.parseHtmlUnit(source);
    // import directive should be resolved
    ht.XmlTagNode htmlNode = unit.tagNodes[0];
    ht.XmlTagNode headNode = htmlNode.tagNodes[0];
    ht.HtmlScriptTagNode scriptNode = headNode.tagNodes[0];
    CompilationUnit script = scriptNode.script;
    ImportDirective importNode = script.directives[0] as ImportDirective;
    expect(importNode.uriContent, isNotNull);
    expect(importNode.source, libSource);
  }

  void test_performAnalysisTask_IOException() {
    TestSource source = _addSourceWithException2("/test.dart", "library test;");
    int oldTimestamp = _context.getModificationStamp(source);
    source.generateExceptionOnRead = false;
    _analyzeAll_assertFinished();
    expect(source.readCount, 1);
    source.generateExceptionOnRead = true;
    do {
      _changeSource(source, "");
      // Ensure that the timestamp differs,
      // so that analysis engine notices the change
    } while (oldTimestamp == _context.getModificationStamp(source));
    _analyzeAll_assertFinished();
    expect(source.readCount, 2);
  }

  void test_performAnalysisTask_addPart() {
    Source libSource = _addSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';''');
    // run all tasks without part
    _analyzeAll_assertFinished();
    // add part and run all tasks
    Source partSource =
        _addSource("/part.dart", r'''
part of lib;
''');
    _analyzeAll_assertFinished();
    // "libSource" should be here
    List<Source> librariesWithPart =
        _context.getLibrariesContaining(partSource);
    expect(librariesWithPart, unorderedEquals([libSource]));
  }

  void test_performAnalysisTask_changeLibraryContents() {
    Source libSource =
        _addSource("/test.dart", "library lib; part 'test-part.dart';");
    Source partSource = _addSource("/test-part.dart", "part of lib;");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 1");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNotNull, reason: "part resolved 1");
    // update and analyze #1
    _context.setContents(libSource, "library lib;");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull, reason: "library changed 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part resolved 2");
    // update and analyze #2
    _context.setContents(libSource, "library lib; part 'test-part.dart';");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull, reason: "library changed 3");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part changed 3");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNotNull, reason: "part resolved 3");
  }

  void test_performAnalysisTask_changeLibraryThenPartContents() {
    Source libSource =
        _addSource("/test.dart", "library lib; part 'test-part.dart';");
    Source partSource = _addSource("/test-part.dart", "part of lib;");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 1");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNotNull, reason: "part resolved 1");
    // update and analyze #1
    _context.setContents(libSource, "library lib;");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull, reason: "library changed 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part resolved 2");
    // update and analyze #2
    _context.setContents(partSource, "part of lib; // 1");
    // Assert that changing the part's content does not effect the library
    // now that it is no longer part of that library
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library changed 3");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part changed 3");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 3");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part resolved 3");
  }

  void test_performAnalysisTask_changePartContents_makeItAPart() {
    Source libSource = _addSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';
void f(x) {}''');
    Source partSource = _addSource(
        "/part.dart",
        "void g() { f(null); }");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 1");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNotNull, reason: "part resolved 1");
    // update and analyze
    _context.setContents(
        partSource,
        r'''
part of lib;
void g() { f(null); }''');
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull, reason: "library changed 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNotNull, reason: "part resolved 2");
    expect(_context.getErrors(libSource).errors, hasLength(0));
    expect(_context.getErrors(partSource).errors, hasLength(0));
  }

  /**
   * https://code.google.com/p/dart/issues/detail?id=12424
   */
  void test_performAnalysisTask_changePartContents_makeItNotPart() {
    Source libSource = _addSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';
void f(x) {}''');
    Source partSource = _addSource(
        "/part.dart",
        r'''
part of lib;
void g() { f(null); }''');
    _analyzeAll_assertFinished();
    expect(_context.getErrors(libSource).errors, hasLength(0));
    expect(_context.getErrors(partSource).errors, hasLength(0));
    // Remove 'part' directive, which should make "f(null)" an error.
    _context.setContents(
        partSource,
        r'''
//part of lib;
void g() { f(null); }''');
    _analyzeAll_assertFinished();
    expect(_context.getErrors(libSource).errors.length != 0, isTrue);
  }

  void test_performAnalysisTask_changePartContents_noSemanticChanges() {
    Source libSource =
        _addSource("/test.dart", "library lib; part 'test-part.dart';");
    Source partSource = _addSource("/test-part.dart", "part of lib;");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 1");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNotNull, reason: "part resolved 1");
    // update and analyze #1
    _context.setContents(partSource, "part of lib; // 1");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull, reason: "library changed 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNotNull, reason: "part resolved 2");
    // update and analyze #2
    _context.setContents(partSource, "part of lib; // 12");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull, reason: "library changed 3");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull, reason: "part changed 3");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNotNull, reason: "library resolved 3");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNotNull, reason: "part resolved 3");
  }

  void test_performAnalysisTask_importedLibraryAdd() {
    Source libASource =
        _addSource("/libA.dart", "library libA; import 'libB.dart';");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libASource, libASource), isNotNull, reason: "libA resolved 1");
    expect(_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)), isTrue, reason: "libA has an error");
    // add libB.dart and analyze
    Source libBSource = _addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libASource, libASource), isNotNull, reason: "libA resolved 2");
    expect(_context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull, reason: "libB resolved 2");
    expect(!_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)), isTrue, reason: "libA doesn't have errors");
  }

  void test_performAnalysisTask_importedLibraryAdd_html() {
    Source htmlSource = _addSource(
        "/page.html",
        r'''
<html><body><script type="application/dart">
  import '/libB.dart';
  main() {print('hello dart');}
</script></body></html>''');
    _analyzeAll_assertFinished();
    expect(_context.getResolvedHtmlUnit(htmlSource), isNotNull, reason: "htmlUnit resolved 1");
    expect(_hasAnalysisErrorWithErrorSeverity(_context.getErrors(htmlSource)), isTrue, reason: "htmlSource has an error");
    // add libB.dart and analyze
    Source libBSource = _addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedHtmlUnit(htmlSource), isNotNull, reason: "htmlUnit resolved 1");
    expect(_context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull, reason: "libB resolved 2");
    AnalysisErrorInfo errors = _context.getErrors(htmlSource);
    expect(!_hasAnalysisErrorWithErrorSeverity(errors), isTrue, reason: "htmlSource doesn't have errors");
  }

  void test_performAnalysisTask_importedLibraryDelete() {
    Source libASource =
        _addSource("/libA.dart", "library libA; import 'libB.dart';");
    Source libBSource = _addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libASource, libASource), isNotNull, reason: "libA resolved 1");
    expect(_context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull, reason: "libB resolved 1");
    expect(!_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)), isTrue, reason: "libA doesn't have errors");
    // remove libB.dart content and analyze
    _context.setContents(libBSource, null);
    _analyzeAll_assertFinished();
    expect(_context.getResolvedCompilationUnit2(libASource, libASource), isNotNull, reason: "libA resolved 2");
    expect(_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)), isTrue, reason: "libA has an error");
  }

  void test_performAnalysisTask_missingPart() {
    Source source =
        _addSource("/test.dart", "library lib; part 'no-such-file.dart';");
    _analyzeAll_assertFinished();
    expect(_context.getLibraryElement(source), isNotNull, reason: "performAnalysisTask failed to compute an element model");
  }

  void test_performAnalysisTask_modifiedAfterParse() {
    // TODO(scheglov) no threads in Dart
//    Source source = _addSource("/test.dart", "library lib;");
//    int initialTime = _context.getModificationStamp(source);
//    List<Source> sources = new List<Source>();
//    sources.add(source);
//    _context.analysisPriorityOrder = sources;
//    _context.parseCompilationUnit(source);
//    while (initialTime == JavaSystem.currentTimeMillis()) {
//      Thread.sleep(1);
//      // Force the modification time to be different.
//    }
//    _context.setContents(source, "library test;");
//    JUnitTestCase.assertTrue(initialTime != _context.getModificationStamp(source));
//    _analyzeAll_assertFinished();
//    JUnitTestCase.assertNotNullMsg("performAnalysisTask failed to compute an element model", _context.getLibraryElement(source));
  }

  void test_resolveCompilationUnit_import_relative() {
    _context = AnalysisContextFactory.contextWithCore();
    Source sourceA =
        _addSource("/libA.dart", "library libA; import 'libB.dart'; class A{}");
    _addSource("/libB.dart", "library libB; class B{}");
    CompilationUnit compilationUnit =
        _context.resolveCompilationUnit2(sourceA, sourceA);
    LibraryElement library = compilationUnit.element.library;
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core", "libB"]);
    List<LibraryElement> visibleLibraries = library.visibleLibraries;
    assertNamedElements(visibleLibraries, ["dart.core", "libA", "libB"]);
  }

  void test_resolveCompilationUnit_import_relative_cyclic() {
    _context = AnalysisContextFactory.contextWithCore();
    Source sourceA =
        _addSource("/libA.dart", "library libA; import 'libB.dart'; class A{}");
    _addSource("/libB.dart", "library libB; import 'libA.dart'; class B{}");
    CompilationUnit compilationUnit =
        _context.resolveCompilationUnit2(sourceA, sourceA);
    LibraryElement library = compilationUnit.element.library;
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core", "libB"]);
    List<LibraryElement> visibleLibraries = library.visibleLibraries;
    assertNamedElements(visibleLibraries, ["dart.core", "libA", "libB"]);
  }

  void test_resolveCompilationUnit_library() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    LibraryElement library = _context.computeLibraryElement(source);
    CompilationUnit compilationUnit =
        _context.resolveCompilationUnit(source, library);
    expect(compilationUnit, isNotNull);
    expect(compilationUnit.element, isNotNull);
  }

  void test_resolveCompilationUnit_source() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    CompilationUnit compilationUnit =
        _context.resolveCompilationUnit2(source, source);
    expect(compilationUnit, isNotNull);
  }

  void test_resolveCompilationUnit_sourceChangeDuringResolution() {
    _context = new _AnalysisContext_sourceChangeDuringResolution();
    AnalysisContextFactory.initContextWithCore(_context);
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    CompilationUnit compilationUnit =
        _context.resolveCompilationUnit2(source, source);
    expect(compilationUnit, isNotNull);
    expect(_context.getLineInfo(source), isNotNull);
  }

  void test_resolveHtmlUnit() {
    Source source = _addSource("/lib.html", "<html></html>");
    ht.HtmlUnit unit = _context.resolveHtmlUnit(source);
    expect(unit, isNotNull);
  }

  void test_setAnalysisOptions() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.cacheSize = 42;
    options.dart2jsHint = false;
    options.hint = false;
    _context.analysisOptions = options;
    AnalysisOptions result = _context.analysisOptions;
    expect(result.cacheSize, options.cacheSize);
    expect(result.dart2jsHint, options.dart2jsHint);
    expect(result.hint, options.hint);
  }

  void test_setAnalysisOptions_reduceAnalysisPriorityOrder() {
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.con1(_context.analysisOptions);
    List<Source> sources = new List<Source>();
    for (int index = 0; index < options.cacheSize; index++) {
      sources.add(_addSource("/lib.dart$index", ""));
    }
    _context.analysisPriorityOrder = sources;
    int oldPriorityOrderSize = _getPriorityOrder(_context).length;
    options.cacheSize = options.cacheSize - 10;
    _context.analysisOptions = options;
    expect(oldPriorityOrderSize > _getPriorityOrder(_context).length, isTrue);
  }

  void test_setAnalysisPriorityOrder_empty() {
    _context.analysisPriorityOrder = new List<Source>();
  }

  void test_setAnalysisPriorityOrder_lessThanCacheSize() {
    AnalysisOptions options = _context.analysisOptions;
    List<Source> sources = new List<Source>();
    for (int index = 0; index < options.cacheSize; index++) {
      sources.add(_addSource("/lib.dart$index", ""));
    }
    _context.analysisPriorityOrder = sources;
    expect(options.cacheSize > _getPriorityOrder(_context).length, isTrue);
  }

  void test_setAnalysisPriorityOrder_nonEmpty() {
    List<Source> sources = new List<Source>();
    sources.add(_addSource("/lib.dart", "library lib;"));
    _context.analysisPriorityOrder = sources;
  }

  void test_setChangedContents_libraryWithPart() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.incremental = true;
    _context = AnalysisContextFactory.contextWithCoreAndOptions(options);
    _sourceFactory = _context.sourceFactory;
    String oldCode = r'''
library lib;
part 'part.dart';
int a = 0;''';
    Source librarySource = _addSource("/lib.dart", oldCode);
    Source partSource = _addSource(
        "/part.dart",
        r'''
part of lib;
int b = a;''');
    LibraryElement element = _context.computeLibraryElement(librarySource);
    CompilationUnit unit =
        _context.getResolvedCompilationUnit(librarySource, element);
    expect(unit, isNotNull);
    int offset = oldCode.indexOf("int a") + 4;
    String newCode = r'''
library lib;
part 'part.dart';
int ya = 0;''';
    expect(_getIncrementalAnalysisCache(_context), isNull);
    _context.setChangedContents(librarySource, newCode, offset, 0, 1);
    expect(_context.getContents(librarySource).data, newCode);
    IncrementalAnalysisCache incrementalCache =
        _getIncrementalAnalysisCache(_context);
    expect(incrementalCache.librarySource, librarySource);
    expect(incrementalCache.resolvedUnit, same(unit));
    expect(_context.getResolvedCompilationUnit2(partSource, librarySource), isNull);
    expect(incrementalCache.newContents, newCode);
  }

  void test_setChangedContents_notResolved() {
    _context = AnalysisContextFactory.contextWithCore();
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.con1(_context.analysisOptions);
    options.incremental = true;
    _context.analysisOptions = options;
    _sourceFactory = _context.sourceFactory;
    String oldCode =
        r'''
library lib;
int a = 0;''';
    Source librarySource = _addSource("/lib.dart", oldCode);
    int offset = oldCode.indexOf("int a") + 4;
    String newCode =
        r'''
library lib;
int ya = 0;''';
    _context.setChangedContents(librarySource, newCode, offset, 0, 1);
    expect(_context.getContents(librarySource).data, newCode);
    expect(_getIncrementalAnalysisCache(_context), isNull);
  }

  void test_setContents_libraryWithPart() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source librarySource = _addSource(
        "/lib.dart",
        r'''
library lib;
part 'part.dart';
int a = 0;''');
    Source partSource = _addSource(
        "/part.dart",
        r'''
part of lib;
int b = a;''');
    _context.computeLibraryElement(librarySource);
    IncrementalAnalysisCache incrementalCache = new IncrementalAnalysisCache(
        librarySource,
        librarySource,
        null,
        null,
        null,
        0,
        0,
        0);
    _setIncrementalAnalysisCache(_context, incrementalCache);
    expect(_getIncrementalAnalysisCache(_context), same(incrementalCache));
    _context.setContents(
        librarySource,
        r'''
library lib;
part 'part.dart';
int aa = 0;''');
    expect(_context.getResolvedCompilationUnit2(partSource, librarySource), isNull);
    expect(_getIncrementalAnalysisCache(_context), isNull);
  }

  void test_setContents_null() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source librarySource = _addSource(
        "/lib.dart",
        r'''
library lib;
int a = 0;''');
    _context.computeLibraryElement(librarySource);
    IncrementalAnalysisCache incrementalCache = new IncrementalAnalysisCache(
        librarySource,
        librarySource,
        null,
        null,
        null,
        0,
        0,
        0);
    _setIncrementalAnalysisCache(_context, incrementalCache);
    expect(_getIncrementalAnalysisCache(_context), same(incrementalCache));
    _context.setContents(librarySource, null);
    expect(_context.getResolvedCompilationUnit2(librarySource, librarySource), isNull);
    expect(_getIncrementalAnalysisCache(_context), isNull);
  }

  void test_setSourceFactory() {
    expect(_context.sourceFactory, _sourceFactory);
    SourceFactory factory = new SourceFactory([]);
    _context.sourceFactory = factory;
    expect(_context.sourceFactory, factory);
  }

  void test_unreadableSource() {
    _context = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source test1 = _addSource(
        "/test1.dart",
        r'''
import 'test2.dart';
library test1;''');
    Source test2 = _addSource(
        "/test2.dart",
        r'''
import 'test1.dart';
import 'test3.dart';
library test2;''');
    Source test3 = _addSourceWithException("/test3.dart");
    _analyzeAll_assertFinished();
    // test1 and test2 should have been successfully analyzed
    // despite the fact that test3 couldn't be read.
    expect(_context.computeLibraryElement(test1), isNotNull);
    expect(_context.computeLibraryElement(test2), isNotNull);
    expect(_context.computeLibraryElement(test3), isNull);
  }

  void test_updateAnalysis() {
    expect(_context.sourcesNeedingProcessing.isEmpty, isTrue);
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    AnalysisDelta delta = new AnalysisDelta();
    delta.setAnalysisLevel(source, AnalysisLevel.ALL);
    _context.applyAnalysisDelta(delta);
    expect(_context.sourcesNeedingProcessing.contains(source), isTrue);
    delta = new AnalysisDelta();
    delta.setAnalysisLevel(source, AnalysisLevel.NONE);
    _context.applyAnalysisDelta(delta);
    expect(_context.sourcesNeedingProcessing.contains(source), isFalse);
  }

  void xtest_performAnalysisTask_stress() {
    int maxCacheSize = 4;
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.con1(_context.analysisOptions);
    options.cacheSize = maxCacheSize;
    _context.analysisOptions = options;
    int sourceCount = maxCacheSize + 2;
    List<Source> sources = new List<Source>();
    ChangeSet changeSet = new ChangeSet();
    for (int i = 0; i < sourceCount; i++) {
      Source source = _addSource("/lib$i.dart", "library lib$i;");
      sources.add(source);
      changeSet.addedSource(source);
    }
    _context.applyChanges(changeSet);
    _context.analysisPriorityOrder = sources;
    for (int i = 0; i < 1000; i++) {
      List<ChangeNotice> notice = _context.performAnalysisTask().changeNotices;
      if (notice == null) {
        //System.out.println("test_performAnalysisTask_stress: " + i);
        break;
      }
    }
    List<ChangeNotice> notice = _context.performAnalysisTask().changeNotices;
    if (notice != null) {
      fail("performAnalysisTask failed to terminate after analyzing all sources");
    }
  }

  Source _addSource(String fileName, String contents) {
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile(fileName));
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
    _context.setContents(source, contents);
    return source;
  }

  TestSource _addSourceWithException(String fileName) {
    return _addSourceWithException2(fileName, "");
  }

  TestSource _addSourceWithException2(String fileName, String contents) {
    TestSource source = new TestSource(fileName, contents);
    source.generateExceptionOnRead = true;
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
    return source;
  }

  /**
   * Perform analysis tasks up to 512 times and asserts that that was enough.
   */
  void _analyzeAll_assertFinished() {
    _analyzeAll_assertFinished2(512);
  }

  /**
   * Perform analysis tasks up to the given number of times and asserts that that was enough.
   *
   * @param maxIterations the maximum number of tasks to perform
   */
  void _analyzeAll_assertFinished2(int maxIterations) {
    for (int i = 0; i < maxIterations; i++) {
      List<ChangeNotice> notice = _context.performAnalysisTask().changeNotices;
      if (notice == null) {
        return;
      }
    }
    fail("performAnalysisTask failed to terminate after analyzing all sources");
  }

  void _changeSource(TestSource source, String contents) {
    source.setContents(contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedSource(source);
    _context.applyChanges(changeSet);
  }

  /**
   * Search the given compilation unit for a class with the given name. Return the class with the
   * given name, or `null` if the class cannot be found.
   *
   * @param unit the compilation unit being searched
   * @param className the name of the class being searched for
   * @return the class with the given name
   */
  ClassElement _findClass(CompilationUnitElement unit, String className) {
    for (ClassElement classElement in unit.types) {
      if (classElement.displayName == className) {
        return classElement;
      }
    }
    return null;
  }

  IncrementalAnalysisCache
      _getIncrementalAnalysisCache(AnalysisContextImpl context2) {
    return context2.test_incrementalAnalysisCache;
  }

  List<Source> _getPriorityOrder(AnalysisContextImpl context2) {
    return context2.test_priorityOrder;
  }

  void _removeSource(Source source) {
    ChangeSet changeSet = new ChangeSet();
    changeSet.removedSource(source);
    _context.applyChanges(changeSet);
  }

  void _setIncrementalAnalysisCache(AnalysisContextImpl context,
      IncrementalAnalysisCache incrementalCache) {
    context.test_incrementalAnalysisCache = incrementalCache;
  }

  /**
   * Returns `true` if there is an [AnalysisError] with [ErrorSeverity#ERROR] in
   * the given [AnalysisErrorInfo].
   */
  static bool _hasAnalysisErrorWithErrorSeverity(AnalysisErrorInfo errorInfo) {
    List<AnalysisError> errors = errorInfo.errors;
    for (AnalysisError analysisError in errors) {
      if (analysisError.errorCode.errorSeverity == ErrorSeverity.ERROR) {
        return true;
      }
    }
    return false;
  }
}


class AnalysisContextImplTest_Source_exists_true extends TestSource {
  @override
  bool exists() => true;
}


class AnalysisContextImplTest_Source_getModificationStamp_fromSource extends
    TestSource {
  int stamp;
  AnalysisContextImplTest_Source_getModificationStamp_fromSource(this.stamp);
  @override
  int get modificationStamp => stamp;
}


class AnalysisContextImplTest_Source_getModificationStamp_overridden extends
    TestSource {
  int stamp;
  AnalysisContextImplTest_Source_getModificationStamp_overridden(this.stamp);
  @override
  int get modificationStamp => stamp;
}


class AnalysisOptionsImplTest extends EngineTestCase {
  void test_AnalysisOptionsImpl_copy() {
    bool booleanValue = true;
    for (int i = 0; i < 2; i++, booleanValue = !booleanValue) {
      AnalysisOptionsImpl options = new AnalysisOptionsImpl();
      options.analyzeAngular = booleanValue;
      options.analyzeFunctionBodies = booleanValue;
      options.analyzePolymer = booleanValue;
      options.cacheSize = i;
      options.dart2jsHint = booleanValue;
      options.enableDeferredLoading = booleanValue;
      options.generateSdkErrors = booleanValue;
      options.hint = booleanValue;
      options.incremental = booleanValue;
      options.preserveComments = booleanValue;
      AnalysisOptionsImpl copy = new AnalysisOptionsImpl.con1(options);
      expect(copy.analyzeAngular, options.analyzeAngular);
      expect(copy.analyzeFunctionBodies, options.analyzeFunctionBodies);
      expect(copy.analyzePolymer, options.analyzePolymer);
      expect(copy.cacheSize, options.cacheSize);
      expect(copy.dart2jsHint, options.dart2jsHint);
      expect(copy.enableAsync, options.enableAsync);
      expect(copy.enableDeferredLoading, options.enableDeferredLoading);
      expect(copy.enableEnum, options.enableEnum);
      expect(copy.generateSdkErrors, options.generateSdkErrors);
      expect(copy.hint, options.hint);
      expect(copy.incremental, options.incremental);
      expect(copy.preserveComments, options.preserveComments);
    }
  }

  void test_getAnalyzeAngular() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    bool value = !options.analyzeAngular;
    options.analyzeAngular = value;
    expect(options.analyzeAngular, value);
  }

  void test_getAnalyzeFunctionBodies() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    bool value = !options.analyzeFunctionBodies;
    options.analyzeFunctionBodies = value;
    expect(options.analyzeFunctionBodies, value);
  }

  void test_getAnalyzePolymer() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    bool value = !options.analyzePolymer;
    options.analyzePolymer = value;
    expect(options.analyzePolymer, value);
  }

  void test_getCacheSize() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    expect(options.cacheSize, AnalysisOptionsImpl.DEFAULT_CACHE_SIZE);
    int value = options.cacheSize + 1;
    options.cacheSize = value;
    expect(options.cacheSize, value);
  }

  void test_getDart2jsHint() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    bool value = !options.dart2jsHint;
    options.dart2jsHint = value;
    expect(options.dart2jsHint, value);
  }

  void test_getEnableAsync() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    expect(options.enableAsync, AnalysisOptionsImpl.DEFAULT_ENABLE_ASYNC);
    bool value = !options.enableAsync;
    options.enableAsync = value;
    expect(options.enableAsync, value);
  }

  void test_getEnableDeferredLoading() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    expect(options.enableDeferredLoading, AnalysisOptionsImpl.DEFAULT_ENABLE_DEFERRED_LOADING);
    bool value = !options.enableDeferredLoading;
    options.enableDeferredLoading = value;
    expect(options.enableDeferredLoading, value);
  }

  void test_getEnableEnum() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    expect(options.enableEnum, AnalysisOptionsImpl.DEFAULT_ENABLE_ENUM);
    bool value = !options.enableEnum;
    options.enableEnum = value;
    expect(options.enableEnum, value);
  }

  void test_getGenerateSdkErrors() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    bool value = !options.generateSdkErrors;
    options.generateSdkErrors = value;
    expect(options.generateSdkErrors, value);
  }

  void test_getHint() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    bool value = !options.hint;
    options.hint = value;
    expect(options.hint, value);
  }

  void test_getIncremental() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    bool value = !options.incremental;
    options.incremental = value;
    expect(options.incremental, value);
  }

  void test_getPreserveComments() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    bool value = !options.preserveComments;
    options.preserveComments = value;
    expect(options.preserveComments, value);
  }
}


class AnalysisTaskTest extends EngineTestCase {
  void test_perform_exception() {
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    AnalysisTask task = new AnalysisTask_test_perform_exception(context);
    task.perform(new TestTaskVisitor<Object>());
  }
}


class AnalysisTask_test_perform_exception extends AnalysisTask {
  AnalysisTask_test_perform_exception(InternalAnalysisContext arg0)
      : super(arg0);
  @override
  String get taskDescription => null;
  @override
  accept(AnalysisTaskVisitor visitor) {
    expect(exception, isNotNull);
    return null;
  }
  @override
  void internalPerform() {
    throw new AnalysisException("Forced exception");
  }
}


class CompilationUnitMock extends TypedMock implements CompilationUnit {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class DartEntryTest extends EngineTestCase {
  void test_allErrors() {
    Source source = new TestSource();
    DartEntry entry = new DartEntry();
    expect(entry.allErrors, hasLength(0));
    entry.setValue(
        DartEntry.SCAN_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(
                source,
                ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
                [])]);
    entry.setValue(
        DartEntry.PARSE_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(source, ParserErrorCode.ABSTRACT_CLASS_MEMBER, [])]);
    entry.setValueInLibrary(
        DartEntry.RESOLUTION_ERRORS,
        source,
        <AnalysisError>[
            new AnalysisError.con1(
                source,
                CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION,
                [])]);
    entry.setValueInLibrary(
        DartEntry.VERIFICATION_ERRORS,
        source,
        <AnalysisError>[
            new AnalysisError.con1(
                source,
                StaticWarningCode.CASE_BLOCK_NOT_TERMINATED,
                [])]);
    entry.setValueInLibrary(
        DartEntry.ANGULAR_ERRORS,
        source,
        <AnalysisError>[new AnalysisError.con1(source, AngularCode.MISSING_NAME, [])]);
    entry.setValueInLibrary(
        DartEntry.HINTS,
        source,
        <AnalysisError>[new AnalysisError.con1(source, HintCode.DEAD_CODE, [])]);
    expect(entry.allErrors, hasLength(5));
  }

  void test_creation() {
    Source librarySource = new TestSource();
    DartEntry entry = new DartEntry();
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.INVALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.INVALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, librarySource), same(CacheState.INVALID));
  }

  void test_getResolvableCompilationUnit_none() {
    DartEntry entry = new DartEntry();
    expect(entry.resolvableCompilationUnit, isNull);
  }

  void test_getResolvableCompilationUnit_parsed_accessed() {
    Source librarySource = new TestSource("/lib.dart");
    String importUri = "/f1.dart";
    Source importSource = new TestSource(importUri);
    ImportDirective importDirective =
        AstFactory.importDirective3(importUri, null, []);
    importDirective.source = importSource;
    importDirective.uriContent = importUri;
    String exportUri = "/f2.dart";
    Source exportSource = new TestSource(exportUri);
    ExportDirective exportDirective =
        AstFactory.exportDirective2(exportUri, []);
    exportDirective.source = exportSource;
    exportDirective.uriContent = exportUri;
    String partUri = "/f3.dart";
    Source partSource = new TestSource(partUri);
    PartDirective partDirective = AstFactory.partDirective2(partUri);
    partDirective.source = partSource;
    partDirective.uriContent = partUri;
    CompilationUnit unit =
        AstFactory.compilationUnit3([importDirective, exportDirective, partDirective]);
    DartEntry entry = new DartEntry();
    entry.setValue(DartEntry.PARSED_UNIT, unit);
    entry.getValue(DartEntry.PARSED_UNIT);
    CompilationUnit result = entry.resolvableCompilationUnit;
    expect(result, same(unit));
    entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, librarySource, unit);
    result = entry.resolvableCompilationUnit;
    expect(result, isNot(same(unit)));
    NodeList<Directive> directives = result.directives;
    ImportDirective resultImportDirective = directives[0] as ImportDirective;
    expect(resultImportDirective.uriContent, importUri);
    expect(resultImportDirective.source, same(importSource));
    ExportDirective resultExportDirective = directives[1] as ExportDirective;
    expect(resultExportDirective.uriContent, exportUri);
    expect(resultExportDirective.source, same(exportSource));
    PartDirective resultPartDirective = directives[2] as PartDirective;
    expect(resultPartDirective.uriContent, partUri);
    expect(resultPartDirective.source, same(partSource));
  }

  void test_getResolvableCompilationUnit_parsed_notAccessed() {
    CompilationUnit unit = AstFactory.compilationUnit();
    DartEntry entry = new DartEntry();
    entry.setValue(DartEntry.PARSED_UNIT, unit);
    expect(entry.resolvableCompilationUnit, same(unit));
  }

  void test_getResolvableCompilationUnit_resolved() {
    String importUri = "f1.dart";
    Source importSource = new TestSource(importUri);
    ImportDirective importDirective =
        AstFactory.importDirective3(importUri, null, []);
    importDirective.source = importSource;
    importDirective.uriContent = importUri;
    String exportUri = "f2.dart";
    Source exportSource = new TestSource(exportUri);
    ExportDirective exportDirective =
        AstFactory.exportDirective2(exportUri, []);
    exportDirective.source = exportSource;
    exportDirective.uriContent = exportUri;
    String partUri = "f3.dart";
    Source partSource = new TestSource(partUri);
    PartDirective partDirective = AstFactory.partDirective2(partUri);
    partDirective.source = partSource;
    partDirective.uriContent = partUri;
    CompilationUnit unit =
        AstFactory.compilationUnit3([importDirective, exportDirective, partDirective]);
    DartEntry entry = new DartEntry();
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        new TestSource("lib.dart"),
        unit);
    CompilationUnit result = entry.resolvableCompilationUnit;
    expect(result, isNot(same(unit)));
    NodeList<Directive> directives = result.directives;
    ImportDirective resultImportDirective = directives[0] as ImportDirective;
    expect(resultImportDirective.uriContent, importUri);
    expect(resultImportDirective.source, same(importSource));
    ExportDirective resultExportDirective = directives[1] as ExportDirective;
    expect(resultExportDirective.uriContent, exportUri);
    expect(resultExportDirective.source, same(exportSource));
    PartDirective resultPartDirective = directives[2] as PartDirective;
    expect(resultPartDirective.uriContent, partUri);
    expect(resultPartDirective.source, same(partSource));
  }

  void test_getStateInLibrary_invalid_element() {
    DartEntry entry = new DartEntry();
    try {
      entry.getStateInLibrary(DartEntry.ELEMENT, new TestSource());
      fail("Expected IllegalArgumentException for ELEMENT");
    } on ArgumentError catch (exception) {
      // Expected
    }
  }

  void test_getState_invalid_resolutionErrors() {
    DartEntry entry = new DartEntry();
    try {
      entry.getState(DartEntry.RESOLUTION_ERRORS);
      fail("Expected IllegalArgumentException for RESOLUTION_ERRORS");
    } on ArgumentError catch (exception) {
      // Expected
    }
  }

  void test_getState_invalid_verificationErrors() {
    DartEntry entry = new DartEntry();
    try {
      entry.getState(DartEntry.VERIFICATION_ERRORS);
      fail("Expected IllegalArgumentException for VERIFICATION_ERRORS");
    } on ArgumentError catch (exception) {
      // Expected
    }
  }

  void test_getValue_containingLibraries() {
    Source testSource = new TestSource();
    DartEntry entry = new DartEntry();
    List<Source> value = entry.containingLibraries;
    expect(value, hasLength(0));
    entry.addContainingLibrary(testSource);
    value = entry.containingLibraries;
    expect(value, hasLength(1));
    expect(value[0], testSource);
    entry.removeContainingLibrary(testSource);
    value = entry.containingLibraries;
    expect(value, hasLength(0));
  }

  void test_getValueInLibrary_invalid_element() {
    DartEntry entry = new DartEntry();
    try {
      entry.getValueInLibrary(DartEntry.ELEMENT, new TestSource());
      fail("Expected IllegalArgumentException for ELEMENT");
    } on ArgumentError catch (exception) {
      // Expected
    }
  }

  void test_getValueInLibrary_invalid_resolutionErrors_multiple() {
    Source source1 = new TestSource();
    Source source2 = new TestSource();
    Source source3 = new TestSource();
    DartEntry entry = new DartEntry();
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source1,
        AstFactory.compilationUnit());
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source2,
        AstFactory.compilationUnit());
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source3,
        AstFactory.compilationUnit());
    try {
      entry.getValueInLibrary(DartEntry.ELEMENT, source3);
      fail("Expected IllegalArgumentException for ELEMENT");
    } on ArgumentError catch (exception) {
      // Expected
    }
  }

  void test_getValue_invalid_resolutionErrors() {
    DartEntry entry = new DartEntry();
    try {
      entry.getValue(DartEntry.RESOLUTION_ERRORS);
      fail("Expected IllegalArgumentException for RESOLUTION_ERRORS");
    } on ArgumentError catch (exception) {
    }
  }

  void test_getValue_invalid_verificationErrors() {
    DartEntry entry = new DartEntry();
    try {
      entry.getValue(DartEntry.VERIFICATION_ERRORS);
      fail("Expected IllegalArgumentException for VERIFICATION_ERRORS");
    } on ArgumentError catch (exception) {
      // Expected
    }
  }

  void test_hasInvalidData_false() {
    DartEntry entry = new DartEntry();
    entry.recordScanError(new CaughtException(new AnalysisException(), null));
    expect(entry.hasInvalidData(DartEntry.ELEMENT), isFalse);
    expect(entry.hasInvalidData(DartEntry.EXPORTED_LIBRARIES), isFalse);
    expect(entry.hasInvalidData(DartEntry.HINTS), isFalse);
    expect(entry.hasInvalidData(DartEntry.IMPORTED_LIBRARIES), isFalse);
    expect(entry.hasInvalidData(DartEntry.INCLUDED_PARTS), isFalse);
    expect(entry.hasInvalidData(DartEntry.IS_CLIENT), isFalse);
    expect(entry.hasInvalidData(DartEntry.IS_LAUNCHABLE), isFalse);
    expect(entry.hasInvalidData(SourceEntry.LINE_INFO), isFalse);
    expect(entry.hasInvalidData(DartEntry.PARSE_ERRORS), isFalse);
    expect(entry.hasInvalidData(DartEntry.PARSED_UNIT), isFalse);
    expect(entry.hasInvalidData(DartEntry.PUBLIC_NAMESPACE), isFalse);
    expect(entry.hasInvalidData(DartEntry.SOURCE_KIND), isFalse);
    expect(entry.hasInvalidData(DartEntry.RESOLUTION_ERRORS), isFalse);
    expect(entry.hasInvalidData(DartEntry.RESOLVED_UNIT), isFalse);
    expect(entry.hasInvalidData(DartEntry.VERIFICATION_ERRORS), isFalse);
  }

  void test_hasInvalidData_true() {
    DartEntry entry = new DartEntry();
    expect(entry.hasInvalidData(DartEntry.ELEMENT), isTrue);
    expect(entry.hasInvalidData(DartEntry.EXPORTED_LIBRARIES), isTrue);
    expect(entry.hasInvalidData(DartEntry.HINTS), isTrue);
    expect(entry.hasInvalidData(DartEntry.IMPORTED_LIBRARIES), isTrue);
    expect(entry.hasInvalidData(DartEntry.INCLUDED_PARTS), isTrue);
    expect(entry.hasInvalidData(DartEntry.IS_CLIENT), isTrue);
    expect(entry.hasInvalidData(DartEntry.IS_LAUNCHABLE), isTrue);
    expect(entry.hasInvalidData(SourceEntry.LINE_INFO), isTrue);
    expect(entry.hasInvalidData(DartEntry.PARSE_ERRORS), isTrue);
    expect(entry.hasInvalidData(DartEntry.PARSED_UNIT), isTrue);
    expect(entry.hasInvalidData(DartEntry.PUBLIC_NAMESPACE), isTrue);
    expect(entry.hasInvalidData(DartEntry.SOURCE_KIND), isTrue);
    expect(entry.hasInvalidData(DartEntry.RESOLUTION_ERRORS), isTrue);
    expect(entry.hasInvalidData(DartEntry.RESOLVED_UNIT), isTrue);
    expect(entry.hasInvalidData(DartEntry.VERIFICATION_ERRORS), isTrue);
  }

  void test_invalidateAllInformation() {
    Source librarySource = new TestSource();
    DartEntry entry = _entryWithValidState(librarySource);
    entry.invalidateAllInformation();
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.INVALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.INVALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, librarySource), same(CacheState.INVALID));
  }

  void test_invalidateAllResolutionInformation() {
    Source librarySource = new TestSource();
    DartEntry entry = _entryWithValidState(librarySource);
    entry.invalidateAllResolutionInformation(false);
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.VALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.VALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, librarySource), same(CacheState.INVALID));
  }

  void test_invalidateAllResolutionInformation_includingUris() {
    Source librarySource = new TestSource();
    DartEntry entry = _entryWithValidState(librarySource);
    entry.invalidateAllResolutionInformation(true);
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.INVALID));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.VALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.VALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, librarySource), same(CacheState.INVALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, librarySource), same(CacheState.INVALID));
  }

  void test_isClient() {
    DartEntry entry = new DartEntry();
    // true
    entry.setValue(DartEntry.IS_CLIENT, true);
    expect(entry.getValue(DartEntry.IS_CLIENT), isTrue);
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.VALID));
    // invalidate
    entry.setState(DartEntry.IS_CLIENT, CacheState.INVALID);
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.INVALID));
    // false
    entry.setValue(DartEntry.IS_CLIENT, false);
    expect(entry.getValue(DartEntry.IS_CLIENT), isFalse);
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.VALID));
  }

  void test_isLaunchable() {
    DartEntry entry = new DartEntry();
    // true
    entry.setValue(DartEntry.IS_LAUNCHABLE, true);
    expect(entry.getValue(DartEntry.IS_LAUNCHABLE), isTrue);
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.VALID));
    // invalidate
    entry.setState(DartEntry.IS_LAUNCHABLE, CacheState.INVALID);
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.INVALID));
    // false
    entry.setValue(DartEntry.IS_LAUNCHABLE, false);
    expect(entry.getValue(DartEntry.IS_LAUNCHABLE), isFalse);
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.VALID));
  }

  void test_recordBuildElementError() {
    Source firstLibrary = new TestSource('first.dart');
    Source secondLibrary = new TestSource('second.dart');
    DartEntry entry = _entryWithValidState(firstLibrary, secondLibrary);
    entry.recordBuildElementErrorInLibrary(
        firstLibrary,
        new CaughtException(new AnalysisException(), null));
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.VALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.VALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.HINTS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary), same(CacheState.ERROR));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary), same(CacheState.VALID));
  }

  void test_recordContentError() {
    Source firstLibrary = new TestSource('first.dart');
//    Source secondLibrary = new TestSource('second.dart');
    DartEntry entry = _entryWithValidState(firstLibrary);
    entry.recordContentError(
        new CaughtException(new AnalysisException(), null));
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.ERROR));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.ERROR));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.HINTS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary), same(CacheState.ERROR));

    // The following lines are commented out because we don't currently have
    // any way of setting the state for data associated with a library we
    // don't know anything about.
//    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.HINTS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary), same(CacheState.ERROR));
  }

  void test_recordHintErrorInLibrary() {
    Source firstLibrary = new TestSource('first.dart');
    Source secondLibrary = new TestSource('second.dart');
    DartEntry entry = _entryWithValidState(firstLibrary, secondLibrary);
    entry.recordHintErrorInLibrary(
        firstLibrary,
        new CaughtException(new AnalysisException(), null));
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.VALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.VALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary), same(CacheState.VALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary), same(CacheState.VALID));
  }

  void test_recordParseError() {
    Source firstLibrary = new TestSource('first.dart');
//    Source secondLibrary = new TestSource('second.dart');
    DartEntry entry = _entryWithValidState(firstLibrary);
    entry.recordParseError(new CaughtException(new AnalysisException(), null));
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.VALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.HINTS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary), same(CacheState.ERROR));

    // The following lines are commented out because we don't currently have
    // any way of setting the state for data associated with a library we
    // don't know anything about.
//    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.HINTS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary), same(CacheState.ERROR));
  }

  void test_recordResolutionError() {
    Source firstLibrary = new TestSource('first.dart');
//    Source secondLibrary = new TestSource('second.dart');
    DartEntry entry = _entryWithValidState(firstLibrary);
    entry.recordResolutionError(
        new CaughtException(new AnalysisException(), null));
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.VALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.VALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.HINTS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary), same(CacheState.ERROR));

    // The following lines are commented out because we don't currently have
    // any way of setting the state for data associated with a library we
    // don't know anything about.
//    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.HINTS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary), same(CacheState.ERROR));
  }

  void test_recordResolutionErrorInLibrary() {
    Source firstLibrary = new TestSource('first.dart');
    Source secondLibrary = new TestSource('second.dart');
    DartEntry entry = _entryWithValidState(firstLibrary, secondLibrary);
    entry.recordResolutionErrorInLibrary(
        firstLibrary,
        new CaughtException(new AnalysisException(), null));
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.VALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.VALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary), same(CacheState.ERROR));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary), same(CacheState.VALID));
  }

  void test_recordScanError() {
    Source firstLibrary = new TestSource('first.dart');
//    Source secondLibrary = new TestSource('second.dart');
    DartEntry entry = _entryWithValidState(firstLibrary);
    entry.recordScanError(new CaughtException(new AnalysisException(), null));
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.ERROR));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.ERROR));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.HINTS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary), same(CacheState.ERROR));

    // The following lines are commented out because we don't currently have
    // any way of setting the state for data associated with a library we
    // don't know anything about.
//    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.HINTS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary), same(CacheState.ERROR));
//    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary), same(CacheState.ERROR));
  }

  void test_recordVerificationErrorInLibrary() {
    Source firstLibrary = new TestSource('first.dart');
    Source secondLibrary = new TestSource('second.dart');
    DartEntry entry = _entryWithValidState(firstLibrary, secondLibrary);
    entry.recordVerificationErrorInLibrary(
        firstLibrary,
        new CaughtException(new AnalysisException(), null));
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.VALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.VALID));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, firstLibrary), same(CacheState.ERROR));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary), same(CacheState.ERROR));

    expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.HINTS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary), same(CacheState.VALID));
    expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary), same(CacheState.VALID));
  }

  void test_removeResolution_multiple_first() {
    Source source1 = new TestSource('first.dart');
    Source source2 = new TestSource('second.dart');
    Source source3 = new TestSource('third.dart');
    DartEntry entry = new DartEntry();
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source1,
        AstFactory.compilationUnit());
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source2,
        AstFactory.compilationUnit());
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source3,
        AstFactory.compilationUnit());
    entry.removeResolution(source1);
  }

  void test_removeResolution_multiple_last() {
    Source source1 = new TestSource('first.dart');
    Source source2 = new TestSource('second.dart');
    Source source3 = new TestSource('third.dart');
    DartEntry entry = new DartEntry();
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source1,
        AstFactory.compilationUnit());
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source2,
        AstFactory.compilationUnit());
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source3,
        AstFactory.compilationUnit());
    entry.removeResolution(source3);
  }

  void test_removeResolution_multiple_middle() {
    Source source1 = new TestSource('first.dart');
    Source source2 = new TestSource('second.dart');
    Source source3 = new TestSource('third.dart');
    DartEntry entry = new DartEntry();
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source1,
        AstFactory.compilationUnit());
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source2,
        AstFactory.compilationUnit());
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source3,
        AstFactory.compilationUnit());
    entry.removeResolution(source2);
  }

  void test_removeResolution_single() {
    Source source1 = new TestSource();
    DartEntry entry = new DartEntry();
    entry.setValueInLibrary(
        DartEntry.RESOLVED_UNIT,
        source1,
        AstFactory.compilationUnit());
    entry.removeResolution(source1);
  }

  void test_setState_element() {
    _setState(DartEntry.ELEMENT);
  }

  void test_setState_exportedLibraries() {
    _setState(DartEntry.EXPORTED_LIBRARIES);
  }

  void test_setState_hints() {
    _setStateInLibrary(DartEntry.HINTS);
  }

  void test_setState_importedLibraries() {
    _setState(DartEntry.IMPORTED_LIBRARIES);
  }

  void test_setState_includedParts() {
    _setState(DartEntry.INCLUDED_PARTS);
  }

  void test_setState_invalid_element() {
    DartEntry entry = new DartEntry();
    try {
      entry.setStateInLibrary(DartEntry.ELEMENT, null, CacheState.FLUSHED);
      fail("Expected IllegalArgumentException for ELEMENT");
    } on ArgumentError catch (exception) {
      // Expected
    }
  }

  void test_setState_invalid_resolutionErrors() {
    DartEntry entry = new DartEntry();
    try {
      entry.setState(DartEntry.RESOLUTION_ERRORS, CacheState.FLUSHED);
      fail("Expected IllegalArgumentException for RESOLUTION_ERRORS");
    } on ArgumentError catch (exception) {
      // Expected
    }
  }

  void test_setState_invalid_validState() {
    DartEntry entry = new DartEntry();
    try {
      entry.setState(SourceEntry.LINE_INFO, CacheState.VALID);
      fail("Expected ArgumentError for a state of VALID");
    } on ArgumentError catch (exception) {
    }
  }

  void test_setState_invalid_verificationErrors() {
    DartEntry entry = new DartEntry();
    try {
      entry.setState(DartEntry.VERIFICATION_ERRORS, CacheState.FLUSHED);
      fail("Expected IllegalArgumentException for VERIFICATION_ERRORS");
    } on ArgumentError catch (exception) {
      // Expected
     }
   }

  void test_setState_isClient() {
    _setState(DartEntry.IS_CLIENT);
  }

  void test_setState_isLaunchable() {
    _setState(DartEntry.IS_LAUNCHABLE);
  }

  void test_setState_lineInfo() {
    _setState(SourceEntry.LINE_INFO);
  }

  void test_setState_parseErrors() {
    _setState(DartEntry.PARSE_ERRORS);
  }

  void test_setState_parsedUnit() {
    _setState(DartEntry.PARSED_UNIT);
  }

  void test_setState_publicNamespace() {
    _setState(DartEntry.PUBLIC_NAMESPACE);
  }

  void test_setState_resolutionErrors() {
    _setStateInLibrary(DartEntry.RESOLUTION_ERRORS);
  }

  void test_setState_resolvedUnit() {
    _setStateInLibrary(DartEntry.RESOLVED_UNIT);
  }

  void test_setState_scanErrors() {
    _setState(DartEntry.SCAN_ERRORS);
  }

  void test_setState_sourceKind() {
    _setState(DartEntry.SOURCE_KIND);
  }

  void test_setState_tokenStream() {
    _setState(DartEntry.TOKEN_STREAM);
  }

  void test_setState_verificationErrors() {
    _setStateInLibrary(DartEntry.VERIFICATION_ERRORS);
  }

  void test_setValue_element() {
    _setValue(
        DartEntry.ELEMENT,
        new LibraryElementImpl.forNode(null, AstFactory.libraryIdentifier2(["lib"])));
  }

  void test_setValue_exportedLibraries() {
    _setValue(DartEntry.EXPORTED_LIBRARIES, <Source>[new TestSource()]);
  }

  void test_setValue_hints() {
    _setValueInLibrary(
        DartEntry.HINTS,
        <AnalysisError>[new AnalysisError.con1(null, HintCode.DEAD_CODE, [])]);
  }

  void test_setValue_importedLibraries() {
    _setValue(DartEntry.IMPORTED_LIBRARIES, <Source>[new TestSource()]);
  }

  void test_setValue_includedParts() {
    _setValue(DartEntry.INCLUDED_PARTS, <Source>[new TestSource()]);
  }

  void test_setValue_isClient() {
    _setValue(DartEntry.IS_CLIENT, true);
  }

  void test_setValue_isLaunchable() {
    _setValue(DartEntry.IS_LAUNCHABLE, true);
  }

  void test_setValue_lineInfo() {
    _setValue(SourceEntry.LINE_INFO, new LineInfo(<int>[0]));
  }

  void test_setValue_parseErrors() {
    _setValue(
        DartEntry.PARSE_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(null, ParserErrorCode.ABSTRACT_CLASS_MEMBER, [])]);
  }

  void test_setValue_parsedUnit() {
    _setValue(DartEntry.PARSED_UNIT, AstFactory.compilationUnit());
  }

  void test_setValue_publicNamespace() {
    _setValue(
        DartEntry.PUBLIC_NAMESPACE,
        new Namespace(new HashMap<String, Element>()));
  }

  void test_setValue_resolutionErrors() {
    _setValueInLibrary(
        DartEntry.RESOLUTION_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(
                null,
                CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION,
                [])]);
  }

  void test_setValue_resolvedUnit() {
    _setValueInLibrary(DartEntry.RESOLVED_UNIT, AstFactory.compilationUnit());
  }

  void test_setValue_scanErrors() {
    _setValue(
        DartEntry.SCAN_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(
                null,
                ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT,
                [])]);
  }

  void test_setValue_sourceKind() {
    _setValue(DartEntry.SOURCE_KIND, SourceKind.LIBRARY);
  }

  void test_setValue_tokenStream() {
    _setValue(DartEntry.TOKEN_STREAM, new Token(TokenType.LT, 5));
  }

  void test_setValue_verificationErrors() {
    _setValueInLibrary(
        DartEntry.VERIFICATION_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(null, StaticWarningCode.CASE_BLOCK_NOT_TERMINATED, [])]);
  }

  DartEntry _entryWithValidState([Source firstLibrary, Source secondLibrary]) {
    DartEntry entry = new DartEntry();
    entry.setValue(SourceEntry.CONTENT, null);
    entry.setValue(SourceEntry.LINE_INFO, null);
    entry.setValue(DartEntry.CONTAINING_LIBRARIES, null);
    entry.setValue(DartEntry.ELEMENT, null);
    entry.setValue(DartEntry.EXPORTED_LIBRARIES, null);
    entry.setValue(DartEntry.IMPORTED_LIBRARIES, null);
    entry.setValue(DartEntry.INCLUDED_PARTS, null);
    entry.setValue(DartEntry.IS_CLIENT, null);
    entry.setValue(DartEntry.IS_LAUNCHABLE, null);
    entry.setValue(DartEntry.PARSE_ERRORS, null);
    entry.setValue(DartEntry.PARSED_UNIT, null);
    entry.setValue(DartEntry.PUBLIC_NAMESPACE, null);
    entry.setValue(DartEntry.SCAN_ERRORS, null);
    entry.setValue(DartEntry.SOURCE_KIND, null);
    entry.setValue(DartEntry.TOKEN_STREAM, null);
    if (firstLibrary != null) {
      entry.setValueInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary, null);
      entry.setValueInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary, null);
      entry.setValueInLibrary(DartEntry.BUILT_UNIT, firstLibrary, null);
      entry.setValueInLibrary(DartEntry.HINTS, firstLibrary, null);
      entry.setValueInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary, null);
      entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary, null);
      entry.setValueInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary, null);
    }
    if (secondLibrary != null) {
      entry.setValueInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary, null);
      entry.setValueInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary, null);
      entry.setValueInLibrary(DartEntry.BUILT_UNIT, secondLibrary, null);
      entry.setValueInLibrary(DartEntry.HINTS, secondLibrary, null);
      entry.setValueInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary, null);
      entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary, null);
      entry.setValueInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary, null);
    }
    //
    // Validate that the state was set correctly.
    //
    expect(entry.getState(SourceEntry.CONTENT), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(DartEntry.CONTAINING_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.ELEMENT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.EXPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IMPORTED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(DartEntry.INCLUDED_PARTS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_CLIENT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.IS_LAUNCHABLE), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(DartEntry.PUBLIC_NAMESPACE), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SCAN_ERRORS), same(CacheState.VALID));
    expect(entry.getState(DartEntry.SOURCE_KIND), same(CacheState.VALID));
    expect(entry.getState(DartEntry.TOKEN_STREAM), same(CacheState.VALID));
    if (firstLibrary != null) {
      expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, firstLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, firstLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, firstLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.HINTS, firstLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, firstLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, firstLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, firstLibrary), same(CacheState.VALID));
    }
    if (secondLibrary != null) {
      expect(entry.getStateInLibrary(DartEntry.ANGULAR_ERRORS, secondLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.BUILT_ELEMENT, secondLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.BUILT_UNIT, secondLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.HINTS, secondLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, secondLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, secondLibrary), same(CacheState.VALID));
      expect(entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, secondLibrary), same(CacheState.VALID));
    }
    return entry;
  }

  void _setState(DataDescriptor descriptor) {
    DartEntry entry = new DartEntry();
    expect(entry.getState(descriptor), isNot(same(CacheState.FLUSHED)));
    entry.setState(descriptor, CacheState.FLUSHED);
    expect(entry.getState(descriptor), same(CacheState.FLUSHED));
  }

  void _setStateInLibrary(DataDescriptor descriptor) {
    Source source = new TestSource();
    DartEntry entry = new DartEntry();
    expect(entry.getStateInLibrary(descriptor, source), isNot(same(CacheState.FLUSHED)));
    entry.setStateInLibrary(descriptor, source, CacheState.FLUSHED);
    expect(entry.getStateInLibrary(descriptor, source), same(CacheState.FLUSHED));
  }

  void _setValue(DataDescriptor descriptor, Object newValue) {
    DartEntry entry = new DartEntry();
    Object value = entry.getValue(descriptor);
    expect(newValue, isNot(same(value)));
    entry.setValue(descriptor, newValue);
    expect(entry.getState(descriptor), same(CacheState.VALID));
    expect(entry.getValue(descriptor), same(newValue));
  }

  void _setValueInLibrary(DataDescriptor descriptor, Object newValue) {
    Source source = new TestSource();
    DartEntry entry = new DartEntry();
    Object value = entry.getValueInLibrary(descriptor, source);
    expect(newValue, isNot(same(value)));
    entry.setValueInLibrary(descriptor, source, newValue);
    expect(entry.getStateInLibrary(descriptor, source), same(CacheState.VALID));
    expect(entry.getValueInLibrary(descriptor, source), same(newValue));
  }
}


class GenerateDartErrorsTaskTest extends EngineTestCase {
  void test_accept() {
    GenerateDartErrorsTask task =
        new GenerateDartErrorsTask(null, null, null, null);
    expect(task.accept(new GenerateDartErrorsTaskTestTV_accept()), isTrue);
  }

  void test_getException() {
    GenerateDartErrorsTask task =
        new GenerateDartErrorsTask(null, null, null, null);
    expect(task.exception, isNull);
  }

  void test_getLibraryElement() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    LibraryElement element = ElementFactory.library(context, "lib");
    GenerateDartErrorsTask task =
        new GenerateDartErrorsTask(context, null, null, element);
    expect(task.libraryElement, same(element));
  }

  void test_getSource() {
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    GenerateDartErrorsTask task =
        new GenerateDartErrorsTask(null, source, null, null);
    expect(task.source, same(source));
  }

  void test_perform() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    context.setContents(
        source,
        r'''
library lib;
class A {
  int f = new A();
}''');
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnit unit =
        context.getResolvedCompilationUnit(source, libraryElement);
    GenerateDartErrorsTask task = new GenerateDartErrorsTask(
        context,
        source,
        unit,
        libraryElement);
    task.perform(
        new GenerateDartErrorsTaskTestTV_perform(libraryElement, source));
  }

  void test_perform_validateDirectives() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    // TODO(scheglov) "import" causes second error reported
//    context.setContents(source, EngineTestCase.createSource([
//        "library lib;",
//        "import 'invaliduri^.dart';",
//        "export '\${a}lib3.dart';",
//        "part '/does/not/exist.dart';",
//        "class A {}"]));
    context.setContents(
        source,
        r'''
library lib;
part '/does/not/exist.dart';
class A {}''');
    LibraryElement libraryElement = context.computeLibraryElement(source);
    CompilationUnit unit =
        context.getResolvedCompilationUnit(source, libraryElement);
    GenerateDartErrorsTask task = new GenerateDartErrorsTask(
        context,
        source,
        unit,
        libraryElement);
    task.perform(
        new GenerateDartErrorsTaskTestTV_perform_validateDirectives(
            libraryElement,
            source));
  }
}


class GenerateDartErrorsTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitGenerateDartErrorsTask(GenerateDartErrorsTask task) => true;
}


class GenerateDartErrorsTaskTestTV_perform extends TestTaskVisitor<bool> {
  LibraryElement libraryElement;
  Source source;
  GenerateDartErrorsTaskTestTV_perform(this.libraryElement, this.source);
  @override
  bool visitGenerateDartErrorsTask(GenerateDartErrorsTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.libraryElement, same(libraryElement));
    expect(task.source, same(source));
    List<AnalysisError> errors = task.errors;
    expect(errors, hasLength(1));
    return true;
  }
}


class GenerateDartErrorsTaskTestTV_perform_validateDirectives extends
    TestTaskVisitor<bool> {
  LibraryElement libraryElement;
  Source source;
  GenerateDartErrorsTaskTestTV_perform_validateDirectives(this.libraryElement,
      this.source);
  @override
  bool visitGenerateDartErrorsTask(GenerateDartErrorsTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.libraryElement, same(libraryElement));
    expect(task.source, same(source));
    List<AnalysisError> errors = task.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, same(CompileTimeErrorCode.URI_DOES_NOT_EXIST));
    return true;
  }
}

class GenerateDartHintsTaskTest extends EngineTestCase {
  void test_accept() {
    GenerateDartHintsTask task = new GenerateDartHintsTask(null, null, null);
    expect(task.accept(new GenerateDartHintsTaskTestTV_accept()), isTrue);
  }
  void test_getException() {
    GenerateDartHintsTask task = new GenerateDartHintsTask(null, null, null);
    expect(task.exception, isNull);
  }
  void test_getHintMap() {
    GenerateDartHintsTask task = new GenerateDartHintsTask(null, null, null);
    expect(task.hintMap, isNull);
  }
  void test_getLibraryElement() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    LibraryElement element = ElementFactory.library(context, "lib");
    GenerateDartHintsTask task =
        new GenerateDartHintsTask(context, null, element);
    expect(task.libraryElement, same(element));
  }
  void test_perform() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    ChangeSet changeSet = new ChangeSet();
    Source librarySource =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    changeSet.addedSource(librarySource);
    Source unusedSource =
        new FileBasedSource.con1(FileUtilities2.createFile("/unused.dart"));
    changeSet.addedSource(unusedSource);
    Source partSource =
        new FileBasedSource.con1(FileUtilities2.createFile("/part.dart"));
    changeSet.addedSource(partSource);
    context.applyChanges(changeSet);
    context.setContents(
        librarySource,
        r'''
library lib;
import 'unused.dart';
part 'part.dart';''');
    context.setContents(
        unusedSource,
        "library unused;");
    context.setContents(
        partSource,
        "part of lib;");
    List<TimestampedData<CompilationUnit>> units = new List<TimestampedData>(2);
    units[0] = new TimestampedData<CompilationUnit>(
        context.getModificationStamp(librarySource),
        context.resolveCompilationUnit2(librarySource, librarySource));
    units[1] = new TimestampedData<CompilationUnit>(
        context.getModificationStamp(partSource),
        context.resolveCompilationUnit2(partSource, librarySource));
    GenerateDartHintsTask task = new GenerateDartHintsTask(
        context,
        units,
        context.computeLibraryElement(librarySource));
    task.perform(
        new GenerateDartHintsTaskTestTV_perform(librarySource, partSource));
  }
}


class GenerateDartHintsTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitGenerateDartHintsTask(GenerateDartHintsTask task) => true;
}


class GenerateDartHintsTaskTestTV_perform extends TestTaskVisitor<bool> {
  Source librarySource;
  Source partSource;
  GenerateDartHintsTaskTestTV_perform(this.librarySource, this.partSource);
  @override
  bool visitGenerateDartHintsTask(GenerateDartHintsTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.libraryElement, isNotNull);
    HashMap<Source, List<AnalysisError>> hintMap = task.hintMap;
    expect(hintMap, hasLength(2));
    expect(hintMap[librarySource], hasLength(1));
    expect(hintMap[partSource], hasLength(0));
    return true;
  }
}


class GetContentTaskTest extends EngineTestCase {
  void test_accept() {
    Source source = new TestSource('/test.dart', '');
    GetContentTask task = new GetContentTask(null, source);
    expect(task.accept(new GetContentTaskTestTV_accept()), isTrue);
  }

  void test_getException() {
    Source source = new TestSource('/test.dart', '');
    GetContentTask task = new GetContentTask(null, source);
    expect(task.exception, isNull);
  }

  void test_getModificationTime() {
    Source source = new TestSource('/test.dart', '');
    GetContentTask task = new GetContentTask(null, source);
    expect(task.modificationTime, -1);
  }

  void test_getSource() {
    Source source = new TestSource('/test.dart', '');
    GetContentTask task = new GetContentTask(null, source);
    expect(task.source, same(source));
  }

  void test_perform_exception() {
    TestSource source = new TestSource();
    source.generateExceptionOnRead = true;
    //    final InternalAnalysisContext context = new AnalysisContextImpl();
    //    context.setSourceFactory(new SourceFactory(new FileUriResolver()));
    GetContentTask task = new GetContentTask(null, source);
    task.perform(new GetContentTaskTestTV_perform_exception());
  }

  void test_perform_valid() {
    Source source = new TestSource('/test.dart', 'class A {}');
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    GetContentTask task = new GetContentTask(context, source);
    task.perform(new GetContentTaskTestTV_perform_valid(context, source));
  }
}


class GetContentTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitGetContentTask(GetContentTask task) => true;
}


class GetContentTaskTestTV_perform_exception extends TestTaskVisitor<bool> {
  @override
  bool visitGetContentTask(GetContentTask task) {
    expect(task.exception, isNotNull);
    return true;
  }
}


class GetContentTaskTestTV_perform_valid extends TestTaskVisitor<bool> {
  InternalAnalysisContext context;
  Source source;
  GetContentTaskTestTV_perform_valid(this.context, this.source);
  @override
  bool visitGetContentTask(GetContentTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.modificationTime, context.getModificationStamp(source));
    expect(task.source, same(source));
    return true;
  }
}


class HtmlEntryTest extends EngineTestCase {
  void set state(DataDescriptor descriptor) {
    HtmlEntry entry = new HtmlEntry();
    expect(entry.getState(descriptor), isNot(same(CacheState.FLUSHED)));
    entry.setState(descriptor, CacheState.FLUSHED);
    expect(entry.getState(descriptor), same(CacheState.FLUSHED));
  }

  void test_creation() {
    HtmlEntry entry = new HtmlEntry();
    expect(entry, isNotNull);
  }

  void test_getAllErrors() {
    Source source = new TestSource();
    HtmlEntry entry = new HtmlEntry();
    expect(entry.allErrors, hasLength(0));
    entry.setValue(
        HtmlEntry.PARSE_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(source, ParserErrorCode.EXPECTED_TOKEN, [";"])]);
    entry.setValue(
        HtmlEntry.RESOLUTION_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(source, HtmlWarningCode.INVALID_URI, ["-"])]);
    entry.setValue(
        HtmlEntry.ANGULAR_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(source, AngularCode.INVALID_REPEAT_SYNTAX, ["-"])]);
    entry.setValue(
        HtmlEntry.POLYMER_BUILD_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(source, PolymerCode.INVALID_ATTRIBUTE_NAME, ["-"])]);
    entry.setValue(
        HtmlEntry.POLYMER_RESOLUTION_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(source, PolymerCode.INVALID_ATTRIBUTE_NAME, ["-"])]);
    entry.setValue(
        HtmlEntry.HINTS,
        <AnalysisError>[new AnalysisError.con1(source, HintCode.DEAD_CODE, [])]);
    expect(entry.allErrors, hasLength(6));
  }

  void test_invalidateAllResolutionInformation() {
    HtmlEntry entry = _entryWithValidState();
    entry.invalidateAllResolutionInformation(false);
    expect(entry.getState(HtmlEntry.ANGULAR_APPLICATION), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.ANGULAR_COMPONENT), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.ANGULAR_ENTRY), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.ANGULAR_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.POLYMER_BUILD_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.POLYMER_RESOLUTION_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.ELEMENT), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.HINTS), same(CacheState.INVALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.REFERENCED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.RESOLUTION_ERRORS), same(CacheState.INVALID));
  }

  void test_invalidateAllResolutionInformation_includingUris() {
    HtmlEntry entry = _entryWithValidState();
    entry.invalidateAllResolutionInformation(true);
    expect(entry.getState(HtmlEntry.ANGULAR_APPLICATION), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.ANGULAR_COMPONENT), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.ANGULAR_ENTRY), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.ANGULAR_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.POLYMER_BUILD_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.POLYMER_RESOLUTION_ERRORS), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.ELEMENT), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.HINTS), same(CacheState.INVALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.REFERENCED_LIBRARIES), same(CacheState.INVALID));
    expect(entry.getState(HtmlEntry.RESOLUTION_ERRORS), same(CacheState.INVALID));
  }

  void test_setState_angularErrors() {
    state = HtmlEntry.ANGULAR_ERRORS;
  }

  void test_setState_element() {
    state = HtmlEntry.ELEMENT;
  }

  void test_setState_hints() {
    state = HtmlEntry.HINTS;
  }

  void test_setState_lineInfo() {
    state = SourceEntry.LINE_INFO;
  }

  void test_setState_parseErrors() {
    state = HtmlEntry.PARSE_ERRORS;
  }

  void test_setState_parsedUnit() {
    state = HtmlEntry.PARSED_UNIT;
  }

  void test_setState_polymerBuildErrors() {
    state = HtmlEntry.POLYMER_BUILD_ERRORS;
  }

  void test_setState_polymerResolutionErrors() {
    state = HtmlEntry.POLYMER_RESOLUTION_ERRORS;
  }

  void test_setState_referencedLibraries() {
    state = HtmlEntry.REFERENCED_LIBRARIES;
  }

  void test_setState_resolutionErrors() {
    state = HtmlEntry.RESOLUTION_ERRORS;
  }

  void test_setValue_angularErrors() {
    _setValue(
        HtmlEntry.ANGULAR_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(null, AngularCode.INVALID_REPEAT_SYNTAX, ["-"])]);
  }

  void test_setValue_element() {
    _setValue(HtmlEntry.ELEMENT, new HtmlElementImpl(null, "test.html"));
  }

  void test_setValue_hints() {
    _setValue(
        HtmlEntry.HINTS,
        <AnalysisError>[new AnalysisError.con1(null, HintCode.DEAD_CODE, [])]);
  }

  void test_setValue_illegal() {
    HtmlEntry entry = new HtmlEntry();
    try {
      entry.setValue(DartEntry.ELEMENT, null);
      fail("Expected IllegalArgumentException for DartEntry.ELEMENT");
    } on ArgumentError catch (exception) {
    }
  }

  void test_setValue_lineInfo() {
    _setValue(SourceEntry.LINE_INFO, new LineInfo(<int>[0]));
  }

  void test_setValue_parseErrors() {
    _setValue(
        HtmlEntry.PARSE_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(null, HtmlWarningCode.INVALID_URI, ["-"])]);
  }

  void test_setValue_parsedUnit() {
    _setValue(HtmlEntry.PARSED_UNIT, new ht.HtmlUnit(null, null, null));
  }

  void test_setValue_polymerBuildErrors() {
    _setValue(
        HtmlEntry.POLYMER_BUILD_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(null, PolymerCode.INVALID_ATTRIBUTE_NAME, ["-"])]);
  }

  void test_setValue_polymerResolutionErrors() {
    _setValue(
        HtmlEntry.POLYMER_RESOLUTION_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(null, PolymerCode.INVALID_ATTRIBUTE_NAME, ["-"])]);
  }

  void test_setValue_referencedLibraries() {
    _setValue(HtmlEntry.REFERENCED_LIBRARIES, <Source>[new TestSource()]);
  }

  void test_setValue_resolutionErrors() {
    _setValue(
        HtmlEntry.RESOLUTION_ERRORS,
        <AnalysisError>[
            new AnalysisError.con1(null, HtmlWarningCode.INVALID_URI, ["-"])]);
  }

  HtmlEntry _entryWithValidState() {
    HtmlEntry entry = new HtmlEntry();
    entry.setValue(HtmlEntry.ANGULAR_APPLICATION, null);
    entry.setValue(HtmlEntry.ANGULAR_COMPONENT, null);
    entry.setValue(HtmlEntry.ANGULAR_ERRORS, null);
    entry.setValue(HtmlEntry.ELEMENT, null);
    entry.setValue(HtmlEntry.HINTS, null);
    entry.setValue(SourceEntry.LINE_INFO, null);
    entry.setValue(HtmlEntry.PARSE_ERRORS, null);
    entry.setValue(HtmlEntry.PARSED_UNIT, null);
    entry.setValue(HtmlEntry.POLYMER_BUILD_ERRORS, null);
    entry.setValue(HtmlEntry.POLYMER_RESOLUTION_ERRORS, null);
    entry.setValue(HtmlEntry.REFERENCED_LIBRARIES, null);
    entry.setValue(HtmlEntry.RESOLUTION_ERRORS, null);
    expect(entry.getState(HtmlEntry.ANGULAR_ERRORS), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.ELEMENT), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.HINTS), same(CacheState.VALID));
    expect(entry.getState(SourceEntry.LINE_INFO), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.PARSE_ERRORS), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.PARSED_UNIT), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.POLYMER_BUILD_ERRORS), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.POLYMER_RESOLUTION_ERRORS), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.REFERENCED_LIBRARIES), same(CacheState.VALID));
    expect(entry.getState(HtmlEntry.RESOLUTION_ERRORS), same(CacheState.VALID));
    return entry;
  }

  void _setValue(DataDescriptor descriptor, Object newValue) {
    HtmlEntry entry = new HtmlEntry();
    Object value = entry.getValue(descriptor);
    expect(newValue, isNot(same(value)));
    entry.setValue(descriptor, newValue);
    expect(entry.getState(descriptor), same(CacheState.VALID));
    expect(entry.getValue(descriptor), same(newValue));
  }
}


class IncrementalAnalysisCacheTest {
  Source _source = new TestSource();
  DartEntry _entry = new DartEntry();
  CompilationUnit _unit = new CompilationUnitMock();
  IncrementalAnalysisCache _result;
  void setUp() {
    _entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, _unit);
  }
  void test_cacheResult() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    CompilationUnit newUnit = new CompilationUnitMock();
    _result = IncrementalAnalysisCache.cacheResult(cache, newUnit);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(newUnit));
    expect(_result.oldContents, "hbazlo");
    expect(_result.newContents, "hbazlo");
    expect(_result.offset, 0);
    expect(_result.oldLength, 0);
    expect(_result.newLength, 0);
  }
  void test_cacheResult_noCache() {
    IncrementalAnalysisCache cache = null;
    CompilationUnit newUnit = new CompilationUnitMock();
    _result = IncrementalAnalysisCache.cacheResult(cache, newUnit);
    expect(_result, isNull);
  }
  void test_cacheResult_noCacheNoResult() {
    IncrementalAnalysisCache cache = null;
    CompilationUnit newUnit = null;
    _result = IncrementalAnalysisCache.cacheResult(cache, newUnit);
    expect(_result, isNull);
  }
  void test_cacheResult_noResult() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    CompilationUnit newUnit = null;
    _result = IncrementalAnalysisCache.cacheResult(cache, newUnit);
    expect(_result, isNull);
  }
  void test_clear_differentSource() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    Source otherSource = new TestSource("blat.dart", "blat");
    _result = IncrementalAnalysisCache.clear(cache, otherSource);
    expect(_result, same(cache));
  }
  void test_clear_nullCache() {
    IncrementalAnalysisCache cache = null;
    _result = IncrementalAnalysisCache.clear(cache, _source);
    expect(_result, isNull);
  }
  void test_clear_sameSource() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    _result = IncrementalAnalysisCache.clear(cache, _source);
    expect(_result, isNull);
  }
  void test_update_append() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    DartEntry newEntry = new DartEntry();
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "hbazlo",
        "hbazxlo",
        4,
        0,
        1,
        newEntry);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(_unit));
    expect(_result.oldContents, "hello");
    expect(_result.newContents, "hbazxlo");
    expect(_result.offset, 1);
    expect(_result.oldLength, 2);
    expect(_result.newLength, 4);
  }
  void test_update_appendToCachedResult() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    CompilationUnit newUnit = new CompilationUnitMock();
    cache = IncrementalAnalysisCache.cacheResult(cache, newUnit);
    expect(cache, isNotNull);
    DartEntry newEntry = new DartEntry();
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "hbazlo",
        "hbazxlo",
        4,
        0,
        1,
        newEntry);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(newUnit));
    expect(_result.oldContents, "hbazlo");
    expect(_result.newContents, "hbazxlo");
    expect(_result.offset, 4);
    expect(_result.oldLength, 0);
    expect(_result.newLength, 1);
  }
  void test_update_appendWithNewResolvedUnit() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    DartEntry newEntry = new DartEntry();
    CompilationUnit newUnit = new CompilationUnitMock();
    newEntry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, newUnit);
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "hbazlo",
        "hbazxlo",
        4,
        0,
        1,
        newEntry);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(newUnit));
    expect(_result.oldContents, "hbazlo");
    expect(_result.newContents, "hbazxlo");
    expect(_result.offset, 4);
    expect(_result.oldLength, 0);
    expect(_result.newLength, 1);
  }
  void test_update_appendWithNoNewResolvedUnit() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    DartEntry newEntry = new DartEntry();
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "hbazlo",
        "hbazxlo",
        4,
        0,
        1,
        newEntry);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(_unit));
    expect(_result.oldContents, "hello");
    expect(_result.newContents, "hbazxlo");
    expect(_result.offset, 1);
    expect(_result.oldLength, 2);
    expect(_result.newLength, 4);
  }
  void test_update_delete() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    DartEntry newEntry = new DartEntry();
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "hbazlo",
        "hzlo",
        1,
        2,
        0,
        newEntry);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(_unit));
    expect(_result.oldContents, "hello");
    expect(_result.newContents, "hzlo");
    expect(_result.offset, 1);
    expect(_result.oldLength, 2);
    expect(_result.newLength, 1);
  }
  void test_update_insert_nonContiguous_after() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    DartEntry newEntry = new DartEntry();
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "hbazlo",
        "hbazlox",
        6,
        0,
        1,
        newEntry);
    expect(_result, isNull);
  }
  void test_update_insert_nonContiguous_before() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    DartEntry newEntry = new DartEntry();
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "hbazlo",
        "xhbazlo",
        0,
        0,
        1,
        newEntry);
    expect(_result, isNull);
  }
  void test_update_newSource_entry() {
    Source oldSource = new TestSource("blat.dart", "blat");
    DartEntry oldEntry = new DartEntry();
    CompilationUnit oldUnit = new CompilationUnitMock();
    oldEntry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, oldUnit);
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        oldSource,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        oldEntry);
    expect(cache.source, same(oldSource));
    expect(cache.resolvedUnit, same(oldUnit));
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "foo",
        "foobz",
        3,
        0,
        2,
        _entry);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(_unit));
    expect(_result.oldContents, "foo");
    expect(_result.newContents, "foobz");
    expect(_result.offset, 3);
    expect(_result.oldLength, 0);
    expect(_result.newLength, 2);
  }
  void test_update_newSource_noEntry() {
    Source oldSource = new TestSource("blat.dart", "blat");
    DartEntry oldEntry = new DartEntry();
    CompilationUnit oldUnit = new CompilationUnitMock();
    oldEntry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, oldUnit);
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        oldSource,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        oldEntry);
    expect(cache.source, same(oldSource));
    expect(cache.resolvedUnit, same(oldUnit));
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "foo",
        "foobar",
        3,
        0,
        3,
        null);
    expect(_result, isNull);
  }
  void test_update_noCache_entry() {
    _result = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(_unit));
    expect(_result.oldContents, "hello");
    expect(_result.newContents, "hbazlo");
    expect(_result.offset, 1);
    expect(_result.oldLength, 2);
    expect(_result.newLength, 3);
    expect(_result.hasWork, isTrue);
  }
  void test_update_noCache_entry_noOldSource_append() {
    _result = IncrementalAnalysisCache.update(
        null,
        _source,
        null,
        "hellxo",
        4,
        0,
        1,
        _entry);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(_unit));
    expect(_result.oldContents, "hello");
    expect(_result.newContents, "hellxo");
    expect(_result.offset, 4);
    expect(_result.oldLength, 0);
    expect(_result.newLength, 1);
    expect(_result.hasWork, isTrue);
  }
  void test_update_noCache_entry_noOldSource_delete() {
    _result =
        IncrementalAnalysisCache.update(null, _source, null, "helo", 4, 1, 0, _entry);
    expect(_result, isNull);
  }
  void test_update_noCache_entry_noOldSource_replace() {
    _result =
        IncrementalAnalysisCache.update(null, _source, null, "helxo", 4, 1, 1, _entry);
    expect(_result, isNull);
  }
  void test_update_noCache_noEntry() {
    _result = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        null);
    expect(_result, isNull);
  }
  void test_update_replace() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    _result = IncrementalAnalysisCache.update(
        cache,
        _source,
        "hbazlo",
        "hbarrlo",
        3,
        1,
        2,
        null);
    expect(_result, isNotNull);
    expect(_result.source, same(_source));
    expect(_result.resolvedUnit, same(_unit));
    expect(_result.oldContents, "hello");
    expect(_result.newContents, "hbarrlo");
    expect(_result.offset, 1);
    expect(_result.oldLength, 2);
    expect(_result.newLength, 4);
  }
  void test_verifyStructure_invalidUnit() {
    String oldCode = "main() {foo;}";
    String newCode = "main() {boo;}";
    CompilationUnit badUnit = _parse("main() {bad;}");
    _entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, badUnit);
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        oldCode,
        newCode,
        8,
        1,
        1,
        _entry);
    CompilationUnit newUnit = _parse(newCode);
    _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
    expect(_result, isNull);
  }
  void test_verifyStructure_noCache() {
    IncrementalAnalysisCache cache = null;
    CompilationUnit newUnit = new CompilationUnitMock();
    _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
    expect(_result, isNull);
  }
  void test_verifyStructure_noCacheNoUnit() {
    IncrementalAnalysisCache cache = null;
    CompilationUnit newUnit = null;
    _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
    expect(_result, isNull);
  }
  void test_verifyStructure_noUnit() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    CompilationUnit newUnit = null;
    _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
    expect(_result, same(cache));
    expect(_result.resolvedUnit, same(_unit));
  }
  void test_verifyStructure_otherSource() {
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        "hello",
        "hbazlo",
        1,
        2,
        3,
        _entry);
    CompilationUnit newUnit = new CompilationUnitMock();
    Source otherSource = new TestSource("blat.dart", "blat");
    _result =
        IncrementalAnalysisCache.verifyStructure(cache, otherSource, newUnit);
    expect(_result, same(cache));
    expect(_result.resolvedUnit, same(_unit));
  }
  void test_verifyStructure_validUnit() {
    String oldCode = "main() {foo;}";
    String newCode = "main() {boo;}";
    CompilationUnit goodUnit = _parse(newCode);
    _entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, goodUnit);
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        _source,
        oldCode,
        newCode,
        1,
        2,
        3,
        _entry);
    CompilationUnit newUnit = _parse(newCode);
    _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
    expect(_result, same(cache));
    expect(_result.resolvedUnit, same(goodUnit));
  }
  CompilationUnit _parse(String code) {
    Scanner scanner = new Scanner(
        _source,
        new CharSequenceReader(code),
        AnalysisErrorListener.NULL_LISTENER);
    Parser parser = new Parser(_source, AnalysisErrorListener.NULL_LISTENER);
    return parser.parseCompilationUnit(scanner.tokenize());
  }
}



class IncrementalAnalysisTaskTest extends EngineTestCase {
  void test_accept() {
    IncrementalAnalysisTask task = new IncrementalAnalysisTask(null, null);
    expect(task.accept(new IncrementalAnalysisTaskTestTV_accept()), isTrue);
  }

  void test_perform() {
    // main() {} String foo;
    // main() {String} String foo;
    CompilationUnit newUnit =
        _assertTask("main() {", "", "String", "} String foo;");
    NodeList<CompilationUnitMember> declarations = newUnit.declarations;
    FunctionDeclaration main = declarations[0] as FunctionDeclaration;
    expect(main.name.name, "main");
    BlockFunctionBody body = main.functionExpression.body as BlockFunctionBody;
    ExpressionStatement statement =
        body.block.statements[0] as ExpressionStatement;
    expect(statement.toSource(), "String;");
    SimpleIdentifier identifier = statement.expression as SimpleIdentifier;
    expect(identifier.name, "String");
    expect(identifier.staticElement, isNotNull);
    TopLevelVariableDeclaration fooDecl =
        declarations[1] as TopLevelVariableDeclaration;
    SimpleIdentifier fooName = fooDecl.variables.variables[0].name;
    expect(fooName.name, "foo");
    expect(fooName.staticElement, isNotNull);
    // assert element reference is preserved
  }

  CompilationUnit _assertTask(String prefix, String removed, String added,
      String suffix) {
    String oldCode = "$prefix$removed$suffix";
    String newCode = "$prefix$added$suffix";
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    Source source = new TestSource("/test.dart", oldCode);
    DartEntry entry = new DartEntry();
    CompilationUnit oldUnit = context.resolveCompilationUnit2(source, source);
    expect(oldUnit, isNotNull);
    entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source, oldUnit);
    IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(
        null,
        source,
        oldCode,
        newCode,
        prefix.length,
        removed.length,
        added.length,
        entry);
    expect(cache, isNotNull);
    IncrementalAnalysisTask task = new IncrementalAnalysisTask(context, cache);
    CompilationUnit newUnit =
        task.perform(new IncrementalAnalysisTaskTestTV_assertTask(task));
    expect(newUnit, isNotNull);
    return newUnit;
  }
}


class IncrementalAnalysisTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitIncrementalAnalysisTask(IncrementalAnalysisTask task) => true;
}


class IncrementalAnalysisTaskTestTV_assertTask extends
    TestTaskVisitor<CompilationUnit> {
  IncrementalAnalysisTask task;
  IncrementalAnalysisTaskTestTV_assertTask(this.task);
  @override
  CompilationUnit
      visitIncrementalAnalysisTask(IncrementalAnalysisTask incrementalAnalysisTask) =>
      task.compilationUnit;
}


class InstrumentedAnalysisContextImplTest extends EngineTestCase {
  void test_addSourceInfo() {
    TestAnalysisContext_test_addSourceInfo innerContext = new TestAnalysisContext_test_addSourceInfo();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.addSourceInfo(null, null);
    expect(innerContext.invoked, isTrue);
  }

  void test_applyChanges() {
    TestAnalysisContext_test_applyChanges innerContext = new TestAnalysisContext_test_applyChanges();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.applyChanges(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_computeDocumentationComment() {
    TestAnalysisContext_test_computeDocumentationComment innerContext = new TestAnalysisContext_test_computeDocumentationComment();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.computeDocumentationComment(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_computeErrors() {
    TestAnalysisContext_test_computeErrors innerContext = new TestAnalysisContext_test_computeErrors();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.computeErrors(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_computeExportedLibraries() {
    TestAnalysisContext_test_computeExportedLibraries innerContext = new TestAnalysisContext_test_computeExportedLibraries();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.computeExportedLibraries(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_computeHtmlElement() {
    TestAnalysisContext_test_computeHtmlElement innerContext = new TestAnalysisContext_test_computeHtmlElement();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.computeHtmlElement(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_computeImportedLibraries() {
    TestAnalysisContext_test_computeImportedLibraries innerContext = new TestAnalysisContext_test_computeImportedLibraries();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.computeImportedLibraries(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_computeKindOf() {
    TestAnalysisContext_test_computeKindOf innerContext = new TestAnalysisContext_test_computeKindOf();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.computeKindOf(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_computeLibraryElement() {
    TestAnalysisContext_test_computeLibraryElement innerContext = new TestAnalysisContext_test_computeLibraryElement();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.computeLibraryElement(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_computeLineInfo() {
    TestAnalysisContext_test_computeLineInfo innerContext = new TestAnalysisContext_test_computeLineInfo();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.computeLineInfo(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_computeResolvableCompilationUnit() {
    TestAnalysisContext_test_computeResolvableCompilationUnit innerContext = new TestAnalysisContext_test_computeResolvableCompilationUnit();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.computeResolvableCompilationUnit(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_creation() {
    expect(new InstrumentedAnalysisContextImpl(), isNotNull);
  }

  void test_dispose() {
    TestAnalysisContext_test_dispose innerContext = new TestAnalysisContext_test_dispose();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.dispose();
    expect(innerContext.invoked, isTrue);
  }

  void test_exists() {
    TestAnalysisContext_test_exists innerContext = new TestAnalysisContext_test_exists();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.exists(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getAnalysisOptions() {
    TestAnalysisContext_test_getAnalysisOptions innerContext = new TestAnalysisContext_test_getAnalysisOptions();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.analysisOptions;
    expect(innerContext.invoked, isTrue);
  }

  void test_getAngularApplicationWithHtml() {
    TestAnalysisContext_test_getAngularApplicationWithHtml innerContext = new TestAnalysisContext_test_getAngularApplicationWithHtml();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getAngularApplicationWithHtml(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getCompilationUnitElement() {
    TestAnalysisContext_test_getCompilationUnitElement innerContext = new TestAnalysisContext_test_getCompilationUnitElement();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getCompilationUnitElement(null, null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getContents() {
    TestAnalysisContext_test_getContents innerContext = new TestAnalysisContext_test_getContents();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getContents(null);
    expect(innerContext.invoked, isTrue);
  }

//  void test_getContentsToReceiver() {
//    TestAnalysisContext_test_getContentsToReceiver innerContext = new TestAnalysisContext_test_getContentsToReceiver();
//    InstrumentedAnalysisContextImpl context
//        = new InstrumentedAnalysisContextImpl.con1(innerContext);
//    context.getContentsToReceiver(null, null);
//    expect(innerContext.invoked, isTrue);
//  }

  void test_getElement() {
    TestAnalysisContext_test_getElement innerContext = new TestAnalysisContext_test_getElement();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getElement(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getErrors() {
    TestAnalysisContext_test_getErrors innerContext = new TestAnalysisContext_test_getErrors();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getErrors(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getHtmlElement() {
    TestAnalysisContext_test_getHtmlElement innerContext = new TestAnalysisContext_test_getHtmlElement();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getHtmlElement(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getHtmlFilesReferencing() {
    TestAnalysisContext_test_getHtmlFilesReferencing innerContext = new TestAnalysisContext_test_getHtmlFilesReferencing();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getHtmlFilesReferencing(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getHtmlSources() {
    TestAnalysisContext_test_getHtmlSources innerContext = new TestAnalysisContext_test_getHtmlSources();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.htmlSources;
    expect(innerContext.invoked, isTrue);
  }

  void test_getKindOf() {
    TestAnalysisContext_test_getKindOf innerContext = new TestAnalysisContext_test_getKindOf();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getKindOf(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getLaunchableClientLibrarySources() {
    TestAnalysisContext_test_getLaunchableClientLibrarySources innerContext = new TestAnalysisContext_test_getLaunchableClientLibrarySources();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.launchableClientLibrarySources;
    expect(innerContext.invoked, isTrue);
  }

  void test_getLaunchableServerLibrarySources() {
    TestAnalysisContext_test_getLaunchableServerLibrarySources innerContext = new TestAnalysisContext_test_getLaunchableServerLibrarySources();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.launchableServerLibrarySources;
    expect(innerContext.invoked, isTrue);
  }

  void test_getLibrariesContaining() {
    TestAnalysisContext_test_getLibrariesContaining innerContext = new TestAnalysisContext_test_getLibrariesContaining();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getLibrariesContaining(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getLibrariesDependingOn() {
    TestAnalysisContext_test_getLibrariesDependingOn innerContext = new TestAnalysisContext_test_getLibrariesDependingOn();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getLibrariesDependingOn(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getLibrariesReferencedFromHtml() {
    TestAnalysisContext_test_getLibrariesReferencedFromHtml innerContext = new TestAnalysisContext_test_getLibrariesReferencedFromHtml();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getLibrariesReferencedFromHtml(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getLibraryElement() {
    TestAnalysisContext_test_getLibraryElement innerContext = new TestAnalysisContext_test_getLibraryElement();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getLibraryElement(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getLibrarySources() {
    TestAnalysisContext_test_getLibrarySources innerContext = new TestAnalysisContext_test_getLibrarySources();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.librarySources;
    expect(innerContext.invoked, isTrue);
  }

  void test_getLineInfo() {
    TestAnalysisContext_test_getLineInfo innerContext = new TestAnalysisContext_test_getLineInfo();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getLineInfo(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getModificationStamp() {
    TestAnalysisContext_test_getModificationStamp innerContext = new TestAnalysisContext_test_getModificationStamp();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getModificationStamp(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getPublicNamespace() {
    TestAnalysisContext_test_getPublicNamespace innerContext = new TestAnalysisContext_test_getPublicNamespace();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getPublicNamespace(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getRefactoringUnsafeSources() {
    TestAnalysisContext_test_getRefactoringUnsafeSources innerContext = new TestAnalysisContext_test_getRefactoringUnsafeSources();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.refactoringUnsafeSources;
    expect(innerContext.invoked, isTrue);
  }

  void test_getResolvedCompilationUnit_element() {
    TestAnalysisContext_test_getResolvedCompilationUnit_element innerContext = new TestAnalysisContext_test_getResolvedCompilationUnit_element();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getResolvedCompilationUnit(null, null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getResolvedCompilationUnit_source() {
    TestAnalysisContext_test_getResolvedCompilationUnit_source innerContext = new TestAnalysisContext_test_getResolvedCompilationUnit_source();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getResolvedCompilationUnit2(null, null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getResolvedHtmlUnit() {
    TestAnalysisContext_test_getResolvedHtmlUnit innerContext = new TestAnalysisContext_test_getResolvedHtmlUnit();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.getResolvedHtmlUnit(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_getSourceFactory() {
    TestAnalysisContext_test_getSourceFactory innerContext = new TestAnalysisContext_test_getSourceFactory();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.sourceFactory;
    expect(innerContext.invoked, isTrue);
  }

  void test_getStatistics() {
    TestAnalysisContext_test_getStatistics innerContext = new TestAnalysisContext_test_getStatistics();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.statistics;
    expect(innerContext.invoked, isTrue);
  }

  void test_getTypeProvider() {
    TestAnalysisContext_test_getTypeProvider innerContext = new TestAnalysisContext_test_getTypeProvider();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.typeProvider;
    expect(innerContext.invoked, isTrue);
  }

  void test_isClientLibrary() {
    TestAnalysisContext_test_isClientLibrary innerContext = new TestAnalysisContext_test_isClientLibrary();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.isClientLibrary(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_isDisposed() {
    TestAnalysisContext_test_isDisposed innerContext = new TestAnalysisContext_test_isDisposed();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.isDisposed;
    expect(innerContext.invoked, isTrue);
  }

  void test_isServerLibrary() {
    TestAnalysisContext_test_isServerLibrary innerContext = new TestAnalysisContext_test_isServerLibrary();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.isServerLibrary(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_parseCompilationUnit() {
    TestAnalysisContext_test_parseCompilationUnit innerContext = new TestAnalysisContext_test_parseCompilationUnit();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.parseCompilationUnit(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_parseHtmlUnit() {
    TestAnalysisContext_test_parseHtmlUnit innerContext = new TestAnalysisContext_test_parseHtmlUnit();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.parseHtmlUnit(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_performAnalysisTask() {
    TestAnalysisContext_test_performAnalysisTask innerContext = new TestAnalysisContext_test_performAnalysisTask();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.performAnalysisTask();
    expect(innerContext.invoked, isTrue);
  }

  void test_recordLibraryElements() {
    TestAnalysisContext_test_recordLibraryElements innerContext = new TestAnalysisContext_test_recordLibraryElements();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.recordLibraryElements(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_resolveCompilationUnit() {
    TestAnalysisContext_test_resolveCompilationUnit innerContext = new TestAnalysisContext_test_resolveCompilationUnit();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.resolveCompilationUnit2(null, null);
    expect(innerContext.invoked, isTrue);
  }

  void test_resolveCompilationUnit_element() {
    TestAnalysisContext_test_resolveCompilationUnit_element innerContext = new TestAnalysisContext_test_resolveCompilationUnit_element();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.resolveCompilationUnit(null, null);
    expect(innerContext.invoked, isTrue);
  }

  void test_resolveHtmlUnit() {
    TestAnalysisContext_test_resolveHtmlUnit innerContext = new TestAnalysisContext_test_resolveHtmlUnit();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.resolveHtmlUnit(null);
    expect(innerContext.invoked, isTrue);
  }

  void test_setAnalysisOptions() {
    TestAnalysisContext_test_setAnalysisOptions innerContext = new TestAnalysisContext_test_setAnalysisOptions();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.analysisOptions = null;
    expect(innerContext.invoked, isTrue);
  }

  void test_setAnalysisPriorityOrder() {
    TestAnalysisContext_test_setAnalysisPriorityOrder innerContext = new TestAnalysisContext_test_setAnalysisPriorityOrder();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.analysisPriorityOrder = null;
    expect(innerContext.invoked, isTrue);
  }

  void test_setChangedContents() {
    TestAnalysisContext_test_setChangedContents innerContext = new TestAnalysisContext_test_setChangedContents();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.setChangedContents(null, null, 0, 0, 0);
    expect(innerContext.invoked, isTrue);
  }

  void test_setContents() {
    TestAnalysisContext_test_setContents innerContext = new TestAnalysisContext_test_setContents();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.setContents(null, null);
    expect(innerContext.invoked, isTrue);
  }

  void test_setSourceFactory() {
    TestAnalysisContext_test_setSourceFactory innerContext = new TestAnalysisContext_test_setSourceFactory();
    InstrumentedAnalysisContextImpl context =
        new InstrumentedAnalysisContextImpl.con1(innerContext);
    context.sourceFactory = null;
    expect(innerContext.invoked, isTrue);
  }
}


class ParseDartTaskTest extends EngineTestCase {
  void test_accept() {
    ParseDartTask task = new ParseDartTask(null, null, null, null);
    expect(task.accept(new ParseDartTaskTestTV_accept()), isTrue);
  }

  void test_getCompilationUnit() {
    ParseDartTask task = new ParseDartTask(null, null, null, null);
    expect(task.compilationUnit, isNull);
  }

  void test_getErrors() {
    ParseDartTask task = new ParseDartTask(null, null, null, null);
    expect(task.errors, hasLength(0));
  }

  void test_getException() {
    ParseDartTask task = new ParseDartTask(null, null, null, null);
    expect(task.exception, isNull);
  }

  void test_getSource() {
    Source source = new TestSource('/test.dart');
    ParseDartTask task = new ParseDartTask(null, source, null, null);
    expect(task.source, same(source));
  }

  void test_hasNonPartOfDirective() {
    ParseDartTask task = new ParseDartTask(null, null, null, null);
    expect(task.hasNonPartOfDirective, isFalse);
  }

  void test_hasPartOfDirective() {
    ParseDartTask task = new ParseDartTask(null, null, null, null);
    expect(task.hasPartOfDirective, isFalse);
  }

  void test_perform_exception() {
    TestSource source = new TestSource();
    source.generateExceptionOnRead = true;
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    ParseDartTask task = new ParseDartTask(context, source, null, null);
    task.perform(new ParseDartTaskTestTV_perform_exception());
  }

  void test_perform_library() {
    String content = r'''
library lib;
import 'lib2.dart';
export 'lib3.dart';
part 'part.dart';
class A {''';
    Source source = new TestSource('/test.dart', content);
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    ParseDartTask task = _createParseTask(context, source, content);
    task.perform(new ParseDartTaskTestTV_perform_library(context, source));
  }

  void test_perform_part() {
    String content =
        r'''
part of lib;
class B {}''';
    Source source = new TestSource('/test.dart', content);
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    ParseDartTask task = _createParseTask(context, source, content);
    task.perform(new ParseDartTaskTestTV_perform_part(context, source));
  }

  void test_perform_validateDirectives() {
    String content = r'''
library lib;
import '/does/not/exist.dart';
import '://invaliduri.dart';
export '${a}lib3.dart';
part 'part.dart';
class A {}''';
    Source source = new TestSource('/test.dart', content);
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    ParseDartTask task = _createParseTask(context, source, content);
    task.perform(
        new ParseDartTaskTestTV_perform_validateDirectives(context, source));
  }

  /**
   * Create and return a task that will parse the given content from the given source in the given
   * context.
   *
   * @param context the context to be passed to the task
   * @param source the source to be parsed
   * @param content the content of the source to be parsed
   * @return the task that was created
   * @throws AnalysisException if the task could not be created
   */
  ParseDartTask _createParseTask(InternalAnalysisContext context, Source source,
      String content) {
    ScanDartTask scanTask = new ScanDartTask(
        context,
        source,
        content);
    scanTask.perform(new ParseDartTaskTestTV_createParseTask());
    return new ParseDartTask(
        context,
        source,
        scanTask.tokenStream,
        scanTask.lineInfo);
  }
}


class ParseDartTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitParseDartTask(ParseDartTask task) => true;
}


class ParseDartTaskTestTV_createParseTask extends TestTaskVisitor<Object> {
  @override
  Object visitScanDartTask(ScanDartTask task) => null;
}


class ParseDartTaskTestTV_perform_exception extends TestTaskVisitor<bool> {
  @override
  bool visitParseDartTask(ParseDartTask task) {
    expect(task.exception, isNotNull);
    return true;
  }
}


class ParseDartTaskTestTV_perform_library extends TestTaskVisitor<Object> {
  InternalAnalysisContext context;
  Source source;
  ParseDartTaskTestTV_perform_library(this.context, this.source);
  @override
  Object visitParseDartTask(ParseDartTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.compilationUnit, isNotNull);
    expect(task.errors, hasLength(1));
    expect(task.source, same(source));
    expect(task.hasNonPartOfDirective, isTrue);
    expect(task.hasPartOfDirective, isFalse);
    return null;
  }
}


class ParseDartTaskTestTV_perform_part extends TestTaskVisitor<Object> {
  InternalAnalysisContext context;
  Source source;
  ParseDartTaskTestTV_perform_part(this.context, this.source);
  @override
  Object visitParseDartTask(ParseDartTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.compilationUnit, isNotNull);
    expect(task.errors, hasLength(0));
    expect(task.source, same(source));
    expect(task.hasNonPartOfDirective, isFalse);
    expect(task.hasPartOfDirective, isTrue);
    return null;
  }
}


class ParseDartTaskTestTV_perform_validateDirectives extends
    TestTaskVisitor<Object> {
  InternalAnalysisContext context;
  Source source;
  ParseDartTaskTestTV_perform_validateDirectives(this.context, this.source);
  @override
  Object visitParseDartTask(ParseDartTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.compilationUnit, isNotNull);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    errorListener.addAll(task.errors);
    errorListener.assertErrorsWithCodes(
        [
            CompileTimeErrorCode.URI_WITH_INTERPOLATION,
            CompileTimeErrorCode.INVALID_URI]);
    expect(task.source, same(source));
    expect(task.hasNonPartOfDirective, isTrue);
    expect(task.hasPartOfDirective, isFalse);
    return null;
  }
}


class ParseHtmlTaskTest extends EngineTestCase {
  ParseHtmlTask parseContents(String contents, TestLogger testLogger) {
    return parseSource(
        new TestSource('/test.dart', contents),
        contents,
        testLogger);
  }

  ParseHtmlTask parseSource(Source source, String contents,
      TestLogger testLogger) {
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.setContents(source, contents);
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    ParseHtmlTask task = new ParseHtmlTask(
        context,
        source,
        contents);
    Logger oldLogger = AnalysisEngine.instance.logger;
    try {
      AnalysisEngine.instance.logger = testLogger;
      task.perform(new ParseHtmlTaskTestTV_parseSource(context, source));
    } finally {
      AnalysisEngine.instance.logger = oldLogger;
    }
    return task;
  }

  void test_accept() {
    ParseHtmlTask task = new ParseHtmlTask(null, null, "");
    expect(task.accept(new ParseHtmlTaskTestTV_accept()), isTrue);
  }

  void test_getException() {
    ParseHtmlTask task = new ParseHtmlTask(null, null, "");
    expect(task.exception, isNull);
  }

  void test_getHtmlUnit() {
    ParseHtmlTask task = new ParseHtmlTask(null, null, "");
    expect(task.htmlUnit, isNull);
  }

  void test_getLineInfo() {
    ParseHtmlTask task = new ParseHtmlTask(null, null, "");
    expect(task.lineInfo, isNull);
  }

  void test_getReferencedLibraries() {
    ParseHtmlTask task = new ParseHtmlTask(null, null, "");
    expect(task.referencedLibraries, hasLength(0));
  }

  void test_getSource() {
    Source source = new TestSource('/test.dart');
    ParseHtmlTask task = new ParseHtmlTask(null, source, "");
    expect(task.source, same(source));
  }

  void test_perform_embedded_source() {
    String contents = r'''
<html>
<head>
  <script type='application/dart'>
    void buttonPressed() {}
  </script>
</head>
<body>
</body>
</html>''';
    TestLogger testLogger = new TestLogger();
    ParseHtmlTask task = parseContents(contents, testLogger);
    expect(task.referencedLibraries, hasLength(0));
    expect(testLogger.errorCount, 0);
    expect(testLogger.infoCount, 0);
  }

  void test_perform_empty_source_reference() {
    String contents = r'''
<html>
<head>
  <script type='application/dart' src=''/>
</head>
<body>
</body>
</html>''';
    TestLogger testLogger = new TestLogger();
    ParseHtmlTask task = parseContents(contents, testLogger);
    expect(task.referencedLibraries, hasLength(0));
    expect(testLogger.errorCount, 0);
    expect(testLogger.infoCount, 0);
  }

  void test_perform_invalid_source_reference() {
    String contents = r'''
<html>
<head>
  <script type='application/dart' src='an;invalid:[]uri'/>
</head>
<body>
</body>
</html>''';
    TestLogger testLogger = new TestLogger();
    ParseHtmlTask task = parseContents(contents, testLogger);
    expect(task.referencedLibraries, hasLength(0));
    expect(testLogger.errorCount, 0);
    expect(testLogger.infoCount, 0);
  }

  void test_perform_non_existing_source_reference() {
    String contents = r'''
<html>
<head>
  <script type='application/dart' src='does/not/exist.dart'/>
</head>
<body>
</body>
</html>''';
    TestLogger testLogger = new TestLogger();
    ParseHtmlTask task = parseSource(
        new ParseHtmlTaskTest_non_existing_source(contents),
        contents,
        testLogger);
    expect(task.referencedLibraries, hasLength(0));
    expect(testLogger.errorCount, 0);
    expect(testLogger.infoCount, 0);
  }

  void test_perform_referenced_source() {
    // TODO(scheglov) this test fails because we put into cache TestSource
    // test.dart (and actually should test.html), but resolve
    // src='test.dart' as a FileBasedSource
    // We need to switch to a virtual file system and use it everywhere.
//    String contents = EngineTestCase.createSource([
//        "<html>",
//        "<head>",
//        "  <script type='application/dart' src='test.dart'/>",
//        "</head>",
//        "<body>",
//        "</body>",
//        "</html>"]);
//    TestLogger testLogger = new TestLogger();
//    ParseHtmlTask task = parseContents(contents, testLogger);
//    EngineTestCase.assertLength(1, task.referencedLibraries);
//    JUnitTestCase.assertEquals(0, testLogger.errorCount);
//    JUnitTestCase.assertEquals(0, testLogger.errorCount);
  }
}


class ParseHtmlTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitParseHtmlTask(ParseHtmlTask task) => true;
}


class ParseHtmlTaskTestTV_parseSource extends TestTaskVisitor<bool> {
  InternalAnalysisContext context;
  Source source;
  ParseHtmlTaskTestTV_parseSource(this.context, this.source);
  @override
  bool visitParseHtmlTask(ParseHtmlTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.htmlUnit, isNotNull);
    expect(task.lineInfo, isNotNull);
    expect(task.source, same(source));
    return true;
  }
}


class ParseHtmlTaskTest_non_existing_source extends TestSource {
  ParseHtmlTaskTest_non_existing_source(String arg0) : super(arg0);
  @override
  Uri resolveRelativeUri(Uri containedUri) {
    try {
      return parseUriWithException("file:/does/not/exist.dart");
    } on URISyntaxException catch (exception) {
      return null;
    }
  }
}


class PartitionManagerTest extends EngineTestCase {
  void test_clearCache() {
    PartitionManager manager = new PartitionManager();
    DartSdk sdk = new MockDartSdk();
    SdkCachePartition oldPartition = manager.forSdk(sdk);
    manager.clearCache();
    SdkCachePartition newPartition = manager.forSdk(sdk);
    expect(newPartition, isNot(same(oldPartition)));
  }

  void test_creation() {
    expect(new PartitionManager(), isNotNull);
  }

  void test_forSdk() {
    PartitionManager manager = new PartitionManager();
    DartSdk sdk1 = new MockDartSdk();
    SdkCachePartition partition1 = manager.forSdk(sdk1);
    expect(partition1, isNotNull);
    expect(manager.forSdk(sdk1), same(partition1));
    DartSdk sdk2 = new MockDartSdk();
    SdkCachePartition partition2 = manager.forSdk(sdk2);
    expect(partition2, isNotNull);
    expect(manager.forSdk(sdk2), same(partition2));
    expect(partition2, isNot(same(partition1)));
  }
}


class ResolveDartLibraryTaskTest extends EngineTestCase {
  void test_accept() {
    ResolveDartLibraryTask task = new ResolveDartLibraryTask(null, null, null);
    expect(task.accept(new ResolveDartLibraryTaskTestTV_accept()), isTrue);
  }
  void test_getException() {
    ResolveDartLibraryTask task = new ResolveDartLibraryTask(null, null, null);
    expect(task.exception, isNull);
  }
  void test_getLibraryResolver() {
    ResolveDartLibraryTask task = new ResolveDartLibraryTask(null, null, null);
    expect(task.libraryResolver, isNull);
  }
  void test_getLibrarySource() {
    Source source = new TestSource('/test.dart');
    ResolveDartLibraryTask task =
        new ResolveDartLibraryTask(null, null, source);
    expect(task.librarySource, same(source));
  }
  void test_getUnitSource() {
    Source source = new TestSource('/test.dart');
    ResolveDartLibraryTask task =
        new ResolveDartLibraryTask(null, source, null);
    expect(task.unitSource, same(source));
  }
  void test_perform_exception() {
    TestSource source = new TestSource();
    source.generateExceptionOnRead = true;
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    ResolveDartLibraryTask task =
        new ResolveDartLibraryTask(context, source, source);
    task.perform(new ResolveDartLibraryTaskTestTV_perform_exception());
  }
  void test_perform_library() {
    Source source = new TestSource(
        '/test.dart',
        r'''
library lib;
class A {}''');
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    ResolveDartLibraryTask task =
        new ResolveDartLibraryTask(context, source, source);
    task.perform(new ResolveDartLibraryTaskTestTV_perform_library(source));
  }
}


class ResolveDartLibraryTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitResolveDartLibraryTask(ResolveDartLibraryTask task) => true;
}


class ResolveDartLibraryTaskTestTV_perform_exception extends
    TestTaskVisitor<bool> {
  @override
  bool visitResolveDartLibraryTask(ResolveDartLibraryTask task) {
    expect(task.exception, isNotNull);
    return true;
  }
}


class ResolveDartLibraryTaskTestTV_perform_library extends TestTaskVisitor<bool>
    {
  Source source;
  ResolveDartLibraryTaskTestTV_perform_library(this.source);
  @override
  bool visitResolveDartLibraryTask(ResolveDartLibraryTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.libraryResolver, isNotNull);
    expect(task.librarySource, same(source));
    expect(task.unitSource, same(source));
    return true;
  }
}


class ResolveDartUnitTaskTest extends EngineTestCase {
  void test_accept() {
    ResolveDartUnitTask task = new ResolveDartUnitTask(null, null, null);
    expect(task.accept(new ResolveDartUnitTaskTestTV_accept()), isTrue);
  }

  void test_getException() {
    ResolveDartUnitTask task = new ResolveDartUnitTask(null, null, null);
    expect(task.exception, isNull);
  }

  void test_getLibrarySource() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    LibraryElementImpl element = ElementFactory.library(context, "lib");
    Source source = element.source;
    ResolveDartUnitTask task = new ResolveDartUnitTask(null, null, element);
    expect(task.librarySource, same(source));
  }

  void test_getResolvedUnit() {
    ResolveDartUnitTask task = new ResolveDartUnitTask(null, null, null);
    expect(task.resolvedUnit, isNull);
  }

  void test_getSource() {
    Source source = new TestSource('/test.dart');
    ResolveDartUnitTask task = new ResolveDartUnitTask(null, source, null);
    expect(task.source, same(source));
  }

  void test_perform_exception() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    LibraryElementImpl element = ElementFactory.library(context, "lib");
    TestSource source = new TestSource();
    source.generateExceptionOnRead = true;
    (element.definingCompilationUnit as CompilationUnitElementImpl).source =
        source;
    ResolveDartUnitTask task =
        new ResolveDartUnitTask(context, source, element);
    task.perform(new ResolveDartUnitTaskTestTV_perform_exception());
  }

  void test_perform_library() {
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    LibraryElementImpl libraryElement = ElementFactory.library(context, "lib");
    CompilationUnitElementImpl unitElement =
        libraryElement.definingCompilationUnit as CompilationUnitElementImpl;
    ClassElementImpl classElement = ElementFactory.classElement2("A", []);
    classElement.nameOffset = 19;
    ConstructorElementImpl constructorElement =
        ElementFactory.constructorElement2(classElement, null, []);
    constructorElement.synthetic = true;
    classElement.constructors = <ConstructorElement>[constructorElement];
    unitElement.types = <ClassElement>[classElement];
    Source source = unitElement.source;
    context.setContents(
        source,
        r'''
library lib;
class A {}''');
    ResolveDartUnitTask task =
        new ResolveDartUnitTask(context, source, libraryElement);
    task.perform(
        new ResolveDartUnitTaskTestTV_perform_library(source, context));
  }
}


class ResolveDartUnitTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitResolveDartUnitTask(ResolveDartUnitTask task) => true;
}


class ResolveDartUnitTaskTestTV_perform_exception extends TestTaskVisitor<bool>
    {
  @override
  bool visitResolveDartUnitTask(ResolveDartUnitTask task) {
    expect(task.exception, isNotNull);
    return true;
  }
}


class ResolveDartUnitTaskTestTV_perform_library extends TestTaskVisitor<bool> {
  Source source;
  InternalAnalysisContext context;
  ResolveDartUnitTaskTestTV_perform_library(this.source, this.context);
  @override
  bool visitResolveDartUnitTask(ResolveDartUnitTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.librarySource, same(source));
    expect(task.resolvedUnit, isNotNull);
    expect(task.source, same(source));
    return true;
  }
}


class ResolveHtmlTaskTest extends EngineTestCase {
  void test_accept() {
    ResolveHtmlTask task = new ResolveHtmlTask(null, null, 0, null);
    expect(task.accept(new ResolveHtmlTaskTestTV_accept()), isTrue);
  }

  void test_getElement() {
    ResolveHtmlTask task = new ResolveHtmlTask(null, null, 0, null);
    expect(task.element, isNull);
  }

  void test_getException() {
    ResolveHtmlTask task = new ResolveHtmlTask(null, null, 0, null);
    expect(task.exception, isNull);
  }

  void test_getResolutionErrors() {
    ResolveHtmlTask task = new ResolveHtmlTask(null, null, 0, null);
    expect(task.resolutionErrors, hasLength(0));
  }

  void test_getSource() {
    Source source = new TestSource('test.dart', '');
    ResolveHtmlTask task = new ResolveHtmlTask(null, source, 0, null);
    expect(task.source, same(source));
  }

  void test_perform_exception() {
    Source source = new TestSource();
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    ResolveHtmlTask task = new ResolveHtmlTask(context, source, 0, null);
    task.perform(new ResolveHtmlTaskTestTV_perform_exception());
  }

  void test_perform_valid() {
    int modificationStamp = 73;
    String content = r'''
<html>
<head>
  <script type='application/dart'>
    void f() { x = 0; }
  </script>
</head>
<body>
</body>
</html>''';
    Source source = new TestSource("/test.html", content);
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    ParseHtmlTask parseTask =
        new ParseHtmlTask(context, source, content);
    parseTask.perform(new ResolveHtmlTaskTestTV_perform_valid_2());
    ResolveHtmlTask task = new ResolveHtmlTask(
        context,
        source,
        modificationStamp,
        parseTask.htmlUnit);
    task.perform(
        new ResolveHtmlTaskTestTV_perform_valid(modificationStamp, source));
  }
}


class ResolveHtmlTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitResolveHtmlTask(ResolveHtmlTask task) => true;
}


class ResolveHtmlTaskTestTV_perform_exception extends TestTaskVisitor<bool> {
  @override
  bool visitResolveHtmlTask(ResolveHtmlTask task) {
    expect(task.exception, isNotNull);
    return true;
  }
}


class ResolveHtmlTaskTestTV_perform_valid extends TestTaskVisitor<Object> {
  int modificationStamp;
  Source source;
  ResolveHtmlTaskTestTV_perform_valid(this.modificationStamp, this.source);
  @override
  Object visitResolveHtmlTask(ResolveHtmlTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.element, isNotNull);
    expect(task.resolutionErrors, hasLength(1));
    expect(task.source, same(source));
    return null;
  }
}


class ResolveHtmlTaskTestTV_perform_valid_2 extends TestTaskVisitor<Object> {
  @override
  Object visitParseHtmlTask(ParseHtmlTask task) => null;
}


class ScanDartTaskTest extends EngineTestCase {
  void test_accept() {
    ScanDartTask task = new ScanDartTask(null, null, null);
    expect(task.accept(new ScanDartTaskTestTV_accept()), isTrue);
  }

  void test_getErrors() {
    ScanDartTask task = new ScanDartTask(null, null, null);
    expect(task.errors, hasLength(0));
  }

  void test_getException() {
    ScanDartTask task = new ScanDartTask(null, null, null);
    expect(task.exception, isNull);
  }

  void test_getLineInfo() {
    ScanDartTask task = new ScanDartTask(null, null, null);
    expect(task.lineInfo, isNull);
  }

  void test_getSource() {
    Source source = new TestSource('test.dart', '');
    ScanDartTask task = new ScanDartTask(null, source, null);
    expect(task.source, same(source));
  }

  void test_perform_valid() {
    String content = 'class A {}';
    Source source = new TestSource('test.dart', content);
    InternalAnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([new FileUriResolver()]);
    ScanDartTask task =
        new ScanDartTask(context, source, content);
    task.perform(new ScanDartTaskTestTV_perform_valid(context, source));
  }
}


class ScanDartTaskTestTV_accept extends TestTaskVisitor<bool> {
  @override
  bool visitScanDartTask(ScanDartTask task) => true;
}


class ScanDartTaskTestTV_perform_valid extends TestTaskVisitor<bool> {
  InternalAnalysisContext context;
  Source source;
  ScanDartTaskTestTV_perform_valid(this.context, this.source);
  @override
  bool visitScanDartTask(ScanDartTask task) {
    CaughtException exception = task.exception;
    if (exception != null) {
      throw exception;
    }
    expect(task.tokenStream, isNotNull);
    expect(task.errors, hasLength(0));
    expect(task.lineInfo, isNotNull);
    expect(task.source, same(source));
    return true;
  }
}


class SdkCachePartitionTest extends EngineTestCase {
  void test_contains_false() {
    SdkCachePartition partition = new SdkCachePartition(null, 8);
    Source source = new TestSource();
    expect(partition.contains(source), isFalse);
  }

  void test_contains_true() {
    SdkCachePartition partition = new SdkCachePartition(null, 8);
    SourceFactory factory =
        new SourceFactory([new DartUriResolver(DirectoryBasedDartSdk.defaultSdk)]);
    Source source = factory.forUri("dart:core");
    expect(partition.contains(source), isTrue);
  }

  void test_creation() {
    expect(new SdkCachePartition(null, 8), isNotNull);
  }
}


/**
 * Instances of the class `TestAnalysisContext` implement an analysis context in which every
 * method will cause a test to fail when invoked.
 */
class TestAnalysisContext implements InternalAnalysisContext {
  @override
  AnalysisOptions get analysisOptions {
    fail("Unexpected invocation of getAnalysisOptions");
    return null;
  }
  @override
  void set analysisOptions(AnalysisOptions options) {
    fail("Unexpected invocation of setAnalysisOptions");
  }
  @override
  void set analysisPriorityOrder(List<Source> sources) {
    fail("Unexpected invocation of setAnalysisPriorityOrder");
  }
  @override
  DeclaredVariables get declaredVariables {
    fail("Unexpected invocation of getDeclaredVariables");
    return null;
  }
  @override
  List<Source> get htmlSources {
    fail("Unexpected invocation of getHtmlSources");
    return null;
  }
  @override
  bool get isDisposed {
    fail("Unexpected invocation of isDisposed");
    return false;
  }
  @override
  List<Source> get launchableClientLibrarySources {
    fail("Unexpected invocation of getLaunchableClientLibrarySources");
    return null;
  }
  @override
  List<Source> get launchableServerLibrarySources {
    fail("Unexpected invocation of getLaunchableServerLibrarySources");
    return null;
  }
  @override
  List<Source> get librarySources {
    fail("Unexpected invocation of getLibrarySources");
    return null;
  }
  @override
  List<Source> get prioritySources {
    fail("Unexpected invocation of getPrioritySources");
    return null;
  }
  @override
  List<Source> get refactoringUnsafeSources {
    fail("Unexpected invocation of getRefactoringUnsafeSources");
    return null;
  }
  @override
  SourceFactory get sourceFactory {
    fail("Unexpected invocation of getSourceFactory");
    return null;
  }
  @override
  void set sourceFactory(SourceFactory factory) {
    fail("Unexpected invocation of setSourceFactory");
  }
  @override
  AnalysisContextStatistics get statistics {
    fail("Unexpected invocation of getStatistics");
    return null;
  }
  @override
  TypeProvider get typeProvider {
    fail("Unexpected invocation of getTypeProvider");
    return null;
  }
  @override
  void addListener(AnalysisListener listener) {
    fail("Unexpected invocation of addListener");
  }
  @override
  void addSourceInfo(Source source, SourceEntry info) {
    fail("Unexpected invocation of addSourceInfo");
  }
  @override
  void applyAnalysisDelta(AnalysisDelta delta) {
    fail("Unexpected invocation of applyAnalysisDelta");
  }
  @override
  void applyChanges(ChangeSet changeSet) {
    fail("Unexpected invocation of applyChanges");
  }
  @override
  String computeDocumentationComment(Element element) {
    fail("Unexpected invocation of computeDocumentationComment");
    return null;
  }
  @override
  List<AnalysisError> computeErrors(Source source) {
    fail("Unexpected invocation of computeErrors");
    return null;
  }
  @override
  List<Source> computeExportedLibraries(Source source) {
    fail("Unexpected invocation of computeExportedLibraries");
    return null;
  }
  @override
  HtmlElement computeHtmlElement(Source source) {
    fail("Unexpected invocation of computeHtmlElement");
    return null;
  }
  @override
  List<Source> computeImportedLibraries(Source source) {
    fail("Unexpected invocation of computeImportedLibraries");
    return null;
  }
  @override
  SourceKind computeKindOf(Source source) {
    fail("Unexpected invocation of computeKindOf");
    return null;
  }
  @override
  LibraryElement computeLibraryElement(Source source) {
    fail("Unexpected invocation of computeLibraryElement");
    return null;
  }
  @override
  LineInfo computeLineInfo(Source source) {
    fail("Unexpected invocation of computeLineInfo");
    return null;
  }
  @override
  CompilationUnit computeResolvableCompilationUnit(Source source) {
    fail("Unexpected invocation of computeResolvableCompilationUnit");
    return null;
  }
  @override
  void dispose() {
    fail("Unexpected invocation of dispose");
  }
  @override
  bool exists(Source source) {
    fail("Unexpected invocation of exists");
    return false;
  }
  @override
  AngularApplication getAngularApplicationWithHtml(Source htmlSource) {
    fail("Unexpected invocation of getAngularApplicationWithHtml");
    return null;
  }
  @override
  CompilationUnitElement getCompilationUnitElement(Source unitSource,
      Source librarySource) {
    fail("Unexpected invocation of getCompilationUnitElement");
    return null;
  }
  @override
  TimestampedData<String> getContents(Source source) {
    fail("Unexpected invocation of getContents");
    return null;
  }
  @override
  InternalAnalysisContext getContextFor(Source source) {
    fail("Unexpected invocation of getContextFor");
    return null;
  }
  @override
  Element getElement(ElementLocation location) {
    fail("Unexpected invocation of getElement");
    return null;
  }
  @override
  AnalysisErrorInfo getErrors(Source source) {
    fail("Unexpected invocation of getErrors");
    return null;
  }
  @override
  HtmlElement getHtmlElement(Source source) {
    fail("Unexpected invocation of getHtmlElement");
    return null;
  }
  @override
  List<Source> getHtmlFilesReferencing(Source source) {
    fail("Unexpected invocation of getHtmlFilesReferencing");
    return null;
  }
  @override
  SourceKind getKindOf(Source source) {
    fail("Unexpected invocation of getKindOf");
    return null;
  }
  @override
  List<Source> getLibrariesContaining(Source source) {
    fail("Unexpected invocation of getLibrariesContaining");
    return null;
  }
  @override
  List<Source> getLibrariesDependingOn(Source librarySource) {
    fail("Unexpected invocation of getLibrariesDependingOn");
    return null;
  }
  @override
  List<Source> getLibrariesReferencedFromHtml(Source htmlSource) {
    fail("Unexpected invocation of getLibrariesReferencedFromHtml");
    return null;
  }
  @override
  LibraryElement getLibraryElement(Source source) {
    fail("Unexpected invocation of getLibraryElement");
    return null;
  }
  @override
  LineInfo getLineInfo(Source source) {
    fail("Unexpected invocation of getLineInfo");
    return null;
  }
  @override
  int getModificationStamp(Source source) {
    fail("Unexpected invocation of getModificationStamp");
    return 0;
  }
  @override
  Namespace getPublicNamespace(LibraryElement library) {
    fail("Unexpected invocation of getPublicNamespace");
    return null;
  }
  @override
  CompilationUnit getResolvedCompilationUnit(Source unitSource,
      LibraryElement library) {
    fail("Unexpected invocation of getResolvedCompilationUnit");
    return null;
  }
  @override
  CompilationUnit getResolvedCompilationUnit2(Source unitSource,
      Source librarySource) {
    fail("Unexpected invocation of getResolvedCompilationUnit");
    return null;
  }
  @override
  ht.HtmlUnit getResolvedHtmlUnit(Source htmlSource) {
    fail("Unexpected invocation of getResolvedHtmlUnit");
    return null;
  }
  @override
  bool isClientLibrary(Source librarySource) {
    fail("Unexpected invocation of isClientLibrary");
    return false;
  }
  @override
  bool isServerLibrary(Source librarySource) {
    fail("Unexpected invocation of isServerLibrary");
    return false;
  }
  @override
  CompilationUnit parseCompilationUnit(Source source) {
    fail("Unexpected invocation of parseCompilationUnit");
    return null;
  }
  @override
  ht.HtmlUnit parseHtmlUnit(Source source) {
    fail("Unexpected invocation of parseHtmlUnit");
    return null;
  }
  @override
  AnalysisResult performAnalysisTask() {
    fail("Unexpected invocation of performAnalysisTask");
    return null;
  }
  @override
  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    fail("Unexpected invocation of recordLibraryElements");
  }
  @override
  void removeListener(AnalysisListener listener) {
    fail("Unexpected invocation of removeListener");
  }
  @override
  CompilationUnit resolveCompilationUnit(Source unitSource,
      LibraryElement library) {
    fail("Unexpected invocation of resolveCompilationUnit");
    return null;
  }
  @override
  CompilationUnit resolveCompilationUnit2(Source unitSource,
      Source librarySource) {
    fail("Unexpected invocation of resolveCompilationUnit");
    return null;
  }
  @override
  ht.HtmlUnit resolveHtmlUnit(Source htmlSource) {
    fail("Unexpected invocation of resolveHtmlUnit");
    return null;
  }
  @override
  void setChangedContents(Source source, String contents, int offset,
      int oldLength, int newLength) {
    fail("Unexpected invocation of setChangedContents");
  }
  @override
  void setContents(Source source, String contents) {
    fail("Unexpected invocation of setContents");
  }
  @override
  void visitCacheItems(void callback(Source source, SourceEntry dartEntry,
                                     DataDescriptor rowDesc,
                                     CacheState state)) {
    fail("Unexpected invocation of visitCacheItems");
  }
}


class TestAnalysisContext_test_addSourceInfo extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_addSourceInfo();
  @override
  void addSourceInfo(Source source, SourceEntry info) {
    invoked = true;
  }
}


class TestAnalysisContext_test_applyChanges extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_applyChanges();
  @override
  void applyChanges(ChangeSet changeSet) {
    invoked = true;
  }
}


class TestAnalysisContext_test_computeDocumentationComment extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_computeDocumentationComment();
  @override
  String computeDocumentationComment(Element element) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_computeErrors extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_computeErrors();
  @override
  List<AnalysisError> computeErrors(Source source) {
    invoked = true;
    return AnalysisError.NO_ERRORS;
  }
}


class TestAnalysisContext_test_computeExportedLibraries extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_computeExportedLibraries();
  @override
  List<Source> computeExportedLibraries(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_computeHtmlElement extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_computeHtmlElement();
  @override
  HtmlElement computeHtmlElement(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_computeImportedLibraries extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_computeImportedLibraries();
  @override
  List<Source> computeImportedLibraries(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_computeKindOf extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_computeKindOf();
  @override
  SourceKind computeKindOf(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_computeLibraryElement extends TestAnalysisContext
    {
  bool invoked = false;
  TestAnalysisContext_test_computeLibraryElement();
  @override
  LibraryElement computeLibraryElement(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_computeLineInfo extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_computeLineInfo();
  @override
  LineInfo computeLineInfo(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_computeResolvableCompilationUnit extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_computeResolvableCompilationUnit();
  @override
  CompilationUnit computeResolvableCompilationUnit(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_dispose extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_dispose();
  @override
  void dispose() {
    invoked = true;
  }
}


class TestAnalysisContext_test_exists extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_exists();
  @override
  bool exists(Source source) {
    invoked = true;
    return false;
  }
}


class TestAnalysisContext_test_getAnalysisOptions extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getAnalysisOptions();
  @override
  AnalysisOptions get analysisOptions {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getAngularApplicationWithHtml extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getAngularApplicationWithHtml();
  @override
  AngularApplication getAngularApplicationWithHtml(Source htmlSource) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getCompilationUnitElement extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getCompilationUnitElement();
  @override
  CompilationUnitElement getCompilationUnitElement(Source unitSource,
      Source librarySource) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getContents extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getContents();
  @override
  TimestampedData<String> getContents(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getElement extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getElement();
  @override
  Element getElement(ElementLocation location) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getErrors extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getErrors();
  @override
  AnalysisErrorInfo getErrors(Source source) {
    invoked = true;
    return new AnalysisErrorInfoImpl(AnalysisError.NO_ERRORS, null);
  }
}


class TestAnalysisContext_test_getHtmlElement extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getHtmlElement();
  @override
  HtmlElement getHtmlElement(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getHtmlFilesReferencing extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getHtmlFilesReferencing();
  @override
  List<Source> getHtmlFilesReferencing(Source source) {
    invoked = true;
    return Source.EMPTY_ARRAY;
  }
}


class TestAnalysisContext_test_getHtmlSources extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getHtmlSources();
  @override
  List<Source> get htmlSources {
    invoked = true;
    return Source.EMPTY_ARRAY;
  }
}


class TestAnalysisContext_test_getKindOf extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getKindOf();
  @override
  SourceKind getKindOf(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getLaunchableClientLibrarySources extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getLaunchableClientLibrarySources();
  @override
  List<Source> get launchableClientLibrarySources {
    invoked = true;
    return Source.EMPTY_ARRAY;
  }
}


class TestAnalysisContext_test_getLaunchableServerLibrarySources extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getLaunchableServerLibrarySources();
  @override
  List<Source> get launchableServerLibrarySources {
    invoked = true;
    return Source.EMPTY_ARRAY;
  }
}


class TestAnalysisContext_test_getLibrariesContaining extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getLibrariesContaining();
  @override
  List<Source> getLibrariesContaining(Source source) {
    invoked = true;
    return Source.EMPTY_ARRAY;
  }
}


class TestAnalysisContext_test_getLibrariesDependingOn extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getLibrariesDependingOn();
  @override
  List<Source> getLibrariesDependingOn(Source librarySource) {
    invoked = true;
    return Source.EMPTY_ARRAY;
  }
}


class TestAnalysisContext_test_getLibrariesReferencedFromHtml extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getLibrariesReferencedFromHtml();
  @override
  List<Source> getLibrariesReferencedFromHtml(Source htmlSource) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getLibraryElement extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getLibraryElement();
  @override
  LibraryElement getLibraryElement(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getLibrarySources extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getLibrarySources();
  @override
  List<Source> get librarySources {
    invoked = true;
    return Source.EMPTY_ARRAY;
  }
}


class TestAnalysisContext_test_getLineInfo extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getLineInfo();
  @override
  LineInfo getLineInfo(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getModificationStamp extends TestAnalysisContext
    {
  bool invoked = false;
  TestAnalysisContext_test_getModificationStamp();
  @override
  int getModificationStamp(Source source) {
    invoked = true;
    return 0;
  }
}


class TestAnalysisContext_test_getPublicNamespace extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getPublicNamespace();
  @override
  Namespace getPublicNamespace(LibraryElement library) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getRefactoringUnsafeSources extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getRefactoringUnsafeSources();
  @override
  List<Source> get refactoringUnsafeSources {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getResolvedCompilationUnit_element extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getResolvedCompilationUnit_element();
  @override
  CompilationUnit getResolvedCompilationUnit(Source unitSource,
      LibraryElement library) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getResolvedCompilationUnit_source extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getResolvedCompilationUnit_source();
  @override
  CompilationUnit getResolvedCompilationUnit2(Source unitSource,
      Source librarySource) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getResolvedHtmlUnit extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getResolvedHtmlUnit();
  @override
  ht.HtmlUnit getResolvedHtmlUnit(Source htmlSource) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getSourceFactory extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getSourceFactory();
  @override
  SourceFactory get sourceFactory {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getStatistics extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getStatistics();
  @override
  AnalysisContextStatistics get statistics {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_getTypeProvider extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_getTypeProvider();
  @override
  TypeProvider get typeProvider {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_isClientLibrary extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_isClientLibrary();
  @override
  bool isClientLibrary(Source librarySource) {
    invoked = true;
    return false;
  }
}


class TestAnalysisContext_test_isDisposed extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_isDisposed();
  @override
  bool get isDisposed {
    invoked = true;
    return false;
  }
}


class TestAnalysisContext_test_isServerLibrary extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_isServerLibrary();
  @override
  bool isServerLibrary(Source librarySource) {
    invoked = true;
    return false;
  }
}


class TestAnalysisContext_test_parseCompilationUnit extends TestAnalysisContext
    {
  bool invoked = false;
  TestAnalysisContext_test_parseCompilationUnit();
  @override
  CompilationUnit parseCompilationUnit(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_parseHtmlUnit extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_parseHtmlUnit();
  @override
  ht.HtmlUnit parseHtmlUnit(Source source) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_performAnalysisTask extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_performAnalysisTask();
  @override
  AnalysisResult performAnalysisTask() {
    invoked = true;
    return new AnalysisResult(new List<ChangeNotice>(0), 0, null, 0);
  }
}


class TestAnalysisContext_test_recordLibraryElements extends TestAnalysisContext
    {
  bool invoked = false;
  TestAnalysisContext_test_recordLibraryElements();
  @override
  void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
    invoked = true;
  }
}


class TestAnalysisContext_test_resolveCompilationUnit extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_resolveCompilationUnit();
  @override
  CompilationUnit resolveCompilationUnit2(Source unitSource,
      Source librarySource) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_resolveCompilationUnit_element extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_resolveCompilationUnit_element();
  @override
  CompilationUnit resolveCompilationUnit(Source unitSource,
      LibraryElement library) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_resolveHtmlUnit extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_resolveHtmlUnit();
  @override
  ht.HtmlUnit resolveHtmlUnit(Source htmlSource) {
    invoked = true;
    return null;
  }
}


class TestAnalysisContext_test_setAnalysisOptions extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_setAnalysisOptions();
  @override
  void set analysisOptions(AnalysisOptions options) {
    invoked = true;
  }
}


class TestAnalysisContext_test_setAnalysisPriorityOrder extends
    TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_setAnalysisPriorityOrder();
  @override
  void set analysisPriorityOrder(List<Source> sources) {
    invoked = true;
  }
}


class TestAnalysisContext_test_setChangedContents extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_setChangedContents();
  @override
  void setChangedContents(Source source, String contents, int offset,
      int oldLength, int newLength) {
    invoked = true;
  }
}


class TestAnalysisContext_test_setContents extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_setContents();
  @override
  void setContents(Source source, String contents) {
    invoked = true;
  }
}


class TestAnalysisContext_test_setSourceFactory extends TestAnalysisContext {
  bool invoked = false;
  TestAnalysisContext_test_setSourceFactory();
  @override
  void set sourceFactory(SourceFactory factory) {
    invoked = true;
  }
}


/**
 * Instances of the class `TestTaskVisitor` implement a task visitor that fails if any of its
 * methods are invoked. Subclasses typically override the expected methods to not cause a test
 * failure.
 */
class TestTaskVisitor<E> implements AnalysisTaskVisitor<E> {
  @override
  E visitBuildUnitElementTask(BuildUnitElementTask task) {
    fail("Unexpectedly invoked visitGenerateDartErrorsTask");
    return null;
  }

  @override
  E visitGenerateDartErrorsTask(GenerateDartErrorsTask task) {
    fail("Unexpectedly invoked visitGenerateDartErrorsTask");
    return null;
  }
  @override
  E visitGenerateDartHintsTask(GenerateDartHintsTask task) {
    fail("Unexpectedly invoked visitGenerateDartHintsTask");
    return null;
  }
  @override
  E visitGetContentTask(GetContentTask task) {
    fail("Unexpectedly invoked visitGetContentsTask");
    return null;
  }
  @override
  E
      visitIncrementalAnalysisTask(IncrementalAnalysisTask incrementalAnalysisTask) {
    fail("Unexpectedly invoked visitIncrementalAnalysisTask");
    return null;
  }
  @override
  E visitParseDartTask(ParseDartTask task) {
    fail("Unexpectedly invoked visitParseDartTask");
    return null;
  }
  @override
  E visitParseHtmlTask(ParseHtmlTask task) {
    fail("Unexpectedly invoked visitParseHtmlTask");
    return null;
  }
  @override
  E visitPolymerBuildHtmlTask(PolymerBuildHtmlTask task) {
    fail("Unexpectedly invoked visitPolymerBuildHtmlTask");
    return null;
  }
  @override
  E visitPolymerResolveHtmlTask(PolymerResolveHtmlTask task) {
    fail("Unexpectedly invoked visitPolymerResolveHtmlTask");
    return null;
  }
  @override
  E
      visitResolveAngularComponentTemplateTask(ResolveAngularComponentTemplateTask task) {
    fail("Unexpectedly invoked visitResolveAngularComponentTemplateTask");
    return null;
  }
  @override
  E visitResolveAngularEntryHtmlTask(ResolveAngularEntryHtmlTask task) {
    fail("Unexpectedly invoked visitResolveAngularEntryHtmlTask");
    return null;
  }
  @override
  E visitResolveDartLibraryCycleTask(ResolveDartLibraryCycleTask task) {
    fail("Unexpectedly invoked visitResolveDartLibraryCycleTask");
    return null;
  }
  @override
  E visitResolveDartLibraryTask(ResolveDartLibraryTask task) {
    fail("Unexpectedly invoked visitResolveDartLibraryTask");
    return null;
  }
  @override
  E visitResolveDartUnitTask(ResolveDartUnitTask task) {
    fail("Unexpectedly invoked visitResolveDartUnitTask");
    return null;
  }
  @override
  E visitResolveHtmlTask(ResolveHtmlTask task) {
    fail("Unexpectedly invoked visitResolveHtmlTask");
    return null;
  }
  @override
  E visitScanDartTask(ScanDartTask task) {
    fail("Unexpectedly invoked visitScanDartTask");
    return null;
  }
}


class UniversalCachePartitionTest extends EngineTestCase {
  void test_contains() {
    UniversalCachePartition partition =
        new UniversalCachePartition(null, 8, null);
    TestSource source = new TestSource();
    expect(partition.contains(source), isTrue);
  }
  void test_creation() {
    expect(new UniversalCachePartition(null, 8, null), isNotNull);
  }
  void test_entrySet() {
    UniversalCachePartition partition =
        new UniversalCachePartition(null, 8, null);
    TestSource source = new TestSource();
    DartEntry entry = new DartEntry();
    partition.put(source, entry);
    Map<Source, SourceEntry> entryMap = partition.map;
    expect(entryMap.length, 1);
    Source entryKey = entryMap.keys.first;
    expect(entryKey, same(source));
    expect(entryMap[entryKey], same(entry));
  }
  void test_get() {
    UniversalCachePartition partition =
        new UniversalCachePartition(null, 8, null);
    TestSource source = new TestSource();
    expect(partition.get(source), isNull);
  }
  void test_put_noFlush() {
    UniversalCachePartition partition =
        new UniversalCachePartition(null, 8, null);
    TestSource source = new TestSource();
    DartEntry entry = new DartEntry();
    partition.put(source, entry);
    expect(partition.get(source), same(entry));
  }
  void test_remove() {
    UniversalCachePartition partition =
        new UniversalCachePartition(null, 8, null);
    TestSource source = new TestSource();
    DartEntry entry = new DartEntry();
    partition.put(source, entry);
    expect(partition.get(source), same(entry));
    partition.remove(source);
    expect(partition.get(source), isNull);
  }
  void test_setMaxCacheSize() {
    UniversalCachePartition partition = new UniversalCachePartition(
        null,
        8,
        new _UniversalCachePartitionTest_test_setMaxCacheSize());
    int size = 6;
    for (int i = 0; i < size; i++) {
      Source source = new TestSource("/test$i.dart");
      DartEntry entry = new DartEntry();
      entry.setValue(DartEntry.PARSED_UNIT, null);
      partition.put(source, entry);
      partition.accessedAst(source);
    }
    _assertNonFlushedCount(size, partition);
    int newSize = size - 2;
    partition.maxCacheSize = newSize;
    _assertNonFlushedCount(newSize, partition);
  }
  void test_size() {
    UniversalCachePartition partition =
        new UniversalCachePartition(null, 8, null);
    int size = 4;
    for (int i = 0; i < size; i++) {
      Source source = new TestSource("/test$i.dart");
      partition.put(source, new DartEntry());
      partition.accessedAst(source);
    }
    expect(partition.size(), size);
  }
  void _assertNonFlushedCount(int expectedCount,
      UniversalCachePartition partition) {
    int nonFlushedCount = 0;
    Map<Source, SourceEntry> entryMap = partition.map;
    entryMap.values.forEach((SourceEntry value) {
      if (value.getState(DartEntry.PARSED_UNIT) != CacheState.FLUSHED) {
        nonFlushedCount++;
      }
    });
    expect(nonFlushedCount, expectedCount);
  }
}


class WorkManagerTest extends EngineTestCase {
  void test_addFirst() {
    TestSource source1 = new TestSource("/f1.dart");
    TestSource source2 = new TestSource("/f2.dart");
    WorkManager manager = new WorkManager();
    manager.add(source1, SourcePriority.UNKNOWN);
    manager.addFirst(source2, SourcePriority.UNKNOWN);
    WorkManager_WorkIterator iterator = manager.iterator();
    expect(iterator.next(), same(source2));
    expect(iterator.next(), same(source1));
  }
  void test_creation() {
    expect(new WorkManager(), isNotNull);
  }
  void test_iterator_empty() {
    WorkManager manager = new WorkManager();
    WorkManager_WorkIterator iterator = manager.iterator();
    expect(iterator.hasNext, isFalse);
    try {
      iterator.next();
      fail("Expected NoSuchElementException");
    } on NoSuchElementException catch (exception) {
    }
  }
  void test_iterator_nonEmpty() {
    TestSource source = new TestSource();
    WorkManager manager = new WorkManager();
    manager.add(source, SourcePriority.UNKNOWN);
    WorkManager_WorkIterator iterator = manager.iterator();
    expect(iterator.hasNext, isTrue);
    expect(iterator.next(), same(source));
  }
  void test_remove() {
    TestSource source1 = new TestSource("/f1.dart");
    TestSource source2 = new TestSource("/f2.dart");
    TestSource source3 = new TestSource("/f3.dart");
    WorkManager manager = new WorkManager();
    manager.add(source1, SourcePriority.UNKNOWN);
    manager.add(source2, SourcePriority.UNKNOWN);
    manager.add(source3, SourcePriority.UNKNOWN);
    manager.remove(source2);
    WorkManager_WorkIterator iterator = manager.iterator();
    expect(iterator.next(), same(source1));
    expect(iterator.next(), same(source3));
  }
  void test_toString_empty() {
    WorkManager manager = new WorkManager();
    expect(manager.toString(), isNotNull);
  }
  void test_toString_nonEmpty() {
    WorkManager manager = new WorkManager();
    manager.add(new TestSource(), SourcePriority.HTML);
    manager.add(new TestSource(), SourcePriority.LIBRARY);
    manager.add(new TestSource(), SourcePriority.NORMAL_PART);
    manager.add(new TestSource(), SourcePriority.PRIORITY_PART);
    manager.add(new TestSource(), SourcePriority.UNKNOWN);
    expect(manager.toString(), isNotNull);
  }
}


class _AnalysisCacheTest_test_setMaxCacheSize implements CacheRetentionPolicy {
  @override
  RetentionPriority getAstPriority(Source source, SourceEntry sourceEntry) =>
      RetentionPriority.LOW;
}


class _AnalysisContextImplTest_test_applyChanges_removeContainer implements
    SourceContainer {
  Source libB;
  _AnalysisContextImplTest_test_applyChanges_removeContainer(this.libB);
  @override
  bool contains(Source source) => source == libB;
}


class _AnalysisContext_sourceChangeDuringResolution extends
    AnalysisContextForTests {
  @override
  DartEntry recordResolveDartLibraryTaskResults(ResolveDartLibraryTask task) {
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedSource(task.librarySource);
    applyChanges(changeSet);
    return super.recordResolveDartLibraryTaskResults(task);
  }
}


class _UniversalCachePartitionTest_test_setMaxCacheSize implements
    CacheRetentionPolicy {
  @override
  RetentionPriority getAstPriority(Source source, SourceEntry sourceEntry) =>
      RetentionPriority.LOW;
}
