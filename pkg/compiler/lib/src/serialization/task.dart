// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.task;

import 'dart:async' show Future;
import '../common/resolution.dart' show ResolutionImpact, ResolutionWorkItem;
import '../common/tasks.dart' show CompilerTask;
import '../common/work.dart' show ItemCompilationContext;
import '../compiler.dart' show Compiler;
import '../elements/elements.dart';
import '../enqueue.dart' show ResolutionEnqueuer;
import '../universe/world_impact.dart' show WorldImpact;

/// A deserializer that can load a library element by reading it's information
/// from a serialized form.
abstract class LibraryDeserializer {
  /// Loads the [LibraryElement] associated with a library under [uri], or null
  /// if no serialized information is available for the given library.
  Future<LibraryElement> readLibrary(Uri uri);
}

/// Task that supports deserialization of elements.
class SerializationTask extends CompilerTask implements LibraryDeserializer {
  SerializationTask(Compiler compiler) : super(compiler);

  DeserializerSystem deserializer;

  String get name => 'Serialization';

  /// If `true`, data must be retained to support serialization.
  // TODO(johnniwinther): Make this more precise in terms of what needs to be
  // retained, for instance impacts, resolution data etc.
  bool supportSerialization = false;

  /// Returns the [LibraryElement] for [resolvedUri] if available from
  /// serialization.
  Future<LibraryElement> readLibrary(Uri resolvedUri) {
    if (deserializer == null) return new Future<LibraryElement>.value();
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
    world.registerProcessedElement(element);
    return worldImpact;
  }
}

/// The interface for a system that supports deserialization of libraries and
/// elements.
abstract class DeserializerSystem {
  Future<LibraryElement> readLibrary(Uri resolvedUri);
  bool isDeserialized(Element element);
  ResolvedAst getResolvedAst(Element element);
  ResolutionImpact getResolutionImpact(Element element);
  WorldImpact computeWorldImpact(Element element);
}
