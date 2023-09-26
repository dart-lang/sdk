// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.program_builder;

import '../../common.dart';
import '../../common/elements.dart' show JCommonElements, JElementEnvironment;
import '../../common/names.dart' show Names, Selectors;
import '../../constants/values.dart';
import '../../deferred_load/output_unit.dart'
    show deferredPartFileName, OutputUnit, OutputUnitData;
import '../../elements/entities.dart';
import '../../elements/types.dart';
import '../../io/source_information.dart';
import '../../js/js.dart' as js;
import '../../js_backend/field_analysis.dart'
    show FieldAnalysisData, JFieldAnalysis;
import '../../js_backend/backend_usage.dart';
import '../../js_backend/custom_elements_analysis.dart';
import '../../js_backend/inferred_data.dart';
import '../../js_backend/interceptor_data.dart';
import '../../js_backend/namer.dart' show Namer;
import '../../js_backend/namer.dart' show StringBackedName, compareNames;
import '../../js_backend/native_data.dart';
import '../../js_backend/records_codegen.dart' show RecordsCodegen;
import '../../js_backend/runtime_types.dart' show RuntimeTypesChecks;
import '../../js_backend/runtime_types_codegen.dart' show TypeCheck;
import '../../js_backend/runtime_types_new.dart'
    show RecipeEncoder, RecipeEncoding;
import '../../js_backend/runtime_types_new.dart' as newRti;
import '../../js_backend/runtime_types_resolution.dart' show RuntimeTypesNeed;
import '../../js_model/elements.dart'
    show JField, JGeneratorBody, JSignatureMethod;
import '../../js_model/js_world.dart';
import '../../js_model/records.dart' show RecordData, RecordRepresentation;
import '../../js_model/type_recipe.dart'
    show FullTypeEnvironmentStructure, TypeExpressionRecipe;
import '../../native/enqueue.dart' show NativeCodegenEnqueuer;
import '../../options.dart';
import '../../universe/class_hierarchy.dart';
import '../../universe/codegen_world_builder.dart';
import '../../universe/selector.dart' show Selector;
import '../../universe/world_builder.dart' show SelectorConstraints;
import '../class_stub_generator.dart' show ClassStubGenerator;
import '../instantiation_stub_generator.dart' show InstantiationStubGenerator;
import '../interceptor_stub_generator.dart' show InterceptorStubGenerator;
import '../main_call_stub_generator.dart' show MainCallStubGenerator;
import '../parameter_stub_generator.dart' show ParameterStubGenerator;
import '../runtime_type_generator.dart'
    show RuntimeTypeGenerator, TypeTestProperties;
import '../js_emitter.dart' show CodeEmitterTask, Emitter;
import '../model.dart';
import '../sorter.dart';

part 'collector.dart';
part 'field_visitor.dart';
part 'registry.dart';

/// Builds a self-contained representation of the program that can then be
/// emitted more easily by the individual emitters.
class ProgramBuilder {
  final CompilerOptions _options;
  final JElementEnvironment _elementEnvironment;
  final JCommonElements _commonElements;
  final OutputUnitData _outputUnitData;
  final CodegenWorld _codegenWorld;
  final NativeCodegenEnqueuer _nativeCodegenEnqueuer;
  final BackendUsage _backendUsage;
  final NativeData _nativeData;
  final RuntimeTypesNeed _rtiNeed;
  final InterceptorData _interceptorData;
  final RuntimeTypesChecks _rtiChecks;
  final RecipeEncoder _rtiRecipeEncoder;
  final OneShotInterceptorData _oneShotInterceptorData;
  final CustomElementsCodegenAnalysis _customElementsCodegenAnalysis;
  final RecordsCodegen _recordsCodegen;
  final Map<MemberEntity, js.Expression> _generatedCode;
  final Namer _namer;
  final CodeEmitterTask _task;
  final JClosedWorld _closedWorld;
  final JFieldAnalysis _fieldAnalysis;
  final RecordData _recordData;
  final InferredData _inferredData;
  final SourceInformationStrategy _sourceInformationStrategy;

  /// The [Sorter] used for ordering elements in the generated JavaScript.
  final Sorter _sorter;

  /// Contains the collected information the program builder used to build
  /// the model.
  // The collector will be filled on the first call to `buildProgram`.
  // It is publicly exposed for backwards compatibility. New code
  // (and in particular new emitters) should not access it outside this class.
  final Collector collector;

  final Registry _registry;

  final FunctionEntity _mainFunction;
  final Iterable<ClassEntity> _rtiNeededClasses;

  /// True if the program should store function types in the metadata.
  bool _storeFunctionTypesInMetadata = false;

  final Set<TypeVariableType> _lateNamedTypeVariablesNewRti = {};

  ClassHierarchy get _classHierarchy => _closedWorld.classHierarchy;
  DartTypes get _dartTypes => _closedWorld.dartTypes;

  ProgramBuilder(
      this._options,
      this._elementEnvironment,
      this._commonElements,
      this._outputUnitData,
      this._codegenWorld,
      this._nativeCodegenEnqueuer,
      this._backendUsage,
      this._nativeData,
      this._rtiNeed,
      this._interceptorData,
      this._rtiChecks,
      this._rtiRecipeEncoder,
      this._oneShotInterceptorData,
      this._customElementsCodegenAnalysis,
      this._recordsCodegen,
      this._generatedCode,
      this._namer,
      this._task,
      this._closedWorld,
      this._fieldAnalysis,
      this._recordData,
      this._inferredData,
      this._sourceInformationStrategy,
      this._sorter,
      this._rtiNeededClasses,
      this._mainFunction)
      : this.collector = Collector(
            _commonElements,
            _elementEnvironment,
            _outputUnitData,
            _codegenWorld,
            _task.emitter,
            _nativeData,
            _interceptorData,
            _oneShotInterceptorData,
            _closedWorld,
            _rtiNeededClasses,
            _generatedCode,
            _sorter),
        this._registry = Registry(_outputUnitData.mainOutputUnit, _sorter);

