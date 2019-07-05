// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:compiler/src/colors.dart' as colors;
import 'package:compiler/src/common.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/util/features.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/testing/annotated_code_helper.dart';

import '../helpers/memory_compiler.dart';
import '../equivalence/id_equivalence.dart';

/// `true` if ANSI colors are supported by stdout.
bool useColors = stdout.supportsAnsiEscapes;

/// Colorize a message [text], if ANSI colors are supported.
String colorizeMessage(String text) {
  if (useColors) {
    return '${colors.yellow(text)}';
  } else {
    return text;
  }
}

/// Colorize a matching annotation [text], if ANSI colors are supported.
String colorizeMatch(String text) {
  if (useColors) {
    return '${colors.blue(text)}';
  } else {
    return text;
  }
}

/// Colorize a single annotation [text], if ANSI colors are supported.
String colorizeSingle(String text) {
  if (useColors) {
    return '${colors.green(text)}';
  } else {
    return text;
  }
}

/// Colorize the actual annotation [text], if ANSI colors are supported.
String colorizeActual(String text) {
  if (useColors) {
    return '${colors.red(text)}';
  } else {
    return text;
  }
}

/// Colorize an expected annotation [text], if ANSI colors are supported.
String colorizeExpected(String text) {
  if (useColors) {
    return '${colors.green(text)}';
  } else {
    return text;
  }
}

/// Colorize delimiter [text], if ANSI colors are supported.
String colorizeDelimiter(String text) {
  if (useColors) {
    return '${colors.yellow(text)}';
  } else {
    return text;
  }
}

/// Colorize diffs [expected] and [actual] and [delimiter], if ANSI colors are
/// supported.
String colorizeDiff(String expected, String delimiter, String actual) {
  return '${colorizeExpected(expected)}'
      '${colorizeDelimiter(delimiter)}${colorizeActual(actual)}';
}

/// Colorize annotation delimiters [start] and [end] surrounding [text], if
/// ANSI colors are supported.
String colorizeAnnotation(String start, String text, String end) {
  return '${colorizeDelimiter(start)}$text${colorizeDelimiter(end)}';
}

abstract class DataComputer<T> {
  const DataComputer();

  /// Called before testing to setup flags needed for data collection.
  void setup() {}

  /// Called before testing to setup flags needed for data collection.
  void onCompilation(Compiler compiler) {}

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
  /// for the data origin.
  void computeMemberData(
      Compiler compiler, MemberEntity member, Map<Id, ActualData<T>> actualMap,
      {bool verbose});

  /// Returns `true` if [computeClassData] is supported.
  bool get computesClassData => false;

  /// Returns `true` if frontend member should be tested.
  bool get testFrontend => false;

  /// Function that computes a data mapping for [cls].
  ///
  /// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
  /// for the data origin.
  void computeClassData(
      Compiler compiler, ClassEntity cls, Map<Id, ActualData<T>> actualMap,
      {bool verbose}) {}

  DataInterpreter<T> get dataValidator;
}

const String stopAfterTypeInference = 'stopAfterTypeInference';

/// Reports [message] as an error using [spannable] as error location.
void reportError(
    DiagnosticReporter reporter, Spannable spannable, String message) {
  reporter
      .reportErrorMessage(spannable, MessageKind.GENERIC, {'text': message});
}

/// Display name used for strong mode compilation using the new common frontend.
const String strongName = 'strong mode';

/// Display name used for strong mode compilation without implicit checks using
/// the new common frontend.
const String omitName = 'strong mode without implicit checks';

