// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution_strategy;

import 'package:front_end/src/fasta/scanner.dart' show Token;

import '../common.dart';
import '../common_elements.dart';
import '../common/backend_api.dart';
import '../common/names.dart';
import '../common/resolution.dart';
import '../common/tasks.dart';
import '../common/work.dart';
import '../compiler.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/modelx.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../environment.dart';
import '../enqueue.dart';
import '../frontend_strategy.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/mirrors_analysis.dart';
import '../js_backend/mirrors_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../library_loader.dart';
import '../native/resolver.dart';
import '../tree/tree.dart' show Node;
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
class ResolutionFrontEndStrategy implements FrontendStrategy {
  final Compiler _compiler;
  final _CompilerElementEnvironment _elementEnvironment;
  final CommonElements commonElements;

  AnnotationProcessor _annotationProcessor;

  factory ResolutionFrontEndStrategy(Compiler compiler) {
    ElementEnvironment elementEnvironment =
        new _CompilerElementEnvironment(compiler);
    CommonElements commonElements = new CommonElements(elementEnvironment);
    return new ResolutionFrontEndStrategy.internal(
        compiler, elementEnvironment, commonElements);
  }

  ResolutionFrontEndStrategy.internal(
      this._compiler, this._elementEnvironment, this.commonElements);

  ElementEnvironment get elementEnvironment => _elementEnvironment;

  DartTypes get dartTypes => _compiler.types;

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
        commonElements,
        nativeBasicData);
  }

  NoSuchMethodResolver createNoSuchMethodResolver() =>
      new ResolutionNoSuchMethodResolver();

  MirrorsDataBuilder createMirrorsDataBuilder() {
    return new MirrorsDataImpl(_compiler, _compiler.options, commonElements);
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
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      SelectorConstraintsStrategy selectorConstraintsStrategy) {
    return new ElementResolutionWorldBuilder(
        _compiler.backend,
        _compiler.resolution,
        nativeBasicData,
        nativeDataBuilder,
        interceptorDataBuilder,
        backendUsageBuilder,
        selectorConstraintsStrategy);
  }

  WorkItemBuilder createResolutionWorkItemBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      ImpactTransformer impactTransformer) {
    return new ResolutionWorkItemBuilder(_compiler.resolution);
  }

  FunctionEntity computeMain(
      LibraryElement mainApp, WorldImpactBuilder impactBuilder) {
    _elementEnvironment._mainLibrary = mainApp;
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
      mainFunction = commonElements.missingMain;
    } else if (main.isError && main.isSynthesized) {
      if (main is ErroneousElement) {
        errorElement = main;
      } else {
        _compiler.reporter
            .internalError(main, 'Problem with ${Identifiers.main}.');
      }
      mainFunction = commonElements.badMain;
    } else if (!main.isFunction) {
      errorElement = new ErroneousElementX(MessageKind.MAIN_NOT_A_FUNCTION,
          {'main': Identifiers.main}, Identifiers.main, main);
      mainFunction = commonElements.badMain;
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

          mainFunction = commonElements.mainHasTooManyParameters;
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
    _elementEnvironment._mainFunction = mainMethod;
    return mainMethod;
  }

  SourceSpan spanFromToken(Element currentElement, Token token) =>
      _spanFromTokens(currentElement, token, token);

  SourceSpan _spanFromTokens(Element currentElement, Token begin, Token end,
      [Uri uri]) {
    if (begin == null || end == null) {
      // TODO(ahe): We can almost always do better. Often it is only
      // end that is null. Otherwise, we probably know the current
      // URI.
      throw 'Cannot find tokens to produce error message.';
    }
    if (uri == null && currentElement != null) {
      if (currentElement is! Element) {
        throw 'Can only find tokens from an Element.';
      }
      Element element = currentElement;
      uri = element.compilationUnit.script.resourceUri;
      assert(() {
        bool sameToken(Token token, Token sought) {
          if (token == sought) return true;
          if (token.stringValue == '>>') {
            // `>>` is converted to `>` in the parser when needed.
            return sought.stringValue == '>' &&
                token.charOffset <= sought.charOffset &&
                sought.charOffset < token.charEnd;
          }
          return false;
        }

        /// Check that [begin] and [end] can be found between [from] and [to].
        validateToken(Token from, Token to) {
          if (from == null || to == null) return true;
          bool foundBegin = false;
          bool foundEnd = false;
          Token token = from;
          while (true) {
            if (sameToken(token, begin)) {
              foundBegin = true;
            }
            if (sameToken(token, end)) {
              foundEnd = true;
            }
            if (foundBegin && foundEnd) {
              return true;
            }
            if (token == to || token == token.next || token.next == null) {
              break;
            }
            token = token.next;
          }

          // Create a good message for when the tokens were not found.
          StringBuffer sb = new StringBuffer();
          sb.write('Invalid current element: $element. ');
          sb.write('Looking for ');
          sb.write('[${begin} (${begin.hashCode}),');
          sb.write('${end} (${end.hashCode})] in');

          token = from;
          while (true) {
            sb.write('\n ${token} (${token.hashCode})');
            if (token == to || token == token.next || token.next == null) {
              break;
            }
            token = token.next;
          }
          return sb.toString();
        }

        if (element.enclosingClass != null &&
            element.enclosingClass.isEnumClass) {
          // Enums ASTs are synthesized (and give messed up messages).
          return true;
        }

        if (element is AstElement) {
          AstElement astElement = element;
          if (astElement.hasNode) {
            Token from = astElement.node.getBeginToken();
            Token to = astElement.node.getEndToken();
            if (astElement.metadata.isNotEmpty) {
              if (!astElement.metadata.first.hasNode) {
                // We might try to report an error while parsing the metadata
                // itself.
                return true;
              }
              from = astElement.metadata.first.node.getBeginToken();
            }
            return validateToken(from, to);
          }
        }
        return true;
      },
          failedAt(currentElement,
              "Invalid current element: $element [$begin,$end]."));
    }
    return new SourceSpan.fromTokens(uri, begin, end);
  }

  SourceSpan _spanFromNode(Element currentElement, Node node) {
    return _spanFromTokens(
        currentElement, node.getBeginToken(), node.getPrefixEndToken());
  }

  SourceSpan _spanFromElement(Element currentElement, Element element) {
    if (element != null && element.sourcePosition != null) {
      return element.sourcePosition;
    }
    while (element != null && element.isSynthesized) {
      element = element.enclosingElement;
    }
    if (element != null &&
        element.sourcePosition == null &&
        !element.isLibrary &&
        !element.isCompilationUnit) {
      // Sometimes, the backend fakes up elements that have no
      // position. So we use the enclosing element instead. It is
      // not a good error location, but cancel really is "internal
      // error" or "not implemented yet", so the vicinity is good
      // enough for now.
      element = element.enclosingElement;
      // TODO(ahe): I plan to overhaul this infrastructure anyways.
    }
    if (element == null) {
      element = currentElement;
    }
    if (element == null) {
      return null;
    }

    if (element.sourcePosition != null) {
      return element.sourcePosition;
    }
    Token position = element.position;
    Uri uri = element.compilationUnit.script.resourceUri;
    return (position == null)
        ? new SourceSpan(uri, 0, 0)
        : _spanFromTokens(currentElement, position, position, uri);
  }

  SourceSpan spanFromSpannable(Spannable node, Entity currentElement) {
    if (node is Node) {
      return _spanFromNode(currentElement, node);
    } else if (node is Element) {
      return _spanFromElement(currentElement, node);
    } else if (node is MetadataAnnotation) {
      return node.sourcePosition;
    }
    return null;
  }
}

