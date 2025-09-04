// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

import '../../js_interop_checks.dart' show JsInteropChecks;
import '../js_interop.dart'
    show
        annotationClass,
        getJSName,
        hasAnonymousAnnotation,
        hasDartJSInteropAnnotation,
        hasJSInteropAnnotation,
        hasNativeAnnotation,
        hasStaticInteropAnnotation,
        hasTrustTypesAnnotation;

/// For any external static interop member, we can replace the call site
/// (invocation) with an expression that calls the target, update the external
/// member to be a stub that does the external call, do both, or do
/// nothing. Collectively, these actions are called the [_Treatment] for a
/// static interop member.
///
/// The treatment holds a closure to perform each of the actions (building a
/// replacement or updating the definition).  The treatment is computed once per
/// [Procedure] and reused when visiting the definition and call-sites of the
/// same static interop member. Recomputing information about the same member is
/// avoided - using a cached [_Treatment] that holds a cached closure allows the
/// closure to retain information rather than recompute it.
final class _Treatment {
  final _InvocationBuilder? _builder;
  final void Function(Procedure)? _update;

  const _Treatment._(this._builder, this._update);
  _Treatment.replace(this._builder) : _update = null;
  _Treatment.update(this._update) : _builder = null;

  static const _Treatment none = _Treatment._(null, null);
}

/// Function type that given an [Expression], which is an invocation of a static
/// interop member, and the list of [Arguments] to that invocation, returns an
/// [Expression] that inlines the static interop member call.
typedef _InvocationBuilder =
    Expression Function(Arguments arguments, Expression invocation);

/// Replaces js_util methods with inline calls to foreign_helper JS which
/// emits the code as a JavaScript code fragment.
class JsUtilOptimizer extends Transformer {
  final Procedure _allowInteropTarget;
  final Iterable<Procedure> _allowedInteropJsUtilTargets;
  final Procedure _callMethodTarget;
  final Procedure _callMethodTrustTypeTarget;
  final List<Procedure> _callMethodUncheckedTargets;
  final List<Procedure> _callMethodUncheckedTrustTypeTargets;
  final Procedure _callConstructorTarget;
  final List<Procedure> _callConstructorUncheckedTargets;
  final Procedure _functionToJSTarget;
  final Procedure _functionToJSCaptureThisTarget;
  final List<Procedure> _functionToJSTargets;
  final List<Procedure>? _functionToJSCaptureThisTargets;
  final Procedure _functionToJSNTarget;
  final Procedure _functionToJSCaptureThisNTarget;
  final Procedure _getPropertyTarget;
  final Procedure _getPropertyTrustTypeTarget;
  final Procedure _globalContextTarget;
  final Procedure _jsExportedDartFunctionToDartTarget;
  final Procedure _jsFunctionToDart;
  final Procedure _jsTarget;
  final Procedure _listEmptyFactory;
  final InterfaceType _objectType;
  final Procedure _setPropertyTarget;
  final Procedure _setPropertyUncheckedTarget;

  final CoreTypes _coreTypes;
  final CloneVisitorNotMembers _cloner = CloneVisitorWithMembers();
  final ExtensionIndex _extensionIndex;
  final Map<Member, _Treatment> _treatments = {};
  final StatefulStaticTypeContext _staticTypeContext;

  final bool isDart2JS;

  /// Dynamic members in js_util that interop allowed.
  static const List<String> _allowedInteropJsUtilMembers = [
    'callConstructor',
    'callMethod',
    'getProperty',
    'jsify',
    'newObject',
    'setProperty',
  ];

