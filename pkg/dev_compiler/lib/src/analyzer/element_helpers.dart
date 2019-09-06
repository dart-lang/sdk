// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart'
    show DartType, InterfaceType, FunctionType;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart'
    show DartObject, DartObjectImpl;
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/type_system.dart' show Dart2TypeSystem;

class Tuple2<T0, T1> {
  final T0 e0;
  final T1 e1;
  Tuple2(this.e0, this.e1);
}

/// Instantiates [t] with dynamic bounds.
///
/// Note: this should only be used when the resulting type is later replaced,
/// such as a "deferred supertype" (used to break circularity between the
/// supertype's type arguments and the class definition). Otherwise
/// [instantiateElementTypeToBounds] should be used instead.
InterfaceType fillDynamicTypeArgsForClass(InterfaceType t) {
  if (t.typeArguments.isNotEmpty) {
    var rawT = t.element.type;
    var dyn = List.filled(rawT.typeArguments.length, DynamicTypeImpl.instance);
    return rawT.substitute2(dyn, rawT.typeArguments);
  }
  return t;
}

/// Instantiates the [element] type to bounds.
///
/// Conceptually this is similar to [Dart2TypeSystem.instantiateToBounds] on
/// `element.type`, but unfortunately typedef elements do not return a
/// meaningful type, so we need to work around that.
DartType instantiateElementTypeToBounds(
    Dart2TypeSystem rules, TypeDefiningElement element) {
  Element e = element;
  if (e is TypeParameterizedElement) {
    // TODO(jmesserly): we can't use `instantiateToBounds` because typedefs do
    // not include their type parameters, for example:
    //
    //     typedef void void Func<T>(T x);               // Dart 1 syntax.
    //     typedef void GenericFunc<T> = S Func<S>(T x); // Dart 2 syntax.
    //
    // There is no way to get a type that has `<T>` as a type formal from the
    // element (without constructing it ourselves).
    //
    // Futhermore, the second line is represented by a GenericTypeAliasElement,
    // and its type getter does not even include its own type formals `<S>`.
    // That has to be worked around using `.function.type`.
    DartType type;
    if (e is GenericTypeAliasElement) {
      type = e.function.type;
    } else if (e is FunctionTypedElement) {
      type = e.type;
    } else if (e is ClassElement) {
      type = e.type;
    }
    var bounds = rules.instantiateTypeFormalsToBounds(e.typeParameters);
    if (bounds == null) return type;
    return type.substitute2(
        bounds, TypeParameterTypeImpl.getTypes(e.typeParameters));
  }
  return element.type;
}

/// Given an [element] and a [test] function, returns the first matching
/// constant valued metadata annotation on the element.
///
/// If the element is a synthetic getter/setter (Analyzer creates these for
/// fields), then this will use the corresponding real element, which will have
/// the metadata annotations.
///
/// For example if we had the [ClassDeclaration] node for `FontElement`:
///
///    @js.JS('HTMLFontElement')
///    @deprecated
///    class FontElement { ... }
///
/// We could match `@deprecated` with a test function like:
///
///    (v) => v.type.name == 'Deprecated' && v.type.element.library.isDartCore
///
DartObject findAnnotation(Element element, bool test(DartObjectImpl value)) {
  if (element == null) return null;
  var accessor = element;
  if (accessor is PropertyAccessorElement && accessor.isSynthetic) {
    // Look for metadata on the real element, not the synthetic one.
    element = accessor.variable;
  }
  for (var metadata in element.metadata) {
    var value = metadata.computeConstantValue();
    if (value is DartObjectImpl && test(value)) return value;
  }
  return null;
}

/// Searches all supertype, in order of most derived members, to see if any
/// [match] a condition. If so, returns the first match, otherwise returns null.
InterfaceType findSupertype(InterfaceType type, bool match(InterfaceType t)) {
  for (var m in type.mixins.reversed) {
    if (match(m)) return m;
  }
  var s = type.superclass;
  if (s == null) return null;

  if (match(s)) return type;
  return findSupertype(s, match);
}

