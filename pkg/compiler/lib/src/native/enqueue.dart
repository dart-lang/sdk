// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show Queue;

import '../common.dart';
import '../common/backend_api.dart' show ForeignResolver;
import '../common/resolution.dart' show Resolution;
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../core_types.dart' show CoreTypes;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart' show FunctionElementX;
import '../js_backend/backend_helpers.dart' show BackendHelpers;
import '../js_backend/js_backend.dart';
import '../js_emitter/js_emitter.dart' show CodeEmitterTask, NativeEmitter;
import '../tokens/token.dart' show BeginGroupToken, Token;
import '../tokens/token_constants.dart' as Tokens show EOF_TOKEN;
import '../tree/tree.dart';
import '../universe/use.dart' show StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import 'behavior.dart';

/**
 * This could be an abstract class but we use it as a stub for the dart_backend.
 */
class NativeEnqueuer {
  /// Called when a [type] has been instantiated natively.
  void onInstantiatedType(InterfaceType type) {}

  /// Initial entry point to native enqueuer.
  WorldImpact processNativeClasses(Iterable<LibraryElement> libraries) =>
      const WorldImpact();

  /// Registers the [nativeBehavior]. Adds the liveness of its instantiated
  /// types to the world.
  void registerNativeBehavior(
      WorldImpactBuilder impactBuilder, NativeBehavior nativeBehavior, cause) {}

  // TODO(johnniwinther): Move [handleFieldAnnotations] and
  // [handleMethodAnnotations] to [JavaScriptBackend] or [NativeData].
  // TODO(johnniwinther): Change the return type to 'bool' and rename them to
  // something like `computeNativeField`.
  /// Process the potentially native [field]. Adds information from metadata
  /// attributes.
  void handleFieldAnnotations(Element field) {}

  /// Process the potentially native [method]. Adds information from metadata
  /// attributes.
  void handleMethodAnnotations(Element method) {}

  /// Returns whether native classes are being used.
  bool get hasInstantiatedNativeClasses => false;

  /// Emits a summary information using the [log] function.
  void logSummary(log(message)) {}

  // Do not use annotations in dart2dart.
  ClassElement get annotationCreatesClass => null;
  ClassElement get annotationReturnsClass => null;
  ClassElement get annotationJsNameClass => null;
}

abstract class NativeEnqueuerBase implements NativeEnqueuer {
  static final RegExp _identifier = new RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');

  /// The set of all native classes.  Each native class is in [nativeClasses]
  /// and exactly one of [unusedClasses] and [registeredClasses].
  final Set<ClassElement> _nativeClasses = new Set<ClassElement>();

  final Set<ClassElement> _registeredClasses = new Set<ClassElement>();
  final Set<ClassElement> _unusedClasses = new Set<ClassElement>();

  final Set<LibraryElement> processedLibraries;

  bool get hasInstantiatedNativeClasses => !_registeredClasses.isEmpty;

  final Set<ClassElement> nativeClassesAndSubclasses = new Set<ClassElement>();

  final Compiler compiler;
  final bool enableLiveTypeAnalysis;

  ClassElement _annotationCreatesClass;
  ClassElement _annotationReturnsClass;
  ClassElement _annotationJsNameClass;

  /// Subclasses of [NativeEnqueuerBase] are constructed by the backend.
  NativeEnqueuerBase(Compiler compiler, this.enableLiveTypeAnalysis)
      : this.compiler = compiler,
        processedLibraries = compiler.cacheStrategy.newSet();

  JavaScriptBackend get backend => compiler.backend;
  BackendHelpers get helpers => backend.helpers;
  Resolution get resolution => compiler.resolution;

  DiagnosticReporter get reporter => compiler.reporter;
  CoreTypes get coreTypes => compiler.coreTypes;

  void onInstantiatedType(InterfaceType type) {
    if (_unusedClasses.remove(type.element)) {
      _registeredClasses.add(type.element);
    }
  }

