// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.program_builder;

import '../js_emitter.dart' show computeMixinClass, Emitter;
import '../model.dart';

import '../../common.dart';
import '../../closure.dart' show ClosureFieldElement;
import '../../js/js.dart' as js;

import '../../js_backend/js_backend.dart' show
    Namer,
    JavaScriptBackend,
    JavaScriptConstantCompiler;

import '../js_emitter.dart' show
    ClassStubGenerator,
    CodeEmitterTask,
    InterceptorStubGenerator,
    MainCallStubGenerator,
    ParameterStubGenerator,
    RuntimeTypeGenerator,
    TypeTestProperties;

import '../../elements/elements.dart' show
    FieldElement,
    MethodElement,
    ParameterElement;

import '../../universe/universe.dart' show Universe, TypeMaskSet;
import '../../deferred_load.dart' show DeferredLoadTask, OutputUnit;

part 'collector.dart';
part 'registry.dart';
part 'field_visitor.dart';

/// Builds a self-contained representation of the program that can then be
/// emitted more easily by the individual emitters.
class ProgramBuilder {
  final Compiler _compiler;
  final Namer namer;
  final CodeEmitterTask _task;

  /// Contains the collected information the program builder used to build
  /// the model.
  // The collector will be filled on the first call to `buildProgram`.
  // It is stored and publicly exposed for backwards compatibility. New code
  // (and in particular new emitters) should not use it.
  final Collector collector;

  final Registry _registry;

  /// True if the program should store function types in the metadata.
  bool _storeFunctionTypesInMetadata = false;

  ProgramBuilder(Compiler compiler,
                 Namer namer,
                 this._task,
                 Emitter emitter,
                 Set<ClassElement> rtiNeededClasses)
      : this._compiler = compiler,
        this.namer = namer,
        this.collector =
            new Collector(compiler, namer, rtiNeededClasses, emitter),
        this._registry = new Registry(compiler);

  JavaScriptBackend get backend => _compiler.backend;
  Universe get universe => _compiler.codegenWorld;

  /// Mapping from [ClassElement] to constructed [Class]. We need this to
  /// update the superclass in the [Class].
  final Map<ClassElement, Class> _classes = <ClassElement, Class>{};

  /// Mapping from [OutputUnit] to constructed [Fragment]. We need this to
  /// generate the deferredLoadingMap (to know which hunks to load).
  final Map<OutputUnit, Fragment> _outputs = <OutputUnit, Fragment>{};

  /// Mapping from [ConstantValue] to constructed [Constant]. We need this to
  /// update field-initializers to point to the ConstantModel.
  final Map<ConstantValue, Constant> _constants = <ConstantValue, Constant>{};

  Set<Class> _unneededNativeClasses;

