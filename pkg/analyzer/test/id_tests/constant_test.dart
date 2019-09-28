// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(
      Platform.script.resolve('../../../front_end/test/constants/data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const ConstantsDataComputer(), [analyzerConstantUpdate2018Config]));
}

class ConstantsDataComputer extends DataComputer<String> {
  const ConstantsDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<String>> actualMap) {
    ConstantsDataExtractor(unit.declaredElement.source.uri, actualMap)
        .run(unit);
  }
}

class ConstantsDataExtractor extends AstDataExtractor<String> {
  ConstantsDataExtractor(Uri uri, Map<Id, ActualData<String>> actualMap)
      : super(uri, actualMap);

  @override
  String computeNodeValue(Id id, AstNode node) {
    if (node is Identifier) {
      var element = node.staticElement;
      if (element is PropertyAccessorElement && element.isSynthetic) {
        var variable = element.variable;
        if (!variable.isSynthetic && variable.isConst) {
          var value = variable.constantValue;
          if (value != null) return _stringify(value);
        }
      }
    }
    return null;
  }

  String _stringify(DartObject value) {
    var type = value.type;
    if (type is InterfaceType) {
      if (type.isDartCoreNull) return 'Null()';
      if (type.isDartCoreBool) return 'Bool(${value.toBoolValue()})';
      if (type.isDartCoreString) return 'String(${value.toStringValue()})';
      if (type.isDartCoreInt) return 'Int(${value.toIntValue()})';
      if (type.isDartCoreDouble) return 'Double(${value.toDoubleValue()})';
      if (type.isDartCoreSymbol) return 'Symbol(${value.toSymbolValue()})';
      if (type.isDartCoreSet) {
        var elements = value.toSetValue().map(_stringify).join(',');
        return 'Set<${type.typeArguments[0]}>($elements)';
      }
      if (type.isDartCoreList) {
        var elements = value.toListValue().map(_stringify).join(',');
        return 'List<${type.typeArguments[0]}>($elements)';
      }
      if (type.isDartCoreMap) {
        var typeArguments = type.typeArguments.join(',');
        var elements = value.toMapValue().entries.map((entry) {
          var key = _stringify(entry.key);
          var value = _stringify(entry.value);
          return '$key:$value';
        }).join(',');
        return 'Map<$typeArguments>($elements)';
      }
    } else if (type is FunctionType) {
      var element = value.toFunctionValue();
      return 'Function(${element.name},type=${value.type})';
    }
    throw UnimplementedError('_stringify for type $type');
  }
}
