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
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import 'package:sourcemap_testing/src/annotated_code_helper.dart';

import '../memory_compiler.dart';
import '../equivalence/id_equivalence.dart';
import '../kernel/test_helpers.dart';

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

/// Colorize diffs [left] and [right] and [delimiter], if ANSI colors are
/// supported.
String colorizeDiff(String left, String delimiter, String right) {
  if (useColors) {
    return '${colors.green(left)}'
        '${colors.yellow(delimiter)}${colors.red(right)}';
  } else {
    return '$left$delimiter$right';
  }
}

/// Colorize annotation delimiters [start] and [end] surrounding [text], if
/// ANSI colors are supported.
String colorizeAnnotation(String start, String text, String end) {
  if (useColors) {
    return '${colors.yellow(start)}$text${colors.yellow(end)}';
  } else {
    return '$start$text$end';
  }
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

const String stopAfterTypeInference = 'stopAfterTypeInference';

/// Reports [message] as an error using [spannable] as error location.
void reportError(
    DiagnosticReporter reporter, Spannable spannable, String message) {
  reporter
      .reportErrorMessage(spannable, MessageKind.GENERIC, {'text': message});
}

/// Display name used for compilation using the old dart2js frontend.
const String astName = 'dart2js old frontend';

/// Display name used for compilation using the new common frontend.
const String kernelName = 'kernel';

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
  ClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  CommonElements commonElements = closedWorld.commonElements;

  Map<Uri, Map<Id, ActualData>> actualMaps = <Uri, Map<Id, ActualData>>{};
  Map<Id, ActualData> globalData = <Id, ActualData>{};

  Map<Id, ActualData> actualMapFor(Entity entity) {
    if (entity is Element) {
      // TODO(johnniwinther): Remove this when patched members from kernel are
      // no longer ascribed to the patch file.
      Element element = entity;
      entity = element.implementation;
    }
    SourceSpan span =
        compiler.backendStrategy.spanFromSpannable(entity, entity);
    Uri uri = resolveFastaUri(span.uri);
    return actualMaps.putIfAbsent(uri, () => <Id, ActualData>{});
  }

  void processMember(MemberEntity member, Map<Id, ActualData> actualMap) {
    if (member.isAbstract) {
      return;
    }
    if (member is ConstructorElement && member.isRedirectingFactory) {
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
        "Global member '$member' not found in the global "
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
          .add(colorizeSingle(value1));
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
Future checkTests(Directory dataDir, ComputeMemberDataFunction computeFromAst,
    ComputeMemberDataFunction computeFromKernel,
    {List<String> skipForAst: const <String>[],
    List<String> skipForKernel: const <String>[],
    bool filterActualData(IdValue idValue, ActualData actualData),
    List<String> options: const <String>[],
    List<String> args: const <String>[],
    Directory libDirectory: null,
    bool forUserLibrariesOnly: true,
    Callback setUpFunction,
    ComputeClassDataFunction computeClassDataFromAst,
    ComputeClassDataFunction computeClassDataFromKernel,
    int shards: 1,
    int shardIndex: 0}) async {
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
    if (name.endsWith('_ea.dart')) {
      testOptions.add(Flags.enableAsserts);
    } else if (name.endsWith('_strong.dart')) {
      strongModeOnlyTest = true;
      testOptions.add(Flags.strongMode);
    } else if (name.endsWith('_checked.dart')) {
      testOptions.add(Flags.enableCheckedMode);
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
      astMarker: new MemberAnnotations<IdValue>(),
      kernelMarker: new MemberAnnotations<IdValue>()
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

    if (skipForAst.contains(name) || strongModeOnlyTest) {
      print('--skipped for ast-----------------------------------------------');
    } else {
      print('--from ast------------------------------------------------------');
      MemberAnnotations<IdValue> annotations = expectedMaps[astMarker];
      CompiledData compiledData1 = await computeData(
          entryPoint, memorySourceFiles, computeFromAst,
          computeClassData: computeClassDataFromAst,
          options: [Flags.useOldFrontend]..addAll(testOptions),
          verbose: verbose,
          forUserLibrariesOnly: forUserLibrariesOnly,
          globalIds: annotations.globalData.keys);
      if (await checkCode(astName, entity.uri, code, annotations, compiledData1,
          fatalErrors: !testAfterFailures)) {
        hasFailures = true;
      }
    }
    if (skipForKernel.contains(name)) {
      print('--skipped for kernel--------------------------------------------');
    } else {
      print('--from kernel---------------------------------------------------');
      MemberAnnotations<IdValue> annotations = expectedMaps[kernelMarker];
      CompiledData compiledData2 = await computeData(
          entryPoint, memorySourceFiles, computeFromKernel,
          computeClassData: computeClassDataFromKernel,
          options: testOptions,
          verbose: verbose,
          forUserLibrariesOnly: forUserLibrariesOnly,
          globalIds: annotations.globalData.keys);
      if (await checkCode(
          kernelName, entity.uri, code, annotations, compiledData2,
          filterActualData: filterActualData,
          fatalErrors: !testAfterFailures)) {
        hasFailures = true;
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
              '${colors.red('$actual')} for ${actualData.objectText}. '
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
              'expected: ${colors.green('$expected')}\n '
              'actual: ${colors.red('$actual')}');
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
    if (memberName != '[]=' && memberName.endsWith('=')) {
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

const String astMarker = 'ast.';
const String kernelMarker = 'kernel.';

/// Compute two [MemberAnnotations] objects from [code] specifying the expected
/// annotations we anticipate encountering; one corresponding to the old
/// implementation, one for the new implementation.
///
/// If an annotation starts with 'ast.' it is only expected for the old
/// implementation and if it starts with 'kernel.' it is only expected for the
/// new implementation. Otherwise it is expected for both implementations.
///
/// Most nodes have the same and expectations should match this by using
/// annotations without prefixes.
void computeExpectedMap(Uri sourceUri, AnnotatedCode code,
    Map<String, MemberAnnotations<IdValue>> maps) {
  List<String> mapKeys = [astMarker, kernelMarker];
  Map<String, AnnotatedCode> split = splitByPrefixes(code, mapKeys);

  split.forEach((String marker, AnnotatedCode code) {
    MemberAnnotations<IdValue> fileAnnotations = maps[marker];
    Map<Id, IdValue> expectedValues = fileAnnotations[sourceUri];
    for (Annotation annotation in code.annotations) {
      String text = annotation.text;
      IdValue idValue = IdValue.decode(annotation.offset, text);
      if (idValue.id.isGlobal) {
        Expect.isFalse(
            fileAnnotations.globalData.containsKey(idValue.id),
            "Duplicate annotations for ${idValue.id}: ${idValue} and "
            "${fileAnnotations.globalData[idValue.id]}.");
        fileAnnotations.globalData[idValue.id] = idValue;
      } else {
        Expect.isFalse(
            expectedValues.containsKey(idValue.id),
            "Duplicate annotations for ${idValue.id}: ${idValue} and "
            "${expectedValues[idValue.id]}.");
        expectedValues[idValue.id] = idValue;
      }
    }
  });
}

Future<bool> compareData(
    Uri mainFileUri,
    Uri entryPoint,
    Map<String, String> memorySourceFiles,
    ComputeMemberDataFunction computeAstData,
    ComputeMemberDataFunction computeIrData,
    {List<String> options: const <String>[],
    bool forUserLibrariesOnly: true,
    bool skipUnprocessedMembers: false,
    bool skipFailedCompilations: false,
    bool verbose: false,
    bool whiteList(Uri uri, Id id)}) async {
  print('--from ast----------------------------------------------------------');
  CompiledData data1 = await computeData(
      entryPoint, memorySourceFiles, computeAstData,
      options: [Flags.useOldFrontend]..addAll(options),
      forUserLibrariesOnly: forUserLibrariesOnly,
      skipUnprocessedMembers: skipUnprocessedMembers,
      skipFailedCompilations: skipFailedCompilations);
  if (data1 == null) return false;
  print('--from kernel-------------------------------------------------------');
  CompiledData data2 = await computeData(
      entryPoint, memorySourceFiles, computeIrData,
      options: options,
      forUserLibrariesOnly: forUserLibrariesOnly,
      skipUnprocessedMembers: skipUnprocessedMembers,
      skipFailedCompilations: skipFailedCompilations);
  if (data2 == null) return false;
  await compareCompiledData(mainFileUri, data1, data2,
      whiteList: whiteList,
      skipMissingUris: !forUserLibrariesOnly,
      verbose: verbose);
  return true;
}

Future compareCompiledData(
    Uri mainFileUri, CompiledData data1, CompiledData data2,
    {bool skipMissingUris: false,
    bool verbose: false,
    bool whiteList(Uri uri, Id id)}) async {
  if (whiteList == null) {
    whiteList = (uri, id) => false;
  }
  bool hasErrors = false;
  String libraryRoot1;

  SourceFileProvider provider1 = data1.compiler.provider;
  SourceFileProvider provider2 = data2.compiler.provider;
  for (Uri uri1 in data1.actualMaps.keys) {
    Uri uri2 = uri1;
    bool hasErrorsInUri = false;
    Map<Id, ActualData> actualMap1 = data1.actualMaps[uri1];
    Map<Id, ActualData> actualMap2 = data2.actualMaps[uri2];
    if (actualMap2 == null && skipMissingUris) {
      libraryRoot1 ??= '${data1.compiler.options.libraryRoot}';
      String uriText = '$uri1';
      if (uriText.startsWith(libraryRoot1)) {
        String relativePath = uriText.substring(libraryRoot1.length);
        uri2 =
            resolveFastaUri(Uri.parse('patched_dart2js_sdk/${relativePath}'));
        actualMap2 = data2.actualMaps[uri2];
      }
      if (actualMap2 == null) {
        continue;
      }
    }
    Expect.isNotNull(actualMap2,
        "No data for $uri1 in:\n ${data2.actualMaps.keys.join('\n ')}");
    SourceFile sourceFile1 = await provider1.getUtf8SourceFile(uri1) ??
        await provider1.autoReadFromFile(uri1);
    Expect.isNotNull(sourceFile1, 'No source file for $uri1');
    String sourceCode1 = sourceFile1.slowText();
    if (uri1 != uri2) {
      SourceFile sourceFile2 = await provider2.getUtf8SourceFile(uri2) ??
          await provider2.autoReadFromFile(uri2);
      Expect.isNotNull(sourceFile2, 'No source file for $uri2');
      String sourceCode2 = sourceFile2.slowText();
      if (sourceCode1.length != sourceCode2.length) {
        continue;
      }
    }

    actualMap1.forEach((Id id, ActualData actualData1) {
      IdValue value1 = actualData1.value;
      IdValue value2 = actualMap2[id]?.value;

      if (value1 != value2) {
        String message;
        if (value2 != null) {
          String prefix = 'DATA MISMATCH for ${id.descriptor}';
          message = '$prefix: Data from $astName: ${value1}, '
              'data from $kernelName: ${value2}';
        } else {
          String prefix = 'MISSING $kernelName DATA for ${id.descriptor}, '
              'object = ${actualData1.objectText}';
          message = '$prefix: Data from $astName: ${value1}, '
              'no data from $kernelName';
        }
        reportError(data1.compiler.reporter, actualData1.sourceSpan, message);
        if (!whiteList(uri1, id)) {
          hasErrors = hasErrorsInUri = true;
        }
      }
    });
    actualMap2.forEach((Id id, ActualData actualData2) {
      IdValue value2 = actualData2.value;
      IdValue value1 = actualMap1[id]?.value;
      if (value1 != value2) {
        String prefix = 'EXTRA $kernelName DATA for ${id.descriptor}, '
            'object = ${actualData2.objectText}';
        String message =
            '$prefix: Data from $kernelName: ${value2}, no data from $astName';
        reportError(data1.compiler.reporter, actualData2.sourceSpan, message);
        if (!whiteList(uri1, id)) {
          hasErrors = hasErrorsInUri = true;
        }
      }
    });
    if (hasErrorsInUri) {
      Uri fileUri;
      if (data1.compiler.mainLibraryUri == uri1) {
        fileUri = mainFileUri;
      } else {
        fileUri = uri1;
      }
      print('--annotations diff for: $fileUri -------------------------------');
      print(withAnnotations(
          sourceCode1,
          data1.computeDiffAnnotationsAgainst(actualMap1, actualMap2, uri1,
              includeMatches: verbose)));
      print('----------------------------------------------------------');
    }
  }
  if (hasErrors) {
    Expect.fail('Annotations mismatch');
  }
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
