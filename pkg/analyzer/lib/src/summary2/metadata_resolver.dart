// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/builder/source_library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/reference.dart';

class MetadataResolver {
  AstResolver _astResolver;

  MetadataResolver(Linker linker, Reference libraryRef) {
    _astResolver = AstResolver(linker, libraryRef);
  }

  void resolve(UnitBuilder unit) {
    var unitDeclarations = unit.node.compilationUnit_declarations;
    for (LinkedNodeBuilder unitDeclaration in unitDeclarations) {
      var kind = unitDeclaration.kind;
      if (_isAnnotatedNode(kind)) {
        _annotatedNode(
          unit,
          unitDeclaration,
        );
      }
      if (kind == LinkedNodeKind.classDeclaration) {
        _class(unit, unitDeclaration);
      } else if (kind == LinkedNodeKind.enumDeclaration) {
        _enumDeclaration(unit, unitDeclaration);
      } else if (kind == LinkedNodeKind.functionDeclaration) {
        var function = unitDeclaration.functionDeclaration_functionExpression;
        _formalParameterList(
          unit,
          function.functionExpression_formalParameters,
        );
      } else if (kind == LinkedNodeKind.topLevelVariableDeclaration) {
        _variables(
          unit,
          unitDeclaration,
          unitDeclaration.topLevelVariableDeclaration_variableList,
        );
      }
    }
  }

  void _annotatedNode(UnitBuilder unit, LinkedNodeBuilder node) {
    var unresolved = node.annotatedNode_metadata;
    var resolved = _list(unit, unresolved);
    node.annotatedNode_metadata = resolved;
  }

  void _class(UnitBuilder unit, LinkedNodeBuilder unitDeclaration) {
    var members = unitDeclaration.classOrMixinDeclaration_members;
    for (var classMember in members) {
      var kind = classMember.kind;
      if (_isAnnotatedNode(kind)) {
        _annotatedNode(unit, classMember);
      }
      if (kind == LinkedNodeKind.fieldDeclaration) {
        _variables(
          unit,
          classMember,
          classMember.fieldDeclaration_fields,
        );
      } else if (kind == LinkedNodeKind.methodDeclaration) {
        _formalParameterList(
          unit,
          classMember.methodDeclaration_formalParameters,
        );
      }
    }
  }

  void _enumDeclaration(UnitBuilder unit, LinkedNodeBuilder node) {
    for (var constant in node.enumDeclaration_constants) {
      var kind = constant.kind;
      if (kind == LinkedNodeKind.enumConstantDeclaration) {
        _annotatedNode(unit, constant);
      }
    }
  }

  void _formalParameterList(UnitBuilder unit, LinkedNodeBuilder node) {
    if (node == null) return;

    for (var parameter in node.formalParameterList_parameters) {
      if (parameter.kind == LinkedNodeKind.defaultFormalParameter) {
        var actual = parameter.defaultFormalParameter_parameter;
        var unresolved = actual.normalFormalParameter_metadata;
        var resolved = _list(unit, unresolved);
        actual.normalFormalParameter_metadata = resolved;
      } else {
        var unresolved = parameter.normalFormalParameter_metadata;
        var resolved = _list(unit, unresolved);
        parameter.normalFormalParameter_metadata = resolved;
      }
    }
  }

  List<LinkedNodeBuilder> _list(UnitBuilder unit, List<LinkedNode> unresolved) {
    var resolved = List<LinkedNodeBuilder>(unresolved.length);
    for (var i = 0; i < unresolved.length; ++i) {
      var unresolvedNode = unresolved[i];

      var reader = AstBinaryReader(unit.context);
      var ast = reader.readNode(unresolvedNode) as Annotation;
      ast.elementAnnotation = ElementAnnotationImpl(null);

      // Set some parent, so that resolver does not bail out.
      astFactory.libraryDirective(null, [ast], null, null, null);

      var resolvedNode = _astResolver.resolve(unit, ast);
      resolved[i] = resolvedNode;
    }
    return resolved;
  }

  /// Resolve annotations of the [declaration] (field or top-level variable),
  /// and set them as metadata for each variable in the [variableList].
  void _variables(UnitBuilder unit, LinkedNodeBuilder declaration,
      LinkedNodeBuilder variableList) {
    for (var variable in variableList.variableDeclarationList_variables) {
      var unresolved = declaration.annotatedNode_metadata;
      var resolved = _list(unit, unresolved);
      variable.annotatedNode_metadata = resolved;
    }
  }

  static bool _isAnnotatedNode(LinkedNodeKind kind) {
    return kind == LinkedNodeKind.classDeclaration ||
        kind == LinkedNodeKind.classTypeAlias ||
        kind == LinkedNodeKind.constructorDeclaration ||
        kind == LinkedNodeKind.enumDeclaration ||
        kind == LinkedNodeKind.functionDeclaration ||
        kind == LinkedNodeKind.functionTypeAlias ||
        kind == LinkedNodeKind.methodDeclaration;
  }
}
