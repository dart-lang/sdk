// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.stress.limited_invalidation;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' as fs;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

main() {
  new StressTest().run();
}

void _failTypeMismatch(Object actual, Object expected, {String reason}) {
  String message = 'Actual $actual is ${actual.runtimeType}, '
      'but expected $expected is ${expected.runtimeType}';
  if (reason != null) {
    message += ' $reason';
  }
  fail(message);
}

void _logPrint(String message) {
  DateTime time = new DateTime.now();
  print('$time: $message');
}

class FileInfo {
  final String path;
  final int modification;

  FileInfo(this.path, this.modification);
}

class FolderDiff {
  final List<String> added;
  final List<String> changed;
  final List<String> removed;

  FolderDiff(this.added, this.changed, this.removed);

  bool get isEmpty => added.isEmpty && changed.isEmpty && removed.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return '[added=$added, changed=$changed, removed=$removed]';
  }
}

class FolderInfo {
  final String path;
  final List<FileInfo> files = <FileInfo>[];

  FolderInfo(this.path) {
    List<FileSystemEntity> entities =
        new Directory(path).listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      if (entity is File) {
        String path = entity.path;
        if (path.contains('packages') || path.contains('.pub')) {
          continue;
        }
        if (path.endsWith('.dart')) {
          files.add(new FileInfo(
              path, entity.lastModifiedSync().millisecondsSinceEpoch));
        }
      }
    }
  }

  FolderDiff diff(FolderInfo oldFolder) {
    Map<String, FileInfo> toMap(FolderInfo folder) {
      Map<String, FileInfo> map = <String, FileInfo>{};
      folder.files.forEach((file) {
        map[file.path] = file;
      });
      return map;
    }

    Map<String, FileInfo> newFiles = toMap(this);
    Map<String, FileInfo> oldFiles = toMap(oldFolder);
    Set<String> addedPaths = newFiles.keys.toSet()..removeAll(oldFiles.keys);
    Set<String> removedPaths = oldFiles.keys.toSet()..removeAll(newFiles.keys);
    List<String> changedPaths = <String>[];
    newFiles.forEach((path, newFile) {
      FileInfo oldFile = oldFiles[path];
      if (oldFile != null && oldFile.modification != newFile.modification) {
        changedPaths.add(path);
      }
    });
    return new FolderDiff(
        addedPaths.toList(), changedPaths, removedPaths.toList());
  }
}

class GitException {
  final String message;
  final String stdout;
  final String stderr;

  GitException(this.message)
      : stdout = null,
        stderr = null;

  GitException.forProcessResult(this.message, ProcessResult processResult)
      : stdout = processResult.stdout,
        stderr = processResult.stderr;

  @override
  String toString() => '$message\n$stdout\n$stderr\n';
}

class GitRepository {
  final String path;

  GitRepository(this.path);

  Future checkout(String hash) async {
    // TODO(scheglov) use for updating only some files
    if (hash.endsWith('hash')) {
      List<String> filePaths = <String>[
        '/Users/user/full/path/one.dart',
        '/Users/user/full/path/two.dart',
      ];
      for (var filePath in filePaths) {
        await Process.run('git', <String>['checkout', '-f', hash, filePath],
            workingDirectory: path);
      }
      return;
    }
    ProcessResult processResult = await Process
        .run('git', <String>['checkout', '-f', hash], workingDirectory: path);
    _throwIfNotSuccess(processResult);
  }

  Future<List<GitRevision>> getRevisions({String after}) async {
    List<String> args = <String>['log', '--format=%ct %H %s'];
    if (after != null) {
      args.add('--after=$after');
    }
    ProcessResult processResult =
        await Process.run('git', args, workingDirectory: path);
    _throwIfNotSuccess(processResult);
    String output = processResult.stdout;
    List<String> logLines = output.split('\n');
    List<GitRevision> revisions = <GitRevision>[];
    for (String logLine in logLines) {
      int index1 = logLine.indexOf(' ');
      if (index1 != -1) {
        int index2 = logLine.indexOf(' ', index1 + 1);
        if (index2 != -1) {
          int timestamp = int.parse(logLine.substring(0, index1));
          String hash = logLine.substring(index1 + 1, index2);
          String message = logLine.substring(index2).trim();
          revisions.add(new GitRevision(timestamp, hash, message));
        }
      }
    }
    return revisions;
  }

