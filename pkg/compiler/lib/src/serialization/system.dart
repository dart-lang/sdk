// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_system;

import 'dart:async';
import '../commandline_options.dart';
import '../common.dart';
import '../common/backend_api.dart';
import '../common/names.dart';
import '../common/resolution.dart';
import '../compiler.dart';
import '../elements/elements.dart';
import '../io/source_file.dart';
import '../scanner/scanner.dart';
import '../script.dart';
import '../serialization/impact_serialization.dart';
import '../tokens/token.dart';
import '../universe/call_structure.dart';
import '../universe/world_impact.dart';
import '../universe/use.dart';
import 'json_serializer.dart';
import 'modelz.dart';
import 'resolved_ast_serialization.dart';
import 'serialization.dart';
import 'task.dart';

class DeserializerSystemImpl extends DeserializerSystem {
  final Compiler _compiler;
  final DeserializationContext deserializationContext;
  final List<LibraryElement> deserializedLibraries = <LibraryElement>[];
  final ResolutionImpactDeserializer _resolutionImpactDeserializer;
  final ResolvedAstDeserializerPlugin _resolvedAstDeserializer;
  final ImpactTransformer _impactTransformer;

  factory DeserializerSystemImpl(
      Compiler compiler, ImpactTransformer impactTransformer) {
    DeserializationContext context =
        new DeserializationContext(compiler.reporter);
    DeserializerPlugin backendDeserializer =
        compiler.backend.serialization.deserializer;
    context.plugins.add(backendDeserializer);
    ResolutionImpactDeserializer resolutionImpactDeserializer =
        new ResolutionImpactDeserializer(backendDeserializer);
    context.plugins.add(resolutionImpactDeserializer);
    ResolvedAstDeserializerPlugin resolvedAstDeserializer =
        new ResolvedAstDeserializerPlugin(
            compiler.parsingContext, backendDeserializer);
    context.plugins.add(resolvedAstDeserializer);
    return new DeserializerSystemImpl._(compiler, context, impactTransformer,
        resolutionImpactDeserializer, resolvedAstDeserializer);
  }

  DeserializerSystemImpl._(
      this._compiler,
      this.deserializationContext,
      this._impactTransformer,
      this._resolutionImpactDeserializer,
      this._resolvedAstDeserializer);

  @override
  Future<LibraryElement> readLibrary(Uri resolvedUri) {
    LibraryElement library = deserializationContext.lookupLibrary(resolvedUri);
    if (library != null) {
      deserializedLibraries.add(library);
      return Future.forEach(library.compilationUnits,
          (CompilationUnitElement compilationUnit) {
        ScriptZ script = compilationUnit.script;
        return _compiler
            .readScript(script.readableUri)
            .then((Script newScript) {
          script.file = newScript.file;
          script.isSynthesized = newScript.isSynthesized;
          _resolvedAstDeserializer.scripts[script.resourceUri] = script;
        });
      }).then((_) => library);
    }
    return new Future<LibraryElement>.value(library);
  }

  // TODO(johnniwinther): Remove the need for this method.
  @override
  bool hasResolvedAst(ExecutableElement element) {
    return getResolvedAst(element) != null;
  }

  @override
  ResolvedAst getResolvedAst(ExecutableElement element) {
    return _resolvedAstDeserializer.getResolvedAst(element);
  }

  @override
  bool hasResolutionImpact(Element element) {
    if (element.isConstructor &&
        element.enclosingClass.isUnnamedMixinApplication) {
      return true;
    }
    return _resolutionImpactDeserializer.impactMap.containsKey(element);
  }

  @override
  ResolutionImpact getResolutionImpact(Element element) {
    if (element.isConstructor &&
        element.enclosingClass.isUnnamedMixinApplication) {
      ClassElement superclass = element.enclosingClass.superclass;
      ConstructorElement superclassConstructor =
          superclass.lookupConstructor(element.name);
      assert(invariant(element, superclassConstructor != null,
          message: "Superclass constructor '${element.name}' called from "
              "${element} not found in ${superclass}."));
      // TODO(johnniwinther): Compute callStructure. Currently not used.
      CallStructure callStructure;
      return _resolutionImpactDeserializer.impactMap.putIfAbsent(element, () {
        return new DeserializedResolutionImpact(staticUses: <StaticUse>[
          new StaticUse.superConstructorInvoke(
              superclassConstructor, callStructure)
        ]);
      });
    }
    return _resolutionImpactDeserializer.impactMap[element];
  }

