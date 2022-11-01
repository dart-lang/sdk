// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/elements.dart';
import '../elements/entities.dart';
import '../js_backend/native_data.dart';

/// Returns a unique suffix for an intercepted accesses to [classes]. This is
/// used as the suffix for emitted interceptor methods and as the unique key
/// used to distinguish equivalences of sets of intercepted classes.
String suffixForGetInterceptor(CommonElements commonElements,
    NativeData nativeData, Iterable<ClassEntity> classes) {
  String abbreviate(ClassEntity cls) {
    if (cls == commonElements.objectClass) return "o";
    if (cls == commonElements.jsStringClass) return "s";
    if (cls == commonElements.jsArrayClass) return "a";
    if (cls == commonElements.jsNumNotIntClass) return "d";
    if (cls == commonElements.jsIntClass) return "i";
    if (cls == commonElements.jsNumberClass) return "n";
    if (cls == commonElements.jsNullClass) return "u";
    if (cls == commonElements.jsBoolClass) return "b";
    if (cls == commonElements.jsInterceptorClass) return "I";
    return cls.name;
  }

  List<String> names = classes
      .where((cls) => !nativeData.isNativeOrExtendsNative(cls))
      .map(abbreviate)
      .toList();
  // There is one dispatch mechanism for all native classes.
  if (classes.any((cls) => nativeData.isNativeOrExtendsNative(cls))) {
    names.add("x");
  }
  // Sort the names of the classes after abbreviating them to ensure
  // the suffix is stable and predictable for the suggested names.
  names.sort();
  return names.join();
}

/// Fixed names usage by the namer.
class FixedNames {
  const FixedNames();

  String get getterPrefix => r'get$';
  String get setterPrefix => r'set$';
  String get callPrefix => 'call';
  String get callCatchAllName => r'call*';
  String get callNameField => r'$callName';
  String get defaultValuesField => r'$defaultValues';
  String get deferredAction => r'$deferredAction';
  String get operatorIsPrefix => r'$is';
  String get operatorSignature => r'$signature';
  String get requiredParameterField => r'$requiredArgCount';
  String get rtiName => r'$ti';
}

String? operatorNameToIdentifier(String? name) {
  if (name == null) return null;
  if (name == '==') {
    return r'$eq';
  } else if (name == '~') {
    return r'$not';
  } else if (name == '[]') {
    return r'$index';
  } else if (name == '[]=') {
    return r'$indexSet';
  } else if (name == '*') {
    return r'$mul';
  } else if (name == '/') {
    return r'$div';
  } else if (name == '%') {
    return r'$mod';
  } else if (name == '~/') {
    return r'$tdiv';
  } else if (name == '+') {
    return r'$add';
  } else if (name == '<<') {
    return r'$shl';
  } else if (name == '>>') {
    return r'$shr';
  } else if (name == '>>>') {
    return r'$shru';
  } else if (name == '>=') {
    return r'$ge';
  } else if (name == '>') {
    return r'$gt';
  } else if (name == '<=') {
    return r'$le';
  } else if (name == '<') {
    return r'$lt';
  } else if (name == '&') {
    return r'$and';
  } else if (name == '^') {
    return r'$xor';
  } else if (name == '|') {
    return r'$or';
  } else if (name == '-') {
    return r'$sub';
  } else if (name == 'unary-') {
    return r'$negate';
  } else {
    return name;
  }
}
