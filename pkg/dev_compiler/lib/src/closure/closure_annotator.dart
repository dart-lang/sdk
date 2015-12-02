// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.closure.closure_codegen;

import 'package:analyzer/analyzer.dart' show ParameterKind;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;

import 'closure_annotation.dart';
import 'closure_type.dart';

/// Mixin that can generate [ClosureAnnotation]s for Dart elements and types.
abstract class ClosureAnnotator {
  TypeProvider get types;

  /// Must return a JavaScript qualified name that can be used to refer to [type].
  String getQualifiedName(TypeDefiningElement type);

  ClosureAnnotation closureAnnotationForVariable(VariableElement e) =>
      new ClosureAnnotation(
          type: _closureTypeForDartType(e.type),
          // Note: we don't set isConst here because Closure's constness and
          // Dart's are not really compatible.
          isFinal: e.isFinal || e.isConst);

  /// We don't use Closure's `@typedef` annotations
  ClosureAnnotation closureAnnotationForTypeDef(FunctionTypeAliasElement e) =>
      new ClosureAnnotation(
          type: _closureTypeForDartType(e.type, forceTypeDefExpansion: true),
          isTypedef: true);

  ClosureAnnotation closureAnnotationForDefaultConstructor(ClassElement e) =>
      new ClosureAnnotation(
          superType: _closureTypeForDartType(e.supertype),
          interfaces: e.interfaces.map(_closureTypeForDartType).toList());

  // TODO(ochafik): Handle destructured params when Closure supports it.
  ClosureAnnotation closureAnnotationFor(
      ExecutableElement e, String namedArgsMapName) {
    var paramTypes = <String, ClosureType>{};
    var namedArgs = <String, ClosureType>{};
    for (var param in e.parameters) {
      var t = _closureTypeForDartType(param.type);
      switch (param.parameterKind) {
        case ParameterKind.NAMED:
          namedArgs[param.name] = t.orUndefined();
          break;
        case ParameterKind.POSITIONAL:
          paramTypes[param.name] = t.toOptional();
          break;
        case ParameterKind.REQUIRED:
          paramTypes[param.name] = t;
          break;
      }
    }
    if (namedArgs.isNotEmpty) {
      paramTypes[namedArgsMapName] =
          new ClosureType.record(namedArgs).toOptional();
    }

    var returnType = e is ConstructorElement
        ? (e.isFactory ? _closureTypeForClass(e.enclosingElement) : null)
        : _closureTypeForDartType(e.returnType);

    return new ClosureAnnotation(
        isOverride: e.isOverride,
        // Note: Dart and Closure privacy are not compatible: don't set `isPrivate: e.isPrivate`.
        paramTypes: paramTypes,
        returnType: returnType);
  }

  Map<DartType, ClosureType> __commonTypes;
  Map<DartType, ClosureType> get _commonTypes {
    if (__commonTypes == null) {
      var numberType = new ClosureType.number().toNullable();
      __commonTypes = {
        types.intType: numberType,
        types.numType: numberType,
        types.doubleType: numberType,
        types.boolType: new ClosureType.boolean().toNullable(),
        types.stringType: new ClosureType.string(),
      };
    }
    return __commonTypes;
  }

  ClosureType _closureTypeForClass(ClassElement classElement, [DartType type]) {
    ClosureType closureType = _commonTypes[type];
    if (closureType != null) return closureType;

    var fullName = _getFullName(classElement);
    switch (fullName) {
      // TODO(ochafik): Test DartTypes directly if possible.
      case "dart.js.JsArray":
        return new ClosureType.array(
            type is InterfaceType && type.typeArguments.length == 1
                ? _closureTypeForDartType(type.typeArguments.single)
                : null);
      case "dart.js.JsObject":
        return new ClosureType.map();
      case "dart.js.JsFunction":
        return new ClosureType.function();
      default:
        return new ClosureType.type(getQualifiedName(classElement));
    }
  }

  ClosureType _closureTypeForDartType(DartType type,
      {bool forceTypeDefExpansion: false}) {
    if (type == null || type.isBottom || type.isDynamic) {
      return new ClosureType.unknown();
    }
    if (type.isVoid) return null;
    if (type is FunctionType) {
      if (!forceTypeDefExpansion && type.element.name != '') {
        return new ClosureType.type(getQualifiedName(type.element));
      }

      var args = []
        ..addAll(type.normalParameterTypes.map(_closureTypeForDartType))
        ..addAll(type.optionalParameterTypes
            .map((t) => _closureTypeForDartType(t).toOptional()));
      if (type.namedParameterTypes.isNotEmpty) {
        var namedArgs = <String, ClosureType>{};
        type.namedParameterTypes.forEach((n, t) {
          namedArgs[n] = _closureTypeForDartType(t).orUndefined();
        });
        args.add(new ClosureType.record(namedArgs).toOptional());
      }
      return new ClosureType.function(
          args, _closureTypeForDartType(type.returnType));
    }
    if (type is InterfaceType) {
      return _closureTypeForClass(type.element, type);
    }
    return new ClosureType.unknown();
  }

  /// TODO(ochafik): Use a package-and-file-uri-dependent naming, since libraries can collide.
  String _getFullName(ClassElement type) =>
      type.library.name == '' ? type.name : '${type.library.name}.${type.name}';
}
