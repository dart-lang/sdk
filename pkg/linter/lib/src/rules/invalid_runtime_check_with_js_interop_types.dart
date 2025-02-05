// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type_system.dart'
    show TypeSystemImpl, ExtensionTypeErasure;
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type_visitor.dart';

import '../analyzer.dart';

const String _dartJsAnnotationsUri = 'dart:_js_annotations';
const String _dartJsInteropUri = 'dart:js_interop';
const String _dartJsUri = 'dart:js';

const _desc =
    r'''Avoid runtime type tests with JS interop types where the result may not
    be platform-consistent.''';

const Set<String> _sdkWebLibraries = {
  'dart:html',
  'dart:indexed_db',
  'dart:svg',
  'dart:web_audio',
  'dart:web_gl',
};

/// Given a [type], determine if it is a JS interop type that corresponds to
/// [kind].
bool _isJsInteropType(DartType type, _InteropTypeKind kind) {
  if (type is TypeParameterType) return _isJsInteropType(type.bound, kind);
  if (type is InterfaceType) {
    var element = type.element3;
    var dartJsInteropTypeKind = kind == _InteropTypeKind.dartJsInteropType ||
        kind == _InteropTypeKind.any;
    var userJsInteropTypeKind = kind == _InteropTypeKind.userJsInteropType ||
        kind == _InteropTypeKind.any;
    if (element is ExtensionTypeElement2) {
      if (dartJsInteropTypeKind && element.isFromLibrary(_dartJsInteropUri)) {
        return true;
      } else if (userJsInteropTypeKind) {
        var representationType = element.representation2.type;
        return _isJsInteropType(
                representationType, _InteropTypeKind.dartJsInteropType) ||
            _isJsInteropType(
                representationType, _InteropTypeKind.userJsInteropType);
      }
    } else if (userJsInteropTypeKind && _jsTypeForStaticInterop(type) != null) {
      return true;
    }
  }
  return false;
}

/// Whether [type] comes from a JS interop library that is unavailable in
/// dart2wasm.
///
/// Currently, the set of interop libraries that declare types or allow users to
/// declare types includes `package:js`, the SDK web libraries, and `dart:js`.
///
/// Since dart2wasm doesn't support these libraries, users can't come across
/// platform-inconsistent type tests, and therefore we should not lint for these
/// types.
bool _isWasmIncompatibleJsInterop(DartType type) {
  if (type is TypeParameterType) {
    return _isWasmIncompatibleJsInterop(type.bound);
  }
  if (type is! InterfaceType) return false;
  var element = type.element3;
  // `hasJS` only checks for the `dart:_js_annotations` definition, which is
  // what we want here.
  if (element.metadata2.hasJS) return true;
  return _sdkWebLibraries.any((uri) => element.isFromLibrary(uri)) ||
      // While a type test with types from this library is very rare, we should
      // still ignore it for consistency.
      element.isFromLibrary(_dartJsUri);
}

/// If [type] is a type declared using `@staticInterop` through
/// `dart:js_interop`, returns the JS type equivalent for that class, which is
/// just `JSObject`.
///
/// `@staticInterop` types that were declared using `package:js` do not apply as
/// that package is incompatible with dart2wasm.
///
/// Returns null if `type` is not a `dart:js_interop` `@staticInterop` class.
DartType? _jsTypeForStaticInterop(InterfaceType type) {
  var element = type.element3;
  if (element is! ClassElement2) return null;
  var metadata = element.metadata2;
  var hasJS = false;
  var hasStaticInterop = false;
  LibraryElement2? dartJsInterop;
  for (var annotation in metadata.annotations) {
    var annotationElement = annotation.element2;
    if (annotationElement is ConstructorElement2 &&
        annotationElement.isFromLibrary(_dartJsInteropUri) &&
        annotationElement.enclosingElement2.name3 == 'JS') {
      hasJS = true;
      dartJsInterop = annotationElement.library2;
    } else if (annotationElement is GetterElement &&
        annotationElement.isFromLibrary(_dartJsAnnotationsUri) &&
        annotationElement.name3 == 'staticInterop') {
      hasStaticInterop = true;
    }
  }
  return (hasJS && hasStaticInterop && dartJsInterop != null)
      ? dartJsInterop.extensionTypes
          .singleWhere((extType) => extType.name3 == 'JSObject')
          // Nullability is ignored in this lint, so just return `thisType`.
          .thisType
      : null;
}