  void removeIndexLock() {
    File file = new File('$path/.git/index.lock');
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  Future resetHard() async {
    ProcessResult processResult = await Process
        .run('git', <String>['reset', '--hard'], workingDirectory: path);
    _throwIfNotSuccess(processResult);
  }

  void _throwIfNotSuccess(ProcessResult processResult) {
    if (processResult.exitCode != 0) {
      throw new GitException.forProcessResult(
          'Unable to run "git log".', processResult);
    }
  }
}

class GitRevision {
  final int timestamp;
  final String hash;
  final String message;

  GitRevision(this.timestamp, this.hash, this.message);

  @override
  String toString() {
    DateTime dateTime =
        new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
            .toLocal();
    return '$dateTime|$hash|$message|';
  }
}

class StressTest {
  String repoPath = '/Users/scheglov/tmp/limited-invalidation/path';
  String folderPath = '/Users/scheglov/tmp/limited-invalidation/path';
//  String repoPath = '/Users/scheglov/tmp/limited-invalidation/async';
//  String folderPath = '/Users/scheglov/tmp/limited-invalidation/async';
//  String repoPath = '/Users/scheglov/tmp/limited-invalidation/sdk';
//  String folderPath = '/Users/scheglov/tmp/limited-invalidation/sdk/pkg/analyzer';

  fs.ResourceProvider resourceProvider;
  path.Context pathContext;
  DartSdkManager sdkManager;
  ContentCache contentCache;

  AnalysisContextImpl expectedContext;
  AnalysisContextImpl actualContext;

  Set<Element> currentRevisionValidatedElements = new Set<Element>();

  void createContexts() {
    assert(expectedContext == null);
    assert(actualContext == null);
    resourceProvider = PhysicalResourceProvider.INSTANCE;
    pathContext = resourceProvider.pathContext;
    fs.Folder sdkDirectory =
        FolderBasedDartSdk.defaultSdkDirectory(resourceProvider);
    sdkManager = new DartSdkManager(sdkDirectory.path, false);
    contentCache = new ContentCache();
    ContextBuilderOptions builderOptions = new ContextBuilderOptions();
    builderOptions.defaultOptions = new AnalysisOptionsImpl();
    ContextBuilder builder = new ContextBuilder(
        resourceProvider, sdkManager, contentCache,
        options: builderOptions);
    expectedContext = builder.buildContext(folderPath);
    actualContext = builder.buildContext(folderPath);
    expectedContext.analysisOptions =
        new AnalysisOptionsImpl.from(expectedContext.analysisOptions)
          ..incremental = true;
    actualContext.analysisOptions =
        new AnalysisOptionsImpl.from(actualContext.analysisOptions)
          ..incremental = true
          ..finerGrainedInvalidation = true;
    print('Created contexts');
  }

  run() async {
    GitRepository repository = new GitRepository(repoPath);

    // Recover.
    repository.removeIndexLock();
    await repository.resetHard();

    await repository.checkout('master');
    List<GitRevision> revisions =
        await repository.getRevisions(after: '2016-01-01');
    revisions = revisions.reversed.toList();
    // TODO(scheglov) Use to compare two revisions.
//    List<GitRevision> revisions = [
//      new GitRevision(0, '99517a162cbabf3d3afbdb566df3fe2b18cd4877', 'aaa'),
//      new GitRevision(0, '2ef00b0c3d0182b5e4ea5ca55fd00b9d038ae40d', 'bbb'),
//    ];
    FolderInfo oldFolder = null;
    for (GitRevision revision in revisions) {
      print(revision);
      await repository.checkout(revision.hash);

      // Run "pub get".
      if (!new File('$folderPath/pubspec.yaml').existsSync()) {
        continue;
      }
      {
        ProcessResult processResult = await Process.run(
            '/Users/scheglov/Applications/dart-sdk/bin/pub', <String>['get'],
            workingDirectory: folderPath);
        if (processResult.exitCode != 0) {
          _logPrint('Pub get failed.');
          _logPrint(processResult.stdout);
          _logPrint(processResult.stderr);
          continue;
        }
        _logPrint('\tpub get OK');
      }
      FolderInfo newFolder = new FolderInfo(folderPath);

      if (expectedContext == null) {
        createContexts();
        _applyChanges(
            newFolder.files.map((file) => file.path).toList(), [], []);
        _analyzeContexts();
      }

      if (oldFolder != null) {
        FolderDiff diff = newFolder.diff(oldFolder);
        print('    $diff');
        if (diff.isNotEmpty) {
          _applyChanges(diff.added, diff.changed, diff.removed);
          _analyzeContexts();
        }
      }
      oldFolder = newFolder;
      print('\n');
      print('\n');
    }
  }

