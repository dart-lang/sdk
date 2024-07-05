// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type_system.dart'
    show TypeSystemImpl, ExtensionTypeErasure;

import '../analyzer.dart';

const String _dartJsAnnotationsUri = 'dart:_js_annotations';
const String _dartJsInteropUri = 'dart:js_interop';
const String _dartJsUri = 'dart:js';

const _desc =
    r'''Avoid runtime type tests with JS interop types where the result may not
    be platform-consistent.''';

const _details = r'''
**DON'T** use 'is' checks where the type is a JS interop type.

**DON'T** use 'is' checks where the type is a generic Dart type that has JS
interop type arguments.

**DON'T** use 'is' checks with a JS interop value.

'dart:js_interop' types have runtime types that are different based on whether
you are compiling to JS or to Wasm. Therefore, runtime type checks may result in
different behavior. Runtime checks also do not necessarily check that a JS
interop value is a particular JavaScript type.

**BAD:**
```dart
extension type HTMLElement(JSObject o) {}
extension type HTMLDivElement(JSObject o) implements HTMLElement {}

void compute(JSAny a, bool b, List<JSObject> lo, List<String> ls, JSObject o,
    HTMLElement e) {
  a is String; // LINT, checking that a JS value is a Dart type
  b is JSBoolean; // LINT, checking that a Dart value is a JS type
  a is JSString; // LINT, checking that a JS value is a different JS interop
                 // type
  o is JSNumber; // LINT, checking that a JS value is a different JS interop
                 // type
  lo is List<String>; // LINT, JS interop type argument and Dart type argument
                      // are incompatible
  ls is List<JSString>; // LINT, Dart type argument and JS interop type argument
                        // are incompatible
  lo is List<JSArray>; // LINT, comparing JS interop type argument with
                       // different JS interop type argument
  lo is List<JSNumber>; // LINT, comparing JS interop type argument with
                        // different JS interop type argument
  o is HTMLElement; // LINT, true because both are JSObjects but doesn't check
                    // that it's a JS HTMLElement
  e is HTMLDivElement; // LINT, true because both are JSObjects but doesn't
                       // check that it's a JS HTMLDivElement
}
```

Prefer using JS interop helpers like 'isA' from 'dart:js_interop' to check the
underlying type of JS interop values.

**GOOD:**
```dart
extension type HTMLElement(JSObject o) implements JSObject {}
extension type HTMLDivElement(JSObject o) implements HTMLElement {}

void compute(JSAny a, List<JSAny> l, JSObject o, HTMLElement e) {
  a.isA<JSString>; // OK, uses JS interop to check it is a JS string
  l[0].isA<JSString>; // OK, uses JS interop to check it is a JS string
  o.isA<HTMLElement>(); // OK, uses JS interop to check `o` is an HTMLElement
  e.isA<HTMLDivElement>(); // OK, uses JS interop to check `e` is an
                           // HTMLDivElement
}
```

**DON'T** use 'as' to cast a JS interop value to an unrelated Dart type or an
unrelated Dart value to a JS interop type.

**DON'T** use 'as' to cast a JS interop value to a JS interop type represented
by an incompatible 'dart:js_interop' type.

**BAD:**
```dart
extension type Window(JSObject o) {}

void compute(String s, JSBoolean b, Window w, List<String> l,
    List<JSObject> lo) {
  s as JSString; // LINT, casting Dart type to JS interop type
  b as bool; // LINT, casting JS interop type to Dart type
  b as JSNumber; // LINT, JSBoolean and JSNumber are incompatible
  b as Window; // LINT, JSBoolean and JSObject are incompatible
  w as JSBoolean; // LINT, JSObject and JSBoolean are incompatible
  l as List<JSString>; // LINT, casting Dart value with Dart type argument to
                       // Dart type with JS interop type argument
  lo as List<String>; // LINT, casting Dart value with JS interop type argument
                      // to Dart type with Dart type argument
  lo as List<JSBoolean>; // LINT, casting Dart value with JS interop type
                         // argument to Dart type with incompatible JS interop
                         // type argument
}
```

Prefer using 'dart:js_interop' conversion methods to convert a JS interop value
to a Dart value and vice versa.

**GOOD:**
```dart
extension type Window(JSObject o) {}
extension type Document(JSObject o) {}

void compute(String s, JSBoolean b, Window w, JSArray<JSString> a,
    List<String> ls, JSObject o, List<JSAny> la) {
  s.toJS; // OK, converts the Dart type to a JS type
  b.toDart; // OK, converts the JS type to a Dart type
  a.toDart; // OK, converts the JS type to a Dart type
  w as Document; // OK, but no runtime check that `w` is a JS Document
  ls.map((e) => e.toJS).toList(); // OK, converts the Dart types to JS types
  o as JSArray<JSString>; // OK, JSObject and JSArray are compatible
  la as List<JSString>; // OK, JSAny and JSString are compatible
  (o as Object) as JSObject; // OK, Object is a supertype of JSAny
}
```

''';
const Set<String> _sdkWebLibraries = {
  'dart:html',
  'dart:indexed_db',
  'dart:svg',
  'dart:web_audio',
  'dart:web_gl',
};