  WorldImpact processNativeClasses(Iterable<LibraryElement> libraries) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    _processNativeClasses(impactBuilder, libraries);
    return impactBuilder;
  }

  void _processNativeClasses(
      WorldImpactBuilder impactBuilder, Iterable<LibraryElement> libraries) {
    if (compiler.options.hasIncrementalSupport) {
      // Since [Set.add] returns bool if an element was added, this restricts
      // [libraries] to ones that haven't already been processed. This saves
      // time during incremental compiles.
      libraries = libraries.where(processedLibraries.add);
    }
    libraries.forEach(processNativeClassesInLibrary);
    if (helpers.isolateHelperLibrary != null) {
      processNativeClassesInLibrary(helpers.isolateHelperLibrary);
    }
    processSubclassesOfNativeClasses(libraries);
    if (!enableLiveTypeAnalysis) {
      _registerTypeUses(impactBuilder, _nativeClasses, 'forced');
    }
  }

  void processNativeClassesInLibrary(LibraryElement library) {
    // Use implementation to ensure the inclusion of injected members.
    library.implementation.forEachLocalMember((Element element) {
      if (element.isClass && backend.isNative(element)) {
        processNativeClass(element);
      }
    });
  }

  void processNativeClass(ClassElement classElement) {
    _nativeClasses.add(classElement);
    _unusedClasses.add(classElement);
    // Resolve class to ensure the class has valid inheritance info.
    classElement.ensureResolved(resolution);
  }

  void processSubclassesOfNativeClasses(Iterable<LibraryElement> libraries) {
    // Collect potential subclasses, e.g.
    //
    //     class B extends foo.A {}
    //
    // String "A" has a potential subclass B.

    var potentialExtends = new Map<String, Set<ClassElement>>();

    libraries.forEach((library) {
      library.implementation.forEachLocalMember((element) {
        if (element.isClass) {
          String extendsName = findExtendsNameOfClass(element);
          if (extendsName != null) {
            Set<ClassElement> potentialSubclasses = potentialExtends
                .putIfAbsent(extendsName, () => new Set<ClassElement>());
            potentialSubclasses.add(element);
          }
        }
      });
    });

    // Resolve all the native classes and any classes that might extend them in
    // [potentialExtends], and then check that the properly resolved class is in
    // fact a subclass of a native class.

    ClassElement nativeSuperclassOf(ClassElement classElement) {
      if (backend.isNative(classElement)) return classElement;
      if (classElement.superclass == null) return null;
      return nativeSuperclassOf(classElement.superclass);
    }

    void walkPotentialSubclasses(ClassElement element) {
      if (nativeClassesAndSubclasses.contains(element)) return;
      element.ensureResolved(resolution);
      ClassElement nativeSuperclass = nativeSuperclassOf(element);
      if (nativeSuperclass != null) {
        nativeClassesAndSubclasses.add(element);
        Set<ClassElement> potentialSubclasses = potentialExtends[element.name];
        if (potentialSubclasses != null) {
          potentialSubclasses.forEach(walkPotentialSubclasses);
        }
      }
    }

    _nativeClasses.forEach(walkPotentialSubclasses);

    _nativeClasses.addAll(nativeClassesAndSubclasses);
    _unusedClasses.addAll(nativeClassesAndSubclasses);
  }

  /**
   * Returns the source string of the class named in the extends clause, or
   * `null` if there is no extends clause.
   */
  String findExtendsNameOfClass(ClassElement classElement) {
    if (classElement.isResolved) {
      ClassElement superClass = classElement.superclass;
      while (superClass != null) {
        if (!superClass.isUnnamedMixinApplication) {
          return superClass.name;
        }
        superClass = superClass.superclass;
      }
      return null;
    }

    //  "class B extends A ... {}"  --> "A"
    //  "class B extends foo.A ... {}"  --> "A"
    //  "class B<T> extends foo.A<T,T> with M1, M2 ... {}"  --> "A"

    // We want to avoid calling classElement.parseNode on every class.  Doing so
    // will slightly increase parse time and size and cause compiler errors and
    // warnings to me emitted in more unused code.

    // An alternative to this code is to extend the API of ClassElement to
    // expose the name of the extended element.

    // Pattern match the above cases in the token stream.
    //  [abstract] class X extends [id.]* id

    Token skipTypeParameters(Token token) {
      BeginGroupToken beginGroupToken = token;
      Token endToken = beginGroupToken.endGroup;
      return endToken.next;
      //for (;;) {
      //  token = token.next;
      //  if (token.stringValue == '>') return token.next;
      //  if (token.stringValue == '<') return skipTypeParameters(token);
      //}
    }

    String scanForExtendsName(Token token) {
      if (token.stringValue == 'abstract') token = token.next;
      if (token.stringValue != 'class') return null;
      token = token.next;
      if (!token.isIdentifier()) return null;
      token = token.next;
      //  class F<X extends B<X>> extends ...
      if (token.stringValue == '<') {
        token = skipTypeParameters(token);
      }
      if (token.stringValue != 'extends') return null;
      token = token.next;
      Token id = token;
      while (token.kind != Tokens.EOF_TOKEN) {
        token = token.next;
        if (token.stringValue != '.') break;
        token = token.next;
        if (!token.isIdentifier()) return null;
        id = token;
      }
      // Should be at '{', 'with', 'implements', '<' or 'native'.
      return id.value;
    }

    return reporter.withCurrentElement(classElement, () {
      return scanForExtendsName(classElement.position);
    });
  }

  ClassElement get annotationCreatesClass {
    findAnnotationClasses();
    return _annotationCreatesClass;
  }

  ClassElement get annotationReturnsClass {
    findAnnotationClasses();
    return _annotationReturnsClass;
  }

  ClassElement get annotationJsNameClass {
    findAnnotationClasses();
    return _annotationJsNameClass;
  }

  void findAnnotationClasses() {
    if (_annotationCreatesClass != null) return;
    ClassElement find(name) {
      Element e = helpers.findHelper(name);
      if (e == null || e is! ClassElement) {
        reporter.internalError(NO_LOCATION_SPANNABLE,
            "Could not find implementation class '${name}'.");
      }
      return e;
    }

    _annotationCreatesClass = find('Creates');
    _annotationReturnsClass = find('Returns');
    _annotationJsNameClass = find('JSName');
  }

  /// Returns the JSName annotation string or `null` if no JSName annotation is
  /// present.
  String findJsNameFromAnnotation(Element element) {
    String name = null;
    ClassElement annotationClass = annotationJsNameClass;
    for (MetadataAnnotation annotation in element.implementation.metadata) {
      annotation.ensureResolved(resolution);
      ConstantValue value =
          compiler.constants.getConstantValue(annotation.constant);
      if (!value.isConstructedObject) continue;
      ConstructedConstantValue constructedObject = value;
      if (constructedObject.type.element != annotationClass) continue;

      Iterable<ConstantValue> fields = constructedObject.fields.values;
      // TODO(sra): Better validation of the constant.
      if (fields.length != 1 || fields.single is! StringConstantValue) {
        reporter.internalError(
            annotation, 'Annotations needs one string: ${annotation}');
      }
      StringConstantValue specStringConstant = fields.single;
      String specString = specStringConstant.toDartString().slowToString();
      if (name == null) {
        name = specString;
      } else {
        reporter.internalError(
            annotation, 'Too many JSName annotations: ${annotation}');
      }
    }
    return name;
  }

  /// Register [classes] as natively instantiated in [impactBuilder].
  void _registerTypeUses(
      WorldImpactBuilder impactBuilder, Set<ClassElement> classes, cause) {
    for (ClassElement cls in classes) {
      if (!_unusedClasses.contains(cls)) {
        // No need to add [classElement] to [impactBuilder]: it has already been
        // instantiated and we don't track origins of native instantiations
        // precisely.
        continue;
      }
      cls.ensureResolved(resolution);
      impactBuilder
          .registerTypeUse(new TypeUse.nativeInstantiation(cls.rawType));
    }
  }

  void handleFieldAnnotations(Element element) {
    if (compiler.serialization.isDeserialized(element)) {
      return;
    }
    if (backend.isNative(element.enclosingElement)) {
      // Exclude non-instance (static) fields - they not really native and are
      // compiled as isolate globals.  Access of a property of a constructor
      // function or a non-method property in the prototype chain, must be coded
      // using a JS-call.
      if (element.isInstanceMember) {
        _setNativeName(element);
      }
    }
  }

  void handleMethodAnnotations(Element method) {
    if (compiler.serialization.isDeserialized(method)) {
      return;
    }
    if (isNativeMethod(method)) {
      if (method.isStatic) {
        _setNativeNameForStaticMethod(method);
      } else {
        _setNativeName(method);
      }
    }
  }

  /// Sets the native name of [element], either from an annotation, or
  /// defaulting to the Dart name.
  void _setNativeName(MemberElement element) {
    String name = findJsNameFromAnnotation(element);
    if (name == null) name = element.name;
    backend.nativeData.setNativeMemberName(element, name);
  }

  /// Sets the native name of the static native method [element], using the
  /// following rules:
  /// 1. If [element] has a @JSName annotation that is an identifier, qualify
  ///    that identifier to the @Native name of the enclosing class
  /// 2. If [element] has a @JSName annotation that is not an identifier,
  ///    use the declared @JSName as the expression
  /// 3. If [element] does not have a @JSName annotation, qualify the name of
  ///    the method with the @Native name of the enclosing class.
  void _setNativeNameForStaticMethod(MethodElement element) {
    String name = findJsNameFromAnnotation(element);
    if (name == null) name = element.name;
    if (isIdentifier(name)) {
      List<String> nativeNames =
          backend.nativeData.getNativeTagsOfClassRaw(element.enclosingClass);
      if (nativeNames.length != 1) {
        reporter.internalError(
            element,
            'Unable to determine a native name for the enclosing class, '
            'options: $nativeNames');
      }
      backend.nativeData
          .setNativeMemberName(element, '${nativeNames[0]}.$name');
    } else {
      backend.nativeData.setNativeMemberName(element, name);
    }
  }

  bool isIdentifier(String s) => _identifier.hasMatch(s);

  bool isNativeMethod(FunctionElementX element) {
    if (!backend.canLibraryUseNative(element.library)) return false;
    // Native method?
    return reporter.withCurrentElement(element, () {
      Node node = element.parseNode(resolution.parsingContext);
      if (node is! FunctionExpression) return false;
      FunctionExpression functionExpression = node;
      node = functionExpression.body;
      Token token = node.getBeginToken();
      if (identical(token.stringValue, 'native')) return true;
      return false;
    });
  }

  void registerNativeBehavior(
      WorldImpactBuilder impactBuilder, NativeBehavior nativeBehavior, cause) {
    _processNativeBehavior(impactBuilder, nativeBehavior, cause);
  }

  void _processNativeBehavior(
      WorldImpactBuilder impactBuilder, NativeBehavior behavior, cause) {
    void registerInstantiation(InterfaceType type) {
      impactBuilder.registerTypeUse(new TypeUse.nativeInstantiation(type));
    }

    int unusedBefore = _unusedClasses.length;
    Set<ClassElement> matchingClasses = new Set<ClassElement>();
    for (var type in behavior.typesInstantiated) {
      if (type is SpecialType) {
        if (type == SpecialType.JsObject) {
          registerInstantiation(compiler.coreTypes.objectType);
        }
        continue;
      }
      if (type is InterfaceType) {
        if (type == coreTypes.intType) {
          registerInstantiation(type);
        } else if (type == coreTypes.doubleType) {
          registerInstantiation(type);
        } else if (type == coreTypes.numType) {
          registerInstantiation(coreTypes.doubleType);
          registerInstantiation(coreTypes.intType);
        } else if (type == coreTypes.stringType) {
          registerInstantiation(type);
        } else if (type == coreTypes.nullType) {
          registerInstantiation(type);
        } else if (type == coreTypes.boolType) {
          registerInstantiation(type);
        } else if (compiler.types.isSubtype(
            type, backend.backendClasses.listImplementation.rawType)) {
          registerInstantiation(type);
        }
        // TODO(johnniwinther): Improve spec string precision to handle type
        // arguments and implements relations that preserve generics. Currently
        // we cannot distinguish between `List`, `List<dynamic>`, and
        // `List<int>` and take all to mean `List<E>`; in effect not including
        // any native subclasses of generic classes.
        // TODO(johnniwinther,sra): Find and replace uses of `List` with the
        // actual implementation classes such as `JSArray` et al.
        matchingClasses
            .addAll(_findUnusedClassesMatching((ClassElement nativeClass) {
          InterfaceType nativeType = nativeClass.thisType;
          InterfaceType specType = type.element.thisType;
          return compiler.types.isSubtype(nativeType, specType);
        }));
      } else if (type.isDynamic) {
        matchingClasses.addAll(_unusedClasses);
      } else {
        assert(type is VoidType);
      }
    }
    if (matchingClasses.isNotEmpty && _registeredClasses.isEmpty) {
      matchingClasses.addAll(_onFirstNativeClass(impactBuilder));
    }
    _registerTypeUses(impactBuilder, matchingClasses, cause);

    // Give an info so that library developers can compile with -v to find why
    // all the native classes are included.
    if (unusedBefore == matchingClasses.length) {
      reporter.log('All native types marked as used due to $cause.');
    }
  }

  Iterable<ClassElement> _findUnusedClassesMatching(
      bool predicate(classElement)) {
    return _unusedClasses.where(predicate);
  }

  Iterable<ClassElement> _onFirstNativeClass(WorldImpactBuilder impactBuilder) {
    void staticUse(name) {
      Element element = helpers.findHelper(name);
      impactBuilder.registerStaticUse(new StaticUse.foreignUse(element));
      backend.registerBackendUse(element);
      compiler.globalDependencies.registerDependency(element);
    }

    staticUse('defineProperty');
    staticUse('toStringForNativeObject');
    staticUse('hashCodeForNativeObject');
    staticUse('convertDartClosureToJS');
    return _findNativeExceptions();
  }

  Iterable<ClassElement> _findNativeExceptions() {
    return _findUnusedClassesMatching((classElement) {
      // TODO(sra): Annotate exception classes in dart:html.
      String name = classElement.name;
      if (name.contains('Exception')) return true;
      if (name.contains('Error')) return true;
      return false;
    });
  }
}

