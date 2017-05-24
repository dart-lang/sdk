// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.program_builder;

import 'dart:io';
import 'dart:convert' show JSON;

import '../../closure.dart' show ClosureTask, ClosureFieldElement;
import '../../common.dart';
import '../../common/names.dart' show Names, Selectors;
import '../../constants/values.dart'
    show ConstantValue, InterceptorConstantValue;
import '../../common_elements.dart' show CommonElements, ElementEnvironment;
import '../../deferred_load.dart' show DeferredLoadTask, OutputUnit;
import '../../elements/elements.dart'
    show
        ClassElement,
        Element,
        Elements,
        FieldElement,
        FunctionElement,
        FunctionSignature,
        GetterElement,
        LibraryElement,
        MemberElement,
        MethodElement,
        ParameterElement,
        TypedefElement,
        VariableElement;
import '../../elements/entities.dart';
import '../../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionFunctionType, ResolutionTypedefType;
import '../../elements/types.dart' show DartType, DartTypes;
import '../../js/js.dart' as js;
import '../../js_backend/backend.dart' show SuperMemberData;
import '../../js_backend/backend_usage.dart';
import '../../js_backend/constant_handler_javascript.dart'
    show JavaScriptConstantCompiler;
import '../../js_backend/custom_elements_analysis.dart';
import '../../js_backend/namer.dart' show Namer, StringBackedName;
import '../../js_backend/native_data.dart';
import '../../js_backend/interceptor_data.dart';
import '../../js_backend/mirrors_data.dart';
import '../../js_backend/js_interop_analysis.dart';
import '../../js_backend/runtime_types.dart'
    show
        RuntimeTypesChecks,
        RuntimeTypesNeed,
        RuntimeTypesEncoder,
        RuntimeTypesSubstitutions;
import '../../native/enqueue.dart' show NativeCodegenEnqueuer;
import '../../options.dart';
import '../../universe/selector.dart' show Selector;
import '../../universe/world_builder.dart'
    show CodegenWorldBuilder, SelectorConstraints;
import '../../world.dart' show ClosedWorld;
import '../js_emitter.dart'
    show
        ClassStubGenerator,
        CodeEmitterTask,
        computeMixinClass,
        Emitter,
        InterceptorStubGenerator,
        MainCallStubGenerator,
        ParameterStubGenerator,
        RuntimeTypeGenerator,
        TypeTestProperties;
import '../model.dart';
import '../sorter.dart';

part 'collector.dart';
part 'field_visitor.dart';
part 'registry.dart';

/// Builds a self-contained representation of the program that can then be
/// emitted more easily by the individual emitters.
class ProgramBuilder {
  final CompilerOptions _options;
  final DiagnosticReporter _reporter;
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final DartTypes _types;
  final DeferredLoadTask _deferredLoadTask;
  final ClosureTask _closureToClassMapper;
  final CodegenWorldBuilder _worldBuilder;
  final NativeCodegenEnqueuer _nativeCodegenEnqueuer;
  final BackendUsage _backendUsage;
  final JavaScriptConstantCompiler _constantHandler;
  final NativeData _nativeData;
  final RuntimeTypesNeed _rtiNeed;
  final MirrorsData _mirrorsData;
  final InterceptorData _interceptorData;
  final SuperMemberData _superMemberData;
  final RuntimeTypesChecks _rtiChecks;
  final RuntimeTypesEncoder _rtiEncoder;
  final RuntimeTypesSubstitutions _rtiSubstitutions;
  final JsInteropAnalysis _jsInteropAnalysis;
  final OneShotInterceptorData _oneShotInterceptorData;
  final CustomElementsCodegenAnalysis _customElementsCodegenAnalysis;
  final Map<MemberEntity, js.Expression> _generatedCode;
  final Namer _namer;
  final CodeEmitterTask _task;
  final ClosedWorld _closedWorld;

  /// Contains the collected information the program builder used to build
  /// the model.
  // The collector will be filled on the first call to `buildProgram`.
  // It is stored and publicly exposed for backwards compatibility. New code
  // (and in particular new emitters) should not use it.
  final Collector collector;

  final Registry _registry;

  final FunctionEntity _mainFunction;
  final bool _isMockCompilation;

  /// True if the program should store function types in the metadata.
  bool _storeFunctionTypesInMetadata = false;

  ProgramBuilder(
      this._options,
      this._reporter,
      this._elementEnvironment,
      this._commonElements,
      this._types,
      this._deferredLoadTask,
      this._closureToClassMapper,
      this._worldBuilder,
      this._nativeCodegenEnqueuer,
      this._backendUsage,
      this._constantHandler,
      this._nativeData,
      this._rtiNeed,
      this._mirrorsData,
      this._interceptorData,
      this._superMemberData,
      this._rtiChecks,
      this._rtiEncoder,
      this._rtiSubstitutions,
      this._jsInteropAnalysis,
      this._oneShotInterceptorData,
      this._customElementsCodegenAnalysis,
      this._generatedCode,
      this._namer,
      this._task,
      this._closedWorld,
      Set<ClassEntity> rtiNeededClasses,
      this._mainFunction,
      {bool isMockCompilation})
      : this._isMockCompilation = isMockCompilation,
        this.collector = new Collector(
            _options,
            _commonElements,
            _deferredLoadTask,
            _worldBuilder,
            _namer,
            _task.emitter,
            _constantHandler,
            _nativeData,
            _interceptorData,
            _oneShotInterceptorData,
            _mirrorsData,
            _closedWorld,
            rtiNeededClasses,
            _generatedCode,
            _task.sorter),
        this._registry = new Registry(_deferredLoadTask, _task.sorter);

