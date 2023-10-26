// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show Position;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMethod extends ResolvedCorrectionProducer {
  /// The kind of method to be created.
  final _MethodKind _kind;

  String _memberName = '';

  @override
  bool canBeAppliedInBulk;

  @override
  bool canBeAppliedToFile;

  /// Initialize a newly created instance that will create either an equals
  /// (operator =) or `hashCode` method based on the existing other half of the
  /// pair.
  CreateMethod.equalsOrHashCode()
      : _kind = _MethodKind.equalsOrHashCode,
        canBeAppliedInBulk = false,
        canBeAppliedToFile = true;

  /// Initialize a newly created instance that will create a method based on an
  /// invocation of an undefined method.
  CreateMethod.method()
      : _kind = _MethodKind.method,
        canBeAppliedInBulk = false,
        canBeAppliedToFile = false;

  @override
  List<Object> get fixArguments => [_memberName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_METHOD;

  @override
  FixKind get multiFixKind => DartFixKind.CREATE_METHOD_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_kind == _MethodKind.equalsOrHashCode) {
      await createEqualsOrHashCode(builder);
    } else if (_kind == _MethodKind.method) {
      await createMethod(builder);
    }
  }

  Future<void> createEqualsOrHashCode(ChangeBuilder builder) async {
    final memberDecl = node.thisOrAncestorOfType<ClassMember>();
    if (memberDecl == null) {
      return;
    }
    final classDecl = memberDecl.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl != null) {
      final classElement = classDecl.declaredElement!;

      var missingEquals = memberDecl is FieldDeclaration ||
          (memberDecl as MethodDeclaration).name.lexeme == 'hashCode';
      ExecutableElement? element;
      if (missingEquals) {
        _memberName = '==';
        element = classElement.lookUpInheritedMethod(
            _memberName, classElement.library);
      } else {
        _memberName = 'hashCode';
        element = classElement.lookUpInheritedConcreteGetter(
            _memberName, classElement.library);
      }
      if (element == null) {
        return;
      }

      final location =
          utils.prepareNewClassMemberLocation(classDecl, (_) => true);
      if (location == null) {
        return;
      }

      final element_final = element;
      await builder.addDartFileEdit(file, (fileBuilder) {
        fileBuilder.addInsertion(location.offset, (builder) {
          builder.write(location.prefix);
          builder.writeOverride(element_final, invokeSuper: true);
          builder.write(location.suffix);
        });
      });

      builder.setSelection(Position(file, location.offset));
    }
  }

  Future<void> createMethod(ChangeBuilder builder) async {
    if (node is! SimpleIdentifier || node.parent is! MethodInvocation) {
      return;
    }
    _memberName = (node as SimpleIdentifier).name;
    var invocation = node.parent as MethodInvocation;
    // prepare environment
    Element? targetElement;
    var staticModifier = false;

    CompilationUnitMember? targetNode;
    var target = invocation.realTarget;
    var utilsForTargetNode = utils;
    if (target is ExtensionOverride) {
      targetElement = target.element;
      if (targetElement is ExtensionElement) {
        targetNode = await getExtensionDeclaration(targetElement);
        if (targetNode == null) {
          return;
        }
      }
    } else if (target is Identifier &&
        target.staticElement is ExtensionElement) {
      targetElement = target.staticElement;
      if (targetElement is ExtensionElement) {
        targetNode = await getExtensionDeclaration(targetElement);
        if (targetNode == null) {
          return;
        }
      }
      staticModifier = true;
    } else if (target == null) {
      targetElement = unit.declaredElement;
      var enclosingMember = node.thisOrAncestorOfType<ClassMember>();
      if (enclosingMember == null) {
        // If the undefined identifier isn't inside a class member, then it
        // doesn't make sense to create a method.
        return;
      }
      var enclosingMemberParent = enclosingMember.parent;
      if (enclosingMemberParent is CompilationUnitMember) {
        targetNode = enclosingMemberParent;
        staticModifier = inStaticContext;
      }
    } else {
      var targetClassElement = getTargetInterfaceElement(target);
      if (targetClassElement == null) {
        return;
      }
      targetElement = targetClassElement;
      if (targetClassElement.library.isInSdk) {
        return;
      }
      // prepare target ClassDeclaration
      if (targetClassElement is MixinElement) {
        targetNode = await getMixinDeclaration(targetClassElement);
      } else if (targetClassElement is ClassElement) {
        targetNode = await getClassDeclaration(targetClassElement);
      } else if (targetClassElement is ExtensionTypeElement) {
        targetNode = await getExtensionTypeDeclaration(targetClassElement);
      }
      if (targetNode == null) {
        return;
      }
      // maybe static
      if (target is Identifier) {
        staticModifier = target.staticElement?.kind == ElementKind.CLASS ||
            target.staticElement?.kind == ElementKind.EXTENSION_TYPE ||
            target.staticElement?.kind == ElementKind.MIXIN;
      }
      // use different utils
      var targetPath = targetClassElement.source.fullName;
      var targetResolveResult =
          await unitResult.session.getResolvedUnit(targetPath);
      if (targetResolveResult is! ResolvedUnitResult) {
        return;
      }
      utilsForTargetNode = CorrectionUtils(targetResolveResult);
    }
    if (targetElement == null || targetNode == null) {
      return;
    }
    var targetLocation =
        utilsForTargetNode.prepareNewMethodLocation(targetNode);
    if (targetLocation == null) {
      return;
    }
    var targetSource = targetElement.source;
    if (targetSource == null) {
      return;
    }
    var targetFile = targetSource.fullName;
    // build method source
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.addInsertion(targetLocation.offset, (builder) {
        builder.write(targetLocation.prefix);
        // maybe "static"
        if (staticModifier) {
          builder.write('static ');
        }
        // append return type
        {
          var type = inferUndefinedExpressionType(invocation);
          if (builder.writeType(type, groupName: 'RETURN_TYPE')) {
            builder.write(' ');
          }
        }
        // append name
        builder.addLinkedEdit('NAME', (builder) {
          builder.write(_memberName);
        });
        builder.write('(');
        builder.writeParametersMatchingArguments(invocation.argumentList);
        builder.write(') {}');
        builder.write(targetLocation.suffix);
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
  }
}

/// A representation of the kind of element that should be suggested.
enum _MethodKind {
  equalsOrHashCode,
  method,
}
