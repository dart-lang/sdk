// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMethodOrFunction extends ResolvedCorrectionProducer {
  @override
  final FixKind fixKind;

  String _functionName = '';

  /// The [Element] for the target of the node's parent, if that is a
  /// [PrefixedIdentifier] or [PropertyAccess], and `null` otherwise.
  final Element? _targetElement;

  factory CreateMethodOrFunction({required CorrectionProducerContext context}) {
    if (context is StubCorrectionProducerContext) {
      return CreateMethodOrFunction._(
        context: context,
        fixKind: DartFixKind.createFunctionTearoff,
      );
    }

    if (context.node case SimpleIdentifier node) {
      // Prepare the argument expression (to get the parameter).
      Element? targetElement;
      var target = getQualifiedPropertyTarget(node);
      if (target == null) {
        targetElement = node.enclosingInterfaceElement;
      } else {
        var targetType = target.staticType;
        if (targetType is InterfaceType) {
          targetElement = targetType.element;
        } else {
          targetElement = switch (target) {
            SimpleIdentifier() => target.element,
            PrefixedIdentifier() => target.identifier.element,
            _ => null,
          };
        }
      }

      return CreateMethodOrFunction._(
        context: context,
        targetElement: targetElement,
        fixKind: targetElement is InterfaceElement
            ? DartFixKind.createMethodTearoff
            : DartFixKind.createFunctionTearoff,
      );
    }

    return CreateMethodOrFunction._(
      context: context,
      fixKind: DartFixKind.createFunctionTearoff,
    );
  }

  CreateMethodOrFunction._({
    required super.context,
    Element? targetElement,
    required this.fixKind,
  }) : _targetElement = targetElement;

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_functionName];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node case SimpleIdentifier node) {
      DartType? parameterType;
      var fieldTypeNode = climbPropertyAccess(node);
      parameterType = inferUndefinedExpressionType(fieldTypeNode);
      if (parameterType is InvalidType) {
        return;
      }

      var target = getQualifiedPropertyTarget(node);

      if (parameterType == null) {
        // If we cannot infer the type, we cannot create a method or function.
        return;
      }

      if (parameterType is InterfaceType && parameterType.isDartCoreFunction) {
        parameterType = FunctionTypeImpl(
          typeParameters: const [],
          parameters: const [],
          returnType: DynamicTypeImpl.instance,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }

      if (parameterType is! FunctionType) {
        // If the type is not a function type, we cannot create a method or
        // function.
        return;
      }

      if (_targetElement is InterfaceElement) {
        var isStatic =
            (target is SimpleIdentifier &&
                target.element is InterfaceElement) ||
            (target is PrefixedIdentifier &&
                target.identifier.element is InterfaceElement);
        await _createMethod(
          builder,
          _targetElement,
          parameterType,
          isStatic: isStatic,
        );
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
    String prefix, {
    required bool leadingEol,
    required bool trailingEol,
  }) async {
    // build method source
    await builder.addDartFileEdit(targetFile, (builder) {
      var eol = builder.eol;
      builder.addInsertion(insertOffset, (builder) {
        if (leadingEol) {
          builder.writeln();
        }
        builder.write(prefix);
        // may be static
        if (isStatic) {
          builder.write('static ');
        }
        // append return type
        if (builder.writeType(
          functionType.returnType,
          groupName: 'RETURN_TYPE',
        )) {
          builder.write(' ');
        }
        // append name
        builder.addLinkedEdit('NAME', (builder) {
          builder.write(name);
        });
        // append type parameters
        builder.writeTypeParameters(functionType.typeParameters);
        // append parameters
        builder.writeFormalParameters(functionType.formalParameters);
        if (functionType.returnType.isDartAsyncFuture) {
          builder.write(' async');
        }
        // close method
        builder.write(' {$eol$prefix}');
        if (trailingEol) {
          builder.writeln();
        }
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] inside the target element.
  Future<void> _createFunction(
    ChangeBuilder builder,
    FunctionType functionType,
  ) async {
    var name = (node as SimpleIdentifier).name;
    // prepare environment
    var insertOffset = unit.end;
    // prepare prefix
    var prefix = '';
    await _createExecutable(
      builder,
      functionType,
      name,
      file,
      insertOffset,
      false,
      prefix,
      leadingEol: true,
      trailingEol: true,
    );
    _functionName = name;
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] inside the target element.
  Future<void> _createMethod(
    ChangeBuilder builder,
    InterfaceElement targetClassElement,
    FunctionType functionType, {
    required bool isStatic,
  }) async {
    var name = (node as SimpleIdentifier).name;
    // prepare environment
    var targetSource = targetClassElement.firstFragment.libraryFragment.source;
    // prepare insert offset
    CompilationUnitMember? targetNode;
    List<ClassMember>? classMembers;
    if (targetClassElement is MixinElement) {
      var fragment = targetClassElement.firstFragment;
      var node = targetNode = await getMixinDeclaration(fragment);
      classMembers = node?.members;
    } else if (targetClassElement is ClassElement) {
      var fragment = targetClassElement.firstFragment;
      var node = targetNode = await getClassDeclaration(fragment);
      classMembers = node?.members;
    } else if (targetClassElement is ExtensionTypeElement) {
      var fragment = targetClassElement.firstFragment;
      var node = targetNode = await getExtensionTypeDeclaration(fragment);
      classMembers = node?.members;
    } else if (targetClassElement is EnumElement) {
      var fragment = targetClassElement.firstFragment;
      var node = targetNode = await getEnumDeclaration(fragment);
      classMembers = node?.members;
    }
    if (targetNode == null || classMembers == null) {
      return;
    }
    var insertOffset = targetNode.end - 1;
    // prepare prefix
    var prefix = '  ';
    var leadingEol = classMembers.isNotEmpty;
    var trailingEol = true;
    await _createExecutable(
      builder,
      functionType,
      name,
      targetSource.fullName,
      insertOffset,
      isStatic || inStaticContext,
      prefix,
      leadingEol: leadingEol,
      trailingEol: trailingEol,
    );
    _functionName = name;
  }
}
