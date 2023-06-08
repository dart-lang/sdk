// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.target.targets;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../reference_from_index.dart';
import '../verifier.dart';
import 'changed_structure_notifier.dart';

final List<String> targetNames = targets.keys.toList();

class TargetFlags {
  final bool trackWidgetCreation;
  final bool soundNullSafety;
  final bool supportMirrors;

  const TargetFlags(
      {this.trackWidgetCreation = false,
      this.soundNullSafety = true,
      this.supportMirrors = true});

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is TargetFlags &&
        trackWidgetCreation == other.trackWidgetCreation &&
        soundNullSafety == other.soundNullSafety &&
        supportMirrors == other.supportMirrors;
  }

  @override
  int get hashCode {
    int hash = 485786;
    hash = 0x3fffffff & (hash * 31 + (hash ^ trackWidgetCreation.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ soundNullSafety.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ supportMirrors.hashCode));
    return hash;
  }
}

typedef Target _TargetBuilder(TargetFlags flags);

final Map<String, _TargetBuilder> targets = <String, _TargetBuilder>{
  'none': (TargetFlags flags) => new NoneTarget(flags),
};

Target? getTarget(String name, TargetFlags flags) {
  _TargetBuilder? builder = targets[name];
  if (builder == null) return null;
  Target target = builder(flags);
  if (flags is TestTargetFlags) {
    target = new TestTargetWrapper(target, flags);
  }
  return target;
}

abstract class DiagnosticReporter<M, C> {
  void report(M message, int charOffset, int length, Uri? fileUri,
      {List<C> context});
}

/// The different kinds of number semantics supported by the constant evaluator.
enum NumberSemantics {
  /// Dart VM number semantics.
  vm,

  /// JavaScript (Dart2js and DDC) number semantics.
  js,
}

// Backend specific constant evaluation behavior
class ConstantsBackend {
  const ConstantsBackend();

  /// Lowering of a list constant to a backend-specific representation.
  Constant lowerListConstant(ListConstant constant) => constant;

  /// Returns `true` if [constant] is lowered list constant created by
  /// [lowerListConstant].
  bool isLoweredListConstant(Constant constant) => false;

  /// Calls `f` for each element in the lowered list [constant].
  ///
  /// This assumes that `isLoweredListConstant(constant)` is true.
  void forEachLoweredListConstantElement(
      Constant constant, void Function(Constant element) f) {}

  /// Lowering of a set constant to a backend-specific representation.
  Constant lowerSetConstant(SetConstant constant) => constant;

  /// Returns `true` if [constant] is lowered set constant created by
  /// [lowerSetConstant].
  bool isLoweredSetConstant(Constant constant) => false;

  /// Calls `f` for each element in the lowered set [constant].
  ///
  /// This assumes that `isLoweredSetConstant(constant)` is true.
  void forEachLoweredSetConstantElement(
      Constant constant, void Function(Constant element) f) {}

  /// Lowering of a map constant to a backend-specific representation.
  Constant lowerMapConstant(MapConstant constant) => constant;

  /// Returns `true` if [constant] is lowered map constant created by
  /// [lowerMapConstant].
  bool isLoweredMapConstant(Constant constant) => false;

  /// Calls `f` for each key/value pair in the lowered map [constant].
  ///
  /// This assumes that `lowerMapConstant(constant)` is true.
  void forEachLoweredMapConstantEntry(
      Constant constant, void Function(Constant key, Constant value) f) {}

  /// Number semantics to use for this backend.
  NumberSemantics get numberSemantics => NumberSemantics.vm;

  /// If true, all constants are inlined. Otherwise [shouldInlineConstant] is
  /// called to determine whether a constant expression should be inlined.
  bool get alwaysInlineConstants => true;

  /// Inline control of constant variables. The given constant expression
  /// is the initializer of a [Field] or [VariableDeclaration] node.
  /// If this method returns `true`, the variable will be inlined at all
  /// points of reference and the variable itself removed (unless overridden
  /// by the `keepFields` or `keepLocals` properties).
  /// This method must be deterministic, i.e. it must always return the same
  /// value for the same constant value and place in the AST.
  ///
  /// This is only called if [alwaysInlineConstants] is `true`.
  bool shouldInlineConstant(ConstantExpression initializer) =>
      throw new UnsupportedError(
          'Per-value constant inlining is not supported');

