// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:front_end/src/base/instrumentation.dart' as fasta;
import 'package:front_end/src/fasta/compiler_context.dart' as fasta;
import 'package:front_end/src/fasta/testing/validating_instrumentation.dart'
    as fasta;
import 'package:kernel/kernel.dart' as fasta;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'front_end_test_common.dart';

main() {
  // Use a group() wrapper to specify the timeout.
  group('front_end_inference_test', () {
    defineReflectiveSuite(() {
      defineReflectiveTests(RunFrontEndInferenceTest);
    });
  }, timeout: new Timeout(const Duration(seconds: 120)));
}

@reflectiveTest
class RunFrontEndInferenceTest extends RunFrontEndTest {
  @override
  get testSubdir => 'inference';

  @override
  void visitUnit(TypeProvider typeProvider, CompilationUnit unit,
      fasta.ValidatingInstrumentation validation, Uri uri) {
    unit.accept(new _InstrumentationVisitor(validation, uri));
  }
}

/**
 * Visitor for ASTs that reports instrumentation for types.
 */
class _InstrumentationVisitor extends RecursiveAstVisitor<Null> {
  final fasta.Instrumentation _instrumentation;
  final Uri uri;
  ElementNamer elementNamer = new ElementNamer(null);

  _InstrumentationVisitor(this._instrumentation, this.uri);

