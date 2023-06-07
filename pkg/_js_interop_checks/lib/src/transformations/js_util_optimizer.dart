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
        getJSName,
        hasAnonymousAnnotation,
        hasDartJSInteropAnnotation,
        hasJSInteropAnnotation,
        hasNativeAnnotation,
        hasStaticInteropAnnotation,
        hasTrustTypesAnnotation;

/// Function type that given an [Expression], which is an invocation of a static
/// interop member, and the list of [Arguments] to that invocation, returns an
/// [Expression] that inlines the static interop member call.
///
/// In order to avoid recomputing information about the same static interop
/// member, we utilize closures that contain a lot of that information already.
/// We compute one [_InvocationBuilder] per node, and reuse as needed for
/// multiple invocations of the same static interop member.
typedef _InvocationBuilder = Expression Function(
    Arguments arguments, Expression invocation);

/// Replaces js_util methods with inline calls to foreign_helper JS which
/// emits the code as a JavaScript code fragment.
class JsUtilOptimizer extends Transformer {
  final Procedure _callMethodTarget;
  final Procedure _callMethodTrustTypeTarget;
  final List<Procedure> _callMethodUncheckedTargets;
  final List<Procedure> _callMethodUncheckedTrustTypeTargets;
  final Procedure _callConstructorTarget;
  final List<Procedure> _callConstructorUncheckedTargets;
  final CloneVisitorNotMembers _cloner = CloneVisitorWithMembers();
  final Map<Member, _InvocationBuilder?> _externalInvocationBuilders = {};
  final Procedure _getPropertyTarget;
  final Procedure _getPropertyTrustTypeTarget;
  final Procedure _globalThisTarget;
  final InterfaceType _objectType;
  final Procedure _setPropertyTarget;
  final Procedure _setPropertyUncheckedTarget;

  /// Dynamic members in js_util that interop allowed.
  static final Iterable<String> _allowedInteropJsUtilMembers = <String>[
    'callConstructor',
    'callMethod',
    'getProperty',
    'jsify',
    'newObject',
    'setProperty'
  ];
  final Iterable<Procedure> _allowedInteropJsUtilTargets;
  final Procedure _jsTarget;
  final Procedure _allowInteropTarget;
  final Procedure _listEmptyFactory;

  final CoreTypes _coreTypes;
  final StatefulStaticTypeContext _staticTypeContext;

  final InlineExtensionIndex _inlineExtensionIndex = InlineExtensionIndex();