  JsUtilOptimizer(
    this._coreTypes,
    ClassHierarchy hierarchy,
    this._extensionIndex, {
    required this.isDart2JS,
  }) : _callMethodTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         'callMethod',
       ),
       _callMethodTrustTypeTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         '_callMethodTrustType',
       ),
       _callMethodUncheckedTargets = List<Procedure>.generate(
         5,
         (i) => _coreTypes.index.getTopLevelProcedure(
           'dart:js_util',
           '_callMethodUnchecked$i',
         ),
       ),
       _callMethodUncheckedTrustTypeTargets = List<Procedure>.generate(
         5,
         (i) => _coreTypes.index.getTopLevelProcedure(
           'dart:js_util',
           '_callMethodUncheckedTrustType$i',
         ),
       ),
       _callConstructorTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         'callConstructor',
       ),
       _callConstructorUncheckedTargets = List<Procedure>.generate(
         5,
         (i) => _coreTypes.index.getTopLevelProcedure(
           'dart:js_util',
           '_callConstructorUnchecked$i',
         ),
       ),
       _functionToJSTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_interop',
         'FunctionToJSExportedDartFunction|get#toJS',
       ),
       _functionToJSCaptureThisTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_interop',
         'FunctionToJSExportedDartFunction|get#toJSCaptureThis',
       ),
       _functionToJSTargets = List<Procedure>.generate(
         6,
         (i) => _coreTypes.index.getTopLevelProcedure(
           'dart:js_util',
           '_functionToJS$i',
         ),
       ),
       _functionToJSCaptureThisTargets = isDart2JS
           ? List<Procedure>.generate(
               5,
               (i) => _coreTypes.index.getTopLevelProcedure(
                 'dart:js_util',
                 '_functionToJSCaptureThis$i',
               ),
             )
           : null,
       _functionToJSNTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         '_functionToJSN',
       ),
       _functionToJSCaptureThisNTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         '_functionToJSCaptureThisN',
       ),
       _getPropertyTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         'getProperty',
       ),
       _getPropertyTrustTypeTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         '_getPropertyTrustType',
       ),
       _globalContextTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:_js_helper',
         'get:staticInteropGlobalContext',
       ),
       _jsExportedDartFunctionToDartTarget = _coreTypes.index
           .getTopLevelProcedure(
             'dart:js_interop',
             'JSExportedDartFunctionToFunction|get#toDart',
           ),
       _jsFunctionToDart = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         '_jsFunctionToDart',
       ),
       _objectType = hierarchy.coreTypes.objectNonNullableRawType,
       _setPropertyTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         'setProperty',
       ),
       _setPropertyUncheckedTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         '_setPropertyUnchecked',
       ),
       _jsTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:_foreign_helper',
         'JS',
       ),
       _allowInteropTarget = _coreTypes.index.getTopLevelProcedure(
         'dart:js_util',
         'allowInterop',
       ),
       _allowedInteropJsUtilTargets = _allowedInteropJsUtilMembers.map(
         (member) =>
             _coreTypes.index.getTopLevelProcedure('dart:js_util', member),
       ),
       _listEmptyFactory = _coreTypes.index.getProcedure(
         'dart:core',
         'List',
         'empty',
       ),
       _staticTypeContext = StatefulStaticTypeContext.stacked(
         TypeEnvironment(_coreTypes, hierarchy),
       );

  _Treatment _treatmentFor(Procedure member) {
    return _treatments[member] ??= _treatmentForProcedure(member);
  }

  @override
  TreeNode visitLibrary(Library node) {
    _staticTypeContext.enterLibrary(node);
    node.transformChildren(this);
    _staticTypeContext.leaveLibrary(node);
    return node;
  }

  @override
  TreeNode defaultMember(Member node) {
    _staticTypeContext.enterMember(node);
    node.transformChildren(this);
    _staticTypeContext.leaveMember(node);
    return node;
  }

  @override
  TreeNode visitProcedure(Procedure node) {
    _staticTypeContext.enterMember(node);
    if (node.isExternal &&
        node.isStatic &&
        !JsInteropChecks.isPatchedMember(node)) {
      final update = _treatmentFor(node)._update;
      if (update != null) update(node);
    }
    node.transformChildren(this);
    _staticTypeContext.leaveMember(node);
    return node;
  }

  /// Given a static interop procedure [node], return a
  /// [_Treatment] that will create new [StaticInvocation]s that
  /// replace calls to [node], or update the procedure with a synthesized body.
  ///
  /// If [node] is not one of several static interop members, this function
  /// returns [_Treatment.none].
  _Treatment _treatmentForProcedure(Procedure node) {
    if (!node.isExternal) return _Treatment.none;

    if (_extensionIndex.isInstanceInteropMember(node)) {
      var shouldTrustType = _extensionIndex.isTrustTypesMember(node);
      if (_extensionIndex.isGetter(node)) {
        return _getExternalGetterTreatment(node, shouldTrustType);
      } else if (_extensionIndex.isSetter(node)) {
        return _getExternalSetterTreatment(node);
      } else if (_extensionIndex.isMethod(node)) {
        return _getExternalMethodTreatment(node, shouldTrustType);
      } else if (_extensionIndex.isOperator(node)) {
        return _getExternalOperatorTreatment(node, shouldTrustType);
      }
    } else {
      // Do the lowerings for top-levels, static class members, and
      // constructors/factories.
      var prefixSelectors = _getPrefixSelectorsForStaticallyResolvableMember(
        node,
      );

      if (prefixSelectors != null) {
        var receiver = _getNestedValueInGlobalContext(prefixSelectors);
        var shouldTrustType =
            node.enclosingClass != null &&
            hasTrustTypesAnnotation(node.enclosingClass!);
        if (_extensionIndex.isGetter(node)) {
          return _getExternalGetterTreatment(node, shouldTrustType, receiver);
        } else if (_extensionIndex.isSetter(node)) {
          return _getExternalSetterTreatment(node, receiver);
        } else if (_extensionIndex.isMethod(node)) {
          return _getExternalMethodTreatment(node, shouldTrustType, receiver);
        } else if (_extensionIndex.isNonLiteralConstructor(node)) {
          // Get the constructor object using the class name.
          return _getExternalConstructorTreatment(node, receiver);
        }
      }
    }
    return _Treatment.none;
  }

  /// Returns the prefixed selectors for the given [node] using the enclosing
  /// library's and enclosing type's (if any) `@JS` values.
  ///
  /// Returns null if [node] is not external and one of:
  /// 1. A top-level member
  /// 2. A `@staticInterop` factory
  /// 3. A `@staticInterop` static member
  /// 4. A `@JS` extension type constructor
  /// 5. A `@JS` extension type static member
  List<String>? _getPrefixSelectorsForStaticallyResolvableMember(
    Procedure node,
  ) {
    if (!node.isExternal || node.isExtensionMember) return null;

    final libraryName = getJSName(node.enclosingLibrary);
    final librarySelectors = libraryName.isEmpty
        ? <String>[]
        : libraryName.split('.');

    if (!node.isExtensionTypeMember && node.enclosingClass == null) {
      // Top-level.
      if (hasDartJSInteropAnnotation(node) ||
          hasDartJSInteropAnnotation(node.enclosingLibrary)) {
        return librarySelectors;
      }
      return null;
    } else {
      // Type member.
      Annotatable enclosingType;
      if (node.isExtensionTypeMember) {
        final descriptor = _extensionIndex.getExtensionTypeDescriptor(node);
        if (descriptor == null ||
            (!descriptor.isStatic &&
                descriptor.kind != ExtensionTypeMemberKind.Constructor &&
                descriptor.kind != ExtensionTypeMemberKind.Factory)) {
          return null;
        }
        enclosingType = _extensionIndex.getExtensionType(node)!;
      } else if (node.enclosingClass != null &&
          hasStaticInteropAnnotation(node.enclosingClass!)) {
        if (!node.isFactory && !node.isStatic) return null;
        enclosingType = node.enclosingClass!;
      } else {
        return null;
      }
      // If `@staticInterop` or `@JS` extension type factory/constructor/static
      // member, add the type name to the dotted prefix.
      var typeName = getJSName(enclosingType);
      if (typeName.isEmpty) {
        typeName = enclosingType is Class
            ? enclosingType.name
            : (enclosingType as ExtensionTypeDeclaration).name;
      }
      return [...librarySelectors, ...typeName.split('.')];
    }
  }

  // TODO(srujzs): It feels weird to have this be public, but it's weirder to
  // have this method elsewhere for now. Figure out a better place for this.
  /// Given two `@JS` values, combines them into a concatenated name using '.'.
  ///
  /// If either parameters are empty, returns the other.
  static String concatenateJSNames(String prefix, String suffix) {
    if (prefix.isEmpty) return suffix;
    if (suffix.isEmpty) return prefix;
    return '$prefix.$suffix';
  }

  /// Given an initial JS value, [jsValue], for each property in [selectors],
  /// creates an expression that fetches the property value from the previously
  /// fetched JS value.
  ///
  /// The property accesses are unchecked.
  ///
  /// If [selectors] is empty, returns [jsValue]. Otherwise, returns the nested
  /// expression.
  Expression _getNestedValueInJSValue(
    List<String> selectors,
    Expression jsValue,
  ) {
    for (String selector in selectors) {
      jsValue = StaticInvocation(
        _getPropertyTrustTypeTarget,
        Arguments([jsValue, StringLiteral(selector)], types: [_objectType]),
      );
    }
    return jsValue;
  }

  Expression _getNestedValueInGlobalContext(List<String> selectors) =>
      _getNestedValueInJSValue(selectors, StaticGet(_globalContextTarget));

  /// Convert a procedure from an external method to a stub method with [value]
  /// as the expression body.
  void _convertToStubWithExpression(Procedure node, Expression value) {
    assert(node.isExternal);
    final body = ReturnStatement(value)..fileOffset = node.fileOffset;
    node.function.body = body;
    body.parent = node.function;
    node.isExternal = false;
  }

  /// Returns a new [_Treatment] for the given [node] external getter.
  ///
  /// The builder will return an [Expression] that will call the optimized
  /// version of `js_util.getProperty` for the given external getter. If
  /// [shouldTrustType] is true, the builder creates a variant that does not
  /// check the return type. If [staticReceiver] is non-null, the builder uses
  /// that instead of the first positional argument as the receiver for
  /// `js_util.getProperty`. If the member has an `@JS` rename that contains
  /// multiple selectors, fetches the value right before the last selector using
  /// `js_util.getPropertyTrustType` and treats that as the receiver, similar to
  /// library or type renames.
  _Treatment _getExternalGetterTreatment(
    Procedure node,
    bool shouldTrustType, [
    Expression? staticReceiver,
  ]) {
    final target = shouldTrustType
        ? _getPropertyTrustTypeTarget
        : _getPropertyTarget;
    final isInstanceMember = _extensionIndex.isInstanceInteropMember(node);
    assert(isInstanceMember == (staticReceiver == null));
    final selectors = _getMemberJSNameSelectors(node);
    final name = selectors.removeLast();
    if (!isInstanceMember) {
      // Receiver is known ahead of time, so pre-compute.
      staticReceiver = _getNestedValueInJSValue(selectors, staticReceiver!);
      selectors.clear();
    }

    if (_preferStub(node)) {
      // Update procedure to be a stub with a synthesized body
      //
      //     => getProperty{TrustType}<T>(receiver, "name")
      //
      return _Treatment.update((Procedure procedure) {
        assert(node == procedure);
        final function = node.function;
        final (receiver, positional) = _splitOutReceiver(staticReceiver, [
          if (staticReceiver == null)
            VariableGet(function.positionalParameters.single),
        ], selectors);
        assert(positional.isEmpty);
        final property = StringLiteral(name);
        final expression = StaticInvocation(
          target,
          Arguments([receiver, property], types: [function.returnType]),
        )..fileOffset = node.fileOffset;
        _convertToStubWithExpression(node, expression);
      });
    }

    // The default treatment is to inline at all calls.
    return _Treatment.replace((Arguments arguments, Expression invocation) {
      final (receiver, positional) = _splitOutReceiver(
        staticReceiver,
        arguments.positional,
        selectors,
      );
      assert(positional.isEmpty);
      final property = StringLiteral(name);
      return StaticInvocation(
          target,
          Arguments(
            [receiver, property],
            types: [invocation.getStaticType(_staticTypeContext)],
          ),
        )
        ..fileOffset = invocation.fileOffset
        ..parent = invocation.parent;
    });
  }

  /// Returns a new [_Treatment] for the given [node] external setter.
  ///
  /// The builder will return an [Expression] that will call the optimized
  /// version of `js_util.setProperty` for the given external setter. If
  /// [staticReceiver] is non-null, the builder uses that instead of the first
  /// positional argument as the receiver for `js_util.setProperty`. If the
  /// member has an `@JS` rename that contains multiple selectors, fetches the
  /// value right before the last selector using `js_util.getPropertyTrustType`
  /// and treats that as the receiver, similar to library or type renames.
  _Treatment _getExternalSetterTreatment(
    Procedure node, [
    Expression? staticReceiver,
  ]) {
    final target = _setPropertyTarget;
    final isInstanceMember = _extensionIndex.isInstanceInteropMember(node);
    assert(isInstanceMember == (staticReceiver == null));
    final selectors = _getMemberJSNameSelectors(node);
    final name = selectors.removeLast();
    if (!isInstanceMember) {
      // Receiver is known ahead of time, so pre-compute.
      staticReceiver = _getNestedValueInJSValue(selectors, staticReceiver!);
      selectors.clear();
    }

    if (_preferStub(node)) {
      // Update procedure to be a stub with a synthesized body
      //
      //     => _setProperty<T>(receiver, "name", value);
      //
      return _Treatment.update((Procedure procedure) {
        assert(node == procedure);
        final function = node.function;
        final (receiver, positional) = _splitOutReceiver(staticReceiver, [
          ...function.positionalParameters.map(VariableGet.new),
        ], selectors);
        assert(positional.length == 1);
        final property = StringLiteral(name);
        final value = positional.single;
        final setterMethodInvocation = StaticInvocation(
          target,
          Arguments(
            [receiver, property, value],
            types: [value.getStaticType(_staticTypeContext)],
          ),
        )..fileOffset = node.fileOffset;
        _convertToStubWithExpression(node, setterMethodInvocation);
        // [_lowerSetProperty] called when transformer visits synthesized body.
      });
    }

    return _Treatment.replace((Arguments arguments, Expression invocation) {
      final (receiver, positional) = _splitOutReceiver(
        staticReceiver,
        arguments.positional,
        selectors,
      );
      assert(positional.length == 1);
      final property = StringLiteral(name);
      final value = positional.single;
      return _lowerSetProperty(
        StaticInvocation(
            target,
            Arguments(
              [receiver, property, value],
              types: [value.getStaticType(_staticTypeContext)],
            ),
          )
          ..fileOffset = invocation.fileOffset
          ..parent = invocation.parent,
      );
    });
  }

  /// Returns a new [_Treatment] for the given [node] external method.
  ///
  /// The builder will return an [Expression] that will call the optimized
  /// version of `js_util.callMethod` for the given external method. If
  /// [shouldTrustType] is true, the builder creates a variant that does not
  /// check the return type. If [staticReceiver] is non-null, the builder uses
  /// that instead of the first positional argument as the receiver for
  /// `js_util.callMethod`.  If the member has an `@JS` rename that contains
  /// multiple selectors, fetches the value right before the last selector using
  /// `js_util.getPropertyTrustType` and treats that as the receiver, similar to
  /// library or type renames.
  _Treatment _getExternalMethodTreatment(
    Procedure node,
    bool shouldTrustType, [
    Expression? staticReceiver,
  ]) {
    final target = shouldTrustType
        ? _callMethodTrustTypeTarget
        : _callMethodTarget;
    final isInstanceMember = _extensionIndex.isInstanceInteropMember(node);
    assert(isInstanceMember == (staticReceiver == null));
    final selectors = _getMemberJSNameSelectors(node);
    final name = selectors.removeLast();
    if (!isInstanceMember) {
      // Receiver is known ahead of time, so pre-compute.
      staticReceiver = _getNestedValueInJSValue(selectors, staticReceiver!);
      selectors.clear();
    }

    if (_preferStub(node) &&
        // Can only convert to a stub for fixed number of positional arguments.
        node.function.namedParameters.isEmpty &&
        node.function.positionalParameters.length ==
            node.function.requiredParameterCount) {
      // Update procedure to be a stub with a synthesized body
      //
      //     => _callMethod{TrustType}<T>(receiver, "name", [arguments])
      //
      return _Treatment.update((Procedure procedure) {
        assert(node == procedure);
        final function = node.function;
        final (receiver, positional) = _splitOutReceiver(staticReceiver, [
          ...function.positionalParameters.map(VariableGet.new),
        ], selectors);
        final callMethodInvocation = StaticInvocation(
          target,
          Arguments(
            [receiver, StringLiteral(name), ListLiteral(positional)],
            types: [function.returnType],
          ),
        )..fileOffset = node.fileOffset;
        _convertToStubWithExpression(node, callMethodInvocation);
        // [_lowerCallMethod] called when transformer visits synthesized body.
      });
    }

    return _Treatment.replace((Arguments arguments, Expression invocation) {
      final (receiver, positional) = _splitOutReceiver(
        staticReceiver,
        arguments.positional,
        selectors,
      );
      final callMethodInvocation =
          StaticInvocation(
              target,
              Arguments(
                [receiver, StringLiteral(name), ListLiteral(positional)],
                types: [invocation.getStaticType(_staticTypeContext)],
              ),
            )
            ..fileOffset = invocation.fileOffset
            ..parent = invocation.parent;
      return _lowerCallMethod(
        callMethodInvocation,
        shouldTrustType: shouldTrustType,
      );
    });
  }

  /// For dart2js we generate a stub if the method has a `pragma` annotation so
  /// that the annotations are not erased by lowering the call.
  bool _preferStub(Procedure node) {
    if (isDart2JS) {
      final annotations = node.annotations;
      if (annotations.any(_isPragma)) return true;
      // TODO(sra): Are there other annotations we want to preserve?
    }
    return false;
  }

  static bool _isPragma(Expression value) {
    final cls = annotationClass(value);
    return cls != null &&
        cls.name == 'pragma' &&
        cls.enclosingLibrary.importUri == _dartCore;
  }

  static final _dartCore = Uri.parse('dart:core');

  /// Given a potentially null static receiver and the [positional] arguments to
  /// a JS interop call, returns the actual receiver and arguments.
  ///
  /// The receiver for the call is either the provided static receiver (a
  /// statically resolvable namespace/type), or the first argument provided to a
  /// static extension or extension type method.
  ///
  /// If [selectors] is not empty, fetches the value off of the receiver using
  /// those selectors and returns the result as the new receiver.
  (Expression, List<Expression>) _splitOutReceiver(
    Expression? staticReceiver,
    List<Expression> positional,
    List<String> selectors,
  ) {
    var (receiver, arguments) = staticReceiver == null
        ? (positional.first, positional.sublist(1))
        // We clone the static receiver as each invocation needs a fresh node.
        : (_cloner.clone(staticReceiver), positional);
    receiver = _getNestedValueInJSValue(selectors, receiver);
    return (receiver, arguments);
  }

  /// Returns a new [_Treatment] for the [node] external operator.
  ///
  /// This function only supports '[]' and '[]=' for now.
  _Treatment _getExternalOperatorTreatment(
    Procedure node,
    bool shouldTrustType,
  ) {
    final operator =
        _extensionIndex.getExtensionTypeDescriptor(node)?.name.text ??
        _extensionIndex.getExtensionDescriptor(node)?.name.text;

    // TODO(srujzs): Support more operators for overloading using some
    // combination of Dart-defineable operators and @JS renaming for the ones
    // that are not renameable.
    final Procedure target;
    StaticInvocation Function(StaticInvocation)? invocationOptimizer;
    switch (operator) {
      case '[]':
        target = shouldTrustType
            ? _getPropertyTrustTypeTarget
            : _getPropertyTarget;
        break;
      case '[]=':
        target = _setPropertyTarget;
        invocationOptimizer = _lowerSetProperty;
        break;
      default:
        throw UnimplementedError(
          'External operator $operator is unsupported for static interop. ',
        );
    }

    return _Treatment.replace((Arguments arguments, Expression invocation) {
      final replacement =
          StaticInvocation(
              target,
              Arguments(
                arguments.positional,
                types: [invocation.getStaticType(_staticTypeContext)],
              ),
            )
            ..fileOffset = invocation.fileOffset
            ..parent = invocation.parent;
      return invocationOptimizer != null
          ? invocationOptimizer(replacement)
          : replacement;
    });
  }

  /// Returns a new [_Treatment] for the given [node] external non-object
  /// literal factory.
  ///
  /// The builder will return an [Expression] that will call the optimized
  /// version of `js_util.callConstructor` using the given [constructor] and the
  /// [Arguments] of the [Expression] that calls [node].
  _Treatment _getExternalConstructorTreatment(
    Procedure node,
    Expression constructor,
  ) {
    final function = node.function;
    assert(function.namedParameters.isEmpty);
    return _Treatment.replace((Arguments arguments, Expression invocation) {
      final callConstructorInvocation =
          StaticInvocation(
              _callConstructorTarget,
              Arguments(
                [_cloner.clone(constructor), ListLiteral(arguments.positional)],
                types: [invocation.getStaticType(_staticTypeContext)],
              ),
            )
            ..fileOffset = invocation.fileOffset
            ..parent = invocation.parent;
      return _lowerCallConstructor(callConstructorInvocation);
    });
  }

  /// Returns a new list containing the underlying JS name, split by '.'.
  ///
  /// Uses the name from the `@JS` annotation if non-empty and the declared name
  /// of the member otherwise.
  ///
  /// In the case of an extension or extension type member, this does not return
  /// the CFE generated name for the top level member, but rather the name of
  /// the original member.
  List<String> _getMemberJSNameSelectors(Procedure node) {
    var name = getJSName(node);
    if (name.isEmpty) {
      if (node.isExtensionMember) {
        name = _extensionIndex.getExtensionDescriptor(node)!.name.text;
      } else if (node.isExtensionTypeMember) {
        name = _extensionIndex.getExtensionTypeDescriptor(node)!.name.text;
      } else {
        name = node.name.text;
      }
    }
    return name.split('.');
  }

  /// Replaces js_util method and static interop member calls with optimization
  /// when possible.
  ///
  /// - Lowers `setProperty` to  `_setPropertyUnchecked` for values that are
  /// not Function type and guaranteed to be interop allowed.
  /// - Lowers `callMethod` to `_callMethodUncheckedN` when the number of given
  /// arguments is 0-4 and all arguments are guaranteed to be interop allowed.
  /// - Lowers `callConstructor` to `_callConstructorUncheckedN` when there are
  /// 0-4 arguments and all arguments are guaranteed to be interop allowed.
  /// - Computes and caches a [_Treatment] for a given non-custom static interop
  ///   invocation, and then calls that builder to replace the current [node].
  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    Expression invocation = node;
    final target = node.target;
    if (target == _setPropertyTarget) {
      invocation = _lowerSetProperty(node);
    } else if (target == _callMethodTarget) {
      // Never trust types on explicit `js_util` calls.
      invocation = _lowerCallMethod(node, shouldTrustType: false);
    } else if (target == _callConstructorTarget) {
      invocation = _lowerCallConstructor(node);
      // TODO(srujzs): Delete the `isPatchedMember` check once
      // https://github.com/dart-lang/sdk/issues/53367 is resolved.
    } else if (target == _functionToJSTarget) {
      invocation = _lowerFunctionToJS(node);
    } else if (target == _functionToJSCaptureThisTarget) {
      invocation = _lowerFunctionToJS(node, captureThis: true);
    } else if (target == _jsExportedDartFunctionToDartTarget) {
      invocation = _lowerJSExportedDartFunctionToDart(node);
    } else if (target.isExternal && !JsInteropChecks.isPatchedMember(target)) {
      final builder = _treatmentFor(target)._builder;
      if (builder != null) invocation = builder(node.arguments, node);
    }
    invocation.transformChildren(this);
    return invocation;
  }

  @override
  TreeNode visitStaticGet(StaticGet node) {
    Expression invocation = node;
    final target = node.target;
    if (target.isExternal && target is Procedure) {
      // Reference to a static interop getter declared as static. Note that we
      // provide no arguments as static getters do not have a 'this'.
      final builder = _treatmentFor(target)._builder;
      if (builder != null) invocation = builder(Arguments([]), node);
    }
    invocation.transformChildren(this);
    return invocation;
  }

  @override
  TreeNode visitStaticSet(StaticSet node) {
    Expression invocation = node;
    final target = node.target;
    if (target.isExternal && target is Procedure) {
      // Reference to a static interop setter declared as static. Note that we
      // provide only the value as static setters do not have a 'this'.
      final builder = _treatmentFor(target)._builder;
      if (builder != null) invocation = builder(Arguments([node.value]), node);
    }
    invocation.transformChildren(this);
    return invocation;
  }

  /// Lowers the given js_util `setProperty` call to `_setPropertyUnchecked`
  /// when the additional validation checks in `setProperty` can be elided.
  ///
  /// Removing the checks allows further inlining by the compilers.
  StaticInvocation _lowerSetProperty(StaticInvocation node) {
    Arguments arguments = node.arguments;
    assert(arguments.positional.length == 3);
    assert(arguments.named.isEmpty);

    if (!_allowedInterop(arguments.positional.last)) {
      return node;
    }

    return StaticInvocation(_setPropertyUncheckedTarget, arguments)
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
  }

  /// Lowers the given js_util `callMethod` call to `_callMethodUncheckedN`
  /// when the additional validation checks on the arguments can be elided.
  ///
  /// Calls will be lowered when using a List literal or constant list with 0-4
  /// elements for the `callMethod` arguments, or the `List.empty()` factory.
  /// Removing the checks allows further inlining by the compilers.
  StaticInvocation _lowerCallMethod(
    StaticInvocation node, {
    required bool shouldTrustType,
  }) {
    Arguments arguments = node.arguments;
    assert(arguments.positional.length == 3);
    assert(arguments.named.isEmpty);
    List<Procedure> targets = shouldTrustType
        ? _callMethodUncheckedTrustTypeTargets
        : _callMethodUncheckedTargets;

    return _lowerToCallUnchecked(
      node,
      targets,
      arguments.positional.sublist(0, 2),
    );
  }

  /// Lowers the given js_util `callConstructor` call to
  /// `_callConstructorUncheckedN` when the additional validation checks on the
  /// arguments can be elided.
  ///
  /// Calls will be lowered when using a List literal or constant list with 0-4
  /// elements for the `callConstructor` arguments, or the `List.empty()`
  /// factory. Removing the checks allows further inlining by the compilers.
  StaticInvocation _lowerCallConstructor(StaticInvocation node) {
    Arguments arguments = node.arguments;
    assert(arguments.positional.length == 2);
    assert(arguments.named.isEmpty);

    return _lowerToCallUnchecked(node, _callConstructorUncheckedTargets, [
      arguments.positional.first,
    ]);
  }

  /// Helper to lower the given [node] to the relevant unchecked target in the
  /// [callUncheckedTargets] based on whether the validation checks on the
  /// [originalArguments] can be elided.
  ///
  /// Calls will be lowered when using a List literal or constant list with 0-4
  /// arguments, or the `List.empty()` factory. Removing the checks allows further
  /// inlining by the compilers.
  StaticInvocation _lowerToCallUnchecked(
    StaticInvocation node,
    List<Procedure> callUncheckedTargets,
    List<Expression> originalArguments,
  ) {
    var argumentsList = node.arguments.positional.last;
    // Lower arguments in a List.empty factory call.
    if (argumentsList is StaticInvocation &&
        argumentsList.target == _listEmptyFactory) {
      return _createCallUncheckedNode(
        callUncheckedTargets,
        node.arguments.types,
        [],
        originalArguments,
        node.fileOffset,
        node.parent,
        node.arguments.fileOffset,
      );
    }

    // Lower arguments in other kinds of Lists.
    List<Expression> callUncheckedArguments;
    DartType entryType;
    if (argumentsList is ListLiteral) {
      if (argumentsList.expressions.length >= callUncheckedTargets.length) {
        return node;
      }
      callUncheckedArguments = argumentsList.expressions;
      entryType = argumentsList.typeArgument;
    } else if (argumentsList is ConstantExpression &&
        argumentsList.constant is ListConstant) {
      var argumentsListConstant = argumentsList.constant as ListConstant;
      if (argumentsListConstant.entries.length >= callUncheckedTargets.length) {
        return node;
      }
      callUncheckedArguments = argumentsListConstant.entries
          .map<Expression>(
            (constant) => ConstantExpression(
              constant,
              constant.getType(_staticTypeContext),
            ),
          )
          .toList();
      entryType = argumentsListConstant.typeArgument;
    } else {
      // Skip lowering arguments in any other type of List.
      return node;
    }

    // Check the arguments List type, then verify each argument if needed.
    if (!_allowedInteropType(entryType)) {
      for (var argument in callUncheckedArguments) {
        if (!_allowedInterop(argument)) {
          return node;
        }
      }
    }

    return _createCallUncheckedNode(
      callUncheckedTargets,
      node.arguments.types,
      callUncheckedArguments,
      originalArguments,
      node.fileOffset,
      node.parent,
      node.arguments.fileOffset,
    );
  }

  /// Creates a new StaticInvocation node for the relevant unchecked target
  /// with the given 0-4 arguments.
  StaticInvocation _createCallUncheckedNode(
    List<Procedure> callUncheckedTargets,
    List<DartType> callUncheckedTypes,
    List<Expression> callUncheckedArguments,
    List<Expression> originalArguments,
    int nodeFileOffset,
    TreeNode? nodeParent,
    int argumentsFileOffset,
  ) {
    assert(callUncheckedArguments.length <= 4);
    return StaticInvocation(
        callUncheckedTargets[callUncheckedArguments.length],
        Arguments([
          ...originalArguments,
          ...callUncheckedArguments,
        ], types: callUncheckedTypes)..fileOffset = argumentsFileOffset,
      )
      ..fileOffset = nodeFileOffset
      ..parent = nodeParent;
  }

  /// For the given `dart:js_interop` `Function.toJS` or
  /// `Function.toJSCaptureThis` invocation [node], returns an invocation of the
  /// corresponding private stub in `js_util` with the invocation's [Function]
  /// argument and the number of positional parameters of that [Function].
  ///
  /// If [captureThis] is false, the node target is assumed to be
  /// `Function.toJS` and otherwise `Function.toJSCaptureThis`.
  ///
  /// There are specialized stubs up to a certain positional parameter length,
  /// and after that, either an invocation of `_functionToJSN` or
  /// `_functionToJSCaptureThisN` is returned.
  StaticInvocation _lowerFunctionToJS(
    StaticInvocation node, {
    bool captureThis = false,
  }) {
    // JS interop checks assert that the static type is available, and that
    // there are no named arguments or type arguments.
    final function = node.arguments.positional.single;
    final functionType =
        function.getStaticType(_staticTypeContext) as FunctionType;
    final parametersLength = functionType.positionalParameters.length;
    List<Procedure>? specializedStubs;
    int stubIndex;
    Procedure genericStub;
    if (captureThis) {
      specializedStubs = _functionToJSCaptureThisTargets;
      stubIndex = parametersLength - 1; // Account for `this`.
      genericStub = _functionToJSCaptureThisNTarget;
    } else {
      specializedStubs = _functionToJSTargets;
      stubIndex = parametersLength;
      genericStub = _functionToJSNTarget;
    }
    Procedure target;
    Arguments arguments;
    if (specializedStubs != null &&
        stubIndex >= 0 &&
        stubIndex < specializedStubs.length) {
      target = specializedStubs[stubIndex];
      arguments = Arguments([function]);
    } else {
      target = genericStub;
      arguments = Arguments([function, IntLiteral(parametersLength)]);
    }
    return StaticInvocation(
        target,
        arguments..fileOffset = node.arguments.fileOffset,
      )
      ..fileOffset = node.fileOffset
      ..parent = node.parent;
  }

  /// For the given `dart:js_interop` `JSExportedDartFunction.toDart` invocation
  /// [node], returns an invocation of `_jsFunctionToDart` with the given
  /// `JSExportedDartFunction` argument.
  StaticInvocation _lowerJSExportedDartFunctionToDart(StaticInvocation node) =>
      StaticInvocation(
          _jsFunctionToDart,
          Arguments([node.arguments.positional[0]])
            ..fileOffset = node.arguments.fileOffset,
        )
        ..fileOffset = node.fileOffset
        ..parent = node.parent;

  /// Returns whether the given [node] is guaranteed to be allowed to interop
  /// with JS.
  ///
  /// [node] is guaranteed to be allowed to interop with JS if:
  /// - It is guaranteed to not be a function or is an allowlisted type.
  /// - It is an invocation of any of the allowed methods:
  ///   - dart:_foreign_helper JS
  ///   - dart:js `allowInterop`
  ///   - dart:js_util and any of the `_allowedInteropJsUtilMembers`
  bool _allowedInterop(Expression node) {
    // TODO(rileyporter): Detect functions that have been wrapped at some point
    // with `allowInterop`
    if (node is StaticInvocation) {
      if (node.target == _allowInteropTarget) return true;
      if (node.target == _jsTarget) return true;
      if (_allowedInteropJsUtilTargets.contains(node.target)) return true;
    }

    return _allowedInteropType(node.getStaticType(_staticTypeContext));
  }

  /// Returns whether the given [type] is either a type that is guaranteed to
  /// not be a function or is an allowlisted type that can flow to JS without
  /// needing to be checked.
  bool _allowedInteropType(DartType type) {
    // Static interop types and `ExternalDartReference` are allowlisted because
    // even though types like `JSAny` and `ExternalDartReference`, which are
    // actually `Object` underneath, can actually be Dart functions, that is
    // either true if there was a deliberate cast (which is linted and
    // platform-inconsistent) or it's meant to be used as an opaque reference.
    // To avoid a slower code path when using these types, we allowlist them.
    if (_extensionIndex.isStaticInteropType(type) ||
        _extensionIndex.isExternalDartReferenceType(type)) {
      return true;
    }
    type = type.extensionTypeErasure;
    // TODO(srujzs): We should check for type parameters and dynamic.
    if (type is InterfaceType) {
      return type.classNode != _coreTypes.functionClass &&
          type.classNode != _coreTypes.objectClass;
    } else {
      // Only other DartType guaranteed to not be a function.
      return type is NullType;
    }
  }
}