  /// Mapping from [ClassEntity] to constructed [Class]. We need this to
  /// update the superclass in the [Class].
  final Map<ClassEntity, Class> _classes = <ClassEntity, Class>{};

  /// Mapping from [OutputUnit] to constructed [Fragment]. We need this to
  /// generate the deferredLoadingMap (to know which hunks to load).
  final Map<OutputUnit, Fragment> _outputs = <OutputUnit, Fragment>{};

  /// Mapping from [ConstantValue] to constructed [Constant]. We need this to
  /// update field-initializers to point to the ConstantModel.
  final Map<ConstantValue, Constant> _constants = <ConstantValue, Constant>{};

  /// Mapping from names to strings.
  ///
  /// This mapping is used to support `const Symbol` expressions.
  ///
  /// This map is filled when building classes.
  final Map<js.Name, String> _symbolsMap = <js.Name, String>{};

  Set<Class> _unneededNativeClasses;

  /// Classes that have been allocated during a profile run.
  ///
  /// These classes should not be soft-deferred.
  ///
  /// Also contains classes that are not tracked by the profile run (like
  /// interceptors, ...).
  Set<ClassElement> _notSoftDeferred;

  Program buildProgram({bool storeFunctionTypesInMetadata: false}) {
    collector.collect();
    _initializeSoftDeferredMap();

    this._storeFunctionTypesInMetadata = storeFunctionTypesInMetadata;
    // Note: In rare cases (mostly tests) output units can be empty. This
    // happens when the deferred code is dead-code eliminated but we still need
    // to check that the library has been loaded.
    _deferredLoadTask.allOutputUnits.forEach(_registry.registerOutputUnit);
    collector.outputClassLists.forEach(_registry.registerClasses);
    collector.outputStaticLists.forEach(_registry.registerMembers);
    collector.outputConstantLists.forEach(_registerConstants);
    collector.outputStaticNonFinalFieldLists.forEach(_registry.registerMembers);

    // We always add the current isolate holder.
    _registerStaticStateHolder();

    // We need to run the native-preparation before we build the output. The
    // preparation code, in turn needs the classes to be set up.
    // We thus build the classes before building their containers.
    collector.outputClassLists
        .forEach((OutputUnit _, List<ClassEntity> classes) {
      classes.forEach(_buildClass);
    });

    // Resolve the superclass references after we've processed all the classes.
    _classes.forEach((ClassEntity cls, Class c) {
      ClassEntity superclass = _elementEnvironment.getSuperClass(cls);
      if (superclass != null) {
        c.setSuperclass(_classes[superclass]);
        assert(
            c.superclass != null,
            failedAt(
                cls,
                "No Class for has been created for superclass "
                "${superclass} of $c."));
      }
      if (c is MixinApplication) {
        c.setMixinClass(_classes[computeMixinClass(cls)]);
        assert(c.mixinClass != null);
      }
    });

    List<Class> nativeClasses = collector.nativeClassesAndSubclasses
        .map((ClassEntity classElement) => _classes[classElement])
        .toList();

    Set<ClassEntity> interceptorClassesNeededByConstants =
        collector.computeInterceptorsReferencedFromConstants();
    Set<ClassEntity> classesModifiedByEmitRTISupport =
        _task.typeTestRegistry.computeClassesModifiedByEmitRuntimeTypeSupport();

    _unneededNativeClasses = _task.nativeEmitter.prepareNativeClasses(
        nativeClasses,
        interceptorClassesNeededByConstants,
        classesModifiedByEmitRTISupport);

    _addJsInteropStubs(_registry.mainLibrariesMap);

    MainFragment mainFragment = _buildMainFragment(_registry.mainLibrariesMap);
    Iterable<Fragment> deferredFragments =
        _registry.deferredLibrariesMap.map(_buildDeferredFragment);

    List<Fragment> fragments = new List<Fragment>(_registry.librariesMapCount);
    fragments[0] = mainFragment;
    fragments.setAll(1, deferredFragments);

    _markEagerClasses();

    List<Holder> holders = _registry.holders.toList(growable: false);

    bool needsNativeSupport =
        _nativeCodegenEnqueuer.hasInstantiatedNativeClasses;

    assert(!needsNativeSupport || nativeClasses.isNotEmpty);

    List<js.TokenFinalizer> finalizers = [_task.metadataCollector];
    if (_namer is js.TokenFinalizer) {
      var namingFinalizer = _namer;
      finalizers.add(namingFinalizer as js.TokenFinalizer);
    }

    return new Program(fragments, holders, _buildLoadMap(), _symbolsMap,
        _buildTypeToInterceptorMap(), _task.metadataCollector, finalizers,
        needsNativeSupport: needsNativeSupport,
        outputContainsConstantList: collector.outputContainsConstantList,
        hasIsolateSupport: _backendUsage.isIsolateInUse,
        hasSoftDeferredClasses: _notSoftDeferred != null);
  }

