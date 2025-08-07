// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMethod extends ResolvedCorrectionProducer {
  /// The kind of method to be created.
  final _MethodKind _kind;

  String _memberName = '';

  @override
  final CorrectionApplicability applicability;

  /// Initializes a newly created instance that will create either an equality
  /// (`operator ==`) method or `hashCode` getter based on the existing other
  /// half of the pair.
  CreateMethod.equalityOrHashCode({required super.context})
    : _kind = _MethodKind.equalityOrHashCode,
      applicability = CorrectionApplicability.acrossSingleFile;

  /// Initializes a newly created instance that will create a method based on an
  /// invocation of an undefined method.
  CreateMethod.method({required super.context})
    : _kind = _MethodKind.method,
      applicability = CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_memberName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_METHOD;

  @override
  FixKind get multiFixKind => DartFixKind.CREATE_METHOD_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) => switch (_kind) {
    _MethodKind.equalityOrHashCode => _createEqualsOrHashCode(builder),
    _MethodKind.method => _createMethod(builder),
  };

  Future<void> _createEqualsOrHashCode(ChangeBuilder builder) async {
    var memberDecl = node.thisOrAncestorOfType<ClassMember>();
    if (memberDecl == null) {
      return;
    }
    // TODO(srawlins): Shouldn't this be available on enums and mixins as well?
    var classDecl = memberDecl.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) {
      return;
    }

    var classElement = classDecl.declaredFragment!.element;
    var missingEquals =
        memberDecl is FieldDeclaration ||
        (memberDecl as MethodDeclaration).name.lexeme == 'hashCode';

    await builder.addDartFileEdit(file, (fileBuilder) {
      fileBuilder.insertIntoUnitMember(classDecl, (builder) {
        ExecutableElement? element;
        if (missingEquals) {
          _memberName = '==';
          element = classElement.getInheritedMember(
            Name.forLibrary(classElement.library, _memberName),
          );
        } else {
          _memberName = 'hashCode';
          element = classElement.getInheritedMember(
            Name.forLibrary(classElement.library, _memberName),
          );
        }
        if (element == null) {
          return;
        }

        builder.writeOverride(element, invokeSuper: true);
      });
    });
  }

  Future<void> _createMethod(ChangeBuilder builder) async {
    if (node is! SimpleIdentifier) return;
    _memberName = (node as SimpleIdentifier).name;

    var invocation = node.parent;
    switch (invocation) {
      case MethodInvocation():
        await _createMethodFromMethodInvocation(builder, invocation);
      case DotShorthandInvocation():
        await _createMethodFromDotShorthandInvocation(builder, invocation);
    }
  }

  Future<void> _createMethodFromDotShorthandInvocation(
    ChangeBuilder builder,
    DotShorthandInvocation invocation,
  ) async {
    var targetClassElement = computeDotShorthandContextTypeElement(
      invocation,
      unitResult.libraryElement,
    );
    if (targetClassElement == null) return;

    var targetNode = await _declarationNodeFromElement(targetClassElement);
    if (targetNode is! CompilationUnitMember) return;

    await _writeMethod(
      builder,
      invocation,
      invocation.argumentList,
      targetClassElement.firstFragment,
      targetNode,
      hasStaticModifier: true,
    );
  }

  Future<void> _createMethodFromMethodInvocation(
    ChangeBuilder builder,
    MethodInvocation invocation,
  ) async {
    // Prepare environment.
    Fragment? targetFragment;
    var hasStaticModifier = false;

    CompilationUnitMember? targetNode;
    var target = invocation.realTarget;
    if (target is ExtensionOverride) {
      // This case should be handled by the "Add extension method" quick fix
      return;
    } else if (target is Identifier && target.element is ExtensionElement) {
      // This case should be handled by the "Add extension method" quick fix
      return;
    } else if (target == null) {
      targetFragment = unit.declaredFragment;
      var enclosingMember = node.thisOrAncestorOfType<ClassMember>();
      if (enclosingMember == null) {
        // If the undefined identifier isn't inside a class member, then it
        // doesn't make sense to create a method.
        return;
      }
      var enclosingMemberParent = enclosingMember.parent;
      if (enclosingMemberParent is CompilationUnitMember &&
          enclosingMemberParent is! ExtensionDeclaration) {
        targetNode = enclosingMemberParent;
        hasStaticModifier = switch (enclosingMember) {
          ConstructorDeclaration(:var factoryKeyword) => factoryKeyword != null,
          MethodDeclaration(:var isStatic) => isStatic,
          FieldDeclaration(
            :var isStatic,
            fields: VariableDeclarationList(:var isLate),
          ) =>
            isStatic || !isLate,
        };
      }
    } else {
      var targetClassElement = getTargetInterfaceElement(target);
      if (targetClassElement == null) return;
      targetFragment = targetClassElement.firstFragment;

      targetNode = await _declarationNodeFromElement(targetClassElement);
      if (targetNode == null) return;

      // Maybe static.
      if (target is Identifier) {
        hasStaticModifier =
            target.element?.kind == ElementKind.CLASS ||
            target.element?.kind == ElementKind.ENUM ||
            target.element?.kind == ElementKind.EXTENSION_TYPE ||
            target.element?.kind == ElementKind.MIXIN;
      }
    }
    await _writeMethod(
      builder,
      invocation,
      invocation.argumentList,
      targetFragment,
      targetNode,
      hasStaticModifier: hasStaticModifier,
    );
  }

  Future<CompilationUnitMember?> _declarationNodeFromElement(
    InterfaceElement element,
  ) async {
    if (element.library.isInSdk) return null;
    if (element is MixinElement) {
      var fragment = element.firstFragment;
      return await getMixinDeclaration(fragment);
    } else if (element is ClassElement) {
      var fragment = element.firstFragment;
      return await getClassDeclaration(fragment);
    } else if (element is ExtensionTypeElement) {
      var fragment = element.firstFragment;
      return await getExtensionTypeDeclaration(fragment);
    } else if (element is EnumElement) {
      var fragment = element.firstFragment;
      return await getEnumDeclaration(fragment);
    }
    return null;
  }

  /// Inserts the new method into the source code.
  Future<void> _writeMethod(
    ChangeBuilder builder,
    Expression invocation,
    ArgumentList argumentList,
    Fragment? targetFragment,
    CompilationUnitMember? targetNode, {
    required bool hasStaticModifier,
  }) async {
    var targetSource = targetFragment?.libraryFragment!.source;
    if (targetSource == null) return;

    var targetFile = targetSource.fullName;
    var type = inferUndefinedExpressionType(invocation);
    if (type is InvalidType) {
      return;
    }

    await builder.addDartFileEdit(targetFile, (builder) {
      if (targetNode == null) return;
      builder.insertMethod(targetNode, (builder) {
        // Maybe 'static'.
        if (hasStaticModifier) {
          builder.write('static ');
        }
        // Append return type.
        if (builder.writeType(type, groupName: 'RETURN_TYPE')) {
          builder.write(' ');
        }

        // Append name.
        builder.addLinkedEdit('NAME', (builder) {
          builder.write(_memberName);
        });
        builder.write('(');
        builder.writeParametersMatchingArguments(argumentList);
        builder.write(')');
        if (type?.isDartAsyncFuture == true) {
          builder.write(' async');
        }
        builder.write(' {}');
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
  }
}

/// A representation of the kind of element that should be suggested.
enum _MethodKind { equalityOrHashCode, method }
