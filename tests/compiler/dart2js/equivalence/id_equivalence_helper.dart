// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';

import '../annotated_code_helper.dart';
import '../memory_compiler.dart';
import '../equivalence/id_equivalence.dart';
import '../kernel/compiler_helper.dart';

/// Function that compiles [mainUri] from [memorySourceFiles] with [options] and
/// returns the [Compiler] object.
typedef Future<Compiler> CompileFunction(
    Uri mainUri, Map<String, String> memorySourceFiles, List<String> options);

/// Function that computes a data mapping for [member].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
typedef void ComputeMemberDataFunction(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose});

const String stopAfterTypeInference = 'stopAfterTypeInference';

/// Compile compiles [mainUri] from [memorySourceFiles] using the old frontend.
Future<Compiler> compileFromSource(Uri mainUri,
    Map<String, String> memorySourceFiles, List<String> options) async {
  Compiler compiler =
      compilerFor(memorySourceFiles: memorySourceFiles, options: options);
  compiler.stopAfterTypeInference = options.contains(stopAfterTypeInference);
  await compiler.run(mainUri);
  return compiler;
}

/// Compile [mainUri] from [memorySourceFiles] using the new frontend.
Future<Compiler> compileFromDill(Uri mainUri,
    Map<String, String> memorySourceFiles, List<String> options) async {
  Compiler compiler = await compileWithDill(
      entryPoint: mainUri,
      memorySourceFiles: memorySourceFiles,
      options: options,
      beforeRun: (Compiler compiler) {
        compiler.stopAfterTypeInference =
            options.contains(stopAfterTypeInference);
      });
  return compiler;
}

/// Compute actual data for all members defined in the program with the
/// [entryPoint] and [memorySourceFiles].
///
/// Actual data is computed using [computeMemberData] and [code] is compiled
/// using [compileFunction].
Future<CompiledData> computeData(
    Uri entryPoint,
    Map<String, String> memorySourceFiles,
    ComputeMemberDataFunction computeMemberData,
    CompileFunction compileFunction,
    {List<String> options: const <String>[],
    bool verbose: false}) async {
  Compiler compiler =
      await compileFunction(entryPoint, memorySourceFiles, options);
  ClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  Map<Id, ActualData> actualMap = <Id, ActualData>{};
  LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
  elementEnvironment.forEachClass(mainLibrary, (ClassEntity cls) {
    if (closedWorld.isInstantiated(cls) &&
        !elementEnvironment.isEnumClass(cls)) {
      elementEnvironment.forEachConstructor(cls,
          (ConstructorEntity constructor) {
        computeMemberData(compiler, constructor, actualMap, verbose: verbose);
      });
    }
    elementEnvironment.forEachClassMember(cls,
        (ClassEntity declarer, MemberEntity member) {
      if (cls == declarer) {
        if (elementEnvironment.isEnumClass(cls)) {
          if (member.isInstanceMember || member.name == 'values') {
            return;
          }
        }
        computeMemberData(compiler, member, actualMap, verbose: verbose);
      }
    });
  });
  elementEnvironment.forEachLibraryMember(mainLibrary, (MemberEntity member) {
    computeMemberData(compiler, member, actualMap, verbose: verbose);
  });

  return new CompiledData(compiler, elementEnvironment, entryPoint, actualMap);
}

class CompiledData {
  final Compiler compiler;
  final ElementEnvironment elementEnvironment;
  final Uri mainUri;
  final Map<Id, ActualData> actualMap;

  CompiledData(
      this.compiler, this.elementEnvironment, this.mainUri, this.actualMap);

