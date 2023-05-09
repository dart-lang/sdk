// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

import '../js_interop.dart'
    show
        getJSName,
        hasAnonymousAnnotation,
        hasDartJSInteropAnnotation,
        hasJSInteropAnnotation,
        hasNativeAnnotation,
        hasObjectLiteralAnnotation,
        hasStaticInteropAnnotation,
        hasTrustTypesAnnotation;

enum _MethodSpecializationType {
  constructor,
  method,
}

class _MethodCallSiteSpecialization {
  final bool shouldTrustType;
  final Expression? maybeReceiver;
  final _MethodSpecializationType type;

  _MethodCallSiteSpecialization(
      this.shouldTrustType, this.maybeReceiver, this.type);
}

/// Replaces js_util methods with inline calls to foreign_helper JS which
/// emits the code as a JavaScript code fragment.
class JsUtilOptimizer extends Transformer {
  final Procedure _callMethodTarget;
  final Procedure _callMethodTrustTypeTarget;
  final List<Procedure> _callMethodUncheckedTargets;
  final List<Procedure> _callMethodUncheckedTrustTypeTargets;
  final Procedure _callConstructorTarget;
  final List<Procedure> _callConstructorUncheckedTargets;
  final Procedure _getPropertyTarget;
  final Procedure _getPropertyTrustTypeTarget;
  final Procedure _globalThisTarget;
  final InterfaceType _objectType;
  final Procedure _setPropertyTarget;
  final Procedure _setPropertyUncheckedTarget;
  final Map<Procedure, _MethodCallSiteSpecialization> _proceduresToSpecialize =
      {};

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

