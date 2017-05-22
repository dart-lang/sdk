// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../js_backend/backend_usage.dart' show BackendUsageBuilder;
import '../js_backend/native_data.dart' show NativeData;
import '../js_emitter/js_emitter.dart' show CodeEmitterTask, NativeEmitter;
import '../options.dart';
import '../universe/use.dart' show StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import 'behavior.dart';
import 'resolver.dart' show NativeClassFinder;

/**
 * This could be an abstract class but we use it as a stub for the dart_backend.
 */
class NativeEnqueuer {
  /// Called when a [type] has been instantiated natively.
  void onInstantiatedType(InterfaceType type) {}

  /// Initial entry point to native enqueuer.
  WorldImpact processNativeClasses(Iterable<LibraryEntity> libraries) =>
      const WorldImpact();

  /// Registers the [nativeBehavior]. Adds the liveness of its instantiated
  /// types to the world.
  void registerNativeBehavior(
      WorldImpactBuilder impactBuilder, NativeBehavior nativeBehavior, cause) {}

  /// Returns whether native classes are being used.
  bool get hasInstantiatedNativeClasses => false;

  /// Emits a summary information using the [log] function.
  void logSummary(void log(String message)) {}
}

abstract class NativeEnqueuerBase implements NativeEnqueuer {
  final Set<ClassEntity> _registeredClasses = new Set<ClassEntity>();
  final Set<ClassEntity> _unusedClasses = new Set<ClassEntity>();

  bool get hasInstantiatedNativeClasses => !_registeredClasses.isEmpty;

  /// Log message reported if all native types are used.
  String _allUsedMessage;

  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final DartTypes _dartTypes;
  final CommonElements _commonElements;

  /// Subclasses of [NativeEnqueuerBase] are constructed by the backend.
  NativeEnqueuerBase(this._options, this._elementEnvironment,
      this._commonElements, this._dartTypes);

  bool get enableLiveTypeAnalysis => _options.enableNativeLiveTypeAnalysis;

  void onInstantiatedType(InterfaceType type) {
    if (_unusedClasses.remove(type.element)) {
      _registeredClasses.add(type.element);
    }
  }