/// Lazily-initialized indexes for extension and extension type interop members.
///
/// As the query APIs are called, we process the enclosing libraries of the
/// member in question if needed. We only process JS interop extension types and
/// extensions on either JS interop or @Native classes.
class ExtensionIndex {
  final Map<Reference, Reference?> _coreInteropTypeIndex = {};
  final Map<Reference, Annotatable> _extensionAnnotatableIndex = {};
  final Map<Reference, Extension> _extensionIndex = {};
  final Map<Reference, ExtensionMemberDescriptor> _extensionMemberIndex = {};
  final Map<Reference, Reference> _extensionTearOffIndex = {};
  final Map<Reference, ExtensionTypeDeclaration> _extensionTypeIndex = {};
  final Map<Reference, ExtensionTypeMemberDescriptor>
  _extensionTypeMemberIndex = {};
  final Map<Reference, Reference> _extensionTypeTearOffIndex = {};
  final Set<Reference> _externalDartReferences = {};
  final Class? _javaScriptObject;
  final Set<Library> _processedExtensionLibraries = {};
  final Set<Library> _processedExtensionTypeLibraries = {};
  final Set<Reference> _shouldTrustType = {};
  final TypeEnvironment _typeEnvironment;

  ExtensionIndex(CoreTypes coreTypes, this._typeEnvironment)
    : _javaScriptObject = coreTypes.index.tryGetClass(
        'dart:_interceptors',
        'JavaScriptObject',
      );

