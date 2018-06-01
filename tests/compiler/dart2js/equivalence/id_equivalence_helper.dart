// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:compiler/src/colors.dart' as colors;
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import 'package:sourcemap_testing/src/annotated_code_helper.dart';

import '../memory_compiler.dart';
import '../equivalence/id_equivalence.dart';

/// `true` if ANSI colors are supported by stdout.
bool useColors = stdout.supportsAnsiEscapes;

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

/// Function that computes a data mapping for [member].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
typedef void ComputeMemberDataFunction(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose});

/// Function that computes a data mapping for [cls].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
typedef void ComputeClassDataFunction(
    Compiler compiler, ClassEntity cls, Map<Id, ActualData> actualMap,
    {bool verbose});

abstract class DataComputer {
  void setup();

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
  /// for the data origin.
  void computeMemberData(
      Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
      {bool verbose});

  /// Function that computes a data mapping for [cls].
  ///
  /// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
  /// for the data origin.
  void computeClassData(
      Compiler compiler, ClassEntity cls, Map<Id, ActualData> actualMap,
      {bool verbose});
}

const String stopAfterTypeInference = 'stopAfterTypeInference';

/// Reports [message] as an error using [spannable] as error location.
void reportError(
    DiagnosticReporter reporter, Spannable spannable, String message) {
  reporter
      .reportErrorMessage(spannable, MessageKind.GENERIC, {'text': message});
}

/// Display name used for compilation using the new common frontend.
const String kernelName = 'kernel';

/// Display name used for strong mode compilation using the new common frontend.
const String strongName = 'strong mode';

/// Display name used for strong mode compilation without implicit checks using
/// the new common frontend.
const String trustName = 'strong mode without implicit checks';

/// Compute actual data for all members defined in the program with the
/// [entryPoint] and [memorySourceFiles].
///
/// Actual data is computed using [computeMemberData].
Future<CompiledData> computeData(
    Uri entryPoint,
    Map<String, String> memorySourceFiles,
    ComputeMemberDataFunction computeMemberData,
    {List<String> options: const <String>[],
    bool verbose: false,
    bool testFrontend: false,
    bool forUserLibrariesOnly: true,
    bool skipUnprocessedMembers: false,
    bool skipFailedCompilations: false,
    ComputeClassDataFunction computeClassData,
    Iterable<Id> globalIds: const <Id>[]}) async {
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: options,
      beforeRun: (compiler) {
        compiler.stopAfterTypeInference =
            options.contains(stopAfterTypeInference);
      });
  if (!result.isSuccess) {
    if (skipFailedCompilations) return null;
    Expect.isTrue(result.isSuccess, "Unexpected compilation error.");
  }
  Compiler compiler = result.compiler;
  ClosedWorld closedWorld = testFrontend
      ? compiler.resolutionWorldBuilder.closedWorldForTesting
      : compiler.backendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  CommonElements commonElements = closedWorld.commonElements;

  Map<Uri, Map<Id, ActualData>> actualMaps = <Uri, Map<Id, ActualData>>{};
  Map<Id, ActualData> globalData = <Id, ActualData>{};

  Map<Id, ActualData> actualMapFor(Entity entity) {
    SourceSpan span =
        compiler.backendStrategy.spanFromSpannable(entity, entity);
    Uri uri = span.uri;
    return actualMaps.putIfAbsent(uri, () => <Id, ActualData>{});
  }

  void processMember(MemberEntity member, Map<Id, ActualData> actualMap) {
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
    computeMemberData(compiler, member, actualMap, verbose: verbose);
  }

  void processClass(ClassEntity cls, Map<Id, ActualData> actualMap) {
    if (skipUnprocessedMembers && !closedWorld.isImplemented(cls)) {
      return;
    }
    computeClassData(compiler, cls, actualMap, verbose: verbose);
  }

  bool excludeLibrary(LibraryEntity library) {
    return forUserLibrariesOnly &&
        (library.canonicalUri.scheme == 'dart' ||
            library.canonicalUri.scheme == 'package');
  }

  if (computeClassData != null) {
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
    if (id is ElementId) {
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
      if (computeClassData != null) {
        ClassEntity cls = getGlobalClass(id.className);
        processClass(cls, globalData);
      }
    } else {
      throw new UnsupportedError("Unexpected global id: $id");
    }
  }

  return new CompiledData(
      compiler, elementEnvironment, entryPoint, actualMaps, globalData);
}