  /**
   * Perform analysis tasks up to 512 times and assert that it was enough.
   */
  void _analyzeAll_assertFinished(AnalysisContext context,
      [int maxIterations = 1000000]) {
    for (int i = 0; i < maxIterations; i++) {
      List<ChangeNotice> notice = context.performAnalysisTask().changeNotices;
      if (notice == null) {
        return;
      }
    }
    throw new StateError(
        "performAnalysisTask failed to terminate after analyzing all sources");
  }

  void _analyzeContexts() {
    {
      Stopwatch sw = new Stopwatch()..start();
      _analyzeAll_assertFinished(expectedContext);
      print('    analyze(expected):    ${sw.elapsedMilliseconds}');
    }
    {
      Stopwatch sw = new Stopwatch()..start();
      _analyzeAll_assertFinished(actualContext);
      print('    analyze(actual): ${sw.elapsedMilliseconds}');
    }
    _validateContexts();
  }

  void _applyChanges(
      List<String> added, List<String> changed, List<String> removed) {
    ChangeSet changeSet = new ChangeSet();
    added.map(_pathToSource).forEach(changeSet.addedSource);
    removed.map(_pathToSource).forEach(changeSet.removedSource);
    changed.map(_pathToSource).forEach(changeSet.changedSource);
    changed.forEach((path) => new File(path).readAsStringSync());
    {
      Stopwatch sw = new Stopwatch()..start();
      expectedContext.applyChanges(changeSet);
      print('    apply(expected):    ${sw.elapsedMilliseconds}');
    }
    {
      Stopwatch sw = new Stopwatch()..start();
      actualContext.applyChanges(changeSet);
      print('    apply(actual): ${sw.elapsedMilliseconds}');
    }
  }

  Source _pathToSource(String path) {
    fs.File file = resourceProvider.getFile(path);
    return _createSourceInContext(expectedContext, file);
  }

  void _validateContexts() {
    currentRevisionValidatedElements.clear();
    MapIterator<AnalysisTarget, CacheEntry> iterator =
        expectedContext.privateAnalysisCachePartition.iterator();
    while (iterator.moveNext()) {
      AnalysisTarget target = iterator.key;
      CacheEntry entry = iterator.value;
      if (target is NonExistingSource) {
        continue;
      }
      _validateEntry(target, entry);
    }
  }

