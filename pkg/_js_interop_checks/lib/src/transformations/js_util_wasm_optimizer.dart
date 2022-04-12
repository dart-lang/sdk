// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

import '../js_interop.dart' show getJSName, hasStaticInteropAnnotation;

/// Replaces:
///   1) Factory constructors in classes with `@staticInterop` annotations with
///      calls to `js_util_wasm.callConstructorVarArgs`.
///   2) External methods in `@staticInterop` class extensions to their
///      corresponding `js_util_wasm` calls.
/// TODO(joshualitt): In the long term we'd like to have the same
/// `JsUtilOptimizer` for all web backends. This is to ensure uniform semantics
/// across all web backends. Some known challenges remain, and there may be
/// unknown challenges that appear as we proceed. Known challenges include:
///   1) Some constructs may need to be restricted on Dart2wasm, for example
///      callbacks must be fully typed for the time being, though we could
///      generalize this using `Function.apply`, but this is currently not
///      implemented on Dart2wasm.
///   2) We may want to handle this lowering differently on Dart2wasm in the
///      long term. Currently, js_util on Wasm is implemented using a single
///      trampoline per js_util function. We may want to specialize these
///      trampolines based off the interop type, to avoid megamorphic behavior.
///      This would have code size implications though, so we would need to
///      proceed carefully.
class JsUtilWasmOptimizer extends Transformer {
  final Procedure _callMethodTarget;
  final Procedure _callConstructorTarget;
  final Procedure _globalThisTarget;
  final Procedure _getPropertyTarget;
  final Procedure _setPropertyTarget;
  final Procedure _jsifyTarget;
  final Procedure _dartifyTarget;
  final Class _jsValueClass;

  final CoreTypes _coreTypes;
  final StatefulStaticTypeContext _staticTypeContext;
  Map<Reference, ExtensionMemberDescriptor>? _extensionMemberIndex;
  final Set<Class> _transformedClasses = {};

