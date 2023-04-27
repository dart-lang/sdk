// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:_js_interop_checks/src/js_interop.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/src/constant_replacer.dart';
import 'package:kernel/src/replacement_visitor.dart';

/// Erasure function for `dart:_js_types` `@staticInterop` types.
InterfaceType transformJSTypesForJSCompilers(
    CoreTypes coreTypes, InterfaceType staticInteropType) {
  final className = staticInteropType.classNode.name;
  Class erasedClass;
  var typeArguments = staticInteropType.typeArguments;
  switch (className) {
    case 'JSAny':
      erasedClass = coreTypes.objectClass;
      break;
    case 'JSObject':
      erasedClass = coreTypes.index.getClass('dart:_interceptors', 'JSObject');
      break;
    case 'JSFunction':
      erasedClass = coreTypes.functionClass;
      break;
    case 'JSExportedDartFunction':
      erasedClass = coreTypes.functionClass;
      break;
    case 'JSArray':
      erasedClass = coreTypes.listClass;
      typeArguments = [coreTypes.objectNullableRawType];
      break;
    case 'JSExportedDartObject':
      erasedClass = coreTypes.objectClass;
      break;
    case 'JSArrayBuffer':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'ByteBuffer');
      break;
    case 'JSDataView':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'ByteData');
      break;
    case 'JSTypedArray':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'TypedData');
      break;
    case 'JSInt8Array':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'Int8List');
      break;
    case 'JSUint8Array':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'Uint8List');
      break;
    case 'JSUint8ClampedArray':
      erasedClass =
          coreTypes.index.getClass('dart:typed_data', 'Uint8ClampedList');
      break;
    case 'JSInt16Array':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'Int16List');
      break;
    case 'JSUint16Array':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'Uint16List');
      break;
    case 'JSInt32Array':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'Int32List');
      break;
    case 'JSUint32Array':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'Uint32List');
      break;
    case 'JSFloat32Array':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'Float32List');
      break;
    case 'JSFloat64Array':
      erasedClass = coreTypes.index.getClass('dart:typed_data', 'Float64List');
      break;
    case 'JSNumber':
      erasedClass = coreTypes.doubleClass;
      break;
    case 'JSBoolean':
      erasedClass = coreTypes.boolClass;
      break;
    case 'JSString':
      erasedClass = coreTypes.stringClass;
      break;
    case 'JSPromise':
      erasedClass = coreTypes.index.getClass('dart:_interceptors', 'JSObject');
      break;
    default:
      throw 'Unimplemented `dart:_js_types`: $className';
  }
  return InterfaceType(
      erasedClass, staticInteropType.declaredNullability, typeArguments);
}

class _TypeSubstitutor extends ReplacementVisitor {
  final InterfaceType Function(InterfaceType staticInteropType)
      _eraseStaticInteropType;
  _TypeSubstitutor(this._eraseStaticInteropType);

  @override
  DartType? visitInterfaceType(InterfaceType type, int variance) {
    if (hasStaticInteropAnnotation(type.classNode)) {
      return _eraseStaticInteropType(type);
    }
    return super.visitInterfaceType(type, variance);
  }
}

/// Erases usage of `@JS` classes that are annotated with `@staticInterop` in
/// favor of `JavaScriptObject`.
class StaticInteropClassEraser extends Transformer {
  final CloneVisitorNotMembers _cloner = CloneVisitorNotMembers();
  late final _StaticInteropConstantReplacer _constantReplacer;
  late final _TypeSubstitutor _typeSubstitutor;
  Component? currentComponent;
  ReferenceFromIndex? referenceFromIndex;
  // Custom erasure function for `@staticInterop` types. This is useful for when
  // they should be erased to another type besides `JavaScriptObject`, like in
  // dart2wasm.
  late final InterfaceType Function(InterfaceType staticInteropType)
      _eraseStaticInteropType;
  // Visiting core libraries that don't contain `@staticInterop` adds overhead.
  // To avoid this, we use an allowlist that contains libraries that we know use
  // `@staticInterop`.
  late final Set<String> _erasableCoreLibraries = {
    'js_interop_unsafe',
    'ui',
    '_engine',
    '_skwasm_impl'
  };

