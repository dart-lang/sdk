// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.context.context_test;

import 'dart:async';

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/cancelable_future.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    show
        AnalysisContext,
        AnalysisContextStatistics,
        AnalysisDelta,
        AnalysisEngine,
        AnalysisErrorInfo,
        AnalysisLevel,
        AnalysisNotScheduledError,
        AnalysisOptions,
        AnalysisOptionsImpl,
        AnalysisResult,
        CacheState,
        ChangeNotice,
        ChangeSet,
        IncrementalAnalysisCache,
        TimestampedData;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/html.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';
import 'package:html/dom.dart' show Document;
import 'package:unittest/unittest.dart';
import 'package:watcher/src/utils.dart';

import '../../generated/engine_test.dart';
import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import 'abstract_context.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisContextImplTest);
  runReflectiveTests(LimitedInvalidateTest);
}

@reflectiveTest
class AnalysisContextImplTest extends AbstractContextTest {
  Future fail_implicitAnalysisEvents_removed() async {
    AnalyzedSourcesListener listener = new AnalyzedSourcesListener();
    context.implicitAnalysisEvents.listen(listener.onData);
    //
    // Create a file that references an file that is not explicitly being
    // analyzed and fully analyze it. Ensure that the listener is told about
    // the implicitly analyzed file.
    //
    Source sourceA = newSource('/a.dart', "library a; import 'b.dart';");
    Source sourceB = newSource('/b.dart', "library b;");
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(sourceA);
    context.applyChanges(changeSet);
    context.computeErrors(sourceA);
    await pumpEventQueue();
    listener.expectAnalyzed(sourceB);
    //
    // Remove the reference and ensure that the listener is told that we're no
    // longer implicitly analyzing the file.
    //
    context.setContents(sourceA, "library a;");
    context.computeErrors(sourceA);
    await pumpEventQueue();
    listener.expectNotAnalyzed(sourceB);
  }

  void fail_performAnalysisTask_importedLibraryDelete_html() {
    // NOTE: This was failing before converting to the new task model.
    Source htmlSource = addSource("/page.html", r'''
<html><body><script type="application/dart">
  import 'libB.dart';
  main() {print('hello dart');}
</script></body></html>''');
    Source libBSource = addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    context.computeErrors(htmlSource);
    expect(
        context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull,
        reason: "libB resolved 1");
    expect(!_hasAnalysisErrorWithErrorSeverity(context.getErrors(htmlSource)),
        isTrue, reason: "htmlSource doesn't have errors");
    // remove libB.dart content and analyze
    context.setContents(libBSource, null);
    _analyzeAll_assertFinished();
    context.computeErrors(htmlSource);
    AnalysisErrorInfo errors = context.getErrors(htmlSource);
    expect(_hasAnalysisErrorWithErrorSeverity(errors), isTrue,
        reason: "htmlSource has an error");
  }

  void fail_recordLibraryElements() {
    fail("Implement this");
  }

  @override
  void tearDown() {
    context = null;
    sourceFactory = null;
    super.tearDown();
  }

