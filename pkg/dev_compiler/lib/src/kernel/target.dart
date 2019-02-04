// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:core' hide MapEntry;
import 'package:kernel/kernel.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/target/targets.dart';
import 'kernel_helpers.dart';

/// A kernel [Target] to configure the Dart Front End for dartdevc.
class DevCompilerTarget extends Target {
  ClassHierarchy hierarchy;

  bool get legacyMode => false;

  bool get enableSuperMixins => true;

  String get name => 'dartdevc';

  List<String> get extraRequiredLibraries => const [
        'dart:_runtime',
        'dart:_debugger',
        'dart:_foreign_helper',
        'dart:_interceptors',
        'dart:_internal',
        'dart:_isolate_helper',
        'dart:_js_helper',
        'dart:_js_mirrors',
        'dart:_js_primitives',
        'dart:_metadata',
        'dart:_native_typed_data',
        'dart:async',
        'dart:collection',
        'dart:convert',
        'dart:developer',
        'dart:io',
        'dart:isolate',
        'dart:js',
        'dart:js_util',
        'dart:math',
        'dart:mirrors',
        'dart:typed_data',
        'dart:indexed_db',
        'dart:html',
        'dart:html_common',
        'dart:svg',
        'dart:web_audio',
        'dart:web_gl',
        'dart:web_sql'
      ];

  @override
  bool mayDefineRestrictedType(Uri uri) =>
      uri.scheme == 'dart' &&
      (uri.path == 'core' || uri.path == '_interceptors');

  @override
  bool enableNative(Uri uri) => uri.scheme == 'dart';

  @override
  bool get nativeExtensionExpectsString => false;

  @override
  bool get errorOnUnexactWebIntLiterals => true;

  @override
  bool get enableNoSuchMethodForwarders => true;

  @override
  void performModularTransformationsOnLibraries(
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      List<Library> libraries,
      DiagnosticReporter diagnosticReporter,
      {void logger(String msg)}) {
    this.hierarchy = hierarchy;
    for (var library in libraries) {
      _CovarianceTransformer(library).transform();
    }
  }

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    // TODO(jmesserly): preserve source information?
    // (These method are synthetic. Also unclear if the offset will correspond
    // to the file where the class resides, or the file where the method we're
    // mocking resides).
    Expression createInvocation(String name, List<Expression> positional) {
      // TODO(jmesserly): this uses the implementation _Invocation class,
      // because the CFE does not resolve the redirecting factory constructors
      // like it would for user code. Our code generator expects all redirecting
      // factories to be resolved to the real constructor.
      var ctor = coreTypes.index
          .getClass('dart:core', '_Invocation')
          .constructors
          .firstWhere((c) => c.name.name == name);
      return ConstructorInvocation(ctor, Arguments(positional));
    }

    if (name.startsWith('get:')) {
      return createInvocation('getter', [SymbolLiteral(name.substring(4))]);
    }
    if (name.startsWith('set:')) {
      return createInvocation('setter', [
        SymbolLiteral(name.substring(4) + '='),
        arguments.positional.single
      ]);
    }
    var ctorArgs = <Expression>[SymbolLiteral(name)];
    bool isGeneric = arguments.types.isNotEmpty;
    if (isGeneric) {
      ctorArgs.add(
          ListLiteral(arguments.types.map((t) => TypeLiteral(t)).toList()));
    } else {
      ctorArgs.add(NullLiteral());
    }
    ctorArgs.add(ListLiteral(arguments.positional));
    if (arguments.named.isNotEmpty) {
      ctorArgs.add(MapLiteral(
          arguments.named
              .map((n) => MapEntry(SymbolLiteral(n.name), n.value))
              .toList(),
          keyType: coreTypes.symbolClass.rawType));
    }
    return createInvocation('method', ctorArgs);
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
    // TODO(sigmund): implement;
    return InvalidExpression(null);
  }
}

/// Analyzes a component to determine if any covariance checks in private
/// members can be eliminated, and adjusts the flags to remove those checks.
///
/// See [_CovarianceTransformer.transform].
class _CovarianceTransformer extends RecursiveVisitor<void> {
  /// The set of private instance members in [_library] that (potentially) need
  /// covariance checks.
  ///
  /// Members need checks if they are accessed through a receiver whose type is
  /// not exactly known (i.e. the actual receiver could be a subtype of its
  /// static type). If the receiver expression is `this`, `super` or non-factory
  /// instance creation, it is known to have an exact type.
  final _checkedMembers = HashSet<Member>();

  /// List of private instance procedures.
  ///
  /// [transform] uses this list to eliminate covariance flags for members that
  /// aren't in [_checkedMembers].
  final _privateProcedures = List<Procedure>();

  /// List of private instance fields.
  ///
  /// [transform] uses this list to eliminate covariance flags for members that
  /// aren't in [_checkedMembers].
  final _privateFields = List<Field>();

  final Library _library;