/// An element environment base on a [Compiler].
class _CompilerElementEnvironment implements ElementEnvironment {
  final Compiler _compiler;

  LibraryEntity _mainLibrary;
  FunctionEntity _mainFunction;

  _CompilerElementEnvironment(this._compiler);

  LibraryProvider get _libraryProvider => _compiler.libraryLoader;
  Resolution get _resolution => _compiler.resolution;

  ResolutionDynamicType get dynamicType => const ResolutionDynamicType();

  @override
  LibraryEntity get mainLibrary => _mainLibrary;

  @override
  FunctionEntity get mainFunction => _mainFunction;

  @override
  Iterable<LibraryEntity> get libraries => _compiler.libraryLoader.libraries;

  @override
  String getLibraryName(LibraryElement library) => library.libraryName;

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
  bool isMixinApplication(ClassElement cls) {
    return cls.isMixinApplication;
  }

  @override
  bool isUnnamedMixinApplication(ClassElement cls) {
    return cls.isUnnamedMixinApplication;
  }

  @override
  ClassEntity getEffectiveMixinClass(ClassElement cls) {
    if (!cls.isMixinApplication) return null;
    do {
      MixinApplicationElement mixinApplication = cls;
      cls = mixinApplication.mixin;
    } while (cls.isMixinApplication);
    return cls;
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
    // TODO(johnniwinther): Skip redirecting factories.
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
    cls.forEachMember((ClassElement declarer, _member) {
      MemberElement member = _member;
      if (member.isSynthesized) return;
      if (member.isMalformed) return;
      if (member.isConstructor) return;
      f(declarer, member);
    }, includeSuperAndInjectedMembers: true);
  }

  @override
  void forEachConstructor(
      ClassElement cls, void f(ConstructorEntity constructor)) {
    cls.ensureResolved(_resolution);
    for (ConstructorElement constructor in cls.implementation.constructors) {
      _resolution.ensureResolved(constructor.declaration);
      if (constructor.isRedirectingFactory) continue;
      f(constructor);
    }
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
  void forEachLibraryMember(
      LibraryElement library, void f(MemberEntity member)) {
    library.implementation.forEachLocalMember((Element element) {
      if (!element.isClass && !element.isTypedef) {
        MemberElement member = element;
        f(member);
      }
    });
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
  bool isDeferredLoadLibraryGetter(MemberElement member) {
    return member.isDeferredLoaderGetter;
  }

  @override
  ResolutionFunctionType getFunctionType(MethodElement method) {
    if (method is ConstructorBodyElement) {
      return method.constructor.type;
    }
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
        assert(metadata.constant != null,
            failedAt(metadata, "Unevaluated metadata constant."));
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

  CommonElements get _commonElements => _compiler.resolution.commonElements;

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
            name = stringValue.primitiveValue;
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

        classElement.forEachMember((ClassElement classElement, _member) {
          MemberElement member = _member;
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
              fn.functionSignature.orderedForEachParameter((_parameter) {
                ParameterElement parameter = _parameter;
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

/// Builder that creates work item necessary for the resolution of a
/// [MemberElement].
class ResolutionWorkItemBuilder extends WorkItemBuilder {
  final Resolution _resolution;

  ResolutionWorkItemBuilder(this._resolution);

  @override
  WorkItem createWorkItem(MemberElement element) {
    assert(element.isDeclaration, failedAt(element));
    if (element.isMalformed) return null;

    assert(element is AnalyzableElement,
        failedAt(element, 'Element $element is not analyzable.'));
    return _resolution.createWorkItem(element);
  }
}