  /// Register [classes] as natively instantiated in [impactBuilder].
  void _registerTypeUses(
      WorldImpactBuilder impactBuilder, Set<ClassEntity> classes, cause) {
    for (ClassEntity cls in classes) {
      if (!_unusedClasses.contains(cls)) {
        // No need to add [classElement] to [impactBuilder]: it has already been
        // instantiated and we don't track origins of native instantiations
        // precisely.
        continue;
      }
      impactBuilder.registerTypeUse(
          new TypeUse.nativeInstantiation(_elementEnvironment.getRawType(cls)));
    }
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
    Set<ClassEntity> matchingClasses = new Set<ClassEntity>();
    for (var type in behavior.typesInstantiated) {
      if (type is SpecialType) {
        if (type == SpecialType.JsObject) {
          registerInstantiation(_commonElements.objectType);
        }
        continue;
      }
      if (type is InterfaceType) {
        if (type == _commonElements.numType) {
          registerInstantiation(_commonElements.doubleType);
          registerInstantiation(_commonElements.intType);
        } else if (type == _commonElements.intType ||
            type == _commonElements.doubleType ||
            type == _commonElements.stringType ||
            type == _commonElements.nullType ||
            type == _commonElements.boolType ||
            _dartTypes.isSubtype(type,
                _elementEnvironment.getRawType(_commonElements.jsArrayClass))) {
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
            .addAll(_findUnusedClassesMatching((ClassEntity nativeClass) {
          InterfaceType nativeType =
              _elementEnvironment.getThisType(nativeClass);
          InterfaceType specType =
              _elementEnvironment.getThisType(type.element);
          return _dartTypes.isSubtype(nativeType, specType);
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
    if (unusedBefore > 0 && unusedBefore == matchingClasses.length) {
      _allUsedMessage ??= 'All native types marked as used due to $cause.';
    }
  }

  Iterable<ClassEntity> _findUnusedClassesMatching(
      bool predicate(ClassEntity classElement)) {
    return _unusedClasses.where(predicate);
  }

  void _registerBackendUse(FunctionEntity element) {}

  Iterable<ClassEntity> _onFirstNativeClass(WorldImpactBuilder impactBuilder) {
    void staticUse(FunctionEntity element) {
      impactBuilder.registerStaticUse(new StaticUse.implicitInvoke(element));
      _registerBackendUse(element);
    }

    staticUse(_commonElements.defineProperty);
    staticUse(_commonElements.toStringForNativeObject);
    staticUse(_commonElements.hashCodeForNativeObject);
    staticUse(_commonElements.closureConverter);
    return _findNativeExceptions();
  }

  Iterable<ClassEntity> _findNativeExceptions() {
    return _findUnusedClassesMatching((ClassEntity classElement) {
      // TODO(sra): Annotate exception classes in dart:html.
      String name = classElement.name;
      if (name.contains('Exception')) return true;
      if (name.contains('Error')) return true;
      return false;
    });
  }

  void logSummary(void log(String message)) {
    if (_allUsedMessage != null) {
      log(_allUsedMessage);
    }
  }
}

class NativeResolutionEnqueuer extends NativeEnqueuerBase {
  final NativeClassFinder _nativeClassFinder;
  final BackendUsageBuilder _backendUsageBuilder;

  /// The set of all native classes.  Each native class is in [nativeClasses]
  /// and exactly one of [unusedClasses] and [registeredClasses].
  final Set<ClassEntity> _nativeClasses = new Set<ClassEntity>();

  NativeResolutionEnqueuer(
      CompilerOptions options,
      ElementEnvironment elementEnvironment,
      CommonElements commonElements,
      DartTypes dartTypes,
      this._backendUsageBuilder,
      this._nativeClassFinder)
      : super(options, elementEnvironment, commonElements, dartTypes);

  Iterable<ClassEntity> get nativeClassesForTesting => _nativeClasses;

  Iterable<ClassEntity> get registeredClassesForTesting => _registeredClasses;

  void _registerBackendUse(FunctionEntity element) {
    _backendUsageBuilder.registerBackendFunctionUse(element);
    _backendUsageBuilder.registerGlobalFunctionDependency(element);
  }

  WorldImpact processNativeClasses(Iterable<LibraryEntity> libraries) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    Iterable<ClassEntity> nativeClasses =
        _nativeClassFinder.computeNativeClasses(libraries);
    _nativeClasses.addAll(nativeClasses);
    _unusedClasses.addAll(nativeClasses);
    if (!enableLiveTypeAnalysis) {
      _registerTypeUses(impactBuilder, _nativeClasses, 'forced');
    }
    return impactBuilder;
  }

  void logSummary(void log(String message)) {
    super.logSummary(log);
    log('Resolved ${_registeredClasses.length} native elements used, '
        '${_unusedClasses.length} native elements dead.');
  }
}

class NativeCodegenEnqueuer extends NativeEnqueuerBase {
  final CodeEmitterTask _emitter;
  final NativeResolutionEnqueuer _resolutionEnqueuer;
  final NativeData _nativeData;

  final Set<ClassEntity> _doneAddSubtypes = new Set<ClassEntity>();

  NativeCodegenEnqueuer(
      CompilerOptions options,
      ElementEnvironment elementEnvironment,
      CommonElements commonElements,
      DartTypes dartTypes,
      this._emitter,
      this._resolutionEnqueuer,
      this._nativeData)
      : super(options, elementEnvironment, commonElements, dartTypes);

  WorldImpact processNativeClasses(Iterable<LibraryEntity> libraries) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    _unusedClasses.addAll(_resolutionEnqueuer._nativeClasses);

    if (!enableLiveTypeAnalysis) {
      _registerTypeUses(
          impactBuilder, _resolutionEnqueuer._nativeClasses, 'forced');
    }

    // HACK HACK - add all the resolved classes.
    Set<ClassEntity> matchingClasses = new Set<ClassEntity>();
    for (ClassEntity classElement in _resolutionEnqueuer._registeredClasses) {
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
      WorldImpactBuilder impactBuilder, Set<ClassEntity> classes, cause) {
    super._registerTypeUses(impactBuilder, classes, cause);

    for (ClassEntity classElement in classes) {
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

  void logSummary(void log(String message)) {
    super.logSummary(log);
    log('Compiled ${_registeredClasses.length} native classes, '
        '${_unusedClasses.length} native classes omitted.');
  }
}
