// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.lazy_emitter.model_emitter;

import 'package:js_runtime/shared/embedded_names.dart'
    show
        CREATE_NEW_ISOLATE,
        DEFERRED_LIBRARY_URIS,
        DEFERRED_LIBRARY_HASHES,
        GET_TYPE_FROM_NAME,
        INITIALIZE_LOADED_HUNK,
        INTERCEPTORS_BY_TAG,
        IS_HUNK_INITIALIZED,
        IS_HUNK_LOADED,
        LEAF_TAGS,
        MANGLED_GLOBAL_NAMES,
        METADATA,
        TYPE_TO_INTERCEPTOR_MAP,
        TYPES;

import '../../../compiler_new.dart';
import '../../compiler.dart' show Compiler;
import '../../constants/values.dart' show ConstantValue, FunctionConstantValue;
import '../../common_elements.dart' show CommonElements;
import '../../elements/elements.dart' show ClassElement, MethodElement;
import '../../js/js.dart' as js;
import '../../js_backend/js_backend.dart'
    show JavaScriptBackend, Namer, ConstantEmitter;
import '../../js_backend/interceptor_data.dart';
import '../../world.dart';
import '../constant_ordering.dart' show deepCompareConstants;
import '../code_emitter_task.dart';
import '../js_emitter.dart' show NativeEmitter;
import '../js_emitter.dart' show NativeGenerator, buildTearOffCode;
import '../model.dart';

class ModelEmitter {
  final Compiler compiler;
  final Namer namer;
  ConstantEmitter constantEmitter;
  final NativeEmitter nativeEmitter;
  final ClosedWorld _closedWorld;

  JavaScriptBackend get backend => compiler.backend;

  /// For deferred loading we communicate the initializers via this global var.
  static const String deferredInitializersGlobal =
      r"$__dart_deferred_initializers__";

  static const String deferredExtension = "part.js";

  static const String typeNameProperty = r"builtin$cls";

  ModelEmitter(this.compiler, this.namer, this.nativeEmitter, this._closedWorld,
      CodeEmitterTask task) {
    this.constantEmitter = new ConstantEmitter(
        compiler.options,
        _closedWorld.commonElements,
        compiler.codegenWorldBuilder,
        compiler.backend.rtiNeed,
        compiler.backend.rtiEncoder,
        namer,
        task,
        this.generateConstantReference,
        constantListGenerator);
  }

  InterceptorData get _interceptorData => _closedWorld.interceptorData;

  js.Expression constantListGenerator(js.Expression array) {
    // TODO(floitsch): remove hard-coded name.
    return js.js('makeConstList(#)', [array]);
  }

  js.Expression generateEmbeddedGlobalAccess(String global) {
    return js.js(generateEmbeddedGlobalAccessString(global));
  }

  String generateEmbeddedGlobalAccessString(String global) {
    // TODO(floitsch): don't use 'init' as global embedder storage.
    return 'init.$global';
  }

  bool isConstantInlinedOrAlreadyEmitted(ConstantValue constant) {
    if (constant.isFunction) return true; // Already emitted.
    if (constant.isPrimitive) return true; // Inlined.
    if (constant.isDummy) return true; // Inlined.
    // The name is null when the constant is already a JS constant.
    // TODO(floitsch): every constant should be registered, so that we can
    // share the ones that take up too much space (like some strings).
    if (namer.constantName(constant) == null) return true;
    return false;
  }

  // TODO(floitsch): copied from full emitter. Adjust or share.
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