  /// Whether this target supports unevaluated constants.
  ///
  /// If not, then trying to perform constant evaluation without an environment
  /// raises an exception.
  ///
  /// This defaults to `false` since it requires additional work for a backend
  /// to support unevaluated constants.
  bool get supportsUnevaluatedConstants => false;

  /// If `true` constant [Field] declarations are not removed from the AST even
  /// when use-sites are inlined.
  ///
  /// All use-sites will be rewritten based on [shouldInlineConstant].
  bool get keepFields => true;

  /// If `true` constant [VariableDeclaration]s are not removed from the AST
  /// even when use-sites are inlined.
  ///
  /// All use-sites will be rewritten based on [shouldInlineConstant].
  bool get keepLocals => false;
}

/// Interface used for determining whether a `dart:*` is considered supported
/// for the current target.
abstract class DartLibrarySupport {
  /// Returns `true` if the 'dart:[libraryName]' library is supported.
  ///
  /// [isSupportedBySpec] is `true` if the dart library was supported by the
  /// libraries specification.
  ///
  /// This is used to allow AOT to consider `dart:mirrors` as unsupported
  /// despite it being supported in the platform dill, and dart2js to consider
  /// `dart:_dart2js_runtime_metrics` to be supported despite it being an
  /// internal library.
  bool computeDartLibrarySupport(String libraryName,
      {required bool isSupportedBySpec});

  static const String dartLibraryPrefix = "dart.library.";

  static bool isDartLibraryQualifier(String dottedName) {
    return dottedName.startsWith(dartLibraryPrefix);
  }

  static String getDartLibraryName(String dottedName) {
    assert(isDartLibraryQualifier(dottedName));
    return dottedName.substring(dartLibraryPrefix.length);
  }

  /// Returns `"true"` if the "dart:[libraryName]" is supported and `""`
  /// otherwise.
  ///
  /// This is used to determine conditional imports and `bool.fromEnvironment`
  /// constant values for "dart.library.[libraryName]" values.
  static String getDartLibrarySupportValue(String libraryName,
      {required bool libraryExists,
      required bool isSynthetic,
      required bool isUnsupported,
      required DartLibrarySupport dartLibrarySupport}) {
    // A `dart:` library can be unsupported for several reasons:
    // * If the library doesn't exist from source or from dill, it is not
    //   supported.
    // * If the library has been synthesized, then it doesn't exist, but has
    //   been synthetically created due to an explicit import or export of it,
    //   in which case it is also not supported.
    // * If the library is marked as not supported in the libraries
    //   specification, it does exist, but is not supported.
    // * If the library is marked as supported in the libraries specification,
    //   it does exist and is potentially supported. Still the [Target] can
    //   consider it unsupported. This is for instance used to consider
    //   `dart:mirrors` as unsupported in AOT. The platform dill is shared with
    //   JIT, so the library exists and is marked as supported, but for AOT
    //   compilation it is still unsupported.
    bool isSupported = libraryExists && !isSynthetic && !isUnsupported;
    isSupported = dartLibrarySupport.computeDartLibrarySupport(libraryName,
        isSupportedBySpec: isSupported);
    return isSupported ? "true" : "";
  }
}

/// [DartLibrarySupport] that only relies on the "supported" property of
/// the libraries specification.
class DefaultDartLibrarySupport implements DartLibrarySupport {
  const DefaultDartLibrarySupport();

  @override
  bool computeDartLibrarySupport(String libraryName,
          {required bool isSupportedBySpec}) =>
      isSupportedBySpec;
}

/// [DartLibrarySupport] that supports overriding `dart:*` library support
/// otherwise defined by the libraries specification.
class CustomizedDartLibrarySupport implements DartLibrarySupport {
  final Set<String> supported;
  final Set<String> unsupported;

  const CustomizedDartLibrarySupport(
      {this.supported = const {}, this.unsupported = const {}});

  @override
  bool computeDartLibrarySupport(String libraryName,
      {required bool isSupportedBySpec}) {
    if (supported.contains(libraryName)) {
      return true;
    } else if (unsupported.contains(libraryName)) {
      return false;
    }
    return isSupportedBySpec;
  }
}