  @override
  WorldImpact computeWorldImpact(Element element) {
    ResolutionImpact resolutionImpact = getResolutionImpact(element);
    assert(invariant(element, resolutionImpact != null,
        message: 'No impact found for $element (${element.library})'));
    if (element is ExecutableElement) {
      getResolvedAst(element);
    }
    return _impactTransformer.transformResolutionImpact(resolutionImpact);
  }

  @override
  bool isDeserialized(Element element) {
    return deserializedLibraries.contains(element.library);
  }
}

const String WORLD_IMPACT_TAG = 'worldImpact';

class ResolutionImpactSerializer extends SerializerPlugin {
  final Resolution resolution;
  final SerializerPlugin nativeDataSerializer;

  ResolutionImpactSerializer(this.resolution, this.nativeDataSerializer);

  @override
  void onElement(Element element, ObjectEncoder createEncoder(String tag)) {
    if (resolution.hasBeenResolved(element)) {
      ResolutionImpact impact = resolution.getResolutionImpact(element);
      ObjectEncoder encoder = createEncoder(WORLD_IMPACT_TAG);
      new ImpactSerializer(element, encoder, nativeDataSerializer)
          .serialize(impact);
    }
  }
}

class ResolutionImpactDeserializer extends DeserializerPlugin {
  Map<Element, ResolutionImpact> impactMap = <Element, ResolutionImpact>{};
  final DeserializerPlugin nativeDataDeserializer;

  ResolutionImpactDeserializer(this.nativeDataDeserializer);

  @override
  void onElement(Element element, ObjectDecoder getDecoder(String tag)) {
    ObjectDecoder decoder = getDecoder(WORLD_IMPACT_TAG);
    if (decoder != null) {
      impactMap[element] = ImpactDeserializer.deserializeImpact(
          element, decoder, nativeDataDeserializer);
    }
  }
}

const String RESOLVED_AST_TAG = 'resolvedAst';

class ResolvedAstSerializerPlugin extends SerializerPlugin {
  final Resolution resolution;
  final SerializerPlugin nativeDataSerializer;

  ResolvedAstSerializerPlugin(this.resolution, this.nativeDataSerializer);

  @override
  void onElement(Element element, ObjectEncoder createEncoder(String tag)) {
    assert(invariant(element, element.isDeclaration,
        message: "Element $element must be the declaration"));
    if (element is MemberElement) {
      assert(invariant(element, resolution.hasResolvedAst(element),
          message: "Element $element must have a resolved ast"));
      ResolvedAst resolvedAst = resolution.getResolvedAst(element);
      ObjectEncoder objectEncoder = createEncoder(RESOLVED_AST_TAG);
      new ResolvedAstSerializer(
              objectEncoder, resolvedAst, nativeDataSerializer)
          .serialize();
    }
  }
}

class ResolvedAstDeserializerPlugin extends DeserializerPlugin {
  final ParsingContext parsingContext;
  final DeserializerPlugin nativeDataDeserializer;
  final Map<Uri, Script> scripts = <Uri, Script>{};

  Map<MemberElement, ObjectDecoder> _decoderMap =
      <MemberElement, ObjectDecoder>{};
  Map<Uri, Token> beginTokenMap = <Uri, Token>{};

  ResolvedAstDeserializerPlugin(
      this.parsingContext, this.nativeDataDeserializer);

  bool hasResolvedAst(ExecutableElement element) {
    return getResolvedAst(element) != null;
  }

  ResolvedAst getResolvedAst(ExecutableElement element) {
    if (element.hasResolvedAst) {
      return element.resolvedAst;
    }

    ObjectDecoder decoder = _decoderMap[element.memberContext];
    if (decoder != null) {
      ResolvedAstDeserializer.deserialize(element.memberContext, decoder,
          parsingContext, findToken, nativeDataDeserializer);
      _decoderMap.remove(element);
      assert(invariant(element, element.hasResolvedAst,
          message: "ResolvedAst not computed for $element."));
      return element.resolvedAst;
    }
    return null;
  }

  Token findToken(Uri uri, int offset) {
    Token beginToken = beginTokenMap.putIfAbsent(uri, () {
      Script script = scripts[uri];
      if (script == null) {
        parsingContext.reporter.internalError(NO_LOCATION_SPANNABLE,
            'No source file found for $uri in:\n ${scripts.keys.join('\n ')}');
      }
      if (script.isSynthesized) return null;
      return new Scanner(script.file).tokenize();
    });
    if (beginToken == null) return null;
    return ResolvedAstDeserializer.findTokenInStream(beginToken, offset);
  }

  @override
  void onElement(Element element, ObjectDecoder getDecoder(String tag)) {
    ObjectDecoder decoder = getDecoder(RESOLVED_AST_TAG);
    if (decoder != null) {
      _decoderMap[element] = decoder;
    }
  }
}