  Program buildProgram({bool storeFunctionTypesInMetadata: false}) {
    collector.collect();

    this._storeFunctionTypesInMetadata = storeFunctionTypesInMetadata;
    // Note: In rare cases (mostly tests) output units can be empty. This
    // happens when the deferred code is dead-code eliminated but we still need
    // to check that the library has been loaded.
    _compiler.deferredLoadTask.allOutputUnits.forEach(
        _registry.registerOutputUnit);
    collector.outputClassLists.forEach(_registry.registerElements);
    collector.outputStaticLists.forEach(_registry.registerElements);
    collector.outputConstantLists.forEach(_registerConstants);
    collector.outputStaticNonFinalFieldLists.forEach(
        _registry.registerElements);

    // We always add the current isolate holder.
    _registerStaticStateHolder();

    // We need to run the native-preparation before we build the output. The
    // preparation code, in turn needs the classes to be set up.
    // We thus build the classes before building their containers.
    collector.outputClassLists.forEach((OutputUnit _, List<ClassElement> classes) {
      classes.forEach(_buildClass);
    });

    // Resolve the superclass references after we've processed all the classes.
    _classes.forEach((ClassElement element, Class c) {
      if (element.superclass != null) {
        c.setSuperclass(_classes[element.superclass]);
        assert(c.superclass != null);
      }
      if (c is MixinApplication) {
        c.setMixinClass(_classes[computeMixinClass(element)]);
        assert(c.mixinClass != null);
      }
    });

    List<Class> nativeClasses = collector.nativeClassesAndSubclasses
        .map((ClassElement classElement) => _classes[classElement])
        .toList();

    Set<ClassElement> interceptorClassesNeededByConstants =
        collector.computeInterceptorsReferencedFromConstants();
    Set<ClassElement> classesModifiedByEmitRTISupport =
        _task.typeTestRegistry.computeClassesModifiedByEmitRuntimeTypeSupport();


    _unneededNativeClasses = _task.nativeEmitter.prepareNativeClasses(
        nativeClasses, interceptorClassesNeededByConstants,
        classesModifiedByEmitRTISupport);

    MainFragment mainFragment = _buildMainFragment(_registry.mainLibrariesMap);
    Iterable<Fragment> deferredFragments =
        _registry.deferredLibrariesMap.map(_buildDeferredFragment);

    List<Fragment> fragments = new List<Fragment>(_registry.librariesMapCount);
    fragments[0] = mainFragment;
    fragments.setAll(1, deferredFragments);

    _markEagerClasses();

    List<Holder> holders = _registry.holders.toList(growable: false);

    bool needsNativeSupport = _compiler.enqueuer.codegen.nativeEnqueuer
        .hasInstantiatedNativeClasses();

    assert(!needsNativeSupport || nativeClasses.isNotEmpty);

    List<js.TokenFinalizer> finalizers = [_task.metadataCollector];
    if (backend.namer is js.TokenFinalizer) {
      var namingFinalizer = backend.namer;
      finalizers.add(namingFinalizer);
    }

    return new Program(
        fragments,
        holders,
        _buildLoadMap(),
        _buildTypeToInterceptorMap(),
        _task.metadataCollector,
        finalizers,
        needsNativeSupport: needsNativeSupport,
        outputContainsConstantList: collector.outputContainsConstantList,
        hasIsolateSupport: _compiler.hasIsolateSupport);
  }

  void _markEagerClasses() {
    _markEagerInterceptorClasses();
  }

  /// Builds a map from loadId to outputs-to-load.
  Map<String, List<Fragment>> _buildLoadMap() {
    Map<String, List<Fragment>> loadMap = <String, List<Fragment>>{};
    _compiler.deferredLoadTask.hunksToLoad
        .forEach((String loadId, List<OutputUnit> outputUnits) {
      loadMap[loadId] = outputUnits
          .map((OutputUnit unit) => _outputs[unit])
          .toList(growable: false);
    });
    return loadMap;
  }

  js.Expression _buildTypeToInterceptorMap() {
    InterceptorStubGenerator stubGenerator =
        new InterceptorStubGenerator(_compiler, namer, backend);
    return stubGenerator.generateTypeToInterceptorMap();
  }

  MainFragment _buildMainFragment(LibrariesMap librariesMap) {
    // Construct the main output from the libraries and the registered holders.
    MainFragment result = new MainFragment(
        librariesMap.outputUnit,
        "",  // The empty string is the name for the main output file.
        _buildInvokeMain(),
        _buildLibraries(librariesMap),
        _buildStaticNonFinalFields(librariesMap),
        _buildStaticLazilyInitializedFields(librariesMap),
        _buildConstants(librariesMap));
    _outputs[librariesMap.outputUnit] = result;
    return result;
  }

  js.Statement _buildInvokeMain() {
    if (_compiler.isMockCompilation) return js.js.comment("Mock compilation");

    MainCallStubGenerator generator =
        new MainCallStubGenerator(_compiler, backend, backend.emitter);
    return generator.generateInvokeMain();
  }

  DeferredFragment _buildDeferredFragment(LibrariesMap librariesMap) {
    DeferredFragment result = new DeferredFragment(
        librariesMap.outputUnit,
        backend.deferredPartFileName(librariesMap.name, addExtension: false),
                                     librariesMap.name,
        _buildLibraries(librariesMap),
        _buildStaticNonFinalFields(librariesMap),
        _buildStaticLazilyInitializedFields(librariesMap),
        _buildConstants(librariesMap));
    _outputs[librariesMap.outputUnit] = result;
    return result;
  }