/// Erases extension types except for JS interop types so that
/// [_Visitor.getInvalidJsInteropTypeTest] can determine if the type test is
/// safe.
class EraseNonJSInteropTypes extends ExtensionTypeErasure {
  /// Determines whether we erase JS interop types to their `dart:js_interop`
  /// equivalent, or keep them as is.
  bool _keepUserInteropTypes = false;

  final _visitedTypes = <DartType>{};

  @override
  DartType perform(DartType type, {bool keepUserInteropTypes = false}) {
    _keepUserInteropTypes = keepUserInteropTypes;
    _visitedTypes.clear();
    return super.perform(type);
  }

  @override
  DartType? visitInterfaceType(covariant InterfaceTypeImpl type) {
    if (_keepUserInteropTypes
        ? _isJsInteropType(type, _InteropTypeKind.any)
        : _isJsInteropType(type, _InteropTypeKind.dartJsInteropType)) {
      // Nullability and generics on interop types are ignored for this lint. In
      // order to just compare the interfaces themselves, we use `thisType`.
      return type.element3.thisType;
    } else {
      return _jsTypeForStaticInterop(type) ?? super.visitInterfaceType(type);
    }
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType type) {
    // Visiting the bound may result in a cycle e.g. `class C<T extends C<T>>`.
    if (!_visitedTypes.add(type)) return type;
    // If the bound is a JS interop type, replace it with its `dart:js_interop`
    // equivalent.
    var newBound = type.bound.accept(this);
    return createPromotedTypeParameterType(
      type: type,
      // Remove any nullability for comparison.
      newNullability: NullabilitySuffix.none,
      newPromotedBound: newBound,
    );
  }
}

/// Determines whether a given [DartType] is or contains a type that is a JS
/// interop type.
class InteropTypeChecker extends RecursiveTypeVisitor {
  bool _hasInteropType = false;
  final _visitedTypes = <DartType>{};

  bool hasInteropType(DartType type) {
    _hasInteropType = false;
    _visitedTypes.clear();
    type.accept(this);
    return _hasInteropType;
  }

  @override
  bool visitInterfaceType(InterfaceType type) {
    _hasInteropType |= _isJsInteropType(type, _InteropTypeKind.any);
    return super.visitInterfaceType(type);
  }

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    // Visiting the bound may result in a cycle e.g. `class C<T extends C<T>>`.
    if (_visitedTypes.add(type)) return type.bound.accept(this);
    return super.visitTypeParameterType(type);
  }
}

class InvalidRuntimeCheckWithJSInteropTypes extends LintRule {
  InvalidRuntimeCheckWithJSInteropTypes()
      : super(
          name: LintNames.invalid_runtime_check_with_js_interop_types,
          description: _desc,
        );

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.invalid_runtime_check_with_js_interop_types_dart_as_js,
        LinterLintCode.invalid_runtime_check_with_js_interop_types_dart_is_js,
        LinterLintCode.invalid_runtime_check_with_js_interop_types_js_as_dart,
        LinterLintCode
            .invalid_runtime_check_with_js_interop_types_js_as_incompatible_js,
        LinterLintCode.invalid_runtime_check_with_js_interop_types_js_is_dart,
        LinterLintCode
            .invalid_runtime_check_with_js_interop_types_js_is_inconsistent_js,
        LinterLintCode
            .invalid_runtime_check_with_js_interop_types_js_is_unrelated_js
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.typeSystem);
    registry.addIsExpression(this, visitor);
    registry.addAsExpression(this, visitor);
  }
}