  /// If unprocessed, for all extension members in [library] whose on-type is a
  /// JS interop or `@Native` class, does the following:
  ///
  /// - Maps the member to its on-type in `_extensionAnnotatableIndex`.
  /// - Maps the member to its extension in `_extensionIndex`.
  /// - Maps the member to its descriptor in `_extensionMemberIndex`.
  /// - Adds the member to `_shouldTrustTypes` if the on-type has a
  /// `@trustTypes` annotation.
  /// - Maps the tear-off member to the member it tears off in
  /// `extensionTearOffIndex`.
  void _indexExtensions(Library library) {
    if (_processedExtensionLibraries.contains(library)) return;
    for (var extension in library.extensions) {
      for (var descriptor in extension.memberDescriptors) {
        var reference = descriptor.memberReference!;
        var onType = extension.onType;
        bool isInteropOnType = false;
        Annotatable? cls;
        if (onType is InterfaceType) {
          cls = onType.classNode;
          // For now, `@trustTypes` can only be used on classes and not
          // extension types.
          if (hasTrustTypesAnnotation(cls)) {
            _shouldTrustType.add(reference);
          }
          isInteropOnType =
              hasJSInteropAnnotation(cls) || hasNativeAnnotation(cls);
        } else if (onType is ExtensionType) {
          final extensionType = onType.extensionTypeDeclaration;
          cls = extensionType;
          isInteropOnType = isInteropExtensionType(extensionType);
        }
        if (!isInteropOnType) continue;

        _extensionMemberIndex[reference] = descriptor;
        _extensionAnnotatableIndex[reference] = cls!;
        _extensionIndex[reference] = extension;
        final tearOffReference = descriptor.tearOffReference;
        if (tearOffReference != null) {
          _extensionMemberIndex[tearOffReference] = descriptor;
          _extensionIndex[tearOffReference] = extension;
          _extensionAnnotatableIndex[reference] = cls;
          _extensionTearOffIndex[tearOffReference] = reference;
        }
      }
    }
    _processedExtensionLibraries.add(library);
  }

