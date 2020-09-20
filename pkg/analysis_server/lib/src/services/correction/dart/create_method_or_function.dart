// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMethodOrFunction extends CorrectionProducer {
  FixKind _fixKind;

  String _functionName;

  @override
  List<Object> get fixArguments => [_functionName];

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is SimpleIdentifier) {
      var nameNode = node as SimpleIdentifier;
      // prepare argument expression (to get parameter)
      ClassElement targetElement;
      Expression argument;
      {
        var target = getQualifiedPropertyTarget(node);
        if (target != null) {
          var targetType = target.staticType;
          if (targetType != null && targetType.element is ClassElement) {
            targetElement = targetType.element as ClassElement;
            argument = target.parent as Expression;
          } else {
            return;
          }
        } else {
          var enclosingClass =
              node.thisOrAncestorOfType<ClassOrMixinDeclaration>();
          targetElement = enclosingClass?.declaredElement;
          argument = nameNode;
        }
      }
      argument = stepUpNamedExpression(argument);
      // should be argument of some invocation
      var parameterElement = argument.staticParameterElement;
      if (parameterElement == null) {
        return;
      }
      // should be parameter of function type
      var parameterType = parameterElement.type;
      if (parameterType is InterfaceType && parameterType.isDartCoreFunction) {
        parameterType = FunctionTypeImpl(
          typeFormals: const [],
          parameters: const [],
          returnType: typeProvider.dynamicType,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
      if (parameterType is! FunctionType) {
        return;
      }
      var functionType = parameterType as FunctionType;
      // add proposal
      if (targetElement != null) {
        await _createMethod(builder, targetElement, functionType);
      } else {
        await _createFunction(builder, functionType);
      }
    }
  }

  /// Prepares proposal for creating function corresponding to the given
  /// [FunctionType].
  Future<void> _createExecutable(
      ChangeBuilder builder,
      FunctionType functionType,
      String name,
      String targetFile,
      int insertOffset,
      bool isStatic,
      String prefix,
      String sourcePrefix,
      String sourceSuffix,
      Element target) async {
    // build method source
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.addInsertion(insertOffset, (builder) {
        builder.write(sourcePrefix);
        builder.write(prefix);
        // may be static
        if (isStatic) {
          builder.write('static ');
        }
        // append return type
        if (builder.writeType(functionType.returnType,
            groupName: 'RETURN_TYPE')) {
          builder.write(' ');
        }
        // append name
        builder.addLinkedEdit('NAME', (builder) {
          builder.write(name);
        });
        // append parameters
        builder.writeParameters(functionType.parameters);
        // close method
        builder.write(' {$eol$prefix}');
        builder.write(sourceSuffix);
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] in the given [ClassElement].
  Future<void> _createFunction(
      ChangeBuilder builder, FunctionType functionType) async {
    var name = (node as SimpleIdentifier).name;
    // prepare environment
    var insertOffset = unit.end;
    // prepare prefix
    var prefix = '';
    var sourcePrefix = '$eol';
    var sourceSuffix = eol;
    await _createExecutable(builder, functionType, name, file, insertOffset,
        false, prefix, sourcePrefix, sourceSuffix, unit.declaredElement);
    _fixKind = DartFixKind.CREATE_FUNCTION;
    _functionName = name;
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] in the given [ClassElement].
  Future<void> _createMethod(ChangeBuilder builder,
      ClassElement targetClassElement, FunctionType functionType) async {
    var name = (node as SimpleIdentifier).name;
    // prepare environment
    var targetSource = targetClassElement.source;
    // prepare insert offset
    var targetNode = await getClassOrMixinDeclaration(targetClassElement);
    if (targetNode == null) {
      return;
    }
    var insertOffset = targetNode.end - 1;
    // prepare prefix
    var prefix = '  ';
    String sourcePrefix;
    if (targetNode.members.isEmpty) {
      sourcePrefix = '';
    } else {
      sourcePrefix = eol;
    }
    var sourceSuffix = eol;
    await _createExecutable(
        builder,
        functionType,
        name,
        targetSource.fullName,
        insertOffset,
        inStaticContext,
        prefix,
        sourcePrefix,
        sourceSuffix,
        targetClassElement);
    _fixKind = DartFixKind.CREATE_METHOD;
    _functionName = name;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateMethodOrFunction newInstance() => CreateMethodOrFunction();
}