class NativeResolutionEnqueuer extends NativeEnqueuerBase {
  Map<String, ClassElement> tagOwner = new Map<String, ClassElement>();

  NativeResolutionEnqueuer(Compiler compiler)
      : super(compiler, compiler.options.enableNativeLiveTypeAnalysis);

  void processNativeClass(ClassElement classElement) {
    super.processNativeClass(classElement);

    // Js Interop interfaces do not have tags.
    if (backend.isJsInterop(classElement)) return;
    // Since we map from dispatch tags to classes, a dispatch tag must be used
    // on only one native class.
    for (String tag in backend.nativeData.getNativeTagsOfClass(classElement)) {
      ClassElement owner = tagOwner[tag];
      if (owner != null) {
        if (owner != classElement) {
          reporter.internalError(
              classElement, "Tag '$tag' already in use by '${owner.name}'");
        }
      } else {
        tagOwner[tag] = classElement;
      }
    }
  }

  void logSummary(log(message)) {
    log('Resolved ${_registeredClasses.length} native elements used, '
        '${_unusedClasses.length} native elements dead.');
  }

  /**
   * Handles JS-calls, which can be an instantiation point for types.
   *
   * For example, the following code instantiates and returns native classes
   * that are `_DOMWindowImpl` or a subtype.
   *
   *     JS('_DOMWindowImpl', 'window')
   *
   */
  NativeBehavior resolveJsCall(Send node, ForeignResolver resolver) {
    return NativeBehavior.ofJsCallSend(
        node, reporter, compiler.parsingContext, compiler.coreTypes, resolver);
  }

