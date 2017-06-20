// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Analysis to determine how to generate code for `LookupMap`s.
library compiler.src.js_backend.lookup_map_analysis;

import 'package:pub_semver/pub_semver.dart';

import '../common.dart';
import '../common_elements.dart';
import '../compile_time_constants.dart';
import '../constants/constant_system.dart';
import '../constants/values.dart'
    show
        ConstantValue,
        ConstructedConstantValue,
        ListConstantValue,
        NullConstantValue,
        StringConstantValue,
        TypeConstantValue;
import '../elements/elements.dart' show FieldElement;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../universe/use.dart' show ConstantUse, StaticUse;
import '../universe/world_impact.dart'
    show WorldImpact, StagedWorldImpactBuilder;

/// Lookup map handling for resolution.
///
/// This analysis checks for the import of `package:lookup_map/lookup_map.dart`,
/// and if found, read the `_version` variable from it.
///
/// In [LookupMapAnalysis] the value of `_version` is checked to ensure that it
/// is valid to perform the optimization of `LookupMap`. The actual optimization
/// is performed by [LookupMapAnalysis].
class LookupMapResolutionAnalysis {
  static final Uri PACKAGE_LOOKUP_MAP =
      new Uri(scheme: 'package', path: 'lookup_map/lookup_map.dart');

  /// Reference the diagnostic reporting system for logging and reporting issues
  /// to the end-user.
  final DiagnosticReporter _reporter;

  final ElementEnvironment _elementEnvironment;

  /// The resolved [FieldEntity] associated with the top-level `_version`.
  FieldEntity lookupMapVersionVariable;

  /// The resolved [LibraryEntity] associated with
  /// `package:lookup_map/lookup_map.dart`.
  LibraryEntity lookupMapLibrary;

  final StagedWorldImpactBuilder _impactBuilder =
      new StagedWorldImpactBuilder();

  LookupMapResolutionAnalysis(this._reporter, this._elementEnvironment);

  /// Compute the [WorldImpact] for the constants registered since last flush.
  WorldImpact flush() {
    return _impactBuilder.flush();
  }

  /// Initializes this analysis by providing the resolved library. This is
  /// invoked during resolution when the `lookup_map` library is discovered.
  void init(LibraryEntity library) {
    lookupMapLibrary = library;
    // We will enable the lookupMapAnalysis as long as we get a known version of
    // the lookup_map package. We otherwise produce a warning.
    lookupMapVersionVariable =
        _elementEnvironment.lookupLibraryMember(lookupMapLibrary, '_version');
    if (lookupMapVersionVariable == null) {
      _reporter.reportHintMessage(
          library, MessageKind.UNRECOGNIZED_VERSION_OF_LOOKUP_MAP);
    } else {
      _impactBuilder
          .registerStaticUse(new StaticUse.staticGet(lookupMapVersionVariable));
    }
  }
}

/// An analysis and optimization to remove unused entries from a `LookupMap`.
///
/// `LookupMaps` are defined in `package:lookup_map/lookup_map.dart`. They are
/// simple maps that contain constant expressions as keys, and that only support
/// the lookup operation.
///
/// This analysis and optimization will tree-shake the contents of the maps by
/// looking at the program and finding which keys are clearly unused. Not all
/// constants can be approximated statically, so this optimization is limited to
/// the following keys:
///
///   * Const expressions that can only be created via const constructors. This
///   excludes primitives, strings, and any const type that overrides the ==
///   operator.
///
///   * Type literals.
///
/// Type literals are more complex than const expressions because they can be
/// created in multiple ways. We can approximate the possible set of keys if we
/// follow these rules:
///
///   * Include all type-literals used explicitly in the code (excluding
///   obviously the uses that can be removed from LookupMaps)
///
///   * Include every reflectable type-literal if a mirror API is used to create
///   types (e.g.  ClassMirror.reflectedType).
///
///   * Include all allocated types if the program contains `e.runtimeType`
///   expressions.
///
///   * Include all generic-type arguments, if the program uses type
///   variables in expressions such as `class A<T> { Type get extract => T }`.
///
// TODO(sigmund): add support for const expressions, currently this
// implementation only supports Type literals. To support const expressions we
// need to change some of the invariants below (e.g. we can no longer use the
// ClassEntity of a type to refer to keys we need to discover).
// TODO(sigmund): detect uses of mirrors
class LookupMapAnalysis {
  const LookupMapAnalysis._();

