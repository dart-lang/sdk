// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.task;

import 'dart:async' show Future;

import '../../compiler_new.dart';
import '../common/resolution.dart' show ResolutionImpact, ResolutionWorkItem;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/elements.dart';
import '../elements/entities.dart' show Entity;
import '../universe/world_impact.dart' show WorldImpact;
import 'json_serializer.dart';
import 'serialization.dart';
import 'system.dart';

/// A deserializer that can load a library element by reading it's information
/// from a serialized form.
abstract class LibraryDeserializer {
  /// Loads the [LibraryElement] associated with a library under [uri], or null
  /// if no serialized information is available for the given library.
  Future<LibraryElement> readLibrary(Uri uri);

  /// Returns `true` if [element] has been deserialized.
  bool isDeserialized(Entity element);
}

/// Task that supports deserialization of elements.
class SerializationTask extends CompilerTask implements LibraryDeserializer {
  final Compiler compiler;
  SerializationTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer);

  DeserializerSystem deserializer;

  String get name => 'Serialization';

  /// If `true`, data must be retained to support serialization.
  // TODO(johnniwinther): Make this more precise in terms of what needs to be
  // retained, for instance impacts, resolution data etc.
  bool supportSerialization = false;

  /// Set this flag to also deserialize [ResolvedAst]s and [ResolutionImpact]s
  /// in `resolveOnly` mode. Use this for testing only.
  bool deserializeCompilationDataForTesting = false;

  /// If `true`, deserialized data is supported.
  bool get supportsDeserialization => deserializer != null;

  /// Returns the [LibraryElement] for [resolvedUri] if available from
  /// serialization.
  Future<LibraryElement> readLibrary(Uri resolvedUri) {
    if (deserializer == null) return new Future<LibraryElement>.value();
    return deserializer.readLibrary(resolvedUri);
  }

  /// Returns `true` if [element] has been deserialized.
  bool isDeserialized(Entity element) {
    return deserializer != null && deserializer.isDeserialized(element);
  }

  bool hasResolutionImpact(Element element) {
    return deserializer != null && deserializer.hasResolutionImpact(element);
  }

  ResolutionImpact getResolutionImpact(Element element) {
    return deserializer != null
        ? deserializer.getResolutionImpact(element)
        : null;
  }

  /// Creates the [ResolutionWorkItem] for the deserialized [element].
  ResolutionWorkItem createResolutionWorkItem(MemberElement element) {
    assert(deserializer != null);
    assert(isDeserialized(element));
    return new DeserializedResolutionWorkItem(
        element, deserializer.computeWorldImpact(element));
  }

  bool hasResolvedAst(ExecutableElement element) {
    return deserializer != null ? deserializer.hasResolvedAst(element) : false;
  }

  ResolvedAst getResolvedAst(ExecutableElement element) {
    return deserializer != null ? deserializer.getResolvedAst(element) : null;
  }

  Serializer createSerializer(Iterable<LibraryElement> libraries) {
    return measure(() {
      assert(supportSerialization);

      Serializer serializer =
          new Serializer(shouldInclude: (e) => libraries.contains(e.library));
      SerializerPlugin backendSerializer =
          compiler.backend.serialization.serializer;
      serializer.plugins.add(backendSerializer);
      serializer.plugins.add(new ResolutionImpactSerializer(
          compiler.resolution, backendSerializer));
      serializer.plugins.add(new ResolvedAstSerializerPlugin(
          compiler.resolution, backendSerializer));

      for (LibraryElement library in libraries) {
        serializer.serialize(library);
      }
      return serializer;
    });
  }

  void serializeToSink(OutputSink sink, Iterable<LibraryElement> libraries) {
    measure(() {
      sink
        ..add(createSerializer(libraries)
            .toText(const JsonSerializationEncoder()))
        ..close();
    });
  }

  void deserializeFromText(Uri sourceUri, String serializedData) {
    measure(() {
      if (deserializer == null) {
        deserializer = new ResolutionDeserializerSystem(compiler,
            deserializeCompilationDataForTesting:
                deserializeCompilationDataForTesting);
      }
      ResolutionDeserializerSystem deserializerImpl = deserializer;
      DeserializationContext context = deserializerImpl.deserializationContext;
      Deserializer dataDeserializer = new Deserializer.fromText(
          context, sourceUri, serializedData, const JsonSerializationDecoder());
      context.deserializers.add(dataDeserializer);
    });
  }
}

/// A [ResolutionWorkItem] for a deserialized element.
///
/// This will not resolve the element but only compute the [WorldImpact].
class DeserializedResolutionWorkItem implements ResolutionWorkItem {
  final MemberElement element;
  final WorldImpact worldImpact;

  DeserializedResolutionWorkItem(this.element, this.worldImpact);

  @override
  WorldImpact run() {
    return worldImpact;
  }
}

/// The interface for a system that supports deserialization of libraries and
/// elements.
abstract class DeserializerSystem {
  Future<LibraryElement> readLibrary(Uri resolvedUri);
  bool isDeserialized(Entity element);
  bool hasResolvedAst(ExecutableElement element);
  ResolvedAst getResolvedAst(ExecutableElement element);
  bool hasResolutionImpact(Element element);
  ResolutionImpact getResolutionImpact(Element element);
  WorldImpact computeWorldImpact(Element element);
}
