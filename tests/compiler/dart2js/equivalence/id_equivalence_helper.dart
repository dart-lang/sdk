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

import '../annotated_code_helper.dart';
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
/// Actual data is computed using [computeMemberData] and [code] is compiled
/// using [compileFunction].
Future<CompiledData> computeData(
    Uri entryPoint,
    Map<String, String> memorySourceFiles,
    ComputeMemberDataFunction computeMemberData,
    {List<String> options: const <String>[],
    bool verbose: false,
    bool forMainLibraryOnly: true,
    bool skipUnprocessedMembers: false,
    bool skipFailedCompilations: false}) async {
  Compiler compiler =
      compilerFor(memorySourceFiles: memorySourceFiles, options: options);
  compiler.stopAfterTypeInference = options.contains(stopAfterTypeInference);
  await compiler.run(entryPoint);
  if (compiler.compilationFailed) {
    if (skipFailedCompilations) return null;
    Expect.isFalse(compiler.compilationFailed, "Unexpected compilation error.");
  }
  ClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  Map<Uri, Map<Id, ActualData>> actualMaps = <Uri, Map<Id, ActualData>>{};

  Map<Id, ActualData> actualMapFor(Entity entity) {
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
    computeMemberData(compiler, member, actualMapFor(member), verbose: verbose);
  }

  if (forMainLibraryOnly) {
    LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
    elementEnvironment.forEachClass(mainLibrary, (ClassEntity cls) {
      if (closedWorld.isInstantiated(cls) &&
          !elementEnvironment.isEnumClass(cls)) {
        elementEnvironment.forEachConstructor(cls, processMember);
      }
      elementEnvironment.forEachLocalClassMember(cls, processMember);
    });
    elementEnvironment.forEachLibraryMember(mainLibrary, processMember);
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
      Map<Id, ActualData> thisMap, Map<Id, ActualData> otherMap,
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
            .spanFromSpannable(
                computeSpannable(elementEnvironment, mainUri, id))
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
  final AnnotatedCode code;
  final Map<Id, IdValue> expectedMap;
  final CompiledData compiledData;

  IdData(this.code, this.expectedMap, this.compiledData);

  Compiler get compiler => compiledData.compiler;
  ElementEnvironment get elementEnvironment => compiledData.elementEnvironment;
  Uri get mainUri => compiledData.mainUri;
  Map<Id, ActualData> get actualMap => compiledData.actualMaps[mainUri];

  String get actualCode {
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMap.forEach((Id id, ActualData data) {
      annotations
          .putIfAbsent(data.sourceSpan.begin, () => [])
          .add('${data.value}');
    });
    return withAnnotations(code.sourceCode, annotations);
  }

  String get diffCode {
    Map<int, List<String>> annotations = <int, List<String>>{};
    actualMap.forEach((Id id, ActualData data) {
      IdValue value = expectedMap[id];
      if (data.value != value || value == null && data.value.value != '') {
        String expected = value?.toString() ?? '';
        int offset = getOffsetFromId(id);
        String value1 = '${expected}';
        String value2 = '${data.value}';
        annotations
            .putIfAbsent(offset, () => [])
            .add(colorizeDiff(value1, ' | ', value2));
      }
    });
    expectedMap.forEach((Id id, IdValue expected) {
      if (!actualMap.containsKey(id)) {
        int offset = getOffsetFromId(id);
        String value1 = '${expected}';
        String value2 = '---';
        annotations
            .putIfAbsent(offset, () => [])
            .add(colorizeDiff(value1, ' | ', value2));
      }
    });
    return withAnnotations(code.sourceCode, annotations);
  }

  int getOffsetFromId(Id id) {
    return compiler.reporter
        .spanFromSpannable(computeSpannable(elementEnvironment, mainUri, id))
        .begin;
  }
}

/// Check code for all test files int [data] using [computeFromAst] and
/// [computeFromKernel] from the respective front ends. If [skipForKernel]
/// contains the name of the test file it isn't tested for kernel.
Future checkTests(Directory dataDir, ComputeMemberDataFunction computeFromAst,
    ComputeMemberDataFunction computeFromKernel,
    {List<String> skipforAst: const <String>[],
    List<String> skipForKernel: const <String>[],
    bool filterActualData(IdValue idValue, ActualData actualData),
    List<String> options: const <String>[],
    List<String> args: const <String>[]}) async {
  args = args.toList();
  bool verbose = args.remove('-v');
  await for (FileSystemEntity entity in dataDir.list()) {
    String name = entity.uri.pathSegments.last;
    if (args.isNotEmpty && !args.contains(name)) continue;
    List<String> testOptions = options.toList();
    if (name.endsWith('_ea.dart')) {
      testOptions.add(Flags.enableAsserts);
    }
    print('----------------------------------------------------------------');
    print('Checking ${entity.uri}');
    print('----------------------------------------------------------------');
    // Pretend this is a dart2js_native test to allow use of 'native' keyword
    // and import of private libraries.
    Uri entryPoint =
        Uri.parse('memory:sdk/tests/compiler/dart2js_native/main.dart');
    String annotatedCode = await new File.fromUri(entity.uri).readAsString();
    AnnotatedCode code =
        new AnnotatedCode.fromText(annotatedCode, commentStart, commentEnd);
    List<Map<Id, IdValue>> expectedMaps = computeExpectedMap(code);
    Map<String, String> memorySourceFiles = {entryPoint.path: code.sourceCode};

    if (skipforAst.contains(name)) {
      print('--skipped for kernel------------------------------------------');
    } else {
      print('--from ast------------------------------------------------------');
      CompiledData compiledData1 = await computeData(
          entryPoint, memorySourceFiles, computeFromAst,
          options: testOptions, verbose: verbose);
      await checkCode(code, expectedMaps[0], compiledData1);
    }
    if (skipForKernel.contains(name)) {
      print('--skipped for kernel------------------------------------------');
    } else {
      print('--from kernel---------------------------------------------------');
      CompiledData compiledData2 = await computeData(
          entryPoint, memorySourceFiles, computeFromKernel,
          options: [Flags.useKernel]..addAll(testOptions), verbose: verbose);
      await checkCode(code, expectedMaps[1], compiledData2,
          filterActualData: filterActualData);
    }
  }
}

/// Checks [compiledData] against the expected data in [expectedMap] derived
/// from [code].
Future checkCode(
    AnnotatedCode code, Map<Id, IdValue> expectedMap, CompiledData compiledData,
    {bool filterActualData(IdValue expected, ActualData actualData)}) async {
  IdData data = new IdData(code, expectedMap, compiledData);

  data.actualMap.forEach((Id id, ActualData actualData) {
    IdValue actual = actualData.value;
    if (!data.expectedMap.containsKey(id)) {
      if (actual.value != '') {
        reportHere(
            data.compiler.reporter,
            actualData.sourceSpan,
            'Id $id = ${actual} for ${actualData.object} '
            '(${actualData.object.runtimeType}) '
            'not expected in ${data.expectedMap.keys}');
        print('--annotations diff--------------------------------------------');
        print(data.diffCode);
        print('--------------------------------------------------------------');
      }
      if (filterActualData == null || filterActualData(null, actualData)) {
        Expect.equals('', actual.value);
      }
    } else {
      IdValue expected = data.expectedMap[id];
      if (actual != expected) {
        reportHere(
            data.compiler.reporter,
            actualData.sourceSpan,
            'Object: ${actualData.object} (${actualData.object.runtimeType}), '
            'expected: ${expected}, actual: ${actual}');
        print('--annotations diff--------------------------------------------');
        print(data.diffCode);
        print('--------------------------------------------------------------');
      }
      if (filterActualData == null || filterActualData(expected, actualData)) {
        Expect.equals(expected, actual);
      }
    }
  });

  Set<Id> missingIds = new Set<Id>();
  data.expectedMap.forEach((Id id, IdValue expected) {
    if (!data.actualMap.containsKey(id)) {
      missingIds.add(id);
      StringBuffer sb = new StringBuffer();
      for (Id id in data.actualMap.keys /*.where((d) => d.kind == id.kind)*/) {
        sb.write('\n  $id');
      }
      reportHere(
          data.compiler.reporter,
          computeSpannable(data.elementEnvironment, data.mainUri, id),
          'Expected $expected for id $id missing in${sb}');
    }
  });
  if (missingIds.isNotEmpty) {
    print('--annotations diff--------------------------------------------');
    print(data.diffCode);
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

/// Compute two expectancy maps from [code]; one corresponding to the old
/// implementation, one for the new implementation.
///
/// If an annotation starts with 'ast.' it is only expected for the old
/// implementation and if it starts with 'kernel.' it is only expected for the
/// new implementation. Otherwise it is expected for both implementations.
///
/// Most nodes have the same and expectations should match this by using
/// annotations without prefixes.
List<Map<Id, IdValue>> computeExpectedMap(AnnotatedCode code) {
  List<Map<Id, IdValue>> maps = [<Id, IdValue>{}, <Id, IdValue>{}];
  for (Annotation annotation in code.annotations) {
    List<Map<Id, IdValue>> activeMaps = maps;
    String text = annotation.text;
    if (text.startsWith(astMarker)) {
      text = text.substring(astMarker.length);
      activeMaps = [maps[0]];
    } else if (text.startsWith(kernelMarker)) {
      text = text.substring(kernelMarker.length);
      activeMaps = [maps[1]];
    }
    IdValue idValue = IdValue.decode(annotation.offset, text);
    for (Map<Id, IdValue> map in activeMaps) {
      Expect.isFalse(map.containsKey(idValue.id),
          "Duplicate annotations for ${idValue.id}.");
      map[idValue.id] = idValue;
    }
  }
  return maps;
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
    bool verbose: false}) async {
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
      skipMissingUris: !forMainLibraryOnly, verbose: verbose);
  return true;
}

Future compareCompiledData(CompiledData data1, CompiledData data2,
    {bool skipMissingUris: false, bool verbose: false}) async {
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
        hasErrors = hasErrorsInUri = true;
      }
    });
    actualMap2.forEach((Id id, ActualData actualData2) {
      IdValue value2 = actualData2.value;
      IdValue value1 = actualMap1[id]?.value;
      if (value1 != value2) {
        reportHere(data2.compiler.reporter, actualData2.sourceSpan,
            '$id: from source:${value1},from dill:${value2}');
        hasErrors = hasErrorsInUri = true;
      }
    });
    if (hasErrorsInUri) {
      print('--annotations diff $uri1---------------------------------------');
      print(withAnnotations(
          sourceCode1,
          data1.computeDiffAnnotationsAgainst(actualMap1, actualMap2,
              includeMatches: verbose)));
      print('----------------------------------------------------------');
    }
  }
  if (hasErrors) {
    Expect.fail('Annotations mismatch');
  }
}