  Map<int, List<String>> computeDiffAnnotationsAgainst(CompiledData other) {
    Map<Id, ActualData> thisMap = actualMap;
    Map<Id, ActualData> otherMap = other.actualMap;
    Map<int, List<String>> annotations = <int, List<String>>{};
    thisMap.forEach((Id id, ActualData data1) {
      ActualData data2 = otherMap[id];
      if (data1.value != data2?.value) {
        annotations
            .putIfAbsent(data1.sourceSpan.begin, () => [])
            .add('${data1.value} | ${data2?.value ?? '---'}');
      }
    });
    otherMap.forEach((Id id, ActualData data2) {
      if (!thisMap.containsKey(id)) {
        int offset = compiler.reporter
            .spanFromSpannable(
                computeSpannable(elementEnvironment, mainUri, id))
            .begin;
        annotations.putIfAbsent(offset, () => []).add('--- | ${data2.value}');
      }
    });
    return annotations;
  }
}

String withAnnotations(String sourceCode, Map<int, List<String>> annotations) {
  StringBuffer sb = new StringBuffer();
  int end = 0;
  for (int offset in annotations.keys.toList()..sort()) {
    if (offset > end) {
      sb.write(sourceCode.substring(end, offset));
    }
    for (String annotation in annotations[offset]) {
      sb.write('/* ');
      sb.write(annotation);
      sb.write(' */');
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
  Map<Id, ActualData> get actualMap => compiledData.actualMap;

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
        annotations
            .putIfAbsent(offset, () => [])
            .add('${expected} | ${data.value}');
      }
    });
    expectedMap.forEach((Id id, IdValue expected) {
      if (!actualMap.containsKey(id)) {
        int offset = getOffsetFromId(id);
        annotations.putIfAbsent(offset, () => []).add('${expected} | ---');
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
    List testOptions = options.toList();
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
          entryPoint, memorySourceFiles, computeFromAst, compileFromSource,
          options: testOptions, verbose: verbose);
      await checkCode(code, expectedMaps[0], compiledData1);
    }
    if (skipForKernel.contains(name)) {
      print('--skipped for kernel------------------------------------------');
    } else {
      print('--from kernel---------------------------------------------------');
      CompiledData compiledData2 = await computeData(
          entryPoint, memorySourceFiles, computeFromKernel, compileFromDill,
          options: testOptions, verbose: verbose);
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

Future compareData(
    Uri entryPoint,
    Map<String, String> memorySourceFiles,
    ComputeMemberDataFunction computeAstData,
    ComputeMemberDataFunction computeIrData,
    {List<String> options: const <String>[]}) async {
  CompiledData data1 = await computeData(
      entryPoint, memorySourceFiles, computeAstData, compileFromSource,
      options: options);
  CompiledData data2 = await computeData(
      entryPoint, memorySourceFiles, computeIrData, compileFromDill,
      options: options);
  await compareCompiledData(data1, data2);
}

Future compareCompiledData(CompiledData data1, CompiledData data2) async {
  Map<Id, ActualData> actualMap1 = data1.actualMap;
  Map<Id, ActualData> actualMap2 = data2.actualMap;
  SourceFileProvider provider = data1.compiler.provider;
  String sourceCode =
      (await provider.getUtf8SourceFile(data1.mainUri)).slowText();
  actualMap1.forEach((Id id, ActualData actualData1) {
    IdValue value1 = actualData1.value;
    IdValue value2 = actualMap2[id]?.value;
    if (value1 != value2) {
      reportHere(data1.compiler.reporter, actualData1.sourceSpan,
          '$id: from source:${value1},from dill:${value2}');
      print('--annotations diff----------------------------------------');
      print(withAnnotations(
          sourceCode, data1.computeDiffAnnotationsAgainst(data2)));
      print('----------------------------------------------------------');
    }
    Expect.equals(value1, value2, 'Value mismatch for $id');
  });
  actualMap2.forEach((Id id, ActualData actualData2) {
    IdValue value2 = actualData2.value;
    IdValue value1 = actualMap1[id]?.value;
    if (value1 != value2) {
      reportHere(data2.compiler.reporter, actualData2.sourceSpan,
          '$id: from source:${value1},from dill:${value2}');
      print('--annotations diff----------------------------------------');
      print(withAnnotations(
          sourceCode, data1.computeDiffAnnotationsAgainst(data2)));
      print('----------------------------------------------------------');
    }
    Expect.equals(value1, value2, 'Unexpected data for $id');
  });
}