  Annotatable? getExtensionAnnotatable(Member member) {
    if (!member.isExtensionMember) return null;
    _indexExtensions(member.enclosingLibrary);
    return _extensionAnnotatableIndex[member.reference];
  }

  Extension? getExtension(Member member) {
    if (!member.isExtensionMember) return null;
    _indexExtensions(member.enclosingLibrary);
    return _extensionIndex[member.reference];
  }

  ExtensionMemberDescriptor? getExtensionDescriptor(Member member) {
    if (!member.isExtensionMember) return null;
    _indexExtensions(member.enclosingLibrary);
    return _extensionMemberIndex[member.reference];
  }

  bool isTrustTypesMember(Member member) {
    if (!member.isExtensionMember) return false;
    _indexExtensions(member.enclosingLibrary);
    return _shouldTrustType.contains(member.reference);
  }

  Reference? getExtensionMemberForTearOff(Member member) {
    if (!member.isExtensionMember) return null;
    _indexExtensions(member.enclosingLibrary);
    return _extensionTearOffIndex[member.reference];
  }

  /// Returns whether [extensionType] is an "interop extension type".
  ///
  /// Interop extension types have either another interop extension type or a
  /// "core" interop type (see below) as their representation type. Extension
  /// types can only declare external JS interop members if they are interop
  /// extension types.
  bool isInteropExtensionType(ExtensionTypeDeclaration extensionType) {
    return getCoreInteropType(
          // Nullability is irrelevant for this purpose.
          ExtensionType(extensionType, Nullability.undetermined),
        ) !=
        null;
  }

