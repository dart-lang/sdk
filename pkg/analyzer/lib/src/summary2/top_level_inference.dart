// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/builder/source_library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/reference.dart';

DartType _dynamicIfNull(DartType type) {
  if (type == null || type.isBottom || type.isDartCoreNull) {
    return DynamicTypeImpl.instance;
  }
  return type;
}

class TopLevelInference {
  final Linker linker;
  final Reference libraryRef;
  final UnitBuilder unit;

  TopLevelInference(this.linker, this.libraryRef, this.unit);

  void infer() {
    _inferFieldsTemporary();
    _inferConstructorFieldFormals();
  }

  void _inferConstructorFieldFormals() {
    _visitClassList((unitDeclaration) {
      var members = unitDeclaration.classOrMixinDeclaration_members;

      var fields = <String, LinkedNodeType>{};
      _visitClassFields(unitDeclaration, (field) {
        var name = unit.context.getVariableName(field);
        var type = field.variableDeclaration_type2;
        if (type == null) {
          throw StateError('Field $name should have a type.');
        }
        fields[name] = type;
      });

      for (var member in members) {
        if (member.kind == LinkedNodeKind.constructorDeclaration) {
          for (var parameter in member.constructorDeclaration_parameters
              .formalParameterList_parameters) {
            if (parameter.kind == LinkedNodeKind.fieldFormalParameter &&
                parameter.fieldFormalParameter_type2 == null) {
              var name = unit.context.getSimpleName(
                parameter.normalFormalParameter_identifier,
              );
              var type = fields[name];
              if (type == null) {
                type = LinkedNodeTypeBuilder(
                  kind: LinkedNodeTypeKind.dynamic_,
                );
              }
              parameter.fieldFormalParameter_type2 = type;
            }
          }
        }
      }
    });
  }

  void _inferFieldsTemporary() {
    var unitDeclarations = unit.node.compilationUnit_declarations;
    for (LinkedNodeBuilder unitDeclaration in unitDeclarations) {
      if (unitDeclaration.kind == LinkedNodeKind.classDeclaration) {
        _visitClassFields(unitDeclaration, (field) {
          var name = unit.context.getVariableName(field);
          // TODO(scheglov) Use inheritance
          if (field.variableDeclaration_type2 == null) {
            field.variableDeclaration_type2 = LinkedNodeTypeBuilder(
              kind: LinkedNodeTypeKind.dynamic_,
            );
          }
        });

        var members = unitDeclaration.classOrMixinDeclaration_members;
        for (var member in members) {
          if (member.kind == LinkedNodeKind.methodDeclaration) {
            // TODO(scheglov) Use inheritance
            if (member.methodDeclaration_returnType2 == null) {
              if (unit.context.isSetter(member)) {
                member.methodDeclaration_returnType2 = LinkedNodeTypeBuilder(
                  kind: LinkedNodeTypeKind.void_,
                );
              } else {
                member.methodDeclaration_returnType2 = LinkedNodeTypeBuilder(
                  kind: LinkedNodeTypeKind.dynamic_,
                );
              }
            }
          }
        }
      } else if (unitDeclaration.kind == LinkedNodeKind.functionDeclaration) {
        if (unit.context.isSetter(unitDeclaration)) {
          unitDeclaration.functionDeclaration_returnType2 =
              LinkedNodeTypeBuilder(
            kind: LinkedNodeTypeKind.void_,
          );
        }
      } else if (unitDeclaration.kind ==
          LinkedNodeKind.topLevelVariableDeclaration) {
        var variableList =
            unitDeclaration.topLevelVariableDeclaration_variableList;
        for (var variable in variableList.variableDeclarationList_variables) {
          // TODO(scheglov) infer in the correct order
          if (variable.variableDeclaration_type2 == null) {
            _inferVariableTypeFromInitializerTemporary(variable);
          }
        }
      }
    }
  }

  void _inferVariableTypeFromInitializerTemporary(LinkedNodeBuilder node) {
    var storedInitializer = node.variableDeclaration_initializer;

    if (storedInitializer == null) {
      node.variableDeclaration_type2 = LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.dynamic_,
      );
      return;
    }

    var reader = AstBinaryReader(
      unit.context.bundleContext.elementFactory.rootReference,
      unit.context.bundleContext.referencesData,
      unit.context.tokens,
    );

    // TODO(scheglov) This duplicates `readInitializer` in LinkedUnitContext
    Expression initializer = reader.readNode(storedInitializer);

    var container =
        astFactory.expressionFunctionBody(null, null, initializer, null);
//    expression.accept(_astRewriteVisitor);
    initializer = container.expression;
//    if (_linker.getAst != null) {
//      expression.accept(_typeResolverVisitor);
//    }
//    expression.accept(_variableResolverVisitor);
//    if (_linker.getAst != null) {
//      expression.accept(_partialResolverVisitor);
//    }

    var bundleContext = unit.context.bundleContext;
    var library = bundleContext.elementFactory.elementOfReference(libraryRef);
    var inheritance = InheritanceManager2(linker.typeSystem);

    var errorListener = RecordingErrorListener();
    var source = _FakeSource();
    var resolverVisitor = new ResolverVisitor(
        inheritance, library, source, linker.typeProvider, errorListener,
        nameScope: LibraryScope(library),
        propagateTypes: false,
        reportConstEvaluationErrors: false);
    initializer.accept(resolverVisitor);

    // TODO(scheglov) use AstBinaryWriter to put resolved initializer

    var initializerType = initializer.staticType;
    initializerType = _dynamicIfNull(initializerType);

    if (initializerType is DynamicTypeImpl) {
      node.variableDeclaration_type2 = LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.dynamic_,
      );
    } else if (initializerType is InterfaceTypeImpl) {
      var element = initializerType.element as ClassElementImpl;
      node.variableDeclaration_type2 = LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.interface,
        interfaceClass: linker.indexOfReference(element.reference),
      );
    } else {
      // TODO(scheglov) support other types
      throw UnimplementedError('${initializerType.runtimeType}');
    }
  }

  void _visitClassFields(
      LinkedNode class_, void Function(LinkedNodeBuilder) f) {
    var members = class_.classOrMixinDeclaration_members;

    for (var member in members) {
      if (member.kind == LinkedNodeKind.fieldDeclaration) {
        var variableList = member.fieldDeclaration_fields;
        for (var field in variableList.variableDeclarationList_variables) {
          f(field);
        }
      }
    }
  }

  void _visitClassList(void Function(LinkedNodeBuilder) f) {
    var unitDeclarations = unit.node.compilationUnit_declarations;
    for (LinkedNodeBuilder unitDeclaration in unitDeclarations) {
      if (unitDeclaration.kind == LinkedNodeKind.classDeclaration) {
        f(unitDeclaration);
      }
    }
  }

  void _visitClassMethods(
      LinkedNode class_, void Function(LinkedNodeBuilder) f) {
    var members = class_.classOrMixinDeclaration_members;
    for (var member in members) {
      if (member.kind == LinkedNodeKind.methodDeclaration) {
        f(member);
      }
    }
  }
}

class _FakeSource implements Source {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