/// Compute actual data for all members defined in the program with the
/// [entryPoint] and [memorySourceFiles].
///
/// Actual data is computed using [computeMemberData].
Future<CompiledData<T>> computeData<T>(Uri entryPoint,
    Map<String, String> memorySourceFiles, DataComputer<T> dataComputer,
    {List<String> options: const <String>[],
    bool verbose: false,
    bool testFrontend: false,
    bool printCode: false,
    bool forUserLibrariesOnly: true,
    bool skipUnprocessedMembers: false,
    bool skipFailedCompilations: false,
    Iterable<Id> globalIds: const <Id>[]}) async {
  OutputCollector outputCollector = new OutputCollector();
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      outputProvider: outputCollector,
      options: options,
      beforeRun: (compiler) {
        compiler.stopAfterTypeInference =
            options.contains(stopAfterTypeInference);
      });
  if (!result.isSuccess) {
    if (skipFailedCompilations) return null;
    Expect.isTrue(result.isSuccess, "Unexpected compilation error.");
  }
  if (printCode) {
    print('--code------------------------------------------------------------');
    print(outputCollector.getOutput('', OutputType.js));
    print('------------------------------------------------------------------');
  }
  Compiler compiler = result.compiler;
  dataComputer.onCompilation(compiler);
  dynamic closedWorld = testFrontend
      ? compiler.resolutionWorldBuilder.closedWorldForTesting
      : compiler.backendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  CommonElements commonElements = closedWorld.commonElements;

  Map<Uri, Map<Id, ActualData<T>>> actualMaps = <Uri, Map<Id, ActualData<T>>>{};
  Map<Id, ActualData<T>> globalData = <Id, ActualData<T>>{};

  Map<Id, ActualData<T>> actualMapFor(Entity entity) {
    SourceSpan span =
        compiler.backendStrategy.spanFromSpannable(entity, entity);
    Uri uri = span.uri;
    return actualMaps.putIfAbsent(uri, () => <Id, ActualData<T>>{});
  }

  void processMember(MemberEntity member, Map<Id, ActualData<T>> actualMap) {
    if (member.isAbstract) {
      return;
    }
    if (skipUnprocessedMembers &&
        !closedWorld.processedMembers.contains(member)) {
      return;
    }
    if (member.enclosingClass != null) {
      if (elementEnvironment.isEnumClass(member.enclosingClass)) {
        if (member.isConstructor ||
            member.isInstanceMember ||
            member.name == 'values') {
          return;
        }
      }
      if (member.isConstructor &&
          elementEnvironment.isMixinApplication(member.enclosingClass)) {
        return;
      }
    }
    dataComputer.computeMemberData(compiler, member, actualMap,
        verbose: verbose);
  }

  void processClass(ClassEntity cls, Map<Id, ActualData<T>> actualMap) {
    if (skipUnprocessedMembers && !closedWorld.isImplemented(cls)) {
      return;
    }
    dataComputer.computeClassData(compiler, cls, actualMap, verbose: verbose);
  }

  bool excludeLibrary(LibraryEntity library) {
    return forUserLibrariesOnly &&
        (library.canonicalUri.scheme == 'dart' ||
            library.canonicalUri.scheme == 'package');
  }

  if (dataComputer.computesClassData) {
    for (LibraryEntity library in elementEnvironment.libraries) {
      if (excludeLibrary(library)) continue;
      elementEnvironment.forEachClass(library, (ClassEntity cls) {
        processClass(cls, actualMapFor(cls));
      });
    }
  }
  for (MemberEntity member in closedWorld.processedMembers) {
    if (excludeLibrary(member.library)) continue;
    processMember(member, actualMapFor(member));
  }

  List<LibraryEntity> globalLibraries = <LibraryEntity>[
    commonElements.coreLibrary,
    elementEnvironment.lookupLibrary(Uri.parse('dart:collection')),
    commonElements.interceptorsLibrary,
    commonElements.jsHelperLibrary,
    commonElements.asyncLibrary,
  ];

  LibraryEntity htmlLibrary =
      elementEnvironment.lookupLibrary(Uri.parse('dart:html'), required: false);
  if (htmlLibrary != null) {
    globalLibraries.add(htmlLibrary);
  }

  ClassEntity getGlobalClass(String className) {
    ClassEntity cls;
    for (LibraryEntity library in globalLibraries) {
      cls ??= elementEnvironment.lookupClass(library, className);
    }
    Expect.isNotNull(
        cls,
        "Global class '$className' not found in the global "
        "libraries: ${globalLibraries.map((l) => l.canonicalUri).join(', ')}");
    return cls;
  }

  MemberEntity getGlobalMember(String memberName) {
    MemberEntity member;
    for (LibraryEntity library in globalLibraries) {
      member ??= elementEnvironment.lookupLibraryMember(library, memberName);
    }
    Expect.isNotNull(
        member,
        "Global member '$memberName' not found in the global "
        "libraries: ${globalLibraries.map((l) => l.canonicalUri).join(', ')}");
    return member;
  }

  for (Id id in globalIds) {
    if (id is MemberId) {
      MemberEntity member;
      if (id.className != null) {
        ClassEntity cls = getGlobalClass(id.className);
        member = elementEnvironment.lookupClassMember(cls, id.memberName);
        member ??= elementEnvironment.lookupConstructor(cls, id.memberName);
        Expect.isNotNull(
            member, "Global member '$member' not found in class $cls.");
      } else {
        member = getGlobalMember(id.memberName);
      }
      processMember(member, globalData);
    } else if (id is ClassId) {
      if (dataComputer.computesClassData) {
        ClassEntity cls = getGlobalClass(id.className);
        processClass(cls, globalData);
      }
    } else {
      throw new UnsupportedError("Unexpected global id: $id");
    }
  }

  return new CompiledData<T>(
      compiler, elementEnvironment, entryPoint, actualMaps, globalData);
}

