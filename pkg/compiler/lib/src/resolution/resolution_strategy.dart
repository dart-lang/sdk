// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution_strategy;

import '../common.dart';
import '../common_elements.dart';
import '../common/resolution.dart';
import '../common/tasks.dart';
import '../compiler.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/resolution_types.dart';
import '../environment.dart';
import '../frontend_strategy.dart';
import '../js_backend/native_data.dart';
import '../library_loader.dart';
import '../native/resolver.dart';
import '../serialization/task.dart';
import '../patch_parser.dart';
import '../resolved_uri_translator.dart';
import '../universe/call_structure.dart';

/// [FrontendStrategy] that loads '.dart' files and creates a resolved element
/// model using the resolver.
class ResolutionFrontEndStrategy implements FrontEndStrategy {
  final Compiler _compiler;
  final ElementEnvironment elementEnvironment;
  AnnotationProcessor _annotationProcessor;

  ResolutionFrontEndStrategy(this._compiler)
      : elementEnvironment = new _CompilerElementEnvironment(_compiler);

  LibraryLoaderTask createLibraryLoader(
      ResolvedUriTranslator uriTranslator,
      ScriptLoader scriptLoader,
      ElementScanner scriptScanner,
      LibraryDeserializer deserializer,
      PatchResolverFunction patchResolverFunc,
      PatchParserTask patchParser,
      Environment environment,
      DiagnosticReporter reporter,
      Measurer measurer) {
    return new ResolutionLibraryLoaderTask(
        uriTranslator,
        scriptLoader,
        scriptScanner,
        deserializer,
        patchResolverFunc,
        patchParser,
        environment,
        reporter,
        measurer);
  }

  AnnotationProcessor get annotationProcesser =>
      _annotationProcessor ??= new _ElementAnnotationProcessor(_compiler);

  @override
  NativeClassFinder createNativeClassResolver(NativeBasicData nativeBasicData) {
    return new ResolutionNativeClassFinder(
        _compiler.resolution,
        _compiler.reporter,
        elementEnvironment,
        _compiler.commonElements,
        nativeBasicData);
  }
}

/// An element environment base on a [Compiler].
class _CompilerElementEnvironment implements ElementEnvironment {
  final Compiler _compiler;

  _CompilerElementEnvironment(this._compiler);

  LibraryProvider get _libraryProvider => _compiler.libraryLoader;
  Resolution get _resolution => _compiler.resolution;

  ResolutionDynamicType get dynamicType => const ResolutionDynamicType();

  @override
  LibraryEntity get mainLibrary => _compiler.mainApp;

  @override
  FunctionEntity get mainFunction => _compiler.mainFunction;

  @override
  Iterable<LibraryEntity> get libraries => _compiler.libraryLoader.libraries;

  @override
  ResolutionInterfaceType getThisType(ClassElement cls) {
    cls.ensureResolved(_resolution);
    return cls.thisType;
  }

  @override
  ResolutionInterfaceType getRawType(ClassElement cls) {
    cls.ensureResolved(_resolution);
    return cls.rawType;
  }

  @override
  ResolutionDartType getTypeVariableBound(TypeVariableElement typeVariable) {
    return typeVariable.bound;
  }

  @override
  ResolutionInterfaceType createInterfaceType(
      ClassElement cls, List<ResolutionDartType> typeArguments) {
    cls.ensureResolved(_resolution);
    return cls.thisType.createInstantiation(typeArguments);
  }

  @override
  bool isSubtype(ResolutionDartType a, ResolutionDartType b) {
    return _compiler.types.isSubtype(a, b);
  }

  @override
  MemberElement lookupClassMember(ClassElement cls, String name,
      {bool setter: false, bool required: false}) {
    cls.ensureResolved(_resolution);
    Element member = cls.implementation.lookupLocalMember(name);
    if (member != null && member.isAbstractField) {
      AbstractFieldElement abstractField = member;
      if (setter) {
        member = abstractField.setter;
      } else {
        member = abstractField.getter;
      }
      if (member == null && required) {
        throw new SpannableAssertionFailure(
            cls,
            "The class '${cls.name}' does not contain required "
            "${setter ? 'setter' : 'getter'}: '$name'.");
      }
    }
    if (member == null && required) {
      throw new SpannableAssertionFailure(
          cls,
          "The class '${cls.name}' does not "
          "contain required member: '$name'.");
    }
    return member?.declaration;
  }

  @override
  ConstructorElement lookupConstructor(ClassElement cls, String name,
      {bool required: false}) {
    cls.ensureResolved(_resolution);
    ConstructorElement constructor = cls.implementation.lookupConstructor(name);
    if (constructor == null && required) {
      throw new SpannableAssertionFailure(
          cls,
          "The class '${cls.name}' does not contain "
          "required constructor: '$name'.");
    }
    return constructor?.declaration;
  }

  @override
  void forEachClassMember(
      ClassElement cls, void f(ClassElement declarer, MemberElement member)) {
    cls.ensureResolved(_resolution);
    cls.forEachMember((ClassElement declarer, MemberElement member) {
      if (member.isSynthesized) return;
      if (member.isMalformed) return;
      f(declarer, member);
    }, includeSuperAndInjectedMembers: true);
  }

