// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner.dart' show BeginGroupToken, Token;
import 'package:front_end/src/fasta/scanner.dart' as Tokens show EOF_TOKEN;

import '../common.dart';
import '../common/backend_api.dart';
import '../common/resolution.dart' show Resolution;
import '../compiler.dart' show Compiler;
import '../common_elements.dart' show CommonElements;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../js_backend/backend_helpers.dart' show BackendHelpers;
import '../js_backend/backend_usage.dart' show BackendUsageBuilder;
import '../js_backend/js_backend.dart';
import '../js_backend/native_data.dart' show NativeBasicData, NativeData;
import '../js_emitter/js_emitter.dart' show CodeEmitterTask, NativeEmitter;
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
  final Set<ClassElement> _registeredClasses = new Set<ClassElement>();
  final Set<ClassElement> _unusedClasses = new Set<ClassElement>();

  bool get hasInstantiatedNativeClasses => !_registeredClasses.isEmpty;

  final Compiler _compiler;
  final bool enableLiveTypeAnalysis;

  /// Subclasses of [NativeEnqueuerBase] are constructed by the backend.
  NativeEnqueuerBase(this._compiler, this.enableLiveTypeAnalysis);

  JavaScriptBackend get _backend => _compiler.backend;
  BackendHelpers get _helpers => _backend.helpers;
  Resolution get _resolution => _compiler.resolution;

  DiagnosticReporter get _reporter => _compiler.reporter;
  CommonElements get _commonElements => _compiler.commonElements;

  NativeBasicData get _nativeBasicData => _backend.nativeBasicData;

  BackendClasses get _backendClasses => _backend.backendClasses;

  void onInstantiatedType(InterfaceType type) {
    if (_unusedClasses.remove(type.element)) {
      _registeredClasses.add(type.element);
    }
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
      cls.ensureResolved(_resolution);
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
          registerInstantiation(_commonElements.objectType);
        }
        continue;
      }
      if (type is ResolutionInterfaceType) {
        if (type == _commonElements.numType) {
          registerInstantiation(_commonElements.doubleType);
          registerInstantiation(_commonElements.intType);
        } else if (type == _commonElements.intType ||
            type == _commonElements.doubleType ||
            type == _commonElements.stringType ||
            type == _commonElements.nullType ||
            type == _commonElements.boolType ||
            type.asInstanceOf(_backendClasses.listClass) != null) {
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
          return _compiler.types.isSubtype(nativeType, specType);
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
      _reporter.log('All native types marked as used due to $cause.');
    }
  }

  Iterable<ClassElement> _findUnusedClassesMatching(
      bool predicate(classElement)) {
    return _unusedClasses.where(predicate);
  }

  void _registerBackendUse(FunctionEntity element) {}

  Iterable<ClassElement> _onFirstNativeClass(WorldImpactBuilder impactBuilder) {
    void staticUse(FunctionEntity element) {
      impactBuilder.registerStaticUse(new StaticUse.implicitInvoke(element));
      _registerBackendUse(element);
    }

    staticUse(_helpers.defineProperty);
    staticUse(_helpers.toStringForNativeObject);
    staticUse(_helpers.hashCodeForNativeObject);
    staticUse(_helpers.closureConverter);
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
  /// The set of all native classes.  Each native class is in [nativeClasses]
  /// and exactly one of [unusedClasses] and [registeredClasses].
  final Set<ClassElement> _nativeClasses = new Set<ClassElement>();

  Map<String, ClassElement> tagOwner = new Map<String, ClassElement>();

  NativeResolutionEnqueuer(Compiler compiler)
      : super(compiler, compiler.options.enableNativeLiveTypeAnalysis);

  BackendUsageBuilder get _backendUsageBuilder => _backend.backendUsageBuilder;

  void _registerBackendUse(FunctionEntity element) {
    _backendUsageBuilder.registerBackendFunctionUse(element);
    _backendUsageBuilder.registerGlobalFunctionDependency(element);
  }

  WorldImpact processNativeClasses(Iterable<LibraryElement> libraries) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    Set<ClassElement> nativeClasses = new Set<ClassElement>();
    libraries.forEach((l) => _processNativeClassesInLibrary(l, nativeClasses));
    if (_helpers.isolateHelperLibrary != null) {
      _processNativeClassesInLibrary(
          _helpers.isolateHelperLibrary, nativeClasses);
    }
    _processSubclassesOfNativeClasses(libraries, nativeClasses);
    _nativeClasses.addAll(nativeClasses);
    _unusedClasses.addAll(nativeClasses);
    if (!enableLiveTypeAnalysis) {
      _registerTypeUses(impactBuilder, _nativeClasses, 'forced');
    }
    return impactBuilder;
  }

  void _processNativeClassesInLibrary(
      LibraryElement library, Set<ClassElement> nativeClasses) {
    // Use implementation to ensure the inclusion of injected members.
    library.implementation.forEachLocalMember((Element element) {
      if (element.isClass) {
        ClassElement cls = element;
        if (_nativeBasicData.isNativeClass(cls)) {
          _processNativeClass(element, nativeClasses);
        }
      }
    });
  }

  void _processNativeClass(
      ClassElement classElement, Set<ClassElement> nativeClasses) {
    nativeClasses.add(classElement);
    // Resolve class to ensure the class has valid inheritance info.
    classElement.ensureResolved(_resolution);
    // Js Interop interfaces do not have tags.
    if (_nativeBasicData.isJsInteropClass(classElement)) return;
    // Since we map from dispatch tags to classes, a dispatch tag must be used
    // on only one native class.
    for (String tag in _nativeBasicData.getNativeTagsOfClass(classElement)) {
      ClassElement owner = tagOwner[tag];
      if (owner != null) {
        if (owner != classElement) {
          _reporter.internalError(
              classElement, "Tag '$tag' already in use by '${owner.name}'");
        }
      } else {
        tagOwner[tag] = classElement;
      }
    }
  }

  void _processSubclassesOfNativeClasses(
      Iterable<LibraryElement> libraries, Set<ClassElement> nativeClasses) {
    Set<ClassElement> nativeClassesAndSubclasses = new Set<ClassElement>();
    // Collect potential subclasses, e.g.
    //
    //     class B extends foo.A {}
    //
    // String "A" has a potential subclass B.

    var potentialExtends = new Map<String, Set<ClassElement>>();

    libraries.forEach((library) {
      library.implementation.forEachLocalMember((element) {
        if (element.isClass) {
          String extendsName = _findExtendsNameOfClass(element);
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
      if (_nativeBasicData.isNativeClass(classElement)) return classElement;
      if (classElement.superclass == null) return null;
      return nativeSuperclassOf(classElement.superclass);
    }

    void walkPotentialSubclasses(ClassElement element) {
      if (nativeClassesAndSubclasses.contains(element)) return;
      element.ensureResolved(_resolution);
      ClassElement nativeSuperclass = nativeSuperclassOf(element);
      if (nativeSuperclass != null) {
        nativeClassesAndSubclasses.add(element);
        Set<ClassElement> potentialSubclasses = potentialExtends[element.name];
        if (potentialSubclasses != null) {
          potentialSubclasses.forEach(walkPotentialSubclasses);
        }
      }
    }

    nativeClasses.forEach(walkPotentialSubclasses);
    nativeClasses.addAll(nativeClassesAndSubclasses);
  }

  /**
   * Returns the source string of the class named in the extends clause, or
   * `null` if there is no extends clause.
   */
  String _findExtendsNameOfClass(ClassElement classElement) {
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

    return _reporter.withCurrentElement(classElement, () {
      return scanForExtendsName(classElement.position);
    });
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
      : super(compiler, compiler.options.enableNativeLiveTypeAnalysis) {}

  NativeData get _nativeData => _backend.nativeData;

  WorldImpact processNativeClasses(Iterable<LibraryElement> libraries) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    _unusedClasses.addAll(_resolutionEnqueuer._nativeClasses);

    if (!enableLiveTypeAnalysis) {
      _registerTypeUses(
          impactBuilder, _resolutionEnqueuer._nativeClasses, 'forced');
    }

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
    return impactBuilder;
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
    if (!_nativeData.isNativeClass(cls)) return;
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
      assert(!_nativeData.isNativeClass(superclass));
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
