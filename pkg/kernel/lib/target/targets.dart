// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.targets;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../reference_from_index.dart';
import 'changed_structure_notifier.dart';

final List<String> targetNames = targets.keys.toList();

class TargetFlags {
  final bool trackWidgetCreation;
  final bool forceLateLoweringForTesting;
  final bool forceNoExplicitGetterCallsForTesting;
  final bool enableNullSafety;

  const TargetFlags(
      {this.trackWidgetCreation = false,
      this.forceLateLoweringForTesting = false,
      this.forceNoExplicitGetterCallsForTesting = false,
      this.enableNullSafety = false});

  bool operator ==(other) {
    if (other is! TargetFlags) return false;
    TargetFlags o = other;
    if (trackWidgetCreation != o.trackWidgetCreation) return false;
    if (forceLateLoweringForTesting != o.forceLateLoweringForTesting) {
      return false;
    }
    if (forceNoExplicitGetterCallsForTesting !=
        o.forceNoExplicitGetterCallsForTesting) {
      return false;
    }
    if (enableNullSafety != o.enableNullSafety) return false;
    return true;
  }

  int get hashCode {
    int hash = 485786;
    hash = 0x3fffffff & (hash * 31 + (hash ^ trackWidgetCreation.hashCode));
    hash = 0x3fffffff &
        (hash * 31 + (hash ^ forceLateLoweringForTesting.hashCode));
    hash = 0x3fffffff &
        (hash * 31 + (hash ^ forceNoExplicitGetterCallsForTesting.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ enableNullSafety.hashCode));
    return hash;
  }
}

typedef Target _TargetBuilder(TargetFlags flags);

final Map<String, _TargetBuilder> targets = <String, _TargetBuilder>{
  'none': (TargetFlags flags) => new NoneTarget(flags),
};

Target getTarget(String name, TargetFlags flags) {
  _TargetBuilder builder = targets[name];
  if (builder == null) return null;
  return builder(flags);
}

abstract class DiagnosticReporter<M, C> {
  void report(M message, int charOffset, int length, Uri fileUri,
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

  /// Lowering of a set constant to a backend-specific representation.
  Constant lowerSetConstant(SetConstant constant) => constant;

  /// Lowering of a map constant to a backend-specific representation.
  Constant lowerMapConstant(MapConstant constant) => constant;

  /// Number semantics to use for this backend.
  NumberSemantics get numberSemantics => NumberSemantics.vm;

  /// Inline control of constant variables. The given constant expression
  /// is the initializer of a [Field] or [VariableDeclaration] node.
  /// If this method returns `true`, the variable will be inlined at all
  /// points of reference and the variable itself removed (unless overridden
  /// by the `keepFields` or `keepLocals` properties).
  /// This method must be deterministic, i.e. it must always return the same
  /// value for the same constant value and place in the AST.
  bool shouldInlineConstant(ConstantExpression initializer) => true;

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

  /// A derived class may change this to `true` to enable Flutter specific
  /// "super-mixins" semantics.
  ///
  /// This semantics relaxes a number of constraint previously imposed on
  /// mixins. Importantly it imposes the following change:
  ///
  ///     An abstract class may contain a member with a super-invocation that
  ///     corresponds to a member of the superclass interface, but where the
  ///     actual superclass does not declare or inherit a matching method.
  ///     Since no amount of overriding can change this property, such a class
  ///     cannot be extended to a class that is not abstract, it can only be
  ///     used to derive a mixin from.
  ///
  /// See dartbug.com/31542 for details of the semantics.
  bool get enableSuperMixins => false;

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
      {void logger(String msg),
      ChangedStructureNotifier changedStructureNotifier}) {}

  /// Perform target-specific modular transformations on the given libraries.
  void performModularTransformationsOnLibraries(
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      List<Library> libraries,
      // TODO(askesc): Consider how to generally pass compiler options to
      // transformations.
      Map<String, String> environmentDefines,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex referenceFromIndex,
      {void logger(String msg),
      ChangedStructureNotifier changedStructureNotifier});