class CompiledData<T> {
  final Compiler compiler;
  final ElementEnvironment elementEnvironment;
  final Uri mainUri;
  final Map<Uri, Map<Id, ActualData<T>>> actualMaps;
  final Map<Id, ActualData<T>> globalData;

  CompiledData(this.compiler, this.elementEnvironment, this.mainUri,
      this.actualMaps, this.globalData);

  Map<int, List<String>> computeAnnotations(Uri uri) {
    Map<Id, ActualData<T>> thisMap = actualMaps[uri];
    Map<int, List<String>> annotations = <int, List<String>>{};
    thisMap.forEach((Id id, ActualData<T> data1) {
      String value1 = '${data1.value}';
      annotations
          .putIfAbsent(data1.offset, () => [])
          .add(colorizeActual(value1));
    });
    return annotations;
  }

  Map<int, List<String>> computeDiffAnnotationsAgainst(
      Map<Id, ActualData<T>> thisMap, Map<Id, ActualData<T>> otherMap, Uri uri,
      {bool includeMatches: false}) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    thisMap.forEach((Id id, ActualData<T> data1) {
      ActualData<T> data2 = otherMap[id];
      String value1 = '${data1.value}';
      if (data1.value != data2?.value) {
        String value2 = '${data2?.value ?? '---'}';
        annotations
            .putIfAbsent(data1.offset, () => [])
            .add(colorizeDiff(value1, ' | ', value2));
      } else if (includeMatches) {
        annotations
            .putIfAbsent(data1.offset, () => [])
            .add(colorizeMatch(value1));
      }
    });
    otherMap.forEach((Id id, ActualData<T> data2) {
      if (!thisMap.containsKey(id)) {
        String value1 = '---';
        String value2 = '${data2.value}';
        annotations
            .putIfAbsent(data2.offset, () => [])
            .add(colorizeDiff(value1, ' | ', value2));
      }
    });
    return annotations;
  }
}

String withAnnotations(String sourceCode, Map<int, List<String>> annotations) {
  StringBuffer sb = new StringBuffer();
  int end = 0;
  for (int offset in annotations.keys.toList()..sort()) {
    if (offset >= sourceCode.length) {
      sb.write('...');
      return sb.toString();
    }
    if (offset > end) {
      sb.write(sourceCode.substring(end, offset));
    }
    for (String annotation in annotations[offset]) {
      sb.write(colorizeAnnotation('/*', annotation, '*/'));
    }
    end = offset;
  }
  if (end < sourceCode.length) {
    sb.write(sourceCode.substring(end));
  }
  return sb.toString();
}

/// Data collected by [computeData].
class IdData<T> {
  final Map<Uri, AnnotatedCode> code;
  final MemberAnnotations<IdValue> expectedMaps;
  final CompiledData _compiledData;
  final MemberAnnotations<ActualData<T>> _actualMaps = new MemberAnnotations();

  IdData(this.code, this.expectedMaps, this._compiledData) {
    for (Uri uri in code.keys) {
      _actualMaps[uri] = _compiledData.actualMaps[uri] ?? <Id, ActualData<T>>{};
    }
    _actualMaps.globalData.addAll(_compiledData.globalData);
  }

  Compiler get compiler => _compiledData.compiler;
  ElementEnvironment get elementEnvironment => _compiledData.elementEnvironment;
  Uri get mainUri => _compiledData.mainUri;
  MemberAnnotations<ActualData<T>> get actualMaps => _actualMaps;

  String actualCode(Uri uri) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMaps[uri].forEach((Id id, ActualData<T> data) {
      annotations.putIfAbsent(data.offset, () => []).add('${data.value}');
    });
    return withAnnotations(code[uri].sourceCode, annotations);
  }

  String diffCode(Uri uri, DataInterpreter<T> dataValidator) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMaps[uri].forEach((Id id, ActualData<T> data) {
      IdValue expectedValue = expectedMaps[uri][id];
      T actualValue = data.value;
      String unexpectedMessage =
          dataValidator.isAsExpected(actualValue, expectedValue?.value);
      if (unexpectedMessage != null) {
        String expected = expectedValue?.toString() ?? '';
        String actual = dataValidator.getText(actualValue);
        int offset = getOffsetFromId(id, uri);
        if (offset != null) {
          String value1 = '${expected}';
          String value2 = IdValue.idToString(id, '${actual}');
          annotations
              .putIfAbsent(offset, () => [])
              .add(colorizeDiff(value1, ' | ', value2));
        }
      }
    });
    expectedMaps[uri].forEach((Id id, IdValue expected) {
      if (!actualMaps[uri].containsKey(id)) {
        int offset = getOffsetFromId(id, uri);
        if (offset != null) {
          String value1 = '${expected}';
          String value2 = '---';
          annotations
              .putIfAbsent(offset, () => [])
              .add(colorizeDiff(value1, ' | ', value2));
        }
      }
    });
    return withAnnotations(code[uri].sourceCode, annotations);
  }

  int getOffsetFromId(Id id, Uri uri) {
    return compiler.reporter
        .spanFromSpannable(computeSpannable(elementEnvironment, uri, id))
        ?.begin;
  }
}