/// A target provides backend-specific options for generating kernel IR.
abstract class Target {
  TargetFlags get flags;
  String get name;

  /// A list of URIs of required libraries, not including dart:core.
  ///
  /// Libraries will be loaded in order.
  List<String> get extraRequiredLibraries => const <String>[];

  /// A list of URIs of extra required libraries when compiling the platform.
  ///
  /// Libraries will be loaded in order after the [extraRequiredLibraries]
  /// above.
  ///
  /// Normally not needed, but can be useful if removing libraries from the
  /// [extraRequiredLibraries] list so libraries will still be available in the
  /// platform if having a weird mix of current and not-quite-current as can
  /// sometimes be the case.
  List<String> get extraRequiredLibrariesPlatform => const <String>[];

  /// A list of URIs of libraries to be indexed in the CoreTypes index, not
  /// including dart:_internal, dart:async, dart:core and dart:mirrors.
  List<String> get extraIndexedLibraries => const <String>[];

  /// Additional declared variables implied by this target.
  ///
  /// These can also be passed on the command-line of form `-D<name>=<value>`,
  /// and those provided on the command-line take precedence over those defined
  /// by the target.
  Map<String, String> get extraDeclaredVariables => const <String, String>{};

  /// Classes from the SDK whose interface is required for the modular
  /// transformations.
  Map<String, List<String>> get requiredSdkClasses => CoreTypes.requiredClasses;

  /// A derived class may change this to `true` to enable forwarders to
  /// user-defined `noSuchMethod` that are generated for each abstract member
  /// if such `noSuchMethod` is present.
  ///
  /// The forwarders are abstract [Procedure]s with [isNoSuchMethodForwarder]
  /// bit set.  The implementation of the behavior of such forwarders is up
  /// for the target backend.
  bool get enableNoSuchMethodForwarders => false;

  /// Perform target-specific transformations on the outlines stored in
  /// [Component] when generating summaries.
  ///
  /// This transformation is used to add metadata on outlines and to filter
  /// unnecessary information before generating program summaries. This
  /// transformation is not applied when compiling full kernel programs to
  /// prevent affecting the internal invariants of the compiler and accidentally
  /// slowing down compilation.
  void performOutlineTransformations(Component component) {}