  _CovarianceTransformer(this._library);

  /// Transforms [_library], eliminating unncessary checks for private members.
  ///
  /// Kernel will mark covariance checks on members, for example:
  /// - a field with [Field.isGenericCovariantImpl] or [Field.isCovariant].
  /// - a method/setter with parameter(s) or type parameter(s) that have
  ///   `isGenericCovariantImpl` or `isCovariant` set.
  ///
  /// If the check can be safely eliminanted, those properties will be set to
  /// false so the JS compiler does not emit checks.
  ///
  /// Public members always need covariance checks (we cannot see all potential
  /// call sites), but in some cases we can eliminate these checks for private
  /// members.
  ///
  /// Private members only need covariance checks if they are accessed through a
  /// receiver whose type is not exactly known (i.e. the actual receiver could
  /// be a subtype of its static type). If the receiver expression is `this`,
  /// `super` or non-factory instance creation, it is known to have an exact
  /// type, so no callee check is necessary to ensure soundness (normal
  /// subtyping checks at the call site are sufficient).
  ///
  /// However to eliminate a check, we must know that all call sites are safe.
  /// So the first pass is to collect any potentially-unsafe call sites, this
  /// is done by [_checkTarget] and [_checkTearoff].
  ///
  /// Method tearoffs must also be marked potentially-unsafe, regardless of
  /// whether the receiver type is known, because they could escape. Also their
  /// runtime type must store `Object` in for covariant parameters (this
  /// affects `is`, casts, and the `.runtimeType` property).
  ///
  /// Note 1: dynamic calls do not need to be considered here, because they
  /// will be checked based on runtime type information.
  ///
  /// Node 2: public members in private classes cannot be treated as private
  /// unless we know that the member is not exposed via some public interface
  /// (implemented by their class or a subclass) that needs a covariance check.
  /// That is somewhat complex to analyze, so for now we ignore it.
  void transform() {
    _library.visitChildren(this);

    // Update the tree based on the methods that need checks.
    for (var field in _privateFields) {
      if (!_checkedMembers.contains(field)) {
        field.isCovariant = false;
        field.isGenericCovariantImpl = false;
      }
    }
    void clearCovariant(VariableDeclaration parameter) {
      parameter.isCovariant = false;
      parameter.isGenericCovariantImpl = false;
    }

    for (var member in _privateProcedures) {
      if (!_checkedMembers.contains(member)) {
        var function = member.function;
        function.positionalParameters.forEach(clearCovariant);
        function.namedParameters.forEach(clearCovariant);
        for (var t in function.typeParameters) {
          t.isGenericCovariantImpl = false;
        }
      }
    }
  }

  /// Checks if [target] is a private member called through a [receiver] that
  /// will potentially need a covariance check.
  ///
  /// If the member needs a check it will be stored in [_checkedMembers].
  ///
  /// See [transform] for more information.
  void _checkTarget(Expression receiver, Member target) {
    if (target != null &&
        target.name.isPrivate &&
        target.isInstanceMember &&
        receiver is! ThisExpression &&
        receiver is! ConstructorInvocation) {
      assert(target.enclosingLibrary == _library,
          'call to private member must be in same library');
      _checkedMembers.add(target);
    }
  }

  /// Checks if [target] is a tearoff of a private member.
  ///
  /// In this case we will need a covariance check, because the method could
  /// escape, and it also has a different runtime type.
  ///
  /// See [transform] for more information.
  void _checkTearoff(Member target) {
    if (target != null &&
        target.name.isPrivate &&
        target.isInstanceMember &&
        target is Procedure &&
        !target.isAccessor) {
      assert(target.enclosingLibrary == _library,
          'tearoff of private member must be in same library');
      _checkedMembers.add(target);
    }
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.name.isPrivate && node.isInstanceMember && node.function != null) {
      _privateProcedures.add(node);
    }
    super.visitProcedure(node);
  }

  @override
  void visitField(Field node) {
    if (node.name.isPrivate && isCovariantField(node)) _privateFields.add(node);
    super.visitField(node);
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    _checkTearoff(node.interfaceTarget);
    super.visitPropertyGet(node);
  }

  @override
  void visitDirectPropertyGet(DirectPropertyGet node) {
    _checkTearoff(node.target);
    super.visitDirectPropertyGet(node);
  }

  @override
  void visitPropertySet(PropertySet node) {
    _checkTarget(node.receiver, node.interfaceTarget);
    super.visitPropertySet(node);
  }

  @override
  void visitDirectPropertySet(DirectPropertySet node) {
    _checkTarget(node.receiver, node.target);
    super.visitDirectPropertySet(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkTarget(node.receiver, node.interfaceTarget);
    super.visitMethodInvocation(node);
  }

  @override
  void visitDirectMethodInvocation(DirectMethodInvocation node) {
    _checkTarget(node.receiver, node.target);
    super.visitDirectMethodInvocation(node);
  }
}
