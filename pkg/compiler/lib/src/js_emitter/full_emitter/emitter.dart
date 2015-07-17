// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.full_emitter;

import 'dart:convert';
import 'dart:collection' show HashMap;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;
import 'package:js_runtime/shared/embedded_names.dart' show JsBuiltin;

import '../js_emitter.dart' hide Emitter;
import '../js_emitter.dart' as js_emitter show Emitter;

import '../model.dart';
import '../program_builder/program_builder.dart';

import '../../common.dart';

import '../../constants/values.dart';

import '../../deferred_load.dart' show OutputUnit;

import '../../elements/elements.dart' show
    ConstructorBodyElement,
    ElementKind,
    FieldElement,
    ParameterElement,
    TypeVariableElement,
    MethodElement,
    MemberElement;

import '../../hash/sha1.dart' show Hasher;

import '../../io/code_output.dart';

import '../../io/line_column_provider.dart' show
    LineColumnCollector,
    LineColumnProvider;

import '../../io/source_map_builder.dart' show
    SourceMapBuilder;

import '../../js/js.dart' as jsAst;
import '../../js/js.dart' show js;

import '../../js_backend/js_backend.dart' show
    CheckedModeHelper,
    CompoundName,
    ConstantEmitter,
    CustomElementsAnalysis,
    GetterName,
    JavaScriptBackend,
    JavaScriptConstantCompiler,
    Namer,
    RuntimeTypes,
    SetterName,
    Substitution,
    TypeCheck,
    TypeChecks,
    TypeVariableHandler;

import '../../util/characters.dart' show
    $$,
    $A,
    $HASH,
    $PERIOD,
    $Z,
    $a,
    $z;

import '../../util/uri_extras.dart' show
    relativize;

import '../../util/util.dart' show
    NO_LOCATION_SPANNABLE,
    equalElements;

part 'class_builder.dart';
part 'class_emitter.dart';
part 'code_emitter_helper.dart';
part 'container_builder.dart';
part 'declarations.dart';
part 'deferred_output_unit_hash.dart';
part 'interceptor_emitter.dart';
part 'nsm_emitter.dart';
part 'setup_program_builder.dart';


class Emitter implements js_emitter.Emitter {
  final Compiler compiler;
  final CodeEmitterTask task;

  // The following fields will be set to copies of the program-builder's
  // collector.
  Map<OutputUnit, List<VariableElement>> outputStaticNonFinalFieldLists;
  Map<OutputUnit, Set<LibraryElement>> outputLibraryLists;
  List<TypedefElement> typedefsNeededForReflection;

  final ContainerBuilder containerBuilder = new ContainerBuilder();
  final ClassEmitter classEmitter = new ClassEmitter();
  final NsmEmitter nsmEmitter = new NsmEmitter();
  final InterceptorEmitter interceptorEmitter = new InterceptorEmitter();

  // TODO(johnniwinther): Wrap these fields in a caching strategy.
  final Set<ConstantValue> cachedEmittedConstants;
  final List<jsAst.Statement> cachedEmittedConstantsAst = <jsAst.Statement>[];
  final Map<Element, ClassBuilder> cachedClassBuilders;
  final Set<Element> cachedElements;

  bool needsClassSupport = false;
  bool needsMixinSupport = false;
  bool needsLazyInitializer = false;

  /// True if [ContainerBuilder.addMemberMethodFromInfo] used "structured info",
  /// that is, some function was needed for reflection, had stubs, or had a
  /// super alias.
  bool needsStructuredMemberInfo = false;

  final Namer namer;
  ConstantEmitter constantEmitter;
  NativeEmitter get nativeEmitter => task.nativeEmitter;
  TypeTestRegistry get typeTestRegistry => task.typeTestRegistry;

  // The full code that is written to each hunk part-file.
  Map<OutputUnit, CodeOutput> outputBuffers = new Map<OutputUnit, CodeOutput>();

  String classesCollector;
  final Map<jsAst.Name, String> mangledFieldNames =
      new HashMap<jsAst.Name, String>();
  final Map<jsAst.Name, String> mangledGlobalFieldNames =
      new HashMap<jsAst.Name, String>();
  final Set<jsAst.Name> recordedMangledNames = new Set<jsAst.Name>();

  JavaScriptBackend get backend => compiler.backend;
  TypeVariableHandler get typeVariableHandler => backend.typeVariableHandler;

  String get _ => space;
  String get space => compiler.enableMinification ? "" : " ";
  String get n => compiler.enableMinification ? "" : "\n";
  String get N => compiler.enableMinification ? "\n" : ";\n";

  /**
   * List of expressions and statements that will be included in the
   * precompiled function.
   *
   * To save space, dart2js normally generates constructors and accessors
   * dynamically. This doesn't work in CSP mode, so dart2js emits them directly
   * when in CSP mode.
   */
  Map<OutputUnit, List<jsAst.Node>> _cspPrecompiledFunctions =
      new Map<OutputUnit, List<jsAst.Node>>();

  Map<OutputUnit, List<jsAst.Expression>> _cspPrecompiledConstructorNames =
      new Map<OutputUnit, List<jsAst.Expression>>();

  /**
   * Accumulate properties for classes and libraries, describing their
   * static/top-level members.
   * Later, these members are emitted when the class or library is emitted.
   *
   * See [getElementDescriptor].
   */
  // TODO(ahe): Generate statics with their class, and store only libraries in
  // this map.
  final Map<Fragment, Map<Element, ClassBuilder>> elementDescriptors =
      new Map<Fragment, Map<Element, ClassBuilder>>();

  final bool generateSourceMap;

  Emitter(Compiler compiler, Namer namer, this.generateSourceMap, this.task)
      : this.compiler = compiler,
        this.namer = namer,
        cachedEmittedConstants = compiler.cacheStrategy.newSet(),
        cachedClassBuilders = compiler.cacheStrategy.newMap(),
        cachedElements = compiler.cacheStrategy.newSet() {
    constantEmitter = new ConstantEmitter(
        compiler, namer, this.constantReference, constantListGenerator);
    containerBuilder.emitter = this;
    classEmitter.emitter = this;
    nsmEmitter.emitter = this;
    interceptorEmitter.emitter = this;
  }

  List<jsAst.Node> cspPrecompiledFunctionFor(OutputUnit outputUnit) {
    return _cspPrecompiledFunctions.putIfAbsent(
        outputUnit,
        () => new List<jsAst.Node>());
  }

  List<jsAst.Expression> cspPrecompiledConstructorNamesFor(
      OutputUnit outputUnit) {
    return _cspPrecompiledConstructorNames.putIfAbsent(
        outputUnit,
        () => new List<jsAst.Expression>());
  }

  /// Erases the precompiled information for csp mode for all output units.
  /// Used by the incremental compiler.
  void clearCspPrecompiledNodes() {
    _cspPrecompiledFunctions.clear();
    _cspPrecompiledConstructorNames.clear();
  }

