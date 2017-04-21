// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'resolver.dart' show NativeClassResolver;

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
  final NativeClassResolver _nativeClassResolver;

  /// The set of all native classes.  Each native class is in [nativeClasses]
  /// and exactly one of [unusedClasses] and [registeredClasses].
  final Set<ClassElement> _nativeClasses = new Set<ClassElement>();

  NativeResolutionEnqueuer(Compiler compiler, this._nativeClassResolver)
      : super(compiler, compiler.options.enableNativeLiveTypeAnalysis);

  BackendUsageBuilder get _backendUsageBuilder => _backend.backendUsageBuilder;

  void _registerBackendUse(FunctionEntity element) {
    _backendUsageBuilder.registerBackendFunctionUse(element);
    _backendUsageBuilder.registerGlobalFunctionDependency(element);
  }

  WorldImpact processNativeClasses(Iterable<LibraryElement> libraries) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    Set<ClassElement> nativeClasses =
        _nativeClassResolver.computeNativeClasses(libraries);
    _nativeClasses.addAll(nativeClasses);
    _unusedClasses.addAll(nativeClasses);
    if (!enableLiveTypeAnalysis) {
      _registerTypeUses(impactBuilder, _nativeClasses, 'forced');
    }
    return impactBuilder;
  }

  void logSummary(log(message)) {
    log('Resolved ${_registeredClasses.length} native elements used, '
        '${_unusedClasses.length} native elements dead.');
  }
}

class NativeCodegenEnqueuer extends NativeEnqueuerBase {
  final CodeEmitterTask _emitter;

  final Set<ClassElement> _doneAddSubtypes = new Set<ClassElement>();

  final NativeResolutionEnqueuer _resolutionEnqueuer;

  NativeCodegenEnqueuer(
      Compiler compiler, this._emitter, this._resolutionEnqueuer)
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
      _addSubtypes(classElement, _emitter.nativeEmitter);
    }
  }

  void _addSubtypes(ClassElement cls, NativeEmitter emitter) {
    if (!_nativeData.isNativeClass(cls)) return;
    if (_doneAddSubtypes.contains(cls)) return;
    _doneAddSubtypes.add(cls);

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