//TODO(leafp): Is this really necessary?  In theory I think
// the static type should always be filled in for resolved
// ASTs.  This may be a vestigial workaround.
DartType getStaticType(Expression e) =>
    e.staticType ?? DynamicTypeImpl.instance;

// TODO(leafp) Factor this out or use an existing library
/// Similar to [SimpleIdentifier] inGetterContext, inSetterContext, and
/// inDeclarationContext, this method returns true if [node] is used in an
/// invocation context such as a MethodInvocation.
bool inInvocationContext(Expression node) {
  if (node == null) return false;
  var parent = node.parent;
  while (parent is ParenthesizedExpression) {
    node = parent as Expression;
    parent = node.parent;
  }
  return parent is InvocationExpression && identical(node, parent.function) ||
      parent is MethodInvocation &&
          parent.methodName.name == 'call' &&
          identical(node, parent.target);
}

bool isInlineJS(Element e) {
  if (e != null && e.name == 'JS' && e is FunctionElement) {
    var uri = e.librarySource.uri;
    return uri.scheme == 'dart' && uri.path == '_foreign_helper';
  }
  return false;
}

bool isLibraryPrefix(Expression node) =>
    node is SimpleIdentifier && node.staticElement is PrefixElement;

ExecutableElement getFunctionBodyElement(FunctionBody body) {
  var f = body.parent;
  if (f is FunctionExpression) {
    return f.declaredElement;
  } else if (f is MethodDeclaration) {
    return f.declaredElement;
  } else {
    return (f as ConstructorDeclaration).declaredElement;
  }
}

/// Returns the value of the `name` field from the [match]ing annotation on
/// [element], or `null` if we didn't find a valid match or it was not a string.
///
/// For example, consider this code:
///
///     class MyAnnotation {
///       final String name;
///       // ...
///       const MyAnnotation(this.name/*, ... other params ... */);
///     }
///
///     @MyAnnotation('FooBar')
///     main() { ... }
///
/// If we match the annotation for the `@MyAnnotation('FooBar')` this will
/// return the string 'FooBar'.
String getAnnotationName(Element element, bool match(DartObjectImpl value)) =>
    findAnnotation(element, match)?.getField('name')?.toStringValue();

List<ClassElement> getSuperclasses(ClassElement cls) {
  var result = <ClassElement>[];
  var visited = HashSet<ClassElement>();
  while (cls != null && visited.add(cls)) {
    for (var mixinType in cls.mixins.reversed) {
      var mixin = mixinType.element;
      if (mixin != null) result.add(mixin);
    }
    var supertype = cls.supertype;
    // Object or mixin declaration.
    if (supertype == null) break;

    cls = supertype.element;
    result.add(cls);
  }
  return result;
}

List<ClassElement> getImmediateSuperclasses(ClassElement c) {
  var result = <ClassElement>[];
  for (var m in c.mixins.reversed) {
    result.add(m.element);
  }
  var s = c.supertype;
  if (s != null) result.add(s.element);
  return result;
}

/// Returns true if the library [l] is dart:_runtime.
// TODO(jmesserly): unlike other methods in this file, this one wouldn't be
// suitable for upstream to Analyzer, as it's DDC specific.
bool isSdkInternalRuntime(LibraryElement l) {
  var uri = l.source.uri;
  return uri.scheme == 'dart' && uri.path == '_runtime';
}

/// Return `true` if the given [classElement] has a noSuchMethod() method
/// distinct from the one declared in class Object, as per the Dart Language
/// Specification (section 10.4).
// TODO(jmesserly): this was taken from error_verifier.dart
bool hasNoSuchMethod(ClassElement classElement) {
  // TODO(jmesserly): this is slow in Analyzer. It's a linear scan through all
  // methods, up through the class hierarchy.
  var method = classElement.lookUpMethod(
      FunctionElement.NO_SUCH_METHOD_METHOD_NAME, classElement.library);
  var definingClass = method?.enclosingElement;
  return definingClass is ClassElement && !definingClass.type.isObject;
}