  /// Mapping from [ClassEntity] to constructed [Class]. We need this to
  /// update the superclass in the [Class].
  final Map<ClassEntity, Class> _classes = {};

  /// Mapping from [ClassEntity] to constructed [ClassTypeData] object. Used to build
  /// libraries.
  final Map<ClassEntity, ClassTypeData> _classTypeData = {};

  /// Mapping from [OutputUnit] to constructed [Fragment]. We need this to
  /// generate the deferredLoadingMap (to know which hunks to load).
  final Map<OutputUnit, Fragment> _outputs = {};

  /// Mapping from [ConstantValue] to constructed [Constant]. We need this to
  /// update field-initializers to point to the ConstantModel.
  final Map<ConstantValue, Constant> _constants = {};

  late final Set<Class> _unneededNativeClasses;

  ClassEntity get _jsInteropInterceptor =>
      _commonElements.jsLegacyJavaScriptObjectClass;
  final List<StubMethod> _jsInteropIsChecks = [];
  final Set<TypeCheck> _jsInteropTypeChecks = {};

  Program buildProgram({bool storeFunctionTypesInMetadata = false}) {
    collector.collect();

    this._storeFunctionTypesInMetadata = storeFunctionTypesInMetadata;
    // Note: In rare cases (mostly tests) output units can be empty. This
    // happens when the deferred code is dead-code eliminated but we still need
    // to check that the library has been loaded.
    _closedWorld.outputUnitData.outputUnits
        .forEach(_registry.registerOutputUnit);
    collector.outputClassLists.forEach(_registry.registerClasses);
    collector.outputClassTypeLists.forEach(_registry.registerClassTypes);
    collector.outputStaticLists.forEach(_registry.registerMembers);
    collector.outputConstantLists.forEach(_registerConstants);
    collector.outputStaticNonFinalFieldLists.forEach(_registry.registerMembers);

    // We need to run the native-preparation before we build the output. The
    // preparation code, in turn needs the classes to be set up.
    // We thus build the classes before building their containers.
    collector.outputClassTypeLists
        .forEach((OutputUnit _, List<ClassEntity> types) {
      types.forEach(_buildClassTypeData);
    });
    collector.outputClassLists
        .forEach((OutputUnit _, List<ClassEntity> classes) {
      classes.forEach(_buildClass);
    });

    // Resolve the superclass references after we've processed all the classes.
    _classes.forEach((ClassEntity cls, Class c) {
      final superclass = _elementEnvironment.getSuperClass(cls);
      if (superclass != null) {
        c.superclass = _classes[superclass];
        assert(
            c.onlyForConstructor || c.superclass != null,
            failedAt(
                cls,
                "No Class for has been created for superclass "
                "${superclass} of $c."));
      }
      if (c.isSimpleMixinApplication || c.isMixinApplicationWithMembers) {
        final effectiveMixinClass =
            _elementEnvironment.getEffectiveMixinClass(cls);
        c.mixinClass = _classes[effectiveMixinClass];
        assert(
            c.mixinClass != null,
            failedAt(
                cls,
                "No class for effective mixin ${effectiveMixinClass} on "
                "$cls."));
      }
    });

    List<Class> nativeClasses = collector.nativeClassesAndSubclasses
        .map((ClassEntity classElement) => _classes[classElement]!)
        .toList();

    Set<ClassEntity> interceptorClassesNeededByConstants =
        collector.computeInterceptorsReferencedFromConstants();

    _unneededNativeClasses = _task.nativeEmitter.prepareNativeClasses(
        nativeClasses, interceptorClassesNeededByConstants, _rtiNeededClasses);

    _addJsInteropStubs(_registry.mainLibrariesMap);

    MainFragment mainFragment = _buildMainFragment(_registry.mainLibrariesMap);
    Iterable<Fragment> deferredFragments =
        _registry.deferredLibrariesMap.map(_buildDeferredFragment);

    List<Fragment> fragments =
        [mainFragment, ...deferredFragments].toList(growable: false);

    _markEagerClasses();

    associateNamedTypeVariablesNewRti();

    bool needsNativeSupport =
        _nativeCodegenEnqueuer.hasInstantiatedNativeClasses ||
            _nativeData.isAllowInteropUsed;

    assert(!needsNativeSupport ||
        nativeClasses.isNotEmpty ||
        _nativeData.isAllowInteropUsed);

    List<js.TokenFinalizer> finalizers = [_task.metadataCollector];
    if (_namer is js.TokenFinalizer) {
      var namingFinalizer = _namer;
      finalizers.add(namingFinalizer as js.TokenFinalizer);
    }

    return Program(fragments, _buildTypeToInterceptorMap(),
        _task.metadataCollector, finalizers,
        needsNativeSupport: needsNativeSupport,
        outputContainsConstantList: collector.outputContainsConstantList);
  }

  void _markEagerClasses() {
    _markEagerInterceptorClasses();
  }

  js.Expression? _buildTypeToInterceptorMap() {
    InterceptorStubGenerator stubGenerator = InterceptorStubGenerator(
        _commonElements,
        _task.emitter,
        _nativeCodegenEnqueuer,
        _namer,
        _customElementsCodegenAnalysis,
        _codegenWorld,
        _closedWorld);
    return stubGenerator.generateTypeToInterceptorMap();
  }