  /// Perform target-specific modular transformations on the given program.
  ///
  /// This is used when an individual expression is compiled, e.g. for debugging
  /// purposes. It is illegal to modify any of the enclosing nodes of the
  /// procedure.
  void performTransformationsOnProcedure(
      CoreTypes coreTypes, ClassHierarchy hierarchy, Procedure procedure,
      {void logger(String msg)}) {}

  /// Whether a platform library may define a restricted type, such as `bool`,
  /// `int`, `double`, `num`, and `String`.
  ///
  /// By default only `dart:core` may define restricted types, but some target
  /// implementations override this.
  bool mayDefineRestrictedType(Uri uri) =>
      uri.scheme == 'dart' && uri.path == 'core';

  /// Whether a library is allowed to import a platform private library.
  ///
  /// By default only `dart:*` libraries are allowed. May be overridden for
  /// testing purposes.
  bool allowPlatformPrivateLibraryAccess(Uri importer, Uri imported) =>
      imported.scheme != "dart" ||
      !imported.path.startsWith("_") ||
      importer.scheme == "dart" ||
      (importer.scheme == "package" &&
          importer.path.startsWith("dart_internal/"));

  /// Whether the `native` language extension is supported within [library].
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
  /// (i.e. in Javascript) should cause an error to be issued.
  /// An example of such a number is `2^53 + 1` where in Javascript - because
  /// integers are represented as doubles
  /// `Math.pow(2, 53) = Math.pow(2, 53) + 1`.
  bool get errorOnUnexactWebIntLiterals => false;

  /// Whether set literals are natively supported by this target. If set
  /// literals are not supported by the target, they will be desugared into
  /// explicit `Set` creation (for non-const set literals) or wrapped map
  /// literals (for const set literals).
  bool get supportsSetLiterals => true;

  /// Whether late fields and variable are support by this target.
  ///
  /// If `false`, late fields and variables are lowered fields, getter, setters
  /// etc. that provide equivalent semantics. See `pkg/kernel/nnbd_api.md` for
  /// details.
  bool get supportsLateFields;

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
      {bool isMethod: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isField: false,
      bool isLocalVariable: false,
      bool isDynamic: false,
      bool isSuper: false,
      bool isStatic: false,
      bool isConstructor: false,
      bool isTopLevel: false});

  /// Configure the given [Component] in a target specific way.
  /// Returns the configured component.
  Component configureComponent(Component component) => component;

  // Configure environment defines in a target-specific way.
  Map<String, String> updateEnvironmentDefines(Map<String, String> map) => map;

  String toString() => 'Target($name)';

  Class concreteListLiteralClass(CoreTypes coreTypes) => null;
  Class concreteConstListLiteralClass(CoreTypes coreTypes) => null;

  Class concreteMapLiteralClass(CoreTypes coreTypes) => null;
  Class concreteConstMapLiteralClass(CoreTypes coreTypes) => null;

  Class concreteIntLiteralClass(CoreTypes coreTypes, int value) => null;
  Class concreteDoubleLiteralClass(CoreTypes coreTypes, double value) => null;
  Class concreteStringLiteralClass(CoreTypes coreTypes, String value) => null;

  ConstantsBackend constantsBackend(CoreTypes coreTypes);
}

class NoneConstantsBackend extends ConstantsBackend {
  @override
  final bool supportsUnevaluatedConstants;

  const NoneConstantsBackend({this.supportsUnevaluatedConstants});
}

class NoneTarget extends Target {
  final TargetFlags flags;

  NoneTarget(this.flags);

  @override
  bool get supportsLateFields => !flags.forceLateLoweringForTesting;

  @override
  bool get supportsExplicitGetterCalls =>
      !flags.forceNoExplicitGetterCallsForTesting;

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
      Map<String, String> environmentDefines,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex referenceFromIndex,
      {void logger(String msg),
      ChangedStructureNotifier changedStructureNotifier}) {}

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    return new InvalidExpression(null);
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
    return new InvalidExpression(null);
  }

  @override
  ConstantsBackend constantsBackend(CoreTypes coreTypes) =>
      // TODO(johnniwinther): Should this vary with the use case?
      const NoneConstantsBackend(supportsUnevaluatedConstants: true);
}