  /// Perform target-specific transformations on the given libraries that must
  /// run before constant evaluation.
  void performPreConstantEvaluationTransformations(
      Component component,
      CoreTypes coreTypes,
      List<Library> libraries,
      DiagnosticReporter diagnosticReporter,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier}) {}

  /// Perform target-specific modular transformations on the given libraries.
  void performModularTransformationsOnLibraries(
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      List<Library> libraries,
      // TODO(askesc): Consider how to generally pass compiler options to
      // transformations.
      Map<String, String>? environmentDefines,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier});

  /// Perform target-specific modular transformations on the given program.
  ///
  /// This is used when an individual expression is compiled, e.g. for debugging
  /// purposes. It is illegal to modify any of the enclosing nodes of the
  /// procedure.
  void performTransformationsOnProcedure(
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      Procedure procedure,
      // TODO(askesc): Consider how to generally pass compiler options to
      // transformations.
      Map<String, String>? environmentDefines,
      {void Function(String msg)? logger}) {}

  /// Whether a platform library may define a restricted type, such as `bool`,
  /// `int`, `double`, `num`, and `String`.
  ///
  /// By default only `dart:core` and `dart:typed_data` may define restricted
  /// types, but some target implementations override this.
  bool mayDefineRestrictedType(Uri uri) =>
      uri.isScheme('dart') && (uri.path == 'core' || uri.path == 'typed_data');

  /// Whether a library is allowed to import the platform private library
  /// [imported] from library [importer].
  ///
  /// By default only `dart:*` libraries are allowed. May be overridden for
  /// testing purposes.
  bool allowPlatformPrivateLibraryAccess(Uri importer, Uri imported) =>
      importer.isScheme("dart") ||
      (importer.isScheme("package") &&
          importer.path.startsWith("dart_internal/"));

  /// Whether the `native` language extension is supported within the library
  /// with the given import [uri].
  ///
  /// The `native` language extension is not part of the language specification,
  /// it means something else to each target, and it is enabled under different
  /// circumstances for each target implementation. For example, the VM target
  /// enables it everywhere because of existing support for "dart-ext:" native
  /// extensions, but targets like dart2js only enable it on the core libraries.
  bool enableNative(Uri uri) => false;

  /// There are two variants of the `native` language extension. The VM expects
  /// the native token to be followed by string, whereas dart2js and DDC do not.
  // TODO(sigmund, ahe): ideally we should remove the `native` syntax, if not,
  // we should at least unify the VM and non-VM variants.
  bool get nativeExtensionExpectsString => false;

  /// Whether integer literals that cannot be represented exactly on the web
  /// (i.e. in JavaScript) should cause an error to be issued.
  /// An example of such a number is `2^53 + 1` where in JavaScript - because
  /// integers are represented as doubles
  /// `Math.pow(2, 53) = Math.pow(2, 53) + 1`.
  bool get errorOnUnexactWebIntLiterals => false;

  /// Whether set literals are natively supported by this target. If set
  /// literals are not supported by the target, they will be desugared into
  /// explicit `Set` creation (for non-const set literals) or wrapped map
  /// literals (for const set literals).
  bool get supportsSetLiterals => true;

  /// Bit mask of [LateLowering] values for the late lowerings that should
  /// be performed by the CFE.
  ///
  /// For the selected lowerings, late fields and variables are encoded using
  /// fields, getter, setters etc. in a way that provide equivalent semantics.
  /// See `pkg/kernel/nnbd_api.md` for details.
  int get enabledLateLowerings;

  /// Returns `true` if the CFE should lower a late field given it
  /// [hasInitializer], [isFinal], and [isStatic].
  ///
  /// This is determined by the [enabledLateLowerings] mask.
  bool isLateFieldLoweringEnabled(
      {required bool hasInitializer,
      required bool isFinal,
      required bool isStatic}) {
    int mask = LateLowering.getFieldLowering(
        hasInitializer: hasInitializer, isFinal: isFinal, isStatic: isStatic);
    return enabledLateLowerings & mask != 0;
  }

  /// Bit mask of [ConstructorTearOffLowering] values for the constructor tear
  /// off lowerings that should be performed by the CFE.
  ///
  /// For the selected lowerings, constructor tear offs are encoded using
  /// synthesized top level functions.
  int get enabledConstructorTearOffLowerings;

  /// Returns `true` if lowering of generative constructor tear offs is enabled.
  ///
  /// This is determined by the [enabledConstructorTearOffLowerings] mask.
  bool get isConstructorTearOffLoweringEnabled =>
      (enabledConstructorTearOffLowerings &
          ConstructorTearOffLowering.constructors) !=
      0;

  /// Returns `true` if lowering of non-redirecting factory tear offs is
  /// enabled.
  ///
  /// This is determined by the [enabledConstructorTearOffLowerings] mask.
  bool get isFactoryTearOffLoweringEnabled =>
      (enabledConstructorTearOffLowerings &
          ConstructorTearOffLowering.factories) !=
      0;

  /// Returns `true` if lowering of redirecting factory tear offs is enabled.
  ///
  /// This is determined by the [enabledConstructorTearOffLowerings] mask.
  bool get isRedirectingFactoryTearOffLoweringEnabled =>
      (enabledConstructorTearOffLowerings &
          ConstructorTearOffLowering.redirectingFactories) !=
      0;

  /// Returns `true` if lowering of typedef tear offs is enabled.
  ///
  /// This is determined by the [enabledConstructorTearOffLowerings] mask.
  bool get isTypedefTearOffLoweringEnabled =>
      (enabledConstructorTearOffLowerings &
          ConstructorTearOffLowering.typedefs) !=
      0;

  /// Returns `true` if the CFE should lower a late local variable given it
  /// [hasInitializer], [isFinal], and its type [isPotentiallyNullable].
  ///
  /// This is determined by the [enabledLateLowerings] mask.
  bool isLateLocalLoweringEnabled(
      {required bool hasInitializer,
      required bool isFinal,
      required bool isPotentiallyNullable}) {
    int mask = LateLowering.getLocalLowering(
        hasInitializer: hasInitializer,
        isFinal: isFinal,
        isPotentiallyNullable: isPotentiallyNullable);
    return enabledLateLowerings & mask != 0;
  }

  /// If `true`, the backend supports creation and checking of a sentinel value
  /// for uninitialized late fields and variables through the `createSentinel`
  /// and `isSentinel` methods in `dart:_internal`.
  ///
  /// If `true` this is used when [supportsLateFields] is `false`.
  bool get supportsLateLoweringSentinel;

  /// Whether static fields with initializers in nnbd libraries should be
  /// encoded using the late field lowering.
  bool get useStaticFieldLowering;

  /// Whether calls to getters and fields should be encoded as a .call
  /// invocation on a property get.
  ///
  /// If `false`, calls to getters and fields are encoded as method invocations
  /// with the accessed getter or field as the interface target.
  bool get supportsExplicitGetterCalls;

  /// Builds an expression that instantiates an [Invocation] that can be passed
  /// to [noSuchMethod].
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper);

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
      bool isTopLevel = false});

  /// Configure the given [Component] in a target specific way.
  /// Returns the configured component.
  Component configureComponent(Component component) => component;

  /// Configure environment defines in a target-specific way.
  Map<String, String> updateEnvironmentDefines(Map<String, String> map) => map;

  @override
  String toString() => 'Target($name)';

  Class? concreteListLiteralClass(CoreTypes coreTypes) => null;
  Class? concreteConstListLiteralClass(CoreTypes coreTypes) => null;

  Class? concreteMapLiteralClass(CoreTypes coreTypes) => null;
  Class? concreteConstMapLiteralClass(CoreTypes coreTypes) => null;
  Class? concreteSetLiteralClass(CoreTypes coreTypes) => null;
  Class? concreteConstSetLiteralClass(CoreTypes coreTypes) => null;
  Class getRecordImplementationClass(CoreTypes coreTypes,
          int numPositionalFields, List<String> namedFields) =>
      throw UnsupportedError('Target.getRecordImplementationClass');

  Class? concreteIntLiteralClass(CoreTypes coreTypes, int value) => null;
  Class? concreteDoubleLiteralClass(CoreTypes coreTypes, double value) => null;
  Class? concreteStringLiteralClass(CoreTypes coreTypes, String value) => null;

  Class? concreteAsyncResultClass(CoreTypes coreTypes) => null;
  Class? concreteSyncStarResultClass(CoreTypes coreTypes) => null;

  ConstantsBackend get constantsBackend;

  /// Object that defines how AST nodes are verified for this [Target].
  Verification get verification => const Verification();

  /// Returns an [DartLibrarySupport] the defines which, if any, of the
  /// `dart:` libraries supported in the platform, that should not be
  /// considered supported when queried in conditional imports and
  /// `bool.fromEnvironment` constants.
  ///
  /// This is used treat `dart:mirrors` as unsupported in AOT but supported
  /// in JIT.
  DartLibrarySupport get dartLibrarySupport =>
      const DefaultDartLibrarySupport();

  /// Should this target-specific pragma be recognized by annotation parsers?
  bool isSupportedPragma(String pragmaName) => false;
}

