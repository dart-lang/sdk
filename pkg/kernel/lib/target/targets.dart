// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.targets;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../transformations/treeshaker.dart' show ProgramRoot;
import 'flutter.dart' show FlutterTarget;
import 'vm.dart' show VmTarget;
import 'vmcc.dart' show VmClosureConvertedTarget;
import 'vmreify.dart' show VmGenericTypesReifiedTarget;

final List<String> targetNames = targets.keys.toList();

class TargetFlags {
  final bool strongMode;
  final bool treeShake;

  /// Whether `async` functions start synchronously.
  final bool syncAsync;
  final List<ProgramRoot> programRoots;
  final Uri kernelRuntime;
  final bool allowDartInternalImport;

  TargetFlags(
      {this.strongMode: false,
      this.treeShake: false,
      this.syncAsync: false,
      this.allowDartInternalImport: false,
      this.programRoots: const <ProgramRoot>[],
      this.kernelRuntime});
}

typedef Target _TargetBuilder(TargetFlags flags);

final Map<String, _TargetBuilder> targets = <String, _TargetBuilder>{
  'none': (TargetFlags flags) => new NoneTarget(flags),
  'vm': (TargetFlags flags) => new VmTarget(flags),
  'vmcc': (TargetFlags flags) => new VmClosureConvertedTarget(flags),
  'vmreify': (TargetFlags flags) => new VmGenericTypesReifiedTarget(flags),
  'flutter': (TargetFlags flags) => new FlutterTarget(flags),
};

Target getTarget(String name, TargetFlags flags) {
  var builder = targets[name];
  if (builder == null) return null;
  return builder(flags);
}

/// A target provides backend-specific options for generating kernel IR.
abstract class Target {
  String get name;

  /// A list of URIs of required libraries, not including dart:core.
  ///
  /// Libraries will be loaded in order.
  List<String> get extraRequiredLibraries => <String>[];

  /// Additional declared variables implied by this target.
  ///
  /// These can also be passed on the command-line of form `-D<name>=<value>`,
  /// and those provided on the command-line take precedence over those defined
  /// by the target.
  Map<String, String> get extraDeclaredVariables => const <String, String>{};

  /// Classes from the SDK whose interface is required for the modular
  /// transformations.
  Map<String, List<String>> get requiredSdkClasses => CoreTypes.requiredClasses;

  bool get strongMode;

  /// A derived class may change this to `true` to disable type inference and
  /// type promotion phases of analysis.
  ///
  /// This is intended for profiling, to ensure that type inference and type
  /// promotion do not slow down compilation too much.
  bool get disableTypeInference => false;

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

  /// Perform target-specific modular transformations on the given component.
  ///
  /// These transformations should not be whole-component transformations.  They
  /// should expect that the component will contain external libraries.
  void performModularTransformationsOnComponent(
      CoreTypes coreTypes, ClassHierarchy hierarchy, Component component,
      {void logger(String msg)}) {
    performModularTransformationsOnLibraries(
        coreTypes, hierarchy, component.libraries,
        logger: logger);
  }

  /// Perform target-specific modular transformations on the given libraries.
  ///
  /// The intent of this method is to perform the transformations only on some
  /// subset of the component libraries and avoid packing them into a temporary
  /// [Component] instance to pass into [performModularTransformationsOnComponent].
  ///
  /// Note that the following should be equivalent:
  ///
  ///     target.performModularTransformationsOnComponent(coreTypes, component);
  ///
  /// and
  ///
  ///     target.performModularTransformationsOnLibraries(
  ///         coreTypes, component.libraries);
  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)});

  /// Perform target-specific whole-program transformations.
  ///
  /// These transformations should be optimizations and not required for
  /// correctness.  Everything should work if a simple and fast linker chooses
  /// not to apply these transformations.
  ///
  /// Note that [performGlobalTransformations] doesn't have -OnComponent and
  /// -OnLibraries alternatives, because the global knowledge required by the
  /// transformations is assumed to be retrieved from a [Component] instance.
  void performGlobalTransformations(CoreTypes coreTypes, Component component,
      {void logger(String msg)});

  /// Whether a platform library may define a restricted type, such as `bool`,
  /// `int`, `double`, `num`, and `String`.
  ///
  /// By default only `dart:core` may define restricted types, but some target
  /// implementations override this.
  bool mayDefineRestrictedType(Uri uri) =>
      uri.scheme == 'dart' && uri.path == 'core';

  /// Whether a library is allowed to import a platform private library.
  ///
  /// By default only `dart:*` libraries are allowed. May be overriden for
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

  /// Builds an expression that throws [error] as compile-time error. The
  /// target must be able to handle this expression in a constant expression.
  Expression throwCompileConstantError(CoreTypes coreTypes, Expression error) {
    return error;
  }

  /// Builds an expression that represents a compile-time error which is
  /// suitable for being passed to [throwCompileConstantError].
  Expression buildCompileTimeError(
      CoreTypes coreTypes, String message, int offset) {
    return new InvalidExpression(message)..fileOffset = offset;
  }

  String toString() => 'Target($name)';
}

class NoneTarget extends Target {
  final TargetFlags flags;

  NoneTarget(this.flags);

  bool get strongMode => flags.strongMode;
  String get name => 'none';
  List<String> get extraRequiredLibraries => <String>[];
  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)}) {}
  void performGlobalTransformations(CoreTypes coreTypes, Component component,
      {void logger(String msg)}) {}

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
}