  void _validateElements(
      Element actualValue, Element expectedValue, Set visited) {
    if (actualValue == null && expectedValue == null) {
      return;
    }
    if (!currentRevisionValidatedElements.add(expectedValue)) {
      return;
    }
    if (!visited.add(expectedValue)) {
      return;
    }
    List<Element> sortElements(List<Element> elements) {
      elements = elements.toList();
      elements.sort((a, b) {
        if (a.nameOffset != b.nameOffset) {
          return a.nameOffset - b.nameOffset;
        }
        return a.name.compareTo(b.name);
      });
      return elements;
    }

    void validateSortedElements(
        List<Element> actualElements, List<Element> expectedElements) {
      expect(actualElements, hasLength(expectedElements.length));
      actualElements = sortElements(actualElements);
      expectedElements = sortElements(expectedElements);
      for (int i = 0; i < expectedElements.length; i++) {
        _validateElements(actualElements[i], expectedElements[i], visited);
      }
    }

    expect(actualValue?.runtimeType, expectedValue?.runtimeType);
    expect(actualValue.nameOffset, expectedValue.nameOffset);
    expect(actualValue.name, expectedValue.name);
    if (expectedValue is ClassElement) {
      var actualElement = actualValue as ClassElement;
      validateSortedElements(actualElement.accessors, expectedValue.accessors);
      validateSortedElements(
          actualElement.constructors, expectedValue.constructors);
      validateSortedElements(actualElement.fields, expectedValue.fields);
      validateSortedElements(actualElement.methods, expectedValue.methods);
    }
    if (expectedValue is CompilationUnitElement) {
      var actualElement = actualValue as CompilationUnitElement;
      validateSortedElements(actualElement.accessors, expectedValue.accessors);
      validateSortedElements(actualElement.functions, expectedValue.functions);
      validateSortedElements(actualElement.types, expectedValue.types);
      validateSortedElements(
          actualElement.functionTypeAliases, expectedValue.functionTypeAliases);
      validateSortedElements(
          actualElement.topLevelVariables, expectedValue.topLevelVariables);
    }
    if (expectedValue is ExecutableElement) {
      var actualElement = actualValue as ExecutableElement;
      validateSortedElements(
          actualElement.parameters, expectedValue.parameters);
      _validateTypes(
          actualElement.returnType, expectedValue.returnType, visited);
    }
  }

  void _validateEntry(AnalysisTarget target, CacheEntry expectedEntry) {
    CacheEntry actualEntry =
        actualContext.privateAnalysisCachePartition.get(target);
    if (actualEntry == null) {
      return;
    }
    print('  (${target.runtimeType})  $target');
    for (ResultDescriptor result in expectedEntry.nonInvalidResults) {
      var expectedData = expectedEntry.getResultDataOrNull(result);
      var actualData = actualEntry.getResultDataOrNull(result);
      if (expectedData?.state == CacheState.INVALID) {
        expectedData = null;
      }
      if (actualData?.state == CacheState.INVALID) {
        actualData = null;
      }
      if (actualData == null) {
        if (result != CONTENT &&
            result != LIBRARY_ELEMENT4 &&
            result != LIBRARY_ELEMENT5 &&
            result != READY_LIBRARY_ELEMENT6 &&
            result != READY_LIBRARY_ELEMENT7) {
          Source targetSource = target.source;
          if (targetSource != null &&
              targetSource.fullName.startsWith(folderPath)) {
            fail('No ResultData $result for $target');
          }
        }
        continue;
      }
      Object expectedValue = expectedData.value;
      Object actualValue = actualData.value;
      print('    $result  ${expectedValue?.runtimeType}');
      _validateResult(target, result, actualValue, expectedValue);
    }
  }

  void _validatePairs(AnalysisTarget target, ResultDescriptor result,
      List actualList, List expectedList) {
    if (expectedList == null) {
      expect(actualList, isNull);
      return;
    }
    expect(actualList, isNotNull);
    expect(actualList, hasLength(expectedList.length));
    for (int i = 0; i < expectedList.length; i++) {
      Object expected = expectedList[i];
      Object actual = actualList[i];
      _validateResult(target, result, actual, expected);
    }
  }

  void _validateResult(AnalysisTarget target, ResultDescriptor result,
      Object actualValue, Object expectedValue) {
    if (expectedValue is bool) {
      expect(actualValue, expectedValue, reason: '$result of $target');
    }
    if (expectedValue is CompilationUnit) {
      expect(actualValue, new isInstanceOf<CompilationUnit>());
      new _AstValidator().isEqualNodes(expectedValue, actualValue);
    }
    if (expectedValue is Element) {
      expect(actualValue, new isInstanceOf<Element>());
      _validateElements(actualValue, expectedValue, new Set.identity());
    }
    if (expectedValue is List) {
      if (actualValue is List) {
        _validatePairs(target, result, actualValue, expectedValue);
      } else {
        _failTypeMismatch(actualValue, expectedValue);
      }
    }
    if (expectedValue is AnalysisError) {
      if (actualValue is AnalysisError) {
        expect(actualValue.source, expectedValue.source);
        expect(actualValue.offset, expectedValue.offset);
        expect(actualValue.message, expectedValue.message);
      } else {
        _failTypeMismatch(actualValue, expectedValue);
      }
    }
  }

