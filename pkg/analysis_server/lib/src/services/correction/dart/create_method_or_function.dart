// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMethodOrFunction extends ResolvedCorrectionProducer {
  FixKind _fixKind = DartFixKind.CREATE_METHOD;

  String _functionName = '';

  CreateMethodOrFunction({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_functionName];

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var nameNode = node;
    if (nameNode is SimpleIdentifier) {
      // prepare argument expression (to get parameter)
      InterfaceElement2? targetElement;
      Expression argument;
      var target = getQualifiedPropertyTarget(node);
      if (target != null) {
        var targetType = target.staticType;
        if (targetType is InterfaceType) {
          targetElement = targetType.element3;
          argument = target.parent as Expression;
        } else {
          return;
        }
      } else {
        targetElement = node.enclosingInterfaceElement2;
        argument = nameNode;
      }
      argument = stepUpNamedExpression(argument);
      // should be argument of some invocation
      // or child of an expression that is one
      var parameterElement = argument.correspondingParameter;
      if (argument.parent case ConditionalExpression parent) {
        if (argument == parent.condition) {
          return;
        }
        parameterElement = parent.correspondingParameter;
      }
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
      // add proposal
      if (targetElement != null) {
        await _createMethod(builder, targetElement, parameterType);
      } else {
        await _createFunction(builder, parameterType);
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
  ) async {
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
        builder.writeFormalParameters(functionType.formalParameters);
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
  /// [FunctionType] inside the target element.
  Future<void> _createFunction(
      ChangeBuilder builder, FunctionType functionType) async {
    var name = (node as SimpleIdentifier).name;
    // prepare environment
    var insertOffset = unit.end;
    // prepare prefix
    var prefix = '';
    var sourcePrefix = eol;
    var sourceSuffix = eol;
    await _createExecutable(
      builder,
      functionType,
      name,
      file,
      insertOffset,
      false,
      prefix,
      sourcePrefix,
      sourceSuffix,
    );
    _fixKind = DartFixKind.CREATE_FUNCTION;
    _functionName = name;
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] inside the target element.
  Future<void> _createMethod(
    ChangeBuilder builder,
    InterfaceElement2 targetClassElement,
    FunctionType functionType,
  ) async {
    var name = (node as SimpleIdentifier).name;
    // prepare environment
    var targetSource = targetClassElement.firstFragment.libraryFragment.source;
    // prepare insert offset
    CompilationUnitMember? targetNode;
    List<ClassMember>? classMembers;
    if (targetClassElement is MixinElement2) {
      var fragment = targetClassElement.firstFragment;
      var node = targetNode = await getMixinDeclaration2(fragment);
      classMembers = node?.members;
    } else if (targetClassElement is ClassElement2) {
      var fragment = targetClassElement.firstFragment;
      var node = targetNode = await getClassDeclaration2(fragment);
      classMembers = node?.members;
    }
    if (targetNode == null || classMembers == null) {
      return;
    }
    var insertOffset = targetNode.end - 1;
    // prepare prefix
    var prefix = '  ';
    String sourcePrefix;
    if (classMembers.isEmpty) {
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
    );
    _fixKind = DartFixKind.CREATE_METHOD;
    _functionName = name;
  }
}
