// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution_strategy;

import '../common.dart';
import '../common_elements.dart';
import '../common/backend_api.dart';
import '../common/names.dart';
import '../common/resolution.dart';
import '../common/tasks.dart';
import '../compiler.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/modelx.dart';
import '../elements/resolution_types.dart';
import '../environment.dart';
import '../enqueue.dart';
import '../frontend_strategy.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/custom_elements_analysis.dart';
import '../js_backend/mirrors_analysis.dart';
import '../js_backend/mirrors_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../library_loader.dart';
import '../native/resolver.dart';
import '../serialization/task.dart';
import '../patch_parser.dart';
import '../resolved_uri_translator.dart';
import '../universe/call_structure.dart';
import '../universe/use.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import 'no_such_method_resolver.dart';

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
  NativeClassFinder createNativeClassFinder(NativeBasicData nativeBasicData) {
    return new ResolutionNativeClassFinder(
        _compiler.resolution,
        _compiler.reporter,
        elementEnvironment,
        _compiler.commonElements,
        nativeBasicData);
  }

  NoSuchMethodResolver createNoSuchMethodResolver() =>
      new ResolutionNoSuchMethodResolver();

  CustomElementsResolutionAnalysis createCustomElementsResolutionAnalysis(
      NativeBasicData nativeBasicData,
      BackendUsageBuilder backendUsageBuilder) {
    return new CustomElementsResolutionAnalysis(
        _compiler.resolution,
        _compiler.backend.constantSystem,
        _compiler.commonElements,
        nativeBasicData,
        backendUsageBuilder);
  }

  MirrorsDataBuilder createMirrorsDataBuilder() {
    return new MirrorsDataImpl(
        _compiler, _compiler.options, _compiler.commonElements);
  }

  MirrorsResolutionAnalysis createMirrorsResolutionAnalysis(
          JavaScriptBackend backend) =>
      new MirrorsResolutionAnalysisImpl(backend, _compiler.resolution);

  RuntimeTypesNeedBuilder createRuntimeTypesNeedBuilder() {
    return new ResolutionRuntimeTypesNeedBuilderImpl(
        elementEnvironment, _compiler.types);
  }

  ResolutionWorldBuilder createResolutionWorldBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      SelectorConstraintsStrategy selectorConstraintsStrategy) {
    return new ElementResolutionWorldBuilder(
        _compiler.backend,
        _compiler.resolution,
        nativeBasicData,
        nativeDataBuilder,
        selectorConstraintsStrategy);
  }

  WorkItemBuilder createResolutionWorkItemBuilder(
      ImpactTransformer impactTransformer) {
    return new ResolutionWorkItemBuilder(_compiler.resolution);
  }

  FunctionEntity computeMain(
      LibraryElement mainApp, WorldImpactBuilder impactBuilder) {
    if (mainApp == null) return null;
    MethodElement mainFunction;
    Element main = mainApp.findExported(Identifiers.main);
    ErroneousElement errorElement = null;
    if (main == null) {
      if (_compiler.options.analyzeOnly) {
        if (!_compiler.analyzeAll) {
          errorElement = new ErroneousElementX(MessageKind.CONSIDER_ANALYZE_ALL,
              {'main': Identifiers.main}, Identifiers.main, mainApp);
        }
      } else {
        // Compilation requires a main method.
        errorElement = new ErroneousElementX(MessageKind.MISSING_MAIN,
            {'main': Identifiers.main}, Identifiers.main, mainApp);
      }
      mainFunction = _compiler.backend.helperForMissingMain();
    } else if (main.isError && main.isSynthesized) {
      if (main is ErroneousElement) {
        errorElement = main;
      } else {
        _compiler.reporter
            .internalError(main, 'Problem with ${Identifiers.main}.');
      }
      mainFunction = _compiler.backend.helperForBadMain();
    } else if (!main.isFunction) {
      errorElement = new ErroneousElementX(MessageKind.MAIN_NOT_A_FUNCTION,
          {'main': Identifiers.main}, Identifiers.main, main);
      mainFunction = _compiler.backend.helperForBadMain();
    } else {
      mainFunction = main;
      mainFunction.computeType(_compiler.resolution);
      FunctionSignature parameters = mainFunction.functionSignature;
      if (parameters.requiredParameterCount > 2) {
        int index = 0;
        parameters.orderedForEachParameter((Element parameter) {
          if (index++ < 2) return;
          errorElement = new ErroneousElementX(
              MessageKind.MAIN_WITH_EXTRA_PARAMETER,
              {'main': Identifiers.main},
              Identifiers.main,
              parameter);
          // Don't warn about main not being used:
          impactBuilder.registerStaticUse(
              new StaticUse.staticInvoke(mainFunction, CallStructure.NO_ARGS));

          mainFunction = _compiler.backend.helperForMainArity();
        });
      }
    }
    if (mainFunction == null) {
      if (errorElement == null &&
          !_compiler.options.analyzeOnly &&
          !_compiler.analyzeAll) {
        _compiler.reporter
            .internalError(mainApp, "Problem with '${Identifiers.main}'.");
      } else {
        mainFunction = errorElement;
      }
    }
    if (errorElement != null &&
        errorElement.isSynthesized &&
        !mainApp.isSynthesized) {
      _compiler.reporter.reportWarningMessage(errorElement,
          errorElement.messageKind, errorElement.messageArguments);
    }
    MethodElement mainMethod;
    if (mainFunction != null && !mainFunction.isMalformed) {
      mainFunction.computeType(_compiler.resolution);
      mainMethod = mainFunction;
    }
    return mainMethod;
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
  bool isGenericClass(ClassEntity cls) {
    return getThisType(cls).typeArguments.isNotEmpty;
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
  ClassEntity getSuperClass(ClassElement cls,
      {bool skipUnnamedMixinApplications: false}) {
    cls.ensureResolved(_resolution);
    ClassElement superclass = cls.superclass;
    if (skipUnnamedMixinApplications) {
      while (superclass != null && superclass.isUnnamedMixinApplication) {
        superclass = superclass.superclass;
      }
    }
    return superclass;
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
          library,
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
          NO_LOCATION_SPANNABLE, "The library '${uri}' was not found.");
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

  @override
  Iterable<ConstantValue> getMemberMetadata(MemberElement element) {
    List<ConstantValue> values = <ConstantValue>[];
    _compiler.reporter.withCurrentElement(element, () {
      for (MetadataAnnotation metadata in element.implementation.metadata) {
        metadata.ensureResolved(_compiler.resolution);
        assert(invariant(metadata, metadata.constant != null,
            message: "Unevaluated metadata constant."));
        ConstantValue value =
            _compiler.constants.getConstantValue(metadata.constant);
        values.add(value);
      }
    });
    return values;
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

  CommonElements get _commonElements => _compiler.commonElements;

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

  void processJsInteropAnnotations(
      NativeBasicData nativeBasicData, NativeDataBuilder nativeDataBuilder) {
    if (_commonElements.jsAnnotationClass == null) return;

    ClassElement cls = _commonElements.jsAnnotationClass;
    FieldElement nameField = cls.lookupMember('name');

    /// Resolves the metadata of [element] and returns the name of the `JS(...)`
    /// annotation for js interop, if found.
    String processJsInteropAnnotation(Element element) {
      for (MetadataAnnotation annotation in element.implementation.metadata) {
        // TODO(johnniwinther): Avoid processing unresolved elements.
        if (annotation.constant == null) continue;
        ConstantValue constant =
            _compiler.constants.getConstantValue(annotation.constant);
        if (constant == null || constant is! ConstructedConstantValue) continue;
        ConstructedConstantValue constructedConstant = constant;
        if (constructedConstant.type.element ==
            _commonElements.jsAnnotationClass) {
          ConstantValue value = constructedConstant.fields[nameField];
          String name;
          if (value.isString) {
            StringConstantValue stringValue = value;
            name = stringValue.primitiveValue.slowToString();
          } else {
            // TODO(jacobr): report a warning if the value is not a String.
            name = '';
          }
          return name;
        }
      }
      return null;
    }

    void checkFunctionParameters(MethodElement fn) {
      if (fn.hasFunctionSignature &&
          fn.functionSignature.optionalParametersAreNamed) {
        _compiler.reporter.reportErrorMessage(
            fn,
            MessageKind.JS_INTEROP_METHOD_WITH_NAMED_ARGUMENTS,
            {'method': fn.name});
      }
    }

    bool hasAnonymousAnnotation(Element element) {
      if (_commonElements.jsAnonymousClass == null) return false;
      return element.metadata.any((MetadataAnnotation annotation) {
        ConstantValue constant =
            _compiler.constants.getConstantValue(annotation.constant);
        if (constant == null || constant is! ConstructedConstantValue)
          return false;
        ConstructedConstantValue constructedConstant = constant;
        return constructedConstant.type.element ==
            _commonElements.jsAnonymousClass;
      });
    }

    void processJsInteropAnnotationsInLibrary(LibraryElement library) {
      String libraryName = processJsInteropAnnotation(library);
      if (libraryName != null) {
        nativeDataBuilder.setJsInteropLibraryName(library, libraryName);
      }
      library.implementation.forEachLocalMember((Element element) {
        if (element is MemberElement) {
          String memberName = processJsInteropAnnotation(element);
          if (memberName != null) {
            nativeDataBuilder.setJsInteropMemberName(element, memberName);
            if (element is MethodElement) {
              checkFunctionParameters(element);
            }
          }
        }

        if (!element.isClass) return;

        ClassElement classElement = element;
        String className = processJsInteropAnnotation(classElement);
        if (className != null) {
          nativeDataBuilder.setJsInteropClassName(classElement, className);
        }
        if (!nativeBasicData.isJsInteropClass(classElement)) return;

        bool isAnonymous = hasAnonymousAnnotation(classElement);
        if (isAnonymous) {
          nativeDataBuilder.markJsInteropClassAsAnonymous(classElement);
        }

        // Skip classes that are completely unreachable. This should only happen
        // when all of jsinterop types are unreachable from main.
        if (!_compiler.resolutionWorldBuilder.isImplemented(classElement)) {
          return;
        }

        if (!classElement
            .implementsInterface(_commonElements.jsJavaScriptObjectClass)) {
          _compiler.reporter.reportErrorMessage(classElement,
              MessageKind.JS_INTEROP_CLASS_CANNOT_EXTEND_DART_CLASS, {
            'cls': classElement.name,
            'superclass': classElement.superclass.name
          });
        }

        classElement
            .forEachMember((ClassElement classElement, MemberElement member) {
          String memberName = processJsInteropAnnotation(member);
          if (memberName != null) {
            nativeDataBuilder.setJsInteropMemberName(member, memberName);
          }

          if (!member.isSynthesized &&
              nativeBasicData.isJsInteropClass(classElement) &&
              member is MethodElement) {
            MethodElement fn = member;
            if (!fn.isExternal &&
                !fn.isAbstract &&
                !fn.isConstructor &&
                !fn.isStatic) {
              _compiler.reporter.reportErrorMessage(
                  fn,
                  MessageKind.JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER,
                  {'cls': classElement.name, 'member': member.name});
            }

            if (fn.isFactoryConstructor && isAnonymous) {
              fn.functionSignature
                  .orderedForEachParameter((ParameterElement parameter) {
                if (!parameter.isNamed) {
                  _compiler.reporter.reportErrorMessage(
                      parameter,
                      MessageKind
                          .JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS,
                      {'parameter': parameter.name, 'cls': classElement.name});
                }
              });
            } else {
              checkFunctionParameters(fn);
            }
          }
        });
      });
    }

    _compiler.libraryLoader.libraries
        .forEach(processJsInteropAnnotationsInLibrary);
  }
}
