// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.registry;

import '../dart_types.dart' show InterfaceType;
import '../elements/elements.dart' show Element;
import '../enqueue.dart' show Enqueuer;
import '../universe/use.dart' show DynamicUse, StaticUse;

/// Interface for registration of element dependencies.
abstract class Registry {
  // TODO(johnniwinther): Remove this.
  void registerDependency(Element element) {}

  bool get isForResolution;

  void registerDynamicUse(DynamicUse staticUse);

  void registerStaticUse(StaticUse staticUse);

  void registerInstantiation(InterfaceType type);
}

// TODO(johnniwinther): Remove this.
class EagerRegistry extends Registry {
  final String name;
  final Enqueuer world;

  EagerRegistry(this.name, this.world);

  bool get isForResolution => world.isResolutionQueue;

  @override
  void registerDynamicUse(DynamicUse dynamicUse) {
    world.registerDynamicUse(dynamicUse);
  }

  @override
  void registerInstantiation(InterfaceType type) {
    world.registerInstantiatedType(type);
  }

  @override
  void registerStaticUse(StaticUse staticUse) {
    world.registerStaticUse(staticUse);
  }

  String toString() => name;
}
