// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../fragment/fragment.dart';
import 'source_loader.dart' show SourceLoader;

class NativeMethodRegistry {
  final List<FactoryFragment> _nativeFactoryFragments = [];

  final List<GetterFragment> _nativeGetterFragments = [];

  final List<SetterFragment> _nativeSetterFragments = [];

  final List<MethodFragment> _nativeMethodFragments = [];

  final List<ConstructorFragment> _nativeConstructorFragments = [];

  void registerNativeGetterFragment(GetterFragment fragment) {
    _nativeGetterFragments.add(fragment);
  }

  void registerNativeSetterFragment(SetterFragment fragment) {
    _nativeSetterFragments.add(fragment);
  }

  void registerNativeMethodFragment(MethodFragment fragment) {
    _nativeMethodFragments.add(fragment);
  }

  void registerNativeConstructorFragment(ConstructorFragment fragment) {
    _nativeConstructorFragments.add(fragment);
  }

  void registerNativeFactoryFragment(FactoryFragment method) {
    _nativeFactoryFragments.add(method);
  }

  int finishNativeMethods(SourceLoader loader) {
    for (FactoryFragment fragment in _nativeFactoryFragments) {
      fragment.declaration.becomeNative(loader);
    }
    for (GetterFragment fragment in _nativeGetterFragments) {
      fragment.declaration.becomeNative(loader);
    }
    for (SetterFragment fragment in _nativeSetterFragments) {
      fragment.declaration.becomeNative(loader);
    }
    for (MethodFragment fragment in _nativeMethodFragments) {
      fragment.declaration.becomeNative(loader);
    }
    for (ConstructorFragment fragment in _nativeConstructorFragments) {
      fragment.declaration.becomeNative(loader);
    }
    return _nativeFactoryFragments.length;
  }
}