  factory LookupMapAnalysis(
      DiagnosticReporter reporter,
      ConstantSystem constantSystem,
      ConstantEnvironment constants,
      ElementEnvironment elementEnvironment,
      CommonElements commonElements,
      LookupMapResolutionAnalysis analysis) {
    /// Checks if the version of lookup_map is valid, and if so, enable this
    /// analysis during codegen.
    FieldElement lookupMapVersionVariable = analysis.lookupMapVersionVariable;
    if (lookupMapVersionVariable == null) return const LookupMapAnalysis._();

    // At this point, the lookupMapVersionVariable should be resolved and it's
    // constant value should be available.
    StringConstantValue value =
        constants.getConstantValue(lookupMapVersionVariable.constant);
    if (value == null) {
      reporter.reportHintMessage(lookupMapVersionVariable,
          MessageKind.UNRECOGNIZED_VERSION_OF_LOOKUP_MAP);
      return const LookupMapAnalysis._();
    }

    // TODO(sigmund): add proper version resolution using the pub_semver package
    // when we introduce the next version.
    Version version;
    try {
      version = new Version.parse(value.primitiveValue);
    } catch (e) {}

    if (version == null || !_validLookupMapVersionConstraint.allows(version)) {
      reporter.reportHintMessage(lookupMapVersionVariable,
          MessageKind.UNRECOGNIZED_VERSION_OF_LOOKUP_MAP);
      return const LookupMapAnalysis._();
    }

    ClassEntity typeLookupMapClass =
        elementEnvironment.lookupClass(analysis.lookupMapLibrary, 'LookupMap');
    FieldEntity entriesField =
        elementEnvironment.lookupClassMember(typeLookupMapClass, '_entries');
    FieldEntity keyField =
        elementEnvironment.lookupClassMember(typeLookupMapClass, '_key');
    FieldEntity valueField =
        elementEnvironment.lookupClassMember(typeLookupMapClass, '_value');
    // TODO(sigmund): Maybe inline nested maps to make the output code smaller?

    return new _LookupMapAnalysis(constantSystem, elementEnvironment,
        commonElements, entriesField, keyField, valueField, typeLookupMapClass);
  }

  /// Compute the [WorldImpact] for the constants registered since last flush.
  WorldImpact flush() => const WorldImpact();

  /// Whether [constant] is an instance of a `LookupMap`.
  bool isLookupMap(ConstantValue constant) => false;

  /// Registers an instance of a lookup-map with the analysis.
  void registerLookupMapReference(ConstantValue lookupMap) {}

  /// Callback from the enqueuer, invoked when [element] is instantiated.
  void registerInstantiatedClass(ClassEntity element) {}

  /// Callback from the enqueuer, invoked when [type] is instantiated.
  void registerInstantiatedType(InterfaceType type) {}

  /// Callback from the codegen enqueuer, invoked when a constant (which is
  /// possibly a const key or a type literal) is used in the program.
  void registerTypeConstant(ClassEntity element) {}

  void registerConstantKey(ConstantValue constant) {}

  void logSummary(void log(String message)) {}

  void onQueueClosed() {}
}

class _LookupMapAnalysis implements LookupMapAnalysis {
  static final Uri PACKAGE_LOOKUP_MAP =
      new Uri(scheme: 'package', path: 'lookup_map/lookup_map.dart');