/// Encapsulates the member data computed for each source file of interest.
/// It's a glorified wrapper around a map of maps, but written this way to
/// provide a little more information about what it's doing. [DataType] refers
/// to the type this map is holding -- it is either [IdValue] or [ActualData].
class MemberAnnotations<DataType> {
  /// For each Uri, we create a map associating an element id with its
  /// corresponding annotations.
  final Map<Uri, Map<Id, DataType>> _computedDataForEachFile =
      new Map<Uri, Map<Id, DataType>>();

  /// Member or class annotations that don't refer to any of the user files.
  final Map<Id, DataType> globalData = <Id, DataType>{};

  void operator []=(Uri file, Map<Id, DataType> computedData) {
    _computedDataForEachFile[file] = computedData;
  }

  void forEach(void f(Uri file, Map<Id, DataType> computedData)) {
    _computedDataForEachFile.forEach(f);
  }

  Map<Id, DataType> operator [](Uri file) {
    if (!_computedDataForEachFile.containsKey(file)) {
      _computedDataForEachFile[file] = <Id, DataType>{};
    }
    return _computedDataForEachFile[file];
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('MemberAnnotations(');
    String comma = '';
    if (_computedDataForEachFile.isNotEmpty &&
        (_computedDataForEachFile.length > 1 ||
            _computedDataForEachFile.values.single.isNotEmpty)) {
      sb.write('data:{');
      _computedDataForEachFile.forEach((Uri uri, Map<Id, DataType> data) {
        sb.write(comma);
        sb.write('$uri:');
        sb.write(data);
        comma = ',';
      });
      sb.write('}');
    }
    if (globalData.isNotEmpty) {
      sb.write(comma);
      sb.write('global:');
      sb.write(globalData);
    }
    sb.write(')');
    return sb.toString();
  }
}

typedef void Callback();