  JsUtilWasmOptimizer(this._coreTypes, ClassHierarchy hierarchy)
      : _callMethodTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'callMethodVarArgs'),
        _globalThisTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'globalThis'),
        _callConstructorTarget = _coreTypes.index.getTopLevelProcedure(
            'dart:js_util_wasm', 'callConstructorVarArgs'),
        _getPropertyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'getProperty'),
        _setPropertyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'setProperty'),
        _jsifyTarget =
            _coreTypes.index.getTopLevelProcedure('dart:js_util_wasm', 'jsify'),
        _dartifyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util_wasm', 'dartify'),
        _jsValueClass =
            _coreTypes.index.getClass('dart:js_util_wasm', 'JSValue'),
        _staticTypeContext = StatefulStaticTypeContext.stacked(
            TypeEnvironment(_coreTypes, hierarchy)) {}

  @override
  Library visitLibrary(Library lib) {
    _staticTypeContext.enterLibrary(lib);
    lib.transformChildren(this);
    _staticTypeContext.leaveLibrary(lib);
    _extensionMemberIndex = null;
    _transformedClasses.clear();
    return lib;
  }

  @override
  Member defaultMember(Member node) {
    _staticTypeContext.enterMember(node);
    node.transformChildren(this);
    _staticTypeContext.leaveMember(node);
    return node;
  }

  @override
  Procedure visitProcedure(Procedure node) {
    _staticTypeContext.enterMember(node);
    ReturnStatement? transformedBody;
    if (node.isExternal) {
      if (node.isFactory) {
        Class cls = node.enclosingClass!;
        if (hasStaticInteropAnnotation(cls)) {
          String jsName = getJSName(cls);
          String constructorName = jsName == '' ? cls.name : jsName;
          transformedBody =
              _getExternalCallConstructorBody(node, constructorName);
        }
      } else if (node.isExtensionMember) {
        var index = _extensionMemberIndex ??=
            _createExtensionMembersIndex(node.enclosingLibrary);
        var nodeDescriptor = index[node.reference];
        if (nodeDescriptor != null) {
          if (!nodeDescriptor.isStatic) {
            if (nodeDescriptor.kind == ExtensionMemberKind.Getter) {
              transformedBody = _getExternalGetterBody(node);
            } else if (nodeDescriptor.kind == ExtensionMemberKind.Setter) {
              transformedBody = _getExternalSetterBody(node);
            } else if (nodeDescriptor.kind == ExtensionMemberKind.Method) {
              transformedBody = _getExternalMethodBody(node);
            }
          }
        }
      }
    }
    if (transformedBody != null) {
      node.function.body = transformedBody..parent = node.function;
      node.isExternal = false;
    } else {
      node.transformChildren(this);
    }
    _staticTypeContext.leaveMember(node);
    return node;
  }

  /// Returns and initializes `_extensionMemberIndex` to an index of the member
  /// reference to the member `ExtensionMemberDescriptor`, for all extension
  /// members in the given [library] of classes annotated with
  /// `@staticInterop`.
  Map<Reference, ExtensionMemberDescriptor> _createExtensionMembersIndex(
      Library library) {
    _extensionMemberIndex = {};
    library.extensions.forEach((extension) {
      DartType onType = extension.onType;
      if (onType is InterfaceType &&
          hasStaticInteropAnnotation(onType.className.asClass)) {
        extension.members.forEach((descriptor) {
          _extensionMemberIndex![descriptor.member] = descriptor;
        });
      }
    });
    return _extensionMemberIndex!;
  }

  DartType get _nullableJSValueType =>
      _jsValueClass.getThisType(_coreTypes, Nullability.nullable);

  Expression _jsifyVariable(VariableDeclaration variable) =>
      StaticInvocation(_jsifyTarget, Arguments([VariableGet(variable)]));

  /// Returns a new function body for the given [node] external method.
  ///
  /// The new function body will call `js_util_wasm.callConstructorVarArgs`
  /// for the given external method.
  ReturnStatement _getExternalCallConstructorBody(
      Procedure node, String constructorName) {
    var function = node.function;
    var callConstructorInvocation = StaticInvocation(
        _callConstructorTarget,
        Arguments([
          StaticInvocation(_globalThisTarget, Arguments([])),
          StringLiteral(constructorName),
          ListLiteral(
              function.positionalParameters.map(_jsifyVariable).toList(),
              typeArgument: _nullableJSValueType)
        ]))
      ..fileOffset = node.fileOffset;
    return ReturnStatement(callConstructorInvocation);
  }

  Expression _dartify(Expression expression) =>
      StaticInvocation(_dartifyTarget, Arguments([expression]));

  /// Returns a new function body for the given [node] external getter.
  ///
  /// The new function body will call `js_util_wasm.getProperty` for the
  /// given external getter.
  ReturnStatement _getExternalGetterBody(Procedure node) {
    var function = node.function;
    assert(function.positionalParameters.length == 1);
    var getPropertyInvocation = _dartify(StaticInvocation(
        _getPropertyTarget,
        Arguments([
          VariableGet(function.positionalParameters.first),
          StringLiteral(_getExtensionMemberName(node))
        ])))
      ..fileOffset = node.fileOffset;
    return ReturnStatement(getPropertyInvocation);
  }

  /// Returns a new function body for the given [node] external setter.
  ///
  /// The new function body will call `js_util_wasm.setProperty` for
  /// the given external setter.
  ReturnStatement _getExternalSetterBody(Procedure node) {
    var function = node.function;
    assert(function.positionalParameters.length == 2);
    var value = function.positionalParameters.last;
    var setPropertyInvocation = _dartify(StaticInvocation(
        _setPropertyTarget,
        Arguments([
          VariableGet(function.positionalParameters.first),
          StringLiteral(_getExtensionMemberName(node)),
          _jsifyVariable(value)
        ])))
      ..fileOffset = node.fileOffset;
    return ReturnStatement(setPropertyInvocation);
  }

  /// Returns a new function body for the given [node] external method.
  ///
  /// The new function body will call `js_util_wasm.callMethodVarArgs` for
  /// the given external method.
  ReturnStatement _getExternalMethodBody(Procedure node) {
    var function = node.function;
    var callMethodInvocation = _dartify(StaticInvocation(
        _callMethodTarget,
        Arguments([
          VariableGet(function.positionalParameters.first),
          StringLiteral(_getExtensionMemberName(node)),
          ListLiteral(
              function.positionalParameters
                  .sublist(1)
                  .map(_jsifyVariable)
                  .toList(),
              typeArgument: _nullableJSValueType)
        ])))
      ..fileOffset = node.fileOffset;
    return ReturnStatement(callMethodInvocation);
  }

  /// Returns the extension member name.
  ///
  /// Returns either the name from the `@JS` annotation if non-empty, or the
  /// declared name of the extension member. Does not return the CFE generated
  /// name for the top level member for this extension member.
  String _getExtensionMemberName(Procedure node) {
    var jsAnnotationName = getJSName(node);
    if (jsAnnotationName.isNotEmpty) {
      return jsAnnotationName;
    }
    return _extensionMemberIndex![node.reference]!.name.text;
  }
}
