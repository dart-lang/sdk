// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.task;

import '../dart2jslib.dart';
import '../elements/elements.dart';

/// Task that supports deserialization of elements.
class SerializationTask extends CompilerTask {
  SerializationTask(Compiler compiler) : super(compiler);

  DeserializerSystem deserializer;

  String get name => 'Serialization';

  /// Returns the [LibraryElement] for [resolvedUri] if available from
  /// serialization.
  LibraryElement readLibrary(Uri resolvedUri) {
    if (deserializer == null) return null;
    return deserializer.readLibrary(resolvedUri);
  }

  /// Returns `true` if [element] has been deserialized.
  bool isDeserialized(Element element) {
    return deserializer != null && deserializer.isDeserialized(element);
  }

  /// Creates the [ResolutionWorkItem] for the deserialized [element].
  ResolutionWorkItem createResolutionWorkItem(
      Element element, ItemCompilationContext context) {
    assert(deserializer != null);
    assert(isDeserialized(element));
    return new DeserializedResolutionWorkItem(
        element, context, deserializer.computeWorldImpact(element));
  }
}

/// A [ResolutionWorkItem] for a deserialized element.
///
/// This will not resolve the element but only compute the [WorldImpact].
class DeserializedResolutionWorkItem implements ResolutionWorkItem {
  final Element element;
  final ItemCompilationContext compilationContext;
  final WorldImpact worldImpact;
  bool _isAnalyzed = false;

  DeserializedResolutionWorkItem(
      this.element, this.compilationContext, this.worldImpact);

  @override
  bool get isAnalyzed => _isAnalyzed;

  @override
  WorldImpact run(Compiler compiler, ResolutionEnqueuer world) {
    _isAnalyzed = true;
    world.registerResolvedElement(element);
    return worldImpact;
  }
}

/// The interface for a system that supports deserialization of libraries and
/// elements.
abstract class DeserializerSystem {
  LibraryElement readLibrary(Uri resolvedUri);
  bool isDeserialized(Element element);
  WorldImpact computeWorldImpact(Element element);
}
