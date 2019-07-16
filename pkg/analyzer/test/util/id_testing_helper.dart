// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(paulberry,johnniwinther): Use the code for extraction of test data from
// annotated code from CFE.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' hide Annotation;
import 'package:front_end/src/testing/annotated_code_helper.dart';
import 'package:front_end/src/testing/id.dart'
    show ActualData, Id, IdValue, MemberId, NodeId;
import 'package:front_end/src/testing/id_testing.dart';

Future<bool> checkTests<T>(
    String rawCode,
    Future<ResolvedUnitResult> resultComputer(String rawCode),
    DataComputer<T> dataComputer) async {
  AnnotatedCode code =
      new AnnotatedCode.fromText(rawCode, commentStart, commentEnd);
  var result = await resultComputer(code.sourceCode);
  var uri = result.libraryElement.source.uri;
  var marker = 'normal';
  Map<String, MemberAnnotations<IdValue>> expectedMaps = {
    marker: new MemberAnnotations<IdValue>(),
  };
  computeExpectedMap(uri, code, expectedMaps, onFailure: onFailure);
  MemberAnnotations<IdValue> annotations = expectedMaps[marker];
  Map<Id, ActualData<T>> actualMap = {};
  dataComputer.computeUnitData(result.unit, actualMap);
  Map<Uri, AnnotatedCode> codeMap = {uri: code};
  var compiledData =
      AnalyzerCompiledData<T>(codeMap, uri, {uri: actualMap}, {});
  return await checkCode(marker, uri, codeMap, annotations, compiledData,
      dataComputer.dataValidator,
      onFailure: onFailure);
}

class AnalyzerCompiledData<T> extends CompiledData<T> {
  // TODO(johnniwinther,paulberry): Maybe this should have access to the
  // [ResolvedUnitResult] instead.
  final Map<Uri, AnnotatedCode> code;

  AnalyzerCompiledData(
      this.code,
      Uri mainUri,
      Map<Uri, Map<Id, ActualData<T>>> actualMaps,
      Map<Id, ActualData<T>> globalData)
      : super(mainUri, actualMaps, globalData);

  @override
  int getOffsetFromId(Id id, Uri uri) {
    if (id is NodeId) {
      return id.value;
    } else if (id is MemberId) {
      if (id.className != null) {
        throw UnimplementedError('TODO(paulberry): handle class members');
      }
      var name = id.memberName;
      var unit =
          parseString(content: code[uri].sourceCode, throwIfDiagnostics: false)
              .unit;
      for (var declaration in unit.declarations) {
        if (declaration is FunctionDeclaration) {
          if (declaration.name.name == name) {
            return declaration.offset;
          }
        }
      }
      throw StateError('Member not found: $name');
    } else {
      throw StateError('Unexpected id ${id.runtimeType}');
    }
  }

  @override
  void reportError(Uri uri, int offset, String message) {
    print('$offset: $message');
  }
}

void onFailure(String message) {
  throw StateError(message);
}

abstract class DataComputer<T> {
  const DataComputer();

  DataInterpreter<T> get dataValidator;

  /// Function that computes a data mapping for [unit].
  ///
  /// Fills [actualMap] with the data and [sourceSpanMap] with the source spans
  /// for the data origin.
  void computeUnitData(CompilationUnit unit, Map<Id, ActualData<T>> actualMap);
}