  List<Constant> _buildConstants(LibrariesMap librariesMap) {
    List<ConstantValue> constantValues =
        collector.outputConstantLists[librariesMap.outputUnit];
    if (constantValues == null) return const <Constant>[];
    return constantValues.map((ConstantValue value) => _constants[value])
        .toList(growable: false);
  }

  List<StaticField> _buildStaticNonFinalFields(LibrariesMap librariesMap) {
    List<VariableElement> staticNonFinalFields =
         collector.outputStaticNonFinalFieldLists[librariesMap.outputUnit];
    if (staticNonFinalFields == null) return const <StaticField>[];

    return staticNonFinalFields
        .map(_buildStaticField)
        .toList(growable: false);
  }

  StaticField _buildStaticField(Element element) {
    JavaScriptConstantCompiler handler = backend.constants;
    ConstantValue initialValue = handler.getInitialValueFor(element);
    // TODO(zarah): The holder should not be registered during building of
    // a static field.
    _registry.registerHolder(
        namer.globalObjectForConstant(initialValue), isConstantsHolder: true);
    js.Expression code = _task.emitter.constantReference(initialValue);
    js.Name name = namer.globalPropertyName(element);
    bool isFinal = false;
    bool isLazy = false;

    // TODO(floitsch): we shouldn't update the registry in the middle of
    // building a static field. (Note that the static-state holder was
    // already registered earlier, and that we just call the register to get
    // the holder-instance.
    return new StaticField(element,
                           name, _registerStaticStateHolder(), code,
                           isFinal, isLazy);
  }

  List<StaticField> _buildStaticLazilyInitializedFields(
      LibrariesMap librariesMap) {
    // TODO(floitsch): lazy fields should just be in their respective
    // libraries.
    if (librariesMap != _registry.mainLibrariesMap) {
      return const <StaticField>[];
    }

    JavaScriptConstantCompiler handler = backend.constants;
    List<VariableElement> lazyFields =
        handler.getLazilyInitializedFieldsForEmission();
    return Elements.sortedByPosition(lazyFields)
        .map(_buildLazyField)
        .where((field) => field != null)  // Happens when the field was unused.
        .toList(growable: false);
  }

  StaticField _buildLazyField(Element element) {
    js.Expression code = backend.generatedCode[element];
    // The code is null if we ended up not needing the lazily
    // initialized field after all because of constant folding
    // before code generation.
    if (code == null) return null;

    js.Name name = namer.globalPropertyName(element);
    bool isFinal = element.isFinal;
    bool isLazy = true;
    // TODO(floitsch): we shouldn't update the registry in the middle of
    // building a static field. (Note that the static-state holder was
    // already registered earlier, and that we just call the register to get
    // the holder-instance.
    return new StaticField(element,
                           name, _registerStaticStateHolder(), code,
                           isFinal, isLazy);
  }

  List<Library> _buildLibraries(LibrariesMap librariesMap) {
    List<Library> libraries = new List<Library>(librariesMap.length);
    int count = 0;
    librariesMap.forEach((LibraryElement library, List<Element> elements) {
      libraries[count++] = _buildLibrary(library, elements);
    });
    return libraries;
  }

  // Note that a library-element may have multiple [Library]s, if it is split
  // into multiple output units.
  Library _buildLibrary(LibraryElement library, List<Element> elements) {
    String uri = library.canonicalUri.toString();

    List<StaticMethod> statics = elements
        .where((e) => e is FunctionElement)
        .map(_buildStaticMethod)
        .toList();

    if (library == backend.interceptorsLibrary) {
      statics.addAll(_generateGetInterceptorMethods());
      statics.addAll(_generateOneShotInterceptors());
    }

    List<Class> classes = elements
        .where((e) => e is ClassElement)
        .map((ClassElement classElement) => _classes[classElement])
        .where((Class cls) =>
            !cls.isNative || !_unneededNativeClasses.contains(cls))
        .toList(growable: false);

    bool visitStatics = true;
    List<Field> staticFieldsForReflection = _buildFields(library, visitStatics);

    return new Library(library, uri, statics, classes,
                       staticFieldsForReflection);
  }