  /**
   * Handles JS-embedded global calls, which can be an instantiation point for
   * types.
   *
   * For example, the following code instantiates and returns a String class
   *
   *     JS_EMBEDDED_GLOBAL('String', 'foo')
   *
   */
  NativeBehavior resolveJsEmbeddedGlobalCall(
      Send node, ForeignResolver resolver) {
    return NativeBehavior.ofJsEmbeddedGlobalCallSend(
        node, reporter, compiler.coreTypes, resolver);
  }

  /**
   * Handles JS-compiler builtin calls, which can be an instantiation point for
   * types.
   *
   * For example, the following code instantiates and returns a String class
   *
   *     JS_BUILTIN('String', 'int2string', 0)
   *
   */
  NativeBehavior resolveJsBuiltinCall(Send node, ForeignResolver resolver) {
    return NativeBehavior.ofJsBuiltinCallSend(
        node, reporter, compiler.coreTypes, resolver);
  }
}

class NativeCodegenEnqueuer extends NativeEnqueuerBase {
  final CodeEmitterTask emitter;

  final Set<ClassElement> doneAddSubtypes = new Set<ClassElement>();

  NativeCodegenEnqueuer(Compiler compiler, this.emitter)
      : super(compiler, compiler.options.enableNativeLiveTypeAnalysis);