  visitBinaryExpression(BinaryExpression node) {
    super.visitBinaryExpression(node);
    _recordTarget(node.operator.charOffset, node.staticElement);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    ElementNamer oldElementNamer = elementNamer;
    if (node.factoryKeyword != null) {
      // Factory constructors are represented in kernel as static methods, so
      // their type parameters get replicated, e.g.:
      //     class C<T> {
      //       factory C.ctor() {
      //         T t; // Refers to C::T
      //         ...
      //       }
      //     }
      // gets converted to:
      //     class C<T> {
      //       static C<T> C.ctor<T>() {
      //         T t; // Refers to C::ctor::T
      //         ...
      //       }
      //     }
      // So to match kernel behavior, we have to arrange for this renaming to
      // happen during output.
      elementNamer = new ElementNamer(node.element);
    }
    super.visitConstructorDeclaration(node);
    elementNamer = oldElementNamer;
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);
    if (node.type == null) {
      _recordType(node.identifier.offset, node.element.type);
    }
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);

    bool isSetter = node.element.kind == ElementKind.SETTER;
    bool isLocalFunction = node.element is LocalElement &&
        node.element.enclosingElement is! CompilationUnitElement;

    if (isSetter || isLocalFunction) {
      if (node.returnType == null) {
        _instrumentation.record(
            uri,
            node.name.offset,
            isSetter ? 'topType' : 'returnType',
            new InstrumentationValueForType(
                node.element.returnType, elementNamer));
      }
      var parameters = node.functionExpression.parameters;
      for (var parameter in parameters.parameters) {
        // Note: it's tempting to check `parameter.type == null`, but that
        // doesn't work because of function-typed formal parameter syntax.
        if (parameter.element.hasImplicitType) {
          _recordType(parameter.identifier.offset, parameter.element.type);
        }
      }
    }
  }

  visitFunctionExpression(FunctionExpression node) {
    super.visitFunctionExpression(node);
    if (node.parent is! FunctionDeclaration) {
      DartType type = node.staticType;
      if (type is FunctionType) {
        _instrumentation.record(uri, node.parameters.offset, 'returnType',
            new InstrumentationValueForType(type.returnType, elementNamer));
        List<FormalParameter> parameters = node.parameters.parameters;
        for (int i = 0; i < parameters.length; i++) {
          FormalParameter parameter = parameters[i];
          NormalFormalParameter normalParameter =
              parameter is DefaultFormalParameter
                  ? parameter.parameter
                  : parameter;
          if (normalParameter is SimpleFormalParameter &&
              normalParameter.type == null) {
            _recordType(parameter.offset, type.parameters[i].type);
          }
        }
      }
    }
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    super.visitFunctionExpressionInvocation(node);
    var receiverType = node.function.staticType;
    if (receiverType is InterfaceType) {
      // This is a hack since analyzer doesn't record .call targets
      var target = receiverType.element.lookUpMethod('call', null) ??
          receiverType.element.lookUpGetter('call', null);
      if (target != null) {
        _recordTarget(node.argumentList.offset, target);
      }
    }
    if (node.typeArguments == null) {
      var inferredTypeArguments = _getInferredFunctionTypeArguments(
              node.function.staticType,
              node.staticInvokeType,
              node.typeArguments)
          .toList();
      if (inferredTypeArguments.isNotEmpty) {
        _recordTypeArguments(node.argumentList.offset, inferredTypeArguments);
      }
    }
  }

  visitIndexExpression(IndexExpression node) {
    super.visitIndexExpression(node);
    _recordTarget(node.leftBracket.charOffset, node.staticElement);
  }

  visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
    DartType type = node.staticType;
    if (type is InterfaceType) {
      if (type.typeParameters.isNotEmpty &&
          node.constructorName.type.typeArguments == null) {
        _recordTypeArguments(node.constructorName.offset, type.typeArguments);
      }
    }
  }

  visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.typeArguments == null) {
      DartType type = node.staticType;
      if (type is InterfaceType) {
        _recordTypeArguments(node.offset, type.typeArguments);
      }
    }
  }

  visitMapLiteral(MapLiteral node) {
    super.visitMapLiteral(node);
    if (node.typeArguments == null) {
      DartType type = node.staticType;
      if (type is InterfaceType) {
        _recordTypeArguments(node.offset, type.typeArguments);
      }
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    if (node.returnType == null) {
      _recordTopType(node.name.offset, node.element.returnType);
    }
    if (node.element.enclosingElement is ClassElement && !node.isStatic) {
      if (node.parameters != null) {
        for (var parameter in node.parameters.parameters) {
          // Note: it's tempting to check `parameter.type == null`, but that
          // doesn't work because of function-typed formal parameter syntax.
          if (parameter.element.hasImplicitType) {
            _recordTopType(parameter.identifier.offset, parameter.element.type);
          }
        }
      }
    }
  }

  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    if (node.typeArguments == null) {
      var inferredTypeArguments = _getInferredFunctionTypeArguments(
              node.function.staticType,
              node.staticInvokeType,
              node.typeArguments)
          .toList();
      if (inferredTypeArguments.isNotEmpty) {
        _recordTypeArguments(node.methodName.offset, inferredTypeArguments);
      }
    }
    var methodElement = node.methodName.staticElement;
    if (node.target is SuperExpression &&
        methodElement is PropertyAccessorElement) {
      // This is a hack since analyzer doesn't record .call targets
      var getterClass = methodElement.returnType.element;
      if (getterClass is ClassElement) {
        var target = getterClass.lookUpMethod('call', null) ??
            getterClass.lookUpGetter('call', null);
        if (target != null) {
          _recordTarget(node.argumentList.offset, target);
        }
      }
    }
  }

  visitPrefixExpression(PrefixExpression node) {
    super.visitPrefixExpression(node);
    if (node.operator.type != TokenType.PLUS_PLUS &&
        node.operator.type != TokenType.MINUS_MINUS) {
      _recordTarget(node.operator.charOffset, node.staticElement);
    }
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    Element element = node.staticElement;
    if (_elementRequiresMethodDispatch(element) &&
        !node.inDeclarationContext() &&
        (node.inGetterContext() || node.inSetterContext())) {
      _recordTarget(node.offset, element);
    }
    void recordPromotions(DartType elementType) {
      if (node.inGetterContext() && !node.inDeclarationContext()) {
        int offset = node.offset;
        DartType type = node.staticType;
        if (!identical(type, elementType)) {
          _instrumentation.record(uri, offset, 'promotedType',
              new InstrumentationValueForType(type, elementNamer));
        }
      }
    }

    if (element is LocalVariableElement) {
      recordPromotions(element.type);
    } else if (element is ParameterElement) {
      recordPromotions(element.type);
    }
  }

  visitVariableDeclarationList(VariableDeclarationList node) {
    super.visitVariableDeclarationList(node);
    if (node.type == null) {
      for (VariableDeclaration variable in node.variables) {
        VariableElement element = variable.element;
        if (element is LocalVariableElement) {
          _recordType(variable.name.offset, element.type);
        } else if (!element.isStatic || element.initializer != null) {
          _recordTopType(variable.name.offset, element.type);
        }
      }
    }
  }

  bool _elementRequiresMethodDispatch(Element element) {
    if (element is ConstructorElement) {
      return false;
    } else if (element is ClassMemberElement) {
      return !element.isStatic;
    } else if (element is ExecutableElement &&
        element.enclosingElement is ClassElement) {
      return !element.isStatic;
    } else {
      return false;
    }
  }

  /// Based on DDC code generator's `_emitFunctionTypeArguments`
  Iterable<DartType> _getInferredFunctionTypeArguments(
      DartType g, DartType f, TypeArgumentList typeArgs) {
    if (g is FunctionType &&
        g.typeFormals.isNotEmpty &&
        f is FunctionType &&
        f.typeFormals.isEmpty) {
      return _recoverTypeArguments(g, f);
    } else {
      return const [];
    }
  }

  void _recordTarget(int offset, Element element) {
    if (element is ExecutableElement) {
      _instrumentation.record(uri, offset, 'target',
          new InstrumentationValueForExecutableElement(element, elementNamer));
    }
  }

  void _recordTopType(int offset, DartType type) {
    _instrumentation.record(uri, offset, 'topType',
        new InstrumentationValueForType(type, elementNamer));
  }

  void _recordType(int offset, DartType type) {
    _instrumentation.record(uri, offset, 'type',
        new InstrumentationValueForType(type, elementNamer));
  }

  void _recordTypeArguments(int offset, List<DartType> typeArguments) {
    _instrumentation.record(uri, offset, 'typeArgs',
        new InstrumentationValueForTypeArgs(typeArguments, elementNamer));
  }

  /// Based on DDC code generator's `_recoverTypeArguments`
  Iterable<DartType> _recoverTypeArguments(FunctionType g, FunctionType f) {
    assert(identical(g.element, f.element));
    assert(g.typeFormals.isNotEmpty && f.typeFormals.isEmpty);
    assert(g.typeFormals.length + g.typeArguments.length ==
        f.typeArguments.length);
    return f.typeArguments.skip(g.typeArguments.length);
  }
}