  // TODO(joshualitt): Here and in `js_runtime_generator.dart`, there is
  // complexity related to the fact that we lower procedures, and also
  // specialize invocations. We need to do the latter to cleanly support
  // optional parameters, and we currently do the former to support tearoffs.
  // However, the tearoffs will not be consistent with the specialized
  // invocations, and this may be confusing. We should consider disallowing
  // tearoffs of external procedures, which will ensure consistency.
  bool tryTransformProcedure(Procedure node) {
    if (_proceduresToSpecialize.containsKey(node)) {
      return true;
    }
    ReturnStatement? transformedBody;
    if (node.isExternal) {
      if (_inlineExtensionIndex.isInstanceInteropMember(node)) {
        var shouldTrustType = _inlineExtensionIndex.isTrustTypesMember(node);
        if (_inlineExtensionIndex.isGetter(node)) {
          transformedBody = _getExternalGetterBody(node, shouldTrustType);
        } else if (_inlineExtensionIndex.isSetter(node)) {
          transformedBody = _getExternalSetterBody(node);
        } else if (_inlineExtensionIndex.isMethod(node)) {
          transformedBody = _getExternalMethodBody(node, shouldTrustType);
        } else if (_inlineExtensionIndex.isOperator(node)) {
          transformedBody = _getExternalOperatorBody(node, shouldTrustType);
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
            transformedBody =
                _getExternalGetterBody(node, shouldTrustType, receiver);
          } else if (_inlineExtensionIndex.isSetter(node)) {
            transformedBody = _getExternalSetterBody(node, receiver);
          } else if (_inlineExtensionIndex.isMethod(node)) {
            transformedBody =
                _getExternalMethodBody(node, shouldTrustType, receiver);
          } else if (_isNonLiteralConstructor(node)) {
            transformedBody = _getExternalConstructorBody(
                node,
                // Get the constructor object using the class name.
                _getObjectOffGlobalThis(node, dottedPrefix.split('.')));
          }
        }
      }
    }
    if (transformedBody != null) {
      node.function.body = transformedBody;
      transformedBody.parent = node.function;
      node.isExternal = false;
      return true;
    }
    return false;
  }

  @override
  visitProcedure(Procedure node) {
    _staticTypeContext.enterMember(node);
    if (!tryTransformProcedure(node)) {
      node.transformChildren(this);
    }
    _staticTypeContext.leaveMember(node);
    return node;
  }

  bool _isNonLiteralConstructor(Procedure node) {
    if (node.isInlineClassMember) {
      var kind = _inlineExtensionIndex.getInlineDescriptor(node)?.kind;
      return (kind == InlineClassMemberKind.Constructor ||
              kind == InlineClassMemberKind.Factory) &&
          !hasObjectLiteralAnnotation(node);
    } else {
      return node.kind == ProcedureKind.Factory &&
          node.enclosingClass != null &&
          !hasAnonymousAnnotation(node.enclosingClass!);
    }
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
    if (!node.isExternal) return null;

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
    Expression currentTarget = StaticGet(_globalThisTarget)
      ..fileOffset = node.fileOffset;
    for (String selector in selectors) {
      currentTarget = StaticInvocation(
          _getPropertyTrustTypeTarget,
          Arguments([currentTarget, StringLiteral(selector)],
              types: [_objectType]))
        ..fileOffset = node.fileOffset;
    }
    return currentTarget;
  }

  /// Returns a new function body for the given [node] external getter.
  ///
  /// The new function body will call the optimized version of
  /// `js_util.getProperty` for the given external getter. If [shouldTrustType]
  /// is true, we call a variant that does not check the return type. If
  /// [maybeReceiver] is non-null, we use that instead of the first positional
  /// parameter as the receiver for `js_util.getProperty`.
  ReturnStatement _getExternalGetterBody(Procedure node, bool shouldTrustType,
      [Expression? maybeReceiver]) {
    var function = node.function;
    // Parameter `this` only exists for inline and extension instance members.
    // Operators take a `this` and an index.
    final positionalParameters = function.positionalParameters;
    bool isOperator = _inlineExtensionIndex.isOperator(node);
    assert(positionalParameters.length ==
        (isOperator
            ? 2
            : _inlineExtensionIndex.isInstanceInteropMember(node)
                ? 1
                : 0));
    Procedure target =
        shouldTrustType ? _getPropertyTrustTypeTarget : _getPropertyTarget;
    final receiver = maybeReceiver ?? VariableGet(positionalParameters.first);
    final property = isOperator
        ? VariableGet(positionalParameters[1])
        : StringLiteral(_getMemberJSName(node));
    final getPropertyInvocation = StaticInvocation(
        target, Arguments([receiver, property], types: [function.returnType]))
      ..fileOffset = node.fileOffset;
    return ReturnStatement(getPropertyInvocation);
  }

  /// Returns a new function body for the given [node] external setter.
  ///
  /// The new function body will call the optimized version of
  /// `js_util.setProperty` for the given external setter. If [maybeReceiver] is
  /// non-null, we use that instead of the first positional parameter as the
  /// receiver for `js_util.setProperty`.
  ReturnStatement _getExternalSetterBody(Procedure node,
      [Expression? maybeReceiver]) {
    var function = node.function;
    // Parameter `this` only exists for inline and extension instance members.
    // Operators take a `this`, an index, and a value.
    final positionalParameters = function.positionalParameters;
    bool isOperator = _inlineExtensionIndex.isOperator(node);
    assert(positionalParameters.length ==
        (isOperator
            ? 3
            : _inlineExtensionIndex.isInstanceInteropMember(node)
                ? 2
                : 1));
    final receiver = maybeReceiver ?? VariableGet(positionalParameters.first);
    final index = isOperator
        ? VariableGet(positionalParameters[1])
        : StringLiteral(_getMemberJSName(node));
    final value = positionalParameters.last;
    final setPropertyInvocation = StaticInvocation(_setPropertyTarget,
        Arguments([receiver, index, VariableGet(value)], types: [value.type]))
      ..fileOffset = node.fileOffset;
    return ReturnStatement(_lowerSetProperty(setPropertyInvocation));
  }

  /// Returns a new function body for the given [node] external method.
  ///
  /// The new function body will call the optimized version of
  /// `js_util.callMethod` for the given external method. If [shouldTrustType]
  /// is true, we call a variant that does not check the return type. If
  /// [maybeReceiver] is non-null, we use that instead of the first positional
  /// parameter as the receiver for `js_util.callMethod`.
  ReturnStatement _getExternalMethodBody(Procedure node, bool shouldTrustType,
      [Expression? maybeReceiver]) {
    if (_inlineExtensionIndex.canBeInvocationLevelLowered(node)) {
      _proceduresToSpecialize[node] = _MethodCallSiteSpecialization(
          shouldTrustType, maybeReceiver, _MethodSpecializationType.method);
    }
    return ReturnStatement(_getExternalMethodInvocation(
        node,
        shouldTrustType,
        node.function.positionalParameters
            .map<Expression>((v) => VariableGet(v))
            .toList(),
        maybeReceiver));
  }

  StaticInvocation _getExternalMethodInvocation(
      Procedure node, bool shouldTrustType, List<Expression> arguments,
      [Expression? maybeReceiver]) {
    final function = node.function;
    Procedure target =
        shouldTrustType ? _callMethodTrustTypeTarget : _callMethodTarget;
    final receiver = maybeReceiver ?? arguments.first;
    if (_inlineExtensionIndex.isInstanceInteropMember(node)) {
      // Ignore `this` for inline and extension members.
      arguments = arguments.sublist(1);
    }
    var callMethodInvocation = StaticInvocation(
        target,
        Arguments([
          receiver,
          StringLiteral(_getMemberJSName(node)),
          ListLiteral(arguments),
        ], types: [
          function.returnType
        ]))
      ..fileOffset = node.fileOffset;
    return _lowerCallMethod(callMethodInvocation,
        shouldTrustType: shouldTrustType);
  }

  /// Returns a new function body for the given [node] external operator.
  ReturnStatement? _getExternalOperatorBody(
      Procedure node, bool shouldTrustTypes) {
    switch (_inlineExtensionIndex.operatorName(node)) {
      case '[]':
        return _getExternalGetterBody(node, shouldTrustTypes);
      case '[]=':
        return _getExternalSetterBody(node);
      default:
        // TODO(joshualitt): Unfortunately, our current behavior is to allow
        // operators on extension methods to `@JS` classes, but the runtime
        // behavior is undefined. We should really convert this to an error, but
        // it would also technically be a breaking change.
        return null;
    }
  }

  /// Returns a new function body for the given [node] external non-object
  /// literal factory.
  ///
  /// The new function body will call the optimized version of
  /// `js_util.callConstructor` using the given [constructor] and the arguments
  /// of the provided external factory.
  ReturnStatement _getExternalConstructorBody(
      Procedure node, Expression constructor) {
    if (_inlineExtensionIndex.canBeInvocationLevelLowered(node)) {
      _proceduresToSpecialize[node] = _MethodCallSiteSpecialization(
          false, constructor, _MethodSpecializationType.constructor);
    }
    return ReturnStatement(_getExternalConstructorInvocation(
        node,
        constructor,
        node.function.positionalParameters
            .map<Expression>((argument) => VariableGet(argument))
            .toList()));
  }

  StaticInvocation _getExternalConstructorInvocation(
      Procedure node, Expression constructor, List<Expression> parameters) {
    var function = node.function;
    assert(function.namedParameters.isEmpty);
    var callConstructorInvocation = StaticInvocation(
        _callConstructorTarget,
        Arguments([constructor, ListLiteral(parameters)],
            types: [function.returnType]))
      ..fileOffset = node.fileOffset;
    return _lowerCallConstructor(callConstructorInvocation);
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

  /// Replaces js_util method calls with optimization when possible.
  ///
  /// Lowers `setProperty` to  `_setPropertyUnchecked` for values that are
  /// not Function type and guaranteed to be interop allowed.
  /// Lowers `callMethod` to `_callMethodUncheckedN` when the number of given
  /// arguments is 0-4 and all arguments are guaranteed to be interop allowed.
  /// Lowers `callConstructor` to `_callConstructorUncheckedN` when there are
  /// 0-4 arguments and all arguments are guaranteed to be interop allowed.
  @override
  visitStaticInvocation(StaticInvocation node) {
    final target = node.target;
    if (target == _setPropertyTarget) {
      node = _lowerSetProperty(node);
    } else if (target == _callMethodTarget) {
      // Never trust types on explicit `js_util` calls.
      node = _lowerCallMethod(node, shouldTrustType: false);
    } else if (target == _callConstructorTarget) {
      node = _lowerCallConstructor(node);
    } else if (target.isExternal) {
      tryTransformProcedure(target);
    }

    // Make sure to call [tryTransformProcedure] before specializing, just in
    // case we haven't visited the [Procedure] yet.
    if (_proceduresToSpecialize.containsKey(target)) {
      final function = target.function;
      final positional = node.arguments.positional;
      if (positional.length < function.positionalParameters.length) {
        final specialization = _proceduresToSpecialize[target]!;
        switch (specialization.type) {
          case _MethodSpecializationType.method:
            node = _getExternalMethodInvocation(
                target,
                specialization.shouldTrustType,
                positional,
                specialization.maybeReceiver)
              ..fileOffset = node.fileOffset;
            break;
          case _MethodSpecializationType.constructor:
            node = _getExternalConstructorInvocation(
                target, specialization.maybeReceiver!, positional)
              ..fileOffset = node.fileOffset;
        }
      }
    }
    node.transformChildren(this);
    return node;
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
    final descriptorNames = <String, InlineClassMemberDescriptor>{};
    for (var inlineClass in library.inlineClasses) {
      if (hasJSInteropAnnotation(inlineClass)) {
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

  String operatorName(Procedure node) {
    if (getJSName(node).isNotEmpty) {
      throw Exception('Operators cannot have `@JS` annotations.');
    }
    final String name;
    if (node.isInlineClassMember) {
      name = getInlineDescriptor(node)!.name.text;
    } else if (node.isExtensionMember) {
      name = getExtensionDescriptor(node)!.name.text;
    } else {
      throw Exception(
          'Operators are only allowed on extensions / inline classes');
    }
    return name;
  }

  /// Check if [node] is an interop member that can be lowered using
  /// invocation-level semantics.
  ///
  /// Invocation-level semantics here means that we don't call the original
  /// member but rather lower directly to the interop procedure at the
  /// call-site. This is needed in order to support cases where omitted
  /// optional parameters shouldn't be passed.
  bool canBeInvocationLevelLowered(Procedure node) {
    if (hasJSInteropAnnotation(node) ||
        hasJSInteropAnnotation(node.enclosingLibrary) ||
        (node.enclosingClass != null &&
            hasJSInteropAnnotation(node.enclosingClass!))) {
      return true;
    }

    if (node.isExtensionMember) {
      return getExtensionAnnotatable(node) != null;
    }

    if (node.isInlineClassMember) {
      return getInlineClass(node) != null;
    }

    return false;
  }
}