class NoneConstantsBackend extends ConstantsBackend {
  @override
  final bool supportsUnevaluatedConstants;

  const NoneConstantsBackend({required this.supportsUnevaluatedConstants});
}

class NoneTarget extends Target {
  @override
  final TargetFlags flags;

  NoneTarget(this.flags);

  @override
  int get enabledLateLowerings => LateLowering.none;

  @override
  bool get supportsLateLoweringSentinel => false;

  @override
  bool get useStaticFieldLowering => false;

  @override
  bool get supportsExplicitGetterCalls => true;

  @override
  int get enabledConstructorTearOffLowerings => ConstructorTearOffLowering.none;

  @override
  String get name => 'none';

  @override
  List<String> get extraRequiredLibraries => <String>[];

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
      ChangedStructureNotifier? changedStructureNotifier}) {}

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    return new InvalidExpression(null);
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
    return new InvalidExpression(null);
  }

  @override
  ConstantsBackend get constantsBackend =>
      // TODO(johnniwinther): Should this vary with the use case?
      const NoneConstantsBackend(supportsUnevaluatedConstants: true);
}

class LateLowering {
  static const int nullableUninitializedNonFinalLocal = 1 << 0;
  static const int nonNullableUninitializedNonFinalLocal = 1 << 1;
  static const int nullableUninitializedFinalLocal = 1 << 2;
  static const int nonNullableUninitializedFinalLocal = 1 << 3;
  static const int nullableInitializedNonFinalLocal = 1 << 4;
  static const int nonNullableInitializedNonFinalLocal = 1 << 5;
  static const int nullableInitializedFinalLocal = 1 << 6;
  static const int nonNullableInitializedFinalLocal = 1 << 7;
  static const int uninitializedNonFinalStaticField = 1 << 8;
  static const int uninitializedFinalStaticField = 1 << 9;
  static const int initializedNonFinalStaticField = 1 << 10;
  static const int initializedFinalStaticField = 1 << 11;
  static const int uninitializedNonFinalInstanceField = 1 << 12;
  static const int uninitializedFinalInstanceField = 1 << 13;
  static const int initializedNonFinalInstanceField = 1 << 14;
  static const int initializedFinalInstanceField = 1 << 15;