  final ConstantSystem _constantSystem;

  final ElementEnvironment _elementEnvironment;

  final CommonElements _commonElements;

  /// The resolved [ClassEntity] associated with `LookupMap`.
  final ClassEntity _typeLookupMapClass;

  /// The resolved [FieldEntity] for `LookupMap._entries`.
  final FieldEntity _entriesField;

  /// The resolved [FieldEntity] for `LookupMap._key`.
  final FieldEntity _keyField;

  /// The resolved [FieldEntity] for `LookupMap._value`.
  final FieldEntity _valueField;

  /// Constant instances of `LookupMap` and information about them tracked by
  /// this analysis.
  final Map<ConstantValue, _LookupMapInfo> _lookupMaps = {};

  /// Keys that we have discovered to be in use in the program.
  final Set<ConstantValue> _inUse = new Set<ConstantValue>();

  /// Internal helper to memoize the mapping between class elements and their
  /// corresponding type constants.
  final Map<ClassEntity, TypeConstantValue> _typeConstants =
      <ClassEntity, TypeConstantValue>{};

  /// Internal helper to memoize which classes (ignoring Type) override equals.
  ///
  /// Const keys of these types will not be tree-shaken because we can't
  /// statically guarantee that the program doesn't produce an equivalent key at
  /// runtime. Technically if we limit lookup-maps to check for identical keys,
  /// we could allow const instances of these types.  However, we internally use
  /// a hash map within lookup-maps today, so we need this restriction.
  final Map<ClassEntity, bool> _typesWithEquals = <ClassEntity, bool>{};

  /// Pending work to do if we discover that a new key is in use. For each key
  /// that we haven't seen, we record the list of lookup-maps that contain an
  /// entry with that key.
  final _pending = <ConstantValue, List<_LookupMapInfo>>{};

  final StagedWorldImpactBuilder _impactBuilder =
      new StagedWorldImpactBuilder();

  _LookupMapAnalysis(
      this._constantSystem,
      this._elementEnvironment,
      this._commonElements,
      this._entriesField,
      this._keyField,
      this._valueField,
      this._typeLookupMapClass);

  /// Compute the [WorldImpact] for the constants registered since last flush.
  WorldImpact flush() {
    return _impactBuilder.flush();
  }

  /// Whether [constant] is an instance of a `LookupMap`.
  bool isLookupMap(ConstantValue constant) {
    if (constant is ConstructedConstantValue) {
      InterfaceType type = constant.type;
      ClassEntity superclass = type.element;
      while (superclass != null) {
        if (superclass == _typeLookupMapClass) return true;
        superclass = _elementEnvironment.getSuperClass(superclass);
      }
    }
    return false;
  }

  /// Registers an instance of a lookup-map with the analysis.
  void registerLookupMapReference(ConstantValue lookupMap) {
    assert(isLookupMap(lookupMap));
    _lookupMaps.putIfAbsent(
        lookupMap, () => new _LookupMapInfo(lookupMap, this).._updateUsed());
  }

  /// Whether [key] is a constant value whose type overrides equals.
  bool _overridesEquals(ConstantValue key) {
    if (key is ConstructedConstantValue) {
      ClassEntity element = key.type.element;
      return _typesWithEquals.putIfAbsent(element, () {
        ClassEntity cls = element;
        while (cls != _commonElements.objectClass) {
          MemberEntity member =
              _elementEnvironment.lookupClassMember(cls, '==');
          if (member != null) {
            return true;
          }
          cls = _elementEnvironment.getSuperClass(cls);
        }
        return false;
      });
    }
    return false;
  }

  /// Whether we need to preserve [key]. This is true for keys that are not
  /// candidates for tree-shaking in the first place (primitives and non-type
  /// const values overriding equals) and keys that we have seen in the program.
  bool _shouldKeep(ConstantValue key) =>
      key.isPrimitive || _inUse.contains(key) || _overridesEquals(key);