  /// Returns the "core" interop type of [type], unwrapping extension types as
  /// needed and caching along the way.
  ///
  /// A type is a "core" interop type if it is:
  /// - a `dart:js_interop` extension type
  /// - a `@staticInterop` type
  /// - an `@Native` type that <: `JavaScriptObject`. Note that this excludes
  ///   `dart:typed_data`, as typed list factories return a type that is
  ///   <: `JavaScriptObject`, but the typed lists themselves are not such a
  ///   type. This is expected and intended since unlike `dart:html`,
  ///   `dart:typed_data` can be used in dart2wasm, and since we do not want
  ///   typed lists to be considered interoperable there, it makes sense to
  ///   exclude them here.
  ///
  /// If [type] is allowed and is an extension type, it is an interop extension
  /// type as well.
  ///
  /// Returns `null` if there is no [type] that neither wraps nor is a "core"
  /// interop type.
  Reference? getCoreInteropType(DartType type) {
    if (type is ExtensionType) {
      final declaration = type.extensionTypeDeclaration;
      final reference = declaration.reference;
      if (_coreInteropTypeIndex.containsKey(reference)) {
        return _coreInteropTypeIndex[reference];
      }
      if (isJSType(declaration)) {
        return _coreInteropTypeIndex[reference] = reference;
      }
      // Note that we recurse instead of using the erasure, as JS types are
      // extension types.
      return _coreInteropTypeIndex[reference] = getCoreInteropType(
        declaration.declaredRepresentationType,
      );
    } else if (type is InterfaceType) {
      final cls = type.classNode;
      final reference = cls.reference;
      if (hasStaticInteropAnnotation(cls) ||
          (_javaScriptObject != null &&
              hasNativeAnnotation(cls) &&
              _typeEnvironment.isSubtypeOf(
                type,
                InterfaceType(_javaScriptObject, Nullability.nullable),
              ))) {
        return _coreInteropTypeIndex[reference] = reference;
      }
    }
    return null;
  }