  /// HACK for Incremental Compilation.
  ///
  /// Returns a class that contains the fields of a class.
  Class buildFieldsHackForIncrementalCompilation(ClassElement element) {
    assert(_compiler.hasIncrementalSupport);

    List<Field> instanceFields = _buildFields(element, false);
    js.Name name = namer.className(element);

    return new Class(
        element, name, null, [], instanceFields, [], [], [], [], [], null,
        isDirectlyInstantiated: true,
        onlyForRti: false,
        isNative: element.isNative);
  }

  Class _buildClass(ClassElement element) {
    bool onlyForRti = collector.classesOnlyNeededForRti.contains(element);

    List<Method> methods = [];
    List<StubMethod> callStubs = <StubMethod>[];

    ClassStubGenerator classStubGenerator =
        new ClassStubGenerator(_compiler, namer, backend);
    RuntimeTypeGenerator runtimeTypeGenerator =
        new RuntimeTypeGenerator(_compiler, _task, namer);

    void visitMember(ClassElement enclosing, Element member) {
      assert(invariant(element, member.isDeclaration));
      assert(invariant(element, element == enclosing));

      if (Elements.isNonAbstractInstanceMember(member)) {
        // TODO(herhut): Remove once _buildMethod can no longer return null.
        Method method = _buildMethod(member);
        if (method != null) methods.add(method);
      }
      if (member.isGetter || member.isField) {
        Map<Selector, TypeMaskSet> selectors =
            _compiler.codegenWorld.invocationsByName(member.name);
        if (selectors != null && !selectors.isEmpty) {

          Map<js.Name, js.Expression> callStubsForMember =
              classStubGenerator.generateCallStubsForGetter(member, selectors);
          callStubsForMember.forEach((js.Name name, js.Expression code) {
            callStubs.add(_buildStubMethod(name, code, element: member));
          });
        }
      }
    }

    List<StubMethod> typeVariableReaderStubs =
        runtimeTypeGenerator.generateTypeVariableReaderStubs(element);

    List<StubMethod> noSuchMethodStubs = <StubMethod>[];
    if (backend.enabledNoSuchMethod && element == _compiler.objectClass) {
      Map<js.Name, Selector> selectors =
          classStubGenerator.computeSelectorsForNsmHandlers();
      selectors.forEach((js.Name name, Selector selector) {
        noSuchMethodStubs
            .add(classStubGenerator.generateStubForNoSuchMethod(name,
                                                                selector));
      });
    }

    if (element == backend.closureClass) {
      // We add a special getter here to allow for tearing off a closure from
      // itself.
      js.Name name = namer.getterForMember(Selector.CALL_NAME);
      js.Fun function = js.js('function() { return this; }');
      callStubs.add(_buildStubMethod(name, function));
    }

    ClassElement implementation = element.implementation;

    // MixinApplications run through the members of their mixin. Here, we are
    // only interested in direct members.
    if (!onlyForRti && !element.isMixinApplication) {
      implementation.forEachMember(visitMember, includeBackendMembers: true);
    }

    List<Field> instanceFields =
        onlyForRti ? const <Field>[] : _buildFields(element, false);
    List<Field> staticFieldsForReflection =
        onlyForRti ? const <Field>[] : _buildFields(element, true);

    TypeTestProperties typeTests =
        runtimeTypeGenerator.generateIsTests(
            element,
            storeFunctionTypeInMetadata: _storeFunctionTypesInMetadata);

    List<StubMethod> isChecks = <StubMethod>[];
    typeTests.properties.forEach((js.Name name, js.Node code) {
      isChecks.add(_buildStubMethod(name, code));
    });

    js.Name name = namer.className(element);
    String holderName = namer.globalObjectFor(element);
    // TODO(floitsch): we shouldn't update the registry in the middle of
    // building a class.
    Holder holder = _registry.registerHolder(holderName);
    bool isInstantiated =
        _compiler.codegenWorld.directlyInstantiatedClasses.contains(element);

    Class result;
    if (element.isMixinApplication && !onlyForRti) {
      assert(!element.isNative);
      assert(methods.isEmpty);

      result = new MixinApplication(element,
                                    name, holder,
                                    instanceFields,
                                    staticFieldsForReflection,
                                    callStubs,
                                    typeVariableReaderStubs,
                                    isChecks,
                                    typeTests.functionTypeIndex,
                                    isDirectlyInstantiated: isInstantiated,
                                    onlyForRti: onlyForRti);
    } else {
      result = new Class(element,
                         name, holder, methods, instanceFields,
                         staticFieldsForReflection,
                         callStubs,
                         typeVariableReaderStubs,
                         noSuchMethodStubs,
                         isChecks,
                         typeTests.functionTypeIndex,
                         isDirectlyInstantiated: isInstantiated,
                         onlyForRti: onlyForRti,
                         isNative: element.isNative);
    }
    _classes[element] = result;
    return result;
  }