  void _markEagerClasses() {
    _markEagerInterceptorClasses();
  }

  void _initializeSoftDeferredMap() {
    var allocatedClassesPath = _options.experimentalAllocationsPath;
    if (allocatedClassesPath != null) {
      // TODO(29574): the following blacklist is ad-hoc and potentially
      // incomplete. We need to mark all classes as black listed, that are
      // used without code going through the class' constructor.
      var blackList = [
        'dart:_interceptors',
        'dart:html',
        'dart:typed_data_implementation',
        'dart:_native_typed_data'
      ].toSet();

      // TODO(29574): the compiler should not just use dart:io to get the
      // contents of a file.
      File file = new File(allocatedClassesPath);

      // TODO(29574): are the following checks necessary?
      // To make compilation in build-systems easier, we ignore non-existing
      // or empty profiles.
      if (!file.existsSync()) {
        _reporter.log("Profile file does not exist: $allocatedClassesPath");
        return;
      }
      if (file.lengthSync() == 0) {
        _reporter.log("Profile information (allocated classes) is empty.");
        return;
      }

      String data = new File(allocatedClassesPath).readAsStringSync();
      Set<String> allocatedClassesKeys = JSON.decode(data).keys.toSet();
      Set<ClassElement> allocatedClasses = new Set<ClassElement>();

      // Collects all super and mixin classes of a class.
      void collect(ClassElement element) {
        allocatedClasses.add(element);
        if (element.isMixinApplication) {
          collect(computeMixinClass(element));
        }
        if (element.superclass != null) {
          collect(element.superclass);
        }
      }

      // For every known class, see if it was allocated in the profile. If yes,
      // collect its dependencies (supers and mixins) and mark them as
      // not-soft-deferrable.
      collector.outputClassLists.forEach((_, List<ClassElement> elements) {
        for (ClassElement element in elements) {
          // TODO(29574): share the encoding of the element with the code
          // that emits the profile-run.
          var key = "${element.library.canonicalUri}:${element.name}";
          if (allocatedClassesKeys.contains(key) ||
              _nativeData.isJsInteropClass(element) ||
              blackList.contains(element.library.canonicalUri.toString())) {
            collect(element);
          }
        }
      });
      _notSoftDeferred = allocatedClasses;
    }
  }

  /// Builds a map from loadId to outputs-to-load.
  Map<String, List<Fragment>> _buildLoadMap() {
    Map<String, List<Fragment>> loadMap = <String, List<Fragment>>{};
    _deferredLoadTask.hunksToLoad
        .forEach((String loadId, List<OutputUnit> outputUnits) {
      loadMap[loadId] = outputUnits
          .map((OutputUnit unit) => _outputs[unit])
          .toList(growable: false);
    });
    return loadMap;
  }

  js.Expression _buildTypeToInterceptorMap() {
    InterceptorStubGenerator stubGenerator = new InterceptorStubGenerator(
        _options,
        _commonElements,
        _task,
        _nativeCodegenEnqueuer,
        _constantHandler,
        _namer,
        _oneShotInterceptorData,
        _customElementsCodegenAnalysis,
        _worldBuilder,
        _closedWorld);
    return stubGenerator.generateTypeToInterceptorMap();
  }

  MainFragment _buildMainFragment(LibrariesMap librariesMap) {
    // Construct the main output from the libraries and the registered holders.
    MainFragment result = new MainFragment(
        librariesMap.outputUnit,
        "", // The empty string is the name for the main output file.
        _buildInvokeMain(),
        _buildLibraries(librariesMap),
        _buildStaticNonFinalFields(librariesMap),
        _buildStaticLazilyInitializedFields(librariesMap),
        _buildConstants(librariesMap));
    _outputs[librariesMap.outputUnit] = result;
    return result;
  }

  js.Statement _buildInvokeMain() {
    if (_isMockCompilation) return js.js.comment("Mock compilation");

    MainCallStubGenerator generator = new MainCallStubGenerator(
        _commonElements, _task.emitter, _backendUsage);
    return generator.generateInvokeMain(_mainFunction);
  }