/// Returns true if this class is of the form:
/// `class C = Object with M [implements I1, I2 ...];`
///
/// A mixin alias class is a mixin application, that can also be itself used as
/// a mixin.
bool isMixinAliasClass(ClassElement c) {
  return c.isMixinApplication && c.supertype.isObject && c.mixins.length == 1;
}

bool isCallableClass(ClassElement c) {
  // See if we have a "call" with a statically known function type:
  //
  // - if it's a method, then it does because all methods do,
  // - if it's a getter, check the return type.
  //
  // Other cases like a getter returning dynamic/Object/Function will be
  // handled at runtime by the dynamic call mechanism. So we only
  // concern ourselves with statically known function types.
  //
  // We can ignore `noSuchMethod` because:
  // * `dynamic d; d();` without a declared `call` method is handled by dcall.
  // * for `class C implements Callable { noSuchMethod(i) { ... } }` we find
  //   the `call` method on the `Callable` interface.
  var callMethod = c.type.lookUpInheritedGetterOrMethod('call');
  return callMethod is PropertyAccessorElement
      ? callMethod.returnType is FunctionType
      : callMethod != null;
}

/// Returns true if [x] and [y] are equal, in other words, `x <: y` and `y <: x`
/// and they have equivalent display form when printed.
//
// TODO(jmesserly): this exists to work around broken FunctionTypeImpl.== in
// Analyzer. It has two bugs:
// - typeArguments are considered, even though this has no semantic effect.
//   For example: `int -> int` that resulted from `(<T>(T) -> T)<int>` will not
//   equal another `int -> int`, even though they are the same type.
// - named arguments are incorrectly treated as ordered, see
//   https://github.com/dart-lang/sdk/issues/26126.
bool typesAreEqual(DartType x, DartType y) {
  if (identical(x, y)) return true;
  if (x is FunctionType) {
    if (y is FunctionType) {
      if (x.typeFormals.length != y.typeFormals.length) {
        return false;
      }
      // `<T>T -> T` should be equal to `<U>U -> U`
      // To test this, we instantiate both types with the same (unique) type
      // variables, and see if the result is equal.
      if (x.typeFormals.isNotEmpty) {
        var fresh = FunctionTypeImpl.relateTypeFormals(
            x, y, (t, s, _, __) => typesAreEqual(t, s));
        if (fresh == null) {
          return false;
        }
        return typesAreEqual(x.instantiate(fresh), y.instantiate(fresh));
      }

      return typesAreEqual(x.returnType, y.returnType) &&
          _argumentsAreEqual(x.normalParameterTypes, y.normalParameterTypes) &&
          _argumentsAreEqual(
              x.optionalParameterTypes, y.optionalParameterTypes) &&
          _namedArgumentsAreEqual(x.namedParameterTypes, y.namedParameterTypes);
    } else {
      return false;
    }
  }
  if (x is InterfaceType) {
    return y is InterfaceType &&
        x.element == y.element &&
        _argumentsAreEqual(x.typeArguments, y.typeArguments);
  }
  return x == y;
}

bool _argumentsAreEqual(List<DartType> first, List<DartType> second) {
  if (first.length != second.length) return false;
  for (int i = 0; i < first.length; i++) {
    if (!typesAreEqual(first[i], second[i])) return false;
  }
  return true;
}

bool _namedArgumentsAreEqual(
    Map<String, DartType> xArgs, Map<String, DartType> yArgs) {
  if (yArgs.length != xArgs.length) return false;
  for (var name in xArgs.keys) {
    var x = xArgs[name];
    var y = yArgs[name];
    if (y == null || !typesAreEqual(x, y)) return false;
  }
  return true;
}