  bool _methodNeedsStubs(FunctionElement method) {
    return !method.functionSignature.optionalParameters.isEmpty;
  }

  bool _methodCanBeReflected(FunctionElement method) {
    return backend.isAccessibleByReflection(method) ||
        // During incremental compilation, we have to assume that reflection
        // *might* get enabled.
        _compiler.hasIncrementalSupport;
  }

  bool _methodCanBeApplied(FunctionElement method) {
    return _compiler.enabledFunctionApply &&
        _compiler.world.getMightBePassedToApply(method);
  }

  // TODO(herhut): Refactor incremental compilation and remove method.
  Method buildMethodHackForIncrementalCompilation(FunctionElement element) {
    assert(_compiler.hasIncrementalSupport);
    if (element.isInstanceMember) {
      return _buildMethod(element);
    } else {
      return _buildStaticMethod(element);
    }
  }

  /* Map | List */ _computeParameterDefaultValues(FunctionSignature signature) {
    var /* Map | List */ optionalParameterDefaultValues;
    if (signature.optionalParametersAreNamed) {
      optionalParameterDefaultValues = new Map<String, ConstantValue>();
      signature.forEachOptionalParameter((ParameterElement parameter) {
        ConstantValue def =
            backend.constants.getConstantValueForVariable(parameter);
        optionalParameterDefaultValues[parameter.name] = def;
      });
    } else {
      optionalParameterDefaultValues = <ConstantValue>[];
      signature.forEachOptionalParameter((ParameterElement parameter) {
        ConstantValue def =
            backend.constants.getConstantValueForVariable(parameter);
        optionalParameterDefaultValues.add(def);
      });
    }
    return optionalParameterDefaultValues;
  }

  DartMethod _buildMethod(MethodElement element) {
    js.Name name = namer.methodPropertyName(element);
    js.Expression code = backend.generatedCode[element];

    // TODO(kasperl): Figure out under which conditions code is null.
    if (code == null) return null;

    bool canTearOff = false;
    js.Name tearOffName;
    bool isClosure = false;
    bool isNotApplyTarget = !element.isFunction || element.isAccessor;

    bool canBeReflected = _methodCanBeReflected(element);
    bool canBeApplied = _methodCanBeApplied(element);

    js.Name aliasName = backend.isAliasedSuperMember(element)
        ? namer.aliasedSuperMemberPropertyName(element)
        : null;

    if (isNotApplyTarget) {
      canTearOff = false;
    } else {
      if (element.enclosingClass.isClosure) {
        canTearOff = false;
        isClosure = true;
      } else {
        // Careful with operators.
        canTearOff = universe.hasInvokedGetter(element, _compiler.world) ||
            (canBeReflected && !element.isOperator);
        assert(canTearOff ||
               !universe.methodsNeedingSuperGetter.contains(element));
        tearOffName = namer.getterForElement(element);
      }
    }

    if (canTearOff) {
      assert(invariant(element, !element.isGenerativeConstructor));
      assert(invariant(element, !element.isGenerativeConstructorBody));
      assert(invariant(element, !element.isConstructor));
    }

    js.Name callName = null;
    if (canTearOff) {
      Selector callSelector =
          new Selector.fromElement(element).toCallSelector();
      callName = namer.invocationName(callSelector);
    }

    DartType memberType;
    if (element.isGenerativeConstructorBody) {
      // TODO(herhut): Why does this need to be normalized away? We never need
      //               this information anyway as they cannot be torn off or
      //               reflected.
      var body = element;
      memberType = body.constructor.type;
    } else {
      memberType = element.type;
    }

    js.Expression functionType;
    if (canTearOff || canBeReflected) {
      OutputUnit outputUnit =
          _compiler.deferredLoadTask.outputUnitForElement(element);
      functionType = _generateFunctionType(memberType, outputUnit);
    }

    int requiredParameterCount;
    var /* List | Map */ optionalParameterDefaultValues;
    if (canBeApplied || canBeReflected) {
      FunctionSignature signature = element.functionSignature;
      requiredParameterCount = signature.requiredParameterCount;
      optionalParameterDefaultValues =
          _computeParameterDefaultValues(signature);
    }

    return new InstanceMethod(element, name, code,
        _generateParameterStubs(element, canTearOff), callName,
        needsTearOff: canTearOff, tearOffName: tearOffName,
        isClosure: isClosure, aliasName: aliasName,
        canBeApplied: canBeApplied, canBeReflected: canBeReflected,
        requiredParameterCount: requiredParameterCount,
        optionalParameterDefaultValues: optionalParameterDefaultValues,
        functionType: functionType);
  }