  DeferredFragment _buildDeferredFragment(LibrariesMap librariesMap) {
    DeferredFragment result = new DeferredFragment(
        librariesMap.outputUnit,
        _deferredLoadTask.deferredPartFileName(librariesMap.name,
            addExtension: false),
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
    return constantValues
        .map((ConstantValue value) => _constants[value])
        .toList(growable: false);
  }

  List<StaticField> _buildStaticNonFinalFields(LibrariesMap librariesMap) {
    List<FieldEntity> staticNonFinalFields =
        collector.outputStaticNonFinalFieldLists[librariesMap.outputUnit];
    if (staticNonFinalFields == null) return const <StaticField>[];

    return staticNonFinalFields.map(_buildStaticField).toList(growable: false);
  }

  StaticField _buildStaticField(FieldElement element) {
    ConstantValue initialValue =
        _constantHandler.getConstantValue(element.constant);
    // TODO(zarah): The holder should not be registered during building of
    // a static field.
    _registry.registerHolder(_namer.globalObjectForConstant(initialValue),
        isConstantsHolder: true);
    js.Expression code = _task.emitter.constantReference(initialValue);
    js.Name name = _namer.globalPropertyName(element);
    bool isFinal = false;
    bool isLazy = false;

    // TODO(floitsch): we shouldn't update the registry in the middle of
    // building a static field. (Note that the static-state holder was
    // already registered earlier, and that we just call the register to get
    // the holder-instance.
    return new StaticField(
        element, name, _registerStaticStateHolder(), code, isFinal, isLazy);
  }

  List<StaticField> _buildStaticLazilyInitializedFields(
      LibrariesMap librariesMap) {
    Iterable<FieldElement> lazyFields = _constantHandler
        .getLazilyInitializedFieldsForEmission()
        .where((element) =>
            _deferredLoadTask.outputUnitForElement(element) ==
            librariesMap.outputUnit);
    return Elements
        .sortedByPosition(lazyFields)
        .map(_buildLazyField)
        .where((field) => field != null) // Happens when the field was unused.
        .toList(growable: false);
  }

  StaticField _buildLazyField(FieldElement element) {
    js.Expression code = _generatedCode[element];
    // The code is null if we ended up not needing the lazily
    // initialized field after all because of constant folding
    // before code generation.
    if (code == null) return null;

    js.Name name = _namer.globalPropertyName(element);
    bool isFinal = element.isFinal;
    bool isLazy = true;
    // TODO(floitsch): we shouldn't update the registry in the middle of
    // building a static field. (Note that the static-state holder was
    // already registered earlier, and that we just call the register to get
    // the holder-instance.
    return new StaticField(
        element, name, _registerStaticStateHolder(), code, isFinal, isLazy);
  }

  List<Library> _buildLibraries(LibrariesMap librariesMap) {
    List<Library> libraries = new List<Library>(librariesMap.length);
    int count = 0;
    librariesMap.forEach((LibraryEntity library, List<ClassEntity> classes,
        List<MemberEntity> members) {
      libraries[count++] = _buildLibrary(library, classes, members);
    });
    return libraries;
  }

  void _addJsInteropStubs(LibrariesMap librariesMap) {
    if (_classes.containsKey(_commonElements.objectClass)) {
      var toStringInvocation = _namer.invocationName(Selectors.toString_);
      // TODO(jacobr): register toString as used so that it is always accessible
      // from JavaScript.
      _classes[_commonElements.objectClass].callStubs.add(_buildStubMethod(
          new StringBackedName("toString"),
          js.js('function() { return this.#(this) }', toStringInvocation)));
    }

    // We add all members from classes marked with isJsInterop to the base
    // Interceptor class with implementations that directly call the
    // corresponding JavaScript member. We do not attempt to bind this when
    // tearing off JavaScript methods as we cannot distinguish between calling
    // a regular getter that returns a JavaScript function and tearing off
    // a method in the case where there exist multiple JavaScript classes
    // that conflict on whether the member is a getter or a method.
    var interceptorClass = _classes[_commonElements.jsJavaScriptObjectClass];
    var stubNames = new Set<String>();
    librariesMap
        .forEach((LibraryEntity library, List<ClassEntity> classElements, _) {
      for (ClassElement e in classElements) {
        if (_nativeData.isJsInteropClass(e)) {
          e.declaration.forEachMember((_, Element member) {
            var jsName = _nativeData.computeUnescapedJSInteropName(member.name);
            if (!member.isInstanceMember) return;
            if (member.isGetter || member.isField || member.isFunction) {
              var selectors =
                  _worldBuilder.getterInvocationsByName(member.name);
              if (selectors != null && !selectors.isEmpty) {
                for (var selector in selectors.keys) {
                  var stubName = _namer.invocationName(selector);
                  if (stubNames.add(stubName.key)) {
                    interceptorClass.callStubs.add(_buildStubMethod(stubName,
                        js.js('function(obj) { return obj.# }', [jsName]),
                        element: member));
                  }
                }
              }
            }

            if (member.isSetter || (member.isField && !member.isConst)) {
              var selectors =
                  _worldBuilder.setterInvocationsByName(member.name);
              if (selectors != null && !selectors.isEmpty) {
                var stubName = _namer.setterForElement(member);
                if (stubNames.add(stubName.key)) {
                  interceptorClass.callStubs.add(_buildStubMethod(stubName,
                      js.js('function(obj, v) { return obj.# = v }', [jsName]),
                      element: member));
                }
              }
            }

            // Generating stubs for direct calls and stubs for call-through
            // of getters that happen to be functions.
            bool isFunctionLike = false;
            ResolutionFunctionType functionType = null;

            if (member.isFunction) {
              FunctionElement fn = member;
              functionType = fn.type;
            } else if (member.isGetter) {
              if (_options.trustTypeAnnotations) {
                GetterElement getter = member;
                ResolutionDartType returnType = getter.type.returnType;
                if (returnType.isFunctionType) {
                  functionType = returnType;
                } else if (returnType.treatAsDynamic ||
                    _types.isSubtype(
                        returnType,
                        // ignore: UNNECESSARY_CAST
                        _commonElements.functionType as DartType)) {
                  if (returnType.isTypedef) {
                    ResolutionTypedefType typedef = returnType;
                    // TODO(jacobr): can we just use typdef.unaliased instead?
                    functionType = typedef.element.functionSignature.type;
                  } else {
                    // Other misc function type such as commonElements.Function.
                    // Allow any number of arguments.
                    isFunctionLike = true;
                  }
                }
              } else {
                isFunctionLike = true;
              }
            } // TODO(jacobr): handle field elements.

            if (isFunctionLike || functionType != null) {
              int minArgs;
              int maxArgs;
              if (functionType != null) {
                minArgs = functionType.parameterTypes.length;
                maxArgs = minArgs + functionType.optionalParameterTypes.length;
              } else {
                minArgs = 0;
                maxArgs = 32767;
              }
              var selectors = _worldBuilder.invocationsByName(member.name);
              // Named arguments are not yet supported. In the future we
              // may want to map named arguments to an object literal containing
              // all named arguments.
              if (selectors != null && !selectors.isEmpty) {
                for (var selector in selectors.keys) {
                  // Check whether the arity matches this member.
                  var argumentCount = selector.argumentCount;
                  // JS interop does not support named arguments.
                  if (selector.namedArgumentCount > 0) continue;
                  if (argumentCount < minArgs) continue;
                  if (argumentCount > maxArgs) continue;
                  var stubName = _namer.invocationName(selector);
                  if (!stubNames.add(stubName.key)) continue;
                  var parameters =
                      new List<String>.generate(argumentCount, (i) => 'p$i');

                  // We intentionally generate the same stub method for direct
                  // calls and call-throughs of getters so that calling a
                  // getter that returns a function behaves the same as calling
                  // a method. This is helpful as many typed JavaScript APIs
                  // specify member functions with getters that return
                  // functions. The behavior of this solution matches JavaScript
                  // behavior implicitly binding this only when JavaScript
                  // would.
                  interceptorClass.callStubs.add(_buildStubMethod(
                      stubName,
                      js.js('function(receiver, #) { return receiver.#(#) }',
                          [parameters, jsName, parameters]),
                      element: member));
                }
              }
            }
          });
        }
      }
    });
  }

  // Note that a library-element may have multiple [Library]s, if it is split
  // into multiple output units.
  Library _buildLibrary(LibraryElement library, List<ClassEntity> classElements,
      List<MemberEntity> memberElements) {
    String uri = library.canonicalUri.toString();

    List<StaticMethod> statics = memberElements
        .where((e) => e is MethodElement)
        .map(_buildStaticMethod)
        .toList();

    if (library == _commonElements.interceptorsLibrary) {
      statics.addAll(_generateGetInterceptorMethods());
      statics.addAll(_generateOneShotInterceptors());
    }

    List<Class> classes = classElements
        .map((ClassElement classElement) => _classes[classElement])
        .where((Class cls) =>
            !cls.isNative || !_unneededNativeClasses.contains(cls))
        .toList(growable: false);

    bool visitStatics = true;
    List<Field> staticFieldsForReflection =
        _buildFields(library, visitStatics: visitStatics);

    return new Library(
        library, uri, statics, classes, staticFieldsForReflection);
  }

  bool _isSoftDeferred(ClassElement element) {
    return _notSoftDeferred != null && !_notSoftDeferred.contains(element);
  }

  Class _buildClass(ClassElement element) {
    bool onlyForRti = collector.classesOnlyNeededForRti.contains(element);
    bool hasRtiField = _rtiNeed.classNeedsRtiField(element);
    if (_nativeData.isJsInteropClass(element)) {
      // TODO(jacobr): check whether the class has any active static fields
      // if it does not we can suppress it completely.
      onlyForRti = true;
    }
    bool isClosureBaseClass = element == _commonElements.closureClass;

    List<Method> methods = [];
    List<StubMethod> callStubs = <StubMethod>[];

    ClassStubGenerator classStubGenerator = new ClassStubGenerator(
        _task.emitter, _commonElements, _namer, _worldBuilder, _closedWorld,
        enableMinification: _options.enableMinification);
    RuntimeTypeGenerator runtimeTypeGenerator = new RuntimeTypeGenerator(
        _commonElements,
        _closureToClassMapper,
        _task,
        _namer,
        _nativeData,
        _rtiChecks,
        _rtiEncoder,
        _rtiNeed,
        _rtiSubstitutions,
        _jsInteropAnalysis);

    void visitMember(ClassElement enclosing, MemberElement member) {
      assert(member.isDeclaration, failedAt(element));
      assert(element == enclosing, failedAt(element));

      if (Elements.isNonAbstractInstanceMember(member)) {
        // TODO(herhut): Remove once _buildMethod can no longer return null.
        Method method = _buildMethod(member);
        if (method != null) methods.add(method);
      }
      if (member.isGetter || member.isField) {
        Map<Selector, SelectorConstraints> selectors =
            _worldBuilder.invocationsByName(member.name);
        if (selectors != null && !selectors.isEmpty) {
          Map<js.Name, js.Expression> callStubsForMember =
              classStubGenerator.generateCallStubsForGetter(member, selectors);
          callStubsForMember.forEach((js.Name name, js.Expression code) {
            callStubs.add(_buildStubMethod(name, code, element: member));
          });
        }
      }
    }

    List<StubMethod> noSuchMethodStubs = <StubMethod>[];

    if (_backendUsage.isNoSuchMethodUsed && element.isObject) {
      Map<js.Name, Selector> selectors =
          classStubGenerator.computeSelectorsForNsmHandlers();
      selectors.forEach((js.Name name, Selector selector) {
        // If the program contains `const Symbol` names we have to retain them.
        String selectorName = selector.name;
        if (selector.isSetter) selectorName = "$selectorName=";
        if (_mirrorsData.symbolsUsed.contains(selectorName)) {
          _symbolsMap[name] = selectorName;
        }
        noSuchMethodStubs.add(
            classStubGenerator.generateStubForNoSuchMethod(name, selector));
      });
    }

    if (isClosureBaseClass) {
      // We add a special getter to allow for tearing off a closure from itself.
      js.Name name = _namer.getterForMember(Names.call);
      js.Fun function = js.js('function() { return this; }');
      callStubs.add(_buildStubMethod(name, function));
    }

    ClassElement implementation = element.implementation;

    // MixinApplications run through the members of their mixin. Here, we are
    // only interested in direct members.
    if (!onlyForRti && !element.isMixinApplication) {
      implementation.forEachMember(visitMember, includeBackendMembers: true);
    }
    bool isInterceptedClass = _interceptorData.isInterceptedClass(element);
    List<Field> instanceFields = onlyForRti
        ? const <Field>[]
        : _buildFields(element,
            visitStatics: false, isHolderInterceptedClass: isInterceptedClass);
    List<Field> staticFieldsForReflection = onlyForRti
        ? const <Field>[]
        : _buildFields(element,
            visitStatics: true, isHolderInterceptedClass: isInterceptedClass);

    TypeTestProperties typeTests = runtimeTypeGenerator.generateIsTests(element,
        storeFunctionTypeInMetadata: _storeFunctionTypesInMetadata);

    List<StubMethod> checkedSetters = <StubMethod>[];
    List<StubMethod> isChecks = <StubMethod>[];
    if (_nativeData.isJsInteropClass(element)) {
      typeTests.properties.forEach((js.Name name, js.Node code) {
        _classes[_commonElements.jsInterceptorClass]
            .isChecks
            .add(_buildStubMethod(name, code));
      });
    } else {
      for (Field field in instanceFields) {
        if (field.needsCheckedSetter) {
          assert(!field.needsUncheckedSetter);
          FieldElement element = field.element;
          js.Expression code = _generatedCode[element];
          assert(code != null);
          js.Name name = _namer.deriveSetterName(field.accessorName);
          checkedSetters.add(_buildStubMethod(name, code, element: element));
        }
      }

      typeTests.properties.forEach((js.Name name, js.Node code) {
        isChecks.add(_buildStubMethod(name, code));
      });
    }

    js.Name name = _namer.className(element);
    String holderName = _namer.globalObjectFor(element);
    // TODO(floitsch): we shouldn't update the registry in the middle of
    // building a class.
    Holder holder = _registry.registerHolder(holderName);
    bool isInstantiated = !_nativeData.isJsInteropClass(element) &&
        _worldBuilder.directlyInstantiatedClasses.contains(element);

    Class result;
    if (element.isMixinApplication && !onlyForRti) {
      assert(!_nativeData.isNativeClass(element));
      assert(methods.isEmpty);
      assert(!isClosureBaseClass);

      result = new MixinApplication(
          element,
          name,
          holder,
          instanceFields,
          staticFieldsForReflection,
          callStubs,
          checkedSetters,
          isChecks,
          typeTests.functionTypeIndex,
          isDirectlyInstantiated: isInstantiated,
          hasRtiField: hasRtiField,
          onlyForRti: onlyForRti);
    } else {
      result = new Class(
          element,
          name,
          holder,
          methods,
          instanceFields,
          staticFieldsForReflection,
          callStubs,
          noSuchMethodStubs,
          checkedSetters,
          isChecks,
          typeTests.functionTypeIndex,
          isDirectlyInstantiated: isInstantiated,
          hasRtiField: hasRtiField,
          onlyForRti: onlyForRti,
          isNative: _nativeData.isNativeClass(element),
          isClosureBaseClass: isClosureBaseClass,
          isSoftDeferred: _isSoftDeferred(element));
    }
    _classes[element] = result;
    return result;
  }

  bool _methodNeedsStubs(FunctionElement method) {
    return !method.functionSignature.optionalParameters.isEmpty;
  }

  bool _methodCanBeReflected(MethodElement method) {
    return _mirrorsData.isMemberAccessibleByReflection(method);
  }

  bool _methodCanBeApplied(FunctionElement method) {
    return _backendUsage.isFunctionApplyUsed &&
        _closedWorld.getMightBePassedToApply(method);
  }

  /* Map | List */ _computeParameterDefaultValues(FunctionSignature signature) {
    var /* Map | List */ optionalParameterDefaultValues;
    if (signature.optionalParametersAreNamed) {
      optionalParameterDefaultValues = new Map<String, ConstantValue>();
      signature.forEachOptionalParameter((ParameterElement parameter) {
        ConstantValue def =
            _constantHandler.getConstantValue(parameter.constant);
        optionalParameterDefaultValues[parameter.name] = def;
      });
    } else {
      optionalParameterDefaultValues = <ConstantValue>[];
      signature.forEachOptionalParameter((ParameterElement parameter) {
        ConstantValue def =
            _constantHandler.getConstantValue(parameter.constant);
        optionalParameterDefaultValues.add(def);
      });
    }
    return optionalParameterDefaultValues;
  }

  DartMethod _buildMethod(MethodElement element) {
    assert(element.isDeclaration);
    js.Name name = _namer.methodPropertyName(element);
    js.Expression code = _generatedCode[element];

    // TODO(kasperl): Figure out under which conditions code is null.
    if (code == null) return null;

    bool canTearOff = false;
    js.Name tearOffName;
    bool isClosureCallMethod = false;
    bool isNotApplyTarget = !element.isFunction || element.isAccessor;

    bool canBeReflected = _methodCanBeReflected(element);
    bool canBeApplied = _methodCanBeApplied(element);

    js.Name aliasName = _superMemberData.isAliasedSuperMember(element)
        ? _namer.aliasedSuperMemberPropertyName(element)
        : null;

    if (isNotApplyTarget) {
      canTearOff = false;
    } else {
      if (element.enclosingClass.isClosure) {
        canTearOff = false;
        isClosureCallMethod = true;
      } else {
        // Careful with operators.
        canTearOff = _worldBuilder.hasInvokedGetter(element, _closedWorld) ||
            (canBeReflected && !element.isOperator);
        assert(canTearOff ||
            !_worldBuilder.methodsNeedingSuperGetter.contains(element));
        tearOffName = _namer.getterForElement(element);
      }
    }

    if (canTearOff) {
      assert(!element.isGenerativeConstructor, failedAt(element));
      assert(!element.isGenerativeConstructorBody, failedAt(element));
      assert(!element.isConstructor, failedAt(element));
    }

    js.Name callName = null;
    if (canTearOff) {
      Selector callSelector =
          new Selector.fromElement(element).toCallSelector();
      callName = _namer.invocationName(callSelector);
    }

    ResolutionDartType memberType;
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
      OutputUnit outputUnit = _deferredLoadTask.outputUnitForElement(element);
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
        needsTearOff: canTearOff,
        tearOffName: tearOffName,
        isClosureCallMethod: isClosureCallMethod,
        aliasName: aliasName,
        canBeApplied: canBeApplied,
        canBeReflected: canBeReflected,
        requiredParameterCount: requiredParameterCount,
        optionalParameterDefaultValues: optionalParameterDefaultValues,
        functionType: functionType);
  }