  StaticInteropClassEraser(CoreTypes coreTypes, this.referenceFromIndex,
      {InterfaceType Function(InterfaceType staticInteropType)?
          eraseStaticInteropType,
      Set<String> additionalCoreLibraries = const {}}) {
    final dartJsTypes = Uri.parse('dart:_js_types');
    _eraseStaticInteropType = eraseStaticInteropType ??
        (staticInteropType) {
          if (staticInteropType.classNode.enclosingLibrary.importUri ==
              dartJsTypes) {
            return transformJSTypesForJSCompilers(coreTypes, staticInteropType);
          }
          return InterfaceType(
              coreTypes.index
                  .getClass('dart:_interceptors', 'JavaScriptObject'),
              staticInteropType.declaredNullability);
        };
    _typeSubstitutor = _TypeSubstitutor(_eraseStaticInteropType);
    _constantReplacer = _StaticInteropConstantReplacer(this);
    _erasableCoreLibraries.addAll(additionalCoreLibraries);
  }

  String _factoryStubName(Procedure factoryTarget) =>
      '${factoryTarget.name}|staticInteropFactoryStub';

  /// Either finds or creates a static method stub to replace factories with a
  /// body with in a static interop class.
  ///
  /// Modifies [factoryTarget]'s enclosing class to include the new method if we
  /// create one.
  Procedure _findOrCreateFactoryStub(Procedure factoryTarget) {
    assert(factoryTarget.isFactory);
    var factoryClass = factoryTarget.enclosingClass!;
    assert(hasStaticInteropAnnotation(factoryClass));
    var stubName = _factoryStubName(factoryTarget);
    var stubs = factoryClass.procedures
        .where((procedure) => procedure.name.text == stubName);
    if (stubs.isEmpty) {
      // We should only create the stub if we're processing the component in
      // which the stub should exist.
      if (currentComponent != null) {
        assert(factoryTarget.enclosingComponent == currentComponent);
      }
      Name name = Name(stubName);
      var staticMethod = Procedure(
          name, ProcedureKind.Method, FunctionNode(null),
          isStatic: true,
          fileUri: factoryTarget.fileUri,
          reference: referenceFromIndex
              ?.lookupLibrary(factoryClass.enclosingLibrary)
              ?.lookupIndexedClass(factoryClass.name)
              ?.lookupGetterReference(name))
        ..fileOffset = factoryTarget.fileOffset;
      factoryClass.addProcedure(staticMethod);
      // Clone function node after processing the stub in case of mutually
      // recursive factories. Note that the return type of the cloned function
      // is transformed.
      var functionNode = super
              .visitFunctionNode(_cloner.cloneInContext(factoryTarget.function))
          as FunctionNode;
      staticMethod.function = functionNode;
      return staticMethod;
    } else {
      assert(stubs.length == 1);
      return stubs.first;
    }
  }

  @override
  TreeNode visitLibrary(Library node) {
    if (node.importUri.isScheme('dart') &&
        !_erasableCoreLibraries.contains(node.importUri.path)) {
      return node;
    }
    currentComponent = node.enclosingComponent;
    return super.visitLibrary(node);
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
              requiredParameterCount: signatureType.requiredParameterCount);
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
          _eraseStaticInteropType(
              node.target.function.returnType as InterfaceType))
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
        var stub = _findOrCreateFactoryStub(factoryTarget);
        return StaticInvocation(stub, args, isConst: node.isConst)
          ..fileOffset = node.fileOffset;
      } else {
        // Add a cast so that the result gets typed as `JavaScriptObject`.
        var newInvocation = super.visitStaticInvocation(node) as Expression;
        return AsExpression(
            newInvocation, node.target.function.returnType as InterfaceType)
          ..fileOffset = newInvocation.fileOffset;
      }
    }
    return super.visitStaticInvocation(node);
  }

  DartType? _getSubstitutedType(DartType type) {
    // Variance is not a factor in our type transformation here, so just choose
    // `unrelated` as a default.
    return type.accept1(_typeSubstitutor, Variance.unrelated);
  }

  @override
  DartType visitDartType(DartType node) {
    var substitutedType = _getSubstitutedType(node);
    return substitutedType ?? node;
  }

  @override
  Constant visitConstant(Constant node) {
    return _constantReplacer.visitConstant(node) ?? node;
  }

  @override
  Supertype visitSupertype(Supertype node) {
    for (int i = 0; i < node.typeArguments.length; i++) {
      node.typeArguments[i] = visitDartType(node.typeArguments[i]);
    }
    return node;
  }
}

class _StaticInteropConstantReplacer extends ConstantReplacer {
  final StaticInteropClassEraser _eraser;
  _StaticInteropConstantReplacer(this._eraser);

  @override
  DartType? visitDartType(DartType type) => _eraser._getSubstitutedType(type);

  @override
  TreeNode visitTreeNode(TreeNode node) => node.accept(_eraser);
}