    // Resolve collisions in the long name by using a structural order.
    return deepCompareConstants(a, b);
  }

  js.Expression generateStaticClosureAccess(MethodElement element) {
    return js.js('#.#()', [
      namer.globalObjectForMember(element),
      namer.staticClosureName(element)
    ]);
  }

  js.Expression generateConstantReference(ConstantValue value) {
    if (value.isFunction) {
      FunctionConstantValue functionConstant = value;
      return generateStaticClosureAccess(functionConstant.element);
    }

    // We are only interested in the "isInlined" part, but it does not hurt to
    // test for the other predicates.
    if (isConstantInlinedOrAlreadyEmitted(value)) {
      return constantEmitter.generate(value);
    }
    return js.js('#.#()',
        [namer.globalObjectForConstant(value), namer.constantName(value)]);
  }

  int emitProgram(Program program) {
    List<Fragment> fragments = program.fragments;
    MainFragment mainFragment = fragments.first;
    Iterable<Fragment> deferredFragments = program.deferredFragments;

    int totalSize = 0;

    // We have to emit the deferred fragments first, since we need their
    // deferred hash (which depends on the output) when emitting the main
    // fragment.
    List<js.Expression> fragmentsCode = deferredFragments.map((deferredUnit) {
      js.Expression types =
          program.metadataTypesForOutputUnit(deferredUnit.outputUnit);
      return emitDeferredFragment(types, deferredUnit, program.holders);
    }).toList();

    js.Statement mainAst = emitMainFragment(program);

    js.TokenCounter counter = new js.TokenCounter();
    fragmentsCode.forEach(counter.countTokens);
    counter.countTokens(mainAst);

    program.finalizers.forEach((js.TokenFinalizer f) => f.finalizeTokens());

    // TODO(johnniwinther): Support source maps in this emitter.
    for (int i = 0; i < fragmentsCode.length; ++i) {
      String code = js
          .createCodeBuffer(fragmentsCode[i], compiler.options,
              backend.sourceInformationStrategy)
          .getText();
      totalSize += code.length;
      compiler.outputProvider(
          fragments[i + 1].outputFileName, deferredExtension, OutputType.jsPart)
        ..add(code)
        ..close();
    }

    String mainCode = js
        .createCodeBuffer(
            mainAst, compiler.options, backend.sourceInformationStrategy)
        .getText();
    compiler.outputProvider(mainFragment.outputFileName, 'js', OutputType.js)
      ..add(buildGeneratedBy(compiler))
      ..add(mainCode)
      ..close();
    totalSize += mainCode.length;

    return totalSize;
  }

  /// Returns a [js.Literal] that represents the string result of unparsing
  /// [value].
  ///
  /// The returned node will, when its string value is requested, pretty-print
  /// the given [value] and, if [protectForEval] is true, wrap the resulting
  /// string in parenthesis. The result is also escaped.
  ///
  /// See [_UnparsedNode] for details.
  js.Literal unparse(Compiler compiler, js.Node value,
      {bool protectForEval: true}) {
    return new js.UnparsedNode(value, compiler.options, protectForEval);
  }

  String buildGeneratedBy(compiler) {
    var suffix = '';
    if (compiler.options.hasBuildId) {
      suffix = ' version: ${compiler.options.buildId}';
    }
    return '// Generated by dart2js, the Dart to JavaScript compiler$suffix.\n';
  }

  js.Statement emitMainFragment(Program program) {
    MainFragment fragment = program.fragments.first;
    List<js.Expression> elements = fragment.libraries.map(emitLibrary).toList();
    elements.add(
        emitLazilyInitializedStatics(fragment.staticLazilyInitializedFields));
    elements.add(emitConstants(fragment.constants));

    js.Expression code = new js.ArrayInitializer(elements);

    Map<String, dynamic> holes = {
      'deferredInitializer': emitDeferredInitializerGlobal(program.loadMap),
      'holders': emitHolders(program.holders),
      'tearOff': buildTearOffCode(compiler.options, backend.emitter.emitter,
          backend.namer, _closedWorld.commonElements),
      'parseFunctionDescriptor':
          js.js.statement(parseFunctionDescriptorBoilerplate, {
        'argumentCount': js.string(namer.requiredParameterField),
        'defaultArgumentValues': js.string(namer.defaultValuesField),
        'callName': js.string(namer.callNameField)
      }),
      'cyclicThrow': backend.emitter
          .staticFunctionAccess(_closedWorld.commonElements.cyclicThrowHelper),
      'outputContainsConstantList': program.outputContainsConstantList,
      'embeddedGlobals': emitEmbeddedGlobals(program),
      'readMetadataTypeFunction': readMetadataTypeFunction,
      'staticNonFinals':
          emitStaticNonFinalFields(fragment.staticNonFinalFields),
      'operatorIsPrefix': js.string(namer.operatorIsPrefix),
      'callName': js.string(namer.callNameField),
      'argumentCount': js.string(namer.requiredParameterField),
      'defaultArgumentValues': js.string(namer.defaultValuesField),
      'eagerClasses': emitEagerClassInitializations(fragment.libraries),
      'invokeMain': fragment.invokeMain,
      'code': code
    };

    holes.addAll(nativeHoles(program));

    return js.js.statement(boilerplate, holes);
  }

  Map<String, dynamic> nativeHoles(Program program) {
    Map<String, dynamic> nativeHoles = <String, dynamic>{};

    js.Statement nativeIsolateAffinityTagInitialization;
    if (NativeGenerator
        .needsIsolateAffinityTagInitialization(_closedWorld.backendUsage)) {
      nativeIsolateAffinityTagInitialization =
          NativeGenerator.generateIsolateAffinityTagInitialization(
              _closedWorld.backendUsage,
              generateEmbeddedGlobalAccess,
              // TODO(floitsch): internStringFunction.
              js.js("(function(x) { return x; })", []));
    } else {
      nativeIsolateAffinityTagInitialization = js.js.statement(";");
    }
    nativeHoles['nativeIsolateAffinityTagInitialization'] =
        nativeIsolateAffinityTagInitialization;

    js.Expression nativeInfoAccess = js.js('nativeInfo', []);
    js.Expression constructorAccess = js.js('constructor', []);
    Function subclassReadGenerator = (js.Expression subclass) {
      return js.js('holdersMap[#][#].ensureResolved()', [subclass, subclass]);
    };
    js.Expression interceptorsByTagAccess =
        generateEmbeddedGlobalAccess(INTERCEPTORS_BY_TAG);
    js.Expression leafTagsAccess = generateEmbeddedGlobalAccess(LEAF_TAGS);
    js.Statement nativeInfoHandler = NativeGenerator.buildNativeInfoHandler(
        nativeInfoAccess,
        constructorAccess,
        subclassReadGenerator,
        interceptorsByTagAccess,
        leafTagsAccess);

    nativeHoles['needsNativeSupport'] = program.needsNativeSupport;
    nativeHoles['needsNoNativeSupport'] = !program.needsNativeSupport;
    nativeHoles['nativeInfoHandler'] = nativeInfoHandler;

    return nativeHoles;
  }

  js.Block emitHolders(List<Holder> holders) {
    // The top-level variables for holders must *not* be renamed by the
    // JavaScript pretty printer because a lot of code already uses the
    // non-renamed names. The generated code looks like this:
    //
    //    var H = {}, ..., G = {};
    //    var holders = [ H, ..., G ];
    //
    // and it is inserted at the top of the top-level function expression
    // that covers the entire program.

    List<js.Statement> statements = [
      new js.ExpressionStatement(new js.VariableDeclarationList(holders
          .map((e) => new js.VariableInitialization(
              new js.VariableDeclaration(e.name, allowRename: false),
              new js.ObjectInitializer(const [])))
          .toList())),
      js.js.statement(
          'var holders = #',
          new js.ArrayInitializer(holders
              .map((e) => new js.VariableUse(e.name))
              .toList(growable: false))),
      js.js.statement('var holdersMap = Object.create(null)')
    ];
    return new js.Block(statements);
  }

  js.Block emitEmbeddedGlobals(Program program) {
    List<js.Property> globals = <js.Property>[];

    if (program.loadMap.isNotEmpty) {
      globals.addAll(emitEmbeddedGlobalsForDeferredLoading(program.loadMap));
    }

    if (program.typeToInterceptorMap != null) {
      globals.add(new js.Property(
          js.string(TYPE_TO_INTERCEPTOR_MAP), program.typeToInterceptorMap));
    }

    if (program.hasIsolateSupport) {
      String isolateName = namer.staticStateHolder;
      globals.add(new js.Property(js.string(CREATE_NEW_ISOLATE),
          js.js('function () { return $isolateName; }')));
      // TODO(floitsch): add remaining isolate functions.
    }

    globals.add(emitMangledGlobalNames());

    globals.add(emitGetTypeFromName());

    globals.addAll(emitMetadata(program));

    if (program.needsNativeSupport) {
      globals.add(new js.Property(
          js.string(INTERCEPTORS_BY_TAG), js.js('Object.create(null)', [])));
      globals.add(new js.Property(
          js.string(LEAF_TAGS), js.js('Object.create(null)', [])));
    }

    js.ObjectInitializer globalsObject = new js.ObjectInitializer(globals);

    List<js.Statement> statements = [
      new js.ExpressionStatement(new js.VariableDeclarationList([
        new js.VariableInitialization(
            new js.VariableDeclaration("init", allowRename: false),
            globalsObject)
      ]))
    ];
    return new js.Block(statements);
  }

  js.Property emitMangledGlobalNames() {
    List<js.Property> names = <js.Property>[];

    CommonElements commonElements = _closedWorld.commonElements;
    // We want to keep the original names for the most common core classes when
    // calling toString on them.
    List<ClassElement> nativeClassesNeedingUnmangledName = [
      commonElements.intClass,
      commonElements.doubleClass,
      commonElements.numClass,
      commonElements.stringClass,
      commonElements.boolClass,
      commonElements.nullClass,
      commonElements.listClass
    ];
    nativeClassesNeedingUnmangledName.forEach((element) {
      names.add(new js.Property(
          js.quoteName(namer.className(element)), js.string(element.name)));
    });

    return new js.Property(
        js.string(MANGLED_GLOBAL_NAMES), new js.ObjectInitializer(names));
  }

  js.Statement emitDeferredInitializerGlobal(Map loadMap) {
    if (loadMap.isEmpty) return new js.Block.empty();

    return js.js.statement("""
  if (typeof($deferredInitializersGlobal) === 'undefined')
    var $deferredInitializersGlobal = Object.create(null);""");
  }

  Iterable<js.Property> emitEmbeddedGlobalsForDeferredLoading(
      Map<String, List<Fragment>> loadMap) {
    List<js.Property> globals = <js.Property>[];

    js.ArrayInitializer fragmentUris(List<Fragment> fragments) {
      return js.stringArray(fragments
          .map((fragment) => "${fragment.outputFileName}.$deferredExtension"));
    }

    js.ArrayInitializer fragmentHashes(List<Fragment> fragments) {
      // TODO(floitsch): the hash must depend on the generated code.
      return js.numArray(fragments.map((fragment) => fragment.hashCode));
    }

    List<js.Property> uris = new List<js.Property>(loadMap.length);
    List<js.Property> hashes = new List<js.Property>(loadMap.length);
    int count = 0;
    loadMap.forEach((String loadId, List<Fragment> fragmentList) {
      uris[count] =
          new js.Property(js.string(loadId), fragmentUris(fragmentList));
      hashes[count] =
          new js.Property(js.string(loadId), fragmentHashes(fragmentList));
      count++;
    });

    globals.add(new js.Property(
        js.string(DEFERRED_LIBRARY_URIS), new js.ObjectInitializer(uris)));
    globals.add(new js.Property(
        js.string(DEFERRED_LIBRARY_HASHES), new js.ObjectInitializer(hashes)));

    js.Expression isHunkLoadedFunction =
        js.js("function(hash) { return !!$deferredInitializersGlobal[hash]; }");
    globals
        .add(new js.Property(js.string(IS_HUNK_LOADED), isHunkLoadedFunction));

    js.Expression isHunkInitializedFunction =
        js.js("function(hash) { return false; }");
    globals.add(new js.Property(
        js.string(IS_HUNK_INITIALIZED), isHunkInitializedFunction));

    js.Expression typesAccess = generateEmbeddedGlobalAccess(TYPES);

    /// See [emitEmbeddedGlobalsForDeferredLoading] for the format of the
    /// deferred hunk.
    js.Expression initializeLoadedHunkFunction = js.js(
        """
          function(hash) {
            var hunk = $deferredInitializersGlobal[hash];
            $setupProgramName(hunk[0], #typesAccess.length);
            eval(hunk[1]);
            var deferredTypes = eval(hunk[2]);
            #typesAccess.push.apply(#typesAccess, deferredTypes);
          }""",
        {'typesAccess': typesAccess});

    globals.add(new js.Property(
        js.string(INITIALIZE_LOADED_HUNK), initializeLoadedHunkFunction));

    return globals;
  }

  js.Property emitGetTypeFromName() {
    js.Expression function = js.js("""function(name) {
                    return holdersMap[name][name].ensureResolved();
                  }""");
    return new js.Property(js.string(GET_TYPE_FROM_NAME), function);
  }

  static final String readMetadataTypeName = "readMetadataType";

  js.Statement get readMetadataTypeFunction {
    // Types are non-evaluated and must be compiled at first use.
    // Compiled strings are guaranteed not to be strings, and it's thus safe
    // to use a type-test to determine if a type has already been compiled.
    return js.js.statement(
        '''function $readMetadataTypeName(index) {
      var type = #typesAccess[index];
      if (typeof type == 'string') {
        type = expressionCompile(type);
        #typesAccess[index] = type;
      }
      return type;
    }''',
        {"typesAccess": generateEmbeddedGlobalAccess(TYPES)});
  }

  js.Template get templateForReadType {
    // TODO(floitsch): make sure that no local variable shadows the access to
    // the readMetadataType function.
    return js.js.expressionTemplateFor('$readMetadataTypeName(#)');
  }

  static final String readMetadataName = "readLazyMetadata";
  static final String lazyMetadataName = "lazy_$METADATA";

  js.Statement get readMetadataFunction {
    // Types are non-evaluated and must be compiled at first use.
    // Compiled strings are guaranteed not to be strings, and it's thus safe
    // to use a type-test to determine if a type has already been compiled.
    return js.js.statement(
        '''function $readMetadataName(index) {
      var lazyMetadata = #lazyMetadataAccess[index];
      if (typeof lazyMetadata == 'string') {
        #metadataAccess[index] = expressionCompile(lazyMetadata);
        #lazyMetadataAccess[index] = null;
      }
      return #metadataAccess[index];
    }''',
        {
          "lazyMetadataAccess": generateEmbeddedGlobalAccess(lazyMetadataName),
          "metadataAccess": generateEmbeddedGlobalAccess(METADATA)
        });
  }

  js.Template get templateForReadMetadata {
    // TODO(floitsch): make sure that no local variable shadows the access to
    // the readMetadata function.
    return js.js.expressionTemplateFor('$readMetadataName(#)');
  }

  List<js.Property> emitMetadata(Program program) {
    List<js.Property> metadataGlobals = <js.Property>[];

    js.Property createGlobal(js.Expression metadata, String global) {
      return new js.Property(js.string(global), metadata);
    }

    metadataGlobals.add(createGlobal(program.metadata, METADATA));
    js.Expression types =
        program.metadataTypesForOutputUnit(program.mainFragment.outputUnit);
    metadataGlobals.add(createGlobal(types, TYPES));

    return metadataGlobals;
  }

  js.Expression emitDeferredFragment(js.Expression deferredTypes,
      DeferredFragment fragment, List<Holder> holders) {
    // TODO(floitsch): initialize eager classes.
    // TODO(floitsch): the hash must depend on the output.
    int hash = fragment.hashCode;

    List<js.Expression> deferredCode =
        fragment.libraries.map(emitLibrary).toList();

    deferredCode.add(
        emitLazilyInitializedStatics(fragment.staticLazilyInitializedFields));
    deferredCode.add(emitConstants(fragment.constants));

    js.ArrayInitializer deferredArray = new js.ArrayInitializer(deferredCode);

    // This is the code that must be evaluated after all deferred classes have
    // been setup.
    js.Statement immediateCode = new js.Block([
      emitStaticNonFinalFields(fragment.staticNonFinalFields),
      emitEagerClassInitializations(fragment.libraries)
    ]);

    js.Literal immediateString = unparse(compiler, immediateCode);

    js.ArrayInitializer hunk = new js.ArrayInitializer(
        [deferredArray, immediateString, deferredTypes]);

    return js.js("$deferredInitializersGlobal[$hash] = #", hunk);
  }

  // This string should be referenced wherever JavaScript code makes assumptions
  // on the constants format.
  static final String constantsDescription =
      "The constants are encoded as a follows:"
      "   [constantsHolderIndex, name, code, name2, code2, ...]."
      "The array is completely empty if there is no constant at all.";

  js.ArrayInitializer emitConstants(List<Constant> constants) {
    List<js.Expression> data = <js.Expression>[];
    if (constants.isNotEmpty) {
      int holderIndex = constants.first.holder.index;
      data.add(js.number(holderIndex));
      data.addAll(constants.expand((Constant constant) {
        assert(constant.holder.index == holderIndex);
        js.Expression code = constantEmitter.generate(constant.value);
        return [js.quoteName(constant.name), unparse(compiler, code)];
      }));
    }
    return new js.ArrayInitializer(data);
  }

  js.Block emitStaticNonFinalFields(List<StaticField> fields) {
    Iterable<js.Statement> statements = fields.map((StaticField field) {
      return js.js
          .statement("#.# = #;", [field.holder.name, field.name, field.code]);
    });
    return new js.Block(statements.toList());
  }

  js.Expression emitLazilyInitializedStatics(List<StaticField> fields) {
    Iterable fieldDescriptors = fields.expand((field) => [
          js.quoteName(field.name),
          js.quoteName(namer.deriveLazyInitializerName(field.name)),
          js.number(field.holder.index),
          emitLazyInitializer(field)
        ]);
    return new js.ArrayInitializer(fieldDescriptors.toList(growable: false));
  }

  js.Block emitEagerClassInitializations(List<Library> libraries) {
    js.Statement createInstantiation(Class cls) {
      return js.js.statement('new #.#()', [cls.holder.name, cls.name]);
    }

    List<js.Statement> instantiations = libraries
        .expand((Library library) => library.classes)
        .where((Class cls) => cls.isEager)
        .map(createInstantiation)
        .toList(growable: false);
    return new js.Block(instantiations);
  }

  // This string should be referenced wherever JavaScript code makes assumptions
  // on the mixin format.
  static final String nativeInfoDescription = "A class is encoded as follows:"
      "   [name, class-code, holder-index], or "
      "   [name, class-code, native-info, holder-index].";

  js.Expression emitLibrary(Library library) {
    Iterable staticDescriptors = library.statics.expand(emitStaticMethod);

    Iterable classDescriptors = library.classes.expand((Class cls) {
      js.Literal name = js.quoteName(cls.name);
      js.LiteralNumber holderIndex = js.number(cls.holder.index);
      js.Expression emittedClass = emitClass(cls);
      js.Expression nativeInfo = NativeGenerator.encodeNativeInfo(cls);
      if (nativeInfo == null) {
        return [name, emittedClass, holderIndex];
      } else {
        return [name, emittedClass, nativeInfo, holderIndex];
      }
    });

    js.Expression staticArray =
        new js.ArrayInitializer(staticDescriptors.toList(growable: false));
    js.Expression classArray =
        new js.ArrayInitializer(classDescriptors.toList(growable: false));

    return new js.ArrayInitializer([staticArray, classArray]);
  }

  js.Expression _generateConstructor(Class cls) {
    List<js.Name> fieldNames = const <js.Name>[];

    // If the class is not directly instantiated we only need it for inheritance
    // or RTI. In either case we don't need its fields.
    if (cls.isDirectlyInstantiated && !cls.isNative) {
      fieldNames = cls.fields.map((Field field) => field.name).toList();
      if (cls.hasRtiField) {
        fieldNames.add(namer.rtiFieldJsName);
      }
    }
    js.Name name = cls.name;

    Iterable<js.Name> assignments = fieldNames.map((js.Name field) {
      return js.js("this.#field = #field", {"field": field});
    });

    return js.js('function #(#) { # }', [name, fieldNames, assignments]);
  }

  Method _generateGetter(Field field) {
    String getterTemplateFor(int flags) {
      switch (flags) {
        case 1:
          return "function() { return this[#]; }";
        case 2:
          return "function(receiver) { return receiver[#]; }";
        case 3:
          return "function(receiver) { return this[#]; }";
      }
      return null;
    }

    js.Expression fieldName = js.quoteName(field.name);
    js.Expression code = js.js(getterTemplateFor(field.getterFlags), fieldName);
    js.Name getterName = namer.deriveGetterName(field.accessorName);
    return new StubMethod(getterName, code);
  }

  Method _generateSetter(Field field) {
    String setterTemplateFor(int flags) {
      switch (flags) {
        case 1:
          return "function(val) { return this[#] = val; }";
        case 2:
          return "function(receiver, val) { return receiver[#] = val; }";
        case 3:
          return "function(receiver, val) { return this[#] = val; }";
      }
      return null;
    }

    js.Expression fieldName = js.quoteName(field.name);
    js.Expression code = js.js(setterTemplateFor(field.setterFlags), fieldName);
    js.Name setterName = namer.deriveSetterName(field.accessorName);
    return new StubMethod(setterName, code);
  }

  Iterable<Method> _generateGettersSetters(Class cls) {
    Iterable<Method> getters = cls.fields
        .where((Field field) => field.needsGetter)
        .map(_generateGetter);

    Iterable<Method> setters = cls.fields
        .where((Field field) => field.needsUncheckedSetter)
        .map(_generateSetter);

    return [getters, setters].expand((x) => x);
  }

  // This string should be referenced wherever JavaScript code makes assumptions
  // on the mixin format.
  static final String mixinFormatDescription =
      "Mixins have a reference to their mixin class at the place of the usual"
      "constructor. If they are instantiated the constructor follows the"
      "reference.";

  js.Expression emitClass(Class cls) {
    List elements = [
      js.quoteName(cls.superclassName, allowNull: true),
      js.number(cls.superclassHolderIndex)
    ];

    if (cls.isMixinApplication) {
      MixinApplication mixin = cls;
      elements.add(js.quoteName(mixin.mixinClass.name));
      elements.add(js.number(mixin.mixinClass.holder.index));
      if (cls.isDirectlyInstantiated) {
        elements.add(_generateConstructor(cls));
      }
    } else {
      elements.add(_generateConstructor(cls));
    }
    Iterable<Method> methods = cls.methods;
    Iterable<Method> isChecks = cls.isChecks;
    Iterable<Method> callStubs = cls.callStubs;
    Iterable<Method> noSuchMethodStubs = cls.noSuchMethodStubs;
    Iterable<Method> gettersSetters = _generateGettersSetters(cls);
    Iterable<Method> allMethods = [
      methods,
      isChecks,
      callStubs,
      noSuchMethodStubs,
      gettersSetters
    ].expand((x) => x);
    elements.addAll(allMethods.expand(emitInstanceMethod));

    return unparse(compiler, new js.ArrayInitializer(elements));
  }

  js.Expression emitLazyInitializer(StaticField field) {
    assert(field.isLazy);
    return unparse(compiler, field.code);
  }

  /// JavaScript code template that implements parsing of a function descriptor.
  /// Descriptors are used in place of the actual JavaScript function
  /// definition in the output if additional information needs to be passed to
  /// facilitate the generation of tearOffs at runtime. The format is an array
  /// with the following fields:
  ///
  /// * [InstanceMethod.aliasName] (optional).
  /// * [Method.code]
  /// * [DartMethod.callName]
  /// * isInterceptedMethod (optional, present if [DartMethod.needsTearOff]).
  /// * [DartMethod.tearOffName] (optional, present if
  ///   [DartMethod.needsTearOff]).
  /// * functionType (optional, present if [DartMethod.needsTearOff]).
  ///
  /// followed by
  ///
  /// * [ParameterStubMethod.name]
  /// * [ParameterStubMethod.callName]
  /// * [ParameterStubMethod.code]
  ///
  /// for each stub in [DartMethod.parameterStubs].
  ///
  /// If the closure could be used in `Function.apply` (i.e.
  /// [DartMethod.canBeApplied] is true) then the following fields are appended:
  ///
  /// * [DartMethod.requiredParameterCount]
  /// * [DartMethod.optionalParameterDefaultValues]

  static final String parseFunctionDescriptorBoilerplate = r"""
function parseFunctionDescriptor(proto, name, descriptor, typesOffset) {
  if (descriptor instanceof Array) {
    // 'pos' points to the last read entry.
    var f, pos = -1;
    var aliasOrFunction = descriptor[++pos];
    if (typeof aliasOrFunction == "string") {
      // Install the alias for super calls on the prototype chain.
      proto[aliasOrFunction] = f = descriptor[++pos];
    } else {
      f = aliasOrFunction;
    }

    proto[name] = f;
    var funs = [f];
    f[#callName] = descriptor[++pos];

    var isInterceptedOrParameterStubName = descriptor[pos + 1];
    var isIntercepted, tearOffName, reflectionInfo;
    if (typeof isInterceptedOrParameterStubName == "boolean") {
      isIntercepted = descriptor[++pos];
      tearOffName = descriptor[++pos];
      reflectionInfo = descriptor[++pos];
      if (typeof reflectionInfo == "number") {
        reflectionInfo = reflectionInfo + typesOffset;
      }
    }

    // We iterate in blocks of 3 but have to stop before we reach the (optional)
    // two trailing items. To accomplish this, we only iterate until we reach
    // length - 2.
    for (++pos; pos < descriptor.length - 2; pos += 3) {
      var stub = descriptor[pos + 2];
      stub[#callName] = descriptor[pos + 1];
      proto[descriptor[pos]] = stub;
      funs.push(stub);
    }

    if (tearOffName) {
      proto[tearOffName] =
          tearOff(funs, reflectionInfo, false, name, isIntercepted);
    }
    if (pos < descriptor.length) {
      f[#argumentCount] = descriptor[pos];
      f[#defaultArgumentValues] = descriptor[pos + 1];
    }
  } else {
    proto[name] = descriptor;
  }
}
""";

  js.Expression _encodeOptionalParameterDefaultValues(DartMethod method) {
    // TODO(herhut): Replace [js.LiteralNull] with [js.ArrayHole].
    if (method.optionalParameterDefaultValues is List) {
      List<ConstantValue> defaultValues = method.optionalParameterDefaultValues;
      Iterable<js.Expression> elements =
          defaultValues.map(generateConstantReference);
      return new js.ArrayInitializer(elements.toList());
    } else {
      Map<String, ConstantValue> defaultValues =
          method.optionalParameterDefaultValues;
      List<js.Property> properties = <js.Property>[];
      defaultValues.forEach((String name, ConstantValue value) {
        properties.add(
            new js.Property(js.string(name), generateConstantReference(value)));
      });
      return new js.ObjectInitializer(properties);
    }
  }

  Iterable<js.Expression> emitInstanceMethod(Method method) {
    List<js.Expression> makeNameCodePair(Method method) {
      return [js.quoteName(method.name), method.code];
    }

    List<js.Expression> makeNameCallNameCodeTriplet(ParameterStubMethod stub) {
      js.Expression callName = stub.callName == null
          ? new js.LiteralNull()
          : js.quoteName(stub.callName);
      return [js.quoteName(stub.name), callName, stub.code];
    }

    if (method is InstanceMethod) {
      if (method.needsTearOff || method.aliasName != null) {
        /// See [parseFunctionDescriptorBoilerplate] for a full description of
        /// the format.
        // [name, [aliasName, function, callName, isIntercepted, tearOffName,
        // functionType, stub1_name, stub1_callName, stub1_code, ...]
        var data = [];
        if (method.aliasName != null) {
          data.add(js.quoteName(method.aliasName));
        }
        data.add(method.code);
        data.add(js.quoteName(method.callName, allowNull: true));

        if (method.needsTearOff) {
          MethodElement element = method.element;
          bool isIntercepted = _interceptorData.isInterceptedMethod(element);
          data.add(new js.LiteralBool(isIntercepted));
          data.add(js.quoteName(method.tearOffName));
          data.add((method.functionType));
        }

        data.addAll(method.parameterStubs.expand(makeNameCallNameCodeTriplet));
        if (method.canBeApplied) {
          data.add(js.number(method.requiredParameterCount));
          data.add(_encodeOptionalParameterDefaultValues(method));
        }
        return [js.quoteName(method.name), new js.ArrayInitializer(data)];
      } else {
        // TODO(floitsch): not the most efficient way...
        return (<dynamic>[method]..addAll(method.parameterStubs))
            .expand(makeNameCodePair);
      }
    } else {
      return makeNameCodePair(method);
    }
  }

  Iterable<js.Expression> emitStaticMethod(StaticMethod method) {
    js.Expression holderIndex = js.number(method.holder.index);
    List<js.Expression> output = <js.Expression>[];

    void _addMethod(Method method) {
      js.Expression unparsed = unparse(compiler, method.code);
      output.add(js.quoteName(method.name));
      output.add(holderIndex);
      output.add(unparsed);
    }

    List<js.Expression> makeNameCallNameCodeTriplet(ParameterStubMethod stub) {
      js.Expression callName = stub.callName == null
          ? new js.LiteralNull()
          : js.quoteName(stub.callName);
      return [js.quoteName(stub.name), callName, unparse(compiler, stub.code)];
    }

    _addMethod(method);
    // TODO(floitsch): can there be anything else than a StaticDartMethod?
    if (method is StaticDartMethod) {
      if (method.needsTearOff) {
        /// The format emitted is the same as for the parser specified at
        /// [parseFunctionDescriptorBoilerplate] except for the missing
        /// field whether the method is intercepted.
        // [name, [function, callName, tearOffName, functionType,
        //     stub1_name, stub1_callName, stub1_code, ...]
        var data = <js.Expression>[unparse(compiler, method.code)];
        data.add(js.quoteName(method.callName));
        data.add(js.quoteName(method.tearOffName));
        data.add(method.functionType);
        data.addAll(method.parameterStubs.expand(makeNameCallNameCodeTriplet));
        if (method.canBeApplied) {
          data.add(js.number(method.requiredParameterCount));
          data.add(_encodeOptionalParameterDefaultValues(method));
        }
        return [
          js.quoteName(method.name),
          holderIndex,
          new js.ArrayInitializer(data)
        ];
      } else {
        method.parameterStubs.forEach(_addMethod);
      }
    }
    return output;
  }

  static final String setupProgramName = "setupProgram";

  static final String boilerplate = """
{
// Declare deferred-initializer global.
#deferredInitializer;

(function(start, program) {
  // Initialize holder objects.
  #holders;
  var nativeInfos = Object.create(null);

  // Counter to generate unique names for tear offs.
  var functionCounter = 0;

  function $setupProgramName(program, typesOffset) {
    for (var i = 0; i < program.length - 2; i++) {
      setupLibrary(program[i], typesOffset);
    }
    setupLazyStatics(program[i]);
    setupConstants(program[i + 1]);
  }

  function setupLibrary(library, typesOffset) {
    var statics = library[0];
    for (var i = 0; i < statics.length; i += 3) {
      var holderIndex = statics[i + 1];
      setupStatic(statics[i], holders[holderIndex], statics[i + 2],
                  typesOffset);
    }

    var classes = library[1];
    for (var i = 0; i < classes.length; i += 3) {
      var name = classes[i];
      var cls = classes[i + 1];

      if (#needsNativeSupport) {
        // $nativeInfoDescription.
        var indexOrNativeInfo = classes[i + 2];
        if (typeof indexOrNativeInfo == "number") {
          var holderIndex = classes[i + 2];
        } else {
          nativeInfos[name] = indexOrNativeInfo;
          holderIndex = classes[i + 3];
          i++;
        }
      }

      if (#needsNoNativeSupport) {
        var holderIndex = classes[i + 2];
      }

      holdersMap[name] = holders[holderIndex];
      setupClass(name, holders[holderIndex], cls, typesOffset);
    }
  }

  function setupLazyStatics(statics) {
    for (var i = 0; i < statics.length; i += 4) {
      var name = statics[i];
      var getterName = statics[i + 1];
      var holderIndex = statics[i + 2];
      var initializer = statics[i + 3];
      setupLazyStatic(name, getterName, holders[holderIndex], initializer);
    }
  }

  function setupConstants(constants) {
    // $constantsDescription.
    if (constants.length == 0) return;
    // We assume that all constants are in the same holder.
    var holder = holders[constants[0]];
    for (var i = 1; i < constants.length; i += 2) {
      var name = constants[i];
      var initializer = constants[i + 1];
      setupConstant(name, holder, initializer);
    }
  }

  function setupStatic(name, holder, descriptor, typesOffset) {
    if (typeof descriptor == 'string') {
      holder[name] = function() {
        if (descriptor == null) {
          // Already compiled. This happens when we have calls to the static as
          // arguments to the static: `foo(foo(499))`;
          return holder[name].apply(this, arguments);
        }
        var method = compile(name, descriptor);
        holder[name] = method;
        descriptor = null;  // GC the descriptor.
        return method.apply(this, arguments);
      };
    } else {
      // Parse the tear off information and generate compile handlers.
      // TODO(herhut): Share parser with instance methods.
      function compileAllStubs(typesOffset) {
        var funs;
        var fun = compile(name, descriptor[0]);
        fun[#callName] = descriptor[1];
        holder[name] = fun;
        funs = [fun];
        // We iterate in blocks of 3 but have to stop before we reach the
        // (optional) two trailing items. To accomplish this, we only iterate
        // until we reach length - 2.
        for (var pos = 4; pos < descriptor.length - 2; pos += 3) {
          var stubName = descriptor[pos];
          fun = compile(stubName, descriptor[pos + 2]);
          fun[#callName] = descriptor[pos + 1];
          holder[stubName] = fun;
          funs.push(fun);
        }
        if (descriptor[2] != null) {  // tear-off name.
          // functions, reflectionInfo, isStatic, name, isIntercepted.
          var reflectionInfo = descriptor[3];
          if (typeof reflectionInfo == "number") {
            reflectionInfo = reflectionInfo + typesOffset;
          }
          holder[descriptor[2]] =
              tearOff(funs, reflectionInfo, true, name, false);
        }
        if (pos < descriptor.length) {
          fun[#argumentCount] = descriptor[pos];
          fun[#defaultArgumentValues] = descriptor[pos + 1];
        }
      }

      function setupCompileAllAndDelegateStub(name, typesOffset) {
        holder[name] = function() {
          // The descriptor is null if we already compiled this function. This
          // happens when we have calls to the static as arguments to the
          // static: `foo(foo(499))`;
          if (descriptor != null) {
            compileAllStubs(typesOffset);
            descriptor = null;  // GC the descriptor.
          }
          return holder[name].apply(this, arguments);
        };
      }

      setupCompileAllAndDelegateStub(name, typesOffset);
      for (var pos = 4; pos < descriptor.length; pos += 3) {
        setupCompileAllAndDelegateStub(descriptor[pos], typesOffset);
      }
      if (descriptor[2] != null) {  // tear-off name.
        setupCompileAllAndDelegateStub(descriptor[2], typesOffset)
      }
    }
  }

  function setupLazyStatic(name, getterName, holder, descriptor) {
    holder[name] = null;
    holder[getterName] = function() {
      var initializer = compile(name, descriptor);
      holder[getterName] = function() { #cyclicThrow(name) };
      var result;
      var sentinelInProgress = descriptor;
      try {
        result = holder[name] = sentinelInProgress;
        result = holder[name] = initializer();
      } finally {
        // Use try-finally, not try-catch/throw as it destroys the stack trace.
        if (result === sentinelInProgress) {
          // The lazy static (holder[name]) might have been set to a different
          // value. According to spec we still have to reset it to null, if the
          // initialization failed.
          holder[name] = null;
        }
        // TODO(floitsch): the function should probably be unique for each
        // static.
        holder[getterName] = function() { return this[name]; };
      }
      return result;
    };
  }

  function setupConstant(name, holder, descriptor) {
    var c;
    holder[name] = function() {
      if (descriptor !== null) {
        c = compile(name, descriptor);
        name = null;
        descriptor = null;
      }
      return c;
    };
  }

  function setupClass(name, holder, descriptor, typesOffset) {
    var patch = function() {
      if (patch.ensureResolved == patch) {
        // We have not yet been compiled.
        var constructor = compileConstructor(name, descriptor, typesOffset);
        holder[name] = constructor;
        name = holder = descriptor = null;  // GC the captured arguments.
        // Make sure we can invoke 'ensureResolved' multiple times on the patch
        // function.
        patch.ensureResolved = function() { return constructor; };
        constructor.ensureResolved = function() { return this; };
      } else {
        // This can happen when arguments to the constructor are of the same
        // class, like in `new A(new A(null))`.
        constructor = patch.ensureResolved();
      }
      // If the patch has been called as "ensureResolved" return.
      if (this === patch) return constructor;
      var object = new constructor();
      constructor.apply(object, arguments);
      return object;
    };

    // We store the patch function on itself to make it
    // possible to resolve superclass references without constructing instances.
    patch.ensureResolved = patch;
    holder[name] = patch;
  }

  #tearOff;

  #parseFunctionDescriptor;

  function compileConstructor(name, descriptor, typesOffset) {
    descriptor = compile(name, descriptor);
    var prototype = determinePrototype(descriptor);
    var constructor;
    var functionsIndex;
    // $mixinFormatDescription.
    if (typeof descriptor[2] !== 'function') {
      fillPrototypeWithMixedIn(descriptor[2], descriptor[3], prototype);
      // descriptor[4] contains the constructor if the mixin application is
      // directly instantiated.
      if (typeof descriptor[4] === 'function') {
        constructor = descriptor[4];
        functionsIndex = 5;
      } else {
        constructor = function() {};
        functionsIndex = 4;
      }
    } else {
      constructor = descriptor[2];
      functionsIndex = 3;
    }

    for (var i = functionsIndex; i < descriptor.length; i += 2) {
      parseFunctionDescriptor(prototype, descriptor[i], descriptor[i + 1],
                              typesOffset);
    }

    constructor.$typeNameProperty = name;  // Needed for RTI.
    constructor.prototype = prototype;
    prototype[#operatorIsPrefix + name] = constructor;
    prototype.constructor = constructor;
    return constructor;
  }

  function fillPrototypeWithMixedIn(mixinName, mixinHolderIndex, prototype) {
    var mixin = holders[mixinHolderIndex][mixinName].ensureResolved();
    var mixinPrototype = mixin.prototype;

    // Fill the prototype with the mixin's properties.
    var mixinProperties = Object.keys(mixinPrototype);
    for (var i = 0; i < mixinProperties.length; i++) {
      var p = mixinProperties[i];
      prototype[p] = mixinPrototype[p];
    }
  }

  function determinePrototype(descriptor) {
    var superclassName = descriptor[0];
    if (!superclassName) return { };

    // Look up the superclass constructor function in the right holder.
    var holderIndex = descriptor[1];
    var superclass = holders[holderIndex][superclassName].ensureResolved();

    // Create a new prototype object chained to the superclass prototype.
    var intermediate = function() { };
    intermediate.prototype = superclass.prototype;
    return new intermediate();
  }

  function compile(__name__, __s__) {
    'use strict';
    // TODO(floitsch): evaluate the performance impact of the string
    // concatenations.
    return eval(__s__ + "\\n//# sourceURL=" + __name__ + ".js");
  }

  if (#outputContainsConstantList) {
    function makeConstList(list) {
      // By assigning a function to the properties they become part of the
      // hidden class. The actual values of the fields don't matter, since we
      // only check if they exist.
      list.immutable\$list = Array;
      list.fixed\$length = Array;
      return list;
    }
  }

  if (#needsNativeSupport) {
    function handleNativeClassInfos() {
      for (var nativeClass in nativeInfos) {
        var constructor = holdersMap[nativeClass][nativeClass].ensureResolved();
        var nativeInfo = nativeInfos[nativeClass];
        #nativeInfoHandler;
      }
    }
  }

  $setupProgramName(program, 0);

  // Initialize globals.
  #embeddedGlobals;

  function expressionCompile(__s__) {
    'use strict';
    return eval('(' + __s__ + ')');
  }

  #readMetadataTypeFunction;

  // TODO(floitsch): this order means that native classes may not be
  // referenced from constants. I'm mostly afraid of things like using them as
  // generic arguments (which should be fine, but maybe there are other
  // similar things).
  // Initialize natives.
  if (#needsNativeSupport) handleNativeClassInfos();

  // Initialize static non-final fields.
  #staticNonFinals;

  // Add native boilerplate code.
  #nativeIsolateAffinityTagInitialization;

  // Initialize eager classes.
  #eagerClasses;

  var end = Date.now();
  // print('Setup: ' + (end - start) + ' ms.');

  #invokeMain;  // Start main.

})(Date.now(), #code)
}""";
}