  MainFragment _buildMainFragment(LibrariesMap librariesMap) {
    final outputUnit = librariesMap.outputUnit;
    // Construct the main output from the libraries and the registered holders.
    MainFragment result = MainFragment(
        outputUnit,
        "", // The empty string is the name for the main output file.
        _buildInvokeMain(),
        _buildMainUnitRecordTypeStubs(outputUnit),
        _buildLibraries(librariesMap),
        _buildStaticNonFinalFields(librariesMap),
        _buildStaticLazilyInitializedFields(librariesMap),
        _buildConstants(librariesMap));
    _outputs[outputUnit] = result;
    return result;
  }

  js.Statement _buildInvokeMain() {
    return MainCallStubGenerator.generateInvokeMain(
        _commonElements,
        _task.emitter,
        _mainFunction,
        _backendUsage.requiresStartupMetrics,
        _options);
  }

  js.Expression? _buildMainUnitRecordTypeStubs(OutputUnit mainOutputUnit) {
    return _recordsCodegen.generateTestTableForOutputUnit(
        mainOutputUnit, _outputUnitData, _namer);
  }

  DeferredFragment _buildDeferredFragment(LibrariesMap librariesMap) {
    final outputUnit = librariesMap.outputUnit;
    final name = librariesMap.name;
    DeferredFragment result = DeferredFragment(
        outputUnit,
        deferredPartFileName(_options, name, addExtension: false),
        name,
        _buildLibraries(librariesMap),
        _buildStaticNonFinalFields(librariesMap),
        _buildStaticLazilyInitializedFields(librariesMap),
        _buildConstants(librariesMap));
    _outputs[outputUnit] = result;
    return result;
  }

  List<Constant> _buildConstants(LibrariesMap librariesMap) {
    final constantValues =
        collector.outputConstantLists[librariesMap.outputUnit];
    if (constantValues == null) return const [];
    return constantValues
        .map((ConstantValue value) => _constants[value]!)
        .toList(growable: false);
  }

  List<StaticField> _buildStaticNonFinalFields(LibrariesMap librariesMap) {
    final staticNonFinalFields =
        collector.outputStaticNonFinalFieldLists[librariesMap.outputUnit];
    if (staticNonFinalFields == null) return const [];

    return staticNonFinalFields.map(_buildStaticField).toList(growable: false);
  }

  StaticField _buildStaticField(FieldEntity element) {
    FieldAnalysisData fieldData =
        _fieldAnalysis.getFieldData(element as JField);
    final initialValue = fieldData.initialValue;
    late js.Expression code;
    if (initialValue != null) {
      code = _task.emitter.constantReference(initialValue);
    } else {
      assert(fieldData.isEager);
      code = _generatedCode[element]!;
    }
    js.Name name = _namer.globalPropertyNameForMember(element);

    // TODO(floitsch): we shouldn't update the registry in the middle of
    // building a static field. (Note that the static-state holder was
    // already registered earlier, and that we just call the register to get
    // the holder-instance.
    return StaticField(element, name, null, code,
        isFinal: false,
        isLazy: false,
        isInitializedByConstant: initialValue != null,
        usesNonNullableInitialization: element.library.isNonNullableByDefault);
  }

  List<StaticField> _buildStaticLazilyInitializedFields(
      LibrariesMap librariesMap) {
    final lazyFields =
        collector.outputLazyStaticFieldLists[librariesMap.outputUnit];
    if (lazyFields == null) return const [];
    return lazyFields
        .map(_buildLazyField)
        .whereType<StaticField>() // Happens when the field was unused.
        .toList(growable: false);
  }

  StaticField? _buildLazyField(FieldEntity element) {
    final code = _generatedCode[element];
    // The code is null if we ended up not needing the lazily
    // initialized field after all because of constant folding
    // before code generation.
    if (code == null) return null;

    js.Name name = _namer.globalPropertyNameForMember(element);
    js.Name getterName = _namer.lazyInitializerName(element);
    // TODO(floitsch): we shouldn't update the registry in the middle of
    // building a static field. (Note that the static-state holder was
    // already registered earlier, and that we just call the register to get
    // the holder-instance.
    return StaticField(element, name, getterName, code,
        isFinal: !element.isAssignable,
        isLazy: true,
        usesNonNullableInitialization: element.library.isNonNullableByDefault);
  }

  List<Library> _buildLibraries(LibrariesMap librariesMap) {
    return librariesMap.entries.map((entry) {
      final contents = entry.value;
      return _buildLibrary(
          entry.key, contents.classes, contents.members, contents.classTypes);
    }).toList(growable: false);
  }

