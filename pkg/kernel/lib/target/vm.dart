// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.vm;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';

import '../transformations/mixin_full_resolution.dart' as transformMixins
    show transformLibraries;
import '../transformations/continuation.dart' as transformAsync
    show transformLibraries;
import '../transformations/precompiler.dart' as transformPrecompiler
    show transformProgram;

import 'implementation_option.dart' show VmOptions;
import 'targets.dart';

/// Specializes the kernel IR to the Dart VM.
class VmTarget extends Target {
  final TargetFlags flags;

  VmTarget(this.flags);

  @override
  bool get strongMode => flags.strongMode;

  /// The VM patch files are not strong mode clean, so we adopt a hybrid mode
  /// where the SDK is internally unchecked, but trusted to satisfy the types
  /// declared on its interface.
  @override
  bool get strongModeSdk => false;

  @override
  String get name => 'vm';

  // This is the order that bootstrap libraries are loaded according to
  // `runtime/vm/object_store.h`.
  @override
  List<String> get extraRequiredLibraries => const <String>[
        'dart:async',
        'dart:collection',
        'dart:convert',
        'dart:developer',
        'dart:_internal',
        'dart:isolate',
        'dart:math',

        // The library dart:mirrors may be ignored by the VM, e.g. when built in
        // PRODUCT mode.
        'dart:mirrors',

        'dart:profiler',
        'dart:typed_data',
        'dart:vmservice_io',
        'dart:_vmservice',
        'dart:_builtin',
        'dart:nativewrappers',
        'dart:io',
      ];