  JsUtilOptimizer(this._coreTypes, ClassHierarchy hierarchy)
      : _callMethodTarget =
            _coreTypes.index.getTopLevelProcedure('dart:js_util', 'callMethod'),
        _callMethodTrustTypeTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', '_callMethodTrustType'),
        _callMethodUncheckedTargets = List<Procedure>.generate(
            5,
            (i) => _coreTypes.index.getTopLevelProcedure(
                'dart:js_util', '_callMethodUnchecked$i')),
        _callMethodUncheckedTrustTypeTargets = List<Procedure>.generate(
            5,
            (i) => _coreTypes.index.getTopLevelProcedure(
                'dart:js_util', '_callMethodUncheckedTrustType$i')),
        _callConstructorTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'callConstructor'),
        _callConstructorUncheckedTargets = List<Procedure>.generate(
            5,
            (i) => _coreTypes.index.getTopLevelProcedure(
                'dart:js_util', '_callConstructorUnchecked$i')),
        _getPropertyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'getProperty'),
        _getPropertyTrustTypeTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', '_getPropertyTrustType'),
        _globalThisTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'get:globalThis'),
        _objectType = hierarchy.coreTypes.objectNonNullableRawType,
        _setPropertyTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'setProperty'),
        _setPropertyUncheckedTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', '_setPropertyUnchecked'),
        _jsTarget =
            _coreTypes.index.getTopLevelProcedure('dart:_foreign_helper', 'JS'),
        _allowInteropTarget = _coreTypes.index
            .getTopLevelProcedure('dart:js_util', 'allowInterop'),
        _allowedInteropJsUtilTargets = _allowedInteropJsUtilMembers.map(
            (member) =>
                _coreTypes.index.getTopLevelProcedure('dart:js_util', member)),
        _listEmptyFactory =
            _coreTypes.index.getProcedure('dart:core', 'List', 'empty'),
        _staticTypeContext = StatefulStaticTypeContext.stacked(
            TypeEnvironment(_coreTypes, hierarchy));

  @override
  visitLibrary(Library node) {
    _staticTypeContext.enterLibrary(node);
    node.transformChildren(this);
    _staticTypeContext.leaveLibrary(node);
    return node;
  }

  @override
  defaultMember(Member node) {
    _staticTypeContext.enterMember(node);
    node.transformChildren(this);
    _staticTypeContext.leaveMember(node);
    return node;
  }

  /// Given a static interop procedure [node], return a
  /// [_InvocationBuilder] that will create new [StaticInvocation]s that
  /// replace calls to [node].
  ///
  /// If [node] is not one of several static interop members, this function
  /// returns null.
  _InvocationBuilder? _getExternalInvocationBuilder(Procedure node) {
    if (node.isExternal) {
      if (_inlineExtensionIndex.isInstanceInteropMember(node)) {
        var shouldTrustType = _inlineExtensionIndex.isTrustTypesMember(node);
        if (_inlineExtensionIndex.isGetter(node)) {
          return _getExternalGetterInvocationBuilder(node, shouldTrustType);
        } else if (_inlineExtensionIndex.isSetter(node)) {
          return _getExternalSetterInvocationBuilder(node);
        } else if (_inlineExtensionIndex.isMethod(node)) {
          return _getExternalMethodInvocationBuilder(node, shouldTrustType);
        } else if (_inlineExtensionIndex.isOperator(node)) {
          return _getExternalOperatorInvocationBuilder(node, shouldTrustType);
        }
      } else {
        // Do the lowerings for top-levels, static class members, and
        // constructors/factories.
        var dottedPrefix = _getDottedPrefixForStaticallyResolvableMember(node);
        if (dottedPrefix != null) {
          var receiver = _getObjectOffGlobalThis(
              node, dottedPrefix.isEmpty ? [] : dottedPrefix.split('.'));
          var shouldTrustType = node.enclosingClass != null &&
              hasTrustTypesAnnotation(node.enclosingClass!);
          if (_inlineExtensionIndex.isGetter(node)) {
            return _getExternalGetterInvocationBuilder(
                node, shouldTrustType, receiver);
          } else if (_inlineExtensionIndex.isSetter(node)) {
            return _getExternalSetterInvocationBuilder(node, receiver);
          } else if (_inlineExtensionIndex.isMethod(node)) {
            return _getExternalMethodInvocationBuilder(
                node, shouldTrustType, receiver);
          } else if (_inlineExtensionIndex.isNonLiteralConstructor(node)) {
            // Get the constructor object using the class name.
            return _getExternalConstructorInvocationBuilder(
                node, _getObjectOffGlobalThis(node, dottedPrefix.split('.')));
          }
        }
      }
    }
    return null;
  }

  /// Returns the prefixed JS name for the given [node] using the enclosing
  /// library's, enclosing class' (if any), and member's `@JS` values.
  ///
  /// Returns null if [node] is not external and one of:
  /// 1. A top-level member
  /// 2. A `@staticInterop` factory
  /// 3. A `@staticInterop` static member
  /// 4. A `@JS` inline class constructor
  /// 5. A `@JS` inline class static member
  String? _getDottedPrefixForStaticallyResolvableMember(Procedure node) {
    if (!node.isExternal || node.isExtensionMember) return null;

    var dottedPrefix = getJSName(node.enclosingLibrary);

    if (!node.isInlineClassMember &&
        node.enclosingClass == null &&
        (hasDartJSInteropAnnotation(node) ||
            hasDartJSInteropAnnotation(node.enclosingLibrary))) {
      // If the `@JS` value of the node has any '.'s, we take the entries
      // before the last '.' to determine the dotted prefix name.
      var jsName = getJSName(node);
      if (jsName.isNotEmpty) {
        var lastDotIndex = jsName.lastIndexOf('.');
        if (lastDotIndex != -1) {
          dottedPrefix = _concatenateJSNames(
              dottedPrefix, jsName.substring(0, lastDotIndex));
        }
      }
    } else {
      Annotatable enclosingClass;
      if (node.isInlineClassMember) {
        var descriptor = _inlineExtensionIndex.getInlineDescriptor(node);
        if (descriptor == null ||
            (!descriptor.isStatic &&
                descriptor.kind != InlineClassMemberKind.Constructor &&
                descriptor.kind != InlineClassMemberKind.Factory)) {
          return null;
        }
        enclosingClass = _inlineExtensionIndex.getInlineClass(node)!;
      } else if (node.enclosingClass != null &&
          hasStaticInteropAnnotation(node.enclosingClass!)) {
        if (!node.isFactory && !node.isStatic) return null;
        enclosingClass = node.enclosingClass!;
      } else {
        return null;
      }
      // `@staticInterop` or `@JS` inline class
      // factory/constructor/static member, use the class name as part of the
      // dotted prefix.
      var className = getJSName(enclosingClass);
      if (className.isEmpty) {
        className = enclosingClass is Class
            ? enclosingClass.name
            : (enclosingClass as InlineClass).name;
      }
      dottedPrefix = _concatenateJSNames(dottedPrefix, className);
    }
    return dottedPrefix;
  }

  /// Given two `@JS` values, combines them into a concatenated name using '.'.
  ///
  /// If either parameters are empty, returns the other.
  String _concatenateJSNames(String prefix, String suffix) {
    if (prefix.isEmpty) return suffix;
    if (suffix.isEmpty) return prefix;
    return '$prefix.$suffix';
  }

  /// Given a list of strings, [selectors], recursively fetches the property
  /// that corresponds to each string off of the `globalThis` object.
  ///
  /// Returns an expression that contains the nested property gets.
  Expression _getObjectOffGlobalThis(Procedure node, List<String> selectors) {
    Expression currentTarget = StaticGet(_globalThisTarget);
    for (String selector in selectors) {
      currentTarget = StaticInvocation(
          _getPropertyTrustTypeTarget,
          Arguments([currentTarget, StringLiteral(selector)],
              types: [_objectType]));
    }
    return currentTarget;
  }

  /// Returns a new [_InvocationBuilder] for the given [node] external
  /// getter.
  ///
  /// The builder will return an [Expression] that will call the optimized
  /// version of `js_util.getProperty` for the given external getter. If
  /// [shouldTrustType] is true, the builder creates a variant that does not
  /// check the return type. If [maybeReceiver] is non-null, the builder uses
  /// that instead of the first positional argument as the receiver for
  /// `js_util.getProperty`.
  _InvocationBuilder _getExternalGetterInvocationBuilder(
      Procedure node, bool shouldTrustType,
      [Expression? maybeReceiver]) {
    final target =
        shouldTrustType ? _getPropertyTrustTypeTarget : _getPropertyTarget;
    final isOperator = _inlineExtensionIndex.isOperator(node);
    final isInstanceInteropMember =
        _inlineExtensionIndex.isInstanceInteropMember(node);
    final name = _getMemberJSName(node);
    return (Arguments arguments, Expression invocation) {
      // Parameter `this` only exists for inline and extension instance members.
      // Operators take a `this` and an index.
      final positionalArgs = arguments.positional;
      assert(positionalArgs.length ==
          (isOperator
              ? 2
              : isInstanceInteropMember
                  ? 1
                  : 0));
      // We clone the receiver as each invocation needs a fresh node.
      final receiver = maybeReceiver == null
          ? positionalArgs.first
          : _cloner.clone(maybeReceiver);
      final property = isOperator ? positionalArgs[1] : StringLiteral(name);
      return StaticInvocation(
          target,
          Arguments([receiver, property],
              types: [invocation.getStaticType(_staticTypeContext)]))
        ..fileOffset = invocation.fileOffset
        ..parent = invocation.parent;
    };
  }

  /// Returns a new [_InvocationBuilder] for the given [node] external
  /// setter.
  ///
  /// The builder will return an [Expression] that will call the optimized
  /// version of `js_util.setProperty` for the given external setter. If
  /// [maybeReceiver] is non-null, the builder uses that instead of the first
  /// positional argument as the receiver for `js_util.setProperty`.
  _InvocationBuilder _getExternalSetterInvocationBuilder(Procedure node,
      [Expression? maybeReceiver]) {
    final isOperator = _inlineExtensionIndex.isOperator(node);
    final isInstanceInteropMember =
        _inlineExtensionIndex.isInstanceInteropMember(node);
    final name = _getMemberJSName(node);
    return (Arguments arguments, Expression invocation) {
      // Parameter `this` only exists for inline and extension instance members.
      // Operators take a `this`, an index, and a value.
      final positionalArgs = arguments.positional;
      assert(positionalArgs.length ==
          (isOperator
              ? 3
              : isInstanceInteropMember
                  ? 2
                  : 1));
      final receiver = maybeReceiver == null
          ? positionalArgs.first
          : _cloner.clone(maybeReceiver);
      final property = isOperator ? positionalArgs[1] : StringLiteral(name);
      final value = positionalArgs.last;
      return StaticInvocation(
          _setPropertyTarget,
          Arguments([receiver, property, value],
              types: [value.getStaticType(_staticTypeContext)]))
        ..fileOffset = invocation.fileOffset
        ..parent = invocation.parent;
    };
  }

  /// Returns a new [_InvocationBuilder] for the given [node] external
  /// method.
  ///
  /// The builder will return an [Expression] that will call the optimized
  /// version of `js_util.callMethod` for the given external method. If
  /// [shouldTrustType] is true, the builder creates a variant that does not
  /// check the return type. If [maybeReceiver] is non-null, the builder uses
  /// that instead of the first positional argument as the receiver for
  /// `js_util.callMethod`.
  _InvocationBuilder _getExternalMethodInvocationBuilder(
      Procedure node, bool shouldTrustType,
      [Expression? maybeReceiver]) {
    final target =
        shouldTrustType ? _callMethodTrustTypeTarget : _callMethodTarget;
    final isInstanceInteropMember =
        _inlineExtensionIndex.isInstanceInteropMember(node);
    final name = _getMemberJSName(node);
    return (Arguments arguments, Expression invocation) {
      var positional = arguments.positional;
      final receiver = maybeReceiver == null
          ? positional.first
          : _cloner.clone(maybeReceiver);
      if (isInstanceInteropMember) {
        // Ignore `this` for inline and extension members.
        positional = positional.sublist(1);
      }
      final callMethodInvocation = StaticInvocation(
          target,
          Arguments([
            receiver,
            StringLiteral(name),
            ListLiteral(positional),
          ], types: [
            invocation.getStaticType(_staticTypeContext)
          ]))
        ..fileOffset = invocation.fileOffset
        ..parent = invocation.parent;
      return _lowerCallMethod(callMethodInvocation,
          shouldTrustType: shouldTrustType);
    };
  }

  /// Returns a new [_InvocationBuilder] for the [node] external operator.
  ///
  /// This function only supports '[]' and '[]=' for now.
  _InvocationBuilder? _getExternalOperatorInvocationBuilder(
      Procedure node, bool shouldTrustType) {
    final operator =
        _inlineExtensionIndex.getInlineDescriptor(node)?.name.text ??
            _inlineExtensionIndex.getExtensionDescriptor(node)?.name.text;
    switch (operator) {
      case '[]':
        return _getExternalGetterInvocationBuilder(node, shouldTrustType);
      case '[]=':
        return _getExternalSetterInvocationBuilder(node);
      default:
        throw 'External operator $operator is unsupported for static interop.';
    }
  }

  /// Returns a new [_InvocationBuilder] for the given [node] external
  /// non-object literal factory.
  ///
  /// The builder will return an [Expression] that will call the optimized
  /// version of `js_util.callConstructor` using the given [constructor] and the
  /// [Arguments] of the [Expression] that calls [node].
  _InvocationBuilder _getExternalConstructorInvocationBuilder(
      Procedure node, Expression constructor) {
    final function = node.function;
    assert(function.namedParameters.isEmpty);
    return (Arguments arguments, Expression invocation) {
      final callConstructorInvocation = StaticInvocation(
          _callConstructorTarget,
          Arguments(
              [_cloner.clone(constructor), ListLiteral(arguments.positional)],
              types: [invocation.getStaticType(_staticTypeContext)]))
        ..fileOffset = invocation.fileOffset
        ..parent = invocation.parent;
      return _lowerCallConstructor(callConstructorInvocation);
    };
  }

  /// Returns the underlying JS name.
  ///
  /// Returns either the name from the `@JS` annotation if non-empty, or the
  /// declared name of the member. In the case of an extension or inline class
  /// member, this does not return the CFE generated name for the top level
  /// member, but rather the name of the original member.
  String _getMemberJSName(Procedure node) {
    var jsAnnotationName = getJSName(node);
    if (jsAnnotationName.isNotEmpty) {
      // In the case of top-level external members, this may contain '.'. The
      // namespacing before the last '.' should be resolved when we provide a
      // receiver to the lowerings. Here, we just take the final identifier.
      return jsAnnotationName.split('.').last;
    } else if (node.isExtensionMember) {
      return _inlineExtensionIndex.getExtensionDescriptor(node)!.name.text;
    } else if (node.isInlineClassMember) {
      return _inlineExtensionIndex.getInlineDescriptor(node)!.name.text;
    } else {
      return node.name.text;
    }
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
  /// - Computes and caches a [_InvocationBuilder] for a given non-custom static
  /// interop invocation, and then calls that builder to replace the current
  /// [node].
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
    } else if (target.isExternal &&
        !JsInteropChecks.isAllowedCustomStaticInteropImplementation(target)) {
      final builder = _externalInvocationBuilders.putIfAbsent(
          target, () => _getExternalInvocationBuilder(target));
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
      final builder = _externalInvocationBuilders.putIfAbsent(
          target, () => _getExternalInvocationBuilder(target));
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
      final builder = _externalInvocationBuilders.putIfAbsent(
          target, () => _getExternalInvocationBuilder(target));
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
      ..fileOffset = node.fileOffset;
  }

  /// Lowers the given js_util `callMethod` call to `_callMethodUncheckedN`
  /// when the additional validation checks on the arguments can be elided.
  ///
  /// Calls will be lowered when using a List literal or constant list with 0-4
  /// elements for the `callMethod` arguments, or the `List.empty()` factory.
  /// Removing the checks allows further inlining by the compilers.
  StaticInvocation _lowerCallMethod(StaticInvocation node,
      {required bool shouldTrustType}) {
    Arguments arguments = node.arguments;
    assert(arguments.positional.length == 3);
    assert(arguments.named.isEmpty);
    List<Procedure> targets = shouldTrustType
        ? _callMethodUncheckedTrustTypeTargets
        : _callMethodUncheckedTargets;

    return _lowerToCallUnchecked(
        node, targets, arguments.positional.sublist(0, 2));
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

    return _lowerToCallUnchecked(
        node, _callConstructorUncheckedTargets, [arguments.positional.first]);
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
      List<Expression> originalArguments) {
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
          node.arguments.fileOffset);
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
          .map<Expression>((constant) => ConstantExpression(
              constant, constant.getType(_staticTypeContext)))
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
        node.arguments.fileOffset);
  }

  /// Creates a new StaticInvocation node for the relevant unchecked target
  /// with the given 0-4 arguments.
  StaticInvocation _createCallUncheckedNode(
      List<Procedure> callUncheckedTargets,
      List<DartType> callUncheckedTypes,
      List<Expression> callUncheckedArguments,
      List<Expression> originalArguments,
      int nodeFileOffset,
      int argumentsFileOffset) {
    assert(callUncheckedArguments.length <= 4);
    return StaticInvocation(
        callUncheckedTargets[callUncheckedArguments.length],
        Arguments(
          [...originalArguments, ...callUncheckedArguments],
          types: callUncheckedTypes,
        )..fileOffset = argumentsFileOffset)
      ..fileOffset = nodeFileOffset;
  }

  /// Returns whether the given Expression is guaranteed to be allowed to
  /// interop with JS.
  ///
  /// Returns true when the node is guaranteed to be not a function:
  ///    - has a static DartType that is NullType or an InterfaceType that is
  ///      not Function or Object
  /// Also returns true for allowed method calls within the JavaScript domain:
  ///        - dart:_foreign_helper JS
  ///        - dart:js `allowInterop`
  ///        - dart:js_util and any of the `_allowedInteropJsUtilMembers`
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

  /// Returns whether the given DartType is guaranteed to be not a function
  /// and therefore allowed to interop with JS.
  bool _allowedInteropType(DartType type) {
    if (type is InterfaceType) {
      return type.classNode != _coreTypes.functionClass &&
          type.classNode != _coreTypes.objectClass;
    } else {
      // Only other DartType guaranteed to not be a function.
      return type is NullType;
    }
  }
}