  Future test_applyChanges_add() {
    SourcesChangedListener listener = new SourcesChangedListener();
    context.onSourcesChanged.listen(listener.onData);
    expect(context.sourcesNeedingProcessing, isEmpty);
    Source source = newSource('/test.dart');
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    expect(context.sourcesNeedingProcessing, contains(source));
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertNoMoreEvents();
    });
  }

  Future test_applyChanges_change() {
    SourcesChangedListener listener = new SourcesChangedListener();
    context.onSourcesChanged.listen(listener.onData);
    expect(context.sourcesNeedingProcessing, isEmpty);
    Source source = newSource('/test.dart');
    ChangeSet changeSet1 = new ChangeSet();
    changeSet1.addedSource(source);
    context.applyChanges(changeSet1);
    expect(context.sourcesNeedingProcessing, contains(source));
    Source source2 = newSource('/test2.dart');
    ChangeSet changeSet2 = new ChangeSet();
    changeSet2.addedSource(source2);
    changeSet2.changedSource(source);
    context.applyChanges(changeSet2);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true, changedSources: [source]);
      listener.assertNoMoreEvents();
    });
  }

  Future test_applyChanges_change_content() {
    SourcesChangedListener listener = new SourcesChangedListener();
    context.onSourcesChanged.listen(listener.onData);
    expect(context.sourcesNeedingProcessing, isEmpty);
    Source source = newSource('/test.dart');
    ChangeSet changeSet1 = new ChangeSet();
    changeSet1.addedSource(source);
    context.applyChanges(changeSet1);
    expect(context.sourcesNeedingProcessing, contains(source));
    Source source2 = newSource('/test2.dart');
    ChangeSet changeSet2 = new ChangeSet();
    changeSet2.addedSource(source2);
    changeSet2.changedContent(source, 'library test;');
    context.applyChanges(changeSet2);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true, changedSources: [source]);
      listener.assertNoMoreEvents();
    });
  }

  void test_applyChanges_change_flush_element() {
    Source librarySource = addSource("/lib.dart", r'''
library lib;
int a = 0;''');
    expect(context.computeLibraryElement(librarySource), isNotNull);
    context.setContents(librarySource, r'''
library lib;
int aa = 0;''');
    expect(context.getLibraryElement(librarySource), isNull);
  }

  Future test_applyChanges_change_multiple() {
    SourcesChangedListener listener = new SourcesChangedListener();
    context.onSourcesChanged.listen(listener.onData);
    String libraryContents1 = r'''
library lib;
part 'part.dart';
int a = 0;''';
    Source librarySource = addSource("/lib.dart", libraryContents1);
    String partContents1 = r'''
part of lib;
int b = a;''';
    Source partSource = addSource("/part.dart", partContents1);
    context.computeLibraryElement(librarySource);
    String libraryContents2 = r'''
library lib;
part 'part.dart';
int aa = 0;''';
    context.setContents(librarySource, libraryContents2);
    String partContents2 = r'''
part of lib;
int b = aa;''';
    context.setContents(partSource, partContents2);
    context.computeLibraryElement(librarySource);
    CompilationUnit libraryUnit =
        context.resolveCompilationUnit2(librarySource, librarySource);
    expect(libraryUnit, isNotNull);
    CompilationUnit partUnit =
        context.resolveCompilationUnit2(partSource, librarySource);
    expect(partUnit, isNotNull);
    TopLevelVariableDeclaration declaration =
        libraryUnit.declarations[0] as TopLevelVariableDeclaration;
    Element declarationElement = declaration.variables.variables[0].element;
    TopLevelVariableDeclaration use =
        partUnit.declarations[0] as TopLevelVariableDeclaration;
    Element useElement = (use.variables.variables[
        0].initializer as SimpleIdentifier).staticElement;
    expect((useElement as PropertyAccessorElement).variable,
        same(declarationElement));
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [librarySource]);
      listener.assertEvent(changedSources: [partSource]);
      listener.assertNoMoreEvents();
    });
  }

  Future test_applyChanges_change_range() {
    SourcesChangedListener listener = new SourcesChangedListener();
    context.onSourcesChanged.listen(listener.onData);
    expect(context.sourcesNeedingProcessing, isEmpty);
    Source source = newSource('/test.dart');
    ChangeSet changeSet1 = new ChangeSet();
    changeSet1.addedSource(source);
    context.applyChanges(changeSet1);
    expect(context.sourcesNeedingProcessing, contains(source));
    Source source2 = newSource('/test2.dart');
    ChangeSet changeSet2 = new ChangeSet();
    changeSet2.addedSource(source2);
    changeSet2.changedRange(source, 'library test;', 0, 0, 13);
    context.applyChanges(changeSet2);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true, changedSources: [source]);
      listener.assertNoMoreEvents();
    });
  }

  void test_applyChanges_empty() {
    context.applyChanges(new ChangeSet());
    expect(context.performAnalysisTask().changeNotices, isNull);
  }

  void test_applyChanges_overriddenSource() {
    // Note: addSource adds the source to the contentCache.
    Source source = addSource("/test.dart", "library test;");
    context.computeErrors(source);
    while (!context.sourcesNeedingProcessing.isEmpty) {
      context.performAnalysisTask();
    }
    // Adding the source as a changedSource should have no effect since
    // it is already overridden in the content cache.
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedSource(source);
    context.applyChanges(changeSet);
    expect(context.sourcesNeedingProcessing, hasLength(0));
  }

  Future test_applyChanges_remove() {
    SourcesChangedListener listener = new SourcesChangedListener();
    context.onSourcesChanged.listen(listener.onData);
    String libAContents = r'''
library libA;
import 'libB.dart';''';
    Source libA = addSource("/libA.dart", libAContents);
    String libBContents = "library libB;";
    Source libB = addSource("/libB.dart", libBContents);
    LibraryElement libAElement = context.computeLibraryElement(libA);
    expect(libAElement, isNotNull);
    List<LibraryElement> importedLibraries = libAElement.importedLibraries;
    expect(importedLibraries, hasLength(2));
    context.computeErrors(libA);
    context.computeErrors(libB);
    expect(context.sourcesNeedingProcessing, hasLength(0));
    context.setContents(libB, null);
    _removeSource(libB);
    List<Source> sources = context.sourcesNeedingProcessing;
    expect(sources, hasLength(1));
    expect(sources[0], same(libA));
    libAElement = context.computeLibraryElement(libA);
    importedLibraries = libAElement.importedLibraries;
    expect(importedLibraries, hasLength(1));
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesRemovedOrDeleted: true);
      listener.assertNoMoreEvents();
    });
  }

  /**
   * IDEA uses the following scenario:
   * 1. Add overlay.
   * 2. Change overlay.
   * 3. If the contents of the document buffer is the same as the contents
   *    of the file, remove overlay.
   * So, we need to try to use incremental resolution for removing overlays too.
   */
  void test_applyChanges_remove_incremental() {
    MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
    Source source = resourceProvider.newFile('/test.dart', r'''
main() {
  print(1);
}
''').createSource();
    context.analysisOptions = new AnalysisOptionsImpl()..incremental = true;
    context.applyChanges(new ChangeSet()..addedSource(source));
    // remember compilation unit
    _analyzeAll_assertFinished();
    CompilationUnit unit = context.getResolvedCompilationUnit2(source, source);
    // add overlay
    context.setContents(source, r'''
main() {
  print(12);
}
''');
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(source, source), unit);
    // remove overlay
    context.setContents(source, null);
    context.validateCacheConsistency();
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(source, source), unit);
  }

  Future test_applyChanges_removeContainer() {
    SourcesChangedListener listener = new SourcesChangedListener();
    context.onSourcesChanged.listen(listener.onData);
    String libAContents = r'''
library libA;
import 'libB.dart';''';
    Source libA = addSource("/libA.dart", libAContents);
    String libBContents = "library libB;";
    Source libB = addSource("/libB.dart", libBContents);
    context.computeLibraryElement(libA);
    context.computeErrors(libA);
    context.computeErrors(libB);
    expect(context.sourcesNeedingProcessing, hasLength(0));
    ChangeSet changeSet = new ChangeSet();
    SourceContainer removedContainer =
        new _AnalysisContextImplTest_test_applyChanges_removeContainer(libB);
    changeSet.removedContainer(removedContainer);
    context.applyChanges(changeSet);
    List<Source> sources = context.sourcesNeedingProcessing;
    expect(sources, hasLength(1));
    expect(sources[0], same(libA));
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesRemovedOrDeleted: true);
      listener.assertNoMoreEvents();
    });
  }

  void test_computeDocumentationComment_block() {
    String comment = "/** Comment */";
    Source source = addSource("/test.dart", """
$comment
class A {}""");
    LibraryElement libraryElement = context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    expect(context.computeDocumentationComment(classElement), comment);
  }

  void test_computeDocumentationComment_none() {
    Source source = addSource("/test.dart", "class A {}");
    LibraryElement libraryElement = context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    expect(context.computeDocumentationComment(classElement), isNull);
  }

  void test_computeDocumentationComment_null() {
    expect(context.computeDocumentationComment(null), isNull);
  }

  void test_computeDocumentationComment_singleLine_multiple_EOL_n() {
    String comment = "/// line 1\n/// line 2\n/// line 3\n";
    Source source = addSource("/test.dart", "${comment}class A {}");
    LibraryElement libraryElement = context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    String actual = context.computeDocumentationComment(classElement);
    expect(actual, "/// line 1\n/// line 2\n/// line 3");
  }

  void test_computeDocumentationComment_singleLine_multiple_EOL_rn() {
    String comment = "/// line 1\r\n/// line 2\r\n/// line 3\r\n";
    Source source = addSource("/test.dart", "${comment}class A {}");
    LibraryElement libraryElement = context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    String actual = context.computeDocumentationComment(classElement);
    expect(actual, "/// line 1\n/// line 2\n/// line 3");
  }

  void test_computeErrors_dart_none() {
    Source source = addSource("/lib.dart", "library lib;");
    List<AnalysisError> errors = context.computeErrors(source);
    expect(errors, hasLength(0));
  }

  void test_computeErrors_dart_part() {
    Source librarySource =
        addSource("/lib.dart", "library lib; part 'part.dart';");
    Source partSource = addSource("/part.dart", "part of 'lib';");
    context.parseCompilationUnit(librarySource);
    List<AnalysisError> errors = context.computeErrors(partSource);
    expect(errors, isNotNull);
    expect(errors.length > 0, isTrue);
  }

  void test_computeErrors_dart_some() {
    Source source = addSource("/lib.dart", "library 'lib';");
    List<AnalysisError> errors = context.computeErrors(source);
    expect(errors, isNotNull);
    expect(errors.length > 0, isTrue);
  }

  void test_computeErrors_html_none() {
    Source source = addSource("/test.html", "<!DOCTYPE html><html></html>");
    List<AnalysisError> errors = context.computeErrors(source);
    expect(errors, hasLength(0));
  }

  void test_computeExportedLibraries_none() {
    Source source = addSource("/test.dart", "library test;");
    expect(context.computeExportedLibraries(source), hasLength(0));
  }

  void test_computeExportedLibraries_some() {
    //    addSource("/lib1.dart", "library lib1;");
    //    addSource("/lib2.dart", "library lib2;");
    Source source = addSource(
        "/test.dart", "library test; export 'lib1.dart'; export 'lib2.dart';");
    expect(context.computeExportedLibraries(source), hasLength(2));
  }

  void test_computeImportedLibraries_none() {
    Source source = addSource("/test.dart", "library test;");
    expect(context.computeImportedLibraries(source), hasLength(0));
  }

  void test_computeImportedLibraries_some() {
    Source source = addSource(
        "/test.dart", "library test; import 'lib1.dart'; import 'lib2.dart';");
    expect(context.computeImportedLibraries(source), hasLength(2));
  }

  void test_computeKindOf_html() {
    Source source = addSource("/test.html", "");
    expect(context.computeKindOf(source), same(SourceKind.HTML));
  }

  void test_computeKindOf_library() {
    Source source = addSource("/test.dart", "library lib;");
    expect(context.computeKindOf(source), same(SourceKind.LIBRARY));
  }

  void test_computeKindOf_libraryAndPart() {
    Source source = addSource("/test.dart", "library lib; part of lib;");
    expect(context.computeKindOf(source), same(SourceKind.LIBRARY));
  }

  void test_computeKindOf_part() {
    Source source = addSource("/test.dart", "part of lib;");
    expect(context.computeKindOf(source), same(SourceKind.PART));
  }

  void test_computeLibraryElement() {
    Source source = addSource("/test.dart", "library lib;");
    LibraryElement element = context.computeLibraryElement(source);
    expect(element, isNotNull);
  }

  void test_computeLineInfo_dart() {
    Source source = addSource("/test.dart", r'''
library lib;

main() {}''');
    LineInfo info = context.computeLineInfo(source);
    expect(info, isNotNull);
  }

  void test_computeLineInfo_html() {
    Source source = addSource("/test.html", r'''
<html>
  <body>
    <h1>A</h1>
  </body>
</html>''');
    LineInfo info = context.computeLineInfo(source);
    expect(info, isNotNull);
  }

  Future test_computeResolvedCompilationUnitAsync() {
    Source source = addSource("/lib.dart", "library lib;");
    // Complete all pending analysis tasks and flush the AST so that it won't
    // be available immediately.
    _performPendingAnalysisTasks();
    _flushAst(source);
    bool completed = false;
    context
        .computeResolvedCompilationUnitAsync(source, source)
        .then((CompilationUnit unit) {
      expect(unit, isNotNull);
      completed = true;
    });
    return pumpEventQueue().then((_) {
      expect(completed, isFalse);
      _performPendingAnalysisTasks();
    }).then((_) => pumpEventQueue()).then((_) {
      expect(completed, isTrue);
    });
  }

  Future test_computeResolvedCompilationUnitAsync_afterDispose() {
    Source source = addSource("/lib.dart", "library lib;");
    // Complete all pending analysis tasks and flush the AST so that it won't
    // be available immediately.
    _performPendingAnalysisTasks();
    _flushAst(source);
    // Dispose of the context.
    context.dispose();
    // Any attempt to start an asynchronous computation should return a future
    // which completes with error.
    CancelableFuture<CompilationUnit> future =
        context.computeResolvedCompilationUnitAsync(source, source);
    bool completed = false;
    future.then((CompilationUnit unit) {
      fail('Future should have completed with error');
    }, onError: (error) {
      expect(error, new isInstanceOf<AnalysisNotScheduledError>());
      completed = true;
    });
    return pumpEventQueue().then((_) {
      expect(completed, isTrue);
    });
  }

  Future test_computeResolvedCompilationUnitAsync_cancel() {
    Source source = addSource("/lib.dart", "library lib;");
    // Complete all pending analysis tasks and flush the AST so that it won't
    // be available immediately.
    _performPendingAnalysisTasks();
    _flushAst(source);
    CancelableFuture<CompilationUnit> future =
        context.computeResolvedCompilationUnitAsync(source, source);
    bool completed = false;
    future.then((CompilationUnit unit) {
      fail('Future should have been canceled');
    }, onError: (error) {
      expect(error, new isInstanceOf<FutureCanceledError>());
      completed = true;
    });
    expect(completed, isFalse);
    expect(context.pendingFutureSources_forTesting, isNotEmpty);
    future.cancel();
    expect(context.pendingFutureSources_forTesting, isEmpty);
    return pumpEventQueue().then((_) {
      expect(completed, isTrue);
      expect(context.pendingFutureSources_forTesting, isEmpty);
    });
  }

  Future test_computeResolvedCompilationUnitAsync_dispose() {
    Source source = addSource("/lib.dart", "library lib;");
    // Complete all pending analysis tasks and flush the AST so that it won't
    // be available immediately.
    _performPendingAnalysisTasks();
    _flushAst(source);
    bool completed = false;
    CancelableFuture<CompilationUnit> future =
        context.computeResolvedCompilationUnitAsync(source, source);
    future.then((CompilationUnit unit) {
      fail('Future should have completed with error');
    }, onError: (error) {
      expect(error, new isInstanceOf<AnalysisNotScheduledError>());
      completed = true;
    });
    expect(completed, isFalse);
    expect(context.pendingFutureSources_forTesting, isNotEmpty);
    // Disposing of the context should cause all pending futures to complete
    // with AnalysisNotScheduled, so that no clients are left hanging.
    context.dispose();
    expect(context.pendingFutureSources_forTesting, isEmpty);
    return pumpEventQueue().then((_) {
      expect(completed, isTrue);
      expect(context.pendingFutureSources_forTesting, isEmpty);
    });
  }

  Future test_computeResolvedCompilationUnitAsync_noCacheEntry() {
    Source librarySource = addSource("/lib.dart", "library lib;");
    Source partSource = addSource("/part.dart", "part of foo;");
    bool completed = false;
    context
        .computeResolvedCompilationUnitAsync(partSource, librarySource)
        .then((CompilationUnit unit) {
      expect(unit, isNotNull);
      completed = true;
    });
    return pumpEventQueue().then((_) {
      expect(completed, isFalse);
      _performPendingAnalysisTasks();
    }).then((_) => pumpEventQueue()).then((_) {
      expect(completed, isTrue);
    });
  }

  void test_dispose() {
    expect(context.isDisposed, isFalse);
    context.dispose();
    expect(context.isDisposed, isTrue);
  }

  void test_ensureResolvedDartUnits_definingUnit_hasResolved() {
    Source source = addSource('/test.dart', '');
    LibrarySpecificUnit libTarget = new LibrarySpecificUnit(source, source);
    analysisDriver.computeResult(libTarget, RESOLVED_UNIT);
    CompilationUnit unit =
        context.getCacheEntry(libTarget).getValue(RESOLVED_UNIT);
    List<CompilationUnit> units = context.ensureResolvedDartUnits(source);
    expect(units, unorderedEquals([unit]));
  }

  void test_ensureResolvedDartUnits_definingUnit_notResolved() {
    Source source = addSource('/test.dart', '');
    LibrarySpecificUnit libTarget = new LibrarySpecificUnit(source, source);
    analysisDriver.computeResult(libTarget, RESOLVED_UNIT);
    // flush
    context.getCacheEntry(libTarget).setState(
        RESOLVED_UNIT, CacheState.FLUSHED);
    // schedule recomputing
    List<CompilationUnit> units = context.ensureResolvedDartUnits(source);
    expect(units, isNull);
    // should be the next result to compute
    TargetedResult nextResult = context.dartWorkManager.getNextResult();
    expect(nextResult.target, libTarget);
    expect(nextResult.result, RESOLVED_UNIT);
  }

  void test_ensureResolvedDartUnits_partUnit_hasResolved() {
    Source libSource1 = addSource('/lib1.dart', r'''
library lib;
part 'part.dart';
''');
    Source libSource2 = addSource('/lib2.dart', r'''
library lib;
part 'part.dart';
''');
    Source partSource = addSource('/part.dart', r'''
part of lib;
''');
    LibrarySpecificUnit partTarget1 =
        new LibrarySpecificUnit(libSource1, partSource);
    LibrarySpecificUnit partTarget2 =
        new LibrarySpecificUnit(libSource2, partSource);
    analysisDriver.computeResult(partTarget1, RESOLVED_UNIT);
    analysisDriver.computeResult(partTarget2, RESOLVED_UNIT);
    CompilationUnit unit1 =
        context.getCacheEntry(partTarget1).getValue(RESOLVED_UNIT);
    CompilationUnit unit2 =
        context.getCacheEntry(partTarget2).getValue(RESOLVED_UNIT);
    List<CompilationUnit> units = context.ensureResolvedDartUnits(partSource);
    expect(units, unorderedEquals([unit1, unit2]));
  }

  void test_ensureResolvedDartUnits_partUnit_notResolved() {
    Source libSource1 = addSource('/lib1.dart', r'''
library lib;
part 'part.dart';
''');
    Source libSource2 = addSource('/lib2.dart', r'''
library lib;
part 'part.dart';
''');
    Source partSource = addSource('/part.dart', r'''
part of lib;
''');
    LibrarySpecificUnit partTarget1 =
        new LibrarySpecificUnit(libSource1, partSource);
    LibrarySpecificUnit partTarget2 =
        new LibrarySpecificUnit(libSource2, partSource);
    analysisDriver.computeResult(partTarget1, RESOLVED_UNIT);
    analysisDriver.computeResult(partTarget2, RESOLVED_UNIT);
    // flush
    context.getCacheEntry(partTarget1).setState(
        RESOLVED_UNIT, CacheState.FLUSHED);
    context.getCacheEntry(partTarget2).setState(
        RESOLVED_UNIT, CacheState.FLUSHED);
    // schedule recomputing
    List<CompilationUnit> units = context.ensureResolvedDartUnits(partSource);
    expect(units, isNull);
    // should be the next result to compute
    TargetedResult nextResult = context.dartWorkManager.getNextResult();
    expect(nextResult.target, anyOf(partTarget1, partTarget2));
    expect(nextResult.result, RESOLVED_UNIT);
  }

  void test_exists_false() {
    TestSource source = new TestSource();
    source.exists2 = false;
    expect(context.exists(source), isFalse);
  }

  void test_exists_null() {
    expect(context.exists(null), isFalse);
  }

  void test_exists_overridden() {
    Source source = new TestSource();
    context.setContents(source, "");
    expect(context.exists(source), isTrue);
  }

  void test_exists_true() {
    expect(context.exists(new AnalysisContextImplTest_Source_exists_true()),
        isTrue);
  }

  void test_getAnalysisOptions() {
    expect(context.analysisOptions, isNotNull);
  }

  void test_getContents_fromSource() {
    String content = "library lib;";
    TimestampedData<String> contents =
        context.getContents(new TestSource('/test.dart', content));
    expect(contents.data.toString(), content);
  }

  void test_getContents_overridden() {
    String content = "library lib;";
    Source source = new TestSource();
    context.setContents(source, content);
    TimestampedData<String> contents = context.getContents(source);
    expect(contents.data.toString(), content);
  }

  void test_getContents_unoverridden() {
    String content = "library lib;";
    Source source = new TestSource('/test.dart', content);
    context.setContents(source, "part of lib;");
    context.setContents(source, null);
    TimestampedData<String> contents = context.getContents(source);
    expect(contents.data.toString(), content);
  }

  void test_getDeclaredVariables() {
    expect(context.declaredVariables, isNotNull);
  }

  void test_getElement() {
    LibraryElement core =
        context.computeLibraryElement(sourceFactory.forUri("dart:core"));
    expect(core, isNotNull);
    ClassElement classObject =
        _findClass(core.definingCompilationUnit, "Object");
    expect(classObject, isNotNull);
    ElementLocation location = classObject.location;
    Element element = context.getElement(location);
    expect(element, same(classObject));
  }

  void test_getElement_constructor_named() {
    Source source = addSource("/lib.dart", r'''
class A {
  A.named() {}
}''');
    _analyzeAll_assertFinished();
    LibraryElement library = context.computeLibraryElement(source);
    ClassElement classA = _findClass(library.definingCompilationUnit, "A");
    ConstructorElement constructor = classA.constructors[0];
    ElementLocation location = constructor.location;
    Element element = context.getElement(location);
    expect(element, same(constructor));
  }

  void test_getElement_constructor_unnamed() {
    Source source = addSource("/lib.dart", r'''
class A {
  A() {}
}''');
    _analyzeAll_assertFinished();
    LibraryElement library = context.computeLibraryElement(source);
    ClassElement classA = _findClass(library.definingCompilationUnit, "A");
    ConstructorElement constructor = classA.constructors[0];
    ElementLocation location = constructor.location;
    Element element = context.getElement(location);
    expect(element, same(constructor));
  }

  void test_getElement_enum() {
    Source source = addSource('/test.dart', 'enum MyEnum {A, B, C}');
    _analyzeAll_assertFinished();
    LibraryElement library = context.computeLibraryElement(source);
    ClassElement myEnum = library.definingCompilationUnit.getEnum('MyEnum');
    ElementLocation location = myEnum.location;
    Element element = context.getElement(location);
    expect(element, same(myEnum));
  }

  void test_getErrors_dart_none() {
    Source source = addSource("/lib.dart", "library lib;");
    var errorInfo = context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, hasLength(0));
    context.computeErrors(source);
    errors = errorInfo.errors;
    expect(errors, hasLength(0));
  }

  void test_getErrors_dart_some() {
    Source source = addSource("/lib.dart", "library 'lib';");
    var errorInfo = context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, hasLength(0));
    errors = context.computeErrors(source);
    expect(errors, hasLength(1));
  }

  void test_getErrors_html_none() {
    Source source = addSource("/test.html", "<html></html>");
    AnalysisErrorInfo errorInfo = context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, hasLength(0));
    context.computeErrors(source);
    errors = errorInfo.errors;
    expect(errors, hasLength(0));
  }

  void test_getErrors_html_some() {
    Source source = addSource("/test.html", r'''
<html><head>
<script type='application/dart' src='test.dart'/>
</head></html>''');
    AnalysisErrorInfo errorInfo = context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, hasLength(0));
    errors = context.computeErrors(source);
    expect(errors, hasLength(3));
  }

  void test_getHtmlFilesReferencing_html() {
    Source htmlSource = addSource("/test.html", r'''
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource = addSource("/test.dart", "library lib;");
    Source secondHtmlSource = addSource("/test.html", "<html></html>");
    context.computeLibraryElement(librarySource);
    List<Source> result = context.getHtmlFilesReferencing(secondHtmlSource);
    expect(result, hasLength(0));
    context.parseHtmlDocument(htmlSource);
    result = context.getHtmlFilesReferencing(secondHtmlSource);
    expect(result, hasLength(0));
  }

  void test_getHtmlFilesReferencing_library() {
    Source htmlSource = addSource("/test.html", r'''
<!DOCTYPE html>
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource = addSource("/test.dart", "library lib;");
    context.computeLibraryElement(librarySource);
    List<Source> result = context.getHtmlFilesReferencing(librarySource);
    expect(result, hasLength(0));
    // Indirectly force the data to be computed.
    context.computeErrors(htmlSource);
    result = context.getHtmlFilesReferencing(librarySource);
    expect(result, hasLength(1));
    expect(result[0], htmlSource);
  }

  void test_getHtmlFilesReferencing_part() {
    Source htmlSource = addSource("/test.html", r'''
<!DOCTYPE html>
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource =
        addSource("/test.dart", "library lib; part 'part.dart';");
    Source partSource = addSource("/part.dart", "part of lib;");
    context.computeLibraryElement(librarySource);
    List<Source> result = context.getHtmlFilesReferencing(partSource);
    expect(result, hasLength(0));
    // Indirectly force the data to be computed.
    context.computeErrors(htmlSource);
    result = context.getHtmlFilesReferencing(partSource);
    expect(result, hasLength(1));
    expect(result[0], htmlSource);
  }

  void test_getHtmlSources() {
    List<Source> sources = context.htmlSources;
    expect(sources, hasLength(0));
    Source source = addSource("/test.html", "");
    sources = context.htmlSources;
    expect(sources, hasLength(1));
    expect(sources[0], source);
  }

  void test_getKindOf_html() {
    Source source = addSource("/test.html", "");
    expect(context.getKindOf(source), same(SourceKind.HTML));
  }

  void test_getKindOf_library() {
    Source source = addSource("/test.dart", "library lib;");
    expect(context.getKindOf(source), same(SourceKind.UNKNOWN));
    context.computeKindOf(source);
    expect(context.getKindOf(source), same(SourceKind.LIBRARY));
  }

  void test_getKindOf_part() {
    Source source = addSource("/test.dart", "part of lib;");
    expect(context.getKindOf(source), same(SourceKind.UNKNOWN));
    context.computeKindOf(source);
    expect(context.getKindOf(source), same(SourceKind.PART));
  }

  void test_getKindOf_unknown() {
    Source source = addSource("/test.css", "");
    expect(context.getKindOf(source), same(SourceKind.UNKNOWN));
  }

  void test_getLaunchableClientLibrarySources_doesNotImportHtml() {
    Source source = addSource("/test.dart", r'''
main() {}''');
    context.computeLibraryElement(source);
    List<Source> sources = context.launchableClientLibrarySources;
    expect(sources, isEmpty);
  }

  void test_getLaunchableClientLibrarySources_importsHtml_explicitly() {
    List<Source> sources = context.launchableClientLibrarySources;
    expect(sources, isEmpty);
    Source source = addSource("/test.dart", r'''
import 'dart:html';
main() {}''');
    context.computeLibraryElement(source);
    sources = context.launchableClientLibrarySources;
    expect(sources, unorderedEquals([source]));
  }

  void test_getLaunchableClientLibrarySources_importsHtml_implicitly() {
    List<Source> sources = context.launchableClientLibrarySources;
    expect(sources, isEmpty);
    addSource("/a.dart", r'''
import 'dart:html';
''');
    Source source = addSource("/test.dart", r'''
import 'a.dart';
main() {}''');
    context.computeLibraryElement(source);
    sources = context.launchableClientLibrarySources;
    expect(sources, unorderedEquals([source]));
  }

  void test_getLaunchableClientLibrarySources_importsHtml_implicitly2() {
    List<Source> sources = context.launchableClientLibrarySources;
    expect(sources, isEmpty);
    addSource("/a.dart", r'''
export 'dart:html';
''');
    Source source = addSource("/test.dart", r'''
import 'a.dart';
main() {}''');
    context.computeLibraryElement(source);
    sources = context.launchableClientLibrarySources;
    expect(sources, unorderedEquals([source]));
  }

  void test_getLaunchableServerLibrarySources() {
    expect(context.launchableServerLibrarySources, isEmpty);
    Source source = addSource("/test.dart", "main() {}");
    context.computeLibraryElement(source);
    expect(context.launchableServerLibrarySources, unorderedEquals([source]));
  }

  void test_getLaunchableServerLibrarySources_importsHtml_explicitly() {
    Source source = addSource("/test.dart", r'''
import 'dart:html';
main() {}
''');
    context.computeLibraryElement(source);
    expect(context.launchableServerLibrarySources, isEmpty);
  }

  void test_getLaunchableServerLibrarySources_importsHtml_implicitly() {
    addSource("/imports_html.dart", r'''
import 'dart:html';
''');
    Source source = addSource("/test.dart", r'''
import 'imports_html.dart';
main() {}''');
    context.computeLibraryElement(source);
    expect(context.launchableServerLibrarySources, isEmpty);
  }

  void test_getLaunchableServerLibrarySources_noMain() {
    Source source = addSource("/test.dart", '');
    context.computeLibraryElement(source);
    expect(context.launchableServerLibrarySources, isEmpty);
  }

  void test_getLibrariesContaining() {
    Source librarySource = addSource("/lib.dart", r'''
library lib;
part 'part.dart';''');
    Source partSource = addSource("/part.dart", "part of lib;");
    context.computeLibraryElement(librarySource);
    List<Source> result = context.getLibrariesContaining(librarySource);
    expect(result, hasLength(1));
    expect(result[0], librarySource);
    result = context.getLibrariesContaining(partSource);
    expect(result, hasLength(1));
    expect(result[0], librarySource);
  }

  void test_getLibrariesDependingOn() {
    Source libASource = addSource("/libA.dart", "library libA;");
    addSource("/libB.dart", "library libB;");
    Source lib1Source = addSource("/lib1.dart", r'''
library lib1;
import 'libA.dart';
export 'libB.dart';''');
    Source lib2Source = addSource("/lib2.dart", r'''
library lib2;
import 'libB.dart';
export 'libA.dart';''');
    context.computeLibraryElement(lib1Source);
    context.computeLibraryElement(lib2Source);
    List<Source> result = context.getLibrariesDependingOn(libASource);
    expect(result, unorderedEquals([lib1Source, lib2Source]));
  }

  void test_getLibrariesReferencedFromHtml() {
    Source htmlSource = addSource("/test.html", r'''
<!DOCTYPE html>
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource = addSource("/test.dart", "library lib;");
    context.computeLibraryElement(librarySource);
    // Indirectly force the data to be computed.
    context.computeErrors(htmlSource);
    List<Source> result = context.getLibrariesReferencedFromHtml(htmlSource);
    expect(result, hasLength(1));
    expect(result[0], librarySource);
  }

  void test_getLibrariesReferencedFromHtml_none() {
    Source htmlSource = addSource("/test.html", r'''
<html><head>
<script type='application/dart' src='test.js'/>
</head></html>''');
    addSource("/test.dart", "library lib;");
    context.parseHtmlDocument(htmlSource);
    List<Source> result = context.getLibrariesReferencedFromHtml(htmlSource);
    expect(result, hasLength(0));
  }

  void test_getLibraryElement() {
    Source source = addSource("/test.dart", "library lib;");
    LibraryElement element = context.getLibraryElement(source);
    expect(element, isNull);
    context.computeLibraryElement(source);
    element = context.getLibraryElement(source);
    expect(element, isNotNull);
  }

  void test_getLibrarySources() {
    List<Source> sources = context.librarySources;
    int originalLength = sources.length;
    Source source = addSource("/test.dart", "library lib;");
    context.computeKindOf(source);
    sources = context.librarySources;
    expect(sources, hasLength(originalLength + 1));
    for (Source returnedSource in sources) {
      if (returnedSource == source) {
        return;
      }
    }
    fail("The added source was not in the list of library sources");
  }

  void test_getLineInfo() {
    Source source = addSource("/test.dart", r'''
library lib;

main() {}''');
    LineInfo info = context.getLineInfo(source);
    expect(info, isNull);
    context.parseCompilationUnit(source);
    info = context.getLineInfo(source);
    expect(info, isNotNull);
  }

  void test_getModificationStamp_fromSource() {
    int stamp = 42;
    expect(context.getModificationStamp(
        new AnalysisContextImplTest_Source_getModificationStamp_fromSource(
            stamp)), stamp);
  }

  void test_getModificationStamp_overridden() {
    int stamp = 42;
    Source source =
        new AnalysisContextImplTest_Source_getModificationStamp_overridden(
            stamp);
    context.setContents(source, "");
    expect(stamp != context.getModificationStamp(source), isTrue);
  }

  void test_getPublicNamespace_element() {
    Source source = addSource("/test.dart", "class A {}");
    LibraryElement library = context.computeLibraryElement(source);
    expect(library, isNotNull);
    Namespace namespace = context.getPublicNamespace(library);
    expect(namespace, isNotNull);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, namespace.get("A"));
  }

  void test_getResolvedCompilationUnit_library() {
    Source source = addSource("/lib.dart", "library libb;");
    LibraryElement library = context.computeLibraryElement(source);
    context.computeErrors(source); // Force the resolved unit to be built.
    expect(context.getResolvedCompilationUnit(source, library), isNotNull);
    context.setContents(source, "library lib;");
    expect(context.getResolvedCompilationUnit(source, library), isNull);
  }

  void test_getResolvedCompilationUnit_library_null() {
    Source source = addSource("/lib.dart", "library lib;");
    expect(context.getResolvedCompilationUnit(source, null), isNull);
  }

  void test_getResolvedCompilationUnit_source_dart() {
    Source source = addSource("/lib.dart", "library lib;");
    expect(context.getResolvedCompilationUnit2(source, source), isNull);
    context.resolveCompilationUnit2(source, source);
    expect(context.getResolvedCompilationUnit2(source, source), isNotNull);
  }

  void test_getResolvedCompilationUnit_source_html() {
    Source source = addSource("/test.html", "<html></html>");
    expect(context.getResolvedCompilationUnit2(source, source), isNull);
    expect(context.resolveCompilationUnit2(source, source), isNull);
    expect(context.getResolvedCompilationUnit2(source, source), isNull);
  }

  void test_getSourceFactory() {
    expect(context.sourceFactory, same(sourceFactory));
  }

  void test_getSourcesWithFullName() {
    String filePath = '/foo/lib/file.dart';
    List<Source> expected = <Source>[];
    ChangeSet changeSet = new ChangeSet();

    TestSourceWithUri source1 =
        new TestSourceWithUri(filePath, Uri.parse('file://$filePath'));
    expected.add(source1);
    changeSet.addedSource(source1);

    TestSourceWithUri source2 =
        new TestSourceWithUri(filePath, Uri.parse('package:foo/file.dart'));
    expected.add(source2);
    changeSet.addedSource(source2);

    context.applyChanges(changeSet);
    expect(context.getSourcesWithFullName(filePath), unorderedEquals(expected));
  }

  void test_getStatistics() {
    AnalysisContextStatistics statistics = context.statistics;
    expect(statistics, isNotNull);
    // The following lines are fragile.
    // The values depend on the number of libraries in the SDK.
//    assertLength(0, statistics.getCacheRows());
//    assertLength(0, statistics.getExceptions());
//    assertLength(0, statistics.getSources());
  }

  void test_handleContentsChanged() {
    ContentCache contentCache = new ContentCache();
    context.contentCache = contentCache;
    String oldContents = 'foo() {}';
    String newContents = 'bar() {}';
    // old contents
    Source source = addSource("/test.dart", oldContents);
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(source, source), isNotNull);
    // new contents
    contentCache.setContents(source, newContents);
    context.handleContentsChanged(source, oldContents, newContents, true);
    // there is some work to do
    AnalysisResult analysisResult = context.performAnalysisTask();
    expect(analysisResult.changeNotices, isNotNull);
  }

  Future test_implicitAnalysisEvents_added() async {
    AnalyzedSourcesListener listener = new AnalyzedSourcesListener();
    context.implicitAnalysisEvents.listen(listener.onData);
    //
    // Create a file that references an file that is not explicitly being
    // analyzed and fully analyze it. Ensure that the listener is told about
    // the implicitly analyzed file.
    //
    Source sourceA = newSource('/a.dart', "library a; import 'b.dart';");
    Source sourceB = newSource('/b.dart', "library b;");
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(sourceA);
    context.applyChanges(changeSet);
    context.computeErrors(sourceA);
    await pumpEventQueue();
    listener.expectAnalyzed(sourceB);
  }

  void test_isClientLibrary_dart() {
    Source source = addSource("/test.dart", r'''
import 'dart:html';

main() {}''');
    expect(context.isClientLibrary(source), isFalse);
    expect(context.isServerLibrary(source), isFalse);
    context.computeLibraryElement(source);
    expect(context.isClientLibrary(source), isTrue);
    expect(context.isServerLibrary(source), isFalse);
  }

  void test_isClientLibrary_html() {
    Source source = addSource("/test.html", "<html></html>");
    expect(context.isClientLibrary(source), isFalse);
  }

  void test_isServerLibrary_dart() {
    Source source = addSource("/test.dart", r'''
library lib;

main() {}''');
    expect(context.isClientLibrary(source), isFalse);
    expect(context.isServerLibrary(source), isFalse);
    context.computeLibraryElement(source);
    expect(context.isClientLibrary(source), isFalse);
    expect(context.isServerLibrary(source), isTrue);
  }

  void test_isServerLibrary_html() {
    Source source = addSource("/test.html", "<html></html>");
    expect(context.isServerLibrary(source), isFalse);
  }

  void test_parseCompilationUnit_errors() {
    Source source = addSource("/lib.dart", "library {");
    CompilationUnit compilationUnit = context.parseCompilationUnit(source);
    expect(compilationUnit, isNotNull);
    var errorInfo = context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, isNotNull);
    expect(errors.length > 0, isTrue);
  }

  void test_parseCompilationUnit_exception() {
    Source source = _addSourceWithException("/test.dart");
    try {
      context.parseCompilationUnit(source);
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  void test_parseCompilationUnit_html() {
    Source source = addSource("/test.html", "<html></html>");
    expect(context.parseCompilationUnit(source), isNull);
  }

  void test_parseCompilationUnit_noErrors() {
    Source source = addSource("/lib.dart", "library lib;");
    CompilationUnit compilationUnit = context.parseCompilationUnit(source);
    expect(compilationUnit, isNotNull);
    AnalysisErrorInfo errorInfo = context.getErrors(source);
    expect(errorInfo, isNotNull);
    expect(errorInfo.errors, hasLength(0));
  }

  void test_parseCompilationUnit_nonExistentSource() {
    Source source = newSource('/test.dart');
    resourceProvider.deleteFile('/test.dart');
    try {
      context.parseCompilationUnit(source);
      fail("Expected AnalysisException because file does not exist");
    } on AnalysisException {
      // Expected result
    }
  }

  void test_parseHtmlDocument() {
    Source source = addSource("/lib.html", "<!DOCTYPE html><html></html>");
    Document document = context.parseHtmlDocument(source);
    expect(document, isNotNull);
  }

  void test_parseHtmlUnit_resolveDirectives() {
    Source libSource = addSource("/lib.dart", r'''
library lib;
class ClassA {}''');
    Source source = addSource("/lib.html", r'''
<!DOCTYPE html>
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
    Document document = context.parseHtmlDocument(source);
    expect(document, isNotNull);
    List<DartScript> scripts = context.computeResult(source, DART_SCRIPTS);
    expect(scripts, hasLength(1));
    CompilationUnit unit = context.computeResult(scripts[0], PARSED_UNIT);
    ImportDirective importNode = unit.directives[0] as ImportDirective;
    expect(importNode.uriContent, isNotNull);
    expect(importNode.source, libSource);
  }

  void test_performAnalysisTask_addPart() {
    Source libSource = addSource("/lib.dart", r'''
library lib;
part 'part.dart';''');
    // run all tasks without part
    _analyzeAll_assertFinished();
    expect(_hasAnalysisErrorWithErrorSeverity(context.getErrors(libSource)),
        isTrue, reason: "lib has errors");
    // add part and run all tasks
    Source partSource = addSource("/part.dart", r'''
part of lib;
''');
    _analyzeAll_assertFinished();
    // "libSource" should be here
    List<Source> librariesWithPart = context.getLibrariesContaining(partSource);
    expect(librariesWithPart, unorderedEquals([libSource]));
    expect(_hasAnalysisErrorWithErrorSeverity(context.getErrors(libSource)),
        isFalse, reason: "lib doesn't have errors");
    expect(
        context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved");
  }

  void test_performAnalysisTask_changeLibraryContents() {
    Source libSource =
        addSource("/test.dart", "library lib; part 'test-part.dart';");
    Source partSource = addSource("/test-part.dart", "part of lib;");
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 1");
    expect(
        context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 1");
    // update and analyze #1
    context.setContents(libSource, "library lib;");
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 2");
    expect(context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 2");
    expect(context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part resolved 2");
    // update and analyze #2
    context.setContents(libSource, "library lib; part 'test-part.dart';");
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 3");
    expect(context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 3");
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 2");
    expect(
        context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 3");
  }

  void test_performAnalysisTask_changeLibraryThenPartContents() {
    Source libSource =
        addSource("/test.dart", "library lib; part 'test-part.dart';");
    Source partSource = addSource("/test-part.dart", "part of lib;");
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 1");
    expect(
        context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 1");
    // update and analyze #1
    context.setContents(libSource, "library lib;");
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 2");
    expect(context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 2");
    expect(context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part resolved 2");
    // update and analyze #2
    context.setContents(partSource, "part of lib; // 1");
    // Assert that changing the part's content does not effect the library
    // now that it is no longer part of that library
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library changed 3");
    expect(context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 3");
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 3");
    expect(context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part resolved 3");
  }

  void test_performAnalysisTask_changePartContents_makeItAPart() {
    Source libSource = addSource("/lib.dart", r'''
library lib;
part 'part.dart';
void f(x) {}''');
    Source partSource = addSource("/part.dart", "void g() { f(null); }");
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 1");
    expect(
        context.getResolvedCompilationUnit2(partSource, partSource), isNotNull,
        reason: "part resolved 1");
    // update and analyze
    context.setContents(partSource, r'''
part of lib;
void g() { f(null); }''');
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 2");
    expect(context.getResolvedCompilationUnit2(partSource, partSource), isNull,
        reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 2");
    expect(
        context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 2");
    expect(context.getErrors(libSource).errors, hasLength(0));
    expect(context.getErrors(partSource).errors, hasLength(0));
  }

  /**
   * https://code.google.com/p/dart/issues/detail?id=12424
   */
  void test_performAnalysisTask_changePartContents_makeItNotPart() {
    Source libSource = addSource("/lib.dart", r'''
library lib;
part 'part.dart';
void f(x) {}''');
    Source partSource = addSource("/part.dart", r'''
part of lib;
void g() { f(null); }''');
    _analyzeAll_assertFinished();
    expect(context.getErrors(libSource).errors, hasLength(0));
    expect(context.getErrors(partSource).errors, hasLength(0));
    // Remove 'part' directive, which should make "f(null)" an error.
    context.setContents(partSource, r'''
//part of lib;
void g() { f(null); }''');
    _analyzeAll_assertFinished();
    expect(context.getErrors(libSource).errors.length != 0, isTrue);
  }

  void test_performAnalysisTask_changePartContents_noSemanticChanges() {
    Source libSource =
        addSource("/test.dart", "library lib; part 'test-part.dart';");
    Source partSource = addSource("/test-part.dart", "part of lib;");
    _analyzeAll_assertFinished();
    expect(context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 1");
    expect(
        context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 1");
    // update and analyze #1
    context.setContents(partSource, "part of lib; // 1");
    if (AnalysisEngine.instance.limitInvalidationInTaskModel) {
      expect(
          context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
          reason: "library changed 2");
      expect(
          context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
          reason: "part changed 2");
    } else {
      expect(context.getResolvedCompilationUnit2(libSource, libSource), isNull,
          reason: "library changed 2");
      expect(context.getResolvedCompilationUnit2(partSource, libSource), isNull,
          reason: "part changed 2");
      _analyzeAll_assertFinished();
      expect(
          context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
          reason: "library resolved 2");
      expect(
          context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
          reason: "part resolved 2");
    }
    // update and analyze #2
    context.setContents(partSource, "part of lib; // 12");
    if (AnalysisEngine.instance.limitInvalidationInTaskModel) {
      expect(
          context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
          reason: "library changed 3");
      expect(
          context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
          reason: "part changed 3");
    } else {
      expect(context.getResolvedCompilationUnit2(libSource, libSource), isNull,
          reason: "library changed 3");
      expect(context.getResolvedCompilationUnit2(partSource, libSource), isNull,
          reason: "part changed 3");
      _analyzeAll_assertFinished();
      expect(
          context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
          reason: "library resolved 3");
      expect(
          context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
          reason: "part resolved 3");
    }
  }

  void test_performAnalysisTask_getContentException_dart() {
    Source source = _addSourceWithException('test.dart');
    // prepare errors
    _analyzeAll_assertFinished();
    List<AnalysisError> errors = context.getErrors(source).errors;
    // validate errors
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.source, same(source));
    expect(error.errorCode, ScannerErrorCode.UNABLE_GET_CONTENT);
  }

  void test_performAnalysisTask_getContentException_html() {
    Source source = _addSourceWithException('test.html');
    // prepare errors
    _analyzeAll_assertFinished();
    List<AnalysisError> errors = context.getErrors(source).errors;
    // validate errors
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.source, same(source));
    expect(error.errorCode, ScannerErrorCode.UNABLE_GET_CONTENT);
  }

  void test_performAnalysisTask_importedLibraryAdd() {
    Source libASource =
        addSource("/libA.dart", "library libA; import 'libB.dart';");
    _analyzeAll_assertFinished();
    expect(
        context.getResolvedCompilationUnit2(libASource, libASource), isNotNull,
        reason: "libA resolved 1");
    expect(_hasAnalysisErrorWithErrorSeverity(context.getErrors(libASource)),
        isTrue, reason: "libA has an error");
    // add libB.dart and analyze
    Source libBSource = addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(
        context.getResolvedCompilationUnit2(libASource, libASource), isNotNull,
        reason: "libA resolved 2");
    expect(
        context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull,
        reason: "libB resolved 2");
    expect(_hasAnalysisErrorWithErrorSeverity(context.getErrors(libASource)),
        isFalse, reason: "libA doesn't have errors");
  }

  void test_performAnalysisTask_importedLibraryAdd_html() {
    Source htmlSource = addSource("/page.html", r'''
<html><body><script type="application/dart">
  import '/libB.dart';
  main() {print('hello dart');}
</script></body></html>''');
    _analyzeAll_assertFinished();
    context.computeErrors(htmlSource);
    expect(_hasAnalysisErrorWithErrorSeverity(context.getErrors(htmlSource)),
        isTrue, reason: "htmlSource has an error");
    // add libB.dart and analyze
    Source libBSource = addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(
        context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull,
        reason: "libB resolved 2");
    // TODO (danrubel) commented out to fix red bots
//    context.computeErrors(htmlSource);
//    AnalysisErrorInfo errors = _context.getErrors(htmlSource);
//    expect(
//        !_hasAnalysisErrorWithErrorSeverity(errors),
//        isTrue,
//        reason: "htmlSource doesn't have errors");
  }

  void test_performAnalysisTask_importedLibraryDelete() {
    Source libASource =
        addSource("/libA.dart", "library libA; import 'libB.dart';");
    Source libBSource = addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(
        context.getResolvedCompilationUnit2(libASource, libASource), isNotNull,
        reason: "libA resolved 1");
    expect(
        context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull,
        reason: "libB resolved 1");
    expect(!_hasAnalysisErrorWithErrorSeverity(context.getErrors(libASource)),
        isTrue, reason: "libA doesn't have errors");
    // remove libB.dart and analyze
    _removeSource(libBSource);
    _analyzeAll_assertFinished();
    expect(
        context.getResolvedCompilationUnit2(libASource, libASource), isNotNull,
        reason: "libA resolved 2");
    expect(_hasAnalysisErrorWithErrorSeverity(context.getErrors(libASource)),
        isTrue, reason: "libA has an error");
  }

  void test_performAnalysisTask_IOException() {
    TestSource source = _addSourceWithException2("/test.dart", "library test;");
    source.generateExceptionOnRead = false;
    _analyzeAll_assertFinished();
    expect(source.readCount, 1);
    _changeSource(source, "");
    source.generateExceptionOnRead = true;
    _analyzeAll_assertFinished();
    if (AnalysisEngine.instance.limitInvalidationInTaskModel) {
      expect(source.readCount, 5);
    } else {
      expect(source.readCount, 3);
    }
  }

  void test_performAnalysisTask_missingPart() {
    Source source =
        addSource("/test.dart", "library lib; part 'no-such-file.dart';");
    _analyzeAll_assertFinished();
    expect(context.getLibraryElement(source), isNotNull,
        reason: "performAnalysisTask failed to compute an element model");
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

  void test_performAnalysisTask_onResultComputed() {
    Set<String> libraryElementUris = new Set<String>();
    Set<String> parsedUnitUris = new Set<String>();
    Set<String> resolvedUnitUris = new Set<String>();
    // listen
    context.onResultComputed(LIBRARY_ELEMENT).listen((event) {
      Source librarySource = event.target;
      libraryElementUris.add(librarySource.uri.toString());
    });
    context.onResultComputed(PARSED_UNIT).listen((event) {
      Source source = event.target;
      parsedUnitUris.add(source.uri.toString());
    });
    context.onResultComputed(RESOLVED_UNIT).listen((event) {
      LibrarySpecificUnit target = event.target;
      Source librarySource = target.library;
      resolvedUnitUris.add(librarySource.uri.toString());
    });
    // analyze
    addSource('/test.dart', 'main() {}');
    _analyzeAll_assertFinished();
    // verify
    expect(libraryElementUris, contains('dart:core'));
    expect(libraryElementUris, contains('file:///test.dart'));
    expect(parsedUnitUris, contains('dart:core'));
    expect(parsedUnitUris, contains('file:///test.dart'));
    expect(resolvedUnitUris, contains('dart:core'));
    expect(resolvedUnitUris, contains('file:///test.dart'));
  }

  void test_resolveCompilationUnit_import_relative() {
    Source sourceA =
        addSource("/libA.dart", "library libA; import 'libB.dart'; class A{}");
    addSource("/libB.dart", "library libB; class B{}");
    CompilationUnit compilationUnit =
        context.resolveCompilationUnit2(sourceA, sourceA);
    expect(compilationUnit, isNotNull);
    LibraryElement library = compilationUnit.element.library;
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core", "libB"]);
    List<LibraryElement> visibleLibraries = library.visibleLibraries;
    assertNamedElements(visibleLibraries, [
      "dart.core",
      "dart.async",
      "dart.math",
      "libA",
      "libB"
    ]);
  }

  void test_resolveCompilationUnit_import_relative_cyclic() {
    Source sourceA =
        addSource("/libA.dart", "library libA; import 'libB.dart'; class A{}");
    addSource("/libB.dart", "library libB; import 'libA.dart'; class B{}");
    CompilationUnit compilationUnit =
        context.resolveCompilationUnit2(sourceA, sourceA);
    expect(compilationUnit, isNotNull);
    LibraryElement library = compilationUnit.element.library;
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core", "libB"]);
    List<LibraryElement> visibleLibraries = library.visibleLibraries;
    assertNamedElements(visibleLibraries, [
      "dart.core",
      "dart.async",
      "dart.math",
      "libA",
      "libB"
    ]);
  }

//  void test_resolveCompilationUnit_sourceChangeDuringResolution() {
//    _context = new _AnalysisContext_sourceChangeDuringResolution();
//    AnalysisContextFactory.initContextWithCore(_context);
//    _sourceFactory = _context.sourceFactory;
//    Source source = _addSource("/lib.dart", "library lib;");
//    CompilationUnit compilationUnit =
//        _context.resolveCompilationUnit2(source, source);
//    expect(compilationUnit, isNotNull);
//    expect(_context.getLineInfo(source), isNotNull);
//  }

  void test_resolveCompilationUnit_library() {
    Source source = addSource("/lib.dart", "library lib;");
    LibraryElement library = context.computeLibraryElement(source);
    CompilationUnit compilationUnit =
        context.resolveCompilationUnit(source, library);
    expect(compilationUnit, isNotNull);
    expect(compilationUnit.element, isNotNull);
  }

  void test_resolveCompilationUnit_source() {
    Source source = addSource("/lib.dart", "library lib;");
    CompilationUnit compilationUnit =
        context.resolveCompilationUnit2(source, source);
    expect(compilationUnit, isNotNull);
  }

  void test_setAnalysisOptions() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.cacheSize = 42;
    options.dart2jsHint = false;
    options.hint = false;
    context.analysisOptions = options;
    AnalysisOptions result = context.analysisOptions;
    expect(result.cacheSize, options.cacheSize);
    expect(result.dart2jsHint, options.dart2jsHint);
    expect(result.hint, options.hint);
  }

  void test_setAnalysisPriorityOrder() {
    int priorityCount = 4;
    List<Source> sources = new List<Source>();
    for (int index = 0; index < priorityCount; index++) {
      sources.add(addSource("/lib.dart$index", ""));
    }
    context.analysisPriorityOrder = sources;
    expect(_getPriorityOrder(context).length, priorityCount);
  }

  void test_setAnalysisPriorityOrder_empty() {
    context.analysisPriorityOrder = new List<Source>();
  }

  void test_setAnalysisPriorityOrder_nonEmpty() {
    List<Source> sources = new List<Source>();
    sources.add(addSource("/lib.dart", "library lib;"));
    context.analysisPriorityOrder = sources;
  }

  Future test_setChangedContents_libraryWithPart() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.incremental = true;
    context.analysisOptions = options;
    SourcesChangedListener listener = new SourcesChangedListener();
    context.onSourcesChanged.listen(listener.onData);
    String oldCode = r'''
library lib;
part 'part.dart';
int a = 0;''';
    Source librarySource = addSource("/lib.dart", oldCode);
    String partContents = r'''
part of lib;
int b = a;''';
    Source partSource = addSource("/part.dart", partContents);
    LibraryElement element = context.computeLibraryElement(librarySource);
    CompilationUnit unit =
        context.resolveCompilationUnit(librarySource, element);
    expect(unit, isNotNull);
    int offset = oldCode.indexOf("int a") + 4;
    String newCode = r'''
library lib;
part 'part.dart';
int ya = 0;''';
    context.setChangedContents(librarySource, newCode, offset, 0, 1);
    expect(context.getContents(librarySource).data, newCode);
    expect(
        context.getResolvedCompilationUnit2(partSource, librarySource), isNull);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [librarySource]);
      listener.assertNoMoreEvents();
    });
  }

  void test_setChangedContents_notResolved() {
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.from(context.analysisOptions);
    options.incremental = true;
    context.analysisOptions = options;
    String oldCode = r'''
library lib;
int a = 0;''';
    Source librarySource = addSource("/lib.dart", oldCode);
    int offset = oldCode.indexOf("int a") + 4;
    String newCode = r'''
library lib;
int ya = 0;''';
    context.setChangedContents(librarySource, newCode, offset, 0, 1);
    expect(context.getContents(librarySource).data, newCode);
  }

  Future test_setContents_libraryWithPart() {
    SourcesChangedListener listener = new SourcesChangedListener();
    context.onSourcesChanged.listen(listener.onData);
    String libraryContents1 = r'''
library lib;
part 'part.dart';
int a = 0;''';
    Source librarySource = addSource("/lib.dart", libraryContents1);
    String partContents1 = r'''
part of lib;
int b = a;''';
    Source partSource = addSource("/part.dart", partContents1);
    context.computeLibraryElement(librarySource);
    String libraryContents2 = r'''
library lib;
part 'part.dart';
int aa = 0;''';
    context.setContents(librarySource, libraryContents2);
    expect(
        context.getResolvedCompilationUnit2(partSource, librarySource), isNull);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [librarySource]);
      listener.assertNoMoreEvents();
    });
  }

  void test_setContents_null() {
    Source librarySource = addSource("/lib.dart", r'''
library lib;
int a = 0;''');
    context.setContents(librarySource, '// different');
    context.computeLibraryElement(librarySource);
    context.setContents(librarySource, null);
    expect(context.getResolvedCompilationUnit2(librarySource, librarySource),
        isNull);
  }

  void test_setContents_unchanged_consistentModificationTime() {
    String contents = "// foo";
    Source source = addSource("/test.dart", contents);
    context.setContents(source, contents);
    // do all, no tasks
    _analyzeAll_assertFinished();
    {
      AnalysisResult result = context.performAnalysisTask();
      expect(result.changeNotices, isNull);
    }
    // set the same contents, still no tasks
    context.setContents(source, contents);
    {
      AnalysisResult result = context.performAnalysisTask();
      expect(result.changeNotices, isNull);
    }
  }

  void test_setSourceFactory() {
    expect(context.sourceFactory, sourceFactory);
    SourceFactory factory = new SourceFactory([]);
    context.sourceFactory = factory;
    expect(context.sourceFactory, factory);
  }

  void test_updateAnalysis() {
    expect(context.sourcesNeedingProcessing, isEmpty);
    Source source = newSource('/test.dart');
    AnalysisDelta delta = new AnalysisDelta();
    delta.setAnalysisLevel(source, AnalysisLevel.ALL);
    context.applyAnalysisDelta(delta);
    expect(context.sourcesNeedingProcessing, contains(source));
    delta = new AnalysisDelta();
    delta.setAnalysisLevel(source, AnalysisLevel.NONE);
    context.applyAnalysisDelta(delta);
    expect(context.sourcesNeedingProcessing.contains(source), isFalse);
  }

  void xtest_performAnalysisTask_stress() {
    int maxCacheSize = 4;
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.from(context.analysisOptions);
    options.cacheSize = maxCacheSize;
    context.analysisOptions = options;
    int sourceCount = maxCacheSize + 2;
    List<Source> sources = new List<Source>();
    ChangeSet changeSet = new ChangeSet();
    for (int i = 0; i < sourceCount; i++) {
      Source source = addSource("/lib$i.dart", "library lib$i;");
      sources.add(source);
      changeSet.addedSource(source);
    }
    context.applyChanges(changeSet);
    context.analysisPriorityOrder = sources;
    for (int i = 0; i < 1000; i++) {
      List<ChangeNotice> notice = context.performAnalysisTask().changeNotices;
      if (notice == null) {
        //System.out.println("test_performAnalysisTask_stress: " + i);
        break;
      }
    }
    List<ChangeNotice> notice = context.performAnalysisTask().changeNotices;
    if (notice != null) {
      fail(
          "performAnalysisTask failed to terminate after analyzing all sources");
    }
  }

  TestSource _addSourceWithException(String fileName) {
    return _addSourceWithException2(fileName, "");
  }

  TestSource _addSourceWithException2(String fileName, String contents) {
    TestSource source = new TestSource(fileName, contents);
    source.generateExceptionOnRead = true;
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
    return source;
  }

  /**
   * Perform analysis tasks up to 512 times and assert that it was enough.
   */
  void _analyzeAll_assertFinished([int maxIterations = 512]) {
    for (int i = 0; i < maxIterations; i++) {
      List<ChangeNotice> notice = context.performAnalysisTask().changeNotices;
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
    context.applyChanges(changeSet);
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

  void _flushAst(Source source) {
    CacheEntry entry =
        context.getCacheEntry(new LibrarySpecificUnit(source, source));
    entry.setState(RESOLVED_UNIT, CacheState.FLUSHED);
  }

  List<Source> _getPriorityOrder(AnalysisContextImpl context2) {
    return context2.test_priorityOrder;
  }

  void _performPendingAnalysisTasks([int maxTasks = 512]) {
    for (int i = 0; context.performAnalysisTask().hasMoreWork; i++) {
      if (i > maxTasks) {
        fail('Analysis did not terminate.');
      }
    }
  }

  void _removeSource(Source source) {
    resourceProvider.deleteFile(source.fullName);
    ChangeSet changeSet = new ChangeSet();
    changeSet.removedSource(source);
    context.applyChanges(changeSet);
  }

  /**
   * Returns `true` if there is an [AnalysisError] with [ErrorSeverity.ERROR] in
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

@reflectiveTest
class LimitedInvalidateTest extends AbstractContextTest {
  @override
  void setUp() {
    AnalysisEngine.instance.limitInvalidationInTaskModel = true;
    super.setUp();
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.from(context.analysisOptions);
    options.incremental = true;
    context.analysisOptions = options;
  }

  @override
  void tearDown() {
    AnalysisEngine.instance.limitInvalidationInTaskModel = false;
    super.tearDown();
  }

  void test_noChange_thenChange() {
    Source sourceA = addSource("/a.dart", r'''
library lib_a;

class A {
  A();
}
class B {
  B();
}
''');
    Source sourceB = addSource("/b.dart", r'''
library lib_b;
import 'a.dart';
main() {
  new A();
}
''');
    _performPendingAnalysisTasks();
    expect(context.getErrors(sourceA).errors, hasLength(0));
    expect(context.getErrors(sourceB).errors, hasLength(0));
    var unitA = context.getResolvedCompilationUnit2(sourceA, sourceA);
    var unitElementA = unitA.element;
    var libraryElementA = unitElementA.library;
    // Update a.dart, no declaration changes.
    context.setContents(sourceA, r'''
library lib_a;
class A {
  A();
}
class B {
  B();
}
''');
    _assertInvalid(sourceA, LIBRARY_ERRORS_READY);
    _assertValid(sourceB, LIBRARY_ERRORS_READY);
    // The a.dart's unit and element are updated incrementally.
    // They are the same instances as initially.
    // So, all the references from other units are still valid.
    {
      LibrarySpecificUnit target = new LibrarySpecificUnit(sourceA, sourceA);
      expect(analysisCache.getValue(target, RESOLVED_UNIT1), same(unitA));
      expect(unitA.element, same(unitElementA));
      expect(unitElementA.library, same(libraryElementA));
    }
    // Analyze.
    _performPendingAnalysisTasks();
    expect(context.getErrors(sourceA).errors, hasLength(0));
    expect(context.getErrors(sourceB).errors, hasLength(0));
    // The a.dart's unit and element are the same.
    {
      LibrarySpecificUnit target = new LibrarySpecificUnit(sourceA, sourceA);
      expect(analysisCache.getValue(target, RESOLVED_UNIT), same(unitA));
      expect(unitA.element, same(unitElementA));
      expect(unitElementA.library, same(libraryElementA));
    }
    // Update a.dart, rename A to A2, invalidates b.dart, so
    // we know that the previous update did not damage dependencies.
    context.setContents(sourceA, r'''
library lib_a;
class A {
  A();
  m() {}
}
class B {
  B();
}
''');
    _assertInvalid(sourceA, LIBRARY_ERRORS_READY);
    _assertInvalid(sourceB, LIBRARY_ERRORS_READY);
    // The a.dart's unit and element are the same.
    {
      LibrarySpecificUnit target = new LibrarySpecificUnit(sourceA, sourceA);
      expect(analysisCache.getValue(target, RESOLVED_UNIT1), same(unitA));
      expect(unitA.element, same(unitElementA));
      expect(unitElementA.library, same(libraryElementA));
    }
    // Analyze.
    _performPendingAnalysisTasks();
    expect(context.getErrors(sourceA).errors, hasLength(0));
    expect(context.getErrors(sourceB).errors, hasLength(0));
  }

  void test_unusedName() {
    Source sourceA = addSource("/a.dart", r'''
library lib_a;
class A {}
class B {}
class C {}
''');
    Source sourceB = addSource("/b.dart", r'''
library lib_b;
import 'a.dart';
main() {
  new A();
  new C();
}
''');
    _performPendingAnalysisTasks();
    // Update A.
    context.setContents(sourceA, r'''
library lib_a;
class A {}
class B2 {}
class C {}
''');
    // Only a.dart is invalidated.
    // Because b.dart does not use B, so it is valid.
    _assertInvalid(sourceA, LIBRARY_ERRORS_READY);
    _assertValid(sourceB, LIBRARY_ERRORS_READY);
  }

  void test_usedName_directUser() {
    Source sourceA = addSource("/a.dart", r'''
library lib_a;
class A {}
class B {}
class C {}
''');
    Source sourceB = addSource("/b.dart", r'''
library lib_b;
import 'a.dart';
main() {
  new A();
  new C2();
}
''');
    _performPendingAnalysisTasks();
    expect(context.getErrors(sourceB).errors, hasLength(1));
    // Update a.dart, invalidates b.dart because it references "C2".
    context.setContents(sourceA, r'''
library lib_a;
class A {}
class B {}
class C2 {}
''');
    _assertInvalid(sourceA, LIBRARY_ERRORS_READY);
    _assertInvalid(sourceB, LIBRARY_ERRORS_READY);
    // Now b.dart is analyzed and the error is fixed.
    _performPendingAnalysisTasks();
    expect(context.getErrors(sourceB).errors, hasLength(0));
    // Update a.dart, invalidates b.dart because it references "C".
    context.setContents(sourceA, r'''
library lib_a;
class A {}
class B {}
class C {}
''');
    _assertInvalid(sourceA, LIBRARY_ERRORS_READY);
    _assertInvalid(sourceB, LIBRARY_ERRORS_READY);
    _performPendingAnalysisTasks();
    // Now b.dart is analyzed and it again has the error.
    expect(context.getErrors(sourceB).errors, hasLength(1));
  }

  void test_usedName_directUser_withIncremental() {
    Source sourceA = addSource("/a.dart", r'''
library lib_a;
class A {
  m() {}
}
''');
    Source sourceB = addSource("/b.dart", r'''
library lib_b;
import 'a.dart';
main() {
  A a = new A();
  a.m();
}
''');
    _performPendingAnalysisTasks();
    // Update A.
    context.setContents(sourceA, r'''
library lib_a;
class A {
  m2() {}
}
''');
    _assertInvalid(sourceA, LIBRARY_ERRORS_READY);
    _assertInvalid(sourceB, LIBRARY_ERRORS_READY);
  }

  void test_usedName_indirectUser() {
    Source sourceA = addSource("/a.dart", r'''
library lib_a;
class A {
  m() {}
}
''');
    Source sourceB = addSource("/b.dart", r'''
library lib_b;
import 'a.dart';
class B extends A {}
''');
    Source sourceC = addSource("/c.dart", r'''
library lib_c;
import 'b.dart';
class C extends B {
  main() {
    m();
  }
}
''');
    // No errors, "A.m" exists.
    _performPendingAnalysisTasks();
    expect(context.getErrors(sourceC).errors, hasLength(0));
    // Replace "A.m" with "A.m2", invalidate both b.dart and c.dart files.
    context.setContents(sourceA, r'''
library lib_a;
class A {
  m2() {}
}
''');
    _assertInvalid(sourceA, LIBRARY_ERRORS_READY);
    _assertInvalid(sourceB, LIBRARY_ERRORS_READY);
    _assertInvalid(sourceC, LIBRARY_ERRORS_READY);
    // There is an error in c.dart, "A.m" does not exist.
    _performPendingAnalysisTasks();
    expect(context.getErrors(sourceB).errors, hasLength(0));
    expect(context.getErrors(sourceC).errors, hasLength(1));
    // Restore "A.m", invalidate both b.dart and c.dart files.
    context.setContents(sourceA, r'''
library lib_a;
class A {
  m() {}
}
''');
    _assertInvalid(sourceA, LIBRARY_ERRORS_READY);
    _assertInvalid(sourceB, LIBRARY_ERRORS_READY);
    _assertInvalid(sourceC, LIBRARY_ERRORS_READY);
    // No errors, "A.m" exists.
    _performPendingAnalysisTasks();
    expect(context.getErrors(sourceC).errors, hasLength(0));
  }

  void _assertInvalid(AnalysisTarget target, ResultDescriptor descriptor) {
    CacheState state = analysisCache.getState(target, descriptor);
    expect(state, CacheState.INVALID);
  }

  void _assertValid(AnalysisTarget target, ResultDescriptor descriptor) {
    CacheState state = analysisCache.getState(target, descriptor);
    expect(state, CacheState.VALID);
  }

  void _performPendingAnalysisTasks([int maxTasks = 512]) {
    for (int i = 0; context.performAnalysisTask().hasMoreWork; i++) {
      if (i > maxTasks) {
        fail('Analysis did not terminate.');
      }
    }
  }
}

class _AnalysisContextImplTest_test_applyChanges_removeContainer
    implements SourceContainer {
  Source libB;
  _AnalysisContextImplTest_test_applyChanges_removeContainer(this.libB);
  @override
  bool contains(Source source) => source == libB;
}
