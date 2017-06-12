// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_system;

import 'dart:async';

import '../common.dart';
import '../common/resolution.dart';
import '../compiler.dart';
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../script.dart';
import '../serialization/impact_serialization.dart';
import 'package:front_end/src/fasta/scanner.dart';
import '../universe/call_structure.dart';
import '../universe/use.dart';
import '../universe/world_impact.dart';
import 'modelz.dart';
import 'resolved_ast_serialization.dart';
import 'serialization.dart';
import 'task.dart';

class ResolutionDeserializerSystem extends DeserializerSystem {
  final Compiler _compiler;
  final Resolution resolution;
  final DeserializationContext deserializationContext;
  final List<LibraryElement> deserializedLibraries = <LibraryElement>[];

  factory ResolutionDeserializerSystem(Compiler compiler,
      {bool deserializeCompilationDataForTesting: false}) {
    DeserializationContext context = new DeserializationContext(
        compiler.reporter, compiler.resolution, compiler.libraryLoader);
    DeserializerPlugin backendDeserializer =
        compiler.backend.serialization.deserializer;
    context.plugins.add(backendDeserializer);
    if (compiler.options.resolveOnly && !deserializeCompilationDataForTesting) {
      return new ResolutionDeserializerSystem._(
          compiler, compiler.resolution, context);
    } else {
      ResolutionImpactDeserializer resolutionImpactDeserializer =
          new ResolutionImpactDeserializer(backendDeserializer);
      context.plugins.add(resolutionImpactDeserializer);
      ResolvedAstDeserializerPlugin resolvedAstDeserializer =
          new ResolvedAstDeserializerPlugin(
              compiler.parsingContext, backendDeserializer);
      context.plugins.add(resolvedAstDeserializer);
      return new CompilationDeserializerSystem._(compiler, compiler.resolution,
          context, resolutionImpactDeserializer, resolvedAstDeserializer);
    }
  }

  ResolutionDeserializerSystem._(
      this._compiler, this.resolution, this.deserializationContext);

  @override
  Future<LibraryElement> readLibrary(Uri resolvedUri) {
    LibraryElement library = deserializationContext.lookupLibrary(resolvedUri);
    if (library != null) {
      deserializedLibraries.add(library);
      return onReadLibrary(library);
    }
    return new Future<LibraryElement>.value(library);
  }

  Future<LibraryElement> onReadLibrary(LibraryElement library) {
    return new Future<LibraryElement>.value(library);
  }

  // TODO(johnniwinther): Remove the need for this method.
  @override
  bool hasResolvedAst(ExecutableElement element) {
    return getResolvedAst(element) != null;
  }

  @override
  ResolvedAst getResolvedAst(ExecutableElement element) => null;

  @override
  bool hasResolutionImpact(Element element) => true;

  @override
  ResolutionImpact getResolutionImpact(Element element) {
    return const ResolutionImpact();
  }

  @override
  WorldImpact computeWorldImpact(Element element) {
    ResolutionImpact resolutionImpact = getResolutionImpact(element);
    assert(resolutionImpact != null,
        failedAt(element, 'No impact found for $element (${element.library})'));
    if (element is ExecutableElement) {
      getResolvedAst(element);
    }
    if (element.isField && !element.isConst) {
      FieldElement field = element;
      if (field.isTopLevel || field.isStatic) {
        if (field.constant == null) {
          // TODO(johnniwinther): Find a cleaner way to do this. Maybe
          // `Feature.LAZY_FIELD` of the resolution impact should be used
          // instead.
          _compiler.backend.constants.registerLazyStatic(element);
        }
      }
    }
    return resolution.transformResolutionImpact(element, resolutionImpact);
  }

  @override
  bool isDeserialized(Element element) {
    return deserializedLibraries.contains(element.library);
  }
}

class CompilationDeserializerSystem extends ResolutionDeserializerSystem {
  final ResolutionImpactDeserializer _resolutionImpactDeserializer;
  final ResolvedAstDeserializerPlugin _resolvedAstDeserializer;

  CompilationDeserializerSystem._(
      Compiler compiler,
      Resolution resolution,
      DeserializationContext deserializationContext,
      this._resolutionImpactDeserializer,
      this._resolvedAstDeserializer)
      : super._(compiler, resolution, deserializationContext);