  @override
  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    if (constant.isFunction) return true;    // Already emitted.
    if (constant.isPrimitive) return true;   // Inlined.
    if (constant.isDummy) return true;       // Inlined.
    // The name is null when the constant is already a JS constant.
    // TODO(floitsch): every constant should be registered, so that we can
    // share the ones that take up too much space (like some strings).
    if (namer.constantName(constant) == null) return true;
    return false;
  }

  @override
  int compareConstants(ConstantValue a, ConstantValue b) {
    // Inlined constants don't affect the order and sometimes don't even have
    // names.
    int cmp1 = isConstantInlinedOrAlreadyEmitted(a) ? 0 : 1;
    int cmp2 = isConstantInlinedOrAlreadyEmitted(b) ? 0 : 1;
    if (cmp1 + cmp2 < 2) return cmp1 - cmp2;

    // Emit constant interceptors first. Constant interceptors for primitives
    // might be used by code that builds other constants.  See Issue 18173.
    if (a.isInterceptor != b.isInterceptor) {
      return a.isInterceptor ? -1 : 1;
    }

    // Sorting by the long name clusters constants with the same constructor
    // which compresses a tiny bit better.
    int r = namer.constantLongName(a).compareTo(namer.constantLongName(b));
    if (r != 0) return r;
    // Resolve collisions in the long name by using the constant name (i.e. JS
    // name) which is unique.
    // TODO(herhut): Find a better way to resolve collisions.
    return namer.constantName(a).hashCode.compareTo(
        namer.constantName(b).hashCode);
  }

  @override
  jsAst.Expression constantReference(ConstantValue value) {
    if (value.isFunction) {
      FunctionConstantValue functionConstant = value;
      return isolateStaticClosureAccess(functionConstant.element);
    }

    // We are only interested in the "isInlined" part, but it does not hurt to
    // test for the other predicates.
    if (isConstantInlinedOrAlreadyEmitted(value)) {
      return constantEmitter.generate(value);
    }
    return js('#.#', [namer.globalObjectForConstant(value),
                      namer.constantName(value)]);
  }

  jsAst.Expression constantInitializerExpression(ConstantValue value) {
    return constantEmitter.generate(value);
  }

  String get name => 'CodeEmitter';

  String get finishIsolateConstructorName
      => '${namer.isolateName}.\$finishIsolateConstructor';
  String get isolatePropertiesName
      => '${namer.isolateName}.${namer.isolatePropertiesName}';
  String get lazyInitializerProperty
      => r'$lazy';
  String get lazyInitializerName
      => '${namer.isolateName}.${lazyInitializerProperty}';
  String get initName => 'init';

  jsAst.Name get makeConstListProperty
      => namer.internalGlobal('makeConstantList');

  /// The name of the property that contains all field names.
  ///
  /// This property is added to constructors when isolate support is enabled.
  static const String FIELD_NAMES_PROPERTY_NAME = r"$__fields__";

  /// For deferred loading we communicate the initializers via this global var.
  final String deferredInitializers = r"$dart_deferred_initializers$";

  /// Contains the global state that is needed to initialize and load a
  /// deferred library.
  String get globalsHolder => r"$globals$";

  @override
  bool get supportsReflection => true;

  @override
  jsAst.Expression generateEmbeddedGlobalAccess(String global) {
    return js(generateEmbeddedGlobalAccessString(global));
  }

  String generateEmbeddedGlobalAccessString(String global) {
    // TODO(floitsch): don't use 'init' as global embedder storage.
    return '$initName.$global';
  }

  jsAst.PropertyAccess globalPropertyAccess(Element element) {
    jsAst.Name name = namer.globalPropertyName(element);
    jsAst.PropertyAccess pa = new jsAst.PropertyAccess(
        new jsAst.VariableUse(namer.globalObjectFor(element)),
        name);
    return pa;
  }

  @override
  jsAst.Expression isolateLazyInitializerAccess(FieldElement element) {
     return jsAst.js('#.#', [namer.globalObjectFor(element),
                             namer.lazyInitializerName(element)]);
   }

  @override
  jsAst.Expression isolateStaticClosureAccess(FunctionElement element) {
     return jsAst.js('#.#()',
         [namer.globalObjectFor(element), namer.staticClosureName(element)]);
   }

  @override
  jsAst.PropertyAccess staticFieldAccess(FieldElement element) {
    return globalPropertyAccess(element);
  }

  @override
  jsAst.PropertyAccess staticFunctionAccess(FunctionElement element) {
    return globalPropertyAccess(element);
  }

  @override
  jsAst.PropertyAccess constructorAccess(ClassElement element) {
    return globalPropertyAccess(element);
  }

  @override
  jsAst.PropertyAccess prototypeAccess(ClassElement element,
                                       bool hasBeenInstantiated) {
    return jsAst.js('#.prototype', constructorAccess(element));
  }

  @override
  jsAst.PropertyAccess interceptorClassAccess(ClassElement element) {
    return globalPropertyAccess(element);
  }

  @override
  jsAst.PropertyAccess typeAccess(Element element) {
    return globalPropertyAccess(element);
  }

  @override
  jsAst.Template templateForBuiltin(JsBuiltin builtin) {
    switch (builtin) {
      case JsBuiltin.dartObjectConstructor:
        return jsAst.js.expressionTemplateYielding(
            typeAccess(compiler.objectClass));

      case JsBuiltin.isCheckPropertyToJsConstructorName:
        int isPrefixLength = namer.operatorIsPrefix.length;
        return jsAst.js.expressionTemplateFor('#.substring($isPrefixLength)');

      case JsBuiltin.isFunctionType:
        return backend.rti.representationGenerator.templateForIsFunctionType;

      case JsBuiltin.rawRtiToJsConstructorName:
        return jsAst.js.expressionTemplateFor("#.$typeNameProperty");

      case JsBuiltin.rawRuntimeType:
        return jsAst.js.expressionTemplateFor("#.constructor");

      case JsBuiltin.createFunctionTypeRti:
        return backend.rti.representationGenerator
            .templateForCreateFunctionType;

      case JsBuiltin.isSubtype:
        // TODO(floitsch): move this closer to where is-check properties are
        // built.
        String isPrefix = namer.operatorIsPrefix;
        return jsAst.js.expressionTemplateFor(
            "('$isPrefix' + #) in #.prototype");

      case JsBuiltin.isGivenTypeRti:
        return jsAst.js.expressionTemplateFor('#.$typeNameProperty === #');

      case JsBuiltin.getMetadata:
        String metadataAccess =
            generateEmbeddedGlobalAccessString(embeddedNames.METADATA);
        return jsAst.js.expressionTemplateFor("$metadataAccess[#]");

      case JsBuiltin.getType:
        String typesAccess =
            generateEmbeddedGlobalAccessString(embeddedNames.TYPES);
        return jsAst.js.expressionTemplateFor("$typesAccess[#]");

      default:
        compiler.internalError(NO_LOCATION_SPANNABLE,
            "Unhandled Builtin: $builtin");
        return null;
    }
  }

  List<jsAst.Statement> buildTrivialNsmHandlers(){
    return nsmEmitter.buildTrivialNsmHandlers();
  }

  jsAst.Statement buildNativeInfoHandler(
      jsAst.Expression infoAccess,
      jsAst.Expression constructorAccess,
      jsAst.Expression subclassReadGenerator(jsAst.Expression subclass),
      jsAst.Expression interceptorsByTagAccess,
      jsAst.Expression leafTagsAccess) {
    return NativeGenerator.buildNativeInfoHandler(infoAccess, constructorAccess,
                                                  subclassReadGenerator,
                                                  interceptorsByTagAccess,
                                                  leafTagsAccess);
  }

  jsAst.ObjectInitializer generateInterceptedNamesSet() {
    return interceptorEmitter.generateInterceptedNamesSet();
  }

  /// In minified mode we want to keep the name for the most common core types.
  bool _isNativeTypeNeedingReflectionName(Element element) {
    if (!element.isClass) return false;
    return (element == compiler.intClass ||
            element == compiler.doubleClass ||
            element == compiler.numClass ||
            element == compiler.stringClass ||
            element == compiler.boolClass ||
            element == compiler.nullClass ||
            element == compiler.listClass);
  }

  /// Returns the "reflection name" of an [Element] or [Selector].
  /// The reflection name of a getter 'foo' is 'foo'.
  /// The reflection name of a setter 'foo' is 'foo='.
  /// The reflection name of a method 'foo' is 'foo:N:M:O', where N is the
  /// number of required arguments, M is the number of optional arguments, and
  /// O is the named arguments.
  /// The reflection name of a constructor is similar to a regular method but
  /// starts with 'new '.
  /// The reflection name of class 'C' is 'C'.
  /// An anonymous mixin application has no reflection name.
  /// This is used by js_mirrors.dart.
  String getReflectionName(elementOrSelector, jsAst.Name mangledName) {
    String name = elementOrSelector.name;
    if (backend.shouldRetainName(name) ||
        elementOrSelector is Element &&
        // Make sure to retain names of unnamed constructors, and
        // for common native types.
        ((name == '' &&
          backend.isAccessibleByReflection(elementOrSelector)) ||
         _isNativeTypeNeedingReflectionName(elementOrSelector))) {

      // TODO(ahe): Enable the next line when I can tell the difference between
      // an instance method and a global.  They may have the same mangled name.
      // if (recordedMangledNames.contains(mangledName)) return null;
      recordedMangledNames.add(mangledName);
      return getReflectionNameInternal(elementOrSelector, mangledName);
    }
    return null;
  }

  String getReflectionNameInternal(elementOrSelector,
                                   jsAst.Name mangledName) {
    String name = namer.privateName(elementOrSelector.memberName);
    if (elementOrSelector.isGetter) return name;
    if (elementOrSelector.isSetter) {
      if (mangledName is! SetterName) return '$name=';
      SetterName setterName = mangledName;
      jsAst.Name base = setterName.base;
      jsAst.Name getter = namer.deriveGetterName(base);
      mangledFieldNames.putIfAbsent(getter, () => name);
      assert(mangledFieldNames[getter] == name);
      recordedMangledNames.add(getter);
      // TODO(karlklose,ahe): we do not actually need to store information
      // about the name of this setter in the output, but it is needed for
      // marking the function as invokable by reflection.
      return '$name=';
    }
    if (elementOrSelector is Element && elementOrSelector.isClosure) {
      // Closures are synthesized and their name might conflict with existing
      // globals. Assign an illegal name, and make sure they don't clash
      // with each other.
      return " $name";
    }
    if (elementOrSelector is Selector
        || elementOrSelector.isFunction
        || elementOrSelector.isConstructor) {
      int positionalParameterCount;
      String namedArguments = '';
      bool isConstructor = false;
      if (elementOrSelector is Selector) {
        CallStructure callStructure = elementOrSelector.callStructure;
        positionalParameterCount = callStructure.positionalArgumentCount;
        namedArguments = namedParametersAsReflectionNames(callStructure);
      } else {
        FunctionElement function = elementOrSelector;
        if (function.isConstructor) {
          isConstructor = true;
          name = Elements.reconstructConstructorName(function);
        }
        FunctionSignature signature = function.functionSignature;
        positionalParameterCount = signature.requiredParameterCount;
        if (signature.optionalParametersAreNamed) {
          var names = [];
          for (Element e in signature.optionalParameters) {
            names.add(e.name);
          }
          CallStructure callStructure =
              new CallStructure(positionalParameterCount, names);
          namedArguments = namedParametersAsReflectionNames(callStructure);
        } else {
          // Named parameters are handled differently by mirrors. For unnamed
          // parameters, they are actually required if invoked
          // reflectively. Also, if you have a method c(x) and c([x]) they both
          // get the same mangled name, so they must have the same reflection
          // name.
          positionalParameterCount += signature.optionalParameterCount;
        }
      }
      String suffix = '$name:$positionalParameterCount$namedArguments';
      return (isConstructor) ? 'new $suffix' : suffix;
    }
    Element element = elementOrSelector;
    if (element.isGenerativeConstructorBody) {
      return null;
    } else if (element.isClass) {
      ClassElement cls = element;
      if (cls.isUnnamedMixinApplication) return null;
      return cls.name;
    } else if (element.isTypedef) {
      return element.name;
    }
    throw compiler.internalError(element,
        'Do not know how to reflect on this $element.');
  }

  String namedParametersAsReflectionNames(CallStructure structure) {
    if (structure.isUnnamed) return '';
    String names = structure.getOrderedNamedArguments().join(':');
    return ':$names';
  }

  jsAst.Statement buildCspPrecompiledFunctionFor(
      OutputUnit outputUnit) {
    if (compiler.useContentSecurityPolicy) {
      // TODO(ahe): Compute a hash code.
      // TODO(sigurdm): Avoid this precompiled function. Generated
      // constructor-functions and getter/setter functions can be stored in the
      // library-description table. Setting properties on these can be moved to
      // finishClasses.
      return js.statement(r"""
        #precompiled = function ($collectedClasses$) {
          #norename;
          var $desc;
          #functions;
          return #result;
        };""",
        {'norename': new jsAst.Comment("// ::norenaming:: "),
         'precompiled': generateEmbeddedGlobalAccess(embeddedNames.PRECOMPILED),
         'functions': cspPrecompiledFunctionFor(outputUnit),
         'result': new jsAst.ArrayInitializer(
               cspPrecompiledConstructorNamesFor(outputUnit))});
    } else {
      return js.comment("Constructors are generated at runtime.");
    }
  }

  void assembleClass(Class cls, ClassBuilder enclosingBuilder,
                     Fragment fragment) {
    ClassElement classElement = cls.element;
    compiler.withCurrentElement(classElement, () {
      if (compiler.hasIncrementalSupport) {
        ClassBuilder cachedBuilder =
            cachedClassBuilders.putIfAbsent(classElement, () {
              ClassBuilder builder =
                  new ClassBuilder.forClass(classElement, namer);
              classEmitter.emitClass(cls, builder, fragment);
              return builder;
            });
        invariant(classElement, cachedBuilder.fields.isEmpty);
        invariant(classElement, cachedBuilder.superName == null);
        invariant(classElement, cachedBuilder.functionType == null);
        invariant(classElement, cachedBuilder.fieldMetadata == null);
        enclosingBuilder.properties.addAll(cachedBuilder.properties);
      } else {
        classEmitter.emitClass(cls, enclosingBuilder, fragment);
      }
    });
  }

  void assembleStaticFunctions(Iterable<Method> staticFunctions,
                               Fragment fragment) {
    if (staticFunctions == null) return;

    for (Method method in staticFunctions) {
      Element element = method.element;
      // We need to filter out null-elements for the interceptors.
      // TODO(floitsch): use the precomputed interceptors here.
      if (element == null) continue;
      ClassBuilder builder = new ClassBuilder.forStatics(element, namer);
      containerBuilder.addMemberMethod(method, builder);
      getElementDescriptor(element, fragment).properties
          .addAll(builder.properties);
    }
  }

  jsAst.Statement buildStaticNonFinalFieldInitializations(
      OutputUnit outputUnit) {
    jsAst.Statement buildInitialization(Element element,
                                       jsAst.Expression initialValue) {
      return js.statement('${namer.staticStateHolder}.# = #',
                          [namer.globalPropertyName(element), initialValue]);
    }

    bool inMainUnit = (outputUnit == compiler.deferredLoadTask.mainOutputUnit);
    JavaScriptConstantCompiler handler = backend.constants;
    List<jsAst.Statement> parts = <jsAst.Statement>[];

    Iterable<Element> fields = outputStaticNonFinalFieldLists[outputUnit];
    // If the outputUnit does not contain any static non-final fields, then
    // [fields] is `null`.
    if (fields != null) {
      for (Element element in fields) {
        compiler.withCurrentElement(element, () {
          ConstantValue constant = handler.getInitialValueFor(element);
          parts.add(buildInitialization(element, constantReference(constant)));
        });
      }
    }

    if (inMainUnit && outputStaticNonFinalFieldLists.length > 1) {
      // In the main output-unit we output a stub initializer for deferred
      // variables, so that `isolateProperties` stays a fast object.
      outputStaticNonFinalFieldLists.forEach(
          (OutputUnit fieldsOutputUnit, Iterable<VariableElement> fields) {
        if (fieldsOutputUnit == outputUnit) return;  // Skip the main unit.
        for (Element element in fields) {
          compiler.withCurrentElement(element, () {
            parts.add(buildInitialization(element, jsAst.number(0)));
          });
        }
      });
    }

    return new jsAst.Block(parts);
  }

  jsAst.Statement buildLazilyInitializedStaticFields() {
    JavaScriptConstantCompiler handler = backend.constants;
    List<VariableElement> lazyFields =
        handler.getLazilyInitializedFieldsForEmission();
    if (lazyFields.isNotEmpty) {
      needsLazyInitializer = true;
      List<jsAst.Expression> laziesInfo = buildLaziesInfo(lazyFields);
      return js.statement('''
      (function(lazies) {
        for (var i = 0; i < lazies.length; ) {
          var fieldName = lazies[i++];
          var getterName = lazies[i++];
          if (#notMinified) {
            var staticName = lazies[i++];
          }
          var lazyValue = lazies[i++];

          // We build the lazy-check here:
          //   lazyInitializer(fieldName, getterName, lazyValue, staticName);
          // 'staticName' is used for error reporting in non-minified mode.
          // 'lazyValue' must be a closure that constructs the initial value.
          if (#notMinified) {
            #lazy(fieldName, getterName, lazyValue, staticName);
          } else {
            #lazy(fieldName, getterName, lazyValue);
          }
        }
      })(#laziesInfo)
      ''', {'notMinified': !compiler.enableMinification,
            'laziesInfo': new jsAst.ArrayInitializer(laziesInfo),
            'lazy': js(lazyInitializerName)});
    } else {
      return js.comment("No lazy statics.");
    }
  }

  List<jsAst.Expression> buildLaziesInfo(List<VariableElement> lazies) {
    List<jsAst.Expression> laziesInfo = <jsAst.Expression>[];
    for (VariableElement element in Elements.sortedByPosition(lazies)) {
      jsAst.Expression code = backend.generatedCode[element];
      // The code is null if we ended up not needing the lazily
      // initialized field after all because of constant folding
      // before code generation.
      if (code == null) continue;
      laziesInfo.add(js.quoteName(namer.globalPropertyName(element)));
      laziesInfo.add(js.quoteName(namer.lazyInitializerName(element)));
      if (!compiler.enableMinification) {
        laziesInfo.add(js.string(element.name));
      }
      laziesInfo.add(code);
    }
    return laziesInfo;
  }

  // TODO(sra): Remove this unused function.
  jsAst.Expression buildLazilyInitializedStaticField(
      VariableElement element, {String isolateProperties}) {
    jsAst.Expression code = backend.generatedCode[element];
    // The code is null if we ended up not needing the lazily
    // initialized field after all because of constant folding
    // before code generation.
    if (code == null) return null;
    // The code only computes the initial value. We build the lazy-check
    // here:
    //   lazyInitializer(fieldName, getterName, initial, name, prototype);
    // The name is used for error reporting. The 'initial' must be a
    // closure that constructs the initial value.
    if (isolateProperties != null) {
      // This is currently only used in incremental compilation to patch
      // in new lazy values.
      return js('#(#,#,#,#,#)',
          [js(lazyInitializerName),
           js.quoteName(namer.globalPropertyName(element)),
           js.quoteName(namer.lazyInitializerName(element)),
           code,
           js.string(element.name),
           isolateProperties]);
    }

    if (compiler.enableMinification) {
      return js('#(#,#,#)',
          [js(lazyInitializerName),
           js.quoteName(namer.globalPropertyName(element)),
           js.quoteName(namer.lazyInitializerName(element)),
           code]);
    } else {
      return js('#(#,#,#,#)',
          [js(lazyInitializerName),
           js.quoteName(namer.globalPropertyName(element)),
           js.quoteName(namer.lazyInitializerName(element)),
           code,
           js.string(element.name)]);
    }
  }

  jsAst.Statement buildMetadata(Program program, OutputUnit outputUnit) {
    List<jsAst.Statement> parts = <jsAst.Statement>[];

    jsAst.Expression types = program.metadataTypesForOutputUnit(outputUnit);

    if (outputUnit == compiler.deferredLoadTask.mainOutputUnit) {
      jsAst.Expression metadataAccess =
          generateEmbeddedGlobalAccess(embeddedNames.METADATA);
      jsAst.Expression typesAccess =
          generateEmbeddedGlobalAccess(embeddedNames.TYPES);

      parts..add(js.statement('# = #;', [metadataAccess, program.metadata]))
           ..add(js.statement('# = #;', [typesAccess, types]));
    } else if (types != null) {
      parts.add(js.statement('var ${namer.deferredTypesName} = #;',
                             types));
    }
    return new jsAst.Block(parts);
  }

  jsAst.Statement buildCompileTimeConstants(List<Constant> constants,
                                           {bool isMainFragment}) {
    assert(isMainFragment != null);

    if (constants.isEmpty) return js.comment("No constants in program.");
    List<jsAst.Statement> parts = <jsAst.Statement>[];
    if (compiler.hasIncrementalSupport && isMainFragment) {
      parts = cachedEmittedConstantsAst;
    }
    for (Constant constant in constants) {
      ConstantValue constantValue = constant.value;
      if (compiler.hasIncrementalSupport && isMainFragment) {
        if (cachedEmittedConstants.contains(constantValue)) continue;
        cachedEmittedConstants.add(constantValue);
      }
      parts.add(buildConstantInitializer(constantValue));
    }

    return new jsAst.Block(parts);
  }

  jsAst.Statement buildConstantInitializer(ConstantValue constant) {
    jsAst.Name name = namer.constantName(constant);
    return js.statement('#.# = #',
                        [namer.globalObjectForConstant(constant), name,
                         constantInitializerExpression(constant)]);
  }

  jsAst.Expression constantListGenerator(jsAst.Expression array) {
    // TODO(floitsch): there is no harm in caching the template.
    return js('${namer.isolateName}.#(#)', [makeConstListProperty, array]);
  }

  jsAst.Statement buildMakeConstantList(bool outputContainsConstantList) {
    if (outputContainsConstantList) {
      return js.statement(r'''
          // Functions are stored in the hidden class and not as properties in
          // the object. We never actually look at the value, but only want
          // to know if the property exists.
          #.# = function (list) {
            list.immutable$list = Array;
            list.fixed$length = Array;
            return list;
          }''',
          [namer.isolateName, makeConstListProperty]);
    } else {
      return js.comment("Output contains no constant list.");
    }
  }

  jsAst.Statement buildFunctionThatReturnsNull() {
    return js.statement('#.# = function() {}',
                        [namer.isolateName,
                         backend.rti.getFunctionThatReturnsNullName]);
  }

  jsAst.Expression generateFunctionThatReturnsNull() {
    return js("#.#", [namer.isolateName,
                      backend.rti.getFunctionThatReturnsNullName]);
  }

  buildMain(jsAst.Statement invokeMain) {
    if (compiler.isMockCompilation) return js.comment("Mock compilation");

    List<jsAst.Statement> parts = <jsAst.Statement>[];

    if (NativeGenerator.needsIsolateAffinityTagInitialization(backend)) {
      parts.add(
          NativeGenerator.generateIsolateAffinityTagInitialization(
              backend,
              generateEmbeddedGlobalAccess,
              js("convertToFastObject", [])));
    }

    parts..add(js.comment('BEGIN invoke [main].'))
         ..add(invokeMain)
         ..add(js.comment('END invoke [main].'));

    return new jsAst.Block(parts);
  }

  jsAst.Statement buildInitFunction(bool outputContainsConstantList) {
    jsAst.Expression allClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.ALL_CLASSES);
    jsAst.Expression getTypeFromNameAccess =
        generateEmbeddedGlobalAccess(embeddedNames.GET_TYPE_FROM_NAME);
    jsAst.Expression interceptorsByTagAccess =
        generateEmbeddedGlobalAccess(embeddedNames.INTERCEPTORS_BY_TAG);
    jsAst.Expression leafTagsAccess =
        generateEmbeddedGlobalAccess(embeddedNames.LEAF_TAGS);
    jsAst.Expression finishedClassesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.FINISHED_CLASSES);
    jsAst.Expression cyclicThrow =
        staticFunctionAccess(backend.getCyclicThrowHelper());
    jsAst.Expression laziesAccess =
        generateEmbeddedGlobalAccess(embeddedNames.LAZIES);

    return js.statement('''
      function init() {
        $isolatePropertiesName = Object.create(null);
        #allClasses = map();
        #getTypeFromName = function(name) {return #allClasses[name];};
        #interceptorsByTag = map();
        #leafTags = map();
        #finishedClasses = map();

        if (#needsLazyInitializer) {
          // [staticName] is only provided in non-minified mode. If missing, we 
          // fall back to [fieldName]. Likewise, [prototype] is optional and 
          // defaults to the isolateProperties object.
          $lazyInitializerName = function (fieldName, getterName, lazyValue,
                                           staticName, prototype) {
            if (!#lazies) #lazies = Object.create(null);
            #lazies[fieldName] = getterName;

            // 'prototype' will be undefined except if we are doing an update
            // during incremental compilation. In this case we put the lazy
            // field directly on the isolate instead of the isolateProperties.
            prototype = prototype || $isolatePropertiesName;
            var sentinelUndefined = {};
            var sentinelInProgress = {};
            prototype[fieldName] = sentinelUndefined;

            prototype[getterName] = function () {
              var result = this[fieldName];
              try {
                if (result === sentinelUndefined) {
                  this[fieldName] = sentinelInProgress;

                  try {
                    result = this[fieldName] = lazyValue();
                  } finally {
                    // Use try-finally, not try-catch/throw as it destroys the
                    // stack trace.
                    if (result === sentinelUndefined)
                      this[fieldName] = null;
                  }
                } else {
                  if (result === sentinelInProgress)
                    // In minified mode, static name is not provided, so fall
                    // back to the minified fieldName.
                    #cyclicThrow(staticName || fieldName);
                }

                return result;
              } finally {
                this[getterName] = function() { return this[fieldName]; };
              }
            }
          }
        }

        // We replace the old Isolate function with a new one that initializes
        // all its fields with the initial (and often final) value of all
        // globals.
        //
        // We also copy over old values like the prototype, and the
        // isolateProperties themselves.
        $finishIsolateConstructorName = function (oldIsolate) {
          var isolateProperties = oldIsolate.#isolatePropertiesName;
          function Isolate() {

            var staticNames = Object.keys(isolateProperties);
            for (var i = 0; i < staticNames.length; i++) {
              var staticName = staticNames[i];
              this[staticName] = isolateProperties[staticName];
            }

            // Reset lazy initializers to null.
            // When forcing the object to fast mode (below) v8 will consider
            // functions as part the object's map. Since we will change them
            // (after the first call to the getter), we would have a map
            // transition.
            var lazies = init.lazies;
            var lazyInitializers = lazies ? Object.keys(lazies) : [];
            for (var i = 0; i < lazyInitializers.length; i++) {
               this[lazies[lazyInitializers[i]]] = null;
            }

            // Use the newly created object as prototype. In Chrome,
            // this creates a hidden class for the object and makes
            // sure it is fast to access.
            function ForceEfficientMap() {}
            ForceEfficientMap.prototype = this;
            new ForceEfficientMap();

            // Now, after being a fast map we can set the lazies again.
            for (var i = 0; i < lazyInitializers.length; i++) {
              var lazyInitName = lazies[lazyInitializers[i]];
              this[lazyInitName] = isolateProperties[lazyInitName];
            }
          }
          Isolate.prototype = oldIsolate.prototype;
          Isolate.prototype.constructor = Isolate;
          Isolate.#isolatePropertiesName = isolateProperties;
          if (#outputContainsConstantList) {
            Isolate.#makeConstListProperty = oldIsolate.#makeConstListProperty;
          }
          Isolate.#functionThatReturnsNullProperty =
              oldIsolate.#functionThatReturnsNullProperty;
          if (#hasIncrementalSupport) {
            Isolate.#lazyInitializerProperty =
                oldIsolate.#lazyInitializerProperty;
          }
          return Isolate;
      }

      }''', {'allClasses': allClassesAccess,
            'getTypeFromName': getTypeFromNameAccess,
            'interceptorsByTag': interceptorsByTagAccess,
            'leafTags': leafTagsAccess,
            'finishedClasses': finishedClassesAccess,
            'needsLazyInitializer': needsLazyInitializer,
            'lazies': laziesAccess, 'cyclicThrow': cyclicThrow,
            'isolatePropertiesName': namer.isolatePropertiesName,
            'outputContainsConstantList': outputContainsConstantList,
            'makeConstListProperty': makeConstListProperty,
            'functionThatReturnsNullProperty':
                backend.rti.getFunctionThatReturnsNullName,
            'hasIncrementalSupport': compiler.hasIncrementalSupport,
            'lazyInitializerProperty': lazyInitializerProperty,});
  }

  jsAst.Statement buildConvertToFastObjectFunction() {
    List<jsAst.Statement> debugCode = <jsAst.Statement>[];
    if (DEBUG_FAST_OBJECTS) {
      debugCode.add(js.statement(r'''
        // The following only works on V8 when run with option
        // "--allow-natives-syntax".  We use'new Function' because the
         // miniparser does not understand V8 native syntax.
        if (typeof print === "function") {
          var HasFastProperties =
            new Function("a", "return %HasFastProperties(a)");
          print("Size of global object: "
                   + String(Object.getOwnPropertyNames(properties).length)
                   + ", fast properties " + HasFastProperties(properties));
        }'''));
    }

    return js.statement(r'''
      function convertToFastObject(properties) {
        // Create an instance that uses 'properties' as prototype. This should
        // make 'properties' a fast object.
        function MyClass() {};
        MyClass.prototype = properties;
        new MyClass();
        #;
        return properties;
      }''', [debugCode]);
  }

  jsAst.Statement buildConvertToSlowObjectFunction() {
    return js.statement(r'''
    function convertToSlowObject(properties) {
      // Add and remove a property to make the object transition into hashmap
      // mode.
      properties.__MAGIC_SLOW_PROPERTY = 1;
      delete properties.__MAGIC_SLOW_PROPERTY;
      return properties;
    }''');
  }

  jsAst.Statement buildSupportsDirectProtoAccess() {
    jsAst.Statement supportsDirectProtoAccess;

    if (compiler.hasIncrementalSupport) {
      supportsDirectProtoAccess = js.statement(r'''
        var supportsDirectProtoAccess = false;
      ''');
    } else {
      supportsDirectProtoAccess = js.statement(r'''
        var supportsDirectProtoAccess = (function () {
          var cls = function () {};
          cls.prototype = {'p': {}};
          var object = new cls();
          return object.__proto__ &&
                 object.__proto__.p === cls.prototype.p;
         })();
      ''');
    }

    return supportsDirectProtoAccess;
  }

  jsAst.Expression generateLibraryDescriptor(LibraryElement library,
                                             Fragment fragment) {
    var uri = "";
    if (!compiler.enableMinification || backend.mustPreserveUris) {
      uri = library.canonicalUri;
      if (uri.scheme == 'file' && compiler.outputUri != null) {
        uri = relativize(compiler.outputUri, library.canonicalUri, false);
      }
    }

    String libraryName =
        (!compiler.enableMinification || backend.mustRetainLibraryNames) ?
        library.getLibraryName() :
        "";

    jsAst.Fun metadata = task.metadataCollector.buildMetadataFunction(library);

    ClassBuilder descriptor = elementDescriptors[fragment][library];

    jsAst.ObjectInitializer initializer;
    if (descriptor == null) {
      // Nothing of the library was emitted.
      // TODO(floitsch): this should not happen. We currently have an example
      // with language/prefix6_negative_test.dart where we have an instance
      // method without its corresponding class.
      initializer = new jsAst.ObjectInitializer([]);
    } else {
      initializer = descriptor.toObjectInitializer();
    }

    compiler.dumpInfoTask.registerElementAst(library, metadata);
    compiler.dumpInfoTask.registerElementAst(library, initializer);

    List<jsAst.Expression> parts = <jsAst.Expression>[];
    parts..add(js.string(libraryName))
         ..add(js.string(uri.toString()))
         ..add(metadata == null ? new jsAst.ArrayHole() : metadata)
         ..add(js('#', namer.globalObjectFor(library)))
         ..add(initializer);
    if (library == compiler.mainApp) {
      parts.add(js.number(1));
    }

    return new jsAst.ArrayInitializer(parts);
  }

  void assemblePrecompiledConstructor(OutputUnit outputUnit,
                                      jsAst.Name constructorName,
                                      jsAst.Expression constructorAst,
                                      List<jsAst.Name> fields) {
    cspPrecompiledFunctionFor(outputUnit).add(
        new jsAst.FunctionDeclaration(constructorName, constructorAst));

    String fieldNamesProperty = FIELD_NAMES_PROPERTY_NAME;
    bool hasIsolateSupport = compiler.hasIsolateSupport;
    jsAst.Node fieldNamesArray;
    if (hasIsolateSupport) {
      fieldNamesArray =
          new jsAst.ArrayInitializer(fields.map(js.quoteName).toList());
    } else {
      fieldNamesArray = new jsAst.LiteralNull();
    }

    cspPrecompiledFunctionFor(outputUnit).add(js.statement(r'''
        {
          #constructorName.#typeNameProperty = #constructorNameString;
          // IE does not have a name property.
          if (!("name" in #constructorName))
              #constructorName.name = #constructorNameString;
          $desc = $collectedClasses$.#constructorName[1];
          #constructorName.prototype = $desc;
          ''' /* next string is not a raw string */ '''
          if (#hasIsolateSupport) {
            #constructorName.$fieldNamesProperty = #fieldNamesArray;
          }
        }''',
        {"constructorName": constructorName,
         "typeNameProperty": typeNameProperty,
         "constructorNameString": js.quoteName(constructorName),
         "hasIsolateSupport": hasIsolateSupport,
         "fieldNamesArray": fieldNamesArray}));

    cspPrecompiledConstructorNamesFor(outputUnit).add(js('#', constructorName));
  }

  void assembleTypedefs(Program program) {
    Fragment mainFragment = program.mainFragment;
    OutputUnit mainOutputUnit = mainFragment.outputUnit;

    // Emit all required typedef declarations into the main output unit.
    // TODO(karlklose): unify required classes and typedefs to declarations
    // and have builders for each kind.
    for (TypedefElement typedef in typedefsNeededForReflection) {
      LibraryElement library = typedef.library;
      // TODO(karlklose): add a TypedefBuilder and move this code there.
      DartType type = typedef.alias;
      // TODO(zarah): reify type variables once reflection on type arguments of
      // typedefs is supported.
      jsAst.Expression typeIndex =
          task.metadataCollector.reifyType(type, ignoreTypeVariables: true);
      ClassBuilder builder = new ClassBuilder.forStatics(typedef, namer);
      builder.addPropertyByName(embeddedNames.TYPEDEF_TYPE_PROPERTY_NAME,
                                typeIndex);
      builder.addPropertyByName(embeddedNames.TYPEDEF_PREDICATE_PROPERTY_NAME,
                                js.boolean(true));

      // We can be pretty sure that the objectClass is initialized, since
      // typedefs are only emitted with reflection, which requires lots of
      // classes.
      assert(compiler.objectClass != null);
      builder.superName = namer.className(compiler.objectClass);
      jsAst.Node declaration = builder.toObjectInitializer();
      jsAst.Name mangledName = namer.globalPropertyName(typedef);
      String reflectionName = getReflectionName(typedef, mangledName);
      getElementDescriptor(library, mainFragment)
          ..addProperty(mangledName, declaration)
          ..addPropertyByName("+$reflectionName", js.string(''));
      // Also emit a trivial constructor for CSP mode.
      jsAst.Name constructorName = mangledName;
      jsAst.Expression constructorAst = js('function() {}');
      List<jsAst.Name> fieldNames = [];
      assemblePrecompiledConstructor(mainOutputUnit,
                                     constructorName,
                                     constructorAst,
                                     fieldNames);
    }
  }

  jsAst.Statement buildGlobalObjectSetup(bool isProgramSplit) {
    List<jsAst.Statement> parts = <jsAst.Statement>[];

    parts.add(js.comment("""
      // The global objects start as so-called "slow objects". For V8, this
      // means that it won't try to make map transitions as we add properties
      // to these objects. Later on, we attempt to turn these objects into
      // fast objects by calling "convertToFastObject" (see
      // [emitConvertToFastObjectFunction]).
      """));

    for (String globalObject in Namer.reservedGlobalObjectNames) {
      if (isProgramSplit) {
        String template =
            "var #globalObject = #globalsHolder.#globalObject = map();";
        parts.add(js.statement(template, {"globalObject": globalObject,
                                          "globalsHolder": globalsHolder}));
      } else {
        parts.add(js.statement("var #globalObject = map();",
                               {"globalObject": globalObject}));
      }

    }

    return new jsAst.Block(parts);
  }

  jsAst.Statement buildConvertGlobalObjectToFastObjects() {
    List<jsAst.Statement> parts = <jsAst.Statement>[];

    for (String globalObject in Namer.reservedGlobalObjectNames) {
      parts.add(js.statement(
          '#globalObject = convertToFastObject(#globalObject);',
          {"globalObject": globalObject}));
    }

    return new jsAst.Block(parts);
  }

  jsAst.Statement buildDebugFastObjectCode() {
    List<jsAst.Statement> parts = <jsAst.Statement>[];

    if (DEBUG_FAST_OBJECTS) {
      parts.add(js.statement(r'''
          // The following only works on V8 when run with option
          // "--allow-natives-syntax".  We use'new Function' because the
          // miniparser does not understand V8 native syntax.
          if (typeof print === "function") {
            var HasFastProperties =
              new Function("a", "return %HasFastProperties(a)");
            print("Size of global helper object: "
                   + String(Object.getOwnPropertyNames(H).length)
                   + ", fast properties " + HasFastProperties(H));
            print("Size of global platform object: "
                   + String(Object.getOwnPropertyNames(P).length)
                   + ", fast properties " + HasFastProperties(P));
            print("Size of global dart:html object: "
                   + String(Object.getOwnPropertyNames(W).length)
                   + ", fast properties " + HasFastProperties(W));
            print("Size of isolate properties object: "
                   + String(Object.getOwnPropertyNames($).length)
                   + ", fast properties " + HasFastProperties($));
            print("Size of constant object: "
                   + String(Object.getOwnPropertyNames(C).length)
                   + ", fast properties " + HasFastProperties(C));
            var names = Object.getOwnPropertyNames($);
            for (var i = 0; i < names.length; i++) {
              print("$." + names[i]);
            }
          }
       '''));

      for (String object in Namer.userGlobalObjects) {
        parts.add(js.statement('''
          if (typeof print === "function") {
            print("Size of " + #objectString + ": "
                  + String(Object.getOwnPropertyNames(#object).length)
                  + ", fast properties " + HasFastProperties(#object));
          }
        ''', {"object": object, "objectString": js.string(object)}));
      }
    }

    return new jsAst.Block(parts);
  }

  jsAst.Statement buildMangledNames() {
    List<jsAst.Statement> parts = <jsAst.Statement>[];

    if (!mangledFieldNames.isEmpty) {
      List<jsAst.Name> keys = mangledFieldNames.keys.toList()..sort();
      var properties = [];
      for (jsAst.Name key in keys) {
        var value = js.string(mangledFieldNames[key]);
        properties.add(new jsAst.Property(key, value));
      }

      jsAst.Expression mangledNamesAccess =
          generateEmbeddedGlobalAccess(embeddedNames.MANGLED_NAMES);
      var map = new jsAst.ObjectInitializer(properties);
      parts.add(js.statement('# = #', [mangledNamesAccess, map]));
    }

    if (!mangledGlobalFieldNames.isEmpty) {
      List<jsAst.Name> keys = mangledGlobalFieldNames.keys.toList()
          ..sort();
      List<jsAst.Property> properties = <jsAst.Property>[];
      for (jsAst.Name key in keys) {
        jsAst.Literal value = js.string(mangledGlobalFieldNames[key]);
        properties.add(new jsAst.Property(js.quoteName(key), value));
      }
      jsAst.Expression mangledGlobalNamesAccess =
          generateEmbeddedGlobalAccess(embeddedNames.MANGLED_GLOBAL_NAMES);
      jsAst.ObjectInitializer map = new jsAst.ObjectInitializer(properties);
      parts.add(js.statement('# = #', [mangledGlobalNamesAccess, map]));
    }

    return new jsAst.Block(parts);
  }

  void checkEverythingEmitted(Iterable<Element> elements) {
    List<Element> pendingStatics;
    if (!compiler.hasIncrementalSupport) {
      pendingStatics =
          Elements.sortedByPosition(elements.where((e) => !e.isLibrary));

      pendingStatics.forEach((element) =>
          compiler.reportInfo(
              element, MessageKind.GENERIC, {'text': 'Pending statics.'}));
    }

    if (pendingStatics != null && !pendingStatics.isEmpty) {
      compiler.internalError(pendingStatics.first,
          'Pending statics (see above).');
    }
  }

  void assembleLibrary(Library library, Fragment fragment) {
    LibraryElement libraryElement = library.element;

    assembleStaticFunctions(library.statics, fragment);

    ClassBuilder libraryBuilder =
        getElementDescriptor(libraryElement, fragment);
    for (Class cls in library.classes) {
      assembleClass(cls, libraryBuilder, fragment);
    }

    classEmitter.emitFields(library, libraryBuilder, emitStatics: true);
  }

  void assembleProgram(Program program) {
    for (Fragment fragment in program.fragments) {
      for (Library library in fragment.libraries) {
        assembleLibrary(library, fragment);
      }
    }
    assembleTypedefs(program);
  }

  jsAst.Program buildOutputAstForMain(Program program,
      Map<OutputUnit, _DeferredOutputUnitHash> deferredLoadHashes) {
    MainFragment mainFragment = program.mainFragment;
    OutputUnit mainOutputUnit = mainFragment.outputUnit;
    bool isProgramSplit = program.isSplit;

    List<jsAst.Statement> statements = <jsAst.Statement>[];

    statements..add(buildGeneratedBy())
              ..add(js.comment(HOOKS_API_USAGE));

    if (isProgramSplit) {
      /// For deferred loading we communicate the initializers via this global
      /// variable. The deferred hunks will add their initialization to this.
      /// The semicolon is important in minified mode, without it the
      /// following parenthesis looks like a call to the object literal.
      statements.add(
          js.statement('self.#deferredInitializers = '
                       'self.#deferredInitializers || Object.create(null);',
                       {'deferredInitializers': deferredInitializers}));
    }

    // Collect the AST for the decriptors
    Map<Element, ClassBuilder> descriptors = elementDescriptors[mainFragment];
    if (descriptors == null) descriptors = const {};

    checkEverythingEmitted(descriptors.keys);

    Iterable<LibraryElement> libraries = outputLibraryLists[mainOutputUnit];
    if (libraries == null) libraries = <LibraryElement>[];

    List<jsAst.Expression> parts = <jsAst.Expression>[];
    for (LibraryElement library in Elements.sortedByPosition(libraries)) {
      parts.add(generateLibraryDescriptor(library, mainFragment));
      descriptors.remove(library);
    }

    if (descriptors.isNotEmpty) {
      List<Element> remainingLibraries = descriptors.keys
      .where((Element e) => e is LibraryElement)
      .toList();

      // The remaining descriptors are only accessible through reflection.
      // The program builder does not collect libraries that only
      // contain typedefs that are used for reflection.
      for (LibraryElement element in remainingLibraries) {
        assert(element is LibraryElement || compiler.hasIncrementalSupport);
        if (element is LibraryElement) {
          parts.add(generateLibraryDescriptor(element, mainFragment));
          descriptors.remove(element);
        }
      }
    }
    jsAst.ArrayInitializer descriptorsAst = new jsAst.ArrayInitializer(parts);

    // Using a named function here produces easier to read stack traces in
    // Chrome/V8.
    statements.add(js.statement("""
    (function() {
       // No renaming in the top-level function to save the locals for the
       // nested context where they will be used more. We have to put the
       // comment into a hole as the parser strips out comments right away.
       #disableVariableRenaming;
       #supportsDirectProtoAccess;

       if (#hasIncrementalSupport) {
         #helper = #helper || Object.create(null);
         #helper.patch = function(a) { eval(a)};
         #helper.schemaChange = #schemaChange;
         #helper.addMethod = #addMethod;
         #helper.extractStubs =
           function(array, name, isStatic, originalDescriptor) {
             var descriptor = Object.create(null);
             this.addStubs(descriptor, array, name, isStatic, []);
             return descriptor;
            };
       }

       if (#isProgramSplit) {
         /// We collect all the global state, so it can be passed to the
         /// initializer of deferred files.
         var #globalsHolder = Object.create(null)
       }

       // [map] returns an object that V8 shouldn't try to optimize with a
       // hidden class. This prevents a potential performance problem where V8
       // tries to build a hidden class for an object used as a hashMap.
       // It requires fewer characters to declare a variable as a parameter than
       // with `var`.
       function map(x) {
         x = Object.create(null);
         x.x = 0;
         delete x.x;
         return x;
       }

       #globalObjectSetup;

       function #isolateName() {}

       if (#isProgramSplit) {
         #globalsHolder.#isolateName = #isolateName;
         #globalsHolder.#initName = #initName;
         #globalsHolder.#setupProgramName = #setupProgramName;
       }

       init();

       #mangledNames;

       #cspPrecompiledFunctions;

       #setupProgram;

       #functionThatReturnsNull;

       // The argument to reflectionDataParser is assigned to a temporary 'dart'
       // so that 'dart.' will appear as the prefix to dart methods in stack
       // traces and profile entries.
       var dart = #descriptors;

       #setupProgramName(dart, 0);

       #getInterceptorMethods;
       #oneShotInterceptors;

       #makeConstantList;

       // We abuse the short name used for the isolate here to store
       // the isolate properties. This is safe as long as the real isolate
       // object does not exist yet.
       var ${namer.staticStateHolder} = #isolatePropertiesName;

       // Constants in checked mode call into RTI code to set type information
       // which may need getInterceptor (and one-shot interceptor) methods, so
       // we have to make sure that [emitGetInterceptorMethods] and
       // [emitOneShotInterceptors] have been called.
       #compileTimeConstants;

       // Static field initializations require the classes and compile-time
       // constants to be set up.
       #staticNonFinalInitializers;

       ${namer.staticStateHolder} = null;

       #deferredBoilerPlate;

       #typeToInterceptorMap;

       #lazyStaticFields;

       #isolateName = $finishIsolateConstructorName(#isolateName);

       ${namer.staticStateHolder} = new #isolateName();

       #metadata;

       #convertToFastObject;
       #convertToSlowObject;

       #convertGlobalObjectsToFastObjects;
       #debugFastObjects;

       #init;

       #main;
    })();
    """, {
      "disableVariableRenaming": js.comment("/* ::norenaming:: */"),
      "hasIncrementalSupport": compiler.hasIncrementalSupport,
      "helper": js('this.#', [namer.incrementalHelperName]),
      "schemaChange": buildSchemaChangeFunction(),
      "addMethod": buildIncrementalAddMethod(),
      "isProgramSplit": isProgramSplit,
      "supportsDirectProtoAccess": buildSupportsDirectProtoAccess(),
      "globalsHolder": globalsHolder,
      "globalObjectSetup": buildGlobalObjectSetup(isProgramSplit),
      "isolateName": namer.isolateName,
      "isolatePropertiesName": js(isolatePropertiesName),
      "initName": initName,
      "functionThatReturnsNull": buildFunctionThatReturnsNull(),
      "mangledNames": buildMangledNames(),
      "setupProgram": buildSetupProgram(program, compiler, backend, namer, this),
      "setupProgramName": setupProgramName,
      "descriptors": descriptorsAst,
      "cspPrecompiledFunctions": buildCspPrecompiledFunctionFor(mainOutputUnit),
      "getInterceptorMethods": interceptorEmitter.buildGetInterceptorMethods(),
      "oneShotInterceptors": interceptorEmitter.buildOneShotInterceptors(),
      "makeConstantList":
          buildMakeConstantList(program.outputContainsConstantList),
      "compileTimeConstants":  buildCompileTimeConstants(mainFragment.constants,
                                                         isMainFragment: true),
      "deferredBoilerPlate": buildDeferredBoilerPlate(deferredLoadHashes),
      "staticNonFinalInitializers": buildStaticNonFinalFieldInitializations(
          mainOutputUnit),
      "typeToInterceptorMap":
          interceptorEmitter.buildTypeToInterceptorMap(program),
      "lazyStaticFields": buildLazilyInitializedStaticFields(),
      "metadata": buildMetadata(program, mainOutputUnit),
      "convertToFastObject": buildConvertToFastObjectFunction(),
      "convertToSlowObject": buildConvertToSlowObjectFunction(),
      "convertGlobalObjectsToFastObjects":
          buildConvertGlobalObjectToFastObjects(),
      "debugFastObjects": buildDebugFastObjectCode(),
      "init": buildInitFunction(program.outputContainsConstantList),
      "main": buildMain(mainFragment.invokeMain)
    }));

    return new jsAst.Program(statements);
  }

  void emitMainOutputUnit(OutputUnit mainOutputUnit, jsAst.Program program) {
    LineColumnCollector lineColumnCollector;
    List<CodeOutputListener> codeOutputListeners;
    if (generateSourceMap) {
      lineColumnCollector = new LineColumnCollector();
      codeOutputListeners = <CodeOutputListener>[lineColumnCollector];
    }

    CodeOutput mainOutput =
        new StreamCodeOutput(compiler.outputProvider('', 'js'),
                             codeOutputListeners);
    outputBuffers[mainOutputUnit] = mainOutput;


    mainOutput.addBuffer(jsAst.prettyPrint(program,
                                           compiler,
                                           monitor: compiler.dumpInfoTask));

    if (compiler.deferredMapUri != null) {
      outputDeferredMap();
    }

    if (generateSourceMap) {
      mainOutput.add(
          generateSourceMapTag(compiler.sourceMapUri, compiler.outputUri));
    }

    mainOutput.close();

    if (generateSourceMap) {
      outputSourceMap(mainOutput, lineColumnCollector, '',
          compiler.sourceMapUri, compiler.outputUri);
    }
  }

  /// Used by incremental compilation to patch up the prototype of
  /// [oldConstructor] for use as prototype of [newConstructor].
  jsAst.Fun buildSchemaChangeFunction() {
    if (!compiler.hasIncrementalSupport) return null;
    return js('''
function(newConstructor, oldConstructor, superclass) {
  // Invariant: newConstructor.prototype has no interesting properties besides
  // generated accessors. These are copied to oldPrototype which will be
  // updated by other incremental changes.
  if (superclass != null) {
    this.inheritFrom(newConstructor, superclass);
  }
  var oldPrototype = oldConstructor.prototype;
  var newPrototype = newConstructor.prototype;
  var hasOwnProperty = Object.prototype.hasOwnProperty;
  for (var property in newPrototype) {
    if (hasOwnProperty.call(newPrototype, property)) {
      // Copy generated accessors.
      oldPrototype[property] = newPrototype[property];
    }
  }
  oldPrototype.__proto__ = newConstructor.prototype.__proto__;
  oldPrototype.constructor = newConstructor;
  newConstructor.prototype = oldPrototype;
  return newConstructor;
}''');
  }

  /// Used by incremental compilation to patch up an object ([holder]) with a
  /// new (or updated) method.  [arrayOrFunction] is either the new method, or
  /// an array containing the method (see
  /// [ContainerBuilder.addMemberMethodFromInfo]). [name] is the name of the
  /// new method. [isStatic] tells if method is static (or
  /// top-level). [globalFunctionsAccess] is a reference to
  /// [embeddedNames.GLOBAL_FUNCTIONS].
  jsAst.Fun buildIncrementalAddMethod() {
    if (!compiler.hasIncrementalSupport) return null;
    return js(r"""
function(originalDescriptor, name, holder, isStatic, globalFunctionsAccess) {
  var arrayOrFunction = originalDescriptor[name];
  var method;
  if (arrayOrFunction.constructor === Array) {
    var existing = holder[name];
    var array = arrayOrFunction;

    // Each method may have a number of stubs associated. For example, if an
    // instance method supports multiple arguments, a stub for each matching
    // selector. There is also a getter stub for tear-off getters. For example,
    // an instance method foo([a]) may have the following stubs: foo$0, foo$1,
    // and get$foo (here exemplified using unminified names).
    // [extractStubs] returns a JavaScript object whose own properties
    // corresponds to the stubs.
    var descriptor =
        this.extractStubs(array, name, isStatic, originalDescriptor);
    method = descriptor[name];

    // Iterate through the properties of descriptor and copy the stubs to the
    // existing holder (for instance methods, a prototype).
    for (var property in descriptor) {
      if (!Object.prototype.hasOwnProperty.call(descriptor, property)) continue;
      var stub = descriptor[property];
      var existingStub = holder[property];
      if (stub === method || !existingStub || !stub.$getterStub) {
        // Not replacing an existing getter stub.
        holder[property] = stub;
        continue;
      }
      if (!stub.$getterStub) {
        var error = new Error('Unexpected stub.');
        error.stub = stub;
        throw error;
      }

      // Existing getter stubs need special treatment as they may already have
      // been called and produced a closure.
      this.pendingStubs = this.pendingStubs || [];
      // It isn't safe to invoke the stub yet.
      this.pendingStubs.push((function(holder, stub, existingStub, existing,
                                       method) {
        return function() {
          var receiver = isStatic ? holder : new holder.constructor();
          // Invoke the existing stub to obtain the tear-off closure.
          existingStub = existingStub.call(receiver);
          // Invoke the new stub to create a tear-off closure we can use as a
          // prototype.
          stub = stub.call(receiver);

          // Copy the properties from the new tear-off's prototype to the
          // prototype of the existing tear-off.
          var newProto = stub.constructor.prototype;
          var existingProto = existingStub.constructor.prototype;
          for (var stubProperty in newProto) {
            if (!Object.prototype.hasOwnProperty.call(newProto, stubProperty))
              continue;
            existingProto[stubProperty] = newProto[stubProperty];
          }

          // Update all the existing stub's references to [existing] to
          // [method]. Instance tear-offs are call-by-name, so this isn't
          // necessary for those.
          if (!isStatic) return;
          for (var reference in existingStub) {
            if (existingStub[reference] === existing) {
              existingStub[reference] = method;
            }
          }
        }
      })(holder, stub, existingStub, existing, method));
    }
  } else {
    method = arrayOrFunction;
    holder[name] = method;
  }
  if (isStatic) globalFunctionsAccess[name] = method;
}""");
  }

  Map<OutputUnit, jsAst.Expression> buildDescriptorsForOutputUnits(
      Program program) {
    Map<OutputUnit, jsAst.Expression> outputs =
        new Map<OutputUnit, jsAst.Expression>();

    for (Fragment fragment in program.deferredFragments) {
      OutputUnit outputUnit = fragment.outputUnit;

      Map<Element, ClassBuilder> descriptors = elementDescriptors[fragment];

      if (descriptors != null && descriptors.isNotEmpty) {
        Iterable<LibraryElement> libraries = outputLibraryLists[outputUnit];
        if (libraries == null) libraries = [];

        // TODO(johnniwinther): Avoid creating [CodeBuffer]s.
        List<jsAst.Expression> parts = <jsAst.Expression>[];
        for (LibraryElement library in Elements.sortedByPosition(libraries)) {
          parts.add(generateLibraryDescriptor(library, fragment));
          descriptors.remove(library);
        }

        outputs[outputUnit] = new jsAst.ArrayInitializer(parts);
      }
    }

    return outputs;
  }

  void finalizeTokensInAst(jsAst.Program main,
                           Iterable<jsAst.Program> deferredParts) {
    jsAst.TokenCounter counter = new jsAst.TokenCounter();
    counter.countTokens(main);
    deferredParts.forEach(counter.countTokens);
    task.metadataCollector.finalizeTokens();
    if (backend.namer is jsAst.TokenFinalizer) {
      var finalizer = backend.namer;
      finalizer.finalizeTokens();
    }
  }

  int emitProgram(ProgramBuilder programBuilder) {
    Program program =
        programBuilder.buildProgram(storeFunctionTypesInMetadata: true);

    outputStaticNonFinalFieldLists =
        programBuilder.collector.outputStaticNonFinalFieldLists;
    outputLibraryLists = programBuilder.collector.outputLibraryLists;
    typedefsNeededForReflection =
       programBuilder.collector.typedefsNeededForReflection;

    assembleProgram(program);

    // Construct the ASTs for all deferred output units.
    Map<OutputUnit, jsAst.Program> deferredParts =
        buildOutputAstForDeferredCode(program);

    Map<OutputUnit, _DeferredOutputUnitHash> deferredHashTokens =
        new Map<OutputUnit, _DeferredOutputUnitHash>.fromIterables(
          deferredParts.keys,
          deferredParts.keys.map((OutputUnit unit) {
            return new _DeferredOutputUnitHash(unit);
          })
        );

    jsAst.Program mainOutput =
        buildOutputAstForMain(program, deferredHashTokens);

    finalizeTokensInAst(mainOutput, deferredParts.values);

    // Emit deferred units first, so we have their hashes.
    // Map from OutputUnit to a hash of its content. The hash uniquely
    // identifies the code of the output-unit. It does not include
    // boilerplate JS code, like the sourcemap directives or the hash
    // itself.
    Map<OutputUnit, String> deferredLoadHashes =
        emitDeferredOutputUnits(deferredParts);

    deferredHashTokens.forEach((OutputUnit key, _DeferredOutputUnitHash token) {
      token.setHash(deferredLoadHashes[key]);
    });
    emitMainOutputUnit(program.mainFragment.outputUnit, mainOutput);

    if (backend.requiresPreamble &&
        !backend.htmlLibraryIsLoaded) {
      compiler.reportHint(NO_LOCATION_SPANNABLE, MessageKind.PREAMBLE);
    }
    // Return the total program size.
    return outputBuffers.values.fold(0, (a, b) => a + b.length);
  }

  String generateSourceMapTag(Uri sourceMapUri, Uri fileUri) {
    if (sourceMapUri != null && fileUri != null) {
      String sourceMapFileName = relativize(fileUri, sourceMapUri, false);
      return '''

//# sourceMappingURL=$sourceMapFileName
''';
    }
    return '';
  }

  ClassBuilder getElementDescriptor(Element element, Fragment fragment) {
    Element owner = element.library;
    if (!element.isLibrary && !element.isTopLevel && !element.isNative) {
      // For static (not top level) elements, record their code in a buffer
      // specific to the class. For now, not supported for native classes and
      // native elements.
      ClassElement cls =
          element.enclosingClassOrCompilationUnit.declaration;
      if (compiler.codegenWorld.directlyInstantiatedClasses.contains(cls) &&
          !cls.isNative &&
          compiler.deferredLoadTask.outputUnitForElement(element) ==
              compiler.deferredLoadTask.outputUnitForElement(cls)) {
        owner = cls;
      }
    }
    if (owner == null) {
      compiler.internalError(element, 'Owner is null.');
    }
    return elementDescriptors
        .putIfAbsent(fragment, () => new Map<Element, ClassBuilder>())
        .putIfAbsent(owner, () {
          return new ClassBuilder(owner, namer, owner.isClass);
        });
  }

  /// Emits support-code for deferred loading into [output].
  jsAst.Statement buildDeferredBoilerPlate(
      Map<OutputUnit, _DeferredOutputUnitHash> deferredLoadHashes) {
    List<jsAst.Statement> parts = <jsAst.Statement>[];

    parts.add(js.statement('''
        {
          // Function for checking if a hunk is loaded given its hash.
          #isHunkLoaded = function(hunkHash) {
            return !!$deferredInitializers[hunkHash];
          };
          #deferredInitialized = new Object(null);
          // Function for checking if a hunk is initialized given its hash.
          #isHunkInitialized = function(hunkHash) {
            return #deferredInitialized[hunkHash];
          };
          // Function for initializing a loaded hunk, given its hash.
          #initializeLoadedHunk = function(hunkHash) {
            $deferredInitializers[hunkHash](
            #globalsHolder, ${namer.staticStateHolder});
            #deferredInitialized[hunkHash] = true;
          };
        }
        ''', {"globalsHolder": globalsHolder,
              "isHunkLoaded": generateEmbeddedGlobalAccess(
                  embeddedNames.IS_HUNK_LOADED),
              "isHunkInitialized": generateEmbeddedGlobalAccess(
                  embeddedNames.IS_HUNK_INITIALIZED),
              "initializeLoadedHunk": generateEmbeddedGlobalAccess(
                  embeddedNames.INITIALIZE_LOADED_HUNK),
              "deferredInitialized": generateEmbeddedGlobalAccess(
                  embeddedNames.DEFERRED_INITIALIZED)}));

    // Write a javascript mapping from Deferred import load ids (derrived
    // from the import prefix.) to a list of lists of uris of hunks to load,
    // and a corresponding mapping to a list of hashes used by
    // INITIALIZE_LOADED_HUNK and IS_HUNK_LOADED.
    Map<String, List<jsAst.LiteralString>> deferredLibraryUris =
        new Map<String, List<jsAst.LiteralString>>();
    Map<String, List<_DeferredOutputUnitHash>> deferredLibraryHashes =
        new Map<String, List<_DeferredOutputUnitHash>>();
    compiler.deferredLoadTask.hunksToLoad.forEach(
                  (String loadId, List<OutputUnit>outputUnits) {
      List<jsAst.LiteralString> uris = new List<jsAst.LiteralString>();
      List<_DeferredOutputUnitHash> hashes =
          new List<_DeferredOutputUnitHash>();
      deferredLibraryHashes[loadId] = new List<_DeferredOutputUnitHash>();
      for (OutputUnit outputUnit in outputUnits) {
        uris.add(js.escapedString(
            backend.deferredPartFileName(outputUnit.name)));
        hashes.add(deferredLoadHashes[outputUnit]);
      }

      deferredLibraryUris[loadId] = uris;
      deferredLibraryHashes[loadId] = hashes;
    });

    void emitMapping(String name, Map<String, List<jsAst.Expression>> mapping) {
      List<jsAst.Property> properties = new List<jsAst.Property>();
      mapping.forEach((String key, List<jsAst.Expression> values) {
        properties.add(new jsAst.Property(js.escapedString(key),
            new jsAst.ArrayInitializer(values)));
      });
      jsAst.Node initializer =
          new jsAst.ObjectInitializer(properties, isOneLiner: true);

      jsAst.Node globalName = generateEmbeddedGlobalAccess(name);
      parts.add(js.statement("# = #", [globalName, initializer]));
    }

    emitMapping(embeddedNames.DEFERRED_LIBRARY_URIS, deferredLibraryUris);
    emitMapping(embeddedNames.DEFERRED_LIBRARY_HASHES,
                deferredLibraryHashes);

    return new jsAst.Block(parts);
  }

  Map <OutputUnit, jsAst.Program> buildOutputAstForDeferredCode(
      Program program) {
    if (!program.isSplit) return const <OutputUnit, jsAst.Program>{};

    Map<OutputUnit, jsAst.Program> result =
        new Map<OutputUnit, jsAst.Program>();

    Map<OutputUnit, jsAst.Expression> deferredAsts =
        buildDescriptorsForOutputUnits(program);

    for (Fragment fragment in program.deferredFragments) {
      OutputUnit outputUnit = fragment.outputUnit;
      jsAst.Expression libraryDescriptor = deferredAsts[outputUnit];
      List<jsAst.Statement> body = <jsAst.Statement>[];

      // No renaming in the top-level function to save the locals for the
      // nested context where they will be used more.
      body.add(js.comment("/* ::norenaming:: "));

      for (String globalObject in Namer.reservedGlobalObjectNames) {
        body.add(js.statement('var #object = #globalsHolder.#object;',
                              {'globalsHolder': globalsHolder,
                               'object': globalObject}));
      }
      body..add(js.statement('var init = #globalsHolder.init;',
                             {'globalsHolder': globalsHolder}))
          ..add(js.statement('var $setupProgramName = '
                             '#globalsHolder.$setupProgramName;',
                             {'globalsHolder': globalsHolder}))
          ..add(js.statement('var ${namer.isolateName} = '
                             '#globalsHolder.${namer.isolateName};',
                             {'globalsHolder': globalsHolder}));
      String typesAccess =
          generateEmbeddedGlobalAccessString(embeddedNames.TYPES);
      if (libraryDescriptor != null) {
        // The argument to reflectionDataParser is assigned to a temporary
        // 'dart' so that 'dart.' will appear as the prefix to dart methods
        // in stack traces and profile entries.
        body.add(js.statement('var dart = #', libraryDescriptor));

        if (compiler.useContentSecurityPolicy) {
          body.add(buildCspPrecompiledFunctionFor(outputUnit));
        }
        body.add(
            js.statement('$setupProgramName(dart, ${typesAccess}.length);'));
      }

      body..add(buildMetadata(program, outputUnit))
          ..add(js.statement('${typesAccess}.push.apply(${typesAccess}, '
                             '${namer.deferredTypesName});'));

      // Sets the static state variable to the state of the current isolate
      // (which is provided as second argument).
      body.add(js.statement("${namer.staticStateHolder} = arguments[1];"));

      body.add(buildCompileTimeConstants(fragment.constants,
                                         isMainFragment: false));
      body.add(buildStaticNonFinalFieldInitializations(outputUnit));

      List<jsAst.Statement> statements = <jsAst.Statement>[];

      statements
          ..add(buildGeneratedBy())
          ..add(js.statement('${deferredInitializers}.current = '
                             """function (#) {
                                  #
                                }
                             """, [globalsHolder, body]));

      result[outputUnit] = new jsAst.Program(statements);
    }

    return result;
  }

  /// Returns a map from OutputUnit to a hash of its content. The hash uniquely
  /// identifies the code of the output-unit. It does not include
  /// boilerplate JS code, like the sourcemap directives or the hash
  /// itself.
  Map<OutputUnit, String> emitDeferredOutputUnits(
      Map<OutputUnit, jsAst.Program> outputAsts) {

    Map<OutputUnit, String> hunkHashes = new Map<OutputUnit, String>();

    for (OutputUnit outputUnit in outputAsts.keys) {
      List<CodeOutputListener> outputListeners = <CodeOutputListener>[];
      Hasher hasher = new Hasher();
      outputListeners.add(hasher);

      LineColumnCollector lineColumnCollector;
      if (generateSourceMap) {
        lineColumnCollector = new LineColumnCollector();
        outputListeners.add(lineColumnCollector);
      }

      String partPrefix =
          backend.deferredPartFileName(outputUnit.name, addExtension: false);
      CodeOutput output = new StreamCodeOutput(
          compiler.outputProvider(partPrefix, 'part.js'),
          outputListeners);

      outputBuffers[outputUnit] = output;

      output.addBuffer(jsAst.prettyPrint(outputAsts[outputUnit],
                                         compiler,
                                         monitor: compiler.dumpInfoTask));

      // Make a unique hash of the code (before the sourcemaps are added)
      // This will be used to retrieve the initializing function from the global
      // variable.
      String hash = hasher.getHash();

      output.add('$N${deferredInitializers}["$hash"]$_=$_'
                       '${deferredInitializers}.current$N');

      if (generateSourceMap) {
        Uri mapUri, partUri;
        Uri sourceMapUri = compiler.sourceMapUri;
        Uri outputUri = compiler.outputUri;

        String partName = "$partPrefix.part";

        if (sourceMapUri != null) {
          String mapFileName = partName + ".js.map";
          List<String> mapSegments = sourceMapUri.pathSegments.toList();
          mapSegments[mapSegments.length - 1] = mapFileName;
          mapUri = compiler.sourceMapUri.replace(pathSegments: mapSegments);
        }

        if (outputUri != null) {
          String partFileName = partName + ".js";
          List<String> partSegments = outputUri.pathSegments.toList();
          partSegments[partSegments.length - 1] = partFileName;
          partUri = compiler.outputUri.replace(pathSegments: partSegments);
        }

        output.add(generateSourceMapTag(mapUri, partUri));
        output.close();
        outputSourceMap(output, lineColumnCollector, partName,
                        mapUri, partUri);
      } else {
        output.close();
      }

      hunkHashes[outputUnit] = hash;
    }
    return hunkHashes;
  }

  jsAst.Comment buildGeneratedBy() {
    String suffix = '';
    if (compiler.hasBuildId) suffix = ' version: ${compiler.buildId}';
    String msg = '// Generated by dart2js, the Dart to JavaScript '
                 'compiler$suffix.';
    return new jsAst.Comment(msg);
  }

  void outputSourceMap(CodeOutput output,
                       LineColumnProvider lineColumnProvider,
                       String name,
                       [Uri sourceMapUri,
                        Uri fileUri]) {
    if (!generateSourceMap) return;
    // Create a source file for the compilation output. This allows using
    // [:getLine:] to transform offsets to line numbers in [SourceMapBuilder].
    SourceMapBuilder sourceMapBuilder =
            new SourceMapBuilder(sourceMapUri, fileUri, lineColumnProvider);
    output.forEachSourceLocation(sourceMapBuilder.addMapping);
    String sourceMap = sourceMapBuilder.build();
    compiler.outputProvider(name, 'js.map')
        ..add(sourceMap)
        ..close();
  }

  void outputDeferredMap() {
    Map<String, dynamic> mapping = new Map<String, dynamic>();
    // Json does not support comments, so we embed the explanation in the
    // data.
    mapping["_comment"] = "This mapping shows which compiled `.js` files are "
        "needed for a given deferred library import.";
    mapping.addAll(compiler.deferredLoadTask.computeDeferredMap());
    compiler.outputProvider(compiler.deferredMapUri.path, 'deferred_map')
        ..add(const JsonEncoder.withIndent("  ").convert(mapping))
        ..close();
  }

  void invalidateCaches() {
    if (!compiler.hasIncrementalSupport) return;
    if (cachedElements.isEmpty) return;
    for (Element element in compiler.enqueuer.codegen.newlyEnqueuedElements) {
      if (element.isInstanceMember) {
        cachedClassBuilders.remove(element.enclosingClass);

        nativeEmitter.cachedBuilders.remove(element.enclosingClass);

      }
    }
  }
}