  bool isAllowedRepresentationType(DartType type) =>
      getCoreInteropType(type) != null;

  /// If unprocessed, for all extension type members in [library] whose
  /// extension type is static interop, does the following:
  ///
  /// - Maps the extension type to its interop type
  /// - Maps the member to its extension type in `_extensionTypeIndex`.
  /// - Maps the member to its descriptor in `_extensionTypeMemberIndex`.
  /// - Maps the tear-off member to the member it tears off in
  /// `_extensionTearOffIndex`.
  void _indexExtensionTypes(Library library) {
    if (_processedExtensionTypeLibraries.contains(library)) return;
    for (var extensionType in library.extensionTypeDeclarations) {
      if (isInteropExtensionType(extensionType)) {
        for (var descriptor in extensionType.memberDescriptors) {
          final reference = descriptor.memberReference!;
          _extensionTypeMemberIndex[reference] = descriptor;
          _extensionTypeIndex[reference] = extensionType;
          final tearOffReference = descriptor.tearOffReference;
          if (tearOffReference != null) {
            _extensionTypeMemberIndex[tearOffReference] = descriptor;
            _extensionTypeIndex[tearOffReference] = extensionType;
            _extensionTypeTearOffIndex[tearOffReference] = reference;
          }
        }
      }
    }
    _processedExtensionTypeLibraries.add(library);
  }

