// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/task/strong/ast_properties.dart';
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
  group('front_end_runtime_check_test', () {
    defineReflectiveSuite(() {
      defineReflectiveTests(RunFrontEndRuntimeCheckTest);
    });
  }, timeout: new Timeout(const Duration(seconds: 120)));
}

@reflectiveTest
class RunFrontEndRuntimeCheckTest extends RunFrontEndTest {
  @override
  get testSubdir => 'runtime_checks';

  @override
  void visitUnit(TypeProvider typeProvider, CompilationUnit unit,
      fasta.ValidatingInstrumentation validation, Uri uri) {
    unit.accept(new _InstrumentationVisitor(
        new StrongTypeSystemImpl(typeProvider), validation, uri));
  }
}

/// Visitor for ASTs that reports instrumentation for strong mode runtime
/// checks.
///
/// Note: this visitor doesn't attempt to report all runtime checks inserted by
/// analyzer; just the ones necessary to validate the front end tests.  This
/// visitor might need to be updated as more front end tests are added.
class _InstrumentationVisitor extends GeneralizingAstVisitor<Null> {
  final fasta.Instrumentation _instrumentation;
  final Uri uri;
  final StrongTypeSystemImpl _typeSystem;
  final _elementNamer = new ElementNamer(null);

  _InstrumentationVisitor(this._typeSystem, this._instrumentation, this.uri);

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    super.visitAssignmentExpression(node);
    var leftHandSide = node.leftHandSide;
    if (leftHandSide is PrefixedIdentifier) {
      var staticElement = leftHandSide.identifier.staticElement;
      if (staticElement is PropertyAccessorElement && staticElement.isSetter) {
        var target = leftHandSide.prefix;
        _annotateCheckCall(
            staticElement,
            target is ThisExpression,
            isDynamicInvoke(leftHandSide.identifier),
            target.staticType,
            [],
            [node.rightHandSide],
            leftHandSide.identifier.offset);
      }
    }
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    super.visitClassDeclaration(node);
    _emitForwardingStubs(node, node.name.offset);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    super.visitClassTypeAlias(node);
    _emitForwardingStubs(node, node.name.offset);
  }

  @override
  visitFormalParameter(FormalParameter node) {
    super.visitFormalParameter(node);
    if (node is DefaultFormalParameter) {
      // Already handled via the contained parameter ast object
      return;
    }
    _annotateFormalParameter(node.element, node.identifier.offset,
        node.getAncestor((n) => n is ClassDeclaration));
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    var staticElement = node.methodName.staticElement;
    var target = node.target;
    var isThis = target is ThisExpression || target == null;
    if (staticElement is PropertyAccessorElement) {
      // Method invocation resolves to a getter; treat it as a get followed by a
      // function invocation.
      _annotateCheckReturn(
          getImplicitOperationCast(node), node.methodName.offset);
      _annotateCheckCall(
          null,
          isThis,
          isDynamicInvoke(node.methodName),
          null,
          node.typeArguments?.arguments,
          node.argumentList.arguments,
          node.argumentList.offset);
    } else {
      _annotateCheckReturn(getImplicitCast(node), node.argumentList.offset);
      _annotateCheckCall(
          staticElement,
          isThis,
          isDynamicInvoke(node.methodName),
          target?.staticType,
          node.typeArguments?.arguments,
          node.argumentList.arguments,
          node.argumentList.offset);
    }
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    super.visitPrefixedIdentifier(node);
    if (node.identifier.staticElement is MethodElement) {
      _annotateTearOff(node, node.identifier.offset);
    }
  }

  @override
  visitTypeParameter(TypeParameter node) {
    super.visitTypeParameter(node);
    if (node.parent.parent is MethodDeclaration) {
      _annotateFormalParameter(node.element, node.name.offset,
          node.getAncestor((n) => n is ClassDeclaration));
    }
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    if (node.parent.parent is FieldDeclaration) {
      FieldElement element = node.element;
      if (!element.isFinal) {
        var setter = element.setter;
        _annotateFormalParameter(setter.parameters[0], node.name.offset,
            node.getAncestor((n) => n is ClassDeclaration));
      }
    }
  }

  /// Generates the appropriate `@checkCall` annotation (if any) for a call
  /// site.
  ///
  /// An annotation of `@checkCall=dynamic` indicates that the call is dynamic
  /// (so it will have to be fully type checked).  An annotation of
  /// "@checkCall=interface(args)" indicates that the call statically resolves
  /// to a member of an interface, but some of the arguments are "semi-typed" so
  /// they may have to be type checked.  `args` lists the positional indices of
  /// the semi-typed arguments (counting from 0).  If any type parameters need
  /// to be checked, they are also listed by index, enclosed in `<>`.  For
  /// example, `@checkCall=interface(<0>,1)` means that type parameter 0 and
  /// regular parameter 1 are semi-typed.
  ///
  /// [staticElement] is the element being invoked, or `null` if there is no
  /// static element (either because this is a dynamic invocation or because the
  /// thing being invoked is function-typed).
  ///
  /// [isThis] indicates whether the receiver of the invocation is `this`.
  ///
  /// [isDynamic] indicates whether analyzer has classified this invocation as a
  /// dynamic invocation.
  ///
  /// [targetType] is the type of the target of the invocation, or `null` if
  /// there is no target (e.g. because of implicit `this` or because the thing
  /// being invoked is function-typed).
  ///
  /// [typeArguments] and [arguments] are the type arguments and regular
  /// arguments of the invocation, respectively.
  ///
  /// [offset] is the location of the invocation in source code.
  void _annotateCheckCall(
      Element staticElement,
      bool isThis,
      bool isDynamic,
      DartType targetType,
      List<TypeAnnotation> typeArguments,
      List<Expression> arguments,
      int offset) {
    if (staticElement is FunctionElement &&
        staticElement.enclosingElement is CompilationUnitElement) {
      // Invocation of a top level function; no annotation needed.
      return;
    }
    if (isDynamic) {
      if (targetType == null &&
          staticElement != null &&
          staticElement is! MethodElement) {
        // Sometimes analyzer annotates invocations of function objects as
        // dynamic (presumably due to "dynamic is bottom" behavior).  Ignore
        // this.
      } else {
        _recordCheckCall(offset, 'dynamic');
        return;
      }
    }
    if (staticElement is MethodElement && isThis) {
      // Calls through "this" are always typed because the type parameters match
      // up perfectly; no annotation needed.
      return;
    }
    var semiTypedArgs = <String>[];
    if (typeArguments != null) {
      for (int argPosition = 0;
          argPosition < typeArguments.length;
          argPosition++) {
        DartType getArgument(FunctionType functionType) {
          return functionType.typeFormals[argPosition].bound;
        }

        if (_isArgumentSemiTyped(targetType, staticElement, getArgument)) {
          semiTypedArgs.add('<$argPosition>');
        }
      }
    }
    int argPosition = 0;
    for (var argument in arguments) {
      assert(argument is! NamedExpression); // TODO(paulberry): handle this
      DartType getArgument(FunctionType functionType) {
        // TODO(paulberry): handle named parameters
        if (argPosition >= functionType.normalParameterTypes.length) {
          return functionType.optionalParameterTypes[
              argPosition - functionType.normalParameterTypes.length];
        } else {
          return functionType.normalParameterTypes[argPosition];
        }
      }

      if (_isArgumentSemiTyped(targetType, staticElement, getArgument)) {
        semiTypedArgs.add('$argPosition');
      }
      ++argPosition;
    }
    if (semiTypedArgs.isEmpty) {
      // We don't annotate invocations where all arguments are typed because
      // that's the common case.
    } else {
      _recordCheckCall(
          offset, 'interface(semiTyped:${semiTypedArgs.join(',')})');
    }
  }

  /// Generates the appropriate `@checkReturn` annotation (if any) for a call
  /// site.
  ///
  /// An annotation of `@checkReturn=type` indicates that the value returned by
  /// the call will have to be checked to make sure it is an instance of the
  /// given type.
  void _annotateCheckReturn(DartType castType, int offset) {
    if (castType != null) {
      _recordCheckReturn(offset, castType);
    }
  }

  /// Generates the appropriate `@checkFormal` annotation (if any) for a method
  /// formal parameter, method type parameter, or field declaration.
  ///
  /// When this annotation is generated for a field declaration, it implicitly
  /// refers to the value parameter of the synthetic setter.
  ///
  /// An annotation of `@checkFormal=unsafe` indicates that the parameter needs
  /// to be type checked regardless of the call site.
  ///
  /// An annotation of `@checkFormal=semiSafe` indicates that the parameter
  /// needs to be type checked when corresponding argument at the call site is
  /// considered "semi-typed".
  ///
  /// No annotation indicates that the parameter only needs to be type checked
  /// if the call site is a dynamic invocation.
  void _annotateFormalParameter(
      Element element, int offset, ClassDeclaration cls) {
    if (element is ParameterElement && element.isCovariant) {
      _recordCheckFormal(offset, 'unsafe');
    } else if (cls != null) {
      var covariantParams = getClassCovariantParameters(cls);
      if (covariantParams != null && covariantParams.contains(element)) {
        _recordCheckFormal(offset, 'semiSafe');
      }
    }
  }

  /// Generates the appropriate `@checkTearOff` annotation (if any) for a call
  /// site.
  ///
  /// An annotation of `@checkTearOff=type` indicates that the torn off function
  /// will have to be checked to make sure it is an instance of the given type.
  void _annotateTearOff(Expression node, int offset) {
    // TODO(paulberry): handle dynamic tear offs
    // Note: we don't annotate that non-dynamic tear offs use "interface"
    // dispatch because that's the common case.
    var castType = getImplicitCast(node);
    if (castType != null) {
      _recordCheckTearOff(offset, castType);
    }
  }

  /// Generates the appropriate `@forwardingStub` annotation (if any) for a
  /// class declaration or mixin application.
  ///
  /// An annotation of `@forwardingStub=rettype name(args)` indicates that a
  /// forwarding stub must be inserted into the class having the given name and
  /// return type.  Each argument is listed in `args` as `safety type name`,
  /// where safety is one of `safe` or `semiSafe`.
  void _emitForwardingStubs(Declaration node, int offset) {
    var covariantParams = getSuperclassCovariantParameters(node);
    if (covariantParams != null && covariantParams.isNotEmpty) {
      for (var member
          in covariantParams.map((p) => p.enclosingElement).toSet()) {
        var memberName = member.name;
        if (member is PropertyAccessorElement) {
          throw new UnimplementedError(); // TODO(paulberry)
        } else if (member is MethodElement) {
          var paramDescrs = <String>[];
          for (var param in member.parameters) {
            // TODO(paulberry): test the safe case
            var safetyDescr =
                covariantParams.contains(param) ? 'semiSafe' : 'safe';
            var typeDescr = _typeToString(param.type);
            var paramName = param.name;
            // TODO(paulberry): if necessary, support other parameter kinds
            assert(param.parameterKind == ParameterKind.REQUIRED);
            paramDescrs.add('$safetyDescr $typeDescr $paramName');
          }
          var returnTypeDescr = _typeToString(member.returnType);
          var stub = '$returnTypeDescr $memberName(${paramDescrs.join(', ')})';
          _recordForwardingStub(offset, stub);
        } else {
          throw new StateError('Unexpected covariant member $member');
        }
      }
    }
  }

  /// Determines whether an argument at a call site should be considered
  /// "semi-typed".
  ///
  /// [targetType] indicates the type of the interface being invoked.
  ///
  /// [invocationTarget] is the method or getter/setter being invoked.
  ///
  /// [getArgument] is a callback for accessing the corresponding argument type
  /// from a [FunctionType].
  bool _isArgumentSemiTyped(InterfaceType targetType, Element invocationTarget,
      DartType getArgument(FunctionType functionType)) {
    bool _checkTypes(DartType originalArgumentType,
        DartType lookupArgumentType(InterfaceType interfaceType)) {
      // If the target type lacks type parameters, then everything is safe.
      if (targetType.typeParameters.isEmpty) return false;

      // To see if this argument needs to be semi-typed, we try substituting
      // bottom in for all the active type parameters.  If the resulting
      // argument static type is a supertype of its current static type, then
      // that means that regardless of what we pass in, it won't fail a type
      // check.
      var substitutedInterfaceType = targetType.element.type.instantiate(
          new List<DartType>.filled(
              targetType.typeParameters.length, BottomTypeImpl.instance));
      var substitutedArgumentType =
          lookupArgumentType(substitutedInterfaceType);
      return !_typeSystem.isSubtypeOf(
          originalArgumentType, substitutedArgumentType);
    }

    if (invocationTarget is LocalVariableElement || invocationTarget == null) {
      // This is an invocation of a closure, so every argument is semi-typed.
      return true;
    } else if (invocationTarget is PropertyAccessorElement &&
        invocationTarget.isSetter) {
      return _checkTypes(
          invocationTarget.parameters[0].type,
          (InterfaceType type) => type
              .lookUpSetter(invocationTarget.name, invocationTarget.library)
              .parameters[0]
              .type);
    } else if (invocationTarget is MethodElement) {
      return _checkTypes(
          getArgument(invocationTarget.type),
          (InterfaceType type) => getArgument(type
              .lookUpMethod(invocationTarget.name, invocationTarget.library)
              .type));
    } else {
      throw new UnimplementedError(
          'Unexpected invocation target type: ${invocationTarget.runtimeType}');
    }
  }

  void _recordCheckCall(int offset, String safety) {
    _instrumentation.record(uri, offset, 'checkCall',
        new fasta.InstrumentationValueLiteral(safety));
  }

  void _recordCheckFormal(int offset, String safety) {
    _instrumentation.record(uri, offset, 'checkFormal',
        new fasta.InstrumentationValueLiteral(safety));
  }

  void _recordCheckReturn(int offset, DartType castType) {
    _instrumentation.record(uri, offset, 'checkReturn',
        new InstrumentationValueForType(castType, _elementNamer));
  }

  void _recordCheckTearOff(int offset, DartType castType) {
    _instrumentation.record(uri, offset, 'checkTearOff',
        new InstrumentationValueForType(castType, _elementNamer));
  }

  void _recordForwardingStub(int offset, String descr) {
    _instrumentation.record(uri, offset, 'forwardingStub',
        new fasta.InstrumentationValueLiteral(descr));
  }

  String _typeToString(DartType type) {
    return new InstrumentationValueForType(type, _elementNamer).toString();
  }
}
