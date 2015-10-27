// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.registry;

import '../dart_types.dart' show
    InterfaceType;
import '../enqueue.dart' show
    Enqueuer;
import '../elements/elements.dart' show
    Element,
    FunctionElement;
import '../universe/universe.dart' show
    UniverseSelector;

/// Interface for registration of element dependencies.
abstract class Registry {
  // TODO(johnniwinther): Remove this.
  void registerDependency(Element element) {}

  bool get isForResolution;

  void registerDynamicInvocation(UniverseSelector selector);

  void registerDynamicGetter(UniverseSelector selector);

  void registerDynamicSetter(UniverseSelector selector);

  void registerStaticInvocation(Element element);

  void registerInstantiation(InterfaceType type);

  void registerGetOfStaticFunction(FunctionElement element);
}

// TODO(johnniwinther): Remove this.
class EagerRegistry extends Registry {
  final String name;
  final Enqueuer world;

  EagerRegistry(this.name, this.world);

  bool get isForResolution => world.isResolutionQueue;

  @override
  void registerDynamicGetter(UniverseSelector selector) {
    world.registerDynamicGetter(selector);
  }

  @override
  void registerDynamicInvocation(UniverseSelector selector) {
    world.registerDynamicInvocation(selector);
  }

  @override
  void registerDynamicSetter(UniverseSelector selector) {
    world.registerDynamicSetter(selector);
  }

  @override
  void registerGetOfStaticFunction(FunctionElement element) {
    world.registerGetOfStaticFunction(element);
  }

  @override
  void registerInstantiation(InterfaceType type) {
    world.registerInstantiatedType(type);
  }

  @override
  void registerStaticInvocation(Element element) {
    world.registerStaticUse(element);
  }

  String toString() => name;
}
