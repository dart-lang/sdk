// // Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
// // This code was auto-generated, is not intended to be edited, and is subject to
// // significant change. Please see the README file for more information.
// library engine.engine_test;
// import 'dart:collection';
// import 'package:analyzer/src/generated/ast.dart';
// import 'package:analyzer/src/generated/element.dart';
// import 'package:analyzer/src/generated/engine.dart';
// import 'package:analyzer/src/generated/error.dart';
// import 'package:analyzer/src/generated/java_core.dart';
// import 'package:analyzer/src/generated/java_engine.dart';
// import 'package:analyzer/src/generated/java_engine_io.dart';
// import 'package:analyzer/src/generated/java_io.dart';
// import 'package:analyzer/src/generated/java_junit.dart';
// import 'package:analyzer/src/generated/parser.dart';
// import 'package:analyzer/src/generated/resolver.dart';
// import 'package:analyzer/src/generated/scanner.dart';
// import 'package:analyzer/src/generated/source_io.dart';
// import 'package:unittest/unittest.dart' as _ut;
// import 'package:analyzer/src/generated/testing/ast_factory.dart';
// import 'package:analyzer/src/generated/testing/element_factory.dart';
// import 'resolver_test.dart';
// import 'test_support.dart';
// class AnalysisCacheTest extends EngineTestCase {
//   void test_creation() {
//     JUnitTestCase.assertNotNull(new AnalysisCache(new List<CachePartition>(0)));
//   }
//   void test_get() {
//     AnalysisCache cache = new AnalysisCache(new List<CachePartition>(0));
//     TestSource source = new TestSource();
//     JUnitTestCase.assertNull(cache.get(source));
//   }
//   void test_iterator() {
//     CachePartition partition = new UniversalCachePartition(8, new DefaultRetentionPolicy());
//     AnalysisCache cache = new AnalysisCache(<CachePartition> [partition]);
//     TestSource source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     cache.put(source, entry);
//     MapIterator<Source, SourceEntry> iterator = cache.iterator();
//     JUnitTestCase.assertTrue(iterator.moveNext());
//     JUnitTestCase.assertSame(source, iterator.key);
//     JUnitTestCase.assertSame(entry, iterator.value);
//     JUnitTestCase.assertFalse(iterator.moveNext());
//   }
//   void test_put_noFlush() {
//     CachePartition partition = new UniversalCachePartition(8, new DefaultRetentionPolicy());
//     AnalysisCache cache = new AnalysisCache(<CachePartition> [partition]);
//     TestSource source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     cache.put(source, entry);
//     JUnitTestCase.assertSame(entry, cache.get(source));
//   }
//   void test_setMaxCacheSize() {
//     CachePartition partition = new UniversalCachePartition(8, new CacheRetentionPolicy_AnalysisCacheTest_test_setMaxCacheSize());
//     AnalysisCache cache = new AnalysisCache(<CachePartition> [partition]);
//     int size = 6;
//     for (int i = 0; i < size; i++) {
//       Source source = new TestSource.con1(FileUtilities2.createFile("/test${i}.dart"), "");
//       DartEntryImpl entry = new DartEntryImpl();
//       entry.setValue(DartEntry.PARSED_UNIT, null);
//       cache.put(source, entry);
//       cache.accessedAst(source);
//     }
//     _assertNonFlushedCount(size, cache);
//     int newSize = size - 2;
//     partition.maxCacheSize = newSize;
//     _assertNonFlushedCount(newSize, cache);
//   }
//   void test_size() {
//     CachePartition partition = new UniversalCachePartition(8, new DefaultRetentionPolicy());
//     AnalysisCache cache = new AnalysisCache(<CachePartition> [partition]);
//     int size = 4;
//     for (int i = 0; i < size; i++) {
//       Source source = new TestSource.con1(FileUtilities2.createFile("/test${i}.dart"), "");
//       cache.put(source, new DartEntryImpl());
//       cache.accessedAst(source);
//     }
//     JUnitTestCase.assertEquals(size, cache.size());
//   }
//   void _assertNonFlushedCount(int expectedCount, AnalysisCache cache) {
//     int nonFlushedCount = 0;
//     MapIterator<Source, SourceEntry> iterator = cache.iterator();
//     while (iterator.moveNext()) {
//       if (iterator.value.getState(DartEntry.PARSED_UNIT) != CacheState.FLUSHED) {
//         nonFlushedCount++;
//       }
//     }
//     JUnitTestCase.assertEquals(expectedCount, nonFlushedCount);
//   }
//   static dartSuite() {
//     _ut.group('AnalysisCacheTest', () {
//       _ut.test('test_creation', () {
//         final __test = new AnalysisCacheTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_get', () {
//         final __test = new AnalysisCacheTest();
//         runJUnitTest(__test, __test.test_get);
//       });
//       _ut.test('test_iterator', () {
//         final __test = new AnalysisCacheTest();
//         runJUnitTest(__test, __test.test_iterator);
//       });
//       _ut.test('test_put_noFlush', () {
//         final __test = new AnalysisCacheTest();
//         runJUnitTest(__test, __test.test_put_noFlush);
//       });
//       _ut.test('test_setMaxCacheSize', () {
//         final __test = new AnalysisCacheTest();
//         runJUnitTest(__test, __test.test_setMaxCacheSize);
//       });
//       _ut.test('test_size', () {
//         final __test = new AnalysisCacheTest();
//         runJUnitTest(__test, __test.test_size);
//       });
//     });
//   }
// }
// class AnalysisContextImplTest extends EngineTestCase {
//   /**
//    * Returns `true` if there is an [AnalysisError] with [ErrorSeverity#ERROR] in
//    * the given [AnalysisErrorInfo].
//    */
//   static bool _hasAnalysisErrorWithErrorSeverity(AnalysisErrorInfo errorInfo) {
//     List<AnalysisError> errors = errorInfo.errors;
//     for (AnalysisError analysisError in errors) {
//       if (analysisError.errorCode.errorSeverity == ErrorSeverity.ERROR) {
//         return true;
//       }
//     }
//     return false;
//   }
//   /**
//    * An analysis context whose source factory is [sourceFactory].
//    */
//   AnalysisContextImpl _context;
//   /**
//    * The source factory associated with the analysis [context].
//    */
//   SourceFactory _sourceFactory;
//   void fail_extractContext() {
//     JUnitTestCase.fail("Implement this");
//   }
//   void fail_mergeContext() {
//     JUnitTestCase.fail("Implement this");
//   }
//   void fail_performAnalysisTask_importedLibraryDelete_html() {
//     Source htmlSource = _addSource("/page.html", EngineTestCase.createSource([
//         "<html><body><script type=\"application/dart\">",
//         "  import 'libB.dart';",
//         "  main() {print('hello dart');}",
//         "</script></body></html>"]));
//     Source libBSource = _addSource("/libB.dart", "library libB;");
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("htmlUnit resolved 1", _context.getResolvedHtmlUnit(htmlSource));
//     JUnitTestCase.assertNotNullMsg("libB resolved 1", _context.getResolvedCompilationUnit2(libBSource, libBSource));
//     JUnitTestCase.assertTrueMsg("htmlSource doesn't have errors", !_hasAnalysisErrorWithErrorSeverity(_context.getErrors(htmlSource)));
//     // remove libB.dart content and analyze
//     _context.setContents(libBSource, null);
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("htmlUnit resolved 1", _context.getResolvedHtmlUnit(htmlSource));
//     AnalysisErrorInfo errors = _context.getErrors(htmlSource);
//     JUnitTestCase.assertTrueMsg("htmlSource has an error", _hasAnalysisErrorWithErrorSeverity(errors));
//   }
//   void fail_recordLibraryElements() {
//     JUnitTestCase.fail("Implement this");
//   }
//   @override
//   void setUp() {
//     _context = new AnalysisContextImpl();
//     _sourceFactory = new SourceFactory([
//         new DartUriResolver(DirectoryBasedDartSdk.defaultSdk),
//         new FileUriResolver()]);
//     _context.sourceFactory = _sourceFactory;
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl.con1(_context.analysisOptions);
//     options.cacheSize = 256;
//     _context.analysisOptions = options;
//   }
//   void test_applyChanges_add() {
//     JUnitTestCase.assertTrue(_context.sourcesNeedingProcessing.isEmpty);
//     Source source = _addSource("/test.dart", "main() {}");
//     JUnitTestCase.assertTrue(_context.sourcesNeedingProcessing.contains(source));
//   }
//   void test_applyChanges_change_flush_element() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source librarySource = _addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "int a = 0;"]));
//     JUnitTestCase.assertNotNull(_context.computeLibraryElement(librarySource));
//     _context.setContents(librarySource, EngineTestCase.createSource(["library lib;", "int aa = 0;"]));
//     JUnitTestCase.assertNull(_context.getLibraryElement(librarySource));
//   }
//   void test_applyChanges_change_multiple() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source librarySource = _addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "part 'part.dart';", "int a = 0;"]));
//     Source partSource = _addSource("/part.dart", EngineTestCase.createSource(["part of lib;", "int b = a;"]));
//     _context.computeLibraryElement(librarySource);
//     _context.setContents(librarySource, EngineTestCase.createSource(["library lib;", "part 'part.dart';", "int aa = 0;"]));
//     _context.setContents(partSource, EngineTestCase.createSource(["part of lib;", "int b = aa;"]));
//     _context.computeLibraryElement(librarySource);
//     CompilationUnit libraryUnit = _context.resolveCompilationUnit2(librarySource, librarySource);
//     CompilationUnit partUnit = _context.resolveCompilationUnit2(partSource, librarySource);
//     TopLevelVariableDeclaration declaration = libraryUnit.declarations[0] as TopLevelVariableDeclaration;
//     Element declarationElement = declaration.variables.variables[0].element;
//     TopLevelVariableDeclaration use = partUnit.declarations[0] as TopLevelVariableDeclaration;
//     Element useElement = (use.variables.variables[0].initializer as SimpleIdentifier).staticElement;
//     JUnitTestCase.assertSame(declarationElement, (useElement as PropertyAccessorElement).variable);
//   }
//   void test_applyChanges_empty() {
//     _context.applyChanges(new ChangeSet());
//     JUnitTestCase.assertNull(_context.performAnalysisTask().changeNotices);
//   }
//   void test_applyChanges_overriddenSource() {
//     // Note: addSource adds the source to the contentCache.
//     Source source = _addSource("/test.dart", "library test;");
//     _context.computeErrors(source);
//     while (!_context.sourcesNeedingProcessing.isEmpty) {
//       _context.performAnalysisTask();
//     }
//     // Adding the source as a changedSource should have no effect since it is already overridden
//     // in the content cache.
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.changedSource(source);
//     _context.applyChanges(changeSet);
//     EngineTestCase.assertSizeOfList(0, _context.sourcesNeedingProcessing);
//   }
//   void test_applyChanges_remove() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source libA = _addSource("/libA.dart", EngineTestCase.createSource(["library libA;", "import 'libB.dart';"]));
//     Source libB = _addSource("/libB.dart", EngineTestCase.createSource(["library libB;"]));
//     LibraryElement libAElement = _context.computeLibraryElement(libA);
//     List<LibraryElement> importedLibraries = libAElement.importedLibraries;
//     EngineTestCase.assertLength(2, importedLibraries);
//     _context.computeErrors(libA);
//     _context.computeErrors(libB);
//     EngineTestCase.assertSizeOfList(0, _context.sourcesNeedingProcessing);
//     _context.setContents(libB, null);
//     _removeSource(libB);
//     List<Source> sources = _context.sourcesNeedingProcessing;
//     EngineTestCase.assertSizeOfList(1, sources);
//     JUnitTestCase.assertSame(libA, sources[0]);
//     libAElement = _context.computeLibraryElement(libA);
//     importedLibraries = libAElement.importedLibraries;
//     EngineTestCase.assertLength(1, importedLibraries);
//   }
//   void test_applyChanges_removeContainer() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source libA = _addSource("/libA.dart", EngineTestCase.createSource(["library libA;", "import 'libB.dart';"]));
//     Source libB = _addSource("/libB.dart", EngineTestCase.createSource(["library libB;"]));
//     _context.computeLibraryElement(libA);
//     _context.computeErrors(libA);
//     _context.computeErrors(libB);
//     EngineTestCase.assertSizeOfList(0, _context.sourcesNeedingProcessing);
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.removedContainer(new SourceContainer_AnalysisContextImplTest_test_applyChanges_removeContainer(libB));
//     _context.applyChanges(changeSet);
//     List<Source> sources = _context.sourcesNeedingProcessing;
//     EngineTestCase.assertSizeOfList(1, sources);
//     JUnitTestCase.assertSame(libA, sources[0]);
//   }
//   void test_computeDocumentationComment_block() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     String comment = "/** Comment */";
//     Source source = _addSource("/test.dart", EngineTestCase.createSource([comment, "class A {}"]));
//     LibraryElement libraryElement = _context.computeLibraryElement(source);
//     JUnitTestCase.assertNotNull(libraryElement);
//     ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
//     JUnitTestCase.assertNotNull(libraryElement);
//     JUnitTestCase.assertEquals(comment, _context.computeDocumentationComment(classElement));
//   }
//   void test_computeDocumentationComment_none() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/test.dart", EngineTestCase.createSource(["class A {}"]));
//     LibraryElement libraryElement = _context.computeLibraryElement(source);
//     JUnitTestCase.assertNotNull(libraryElement);
//     ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
//     JUnitTestCase.assertNotNull(libraryElement);
//     JUnitTestCase.assertNull(_context.computeDocumentationComment(classElement));
//   }
//   void test_computeDocumentationComment_null() {
//     JUnitTestCase.assertNull(_context.computeDocumentationComment(null));
//   }
//   void test_computeDocumentationComment_singleLine_multiple_EOL_n() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     String comment = "/// line 1\n/// line 2\n/// line 3\n";
//     Source source = _addSource("/test.dart", "${comment}class A {}");
//     LibraryElement libraryElement = _context.computeLibraryElement(source);
//     JUnitTestCase.assertNotNull(libraryElement);
//     ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
//     JUnitTestCase.assertNotNull(libraryElement);
//     String actual = _context.computeDocumentationComment(classElement);
//     JUnitTestCase.assertEquals("/// line 1\n/// line 2\n/// line 3", actual);
//   }
//   void test_computeDocumentationComment_singleLine_multiple_EOL_rn() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     String comment = "/// line 1\r\n/// line 2\r\n/// line 3\r\n";
//     Source source = _addSource("/test.dart", "${comment}class A {}");
//     LibraryElement libraryElement = _context.computeLibraryElement(source);
//     JUnitTestCase.assertNotNull(libraryElement);
//     ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
//     JUnitTestCase.assertNotNull(libraryElement);
//     String actual = _context.computeDocumentationComment(classElement);
//     JUnitTestCase.assertEquals("/// line 1\n/// line 2\n/// line 3", actual);
//   }
//   void test_computeErrors_dart_none() {
//     Source source = _addSource("/lib.dart", "library lib;");
//     List<AnalysisError> errors = _context.computeErrors(source);
//     EngineTestCase.assertLength(0, errors);
//   }
//   void test_computeErrors_dart_part() {
//     Source librarySource = _addSource("/lib.dart", "library lib; part 'part.dart';");
//     Source partSource = _addSource("/part.dart", "part of 'lib';");
//     _context.parseCompilationUnit(librarySource);
//     List<AnalysisError> errors = _context.computeErrors(partSource);
//     JUnitTestCase.assertNotNull(errors);
//     JUnitTestCase.assertTrue(errors.length > 0);
//   }
//   void test_computeErrors_dart_some() {
//     Source source = _addSource("/lib.dart", "library 'lib';");
//     List<AnalysisError> errors = _context.computeErrors(source);
//     JUnitTestCase.assertNotNull(errors);
//     JUnitTestCase.assertTrue(errors.length > 0);
//   }
//   void test_computeErrors_html_none() {
//     Source source = _addSource("/test.html", "<html></html>");
//     List<AnalysisError> errors = _context.computeErrors(source);
//     EngineTestCase.assertLength(0, errors);
//   }
//   void test_computeExportedLibraries_none() {
//     Source source = _addSource("/test.dart", "library test;");
//     EngineTestCase.assertLength(0, _context.computeExportedLibraries(source));
//   }
//   void test_computeExportedLibraries_some() {
//     //    addSource("/lib1.dart", "library lib1;");
//     //    addSource("/lib2.dart", "library lib2;");
//     Source source = _addSource("/test.dart", "library test; export 'lib1.dart'; export 'lib2.dart';");
//     EngineTestCase.assertLength(2, _context.computeExportedLibraries(source));
//   }
//   void test_computeHtmlElement_nonHtml() {
//     Source source = _addSource("/test.dart", "library test;");
//     JUnitTestCase.assertNull(_context.computeHtmlElement(source));
//   }
//   void test_computeHtmlElement_valid() {
//     Source source = _addSource("/test.html", "<html></html>");
//     HtmlElement element = _context.computeHtmlElement(source);
//     JUnitTestCase.assertNotNull(element);
//     JUnitTestCase.assertSame(element, _context.computeHtmlElement(source));
//   }
//   void test_computeImportedLibraries_none() {
//     Source source = _addSource("/test.dart", "library test;");
//     EngineTestCase.assertLength(0, _context.computeImportedLibraries(source));
//   }
//   void test_computeImportedLibraries_some() {
//     //    addSource("/lib1.dart", "library lib1;");
//     //    addSource("/lib2.dart", "library lib2;");
//     Source source = _addSource("/test.dart", "library test; import 'lib1.dart'; import 'lib2.dart';");
//     EngineTestCase.assertLength(2, _context.computeImportedLibraries(source));
//   }
//   void test_computeKindOf_html() {
//     Source source = _addSource("/test.html", "");
//     JUnitTestCase.assertSame(SourceKind.HTML, _context.computeKindOf(source));
//   }
//   void test_computeKindOf_library() {
//     Source source = _addSource("/test.dart", "library lib;");
//     JUnitTestCase.assertSame(SourceKind.LIBRARY, _context.computeKindOf(source));
//   }
//   void test_computeKindOf_libraryAndPart() {
//     Source source = _addSource("/test.dart", "library lib; part of lib;");
//     JUnitTestCase.assertSame(SourceKind.LIBRARY, _context.computeKindOf(source));
//   }
//   void test_computeKindOf_part() {
//     Source source = _addSource("/test.dart", "part of lib;");
//     JUnitTestCase.assertSame(SourceKind.PART, _context.computeKindOf(source));
//   }
//   void test_computeLibraryElement() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/test.dart", "library lib;");
//     LibraryElement element = _context.computeLibraryElement(source);
//     JUnitTestCase.assertNotNull(element);
//   }
//   void test_computeLineInfo_dart() {
//     Source source = _addSource("/test.dart", EngineTestCase.createSource(["library lib;", "", "main() {}"]));
//     LineInfo info = _context.computeLineInfo(source);
//     JUnitTestCase.assertNotNull(info);
//   }
//   void test_computeLineInfo_html() {
//     Source source = _addSource("/test.html", EngineTestCase.createSource([
//         "<html>",
//         "  <body>",
//         "    <h1>A</h1>",
//         "  </body>",
//         "</html>"]));
//     LineInfo info = _context.computeLineInfo(source);
//     JUnitTestCase.assertNotNull(info);
//   }
//   void test_computeResolvableCompilationUnit_exception() {
//     TestSource source = _addSourceWithException("/test.dart");
//     try {
//       _context.computeResolvableCompilationUnit(source);
//       JUnitTestCase.fail("Expected AnalysisException");
//     } on AnalysisException catch (exception) {
//     }
//   }
//   void test_computeResolvableCompilationUnit_html() {
//     Source source = _addSource("/lib.html", "<html></html>");
//     try {
//       _context.computeResolvableCompilationUnit(source);
//       JUnitTestCase.fail("Expected AnalysisException");
//     } on AnalysisException catch (exception) {
//     }
//   }
//   void test_computeResolvableCompilationUnit_valid() {
//     Source source = _addSource("/lib.dart", "library lib;");
//     CompilationUnit compilationUnit = _context.parseCompilationUnit(source);
//     JUnitTestCase.assertNotNull(compilationUnit);
//     JUnitTestCase.assertNotSame(compilationUnit, _context.computeResolvableCompilationUnit(source));
//   }
//   void test_dispose() {
//     JUnitTestCase.assertFalse(_context.isDisposed);
//     _context.dispose();
//     JUnitTestCase.assertTrue(_context.isDisposed);
//   }
//   void test_exists_false() {
//     JUnitTestCase.assertFalse(_context.exists(new TestSource()));
//   }
//   void test_exists_null() {
//     JUnitTestCase.assertFalse(_context.exists(null));
//   }
//   void test_exists_overridden() {
//     Source source = new TestSource();
//     _context.setContents(source, "");
//     JUnitTestCase.assertTrue(_context.exists(source));
//   }
//   void test_exists_true() {
//     JUnitTestCase.assertTrue(_context.exists(new TestSource_AnalysisContextImplTest_test_exists_true()));
//   }
//   void test_getAnalysisOptions() {
//     JUnitTestCase.assertNotNull(_context.analysisOptions);
//   }
//   void test_getContents_fromSource() {
//     String content = "library lib;";
//     TimestampedData<String> contents = _context.getContents(new TestSource.con2(content));
//     JUnitTestCase.assertEquals(content, contents.data.toString());
//   }
//   void test_getContents_overridden() {
//     String content = "library lib;";
//     Source source = new TestSource();
//     _context.setContents(source, content);
//     TimestampedData<String> contents = _context.getContents(source);
//     JUnitTestCase.assertEquals(content, contents.data.toString());
//   }
//   void test_getContents_unoverridden() {
//     String content = "library lib;";
//     Source source = new TestSource.con2(content);
//     _context.setContents(source, "part of lib;");
//     _context.setContents(source, null);
//     TimestampedData<String> contents = _context.getContents(source);
//     JUnitTestCase.assertEquals(content, contents.data.toString());
//   }
//   void test_getDeclaredVariables() {
//     _context = AnalysisContextFactory.contextWithCore();
//     JUnitTestCase.assertNotNull(_context.declaredVariables);
//   }
//   void test_getElement() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     LibraryElement core = _context.computeLibraryElement(_sourceFactory.forUri("dart:core"));
//     JUnitTestCase.assertNotNull(core);
//     ClassElement classObject = _findClass(core.definingCompilationUnit, "Object");
//     JUnitTestCase.assertNotNull(classObject);
//     ElementLocation location = classObject.location;
//     Element element = _context.getElement(location);
//     JUnitTestCase.assertSame(classObject, element);
//   }
//   void test_getElement_constructor_named() {
//     Source source = _addSource("/lib.dart", EngineTestCase.createSource(["class A {", "  A.named() {}", "}"]));
//     _analyzeAll_assertFinished();
//     LibraryElement library = _context.computeLibraryElement(source);
//     ClassElement classA = _findClass(library.definingCompilationUnit, "A");
//     ConstructorElement constructor = classA.constructors[0];
//     ElementLocation location = constructor.location;
//     Element element = _context.getElement(location);
//     JUnitTestCase.assertSame(constructor, element);
//   }
//   void test_getElement_constructor_unnamed() {
//     Source source = _addSource("/lib.dart", EngineTestCase.createSource(["class A {", "  A() {}", "}"]));
//     _analyzeAll_assertFinished();
//     LibraryElement library = _context.computeLibraryElement(source);
//     ClassElement classA = _findClass(library.definingCompilationUnit, "A");
//     ConstructorElement constructor = classA.constructors[0];
//     ElementLocation location = constructor.location;
//     Element element = _context.getElement(location);
//     JUnitTestCase.assertSame(constructor, element);
//   }
//   void test_getErrors_dart_none() {
//     Source source = _addSource("/lib.dart", "library lib;");
//     List<AnalysisError> errors = _context.getErrors(source).errors;
//     EngineTestCase.assertLength(0, errors);
//     _context.computeErrors(source);
//     errors = _context.getErrors(source).errors;
//     EngineTestCase.assertLength(0, errors);
//   }
//   void test_getErrors_dart_some() {
//     Source source = _addSource("/lib.dart", "library 'lib';");
//     List<AnalysisError> errors = _context.getErrors(source).errors;
//     EngineTestCase.assertLength(0, errors);
//     _context.computeErrors(source);
//     errors = _context.getErrors(source).errors;
//     EngineTestCase.assertLength(1, errors);
//   }
//   void test_getErrors_html_none() {
//     Source source = _addSource("/test.html", "<html></html>");
//     List<AnalysisError> errors = _context.getErrors(source).errors;
//     EngineTestCase.assertLength(0, errors);
//     _context.computeErrors(source);
//     errors = _context.getErrors(source).errors;
//     EngineTestCase.assertLength(0, errors);
//   }
//   void test_getErrors_html_some() {
//     Source source = _addSource("/test.html", EngineTestCase.createSource([
//         "<html><head>",
//         "<script type='application/dart' src='test.dart'/>",
//         "</head></html>"]));
//     List<AnalysisError> errors = _context.getErrors(source).errors;
//     EngineTestCase.assertLength(0, errors);
//     _context.computeErrors(source);
//     errors = _context.getErrors(source).errors;
//     EngineTestCase.assertLength(1, errors);
//   }
//   void test_getHtmlElement_dart() {
//     Source source = _addSource("/test.dart", "");
//     JUnitTestCase.assertNull(_context.getHtmlElement(source));
//     JUnitTestCase.assertNull(_context.computeHtmlElement(source));
//     JUnitTestCase.assertNull(_context.getHtmlElement(source));
//   }
//   void test_getHtmlElement_html() {
//     Source source = _addSource("/test.html", "<html></html>");
//     HtmlElement element = _context.getHtmlElement(source);
//     JUnitTestCase.assertNull(element);
//     _context.computeHtmlElement(source);
//     element = _context.getHtmlElement(source);
//     JUnitTestCase.assertNotNull(element);
//   }
//   void test_getHtmlFilesReferencing_html() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source htmlSource = _addSource("/test.html", EngineTestCase.createSource([
//         "<html><head>",
//         "<script type='application/dart' src='test.dart'/>",
//         "<script type='application/dart' src='test.js'/>",
//         "</head></html>"]));
//     Source librarySource = _addSource("/test.dart", "library lib;");
//     Source secondHtmlSource = _addSource("/test.html", "<html></html>");
//     _context.computeLibraryElement(librarySource);
//     List<Source> result = _context.getHtmlFilesReferencing(secondHtmlSource);
//     EngineTestCase.assertLength(0, result);
//     _context.parseHtmlUnit(htmlSource);
//     result = _context.getHtmlFilesReferencing(secondHtmlSource);
//     EngineTestCase.assertLength(0, result);
//   }
//   void test_getHtmlFilesReferencing_library() {
//     Source htmlSource = _addSource("/test.html", EngineTestCase.createSource([
//         "<html><head>",
//         "<script type='application/dart' src='test.dart'/>",
//         "<script type='application/dart' src='test.js'/>",
//         "</head></html>"]));
//     Source librarySource = _addSource("/test.dart", "library lib;");
//     List<Source> result = _context.getHtmlFilesReferencing(librarySource);
//     EngineTestCase.assertLength(0, result);
//     _context.parseHtmlUnit(htmlSource);
//     result = _context.getHtmlFilesReferencing(librarySource);
//     EngineTestCase.assertLength(1, result);
//     JUnitTestCase.assertEquals(htmlSource, result[0]);
//   }
//   void test_getHtmlFilesReferencing_part() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source htmlSource = _addSource("/test.html", EngineTestCase.createSource([
//         "<html><head>",
//         "<script type='application/dart' src='test.dart'/>",
//         "<script type='application/dart' src='test.js'/>",
//         "</head></html>"]));
//     Source librarySource = _addSource("/test.dart", "library lib; part 'part.dart';");
//     Source partSource = _addSource("/part.dart", "part of lib;");
//     _context.computeLibraryElement(librarySource);
//     List<Source> result = _context.getHtmlFilesReferencing(partSource);
//     EngineTestCase.assertLength(0, result);
//     _context.parseHtmlUnit(htmlSource);
//     result = _context.getHtmlFilesReferencing(partSource);
//     EngineTestCase.assertLength(1, result);
//     JUnitTestCase.assertEquals(htmlSource, result[0]);
//   }
//   void test_getHtmlSources() {
//     List<Source> sources = _context.htmlSources;
//     EngineTestCase.assertLength(0, sources);
//     Source source = _addSource("/test.html", "");
//     _context.computeKindOf(source);
//     sources = _context.htmlSources;
//     EngineTestCase.assertLength(1, sources);
//     JUnitTestCase.assertEquals(source, sources[0]);
//   }
//   void test_getKindOf_html() {
//     Source source = _addSource("/test.html", "");
//     JUnitTestCase.assertSame(SourceKind.HTML, _context.getKindOf(source));
//   }
//   void test_getKindOf_library() {
//     Source source = _addSource("/test.dart", "library lib;");
//     JUnitTestCase.assertSame(SourceKind.UNKNOWN, _context.getKindOf(source));
//     _context.computeKindOf(source);
//     JUnitTestCase.assertSame(SourceKind.LIBRARY, _context.getKindOf(source));
//   }
//   void test_getKindOf_part() {
//     Source source = _addSource("/test.dart", "part of lib;");
//     JUnitTestCase.assertSame(SourceKind.UNKNOWN, _context.getKindOf(source));
//     _context.computeKindOf(source);
//     JUnitTestCase.assertSame(SourceKind.PART, _context.getKindOf(source));
//   }
//   void test_getKindOf_unknown() {
//     Source source = _addSource("/test.css", "");
//     JUnitTestCase.assertSame(SourceKind.UNKNOWN, _context.getKindOf(source));
//   }
//   void test_getLaunchableClientLibrarySources() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     List<Source> sources = _context.launchableClientLibrarySources;
//     EngineTestCase.assertLength(0, sources);
//     Source source = _addSource("/test.dart", EngineTestCase.createSource(["import 'dart:html';", "main() {}"]));
//     _context.computeLibraryElement(source);
//     sources = _context.launchableClientLibrarySources;
//     EngineTestCase.assertLength(1, sources);
//   }
//   void test_getLaunchableServerLibrarySources() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     List<Source> sources = _context.launchableServerLibrarySources;
//     EngineTestCase.assertLength(0, sources);
//     Source source = _addSource("/test.dart", "main() {}");
//     _context.computeLibraryElement(source);
//     sources = _context.launchableServerLibrarySources;
//     EngineTestCase.assertLength(1, sources);
//   }
//   void test_getLibrariesContaining() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source librarySource = _addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "part 'part.dart';"]));
//     Source partSource = _addSource("/part.dart", "part of lib;");
//     _context.computeLibraryElement(librarySource);
//     List<Source> result = _context.getLibrariesContaining(librarySource);
//     EngineTestCase.assertLength(1, result);
//     JUnitTestCase.assertEquals(librarySource, result[0]);
//     result = _context.getLibrariesContaining(partSource);
//     EngineTestCase.assertLength(1, result);
//     JUnitTestCase.assertEquals(librarySource, result[0]);
//   }
//   void test_getLibrariesDependingOn() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source libASource = _addSource("/libA.dart", "library libA;");
//     _addSource("/libB.dart", "library libB;");
//     Source lib1Source = _addSource("/lib1.dart", EngineTestCase.createSource([
//         "library lib1;",
//         "import 'libA.dart';",
//         "export 'libB.dart';"]));
//     Source lib2Source = _addSource("/lib2.dart", EngineTestCase.createSource([
//         "library lib2;",
//         "import 'libB.dart';",
//         "export 'libA.dart';"]));
//     _context.computeLibraryElement(lib1Source);
//     _context.computeLibraryElement(lib2Source);
//     List<Source> result = _context.getLibrariesDependingOn(libASource);
//     EngineTestCase.assertContains(result, [lib1Source, lib2Source]);
//   }
//   void test_getLibrariesReferencedFromHtml() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source htmlSource = _addSource("/test.html", EngineTestCase.createSource([
//         "<html><head>",
//         "<script type='application/dart' src='test.dart'/>",
//         "<script type='application/dart' src='test.js'/>",
//         "</head></html>"]));
//     Source librarySource = _addSource("/test.dart", "library lib;");
//     _context.computeLibraryElement(librarySource);
//     _context.parseHtmlUnit(htmlSource);
//     List<Source> result = _context.getLibrariesReferencedFromHtml(htmlSource);
//     EngineTestCase.assertLength(1, result);
//     JUnitTestCase.assertEquals(librarySource, result[0]);
//   }
//   void test_getLibrariesReferencedFromHtml_no() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source htmlSource = _addSource("/test.html", EngineTestCase.createSource([
//         "<html><head>",
//         "<script type='application/dart' src='test.js'/>",
//         "</head></html>"]));
//     _addSource("/test.dart", "library lib;");
//     _context.parseHtmlUnit(htmlSource);
//     List<Source> result = _context.getLibrariesReferencedFromHtml(htmlSource);
//     EngineTestCase.assertLength(0, result);
//   }
//   void test_getLibraryElement() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/test.dart", "library lib;");
//     LibraryElement element = _context.getLibraryElement(source);
//     JUnitTestCase.assertNull(element);
//     _context.computeLibraryElement(source);
//     element = _context.getLibraryElement(source);
//     JUnitTestCase.assertNotNull(element);
//   }
//   void test_getLibrarySources() {
//     List<Source> sources = _context.librarySources;
//     EngineTestCase.assertLength(0, sources);
//     Source source = _addSource("/test.dart", "library lib;");
//     _context.computeKindOf(source);
//     sources = _context.librarySources;
//     EngineTestCase.assertLength(1, sources);
//     JUnitTestCase.assertEquals(source, sources[0]);
//   }
//   void test_getLineInfo() {
//     Source source = _addSource("/test.dart", EngineTestCase.createSource(["library lib;", "", "main() {}"]));
//     LineInfo info = _context.getLineInfo(source);
//     JUnitTestCase.assertNull(info);
//     _context.parseCompilationUnit(source);
//     info = _context.getLineInfo(source);
//     JUnitTestCase.assertNotNull(info);
//   }
//   void test_getModificationStamp_fromSource() {
//     int stamp = 42;
//     JUnitTestCase.assertEquals(stamp, _context.getModificationStamp(new TestSource_AnalysisContextImplTest_test_getModificationStamp_fromSource(stamp)));
//   }
//   void test_getModificationStamp_overridden() {
//     int stamp = 42;
//     Source source = new TestSource_AnalysisContextImplTest_test_getModificationStamp_overridden(stamp);
//     _context.setContents(source, "");
//     JUnitTestCase.assertTrue(stamp != _context.getModificationStamp(source));
//   }
//   void test_getPublicNamespace_element() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/test.dart", "class A {}");
//     LibraryElement library = _context.computeLibraryElement(source);
//     Namespace namespace = _context.getPublicNamespace(library);
//     JUnitTestCase.assertNotNull(namespace);
//     EngineTestCase.assertInstanceOf((obj) => obj is ClassElement, ClassElement, namespace.get("A"));
//   }
//   void test_getRefactoringUnsafeSources() {
//     // not sources initially
//     List<Source> sources = _context.refactoringUnsafeSources;
//     EngineTestCase.assertLength(0, sources);
//     // add new source, unresolved
//     Source source = _addSource("/test.dart", "library lib;");
//     sources = _context.refactoringUnsafeSources;
//     EngineTestCase.assertLength(1, sources);
//     JUnitTestCase.assertEquals(source, sources[0]);
//     // resolve source
//     _context.computeLibraryElement(source);
//     sources = _context.refactoringUnsafeSources;
//     EngineTestCase.assertLength(0, sources);
//   }
//   void test_getResolvedCompilationUnit_library() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/lib.dart", "library libb;");
//     LibraryElement library = _context.computeLibraryElement(source);
//     JUnitTestCase.assertNotNull(_context.getResolvedCompilationUnit(source, library));
//     _context.setContents(source, "library lib;");
//     JUnitTestCase.assertNull(_context.getResolvedCompilationUnit(source, library));
//   }
//   void test_getResolvedCompilationUnit_library_null() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/lib.dart", "library lib;");
//     JUnitTestCase.assertNull(_context.getResolvedCompilationUnit(source, null as LibraryElement));
//   }
//   void test_getResolvedCompilationUnit_source_dart() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/lib.dart", "library lib;");
//     JUnitTestCase.assertNull(_context.getResolvedCompilationUnit2(source, source));
//     _context.resolveCompilationUnit2(source, source);
//     JUnitTestCase.assertNotNull(_context.getResolvedCompilationUnit2(source, source));
//   }
//   void test_getResolvedCompilationUnit_source_html() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/test.html", "<html></html>");
//     JUnitTestCase.assertNull(_context.getResolvedCompilationUnit2(source, source));
//     JUnitTestCase.assertNull(_context.resolveCompilationUnit2(source, source));
//     JUnitTestCase.assertNull(_context.getResolvedCompilationUnit2(source, source));
//   }
//   void test_getResolvedHtmlUnit() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/test.html", "<html></html>");
//     JUnitTestCase.assertNull(_context.getResolvedHtmlUnit(source));
//     _context.resolveHtmlUnit(source);
//     JUnitTestCase.assertNotNull(_context.getResolvedHtmlUnit(source));
//   }
//   void test_getSourceFactory() {
//     JUnitTestCase.assertSame(_sourceFactory, _context.sourceFactory);
//   }
//   void test_getStatistics() {
//     AnalysisContextStatistics statistics = _context.statistics;
//     JUnitTestCase.assertNotNull(statistics);
//     EngineTestCase.assertLength(0, statistics.cacheRows);
//     EngineTestCase.assertLength(0, statistics.exceptions);
//     EngineTestCase.assertLength(0, statistics.sources);
//   }
//   void test_isClientLibrary_dart() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/test.dart", EngineTestCase.createSource(["import 'dart:html';", "", "main() {}"]));
//     JUnitTestCase.assertFalse(_context.isClientLibrary(source));
//     JUnitTestCase.assertFalse(_context.isServerLibrary(source));
//     _context.computeLibraryElement(source);
//     JUnitTestCase.assertTrue(_context.isClientLibrary(source));
//     JUnitTestCase.assertFalse(_context.isServerLibrary(source));
//   }
//   void test_isClientLibrary_html() {
//     Source source = _addSource("/test.html", "<html></html>");
//     JUnitTestCase.assertFalse(_context.isClientLibrary(source));
//   }
//   void test_isServerLibrary_dart() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/test.dart", EngineTestCase.createSource(["library lib;", "", "main() {}"]));
//     JUnitTestCase.assertFalse(_context.isClientLibrary(source));
//     JUnitTestCase.assertFalse(_context.isServerLibrary(source));
//     _context.computeLibraryElement(source);
//     JUnitTestCase.assertFalse(_context.isClientLibrary(source));
//     JUnitTestCase.assertTrue(_context.isServerLibrary(source));
//   }
//   void test_isServerLibrary_html() {
//     Source source = _addSource("/test.html", "<html></html>");
//     JUnitTestCase.assertFalse(_context.isServerLibrary(source));
//   }
//   void test_parseCompilationUnit_errors() {
//     Source source = _addSource("/lib.dart", "library {");
//     CompilationUnit compilationUnit = _context.parseCompilationUnit(source);
//     JUnitTestCase.assertNotNull(compilationUnit);
//     List<AnalysisError> errors = _context.getErrors(source).errors;
//     JUnitTestCase.assertNotNull(errors);
//     JUnitTestCase.assertTrue(errors.length > 0);
//   }
//   void test_parseCompilationUnit_exception() {
//     Source source = _addSourceWithException("/test.dart");
//     try {
//       _context.parseCompilationUnit(source);
//       JUnitTestCase.fail("Expected AnalysisException");
//     } on AnalysisException catch (exception) {
//     }
//   }
//   void test_parseCompilationUnit_html() {
//     Source source = _addSource("/test.html", "<html></html>");
//     JUnitTestCase.assertNull(_context.parseCompilationUnit(source));
//   }
//   void test_parseCompilationUnit_noErrors() {
//     Source source = _addSource("/lib.dart", "library lib;");
//     CompilationUnit compilationUnit = _context.parseCompilationUnit(source);
//     JUnitTestCase.assertNotNull(compilationUnit);
//     EngineTestCase.assertLength(0, _context.getErrors(source).errors);
//   }
//   void test_parseCompilationUnit_nonExistentSource() {
//     Source source = new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
//     try {
//       _context.parseCompilationUnit(source);
//       JUnitTestCase.fail("Expected AnalysisException because file does not exist");
//     } on AnalysisException catch (exception) {
//     }
//   }
//   void test_parseHtmlUnit_noErrors() {
//     Source source = _addSource("/lib.html", "<html></html>");
//     HtmlUnit unit = _context.parseHtmlUnit(source);
//     JUnitTestCase.assertNotNull(unit);
//   }
//   void test_parseHtmlUnit_resolveDirectives() {
//     Source libSource = _addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "class ClassA {}"]));
//     Source source = _addSource("/lib.html", EngineTestCase.createSource([
//         "<html>",
//         "<head>",
//         "  <script type='application/dart'>",
//         "    import 'lib.dart';",
//         "    ClassA v = null;",
//         "  </script>",
//         "</head>",
//         "<body>",
//         "</body>",
//         "</html>"]));
//     HtmlUnit unit = _context.parseHtmlUnit(source);
//     // import directive should be resolved
//     XmlTagNode htmlNode = unit.tagNodes[0];
//     XmlTagNode headNode = htmlNode.tagNodes[0];
//     HtmlScriptTagNode scriptNode = headNode.tagNodes[0] as HtmlScriptTagNode;
//     CompilationUnit script = scriptNode.script;
//     ImportDirective importNode = script.directives[0] as ImportDirective;
//     JUnitTestCase.assertNotNull(importNode.uriContent);
//     JUnitTestCase.assertEquals(libSource, importNode.source);
//   }
//   void test_performAnalysisTask_addPart() {
//     Source libSource = _addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "part 'part.dart';"]));
//     // run all tasks without part
//     _analyzeAll_assertFinished();
//     // add part and run all tasks
//     Source partSource = _addSource("/part.dart", EngineTestCase.createSource(["part of lib;", ""]));
//     _analyzeAll_assertFinished();
//     // "libSource" should be here
//     List<Source> librariesWithPart = _context.getLibrariesContaining(partSource);
//     EngineTestCase.assertContains(librariesWithPart, [libSource]);
//   }
//   void test_performAnalysisTask_changeLibraryContents() {
//     Source libSource = _addSource("/test.dart", "library lib; part 'test-part.dart';");
//     Source partSource = _addSource("/test-part.dart", "part of lib;");
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 1", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNotNullMsg("part resolved 1", _context.getResolvedCompilationUnit2(partSource, libSource));
//     // update and analyze #1
//     _context.setContents(libSource, "library lib;");
//     JUnitTestCase.assertNullMsg("library changed 2", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part changed 2", _context.getResolvedCompilationUnit2(partSource, libSource));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 2", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part resolved 2", _context.getResolvedCompilationUnit2(partSource, libSource));
//     // update and analyze #2
//     _context.setContents(libSource, "library lib; part 'test-part.dart';");
//     JUnitTestCase.assertNullMsg("library changed 3", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part changed 3", _context.getResolvedCompilationUnit2(partSource, libSource));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 2", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNotNullMsg("part resolved 3", _context.getResolvedCompilationUnit2(partSource, libSource));
//   }
//   void test_performAnalysisTask_changeLibraryThenPartContents() {
//     Source libSource = _addSource("/test.dart", "library lib; part 'test-part.dart';");
//     Source partSource = _addSource("/test-part.dart", "part of lib;");
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 1", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNotNullMsg("part resolved 1", _context.getResolvedCompilationUnit2(partSource, libSource));
//     // update and analyze #1
//     _context.setContents(libSource, "library lib;");
//     JUnitTestCase.assertNullMsg("library changed 2", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part changed 2", _context.getResolvedCompilationUnit2(partSource, libSource));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 2", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part resolved 2", _context.getResolvedCompilationUnit2(partSource, libSource));
//     // update and analyze #2
//     _context.setContents(partSource, "part of lib; // 1");
//     // Assert that changing the part's content does not effect the library
//     // now that it is no longer part of that library
//     JUnitTestCase.assertNotNullMsg("library changed 3", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part changed 3", _context.getResolvedCompilationUnit2(partSource, libSource));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 3", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part resolved 3", _context.getResolvedCompilationUnit2(partSource, libSource));
//   }
//   void test_performAnalysisTask_changePartContents_makeItAPart() {
//     Source libSource = _addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "part 'part.dart';", "void f(x) {}"]));
//     Source partSource = _addSource("/part.dart", EngineTestCase.createSource(["void g() { f(null); }"]));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 1", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNotNullMsg("part resolved 1", _context.getResolvedCompilationUnit2(partSource, libSource));
//     // update and analyze
//     _context.setContents(partSource, EngineTestCase.createSource(["part of lib;", "void g() { f(null); }"]));
//     JUnitTestCase.assertNullMsg("library changed 2", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part changed 2", _context.getResolvedCompilationUnit2(partSource, libSource));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 2", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNotNullMsg("part resolved 2", _context.getResolvedCompilationUnit2(partSource, libSource));
//     EngineTestCase.assertLength(0, _context.getErrors(libSource).errors);
//     EngineTestCase.assertLength(0, _context.getErrors(partSource).errors);
//   }
//   /**
//    * https://code.google.com/p/dart/issues/detail?id=12424
//    */
//   void test_performAnalysisTask_changePartContents_makeItNotPart() {
//     Source libSource = _addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "part 'part.dart';", "void f(x) {}"]));
//     Source partSource = _addSource("/part.dart", EngineTestCase.createSource(["part of lib;", "void g() { f(null); }"]));
//     _analyzeAll_assertFinished();
//     EngineTestCase.assertLength(0, _context.getErrors(libSource).errors);
//     EngineTestCase.assertLength(0, _context.getErrors(partSource).errors);
//     // Remove 'part' directive, which should make "f(null)" an error.
//     _context.setContents(partSource, EngineTestCase.createSource(["//part of lib;", "void g() { f(null); }"]));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertTrue(_context.getErrors(libSource).errors.length != 0);
//   }
//   void test_performAnalysisTask_changePartContents_noSemanticChanges() {
//     Source libSource = _addSource("/test.dart", "library lib; part 'test-part.dart';");
//     Source partSource = _addSource("/test-part.dart", "part of lib;");
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 1", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNotNullMsg("part resolved 1", _context.getResolvedCompilationUnit2(partSource, libSource));
//     // update and analyze #1
//     _context.setContents(partSource, "part of lib; // 1");
//     JUnitTestCase.assertNullMsg("library changed 2", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part changed 2", _context.getResolvedCompilationUnit2(partSource, libSource));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 2", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNotNullMsg("part resolved 2", _context.getResolvedCompilationUnit2(partSource, libSource));
//     // update and analyze #2
//     _context.setContents(partSource, "part of lib; // 12");
//     JUnitTestCase.assertNullMsg("library changed 3", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNullMsg("part changed 3", _context.getResolvedCompilationUnit2(partSource, libSource));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("library resolved 3", _context.getResolvedCompilationUnit2(libSource, libSource));
//     JUnitTestCase.assertNotNullMsg("part resolved 3", _context.getResolvedCompilationUnit2(partSource, libSource));
//   }
//   void test_performAnalysisTask_importedLibraryAdd() {
//     Source libASource = _addSource("/libA.dart", "library libA; import 'libB.dart';");
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("libA resolved 1", _context.getResolvedCompilationUnit2(libASource, libASource));
//     JUnitTestCase.assertTrueMsg("libA has an error", _hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)));
//     // add libB.dart and analyze
//     Source libBSource = _addSource("/libB.dart", "library libB;");
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("libA resolved 2", _context.getResolvedCompilationUnit2(libASource, libASource));
//     JUnitTestCase.assertNotNullMsg("libB resolved 2", _context.getResolvedCompilationUnit2(libBSource, libBSource));
//     JUnitTestCase.assertTrueMsg("libA doesn't have errors", !_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)));
//   }
//   void test_performAnalysisTask_importedLibraryAdd_html() {
//     Source htmlSource = _addSource("/page.html", EngineTestCase.createSource([
//         "<html><body><script type=\"application/dart\">",
//         "  import '/libB.dart';",
//         "  main() {print('hello dart');}",
//         "</script></body></html>"]));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("htmlUnit resolved 1", _context.getResolvedHtmlUnit(htmlSource));
//     JUnitTestCase.assertTrueMsg("htmlSource has an error", _hasAnalysisErrorWithErrorSeverity(_context.getErrors(htmlSource)));
//     // add libB.dart and analyze
//     Source libBSource = _addSource("/libB.dart", "library libB;");
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("htmlUnit resolved 1", _context.getResolvedHtmlUnit(htmlSource));
//     JUnitTestCase.assertNotNullMsg("libB resolved 2", _context.getResolvedCompilationUnit2(libBSource, libBSource));
//     AnalysisErrorInfo errors = _context.getErrors(htmlSource);
//     JUnitTestCase.assertTrueMsg("htmlSource doesn't have errors", !_hasAnalysisErrorWithErrorSeverity(errors));
//   }
//   void test_performAnalysisTask_importedLibraryDelete() {
//     Source libASource = _addSource("/libA.dart", "library libA; import 'libB.dart';");
//     Source libBSource = _addSource("/libB.dart", "library libB;");
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("libA resolved 1", _context.getResolvedCompilationUnit2(libASource, libASource));
//     JUnitTestCase.assertNotNullMsg("libB resolved 1", _context.getResolvedCompilationUnit2(libBSource, libBSource));
//     JUnitTestCase.assertTrueMsg("libA doesn't have errors", !_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)));
//     // remove libB.dart content and analyze
//     _context.setContents(libBSource, null);
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("libA resolved 2", _context.getResolvedCompilationUnit2(libASource, libASource));
//     JUnitTestCase.assertTrueMsg("libA has an error", _hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)));
//   }
//   void test_performAnalysisTask_IOException() {
//     TestSource source = _addSourceWithException2("/test.dart", "library test;");
//     source.generateExceptionOnRead = false;
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertEquals(1, source.readCount);
//     source.generateExceptionOnRead = true;
//     _changeSource(source, "");
//     _context.performAnalysisTask();
//     JUnitTestCase.assertNull(_context.performAnalysisTask().changeNotices);
//     JUnitTestCase.assertEquals(2, source.readCount);
//   }
//   void test_performAnalysisTask_missingPart() {
//     Source source = _addSource("/test.dart", "library lib; part 'no-such-file.dart';");
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("performAnalysisTask failed to compute an element model", _context.getLibraryElement(source));
//   }
//   void test_performAnalysisTask_modifiedAfterParse() {
//     Source source = _addSource("/test.dart", "library lib;");
//     int initialTime = _context.getModificationStamp(source);
//     List<Source> sources = new List<Source>();
//     sources.add(source);
//     _context.analysisPriorityOrder = sources;
//     _context.parseCompilationUnit(source);
//     while (initialTime == JavaSystem.currentTimeMillis()) {
//       Thread.sleep(1);
//     }
//     _context.setContents(source, "library test;");
//     JUnitTestCase.assertTrue(initialTime != _context.getModificationStamp(source));
//     _analyzeAll_assertFinished();
//     JUnitTestCase.assertNotNullMsg("performAnalysisTask failed to compute an element model", _context.getLibraryElement(source));
//   }
//   void test_resolveCompilationUnit_library() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/lib.dart", "library lib;");
//     LibraryElement library = _context.computeLibraryElement(source);
//     CompilationUnit compilationUnit = _context.resolveCompilationUnit(source, library);
//     JUnitTestCase.assertNotNull(compilationUnit);
//   }
//   void test_resolveCompilationUnit_source() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/lib.dart", "library lib;");
//     CompilationUnit compilationUnit = _context.resolveCompilationUnit2(source, source);
//     JUnitTestCase.assertNotNull(compilationUnit);
//   }
//   void test_resolveCompilationUnit_sourceChangeDuringResolution() {
//     _context = new AnalysisContextImpl_AnalysisContextImplTest_test_resolveCompilationUnit_sourceChangeDuringResolution();
//     AnalysisContextFactory.initContextWithCore(_context);
//     _sourceFactory = _context.sourceFactory;
//     Source source = _addSource("/lib.dart", "library lib;");
//     CompilationUnit compilationUnit = _context.resolveCompilationUnit2(source, source);
//     JUnitTestCase.assertNotNull(compilationUnit);
//     JUnitTestCase.assertNotNull(_context.getLineInfo(source));
//   }
//   void test_resolveHtmlUnit() {
//     Source source = _addSource("/lib.html", "<html></html>");
//     HtmlUnit unit = _context.resolveHtmlUnit(source);
//     JUnitTestCase.assertNotNull(unit);
//   }
//   void test_setAnalysisOptions() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     options.cacheSize = 42;
//     options.dart2jsHint = false;
//     options.hint = false;
//     _context.analysisOptions = options;
//     AnalysisOptions result = _context.analysisOptions;
//     JUnitTestCase.assertEquals(options.cacheSize, result.cacheSize);
//     JUnitTestCase.assertEquals(options.dart2jsHint, result.dart2jsHint);
//     JUnitTestCase.assertEquals(options.hint, result.hint);
//   }
//   void test_setAnalysisOptions_reduceAnalysisPriorityOrder() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl.con1(_context.analysisOptions);
//     List<Source> sources = new List<Source>();
//     for (int index = 0; index < options.cacheSize; index++) {
//       sources.add(_addSource("/lib.dart${index}", ""));
//     }
//     _context.analysisPriorityOrder = sources;
//     int oldPriorityOrderSize = _getPriorityOrder(_context).length;
//     options.cacheSize = options.cacheSize - 10;
//     _context.analysisOptions = options;
//     JUnitTestCase.assertTrue(oldPriorityOrderSize > _getPriorityOrder(_context).length);
//   }
//   void test_setAnalysisPriorityOrder_empty() {
//     _context.analysisPriorityOrder = new List<Source>();
//   }
//   void test_setAnalysisPriorityOrder_lessThanCacheSize() {
//     AnalysisOptions options = _context.analysisOptions;
//     List<Source> sources = new List<Source>();
//     for (int index = 0; index < options.cacheSize; index++) {
//       sources.add(_addSource("/lib.dart${index}", ""));
//     }
//     _context.analysisPriorityOrder = sources;
//     JUnitTestCase.assertTrue(options.cacheSize > _getPriorityOrder(_context).length);
//   }
//   void test_setAnalysisPriorityOrder_nonEmpty() {
//     List<Source> sources = new List<Source>();
//     sources.add(_addSource("/lib.dart", "library lib;"));
//     _context.analysisPriorityOrder = sources;
//   }
//   void test_setChangedContents_libraryWithPart() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     options.incremental = true;
//     _context = AnalysisContextFactory.contextWithCoreAndOptions(options);
//     _sourceFactory = _context.sourceFactory;
//     String oldCode = EngineTestCase.createSource(["library lib;", "part 'part.dart';", "int a = 0;"]);
//     Source librarySource = _addSource("/lib.dart", oldCode);
//     Source partSource = _addSource("/part.dart", EngineTestCase.createSource(["part of lib;", "int b = a;"]));
//     LibraryElement element = _context.computeLibraryElement(librarySource);
//     CompilationUnit unit = _context.getResolvedCompilationUnit(librarySource, element);
//     JUnitTestCase.assertNotNull(unit);
//     int offset = oldCode.indexOf("int a") + 4;
//     String newCode = EngineTestCase.createSource(["library lib;", "part 'part.dart';", "int ya = 0;"]);
//     JUnitTestCase.assertNull(_getIncrementalAnalysisCache(_context));
//     _context.setChangedContents(librarySource, newCode, offset, 0, 1);
//     JUnitTestCase.assertEquals(newCode, _context.getContents(librarySource).data);
//     IncrementalAnalysisCache incrementalCache = _getIncrementalAnalysisCache(_context);
//     JUnitTestCase.assertEquals(librarySource, incrementalCache.librarySource);
//     JUnitTestCase.assertSame(unit, incrementalCache.resolvedUnit);
//     JUnitTestCase.assertNull(_context.getResolvedCompilationUnit2(partSource, librarySource));
//     JUnitTestCase.assertEquals(newCode, incrementalCache.newContents);
//   }
//   void test_setChangedContents_notResolved() {
//     _context = AnalysisContextFactory.contextWithCore();
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl.con1(_context.analysisOptions);
//     options.incremental = true;
//     _context.analysisOptions = options;
//     _sourceFactory = _context.sourceFactory;
//     String oldCode = EngineTestCase.createSource(["library lib;", "int a = 0;"]);
//     Source librarySource = _addSource("/lib.dart", oldCode);
//     int offset = oldCode.indexOf("int a") + 4;
//     String newCode = EngineTestCase.createSource(["library lib;", "int ya = 0;"]);
//     _context.setChangedContents(librarySource, newCode, offset, 0, 1);
//     JUnitTestCase.assertEquals(newCode, _context.getContents(librarySource).data);
//     JUnitTestCase.assertNull(_getIncrementalAnalysisCache(_context));
//   }
//   void test_setContents_libraryWithPart() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source librarySource = _addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "part 'part.dart';", "int a = 0;"]));
//     Source partSource = _addSource("/part.dart", EngineTestCase.createSource(["part of lib;", "int b = a;"]));
//     _context.computeLibraryElement(librarySource);
//     IncrementalAnalysisCache incrementalCache = new IncrementalAnalysisCache(librarySource, librarySource, null, null, null, 0, 0, 0);
//     _setIncrementalAnalysisCache(_context, incrementalCache);
//     JUnitTestCase.assertSame(incrementalCache, _getIncrementalAnalysisCache(_context));
//     _context.setContents(librarySource, EngineTestCase.createSource(["library lib;", "part 'part.dart';", "int aa = 0;"]));
//     JUnitTestCase.assertNull(_context.getResolvedCompilationUnit2(partSource, librarySource));
//     JUnitTestCase.assertNull(_getIncrementalAnalysisCache(_context));
//   }
//   void test_setContents_null() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source librarySource = _addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "int a = 0;"]));
//     _context.computeLibraryElement(librarySource);
//     IncrementalAnalysisCache incrementalCache = new IncrementalAnalysisCache(librarySource, librarySource, null, null, null, 0, 0, 0);
//     _setIncrementalAnalysisCache(_context, incrementalCache);
//     JUnitTestCase.assertSame(incrementalCache, _getIncrementalAnalysisCache(_context));
//     _context.setContents(librarySource, null);
//     JUnitTestCase.assertNull(_context.getResolvedCompilationUnit2(librarySource, librarySource));
//     JUnitTestCase.assertNull(_getIncrementalAnalysisCache(_context));
//   }
//   void test_setSourceFactory() {
//     JUnitTestCase.assertEquals(_sourceFactory, _context.sourceFactory);
//     SourceFactory factory = new SourceFactory([]);
//     _context.sourceFactory = factory;
//     JUnitTestCase.assertEquals(factory, _context.sourceFactory);
//   }
//   void test_unreadableSource() {
//     _context = AnalysisContextFactory.contextWithCore();
//     _sourceFactory = _context.sourceFactory;
//     Source test1 = _addSource("/test1.dart", EngineTestCase.createSource(["import 'test2.dart';", "library test1;"]));
//     Source test2 = _addSource("/test2.dart", EngineTestCase.createSource([
//         "import 'test1.dart';",
//         "import 'test3.dart';",
//         "library test2;"]));
//     Source test3 = _addSourceWithException("/test3.dart");
//     _analyzeAll_assertFinished();
//     // test1 and test2 should have been successfully analyzed despite the fact that
//     // test3 couldn't be read.
//     JUnitTestCase.assertNotNull(_context.computeLibraryElement(test1));
//     JUnitTestCase.assertNotNull(_context.computeLibraryElement(test2));
//     JUnitTestCase.assertNull(_context.computeLibraryElement(test3));
//   }
//   void test_updateAnalysis() {
//     JUnitTestCase.assertTrue(_context.sourcesNeedingProcessing.isEmpty);
//     Source source = new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
//     AnalysisDelta delta = new AnalysisDelta();
//     delta.setAnalysisLevel(source, AnalysisLevel.ALL);
//     _context.applyAnalysisDelta(delta);
//     JUnitTestCase.assertTrue(_context.sourcesNeedingProcessing.contains(source));
//     delta = new AnalysisDelta();
//     delta.setAnalysisLevel(source, AnalysisLevel.NONE);
//     _context.applyAnalysisDelta(delta);
//     JUnitTestCase.assertFalse(_context.sourcesNeedingProcessing.contains(source));
//   }
//   void xtest_performAnalysisTask_stress() {
//     int maxCacheSize = 4;
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl.con1(_context.analysisOptions);
//     options.cacheSize = maxCacheSize;
//     _context.analysisOptions = options;
//     int sourceCount = maxCacheSize + 2;
//     List<Source> sources = new List<Source>();
//     ChangeSet changeSet = new ChangeSet();
//     for (int i = 0; i < sourceCount; i++) {
//       Source source = _addSource("/lib${i}.dart", "library lib${i};");
//       sources.add(source);
//       changeSet.addedSource(source);
//     }
//     _context.applyChanges(changeSet);
//     _context.analysisPriorityOrder = sources;
//     for (int i = 0; i < 1000; i++) {
//       List<ChangeNotice> notice = _context.performAnalysisTask().changeNotices;
//       if (notice == null) {
//         //System.out.println("test_performAnalysisTask_stress: " + i);
//         break;
//       }
//     }
//     List<ChangeNotice> notice = _context.performAnalysisTask().changeNotices;
//     if (notice != null) {
//       JUnitTestCase.fail("performAnalysisTask failed to terminate after analyzing all sources");
//     }
//   }
//   Source _addSource(String fileName, String contents) {
//     Source source = new FileBasedSource.con1(FileUtilities2.createFile(fileName));
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.addedSource(source);
//     _context.applyChanges(changeSet);
//     _context.setContents(source, contents);
//     return source;
//   }
//   TestSource _addSourceWithException(String fileName) => _addSourceWithException2(fileName, "");
//   TestSource _addSourceWithException2(String fileName, String contents) {
//     TestSource source = new TestSource.con1(FileUtilities2.createFile(fileName), contents);
//     source.generateExceptionOnRead = true;
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.addedSource(source);
//     _context.applyChanges(changeSet);
//     return source;
//   }
//   /**
//    * Perform analysis tasks up to 512 times and asserts that that was enough.
//    */
//   void _analyzeAll_assertFinished() {
//     _analyzeAll_assertFinished2(512);
//   }
//   /**
//    * Perform analysis tasks up to the given number of times and asserts that that was enough.
//    *
//    * @param maxIterations the maximum number of tasks to perform
//    */
//   void _analyzeAll_assertFinished2(int maxIterations) {
//     for (int i = 0; i < maxIterations; i++) {
//       List<ChangeNotice> notice = _context.performAnalysisTask().changeNotices;
//       if (notice == null) {
//         return;
//       }
//     }
//     JUnitTestCase.fail("performAnalysisTask failed to terminate after analyzing all sources");
//   }
//   void _changeSource(TestSource source, String contents) {
//     source.contents = contents;
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.changedSource(source);
//     _context.applyChanges(changeSet);
//   }
//   /**
//    * Search the given compilation unit for a class with the given name. Return the class with the
//    * given name, or `null` if the class cannot be found.
//    *
//    * @param unit the compilation unit being searched
//    * @param className the name of the class being searched for
//    * @return the class with the given name
//    */
//   ClassElement _findClass(CompilationUnitElement unit, String className) {
//     for (ClassElement classElement in unit.types) {
//       if (classElement.displayName == className) {
//         return classElement;
//       }
//     }
//     return null;
//   }
//   IncrementalAnalysisCache _getIncrementalAnalysisCache(AnalysisContextImpl context2) {
//     return context2.incrementalAnalysisCache_J2DAccessor as IncrementalAnalysisCache;
//   }
//   List<Source> _getPriorityOrder(AnalysisContextImpl context2) {
//     return context2.priorityOrder_J2DAccessor as List<Source>;
//   }
//   void _removeSource(Source source) {
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.removedSource(source);
//     _context.applyChanges(changeSet);
//   }
//   void _setIncrementalAnalysisCache(AnalysisContextImpl context2, IncrementalAnalysisCache incrementalCache) {
//     context2.incrementalAnalysisCache_J2DAccessor = incrementalCache;
//   }
//   static dartSuite() {
//     _ut.group('AnalysisContextImplTest', () {
//       _ut.test('test_applyChanges_add', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_applyChanges_add);
//       });
//       _ut.test('test_applyChanges_change_flush_element', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_applyChanges_change_flush_element);
//       });
//       _ut.test('test_applyChanges_change_multiple', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_applyChanges_change_multiple);
//       });
//       _ut.test('test_applyChanges_empty', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_applyChanges_empty);
//       });
//       _ut.test('test_applyChanges_overriddenSource', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_applyChanges_overriddenSource);
//       });
//       _ut.test('test_applyChanges_remove', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_applyChanges_remove);
//       });
//       _ut.test('test_applyChanges_removeContainer', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_applyChanges_removeContainer);
//       });
//       _ut.test('test_computeDocumentationComment_block', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeDocumentationComment_block);
//       });
//       _ut.test('test_computeDocumentationComment_none', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeDocumentationComment_none);
//       });
//       _ut.test('test_computeDocumentationComment_null', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeDocumentationComment_null);
//       });
//       _ut.test('test_computeDocumentationComment_singleLine_multiple_EOL_n', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeDocumentationComment_singleLine_multiple_EOL_n);
//       });
//       _ut.test('test_computeDocumentationComment_singleLine_multiple_EOL_rn', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeDocumentationComment_singleLine_multiple_EOL_rn);
//       });
//       _ut.test('test_computeErrors_dart_none', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeErrors_dart_none);
//       });
//       _ut.test('test_computeErrors_dart_part', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeErrors_dart_part);
//       });
//       _ut.test('test_computeErrors_dart_some', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeErrors_dart_some);
//       });
//       _ut.test('test_computeErrors_html_none', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeErrors_html_none);
//       });
//       _ut.test('test_computeExportedLibraries_none', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeExportedLibraries_none);
//       });
//       _ut.test('test_computeExportedLibraries_some', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeExportedLibraries_some);
//       });
//       _ut.test('test_computeHtmlElement_nonHtml', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeHtmlElement_nonHtml);
//       });
//       _ut.test('test_computeHtmlElement_valid', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeHtmlElement_valid);
//       });
//       _ut.test('test_computeImportedLibraries_none', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeImportedLibraries_none);
//       });
//       _ut.test('test_computeImportedLibraries_some', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeImportedLibraries_some);
//       });
//       _ut.test('test_computeKindOf_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeKindOf_html);
//       });
//       _ut.test('test_computeKindOf_library', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeKindOf_library);
//       });
//       _ut.test('test_computeKindOf_libraryAndPart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeKindOf_libraryAndPart);
//       });
//       _ut.test('test_computeKindOf_part', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeKindOf_part);
//       });
//       _ut.test('test_computeLibraryElement', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeLibraryElement);
//       });
//       _ut.test('test_computeLineInfo_dart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeLineInfo_dart);
//       });
//       _ut.test('test_computeLineInfo_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeLineInfo_html);
//       });
//       _ut.test('test_computeResolvableCompilationUnit_exception', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeResolvableCompilationUnit_exception);
//       });
//       _ut.test('test_computeResolvableCompilationUnit_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeResolvableCompilationUnit_html);
//       });
//       _ut.test('test_computeResolvableCompilationUnit_valid', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeResolvableCompilationUnit_valid);
//       });
//       _ut.test('test_dispose', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_dispose);
//       });
//       _ut.test('test_exists_false', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_exists_false);
//       });
//       _ut.test('test_exists_null', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_exists_null);
//       });
//       _ut.test('test_exists_overridden', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_exists_overridden);
//       });
//       _ut.test('test_exists_true', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_exists_true);
//       });
//       _ut.test('test_getAnalysisOptions', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getAnalysisOptions);
//       });
//       _ut.test('test_getContents_fromSource', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getContents_fromSource);
//       });
//       _ut.test('test_getContents_overridden', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getContents_overridden);
//       });
//       _ut.test('test_getContents_unoverridden', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getContents_unoverridden);
//       });
//       _ut.test('test_getDeclaredVariables', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getDeclaredVariables);
//       });
//       _ut.test('test_getElement', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getElement);
//       });
//       _ut.test('test_getElement_constructor_named', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getElement_constructor_named);
//       });
//       _ut.test('test_getElement_constructor_unnamed', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getElement_constructor_unnamed);
//       });
//       _ut.test('test_getErrors_dart_none', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getErrors_dart_none);
//       });
//       _ut.test('test_getErrors_dart_some', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getErrors_dart_some);
//       });
//       _ut.test('test_getErrors_html_none', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getErrors_html_none);
//       });
//       _ut.test('test_getErrors_html_some', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getErrors_html_some);
//       });
//       _ut.test('test_getHtmlElement_dart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getHtmlElement_dart);
//       });
//       _ut.test('test_getHtmlElement_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getHtmlElement_html);
//       });
//       _ut.test('test_getHtmlFilesReferencing_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getHtmlFilesReferencing_html);
//       });
//       _ut.test('test_getHtmlFilesReferencing_library', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getHtmlFilesReferencing_library);
//       });
//       _ut.test('test_getHtmlFilesReferencing_part', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getHtmlFilesReferencing_part);
//       });
//       _ut.test('test_getHtmlSources', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getHtmlSources);
//       });
//       _ut.test('test_getKindOf_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getKindOf_html);
//       });
//       _ut.test('test_getKindOf_library', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getKindOf_library);
//       });
//       _ut.test('test_getKindOf_part', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getKindOf_part);
//       });
//       _ut.test('test_getKindOf_unknown', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getKindOf_unknown);
//       });
//       _ut.test('test_getLaunchableClientLibrarySources', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLaunchableClientLibrarySources);
//       });
//       _ut.test('test_getLaunchableServerLibrarySources', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLaunchableServerLibrarySources);
//       });
//       _ut.test('test_getLibrariesContaining', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibrariesContaining);
//       });
//       _ut.test('test_getLibrariesDependingOn', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibrariesDependingOn);
//       });
//       _ut.test('test_getLibrariesReferencedFromHtml', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibrariesReferencedFromHtml);
//       });
//       _ut.test('test_getLibrariesReferencedFromHtml_no', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibrariesReferencedFromHtml_no);
//       });
//       _ut.test('test_getLibraryElement', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibraryElement);
//       });
//       _ut.test('test_getLibrarySources', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibrarySources);
//       });
//       _ut.test('test_getLineInfo', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLineInfo);
//       });
//       _ut.test('test_getModificationStamp_fromSource', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getModificationStamp_fromSource);
//       });
//       _ut.test('test_getModificationStamp_overridden', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getModificationStamp_overridden);
//       });
//       _ut.test('test_getPublicNamespace_element', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getPublicNamespace_element);
//       });
//       _ut.test('test_getRefactoringUnsafeSources', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getRefactoringUnsafeSources);
//       });
//       _ut.test('test_getResolvedCompilationUnit_library', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getResolvedCompilationUnit_library);
//       });
//       _ut.test('test_getResolvedCompilationUnit_library_null', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getResolvedCompilationUnit_library_null);
//       });
//       _ut.test('test_getResolvedCompilationUnit_source_dart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getResolvedCompilationUnit_source_dart);
//       });
//       _ut.test('test_getResolvedCompilationUnit_source_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getResolvedCompilationUnit_source_html);
//       });
//       _ut.test('test_getResolvedHtmlUnit', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getResolvedHtmlUnit);
//       });
//       _ut.test('test_getSourceFactory', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getSourceFactory);
//       });
//       _ut.test('test_getStatistics', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getStatistics);
//       });
//       _ut.test('test_isClientLibrary_dart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_isClientLibrary_dart);
//       });
//       _ut.test('test_isClientLibrary_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_isClientLibrary_html);
//       });
//       _ut.test('test_isServerLibrary_dart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_isServerLibrary_dart);
//       });
//       _ut.test('test_isServerLibrary_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_isServerLibrary_html);
//       });
//       _ut.test('test_parseCompilationUnit_errors', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_parseCompilationUnit_errors);
//       });
//       _ut.test('test_parseCompilationUnit_exception', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_parseCompilationUnit_exception);
//       });
//       _ut.test('test_parseCompilationUnit_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_parseCompilationUnit_html);
//       });
//       _ut.test('test_parseCompilationUnit_noErrors', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_parseCompilationUnit_noErrors);
//       });
//       _ut.test('test_parseCompilationUnit_nonExistentSource', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_parseCompilationUnit_nonExistentSource);
//       });
//       _ut.test('test_parseHtmlUnit_noErrors', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_parseHtmlUnit_noErrors);
//       });
//       _ut.test('test_parseHtmlUnit_resolveDirectives', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_parseHtmlUnit_resolveDirectives);
//       });
//       _ut.test('test_performAnalysisTask_IOException', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_IOException);
//       });
//       _ut.test('test_performAnalysisTask_addPart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_addPart);
//       });
//       _ut.test('test_performAnalysisTask_changeLibraryContents', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_changeLibraryContents);
//       });
//       _ut.test('test_performAnalysisTask_changeLibraryThenPartContents', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_changeLibraryThenPartContents);
//       });
//       _ut.test('test_performAnalysisTask_changePartContents_makeItAPart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_changePartContents_makeItAPart);
//       });
//       _ut.test('test_performAnalysisTask_changePartContents_makeItNotPart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_changePartContents_makeItNotPart);
//       });
//       _ut.test('test_performAnalysisTask_changePartContents_noSemanticChanges', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_changePartContents_noSemanticChanges);
//       });
//       _ut.test('test_performAnalysisTask_importedLibraryAdd', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_importedLibraryAdd);
//       });
//       _ut.test('test_performAnalysisTask_importedLibraryAdd_html', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_importedLibraryAdd_html);
//       });
//       _ut.test('test_performAnalysisTask_importedLibraryDelete', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_importedLibraryDelete);
//       });
//       _ut.test('test_performAnalysisTask_missingPart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_missingPart);
//       });
//       _ut.test('test_performAnalysisTask_modifiedAfterParse', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask_modifiedAfterParse);
//       });
//       _ut.test('test_resolveCompilationUnit_library', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_resolveCompilationUnit_library);
//       });
//       _ut.test('test_resolveCompilationUnit_source', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_resolveCompilationUnit_source);
//       });
//       _ut.test('test_resolveCompilationUnit_sourceChangeDuringResolution', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_resolveCompilationUnit_sourceChangeDuringResolution);
//       });
//       _ut.test('test_resolveHtmlUnit', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_resolveHtmlUnit);
//       });
//       _ut.test('test_setAnalysisOptions', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setAnalysisOptions);
//       });
//       _ut.test('test_setAnalysisOptions_reduceAnalysisPriorityOrder', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setAnalysisOptions_reduceAnalysisPriorityOrder);
//       });
//       _ut.test('test_setAnalysisPriorityOrder_empty', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setAnalysisPriorityOrder_empty);
//       });
//       _ut.test('test_setAnalysisPriorityOrder_lessThanCacheSize', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setAnalysisPriorityOrder_lessThanCacheSize);
//       });
//       _ut.test('test_setAnalysisPriorityOrder_nonEmpty', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setAnalysisPriorityOrder_nonEmpty);
//       });
//       _ut.test('test_setChangedContents_libraryWithPart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setChangedContents_libraryWithPart);
//       });
//       _ut.test('test_setChangedContents_notResolved', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setChangedContents_notResolved);
//       });
//       _ut.test('test_setContents_libraryWithPart', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setContents_libraryWithPart);
//       });
//       _ut.test('test_setContents_null', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setContents_null);
//       });
//       _ut.test('test_setSourceFactory', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setSourceFactory);
//       });
//       _ut.test('test_unreadableSource', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_unreadableSource);
//       });
//       _ut.test('test_updateAnalysis', () {
//         final __test = new AnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_updateAnalysis);
//       });
//     });
//   }
// }
// class AnalysisContextImpl_AnalysisContextImplTest_test_resolveCompilationUnit_sourceChangeDuringResolution extends AnalysisContextImpl {
//   @override
//   DartEntry recordResolveDartLibraryTaskResults(ResolveDartLibraryTask task) {
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.changedSource(task.librarySource);
//     applyChanges(changeSet);
//     return super.recordResolveDartLibraryTaskResults(task);
//   }
// }
// class AnalysisOptionsImplTest extends EngineTestCase {
//   void test_AnalysisOptionsImpl_copy() {
//     bool booleanValue = true;
//     for (int i = 0; i < 2; i++, booleanValue = !booleanValue) {
//       AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//       options.analyzeAngular = booleanValue;
//       options.analyzeFunctionBodies = booleanValue;
//       options.analyzePolymer = booleanValue;
//       options.cacheSize = i;
//       options.dart2jsHint = booleanValue;
//       options.enableDeferredLoading = booleanValue;
//       options.generateSdkErrors = booleanValue;
//       options.hint = booleanValue;
//       options.incremental = booleanValue;
//       options.preserveComments = booleanValue;
//       AnalysisOptionsImpl copy = new AnalysisOptionsImpl.con1(options);
//       JUnitTestCase.assertEquals(options.analyzeAngular, copy.analyzeAngular);
//       JUnitTestCase.assertEquals(options.analyzeFunctionBodies, copy.analyzeFunctionBodies);
//       JUnitTestCase.assertEquals(options.analyzePolymer, copy.analyzePolymer);
//       JUnitTestCase.assertEquals(options.cacheSize, copy.cacheSize);
//       JUnitTestCase.assertEquals(options.dart2jsHint, copy.dart2jsHint);
//       JUnitTestCase.assertEquals(options.enableAsync, copy.enableAsync);
//       JUnitTestCase.assertEquals(options.enableDeferredLoading, copy.enableDeferredLoading);
//       JUnitTestCase.assertEquals(options.enableEnum, copy.enableEnum);
//       JUnitTestCase.assertEquals(options.generateSdkErrors, copy.generateSdkErrors);
//       JUnitTestCase.assertEquals(options.hint, copy.hint);
//       JUnitTestCase.assertEquals(options.incremental, copy.incremental);
//       JUnitTestCase.assertEquals(options.preserveComments, copy.preserveComments);
//     }
//   }
//   void test_getAnalyzeAngular() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     bool value = !options.analyzeAngular;
//     options.analyzeAngular = value;
//     JUnitTestCase.assertEquals(value, options.analyzeAngular);
//   }
//   void test_getAnalyzeFunctionBodies() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     bool value = !options.analyzeFunctionBodies;
//     options.analyzeFunctionBodies = value;
//     JUnitTestCase.assertEquals(value, options.analyzeFunctionBodies);
//   }
//   void test_getAnalyzePolymer() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     bool value = !options.analyzePolymer;
//     options.analyzePolymer = value;
//     JUnitTestCase.assertEquals(value, options.analyzePolymer);
//   }
//   void test_getCacheSize() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     JUnitTestCase.assertEquals(AnalysisOptionsImpl.DEFAULT_CACHE_SIZE, options.cacheSize);
//     int value = options.cacheSize + 1;
//     options.cacheSize = value;
//     JUnitTestCase.assertEquals(value, options.cacheSize);
//   }
//   void test_getDart2jsHint() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     bool value = !options.dart2jsHint;
//     options.dart2jsHint = value;
//     JUnitTestCase.assertEquals(value, options.dart2jsHint);
//   }
//   void test_getEnableAsync() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     JUnitTestCase.assertEquals(AnalysisOptionsImpl.DEFAULT_ENABLE_ASYNC, options.enableAsync);
//     bool value = !options.enableAsync;
//     options.enableAsync = value;
//     JUnitTestCase.assertEquals(value, options.enableAsync);
//   }
//   void test_getEnableDeferredLoading() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     JUnitTestCase.assertEquals(AnalysisOptionsImpl.DEFAULT_ENABLE_DEFERRED_LOADING, options.enableDeferredLoading);
//     bool value = !options.enableDeferredLoading;
//     options.enableDeferredLoading = value;
//     JUnitTestCase.assertEquals(value, options.enableDeferredLoading);
//   }
//   void test_getEnableEnum() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     JUnitTestCase.assertEquals(AnalysisOptionsImpl.DEFAULT_ENABLE_ENUM, options.enableEnum);
//     bool value = !options.enableEnum;
//     options.enableEnum = value;
//     JUnitTestCase.assertEquals(value, options.enableEnum);
//   }
//   void test_getGenerateSdkErrors() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     bool value = !options.generateSdkErrors;
//     options.generateSdkErrors = value;
//     JUnitTestCase.assertEquals(value, options.generateSdkErrors);
//   }
//   void test_getHint() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     bool value = !options.hint;
//     options.hint = value;
//     JUnitTestCase.assertEquals(value, options.hint);
//   }
//   void test_getIncremental() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     bool value = !options.incremental;
//     options.incremental = value;
//     JUnitTestCase.assertEquals(value, options.incremental);
//   }
//   void test_getPreserveComments() {
//     AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//     bool value = !options.preserveComments;
//     options.preserveComments = value;
//     JUnitTestCase.assertEquals(value, options.preserveComments);
//   }
//   static dartSuite() {
//     _ut.group('AnalysisOptionsImplTest', () {
//       _ut.test('test_AnalysisOptionsImpl_copy', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_AnalysisOptionsImpl_copy);
//       });
//       _ut.test('test_getAnalyzeAngular', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getAnalyzeAngular);
//       });
//       _ut.test('test_getAnalyzeFunctionBodies', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getAnalyzeFunctionBodies);
//       });
//       _ut.test('test_getAnalyzePolymer', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getAnalyzePolymer);
//       });
//       _ut.test('test_getCacheSize', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getCacheSize);
//       });
//       _ut.test('test_getDart2jsHint', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getDart2jsHint);
//       });
//       _ut.test('test_getEnableAsync', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getEnableAsync);
//       });
//       _ut.test('test_getEnableDeferredLoading', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getEnableDeferredLoading);
//       });
//       _ut.test('test_getEnableEnum', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getEnableEnum);
//       });
//       _ut.test('test_getGenerateSdkErrors', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getGenerateSdkErrors);
//       });
//       _ut.test('test_getHint', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getHint);
//       });
//       _ut.test('test_getIncremental', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getIncremental);
//       });
//       _ut.test('test_getPreserveComments', () {
//         final __test = new AnalysisOptionsImplTest();
//         runJUnitTest(__test, __test.test_getPreserveComments);
//       });
//     });
//   }
// }
// class AnalysisTaskTest extends EngineTestCase {
//   void test_perform_exception() {
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     AnalysisTask task = new AnalysisTask_AnalysisTaskTest_test_perform_exception(context);
//     task.perform(new TestTaskVisitor<Object>());
//   }
//   static dartSuite() {
//     _ut.group('AnalysisTaskTest', () {
//       _ut.test('test_perform_exception', () {
//         final __test = new AnalysisTaskTest();
//         runJUnitTest(__test, __test.test_perform_exception);
//       });
//     });
//   }
// }
// class AnalysisTask_AnalysisTaskTest_test_perform_exception extends AnalysisTask {
//   AnalysisTask_AnalysisTaskTest_test_perform_exception(InternalAnalysisContext arg0) : super(arg0);
//   @override
//   accept(AnalysisTaskVisitor visitor) {
//     JUnitTestCase.assertNotNull(exception);
//     return null;
//   }
//   @override
//   String get taskDescription => null;
//   @override
//   void internalPerform() {
//     throw new AnalysisException("Forced exception");
//   }
// }
// class BuildDartElementModelTaskTest extends EngineTestCase {
//   void test_accept() {
//     AnalysisContextImpl context = AnalysisContextFactory.contextWithCore();
//     BuildDartElementModelTask task = new BuildDartElementModelTask(context, null, new List<ResolvableLibrary>());
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_BuildDartElementModelTaskTest_test_accept()));
//   }
//   void test_getErrors() {
//     AnalysisContextImpl context = AnalysisContextFactory.contextWithCore();
//     BuildDartElementModelTask task = new BuildDartElementModelTask(context, null, new List<ResolvableLibrary>());
//     EngineTestCase.assertLength(0, task.errorListener.errors);
//   }
//   void test_getLibrariesInCycle() {
//     AnalysisContextImpl context = AnalysisContextFactory.contextWithCore();
//     List<ResolvableLibrary> librariesInCycle = new List<ResolvableLibrary>();
//     BuildDartElementModelTask task = new BuildDartElementModelTask(context, null, librariesInCycle);
//     JUnitTestCase.assertSame(librariesInCycle, task.librariesInCycle);
//   }
//   void test_perform_multiple() {
//     AnalysisContextImpl context = AnalysisContextFactory.contextWithCore();
//     ResolvableLibrary lib3 = _createLibrary(<ResolvableCompilationUnit> [_createUnit(context, "/lib3.dart", EngineTestCase.createSource([
//         "library lib3;",
//         "import 'lib1.dart';",
//         "class C { A a; }"]))], null);
//     ResolvableLibrary lib2 = _createLibrary(<ResolvableCompilationUnit> [_createUnit(context, "/lib2.dart", EngineTestCase.createSource([
//         "library lib2;",
//         "import 'lib3.dart';",
//         "class B { C c; }"]))], <ResolvableLibrary> [_createCoreLibrary(context), lib3]);
//     ResolvableLibrary lib1 = _createLibrary(<ResolvableCompilationUnit> [_createUnit(context, "/lib1.dart", EngineTestCase.createSource([
//         "library lib1;",
//         "import 'lib2.dart';",
//         "class A { B b; }"]))], <ResolvableLibrary> [_createCoreLibrary(context), lib2]);
//     lib3.importedLibraries = <ResolvableLibrary> [_createCoreLibrary(context), lib1];
//     List<ResolvableLibrary> librariesInCycle = new List<ResolvableLibrary>();
//     librariesInCycle.add(lib1);
//     librariesInCycle.add(lib2);
//     librariesInCycle.add(lib3);
//     BuildDartElementModelTask task = new BuildDartElementModelTask(context, null, librariesInCycle);
//     task.perform(new TestTaskVisitor_BuildDartElementModelTaskTest_test_perform_multiple());
//   }
//   void test_perform_single_noParts() {
//     AnalysisContextImpl context = AnalysisContextFactory.contextWithCore();
//     ResolvableLibrary lib1 = _createLibrary(<ResolvableCompilationUnit> [_createUnit(context, "/lib1.dart", EngineTestCase.createSource(["library lib1;", "class A {}", "class B extends A {}"]))], <ResolvableLibrary> [_createCoreLibrary(context)]);
//     List<ResolvableLibrary> librariesInCycle = new List<ResolvableLibrary>();
//     librariesInCycle.add(lib1);
//     BuildDartElementModelTask task = new BuildDartElementModelTask(context, null, librariesInCycle);
//     task.perform(new TestTaskVisitor_BuildDartElementModelTaskTest_test_perform_single_noParts());
//   }
//   void test_perform_single_parts() {
//     AnalysisContextImpl context = AnalysisContextFactory.contextWithCore();
//     ResolvableLibrary lib1 = _createLibrary(<ResolvableCompilationUnit> [
//         _createUnit(context, "/lib1.dart", EngineTestCase.createSource([
//         "library lib1;",
//         "part 'part1-1.dart';",
//         "part 'part1-2.dart';",
//         "class A {}",
//         "class B extends A {}"])),
//         _createUnit(context, "/part1-1.dart", EngineTestCase.createSource(["part of lib1;", "class C extends B {}"])),
//         _createUnit(context, "/part1-2.dart", EngineTestCase.createSource(["part of lib1;", "class D implements A {}"]))], <ResolvableLibrary> [_createCoreLibrary(context)]);
//     List<ResolvableLibrary> librariesInCycle = new List<ResolvableLibrary>();
//     librariesInCycle.add(lib1);
//     BuildDartElementModelTask task = new BuildDartElementModelTask(context, null, librariesInCycle);
//     task.perform(new TestTaskVisitor_BuildDartElementModelTaskTest_test_perform_single_parts());
//   }
//   /**
//    * Create a resolvable library representing the core library.
//    *
//    * @param context the context used to build the library
//    * @return the resolvable library representing the core library
//    * @throws AnalysisException if the core library has not been resolved
//    */
//   ResolvableLibrary _createCoreLibrary(AnalysisContextImpl context) {
//     Source coreSource = context.sourceFactory.forUri(DartSdk.DART_CORE);
//     ResolvableLibrary coreLibrary = new ResolvableLibrary(coreSource);
//     coreLibrary.libraryElement = context.computeLibraryElement(coreSource) as LibraryElementImpl;
//     return coreLibrary;
//   }
//   /**
//    * Create a resolvable library with the given compilation units and imports.
//    *
//    * @param units the compilation units in the library, with the defining compilation unit first
//    * @param imports the libraries imported by the library (including the core library)
//    * @return the resolvable library that was created
//    */
//   ResolvableLibrary _createLibrary(List<ResolvableCompilationUnit> units, List<ResolvableLibrary> imports) {
//     ResolvableLibrary library = new ResolvableLibrary(units[0].source);
//     library.importedLibraries = imports;
//     library.resolvableCompilationUnits = units;
//     return library;
//   }
//   /**
//    * Return a resolvable compilation unit representing the file with the given name and contents.
//    *
//    * @param fileName the name of the file being represented
//    * @param contents the contents of the file being represented
//    * @return a resolvable compilation unit representing the file
//    */
//   ResolvableCompilationUnit _createUnit(AnalysisContextImpl context, String fileName, String contents) {
//     Source source = new FileBasedSource.con1(FileUtilities2.createFile(fileName));
//     context.setContents(source, contents);
//     return new ResolvableCompilationUnit.con2(source.modificationStamp, _parse(context, source, contents), source);
//   }
//   /**
//    * Return the result of parsing the given source.
//    *
//    * @param source the source being parsed
//    * @param contents the contents of the source
//    * @return the result of parsing the given source
//    */
//   CompilationUnit _parse(AnalysisContextImpl context, Source source, String contents) {
//     GatheringErrorListener errorListener = new GatheringErrorListener();
//     Scanner scanner = new Scanner(source, new CharSequenceReader(contents), errorListener);
//     Parser parser = new Parser(source, errorListener);
//     CompilationUnit unit = parser.parseCompilationUnit(scanner.tokenize());
//     for (Directive directive in unit.directives) {
//       if (directive is UriBasedDirective) {
//         UriBasedDirective uriDirective = directive as UriBasedDirective;
//         ParseDartTask.resolveDirective(context, source, uriDirective, errorListener);
//       }
//     }
//     return unit;
//   }
//   static dartSuite() {
//     _ut.group('BuildDartElementModelTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new BuildDartElementModelTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getErrors', () {
//         final __test = new BuildDartElementModelTaskTest();
//         runJUnitTest(__test, __test.test_getErrors);
//       });
//       _ut.test('test_getLibrariesInCycle', () {
//         final __test = new BuildDartElementModelTaskTest();
//         runJUnitTest(__test, __test.test_getLibrariesInCycle);
//       });
//       _ut.test('test_perform_multiple', () {
//         final __test = new BuildDartElementModelTaskTest();
//         runJUnitTest(__test, __test.test_perform_multiple);
//       });
//       _ut.test('test_perform_single_noParts', () {
//         final __test = new BuildDartElementModelTaskTest();
//         runJUnitTest(__test, __test.test_perform_single_noParts);
//       });
//       _ut.test('test_perform_single_parts', () {
//         final __test = new BuildDartElementModelTaskTest();
//         runJUnitTest(__test, __test.test_perform_single_parts);
//       });
//     });
//   }
// }
// class CacheRetentionPolicy_AnalysisCacheTest_test_setMaxCacheSize implements CacheRetentionPolicy {
//   @override
//   RetentionPriority getAstPriority(Source source, SourceEntry sourceEntry) => RetentionPriority.LOW;
// }
// class CacheRetentionPolicy_UniversalCachePartitionTest_test_setMaxCacheSize implements CacheRetentionPolicy {
//   @override
//   RetentionPriority getAstPriority(Source source, SourceEntry sourceEntry) => RetentionPriority.LOW;
// }
// class DartEntryImplTest extends EngineTestCase {
//   void test_creation() {
//     Source librarySource = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.CONTENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.TOKEN_STREAM));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.BUILD_ELEMENT_ERRORS, librarySource));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.BUILT_UNIT, librarySource));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.HINTS, librarySource));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, librarySource));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, librarySource));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, librarySource));
//   }
//   void test_getAllErrors() {
//     Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     EngineTestCase.assertLength(0, entry.allErrors);
//     entry.setValue(DartEntry.SCAN_ERRORS, <AnalysisError> [new AnalysisError.con1(source, ScannerErrorCode.UNTERMINATED_STRING_LITERAL, [])]);
//     entry.setValue(DartEntry.PARSE_ERRORS, <AnalysisError> [new AnalysisError.con1(source, ParserErrorCode.ABSTRACT_CLASS_MEMBER, [])]);
//     entry.setValueInLibrary(DartEntry.BUILD_ELEMENT_ERRORS, source, <AnalysisError> [new AnalysisError.con1(source, CompileTimeErrorCode.MIXIN_OF_NON_CLASS, [])]);
//     entry.setValueInLibrary(DartEntry.RESOLUTION_ERRORS, source, <AnalysisError> [new AnalysisError.con1(source, CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION, [])]);
//     entry.setValueInLibrary(DartEntry.VERIFICATION_ERRORS, source, <AnalysisError> [new AnalysisError.con1(source, StaticWarningCode.CASE_BLOCK_NOT_TERMINATED, [])]);
//     entry.setValueInLibrary(DartEntry.HINTS, source, <AnalysisError> [new AnalysisError.con1(source, HintCode.DEAD_CODE, [])]);
//     EngineTestCase.assertLength(6, entry.allErrors);
//   }
//   void test_getResolvableCompilationUnit_none() {
//     DartEntryImpl entry = new DartEntryImpl();
//     JUnitTestCase.assertNull(entry.resolvableCompilationUnit);
//   }
//   void test_getResolvableCompilationUnit_parsed_accessed() {
//     String importUri = "f1.dart";
//     Source importSource = new TestSource.con1(FileUtilities2.createFile(importUri), "");
//     ImportDirective importDirective = AstFactory.importDirective3(importUri, null, []);
//     importDirective.source = importSource;
//     importDirective.uriContent = importUri;
//     String exportUri = "f2.dart";
//     Source exportSource = new TestSource.con1(FileUtilities2.createFile(exportUri), "");
//     ExportDirective exportDirective = AstFactory.exportDirective2(exportUri, []);
//     exportDirective.source = exportSource;
//     exportDirective.uriContent = exportUri;
//     String partUri = "f3.dart";
//     Source partSource = new TestSource.con1(FileUtilities2.createFile(partUri), "");
//     PartDirective partDirective = AstFactory.partDirective2(partUri);
//     partDirective.source = partSource;
//     partDirective.uriContent = partUri;
//     CompilationUnit unit = AstFactory.compilationUnit3([importDirective, exportDirective, partDirective]);
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.setValue(DartEntry.PARSED_UNIT, unit);
//     entry.getValue(DartEntry.PARSED_UNIT);
//     CompilationUnit result = entry.resolvableCompilationUnit;
//     JUnitTestCase.assertNotSame(unit, result);
//     NodeList<Directive> directives = result.directives;
//     ImportDirective resultImportDirective = directives[0] as ImportDirective;
//     JUnitTestCase.assertEquals(importUri, resultImportDirective.uriContent);
//     JUnitTestCase.assertSame(importSource, resultImportDirective.source);
//     ExportDirective resultExportDirective = directives[1] as ExportDirective;
//     JUnitTestCase.assertEquals(exportUri, resultExportDirective.uriContent);
//     JUnitTestCase.assertSame(exportSource, resultExportDirective.source);
//     PartDirective resultPartDirective = directives[2] as PartDirective;
//     JUnitTestCase.assertEquals(partUri, resultPartDirective.uriContent);
//     JUnitTestCase.assertSame(partSource, resultPartDirective.source);
//   }
//   void test_getResolvableCompilationUnit_parsed_notAccessed() {
//     CompilationUnit unit = AstFactory.compilationUnit();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.setValue(DartEntry.PARSED_UNIT, unit);
//     JUnitTestCase.assertSame(unit, entry.resolvableCompilationUnit);
//   }
//   void test_getResolvableCompilationUnit_resolved() {
//     String importUri = "f1.dart";
//     Source importSource = new TestSource.con1(FileUtilities2.createFile(importUri), "");
//     ImportDirective importDirective = AstFactory.importDirective3(importUri, null, []);
//     importDirective.source = importSource;
//     importDirective.uriContent = importUri;
//     String exportUri = "f2.dart";
//     Source exportSource = new TestSource.con1(FileUtilities2.createFile(exportUri), "");
//     ExportDirective exportDirective = AstFactory.exportDirective2(exportUri, []);
//     exportDirective.source = exportSource;
//     exportDirective.uriContent = exportUri;
//     String partUri = "f3.dart";
//     Source partSource = new TestSource.con1(FileUtilities2.createFile(partUri), "");
//     PartDirective partDirective = AstFactory.partDirective2(partUri);
//     partDirective.source = partSource;
//     partDirective.uriContent = partUri;
//     CompilationUnit unit = AstFactory.compilationUnit3([importDirective, exportDirective, partDirective]);
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, new TestSource.con1(FileUtilities2.createFile("lib.dart"), ""), unit);
//     CompilationUnit result = entry.resolvableCompilationUnit;
//     JUnitTestCase.assertNotSame(unit, result);
//     NodeList<Directive> directives = result.directives;
//     ImportDirective resultImportDirective = directives[0] as ImportDirective;
//     JUnitTestCase.assertEquals(importUri, resultImportDirective.uriContent);
//     JUnitTestCase.assertSame(importSource, resultImportDirective.source);
//     ExportDirective resultExportDirective = directives[1] as ExportDirective;
//     JUnitTestCase.assertEquals(exportUri, resultExportDirective.uriContent);
//     JUnitTestCase.assertSame(exportSource, resultExportDirective.source);
//     PartDirective resultPartDirective = directives[2] as PartDirective;
//     JUnitTestCase.assertEquals(partUri, resultPartDirective.uriContent);
//     JUnitTestCase.assertSame(partSource, resultPartDirective.source);
//   }
//   void test_getState_invalid_buildElementErrors() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.getState(DartEntry.BUILD_ELEMENT_ERRORS);
//       JUnitTestCase.fail("Expected IllegalArgumentException for BUILD_ELEMENT_ERRORS");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_getState_invalid_resolutionErrors() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.getState(DartEntry.RESOLUTION_ERRORS);
//       JUnitTestCase.fail("Expected IllegalArgumentException for RESOLUTION_ERRORS");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_getState_invalid_verificationErrors() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.getState(DartEntry.VERIFICATION_ERRORS);
//       JUnitTestCase.fail("Expected IllegalArgumentException for VERIFICATION_ERRORS");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_getStateInLibrary_invalid_element() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.getStateInLibrary(DartEntry.ELEMENT, new TestSource());
//       JUnitTestCase.fail("Expected IllegalArgumentException for ELEMENT");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_getValue_containingLibraries() {
//     Source testSource = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     List<Source> value = entry.getValue(DartEntry.CONTAINING_LIBRARIES);
//     EngineTestCase.assertLength(0, value);
//     entry.addContainingLibrary(testSource);
//     value = entry.getValue(DartEntry.CONTAINING_LIBRARIES);
//     EngineTestCase.assertLength(1, value);
//     JUnitTestCase.assertEquals(testSource, value[0]);
//     entry.removeContainingLibrary(testSource);
//     value = entry.getValue(DartEntry.CONTAINING_LIBRARIES);
//     EngineTestCase.assertLength(0, value);
//   }
//   void test_getValue_invalid_buildElementErrors() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.getValue(DartEntry.BUILD_ELEMENT_ERRORS);
//       JUnitTestCase.fail("Expected IllegalArgumentException for BUILD_ELEMENT_ERRORS");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_getValue_invalid_resolutionErrors() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.getValue(DartEntry.RESOLUTION_ERRORS);
//       JUnitTestCase.fail("Expected IllegalArgumentException for RESOLUTION_ERRORS");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_getValue_invalid_verificationErrors() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.getValue(DartEntry.VERIFICATION_ERRORS);
//       JUnitTestCase.fail("Expected IllegalArgumentException for VERIFICATION_ERRORS");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_getValueInLibrary_invalid_element() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.getValueInLibrary(DartEntry.ELEMENT, new TestSource());
//       JUnitTestCase.fail("Expected IllegalArgumentException for ELEMENT");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_getValueInLibrary_invalid_resolutionErrors_multiple() {
//     Source source1 = new TestSource();
//     Source source2 = new TestSource();
//     Source source3 = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source1, AstFactory.compilationUnit());
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source2, AstFactory.compilationUnit());
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source3, AstFactory.compilationUnit());
//     try {
//       entry.getValueInLibrary(DartEntry.ELEMENT, source3);
//       JUnitTestCase.fail("Expected IllegalArgumentException for ELEMENT");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_getWritableCopy() {
//     DartEntryImpl entry = new DartEntryImpl();
//     DartEntryImpl copy = entry.writableCopy;
//     JUnitTestCase.assertNotNull(copy);
//     JUnitTestCase.assertNotSame(entry, copy);
//   }
//   void test_hasInvalidData_false() {
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordScanError(new CaughtException(new AnalysisException(), null));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.ELEMENT));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.HINTS));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.BUILD_ELEMENT_ERRORS));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.RESOLUTION_ERRORS));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.RESOLVED_UNIT));
//     JUnitTestCase.assertFalse(entry.hasInvalidData(DartEntry.VERIFICATION_ERRORS));
//   }
//   void test_hasInvalidData_true() {
//     DartEntryImpl entry = new DartEntryImpl();
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.ELEMENT));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.HINTS));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.BUILD_ELEMENT_ERRORS));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.RESOLUTION_ERRORS));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.RESOLVED_UNIT));
//     JUnitTestCase.assertTrue(entry.hasInvalidData(DartEntry.VERIFICATION_ERRORS));
//   }
//   void test_invalidateAllInformation() {
//     DartEntryImpl entry = _entryWithValidState();
//     entry.invalidateAllInformation();
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.TOKEN_STREAM));
//   }
//   void test_invalidateAllResolutionInformation() {
//     DartEntryImpl entry = _entryWithValidState();
//     entry.invalidateAllResolutionInformation(false);
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.INCLUDED_PARTS));
//   }
//   void test_invalidateAllResolutionInformation_includingUris() {
//     DartEntryImpl entry = _entryWithValidState();
//     entry.invalidateAllResolutionInformation(true);
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.INCLUDED_PARTS));
//   }
//   void test_isClient() {
//     DartEntryImpl entry = new DartEntryImpl();
//     // true
//     entry.setValue(DartEntry.IS_CLIENT, true);
//     JUnitTestCase.assertTrue(entry.getValue(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.IS_CLIENT));
//     // invalidate
//     entry.setState(DartEntry.IS_CLIENT, CacheState.INVALID);
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_CLIENT));
//     // false
//     entry.setValue(DartEntry.IS_CLIENT, false);
//     JUnitTestCase.assertFalse(entry.getValue(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.IS_CLIENT));
//   }
//   void test_isLaunchable() {
//     DartEntryImpl entry = new DartEntryImpl();
//     // true
//     entry.setValue(DartEntry.IS_LAUNCHABLE, true);
//     JUnitTestCase.assertTrue(entry.getValue(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//     // invalidate
//     entry.setState(DartEntry.IS_LAUNCHABLE, CacheState.INVALID);
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//     // false
//     entry.setValue(DartEntry.IS_LAUNCHABLE, false);
//     JUnitTestCase.assertFalse(entry.getValue(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//   }
//   void test_recordBuildElementErrorInLibrary() {
//     // TODO(brianwilkerson) This test should set the state for two libraries, record an error in one
//     // library, then verify that the data for the other library is still valid.
//     Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordBuildElementErrorInLibrary(source, new CaughtException(new AnalysisException(), null));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.CONTENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.TOKEN_STREAM));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.BUILD_ELEMENT_ERRORS, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.BUILT_UNIT, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.HINTS, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, source));
//   }
//   void test_recordContentError() {
//     //    Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordContentError(new CaughtException(new AnalysisException(), null));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(SourceEntry.CONTENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.TOKEN_STREAM));
//   }
//   void test_recordHintErrorInLibrary() {
//     // TODO(brianwilkerson) This test should set the state for two libraries, record an error in one
//     // library, then verify that the data for the other library is still valid.
//     Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordHintErrorInLibrary(source, new CaughtException(new AnalysisException(), null));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.CONTENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.TOKEN_STREAM));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.BUILD_ELEMENT_ERRORS, source));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.BUILT_UNIT, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.HINTS, source));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, source));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, source));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, source));
//   }
//   void test_recordParseError() {
//     //    Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordParseError(new CaughtException(new AnalysisException(), null));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.CONTENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.TOKEN_STREAM));
//   }
//   void test_recordParseInProcess() {
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordParseInProcess();
//     JUnitTestCase.assertSame(CacheState.IN_PROCESS, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.IN_PROCESS, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.IN_PROCESS, entry.getState(DartEntry.SOURCE_KIND));
//   }
//   void test_recordResolutionError() {
//     //    Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordResolutionError(new CaughtException(new AnalysisException(), null));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.CONTENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.TOKEN_STREAM));
//   }
//   void test_recordResolutionErrorInLibrary() {
//     // TODO(brianwilkerson) This test should set the state for two libraries, record an error in one
//     // library, then verify that the data for the other library is still valid.
//     Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordResolutionErrorInLibrary(source, new CaughtException(new AnalysisException(), null));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.CONTENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.TOKEN_STREAM));
//     // The following lines are commented out because we don't currently have any way of setting the
//     // state for data associated with a library we don't know anything about.
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.BUILD_ELEMENT_ERRORS, source));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.BUILT_UNIT, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.HINTS, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, source));
//   }
//   void test_recordScanError() {
//     //    Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordScanError(new CaughtException(new AnalysisException(), null));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.CONTENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getState(DartEntry.TOKEN_STREAM));
//   }
//   void test_recordScanInProcess() {
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordScanInProcess();
//     JUnitTestCase.assertSame(CacheState.IN_PROCESS, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.IN_PROCESS, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.IN_PROCESS, entry.getState(DartEntry.TOKEN_STREAM));
//   }
//   void test_recordVerificationErrorInLibrary() {
//     // TODO(brianwilkerson) This test should set the state for two libraries, record an error in one
//     // library, then verify that the data for the other library is still valid.
//     Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.recordVerificationErrorInLibrary(source, new CaughtException(new AnalysisException(), null));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.CONTENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SCAN_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.SOURCE_KIND));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(DartEntry.TOKEN_STREAM));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.BUILD_ELEMENT_ERRORS, source));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.BUILT_UNIT, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.HINTS, source));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.RESOLUTION_ERRORS, source));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getStateInLibrary(DartEntry.RESOLVED_UNIT, source));
//     JUnitTestCase.assertSame(CacheState.ERROR, entry.getStateInLibrary(DartEntry.VERIFICATION_ERRORS, source));
//   }
//   void test_removeResolution_multiple_first() {
//     Source source1 = new TestSource();
//     Source source2 = new TestSource();
//     Source source3 = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source1, AstFactory.compilationUnit());
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source2, AstFactory.compilationUnit());
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source3, AstFactory.compilationUnit());
//     entry.removeResolution(source1);
//   }
//   void test_removeResolution_multiple_last() {
//     Source source1 = new TestSource();
//     Source source2 = new TestSource();
//     Source source3 = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source1, AstFactory.compilationUnit());
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source2, AstFactory.compilationUnit());
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source3, AstFactory.compilationUnit());
//     entry.removeResolution(source3);
//   }
//   void test_removeResolution_multiple_middle() {
//     Source source1 = new TestSource();
//     Source source2 = new TestSource();
//     Source source3 = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source1, AstFactory.compilationUnit());
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source2, AstFactory.compilationUnit());
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source3, AstFactory.compilationUnit());
//     entry.removeResolution(source2);
//   }
//   void test_removeResolution_single() {
//     Source source1 = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source1, AstFactory.compilationUnit());
//     entry.removeResolution(source1);
//   }
//   void test_resolutionState() {
//     DartEntryImpl entry1 = new DartEntryImpl();
//     Source libSrc1 = new TestSource.con1(FileUtilities2.createFile("/test1.dart"), "");
//     Source libSrc2 = new TestSource.con1(FileUtilities2.createFile("/test2.dart"), "");
//     ParserErrorCode errCode = ParserErrorCode.DIRECTIVE_AFTER_DECLARATION;
//     List<AnalysisError> errors1 = <AnalysisError> [new AnalysisError.con2(libSrc1, 0, 10, errCode, [])];
//     List<AnalysisError> errors2 = <AnalysisError> [new AnalysisError.con2(libSrc2, 0, 20, errCode, [])];
//     entry1.setValueInLibrary(DartEntry.RESOLUTION_ERRORS, libSrc1, errors1);
//     entry1.setValueInLibrary(DartEntry.RESOLUTION_ERRORS, libSrc2, errors2);
//     TestDartEntryImpl entry2 = new TestDartEntryImpl();
//     entry2.copyFrom(entry1);
//     EngineTestCase.assertExactElementsInArray(entry2.allErrors, [errors1[0], errors2[0]]);
//     entry1.removeResolution(libSrc2);
//     EngineTestCase.assertExactElementsInArray(entry1.allErrors, [errors1[0]]);
//     entry2.removeResolution(libSrc1);
//     EngineTestCase.assertExactElementsInArray(entry2.allErrors, [errors2[0]]);
//     entry2.removeResolution(libSrc2);
//     EngineTestCase.assertExactElementsInArray(entry2.allErrors, []);
//   }
//   void test_setState_buildElementErrors() {
//     state3 = DartEntry.BUILD_ELEMENT_ERRORS;
//   }
//   void test_setState_element() {
//     state2 = DartEntry.ELEMENT;
//   }
//   void test_setState_exportedLibraries() {
//     state2 = DartEntry.EXPORTED_LIBRARIES;
//   }
//   void test_setState_hints() {
//     state3 = DartEntry.HINTS;
//   }
//   void test_setState_importedLibraries() {
//     state2 = DartEntry.IMPORTED_LIBRARIES;
//   }
//   void test_setState_includedParts() {
//     state2 = DartEntry.INCLUDED_PARTS;
//   }
//   void test_setState_invalid_buildElementErrors() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.setState(DartEntry.BUILD_ELEMENT_ERRORS, CacheState.FLUSHED);
//       JUnitTestCase.fail("Expected IllegalArgumentException for BUILD_ELEMENT_ERRORS");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_setState_invalid_element() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.setStateInLibrary(DartEntry.ELEMENT, null, CacheState.FLUSHED);
//       JUnitTestCase.fail("Expected IllegalArgumentException for ELEMENT");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_setState_invalid_resolutionErrors() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.setState(DartEntry.RESOLUTION_ERRORS, CacheState.FLUSHED);
//       JUnitTestCase.fail("Expected IllegalArgumentException for RESOLUTION_ERRORS");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_setState_invalid_validState() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.setState(DartEntry.LINE_INFO, CacheState.VALID);
//       JUnitTestCase.fail("Expected IllegalArgumentException for a state of VALID");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_setState_invalid_verificationErrors() {
//     DartEntryImpl entry = new DartEntryImpl();
//     try {
//       entry.setState(DartEntry.VERIFICATION_ERRORS, CacheState.FLUSHED);
//       JUnitTestCase.fail("Expected IllegalArgumentException for VERIFICATION_ERRORS");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_setState_isClient() {
//     state2 = DartEntry.IS_CLIENT;
//   }
//   void test_setState_isLaunchable() {
//     state2 = DartEntry.IS_LAUNCHABLE;
//   }
//   void test_setState_lineInfo() {
//     state2 = SourceEntry.LINE_INFO;
//   }
//   void test_setState_parsedUnit() {
//     state2 = DartEntry.PARSED_UNIT;
//   }
//   void test_setState_parseErrors() {
//     state2 = DartEntry.PARSE_ERRORS;
//   }
//   void test_setState_publicNamespace() {
//     state2 = DartEntry.PUBLIC_NAMESPACE;
//   }
//   void test_setState_resolutionErrors() {
//     state3 = DartEntry.RESOLUTION_ERRORS;
//   }
//   void test_setState_resolvedUnit() {
//     state3 = DartEntry.RESOLVED_UNIT;
//   }
//   void test_setState_scanErrors() {
//     state2 = DartEntry.SCAN_ERRORS;
//   }
//   void test_setState_sourceKind() {
//     state2 = DartEntry.SOURCE_KIND;
//   }
//   void test_setState_tokenStream() {
//     state2 = DartEntry.TOKEN_STREAM;
//   }
//   void test_setState_verificationErrors() {
//     state3 = DartEntry.VERIFICATION_ERRORS;
//   }
//   void test_setValue_buildElementErrors() {
//     _setValue3(DartEntry.BUILD_ELEMENT_ERRORS, <AnalysisError> [new AnalysisError.con1(null, CompileTimeErrorCode.MIXIN_OF_NON_CLASS, [])]);
//   }
//   void test_setValue_element() {
//     _setValue2(DartEntry.ELEMENT, new LibraryElementImpl.forNode(null, AstFactory.libraryIdentifier2(["lib"])));
//   }
//   void test_setValue_exportedLibraries() {
//     _setValue2(DartEntry.EXPORTED_LIBRARIES, <Source> [new TestSource()]);
//   }
//   void test_setValue_hints() {
//     _setValue3(DartEntry.HINTS, <AnalysisError> [new AnalysisError.con1(null, HintCode.DEAD_CODE, [])]);
//   }
//   void test_setValue_importedLibraries() {
//     _setValue2(DartEntry.IMPORTED_LIBRARIES, <Source> [new TestSource()]);
//   }
//   void test_setValue_includedParts() {
//     _setValue2(DartEntry.INCLUDED_PARTS, <Source> [new TestSource()]);
//   }
//   void test_setValue_isClient() {
//     _setValue2(DartEntry.IS_CLIENT, true);
//   }
//   void test_setValue_isLaunchable() {
//     _setValue2(DartEntry.IS_LAUNCHABLE, true);
//   }
//   void test_setValue_lineInfo() {
//     _setValue2(SourceEntry.LINE_INFO, new LineInfo(<int> [0]));
//   }
//   void test_setValue_parsedUnit() {
//     _setValue2(DartEntry.PARSED_UNIT, AstFactory.compilationUnit());
//   }
//   void test_setValue_parseErrors() {
//     _setValue2(DartEntry.PARSE_ERRORS, <AnalysisError> [new AnalysisError.con1(null, ParserErrorCode.ABSTRACT_CLASS_MEMBER, [])]);
//   }
//   void test_setValue_publicNamespace() {
//     _setValue2(DartEntry.PUBLIC_NAMESPACE, new Namespace(new HashMap<String, Element>()));
//   }
//   void test_setValue_resolutionErrors() {
//     _setValue3(DartEntry.RESOLUTION_ERRORS, <AnalysisError> [new AnalysisError.con1(null, CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION, [])]);
//   }
//   void test_setValue_resolvedUnit() {
//     _setValue3(DartEntry.RESOLVED_UNIT, AstFactory.compilationUnit());
//   }
//   void test_setValue_scanErrors() {
//     _setValue2(DartEntry.SCAN_ERRORS, <AnalysisError> [new AnalysisError.con1(null, ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT, [])]);
//   }
//   void test_setValue_sourceKind() {
//     _setValue2(DartEntry.SOURCE_KIND, SourceKind.LIBRARY);
//   }
//   void test_setValue_tokenStream() {
//     _setValue2(DartEntry.TOKEN_STREAM, new Token(TokenType.LT, 5));
//   }
//   void test_setValue_verificationErrors() {
//     _setValue3(DartEntry.VERIFICATION_ERRORS, <AnalysisError> [new AnalysisError.con1(null, StaticWarningCode.CASE_BLOCK_NOT_TERMINATED, [])]);
//   }
//   DartEntryImpl _entryWithValidState() {
//     DartEntryImpl entry = new DartEntryImpl();
//     entry.setValue(DartEntry.ELEMENT, null);
//     entry.setValue(DartEntry.EXPORTED_LIBRARIES, null);
//     entry.setValue(DartEntry.IMPORTED_LIBRARIES, null);
//     entry.setValue(DartEntry.INCLUDED_PARTS, null);
//     entry.setValue(DartEntry.IS_CLIENT, true);
//     entry.setValue(DartEntry.IS_LAUNCHABLE, true);
//     entry.setValue(SourceEntry.LINE_INFO, null);
//     entry.setValue(DartEntry.PARSE_ERRORS, null);
//     entry.setValue(DartEntry.PARSED_UNIT, null);
//     entry.setValue(DartEntry.PUBLIC_NAMESPACE, null);
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.EXPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.IMPORTED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.INCLUDED_PARTS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.IS_CLIENT));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.IS_LAUNCHABLE));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(DartEntry.PUBLIC_NAMESPACE));
//     return entry;
//   }
//   void set state2(DataDescriptor descriptor) {
//     DartEntryImpl entry = new DartEntryImpl();
//     JUnitTestCase.assertNotSame(CacheState.FLUSHED, entry.getState(descriptor));
//     entry.setState(descriptor, CacheState.FLUSHED);
//     JUnitTestCase.assertSame(CacheState.FLUSHED, entry.getState(descriptor));
//   }
//   void set state3(DataDescriptor descriptor) {
//     Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     JUnitTestCase.assertNotSame(CacheState.FLUSHED, entry.getStateInLibrary(descriptor, source));
//     entry.setStateInLibrary(descriptor, source, CacheState.FLUSHED);
//     JUnitTestCase.assertSame(CacheState.FLUSHED, entry.getStateInLibrary(descriptor, source));
//   }
//   void _setValue2(DataDescriptor descriptor, Object newValue) {
//     DartEntryImpl entry = new DartEntryImpl();
//     Object value = entry.getValue(descriptor);
//     JUnitTestCase.assertNotSame(value, newValue);
//     entry.setValue(descriptor, newValue);
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(descriptor));
//     JUnitTestCase.assertSame(newValue, entry.getValue(descriptor));
//   }
//   void _setValue3(DataDescriptor descriptor, Object newValue) {
//     Source source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     Object value = entry.getValueInLibrary(descriptor, source);
//     JUnitTestCase.assertNotSame(value, newValue);
//     entry.setValueInLibrary(descriptor, source, newValue);
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getStateInLibrary(descriptor, source));
//     JUnitTestCase.assertSame(newValue, entry.getValueInLibrary(descriptor, source));
//   }
//   static dartSuite() {
//     _ut.group('DartEntryImplTest', () {
//       _ut.test('test_creation', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_getAllErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getAllErrors);
//       });
//       _ut.test('test_getResolvableCompilationUnit_none', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getResolvableCompilationUnit_none);
//       });
//       _ut.test('test_getResolvableCompilationUnit_parsed_accessed', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getResolvableCompilationUnit_parsed_accessed);
//       });
//       _ut.test('test_getResolvableCompilationUnit_parsed_notAccessed', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getResolvableCompilationUnit_parsed_notAccessed);
//       });
//       _ut.test('test_getResolvableCompilationUnit_resolved', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getResolvableCompilationUnit_resolved);
//       });
//       _ut.test('test_getStateInLibrary_invalid_element', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getStateInLibrary_invalid_element);
//       });
//       _ut.test('test_getState_invalid_buildElementErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getState_invalid_buildElementErrors);
//       });
//       _ut.test('test_getState_invalid_resolutionErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getState_invalid_resolutionErrors);
//       });
//       _ut.test('test_getState_invalid_verificationErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getState_invalid_verificationErrors);
//       });
//       _ut.test('test_getValueInLibrary_invalid_element', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getValueInLibrary_invalid_element);
//       });
//       _ut.test('test_getValueInLibrary_invalid_resolutionErrors_multiple', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getValueInLibrary_invalid_resolutionErrors_multiple);
//       });
//       _ut.test('test_getValue_containingLibraries', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getValue_containingLibraries);
//       });
//       _ut.test('test_getValue_invalid_buildElementErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getValue_invalid_buildElementErrors);
//       });
//       _ut.test('test_getValue_invalid_resolutionErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getValue_invalid_resolutionErrors);
//       });
//       _ut.test('test_getValue_invalid_verificationErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getValue_invalid_verificationErrors);
//       });
//       _ut.test('test_getWritableCopy', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_getWritableCopy);
//       });
//       _ut.test('test_hasInvalidData_false', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_hasInvalidData_false);
//       });
//       _ut.test('test_hasInvalidData_true', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_hasInvalidData_true);
//       });
//       _ut.test('test_invalidateAllInformation', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_invalidateAllInformation);
//       });
//       _ut.test('test_invalidateAllResolutionInformation', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_invalidateAllResolutionInformation);
//       });
//       _ut.test('test_invalidateAllResolutionInformation_includingUris', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_invalidateAllResolutionInformation_includingUris);
//       });
//       _ut.test('test_isClient', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_isClient);
//       });
//       _ut.test('test_isLaunchable', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_isLaunchable);
//       });
//       _ut.test('test_recordBuildElementErrorInLibrary', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordBuildElementErrorInLibrary);
//       });
//       _ut.test('test_recordContentError', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordContentError);
//       });
//       _ut.test('test_recordHintErrorInLibrary', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordHintErrorInLibrary);
//       });
//       _ut.test('test_recordParseError', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordParseError);
//       });
//       _ut.test('test_recordParseInProcess', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordParseInProcess);
//       });
//       _ut.test('test_recordResolutionError', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordResolutionError);
//       });
//       _ut.test('test_recordResolutionErrorInLibrary', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordResolutionErrorInLibrary);
//       });
//       _ut.test('test_recordScanError', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordScanError);
//       });
//       _ut.test('test_recordScanInProcess', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordScanInProcess);
//       });
//       _ut.test('test_recordVerificationErrorInLibrary', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_recordVerificationErrorInLibrary);
//       });
//       _ut.test('test_removeResolution_multiple_first', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_removeResolution_multiple_first);
//       });
//       _ut.test('test_removeResolution_multiple_last', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_removeResolution_multiple_last);
//       });
//       _ut.test('test_removeResolution_multiple_middle', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_removeResolution_multiple_middle);
//       });
//       _ut.test('test_removeResolution_single', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_removeResolution_single);
//       });
//       _ut.test('test_resolutionState', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_resolutionState);
//       });
//       _ut.test('test_setState_buildElementErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_buildElementErrors);
//       });
//       _ut.test('test_setState_element', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_element);
//       });
//       _ut.test('test_setState_exportedLibraries', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_exportedLibraries);
//       });
//       _ut.test('test_setState_hints', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_hints);
//       });
//       _ut.test('test_setState_importedLibraries', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_importedLibraries);
//       });
//       _ut.test('test_setState_includedParts', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_includedParts);
//       });
//       _ut.test('test_setState_invalid_buildElementErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_invalid_buildElementErrors);
//       });
//       _ut.test('test_setState_invalid_element', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_invalid_element);
//       });
//       _ut.test('test_setState_invalid_resolutionErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_invalid_resolutionErrors);
//       });
//       _ut.test('test_setState_invalid_validState', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_invalid_validState);
//       });
//       _ut.test('test_setState_invalid_verificationErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_invalid_verificationErrors);
//       });
//       _ut.test('test_setState_isClient', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_isClient);
//       });
//       _ut.test('test_setState_isLaunchable', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_isLaunchable);
//       });
//       _ut.test('test_setState_lineInfo', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_lineInfo);
//       });
//       _ut.test('test_setState_parseErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_parseErrors);
//       });
//       _ut.test('test_setState_parsedUnit', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_parsedUnit);
//       });
//       _ut.test('test_setState_publicNamespace', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_publicNamespace);
//       });
//       _ut.test('test_setState_resolutionErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_resolutionErrors);
//       });
//       _ut.test('test_setState_resolvedUnit', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_resolvedUnit);
//       });
//       _ut.test('test_setState_scanErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_scanErrors);
//       });
//       _ut.test('test_setState_sourceKind', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_sourceKind);
//       });
//       _ut.test('test_setState_tokenStream', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_tokenStream);
//       });
//       _ut.test('test_setState_verificationErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_verificationErrors);
//       });
//       _ut.test('test_setValue_buildElementErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_buildElementErrors);
//       });
//       _ut.test('test_setValue_element', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_element);
//       });
//       _ut.test('test_setValue_exportedLibraries', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_exportedLibraries);
//       });
//       _ut.test('test_setValue_hints', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_hints);
//       });
//       _ut.test('test_setValue_importedLibraries', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_importedLibraries);
//       });
//       _ut.test('test_setValue_includedParts', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_includedParts);
//       });
//       _ut.test('test_setValue_isClient', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_isClient);
//       });
//       _ut.test('test_setValue_isLaunchable', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_isLaunchable);
//       });
//       _ut.test('test_setValue_lineInfo', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_lineInfo);
//       });
//       _ut.test('test_setValue_parseErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_parseErrors);
//       });
//       _ut.test('test_setValue_parsedUnit', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_parsedUnit);
//       });
//       _ut.test('test_setValue_publicNamespace', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_publicNamespace);
//       });
//       _ut.test('test_setValue_resolutionErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_resolutionErrors);
//       });
//       _ut.test('test_setValue_resolvedUnit', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_resolvedUnit);
//       });
//       _ut.test('test_setValue_scanErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_scanErrors);
//       });
//       _ut.test('test_setValue_sourceKind', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_sourceKind);
//       });
//       _ut.test('test_setValue_tokenStream', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_tokenStream);
//       });
//       _ut.test('test_setValue_verificationErrors', () {
//         final __test = new DartEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_verificationErrors);
//       });
//     });
//   }
// }
// class GenerateDartErrorsTaskTest extends EngineTestCase {
//   void test_accept() {
//     GenerateDartErrorsTask task = new GenerateDartErrorsTask(null, null, 0, null, null);
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_GenerateDartErrorsTaskTest_test_accept()));
//   }
//   void test_getException() {
//     GenerateDartErrorsTask task = new GenerateDartErrorsTask(null, null, 0, null, null);
//     JUnitTestCase.assertNull(task.exception);
//   }
//   void test_getLibraryElement() {
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     LibraryElement element = ElementFactory.library(context, "lib");
//     GenerateDartErrorsTask task = new GenerateDartErrorsTask(context, null, 0, null, element);
//     JUnitTestCase.assertSame(element, task.libraryElement);
//   }
//   void test_getSource() {
//     Source source = new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
//     GenerateDartErrorsTask task = new GenerateDartErrorsTask(null, source, 0, null, null);
//     JUnitTestCase.assertSame(source, task.source);
//   }
//   void test_perform() {
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     Source source = new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.addedSource(source);
//     context.applyChanges(changeSet);
//     context.setContents(source, EngineTestCase.createSource(["library lib;", "class A {", "  int f = new A();", "}"]));
//     LibraryElement libraryElement = context.computeLibraryElement(source);
//     CompilationUnit unit = context.getResolvedCompilationUnit(source, libraryElement);
//     GenerateDartErrorsTask task = new GenerateDartErrorsTask(context, source, context.getModificationStamp(source), unit, libraryElement);
//     task.perform(new TestTaskVisitor_GenerateDartErrorsTaskTest_test_perform(libraryElement, source));
//   }
//   void test_perform_validateDirectives() {
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     Source source = new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
//     ChangeSet changeSet = new ChangeSet();
//     changeSet.addedSource(source);
//     context.applyChanges(changeSet);
//     context.setContents(source, EngineTestCase.createSource([
//         "library lib;",
//         "import 'invaliduri^.dart';",
//         "export '\${a}lib3.dart';",
//         "part '/does/not/exist.dart';",
//         "class A {}"]));
//     LibraryElement libraryElement = context.computeLibraryElement(source);
//     CompilationUnit unit = context.getResolvedCompilationUnit(source, libraryElement);
//     GenerateDartErrorsTask task = new GenerateDartErrorsTask(context, source, context.getModificationStamp(source), unit, libraryElement);
//     task.perform(new TestTaskVisitor_GenerateDartErrorsTaskTest_test_perform_validateDirectives(libraryElement, source));
//   }
//   static dartSuite() {
//     _ut.group('GenerateDartErrorsTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new GenerateDartErrorsTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getException', () {
//         final __test = new GenerateDartErrorsTaskTest();
//         runJUnitTest(__test, __test.test_getException);
//       });
//       _ut.test('test_getLibraryElement', () {
//         final __test = new GenerateDartErrorsTaskTest();
//         runJUnitTest(__test, __test.test_getLibraryElement);
//       });
//       _ut.test('test_getSource', () {
//         final __test = new GenerateDartErrorsTaskTest();
//         runJUnitTest(__test, __test.test_getSource);
//       });
//       _ut.test('test_perform', () {
//         final __test = new GenerateDartErrorsTaskTest();
//         runJUnitTest(__test, __test.test_perform);
//       });
//       _ut.test('test_perform_validateDirectives', () {
//         final __test = new GenerateDartErrorsTaskTest();
//         runJUnitTest(__test, __test.test_perform_validateDirectives);
//       });
//     });
//   }
// }
// class GenerateDartHintsTaskTest extends EngineTestCase {
//   void test_accept() {
//     GenerateDartHintsTask task = new GenerateDartHintsTask(null, null, null);
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_GenerateDartHintsTaskTest_test_accept()));
//   }
//   void test_getException() {
//     GenerateDartHintsTask task = new GenerateDartHintsTask(null, null, null);
//     JUnitTestCase.assertNull(task.exception);
//   }
//   void test_getHintMap() {
//     GenerateDartHintsTask task = new GenerateDartHintsTask(null, null, null);
//     JUnitTestCase.assertNull(task.hintMap);
//   }
//   void test_getLibraryElement() {
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     LibraryElement element = ElementFactory.library(context, "lib");
//     GenerateDartHintsTask task = new GenerateDartHintsTask(context, null, element);
//     JUnitTestCase.assertSame(element, task.libraryElement);
//   }
//   void test_perform() {
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     ChangeSet changeSet = new ChangeSet();
//     Source librarySource = new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
//     changeSet.addedSource(librarySource);
//     Source unusedSource = new FileBasedSource.con1(FileUtilities2.createFile("/unused.dart"));
//     changeSet.addedSource(unusedSource);
//     Source partSource = new FileBasedSource.con1(FileUtilities2.createFile("/part.dart"));
//     changeSet.addedSource(partSource);
//     context.applyChanges(changeSet);
//     context.setContents(librarySource, EngineTestCase.createSource([
//         "library lib;",
//         "import 'unused.dart';",
//         "part 'part.dart';"]));
//     context.setContents(unusedSource, EngineTestCase.createSource(["library unused;"]));
//     context.setContents(partSource, EngineTestCase.createSource(["part of lib;"]));
//     List<TimestampedData<CompilationUnit>> units = new List<TimestampedData>(2);
//     units[0] = new TimestampedData<CompilationUnit>(context.getModificationStamp(librarySource), context.resolveCompilationUnit2(librarySource, librarySource));
//     units[1] = new TimestampedData<CompilationUnit>(context.getModificationStamp(partSource), context.resolveCompilationUnit2(partSource, librarySource));
//     GenerateDartHintsTask task = new GenerateDartHintsTask(context, units, context.computeLibraryElement(librarySource));
//     task.perform(new TestTaskVisitor_GenerateDartHintsTaskTest_test_perform(librarySource, partSource));
//   }
//   static dartSuite() {
//     _ut.group('GenerateDartHintsTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new GenerateDartHintsTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getException', () {
//         final __test = new GenerateDartHintsTaskTest();
//         runJUnitTest(__test, __test.test_getException);
//       });
//       _ut.test('test_getHintMap', () {
//         final __test = new GenerateDartHintsTaskTest();
//         runJUnitTest(__test, __test.test_getHintMap);
//       });
//       _ut.test('test_getLibraryElement', () {
//         final __test = new GenerateDartHintsTaskTest();
//         runJUnitTest(__test, __test.test_getLibraryElement);
//       });
//       _ut.test('test_perform', () {
//         final __test = new GenerateDartHintsTaskTest();
//         runJUnitTest(__test, __test.test_perform);
//       });
//     });
//   }
// }
// class GetContentTaskTest extends EngineTestCase {
//   void test_accept() {
//     Source source = new TestSource.con2("");
//     GetContentTask task = new GetContentTask(null, source);
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_GetContentTaskTest_test_accept()));
//   }
//   void test_getException() {
//     Source source = new TestSource.con2("");
//     GetContentTask task = new GetContentTask(null, source);
//     JUnitTestCase.assertNull(task.exception);
//   }
//   void test_getModificationTime() {
//     Source source = new TestSource.con2("");
//     GetContentTask task = new GetContentTask(null, source);
//     JUnitTestCase.assertEquals(-1, task.modificationTime);
//   }
//   void test_getSource() {
//     Source source = new TestSource.con2("");
//     GetContentTask task = new GetContentTask(null, source);
//     JUnitTestCase.assertSame(source, task.source);
//   }
//   void test_perform_exception() {
//     TestSource source = new TestSource();
//     source.generateExceptionOnRead = true;
//     //    final InternalAnalysisContext context = new AnalysisContextImpl();
//     //    context.setSourceFactory(new SourceFactory(new FileUriResolver()));
//     GetContentTask task = new GetContentTask(null, source);
//     task.perform(new TestTaskVisitor_GetContentTaskTest_test_perform_exception());
//   }
//   void test_perform_valid() {
//     String content = EngineTestCase.createSource(["class A {}"]);
//     Source source = new TestSource.con2(content);
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     GetContentTask task = new GetContentTask(context, source);
//     task.perform(new TestTaskVisitor_GetContentTaskTest_test_perform_valid(context, source));
//   }
//   static dartSuite() {
//     _ut.group('GetContentTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new GetContentTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getException', () {
//         final __test = new GetContentTaskTest();
//         runJUnitTest(__test, __test.test_getException);
//       });
//       _ut.test('test_getModificationTime', () {
//         final __test = new GetContentTaskTest();
//         runJUnitTest(__test, __test.test_getModificationTime);
//       });
//       _ut.test('test_getSource', () {
//         final __test = new GetContentTaskTest();
//         runJUnitTest(__test, __test.test_getSource);
//       });
//       _ut.test('test_perform_exception', () {
//         final __test = new GetContentTaskTest();
//         runJUnitTest(__test, __test.test_perform_exception);
//       });
//       _ut.test('test_perform_valid', () {
//         final __test = new GetContentTaskTest();
//         runJUnitTest(__test, __test.test_perform_valid);
//       });
//     });
//   }
// }
// class HtmlEntryImplTest extends EngineTestCase {
//   void test_creation() {
//     HtmlEntryImpl entry = new HtmlEntryImpl();
//     JUnitTestCase.assertNotNull(entry);
//   }
//   void test_getAllErrors() {
//     Source source = new TestSource();
//     HtmlEntryImpl entry = new HtmlEntryImpl();
//     EngineTestCase.assertLength(0, entry.allErrors);
//     entry.setValue(HtmlEntry.PARSE_ERRORS, <AnalysisError> [new AnalysisError.con1(source, ParserErrorCode.EXPECTED_TOKEN, [";"])]);
//     entry.setValue(HtmlEntry.RESOLUTION_ERRORS, <AnalysisError> [new AnalysisError.con1(source, HtmlWarningCode.INVALID_URI, ["-"])]);
//     entry.setValue(HtmlEntry.ANGULAR_ERRORS, <AnalysisError> [new AnalysisError.con1(source, AngularCode.INVALID_REPEAT_SYNTAX, ["-"])]);
//     entry.setValue(HtmlEntry.POLYMER_BUILD_ERRORS, <AnalysisError> [new AnalysisError.con1(source, PolymerCode.INVALID_ATTRIBUTE_NAME, ["-"])]);
//     entry.setValue(HtmlEntry.POLYMER_RESOLUTION_ERRORS, <AnalysisError> [new AnalysisError.con1(source, PolymerCode.INVALID_ATTRIBUTE_NAME, ["-"])]);
//     entry.setValue(HtmlEntry.HINTS, <AnalysisError> [new AnalysisError.con1(source, HintCode.DEAD_CODE, [])]);
//     EngineTestCase.assertLength(6, entry.allErrors);
//   }
//   void test_getWritableCopy() {
//     HtmlEntryImpl entry = new HtmlEntryImpl();
//     HtmlEntryImpl copy = entry.writableCopy;
//     JUnitTestCase.assertNotNull(copy);
//     JUnitTestCase.assertNotSame(entry, copy);
//   }
//   void test_invalidateAllResolutionInformation() {
//     HtmlEntryImpl entry = _entryWithValidState();
//     entry.invalidateAllResolutionInformation(false);
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.ANGULAR_APPLICATION));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.ANGULAR_COMPONENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.ANGULAR_ENTRY));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.ANGULAR_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.POLYMER_BUILD_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.POLYMER_RESOLUTION_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.HINTS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.REFERENCED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.RESOLUTION_ERRORS));
//   }
//   void test_invalidateAllResolutionInformation_includingUris() {
//     HtmlEntryImpl entry = _entryWithValidState();
//     entry.invalidateAllResolutionInformation(true);
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.ANGULAR_APPLICATION));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.ANGULAR_COMPONENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.ANGULAR_ENTRY));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.ANGULAR_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.POLYMER_BUILD_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.POLYMER_RESOLUTION_ERRORS));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.HINTS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.REFERENCED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.INVALID, entry.getState(HtmlEntry.RESOLUTION_ERRORS));
//   }
//   void test_setState_angularErrors() {
//     state = HtmlEntry.ANGULAR_ERRORS;
//   }
//   void test_setState_element() {
//     state = HtmlEntry.ELEMENT;
//   }
//   void test_setState_hints() {
//     state = HtmlEntry.HINTS;
//   }
//   void test_setState_lineInfo() {
//     state = SourceEntry.LINE_INFO;
//   }
//   void test_setState_parsedUnit() {
//     state = HtmlEntry.PARSED_UNIT;
//   }
//   void test_setState_parseErrors() {
//     state = HtmlEntry.PARSE_ERRORS;
//   }
//   void test_setState_polymerBuildErrors() {
//     state = HtmlEntry.POLYMER_BUILD_ERRORS;
//   }
//   void test_setState_polymerResolutionErrors() {
//     state = HtmlEntry.POLYMER_RESOLUTION_ERRORS;
//   }
//   void test_setState_referencedLibraries() {
//     state = HtmlEntry.REFERENCED_LIBRARIES;
//   }
//   void test_setState_resolutionErrors() {
//     state = HtmlEntry.RESOLUTION_ERRORS;
//   }
//   void test_setValue_angularErrors() {
//     _setValue(HtmlEntry.ANGULAR_ERRORS, <AnalysisError> [new AnalysisError.con1(null, AngularCode.INVALID_REPEAT_SYNTAX, ["-"])]);
//   }
//   void test_setValue_element() {
//     _setValue(HtmlEntry.ELEMENT, new HtmlElementImpl(null, "test.html"));
//   }
//   void test_setValue_hints() {
//     _setValue(HtmlEntry.HINTS, <AnalysisError> [new AnalysisError.con1(null, HintCode.DEAD_CODE, [])]);
//   }
//   void test_setValue_illegal() {
//     HtmlEntryImpl entry = new HtmlEntryImpl();
//     try {
//       entry.setValue(DartEntry.ELEMENT, null);
//       JUnitTestCase.fail("Expected IllegalArgumentException for DartEntry.ELEMENT");
//     } on IllegalArgumentException catch (exception) {
//     }
//   }
//   void test_setValue_lineInfo() {
//     _setValue(SourceEntry.LINE_INFO, new LineInfo(<int> [0]));
//   }
//   void test_setValue_parsedUnit() {
//     _setValue(HtmlEntry.PARSED_UNIT, new HtmlUnit(null, null, null));
//   }
//   void test_setValue_parseErrors() {
//     _setValue(HtmlEntry.PARSE_ERRORS, <AnalysisError> [new AnalysisError.con1(null, HtmlWarningCode.INVALID_URI, ["-"])]);
//   }
//   void test_setValue_polymerBuildErrors() {
//     _setValue(HtmlEntry.POLYMER_BUILD_ERRORS, <AnalysisError> [new AnalysisError.con1(null, PolymerCode.INVALID_ATTRIBUTE_NAME, ["-"])]);
//   }
//   void test_setValue_polymerResolutionErrors() {
//     _setValue(HtmlEntry.POLYMER_RESOLUTION_ERRORS, <AnalysisError> [new AnalysisError.con1(null, PolymerCode.INVALID_ATTRIBUTE_NAME, ["-"])]);
//   }
//   void test_setValue_referencedLibraries() {
//     _setValue(HtmlEntry.REFERENCED_LIBRARIES, <Source> [new TestSource()]);
//   }
//   void test_setValue_resolutionErrors() {
//     _setValue(HtmlEntry.RESOLUTION_ERRORS, <AnalysisError> [new AnalysisError.con1(null, HtmlWarningCode.INVALID_URI, ["-"])]);
//   }
//   HtmlEntryImpl _entryWithValidState() {
//     HtmlEntryImpl entry = new HtmlEntryImpl();
//     entry.setValue(HtmlEntry.ANGULAR_ERRORS, null);
//     entry.setValue(HtmlEntry.ELEMENT, null);
//     entry.setValue(HtmlEntry.HINTS, null);
//     entry.setValue(SourceEntry.LINE_INFO, null);
//     entry.setValue(HtmlEntry.PARSE_ERRORS, null);
//     entry.setValue(HtmlEntry.PARSED_UNIT, null);
//     entry.setValue(HtmlEntry.POLYMER_BUILD_ERRORS, null);
//     entry.setValue(HtmlEntry.POLYMER_RESOLUTION_ERRORS, null);
//     entry.setValue(HtmlEntry.REFERENCED_LIBRARIES, null);
//     entry.setValue(HtmlEntry.RESOLUTION_ERRORS, null);
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.ANGULAR_ERRORS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.ELEMENT));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.HINTS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(SourceEntry.LINE_INFO));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.PARSE_ERRORS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.PARSED_UNIT));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.POLYMER_BUILD_ERRORS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.POLYMER_RESOLUTION_ERRORS));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.REFERENCED_LIBRARIES));
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(HtmlEntry.RESOLUTION_ERRORS));
//     return entry;
//   }
//   void set state(DataDescriptor descriptor) {
//     HtmlEntryImpl entry = new HtmlEntryImpl();
//     JUnitTestCase.assertNotSame(CacheState.FLUSHED, entry.getState(descriptor));
//     entry.setState(descriptor, CacheState.FLUSHED);
//     JUnitTestCase.assertSame(CacheState.FLUSHED, entry.getState(descriptor));
//   }
//   void _setValue(DataDescriptor descriptor, Object newValue) {
//     HtmlEntryImpl entry = new HtmlEntryImpl();
//     Object value = entry.getValue(descriptor);
//     JUnitTestCase.assertNotSame(value, newValue);
//     entry.setValue(descriptor, newValue);
//     JUnitTestCase.assertSame(CacheState.VALID, entry.getState(descriptor));
//     JUnitTestCase.assertSame(newValue, entry.getValue(descriptor));
//   }
//   static dartSuite() {
//     _ut.group('HtmlEntryImplTest', () {
//       _ut.test('test_creation', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_getAllErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_getAllErrors);
//       });
//       _ut.test('test_getWritableCopy', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_getWritableCopy);
//       });
//       _ut.test('test_invalidateAllResolutionInformation', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_invalidateAllResolutionInformation);
//       });
//       _ut.test('test_invalidateAllResolutionInformation_includingUris', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_invalidateAllResolutionInformation_includingUris);
//       });
//       _ut.test('test_setState_angularErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_angularErrors);
//       });
//       _ut.test('test_setState_element', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_element);
//       });
//       _ut.test('test_setState_hints', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_hints);
//       });
//       _ut.test('test_setState_lineInfo', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_lineInfo);
//       });
//       _ut.test('test_setState_parseErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_parseErrors);
//       });
//       _ut.test('test_setState_parsedUnit', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_parsedUnit);
//       });
//       _ut.test('test_setState_polymerBuildErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_polymerBuildErrors);
//       });
//       _ut.test('test_setState_polymerResolutionErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_polymerResolutionErrors);
//       });
//       _ut.test('test_setState_referencedLibraries', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_referencedLibraries);
//       });
//       _ut.test('test_setState_resolutionErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setState_resolutionErrors);
//       });
//       _ut.test('test_setValue_angularErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_angularErrors);
//       });
//       _ut.test('test_setValue_element', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_element);
//       });
//       _ut.test('test_setValue_hints', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_hints);
//       });
//       _ut.test('test_setValue_illegal', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_illegal);
//       });
//       _ut.test('test_setValue_lineInfo', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_lineInfo);
//       });
//       _ut.test('test_setValue_parseErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_parseErrors);
//       });
//       _ut.test('test_setValue_parsedUnit', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_parsedUnit);
//       });
//       _ut.test('test_setValue_polymerBuildErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_polymerBuildErrors);
//       });
//       _ut.test('test_setValue_polymerResolutionErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_polymerResolutionErrors);
//       });
//       _ut.test('test_setValue_referencedLibraries', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_referencedLibraries);
//       });
//       _ut.test('test_setValue_resolutionErrors', () {
//         final __test = new HtmlEntryImplTest();
//         runJUnitTest(__test, __test.test_setValue_resolutionErrors);
//       });
//     });
//   }
// }
// class IncrementalAnalysisCacheTest extends JUnitTestCase {
//   Source _source = new TestSource();
//   DartEntryImpl _entry = new DartEntryImpl();
//   CompilationUnit _unit = mock(CompilationUnit);
//   IncrementalAnalysisCache _result;
//   void test_cacheResult() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     CompilationUnit newUnit = mock(CompilationUnit);
//     _result = IncrementalAnalysisCache.cacheResult(cache, newUnit);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(newUnit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("hbazlo", _result.oldContents);
//     JUnitTestCase.assertEquals("hbazlo", _result.newContents);
//     JUnitTestCase.assertEquals(0, _result.offset);
//     JUnitTestCase.assertEquals(0, _result.oldLength);
//     JUnitTestCase.assertEquals(0, _result.newLength);
//   }
//   void test_cacheResult_noCache() {
//     IncrementalAnalysisCache cache = null;
//     CompilationUnit newUnit = mock(CompilationUnit);
//     _result = IncrementalAnalysisCache.cacheResult(cache, newUnit);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_cacheResult_noCacheNoResult() {
//     IncrementalAnalysisCache cache = null;
//     CompilationUnit newUnit = null;
//     _result = IncrementalAnalysisCache.cacheResult(cache, newUnit);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_cacheResult_noResult() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     CompilationUnit newUnit = null;
//     _result = IncrementalAnalysisCache.cacheResult(cache, newUnit);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_clear_differentSource() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     Source otherSource = new TestSource.con1(new JavaFile("blat.dart"), "blat");
//     _result = IncrementalAnalysisCache.clear(cache, otherSource);
//     JUnitTestCase.assertSame(cache, _result);
//   }
//   void test_clear_nullCache() {
//     IncrementalAnalysisCache cache = null;
//     _result = IncrementalAnalysisCache.clear(cache, _source);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_clear_sameSource() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     _result = IncrementalAnalysisCache.clear(cache, _source);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_update_append() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     DartEntryImpl newEntry = new DartEntryImpl();
//     _result = IncrementalAnalysisCache.update(cache, _source, "hbazlo", "hbazxlo", 4, 0, 1, newEntry);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(_unit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("hello", _result.oldContents);
//     JUnitTestCase.assertEquals("hbazxlo", _result.newContents);
//     JUnitTestCase.assertEquals(1, _result.offset);
//     JUnitTestCase.assertEquals(2, _result.oldLength);
//     JUnitTestCase.assertEquals(4, _result.newLength);
//   }
//   void test_update_appendToCachedResult() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     CompilationUnit newUnit = mock(CompilationUnit);
//     cache = IncrementalAnalysisCache.cacheResult(cache, newUnit);
//     JUnitTestCase.assertNotNull(cache);
//     DartEntryImpl newEntry = new DartEntryImpl();
//     _result = IncrementalAnalysisCache.update(cache, _source, "hbazlo", "hbazxlo", 4, 0, 1, newEntry);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(newUnit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("hbazlo", _result.oldContents);
//     JUnitTestCase.assertEquals("hbazxlo", _result.newContents);
//     JUnitTestCase.assertEquals(4, _result.offset);
//     JUnitTestCase.assertEquals(0, _result.oldLength);
//     JUnitTestCase.assertEquals(1, _result.newLength);
//   }
//   void test_update_appendWithNewResolvedUnit() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     DartEntryImpl newEntry = new DartEntryImpl();
//     CompilationUnit newUnit = mock(CompilationUnit);
//     newEntry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, newUnit);
//     _result = IncrementalAnalysisCache.update(cache, _source, "hbazlo", "hbazxlo", 4, 0, 1, newEntry);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(newUnit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("hbazlo", _result.oldContents);
//     JUnitTestCase.assertEquals("hbazxlo", _result.newContents);
//     JUnitTestCase.assertEquals(4, _result.offset);
//     JUnitTestCase.assertEquals(0, _result.oldLength);
//     JUnitTestCase.assertEquals(1, _result.newLength);
//   }
//   void test_update_appendWithNoNewResolvedUnit() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     DartEntryImpl newEntry = new DartEntryImpl();
//     _result = IncrementalAnalysisCache.update(cache, _source, "hbazlo", "hbazxlo", 4, 0, 1, newEntry);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(_unit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("hello", _result.oldContents);
//     JUnitTestCase.assertEquals("hbazxlo", _result.newContents);
//     JUnitTestCase.assertEquals(1, _result.offset);
//     JUnitTestCase.assertEquals(2, _result.oldLength);
//     JUnitTestCase.assertEquals(4, _result.newLength);
//   }
//   void test_update_delete() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     DartEntryImpl newEntry = new DartEntryImpl();
//     _result = IncrementalAnalysisCache.update(cache, _source, "hbazlo", "hzlo", 1, 2, 0, newEntry);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(_unit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("hello", _result.oldContents);
//     JUnitTestCase.assertEquals("hzlo", _result.newContents);
//     JUnitTestCase.assertEquals(1, _result.offset);
//     JUnitTestCase.assertEquals(2, _result.oldLength);
//     JUnitTestCase.assertEquals(1, _result.newLength);
//   }
//   void test_update_insert_nonContiguous_after() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     DartEntryImpl newEntry = new DartEntryImpl();
//     _result = IncrementalAnalysisCache.update(cache, _source, "hbazlo", "hbazlox", 6, 0, 1, newEntry);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_update_insert_nonContiguous_before() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     DartEntryImpl newEntry = new DartEntryImpl();
//     _result = IncrementalAnalysisCache.update(cache, _source, "hbazlo", "xhbazlo", 0, 0, 1, newEntry);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_update_newSource_entry() {
//     Source oldSource = new TestSource.con1(new JavaFile("blat.dart"), "blat");
//     DartEntryImpl oldEntry = new DartEntryImpl();
//     CompilationUnit oldUnit = mock(CompilationUnit);
//     oldEntry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, oldUnit);
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, oldSource, "hello", "hbazlo", 1, 2, 3, oldEntry);
//     JUnitTestCase.assertSame(oldSource, cache.source);
//     JUnitTestCase.assertSame(oldUnit, cache.resolvedUnit);
//     _result = IncrementalAnalysisCache.update(cache, _source, "foo", "foobz", 3, 0, 2, _entry);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(_unit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("foo", _result.oldContents);
//     JUnitTestCase.assertEquals("foobz", _result.newContents);
//     JUnitTestCase.assertEquals(3, _result.offset);
//     JUnitTestCase.assertEquals(0, _result.oldLength);
//     JUnitTestCase.assertEquals(2, _result.newLength);
//   }
//   void test_update_newSource_noEntry() {
//     Source oldSource = new TestSource.con1(new JavaFile("blat.dart"), "blat");
//     DartEntryImpl oldEntry = new DartEntryImpl();
//     CompilationUnit oldUnit = mock(CompilationUnit);
//     oldEntry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, oldUnit);
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, oldSource, "hello", "hbazlo", 1, 2, 3, oldEntry);
//     JUnitTestCase.assertSame(oldSource, cache.source);
//     JUnitTestCase.assertSame(oldUnit, cache.resolvedUnit);
//     _result = IncrementalAnalysisCache.update(cache, _source, "foo", "foobar", 3, 0, 3, null);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_update_noCache_entry() {
//     _result = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(_unit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("hello", _result.oldContents);
//     JUnitTestCase.assertEquals("hbazlo", _result.newContents);
//     JUnitTestCase.assertEquals(1, _result.offset);
//     JUnitTestCase.assertEquals(2, _result.oldLength);
//     JUnitTestCase.assertEquals(3, _result.newLength);
//     JUnitTestCase.assertTrue(_result.hasWork);
//   }
//   void test_update_noCache_entry_noOldSource_append() {
//     _result = IncrementalAnalysisCache.update(null, _source, null, "hellxo", 4, 0, 1, _entry);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(_unit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("hello", _result.oldContents);
//     JUnitTestCase.assertEquals("hellxo", _result.newContents);
//     JUnitTestCase.assertEquals(4, _result.offset);
//     JUnitTestCase.assertEquals(0, _result.oldLength);
//     JUnitTestCase.assertEquals(1, _result.newLength);
//     JUnitTestCase.assertTrue(_result.hasWork);
//   }
//   void test_update_noCache_entry_noOldSource_delete() {
//     _result = IncrementalAnalysisCache.update(null, _source, null, "helo", 4, 1, 0, _entry);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_update_noCache_entry_noOldSource_replace() {
//     _result = IncrementalAnalysisCache.update(null, _source, null, "helxo", 4, 1, 1, _entry);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_update_noCache_noEntry() {
//     _result = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, null);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_update_replace() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     _result = IncrementalAnalysisCache.update(cache, _source, "hbazlo", "hbarrlo", 3, 1, 2, null);
//     JUnitTestCase.assertNotNull(_result);
//     JUnitTestCase.assertSame(_source, _result.source);
//     JUnitTestCase.assertSame(_unit, _result.resolvedUnit);
//     JUnitTestCase.assertEquals("hello", _result.oldContents);
//     JUnitTestCase.assertEquals("hbarrlo", _result.newContents);
//     JUnitTestCase.assertEquals(1, _result.offset);
//     JUnitTestCase.assertEquals(2, _result.oldLength);
//     JUnitTestCase.assertEquals(4, _result.newLength);
//   }
//   void test_verifyStructure_invalidUnit() {
//     String oldCode = "main() {foo;}";
//     String newCode = "main() {boo;}";
//     CompilationUnit badUnit = _parse("main() {bad;}");
//     _entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, badUnit);
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, oldCode, newCode, 8, 1, 1, _entry);
//     CompilationUnit newUnit = _parse(newCode);
//     _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_verifyStructure_noCache() {
//     IncrementalAnalysisCache cache = null;
//     CompilationUnit newUnit = mock(CompilationUnit);
//     _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_verifyStructure_noCacheNoUnit() {
//     IncrementalAnalysisCache cache = null;
//     CompilationUnit newUnit = null;
//     _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
//     JUnitTestCase.assertNull(_result);
//   }
//   void test_verifyStructure_noUnit() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     CompilationUnit newUnit = null;
//     _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
//     JUnitTestCase.assertSame(cache, _result);
//     JUnitTestCase.assertSame(_unit, _result.resolvedUnit);
//   }
//   void test_verifyStructure_otherSource() {
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, "hello", "hbazlo", 1, 2, 3, _entry);
//     CompilationUnit newUnit = mock(CompilationUnit);
//     Source otherSource = new TestSource.con1(new JavaFile("blat.dart"), "blat");
//     _result = IncrementalAnalysisCache.verifyStructure(cache, otherSource, newUnit);
//     JUnitTestCase.assertSame(cache, _result);
//     JUnitTestCase.assertSame(_unit, _result.resolvedUnit);
//   }
//   void test_verifyStructure_validUnit() {
//     String oldCode = "main() {foo;}";
//     String newCode = "main() {boo;}";
//     CompilationUnit goodUnit = _parse(newCode);
//     _entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, goodUnit);
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, _source, oldCode, newCode, 1, 2, 3, _entry);
//     CompilationUnit newUnit = _parse(newCode);
//     _result = IncrementalAnalysisCache.verifyStructure(cache, _source, newUnit);
//     JUnitTestCase.assertSame(cache, _result);
//     JUnitTestCase.assertSame(goodUnit, _result.resolvedUnit);
//   }
//   @override
//   void setUp() {
//     _entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, _source, _unit);
//   }
//   CompilationUnit _parse(String code) {
//     Scanner scanner = new Scanner(_source, new CharSequenceReader(code), AnalysisErrorListener.NULL_LISTENER);
//     Parser parser = new Parser(_source, AnalysisErrorListener.NULL_LISTENER);
//     return parser.parseCompilationUnit(scanner.tokenize());
//   }
//   static dartSuite() {
//     _ut.group('IncrementalAnalysisCacheTest', () {
//       _ut.test('test_cacheResult', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_cacheResult);
//       });
//       _ut.test('test_cacheResult_noCache', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_cacheResult_noCache);
//       });
//       _ut.test('test_cacheResult_noCacheNoResult', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_cacheResult_noCacheNoResult);
//       });
//       _ut.test('test_cacheResult_noResult', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_cacheResult_noResult);
//       });
//       _ut.test('test_clear_differentSource', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_clear_differentSource);
//       });
//       _ut.test('test_clear_nullCache', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_clear_nullCache);
//       });
//       _ut.test('test_clear_sameSource', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_clear_sameSource);
//       });
//       _ut.test('test_update_append', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_append);
//       });
//       _ut.test('test_update_appendToCachedResult', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_appendToCachedResult);
//       });
//       _ut.test('test_update_appendWithNewResolvedUnit', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_appendWithNewResolvedUnit);
//       });
//       _ut.test('test_update_appendWithNoNewResolvedUnit', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_appendWithNoNewResolvedUnit);
//       });
//       _ut.test('test_update_delete', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_delete);
//       });
//       _ut.test('test_update_insert_nonContiguous_after', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_insert_nonContiguous_after);
//       });
//       _ut.test('test_update_insert_nonContiguous_before', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_insert_nonContiguous_before);
//       });
//       _ut.test('test_update_newSource_entry', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_newSource_entry);
//       });
//       _ut.test('test_update_newSource_noEntry', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_newSource_noEntry);
//       });
//       _ut.test('test_update_noCache_entry', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_noCache_entry);
//       });
//       _ut.test('test_update_noCache_entry_noOldSource_append', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_noCache_entry_noOldSource_append);
//       });
//       _ut.test('test_update_noCache_entry_noOldSource_delete', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_noCache_entry_noOldSource_delete);
//       });
//       _ut.test('test_update_noCache_entry_noOldSource_replace', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_noCache_entry_noOldSource_replace);
//       });
//       _ut.test('test_update_noCache_noEntry', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_noCache_noEntry);
//       });
//       _ut.test('test_update_replace', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_update_replace);
//       });
//       _ut.test('test_verifyStructure_invalidUnit', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_verifyStructure_invalidUnit);
//       });
//       _ut.test('test_verifyStructure_noCache', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_verifyStructure_noCache);
//       });
//       _ut.test('test_verifyStructure_noCacheNoUnit', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_verifyStructure_noCacheNoUnit);
//       });
//       _ut.test('test_verifyStructure_noUnit', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_verifyStructure_noUnit);
//       });
//       _ut.test('test_verifyStructure_otherSource', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_verifyStructure_otherSource);
//       });
//       _ut.test('test_verifyStructure_validUnit', () {
//         final __test = new IncrementalAnalysisCacheTest();
//         runJUnitTest(__test, __test.test_verifyStructure_validUnit);
//       });
//     });
//   }
// }
// class IncrementalAnalysisTaskTest extends EngineTestCase {
//   void test_accept() {
//     IncrementalAnalysisTask task = new IncrementalAnalysisTask(null, null);
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_IncrementalAnalysisTaskTest_test_accept()));
//   }
//   void test_perform() {
//     // main() {} String foo;
//     // main() {String} String foo;
//     CompilationUnit newUnit = _assertTask("main() {", "", "String", "} String foo;");
//     NodeList<CompilationUnitMember> declarations = newUnit.declarations;
//     FunctionDeclaration main = declarations[0] as FunctionDeclaration;
//     JUnitTestCase.assertEquals("main", main.name.name);
//     BlockFunctionBody body = main.functionExpression.body as BlockFunctionBody;
//     ExpressionStatement statement = body.block.statements[0] as ExpressionStatement;
//     JUnitTestCase.assertEquals("String;", statement.toSource());
//     SimpleIdentifier identifier = statement.expression as SimpleIdentifier;
//     JUnitTestCase.assertEquals("String", identifier.name);
//     JUnitTestCase.assertNotNull(identifier.staticElement);
//     TopLevelVariableDeclaration fooDecl = declarations[1] as TopLevelVariableDeclaration;
//     SimpleIdentifier fooName = fooDecl.variables.variables[0].name;
//     JUnitTestCase.assertEquals("foo", fooName.name);
//     JUnitTestCase.assertNotNull(fooName.staticElement);
//   }
//   CompilationUnit _assertTask(String prefix, String removed, String added, String suffix) {
//     String oldCode = EngineTestCase.createSource(["${prefix}${removed}${suffix}"]);
//     String newCode = EngineTestCase.createSource(["${prefix}${added}${suffix}"]);
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     Source source = new TestSource.con1(new JavaFile("/test.dart"), oldCode);
//     DartEntryImpl entry = new DartEntryImpl();
//     CompilationUnit oldUnit = context.resolveCompilationUnit2(source, source);
//     JUnitTestCase.assertNotNull(oldUnit);
//     entry.setValueInLibrary(DartEntry.RESOLVED_UNIT, source, oldUnit);
//     IncrementalAnalysisCache cache = IncrementalAnalysisCache.update(null, source, oldCode, newCode, prefix.length, removed.length, added.length, entry);
//     JUnitTestCase.assertNotNull(cache);
//     IncrementalAnalysisTask task = new IncrementalAnalysisTask(context, cache);
//     CompilationUnit newUnit = task.perform(new TestTaskVisitor_IncrementalAnalysisTaskTest_assertTask(task));
//     JUnitTestCase.assertNotNull(newUnit);
//     return newUnit;
//   }
//   static dartSuite() {
//     _ut.group('IncrementalAnalysisTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new IncrementalAnalysisTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_perform', () {
//         final __test = new IncrementalAnalysisTaskTest();
//         runJUnitTest(__test, __test.test_perform);
//       });
//     });
//   }
// }
// class InstrumentedAnalysisContextImplTest extends EngineTestCase {
//   void test_addSourceInfo() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_addSourceInfo(invoked));
//     context.addSourceInfo(null, null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_applyChanges() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_applyChanges(invoked));
//     context.applyChanges(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_computeDocumentationComment() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeDocumentationComment(invoked));
//     context.computeDocumentationComment(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_computeErrors() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeErrors(invoked));
//     context.computeErrors(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_computeExportedLibraries() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeExportedLibraries(invoked));
//     context.computeExportedLibraries(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_computeHtmlElement() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeHtmlElement(invoked));
//     context.computeHtmlElement(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_computeImportedLibraries() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeImportedLibraries(invoked));
//     context.computeImportedLibraries(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_computeKindOf() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeKindOf(invoked));
//     context.computeKindOf(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_computeLibraryElement() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeLibraryElement(invoked));
//     context.computeLibraryElement(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_computeLineInfo() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeLineInfo(invoked));
//     context.computeLineInfo(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_computeResolvableCompilationUnit() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeResolvableCompilationUnit(invoked));
//     context.computeResolvableCompilationUnit(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_creation() {
//     JUnitTestCase.assertNotNull(new InstrumentedAnalysisContextImpl());
//   }
//   void test_dispose() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_dispose(invoked));
//     context.dispose();
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_exists() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_exists(invoked));
//     context.exists(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_extractContext() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_extractContext(invoked));
//     context.extractContext(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_extractContextInto() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_extractContextInto(invoked));
//     context.extractContextInto(null, null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getAnalysisOptions() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getAnalysisOptions(invoked));
//     context.analysisOptions;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getAngularApplicationWithHtml() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getAngularApplicationWithHtml(invoked));
//     context.getAngularApplicationWithHtml(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getCompilationUnitElement() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getCompilationUnitElement(invoked));
//     context.getCompilationUnitElement(null, null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getContents() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getContents(invoked));
//     context.getContents(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getContentsToReceiver() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getContentsToReceiver(invoked));
//     context.getContentsToReceiver(null, null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getElement() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getElement(invoked));
//     context.getElement(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getErrors() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getErrors(invoked));
//     context.getErrors(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getHtmlElement() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getHtmlElement(invoked));
//     context.getHtmlElement(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getHtmlFilesReferencing() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getHtmlFilesReferencing(invoked));
//     context.getHtmlFilesReferencing(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getHtmlSources() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getHtmlSources(invoked));
//     context.htmlSources;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getKindOf() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getKindOf(invoked));
//     context.getKindOf(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getLaunchableClientLibrarySources() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLaunchableClientLibrarySources(invoked));
//     context.launchableClientLibrarySources;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getLaunchableServerLibrarySources() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLaunchableServerLibrarySources(invoked));
//     context.launchableServerLibrarySources;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getLibrariesContaining() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrariesContaining(invoked));
//     context.getLibrariesContaining(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getLibrariesDependingOn() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrariesDependingOn(invoked));
//     context.getLibrariesDependingOn(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getLibrariesReferencedFromHtml() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrariesReferencedFromHtml(invoked));
//     context.getLibrariesReferencedFromHtml(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getLibraryElement() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibraryElement(invoked));
//     context.getLibraryElement(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getLibrarySources() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrarySources(invoked));
//     context.librarySources;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getLineInfo() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLineInfo(invoked));
//     context.getLineInfo(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getModificationStamp() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getModificationStamp(invoked));
//     context.getModificationStamp(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getPublicNamespace() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getPublicNamespace(invoked));
//     context.getPublicNamespace(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getRefactoringUnsafeSources() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getRefactoringUnsafeSources(invoked));
//     context.refactoringUnsafeSources;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getResolvedCompilationUnit_element() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getResolvedCompilationUnit_element(invoked));
//     context.getResolvedCompilationUnit(null, null as LibraryElement);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getResolvedCompilationUnit_source() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getResolvedCompilationUnit_source(invoked));
//     context.getResolvedCompilationUnit2(null, null as Source);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getResolvedHtmlUnit() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getResolvedHtmlUnit(invoked));
//     context.getResolvedHtmlUnit(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getSourceFactory() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getSourceFactory(invoked));
//     context.sourceFactory;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getStatistics() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getStatistics(invoked));
//     context.statistics;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_getTypeProvider() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getTypeProvider(invoked));
//     context.typeProvider;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_isClientLibrary() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_isClientLibrary(invoked));
//     context.isClientLibrary(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_isDisposed() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_isDisposed(invoked));
//     context.isDisposed;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_isServerLibrary() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_isServerLibrary(invoked));
//     context.isServerLibrary(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_mergeContext() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_mergeContext(invoked));
//     context.mergeContext(new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext()));
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_parseCompilationUnit() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_parseCompilationUnit(invoked));
//     context.parseCompilationUnit(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_parseHtmlUnit() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_parseHtmlUnit(invoked));
//     context.parseHtmlUnit(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_performAnalysisTask() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_performAnalysisTask(invoked));
//     context.performAnalysisTask();
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_recordLibraryElements() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_recordLibraryElements(invoked));
//     context.recordLibraryElements(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_resolveCompilationUnit() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_resolveCompilationUnit(invoked));
//     context.resolveCompilationUnit2(null, null as Source);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_resolveCompilationUnit_element() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_resolveCompilationUnit_element(invoked));
//     context.resolveCompilationUnit(null, null as LibraryElement);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_resolveHtmlUnit() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_resolveHtmlUnit(invoked));
//     context.resolveHtmlUnit(null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_setAnalysisOptions() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setAnalysisOptions(invoked));
//     context.analysisOptions = null;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_setAnalysisPriorityOrder() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setAnalysisPriorityOrder(invoked));
//     context.analysisPriorityOrder = null;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_setChangedContents() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setChangedContents(invoked));
//     context.setChangedContents(null, null, 0, 0, 0);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_setContents() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setContents(invoked));
//     context.setContents(null, null);
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   void test_setSourceFactory() {
//     List<bool> invoked = [false];
//     InstrumentedAnalysisContextImpl context = new InstrumentedAnalysisContextImpl.con1(new TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setSourceFactory(invoked));
//     context.sourceFactory = null;
//     JUnitTestCase.assertTrue(invoked[0]);
//   }
//   static dartSuite() {
//     _ut.group('InstrumentedAnalysisContextImplTest', () {
//       _ut.test('test_addSourceInfo', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_addSourceInfo);
//       });
//       _ut.test('test_applyChanges', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_applyChanges);
//       });
//       _ut.test('test_computeDocumentationComment', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeDocumentationComment);
//       });
//       _ut.test('test_computeErrors', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeErrors);
//       });
//       _ut.test('test_computeExportedLibraries', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeExportedLibraries);
//       });
//       _ut.test('test_computeHtmlElement', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeHtmlElement);
//       });
//       _ut.test('test_computeImportedLibraries', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeImportedLibraries);
//       });
//       _ut.test('test_computeKindOf', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeKindOf);
//       });
//       _ut.test('test_computeLibraryElement', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeLibraryElement);
//       });
//       _ut.test('test_computeLineInfo', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeLineInfo);
//       });
//       _ut.test('test_computeResolvableCompilationUnit', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_computeResolvableCompilationUnit);
//       });
//       _ut.test('test_creation', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_dispose', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_dispose);
//       });
//       _ut.test('test_exists', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_exists);
//       });
//       _ut.test('test_extractContext', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_extractContext);
//       });
//       _ut.test('test_extractContextInto', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_extractContextInto);
//       });
//       _ut.test('test_getAnalysisOptions', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getAnalysisOptions);
//       });
//       _ut.test('test_getAngularApplicationWithHtml', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getAngularApplicationWithHtml);
//       });
//       _ut.test('test_getCompilationUnitElement', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getCompilationUnitElement);
//       });
//       _ut.test('test_getContents', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getContents);
//       });
//       _ut.test('test_getContentsToReceiver', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getContentsToReceiver);
//       });
//       _ut.test('test_getElement', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getElement);
//       });
//       _ut.test('test_getErrors', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getErrors);
//       });
//       _ut.test('test_getHtmlElement', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getHtmlElement);
//       });
//       _ut.test('test_getHtmlFilesReferencing', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getHtmlFilesReferencing);
//       });
//       _ut.test('test_getHtmlSources', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getHtmlSources);
//       });
//       _ut.test('test_getKindOf', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getKindOf);
//       });
//       _ut.test('test_getLaunchableClientLibrarySources', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLaunchableClientLibrarySources);
//       });
//       _ut.test('test_getLaunchableServerLibrarySources', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLaunchableServerLibrarySources);
//       });
//       _ut.test('test_getLibrariesContaining', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibrariesContaining);
//       });
//       _ut.test('test_getLibrariesDependingOn', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibrariesDependingOn);
//       });
//       _ut.test('test_getLibrariesReferencedFromHtml', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibrariesReferencedFromHtml);
//       });
//       _ut.test('test_getLibraryElement', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibraryElement);
//       });
//       _ut.test('test_getLibrarySources', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLibrarySources);
//       });
//       _ut.test('test_getLineInfo', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getLineInfo);
//       });
//       _ut.test('test_getModificationStamp', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getModificationStamp);
//       });
//       _ut.test('test_getPublicNamespace', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getPublicNamespace);
//       });
//       _ut.test('test_getRefactoringUnsafeSources', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getRefactoringUnsafeSources);
//       });
//       _ut.test('test_getResolvedCompilationUnit_element', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getResolvedCompilationUnit_element);
//       });
//       _ut.test('test_getResolvedCompilationUnit_source', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getResolvedCompilationUnit_source);
//       });
//       _ut.test('test_getResolvedHtmlUnit', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getResolvedHtmlUnit);
//       });
//       _ut.test('test_getSourceFactory', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getSourceFactory);
//       });
//       _ut.test('test_getStatistics', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getStatistics);
//       });
//       _ut.test('test_getTypeProvider', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_getTypeProvider);
//       });
//       _ut.test('test_isClientLibrary', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_isClientLibrary);
//       });
//       _ut.test('test_isDisposed', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_isDisposed);
//       });
//       _ut.test('test_isServerLibrary', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_isServerLibrary);
//       });
//       _ut.test('test_mergeContext', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_mergeContext);
//       });
//       _ut.test('test_parseCompilationUnit', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_parseCompilationUnit);
//       });
//       _ut.test('test_parseHtmlUnit', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_parseHtmlUnit);
//       });
//       _ut.test('test_performAnalysisTask', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_performAnalysisTask);
//       });
//       _ut.test('test_recordLibraryElements', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_recordLibraryElements);
//       });
//       _ut.test('test_resolveCompilationUnit', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_resolveCompilationUnit);
//       });
//       _ut.test('test_resolveCompilationUnit_element', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_resolveCompilationUnit_element);
//       });
//       _ut.test('test_resolveHtmlUnit', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_resolveHtmlUnit);
//       });
//       _ut.test('test_setAnalysisOptions', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setAnalysisOptions);
//       });
//       _ut.test('test_setAnalysisPriorityOrder', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setAnalysisPriorityOrder);
//       });
//       _ut.test('test_setChangedContents', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setChangedContents);
//       });
//       _ut.test('test_setContents', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setContents);
//       });
//       _ut.test('test_setSourceFactory', () {
//         final __test = new InstrumentedAnalysisContextImplTest();
//         runJUnitTest(__test, __test.test_setSourceFactory);
//       });
//     });
//   }
// }
// class ParseDartTaskTest extends EngineTestCase {
//   void test_accept() {
//     ParseDartTask task = new ParseDartTask(null, null, 0, null, null);
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_ParseDartTaskTest_test_accept()));
//   }
//   void test_getCompilationUnit() {
//     ParseDartTask task = new ParseDartTask(null, null, 0, null, null);
//     JUnitTestCase.assertNull(task.compilationUnit);
//   }
//   void test_getErrors() {
//     ParseDartTask task = new ParseDartTask(null, null, 0, null, null);
//     EngineTestCase.assertLength(0, task.errors);
//   }
//   void test_getException() {
//     ParseDartTask task = new ParseDartTask(null, null, 0, null, null);
//     JUnitTestCase.assertNull(task.exception);
//   }
//   void test_getModificationTime() {
//     int modificationTime = 26;
//     ParseDartTask task = new ParseDartTask(null, null, modificationTime, null, null);
//     JUnitTestCase.assertEquals(modificationTime, task.modificationTime);
//   }
//   void test_getSource() {
//     Source source = new TestSource.con2("");
//     ParseDartTask task = new ParseDartTask(null, source, 0, null, null);
//     JUnitTestCase.assertSame(source, task.source);
//   }
//   void test_hasNonPartOfDirective() {
//     ParseDartTask task = new ParseDartTask(null, null, 0, null, null);
//     JUnitTestCase.assertFalse(task.hasNonPartOfDirective);
//   }
//   void test_hasPartOfDirective() {
//     ParseDartTask task = new ParseDartTask(null, null, 0, null, null);
//     JUnitTestCase.assertFalse(task.hasPartOfDirective);
//   }
//   void test_perform_exception() {
//     TestSource source = new TestSource();
//     source.generateExceptionOnRead = true;
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     ParseDartTask task = new ParseDartTask(context, source, 0, null, null);
//     task.perform(new TestTaskVisitor_ParseDartTaskTest_test_perform_exception());
//   }
//   void test_perform_library() {
//     String content = EngineTestCase.createSource([
//         "library lib;",
//         "import 'lib2.dart';",
//         "export 'lib3.dart';",
//         "part 'part.dart';",
//         "class A {"]);
//     Source source = new TestSource.con2(content);
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     ParseDartTask task = _createParseTask(context, source, content);
//     task.perform(new TestTaskVisitor_ParseDartTaskTest_test_perform_library(context, source));
//   }
//   void test_perform_part() {
//     String content = EngineTestCase.createSource(["part of lib;", "class B {}"]);
//     Source source = new TestSource.con2(content);
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     ParseDartTask task = _createParseTask(context, source, content);
//     task.perform(new TestTaskVisitor_ParseDartTaskTest_test_perform_part(context, source));
//   }
//   void test_perform_validateDirectives() {
//     String content = EngineTestCase.createSource([
//         "library lib;",
//         "import '/does/not/exist.dart';",
//         "import 'invaliduri^.dart';",
//         "export '\${a}lib3.dart';",
//         "part 'part.dart';",
//         "class A {}"]);
//     Source source = new TestSource.con2(content);
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     ParseDartTask task = _createParseTask(context, source, content);
//     task.perform(new TestTaskVisitor_ParseDartTaskTest_test_perform_validateDirectives(context, source));
//   }
//   /**
//    * Create and return a task that will parse the given content from the given source in the given
//    * context.
//    *
//    * @param context the context to be passed to the task
//    * @param source the source to be parsed
//    * @param content the content of the source to be parsed
//    * @return the task that was created
//    * @throws AnalysisException if the task could not be created
//    */
//   ParseDartTask _createParseTask(InternalAnalysisContext context, Source source, String content) {
//     ScanDartTask scanTask = new ScanDartTask(context, source, context.getModificationStamp(source), content);
//     scanTask.perform(new TestTaskVisitor_ParseDartTaskTest_createParseTask());
//     return new ParseDartTask(context, source, scanTask.modificationTime, scanTask.tokenStream, scanTask.lineInfo);
//   }
//   static dartSuite() {
//     _ut.group('ParseDartTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getCompilationUnit', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_getCompilationUnit);
//       });
//       _ut.test('test_getErrors', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_getErrors);
//       });
//       _ut.test('test_getException', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_getException);
//       });
//       _ut.test('test_getModificationTime', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_getModificationTime);
//       });
//       _ut.test('test_getSource', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_getSource);
//       });
//       _ut.test('test_hasNonPartOfDirective', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_hasNonPartOfDirective);
//       });
//       _ut.test('test_hasPartOfDirective', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_hasPartOfDirective);
//       });
//       _ut.test('test_perform_exception', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_perform_exception);
//       });
//       _ut.test('test_perform_library', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_perform_library);
//       });
//       _ut.test('test_perform_part', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_perform_part);
//       });
//       _ut.test('test_perform_validateDirectives', () {
//         final __test = new ParseDartTaskTest();
//         runJUnitTest(__test, __test.test_perform_validateDirectives);
//       });
//     });
//   }
// }
// class ParseHtmlTaskTest extends EngineTestCase {
//   void test_accept() {
//     ParseHtmlTask task = new ParseHtmlTask(null, null, 0, "");
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_ParseHtmlTaskTest_test_accept()));
//   }
//   void test_getException() {
//     ParseHtmlTask task = new ParseHtmlTask(null, null, 0, "");
//     JUnitTestCase.assertNull(task.exception);
//   }
//   void test_getHtmlUnit() {
//     ParseHtmlTask task = new ParseHtmlTask(null, null, 0, "");
//     JUnitTestCase.assertNull(task.htmlUnit);
//   }
//   void test_getLineInfo() {
//     ParseHtmlTask task = new ParseHtmlTask(null, null, 0, "");
//     JUnitTestCase.assertNull(task.lineInfo);
//   }
//   void test_getReferencedLibraries() {
//     ParseHtmlTask task = new ParseHtmlTask(null, null, 0, "");
//     EngineTestCase.assertLength(0, task.referencedLibraries);
//   }
//   void test_getSource() {
//     Source source = new TestSource.con2("");
//     ParseHtmlTask task = new ParseHtmlTask(null, source, 0, "");
//     JUnitTestCase.assertSame(source, task.source);
//   }
//   void test_perform_embedded_source() {
//     String contents = EngineTestCase.createSource([
//         "<html>",
//         "<head>",
//         "  <script type='application/dart'>",
//         "    void buttonPressed() {}",
//         "  </script>",
//         "</head>",
//         "<body>",
//         "</body>",
//         "</html>"]);
//     TestLogger testLogger = new TestLogger();
//     ParseHtmlTask task = parseContents(contents, testLogger);
//     EngineTestCase.assertLength(0, task.referencedLibraries);
//     JUnitTestCase.assertEquals(0, testLogger.getErrorCount());
//     JUnitTestCase.assertEquals(0, testLogger.getInfoCount());
//   }
//   void test_perform_empty_source_reference() {
//     String contents = EngineTestCase.createSource([
//         "<html>",
//         "<head>",
//         "  <script type='application/dart' src=''/>",
//         "</head>",
//         "<body>",
//         "</body>",
//         "</html>"]);
//     TestLogger testLogger = new TestLogger();
//     ParseHtmlTask task = parseContents(contents, testLogger);
//     EngineTestCase.assertLength(0, task.referencedLibraries);
//     JUnitTestCase.assertEquals(0, testLogger.getErrorCount());
//     JUnitTestCase.assertEquals(0, testLogger.getInfoCount());
//   }
//   void test_perform_invalid_source_reference() {
//     String contents = EngineTestCase.createSource([
//         "<html>",
//         "<head>",
//         "  <script type='application/dart' src='an;invalid:[]uri'/>",
//         "</head>",
//         "<body>",
//         "</body>",
//         "</html>"]);
//     TestLogger testLogger = new TestLogger();
//     ParseHtmlTask task = parseContents(contents, testLogger);
//     EngineTestCase.assertLength(0, task.referencedLibraries);
//     JUnitTestCase.assertEquals(0, testLogger.getErrorCount());
//     JUnitTestCase.assertEquals(0, testLogger.getInfoCount());
//   }
//   void test_perform_non_existing_source_reference() {
//     String contents = EngineTestCase.createSource([
//         "<html>",
//         "<head>",
//         "  <script type='application/dart' src='does/not/exist.dart'/>",
//         "</head>",
//         "<body>",
//         "</body>",
//         "</html>"]);
//     TestLogger testLogger = new TestLogger();
//     ParseHtmlTask task = parseSource(new TestSource_ParseHtmlTaskTest_test_perform_non_existing_source_reference(contents), contents, testLogger);
//     EngineTestCase.assertLength(0, task.referencedLibraries);
//     JUnitTestCase.assertEquals(0, testLogger.getErrorCount());
//     JUnitTestCase.assertEquals(0, testLogger.getInfoCount());
//   }
//   void test_perform_referenced_source() {
//     String contents = EngineTestCase.createSource([
//         "<html>",
//         "<head>",
//         "  <script type='application/dart' src='test.dart'/>",
//         "</head>",
//         "<body>",
//         "</body>",
//         "</html>"]);
//     TestLogger testLogger = new TestLogger();
//     ParseHtmlTask task = parseContents(contents, testLogger);
//     EngineTestCase.assertLength(1, task.referencedLibraries);
//     JUnitTestCase.assertEquals(0, testLogger.getErrorCount());
//     JUnitTestCase.assertEquals(0, testLogger.getInfoCount());
//   }
//   ParseHtmlTask parseContents(String contents, TestLogger testLogger) => parseSource(new TestSource.con2(contents), contents, testLogger);
//   ParseHtmlTask parseSource(Source source, String contents, TestLogger testLogger) {
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.setContents(source, contents);
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     ParseHtmlTask task = new ParseHtmlTask(context, source, context.getModificationStamp(source), contents);
//     Logger oldLogger = AnalysisEngine.instance.logger;
//     try {
//       AnalysisEngine.instance.logger = testLogger;
//       task.perform(new TestTaskVisitor_ParseHtmlTaskTest_parseSource(context, source));
//     } finally {
//       AnalysisEngine.instance.logger = oldLogger;
//     }
//     return task;
//   }
//   static dartSuite() {
//     _ut.group('ParseHtmlTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getException', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getException);
//       });
//       _ut.test('test_getHtmlUnit', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getHtmlUnit);
//       });
//       _ut.test('test_getLineInfo', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getLineInfo);
//       });
//       _ut.test('test_getReferencedLibraries', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getReferencedLibraries);
//       });
//       _ut.test('test_getSource', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getSource);
//       });
//       _ut.test('test_perform_embedded_source', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_perform_embedded_source);
//       });
//       _ut.test('test_perform_empty_source_reference', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_perform_empty_source_reference);
//       });
//       _ut.test('test_perform_invalid_source_reference', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_perform_invalid_source_reference);
//       });
//       _ut.test('test_perform_non_existing_source_reference', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_perform_non_existing_source_reference);
//       });
//       _ut.test('test_perform_referenced_source', () {
//         final __test = new ParseHtmlTaskTest();
//         runJUnitTest(__test, __test.test_perform_referenced_source);
//       });
//     });
//   }
// }
// class PartitionManagerTest extends EngineTestCase {
//   void test_creation() {
//     JUnitTestCase.assertNotNull(new PartitionManager());
//   }
//   void test_forSdk() {
//     PartitionManager manager = new PartitionManager();
//     DartSdk sdk1 = new MockDartSdk();
//     SdkCachePartition partition1 = manager.forSdk(sdk1);
//     JUnitTestCase.assertNotNull(partition1);
//     JUnitTestCase.assertSame(partition1, manager.forSdk(sdk1));
//     DartSdk sdk2 = new MockDartSdk();
//     SdkCachePartition partition2 = manager.forSdk(sdk2);
//     JUnitTestCase.assertNotNull(partition2);
//     JUnitTestCase.assertSame(partition2, manager.forSdk(sdk2));
//     JUnitTestCase.assertNotSame(partition1, partition2);
//   }
//   static dartSuite() {
//     _ut.group('PartitionManagerTest', () {
//       _ut.test('test_creation', () {
//         final __test = new PartitionManagerTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_forSdk', () {
//         final __test = new PartitionManagerTest();
//         runJUnitTest(__test, __test.test_forSdk);
//       });
//     });
//   }
// }
// class ResolveDartLibraryTaskTest extends EngineTestCase {
//   void test_accept() {
//     ResolveDartLibraryTask task = new ResolveDartLibraryTask(null, null, null);
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_ResolveDartLibraryTaskTest_test_accept()));
//   }
//   void test_getException() {
//     ResolveDartLibraryTask task = new ResolveDartLibraryTask(null, null, null);
//     JUnitTestCase.assertNull(task.exception);
//   }
//   void test_getLibraryResolver() {
//     ResolveDartLibraryTask task = new ResolveDartLibraryTask(null, null, null);
//     JUnitTestCase.assertNull(task.libraryResolver);
//   }
//   void test_getLibrarySource() {
//     Source source = new TestSource.con2("");
//     ResolveDartLibraryTask task = new ResolveDartLibraryTask(null, null, source);
//     JUnitTestCase.assertSame(source, task.librarySource);
//   }
//   void test_getUnitSource() {
//     Source source = new TestSource.con2("");
//     ResolveDartLibraryTask task = new ResolveDartLibraryTask(null, source, null);
//     JUnitTestCase.assertSame(source, task.unitSource);
//   }
//   void test_perform_exception() {
//     TestSource source = new TestSource();
//     source.generateExceptionOnRead = true;
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     ResolveDartLibraryTask task = new ResolveDartLibraryTask(context, source, source);
//     task.perform(new TestTaskVisitor_ResolveDartLibraryTaskTest_test_perform_exception());
//   }
//   void test_perform_library() {
//     Source source = new TestSource.con2(EngineTestCase.createSource(["library lib;", "class A {}"]));
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     ResolveDartLibraryTask task = new ResolveDartLibraryTask(context, source, source);
//     task.perform(new TestTaskVisitor_ResolveDartLibraryTaskTest_test_perform_library(source));
//   }
//   static dartSuite() {
//     _ut.group('ResolveDartLibraryTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new ResolveDartLibraryTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getException', () {
//         final __test = new ResolveDartLibraryTaskTest();
//         runJUnitTest(__test, __test.test_getException);
//       });
//       _ut.test('test_getLibraryResolver', () {
//         final __test = new ResolveDartLibraryTaskTest();
//         runJUnitTest(__test, __test.test_getLibraryResolver);
//       });
//       _ut.test('test_getLibrarySource', () {
//         final __test = new ResolveDartLibraryTaskTest();
//         runJUnitTest(__test, __test.test_getLibrarySource);
//       });
//       _ut.test('test_getUnitSource', () {
//         final __test = new ResolveDartLibraryTaskTest();
//         runJUnitTest(__test, __test.test_getUnitSource);
//       });
//       _ut.test('test_perform_exception', () {
//         final __test = new ResolveDartLibraryTaskTest();
//         runJUnitTest(__test, __test.test_perform_exception);
//       });
//       _ut.test('test_perform_library', () {
//         final __test = new ResolveDartLibraryTaskTest();
//         runJUnitTest(__test, __test.test_perform_library);
//       });
//     });
//   }
// }
// class ResolveDartUnitTaskTest extends EngineTestCase {
//   void test_accept() {
//     ResolveDartUnitTask task = new ResolveDartUnitTask(null, null, null);
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_ResolveDartUnitTaskTest_test_accept()));
//   }
//   void test_getException() {
//     ResolveDartUnitTask task = new ResolveDartUnitTask(null, null, null);
//     JUnitTestCase.assertNull(task.exception);
//   }
//   void test_getLibrarySource() {
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     LibraryElementImpl element = ElementFactory.library(context, "lib");
//     Source source = element.source;
//     ResolveDartUnitTask task = new ResolveDartUnitTask(null, null, element);
//     JUnitTestCase.assertSame(source, task.librarySource);
//   }
//   void test_getModificationTime() {
//     ResolveDartUnitTask task = new ResolveDartUnitTask(null, null, null);
//     JUnitTestCase.assertEquals(-1, task.modificationTime);
//   }
//   void test_getResolvedUnit() {
//     ResolveDartUnitTask task = new ResolveDartUnitTask(null, null, null);
//     JUnitTestCase.assertNull(task.resolvedUnit);
//   }
//   void test_getSource() {
//     Source source = new TestSource.con2("");
//     ResolveDartUnitTask task = new ResolveDartUnitTask(null, source, null);
//     JUnitTestCase.assertSame(source, task.source);
//   }
//   void test_perform_exception() {
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     LibraryElementImpl element = ElementFactory.library(context, "lib");
//     TestSource source = new TestSource();
//     source.generateExceptionOnRead = true;
//     (element.definingCompilationUnit as CompilationUnitElementImpl).source = source;
//     ResolveDartUnitTask task = new ResolveDartUnitTask(context, source, element);
//     task.perform(new TestTaskVisitor_ResolveDartUnitTaskTest_test_perform_exception());
//   }
//   void xtest_perform_library() {
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     LibraryElementImpl libraryElement = ElementFactory.library(context, "lib");
//     CompilationUnitElementImpl unitElement = libraryElement.definingCompilationUnit as CompilationUnitElementImpl;
//     ClassElementImpl classElement = ElementFactory.classElement2("A", []);
//     classElement.nameOffset = 19;
//     ConstructorElementImpl constructorElement = ElementFactory.constructorElement2(classElement, null, []);
//     constructorElement.synthetic = true;
//     classElement.constructors = <ConstructorElement> [constructorElement];
//     unitElement.types = <ClassElement> [classElement];
//     Source source = unitElement.source;
//     context.setContents(source, EngineTestCase.createSource(["library lib;", "class A {}"]));
//     ResolveDartUnitTask task = new ResolveDartUnitTask(context, source, libraryElement);
//     task.perform(new TestTaskVisitor_ResolveDartUnitTaskTest_xtest_perform_library(source, context));
//   }
//   static dartSuite() {
//     _ut.group('ResolveDartUnitTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new ResolveDartUnitTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getException', () {
//         final __test = new ResolveDartUnitTaskTest();
//         runJUnitTest(__test, __test.test_getException);
//       });
//       _ut.test('test_getLibrarySource', () {
//         final __test = new ResolveDartUnitTaskTest();
//         runJUnitTest(__test, __test.test_getLibrarySource);
//       });
//       _ut.test('test_getModificationTime', () {
//         final __test = new ResolveDartUnitTaskTest();
//         runJUnitTest(__test, __test.test_getModificationTime);
//       });
//       _ut.test('test_getResolvedUnit', () {
//         final __test = new ResolveDartUnitTaskTest();
//         runJUnitTest(__test, __test.test_getResolvedUnit);
//       });
//       _ut.test('test_getSource', () {
//         final __test = new ResolveDartUnitTaskTest();
//         runJUnitTest(__test, __test.test_getSource);
//       });
//       _ut.test('test_perform_exception', () {
//         final __test = new ResolveDartUnitTaskTest();
//         runJUnitTest(__test, __test.test_perform_exception);
//       });
//     });
//   }
// }
// class ResolveHtmlTaskTest extends EngineTestCase {
//   void test_accept() {
//     ResolveHtmlTask task = new ResolveHtmlTask(null, null, 0, null);
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_ResolveHtmlTaskTest_test_accept()));
//   }
//   void test_getElement() {
//     ResolveHtmlTask task = new ResolveHtmlTask(null, null, 0, null);
//     JUnitTestCase.assertNull(task.element);
//   }
//   void test_getException() {
//     ResolveHtmlTask task = new ResolveHtmlTask(null, null, 0, null);
//     JUnitTestCase.assertNull(task.exception);
//   }
//   void test_getModificationTime() {
//     int modificationTime = 28;
//     ResolveHtmlTask task = new ResolveHtmlTask(null, null, modificationTime, null);
//     JUnitTestCase.assertEquals(modificationTime, task.modificationTime);
//   }
//   void test_getResolutionErrors() {
//     ResolveHtmlTask task = new ResolveHtmlTask(null, null, 0, null);
//     EngineTestCase.assertLength(0, task.resolutionErrors);
//   }
//   void test_getSource() {
//     Source source = new TestSource.con2("");
//     ResolveHtmlTask task = new ResolveHtmlTask(null, source, 0, null);
//     JUnitTestCase.assertSame(source, task.source);
//   }
//   void test_perform_exception() {
//     Source source = new TestSource();
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     ResolveHtmlTask task = new ResolveHtmlTask(context, source, 0, null);
//     task.perform(new TestTaskVisitor_ResolveHtmlTaskTest_test_perform_exception());
//   }
//   void test_perform_valid() {
//     int modificationStamp = 73;
//     String content = EngineTestCase.createSource([
//         "<html>",
//         "<head>",
//         "  <script type='application/dart'>",
//         "    void f() { x = 0; }",
//         "  </script>",
//         "</head>",
//         "<body>",
//         "</body>",
//         "</html>"]);
//     Source source = new TestSource.con1(FileUtilities2.createFile("/test.html"), content);
//     InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
//     ParseHtmlTask parseTask = new ParseHtmlTask(context, source, modificationStamp, content);
//     parseTask.perform(new TestTaskVisitor_ResolveHtmlTaskTest_test_perform_valid());
//     ResolveHtmlTask task = new ResolveHtmlTask(context, source, parseTask.modificationTime, parseTask.htmlUnit);
//     task.perform(new TestTaskVisitor_ResolveHtmlTaskTest_test_perform_valid_2(modificationStamp, source));
//   }
//   static dartSuite() {
//     _ut.group('ResolveHtmlTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new ResolveHtmlTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getElement', () {
//         final __test = new ResolveHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getElement);
//       });
//       _ut.test('test_getException', () {
//         final __test = new ResolveHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getException);
//       });
//       _ut.test('test_getModificationTime', () {
//         final __test = new ResolveHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getModificationTime);
//       });
//       _ut.test('test_getResolutionErrors', () {
//         final __test = new ResolveHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getResolutionErrors);
//       });
//       _ut.test('test_getSource', () {
//         final __test = new ResolveHtmlTaskTest();
//         runJUnitTest(__test, __test.test_getSource);
//       });
//       _ut.test('test_perform_exception', () {
//         final __test = new ResolveHtmlTaskTest();
//         runJUnitTest(__test, __test.test_perform_exception);
//       });
//       _ut.test('test_perform_valid', () {
//         final __test = new ResolveHtmlTaskTest();
//         runJUnitTest(__test, __test.test_perform_valid);
//       });
//     });
//   }
// }
// class ScanDartTaskTest extends EngineTestCase {
//   void test_accept() {
//     ScanDartTask task = new ScanDartTask(null, null, 0, null);
//     JUnitTestCase.assertTrue(task.accept(new TestTaskVisitor_ScanDartTaskTest_test_accept()));
//   }
//   void test_getErrors() {
//     ScanDartTask task = new ScanDartTask(null, null, 0, null);
//     EngineTestCase.assertLength(0, task.errors);
//   }
//   void test_getException() {
//     ScanDartTask task = new ScanDartTask(null, null, 0, null);
//     JUnitTestCase.assertNull(task.exception);
//   }
//   void test_getLineInfo() {
//     ScanDartTask task = new ScanDartTask(null, null, 0, null);
//     JUnitTestCase.assertNull(task.lineInfo);
//   }
//   void test_getModificationTime() {
//     ScanDartTask task = new ScanDartTask(null, null, 0, null);
//     JUnitTestCase.assertEquals(0, task.modificationTime);
//   }
//   void test_getSource() {
//     Source source = new TestSource.con2("");
//     ScanDartTask task = new ScanDartTask(null, source, 0, null);
//     JUnitTestCase.assertSame(source, task.source);
//   }
//   void test_perform_valid() {
//     String content = EngineTestCase.createSource(["class A {}"]);
//     Source source = new TestSource.con2(content);
//     InternalAnalysisContext context = new AnalysisContextImpl();
//     context.sourceFactory = new SourceFactory([new FileUriResolver()]);
//     ScanDartTask task = new ScanDartTask(context, source, source.modificationStamp, content);
//     task.perform(new TestTaskVisitor_ScanDartTaskTest_test_perform_valid(context, source));
//   }
//   static dartSuite() {
//     _ut.group('ScanDartTaskTest', () {
//       _ut.test('test_accept', () {
//         final __test = new ScanDartTaskTest();
//         runJUnitTest(__test, __test.test_accept);
//       });
//       _ut.test('test_getErrors', () {
//         final __test = new ScanDartTaskTest();
//         runJUnitTest(__test, __test.test_getErrors);
//       });
//       _ut.test('test_getException', () {
//         final __test = new ScanDartTaskTest();
//         runJUnitTest(__test, __test.test_getException);
//       });
//       _ut.test('test_getLineInfo', () {
//         final __test = new ScanDartTaskTest();
//         runJUnitTest(__test, __test.test_getLineInfo);
//       });
//       _ut.test('test_getModificationTime', () {
//         final __test = new ScanDartTaskTest();
//         runJUnitTest(__test, __test.test_getModificationTime);
//       });
//       _ut.test('test_getSource', () {
//         final __test = new ScanDartTaskTest();
//         runJUnitTest(__test, __test.test_getSource);
//       });
//       _ut.test('test_perform_valid', () {
//         final __test = new ScanDartTaskTest();
//         runJUnitTest(__test, __test.test_perform_valid);
//       });
//     });
//   }
// }
// class SdkCachePartitionTest extends EngineTestCase {
//   void test_contains_false() {
//     SdkCachePartition partition = new SdkCachePartition(8);
//     Source source = new TestSource();
//     JUnitTestCase.assertFalse(partition.contains(source));
//   }
//   void test_contains_true() {
//     SdkCachePartition partition = new SdkCachePartition(8);
//     SourceFactory factory = new SourceFactory([new DartUriResolver(DirectoryBasedDartSdk.defaultSdk)]);
//     Source source = factory.forUri("dart:core");
//     JUnitTestCase.assertTrue(partition.contains(source));
//   }
//   void test_creation() {
//     JUnitTestCase.assertNotNull(new SdkCachePartition(8));
//   }
//   static dartSuite() {
//     _ut.group('SdkCachePartitionTest', () {
//       _ut.test('test_contains_false', () {
//         final __test = new SdkCachePartitionTest();
//         runJUnitTest(__test, __test.test_contains_false);
//       });
//       _ut.test('test_contains_true', () {
//         final __test = new SdkCachePartitionTest();
//         runJUnitTest(__test, __test.test_contains_true);
//       });
//       _ut.test('test_creation', () {
//         final __test = new SdkCachePartitionTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//     });
//   }
// }
// class SourceContainer_AnalysisContextImplTest_test_applyChanges_removeContainer implements SourceContainer {
//   Source libB;
//   SourceContainer_AnalysisContextImplTest_test_applyChanges_removeContainer(this.libB);
//   @override
//   bool contains(Source source) => source == libB;
// }
// /**
//  * Instances of the class `TestAnalysisContext` implement an analysis context in which every
//  * method will cause a test to fail when invoked.
//  */
// class TestAnalysisContext implements InternalAnalysisContext {
//   @override
//   void addSourceInfo(Source source, SourceEntry info) {
//     JUnitTestCase.fail("Unexpected invocation of addSourceInfo");
//   }
//   @override
//   void applyAnalysisDelta(AnalysisDelta delta) {
//     JUnitTestCase.fail("Unexpected invocation of applyAnalysisDelta");
//   }
//   @override
//   void applyChanges(ChangeSet changeSet) {
//     JUnitTestCase.fail("Unexpected invocation of applyChanges");
//   }
//   @override
//   String computeDocumentationComment(Element element) {
//     JUnitTestCase.fail("Unexpected invocation of computeDocumentationComment");
//     return null;
//   }
//   @override
//   List<AnalysisError> computeErrors(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of computeErrors");
//     return null;
//   }
//   @override
//   List<Source> computeExportedLibraries(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of computeExportedLibraries");
//     return null;
//   }
//   @override
//   HtmlElement computeHtmlElement(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of computeHtmlElement");
//     return null;
//   }
//   @override
//   List<Source> computeImportedLibraries(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of computeImportedLibraries");
//     return null;
//   }
//   @override
//   SourceKind computeKindOf(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of computeKindOf");
//     return null;
//   }
//   @override
//   LibraryElement computeLibraryElement(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of computeLibraryElement");
//     return null;
//   }
//   @override
//   LineInfo computeLineInfo(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of computeLineInfo");
//     return null;
//   }
//   @override
//   ResolvableCompilationUnit computeResolvableCompilationUnit(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of computeResolvableCompilationUnit");
//     return null;
//   }
//   @override
//   void dispose() {
//     JUnitTestCase.fail("Unexpected invocation of dispose");
//   }
//   @override
//   bool exists(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of exists");
//     return false;
//   }
//   @override
//   AnalysisContext extractContext(SourceContainer container) {
//     JUnitTestCase.fail("Unexpected invocation of extractContext");
//     return null;
//   }
//   @override
//   InternalAnalysisContext extractContextInto(SourceContainer container, InternalAnalysisContext newContext) {
//     JUnitTestCase.fail("Unexpected invocation of extractContextInto");
//     return null;
//   }
//   @override
//   AnalysisOptions get analysisOptions {
//     JUnitTestCase.fail("Unexpected invocation of getAnalysisOptions");
//     return null;
//   }
//   @override
//   AngularApplication getAngularApplicationWithHtml(Source htmlSource) {
//     JUnitTestCase.fail("Unexpected invocation of getAngularApplicationWithHtml");
//     return null;
//   }
//   @override
//   CompilationUnitElement getCompilationUnitElement(Source unitSource, Source librarySource) {
//     JUnitTestCase.fail("Unexpected invocation of getCompilationUnitElement");
//     return null;
//   }
//   @override
//   TimestampedData<String> getContents(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of getContents");
//     return null;
//   }
//   @override
//   void getContentsToReceiver(Source source, Source_ContentReceiver receiver) {
//     JUnitTestCase.fail("Unexpected invocation of getContentsToReceiver");
//   }
//   @override
//   DeclaredVariables get declaredVariables {
//     JUnitTestCase.fail("Unexpected invocation of getDeclaredVariables");
//     return null;
//   }
//   @override
//   Element getElement(ElementLocation location) {
//     JUnitTestCase.fail("Unexpected invocation of getElement");
//     return null;
//   }
//   @override
//   AnalysisErrorInfo getErrors(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of getErrors");
//     return null;
//   }
//   @override
//   HtmlElement getHtmlElement(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of getHtmlElement");
//     return null;
//   }
//   @override
//   List<Source> getHtmlFilesReferencing(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of getHtmlFilesReferencing");
//     return null;
//   }
//   @override
//   List<Source> get htmlSources {
//     JUnitTestCase.fail("Unexpected invocation of getHtmlSources");
//     return null;
//   }
//   @override
//   SourceKind getKindOf(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of getKindOf");
//     return null;
//   }
//   @override
//   List<Source> get launchableClientLibrarySources {
//     JUnitTestCase.fail("Unexpected invocation of getLaunchableClientLibrarySources");
//     return null;
//   }
//   @override
//   List<Source> get launchableServerLibrarySources {
//     JUnitTestCase.fail("Unexpected invocation of getLaunchableServerLibrarySources");
//     return null;
//   }
//   @override
//   List<Source> getLibrariesContaining(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of getLibrariesContaining");
//     return null;
//   }
//   @override
//   List<Source> getLibrariesDependingOn(Source librarySource) {
//     JUnitTestCase.fail("Unexpected invocation of getLibrariesDependingOn");
//     return null;
//   }
//   @override
//   List<Source> getLibrariesReferencedFromHtml(Source htmlSource) {
//     JUnitTestCase.fail("Unexpected invocation of getLibrariesReferencedFromHtml");
//     return null;
//   }
//   @override
//   LibraryElement getLibraryElement(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of getLibraryElement");
//     return null;
//   }
//   @override
//   List<Source> get librarySources {
//     JUnitTestCase.fail("Unexpected invocation of getLibrarySources");
//     return null;
//   }
//   @override
//   LineInfo getLineInfo(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of getLineInfo");
//     return null;
//   }
//   @override
//   int getModificationStamp(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of getModificationStamp");
//     return 0;
//   }
//   @override
//   List<Source> get prioritySources {
//     JUnitTestCase.fail("Unexpected invocation of getPrioritySources");
//     return null;
//   }
//   @override
//   Namespace getPublicNamespace(LibraryElement library) {
//     JUnitTestCase.fail("Unexpected invocation of getPublicNamespace");
//     return null;
//   }
//   @override
//   List<Source> get refactoringUnsafeSources {
//     JUnitTestCase.fail("Unexpected invocation of getRefactoringUnsafeSources");
//     return null;
//   }
//   @override
//   CompilationUnit getResolvedCompilationUnit(Source unitSource, LibraryElement library) {
//     JUnitTestCase.fail("Unexpected invocation of getResolvedCompilationUnit");
//     return null;
//   }
//   @override
//   CompilationUnit getResolvedCompilationUnit2(Source unitSource, Source librarySource) {
//     JUnitTestCase.fail("Unexpected invocation of getResolvedCompilationUnit");
//     return null;
//   }
//   @override
//   HtmlUnit getResolvedHtmlUnit(Source htmlSource) {
//     JUnitTestCase.fail("Unexpected invocation of getResolvedHtmlUnit");
//     return null;
//   }
//   @override
//   SourceFactory get sourceFactory {
//     JUnitTestCase.fail("Unexpected invocation of getSourceFactory");
//     return null;
//   }
//   @override
//   AnalysisContextStatistics get statistics {
//     JUnitTestCase.fail("Unexpected invocation of getStatistics");
//     return null;
//   }
//   @override
//   TypeProvider get typeProvider {
//     JUnitTestCase.fail("Unexpected invocation of getTypeProvider");
//     return null;
//   }
//   @override
//   bool isClientLibrary(Source librarySource) {
//     JUnitTestCase.fail("Unexpected invocation of isClientLibrary");
//     return false;
//   }
//   @override
//   bool get isDisposed {
//     JUnitTestCase.fail("Unexpected invocation of isDisposed");
//     return false;
//   }
//   @override
//   bool isServerLibrary(Source librarySource) {
//     JUnitTestCase.fail("Unexpected invocation of isServerLibrary");
//     return false;
//   }
//   @override
//   void mergeContext(AnalysisContext context) {
//     JUnitTestCase.fail("Unexpected invocation of mergeContext");
//   }
//   @override
//   CompilationUnit parseCompilationUnit(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of parseCompilationUnit");
//     return null;
//   }
//   @override
//   HtmlUnit parseHtmlUnit(Source source) {
//     JUnitTestCase.fail("Unexpected invocation of parseHtmlUnit");
//     return null;
//   }
//   @override
//   AnalysisResult performAnalysisTask() {
//     JUnitTestCase.fail("Unexpected invocation of performAnalysisTask");
//     return null;
//   }
//   @override
//   void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
//     JUnitTestCase.fail("Unexpected invocation of recordLibraryElements");
//   }
//   @override
//   CompilationUnit resolveCompilationUnit(Source unitSource, LibraryElement library) {
//     JUnitTestCase.fail("Unexpected invocation of resolveCompilationUnit");
//     return null;
//   }
//   @override
//   CompilationUnit resolveCompilationUnit2(Source unitSource, Source librarySource) {
//     JUnitTestCase.fail("Unexpected invocation of resolveCompilationUnit");
//     return null;
//   }
//   @override
//   HtmlUnit resolveHtmlUnit(Source htmlSource) {
//     JUnitTestCase.fail("Unexpected invocation of resolveHtmlUnit");
//     return null;
//   }
//   @override
//   void set analysisOptions(AnalysisOptions options) {
//     JUnitTestCase.fail("Unexpected invocation of setAnalysisOptions");
//   }
//   @override
//   void set analysisPriorityOrder(List<Source> sources) {
//     JUnitTestCase.fail("Unexpected invocation of setAnalysisPriorityOrder");
//   }
//   @override
//   void setChangedContents(Source source, String contents, int offset, int oldLength, int newLength) {
//     JUnitTestCase.fail("Unexpected invocation of setChangedContents");
//   }
//   @override
//   void setContents(Source source, String contents) {
//     JUnitTestCase.fail("Unexpected invocation of setContents");
//   }
//   @override
//   void set sourceFactory(SourceFactory factory) {
//     JUnitTestCase.fail("Unexpected invocation of setSourceFactory");
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_addSourceInfo extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_addSourceInfo(this.invoked) : super();
//   @override
//   void addSourceInfo(Source source, SourceEntry info) {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_applyChanges extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_applyChanges(this.invoked) : super();
//   @override
//   void applyChanges(ChangeSet changeSet) {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeDocumentationComment extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeDocumentationComment(this.invoked) : super();
//   @override
//   String computeDocumentationComment(Element element) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeErrors extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeErrors(this.invoked) : super();
//   @override
//   List<AnalysisError> computeErrors(Source source) {
//     invoked[0] = true;
//     return AnalysisError.NO_ERRORS;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeExportedLibraries extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeExportedLibraries(this.invoked) : super();
//   @override
//   List<Source> computeExportedLibraries(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeHtmlElement extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeHtmlElement(this.invoked) : super();
//   @override
//   HtmlElement computeHtmlElement(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeImportedLibraries extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeImportedLibraries(this.invoked) : super();
//   @override
//   List<Source> computeImportedLibraries(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeKindOf extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeKindOf(this.invoked) : super();
//   @override
//   SourceKind computeKindOf(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeLibraryElement extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeLibraryElement(this.invoked) : super();
//   @override
//   LibraryElement computeLibraryElement(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeLineInfo extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeLineInfo(this.invoked) : super();
//   @override
//   LineInfo computeLineInfo(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeResolvableCompilationUnit extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_computeResolvableCompilationUnit(this.invoked) : super();
//   @override
//   ResolvableCompilationUnit computeResolvableCompilationUnit(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_dispose extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_dispose(this.invoked) : super();
//   @override
//   void dispose() {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_exists extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_exists(this.invoked) : super();
//   @override
//   bool exists(Source source) {
//     invoked[0] = true;
//     return false;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_extractContext extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_extractContext(this.invoked) : super();
//   @override
//   InternalAnalysisContext extractContextInto(SourceContainer container, InternalAnalysisContext newContext) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_extractContextInto extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_extractContextInto(this.invoked) : super();
//   @override
//   InternalAnalysisContext extractContextInto(SourceContainer container, InternalAnalysisContext newContext) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getAnalysisOptions extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getAnalysisOptions(this.invoked) : super();
//   @override
//   AnalysisOptions get analysisOptions {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getAngularApplicationWithHtml extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getAngularApplicationWithHtml(this.invoked) : super();
//   @override
//   AngularApplication getAngularApplicationWithHtml(Source htmlSource) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getCompilationUnitElement extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getCompilationUnitElement(this.invoked) : super();
//   @override
//   CompilationUnitElement getCompilationUnitElement(Source unitSource, Source librarySource) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getContents extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getContents(this.invoked) : super();
//   @override
//   TimestampedData<String> getContents(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getContentsToReceiver extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getContentsToReceiver(this.invoked) : super();
//   @override
//   void getContentsToReceiver(Source source, Source_ContentReceiver receiver) {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getElement extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getElement(this.invoked) : super();
//   @override
//   Element getElement(ElementLocation location) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getErrors extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getErrors(this.invoked) : super();
//   @override
//   AnalysisErrorInfo getErrors(Source source) {
//     invoked[0] = true;
//     return new AnalysisErrorInfoImpl(AnalysisError.NO_ERRORS, null);
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getHtmlElement extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getHtmlElement(this.invoked) : super();
//   @override
//   HtmlElement getHtmlElement(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getHtmlFilesReferencing extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getHtmlFilesReferencing(this.invoked) : super();
//   @override
//   List<Source> getHtmlFilesReferencing(Source source) {
//     invoked[0] = true;
//     return Source.EMPTY_ARRAY;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getHtmlSources extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getHtmlSources(this.invoked) : super();
//   @override
//   List<Source> get htmlSources {
//     invoked[0] = true;
//     return Source.EMPTY_ARRAY;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getKindOf extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getKindOf(this.invoked) : super();
//   @override
//   SourceKind getKindOf(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLaunchableClientLibrarySources extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLaunchableClientLibrarySources(this.invoked) : super();
//   @override
//   List<Source> get launchableClientLibrarySources {
//     invoked[0] = true;
//     return Source.EMPTY_ARRAY;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLaunchableServerLibrarySources extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLaunchableServerLibrarySources(this.invoked) : super();
//   @override
//   List<Source> get launchableServerLibrarySources {
//     invoked[0] = true;
//     return Source.EMPTY_ARRAY;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrariesContaining extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrariesContaining(this.invoked) : super();
//   @override
//   List<Source> getLibrariesContaining(Source source) {
//     invoked[0] = true;
//     return Source.EMPTY_ARRAY;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrariesDependingOn extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrariesDependingOn(this.invoked) : super();
//   @override
//   List<Source> getLibrariesDependingOn(Source librarySource) {
//     invoked[0] = true;
//     return Source.EMPTY_ARRAY;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrariesReferencedFromHtml extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrariesReferencedFromHtml(this.invoked) : super();
//   @override
//   List<Source> getLibrariesReferencedFromHtml(Source htmlSource) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibraryElement extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibraryElement(this.invoked) : super();
//   @override
//   LibraryElement getLibraryElement(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrarySources extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLibrarySources(this.invoked) : super();
//   @override
//   List<Source> get librarySources {
//     invoked[0] = true;
//     return Source.EMPTY_ARRAY;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLineInfo extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getLineInfo(this.invoked) : super();
//   @override
//   LineInfo getLineInfo(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getModificationStamp extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getModificationStamp(this.invoked) : super();
//   @override
//   int getModificationStamp(Source source) {
//     invoked[0] = true;
//     return 0;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getPublicNamespace extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getPublicNamespace(this.invoked) : super();
//   @override
//   Namespace getPublicNamespace(LibraryElement library) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getRefactoringUnsafeSources extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getRefactoringUnsafeSources(this.invoked) : super();
//   @override
//   List<Source> get refactoringUnsafeSources {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getResolvedCompilationUnit_element extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getResolvedCompilationUnit_element(this.invoked) : super();
//   @override
//   CompilationUnit getResolvedCompilationUnit(Source unitSource, LibraryElement library) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getResolvedCompilationUnit_source extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getResolvedCompilationUnit_source(this.invoked) : super();
//   @override
//   CompilationUnit getResolvedCompilationUnit2(Source unitSource, Source librarySource) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getResolvedHtmlUnit extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getResolvedHtmlUnit(this.invoked) : super();
//   @override
//   HtmlUnit getResolvedHtmlUnit(Source htmlSource) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getSourceFactory extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getSourceFactory(this.invoked) : super();
//   @override
//   SourceFactory get sourceFactory {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getStatistics extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getStatistics(this.invoked) : super();
//   @override
//   AnalysisContextStatistics get statistics {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getTypeProvider extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_getTypeProvider(this.invoked) : super();
//   @override
//   TypeProvider get typeProvider {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_isClientLibrary extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_isClientLibrary(this.invoked) : super();
//   @override
//   bool isClientLibrary(Source librarySource) {
//     invoked[0] = true;
//     return false;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_isDisposed extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_isDisposed(this.invoked) : super();
//   @override
//   bool get isDisposed {
//     invoked[0] = true;
//     return false;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_isServerLibrary extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_isServerLibrary(this.invoked) : super();
//   @override
//   bool isServerLibrary(Source librarySource) {
//     invoked[0] = true;
//     return false;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_mergeContext extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_mergeContext(this.invoked) : super();
//   @override
//   void mergeContext(AnalysisContext context) {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_parseCompilationUnit extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_parseCompilationUnit(this.invoked) : super();
//   @override
//   CompilationUnit parseCompilationUnit(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_parseHtmlUnit extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_parseHtmlUnit(this.invoked) : super();
//   @override
//   HtmlUnit parseHtmlUnit(Source source) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_performAnalysisTask extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_performAnalysisTask(this.invoked) : super();
//   @override
//   AnalysisResult performAnalysisTask() {
//     invoked[0] = true;
//     return new AnalysisResult(new List<ChangeNotice>(0), 0, null, 0);
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_recordLibraryElements extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_recordLibraryElements(this.invoked) : super();
//   @override
//   void recordLibraryElements(Map<Source, LibraryElement> elementMap) {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_resolveCompilationUnit extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_resolveCompilationUnit(this.invoked) : super();
//   @override
//   CompilationUnit resolveCompilationUnit2(Source unitSource, Source librarySource) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_resolveCompilationUnit_element extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_resolveCompilationUnit_element(this.invoked) : super();
//   @override
//   CompilationUnit resolveCompilationUnit(Source unitSource, LibraryElement library) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_resolveHtmlUnit extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_resolveHtmlUnit(this.invoked) : super();
//   @override
//   HtmlUnit resolveHtmlUnit(Source htmlSource) {
//     invoked[0] = true;
//     return null;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setAnalysisOptions extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setAnalysisOptions(this.invoked) : super();
//   @override
//   void set analysisOptions(AnalysisOptions options) {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setAnalysisPriorityOrder extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setAnalysisPriorityOrder(this.invoked) : super();
//   @override
//   void set analysisPriorityOrder(List<Source> sources) {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setChangedContents extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setChangedContents(this.invoked) : super();
//   @override
//   void setChangedContents(Source source, String contents, int offset, int oldLength, int newLength) {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setContents extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setContents(this.invoked) : super();
//   @override
//   void setContents(Source source, String contents) {
//     invoked[0] = true;
//   }
// }
// class TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setSourceFactory extends TestAnalysisContext {
//   List<bool> invoked;
//   TestAnalysisContext_InstrumentedAnalysisContextImplTest_test_setSourceFactory(this.invoked) : super();
//   @override
//   void set sourceFactory(SourceFactory factory) {
//     invoked[0] = true;
//   }
// }
// /**
//  * This subclass of DartEntryImpl allows test code to invoke the copyFrom() method.
//  */
// class TestDartEntryImpl extends DartEntryImpl {
//   @override
//   void copyFrom(SourceEntryImpl entry) {
//     super.copyFrom(entry);
//   }
// }
// class TestSource_AnalysisContextImplTest_test_exists_true extends TestSource {
//   @override
//   bool exists() => true;
// }
// class TestSource_AnalysisContextImplTest_test_getModificationStamp_fromSource extends TestSource {
//   long stamp;
//   TestSource_AnalysisContextImplTest_test_getModificationStamp_fromSource(this.stamp) : super();
//   @override
//   int get modificationStamp => stamp;
// }
// class TestSource_AnalysisContextImplTest_test_getModificationStamp_overridden extends TestSource {
//   long stamp;
//   TestSource_AnalysisContextImplTest_test_getModificationStamp_overridden(this.stamp) : super();
//   @override
//   int get modificationStamp => stamp;
// }
// class TestSource_ParseHtmlTaskTest_test_perform_non_existing_source_reference extends TestSource {
//   TestSource_ParseHtmlTaskTest_test_perform_non_existing_source_reference(String arg0) : super.con2(arg0);
//   @override
//   Uri resolveRelativeUri(Uri containedUri) {
//     try {
//       return parseUriWithException("file:/does/not/exist.dart");
//     } on URISyntaxException catch (exception) {
//       return null;
//     }
//   }
// }
// /**
//  * Instances of the class `TestTaskVisitor` implement a task visitor that fails if any of its
//  * methods are invoked. Subclasses typically override the expected methods to not cause a test
//  * failure.
//  */
// class TestTaskVisitor<E> implements AnalysisTaskVisitor<E> {
//   @override
//   E visitBuildDartElementModelTask(BuildDartElementModelTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitBuildDartElementModelTask");
//     return null;
//   }
//   @override
//   E visitGenerateDartErrorsTask(GenerateDartErrorsTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitGenerateDartErrorsTask");
//     return null;
//   }
//   @override
//   E visitGenerateDartHintsTask(GenerateDartHintsTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitGenerateDartHintsTask");
//     return null;
//   }
//   @override
//   E visitGetContentTask(GetContentTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitGetContentsTask");
//     return null;
//   }
//   @override
//   E visitIncrementalAnalysisTask(IncrementalAnalysisTask incrementalAnalysisTask) {
//     JUnitTestCase.fail("Unexpectedly invoked visitIncrementalAnalysisTask");
//     return null;
//   }
//   @override
//   E visitParseDartTask(ParseDartTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitParseDartTask");
//     return null;
//   }
//   @override
//   E visitParseHtmlTask(ParseHtmlTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitParseHtmlTask");
//     return null;
//   }
//   @override
//   E visitPolymerBuildHtmlTask(PolymerBuildHtmlTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitPolymerBuildHtmlTask");
//     return null;
//   }
//   @override
//   E visitPolymerResolveHtmlTask(PolymerResolveHtmlTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitPolymerResolveHtmlTask");
//     return null;
//   }
//   @override
//   E visitResolveAngularComponentTemplateTask(ResolveAngularComponentTemplateTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitResolveAngularComponentTemplateTask");
//     return null;
//   }
//   @override
//   E visitResolveAngularEntryHtmlTask(ResolveAngularEntryHtmlTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitResolveAngularEntryHtmlTask");
//     return null;
//   }
//   @override
//   E visitResolveDartLibraryCycleTask(ResolveDartLibraryCycleTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitResolveDartLibraryCycleTask");
//     return null;
//   }
//   @override
//   E visitResolveDartLibraryTask(ResolveDartLibraryTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitResolveDartLibraryTask");
//     return null;
//   }
//   @override
//   E visitResolveDartUnitTask(ResolveDartUnitTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitResolveDartUnitTask");
//     return null;
//   }
//   @override
//   E visitResolveHtmlTask(ResolveHtmlTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitResolveHtmlTask");
//     return null;
//   }
//   @override
//   E visitScanDartTask(ScanDartTask task) {
//     JUnitTestCase.fail("Unexpectedly invoked visitScanDartTask");
//     return null;
//   }
// }
// class TestTaskVisitor_BuildDartElementModelTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitBuildDartElementModelTask(BuildDartElementModelTask task) => true;
// }
// class TestTaskVisitor_BuildDartElementModelTaskTest_test_perform_multiple extends TestTaskVisitor<Object> {
//   @override
//   Object visitBuildDartElementModelTask(BuildDartElementModelTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     EngineTestCase.assertLength(0, task.errorListener.errors);
//     List<ResolvableLibrary> librariesInCycle = task.librariesInCycle;
//     EngineTestCase.assertSizeOfList(3, librariesInCycle);
//     for (int i = 0; i < 3; i++) {
//       ResolvableLibrary library = librariesInCycle[i];
//       LibraryElementImpl libraryElement = library.libraryElement;
//       JUnitTestCase.assertNotNull(libraryElement);
//       CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
//       JUnitTestCase.assertNotNull(unitElement);
//       List<ClassElement> types = unitElement.types;
//       EngineTestCase.assertLength(1, types);
//     }
//     return null;
//   }
// }
// class TestTaskVisitor_BuildDartElementModelTaskTest_test_perform_single_noParts extends TestTaskVisitor<Object> {
//   @override
//   Object visitBuildDartElementModelTask(BuildDartElementModelTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     EngineTestCase.assertLength(0, task.errorListener.errors);
//     List<ResolvableLibrary> librariesInCycle = task.librariesInCycle;
//     EngineTestCase.assertSizeOfList(1, librariesInCycle);
//     ResolvableLibrary library = librariesInCycle[0];
//     LibraryElementImpl libraryElement = library.libraryElement;
//     JUnitTestCase.assertNotNull(libraryElement);
//     CompilationUnitElement unitElement = libraryElement.definingCompilationUnit;
//     JUnitTestCase.assertNotNull(unitElement);
//     List<ClassElement> types = unitElement.types;
//     EngineTestCase.assertLength(2, types);
//     InterfaceType supertype = types[1].supertype;
//     JUnitTestCase.assertNotNull(supertype);
//     JUnitTestCase.assertSame(types[0], supertype.element);
//     return null;
//   }
// }
// class TestTaskVisitor_BuildDartElementModelTaskTest_test_perform_single_parts extends TestTaskVisitor<Object> {
//   @override
//   Object visitBuildDartElementModelTask(BuildDartElementModelTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     EngineTestCase.assertLength(0, task.errorListener.errors);
//     List<ResolvableLibrary> librariesInCycle = task.librariesInCycle;
//     EngineTestCase.assertSizeOfList(1, librariesInCycle);
//     ResolvableLibrary library = librariesInCycle[0];
//     LibraryElementImpl libraryElement = library.libraryElement;
//     JUnitTestCase.assertNotNull(libraryElement);
//     CompilationUnitElement definingUnit = libraryElement.definingCompilationUnit;
//     JUnitTestCase.assertNotNull(definingUnit);
//     List<ClassElement> definingTypes = definingUnit.types;
//     EngineTestCase.assertLength(2, definingTypes);
//     List<CompilationUnitElement> parts = libraryElement.parts;
//     JUnitTestCase.assertNotNull(parts);
//     EngineTestCase.assertLength(2, parts);
//     List<ClassElement> types = parts[0].types;
//     EngineTestCase.assertLength(1, types);
//     InterfaceType supertype = types[0].supertype;
//     JUnitTestCase.assertNotNull(supertype);
//     JUnitTestCase.assertSame(definingTypes[1], supertype.element);
//     types = parts[1].types;
//     EngineTestCase.assertLength(1, types);
//     InterfaceType implementedType = types[0].interfaces[0];
//     JUnitTestCase.assertNotNull(implementedType);
//     JUnitTestCase.assertSame(definingTypes[0], implementedType.element);
//     return null;
//   }
// }
// class TestTaskVisitor_GenerateDartErrorsTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitGenerateDartErrorsTask(GenerateDartErrorsTask task) => true;
// }
// class TestTaskVisitor_GenerateDartErrorsTaskTest_test_perform extends TestTaskVisitor<Boolean> {
//   LibraryElement libraryElement;
//   Source source;
//   TestTaskVisitor_GenerateDartErrorsTaskTest_test_perform(this.libraryElement, this.source) : super();
//   @override
//   bool visitGenerateDartErrorsTask(GenerateDartErrorsTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertSame(libraryElement, task.libraryElement);
//     JUnitTestCase.assertSame(source, task.source);
//     List<AnalysisError> errors = task.errors;
//     EngineTestCase.assertLength(1, errors);
//     return true;
//   }
// }
// class TestTaskVisitor_GenerateDartErrorsTaskTest_test_perform_validateDirectives extends TestTaskVisitor<Boolean> {
//   LibraryElement libraryElement;
//   Source source;
//   TestTaskVisitor_GenerateDartErrorsTaskTest_test_perform_validateDirectives(this.libraryElement, this.source) : super();
//   @override
//   bool visitGenerateDartErrorsTask(GenerateDartErrorsTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertSame(libraryElement, task.libraryElement);
//     JUnitTestCase.assertSame(source, task.source);
//     List<AnalysisError> errors = task.errors;
//     EngineTestCase.assertLength(1, errors);
//     JUnitTestCase.assertSame(CompileTimeErrorCode.URI_DOES_NOT_EXIST, errors[0].errorCode);
//     return true;
//   }
// }
// class TestTaskVisitor_GenerateDartHintsTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitGenerateDartHintsTask(GenerateDartHintsTask task) => true;
// }
// class TestTaskVisitor_GenerateDartHintsTaskTest_test_perform extends TestTaskVisitor<Boolean> {
//   Source librarySource;
//   Source partSource;
//   TestTaskVisitor_GenerateDartHintsTaskTest_test_perform(this.librarySource, this.partSource) : super();
//   @override
//   bool visitGenerateDartHintsTask(GenerateDartHintsTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertNotNull(task.libraryElement);
//     HashMap<Source, TimestampedData<List<AnalysisError>>> hintMap = task.hintMap;
//     EngineTestCase.assertSizeOfMap(2, hintMap);
//     EngineTestCase.assertLength(1, hintMap[librarySource].data);
//     EngineTestCase.assertLength(0, hintMap[partSource].data);
//     return true;
//   }
// }
// class TestTaskVisitor_GetContentTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitGetContentTask(GetContentTask task) => true;
// }
// class TestTaskVisitor_GetContentTaskTest_test_perform_exception extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitGetContentTask(GetContentTask task) {
//     JUnitTestCase.assertNotNull(task.exception);
//     return true;
//   }
// }
// class TestTaskVisitor_GetContentTaskTest_test_perform_valid extends TestTaskVisitor<Boolean> {
//   InternalAnalysisContext context;
//   Source source;
//   TestTaskVisitor_GetContentTaskTest_test_perform_valid(this.context, this.source) : super();
//   @override
//   bool visitGetContentTask(GetContentTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertEquals(context.getModificationStamp(source), task.modificationTime);
//     JUnitTestCase.assertSame(source, task.source);
//     return true;
//   }
// }
// class TestTaskVisitor_IncrementalAnalysisTaskTest_assertTask extends TestTaskVisitor<CompilationUnit> {
//   IncrementalAnalysisTask task;
//   TestTaskVisitor_IncrementalAnalysisTaskTest_assertTask(this.task) : super();
//   @override
//   CompilationUnit visitIncrementalAnalysisTask(IncrementalAnalysisTask incrementalAnalysisTask) => task.compilationUnit;
// }
// class TestTaskVisitor_IncrementalAnalysisTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitIncrementalAnalysisTask(IncrementalAnalysisTask task) => true;
// }
// class TestTaskVisitor_ParseDartTaskTest_createParseTask extends TestTaskVisitor<Object> {
//   @override
//   Object visitScanDartTask(ScanDartTask task) => null;
// }
// class TestTaskVisitor_ParseDartTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitParseDartTask(ParseDartTask task) => true;
// }
// class TestTaskVisitor_ParseDartTaskTest_test_perform_exception extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitParseDartTask(ParseDartTask task) {
//     JUnitTestCase.assertNotNull(task.exception);
//     return true;
//   }
// }
// class TestTaskVisitor_ParseDartTaskTest_test_perform_library extends TestTaskVisitor<Object> {
//   InternalAnalysisContext context;
//   Source source;
//   TestTaskVisitor_ParseDartTaskTest_test_perform_library(this.context, this.source) : super();
//   @override
//   Object visitParseDartTask(ParseDartTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertNotNull(task.compilationUnit);
//     EngineTestCase.assertLength(1, task.errors);
//     JUnitTestCase.assertEquals(context.getModificationStamp(source), task.modificationTime);
//     JUnitTestCase.assertSame(source, task.source);
//     JUnitTestCase.assertTrue(task.hasNonPartOfDirective);
//     JUnitTestCase.assertFalse(task.hasPartOfDirective);
//     return null;
//   }
// }
// class TestTaskVisitor_ParseDartTaskTest_test_perform_part extends TestTaskVisitor<Object> {
//   InternalAnalysisContext context;
//   Source source;
//   TestTaskVisitor_ParseDartTaskTest_test_perform_part(this.context, this.source) : super();
//   @override
//   Object visitParseDartTask(ParseDartTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertNotNull(task.compilationUnit);
//     EngineTestCase.assertLength(0, task.errors);
//     JUnitTestCase.assertEquals(context.getModificationStamp(source), task.modificationTime);
//     JUnitTestCase.assertSame(source, task.source);
//     JUnitTestCase.assertFalse(task.hasNonPartOfDirective);
//     JUnitTestCase.assertTrue(task.hasPartOfDirective);
//     return null;
//   }
// }
// class TestTaskVisitor_ParseDartTaskTest_test_perform_validateDirectives extends TestTaskVisitor<Object> {
//   InternalAnalysisContext context;
//   Source source;
//   TestTaskVisitor_ParseDartTaskTest_test_perform_validateDirectives(this.context, this.source) : super();
//   @override
//   Object visitParseDartTask(ParseDartTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertNotNull(task.compilationUnit);
//     GatheringErrorListener errorListener = new GatheringErrorListener();
//     errorListener.addAll(task.errors);
//     errorListener.assertErrorsWithCodes([
//         CompileTimeErrorCode.URI_WITH_INTERPOLATION,
//         CompileTimeErrorCode.INVALID_URI]);
//     JUnitTestCase.assertEquals(context.getModificationStamp(source), task.modificationTime);
//     JUnitTestCase.assertSame(source, task.source);
//     JUnitTestCase.assertTrue(task.hasNonPartOfDirective);
//     JUnitTestCase.assertFalse(task.hasPartOfDirective);
//     return null;
//   }
// }
// class TestTaskVisitor_ParseHtmlTaskTest_parseSource extends TestTaskVisitor<Boolean> {
//   InternalAnalysisContext context;
//   Source source;
//   TestTaskVisitor_ParseHtmlTaskTest_parseSource(this.context, this.source) : super();
//   @override
//   bool visitParseHtmlTask(ParseHtmlTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertNotNull(task.htmlUnit);
//     JUnitTestCase.assertNotNull(task.lineInfo);
//     JUnitTestCase.assertEquals(context.getModificationStamp(source), task.modificationTime);
//     JUnitTestCase.assertSame(source, task.source);
//     return true;
//   }
// }
// class TestTaskVisitor_ParseHtmlTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitParseHtmlTask(ParseHtmlTask task) => true;
// }
// class TestTaskVisitor_ResolveDartLibraryTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitResolveDartLibraryTask(ResolveDartLibraryTask task) => true;
// }
// class TestTaskVisitor_ResolveDartLibraryTaskTest_test_perform_exception extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitResolveDartLibraryTask(ResolveDartLibraryTask task) {
//     JUnitTestCase.assertNotNull(task.exception);
//     return true;
//   }
// }
// class TestTaskVisitor_ResolveDartLibraryTaskTest_test_perform_library extends TestTaskVisitor<Boolean> {
//   Source source;
//   TestTaskVisitor_ResolveDartLibraryTaskTest_test_perform_library(this.source) : super();
//   @override
//   bool visitResolveDartLibraryTask(ResolveDartLibraryTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertNotNull(task.libraryResolver);
//     JUnitTestCase.assertSame(source, task.librarySource);
//     JUnitTestCase.assertSame(source, task.unitSource);
//     return true;
//   }
// }
// class TestTaskVisitor_ResolveDartUnitTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitResolveDartUnitTask(ResolveDartUnitTask task) => true;
// }
// class TestTaskVisitor_ResolveDartUnitTaskTest_test_perform_exception extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitResolveDartUnitTask(ResolveDartUnitTask task) {
//     JUnitTestCase.assertNotNull(task.exception);
//     return true;
//   }
// }
// class TestTaskVisitor_ResolveDartUnitTaskTest_xtest_perform_library extends TestTaskVisitor<Boolean> {
//   Source source;
//   InternalAnalysisContext context;
//   TestTaskVisitor_ResolveDartUnitTaskTest_xtest_perform_library(this.source, this.context) : super();
//   @override
//   bool visitResolveDartUnitTask(ResolveDartUnitTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertSame(source, task.librarySource);
//     JUnitTestCase.assertEquals(context.getModificationStamp(source), task.modificationTime);
//     JUnitTestCase.assertNotNull(task.resolvedUnit);
//     JUnitTestCase.assertSame(source, task.source);
//     return true;
//   }
// }
// class TestTaskVisitor_ResolveHtmlTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitResolveHtmlTask(ResolveHtmlTask task) => true;
// }
// class TestTaskVisitor_ResolveHtmlTaskTest_test_perform_exception extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitResolveHtmlTask(ResolveHtmlTask task) {
//     JUnitTestCase.assertNotNull(task.exception);
//     return true;
//   }
// }
// class TestTaskVisitor_ResolveHtmlTaskTest_test_perform_valid extends TestTaskVisitor<Object> {
//   @override
//   Object visitParseHtmlTask(ParseHtmlTask task) => null;
// }
// class TestTaskVisitor_ResolveHtmlTaskTest_test_perform_valid_2 extends TestTaskVisitor<Object> {
//   long modificationStamp;
//   Source source;
//   TestTaskVisitor_ResolveHtmlTaskTest_test_perform_valid_2(this.modificationStamp, this.source) : super();
//   @override
//   Object visitResolveHtmlTask(ResolveHtmlTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertNotNull(task.element);
//     JUnitTestCase.assertEquals(modificationStamp, task.modificationTime);
//     EngineTestCase.assertLength(1, task.resolutionErrors);
//     JUnitTestCase.assertSame(source, task.source);
//     return null;
//   }
// }
// class TestTaskVisitor_ScanDartTaskTest_test_accept extends TestTaskVisitor<Boolean> {
//   @override
//   bool visitScanDartTask(ScanDartTask task) => true;
// }
// class TestTaskVisitor_ScanDartTaskTest_test_perform_valid extends TestTaskVisitor<Boolean> {
//   InternalAnalysisContext context;
//   Source source;
//   TestTaskVisitor_ScanDartTaskTest_test_perform_valid(this.context, this.source) : super();
//   @override
//   bool visitScanDartTask(ScanDartTask task) {
//     CaughtException exception = task.exception;
//     if (exception != null) {
//       throw exception;
//     }
//     JUnitTestCase.assertNotNull(task.tokenStream);
//     EngineTestCase.assertLength(0, task.errors);
//     JUnitTestCase.assertNotNull(task.lineInfo);
//     JUnitTestCase.assertEquals(context.getModificationStamp(source), task.modificationTime);
//     JUnitTestCase.assertSame(source, task.source);
//     return true;
//   }
// }
// class UniversalCachePartitionTest extends EngineTestCase {
//   void test_contains() {
//     UniversalCachePartition partition = new UniversalCachePartition(8, null);
//     TestSource source = new TestSource();
//     JUnitTestCase.assertTrue(partition.contains(source));
//   }
//   void test_creation() {
//     JUnitTestCase.assertNotNull(new UniversalCachePartition(8, null));
//   }
//   void test_entrySet() {
//     UniversalCachePartition partition = new UniversalCachePartition(8, null);
//     TestSource source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     partition.put(source, entry);
//     JavaIterator<MapEntry<Source, SourceEntry>> entries = new JavaIterator(getMapEntrySet(partition.map));
//     JUnitTestCase.assertTrue(entries.hasNext);
//     MapEntry<Source, SourceEntry> mapEntry = entries.next();
//     JUnitTestCase.assertSame(source, mapEntry.getKey());
//     JUnitTestCase.assertSame(entry, mapEntry.getValue());
//     JUnitTestCase.assertFalse(entries.hasNext);
//   }
//   void test_get() {
//     UniversalCachePartition partition = new UniversalCachePartition(8, null);
//     TestSource source = new TestSource();
//     JUnitTestCase.assertNull(partition.get(source));
//   }
//   void test_put_noFlush() {
//     UniversalCachePartition partition = new UniversalCachePartition(8, null);
//     TestSource source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     partition.put(source, entry);
//     JUnitTestCase.assertSame(entry, partition.get(source));
//   }
//   void test_remove() {
//     UniversalCachePartition partition = new UniversalCachePartition(8, null);
//     TestSource source = new TestSource();
//     DartEntryImpl entry = new DartEntryImpl();
//     partition.put(source, entry);
//     JUnitTestCase.assertSame(entry, partition.get(source));
//     partition.remove(source);
//     JUnitTestCase.assertNull(partition.get(source));
//   }
//   void test_setMaxCacheSize() {
//     UniversalCachePartition partition = new UniversalCachePartition(8, new CacheRetentionPolicy_UniversalCachePartitionTest_test_setMaxCacheSize());
//     int size = 6;
//     for (int i = 0; i < size; i++) {
//       Source source = new TestSource.con1(FileUtilities2.createFile("/test${i}.dart"), "");
//       DartEntryImpl entry = new DartEntryImpl();
//       entry.setValue(DartEntry.PARSED_UNIT, null);
//       partition.put(source, entry);
//       partition.accessedAst(source);
//     }
//     _assertNonFlushedCount(size, partition);
//     int newSize = size - 2;
//     partition.maxCacheSize = newSize;
//     _assertNonFlushedCount(newSize, partition);
//   }
//   void test_size() {
//     UniversalCachePartition partition = new UniversalCachePartition(8, null);
//     int size = 4;
//     for (int i = 0; i < size; i++) {
//       Source source = new TestSource.con1(FileUtilities2.createFile("/test${i}.dart"), "");
//       partition.put(source, new DartEntryImpl());
//       partition.accessedAst(source);
//     }
//     JUnitTestCase.assertEquals(size, partition.size());
//   }
//   void _assertNonFlushedCount(int expectedCount, UniversalCachePartition partition) {
//     int nonFlushedCount = 0;
//     JavaIterator<MapEntry<Source, SourceEntry>> entries = new JavaIterator(getMapEntrySet(partition.map));
//     while (entries.hasNext) {
//       MapEntry<Source, SourceEntry> entry = entries.next();
//       if (entry.getValue().getState(DartEntry.PARSED_UNIT) != CacheState.FLUSHED) {
//         nonFlushedCount++;
//       }
//     }
//     JUnitTestCase.assertEquals(expectedCount, nonFlushedCount);
//   }
//   static dartSuite() {
//     _ut.group('UniversalCachePartitionTest', () {
//       _ut.test('test_contains', () {
//         final __test = new UniversalCachePartitionTest();
//         runJUnitTest(__test, __test.test_contains);
//       });
//       _ut.test('test_creation', () {
//         final __test = new UniversalCachePartitionTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_entrySet', () {
//         final __test = new UniversalCachePartitionTest();
//         runJUnitTest(__test, __test.test_entrySet);
//       });
//       _ut.test('test_get', () {
//         final __test = new UniversalCachePartitionTest();
//         runJUnitTest(__test, __test.test_get);
//       });
//       _ut.test('test_put_noFlush', () {
//         final __test = new UniversalCachePartitionTest();
//         runJUnitTest(__test, __test.test_put_noFlush);
//       });
//       _ut.test('test_remove', () {
//         final __test = new UniversalCachePartitionTest();
//         runJUnitTest(__test, __test.test_remove);
//       });
//       _ut.test('test_setMaxCacheSize', () {
//         final __test = new UniversalCachePartitionTest();
//         runJUnitTest(__test, __test.test_setMaxCacheSize);
//       });
//       _ut.test('test_size', () {
//         final __test = new UniversalCachePartitionTest();
//         runJUnitTest(__test, __test.test_size);
//       });
//     });
//   }
// }
// class WorkManagerTest extends EngineTestCase {
//   void test_addFirst() {
//     TestSource source1 = new TestSource.con1(FileUtilities2.createFile("/f1.dart"), "");
//     TestSource source2 = new TestSource.con1(FileUtilities2.createFile("/f2.dart"), "");
//     WorkManager manager = new WorkManager();
//     manager.add(source1, SourcePriority.UNKNOWN);
//     manager.addFirst(source2, SourcePriority.UNKNOWN);
//     WorkManager_WorkIterator iterator = manager.iterator();
//     JUnitTestCase.assertSame(source2, iterator.next());
//     JUnitTestCase.assertSame(source1, iterator.next());
//   }
//   void test_creation() {
//     JUnitTestCase.assertNotNull(new WorkManager());
//   }
//   void test_iterator_empty() {
//     WorkManager manager = new WorkManager();
//     WorkManager_WorkIterator iterator = manager.iterator();
//     JUnitTestCase.assertFalse(iterator.hasNext);
//     try {
//       iterator.next();
//       JUnitTestCase.fail("Expected NoSuchElementException");
//     } on NoSuchElementException catch (exception) {
//     }
//   }
//   void test_iterator_nonEmpty() {
//     TestSource source = new TestSource();
//     WorkManager manager = new WorkManager();
//     manager.add(source, SourcePriority.UNKNOWN);
//     WorkManager_WorkIterator iterator = manager.iterator();
//     JUnitTestCase.assertTrue(iterator.hasNext);
//     JUnitTestCase.assertSame(source, iterator.next());
//   }
//   void test_remove() {
//     TestSource source1 = new TestSource.con1(FileUtilities2.createFile("/f1.dart"), "");
//     TestSource source2 = new TestSource.con1(FileUtilities2.createFile("/f2.dart"), "");
//     TestSource source3 = new TestSource.con1(FileUtilities2.createFile("/f3.dart"), "");
//     WorkManager manager = new WorkManager();
//     manager.add(source1, SourcePriority.UNKNOWN);
//     manager.add(source2, SourcePriority.UNKNOWN);
//     manager.add(source3, SourcePriority.UNKNOWN);
//     manager.remove(source2);
//     WorkManager_WorkIterator iterator = manager.iterator();
//     JUnitTestCase.assertSame(source1, iterator.next());
//     JUnitTestCase.assertSame(source3, iterator.next());
//   }
//   void test_toString_empty() {
//     WorkManager manager = new WorkManager();
//     JUnitTestCase.assertNotNull(manager.toString());
//   }
//   void test_toString_nonEmpty() {
//     WorkManager manager = new WorkManager();
//     manager.add(new TestSource(), SourcePriority.HTML);
//     manager.add(new TestSource(), SourcePriority.LIBRARY);
//     manager.add(new TestSource(), SourcePriority.NORMAL_PART);
//     manager.add(new TestSource(), SourcePriority.PRIORITY_PART);
//     manager.add(new TestSource(), SourcePriority.UNKNOWN);
//     JUnitTestCase.assertNotNull(manager.toString());
//   }
//   static dartSuite() {
//     _ut.group('WorkManagerTest', () {
//       _ut.test('test_addFirst', () {
//         final __test = new WorkManagerTest();
//         runJUnitTest(__test, __test.test_addFirst);
//       });
//       _ut.test('test_creation', () {
//         final __test = new WorkManagerTest();
//         runJUnitTest(__test, __test.test_creation);
//       });
//       _ut.test('test_iterator_empty', () {
//         final __test = new WorkManagerTest();
//         runJUnitTest(__test, __test.test_iterator_empty);
//       });
//       _ut.test('test_iterator_nonEmpty', () {
//         final __test = new WorkManagerTest();
//         runJUnitTest(__test, __test.test_iterator_nonEmpty);
//       });
//       _ut.test('test_remove', () {
//         final __test = new WorkManagerTest();
//         runJUnitTest(__test, __test.test_remove);
//       });
//       _ut.test('test_toString_empty', () {
//         final __test = new WorkManagerTest();
//         runJUnitTest(__test, __test.test_toString_empty);
//       });
//       _ut.test('test_toString_nonEmpty', () {
//         final __test = new WorkManagerTest();
//         runJUnitTest(__test, __test.test_toString_nonEmpty);
//       });
//     });
//   }
// }
// main() {
//   AnalysisContextImplTest.dartSuite();
//   AnalysisOptionsImplTest.dartSuite();
//   IncrementalAnalysisCacheTest.dartSuite();
//   InstrumentedAnalysisContextImplTest.dartSuite();
//   WorkManagerTest.dartSuite();
//   AnalysisTaskTest.dartSuite();
//   BuildDartElementModelTaskTest.dartSuite();
//   GenerateDartErrorsTaskTest.dartSuite();
//   GenerateDartHintsTaskTest.dartSuite();
//   GetContentTaskTest.dartSuite();
//   IncrementalAnalysisTaskTest.dartSuite();
//   ParseDartTaskTest.dartSuite();
//   ParseHtmlTaskTest.dartSuite();
//   ResolveDartLibraryTaskTest.dartSuite();
//   ResolveDartUnitTaskTest.dartSuite();
//   ResolveHtmlTaskTest.dartSuite();
//   ScanDartTaskTest.dartSuite();
//   AnalysisCacheTest.dartSuite();
//   DartEntryImplTest.dartSuite();
//   HtmlEntryImplTest.dartSuite();
//   PartitionManagerTest.dartSuite();
//   SdkCachePartitionTest.dartSuite();
//   UniversalCachePartitionTest.dartSuite();
// }

main() {
}
