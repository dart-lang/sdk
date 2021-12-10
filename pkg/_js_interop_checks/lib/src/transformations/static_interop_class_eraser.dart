// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/src/replacement_visitor.dart';
import 'package:_js_interop_checks/src/js_interop.dart';

class _TypeSubstitutor extends ReplacementVisitor {
  final Class _javaScriptObject;
  _TypeSubstitutor(this._javaScriptObject);

  @override
  DartType? visitInterfaceType(InterfaceType type, int variance) {
    if (hasStaticInteropAnnotation(type.classNode)) {
      return InterfaceType(_javaScriptObject, type.declaredNullability);
    }
    return super.visitInterfaceType(type, variance);
  }
}

/// Erases usage of `@JS` classes that are annotated with `@staticInterop` in
/// favor of `JavaScriptObject`.
class StaticInteropClassEraser extends Transformer {
  final Class _javaScriptObject;
  final CloneVisitorNotMembers _cloner = CloneVisitorNotMembers();
  late final _TypeSubstitutor _typeSubstitutor;

  StaticInteropClassEraser(CoreTypes coreTypes)
      : _javaScriptObject =
            coreTypes.index.getClass('dart:_interceptors', 'JavaScriptObject') {
    _typeSubstitutor = _TypeSubstitutor(_javaScriptObject);
  }

  String _factoryStubName(Procedure factoryTarget) =>
      '${factoryTarget.name}|staticInteropFactoryStub';

  /// Either finds or creates a static method stub to replace factories with a
  /// body in a static interop class.
  ///
  /// Modifies [factoryTarget]'s enclosing class to include the new method.
  Procedure _findOrCreateFactoryStub(Procedure factoryTarget) {
    assert(factoryTarget.isFactory);
    var factoryClass = factoryTarget.enclosingClass!;
    assert(hasStaticInteropAnnotation(factoryClass));
    var stubName = _factoryStubName(factoryTarget);
    var stubs = factoryClass.procedures
        .where((procedure) => procedure.name.text == stubName);
    if (stubs.isEmpty) {
      // Note that the return type of the cloned function is transformed.
      var functionNode =
          super.visitFunctionNode(_cloner.clone(factoryTarget.function))
              as FunctionNode;
      var staticMethod = Procedure(
          Name(stubName), ProcedureKind.Method, functionNode,
          isStatic: true, fileUri: factoryTarget.fileUri)
        ..parent = factoryClass;
      factoryClass.procedures.add(staticMethod);
      return staticMethod;
    } else {
      assert(stubs.length == 1);
      return stubs.first;
    }
  }

  @override
  TreeNode visitConstructor(Constructor node) {
    if (hasStaticInteropAnnotation(node.enclosingClass)) {
      // Transform children of the constructor node excluding the return type.
      var returnType = node.function.returnType;
      var newConstructor = super.visitConstructor(node) as Constructor;
      newConstructor.function.returnType = returnType;
      return newConstructor;
    }
    return super.visitConstructor(node);
  }

  @override
  TreeNode visitProcedure(Procedure node) {
    // Avoid changing the return types of factories, but rather cast the type of
    // the invocation.
    if (node.isFactory && hasStaticInteropAnnotation(node.enclosingClass!)) {
      if (node.function.body != null && !node.isRedirectingFactory) {
        // Bodies of factories may undergo transformation, which may result in
        // type invariants breaking. For a motivating example, consider:
        //
        // ```
        // factory Foo.fact() => Foo.cons();
        // ```
        //
        // The invocation of `cons` would have its type erased, but then it
        // would no longer match the return type of `fact`, whose return type
        // shouldn't get erased as it is a factory. Note that this is only an
        // issue when the factory has a body that doesn't simply redirect.
        //
        // In order to circumvent this, we introduce a new static method that
        // clones the factory body and has a return type of
        // `JavaScriptObject`. Invocations of the factory are turned into
        // invocations of the static method. The original factory is still kept
        // in order to make modular compilations work.
        _findOrCreateFactoryStub(node);
        return node;
      } else {
        // Transform children of the factory node excluding the return type and
        // return type of the signature type.
        var returnType = node.function.returnType;
        var signatureReturnType = node.signatureType?.returnType;
        var newProcedure = super.visitProcedure(node) as Procedure;
        newProcedure.function.returnType = returnType;
        var signatureType = newProcedure.signatureType;
        if (signatureType != null && signatureReturnType != null) {
          newProcedure.signatureType = FunctionType(
              signatureType.positionalParameters,
              signatureReturnType,
              signatureType.declaredNullability,
              namedParameters: signatureType.namedParameters,
              typeParameters: signatureType.typeParameters,
              requiredParameterCount: signatureType.requiredParameterCount,
              typedefType: signatureType.typedefType);
        }
        return newProcedure;
      }
    }
    return super.visitProcedure(node);
  }

  @override
  TreeNode visitConstructorInvocation(ConstructorInvocation node) {
    if (hasStaticInteropAnnotation(node.target.enclosingClass)) {
      // Add a cast so that the result gets typed as `JavaScriptObject`.
      var newInvocation = super.visitConstructorInvocation(node) as Expression;
      return AsExpression(
          newInvocation,
          InterfaceType(_javaScriptObject,
              node.target.function.returnType.declaredNullability))
        ..fileOffset = newInvocation.fileOffset;
    }
    return super.visitConstructorInvocation(node);
  }

  /// Transform static invocations that correspond only to factories of static
  /// interop classes.
  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    var targetClass = node.target.enclosingClass;
    if (node.target.isFactory &&
        targetClass != null &&
        hasStaticInteropAnnotation(targetClass)) {
      var factoryTarget = node.target;
      if (factoryTarget.function.body != null &&
          !factoryTarget.isRedirectingFactory) {
        // Use or create the static method that replaces this factory instead.
        // Note that the static method will not have been created yet in the
        // case where we visit the factory later. Also note that a cast is not
        // needed since the static method already has its type erased.
        var args = super.visitArguments(node.arguments) as Arguments;
        return StaticInvocation(_findOrCreateFactoryStub(factoryTarget), args,
            isConst: node.isConst)
          ..fileOffset = node.fileOffset;
      } else {
        // Add a cast so that the result gets typed as `JavaScriptObject`.
        var newInvocation = super.visitStaticInvocation(node) as Expression;
        return AsExpression(
            newInvocation,
            InterfaceType(_javaScriptObject,
                node.target.function.returnType.declaredNullability))
          ..fileOffset = newInvocation.fileOffset;
      }
    }
    return super.visitStaticInvocation(node);
  }

  @override
  DartType visitDartType(DartType type) {
    // Variance is not a factor in our type transformation here, so just choose
    // `unrelated` as a default.
    var substitutedType = type.accept1(_typeSubstitutor, Variance.unrelated);
    return substitutedType != null ? substitutedType : type;
  }
}
