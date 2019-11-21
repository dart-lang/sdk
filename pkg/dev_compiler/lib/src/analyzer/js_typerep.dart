// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart' show ClassElement;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/type_system.dart' show TypeSystemImpl;

import '../compiler/js_typerep.dart';
import 'driver.dart';
import 'type_utilities.dart';

class JSTypeRep extends SharedJSTypeRep<DartType> {
  final TypeSystemImpl rules;
  final TypeProvider types;

  final ClassElement _jsBool;
  final ClassElement _jsNumber;
  final ClassElement _jsString;

  JSTypeRep(this.rules, LinkedAnalysisDriver driver)
      : types = driver.typeProvider,
        _jsBool = driver.getClass('dart:_interceptors', 'JSBool'),
        _jsString = driver.getClass('dart:_interceptors', 'JSString'),
        _jsNumber = driver.getClass('dart:_interceptors', 'JSNumber');

  @override
  JSType typeFor(DartType type) {
    while (type is TypeParameterType) {
      type = (type as TypeParameterType).element.bound;
    }
    if (type == null) return JSType.jsUnknown;
    if (type.isDartCoreNull) return JSType.jsNull;
    // Note that this should be changed if Dart gets non-nullable types
    if (type.isBottom) return JSType.jsNull;
    if (rules.isSubtypeOf(type, types.numType)) return JSType.jsNumber;
    if (rules.isSubtypeOf(type, types.boolType)) return JSType.jsBoolean;
    if (rules.isSubtypeOf(type, types.stringType)) return JSType.jsString;
    if (type.isDartAsyncFutureOr) {
      var argument = (type as InterfaceType).typeArguments[0];
      var argumentRep = typeFor(argument);
      if (argumentRep is JSObject || argumentRep is JSNull) {
        return JSType.jsObject;
      }
      return JSType.jsUnknown;
    }
    if (type.isDynamic || type.isObject || type.isVoid) return JSType.jsUnknown;
    return JSType.jsObject;
  }

  /// Given a Dart type return the known implementation type, if any.
  /// Given `bool`, `String`, or `num`/`int`/`double`,
  /// returns the corresponding type in `dart:_interceptors`:
  /// `JSBool`, `JSString`, and `JSNumber` respectively, otherwise null.
  InterfaceType getImplementationType(DartType t) {
    var rep = typeFor(t);
    // Number, String, and Bool are final
    if (rep == JSType.jsNumber) return getLegacyRawClassType(_jsNumber);
    if (rep == JSType.jsBoolean) return getLegacyRawClassType(_jsBool);
    if (rep == JSType.jsString) return getLegacyRawClassType(_jsString);
    return null;
  }
}