/// If [type] is a type declared using `@staticInterop` through
/// `dart:js_interop`, returns the JS type equivalent for that class, which is
/// just `JSObject`.
///
/// `@staticInterop` types that were declared using `package:js` do not apply as
/// that package is incompatible with dart2wasm.
///
/// Returns null if `type` is not a `dart:js_interop` `@staticInterop` class.
DartType? getJsTypeForStaticInterop(InterfaceType type) {
  var element = type.element;
  if (element is! ClassElement) return null;
  var metadata = element.metadata;
  var hasJS = false;
  var hasStaticInterop = false;
  late LibraryElement dartJsInterop;
  for (var i = 0; i < metadata.length; i++) {
    var annotation = metadata[i];
    var annotationElement = annotation.element;
    if (annotationElement is ConstructorElement &&
        isFromLibrary(annotationElement.library, _dartJsInteropUri) &&
        annotationElement.enclosingElement.name == 'JS') {
      hasJS = true;
      dartJsInterop = annotationElement.library;
    } else if (annotationElement is PropertyAccessorElement &&
        isFromLibrary(annotationElement.library, _dartJsAnnotationsUri) &&
        annotationElement.name == 'staticInterop') {
      hasStaticInterop = true;
    }
  }
  return (hasJS && hasStaticInterop)
      ? dartJsInterop.units.single.extensionTypes
          .singleWhere((extType) => extType.name == 'JSObject')
          // Nullability is ignored in this lint, so just return `thisType`.
          .thisType
      : null;
}

/// Given a [type] erased by [EraseNonJSInteropTypes], determine if it is a type
/// that is a `dart:js_interop` type or is bound to one.
bool isDartJsInteropType(DartType type) {
  if (type is TypeParameterType) return isDartJsInteropType(type.bound);
  if (type is InterfaceType) {
    var element = type.element;
    if (element is ExtensionTypeElement) {
      return isFromLibrary(element.library, _dartJsInteropUri);
    }
  }
  return false;
}

bool isFromLibrary(LibraryElement elementLibrary, String uri) =>
    elementLibrary.definingCompilationUnit.source ==
    elementLibrary.context.sourceFactory.forUri(uri);

