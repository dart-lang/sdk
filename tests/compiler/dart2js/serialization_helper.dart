// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_helper;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/backend_api.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/scanner/scanner.dart';
import 'package:compiler/src/serialization/element_serialization.dart';
import 'package:compiler/src/serialization/impact_serialization.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/serialization/resolved_ast_serialization.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:compiler/src/serialization/modelz.dart';
import 'package:compiler/src/serialization/task.dart';
import 'package:compiler/src/tokens/token.dart';
import 'package:compiler/src/script.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'memory_compiler.dart';


Future<String> serializeDartCore({bool serializeResolvedAst: false}) async {
  Compiler compiler = compilerFor(
      options: [Flags.analyzeAll]);
  compiler.serialization.supportSerialization = true;
  await compiler.run(Uris.dart_core);
  return serialize(
      compiler,
      compiler.libraryLoader.libraries,
      serializeResolvedAst: serializeResolvedAst)
        .toText(const JsonSerializationEncoder());
}

Serializer serialize(
    Compiler compiler,
    Iterable<LibraryElement> libraries,
    {bool serializeResolvedAst: false}) {
  assert(compiler.serialization.supportSerialization);

  Serializer serializer = new Serializer();
  serializer.plugins.add(compiler.backend.serialization.serializer);
  serializer.plugins.add(new ResolutionImpactSerializer(compiler.resolution));
  if (serializeResolvedAst) {
    serializer.plugins.add(
        new ResolvedAstSerializerPlugin(compiler.resolution));
  }

  for (LibraryElement library in libraries) {
    serializer.serialize(library);
  }
  return serializer;
}

void deserialize(Compiler compiler,
                 String serializedData,
                 {bool deserializeResolvedAst: false}) {
  Deserializer deserializer = new Deserializer.fromText(
      new DeserializationContext(),
      serializedData,
      const JsonSerializationDecoder());
  deserializer.plugins.add(compiler.backend.serialization.deserializer);
  compiler.serialization.deserializer =
      new _DeserializerSystem(
          compiler,
          deserializer,
          compiler.backend.impactTransformer,
          deserializeResolvedAst: deserializeResolvedAst);
}


const String WORLD_IMPACT_TAG = 'worldImpact';

class ResolutionImpactSerializer extends SerializerPlugin {
  final Resolution resolution;

  ResolutionImpactSerializer(this.resolution);

  @override
  void onElement(Element element, ObjectEncoder createEncoder(String tag)) {
    if (resolution.hasBeenResolved(element)) {
      ResolutionImpact impact = resolution.getResolutionImpact(element);
      ObjectEncoder encoder = createEncoder(WORLD_IMPACT_TAG);
      new ImpactSerializer(encoder).serialize(impact);
    }
  }
}

class ResolutionImpactDeserializer extends DeserializerPlugin {
  Map<Element, ResolutionImpact> impactMap = <Element, ResolutionImpact>{};

  @override
  void onElement(Element element, ObjectDecoder getDecoder(String tag)) {
    ObjectDecoder decoder = getDecoder(WORLD_IMPACT_TAG);
    if (decoder != null) {
      impactMap[element] = ImpactDeserializer.deserializeImpact(decoder);
    }
  }
}

class _DeserializerSystem extends DeserializerSystem {
  final Compiler _compiler;
  final Deserializer _deserializer;
  final List<LibraryElement> deserializedLibraries = <LibraryElement>[];
  final ResolutionImpactDeserializer _resolutionImpactDeserializer =
      new ResolutionImpactDeserializer();
  final ResolvedAstDeserializerPlugin _resolvedAstDeserializer;
  final ImpactTransformer _impactTransformer;
  final bool _deserializeResolvedAst;