  @override
  Future<LibraryElement> onReadLibrary(LibraryElement library) {
    return Future.forEach(library.compilationUnits,
        (CompilationUnitElement compilationUnit) {
      ScriptZ script = compilationUnit.script;
      return _compiler.readScript(script.readableUri).then((Script newScript) {
        script.file = newScript.file;
        script.isSynthesized = newScript.isSynthesized;
        _resolvedAstDeserializer.scripts[script.resourceUri] = script;
      });
    }).then((_) => library);
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
    return _resolutionImpactDeserializer.hasResolutionImpact(element);
  }

  @override
  ResolutionImpact getResolutionImpact(Element element) {
    if (element.isConstructor &&
        element.enclosingClass.isUnnamedMixinApplication) {
      ConstructorElement constructor = element;
      ClassElement superclass = constructor.enclosingClass.superclass;
      ConstructorElement superclassConstructor =
          superclass.lookupConstructor(constructor.name);
      assert(
          superclassConstructor != null,
          failedAt(
              element,
              "Superclass constructor '${constructor.name}' called from "
              "${element} not found in ${superclass}."));
      // TODO(johnniwinther): Compute callStructure. Currently not used.
      CallStructure callStructure;
      return _resolutionImpactDeserializer.registerResolutionImpact(constructor,
          () {
        List<TypeUse> typeUses = <TypeUse>[];
        void addCheckedModeCheck(ResolutionDartType type) {
          if (!type.isDynamic) {
            typeUses.add(new TypeUse.checkedModeCheck(type));
          }
        }

        ResolutionFunctionType type = constructor.type;
        // TODO(johnniwinther): Remove this substitution when synthesized
        // constructors handle type variables correctly.
        type = type.substByContext(constructor.enclosingClass
            .asInstanceOf(constructor.enclosingClass));
        type.parameterTypes.forEach(addCheckedModeCheck);
        type.optionalParameterTypes.forEach(addCheckedModeCheck);
        type.namedParameterTypes.forEach(addCheckedModeCheck);
        return new DeserializedResolutionImpact(staticUses: <StaticUse>[
          new StaticUse.superConstructorInvoke(
              superclassConstructor, callStructure)
        ], typeUses: typeUses);
      });
    }
    return _resolutionImpactDeserializer.getResolutionImpact(element);
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
  Map<Element, ObjectDecoder> _decoderMap = <Element, ObjectDecoder>{};
  Map<Element, ResolutionImpact> _impactMap = <Element, ResolutionImpact>{};
  final DeserializerPlugin nativeDataDeserializer;

  ResolutionImpactDeserializer(this.nativeDataDeserializer);

  @override
  void onElement(Element element, ObjectDecoder getDecoder(String tag)) {
    ObjectDecoder decoder = getDecoder(WORLD_IMPACT_TAG);
    if (decoder != null) {
      _decoderMap[element] = decoder;
    }
  }

  bool hasResolutionImpact(Element element) {
    return _impactMap.containsKey(element) || _decoderMap.containsKey(element);
  }

  ResolutionImpact registerResolutionImpact(
      Element element, ResolutionImpact ifAbsent()) {
    return _impactMap.putIfAbsent(element, ifAbsent);
  }

  ResolutionImpact getResolutionImpact(Element element) {
    return registerResolutionImpact(element, () {
      ObjectDecoder decoder = _decoderMap[element];
      if (decoder != null) {
        _decoderMap.remove(element);
        return ImpactDeserializer.deserializeImpact(
            element, decoder, nativeDataDeserializer);
      }
      return null;
    });
  }
}

const String RESOLVED_AST_TAG = 'resolvedAst';

class ResolvedAstSerializerPlugin extends SerializerPlugin {
  final Resolution resolution;
  final SerializerPlugin nativeDataSerializer;

  ResolvedAstSerializerPlugin(this.resolution, this.nativeDataSerializer);

  @override
  void onElement(Element element, ObjectEncoder createEncoder(String tag)) {
    assert(element.isDeclaration,
        failedAt(element, "Element $element must be the declaration"));
    if (element.isError) return;
    if (element is MemberElement) {
      assert(resolution.hasResolvedAst(element),
          failedAt(element, "Element $element must have a resolved ast"));
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
      assert(element.hasResolvedAst,
          failedAt(element, "ResolvedAst not computed for $element."));
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
      return parsingContext.scanner.scanFile(script.file);
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