/// Check code for all test files int [data] using [computeFromAst] and
/// [computeFromKernel] from the respective front ends. If [skipForKernel]
/// contains the name of the test file it isn't tested for kernel.
///
/// [libDirectory] contains the directory for any supporting libraries that need
/// to be loaded. We expect supporting libraries to have the same prefix as the
/// original test in [dataDir]. So, for example, if testing `foo.dart` in
/// [dataDir], then this function will consider any files named `foo.*\.dart`,
/// such as `foo2.dart`, `foo_2.dart`, and `foo_blah_blah_blah.dart` in
/// [libDirectory] to be supporting library files for `foo.dart`.
/// [setUpFunction] is called once for every test that is executed.
/// If [forUserSourceFilesOnly] is true, we examine the elements in the main
/// file and any supporting libraries.
Future checkTests<T>(Directory dataDir, DataComputer<T> dataComputer,
    {List<String> skipForStrong: const <String>[],
    bool filterActualData(IdValue idValue, ActualData<T> actualData),
    List<String> options: const <String>[],
    List<String> args: const <String>[],
    Directory libDirectory: null,
    bool forUserLibrariesOnly: true,
    Callback setUpFunction,
    int shards: 1,
    int shardIndex: 0,
    bool testOmit: true,
    bool testCFEConstants: false,
    void onTest(Uri uri)}) async {
  dataComputer.setup();

  args = args.toList();
  bool verbose = args.remove('-v');
  bool shouldContinue = args.remove('-c');
  bool testAfterFailures = args.remove('-a');
  bool printCode = args.remove('-p');
  bool continued = false;
  bool hasFailures = false;

  var relativeDir = dataDir.uri.path.replaceAll(Uri.base.path, '');
  print('Data dir: ${relativeDir}');
  List<FileSystemEntity> entities = dataDir.listSync();
  if (shards > 1) {
    int start = entities.length * shardIndex ~/ shards;
    int end = entities.length * (shardIndex + 1) ~/ shards;
    entities = entities.sublist(start, end);
  }
  int testCount = 0;
  for (FileSystemEntity entity in entities) {
    String name = entity.uri.pathSegments.last;
    if (args.isNotEmpty && !args.contains(name) && !continued) continue;
    if (shouldContinue) continued = true;
    testCount++;
    List<String> testOptions = options.toList();
    if (name.endsWith('_ea.dart')) {
      testOptions.add(Flags.enableAsserts);
    }

    if (onTest != null) {
      onTest(entity.uri);
    }
    print('----------------------------------------------------------------');
    print('Test file: ${entity.uri}');
    // Pretend this is a dart2js_native test to allow use of 'native' keyword
    // and import of private libraries.
    String commonTestPath = 'sdk/tests/compiler';
    Uri entryPoint =
        Uri.parse('memory:$commonTestPath/dart2js_native/main.dart');
    String annotatedCode = await new File.fromUri(entity.uri).readAsString();
    userFiles.add('main.dart');
    Map<Uri, AnnotatedCode> code = {
      entryPoint:
          new AnnotatedCode.fromText(annotatedCode, commentStart, commentEnd)
    };
    Map<String, MemberAnnotations<IdValue>> expectedMaps = {
      strongMarker: new MemberAnnotations<IdValue>(),
      omitMarker: new MemberAnnotations<IdValue>(),
      strongConstMarker: new MemberAnnotations<IdValue>(),
      omitConstMarker: new MemberAnnotations<IdValue>(),
    };
    computeExpectedMap(entryPoint, code[entryPoint], expectedMaps);
    Map<String, String> memorySourceFiles = {
      entryPoint.path: code[entryPoint].sourceCode
    };

    if (libDirectory != null) {
      print('Supporting libraries:');
      String filePrefix = name.substring(0, name.lastIndexOf('.'));
      await for (FileSystemEntity libEntity in libDirectory.list()) {
        String libFileName = libEntity.uri.pathSegments.last;
        if (libFileName.startsWith(filePrefix)) {
          print('    - libs/$libFileName');
          Uri libFileUri =
              Uri.parse('memory:$commonTestPath/libs/$libFileName');
          userFiles.add(libEntity.uri.pathSegments.last);
          String libCode = await new File.fromUri(libEntity.uri).readAsString();
          AnnotatedCode annotatedLibCode =
              new AnnotatedCode.fromText(libCode, commentStart, commentEnd);
          memorySourceFiles[libFileUri.path] = annotatedLibCode.sourceCode;
          code[libFileUri] = annotatedLibCode;
          computeExpectedMap(libFileUri, annotatedLibCode, expectedMaps);
        }
      }
    }

    if (setUpFunction != null) setUpFunction();

    Future runTests({bool useCFEConstants: false}) async {
      if (skipForStrong.contains(name)) {
        print('--skipped for kernel (strong mode)----------------------------');
      } else {
        print('--from kernel (strong mode)-----------------------------------');
        List<String> options = new List<String>.from(testOptions);
        String marker = strongMarker;
        if (useCFEConstants) {
          marker = strongConstMarker;
          options
              .add('${Flags.enableLanguageExperiments}=constant-update-2018');
        } else {
          options.add(
              '${Flags.enableLanguageExperiments}=no-constant-update-2018');
        }
        MemberAnnotations<IdValue> annotations = expectedMaps[marker];
        CompiledData<T> compiledData2 = await computeData(
            entryPoint, memorySourceFiles, dataComputer,
            options: options,
            verbose: verbose,
            printCode: printCode,
            testFrontend: dataComputer.testFrontend,
            forUserLibrariesOnly: forUserLibrariesOnly,
            globalIds: annotations.globalData.keys);
        if (await checkCode(strongName, entity.uri, code, annotations,
            compiledData2, dataComputer.dataValidator,
            filterActualData: filterActualData,
            fatalErrors: !testAfterFailures)) {
          hasFailures = true;
        }
      }
      if (testOmit) {
        if (skipForStrong.contains(name)) {
          print(
              '--skipped for kernel (strong mode, omit-implicit-checks)------');
        } else {
          print(
              '--from kernel (strong mode, omit-implicit-checks)-------------');
          List<String> options = [
            Flags.omitImplicitChecks,
            Flags.laxRuntimeTypeToString
          ]..addAll(testOptions);
          String marker = omitMarker;
          if (useCFEConstants) {
            marker = omitConstMarker;
            options
                .add('${Flags.enableLanguageExperiments}=constant-update-2018');
          } else {
            options.add(
                '${Flags.enableLanguageExperiments}=no-constant-update-2018');
          }
          MemberAnnotations<IdValue> annotations = expectedMaps[marker];
          CompiledData<T> compiledData2 = await computeData(
              entryPoint, memorySourceFiles, dataComputer,
              options: options,
              verbose: verbose,
              testFrontend: dataComputer.testFrontend,
              forUserLibrariesOnly: forUserLibrariesOnly,
              globalIds: annotations.globalData.keys);
          if (await checkCode(omitName, entity.uri, code, annotations,
              compiledData2, dataComputer.dataValidator,
              filterActualData: filterActualData,
              fatalErrors: !testAfterFailures)) {
            hasFailures = true;
          }
        }
      }
    }

    await runTests();
    if (testCFEConstants) {
      print('--use cfe constants---------------------------------------------');
      await runTests(useCFEConstants: true);
    }
  }
  Expect.isFalse(hasFailures, 'Errors found.');
  Expect.isTrue(testCount > 0, "No files were tested.");
}