  js.Expression _generateFunctionType(DartType type, OutputUnit outputUnit) {
    if (type.containsTypeVariables) {
      js.Expression thisAccess = js.js(r'this.$receiver');
      return backend.rti.getSignatureEncoding(type, thisAccess);
    } else {
      return backend.emitter.metadataCollector
          .reifyTypeForOutputUnit(type, outputUnit);
    }
  }

  List<ParameterStubMethod> _generateParameterStubs(MethodElement element,
                                                    bool canTearOff) {

    if (!_methodNeedsStubs(element)) return const <ParameterStubMethod>[];

    ParameterStubGenerator generator =
        new ParameterStubGenerator(_compiler, namer, backend);
    return generator.generateParameterStubs(element, canTearOff: canTearOff);
  }

  /// Builds a stub method.
  ///
  /// Stub methods may have an element that can be used for code-size
  /// attribution.
  Method _buildStubMethod(js.Name name, js.Expression code,
                          {Element element}) {
    return new StubMethod(name, code, element: element);
  }

  // The getInterceptor methods directly access the prototype of classes.
  // We must evaluate these classes eagerly so that the prototype is
  // accessible.
  void _markEagerInterceptorClasses() {
    Map<js.Name, Set<ClassElement>> specializedGetInterceptors =
        backend.specializedGetInterceptors;
    for (Set<ClassElement> classes in specializedGetInterceptors.values) {
      for (ClassElement element in classes) {
        Class cls = _classes[element];
        if (cls != null) cls.isEager = true;
      }
    }
  }

  Iterable<StaticStubMethod> _generateGetInterceptorMethods() {
    InterceptorStubGenerator stubGenerator =
        new InterceptorStubGenerator(_compiler, namer, backend);

    String holderName = namer.globalObjectFor(backend.interceptorsLibrary);
    // TODO(floitsch): we shouldn't update the registry in the middle of
    // generating the interceptor methods.
    Holder holder = _registry.registerHolder(holderName);

    Map<js.Name, Set<ClassElement>> specializedGetInterceptors =
        backend.specializedGetInterceptors;
    List<js.Name> names = specializedGetInterceptors.keys.toList()..sort();
    return names.map((js.Name name) {
      Set<ClassElement> classes = specializedGetInterceptors[name];
      js.Expression code = stubGenerator.generateGetInterceptorMethod(classes);
      return new StaticStubMethod(name, holder, code);
    });
  }

  List<Field> _buildFields(Element holder, bool visitStatics) {
    List<Field> fields = <Field>[];
    new FieldVisitor(_compiler, namer).visitFields(
        holder, visitStatics, (VariableElement field,
                               js.Name name,
                               js.Name accessorName,
                               bool needsGetter,
                               bool needsSetter,
                               bool needsCheckedSetter) {
      assert(invariant(field, field.isDeclaration));

      int getterFlags = 0;
      if (needsGetter) {
        if (visitStatics || !backend.fieldHasInterceptedGetter(field)) {
          getterFlags = 1;
        } else {
          getterFlags += 2;
          // TODO(sra): 'isInterceptorClass' might not be the correct test
          // for methods forced to use the interceptor convention because
          // the method's class was elsewhere mixed-in to an interceptor.
          if (!backend.isInterceptorClass(holder)) {
            getterFlags += 1;
          }
        }
      }

      int setterFlags = 0;
      if (needsSetter) {
        if (visitStatics || !backend.fieldHasInterceptedSetter(field)) {
          setterFlags = 1;
        } else {
          setterFlags += 2;
          if (!backend.isInterceptorClass(holder)) {
            setterFlags += 1;
          }
        }
      }

      fields.add(new Field(field, name, accessorName,
                           getterFlags, setterFlags,
                           needsCheckedSetter));
    });

    return fields;
  }