  @override
  ClassEntity getSuperClass(ClassElement cls) {
    cls.ensureResolved(_resolution);
    return cls.superclass;
  }

  @override
  void forEachSupertype(
      ClassElement cls, void f(ResolutionInterfaceType supertype)) {
    cls.allSupertypes
        .forEach((ResolutionInterfaceType supertype) => f(supertype));
  }

  @override
  void forEachMixin(ClassElement cls, void f(ClassElement mixin)) {
    for (; cls != null; cls = cls.superclass) {
      if (cls.isMixinApplication) {
        MixinApplicationElement mixinApplication = cls;
        f(mixinApplication.mixin);
      }
    }
  }

  @override
  MemberElement lookupLibraryMember(LibraryElement library, String name,
      {bool setter: false, bool required: false}) {
    Element member = library.implementation.findLocal(name);
    if (member != null && member.isAbstractField) {
      AbstractFieldElement abstractField = member;
      if (setter) {
        member = abstractField.setter;
      } else {
        member = abstractField.getter;
      }
      if (member == null && required) {
        throw new SpannableAssertionFailure(
            library,
            "The library '${library.canonicalUri}' does not contain required "
            "${setter ? 'setter' : 'getter'}: '$name'.");
      }
    }
    if (member == null && required) {
      throw new SpannableAssertionFailure(
          member,
          "The library '${library.libraryName}' does not "
          "contain required member: '$name'.");
    }
    return member?.declaration;
  }

  @override
  ClassElement lookupClass(LibraryElement library, String name,
      {bool required: false}) {
    ClassElement cls = library.implementation.findLocal(name);
    if (cls == null && required) {
      throw new SpannableAssertionFailure(
          cls,
          "The library '${library.libraryName}' does not "
          "contain required class: '$name'.");
    }
    return cls?.declaration;
  }

  @override
  void forEachClass(LibraryElement library, void f(ClassElement cls)) {
    library.implementation.forEachLocalMember((member) {
      if (member.isClass) {
        f(member);
      }
    });
  }

  @override
  LibraryElement lookupLibrary(Uri uri, {bool required: false}) {
    LibraryElement library = _libraryProvider.lookupLibrary(uri);
    // If the script of the library is synthesized, the library does not exist
    // and we do not try to load the helpers.
    //
    // This could for example happen if dart:async is disabled, then loading it
    // should not try to find the given element.
    if (library != null && library.isSynthesized) {
      return null;
    }
    if (library == null && required) {
      throw new SpannableAssertionFailure(
          library, "The library '${uri}' was not found.");
    }
    return library;
  }

  @override
  CallStructure getCallStructure(MethodElement method) {
    ResolutionFunctionType type = method.computeType(_resolution);
    return new CallStructure(
        type.parameterTypes.length +
            type.optionalParameterTypes.length +
            type.namedParameterTypes.length,
        type.namedParameters);
  }

  @override
  bool isDeferredLoadLibraryGetter(MemberElement member) {
    return member.isDeferredLoaderGetter;
  }

  @override
  ResolutionFunctionType getFunctionType(MethodElement method) {
    method.computeType(_resolution);
    return method.type;
  }

  @override
  ResolutionFunctionType getLocalFunctionType(LocalFunctionElement function) {
    return function.type;
  }

  @override
  ResolutionDartType getUnaliasedType(ResolutionDartType type) {
    type.computeUnaliased(_resolution);
    return type.unaliased;
  }
}

/// AST-based logic for processing annotations. These annotations are processed
/// very early in the compilation pipeline, typically this is before resolution
/// is complete. Because of that this processor does a lightweight parse of the
/// annotation (which is restricted to a limited subset of the annotation
/// syntax), and, once resolution completes, it validates that the parsed
/// annotations correspond to the correct element.
class _ElementAnnotationProcessor implements AnnotationProcessor {
  Compiler _compiler;

  _ElementAnnotationProcessor(this._compiler);

  /// Check whether [cls] has a `@Native(...)` annotation, and if so, set its
  /// native name from the annotation.
  void extractNativeAnnotations(
      LibraryElement library, NativeBasicDataBuilder nativeBasicDataBuilder) {
    library.forEachLocalMember((Element element) {
      if (element.isClass) {
        EagerAnnotationHandler.checkAnnotation(_compiler, element,
            new NativeAnnotationHandler(nativeBasicDataBuilder));
      }
    });
  }

  void extractJsInteropAnnotations(
      LibraryElement library, NativeBasicDataBuilder nativeBasicDataBuilder) {
    bool checkJsInteropAnnotation(Element element) {
      return EagerAnnotationHandler.checkAnnotation(
          _compiler, element, const JsInteropAnnotationHandler());
    }

    if (checkJsInteropAnnotation(library)) {
      nativeBasicDataBuilder.markAsJsInteropLibrary(library);
    }
    library.forEachLocalMember((Element element) {
      if (element.isClass) {
        ClassElement cls = element;
        if (checkJsInteropAnnotation(element)) {
          nativeBasicDataBuilder.markAsJsInteropClass(cls);
        }
      }
    });
  }
}