/// Whether [type] is a user JS interop type using `dart:js_interop` or is bound
/// to one.
///
/// An interop type is a user interop type if it's an extension type on another
/// interop type or a `dart:js_interop` `@staticInterop` type.
bool isUserJsInteropType(DartType type) {
  if (type is TypeParameterType) return isUserJsInteropType(type.bound);
  if (type is InterfaceType) {
    var element = type.element;
    if (element is ExtensionTypeElement) {
      var representationType = element.representation.type;
      return isDartJsInteropType(representationType) ||
          isUserJsInteropType(representationType);
    } else if (getJsTypeForStaticInterop(type) != null) {
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
bool isWasmIncompatibleJsInterop(DartType type) {
  if (type is TypeParameterType) return isWasmIncompatibleJsInterop(type.bound);
  if (type is! InterfaceType) return false;
  var element = type.element;
  // `hasJS` only checks for the `dart:_js_annotations` definition, which is
  // what we want here.
  if (element.hasJS) return true;
  return _sdkWebLibraries.any((uri) => isFromLibrary(element.library, uri)) ||
      // While a type test with types from this library is very rare, we should
      // still ignore it for consistency.
      isFromLibrary(element.library, _dartJsUri);
}

/// Erases extension types except for JS interop types so that
/// [_Visitor.getInvalidJsInteropTypeTest] can determine if the type test is
/// safe.
class EraseNonJSInteropTypes extends ExtensionTypeErasure {
  /// Determines whether we erase JS interop types to their `dart:js_interop`
  /// equivalent, or keep them as is.
  bool _keepUserInteropTypes = false;

  EraseNonJSInteropTypes();

  @override
  DartType perform(DartType type, {bool keepUserInteropTypes = false}) {
    _keepUserInteropTypes = keepUserInteropTypes;
    return super.perform(type);
  }

  @override
  DartType? visitInterfaceType(covariant InterfaceTypeImpl type) {
    if (_keepUserInteropTypes
        ? isUserJsInteropType(type)
        : isDartJsInteropType(type)) {
      // Nullability and generics on interop types are ignored for this lint. In
      // order to just compare the interfaces themselves, we use `thisType`.
      return type.element.thisType;
    } else {
      return getJsTypeForStaticInterop(type) ?? super.visitInterfaceType(type);
    }
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType type) {
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

class InvalidRuntimeCheckWithJSInteropTypes extends LintRule {
  static const String lintName = 'invalid_runtime_check_with_js_interop_types';

  static const LintCode dartTypeIsJsInteropTypeCode = LintCode(
      lintName,
      "Runtime check between '{0}' and '{1}' checks whether a Dart value is a "
      'JS interop type, which may not be platform-consistent.');

  static const LintCode jsInteropTypeIsDartTypeCode = LintCode(
      lintName,
      "Runtime check between '{0}' and '{1}' checks whether a JS interop value "
      'is a Dart type, which may not be platform-consistent.');

  static const LintCode jsInteropTypeIsInconsistentJsInteropType = LintCode(
      lintName,
      "Runtime check between '{0}' and '{1}' involves a non-trivial runtime "
      'check between two JS interop types that may not be platform-consistent.',
      correctionMessage:
          "Try using a JS interop member like 'isA' from 'dart:js_interop' to "
          'check the underlying type of JS interop values.');

  static const LintCode jsInteropTypeIsUnrelatedJsInteropTypeCode = LintCode(
      lintName,
      "Runtime check between '{0}' and '{1}' involves a runtime check between "
      'a JS interop value and an unrelated JS interop type that will always be '
      "true and won't check the underlying type.",
      correctionMessage:
          "Try using a JS interop member like 'isA' from 'dart:js_interop' to "
          'check the underlying type of JS interop values, or make the JS '
          "interop type a supertype using 'implements'.");

  static const LintCode dartTypeAsJsInteropTypeCode = LintCode(
      lintName,
      "Cast from '{0}' to '{1}' casts a Dart value to a JS interop type, which "
      'may not be platform-consistent.',
      correctionMessage:
          "Try using conversion methods from 'dart:js_interop' to convert "
          'between Dart types and JS interop types.');

  static const LintCode jsInteropTypeAsDartTypeCode = LintCode(
      lintName,
      "Cast from '{0}' to '{1}' casts a JS interop value to a Dart type, which "
      'may not be platform-consistent.',
      correctionMessage:
          "Try using conversion methods from 'dart:js_interop' to convert "
          'between JS interop types and Dart types.');

  static const LintCode jsInteropTypeAsIncompatibleJsInteropTypeCode = LintCode(
      lintName,
      "Cast from '{0}' to '{1}' casts a JS interop value to an incompatible JS "
      'interop type, which may not be platform-consistent.');

  InvalidRuntimeCheckWithJSInteropTypes()
      : super(
            name: lintName,
            description: _desc,
            details: _details,
            categories: {Category.error_prone});

  @override
  List<LintCode> get lintCodes => const [
        dartTypeIsJsInteropTypeCode,
        jsInteropTypeIsDartTypeCode,
        jsInteropTypeIsInconsistentJsInteropType,
        jsInteropTypeIsUnrelatedJsInteropTypeCode,
        dartTypeAsJsInteropTypeCode,
        jsInteropTypeAsDartTypeCode,
        jsInteropTypeAsIncompatibleJsInteropTypeCode,
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.typeSystem, context.typeProvider);
    registry.addIsExpression(this, visitor);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeSystemImpl typeSystem;
  final TypeProvider typeProvider;
  late final EraseNonJSInteropTypes _eraseNonJsInteropTypes;

  _Visitor(this.rule, TypeSystem typeSystem, this.typeProvider)
      : typeSystem = typeSystem as TypeSystemImpl,
        _eraseNonJsInteropTypes = EraseNonJSInteropTypes();

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
  LintCode? getInvalidJsInteropTypeTest(DartType? leftType, DartType? rightType,
      {required bool check}) {
    if (leftType == null || rightType == null) return null;
    LintCode? lintCode;
    (DartType, DartType) eraseTypes(DartType left, DartType right) {
      var erasedLeft =
          typeSystem.promoteToNonNull(_eraseNonJsInteropTypes.perform(left));
      var erasedRight =
          typeSystem.promoteToNonNull(_eraseNonJsInteropTypes.perform(right));
      var leftIsInteropType = isDartJsInteropType(erasedLeft);
      var rightIsInteropType = isDartJsInteropType(erasedRight);
      // If there's already an invalid check in this `canBeSubtypeOf` check, we
      // are already going to lint, so only continue checking if we haven't
      // found an issue.
      if (lintCode == null) {
        if (leftIsInteropType || rightIsInteropType) {
          if (!isWasmIncompatibleJsInterop(erasedLeft) &&
              !isWasmIncompatibleJsInterop(erasedRight)) {
            var erasedLeftIsSubtype =
                typeSystem.isSubtypeOf(erasedLeft, erasedRight);
            var erasedRightIsSubtype =
                typeSystem.isSubtypeOf(erasedRight, erasedLeft);
            var erasedLeftIsDynamic = erasedLeft is DynamicType;
            var erasedRightIsDynamic = erasedRight is DynamicType;
            if (check) {
              if (!erasedLeftIsSubtype && !erasedRightIsDynamic) {
                if (leftIsInteropType && rightIsInteropType) {
                  lintCode = InvalidRuntimeCheckWithJSInteropTypes
                      .jsInteropTypeIsInconsistentJsInteropType;
                } else if (leftIsInteropType) {
                  lintCode = InvalidRuntimeCheckWithJSInteropTypes
                      .jsInteropTypeIsDartTypeCode;
                } else {
                  lintCode = InvalidRuntimeCheckWithJSInteropTypes
                      .dartTypeIsJsInteropTypeCode;
                }
              } else if (erasedLeftIsSubtype &&
                  leftIsInteropType &&
                  rightIsInteropType) {
                // Only report if the right type is a user JS interop type.
                // Checks like `window is JSAny` are not confusing and not worth
                // linting.
                if (isUserJsInteropType(right) &&
                    !typeSystem.isSubtypeOf(
                        _eraseNonJsInteropTypes.perform(left,
                            keepUserInteropTypes: true),
                        _eraseNonJsInteropTypes.perform(right,
                            keepUserInteropTypes: true))) {
                  lintCode = InvalidRuntimeCheckWithJSInteropTypes
                      .jsInteropTypeIsUnrelatedJsInteropTypeCode;
                }
              }
            } else {
              if (!erasedLeftIsSubtype &&
                  !erasedRightIsSubtype &&
                  !erasedLeftIsDynamic &&
                  !erasedRightIsDynamic) {
                if (leftIsInteropType && rightIsInteropType) {
                  lintCode = InvalidRuntimeCheckWithJSInteropTypes
                      .jsInteropTypeAsIncompatibleJsInteropTypeCode;
                } else if (leftIsInteropType) {
                  lintCode = InvalidRuntimeCheckWithJSInteropTypes
                      .jsInteropTypeAsDartTypeCode;
                } else {
                  lintCode = InvalidRuntimeCheckWithJSInteropTypes
                      .dartTypeAsJsInteropTypeCode;
                }
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

    typeSystem.canBeSubtypeOf(leftType, rightType, eraseTypes: eraseTypes);
    return lintCode;
  }

  @override
  void visitAsExpression(AsExpression node) {
    var leftType = node.expression.staticType;
    var rightType = node.type.type;
    var code = getInvalidJsInteropTypeTest(leftType, rightType, check: false);
    if (code != null) {
      rule.reportLint(node,
          arguments: [
            leftType!.getDisplayString(),
            rightType!.getDisplayString(),
          ],
          errorCode: code);
    }
  }

  @override
  void visitIsExpression(IsExpression node) {
    var leftType = node.expression.staticType;
    var rightType = node.type.type;
    var code = getInvalidJsInteropTypeTest(leftType, rightType, check: true);
    if (code != null) {
      rule.reportLint(node,
          arguments: [
            leftType!.getDisplayString(),
            rightType!.getDisplayString(),
          ],
          errorCode: code);
    }
  }
}