  void _addClassUse(ClassEntity cls) {
    TypeConstantValue f() => _constantSystem.createType(
        _commonElements, _elementEnvironment.getRawType(cls));
    ConstantValue key = _typeConstants.putIfAbsent(cls, f);
    _addUse(key);
  }

  /// Record that [key] is used and update every lookup map that contains it.
  void _addUse(ConstantValue key) {
    if (_inUse.add(key)) {
      _pending[key]?.forEach((info) => info._markUsed(key));
      _pending.remove(key);
    }
  }

  /// If [key] is a type, cache it in [_typeConstants].
  _registerTypeKey(ConstantValue key) {
    if (key is TypeConstantValue && key.representedType is InterfaceType) {
      InterfaceType type = key.representedType;
      _typeConstants[type.element] = key;
    } else {
      // TODO(sigmund): report error?
    }
  }

  /// Callback from the enqueuer, invoked when [element] is instantiated.
  void registerInstantiatedClass(ClassEntity element) {
    // TODO(sigmund): only add if .runtimeType is ever used
    _addClassUse(element);
  }

  /// Callback from the enqueuer, invoked when [type] is instantiated.
  void registerInstantiatedType(InterfaceType type) {
    // TODO(sigmund): only add if .runtimeType is ever used
    _addClassUse(type.element);
    // TODO(sigmund): only do this when type-argument expressions are used?
    _addGenerics(type);
  }

  /// Records generic type arguments in [type], in case they are retrieved and
  /// returned using a type-argument expression.
  void _addGenerics(InterfaceType type) {
    if (type.typeArguments.isEmpty) return;
    for (DartType arg in type.typeArguments) {
      if (arg is InterfaceType) {
        _addClassUse(arg.element);
        // Note: this call was needed to generate correct code for
        // type_lookup_map/generic_type_test
        // TODO(sigmund): can we get rid of this?
        _impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            _commonElements.createRuntimeType,
            null));
        _addGenerics(arg);
      }
    }
  }

  /// Callback from the codegen enqueuer, invoked when a constant (which is
  /// possibly a const key or a type literal) is used in the program.
  void registerTypeConstant(ClassEntity element) {
    _addClassUse(element);
  }

  void registerConstantKey(ConstantValue constant) {
    if (constant.isPrimitive || _overridesEquals(constant)) return;
    _addUse(constant);
  }

  void logSummary(void log(String message)) {
    // When --verbose is passed, we show the total number and set of keys that
    // were tree-shaken from lookup maps.
    var sb = new StringBuffer();
    int count = 0;
    for (var info in _lookupMaps.values) {
      for (var key in info.unusedEntries.keys) {
        if (count != 0) sb.write(',');
        sb.write(key.toDartText());
        count++;
      }
    }
    log(count == 0
        ? 'lookup-map: nothing was tree-shaken'
        : 'lookup-map: found $count unused keys ($sb)');
  }

  /// Callback from the backend, invoked when reaching the end of the enqueuing
  /// process, but before emitting the code. At this moment we have discovered
  /// all types used in the program and we can tree-shake anything that is
  /// unused.
  void onQueueClosed() {
    _lookupMaps.values.forEach((info) {
      assert(!info.emitted);
      info.emitted = true;
      info._prepareForEmission();
    });

    // Release resources.
    _lookupMaps.clear();
    _pending.clear();
    _inUse.clear();
  }
}

/// Internal information about the entries on a lookup-map.
class _LookupMapInfo {
  /// The original reference to the constant value.
  ///
  /// This reference will be mutated in place to remove it's entries when the
  /// map is first seen during codegen, and to restore them (or a subset of
  /// them) when we have finished discovering which entries are used. This has
  /// the side-effect that `orignal.getDependencies()` will be empty during
  /// most of codegen until we are ready to emit the constants. However,
  /// restoring the entries before emitting code lets us keep the emitter logic
  /// agnostic of this optimization.
  final ConstructedConstantValue original;