final Set<String> userFiles = new Set<String>();

/// Interface used for interpreting annotations.
abstract class DataInterpreter<T> {
  /// Returns `null` if [actualData] satisfies the [expectedData] annotation.
  /// Otherwise, a message is returned contain the information about the
  /// problems found.
  String isAsExpected(T actualData, String expectedData);

  /// Returns `true` if [actualData] corresponds to empty data.
  bool isEmpty(T actualData);

  /// Returns a textual representation of [actualData].
  String getText(T actualData);
}

/// Default data interpreter for string data.
class StringDataInterpreter implements DataInterpreter<String> {
  const StringDataInterpreter();

  @override
  String isAsExpected(String actualData, String expectedData) {
    actualData ??= '';
    expectedData ??= '';
    if (actualData != expectedData) {
      return "Expected $expectedData, found $actualData";
    }
    return null;
  }

  @override
  bool isEmpty(String actualData) {
    return actualData == '';
  }

  @override
  String getText(String actualData) {
    return actualData;
  }
}

class FeaturesDataInterpreter implements DataInterpreter<Features> {
  const FeaturesDataInterpreter();

  @override
  String isAsExpected(Features actualFeatures, String expectedData) {
    if (expectedData == '*') {
      return null;
    } else if (expectedData == '') {
      return actualFeatures.isNotEmpty ? "Expected empty data." : null;
    } else {
      List<String> errorsFound = [];
      Features expectedFeatures = Features.fromText(expectedData);
      Set<String> validatedFeatures = new Set<String>();
      expectedFeatures.forEach((String key, Object expectedValue) {
        bool expectMatch = true;
        if (key.startsWith('!')) {
          key = key.substring(1);
          expectMatch = false;
        }
        validatedFeatures.add(key);
        Object actualValue = actualFeatures[key];
        if (!expectMatch) {
          if (actualFeatures.containsKey(key)) {
            errorsFound.add('Unexpected data found for $key=$actualValue');
          }
        } else if (!actualFeatures.containsKey(key)) {
          errorsFound.add('No data found for $key');
        } else if (expectedValue == '') {
          if (actualValue != '') {
            errorsFound.add('Non-empty data found for $key');
          }
        } else if (expectedValue == '*') {
          return;
        } else if (expectedValue is List) {
          if (actualValue is List) {
            List actualList = actualValue.toList();
            for (Object expectedObject in expectedValue) {
              String expectedText = '$expectedObject';
              bool matchFound = false;
              if (expectedText.endsWith('*')) {
                // Wildcard matcher.
                String prefix =
                    expectedText.substring(0, expectedText.indexOf('*'));
                List matches = [];
                for (Object actualObject in actualList) {
                  if ('$actualObject'.startsWith(prefix)) {
                    matches.add(actualObject);
                    matchFound = true;
                  }
                }
                for (Object match in matches) {
                  actualList.remove(match);
                }
              } else {
                for (Object actualObject in actualList) {
                  if (expectedText == '$actualObject') {
                    actualList.remove(actualObject);
                    matchFound = true;
                    break;
                  }
                }
              }
              if (!matchFound) {
                errorsFound.add("No match found for $key=[$expectedText]");
              }
            }
            if (actualList.isNotEmpty) {
              errorsFound
                  .add("Extra data found $key=[${actualList.join(',')}]");
            }
          } else {
            errorsFound.add("List data expected for $key: "
                "expected '$expectedValue', found '${actualValue}'");
          }
        } else if (expectedValue != actualValue) {
          errorsFound.add(
              "Mismatch for $key: expected '$expectedValue', found '${actualValue}'");
        }
      });
      actualFeatures.forEach((String key, Object value) {
        if (!validatedFeatures.contains(key)) {
          if (value == '') {
            errorsFound.add("Extra data found '$key'");
          } else {
            errorsFound.add("Extra data found $key=$value");
          }
        }
      });
      return errorsFound.isNotEmpty ? errorsFound.join('\n ') : null;
    }
  }