/// Returns a valid hashCode for [t] for use with [typesAreEqual].
int typeHashCode(DartType t) {
  // TODO(jmesserly): this is from Analyzer; it's not a great hash function.
  // We should at least fix how this combines hashes.
  if (t is FunctionType) {
    if (t.typeFormals.isNotEmpty) {
      // Instantiate the generic function type, so we hash equivalent
      // generic function types to the same value. For example, `<X>(X) -> X`
      // and `<Y>(Y) -> Y` shouold have the same hash.
      //
      // TODO(jmesserly): it would be better to instantiate these with unique
      // types for each position, so we can distinguish cases like these:
      //
      //     <A, B>(A) -> B
      //     <C, D>(D) -> C      // reversed
      //     <E, F>(E) -> void   // uses `void`
      //
      // Currently all of those will have the same hash code.
      //
      // The choice of `void` is rather arbitrary. Of the types we can easily
      // obtain from Analyzer, it should collide a bit less than something like
      // `dynamic`.
      int code = t.typeFormals.length;
      code = (code << 1) +
          typeHashCode(t.instantiate(
              List.filled(t.typeFormals.length, VoidTypeImpl.instance)));
      return code;
    }
    int code = typeHashCode(t.returnType);
    for (var p in t.normalParameterTypes) {
      code = (code << 1) + typeHashCode(p);
    }
    for (var p in t.optionalParameterTypes) {
      code = (code << 1) + typeHashCode(p);
    }
    for (var p in t.namedParameterTypes.values) {
      code ^= typeHashCode(p); // xor because named parameters are unordered.
    }
    return code;
  }
  return t.hashCode;
}

Uri uriForCompilationUnit(CompilationUnitElement unit) {
  if (unit.source.isInSystemLibrary) {
    return unit.source.uri;
  }
  // TODO(jmesserly): this needs serious cleanup.
  // There does appear to be something strange going on with Analyzer
  // URIs if we try and use them directly on Windows.
  // See also compiler.dart placeSourceMap, which could use cleanup too.
  var sourcePath = unit.source.fullName;
  return sourcePath.startsWith('package:')
      ? Uri.parse(sourcePath)
      // TODO(jmesserly): shouldn't this be path.toUri?
      : Uri.file(sourcePath);
}

/// Returns true iff this factory constructor just throws [UnsupportedError]/
///
/// `dart:html` has many of these.
bool isUnsupportedFactoryConstructor(ConstructorDeclaration node) {
  var ctorBody = node.body;
  var element = node.declaredElement;
  if (element.isPrivate &&
      element.librarySource.isInSystemLibrary &&
      ctorBody is BlockFunctionBody) {
    var statements = ctorBody.block.statements;
    if (statements.length == 1) {
      var statement = statements[0];
      if (statement is ExpressionStatement) {
        var expr = statement.expression;
        if (expr is ThrowExpression &&
            expr.expression is InstanceCreationExpression) {
          if (expr.expression.staticType.name == 'UnsupportedError') {
            // HTML adds a lot of private constructors that are unreachable.
            // Skip these.
            return true;
          }
        }
      }
    }
  }
  return false;
}

bool isBuiltinAnnotation(
    DartObjectImpl value, String libraryName, String annotationName) {
  var e = value?.type?.element;
  if (e?.name != annotationName) return false;
  var uri = e.source.uri;
  var path = uri.pathSegments[0];
  return uri.scheme == 'dart' && path == libraryName;
}

/// Returns the integer value for [node] as a [BigInt].
///
/// `node.value` should not be used directly as it depends on platform integers
/// and may be `null` for some valid integer literals (in either an `int` or a
/// `double` context)
BigInt getLiteralBigIntValue(IntegerLiteral node) {
  // TODO(jmesserly): workaround for #34360: Analyzer tree does not store
  // the BigInt or double value, so we need to re-parse it from the token.
  return BigInt.parse(node.literal.lexeme);
}
