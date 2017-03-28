// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/backend_api.dart' show ForeignResolver;
import '../common/resolution.dart' show Resolution;
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../common_elements.dart' show CommonElements;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/modelx.dart' show FunctionElementX;
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../js_backend/backend_helpers.dart' show BackendHelpers;
import '../js_backend/backend_usage.dart' show BackendUsageBuilder;
import '../js_backend/js_backend.dart';
import '../js_backend/native_data.dart' show NativeBasicDataBuilder;
import '../js_emitter/js_emitter.dart' show CodeEmitterTask, NativeEmitter;
import 'package:front_end/src/fasta/scanner.dart' show BeginGroupToken, Token;
import 'package:front_end/src/fasta/scanner.dart' as Tokens show EOF_TOKEN;
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

  /// Returns whether native classes are being used.
  bool get hasInstantiatedNativeClasses => false;

  /// Emits a summary information using the [log] function.
  void logSummary(log(message)) {}
}

abstract class NativeEnqueuerBase implements NativeEnqueuer {
  /// The set of all native classes.  Each native class is in [nativeClasses]
  /// and exactly one of [unusedClasses] and [registeredClasses].
  final Set<ClassElement> _nativeClasses = new Set<ClassElement>();

  final Set<ClassElement> _registeredClasses = new Set<ClassElement>();
  final Set<ClassElement> _unusedClasses = new Set<ClassElement>();

  bool get hasInstantiatedNativeClasses => !_registeredClasses.isEmpty;

  final Set<ClassElement> nativeClassesAndSubclasses = new Set<ClassElement>();

  final Compiler compiler;
  final bool enableLiveTypeAnalysis;

  /// Subclasses of [NativeEnqueuerBase] are constructed by the backend.
  NativeEnqueuerBase(Compiler compiler, this.enableLiveTypeAnalysis)
      : this.compiler = compiler;

  JavaScriptBackend get backend => compiler.backend;
  BackendHelpers get helpers => backend.helpers;
  Resolution get resolution => compiler.resolution;

  DiagnosticReporter get reporter => compiler.reporter;
  CommonElements get commonElements => compiler.commonElements;

  void onInstantiatedType(ResolutionInterfaceType type) {
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
      if (element.isClass) {
        ClassElement cls = element;
        if (backend.nativeBasicData.isNativeClass(cls)) {
          processNativeClass(element);
        }
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
      if (backend.nativeBasicData.isNativeClass(classElement))
        return classElement;
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
      return id.lexeme;
    }

    return reporter.withCurrentElement(classElement, () {
      return scanForExtendsName(classElement.position);
    });
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

  void registerNativeBehavior(
      WorldImpactBuilder impactBuilder, NativeBehavior nativeBehavior, cause) {
    _processNativeBehavior(impactBuilder, nativeBehavior, cause);
  }

  void _processNativeBehavior(
      WorldImpactBuilder impactBuilder, NativeBehavior behavior, cause) {
    void registerInstantiation(ResolutionInterfaceType type) {
      impactBuilder.registerTypeUse(new TypeUse.nativeInstantiation(type));
    }

    int unusedBefore = _unusedClasses.length;
    Set<ClassElement> matchingClasses = new Set<ClassElement>();
    for (var type in behavior.typesInstantiated) {
      if (type is SpecialType) {
        if (type == SpecialType.JsObject) {
          registerInstantiation(compiler.commonElements.objectType);
        }
        continue;
      }
      if (type is ResolutionInterfaceType) {
        if (type == commonElements.numType) {
          registerInstantiation(commonElements.doubleType);
          registerInstantiation(commonElements.intType);
        } else if (type == commonElements.intType ||
            type == commonElements.doubleType ||
            type == commonElements.stringType ||
            type == commonElements.nullType ||
            type == commonElements.boolType ||
            type.asInstanceOf(backend.backendClasses.listClass) != null) {
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
          ResolutionInterfaceType nativeType = nativeClass.thisType;
          ResolutionInterfaceType specType = type.element.thisType;
          return compiler.types.isSubtype(nativeType, specType);
        }));
      } else if (type.isDynamic) {
        matchingClasses.addAll(_unusedClasses);
      } else {
        assert(type is ResolutionVoidType);
      }
    }
    if (matchingClasses.isNotEmpty && _registeredClasses.isEmpty) {
      matchingClasses.addAll(_onFirstNativeClass(impactBuilder));
    }
    _registerTypeUses(impactBuilder, matchingClasses, cause);