  @override
  String getText(Features actualData) {
    return actualData.getText();
  }

  @override
  bool isEmpty(Features actualData) {
    return actualData == null || actualData.isEmpty;
  }
}

/// Checks [compiledData] against the expected data in [expectedMap] derived
/// from [code].
Future<bool> checkCode<T>(
    String mode,
    Uri mainFileUri,
    Map<Uri, AnnotatedCode> code,
    MemberAnnotations<IdValue> expectedMaps,
    CompiledData compiledData,
    DataInterpreter<T> dataValidator,
    {bool filterActualData(IdValue expected, ActualData<T> actualData),
    bool fatalErrors: true}) async {
  IdData<T> data = new IdData<T>(code, expectedMaps, compiledData);
  bool hasFailure = false;
  Set<Uri> neededDiffs = new Set<Uri>();

  void checkActualMap(
      Map<Id, ActualData<T>> actualMap, Map<Id, IdValue> expectedMap,
      [Uri uri]) {
    bool hasLocalFailure = false;
    actualMap.forEach((Id id, ActualData<T> actualData) {
      T actual = actualData.value;
      String actualText = dataValidator.getText(actual);

      if (!expectedMap.containsKey(id)) {
        if (!dataValidator.isEmpty(actual)) {
          reportError(
              data.compiler.reporter,
              computeSourceSpanFromUriOffset(actualData.uri, actualData.offset),
              'EXTRA $mode DATA for ${id.descriptor}:\n '
              'object   : ${actualData.objectText}\n '
              'actual   : ${colorizeActual('${IdValue.idToString(id, actualText)}')}\n '
              'Data was expected for these ids: ${expectedMap.keys}');
          if (filterActualData == null || filterActualData(null, actualData)) {
            hasLocalFailure = true;
          }
        }
      } else {
        IdValue expected = expectedMap[id];
        String unexpectedMessage =
            dataValidator.isAsExpected(actual, expected.value);
        if (unexpectedMessage != null) {
          reportError(
              data.compiler.reporter,
              computeSourceSpanFromUriOffset(actualData.uri, actualData.offset),
              'UNEXPECTED $mode DATA for ${id.descriptor}:\n '
              'detail  : ${colorizeMessage(unexpectedMessage)}\n '
              'object  : ${actualData.objectText}\n '
              'expected: ${colorizeExpected('$expected')}\n '
              'actual  : ${colorizeActual('${IdValue.idToString(id, actualText)}')}');
          if (filterActualData == null ||
              filterActualData(expected, actualData)) {
            hasLocalFailure = true;
          }
        }
      }
    });
    if (hasLocalFailure) {
      hasFailure = true;
      if (uri != null) {
        neededDiffs.add(uri);
      }
    }
  }

  data.actualMaps.forEach((Uri uri, Map<Id, ActualData<T>> actualMap) {
    checkActualMap(actualMap, data.expectedMaps[uri], uri);
  });
  checkActualMap(data.actualMaps.globalData, data.expectedMaps.globalData);

  Set<Id> missingIds = new Set<Id>();
  void checkMissing(
      Map<Id, IdValue> expectedMap, Map<Id, ActualData<T>> actualMap,
      [Uri uri]) {
    expectedMap.forEach((Id id, IdValue expected) {
      if (!actualMap.containsKey(id)) {
        missingIds.add(id);
        String message = 'MISSING $mode DATA for ${id.descriptor}: '
            'Expected ${colors.green('$expected')}';
        if (uri != null) {
          reportError(data.compiler.reporter,
              computeSpannable(data.elementEnvironment, uri, id), message);
        } else {
          print(message);
        }
      }
    });
    if (missingIds.isNotEmpty && uri != null) {
      neededDiffs.add(uri);
    }
  }

  data.expectedMaps.forEach((Uri uri, Map<Id, IdValue> expectedMap) {
    checkMissing(expectedMap, data.actualMaps[uri], uri);
  });
  checkMissing(data.expectedMaps.globalData, data.actualMaps.globalData);
  for (Uri uri in neededDiffs) {
    print('--annotations diff [${uri.pathSegments.last}]-------------');
    print(data.diffCode(uri, dataValidator));
    print('----------------------------------------------------------');
  }
  if (missingIds.isNotEmpty) {
    print("MISSING ids: ${missingIds}.");
    hasFailure = true;
  }
  if (hasFailure && fatalErrors) {
    Expect.fail('Errors found.');
  }
  return hasFailure;
}

