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