  static const int none = 0;
  static const int all = (1 << 16) - 1;

  static int getLocalLowering(
      {required bool hasInitializer,
      required bool isFinal,
      required bool isPotentiallyNullable}) {
    if (hasInitializer) {
      if (isFinal) {
        if (isPotentiallyNullable) {
          return nullableInitializedFinalLocal;
        } else {
          return nonNullableInitializedFinalLocal;
        }
      } else {
        if (isPotentiallyNullable) {
          return nullableInitializedNonFinalLocal;
        } else {
          return nonNullableInitializedNonFinalLocal;
        }
      }
    } else {
      if (isFinal) {
        if (isPotentiallyNullable) {
          return nullableUninitializedFinalLocal;
        } else {
          return nonNullableUninitializedFinalLocal;
        }
      } else {
        if (isPotentiallyNullable) {
          return nullableUninitializedNonFinalLocal;
        } else {
          return nonNullableUninitializedNonFinalLocal;
        }
      }
    }
  }

  static int getFieldLowering(
      {required bool hasInitializer,
      required bool isFinal,
      required bool isStatic}) {
    if (hasInitializer) {
      if (isFinal) {
        if (isStatic) {
          return initializedFinalStaticField;
        } else {
          return initializedFinalInstanceField;
        }
      } else {
        if (isStatic) {
          return initializedNonFinalStaticField;
        } else {
          return initializedNonFinalInstanceField;
        }
      }
    } else {
      if (isFinal) {
        if (isStatic) {
          return uninitializedFinalStaticField;
        } else {
          return uninitializedFinalInstanceField;
        }
      } else {
        if (isStatic) {
          return uninitializedNonFinalStaticField;
        } else {
          return uninitializedNonFinalInstanceField;
        }
      }
    }
  }
}

class ConstructorTearOffLowering {
  /// Create static functions to use as tear offs of generative constructors.
  static const int constructors = 1 << 0;

  /// Create static functions to use as tear offs of non-redirecting factories.
  static const int factories = 1 << 1;

  /// Create static functions to use as tear offs of redirecting factories.
  static const int redirectingFactories = 1 << 2;

  /// Create top level functions to use as tear offs of typedefs that are not
  /// proper renames.
  static const int typedefs = 1 << 3;

  static const int none = 0;
  static const int all = (1 << 4) - 1;
}

class TestTargetFlags extends TargetFlags {
  final int? forceLateLoweringsForTesting;
  final bool? forceLateLoweringSentinelForTesting;
  final bool? forceStaticFieldLoweringForTesting;
  final bool? forceNoExplicitGetterCallsForTesting;
  final int? forceConstructorTearOffLoweringForTesting;
  final Set<String> supportedDartLibraries;
  final Set<String> unsupportedDartLibraries;

