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
        _annotateCallKind(
            staticElement,
            target is ThisExpression,
            isDynamicInvoke(leftHandSide.identifier),
            target.staticType,
            null,
            leftHandSide.identifier.offset);
      }
    }
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    super.visitClassDeclaration(node);
    _emitForwardingStubs(node, node.typeParameters, node.name.offset);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    super.visitClassTypeAlias(node);
    _emitForwardingStubs(node, node.typeParameters, node.name.offset);
  }

  @override
  visitFormalParameter(FormalParameter node) {
    super.visitFormalParameter(node);
    if (node is DefaultFormalParameter) {
      // Already handled via the contained parameter ast object
      return;
    }
    if (node.element.enclosingElement.enclosingElement is ClassElement) {
      _annotateFormalParameter(node.element, node.identifier.offset,
          node.getAncestor((n) => n is ClassDeclaration));
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    _annotateContravariant(node.element, node.name.offset, node.parent);
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
      _annotateCheckGetterReturn(
          getImplicitOperationCast(node), node.argumentList.offset);
      _annotateCallKind(null, isThis, isDynamicInvoke(node.methodName), null,
          null, node.argumentList.offset);
    } else {
      _annotateCheckReturn(getImplicitCast(node), node.argumentList.offset);
      _annotateCallKind(
          staticElement,
          isThis,
          isDynamicInvoke(node.methodName),
          target?.staticType,
          node.methodName.staticType,
          node.argumentList.offset);
    }
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    super.visitPrefixedIdentifier(node);
    _handlePropertyAccess(node, node.prefix, node.identifier);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    super.visitPropertyAccess(node);
    _handlePropertyAccess(node, node.target, node.propertyName);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    var staticElement = node.staticElement;
    var parent = node.parent;
    if (parent is! MethodInvocation &&
        parent is! PrefixedIdentifier &&
        parent is! PropertyAccess &&
        !node.inDeclarationContext() &&
        node.inGetterContext() &&
        staticElement is PropertyAccessorElement &&
        staticElement.isGetter) {
      _annotateCallKind(staticElement, true, false, null, null, node.offset);
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
      var cls = node.getAncestor((n) => n is ClassDeclaration);
      var offset = node.name.offset;
      _annotateContravariant(element, offset, cls);
      if (!element.isFinal) {
        var setter = element.setter;
        _annotateFormalParameter(setter.parameters[0], offset, cls);
      }
    }
  }

  /// Generates the appropriate `@callKind` annotation (if any) for a call site.
  ///
  /// An annotation of `@callKind=dynamic` indicates that the call is dynamic
  /// (so it will have to be fully type checked).  An annotation of
  /// `@callKind=closure` indicates that the receiver of the call is a function
  /// object (so any formals marked as "semiSafe" will have to be type checked).
  /// An annotation of `@callKind=this` indicates that the call goes through
  /// `super` or `this` (so formals marked as "semiSafe" don't need to be type
  /// checked).  No annotation indicates that either the call is static, in
  /// which case no parameters need to be type checked, or it goes through an
  /// interface, in which case the set of arguments that have to be type checked
  /// depends on the `@checkInterface` annotations on the static target of the
  /// call.
  void _annotateCallKind(Element staticElement, bool isThis, bool isDynamic,
      DartType targetType, DartType methodType, int offset) {
    if (staticElement is FunctionElement &&
        staticElement.enclosingElement is CompilationUnitElement) {
      // Invocation of a top level function; no annotation needed.
      return;
    }
    if (isDynamic) {
      if (targetType == null &&
          staticElement != null &&
          staticElement is! MethodElement &&
          methodType is FunctionType) {
        // Sometimes analyzer annotates invocations of function objects as
        // dynamic (presumably due to "dynamic is bottom" behavior).  Ignore
        // this.
        _recordCallKind(offset, 'closure');
      } else {
        _recordCallKind(offset, 'dynamic');
        return;
      }
    }
    if (staticElement is MethodElement && !staticElement.isStatic ||
        staticElement is PropertyAccessorElement && !staticElement.isStatic) {
      if (isThis) {
        _recordCallKind(offset, 'this');
        return;
      } else {
        // Interface call; no annotation needed
        return;
      }
    }
    _recordCallKind(offset, 'closure');
  }

  /// Generates the appropriate `@checkGetterReturn` annotation (if any) for a
  /// call site.
  ///
  /// An annotation of `@checkGetterReturn=type` indicates that a method call
  /// desugars to a getter invocation followed by a function invocation; the
  /// value returned by the getter will have to be checked to make sure it is an
  /// instance of the given type.
  void _annotateCheckGetterReturn(DartType castType, int offset) {
    if (castType != null) {
      _recordCheckGetterReturn(offset, castType);
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

  /// Generates the appropriate `@genericContravariant=true` annotation (if needed)
  /// for a method or field declaration.
  void _annotateContravariant(
      Element element, int offset, ClassDeclaration cls) {
    bool isContravariant = false;
    if (cls?.typeParameters != null) {
      if (element is ExecutableElement) {
        if (_usesTypeParametersCovariantly(
            cls.typeParameters.typeParameters, element.returnType,
            flipVariance: true)) {
          isContravariant = true;
        }
      } else if (element is FieldElement) {
        if (_usesTypeParametersCovariantly(
            cls.typeParameters.typeParameters, element.type,
            flipVariance: true)) {
          isContravariant = true;
        }
      }
    }
    if (isContravariant) {
      _recordContravariance(offset);
    }
  }

  /// Generates the appropriate `@covariance` annotation (if any) for a method
  /// formal parameter, method type parameter, or field declaration.
  ///
  /// When these annotations are generated for a field declaration, they
  /// implicitly refer to the value parameter of the synthetic setter.
  ///
  /// An annotation of `@covariance=explicit` indicates that the parameter needs
  /// to be type checked regardless of the call site.
  ///
  /// An annotation of `@covariance=genericImpl` indicates that the parameter
  /// needs to be type checked when the call site is annotated
  /// `@callKind=dynamic` or `@callKind=closure`, or the call site is
  /// unannotated and the corresponding parameter in the interface target is
  /// annotated `@covariance=genericInterface`.
  ///
  /// No `@covariance` annotation indicates that the parameter only needs to be
  /// type checked if the call site is annotated `@callKind=dynamic`.
  void _annotateFormalParameter(
      Element element, int offset, ClassDeclaration cls) {
    bool isExplicit = false;
    bool isGenericImpl = false;
    if (element is ParameterElement && element.isCovariant) {
      isExplicit = true;
    } else if (cls != null) {
      var covariantParams = getClassCovariantParameters(cls);
      if (covariantParams != null && covariantParams.contains(element) ||
          cls?.typeParameters != null &&
              element is ParameterElement &&
              _usesTypeParametersCovariantly(
                  cls.typeParameters.typeParameters, element.type)) {
        isGenericImpl = true;
      }
    }
    bool isGenericInterface = false;
    if (cls?.typeParameters != null) {
      if (element is ParameterElement) {
        if (_usesTypeParametersCovariantly(
            cls.typeParameters.typeParameters, element.type)) {
          isGenericInterface = true;
        }
      } else if (element is TypeParameterElement && element.bound != null) {
        if (_usesTypeParametersCovariantly(
            cls.typeParameters.typeParameters, element.bound)) {
          isGenericInterface = true;
        }
      }
    }
    var covariance = <String>[];
    if (isExplicit) covariance.add('explicit');
    if (isGenericInterface) covariance.add('genericInterface');
    if (isGenericImpl) covariance.add('genericImpl');
    if (covariance.isNotEmpty) {
      _recordCovariance(offset, covariance.join(', '));
    }
  }

  /// Generates the appropriate `@forwardingStub` annotation (if any) for a
  /// class declaration or mixin application.
  ///
  /// An annotation of `@forwardingStub=rettype name(args)` indicates that a
  /// forwarding stub must be inserted into the class having the given name and
  /// return type.  Each argument is listed in `args` as
  /// `covariance=(...) type name`, where the words between the parentheses are
  /// the same as for the `@covariance=` annotation.
  void _emitForwardingStubs(
      Declaration node, TypeParameterList typeParameters, int offset) {
    var covariantParams = getSuperclassCovariantParameters(node);
    void emitStubFor(DartType returnType, String name,
        List<ParameterElement> parameters, String accessorType) {
      String closer = '';
      var previousParameterKind = ParameterKind.REQUIRED;
      var paramDescrs = <String>[];
      for (var param in parameters) {
        var covariances = <String>[];
        if (_usesTypeParametersCovariantly(
            typeParameters?.typeParameters, param.type)) {
          covariances.add('genericInterface');
        }
        if (covariantParams.contains(param)) {
          if (param.isCovariant) {
            covariances.add('explicit');
          } else {
            covariances.add('genericImpl');
          }
        }
        var covariance = 'covariance=(${covariances.join(', ')})';
        var typeDescr = _typeToString(param.type);
        var paramName = accessorType == 'set' ? '_' : param.name;
        var paramDescr = '$covariance $typeDescr $paramName';
        if (param.parameterKind != previousParameterKind) {
          String opener;
          if (param.parameterKind == ParameterKind.POSITIONAL) {
            opener = '[';
            closer = ']';
          } else {
            opener = '{';
            closer = '}';
          }
          paramDescr = opener + paramDescr;
          previousParameterKind = param.parameterKind;
        }
        paramDescrs.add(paramDescr);
      }
      if (closer.isNotEmpty) {
        paramDescrs[paramDescrs.length - 1] += closer;
      }
      var returnTypeDescr = _typeToString(returnType);
      var stubParts = <String>[];
      if (_usesTypeParametersCovariantly(
          typeParameters?.typeParameters, returnType)) {
        stubParts.add('genericContravariant');
      }
      stubParts.add(returnTypeDescr);
      if (accessorType != null) stubParts.add(accessorType);
      stubParts.add('$name(${paramDescrs.join(', ')})');
      _recordForwardingStub(offset, stubParts.join(' '));
    }

    if (covariantParams != null && covariantParams.isNotEmpty) {
      for (var member
          in covariantParams.map((p) => p.enclosingElement).toSet()) {
        var memberName = member.name;
        if (member is PropertyAccessorElement) {
          if (member.isSetter) {
            emitStubFor(
                member.returnType,
                memberName.substring(0, memberName.length - 1),
                member.parameters,
                'set');
          } else {
            emitStubFor(
                member.returnType, memberName, member.parameters, 'get');
          }
        } else if (member is MethodElement) {
          emitStubFor(member.returnType, memberName, member.parameters, null);
        } else {
          throw new StateError('Unexpected covariant member $member');
        }
      }
    }
  }

  /// Generates the appropriate annotations for a property access, whether it
  /// arises from a [PrefixedIdentifier] or a [PropertyAccess].
  void _handlePropertyAccess(
      Expression node, Expression target, SimpleIdentifier propertyName) {
    var staticElement = propertyName.staticElement;
    if (propertyName.inGetterContext()) {
      var isThis = target is ThisExpression || target == null;
      _annotateCheckReturn(getImplicitCast(node), propertyName.offset);
      _annotateCallKind(
          staticElement,
          isThis,
          target.staticType is DynamicTypeImpl,
          target.staticType,
          null,
          propertyName.offset);
    }
  }

  void _recordCallKind(int offset, String kind) {
    _instrumentation.record(
        uri, offset, 'callKind', new fasta.InstrumentationValueLiteral(kind));
  }

  void _recordCheckGetterReturn(int offset, DartType castType) {
    _instrumentation.record(uri, offset, 'checkGetterReturn',
        new InstrumentationValueForType(castType, _elementNamer));
  }

  void _recordCheckReturn(int offset, DartType castType) {
    _instrumentation.record(uri, offset, 'checkReturn',
        new InstrumentationValueForType(castType, _elementNamer));
  }

  void _recordContravariance(int offset) {
    _instrumentation.record(uri, offset, 'genericContravariant',
        new fasta.InstrumentationValueLiteral('true'));
  }

  void _recordCovariance(int offset, String covariance) {
    _instrumentation.record(uri, offset, 'covariance',
        new fasta.InstrumentationValueLiteral(covariance));
  }

  void _recordForwardingStub(int offset, String descr) {
    _instrumentation.record(uri, offset, 'forwardingStub',
        new fasta.InstrumentationValueLiteral(descr));
  }

  String _typeToString(DartType type) {
    return new InstrumentationValueForType(type, _elementNamer).toString();
  }

  /// Determines whether the given type makes covariant use of type parameters.
  bool _usesTypeParametersCovariantly(
      List<TypeParameter> typeParameters, DartType formalType,
      {bool flipVariance: false}) {
    if (typeParameters == null) return false;
    // To see if this parameter needs to be semi-typed, we try substituting
    // bottom for all the active type parameters.  If the resulting parameter
    // static type is a supertype of its current static type, then that means
    // that regardless of what we pass in, it won't fail a type check.
    var substitutedType = formalType.substitute2(
        new List<DartType>.filled(
            typeParameters.length, BottomTypeImpl.instance),
        typeParameters
            .map((p) => new TypeParameterTypeImpl(p.element))
            .toList());
    // To test contravariance, we flip the subtype check.
    if (flipVariance) {
      return !_typeSystem.isSubtypeOf(substitutedType, formalType);
    } else {
      return !_typeSystem.isSubtypeOf(formalType, substitutedType);
    }
  }
}
