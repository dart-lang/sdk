// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:expect/expect.dart';

import '../annotated_code_helper.dart';
import '../memory_compiler.dart';
import '../equivalence/id_equivalence.dart';
import '../kernel/compiler_helper.dart';

/// Function that compiles [code] with [options] and returns the [Compiler] object.
typedef Future<Compiler> CompileFunction(
    AnnotatedCode code, Uri mainUri, List<String> options);

/// Function that computes a data mapping for [member].
///
/// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
/// for the data origin.
typedef void ComputeMemberDataFunction(
    Compiler compiler, MemberEntity member, Map<Id, ActualData> actualMap,
    {bool verbose});

/// Compile [code] from .dart sources.
Future<Compiler> compileFromSource(
    AnnotatedCode code, Uri mainUri, List<String> options) async {
  Compiler compiler = compilerFor(
      memorySourceFiles: {'main.dart': code.sourceCode}, options: options);
  compiler.stopAfterTypeInference = true;
  await compiler.run(mainUri);
  return compiler;
}

/// Compile [code] from .dill sources.
Future<Compiler> compileFromDill(
    AnnotatedCode code, Uri mainUri, List<String> options) async {
  Compiler compiler = await compileWithDill(
      entryPoint: mainUri,
      memorySourceFiles: {'main.dart': code.sourceCode},
      options: options,
      beforeRun: (Compiler compiler) {
        compiler.stopAfterTypeInference = true;
      });
  return compiler;
}

/// Compute expected and actual data for all members defined in [annotatedCode].
///
/// Actual data is computed using [computeMemberData] and [code] is compiled
/// using [compileFunction].
Future<IdData> computeData(
    String annotatedCode,
    ComputeMemberDataFunction computeMemberData,
    CompileFunction compileFunction,
    {List<String> options: const <String>[],
    bool verbose: false}) async {
  AnnotatedCode code =
      new AnnotatedCode.fromText(annotatedCode, commentStart, commentEnd);
  Map<Id, String> expectedMap = computeExpectedMap(code);
  Map<Id, ActualData> actualMap = <Id, ActualData>{};
  Uri mainUri = Uri.parse('memory:main.dart');
  Compiler compiler = await compileFunction(code, mainUri, options);
  ElementEnvironment elementEnvironment =
      compiler.backendClosedWorldForTesting.elementEnvironment;
  LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
  elementEnvironment.forEachClass(mainLibrary, (ClassEntity cls) {
    elementEnvironment.forEachClassMember(cls,
        (ClassEntity declarer, MemberEntity member) {
      if (cls == declarer) {
        computeMemberData(compiler, member, actualMap, verbose: verbose);
      }
    });
  });
  elementEnvironment.forEachLibraryMember(mainLibrary, (MemberEntity member) {
    computeMemberData(compiler, member, actualMap, verbose: verbose);
  });
  return new IdData(
      code, compiler, elementEnvironment, mainUri, expectedMap, actualMap);
}

/// Data collected by [computeData].
class IdData {
  final AnnotatedCode code;
  final Compiler compiler;
  final ElementEnvironment elementEnvironment;
  final Uri mainUri;
  final Map<Id, String> expectedMap;
  final Map<Id, ActualData> actualMap;

  IdData(this.code, this.compiler, this.elementEnvironment, this.mainUri,
      this.expectedMap, this.actualMap);

  String withAnnotations(Map<int, String> annotations) {
    StringBuffer sb = new StringBuffer();
    int end = 0;
    for (int offset in annotations.keys.toList()..sort()) {
      if (offset > end) {
        sb.write(code.sourceCode.substring(end, offset));
      }
      sb.write('/* ');
      sb.write(annotations[offset]);
      sb.write(' */');
      end = offset;
    }
    if (end < code.sourceCode.length) {
      sb.write(code.sourceCode.substring(end));
    }
    return sb.toString();
  }

  String get actualCode {
    Map<int, String> annotations = <int, String>{};
    actualMap.forEach((Id id, ActualData data) {
      annotations[data.sourceSpan.begin] = data.value;
    });
    return withAnnotations(annotations);
  }

  String get diffCode {
    Map<int, String> annotations = <int, String>{};
    actualMap.forEach((Id id, ActualData data) {
      String expected = expectedMap[id];
      if (data.value != expected) {
        expected ??= '---';
        annotations[data.sourceSpan.begin] = '${expected} | ${data.value}';
      }
    });
    expectedMap.forEach((Id id, String expected) {
      if (!actualMap.containsKey(id)) {
        int offset = compiler.reporter
            .spanFromSpannable(
                computeSpannable(elementEnvironment, mainUri, id))
            .begin;
        annotations[offset] = '${expected} | ---';
      }
    });
    return withAnnotations(annotations);
  }