  const TestTargetFlags(
      {bool trackWidgetCreation = false,
      this.forceLateLoweringsForTesting,
      this.forceLateLoweringSentinelForTesting,
      this.forceStaticFieldLoweringForTesting,
      this.forceNoExplicitGetterCallsForTesting,
      this.forceConstructorTearOffLoweringForTesting,
      bool soundNullSafety = false,
      this.supportedDartLibraries = const {},
      this.unsupportedDartLibraries = const {}})
      : super(
            trackWidgetCreation: trackWidgetCreation,
            soundNullSafety: soundNullSafety);
}

mixin TestTargetMixin on Target {
  @override
  TestTargetFlags get flags;

  @override
  int get enabledLateLowerings =>
      flags.forceLateLoweringsForTesting ?? super.enabledLateLowerings;

  @override
  bool get supportsLateLoweringSentinel =>
      flags.forceLateLoweringSentinelForTesting ??
      super.supportsLateLoweringSentinel;

  @override
  bool get useStaticFieldLowering =>
      flags.forceStaticFieldLoweringForTesting ?? super.useStaticFieldLowering;

  @override
  bool get supportsExplicitGetterCalls =>
      flags.forceNoExplicitGetterCallsForTesting != null
          ? !flags.forceNoExplicitGetterCallsForTesting!
          : super.supportsExplicitGetterCalls;

  @override
  int get enabledConstructorTearOffLowerings =>
      flags.forceConstructorTearOffLoweringForTesting ??
      super.enabledConstructorTearOffLowerings;

  @override
  late final DartLibrarySupport dartLibrarySupport =
      new TestDartLibrarySupport(super.dartLibrarySupport, flags);
}

class TestDartLibrarySupport implements DartLibrarySupport {
  final DartLibrarySupport delegate;
  final TestTargetFlags flags;

  TestDartLibrarySupport(this.delegate, this.flags);

  @override
  bool computeDartLibrarySupport(String libraryName,
      {required bool isSupportedBySpec}) {
    if (flags.supportedDartLibraries.contains(libraryName)) {
      return true;
    } else if (flags.unsupportedDartLibraries.contains(libraryName)) {
      return false;
    }
    return delegate.computeDartLibrarySupport(libraryName,
        isSupportedBySpec: isSupportedBySpec);
  }
}

class TargetWrapper extends Target {
  final Target _target;

  TargetWrapper(this._target);

  @override
  TargetFlags get flags => _target.flags;

  @override
  int get enabledLateLowerings => _target.enabledLateLowerings;

  @override
  bool get supportsLateLoweringSentinel => _target.supportsLateLoweringSentinel;

  @override
  bool get useStaticFieldLowering => _target.useStaticFieldLowering;

  @override
  bool get supportsExplicitGetterCalls => _target.supportsExplicitGetterCalls;

  @override
  int get enabledConstructorTearOffLowerings =>
      _target.enabledConstructorTearOffLowerings;

  @override
  bool allowPlatformPrivateLibraryAccess(Uri importer, Uri imported) {
    return _target.allowPlatformPrivateLibraryAccess(importer, imported);
  }

  @override
  Class? concreteConstListLiteralClass(CoreTypes coreTypes) {
    return _target.concreteConstListLiteralClass(coreTypes);
  }

  @override
  Class? concreteConstMapLiteralClass(CoreTypes coreTypes) {
    return _target.concreteConstMapLiteralClass(coreTypes);
  }

  @override
  Class? concreteDoubleLiteralClass(CoreTypes coreTypes, double value) {
    return _target.concreteDoubleLiteralClass(coreTypes, value);
  }

  @override
  Class? concreteIntLiteralClass(CoreTypes coreTypes, int value) {
    return _target.concreteIntLiteralClass(coreTypes, value);
  }

  @override
  Class? concreteListLiteralClass(CoreTypes coreTypes) {
    return _target.concreteListLiteralClass(coreTypes);
  }

  @override
  Class? concreteMapLiteralClass(CoreTypes coreTypes) {
    return _target.concreteMapLiteralClass(coreTypes);
  }

  @override
  Class? concreteStringLiteralClass(CoreTypes coreTypes, String value) {
    return _target.concreteStringLiteralClass(coreTypes, value);
  }

  @override
  Component configureComponent(Component component) {
    return _target.configureComponent(component);
  }