class CompiledData {
  final Compiler compiler;
  final ElementEnvironment elementEnvironment;
  final Uri mainUri;
  final Map<Uri, Map<Id, ActualData>> actualMaps;
  final Map<Id, ActualData> globalData;

  CompiledData(this.compiler, this.elementEnvironment, this.mainUri,
      this.actualMaps, this.globalData);

  Map<int, List<String>> computeAnnotations(Uri uri) {
    Map<Id, ActualData> thisMap = actualMaps[uri];
    Map<int, List<String>> annotations = <int, List<String>>{};
    thisMap.forEach((Id id, ActualData data1) {
      String value1 = '${data1.value}';
      annotations
          .putIfAbsent(data1.offset, () => [])
          .add(colorizeActual(value1));
    });
    return annotations;
  }

  Map<int, List<String>> computeDiffAnnotationsAgainst(
      Map<Id, ActualData> thisMap, Map<Id, ActualData> otherMap, Uri uri,
      {bool includeMatches: false}) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    thisMap.forEach((Id id, ActualData data1) {
      ActualData data2 = otherMap[id];
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
    otherMap.forEach((Id id, ActualData data2) {
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
class IdData {
  final Map<Uri, AnnotatedCode> code;
  final MemberAnnotations<IdValue> expectedMaps;
  final CompiledData _compiledData;
  final MemberAnnotations<ActualData> _actualMaps = new MemberAnnotations();

  IdData(this.code, this.expectedMaps, this._compiledData) {
    for (Uri uri in code.keys) {
      _actualMaps[uri] = _compiledData.actualMaps[uri] ?? <Id, ActualData>{};
    }
    _actualMaps.globalData.addAll(_compiledData.globalData);
  }

  Compiler get compiler => _compiledData.compiler;
  ElementEnvironment get elementEnvironment => _compiledData.elementEnvironment;
  Uri get mainUri => _compiledData.mainUri;
  MemberAnnotations<ActualData> get actualMaps => _actualMaps;

  String actualCode(Uri uri) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMaps[uri].forEach((Id id, ActualData data) {
      annotations
          .putIfAbsent(data.sourceSpan.begin, () => [])
          .add('${data.value}');
    });
    return withAnnotations(code[uri].sourceCode, annotations);
  }

  String diffCode(Uri uri) {
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMaps[uri].forEach((Id id, ActualData data) {
      IdValue value = expectedMaps[uri][id];
      if (data.value != value || value == null && data.value.value != '') {
        String expected = value?.toString() ?? '';
        int offset = getOffsetFromId(id, uri);
        String value1 = '${expected}';
        String value2 = '${data.value}';
        annotations
            .putIfAbsent(offset, () => [])
            .add(colorizeDiff(value1, ' | ', value2));
      }
    });
    expectedMaps[uri].forEach((Id id, IdValue expected) {
      if (!actualMaps[uri].containsKey(id)) {
        int offset = getOffsetFromId(id, uri);
        String value1 = '${expected}';
        String value2 = '---';
        annotations
            .putIfAbsent(offset, () => [])
            .add(colorizeDiff(value1, ' | ', value2));
      }
    });
    return withAnnotations(code[uri].sourceCode, annotations);
  }

  int getOffsetFromId(Id id, Uri uri) {
    return compiler.reporter
        .spanFromSpannable(computeSpannable(elementEnvironment, uri, id))
        .begin;
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
Future checkTests(
    Directory dataDir, ComputeMemberDataFunction computeFromKernel,
    {bool testStrongMode: true,
    List<String> skipForKernel: const <String>[],
    List<String> skipForStrong: const <String>[],
    bool filterActualData(IdValue idValue, ActualData actualData),
    List<String> options: const <String>[],
    List<String> args: const <String>[],
    Directory libDirectory: null,
    bool testFrontend: false,
    bool forUserLibrariesOnly: true,
    Callback setUpFunction,
    ComputeClassDataFunction computeClassDataFromKernel,
    int shards: 1,
    int shardIndex: 0,
    bool testOmit: false}) async {
  args = args.toList();
  bool verbose = args.remove('-v');
  bool shouldContinue = args.remove('-c');
  bool testAfterFailures = args.remove('-a');
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
  for (FileSystemEntity entity in entities) {
    String name = entity.uri.pathSegments.last;
    if (args.isNotEmpty && !args.contains(name) && !continued) continue;
    if (shouldContinue) continued = true;
    List<String> testOptions = options.toList();
    bool strongModeOnlyTest = false;
    bool trustTypeAnnotations = false;
    if (name.endsWith('_ea.dart')) {
      testOptions.add(Flags.enableAsserts);
    }
    if (name.contains('_strong')) {
      strongModeOnlyTest = true;
      if (!testStrongMode) {
        testOptions.add(Flags.strongMode);
      }
    }
    if (name.endsWith('_checked.dart')) {
      testOptions.add(Flags.enableCheckedMode);
    }
    if (name.contains('_trust')) {
      trustTypeAnnotations = true;
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
      kernelMarker: new MemberAnnotations<IdValue>(),
      strongMarker: new MemberAnnotations<IdValue>(),
      omitMarker: new MemberAnnotations<IdValue>(),
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

    if (skipForKernel.contains(name) ||
        (testStrongMode && strongModeOnlyTest)) {
      print('--skipped for kernel--------------------------------------------');
    } else {
      print('--from kernel---------------------------------------------------');
      List<String> options = []..addAll(testOptions);
      if (trustTypeAnnotations) {
        options.add(Flags.trustTypeAnnotations);
      }
      MemberAnnotations<IdValue> annotations = expectedMaps[kernelMarker];
      CompiledData compiledData2 = await computeData(
          entryPoint, memorySourceFiles, computeFromKernel,
          computeClassData: computeClassDataFromKernel,
          options: options,
          verbose: verbose,
          testFrontend: testFrontend,
          forUserLibrariesOnly: forUserLibrariesOnly,
          globalIds: annotations.globalData.keys);
      if (await checkCode(
          kernelName, entity.uri, code, annotations, compiledData2,
          filterActualData: filterActualData,
          fatalErrors: !testAfterFailures)) {
        hasFailures = true;
      }
    }
    if (testStrongMode) {
      if (skipForStrong.contains(name)) {
        print('--skipped for kernel (strong mode)----------------------------');
      } else {
        print('--from kernel (strong mode)-----------------------------------');
        List<String> options = [Flags.strongMode]..addAll(testOptions);
        if (trustTypeAnnotations && !testOmit) {
          options.add(Flags.omitImplicitChecks);
        }
        MemberAnnotations<IdValue> annotations = expectedMaps[strongMarker];
        CompiledData compiledData2 = await computeData(
            entryPoint, memorySourceFiles, computeFromKernel,
            computeClassData: computeClassDataFromKernel,
            options: options,
            verbose: verbose,
            testFrontend: testFrontend,
            forUserLibrariesOnly: forUserLibrariesOnly,
            globalIds: annotations.globalData.keys);
        if (await checkCode(
            strongName, entity.uri, code, annotations, compiledData2,
            filterActualData: filterActualData,
            fatalErrors: !testAfterFailures)) {
          hasFailures = true;
        }
      }
    }
    if (testOmit) {
      if (skipForStrong.contains(name)) {
        print('--skipped for kernel (strong mode, omit-implicit-checks)------');
      } else {
        print('--from kernel (strong mode, omit-implicit-checks)-------------');
        List<String> options = [Flags.strongMode, Flags.omitImplicitChecks]
          ..addAll(testOptions);
        MemberAnnotations<IdValue> annotations = expectedMaps[omitMarker];
        CompiledData compiledData2 = await computeData(
            entryPoint, memorySourceFiles, computeFromKernel,
            computeClassData: computeClassDataFromKernel,
            options: options,
            verbose: verbose,
            testFrontend: testFrontend,
            forUserLibrariesOnly: forUserLibrariesOnly,
            globalIds: annotations.globalData.keys);
        if (await checkCode(
            trustName, entity.uri, code, annotations, compiledData2,
            filterActualData: filterActualData,
            fatalErrors: !testAfterFailures)) {
          hasFailures = true;
        }
      }
    }
  }
  Expect.isFalse(hasFailures, 'Errors found.');
}

final Set<String> userFiles = new Set<String>();

/// Checks [compiledData] against the expected data in [expectedMap] derived
/// from [code].
Future<bool> checkCode(
    String mode,
    Uri mainFileUri,
    Map<Uri, AnnotatedCode> code,
    MemberAnnotations<IdValue> expectedMaps,
    CompiledData compiledData,
    {bool filterActualData(IdValue expected, ActualData actualData),
    bool fatalErrors: true}) async {
  IdData data = new IdData(code, expectedMaps, compiledData);
  bool hasFailure = false;
  Set<Uri> neededDiffs = new Set<Uri>();

  void checkActualMap(
      Map<Id, ActualData> actualMap, Map<Id, IdValue> expectedMap,
      [Uri uri]) {
    bool hasLocalFailure = false;
    actualMap.forEach((Id id, ActualData actualData) {
      IdValue actual = actualData.value;

      if (!expectedMap.containsKey(id)) {
        if (actual.value != '') {
          reportError(
              data.compiler.reporter,
              actualData.sourceSpan,
              'EXTRA $mode DATA for ${id.descriptor} = '
              '${colorizeActual('$actual')} for ${actualData.objectText}. '
              'Data was expected for these ids: ${expectedMap.keys}');
          if (filterActualData == null || filterActualData(null, actualData)) {
            hasLocalFailure = true;
          }
        }
      } else {
        IdValue expected = expectedMap[id];
        if (actual != expected) {
          reportError(
              data.compiler.reporter,
              actualData.sourceSpan,
              'UNEXPECTED $mode DATA for ${id.descriptor}: '
              'Object: ${actualData.objectText}\n '
              'expected: ${colorizeExpected('$expected')}\n '
              'actual  : ${colorizeActual('$actual')}');
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

  data.actualMaps.forEach((Uri uri, Map<Id, ActualData> actualMap) {
    checkActualMap(actualMap, data.expectedMaps[uri], uri);
  });
  checkActualMap(data.actualMaps.globalData, data.expectedMaps.globalData);

  Set<Id> missingIds = new Set<Id>();
  void checkMissing(Map<Id, IdValue> expectedMap, Map<Id, ActualData> actualMap,
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
    print(data.diffCode(uri));
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
  } else if (id is ElementId) {
    String memberName = id.memberName;
    bool isSetter = false;
    if (memberName != '[]=' && memberName != '==' && memberName.endsWith('=')) {
      isSetter = true;
      memberName = memberName.substring(0, memberName.length - 1);
    }
    LibraryEntity library = elementEnvironment.lookupLibrary(mainUri);
    if (id.className != null) {
      ClassEntity cls =
          elementEnvironment.lookupClass(library, id.className, required: true);
      if (cls == null) {
        throw new ArgumentError("No class '${id.className}' in $mainUri.");
      }
      MemberEntity member = elementEnvironment
          .lookupClassMember(cls, memberName, setter: isSetter);
      if (member == null) {
        ConstructorEntity constructor =
            elementEnvironment.lookupConstructor(cls, memberName);
        if (constructor == null) {
          throw new ArgumentError("No class member '${memberName}' in $cls.");
        }
        return constructor;
      }
      return member;
    } else {
      MemberEntity member = elementEnvironment
          .lookupLibraryMember(library, memberName, setter: isSetter);
      if (member == null) {
        throw new ArgumentError("No member '${memberName}' in $mainUri.");
      }
      return member;
    }
  } else if (id is ClassId) {
    LibraryEntity library = elementEnvironment.lookupLibrary(mainUri);
    ClassEntity cls =
        elementEnvironment.lookupClass(library, id.className, required: true);
    if (cls == null) {
      throw new ArgumentError("No class '${id.className}' in $mainUri.");
    }
    return cls;
  }
  throw new UnsupportedError('Unsupported id $id.');
}

const String kernelMarker = 'kernel.';
const String strongMarker = 'strong.';
const String omitMarker = 'omit.';

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
  List<String> mapKeys = [kernelMarker, strongMarker, omitMarker];
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

/// Set of features used in annotations.
class Features {
  Map<String, Object> _features = <String, Object>{};

  void add(String key, {var value: ''}) {
    _features[key] = value.toString();
  }

  void addElement(String key, [var value]) {
    List<String> list = _features.putIfAbsent(key, () => <String>[]);
    if (value != null) {
      list.add(value.toString());
    }
  }

  bool containsKey(String key) {
    return _features.containsKey(key);
  }

  void operator []=(String key, String value) {
    _features[key] = value;
  }

  String operator [](String key) => _features[key];

  String remove(String key) => _features.remove(key);

  /// Returns a string containing all features in a comma-separated list sorted
  /// by feature names.
  String getText() {
    StringBuffer sb = new StringBuffer();
    bool needsComma = false;
    for (String name in _features.keys.toList()..sort()) {
      dynamic value = _features[name];
      if (value != null) {
        if (needsComma) {
          sb.write(',');
        }
        sb.write(name);
        if (value is List<String>) {
          value = '[${(value..sort()).join(',')}]';
        }
        if (value != '') {
          sb.write('=');
          sb.write(value);
        }
        needsComma = true;
      }
    }
    return sb.toString();
  }
}