  ExtensionTypeMemberDescriptor? getExtensionTypeDescriptor(Member member) {
    if (!member.isExtensionTypeMember) return null;
    _indexExtensionTypes(member.enclosingLibrary);
    return _extensionTypeMemberIndex[member.reference];
  }

  ExtensionTypeDeclaration? getExtensionType(Member member) {
    if (!member.isExtensionTypeMember) return null;
    _indexExtensionTypes(member.enclosingLibrary);
    return _extensionTypeIndex[member.reference];
  }

  Reference? getExtensionTypeMemberForTearOff(Member member) {
    if (!member.isExtensionTypeMember) return null;
    _indexExtensionTypes(member.enclosingLibrary);
    return _extensionTypeTearOffIndex[member.reference];
  }

  /// Return whether [node] is either an extension member that's declared as
  /// non-`static` or an extension type member that's declared as non-`static`
  /// and is not a factory or constructor.
  bool isInstanceInteropMember(Member node) {
    if (node.isExtensionMember) {
      var descriptor = getExtensionDescriptor(node);
      return descriptor != null && !descriptor.isStatic;
    } else if (node.isExtensionTypeMember) {
      var descriptor = getExtensionTypeDescriptor(node);
      return descriptor != null &&
          !descriptor.isStatic &&
          descriptor.kind != ExtensionTypeMemberKind.Constructor &&
          descriptor.kind != ExtensionTypeMemberKind.Factory;
    }
    return false;
  }

  bool _isOneOfKinds(
    Procedure node,
    ExtensionTypeMemberKind extensionTypeKind,
    ExtensionMemberKind extensionKind,
    ProcedureKind procedureKind,
  ) {
    if (node.isExtensionTypeMember) {
      return getExtensionTypeDescriptor(node)?.kind == extensionTypeKind;
    } else if (node.isExtensionMember) {
      return getExtensionDescriptor(node)?.kind == extensionKind;
    } else {
      return node.kind == procedureKind;
    }
  }

  bool isGetter(Procedure node) => _isOneOfKinds(
    node,
    ExtensionTypeMemberKind.Getter,
    ExtensionMemberKind.Getter,
    ProcedureKind.Getter,
  );

  bool isSetter(Procedure node) => _isOneOfKinds(
    node,
    ExtensionTypeMemberKind.Setter,
    ExtensionMemberKind.Setter,
    ProcedureKind.Setter,
  );

  bool isMethod(Procedure node) => _isOneOfKinds(
    node,
    ExtensionTypeMemberKind.Method,
    ExtensionMemberKind.Method,
    ProcedureKind.Method,
  );

  bool isOperator(Procedure node) => _isOneOfKinds(
    node,
    ExtensionTypeMemberKind.Operator,
    ExtensionMemberKind.Operator,
    ProcedureKind.Operator,
  );

  /// Given an interop extension type or extension member [node], gets the
  /// function type as written.
  ///
  /// Extension type and extension instance members include the instance as the
  /// first positional parameter of the generated function. Since this was never
  /// written by the user, it is excluded in the resulting function type.
  ///
  /// If not an interop extension type or extension member, returns null.
  FunctionType? getFunctionType(Procedure node) {
    if (getExtensionDescriptor(node) == null &&
        getExtensionTypeDescriptor(node) == null) {
      return null;
    }

    final functionType =
        node.signatureType ??
        node.function.computeFunctionType(Nullability.nonNullable);
    var positionalParameters = functionType.positionalParameters;
    if (isInstanceInteropMember(node)) {
      // Ignore the instance parameter.
      positionalParameters = positionalParameters.skip(1).toList();
    }
    return FunctionType(
      positionalParameters,
      functionType.returnType,
      functionType.declaredNullability,
      namedParameters: functionType.namedParameters,
      typeParameters: functionType.typeParameters,
      requiredParameterCount: functionType.requiredParameterCount,
    );
  }

  /// Return whether [node] is an external static interop constructor/factory.
  ///
  /// If [literal] is true, we check if [node] is an object literal constructor,
  /// and if not, we check that it's a non-literal constructor.
  bool _isStaticInteropConstructor(Procedure node, {required bool literal}) {
    if (!node.isExternal) return false;
    if (node.isExtensionTypeMember) {
      final kind = getExtensionTypeDescriptor(node)?.kind;
      final namedParams = node.function.namedParameters;
      return (kind == ExtensionTypeMemberKind.Constructor ||
              kind == ExtensionTypeMemberKind.Factory) &&
          (literal ? namedParams.isNotEmpty : namedParams.isEmpty);
    } else if (node.kind == ProcedureKind.Factory &&
        node.enclosingClass != null &&
        hasJSInteropAnnotation(node.enclosingClass!)) {
      final isAnonymous = hasAnonymousAnnotation(node.enclosingClass!);
      return literal ? isAnonymous : !isAnonymous;
    }
    return false;
  }

  bool isLiteralConstructor(Procedure node) =>
      _isStaticInteropConstructor(node, literal: true);

  bool isNonLiteralConstructor(Procedure node) =>
      _isStaticInteropConstructor(node, literal: false);

  bool isStaticInteropType(DartType type) {
    if (type is InterfaceType) {
      return hasStaticInteropAnnotation(type.classNode);
    } else if (type is ExtensionType) {
      return isInteropExtensionType(type.extensionTypeDeclaration);
    } else if (type is TypeParameterType || type is StructuralParameterType) {
      return isStaticInteropType(type.nonTypeParameterBound);
    }
    return false;
  }

  bool isJSType(ExtensionTypeDeclaration decl) =>
      decl.enclosingLibrary.importUri.toString() == 'dart:js_interop' &&
      decl.name.startsWith('JS');

  bool isExternalDartReference(ExtensionTypeDeclaration decl) =>
      decl.enclosingLibrary.importUri.toString() == 'dart:js_interop' &&
      decl.name == 'ExternalDartReference';

  bool isExternalDartReferenceType(DartType type) {
    if (type is ExtensionType) {
      final decl = type.extensionTypeDeclaration;
      if (_externalDartReferences.contains(decl.reference)) return true;
      if (isExternalDartReference(decl) ||
          isExternalDartReferenceType(decl.declaredRepresentationType)) {
        _externalDartReferences.add(decl.reference);
        return true;
      }
    } else if (type is TypeParameterType || type is StructuralParameterType) {
      return isExternalDartReferenceType(type.nonTypeParameterBound);
    }
    return false;
  }
}
