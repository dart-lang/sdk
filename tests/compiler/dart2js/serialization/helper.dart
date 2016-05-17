// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_helper;

import 'dart:async';
import 'dart:io';

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common/backend_api.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/scanner/scanner.dart';
import 'package:compiler/src/script.dart';
import 'package:compiler/src/serialization/impact_serialization.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/serialization/modelz.dart';
import 'package:compiler/src/serialization/resolved_ast_serialization.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:compiler/src/serialization/task.dart';
import 'package:compiler/src/tokens/token.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/universe/use.dart';

import '../memory_compiler.dart';

class Arguments {
  final String filename;
  final int index;
  final bool loadSerializedData;
  final bool saveSerializedData;
  final String serializedDataFileName;
  final bool verbose;

  const Arguments({
    this.filename,
    this.index,
    this.loadSerializedData: false,
    this.saveSerializedData: false,
    this.serializedDataFileName: 'out.data',
    this.verbose: false});

  factory Arguments.from(List<String> arguments) {
    String filename;
    int index;
    for (String arg in arguments) {
      if (!arg.startsWith('-')) {
        index = int.parse(arg);
        if (index == null) {
          filename = arg;
        }
      }
    }
    bool verbose = arguments.contains('-v');
    bool loadSerializedData = arguments.contains('-l');
    bool saveSerializedData = arguments.contains('-s');
    return new Arguments(
        filename: filename,
        index: index,
        verbose: verbose,
        loadSerializedData: loadSerializedData,
        saveSerializedData: saveSerializedData);
  }
}


Future<String> serializeDartCore(
    {Arguments arguments: const Arguments()}) async {
  print('------------------------------------------------------------------');
  print('serialize dart:core');
  print('------------------------------------------------------------------');
  String serializedData;
  if (arguments.loadSerializedData) {
    File file = new File(arguments.serializedDataFileName);
    if (file.existsSync()) {
      print('Loading data from $file');
      serializedData = file.readAsStringSync();
    }
  }
  if (serializedData == null) {
    Compiler compiler = compilerFor(
        options: [Flags.analyzeAll]);
    compiler.serialization.supportSerialization = true;
    await compiler.run(Uris.dart_core);
    serializedData = serialize(
        compiler,
        compiler.libraryLoader.libraries)
          .toText(const JsonSerializationEncoder());
    if (arguments.saveSerializedData) {
      File file = new File(arguments.serializedDataFileName);
      print('Saving data to $file');
      file.writeAsStringSync(serializedData);
    }
  }
  return serializedData;
}

Serializer serialize(
    Compiler compiler,
    Iterable<LibraryElement> libraries) {
  assert(compiler.serialization.supportSerialization);

  Serializer serializer = new Serializer();
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
}

void deserialize(Compiler compiler,
                 String serializedData) {
  Deserializer deserializer = new Deserializer.fromText(
      new DeserializationContext(),
      serializedData,
      const JsonSerializationDecoder());
  deserializer.plugins.add(compiler.backend.serialization.deserializer);
  compiler.serialization.deserializer =
      new _DeserializerSystem(
          compiler,
          deserializer,
          compiler.backend.impactTransformer);
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
      impactMap[element] =
          ImpactDeserializer.deserializeImpact(
              element, decoder, nativeDataDeserializer);
    }
  }
}

class _DeserializerSystem extends DeserializerSystem {
  final Compiler _compiler;
  final Deserializer _deserializer;
  final List<LibraryElement> deserializedLibraries = <LibraryElement>[];
  final ResolutionImpactDeserializer _resolutionImpactDeserializer;
  final ResolvedAstDeserializerPlugin _resolvedAstDeserializer;
  final ImpactTransformer _impactTransformer;

  factory _DeserializerSystem(
      Compiler compiler,
      Deserializer deserializer,
      ImpactTransformer impactTransformer) {
    List<DeserializerPlugin> plugins = <DeserializerPlugin>[];
    DeserializerPlugin backendDeserializer =
        compiler.backend.serialization.deserializer;
    deserializer.plugins.add(backendDeserializer);
    ResolutionImpactDeserializer resolutionImpactDeserializer =
        new ResolutionImpactDeserializer(backendDeserializer);
    deserializer.plugins.add(resolutionImpactDeserializer);
    ResolvedAstDeserializerPlugin resolvedAstDeserializer
        = new ResolvedAstDeserializerPlugin(
            compiler.parsingContext, backendDeserializer);
    deserializer.plugins.add(resolvedAstDeserializer);
    return new _DeserializerSystem._(
        compiler,
        deserializer,
        impactTransformer,
        resolutionImpactDeserializer,
        resolvedAstDeserializer);
  }

  _DeserializerSystem._(
      this._compiler,
      this._deserializer,
      this._impactTransformer,
      this._resolutionImpactDeserializer,
      this._resolvedAstDeserializer);


  @override
  Future<LibraryElement> readLibrary(Uri resolvedUri) {
    LibraryElement library = _deserializer.lookupLibrary(resolvedUri);
    if (library != null) {
      deserializedLibraries.add(library);
      return Future.forEach(library.compilationUnits,
          (CompilationUnitElement compilationUnit) {
        ScriptZ script = compilationUnit.script;
        return _compiler.readScript(script.readableUri)
            .then((Script newScript) {
          script.file = newScript.file;
          _resolvedAstDeserializer.sourceFiles[script.resourceUri] =
              newScript.file;
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
      ClassElement superclass =  element.enclosingClass.superclass;
      ConstructorElement superclassConstructor =
          superclass.lookupConstructor(element.name);
      assert(invariant(element, superclassConstructor != null,
          message: "Superclass constructor '${element.name}' called from "
                   "${element} not found in ${superclass}."));
      // TODO(johnniwinther): Compute callStructure. Currently not used.
      CallStructure callStructure;
      return _resolutionImpactDeserializer.impactMap.putIfAbsent(element, () {
        return new DeserializedResolutionImpact(
            staticUses: <StaticUse>[new StaticUse.superConstructorInvoke(
                superclassConstructor, callStructure)]);
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
          objectEncoder,
          resolvedAst,
          nativeDataSerializer).serialize();
    }
  }
}

class ResolvedAstDeserializerPlugin extends DeserializerPlugin {
  final ParsingContext parsingContext;
  final DeserializerPlugin nativeDataDeserializer;
  final Map<Uri, SourceFile> sourceFiles = <Uri, SourceFile>{};

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
      ResolvedAstDeserializer.deserialize(
          element.memberContext, decoder, parsingContext, findToken,
          nativeDataDeserializer);
      _decoderMap.remove(element);
      assert(invariant(element, element.hasResolvedAst,
          message: "ResolvedAst not computed for $element."));
      return element.resolvedAst;
    }
    return null;
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