  _DeserializerSystem(
      Compiler compiler,
      this._deserializer,
      this._impactTransformer,
      {bool deserializeResolvedAst: false})
      : this._compiler = compiler,
        this._deserializeResolvedAst = deserializeResolvedAst,
        this._resolvedAstDeserializer = deserializeResolvedAst
           ? new ResolvedAstDeserializerPlugin(compiler.parsing) : null {
    _deserializer.plugins.add(_resolutionImpactDeserializer);
    if (_deserializeResolvedAst) {
      _deserializer.plugins.add(_resolvedAstDeserializer);
    }
  }

  @override
  Future<LibraryElement> readLibrary(Uri resolvedUri) {
    LibraryElement library = _deserializer.lookupLibrary(resolvedUri);
    if (library != null) {
      deserializedLibraries.add(library);
      if (_deserializeResolvedAst) {
        return Future.forEach(library.compilationUnits,
            (CompilationUnitElement compilationUnit) {
          Script script = compilationUnit.script;
          return _compiler.readScript(script.readableUri)
              .then((Script newScript) {
            _resolvedAstDeserializer.sourceFiles[script.resourceUri] =
                newScript.file;
          });
        }).then((_) => library);
      }
    }
    return new Future<LibraryElement>.value(library);
  }

  @override
  ResolvedAst getResolvedAst(Element element) {
    if (_resolvedAstDeserializer != null) {
      return _resolvedAstDeserializer.getResolvedAst(element);
    }
    return null;
  }

  @override
  ResolutionImpact getResolutionImpact(Element element) {
    return _resolutionImpactDeserializer.impactMap[element];
  }

  @override
  WorldImpact computeWorldImpact(Element element) {
    ResolutionImpact resolutionImpact = getResolutionImpact(element);
    if (resolutionImpact == null) {
      print('No impact found for $element (${element.library})');
      return const WorldImpact();
    } else {
      return _impactTransformer.transformResolutionImpact(resolutionImpact);
    }
  }

  @override
  bool isDeserialized(Element element) {
    return deserializedLibraries.contains(element.library);
  }
}

const String RESOLVED_AST_TAG = 'resolvedAst';

class ResolvedAstSerializerPlugin extends SerializerPlugin {
  final Resolution resolution;

  ResolvedAstSerializerPlugin(this.resolution);

  @override
  void onElement(Element element, ObjectEncoder createEncoder(String tag)) {
    if (element is MemberElement && resolution.hasResolvedAst(element)) {
      ResolvedAst resolvedAst = resolution.getResolvedAst(element);
      ObjectEncoder objectEncoder = createEncoder(RESOLVED_AST_TAG);
      new ResolvedAstSerializer(objectEncoder, resolvedAst).serialize();
    }
  }
}

class ResolvedAstDeserializerPlugin extends DeserializerPlugin {
  final Parsing parsing;
  final Map<Uri, SourceFile> sourceFiles = <Uri, SourceFile>{};

  Map<Element, ResolvedAst> _resolvedAstMap = <Element, ResolvedAst>{};
  Map<Element, ObjectDecoder> _decoderMap = <Element, ObjectDecoder>{};
  Map<Uri, Token> beginTokenMap = <Uri, Token>{};

  ResolvedAstDeserializerPlugin(this.parsing);

  ResolvedAst getResolvedAst(Element element) {
    ResolvedAst resolvedAst = _resolvedAstMap[element];
    if (resolvedAst == null) {
      ObjectDecoder decoder = _decoderMap[element];
      if (decoder != null) {
        resolvedAst = _resolvedAstMap[element] =
            ResolvedAstDeserializer.deserialize(
                element, decoder, parsing, findToken);
        _decoderMap.remove(element);
      }
    }
    return resolvedAst;
  }

  Token findToken(Uri uri, int offset) {
    Token beginToken = beginTokenMap.putIfAbsent(uri, () {
      SourceFile sourceFile = sourceFiles[uri];
      if (sourceFile == null) {
        throw 'No source file found for $uri in:\n '
              '${sourceFiles.keys.join('\n ')}';
      }
      return new Scanner(sourceFile).tokenize();
    });
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