    // Give an info so that library developers can compile with -v to find why
    // all the native classes are included.
    if (unusedBefore > 0 && unusedBefore == matchingClasses.length) {
      reporter.log('All native types marked as used due to $cause.');
    }
  }

  Iterable<ClassElement> _findUnusedClassesMatching(
      bool predicate(classElement)) {
    return _unusedClasses.where(predicate);
  }

  void registerBackendUse(MethodElement element) {}

  Iterable<ClassElement> _onFirstNativeClass(WorldImpactBuilder impactBuilder) {
    void staticUse(MethodElement element) {
      impactBuilder.registerStaticUse(new StaticUse.implicitInvoke(element));
      registerBackendUse(element);
    }

    staticUse(helpers.defineProperty);
    staticUse(helpers.toStringForNativeObject);
    staticUse(helpers.hashCodeForNativeObject);
    staticUse(helpers.closureConverter);
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

  BackendUsageBuilder get _backendUsageBuilder => backend.backendUsageBuilder;

  void registerBackendUse(MethodElement element) {
    _backendUsageBuilder.registerBackendFunctionUse(element);
    _backendUsageBuilder.registerGlobalFunctionDependency(element);
  }

  void processNativeClass(ClassElement classElement) {
    super.processNativeClass(classElement);

    // Js Interop interfaces do not have tags.
    if (backend.nativeBasicData.isJsInteropClass(classElement)) return;
    // Since we map from dispatch tags to classes, a dispatch tag must be used
    // on only one native class.
    for (String tag
        in backend.nativeBasicData.getNativeTagsOfClass(classElement)) {
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
}

class NativeCodegenEnqueuer extends NativeEnqueuerBase {
  final CodeEmitterTask emitter;

  final Set<ClassElement> doneAddSubtypes = new Set<ClassElement>();

  final NativeResolutionEnqueuer _resolutionEnqueuer;

  NativeCodegenEnqueuer(
      Compiler compiler, this.emitter, this._resolutionEnqueuer)
      : super(compiler, compiler.options.enableNativeLiveTypeAnalysis);

  void _processNativeClasses(
      WorldImpactBuilder impactBuilder, Iterable<LibraryElement> libraries) {
    super._processNativeClasses(impactBuilder, libraries);

    // HACK HACK - add all the resolved classes.
    Set<ClassElement> matchingClasses = new Set<ClassElement>();
    for (final classElement in _resolutionEnqueuer._registeredClasses) {
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
    if (!backend.nativeData.isNativeClass(cls)) return;
    if (doneAddSubtypes.contains(cls)) return;
    doneAddSubtypes.add(cls);

    // Walk the superclass chain since classes on the superclass chain might not
    // be instantiated (abstract or simply unused).
    _addSubtypes(cls.superclass, emitter);

    for (ResolutionInterfaceType type in cls.allSupertypes) {
      List<ClassEntity> subtypes =
          emitter.subtypes.putIfAbsent(type.element, () => <ClassEntity>[]);
      subtypes.add(cls);
    }

    // Skip through all the mixin applications in the super class
    // chain. That way, the direct subtypes set only contain the
    // natives classes.
    ClassElement superclass = cls.superclass;
    while (superclass != null && superclass.isMixinApplication) {
      assert(!backend.nativeData.isNativeClass(superclass));
      superclass = superclass.superclass;
    }

    List<ClassEntity> directSubtypes =
        emitter.directSubtypes.putIfAbsent(superclass, () => <ClassEntity>[]);
    directSubtypes.add(cls);
  }

  void logSummary(log(message)) {
    log('Compiled ${_registeredClasses.length} native classes, '
        '${_unusedClasses.length} native classes omitted.');
  }
}