  void _processNativeClasses(
      WorldImpactBuilder impactBuilder, Iterable<LibraryElement> libraries) {
    super._processNativeClasses(impactBuilder, libraries);

    // HACK HACK - add all the resolved classes.
    NativeEnqueuerBase enqueuer = compiler.enqueuer.resolution.nativeEnqueuer;
    Set<ClassElement> matchingClasses = new Set<ClassElement>();
    for (final classElement in enqueuer._registeredClasses) {
      if (_unusedClasses.contains(classElement)) {
        matchingClasses.add(classElement);
      }
    }
    if (matchingClasses.isNotEmpty && _registeredClasses.isEmpty) {
      matchingClasses.addAll(_onFirstNativeClass(impactBuilder));
    }
    _registerTypeUses(impactBuilder, matchingClasses, 'was resolved');
  }

  void _registerTypeUses(
      WorldImpactBuilder impactBuilder, Set<ClassElement> classes, cause) {
    super._registerTypeUses(impactBuilder, classes, cause);

    for (ClassElement classElement in classes) {
      // Add the information that this class is a subtype of its supertypes. The
      // code emitter and the ssa builder use that information.
      _addSubtypes(classElement, emitter.nativeEmitter);
    }
  }

  void _addSubtypes(ClassElement cls, NativeEmitter emitter) {
    if (!backend.isNative(cls)) return;
    if (doneAddSubtypes.contains(cls)) return;
    doneAddSubtypes.add(cls);

    // Walk the superclass chain since classes on the superclass chain might not
    // be instantiated (abstract or simply unused).
    _addSubtypes(cls.superclass, emitter);

    for (DartType type in cls.allSupertypes) {
      List<Element> subtypes =
          emitter.subtypes.putIfAbsent(type.element, () => <ClassElement>[]);
      subtypes.add(cls);
    }

    // Skip through all the mixin applications in the super class
    // chain. That way, the direct subtypes set only contain the
    // natives classes.
    ClassElement superclass = cls.superclass;
    while (superclass != null && superclass.isMixinApplication) {
      assert(!backend.isNative(superclass));
      superclass = superclass.superclass;
    }

    List<Element> directSubtypes =
        emitter.directSubtypes.putIfAbsent(superclass, () => <ClassElement>[]);
    directSubtypes.add(cls);
  }

  void logSummary(log(message)) {
    log('Compiled ${_registeredClasses.length} native classes, '
        '${_unusedClasses.length} native classes omitted.');
  }
}