  Iterable<StaticStubMethod> _generateOneShotInterceptors() {
    InterceptorStubGenerator stubGenerator =
        new InterceptorStubGenerator(_compiler, namer, backend);

    String holderName = namer.globalObjectFor(backend.interceptorsLibrary);
    // TODO(floitsch): we shouldn't update the registry in the middle of
    // generating the interceptor methods.
    Holder holder = _registry.registerHolder(holderName);

    List<js.Name> names = backend.oneShotInterceptors.keys.toList()..sort();
    return names.map((js.Name name) {
      js.Expression code = stubGenerator.generateOneShotInterceptor(name);
      return new StaticStubMethod(name, holder, code);
    });
  }

  StaticDartMethod _buildStaticMethod(FunctionElement element) {
    js.Name name = namer.methodPropertyName(element);
    String holder = namer.globalObjectFor(element);
    js.Expression code = backend.generatedCode[element];

    bool isApplyTarget = !element.isConstructor && !element.isAccessor;
    bool canBeApplied = _methodCanBeApplied(element);
    bool canBeReflected = _methodCanBeReflected(element);

    bool needsTearOff = isApplyTarget &&
        (canBeReflected ||
            universe.staticFunctionsNeedingGetter.contains(element));

    js.Name tearOffName =
        needsTearOff ? namer.staticClosureName(element) : null;


    js.Name callName = null;
    if (needsTearOff) {
      Selector callSelector =
          new Selector.fromElement(element).toCallSelector();
      callName = namer.invocationName(callSelector);
    }
    js.Expression functionType;
    DartType type = element.type;
    if (needsTearOff || canBeReflected) {
      OutputUnit outputUnit =
          _compiler.deferredLoadTask.outputUnitForElement(element);
      functionType = _generateFunctionType(type, outputUnit);
    }

    int requiredParameterCount;
    var /* List | Map */ optionalParameterDefaultValues;
    if (canBeApplied || canBeReflected) {
      FunctionSignature signature = element.functionSignature;
      requiredParameterCount = signature.requiredParameterCount;
      optionalParameterDefaultValues =
          _computeParameterDefaultValues(signature);
    }

    // TODO(floitsch): we shouldn't update the registry in the middle of
    // building a static method.
    return new StaticDartMethod(element,
                                name, _registry.registerHolder(holder), code,
                                _generateParameterStubs(element, needsTearOff),
                                callName,
                                needsTearOff: needsTearOff,
                                tearOffName: tearOffName,
                                canBeApplied: canBeApplied,
                                canBeReflected: canBeReflected,
                                requiredParameterCount: requiredParameterCount,
                                optionalParameterDefaultValues:
                                  optionalParameterDefaultValues,
                                functionType: functionType);
  }

  void _registerConstants(OutputUnit outputUnit,
                          Iterable<ConstantValue> constantValues) {
    // `constantValues` is null if an outputUnit doesn't contain any constants.
    if (constantValues == null) return;
    for (ConstantValue constantValue in constantValues) {
      _registry.registerConstant(outputUnit, constantValue);
      assert(!_constants.containsKey(constantValue));
      js.Name name = namer.constantName(constantValue);
      String constantObject = namer.globalObjectForConstant(constantValue);
      Holder holder =
          _registry.registerHolder(constantObject, isConstantsHolder: true);
      Constant constant = new Constant(name, holder, constantValue);
      _constants[constantValue] = constant;
    }
  }

  Holder _registerStaticStateHolder() {
    return _registry.registerHolder(
        namer.staticStateHolder, isStaticStateHolder: true);
  }
}
