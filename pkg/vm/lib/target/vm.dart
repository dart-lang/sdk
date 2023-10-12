// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart';

import '../transformations/call_site_annotator.dart' as callSiteAnnotator;
import '../transformations/lowering.dart' as lowering
    show transformLibraries, transformProcedure;
import '../transformations/mixin_full_resolution.dart' as transformMixins
    show transformLibraries;
import '../transformations/ffi/common.dart' as ffiHelper
    show calculateTransitiveImportsOfDartFfiIfUsed;
import '../transformations/ffi/definitions.dart' as transformFfiDefinitions
    show transformLibraries;
import '../transformations/ffi/native.dart' as transformFfiNative
    show transformLibraries;
import '../transformations/ffi/use_sites.dart' as transformFfiUseSites
    show transformLibraries;

/// Specializes the kernel IR to the Dart VM.
class VmTarget extends Target {
  final TargetFlags flags;

  Class? _growableList;
  Class? _immutableList;
  Class? _constMap;
  Class? _constSet;
  Class? _map;
  Class? _set;
  Class? _record;
  Class? _oneByteString;
  Class? _twoByteString;
  Class? _smi;
  Class? _double; // _Double, not double.
  Class? _closure;
  Class? _syncStarIterable;

  VmTarget(this.flags);

  @override
  bool get enableNoSuchMethodForwarders => true;

  @override
  bool get supportsSetLiterals => false;

  @override
  int get enabledLateLowerings => LateLowering.none;

  @override
  bool get supportsLateLoweringSentinel => false;

  @override
  bool get useStaticFieldLowering => false;

  @override
  bool get supportsExplicitGetterCalls => true;

  @override
  int get enabledConstructorTearOffLowerings =>
      ConstructorTearOffLowering.typedefs;

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
        'dart:ffi',
        'dart:_internal',
        'dart:isolate',
        'dart:math',

        // The library dart:mirrors may be ignored by the VM, e.g. when built in
        // PRODUCT mode.
        'dart:mirrors',

