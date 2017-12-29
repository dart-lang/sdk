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

const String stopAfterTypeInference = 'stopAfterTypeInference';

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
    bool forMainLibraryOnly: true,
    bool skipUnprocessedMembers: false,
    bool skipFailedCompilations: false,
    bool forUserSourceFilesOnly: false}) async {
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

  Map<Uri, Map<Id, ActualData>> actualMaps = <Uri, Map<Id, ActualData>>{};

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

  void processMember(MemberEntity member) {
    if (member.isAbstract) {
      return;
    }
    if (member is ConstructorElement && member.isRedirectingFactory) {
      return;
    }
    if (!closedWorld.processedMembers.contains(member)) {
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
    computeMemberData(compiler, member, actualMapFor(member), verbose: verbose);
  }

  if (forMainLibraryOnly && !forUserSourceFilesOnly) {
    LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
    elementEnvironment.forEachClass(mainLibrary, (ClassEntity cls) {
      if (!elementEnvironment.isEnumClass(cls)) {
        elementEnvironment.forEachConstructor(cls, processMember);
      }
      elementEnvironment.forEachLocalClassMember(cls, processMember);
    });
    elementEnvironment.forEachLibraryMember(mainLibrary, processMember);
  } else if (forUserSourceFilesOnly) {
    closedWorld.processedMembers
        .where((MemberEntity member) =>
            userFiles.contains(member.library.canonicalUri.pathSegments.last))
        .forEach(processMember);
  } else {
    closedWorld.processedMembers.forEach(processMember);
  }

  return new CompiledData(compiler, elementEnvironment, entryPoint, actualMaps);
}

class CompiledData {
  final Compiler compiler;
  final ElementEnvironment elementEnvironment;
  final Uri mainUri;
  final Map<Uri, Map<Id, ActualData>> actualMaps;

  CompiledData(
      this.compiler, this.elementEnvironment, this.mainUri, this.actualMaps);

  Map<int, List<String>> computeAnnotations(Uri uri) {
    Map<Id, ActualData> thisMap = actualMaps[uri];
    Map<int, List<String>> annotations = <int, List<String>>{};
    thisMap.forEach((Id id, ActualData data1) {
      String value1 = '${data1.value}';
      annotations
          .putIfAbsent(data1.sourceSpan.begin, () => [])
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
            .putIfAbsent(data1.sourceSpan.begin, () => [])
            .add(colorizeDiff(value1, ' | ', value2));
      } else if (includeMatches) {
        annotations
            .putIfAbsent(data1.sourceSpan.begin, () => [])
            .add(colorizeMatch(value1));
      }
    });
    otherMap.forEach((Id id, ActualData data2) {
      if (!thisMap.containsKey(id)) {
        int offset = compiler.reporter
            .spanFromSpannable(computeSpannable(elementEnvironment, uri, id))
            .begin;
        String value1 = '---';
        String value2 = '${data2.value}';
        annotations
            .putIfAbsent(offset, () => [])
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
      sb.write(colorizeAnnotation('/* ', annotation, ' */'));
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
  final CompiledData compiledData;
  final MemberAnnotations<ActualData> _actualMaps = new MemberAnnotations();

  IdData(this.code, this.expectedMaps, this.compiledData) {
    for (Uri uri in code.keys) {
      _actualMaps[uri] = compiledData.actualMaps[uri] ?? <Id, ActualData>{};
    }
  }

  Compiler get compiler => compiledData.compiler;
  ElementEnvironment get elementEnvironment => compiledData.elementEnvironment;
  Uri get mainUri => compiledData.mainUri;
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
    {List<String> skipforAst: const <String>[],
    List<String> skipForKernel: const <String>[],
    bool filterActualData(IdValue idValue, ActualData actualData),
    List<String> options: const <String>[],
    List<String> args: const <String>[],
    Directory libDirectory: null,
    bool forMainLibraryOnly: true,
    bool forUserSourceFilesOnly: false,
    Callback setUpFunction}) async {
  args = args.toList();
  bool verbose = args.remove('-v');

  var relativeDir = dataDir.uri.path.replaceAll(Uri.base.path, '');
  print('Data dir: ${relativeDir}');
  await for (FileSystemEntity entity in dataDir.list()) {
    String name = entity.uri.pathSegments.last;
    if (args.isNotEmpty && !args.contains(name)) continue;
    List<String> testOptions = options.toList();
    if (name.endsWith('_ea.dart')) {
      testOptions.add(Flags.enableAsserts);
    }
    print('----------------------------------------------------------------');
    print('Test: $name');
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

    if (skipforAst.contains(name)) {
      print('--skipped for ast-----------------------------------------------');
    } else {
      print('--from ast------------------------------------------------------');
      CompiledData compiledData1 = await computeData(
          entryPoint, memorySourceFiles, computeFromAst,
          options: testOptions,
          verbose: verbose,
          forMainLibraryOnly: forMainLibraryOnly,
          forUserSourceFilesOnly: forUserSourceFilesOnly);
      await checkCode(code, expectedMaps[astMarker], compiledData1);
    }
    if (skipForKernel.contains(name)) {
      print('--skipped for kernel--------------------------------------------');
    } else {
      print('--from kernel---------------------------------------------------');
      CompiledData compiledData2 = await computeData(
          entryPoint, memorySourceFiles, computeFromKernel,
          options: [Flags.useKernel]..addAll(testOptions),
          verbose: verbose,
          forMainLibraryOnly: forMainLibraryOnly,
          forUserSourceFilesOnly: forUserSourceFilesOnly);
      await checkCode(code, expectedMaps[kernelMarker], compiledData2,
          filterActualData: filterActualData);
    }
  }
}

final Set<String> userFiles = new Set<String>();

/// Checks [compiledData] against the expected data in [expectedMap] derived
/// from [code].
Future checkCode(Map<Uri, AnnotatedCode> code,
    MemberAnnotations<IdValue> expectedMaps, CompiledData compiledData,
    {bool filterActualData(IdValue expected, ActualData actualData)}) async {
  IdData data = new IdData(code, expectedMaps, compiledData);

  data.actualMaps.forEach((Uri uri, Map<Id, ActualData> actualMap) {
    actualMap.forEach((Id id, ActualData actualData) {
      IdValue actual = actualData.value;
      if (!data.expectedMaps[uri].containsKey(id)) {
        if (actual.value != '') {
          reportHere(
              data.compiler.reporter,
              actualData.sourceSpan,
              'Id $id = ${actual} for ${actualData.object} '
              '(${actualData.object.runtimeType}) '
              'not expected in ${data.expectedMaps[uri].keys}');
          print('--annotations diff [${uri.pathSegments.last}]---------------');
          print(data.diffCode(uri));
          print('------------------------------------------------------------');
        }
        if (filterActualData == null || filterActualData(null, actualData)) {
          Expect.equals('', actual.value);
        }
      } else {
        IdValue expected = data.expectedMaps[uri][id];
        if (actual != expected) {
          reportHere(
              data.compiler.reporter,
              actualData.sourceSpan,
              'Object: ${actualData.object} (${actualData.object.runtimeType}), '
              'expected: ${expected}, actual: ${actual}');
          print('--annotations diff [${uri.pathSegments.last}]---------------');
          print(data.diffCode(uri));
          print('------------------------------------------------------------');
        }
        if (filterActualData == null ||
            filterActualData(expected, actualData)) {
          Expect.equals(expected, actual);
        }
      }
    });
  });

  Set<Id> missingIds = new Set<Id>();
  StringBuffer combinedAnnotationsDiff = new StringBuffer();
  data.expectedMaps.forEach((Uri uri, Map<Id, IdValue> expectedMap) {
    expectedMap.forEach((Id id, IdValue expected) {
      if (!data.actualMaps[uri].containsKey(id)) {
        missingIds.add(id);
        StringBuffer sb = new StringBuffer();
        for (Id id
            in data.actualMaps[uri].keys /*.where((d) => d.kind == id.kind)*/) {
          sb.write('\n  $id');
        }
        reportHere(
            data.compiler.reporter,
            computeSpannable(data.elementEnvironment, uri, id),
            'Expected $expected for id $id missing in${sb}');
      }
    });
    if (missingIds.isNotEmpty) {
      combinedAnnotationsDiff.write('Missing in $uri:\n');
      combinedAnnotationsDiff.write('${data.diffCode(uri)}\n');
    }
  });
  if (combinedAnnotationsDiff.isNotEmpty) {
    print('--annotations diff--------------------------------------------');
    print(combinedAnnotationsDiff.toString());
    print('--------------------------------------------------------------');
  }
  Expect.isTrue(missingIds.isEmpty, "Ids not found: ${missingIds}.");
}

/// Compute a [Spannable] from an [id] in the library [mainUri].
Spannable computeSpannable(
    ElementEnvironment elementEnvironment, Uri mainUri, Id id) {
  if (id is NodeId) {
    return new SourceSpan(mainUri, id.value, id.value + 1);
  } else if (id is ElementId) {
    LibraryEntity library = elementEnvironment.lookupLibrary(mainUri);
    if (id.className != null) {
      ClassEntity cls =
          elementEnvironment.lookupClass(library, id.className, required: true);
      if (cls == null) {
        throw new ArgumentError("No class '${id.className}' in $mainUri.");
      }
      MemberEntity member =
          elementEnvironment.lookupClassMember(cls, id.memberName);
      if (member == null) {
        ConstructorEntity constructor =
            elementEnvironment.lookupConstructor(cls, id.memberName);
        if (constructor == null) {
          throw new ArgumentError(
              "No class member '${id.memberName}' in $cls.");
        }
        return constructor;
      }
      return member;
    } else {
      MemberEntity member =
          elementEnvironment.lookupLibraryMember(library, id.memberName);
      if (member == null) {
        throw new ArgumentError("No member '${id.memberName}' in $mainUri.");
      }
      return member;
    }
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
      Expect.isFalse(expectedValues.containsKey(idValue.id),
          "Duplicate annotations for ${idValue.id}.");
      expectedValues[idValue.id] = idValue;
    }
  });
}

Future<bool> compareData(
    Uri entryPoint,
    Map<String, String> memorySourceFiles,
    ComputeMemberDataFunction computeAstData,
    ComputeMemberDataFunction computeIrData,
    {List<String> options: const <String>[],
    bool forMainLibraryOnly: true,
    bool skipUnprocessedMembers: false,
    bool skipFailedCompilations: false,
    bool verbose: false,
    bool whiteList(Uri uri, Id id)}) async {
  print('--from ast----------------------------------------------------------');
  CompiledData data1 = await computeData(
      entryPoint, memorySourceFiles, computeAstData,
      options: options,
      forMainLibraryOnly: forMainLibraryOnly,
      skipUnprocessedMembers: skipUnprocessedMembers,
      skipFailedCompilations: skipFailedCompilations);
  if (data1 == null) return false;
  print('--from kernel-------------------------------------------------------');
  CompiledData data2 = await computeData(
      entryPoint, memorySourceFiles, computeIrData,
      options: [Flags.useKernel]..addAll(options),
      forMainLibraryOnly: forMainLibraryOnly,
      skipUnprocessedMembers: skipUnprocessedMembers,
      skipFailedCompilations: skipFailedCompilations);
  if (data2 == null) return false;
  await compareCompiledData(data1, data2,
      whiteList: whiteList,
      skipMissingUris: !forMainLibraryOnly,
      verbose: verbose);
  return true;
}

Future compareCompiledData(CompiledData data1, CompiledData data2,
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
        reportHere(data1.compiler.reporter, actualData1.sourceSpan,
            '$id: from source:${value1},from dill:${value2}');
        if (!whiteList(uri1, id)) {
          hasErrors = hasErrorsInUri = true;
        }
      }
    });
    actualMap2.forEach((Id id, ActualData actualData2) {
      IdValue value2 = actualData2.value;
      IdValue value1 = actualMap1[id]?.value;
      if (value1 != value2) {
        reportHere(data2.compiler.reporter, actualData2.sourceSpan,
            '$id: from source:${value1},from dill:${value2}');
        if (!whiteList(uri1, id)) {
          hasErrors = hasErrorsInUri = true;
        }
      }
    });
    if (hasErrorsInUri) {
      print('--annotations diff $uri1---------------------------------------');
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
