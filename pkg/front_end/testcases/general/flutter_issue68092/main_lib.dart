// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

class DynamicDispatchRegistry<T extends Function> {
  T register(T function) => null;
}

class Registry extends DynamicDispatchRegistry<int Function({int x})> {}