/// Compute a [Spannable] from an [id] in the library [mainUri].
Spannable computeSpannable(
    ElementEnvironment elementEnvironment, Uri mainUri, Id id) {
  if (id is NodeId) {
    return new SourceSpan(mainUri, id.value, id.value + 1);
  } else if (id is MemberId) {
    String memberName = id.memberName;
    bool isSetter = false;
    if (memberName != '[]=' && memberName != '==' && memberName.endsWith('=')) {
      isSetter = true;
      memberName = memberName.substring(0, memberName.length - 1);
    }
    LibraryEntity library = elementEnvironment.lookupLibrary(mainUri);
    if (id.className != null) {
      ClassEntity cls = elementEnvironment.lookupClass(library, id.className);
      if (cls == null) {
        // Constant expression in CFE might remove inlined parts of sources.
        print("No class '${id.className}' in $mainUri.");
        return NO_LOCATION_SPANNABLE;
      }
      MemberEntity member = elementEnvironment
          .lookupClassMember(cls, memberName, setter: isSetter);
      if (member == null) {
        ConstructorEntity constructor =
            elementEnvironment.lookupConstructor(cls, memberName);
        if (constructor == null) {
          // Constant expression in CFE might remove inlined parts of sources.
          print("No class member '${memberName}' in $cls.");
          return NO_LOCATION_SPANNABLE;
        }
        return constructor;
      }
      return member;
    } else {
      MemberEntity member = elementEnvironment
          .lookupLibraryMember(library, memberName, setter: isSetter);
      if (member == null) {
        // Constant expression in CFE might remove inlined parts of sources.
        print("No member '${memberName}' in $mainUri.");
        return NO_LOCATION_SPANNABLE;
      }
      return member;
    }
  } else if (id is ClassId) {
    LibraryEntity library = elementEnvironment.lookupLibrary(mainUri);
    ClassEntity cls = elementEnvironment.lookupClass(library, id.className);
    if (cls == null) {
      // Constant expression in CFE might remove inlined parts of sources.
      print("No class '${id.className}' in $mainUri.");
      return NO_LOCATION_SPANNABLE;
    }
    return cls;
  }
  throw new UnsupportedError('Unsupported id $id.');
}

const String strongMarker = 'strong.';
const String omitMarker = 'omit.';
const String strongConstMarker = 'strongConst.';
const String omitConstMarker = 'omitConst.';

/// Compute three [MemberAnnotations] objects from [code] specifying the
/// expected annotations we anticipate encountering; one corresponding to the
/// old implementation, one for the new implementation, and one for the new
/// implementation using strong mode.
///
/// If an annotation starts with 'ast.' it is only expected for the old
/// implementation, if it starts with 'kernel.' it is only expected for the
/// new implementation, and if it starts with 'strong.' it is only expected for
/// strong mode (using the common frontend). Otherwise it is expected for all
/// implementations.
///
/// Most nodes have the same and expectations should match this by using
/// annotations without prefixes.
void computeExpectedMap(Uri sourceUri, AnnotatedCode code,
    Map<String, MemberAnnotations<IdValue>> maps) {
  List<String> mapKeys = maps.keys.toList();
  Map<String, AnnotatedCode> split = splitByPrefixes(code, mapKeys);

  split.forEach((String marker, AnnotatedCode code) {
    MemberAnnotations<IdValue> fileAnnotations = maps[marker];
    assert(fileAnnotations != null, "No annotations for $marker in $maps");
    Map<Id, IdValue> expectedValues = fileAnnotations[sourceUri];
    for (Annotation annotation in code.annotations) {
      String text = annotation.text;
      IdValue idValue = IdValue.decode(annotation.offset, text);
      if (idValue.id.isGlobal) {
        Expect.isFalse(
            fileAnnotations.globalData.containsKey(idValue.id),
            "Duplicate annotations for ${idValue.id} in $marker: "
            "${idValue} and ${fileAnnotations.globalData[idValue.id]}.");
        fileAnnotations.globalData[idValue.id] = idValue;
      } else {
        Expect.isFalse(
            expectedValues.containsKey(idValue.id),
            "Duplicate annotations for ${idValue.id} in $marker: "
            "${idValue} and ${expectedValues[idValue.id]}.");
        expectedValues[idValue.id] = idValue;
      }
    }
  });
}
