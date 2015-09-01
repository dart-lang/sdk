// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.registry;

import '../dart_types.dart' show
  InterfaceType;
import '../elements/elements.dart' show
  Element,
  FunctionElement;
import '../universe/universe.dart' show
  UniverseSelector;

/// Interface for registration of element dependencies.
abstract class Registry {
  // TODO(johnniwinther): Remove this getter when [Registry] creates a
  // dependency node.
  Iterable<Element> get otherDependencies;

  void registerDependency(Element element);

  bool get isForResolution;

  void registerDynamicInvocation(UniverseSelector selector);

  void registerDynamicGetter(UniverseSelector selector);

  void registerDynamicSetter(UniverseSelector selector);

  void registerStaticInvocation(Element element);

  void registerInstantiation(InterfaceType type);

  void registerGetOfStaticFunction(FunctionElement element);
}