/// The kind of JS interop type to check for.
///
/// [dartJsInteropType] corresponds to either an extension type from
/// `dart:js_interop` or a type parameter that is bound to one.
/// [userJsInteropType] corresponds to either an extension type whose
/// representation type is a JS interop type, an `@staticInterop` type, or a
/// type parameter that is bound to either.
/// [any] corresponds to either a [dartJsInteropType] or [userJsInteropType].
enum _InteropTypeKind {
  dartJsInteropType,
  userJsInteropType,
  any,
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeSystemImpl typeSystem;
  final EraseNonJSInteropTypes eraseNonJsInteropTypes =
      EraseNonJSInteropTypes();
  final InteropTypeChecker interopTypeChecker = InteropTypeChecker();

  _Visitor(this.rule, TypeSystem typeSystem)
      : typeSystem = typeSystem as TypeSystemImpl;

  /// Determines if a type test from [leftType] to [rightType] is a valid test
  /// for JS interop, and if not, returns the [LintCode] associated with the
  /// specific invalid case.
  ///
  /// If [check] is true, this determines if it's a valid `is` check. Otherwise,
  /// determines if it's a valid `as` cast.
  ///
  /// If neither type contains a JS interop type, it's a valid test and this
  /// returns null.
  ///
  /// `dart:js_interop` types are represented by platform-dependent values and
  /// therefore, type tests that aren't statically guaranteed may be
  /// inconsistent. In order to determine if this test is valid, this function
  /// erases any interop types to its `dart:js_interop` equivalent and any other
  /// extension type to its erasure type. If there are nested types involved, it
  /// nests as needed.
  ///
  /// Let `l` be the positionally-equivalent type in [leftType] and `r` be the
  /// positionally-equivalent type in [rightType]. Let `le` be the
  /// `dart:js_interop` type or the extension type erasure of `l`, and `re` be
  /// the `dart:js_interop` type or the extension type erasure of `r`. If `l` or
  /// `r` are JS interop types, an `is` check is valid only if `l` <: `r`, `le`
  /// <: `re` and `r` is a `dart:js_interop` type, or `r` is `dynamic` or
  /// `Object`. An `as` cast is valid only if `le` <: `re`, `le` :> `re`, `l`
  /// is `dynamic`, or `r` is `dynamic`.
  ///
  /// These restrictions come from the difference in the representation of
  /// `dart:js_interop` types. When compiling to Wasm, JS values are not
  /// differentiated at runtime, and therefore there's only one runtime type.
  /// When compiling to JS, JS values are differentiated and each
  /// `dart:js_interop` has a separate runtime type. An additional restriction
  /// is placed on `is` checks so that type checks between unrelated types that
  /// would be trivially true e.g. `jsObject is Window` aren't interpreted as
  /// doing a runtime check that `jsObject` actually is a JS `Window`.
  ///
  /// Types that belong to JS interop libraries that are not available when
  /// compiling to Wasm are ignored. Nullability is also ignored for the purpose
  /// of this test.
  LintCode? getInvalidJsInteropTypeTest(DartType leftType, DartType rightType,
      {required bool check}) {
    LintCode? lintCode;
    (DartType, DartType) eraseTypes(DartType left, DartType right) {
      var erasedLeft =
          typeSystem.promoteToNonNull(eraseNonJsInteropTypes.perform(left));
      var erasedRight =
          typeSystem.promoteToNonNull(eraseNonJsInteropTypes.perform(right));
      var leftIsInteropType =
          _isJsInteropType(erasedLeft, _InteropTypeKind.dartJsInteropType);
      var rightIsInteropType =
          _isJsInteropType(erasedRight, _InteropTypeKind.dartJsInteropType);
      // If there's already an invalid check in this `canBeSubtypeOf` check, we
      // are already going to lint, so only continue checking if we haven't
      // found an issue.

      if (lintCode == null && leftIsInteropType || rightIsInteropType) {
        if (!_isWasmIncompatibleJsInterop(erasedLeft) &&
            !_isWasmIncompatibleJsInterop(erasedRight)) {
          var erasedLeftIsSubtype =
              typeSystem.isSubtypeOf(erasedLeft, erasedRight);
          var erasedRightIsSubtype =
              typeSystem.isSubtypeOf(erasedRight, erasedLeft);
          var erasedLeftIsDynamic = erasedLeft is DynamicType;
          var erasedRightIsDynamic = erasedRight is DynamicType;
          if (check) {
            if (!erasedLeftIsSubtype && !erasedRightIsDynamic) {
              if (leftIsInteropType && rightIsInteropType) {
                lintCode = LinterLintCode
                    .invalid_runtime_check_with_js_interop_types_js_is_inconsistent_js;
              } else if (leftIsInteropType) {
                lintCode = LinterLintCode
                    .invalid_runtime_check_with_js_interop_types_js_is_dart;
              } else {
                lintCode = LinterLintCode
                    .invalid_runtime_check_with_js_interop_types_dart_is_js;
              }
            } else if (erasedLeftIsSubtype &&
                leftIsInteropType &&
                rightIsInteropType) {
              // Only report if the right type is a user JS interop type.
              // Checks like `window is JSAny` are not confusing and not worth
              // linting.
              if (_isJsInteropType(right, _InteropTypeKind.userJsInteropType) &&
                  !typeSystem.isSubtypeOf(
                      eraseNonJsInteropTypes.perform(left,
                          keepUserInteropTypes: true),
                      eraseNonJsInteropTypes.perform(right,
                          keepUserInteropTypes: true))) {
                lintCode = LinterLintCode
                    .invalid_runtime_check_with_js_interop_types_js_is_unrelated_js;
              }
            }
          } else {
            if (!erasedLeftIsSubtype &&
                !erasedRightIsSubtype &&
                !erasedLeftIsDynamic &&
                !erasedRightIsDynamic) {
              if (leftIsInteropType && rightIsInteropType) {
                lintCode = LinterLintCode
                    .invalid_runtime_check_with_js_interop_types_js_as_incompatible_js;
              } else if (leftIsInteropType) {
                lintCode = LinterLintCode
                    .invalid_runtime_check_with_js_interop_types_js_as_dart;
              } else {
                lintCode = LinterLintCode
                    .invalid_runtime_check_with_js_interop_types_dart_as_js;
              }
            }
          }
        }
      }
      // The resulting types that are checked in `canBeSubtypeOf` are assumed to
      // not be extension types, so erase the types if we avoided erasing them
      // in `EraseNonJSInteropTypes` before continuing.
      if (leftIsInteropType) erasedLeft = left.extensionTypeErasure;
      if (rightIsInteropType) erasedRight = right.extensionTypeErasure;
      return (erasedLeft, erasedRight);
    }

    // If there are no relevant interop types, exit early.
    if (!interopTypeChecker.hasInteropType(leftType) &&
        !interopTypeChecker.hasInteropType(rightType)) {
      return lintCode;
    }
    // Called here for the side effects of `eraseTypes`.
    typeSystem.canBeSubtypeOf(leftType, rightType, eraseTypes: eraseTypes);
    return lintCode;
  }

  @override
  void visitAsExpression(AsExpression node) {
    var leftType = node.expression.staticType;
    var rightType = node.type.type;
    if (leftType == null || rightType == null) return;
    var code = getInvalidJsInteropTypeTest(leftType, rightType, check: false);
    if (code != null) {
      rule.reportLint(node, arguments: [leftType, rightType], errorCode: code);
    }
  }

  @override
  void visitIsExpression(IsExpression node) {
    var leftType = node.expression.staticType;
    var rightType = node.type.type;
    if (leftType == null || rightType == null) return;
    var code = getInvalidJsInteropTypeTest(leftType, rightType, check: true);
    if (code != null) {
      rule.reportLint(node, arguments: [leftType, rightType], errorCode: code);
    }
  }
}

extension on Element2 {
  /// Returns whether this is from the Dart library at [uri].
  bool isFromLibrary(String uri) => library2?.uri.toString() == uri;
}