  String computeDiffCodeFor(IdData other) {
    Map<int, String> annotations = <int, String>{};
    actualMap.forEach((Id id, ActualData data1) {
      ActualData data2 = other.actualMap[id];
      if (data1.value != data2?.value) {
        annotations[data1.sourceSpan.begin] =
            '${data1.value} | ${data2?.value ?? '---'}';
      }
    });
    other.actualMap.forEach((Id id, ActualData data2) {
      if (!actualMap.containsKey(id)) {
        int offset = compiler.reporter
            .spanFromSpannable(
                computeSpannable(elementEnvironment, mainUri, id))
            .begin;
        annotations[offset] = '--- | ${data2.value}';
      }
    });
    return withAnnotations(annotations);
  }
}

/// Check code for all test files int [data] using [computeFromAst] and
/// [computeFromKernel] from the respective front ends. If [skipForKernel]
/// contains the name of the test file it isn't tested for kernel.
Future checkTests(Directory dataDir, ComputeMemberDataFunction computeFromAst,
    ComputeMemberDataFunction computeFromKernel,
    {List<String> skipForKernel: const <String>[],
    List<String> options: const <String>[],
    bool verbose: false}) async {
  await for (FileSystemEntity entity in dataDir.list()) {
    print('----------------------------------------------------------------');
    print('Checking ${entity.uri}');
    print('----------------------------------------------------------------');
    String annotatedCode = await new File.fromUri(entity.uri).readAsString();
    print('--from ast------------------------------------------------------');
    await checkCode(annotatedCode, computeFromAst, compileFromSource,
        options: options, verbose: verbose);
    if (skipForKernel.contains(entity.uri.pathSegments.last)) {
      print('--skipped for kernel------------------------------------------');
      continue;
    }
    print('--from kernel---------------------------------------------------');
    await checkCode(annotatedCode, computeFromKernel, compileFromDill,
        options: options, verbose: verbose);
  }
}

/// Compiles the [annotatedCode] with the provided [options] and calls
/// [computeMemberData] for each member. The result is checked against the
/// expected data derived from [annotatedCode].
Future checkCode(
    String annotatedCode,
    ComputeMemberDataFunction computeMemberData,
    CompileFunction compileFunction,
    {List<String> options: const <String>[],
    bool verbose: false}) async {
  IdData data = await computeData(
      annotatedCode, computeMemberData, compileFunction,
      options: options, verbose: verbose);

  data.actualMap.forEach((Id id, ActualData actualData) {
    String actual = actualData.value;
    if (!data.expectedMap.containsKey(id)) {
      if (actual != '') {
        reportHere(
            data.compiler.reporter,
            actualData.sourceSpan,
            'Id $id for ${actualData.object} '
            '(${actualData.object.runtimeType}) '
            'not expected in ${data.expectedMap.keys}');
        print('--annotations diff--------------------------------------------');
        print(data.diffCode);
        print('--------------------------------------------------------------');
      }
      Expect.equals('', actual);
    } else {
      String expected = data.expectedMap.remove(id);
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
      Expect.equals(expected, actual);
    }
  });

  data.expectedMap.forEach((Id id, String expected) {
    reportHere(
        data.compiler.reporter,
        computeSpannable(data.elementEnvironment, data.mainUri, id),
        'Expected $expected for id $id missing in ${data.actualMap.keys}');
  });
  Expect.isTrue(
      data.expectedMap.isEmpty, "Ids not found: ${data.expectedMap}.");
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
      return elementEnvironment.lookupClassMember(cls, id.memberName);
    } else {
      return elementEnvironment.lookupLibraryMember(library, id.memberName);
    }
  }
  throw new UnsupportedError('Unsupported id $id.');
}

/// Compute the expectancy map from [code].
Map<Id, String> computeExpectedMap(AnnotatedCode code) {
  Map<Id, String> map = <Id, String>{};
  for (Annotation annotation in code.annotations) {
    String text = annotation.text;
    int colonPos = text.indexOf(':');
    Id id;
    String expected;
    if (colonPos == -1) {
      id = new NodeId(annotation.offset);
      expected = text;
    } else {
      id = new ElementId(text.substring(0, colonPos));
      expected = text.substring(colonPos + 1);
    }
    map[id] = expected;
  }
  return map;
}