  void _addJsInteropStubs(LibrariesMap librariesMap) {
    if (_classes.containsKey(_commonElements.objectClass)) {
      js.Name toStringInvocation = _namer.invocationName(Selectors.toString_);
      // TODO(jacobr): register toString as used so that it is always accessible
      // from JavaScript.
      _classes[_commonElements.objectClass]!.callStubs.add(_buildStubMethod(
          StringBackedName("toString"),
          js.js('function() { return this.#(this) }', toStringInvocation)));
    }

    // We add all members from classes marked with isJsInterop to the base
    // Interceptor class with implementations that directly call the
    // corresponding JavaScript member. We do not attempt to bind this when
    // tearing off JavaScript methods as we cannot distinguish between calling
    // a regular getter that returns a JavaScript function and tearing off
    // a method in the case where there exist multiple JavaScript classes
    // that conflict on whether the member is a getter or a method.
    final interceptorClass = _classes[_jsInteropInterceptor];
    final interceptorTypeData = _classTypeData[_jsInteropInterceptor];

    interceptorClass?.isChecks.addAll(_jsInteropIsChecks);
    interceptorTypeData?.classChecks.addAll(_jsInteropTypeChecks);

    Set<String> stubNames = {};
    librariesMap.forEach((LibraryEntity library,
        List<ClassEntity> classElements, _memberElement, _typeElement) {
      for (ClassEntity cls in classElements) {
        if (_nativeData.isJsInteropClass(cls)) {
          _elementEnvironment.forEachLocalClassMember(cls,
              (MemberEntity member) {
            String jsName =
                _nativeData.computeUnescapedJSInteropName(member.name!);
            if (!member.isInstanceMember) return;
            if (member.isGetter || member is FieldEntity || member.isFunction) {
              final selectors =
                  _codegenWorld.getterInvocationsByName(member.name!);
              if (selectors != null && !selectors.isEmpty) {
                for (Selector selector in selectors) {
                  js.Name stubName = _namer.invocationName(selector);
                  if (stubNames.add(stubName.key)) {
                    interceptorClass!.callStubs.add(_buildStubMethod(stubName,
                        js.js('function(obj) { return obj.# }', [jsName]),
                        element: member));
                  }
                }
              }
            }

            if (member.isSetter || (member is FieldEntity && !member.isConst)) {
              final selectors =
                  _codegenWorld.setterInvocationsByName(member.name!);
              if (selectors != null && !selectors.isEmpty) {
                var stubName = _namer.setterForMember(member);
                if (stubNames.add(stubName.key)) {
                  interceptorClass!.callStubs.add(_buildStubMethod(stubName,
                      js.js('function(obj, v) { return obj.# = v }', [jsName]),
                      element: member));
                }
              }
            }

            // Generating stubs for direct calls and stubs for call-through
            // of getters that happen to be functions.
            bool isFunctionLike = false;
            FunctionType? functionType = null;

            if (member.isFunction) {
              final fn = member as FunctionEntity;
              functionType = _elementEnvironment.getFunctionType(fn);
            } else if (member.isGetter) {
              isFunctionLike = true;
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
              var selectors = _codegenWorld.invocationsByName(member.name!);
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
                      List<String>.generate(argumentCount, (i) => 'p$i');

                  // We intentionally generate the same stub method for direct
                  // calls and call-throughs of getters so that calling a
                  // getter that returns a function behaves the same as calling
                  // a method. This is helpful as many typed JavaScript APIs
                  // specify member functions with getters that return
                  // functions. The behavior of this solution matches JavaScript
                  // behavior implicitly binding this only when JavaScript
                  // would.
                  interceptorClass!.callStubs.add(_buildStubMethod(
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
  Library _buildLibrary(LibraryEntity library, List<ClassEntity> classElements,
      List<MemberEntity> memberElements, List<ClassEntity> classTypeElements) {
    String uri = library.canonicalUri.toString();

    List<StaticMethod> statics = memberElements
        .where((e) => e is! FieldEntity)
        .cast<FunctionEntity>()
        .map<StaticMethod>(_buildStaticMethod)
        .toList();

    if (library == _commonElements.interceptorsLibrary) {
      statics.addAll(_generateGetInterceptorMethods());
      statics.addAll(_generateOneShotInterceptors());
    }

    List<Class> classes = classElements
        .map((ClassEntity classElement) => _classes[classElement]!)
        .where((Class cls) =>
            !cls.isNative || !_unneededNativeClasses.contains(cls))
        .toList(growable: false);

    List<ClassTypeData> classTypeData = classTypeElements
        .map(
            (ClassEntity classTypeElement) => _classTypeData[classTypeElement]!)
        .toList();
    classTypeData.addAll(classes.map((Class cls) => cls.typeData).toList());

    return Library(library, uri, statics, classes, classTypeData);
  }

  Class _buildClass(ClassEntity cls) {
    ClassTypeData typeData = _buildClassTypeData(cls);

    bool onlyForConstructor =
        collector.classesOnlyNeededForConstructor.contains(cls);
    // TODO(joshualitt): Can we just emit JSInteropClasses as types?
    // TODO(jacobr): check whether the class has any active static fields
    // if it does not we can suppress it completely.
    bool onlyForRti = _nativeData.isJsInteropClass(cls);
    bool hasRtiField = _rtiNeed.classNeedsTypeArguments(cls);
    bool onlyForConstructorOrRti = onlyForConstructor || onlyForRti;

    // Recognize the specialized base classes for closures.
    bool isClosureBaseClass = cls == _commonElements.closureClass;
    int? sharedClosureApplyMetadata;
    if (cls == _commonElements.closureClass) {
      // The root base class has metadata for single-argument closures.
      sharedClosureApplyMetadata = 1;
    } else if (cls == _commonElements.closureClass0Args) {
      sharedClosureApplyMetadata = 0;
    } else if (cls == _commonElements.closureClass2Args) {
      sharedClosureApplyMetadata = 2;
    }

    int? recordShapeTag;
    js.Expression? recordShapeRecipe;
    RecordRepresentation? record = _recordData.representationForClass(cls);
    if (record != null && record.definesShape) {
      recordShapeTag = record.shapeTag;
      recordShapeRecipe =
          _rtiRecipeEncoder.encodeRecordFromBindingRecipe(record.shape);
    }

    List<Method> methods = [];
    List<StubMethod> callStubs = [];

    ClassStubGenerator classStubGenerator = ClassStubGenerator(
        _task.emitter, _commonElements, _namer, _codegenWorld, _closedWorld,
        enableMinification: _options.enableMinification);
    RuntimeTypeGenerator runtimeTypeGenerator = RuntimeTypeGenerator(
        _commonElements, _outputUnitData, _task, _namer, _rtiChecks);

    void visitInstanceMember(MemberEntity member) {
      if (!member.isAbstract && member is! FieldEntity) {
        if (member is! JSignatureMethod) {
          final method = _buildMethod(member as FunctionEntity);
          if (method != null) methods.add(method);
        }
      }
      if (member.isGetter || member is FieldEntity) {
        Map<Selector, SelectorConstraints>? selectors =
            _codegenWorld.invocationsByName(member.name!);
        if (selectors != null && !selectors.isEmpty) {
          Map<js.Name, js.Expression> callStubsForMember =
              classStubGenerator.generateCallStubsForGetter(member, selectors);
          callStubsForMember.forEach((js.Name name, js.Expression code) {
            callStubs.add(_buildStubMethod(name, code, element: member));
          });
        }
      }
    }

    void visitMember(MemberEntity member) {
      if (member.isInstanceMember) {
        visitInstanceMember(member);
      }
    }

    List<StubMethod> noSuchMethodStubs = [];

    if (_backendUsage.isNoSuchMethodUsed &&
        cls == _commonElements.objectClass) {
      Map<js.Name, Selector> selectors =
          classStubGenerator.computeSelectorsForNsmHandlers();
      selectors.forEach((js.Name name, Selector selector) {
        // If the program contains `const Symbol` names we have to retain them.
        String selectorName = selector.name;
        if (selector.isSetter) selectorName = "$selectorName=";
        noSuchMethodStubs.add(
            classStubGenerator.generateStubForNoSuchMethod(name, selector));
      });
    }

    if (isClosureBaseClass) {
      // We add a special getter to allow for tearing off a closure from itself.
      js.Name name = _namer.getterForMember(Names.call);
      final function = js.js('function() { return this; }') as js.Fun;
      callStubs.add(_buildStubMethod(name, function));
    }

    if (_commonElements.isInstantiationClass(cls) && !onlyForConstructorOrRti) {
      callStubs.addAll(_generateInstantiationStubs(cls));
    }

    // MixinApplications run through the members of their mixin. Here, we are
    // only interested in direct members.
    bool isMixinApplicationWithMembers = false;
    if (!onlyForConstructorOrRti) {
      if (_elementEnvironment.isMixinApplicationWithMembers(cls)) {
        List<MemberEntity> members = [];
        void add(MemberEntity member) {
          if (member.enclosingClass == cls) {
            members.add(member);
            isMixinApplicationWithMembers = true;
          }
        }

        _elementEnvironment.forEachLocalClassMember(cls, add);
        _elementEnvironment.forEachInjectedClassMember(cls, add);

        if (members.isNotEmpty) {
          _sorter.sortMembers(members).forEach(visitMember);
        }
      } else if (!_elementEnvironment.isMixinApplication(cls)) {
        List<MemberEntity> members = [];
        _elementEnvironment.forEachLocalClassMember(cls, members.add);
        _elementEnvironment.forEachInjectedClassMember(cls, members.add);
        _elementEnvironment.forEachConstructorBody(cls, (body) {
          if (_codegenWorld.isLateMemberReachable(body)) members.add(body);
        });
        _sorter.sortMembers(members).forEach(visitMember);
      }
    }
    bool isInterceptedClass = _interceptorData.isInterceptedClass(cls);
    List<Field> instanceFields = onlyForConstructorOrRti
        ? const []
        : _buildFields(cls: cls, isHolderInterceptedClass: isInterceptedClass);

    List<StubMethod> gettersSetters = onlyForConstructorOrRti
        ? const []
        : [
            for (Field field in instanceFields)
              if (field.needsGetter)
                classStubGenerator.generateGetter(field) as StubMethod,
            for (Field field in instanceFields)
              if (field.needsUncheckedSetter)
                classStubGenerator.generateSetter(field) as StubMethod,
          ];

    TypeTestProperties typeTests = runtimeTypeGenerator.generateIsTests(
        cls, _generatedCode,
        storeFunctionTypeInMetadata: _storeFunctionTypesInMetadata);

    List<StubMethod> checkedSetters = [];
    List<StubMethod> isChecks = [];
    if (_nativeData.isJsInteropClass(cls)) {
      // TODO(johnniwinther): Instead of generating all stubs for each
      // js-interop class we should generate a stub for each implemented class.
      // Currently we generate duplicates if a class is implemented by multiple
      // js-interop classes.
      typeTests.forEachProperty(_sorter, (js.Name name, js.Node code) {
        _jsInteropIsChecks.add(_buildStubMethod(name, code as js.Expression));
      });

      _jsInteropTypeChecks.addAll(typeData.classChecks.checks);
    } else {
      for (Field field in instanceFields) {
        if (field.needsCheckedSetter) {
          assert(!field.needsUncheckedSetter);
          FieldEntity element = field.element;
          final code = _generatedCode[element] as js.Expression;
          js.Name name = _namer.deriveSetterName(field.accessorName);
          checkedSetters.add(_buildStubMethod(name, code, element: element));
        }
      }

      typeTests.forEachProperty(_sorter, (js.Name name, js.Node code) {
        isChecks.add(_buildStubMethod(name, code as js.Expression));
      });
    }

    js.Name name = _namer.className(cls);
    bool isInstantiated = !_nativeData.isJsInteropClass(cls) &&
        _codegenWorld.directlyInstantiatedClasses.contains(cls);

    Class result;
    if (_elementEnvironment.isMixinApplication(cls) &&
        !onlyForConstructorOrRti &&
        !isMixinApplicationWithMembers) {
      assert(!_nativeData.isNativeClass(cls));
      assert(methods.isEmpty);
      assert(!isClosureBaseClass);
      assert(sharedClosureApplyMetadata == null);
      assert(recordShapeTag == null);
      assert(recordShapeRecipe == null);

      result = MixinApplication(cls, typeData, name, instanceFields, callStubs,
          checkedSetters, gettersSetters, isChecks, typeTests.functionTypeIndex,
          isDirectlyInstantiated: isInstantiated,
          hasRtiField: hasRtiField,
          onlyForRti: onlyForRti,
          onlyForConstructor: onlyForConstructor);
    } else {
      result = Class(
          cls,
          typeData,
          name,
          methods,
          instanceFields,
          callStubs,
          noSuchMethodStubs,
          checkedSetters,
          gettersSetters,
          isChecks,
          typeTests.functionTypeIndex,
          isDirectlyInstantiated: isInstantiated,
          hasRtiField: hasRtiField,
          onlyForRti: onlyForRti,
          onlyForConstructor: onlyForConstructor,
          isNative: _nativeData.isNativeClass(cls),
          isClosureBaseClass: isClosureBaseClass,
          sharedClosureApplyMetadata: sharedClosureApplyMetadata,
          isMixinApplicationWithMembers: isMixinApplicationWithMembers,
          recordShapeTag: recordShapeTag,
          recordShapeRecipe: recordShapeRecipe);
    }
    _classes[cls] = result;
    return result;
  }

  ClassTypeData _buildClassTypeData(ClassEntity cls) =>
      _classTypeData.putIfAbsent(
          cls, () => ClassTypeData(cls, _rtiChecks.requiredChecks[cls]));

  void associateNamedTypeVariablesNewRti() {
    for (TypeVariableType typeVariable in _codegenWorld.namedTypeVariablesNewRti
        .union(_lateNamedTypeVariablesNewRti)) {
      final declaration = typeVariable.element.typeDeclaration as ClassEntity;
      Iterable<ClassEntity> subtypes =
          newRti.mustCheckAllSubtypes(_closedWorld, declaration)
              ? _classHierarchy.subtypesOf(declaration)
              : _classHierarchy.subclassesOf(declaration);
      for (ClassEntity entity in subtypes) {
        ClassTypeData classTypeData = _nativeData.isJsInteropClass(entity)
            ? _buildClassTypeData(_jsInteropInterceptor)
            : _buildClassTypeData(entity);
        classTypeData.namedTypeVariables.add(typeVariable);
      }
    }
  }

  bool _methodNeedsStubs(FunctionEntity method) {
    if (method is JGeneratorBody) return false;
    if (method is ConstructorBodyEntity) return false;
    return method.parameterStructure.optionalParameters != 0 ||
        method.parameterStructure.typeParameters != 0;
  }

  bool _methodCanBeApplied(FunctionEntity method) {
    return _backendUsage.isFunctionApplyUsed &&
        _inferredData.getMightBePassedToApply(method);
  }

  /* Map | List */ _computeParameterDefaultValues(FunctionEntity method) {
    var /* Map | List */ optionalParameterDefaultValues;
    ParameterStructure parameterStructure = method.parameterStructure;
    if (parameterStructure.namedParameters.isNotEmpty) {
      optionalParameterDefaultValues = Map<String, ConstantValue>();
      _elementEnvironment.forEachParameter(method,
          (DartType type, String? name, ConstantValue? defaultValue) {
        if (parameterStructure.namedParameters.contains(name)) {
          assert(defaultValue != null);
          // ignore: avoid_dynamic_calls
          optionalParameterDefaultValues[name] = defaultValue;
        }
      });
    } else {
      optionalParameterDefaultValues = <ConstantValue>[];
      int index = 0;
      _elementEnvironment.forEachParameter(method,
          (DartType type, String? name, ConstantValue? defaultValue) {
        if (index >= parameterStructure.requiredPositionalParameters) {
          // ignore: avoid_dynamic_calls
          optionalParameterDefaultValues.add(defaultValue);
        }
        index++;
      });
    }
    return optionalParameterDefaultValues;
  }

  DartMethod? _buildMethod(FunctionEntity element) {
    js.Name name = _namer.methodPropertyName(element);
    final code = _generatedCode[element];

    // TODO(kasperl): Figure out under which conditions code is null.
    if (code == null) return null;

    bool canTearOff = false;
    bool tearOffNeedsDirectAccess = false;
    js.Name? tearOffName;
    bool isClosureCallMethod = false;
    bool inheritsApplyMetadata = false;
    bool isNotApplyTarget =
        !element.isFunction || element.isGetter || element.isSetter;

    bool canBeApplied = _methodCanBeApplied(element);

    final aliasName = _codegenWorld.isAliasedSuperMember(element)
        ? _namer.aliasedSuperMemberPropertyName(element)
        : null;

    if (isNotApplyTarget) {
      canTearOff = false;
    } else {
      if (element.enclosingClass!.isClosure) {
        canTearOff = false;
        isClosureCallMethod = true;
        final superclass =
            _elementEnvironment.getSuperClass(element.enclosingClass!);
        if (superclass == _commonElements.closureClass &&
                element.parameterStructure == ParameterStructure.oneArgument ||
            superclass == _commonElements.closureClass0Args &&
                element.parameterStructure ==
                    ParameterStructure.zeroArguments ||
            superclass == _commonElements.closureClass2Args &&
                element.parameterStructure == ParameterStructure.twoArguments) {
          inheritsApplyMetadata = true;
        }
      } else {
        // Careful with operators.
        bool needsSuperGetter = _codegenWorld.methodsNeedsSuperGetter(element);
        canTearOff =
            _codegenWorld.hasInvokedGetter(element) || needsSuperGetter;
        tearOffName = _namer.getterForElement(element);
        tearOffNeedsDirectAccess = needsSuperGetter;
      }
    }

    if (canTearOff) {
      assert(element is! ConstructorEntity, failedAt(element));
      assert(element is! ConstructorBodyEntity, failedAt(element));
    }

    bool isIntercepted =
        _closedWorld.interceptorData.isInterceptedMethod(element);

    js.Name? callName;
    if (canTearOff) {
      Selector callSelector = Selector.fromElement(element).toCallSelector();
      callName = _namer.invocationName(callSelector);
    }

    final memberType = _elementEnvironment.getFunctionType(element);
    js.Expression? functionType;
    if (canTearOff) {
      OutputUnit outputUnit = _outputUnitData.outputUnitForMember(element);
      functionType = _generateFunctionType(
          element.enclosingClass!, memberType, outputUnit);
    }

    FunctionEntity method = element;
    ParameterStructure parameterStructure = method.parameterStructure;
    int requiredParameterCount =
        parameterStructure.requiredPositionalParameters;
    var /* List | Map */ optionalParameterDefaultValues;
    int applyIndex = 0;
    if (canBeApplied) {
      optionalParameterDefaultValues = _computeParameterDefaultValues(method);
      if (parameterStructure.typeParameters > 0) {
        applyIndex = 1;
      }
    }

    return InstanceMethod(element, name, code,
        _generateParameterStubs(element, canTearOff, canBeApplied), callName,
        needsTearOff: canTearOff,
        tearOffName: tearOffName,
        tearOffNeedsDirectAccess: tearOffNeedsDirectAccess,
        isClosureCallMethod: isClosureCallMethod,
        inheritsApplyMetadata: inheritsApplyMetadata,
        isIntercepted: isIntercepted,
        aliasName: aliasName,
        canBeApplied: canBeApplied,
        requiredParameterCount: requiredParameterCount,
        optionalParameterDefaultValues: optionalParameterDefaultValues,
        functionType: functionType,
        applyIndex: applyIndex);
  }

  js.Expression _generateFunctionType(ClassEntity? enclosingClass,
          FunctionType type, OutputUnit outputUnit) =>
      _generateFunctionTypeNewRti(enclosingClass, type, outputUnit);

  js.Expression _generateFunctionTypeNewRti(
      ClassEntity? enclosingClass, FunctionType type, OutputUnit outputUnit) {
    InterfaceType? enclosingType;
    if (enclosingClass != null && type.containsTypeVariables) {
      enclosingType = _elementEnvironment.getThisType(enclosingClass);
      if (!_rtiNeed.classNeedsTypeArguments(enclosingClass)) {
        // Erase type arguments.
        List<DartType> typeArguments = enclosingType.typeArguments;
        type = _dartTypes.subst(
            List<DartType>.filled(
                typeArguments.length, _dartTypes.erasedType()),
            typeArguments,
            type) as FunctionType;
      }
    }

    if (type.containsTypeVariables) {
      RecipeEncoding encoding = _rtiRecipeEncoder.encodeRecipe(
          _task.emitter,
          FullTypeEnvironmentStructure(classType: enclosingType),
          TypeExpressionRecipe(type));
      _lateNamedTypeVariablesNewRti.addAll(encoding.typeVariables);
      return encoding.recipe;
    } else {
      return _task.metadataCollector.reifyType(type, outputUnit);
    }
  }

  List<ParameterStubMethod> _generateParameterStubs(
      FunctionEntity element, bool canTearOff, bool canBeApplied) {
    if (!_methodNeedsStubs(element)) return const [];

    ParameterStubGenerator generator = ParameterStubGenerator(
        _task.emitter,
        _task.nativeEmitter,
        _namer,
        _nativeData,
        _interceptorData,
        _codegenWorld,
        _closedWorld,
        _sourceInformationStrategy);
    return generator.generateParameterStubs(element,
        canTearOff: canTearOff, canBeApplied: canBeApplied);
  }

  List<StubMethod> _generateInstantiationStubs(ClassEntity instantiationClass) {
    InstantiationStubGenerator generator = InstantiationStubGenerator(
        _task, _namer, _closedWorld, _codegenWorld, _sourceInformationStrategy);
    return generator.generateStubs(instantiationClass, null);
  }

  /// Builds a stub method.
  ///
  /// Stub methods may have an element that can be used for code-size
  /// attribution.
  StubMethod _buildStubMethod(js.Name name, js.Expression code,
      {MemberEntity? element}) {
    return StubMethod(name, code, element: element);
  }

  // The getInterceptor methods directly access the prototype of classes.
  // We must evaluate these classes eagerly so that the prototype is
  // accessible.
  void _markEagerInterceptorClasses() {
    Iterable<SpecializedGetInterceptor> interceptors =
        _oneShotInterceptorData.specializedGetInterceptors;
    for (SpecializedGetInterceptor interceptor in interceptors) {
      for (ClassEntity element in interceptor.classes) {
        final cls = _classes[element];
        if (cls != null) cls.isEager = true;
      }
    }
  }

  Iterable<StaticStubMethod> _generateGetInterceptorMethods() {
    InterceptorStubGenerator stubGenerator = InterceptorStubGenerator(
        _commonElements,
        _task.emitter,
        _nativeCodegenEnqueuer,
        _namer,
        _customElementsCodegenAnalysis,
        _codegenWorld,
        _closedWorld);

    List<js.Name> names = [];
    Map<js.Name, SpecializedGetInterceptor> interceptorMap = {};
    for (SpecializedGetInterceptor interceptor
        in _oneShotInterceptorData.specializedGetInterceptors) {
      js.Name name = _namer.nameForGetInterceptor(interceptor.classes);
      names.add(name);
      assert(
          !interceptorMap.containsKey(name),
          "Duplicate specialized get interceptor for $name: Existing: "
          "${interceptorMap[name]}, new ${interceptor}.");
      interceptorMap[name] = interceptor;
    }
    names.sort(compareNames);
    return names.map((js.Name name) {
      final interceptor = interceptorMap[name]!;
      js.Expression code =
          stubGenerator.generateGetInterceptorMethod(interceptor);
      return StaticStubMethod(_commonElements.interceptorsLibrary!, name, code);
    });
  }

  List<Field> _buildFields(
      {bool isHolderInterceptedClass = false, required ClassEntity cls}) {
    List<Field> fields = [];

    void visitField(FieldEntity field, bool needsGetter, bool needsSetter,
        bool needsCheckedSetter) {
      int getterFlags = 0;
      if (needsGetter) {
        if (!_interceptorData.fieldHasInterceptedGetter(field)) {
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
        if (!_interceptorData.fieldHasInterceptedSetter(field)) {
          setterFlags = 1;
        } else {
          setterFlags += 2;
          if (!isHolderInterceptedClass) {
            setterFlags += 1;
          }
        }
      }

      FieldAnalysisData fieldData =
          _fieldAnalysis.getFieldData(field as JField);
      ConstantValue? initializerInAllocator;
      if (fieldData.isInitializedInAllocator) {
        initializerInAllocator = fieldData.initialValue;
      }
      ConstantValue? constantValue;
      if (fieldData.isEffectivelyConstant) {
        constantValue = fieldData.constantValue;
      }

      js.Name name = _namer.instanceFieldPropertyName(field);
      js.Name accessorName = _namer.fieldAccessorName(field);

      fields.add(Field(
          field,
          name,
          accessorName,
          getterFlags,
          setterFlags,
          needsCheckedSetter,
          initializerInAllocator,
          constantValue,
          fieldData.isElided));
    }

    FieldVisitor visitor = FieldVisitor(
        _elementEnvironment, _codegenWorld, _nativeData, _closedWorld);
    visitor.visitFields(visitField, cls);

    return fields;
  }

  Iterable<StaticStubMethod> _generateOneShotInterceptors() {
    InterceptorStubGenerator stubGenerator = InterceptorStubGenerator(
        _commonElements,
        _task.emitter,
        _nativeCodegenEnqueuer,
        _namer,
        _customElementsCodegenAnalysis,
        _codegenWorld,
        _closedWorld);

    List<js.Name> names = [];
    Map<js.Name, OneShotInterceptor> interceptorMap = {};
    for (OneShotInterceptor interceptor
        in _oneShotInterceptorData.oneShotInterceptors) {
      js.Name name = _namer.nameForOneShotInterceptor(
          interceptor.selector, interceptor.classes);
      names.add(name);
      assert(
          !interceptorMap.containsKey(name),
          "Duplicate specialized get interceptor for $name: Existing: "
          "${interceptorMap[name]}, new ${interceptor}.");
      interceptorMap[name] = interceptor;
    }
    names.sort(compareNames);
    return names.map((js.Name name) {
      final interceptor = interceptorMap[name]!;
      js.Expression code =
          stubGenerator.generateOneShotInterceptor(interceptor);
      return StaticStubMethod(_commonElements.interceptorsLibrary!, name, code);
    });
  }

  StaticDartMethod _buildStaticMethod(FunctionEntity element) {
    js.Name name = _namer.methodPropertyName(element);
    js.Expression code = _generatedCode[element]!;

    bool isApplyTarget =
        element is! ConstructorEntity && !element.isGetter && !element.isSetter;
    bool canBeApplied = _methodCanBeApplied(element);

    bool needsTearOff =
        isApplyTarget && _codegenWorld.closurizedStatics.contains(element);

    final tearOffName = needsTearOff ? _namer.staticClosureName(element) : null;

    js.Name? callName;
    if (needsTearOff) {
      Selector callSelector = Selector.fromElement(element).toCallSelector();
      callName = _namer.invocationName(callSelector);
    }
    js.Expression? functionType;
    final type = _elementEnvironment.getFunctionType(element);
    if (needsTearOff) {
      OutputUnit outputUnit = _outputUnitData.outputUnitForMember(element);
      functionType = _generateFunctionType(null, type, outputUnit);
    }

    FunctionEntity method = element;
    ParameterStructure parameterStructure = method.parameterStructure;
    int requiredParameterCount =
        parameterStructure.requiredPositionalParameters;
    var /* List | Map */ optionalParameterDefaultValues;
    int applyIndex = 0;
    if (canBeApplied) {
      optionalParameterDefaultValues = _computeParameterDefaultValues(method);
      if (parameterStructure.typeParameters > 0) {
        applyIndex = 1;
      }
    }

    return StaticDartMethod(element, name, code,
        _generateParameterStubs(element, needsTearOff, canBeApplied), callName,
        needsTearOff: needsTearOff,
        tearOffName: tearOffName,
        canBeApplied: canBeApplied,
        requiredParameterCount: requiredParameterCount,
        optionalParameterDefaultValues: optionalParameterDefaultValues,
        functionType: functionType,
        applyIndex: applyIndex);
  }

  void _registerConstants(
      OutputUnit outputUnit, Iterable<ConstantValue>? constantValues) {
    // `constantValues` is null if an outputUnit doesn't contain any constants.
    if (constantValues == null) return;
    for (ConstantValue constantValue in constantValues) {
      _registry.registerConstant(outputUnit, constantValue);
      assert(!_constants.containsKey(constantValue));
      js.Name name = _namer.constantName(constantValue);
      Constant constant = Constant(name, constantValue);
      _constants[constantValue] = constant;
    }
  }
}