  js.Expression _generateFunctionType(
      ResolutionDartType type, OutputUnit outputUnit) {
    if (type.containsTypeVariables) {
      js.Expression thisAccess = js.js(r'this.$receiver');
      return _rtiEncoder.getSignatureEncoding(_task.emitter, type, thisAccess);
    } else {
      return _task.metadataCollector.reifyTypeForOutputUnit(type, outputUnit);
    }
  }

  List<ParameterStubMethod> _generateParameterStubs(
      MethodElement element, bool canTearOff) {
    if (!_methodNeedsStubs(element)) return const <ParameterStubMethod>[];

    ParameterStubGenerator generator = new ParameterStubGenerator(
        _commonElements,
        _task,
        _constantHandler,
        _namer,
        _nativeData,
        _interceptorData,
        _worldBuilder,
        _closedWorld);
    return generator.generateParameterStubs(element, canTearOff: canTearOff);
  }

  /// Builds a stub method.
  ///
  /// Stub methods may have an element that can be used for code-size
  /// attribution.
  Method _buildStubMethod(js.Name name, js.Expression code,
      {MemberElement element}) {
    return new StubMethod(name, code, element: element);
  }

  // The getInterceptor methods directly access the prototype of classes.
  // We must evaluate these classes eagerly so that the prototype is
  // accessible.
  void _markEagerInterceptorClasses() {
    Iterable<js.Name> names =
        _oneShotInterceptorData.specializedGetInterceptorNames;
    for (js.Name name in names) {
      for (ClassElement element
          in _oneShotInterceptorData.getSpecializedGetInterceptorsFor(name)) {
        Class cls = _classes[element];
        if (cls != null) cls.isEager = true;
      }
    }
  }