  @override
  ConstantsBackend get constantsBackend => _target.constantsBackend;

  @override
  bool enableNative(Uri uri) {
    return _target.enableNative(uri);
  }

  @override
  bool get enableNoSuchMethodForwarders => _target.enableNoSuchMethodForwarders;

  @override
  bool get errorOnUnexactWebIntLiterals => _target.errorOnUnexactWebIntLiterals;

  @override
  Map<String, String> get extraDeclaredVariables =>
      _target.extraDeclaredVariables;

  @override
  List<String> get extraIndexedLibraries => _target.extraIndexedLibraries;

  @override
  List<String> get extraRequiredLibraries => _target.extraRequiredLibraries;

  @override
  List<String> get extraRequiredLibrariesPlatform =>
      _target.extraRequiredLibrariesPlatform;

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    return _target.instantiateInvocation(
        coreTypes, receiver, name, arguments, offset, isSuper);
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
    return _target.instantiateNoSuchMethodError(
        coreTypes, receiver, name, arguments, offset,
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
  }

  @override
  bool mayDefineRestrictedType(Uri uri) {
    return _target.mayDefineRestrictedType(uri);
  }

  @override
  String get name => _target.name;

  @override
  bool get nativeExtensionExpectsString => _target.nativeExtensionExpectsString;

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
    _target.performModularTransformationsOnLibraries(
        component,
        coreTypes,
        hierarchy,
        libraries,
        environmentDefines,
        diagnosticReporter,
        referenceFromIndex,
        logger: logger,
        changedStructureNotifier: changedStructureNotifier);
  }

  @override
  void performOutlineTransformations(Component component) {
    _target.performOutlineTransformations(component);
  }

  @override
  void performPreConstantEvaluationTransformations(
      Component component,
      CoreTypes coreTypes,
      List<Library> libraries,
      DiagnosticReporter diagnosticReporter,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier}) {
    _target.performPreConstantEvaluationTransformations(
        component, coreTypes, libraries, diagnosticReporter,
        logger: logger, changedStructureNotifier: changedStructureNotifier);
  }

  @override
  void performTransformationsOnProcedure(
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      Procedure procedure,
      Map<String, String>? environmentDefines,
      {void Function(String msg)? logger}) {
    _target.performTransformationsOnProcedure(
        coreTypes, hierarchy, procedure, environmentDefines,
        logger: logger);
  }

  @override
  Map<String, List<String>> get requiredSdkClasses =>
      _target.requiredSdkClasses;

  @override
  bool get supportsSetLiterals => _target.supportsSetLiterals;

  @override
  Map<String, String> updateEnvironmentDefines(Map<String, String> map) {
    return _target.updateEnvironmentDefines(map);
  }

  @override
  Verification get verification => _target.verification;
}

class TestTargetWrapper extends TargetWrapper with TestTargetMixin {
  @override
  final TestTargetFlags flags;

  TestTargetWrapper(Target target, this.flags) : super(target);
}

/// Extends a Target to transform outlines to meet the requirements
/// of summaries in bazel and package-build.
///
/// Build systems like package-build may provide the same input file twice to
/// the summary worker, but only intends to have it in one output summary.  The
/// convention is that if it is listed as a source, it is intended to be part of
/// the output, if the source file was loaded as a dependency, then it was
/// already included in a different summary.  The transformation below ensures
/// that the output summary doesn't include those implicit inputs.
///
/// Note: this transformation is destructive and is only intended to be used
/// when generating summaries.
mixin SummaryMixin on Target {
  List<Uri> get sources;
  bool get excludeNonSources;

  @override
  void performOutlineTransformations(Component component) {
    super.performOutlineTransformations(component);
    if (!excludeNonSources) return;

    List<Library> libraries = new List.of(component.libraries);
    component.libraries.clear();
    Set<Uri> include = sources.toSet();
    for (Library library in libraries) {
      if (include.contains(library.importUri)) {
        component.libraries.add(library);
      } else {
        // Excluding the library also means that their canonical names will not
        // be computed as part of serialization, so we need to do that
        // preemptively here to avoid errors when serializing references to
        // elements of these libraries.
        library.bindCanonicalNames(component.root);
      }
    }
  }
}