/// Lazily-initialized indexes for extension and inline class interop members.
///
/// As the query APIs are called, we process the enclosing libraries of the
/// member in question if needed. We only process JS interop inline classes and
/// extensions on either JS interop or @Native classes.
class InlineExtensionIndex {
  final Map<Reference, Annotatable> _extensionAnnotatableIndex = {};
  final Map<Reference, Extension> _extensionIndex = {};
  final Map<Reference, ExtensionMemberDescriptor> _extensionMemberIndex = {};
  final Map<Reference, Reference> _extensionTearOffIndex = {};
  final Map<Reference, InlineClass> _inlineClassIndex = {};
  final Map<Reference, InlineClassMemberDescriptor> _inlineMemberIndex = {};
  final Map<Reference, Reference> _inlineTearOffIndex = {};
  final Set<Library> _processedExtensionLibraries = {};
  final Set<Library> _processedInlineLibraries = {};
  final Set<Reference> _shouldTrustType = {};

  /// If unprocessed, for all extension members in [library] whose on-type has a
  /// `@JS` or `@Native` annotation, does the following:
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
      // Descriptors of tear-offs have the same name as the member they tear
      // off. This is used to find the tear-offs and their associated member.
      final descriptorNames = <String, ExtensionMemberDescriptor>{};
      for (var descriptor in extension.members) {
        var reference = descriptor.member;
        var onType = extension.onType;
        Annotatable? cls;
        if (onType is InterfaceType) {
          cls = onType.classNode;
          // For now, `@trustTypes` can only be used on non-inline
          // classes.
          if (hasTrustTypesAnnotation(cls)) {
            _shouldTrustType.add(reference);
          }
        } else if (onType is InlineType) {
          cls = onType.inlineClass;
        }
        if (cls == null) continue;
        if (hasJSInteropAnnotation(cls) || hasNativeAnnotation(cls)) {
          _extensionMemberIndex[reference] = descriptor;
          _extensionAnnotatableIndex[reference] = cls;
          _extensionIndex[reference] = extension;
        }
        if (descriptor.kind == ExtensionMemberKind.Method ||
            descriptor.kind == ExtensionMemberKind.TearOff) {
          final descriptorName = descriptor.name.text;
          if (descriptorNames.containsKey(descriptorName)) {
            final previousDesc = descriptorNames[descriptorName]!;
            if (previousDesc.kind == ExtensionMemberKind.TearOff) {
              _extensionTearOffIndex[previousDesc.member] = descriptor.member;
            } else {
              _extensionTearOffIndex[descriptor.member] = previousDesc.member;
            }
          } else {
            descriptorNames[descriptorName] = descriptor;
          }
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

  /// If unprocessed, for all inline class members in [library] whose inline
  /// class has a `@JS` annotation, does the following:
  ///
  /// - Maps the member to its inline class in `_inlineClassIndex`.
  /// - Maps the member to its descriptor in `_inlineMemberIndex`.
  /// - Maps the tear-off member to the member it tears off in
  /// `inlineTearOffIndex`.
  void _indexInlineClasses(Library library) {
    if (_processedInlineLibraries.contains(library)) return;
    for (var inlineClass in library.inlineClasses) {
      if (hasJSInteropAnnotation(inlineClass)) {
        final descriptorNames = <String, InlineClassMemberDescriptor>{};
        for (var descriptor in inlineClass.members) {
          final reference = descriptor.member;
          _inlineMemberIndex[reference] = descriptor;
          _inlineClassIndex[reference] = inlineClass;
          if (descriptor.kind == InlineClassMemberKind.Method ||
              descriptor.kind == InlineClassMemberKind.Constructor ||
              descriptor.kind == InlineClassMemberKind.TearOff) {
            final descriptorName = descriptor.name.text;
            if (descriptorNames.containsKey(descriptorName)) {
              final previousDesc = descriptorNames[descriptorName]!;
              if (previousDesc.kind == InlineClassMemberKind.TearOff) {
                _inlineTearOffIndex[previousDesc.member] = descriptor.member;
              } else {
                _inlineTearOffIndex[descriptor.member] = previousDesc.member;
              }
            } else {
              descriptorNames[descriptorName] = descriptor;
            }
          }
        }
      }
    }
    _processedInlineLibraries.add(library);
  }

  InlineClassMemberDescriptor? getInlineDescriptor(Member member) {
    if (!member.isInlineClassMember) return null;
    _indexInlineClasses(member.enclosingLibrary);
    return _inlineMemberIndex[member.reference];
  }

  InlineClass? getInlineClass(Member member) {
    if (!member.isInlineClassMember) return null;
    _indexInlineClasses(member.enclosingLibrary);
    return _inlineClassIndex[member.reference];
  }

  Reference? getInlineMemberForTearOff(Member member) {
    // Constructor tear-offs are not marked as inline members, so we don't check
    // if [member] is an inline class member.
    _indexInlineClasses(member.enclosingLibrary);
    return _inlineTearOffIndex[member.reference];
  }

  /// Return whether [node] is either an extension member that's declared as
  /// non-`static` or an inline class member that's declared as non-`static`
  /// and is not a factory or constructor.
  bool isInstanceInteropMember(Member node) {
    if (node.isExtensionMember) {
      var descriptor = getExtensionDescriptor(node);
      return descriptor != null && !descriptor.isStatic;
    } else if (node.isInlineClassMember) {
      var descriptor = getInlineDescriptor(node);
      return descriptor != null &&
          !descriptor.isStatic &&
          descriptor.kind != InlineClassMemberKind.Constructor &&
          descriptor.kind != InlineClassMemberKind.Factory;
    }
    return false;
  }

  bool _isOneOfKinds(Procedure node, InlineClassMemberKind inlineKind,
      ExtensionMemberKind extensionKind, ProcedureKind procedureKind) {
    if (node.isInlineClassMember) {
      return getInlineDescriptor(node)?.kind == inlineKind;
    } else if (node.isExtensionMember) {
      return getExtensionDescriptor(node)?.kind == extensionKind;
    } else {
      return node.kind == procedureKind;
    }
  }

  bool isGetter(Procedure node) => _isOneOfKinds(
      node,
      InlineClassMemberKind.Getter,
      ExtensionMemberKind.Getter,
      ProcedureKind.Getter);

  bool isSetter(Procedure node) => _isOneOfKinds(
      node,
      InlineClassMemberKind.Setter,
      ExtensionMemberKind.Setter,
      ProcedureKind.Setter);

  bool isMethod(Procedure node) => _isOneOfKinds(
      node,
      InlineClassMemberKind.Method,
      ExtensionMemberKind.Method,
      ProcedureKind.Method);

  bool isOperator(Procedure node) => _isOneOfKinds(
      node,
      InlineClassMemberKind.Operator,
      ExtensionMemberKind.Operator,
      ProcedureKind.Operator);

  /// Return whether [node] is an external static interop constructor/factory.
  ///
  /// If [literal] is true, we check if [node] is an object literal constructor,
  /// and if not, we check that it's a non-literal constructor.
  bool _isStaticInteropConstructor(Procedure node, {required bool literal}) {
    if (!node.isExternal) return false;
    if (node.isInlineClassMember) {
      final kind = getInlineDescriptor(node)?.kind;
      final namedParams = node.function.namedParameters;
      return (kind == InlineClassMemberKind.Constructor ||
                  kind == InlineClassMemberKind.Factory) &&
              literal
          ? namedParams.isNotEmpty
          : namedParams.isEmpty;
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
}
