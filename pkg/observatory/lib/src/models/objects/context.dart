// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class ContextRef extends ObjectRef {
  /// The number of variables in this context.
  int? get length;
}

abstract class Context extends Object implements ContextRef {
  /// [optional] The enclosing context for this context.
  Context? get parentContext;

  // The variables in this context object.
  Iterable<ContextElement>? get variables;
}

abstract class ContextElement {
  Guarded<InstanceRef>? get value;
}