  @override
  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)}) {
    transformMixins.transformLibraries(this, coreTypes, hierarchy, libraries,
        doSuperResolution: false /* resolution is done in Dart VM */);
    logger?.call("Transformed mixin applications");

    // TODO(kmillikin): Make this run on a per-method basis.
    transformAsync.transformLibraries(coreTypes, libraries);
    logger?.call("Transformed async methods");
  }

  @override
  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)}) {
    if (strongMode &&
        (flags.implementationOptions != null) &&
        flags.implementationOptions.contains(VmOptions.strongAOT)) {
      transformPrecompiler.transformProgram(coreTypes, program);
    }
  }

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    // See [_InvocationMirror]
    // (../../../../runtime/lib/invocation_mirror_patch.dart).
    // The _InvocationMirror._withoutType constructor takes the following arguments:
    // * Method name (a string).
    // * List of type arguments.
    // * List of positional arguments.
    // * List of named arguments.
    // * Whether it's a super invocation or not.
    return new ConstructorInvocation(
        coreTypes.invocationMirrorWithoutTypeConstructor,
        new Arguments(<Expression>[
          new StringLiteral(name)..fileOffset = offset,
          _fixedLengthList(
              arguments.types.map((t) => new TypeLiteral(t)).toList(),
              arguments.fileOffset),
          _fixedLengthList(arguments.positional, arguments.fileOffset),
          new StaticInvocation(
              coreTypes.mapUnmodifiable,
              new Arguments([
                new MapLiteral(new List<MapEntry>.from(
                    arguments.named.map((NamedExpression arg) {
                  return new MapEntry(
                      new SymbolLiteral(arg.name)..fileOffset = arg.fileOffset,
                      arg.value)
                    ..fileOffset = arg.fileOffset;
                })))
                  ..isConst = (arguments.named.length == 0)
                  ..fileOffset = arguments.fileOffset
              ]))
            ..fileOffset = arguments.fileOffset,
          new BoolLiteral(isSuper)..fileOffset = arguments.fileOffset
        ]))
      ..fileOffset = offset;
  }

  @override
  Expression instantiateNoSuchMethodError(CoreTypes coreTypes,
      Expression receiver, String name, Arguments arguments, int offset,
      {bool isMethod: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isField: false,
      bool isLocalVariable: false,
      bool isDynamic: false,
      bool isSuper: false,
      bool isStatic: false,
      bool isConstructor: false,
      bool isTopLevel: false}) {
    int type = _invocationType(
        isMethod: isMethod,
        isGetter: isGetter,
        isSetter: isSetter,
        isField: isField,
        isLocalVariable: isLocalVariable,
        isDynamic: isDynamic,
        isSuper: isSuper,
        isStatic: isStatic,
        isConstructor: isConstructor,
        isTopLevel: isTopLevel);
    return new ConstructorInvocation(
        coreTypes.noSuchMethodErrorDefaultConstructor,
        new Arguments(<Expression>[
          receiver,
          new ConstructorInvocation(
              coreTypes.invocationMirrorWithTypeConstructor,
              new Arguments(<Expression>[
                new SymbolLiteral(name)..fileOffset = offset,
                new IntLiteral(type)..fileOffset = offset,
                _fixedLengthList(
                    arguments.types.map((t) => new TypeLiteral(t)).toList(),
                    arguments.fileOffset),
                _fixedLengthList(arguments.positional, arguments.fileOffset),
                new StaticInvocation(
                    coreTypes.mapUnmodifiable,
                    new Arguments([
                      new MapLiteral(new List<MapEntry>.from(
                          arguments.named.map((NamedExpression arg) {
                        return new MapEntry(
                            new SymbolLiteral(arg.name)
                              ..fileOffset = arg.fileOffset,
                            arg.value)
                          ..fileOffset = arg.fileOffset;
                      })))
                        ..isConst = (arguments.named.length == 0)
                        ..fileOffset = arguments.fileOffset
                    ], types: [
                      new DynamicType(),
                      new DynamicType()
                    ]))
                  ..fileOffset = offset
              ]))
        ]));
  }

  int _invocationType(
      {bool isMethod: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isField: false,
      bool isLocalVariable: false,
      bool isDynamic: false,
      bool isSuper: false,
      bool isStatic: false,
      bool isConstructor: false,
      bool isTopLevel: false}) {
    // This is copied from [_InvocationMirror](
    // ../../../../../../runtime/lib/invocation_mirror_patch.dart).

    // Constants describing the invocation type.
    // _FIELD cannot be generated by regular invocation mirrors.
    const int _METHOD = 0;
    const int _GETTER = 1;
    const int _SETTER = 2;
    const int _FIELD = 3;
    const int _LOCAL_VAR = 4;
    // ignore: UNUSED_LOCAL_VARIABLE
    const int _KIND_SHIFT = 0;
    const int _KIND_BITS = 3;
    // ignore: UNUSED_LOCAL_VARIABLE
    const int _KIND_MASK = (1 << _KIND_BITS) - 1;

    // These values, except _DYNAMIC and _SUPER, are only used when throwing
    // NoSuchMethodError for compile-time resolution failures.
    const int _DYNAMIC = 0;
    const int _SUPER = 1;
    const int _STATIC = 2;
    const int _CONSTRUCTOR = 3;
    const int _TOP_LEVEL = 4;
    const int _LEVEL_SHIFT = _KIND_BITS;
    const int _LEVEL_BITS = 3;
    // ignore: UNUSED_LOCAL_VARIABLE
    const int _LEVEL_MASK = (1 << _LEVEL_BITS) - 1;

    int type = -1;
    // For convenience, [isGetter] and [isSetter] takes precedence over
    // [isMethod].
    if (isGetter) {
      type = _GETTER;
    } else if (isSetter) {
      type = _SETTER;
    } else if (isMethod) {
      type = _METHOD;
    } else if (isField) {
      type = _FIELD;
    } else if (isLocalVariable) {
      type = _LOCAL_VAR;
    }

    if (isDynamic) {
      type |= (_DYNAMIC << _LEVEL_SHIFT);
    } else if (isSuper) {
      type |= (_SUPER << _LEVEL_SHIFT);
    } else if (isStatic) {
      type |= (_STATIC << _LEVEL_SHIFT);
    } else if (isConstructor) {
      type |= (_CONSTRUCTOR << _LEVEL_SHIFT);
    } else if (isTopLevel) {
      type |= (_TOP_LEVEL << _LEVEL_SHIFT);
    }

    return type;
  }

  Expression _fixedLengthList(List<Expression> elements, int offset) {
    // TODO(ahe): It's possible that it would be better to create a fixed-length
    // list first, and then populate it. That would create fewer objects. But as
    // this is currently only used in (statically resolved) no-such-method
    // handling, the current approach seems sufficient.

    // The 0-element list must be exactly 'const[]'.
    if (elements.length == 0) {
      return new ListLiteral([])..isConst = true;
    }

    return new MethodInvocation(
        new ListLiteral(elements)..fileOffset = offset,
        new Name("toList"),
        new Arguments(<Expression>[], named: <NamedExpression>[
          new NamedExpression("growable", new BoolLiteral(false))
        ]));
  }

  // TODO(sigmund,ahe): limit this to `dart-ext` libraries only (see
  // https://github.com/dart-lang/sdk/issues/29763).
  @override
  bool enableNative(Uri uri) => true;

  @override
  bool get nativeExtensionExpectsString => true;
}
