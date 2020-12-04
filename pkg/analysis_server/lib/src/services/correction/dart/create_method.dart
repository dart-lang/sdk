// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show Position;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateMethod extends CorrectionProducer {
  /// The kind of method to be created.
  final _MethodKind _kind;

  String _memberName;

  CreateMethod(this._kind);

  @override
  List<Object> get fixArguments => [_memberName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_METHOD;

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
      final classElement = classDecl.declaredElement;

      var missingEquals = memberDecl is FieldDeclaration ||
          (memberDecl as MethodDeclaration).name.name == 'hashCode';
      ExecutableElement element;
      if (missingEquals) {
        _memberName = '==';
        element = classElement.lookUpInheritedMethod(
            _memberName, classElement.library);
      } else {
        _memberName = 'hashCode';
        element = classElement.lookUpInheritedConcreteGetter(
            _memberName, classElement.library);
      }

      final location =
          utils.prepareNewClassMemberLocation(classDecl, (_) => true);

      await builder.addDartFileEdit(file, (fileBuilder) {
        fileBuilder.addInsertion(location.offset, (builder) {
          builder.write(location.prefix);
          builder.writeOverride(element, invokeSuper: true);
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
    Element targetElement;
    var staticModifier = false;

    CompilationUnitMember targetNode;
    var target = invocation.realTarget;
    var utils = this.utils;
    if (target is ExtensionOverride) {
      targetElement = target.staticElement;
      targetNode = await getExtensionDeclaration(targetElement);
      if (targetNode == null) {
        return;
      }
    } else if (target is Identifier &&
        target.staticElement is ExtensionElement) {
      targetElement = target.staticElement;
      targetNode = await getExtensionDeclaration(targetElement);
      if (targetNode == null) {
        return;
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
      targetNode = enclosingMember.parent;
      staticModifier = inStaticContext;
    } else {
      var targetClassElement = getTargetClassElement(target);
      if (targetClassElement == null) {
        return;
      }
      targetElement = targetClassElement;
      if (targetClassElement.librarySource.isInSystemLibrary) {
        return;
      }
      // prepare target ClassDeclaration
      targetNode = await getClassOrMixinDeclaration(targetClassElement);
      if (targetNode == null) {
        return;
      }
      // maybe static
      if (target is Identifier) {
        staticModifier = target.staticElement.kind == ElementKind.CLASS;
      }
      // use different utils
      var targetPath = targetClassElement.source.fullName;
      var targetResolveResult =
          await resolvedResult.session.getResolvedUnit(targetPath);
      utils = CorrectionUtils(targetResolveResult);
    }
    var targetLocation = utils.prepareNewMethodLocation(targetNode);
    var targetFile = targetElement.source.fullName;
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

  /// Return an instance of this class that will create either an equals
  /// (operator =) or `hashCode` method based on the existing other half of the
  /// pair. Used as a tear-off in `FixProcessor`.
  static CreateMethod equalsOrHashCode() =>
      CreateMethod(_MethodKind.equalsOrHashCode);

  /// Return an instance of this class that will create a method based on an
  /// invocation of an undefined method. Used as a tear-off in `FixProcessor`.
  static CreateMethod method() => CreateMethod(_MethodKind.method);
}

/// A representation of the kind of element that should be suggested.
enum _MethodKind {
  equalsOrHashCode,
  method,
}