  void _validateTypes(DartType actualType, DartType expectedType, Set visited) {
    if (!visited.add(expectedType)) {
      return;
    }
    expect(actualType?.runtimeType, expectedType?.runtimeType);
    _validateElements(actualType.element, expectedType.element, visited);
  }

  /**
   * Create and return a source representing the given [file] within the given
   * [context].
   */
  static Source _createSourceInContext(AnalysisContext context, fs.File file) {
    Source source = file.createSource();
    if (context == null) {
      return source;
    }
    Uri uri = context.sourceFactory.restoreUri(source);
    return file.createSource(uri);
  }
}

/**
 * Compares tokens and ASTs, and built elements of declared identifiers.
 */
class _AstValidator extends AstComparator {
  @override
  bool isEqualNodes(AstNode expected, AstNode actual) {
    // TODO(scheglov) skip comments for now
    // [ElementBuilder.visitFunctionExpression] in resolver_test.dart
    // Going from c4493869ca19ef9ba6bd35d3d42e1209eb3b7e63
    // to         3977c9f2274df35df6332a65af9973fd6517bc12
    // With files:
    //  '/Users/scheglov/tmp/limited-invalidation/sdk/pkg/analyzer/lib/src/generated/resolver.dart',
    //  '/Users/scheglov/tmp/limited-invalidation/sdk/pkg/analyzer/lib/src/dart/element/builder.dart',
    //  '/Users/scheglov/tmp/limited-invalidation/sdk/pkg/analyzer/test/generated/resolver_test.dart',
    if (expected is CommentReference) {
      return true;
    }
    // Compare nodes.
    bool result = super.isEqualNodes(expected, actual);
    if (!result) {
      fail('|$actual| != expected |$expected|');
    }
    // Verify that identifiers have equal elements and types.
    if (expected is SimpleIdentifier && actual is SimpleIdentifier) {
      _verifyElements(actual.staticElement, expected.staticElement,
          '$expected staticElement');
      _verifyElements(actual.propagatedElement, expected.propagatedElement,
          '$expected staticElement');
      _verifyTypes(
          actual.staticType, expected.staticType, '$expected staticType');
      _verifyTypes(actual.propagatedType, expected.propagatedType,
          '$expected propagatedType');
      _verifyElements(actual.staticParameterElement,
          expected.staticParameterElement, '$expected staticParameterElement');
      _verifyElements(
          actual.propagatedParameterElement,
          expected.propagatedParameterElement,
          '$expected propagatedParameterElement');
    }
    return true;
  }

  void _verifyElements(Element actual, Element expected, String desc) {
    if (expected == null && actual == null) {
      return;
    }
    if (expected is MultiplyDefinedElement &&
        actual is MultiplyDefinedElement) {
      return;
    }
    while (expected is Member) {
      if (actual is Member) {
        actual = (actual as Member).baseElement;
        expected = (expected as Member).baseElement;
      } else {
        _failTypeMismatch(actual, expected, reason: desc);
      }
    }
    expect(actual, equals(expected), reason: desc);
  }

  void _verifyTypes(DartType actual, DartType expected, String desc) {
    _verifyElements(actual?.element, expected?.element, '$desc element');
    if (expected is InterfaceType) {
      if (actual is InterfaceType) {
        List<DartType> actualArguments = actual.typeArguments;
        List<DartType> expectedArguments = expected.typeArguments;
        expect(
            actualArguments,
            pairwiseCompare(expectedArguments, (a, b) {
              _verifyTypes(a, b, '$desc typeArguments');
              return true;
            }, 'elements'));
      } else {
        _failTypeMismatch(actual, expected);
      }
    }
  }
}