  Iterable<StaticStubMethod> _generateGetInterceptorMethods() {
    InterceptorStubGenerator stubGenerator = new InterceptorStubGenerator(
        _options,
        _commonElements,
        _task,
        _nativeCodegenEnqueuer,
        _constantHandler,
        _namer,
        _oneShotInterceptorData,
        _customElementsCodegenAnalysis,
        _worldBuilder,
        _closedWorld);

    String holderName =
        _namer.globalObjectForLibrary(_commonElements.interceptorsLibrary);
    // TODO(floitsch): we shouldn't update the registry in the middle of
    // generating the interceptor methods.
    Holder holder = _registry.registerHolder(holderName);

    Iterable<js.Name> names =
        _oneShotInterceptorData.specializedGetInterceptorNames;
    return names.map((js.Name name) {
      Set<ClassEntity> classes =
          _oneShotInterceptorData.getSpecializedGetInterceptorsFor(name);
      js.Expression code = stubGenerator.generateGetInterceptorMethod(classes);
      return new StaticStubMethod(name, holder, code);
    });
  }

  List<Field> _buildFields(Element holder,
      {bool visitStatics, bool isHolderInterceptedClass: false}) {
    List<Field> fields = <Field>[];
    new FieldVisitor(_options, _worldBuilder, _nativeData, _mirrorsData, _namer,
            _closedWorld)
        .visitFields(holder, visitStatics, (FieldElement field,
            js.Name name,
            js.Name accessorName,
            bool needsGetter,
            bool needsSetter,
            bool needsCheckedSetter) {
      assert(field.isDeclaration, failedAt(field));

      int getterFlags = 0;
      if (needsGetter) {
        if (visitStatics ||
            !_interceptorData.fieldHasInterceptedGetter(field)) {
          getterFlags = 1;
        } else {
          getterFlags += 2;
          // TODO(sra): 'isInterceptedClass' might not be the correct test
          // for methods forced to use the interceptor convention because
          // the method's class was elsewhere mixed-in to an interceptor.
          if (!isHolderInterceptedClass) {
            getterFlags += 1;
          }
        }
      }

      int setterFlags = 0;
      if (needsSetter) {
        if (visitStatics ||
            !_interceptorData.fieldHasInterceptedSetter(field)) {
          setterFlags = 1;
        } else {
          setterFlags += 2;
          if (!isHolderInterceptedClass) {
            setterFlags += 1;
          }
        }
      }

      fields.add(new Field(field, name, accessorName, getterFlags, setterFlags,
          needsCheckedSetter));
    });

    return fields;
  }