  /// Reference to the lookup map analysis to be able to refer to data shared
  /// across infos.
  final _LookupMapAnalysis analysis;

  /// Whether we have already emitted this constant.
  bool emitted = false;

  /// Whether the `LookupMap` constant was built using the `LookupMap.pair`
  /// constructor.
  bool singlePair;

  /// Entries in the lookup map whose keys have not been seen in the rest of the
  /// program.
  Map<ConstantValue, ConstantValue> unusedEntries =
      <ConstantValue, ConstantValue>{};

  /// Entries that have been used, and thus will be part of the generated code.
  Map<ConstantValue, ConstantValue> usedEntries =
      <ConstantValue, ConstantValue>{};

  /// Creates and initializes the information containing all keys of the
  /// original map marked as unused.
  _LookupMapInfo(this.original, this.analysis) {
    ConstantValue key = original.fields[analysis._keyField];
    singlePair = !key.isNull;

    if (singlePair) {
      unusedEntries[key] = original.fields[analysis._valueField];

      // Note: we modify the constant in-place, see comment in [original].
      original.fields[analysis._keyField] = new NullConstantValue();
      original.fields[analysis._valueField] = new NullConstantValue();
    } else {
      ListConstantValue list = original.fields[analysis._entriesField];
      List<ConstantValue> keyValuePairs = list.entries;
      for (int i = 0; i < keyValuePairs.length; i += 2) {
        ConstantValue key = keyValuePairs[i];
        unusedEntries[key] = keyValuePairs[i + 1];
      }

      // Note: we modify the constant in-place, see comment in [original].
      original.fields[analysis._entriesField] =
          new ListConstantValue(list.type, []);
    }
  }

  /// Check every key in unusedEntries and mark it as used if the analysis has
  /// already discovered them. This is meant to be called once to finalize
  /// initialization after constructing an instance of this class. Afterwards,
  /// we call [_markUsed] on each individual key as it gets discovered.
  void _updateUsed() {
    // Note: we call toList because `_markUsed` modifies the map.
    for (ConstantValue key in unusedEntries.keys.toList()) {
      analysis._registerTypeKey(key);
      if (analysis._shouldKeep(key)) {
        _markUsed(key);
      } else {
        analysis._pending.putIfAbsent(key, () => []).add(this);
      }
    }
  }

  /// Marks that [key] has been seen, and thus, the corresponding entry in this
  /// map should be considered reachable.
  _markUsed(ConstantValue key) {
    assert(!emitted);
    assert(unusedEntries.containsKey(key));
    assert(!usedEntries.containsKey(key));
    ConstantValue constant = unusedEntries.remove(key);
    usedEntries[key] = constant;
    analysis._impactBuilder
        .registerConstantUse(new ConstantUse.lookupMap(constant));
  }

  /// Restores [original] to contain all of the entries marked as possibly used.
  void _prepareForEmission() {
    ListConstantValue originalEntries = original.fields[analysis._entriesField];
    InterfaceType listType = originalEntries.type;
    List<ConstantValue> keyValuePairs = <ConstantValue>[];
    usedEntries.forEach((key, value) {
      keyValuePairs.add(key);
      keyValuePairs.add(value);
    });

    // Note: we are restoring the entries here, see comment in [original].
    if (singlePair) {
      assert(keyValuePairs.length == 0 || keyValuePairs.length == 2);
      if (keyValuePairs.length == 2) {
        original.fields[analysis._keyField] = keyValuePairs[0];
        original.fields[analysis._valueField] = keyValuePairs[1];
      }
    } else {
      original.fields[analysis._entriesField] =
          new ListConstantValue(listType, keyValuePairs);
    }
  }
}

final _validLookupMapVersionConstraint = new VersionConstraint.parse('^0.0.1');
