// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/utilities_dart.dart';

import '../js_ast/js_ast.dart' as JS;
import 'compiler.dart' show CompilerOptions;
import 'js_interop.dart';

/// Mixin with logic to generate [TypeRef]s out of [DartType]s.
abstract class JsTypeRefCodegen {
  final _resolved = <DartType, JS.TypeRef>{};

  // Mixin dependencies:
  CompilerOptions get options;
  TypeProvider get types;
  LibraryElement get dartJSLibrary;
  JS.Identifier get namedArgumentTemp;
  JS.Identifier emitLibraryName(LibraryElement e);

  /// Finds the qualified path to the type.
  JS.TypeRef _emitTopLevelTypeRef(DartType type) {
    var e = type.element;
    return new JS.TypeRef.qualified([
      emitLibraryName(e.library),
      new JS.Identifier(getJSExportName(e) ?? e.name)
    ]);
  }

  JS.TypeRef emitTypeRef(DartType type) {
    if (!options.closure) return null;

    return _resolved.putIfAbsent(type, () {
      if (type == null) new JS.TypeRef.unknown();
      // TODO(ochafik): Consider calling _loader.declareBeforeUse(type.element).
      if (type.isBottom || type.isDynamic) new JS.TypeRef.any();
      if (type.isVoid) return new JS.TypeRef.void_();

      if (type == types.intType) return new JS.TypeRef.number().orNull();
      if (type == types.numType) return new JS.TypeRef.number().orNull();
      if (type == types.doubleType) return new JS.TypeRef.number().orNull();
      if (type == types.boolType) return new JS.TypeRef.boolean().orNull();
      if (type == types.stringType) return new JS.TypeRef.string();

      if (type is TypeParameterType) return new JS.TypeRef.named(type.name);
      if (type is ParameterizedType) {
        JS.TypeRef rawType;
        if (type is FunctionType && type.name == null) {
          var args = <JS.Identifier, JS.TypeRef>{};
          for (var param in type.parameters) {
            if (param.parameterKind == ParameterKind.NAMED) break;
            var type = emitTypeRef(param.type);
            args[new JS.Identifier(param.name)] =
                param.parameterKind == ParameterKind.POSITIONAL
                    ? type.toOptional()
                    : type;
          }
          var namedParamType = emitNamedParamsArgType(type.parameters);
          if (namedParamType != null) {
            args[namedArgumentTemp] = namedParamType.toOptional();
          }

          rawType = new JS.TypeRef.function(emitTypeRef(type.returnType), args);
        } else {
          var jsTypeRef = _getDartJsTypeRef(type);
          if (jsTypeRef != null) return jsTypeRef;

          rawType = _emitTopLevelTypeRef(type);
        }
        var typeArgs = _getOwnTypeArguments(type).map(emitTypeRef);
        return typeArgs.isEmpty
            ? rawType
            : new JS.TypeRef.generic(rawType, typeArgs);
      }
      return new JS.TypeRef.unknown();
    });
  }

  JS.TypeRef emitNamedParamsArgType(List<ParameterElement> params) {
    if (!options.closure) return null;

    var namedArgs = <JS.Identifier, JS.TypeRef>{};
    for (ParameterElement param in params) {
      if (param.parameterKind != ParameterKind.NAMED) continue;
      namedArgs[new JS.Identifier(param.name)] =
          emitTypeRef(param.type).toOptional();
    }
    if (namedArgs.isEmpty) return null;
    return new JS.TypeRef.record(namedArgs);
  }

  /// Gets the "own" type arguments of [type].
  ///
  /// Method argument with adhoc unnamed [FunctionType] inherit any type params
  /// from their enclosing class:
  ///
  ///      class Foo<T> {
  ///        void method(f()); // f has [T] as type arguments,
  ///      }                   // but [] as its "own" type arguments.
  Iterable<DartType> _getOwnTypeArguments(ParameterizedType type) sync* {
    for (int i = 0, n = type.typeParameters.length; i < n; i++) {
      if (type.typeParameters[i].enclosingElement == type.element) {
        yield type.typeArguments[i];
      }
    }
  }

  /// Special treatment of types from dart:js
  /// TODO(ochafik): Is this the right thing to do? And what about package:js?
  JS.TypeRef _getDartJsTypeRef(DartType type) {
    if (type.element.library == dartJSLibrary) {
      switch (type.name) {
        case 'JsArray':
          return new JS.TypeRef.array(
              type is InterfaceType && type.typeArguments.length == 1
                  ? emitTypeRef(type.typeArguments.single)
                  : null);
        case 'JsObject':
          return new JS.TypeRef.object();
        case 'JsFunction':
          return new JS.TypeRef.function();
      }
    }
    return null;
  }
}