  Iterable<StaticStubMethod> _generateOneShotInterceptors() {
    InterceptorStubGenerator stubGenerator = new InterceptorStubGenerator(
        _options,
        _commonElements,
        _task,
        _nativeCodegenEnqueuer,
        _constantHandler,
        _namer,
        _oneShotInterceptorData,
        _customElementsCodegenAnalysis,
        _worldBuilder,
        _closedWorld);

    String holderName =
        _namer.globalObjectForLibrary(_commonElements.interceptorsLibrary);
    // TODO(floitsch): we shouldn't update the registry in the middle of
    // generating the interceptor methods.
    Holder holder = _registry.registerHolder(holderName);

    List<js.Name> names = _oneShotInterceptorData.oneShotInterceptorNames;
    return names.map((js.Name name) {
      js.Expression code = stubGenerator.generateOneShotInterceptor(name);
      return new StaticStubMethod(name, holder, code);
    });
  }

  StaticDartMethod _buildStaticMethod(MethodElement element) {
    js.Name name = _namer.methodPropertyName(element);
    String holder = _namer.globalObjectFor(element);
    js.Expression code = _generatedCode[element];

    bool isApplyTarget = !element.isConstructor && !element.isAccessor;
    bool canBeApplied = _methodCanBeApplied(element);
    bool canBeReflected = _methodCanBeReflected(element);

    bool needsTearOff = isApplyTarget &&
        (canBeReflected ||
            _worldBuilder.staticFunctionsNeedingGetter.contains(element));

    js.Name tearOffName =
        needsTearOff ? _namer.staticClosureName(element) : null;

    js.Name callName = null;
    if (needsTearOff) {
      Selector callSelector =
          new Selector.fromElement(element).toCallSelector();
      callName = _namer.invocationName(callSelector);
    }
    js.Expression functionType;
    ResolutionDartType type = element.type;
    if (needsTearOff || canBeReflected) {
      OutputUnit outputUnit = _deferredLoadTask.outputUnitForElement(element);
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
    return new StaticDartMethod(element, name, _registry.registerHolder(holder),
        code, _generateParameterStubs(element, needsTearOff), callName,
        needsTearOff: needsTearOff,
        tearOffName: tearOffName,
        canBeApplied: canBeApplied,
        canBeReflected: canBeReflected,
        requiredParameterCount: requiredParameterCount,
        optionalParameterDefaultValues: optionalParameterDefaultValues,
        functionType: functionType);
  }

  void _registerConstants(
      OutputUnit outputUnit, Iterable<ConstantValue> constantValues) {
    // `constantValues` is null if an outputUnit doesn't contain any constants.
    if (constantValues == null) return;
    for (ConstantValue constantValue in constantValues) {
      _registry.registerConstant(outputUnit, constantValue);
      assert(!_constants.containsKey(constantValue));
      js.Name name = _namer.constantName(constantValue);
      String constantObject = _namer.globalObjectForConstant(constantValue);
      Holder holder =
          _registry.registerHolder(constantObject, isConstantsHolder: true);
      Constant constant = new Constant(name, holder, constantValue);
      _constants[constantValue] = constant;
    }
  }

  Holder _registerStaticStateHolder() {
    return _registry.registerHolder(_namer.staticStateHolder,
        isStaticStateHolder: true);
  }
}