        'dart:typed_data',
        'dart:vmservice_io',
        'dart:_vmservice',
        'dart:_builtin',
        'dart:nativewrappers',
        'dart:io',
        'dart:cli',
      ];

  @override
  List<String> get extraRequiredLibrariesPlatform => const <String>[];

  void _patchVmConstants(CoreTypes coreTypes) {
    // Fix Endian.host to be a const field equal to Endian.little instead of
    // a final field. VM does not support big-endian architectures at the
    // moment.
    // Can't use normal patching process for this because CFE does not
    // support patching fields.
    // See http://dartbug.com/32836 for the background.
    final Field host =
        coreTypes.index.getField('dart:typed_data', 'Endian', 'host');
    final Field little =
        coreTypes.index.getField('dart:typed_data', 'Endian', 'little');
    host.isConst = true;
    host.initializer = new CloneVisitorNotMembers().clone(little.initializer!)
      ..parent = host;
  }

  @override
  void performPreConstantEvaluationTransformations(
      Component component,
      CoreTypes coreTypes,
      List<Library> libraries,
      DiagnosticReporter diagnosticReporter,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier}) {
    super.performPreConstantEvaluationTransformations(
        component, coreTypes, libraries, diagnosticReporter,
        logger: logger, changedStructureNotifier: changedStructureNotifier);
    _patchVmConstants(coreTypes);
  }

  @override
  List<String> get extraIndexedLibraries => const <String>[
        // TODO(askesc): When the VM supports set literals, we no longer
        // need to index dart:collection, as it is only needed for desugaring of
        // const sets. We can remove it from this list at that time.
        "dart:collection",
        // TODO(askesc): This is for the VM host endian optimization, which
        // could possibly be done more cleanly after the VM no longer supports
        // doing constant evaluation on its own. See http://dartbug.com/32836
        "dart:typed_data",
      ];

  @override
  void performModularTransformationsOnLibraries(
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      List<Library> libraries,
      Map<String, String>? environmentDefines,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier}) {
    transformMixins.transformLibraries(
        this, coreTypes, hierarchy, libraries, referenceFromIndex);
    logger?.call("Transformed mixin applications");

    List<Library>? transitiveImportingDartFfi = ffiHelper
        .calculateTransitiveImportsOfDartFfiIfUsed(component, libraries);
    if (transitiveImportingDartFfi == null) {
      logger?.call("Skipped ffi transformation");
    } else {
      transformFfiDefinitions.transformLibraries(
          component,
          coreTypes,
          hierarchy,
          transitiveImportingDartFfi,
          diagnosticReporter,
          referenceFromIndex,
          changedStructureNotifier);
      transformFfiUseSites.transformLibraries(component, coreTypes, hierarchy,
          transitiveImportingDartFfi, diagnosticReporter, referenceFromIndex);
      logger?.call("Transformed ffi annotations");

      // Transform @FfiNative(..) functions into FFI native call functions.
      // Pass instance method receivers as implicit first argument to the static
      // native function.
      // Transform arguments that extend NativeFieldWrapperClass1 to Pointer if
      // the native function expects Pointer (to avoid Handle overhead).
      transformFfiNative.transformLibraries(component, coreTypes, hierarchy,
          transitiveImportingDartFfi, diagnosticReporter, referenceFromIndex);
      logger?.call("Transformed ffi natives");
    }

    bool productMode = environmentDefines!["dart.vm.product"] == "true";
    lowering.transformLibraries(libraries, coreTypes, hierarchy,
        nullSafety: flags.soundNullSafety, productMode: productMode);
    logger?.call("Lowering transformations performed");

    callSiteAnnotator.transformLibraries(
        component, libraries, coreTypes, hierarchy);
    logger?.call("Annotated call sites");
  }

  @override
  void performTransformationsOnProcedure(
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      Procedure procedure,
      Map<String, String>? environmentDefines,
      {void Function(String msg)? logger}) {
    bool productMode = environmentDefines!["dart.vm.product"] == "true";
    lowering.transformProcedure(procedure, coreTypes, hierarchy,
        nullSafety: flags.soundNullSafety, productMode: productMode);
    logger?.call("Lowering transformations performed");
  }

  Expression _instantiateInvocationMirrorWithType(
      CoreTypes coreTypes,
      Expression receiver,
      String name,
      Arguments arguments,
      int offset,
      int type) {
    return new ConstructorInvocation(
        coreTypes.invocationMirrorWithTypeConstructor,
        new Arguments(<Expression>[
          new SymbolLiteral(name)..fileOffset = offset,
          new IntLiteral(type)..fileOffset = offset,
          _fixedLengthList(
              coreTypes,
              coreTypes.typeLegacyRawType,
              arguments.types
                  .map<Expression>((t) => new TypeLiteral(t))
                  .toList(),
              arguments.fileOffset),
          _fixedLengthList(coreTypes, const DynamicType(), arguments.positional,
              arguments.fileOffset),
          new StaticInvocation(
              coreTypes.mapUnmodifiable,
              new Arguments([
                new MapLiteral(new List<MapLiteralEntry>.from(
                    arguments.named.map((NamedExpression arg) {
                  return new MapLiteralEntry(
                      new SymbolLiteral(arg.name)..fileOffset = arg.fileOffset,
                      arg.value)
                    ..fileOffset = arg.fileOffset;
                })), keyType: coreTypes.symbolLegacyRawType)
                  ..isConst = (arguments.named.isEmpty)
                  ..fileOffset = arguments.fileOffset
              ], types: [
                coreTypes.symbolLegacyRawType,
                new DynamicType()
              ]))
            ..fileOffset = offset
        ]));
  }

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    bool isGetter = false, isSetter = false, isMethod = false;
    if (name.startsWith("set:")) {
      isSetter = true;
      name = name.substring(4);
    } else if (name.startsWith("get:")) {
      isGetter = true;
      name = name.substring(4);
    } else {
      isMethod = true;
    }

    int type = _invocationType(
        isGetter: isGetter,
        isSetter: isSetter,
        isMethod: isMethod,
        isSuper: isSuper);

    return _instantiateInvocationMirrorWithType(
        coreTypes, receiver, name, arguments, offset, type);
  }

  @override
  Expression instantiateNoSuchMethodError(CoreTypes coreTypes,
      Expression receiver, String name, Arguments arguments, int offset,
      {bool isMethod = false,
      bool isGetter = false,
      bool isSetter = false,
      bool isField = false,
      bool isLocalVariable = false,
      bool isDynamic = false,
      bool isSuper = false,
      bool isStatic = false,
      bool isConstructor = false,
      bool isTopLevel = false}) {
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
    return new StaticInvocation(
        coreTypes.noSuchMethodErrorDefaultConstructor,
        new Arguments(<Expression>[
          receiver,
          _instantiateInvocationMirrorWithType(
              coreTypes, receiver, name, arguments, offset, type)
        ]));
  }

  int _invocationType(
      {bool isMethod = false,
      bool isGetter = false,
      bool isSetter = false,
      bool isField = false,
      bool isLocalVariable = false,
      bool isDynamic = false,
      bool isSuper = false,
      bool isStatic = false,
      bool isConstructor = false,
      bool isTopLevel = false}) {
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

  Expression _fixedLengthList(CoreTypes coreTypes, DartType typeArgument,
      List<Expression> elements, int offset) {
    // TODO(ahe): It's possible that it would be better to create a fixed-length
    // list first, and then populate it. That would create fewer objects. But as
    // this is currently only used in (statically resolved) no-such-method
    // handling, the current approach seems sufficient.

    // The 0-element list must be exactly 'const[]'.
    if (elements.isEmpty) {
      return new ListLiteral([], typeArgument: typeArgument)..isConst = true;
    }

    return new StaticInvocation(
        coreTypes.listUnmodifiableConstructor,
        new Arguments([
          new ListLiteral(elements, typeArgument: typeArgument)
            ..fileOffset = offset
        ], types: [
          typeArgument,
        ]));
  }

  // In addition to the default implementation, we allow VM tests to import
  // private platform libraries - such as `dart:_internal` - for testing
  // purposes.
  bool allowPlatformPrivateLibraryAccess(Uri importer, Uri imported) =>
      super.allowPlatformPrivateLibraryAccess(importer, imported) ||
      importer.path.contains('runtime/observatory/tests') ||
      importer.path.contains('runtime/tests/vm/dart') ||
      importer.path.contains('tests/standalone/io') ||
      importer.path.contains('test-lib') ||
      importer.path.contains('tests/ffi');

  // TODO(sigmund,ahe): limit this to `dart-ext` libraries only (see
  // https://github.com/dart-lang/sdk/issues/29763).
  @override
  bool enableNative(Uri uri) => true;

  @override
  bool get nativeExtensionExpectsString => true;

  @override
  Component configureComponent(Component component) {
    callSiteAnnotator.addRepositoryTo(component);
    return super.configureComponent(component);
  }

  @override
  Class concreteListLiteralClass(CoreTypes coreTypes) {
    return _growableList ??=
        coreTypes.index.getClass('dart:core', '_GrowableList');
  }

  @override
  Class concreteConstListLiteralClass(CoreTypes coreTypes) {
    return _immutableList ??=
        coreTypes.index.getClass('dart:core', '_ImmutableList');
  }

  @override
  Class concreteMapLiteralClass(CoreTypes coreTypes) {
    return _map ??= coreTypes.index.getClass('dart:collection', '_Map');
  }

  @override
  Class concreteConstMapLiteralClass(CoreTypes coreTypes) {
    return _constMap ??=
        coreTypes.index.getClass('dart:collection', '_ConstMap');
  }

  @override
  Class concreteSetLiteralClass(CoreTypes coreTypes) {
    return _set ??= coreTypes.index.getClass('dart:collection', '_Set');
  }

  @override
  Class concreteConstSetLiteralClass(CoreTypes coreTypes) {
    return _constSet ??=
        coreTypes.index.getClass('dart:collection', '_ConstSet');
  }

  @override
  Class getRecordImplementationClass(
      CoreTypes coreTypes, int numPositionalFields, List<String> namedFields) {
    return _record ??= coreTypes.index.getClass('dart:core', '_Record');
  }

  @override
  Class? concreteIntLiteralClass(CoreTypes coreTypes, int value) {
    const int bitsPerInt32 = 32;
    const int smiBits32 = bitsPerInt32 - 2;
    const int smiMin32 = -(1 << smiBits32);
    const int smiMax32 = (1 << smiBits32) - 1;
    if ((smiMin32 <= value) && (value <= smiMax32)) {
      // Value fits into Smi on all platforms.
      return _smi ??= coreTypes.index.getClass('dart:core', '_Smi');
    }
    // Otherwise, class could be either _Smi or _Mint depending on a platform.
    return null;
  }

  @override
  Class concreteDoubleLiteralClass(CoreTypes coreTypes, double value) {
    return _double ??= coreTypes.index.getClass('dart:core', '_Double');
  }

  @override
  Class concreteStringLiteralClass(CoreTypes coreTypes, String value) {
    const int maxLatin1 = 0xff;
    for (int i = 0; i < value.length; ++i) {
      if (value.codeUnitAt(i) > maxLatin1) {
        return _twoByteString ??=
            coreTypes.index.getClass('dart:core', '_TwoByteString');
      }
    }
    return _oneByteString ??=
        coreTypes.index.getClass('dart:core', '_OneByteString');
  }

  @override
  Class concreteClosureClass(CoreTypes coreTypes) {
    return _closure ??= coreTypes.index.getClass('dart:core', '_Closure');
  }

  @override
  Class? concreteAsyncResultClass(CoreTypes coreTypes) =>
      coreTypes.futureImplClass;

  @override
  Class? concreteSyncStarResultClass(CoreTypes coreTypes) {
    return _syncStarIterable ??=
        coreTypes.index.getClass('dart:async', '_SyncStarIterable');
  }

  @override
  ConstantsBackend get constantsBackend => const ConstantsBackend();

  @override
  Map<String, String> updateEnvironmentDefines(Map<String, String> map) {
    // TODO(alexmarkov): Call this from the front-end in order to have
    //  the same defines when compiling platform.
    map['dart.isVM'] = 'true';
    return map;
  }

  @override
  DartLibrarySupport get dartLibrarySupport => flags.supportMirrors
      ? const DefaultDartLibrarySupport()
      : const CustomizedDartLibrarySupport(unsupported: {'mirrors'});

  @override
  bool isSupportedPragma(String pragmaName) => pragmaName.startsWith("vm:");
}
