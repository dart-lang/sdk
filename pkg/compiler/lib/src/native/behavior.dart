// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/elements.dart' show CommonElements, ElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as js;
import '../js_backend/native_data.dart' show NativeBasicData;
import '../js_model/js_to_frontend_map.dart' show JsToFrontendMap;
import '../options.dart';
import '../serialization/serialization.dart';
import '../universe/side_effects.dart' show SideEffects;
import 'js.dart';

import 'native_throw_behavior.dart';
export 'native_throw_behavior.dart';

typedef TypeLookup = Object? /*DartType|SpecialType*/
    Function(String typeString, {bool required});

/// This class is a temporary workaround until we get a more powerful DartType.
class SpecialType {
  final String name;
  const SpecialType._(this.name);

  /// The type Object, but no subtypes:
  static const JsObject = SpecialType._('=Object');

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;

  static SpecialType fromName(String name) {
    if (name == '=Object') {
      return JsObject;
    } else {
      throw UnsupportedError("Unknown SpecialType '$name'.");
    }
  }
}

/// A summary of the behavior of a native element.
///
/// Native code can return values of one type and cause native subtypes of
/// another type to be instantiated.  By default, we compute both from the
/// declared type.
///
/// A field might yield any native type that 'is' the field type.
///
/// A method might create and return instances of native subclasses of its
/// declared return type, and a callback argument may be called with instances
/// of the callback parameter type (e.g. Event).
///
/// If there is one or more `@Creates` annotations, the union of the named types
/// replaces the inferred instantiated type, and the return type is ignored for
/// the purpose of inferring instantiated types.
///
///     @Creates('IDBCursor')    // Created asynchronously.
///     @Creates('IDBRequest')   // Created synchronously (for return value).
///     IDBRequest openCursor();
///
/// If there is one or more `@Returns` annotations, the union of the named types
/// replaces the declared return type.
///
///     @Returns('IDBRequest')
///     IDBRequest openCursor();
///
/// Types in annotations are non-nullable, so include `@Returns('Null')` if
/// `null` may be returned.
class NativeBehavior {
  /// Tag used for identifying serialized [NativeBehavior] objects in a
  /// debugging data stream.
  static const String tag = 'native-behavior';

  /// [DartType]s or [SpecialType]s returned or yielded by the native
  /// element.
  final List<Object> typesReturned = [];

  /// [DartType]s or [SpecialType]s instantiated by the native
  /// element.
  final List<Object> typesInstantiated = [];

  String? codeTemplateText;
  // If this behavior is for a JS expression, [codeTemplate] contains the
  // parsed tree.
  js.Template? codeTemplate;

  final SideEffects sideEffects;

  NativeThrowBehavior throwBehavior = NativeThrowBehavior.MAY;

  bool isAllocation = false;
  bool useGvn = false;

  // TODO(sra): Make NativeBehavior immutable so PURE and PURE_ALLOCATION can be
  // final constant-like objects.
  static NativeBehavior get PURE => NativeBehavior._makePure();
  static NativeBehavior get PURE_ALLOCATION =>
      NativeBehavior._makePure(isAllocation: true);
  static NativeBehavior get CHANGES_OTHER => NativeBehavior._makeChangesOther();
  static NativeBehavior get DEPENDS_OTHER => NativeBehavior._makeDependsOther();

  NativeBehavior() : sideEffects = SideEffects.empty();

  NativeBehavior.internal(this.sideEffects);

  /// Deserializes a [NativeBehavior] object from [source].
  factory NativeBehavior.readFromDataSource(DataSourceReader source) {
    source.begin(tag);

    List<Object> readTypes() {
      List<Object> types = [];
      types.addAll(source.readDartTypes());
      int specialCount = source.readInt();
      for (int i = 0; i < specialCount; i++) {
        String name = source.readString();
        types.add(SpecialType.fromName(name));
      }
      return types;
    }

    List<Object> typesReturned = readTypes();
    List<Object> typesInstantiated = readTypes();
    String? codeTemplateText = source.readStringOrNull();
    SideEffects sideEffects = SideEffects.readFromDataSource(source);
    int throwBehavior = source.readInt();
    bool isAllocation = source.readBool();
    bool useGvn = source.readBool();
    source.end(tag);

    NativeBehavior behavior = NativeBehavior.internal(sideEffects);
    behavior.typesReturned.addAll(typesReturned);
    behavior.typesInstantiated.addAll(typesInstantiated);
    if (codeTemplateText != null) {
      behavior.codeTemplateText = codeTemplateText;
      behavior.codeTemplate = js.js.parseForeignJS(codeTemplateText);
    }
    behavior.throwBehavior = NativeThrowBehavior.bitsToValue(throwBehavior);
    assert(behavior.throwBehavior.valueToBits() == throwBehavior);
    behavior.isAllocation = isAllocation;
    behavior.useGvn = useGvn;
    return behavior;
  }

  /// Serializes this [NativeBehavior] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);

    void writeTypes(List<Object> types) {
      List<DartType> dartTypes = [];
      List<SpecialType> specialTypes = [];
      for (var type in types) {
        if (type is DartType) {
          dartTypes.add(type);
        } else {
          specialTypes.add(type as SpecialType);
        }
      }
      sink.writeDartTypes(dartTypes);
      sink.writeInt(specialTypes.length);
      for (SpecialType type in specialTypes) {
        sink.writeString(type.name);
      }
    }

    writeTypes(typesReturned);
    writeTypes(typesInstantiated);
    sink.writeStringOrNull(codeTemplateText);
    sideEffects.writeToDataSink(sink);
    sink.writeInt(throwBehavior.valueToBits());
    sink.writeBool(isAllocation);
    sink.writeBool(useGvn);
    sink.end(tag);
  }

  @override
  String toString() {
    return 'NativeBehavior('
        'returns: ${typesReturned}'
        ', creates: ${typesInstantiated}'
        ', sideEffects: ${sideEffects}'
        ', throws: ${throwBehavior}'
        '${isAllocation ? ", isAllocation" : ""}'
        '${useGvn ? ", useGvn" : ""}'
        ')';
  }

  static NativeBehavior _makePure({bool isAllocation = false}) {
    NativeBehavior behavior = NativeBehavior();
    behavior.sideEffects.clearAllDependencies();
    behavior.sideEffects.clearAllSideEffects();
    behavior.throwBehavior = NativeThrowBehavior.NEVER;
    behavior.isAllocation = isAllocation;
    return behavior;
  }

  static NativeBehavior _makeChangesOther() {
    // TODO(25544): Have a distinct effect instead of using static properties to
    // model 'other' effects.
    return _makePure()..sideEffects.setChangesStaticProperty();
  }

  static NativeBehavior _makeDependsOther() {
    // TODO(25544): Have a distinct effect instead of using static properties to
    // model 'other' effects.
    return _makePure()..sideEffects.setDependsOnStaticPropertyStore();
  }

  /// Processes the type specification string of a call to JS and stores the
  /// result in the [typesReturned] and [typesInstantiated]. It furthermore
  /// computes the side effects, and, if given, invokes [setSideEffects] with
  /// the computed effects. If no side effects are encoded in the [specString]
  /// the [setSideEffects] method is not invoked.
  ///
  /// Two forms of the string is supported:
  ///
  /// 1) A single type string of the form 'void', '', 'var' or 'T1|...|Tn' which
  ///    defines the types returned, and, for the last form, the types also
  ///    created by the call to JS.  'var' (and '') are like 'dynamic' or
  ///    'Object' except that 'dynamic' would indicate that objects of any type
  ///    are created, which defeats tree-shaking.  Think of 'var' (and '') as
  ///    meaning 'any preexisting type'.
  ///
  ///    The types Ti are non-nullable, so add class `Null` to specify a
  ///    nullable type, e.g `'String|Null'`.
  ///
  /// 2) A sequence of <tag>:<value> pairs of the following kinds
  ///
  ///        <type-tag>:<type-string>
  ///        <effect-tag>:<effect-string>
  ///        throws:<throws-string>
  ///        gvn:<gvn-string>
  ///        new:<new-string>
  ///
  ///    A <type-tag> is either 'returns' or 'creates' and <type-string> is a
  ///    type string like in 1). The type string marked by 'returns' defines the
  ///    types returned and 'creates' defines the types created by the call to
  ///    JS. If 'creates' is missing, it defaults to 'returns'.
  ///
  ///    An <effect-tag> is either 'effects' or 'depends' and <effect-string> is
  ///    either 'all', 'none' or a comma-separated list of 'no-index',
  ///    'no-instance', 'no-static'.
  ///
  ///    The flag 'all' indicates that the call affects/depends on every
  ///    side-effect. The flag 'none' indicates that the call does not affect
  ///    (resp. depends on) anything.
  ///
  ///    'no-index' indicates that the call does *not* do any array index-store
  ///    (for 'effects'), or depends on any value in an array (for 'depends').
  ///    The flag 'no-instance' indicates that the call does not modify (resp.
  ///    depends on) any instance variable. Similarly static variables are
  ///    indicated with 'no-static'. The flags 'effects' and 'depends' must be
  ///    used in unison (either both are present or none is).
  ///
  ///    The <throws-string> values are 'never', 'may', 'null(1)', and
  ///    'null(1)+may'.  The default if unspecified is 'may'. 'null(1)' means
  ///    that the template expression throws if and only if the first template
  ///    parameter is `null` or `undefined`, and 'null(1)+may' throws if the
  ///    first argument is `null` / `undefined`, and then may throw for other
  ///    reasons.
  ///
  ///    <gvn-string> values are 'true' and 'false'. The default if unspecified
  ///    is 'false'.
  ///
  ///    <new-string> values are 'true' and 'false'. The default if unspecified
  ///    is 'false'. A 'true' value means that each evaluation returns a fresh
  ///    (new) object that cannot be unaliased with existing objects.
  ///
  ///    Each tag kind (including the 'type-tag's) can only occur once in the
  ///    sequence.
  ///
  /// [specString] is the specification string, [lookupType] resolves named
  /// types into type values, [typesReturned] and [typesInstantiated] collects
  /// the types defined by the specification string, and [objectType] and
  /// [nullType] define the types for `Object` and `Null`, respectively. The
  /// latter is used for the type strings of the form '' and 'var'.
  /// [validTags] can be used to restrict which tags are accepted.
  static void processSpecString(DartTypes dartTypes,
      DiagnosticReporter reporter, Spannable spannable, String specString,
      {Iterable<String>? validTags,
      required void setSideEffects(SideEffects newEffects),
      void Function(NativeThrowBehavior)? setThrows,
      void Function(bool)? setIsAllocation,
      void Function(bool)? setUseGvn,
      required TypeLookup lookupType,
      required List<Object> typesReturned,
      required List<Object> typesInstantiated,
      objectType,
      nullType}) {
    bool seenError = false;

    void reportError(String message) {
      seenError = true;
      reporter.reportErrorMessage(
          spannable, MessageKind.GENERIC, {'text': message});
    }

    const List<String> knownTags = [
      'creates',
      'returns',
      'depends',
      'effects',
      'throws',
      'gvn',
      'new'
    ];

    /// Resolve a type string of one of the three forms:
    /// *  'void' - in which case [onVoid] is called,
    /// *  '' or 'var' - in which case [onVar] is called,
    /// *  'T1|...|Tn' - in which case [onType] is called for each resolved Ti.
    void resolveTypesString(DartTypes dartTypes, String typesString,
        {void Function()? onVoid,
        void Function()? onVar,
        required void Function(Object) onType}) {
      // Various things that are not in fact types.
      if (typesString == 'void') {
        if (onVoid != null) {
          onVoid();
        }
        return;
      }
      if (typesString == '' || typesString == 'var') {
        if (onVar != null) {
          onVar();
        }
        return;
      }
      for (final typeString in typesString.split('|')) {
        onType(_parseType(dartTypes, typeString.trim(), lookupType));
      }
    }

    if (!specString.contains(';') && !specString.contains(':')) {
      // Form (1), types or pseudo-types like 'void' and 'var'.
      resolveTypesString(dartTypes, specString.trim(), onVar: () {
        typesReturned.add(objectType);
        typesReturned.add(nullType);
      }, onType: (type) {
        typesInstantiated.add(type);
        typesReturned.add(type);
      });
      return;
    }

    List<String> specs = specString.split(';').map((s) => s.trim()).toList();
    if (specs.last == "") specs.removeLast(); // Allow separator to terminate.

    assert(
        validTags == null || (validTags.toSet()..removeAll(validTags)).isEmpty);
    if (validTags == null) validTags = knownTags;

    Map<String, String> values = {};

    for (String spec in specs) {
      List<String> tagAndValue = spec.split(':');
      if (tagAndValue.length != 2) {
        reportError("Invalid <tag>:<value> pair '$spec'.");
        continue;
      }
      String tag = tagAndValue[0].trim();
      String value = tagAndValue[1].trim();

      if (validTags.contains(tag)) {
        if (values[tag] == null) {
          values[tag] = value;
        } else {
          reportError("Duplicate tag '$tag'.");
        }
      } else {
        if (knownTags.contains(tag)) {
          reportError("Tag '$tag' is not valid here.");
        } else {
          reportError("Unknown tag '$tag'.");
        }
      }
    }

    // Enum-like tags are looked up in a map. True signature is:
    T? tagValueLookup<T>(String tag, Map<String, T> map) {
      String? tagString = values[tag];
      if (tagString == null) return null;
      var value = map[tagString];
      if (value == null) {
        reportError("Unknown '$tag' specification: '$tagString'.");
      }
      return value;
    }

    String? returns = values['returns'];
    if (returns != null) {
      resolveTypesString(dartTypes, returns, onVar: () {
        typesReturned.add(objectType);
        typesReturned.add(nullType);
      }, onType: (type) {
        typesReturned.add(type);
      });
    }

    String? creates = values['creates'];
    if (creates != null) {
      resolveTypesString(dartTypes, creates, onVoid: () {
        reportError("Invalid type string 'creates:$creates'");
      }, onType: (type) {
        typesInstantiated.add(type);
      });
    } else if (returns != null) {
      resolveTypesString(dartTypes, returns, onType: (type) {
        typesInstantiated.add(type);
      });
    }

    const throwsOption = <String, NativeThrowBehavior>{
      'never': NativeThrowBehavior.NEVER,
      'may': NativeThrowBehavior.MAY,
      'null(1)': NativeThrowBehavior.NULL_NSM,
      'null(1)+may': NativeThrowBehavior.NULL_NSM_THEN_MAY,
    };

    const boolOptions = <String, bool>{'true': true, 'false': false};

    SideEffects? sideEffects =
        processEffects(reportError, values['effects'], values['depends']);
    NativeThrowBehavior? throwsKind = tagValueLookup('throws', throwsOption);
    bool? isAllocation = tagValueLookup('new', boolOptions);
    bool? useGvn = tagValueLookup('gvn', boolOptions);

    if (isAllocation == true && useGvn == true) {
      reportError("'new' and 'gvn' are incompatible");
    }

    if (seenError) return; // Avoid callbacks.

    // TODO(sra): Simplify [throwBehavior] using [sideEffects].

    if (sideEffects != null) setSideEffects(sideEffects);
    if (throwsKind != null) {
      if (setThrows == null) {
        reportError("'throws' not allowed here");
      } else {
        setThrows(throwsKind);
      }
    }
    if (isAllocation != null) {
      if (setIsAllocation == null) {
        reportError("'allocation' not allowed here");
      } else {
        setIsAllocation(isAllocation);
      }
    }
    if (useGvn != null) {
      if (setUseGvn == null) {
        reportError("'gvn' not allowed here");
      } else {
        setUseGvn(useGvn);
      }
    }
  }

  static SideEffects? processEffects(
      void reportError(String message), String? effects, String? depends) {
    if (effects == null && depends == null) return null;

    if (effects == null || depends == null) {
      reportError("'effects' and 'depends' must occur together.");
      return null;
    }

    SideEffects sideEffects = SideEffects();
    if (effects == "none") {
      sideEffects.clearAllSideEffects();
    } else if (effects == "all") {
      // Don't do anything.
    } else {
      List<String> splitEffects = effects.split(",");
      if (splitEffects.isEmpty) {
        reportError("Missing side-effect flag.");
      }
      for (String effect in splitEffects) {
        switch (effect) {
          case "no-index":
            sideEffects.clearChangesIndex();
            break;
          case "no-instance":
            sideEffects.clearChangesInstanceProperty();
            break;
          case "no-static":
            sideEffects.clearChangesStaticProperty();
            break;
          default:
            reportError("Unrecognized side-effect flag: '$effect'.");
        }
      }
    }

    if (depends == "none") {
      sideEffects.clearAllDependencies();
    } else if (depends == "all") {
      // Don't do anything.
    } else {
      List<String> splitDependencies = depends.split(",");
      if (splitDependencies.isEmpty) {
        reportError("Missing side-effect dependency flag.");
      }
      for (String dependency in splitDependencies) {
        switch (dependency) {
          case "no-index":
            sideEffects.clearDependsOnIndexStore();
            break;
          case "no-instance":
            sideEffects.clearDependsOnInstancePropertyStore();
            break;
          case "no-static":
            sideEffects.clearDependsOnStaticPropertyStore();
            break;
          default:
            reportError("Unrecognized side-effect flag: '$dependency'.");
        }
      }
    }

    return sideEffects;
  }

  /// Compute the [NativeBehavior] for a call to the 'JS' function with the
  /// given [specString] and [codeString] (first and second arguments).
  static NativeBehavior ofJsCall(
      String specString,
      String codeString,
      TypeLookup lookupType,
      Spannable spannable,
      DiagnosticReporter reporter,
      CommonElements commonElements) {
    // The first argument of a JS-call is a string encoding various attributes
    // of the code.
    //
    //  'Type1|Type2'.  A union type.
    //  '=Object'.      A JavaScript Object, no subtype.

    NativeBehavior behavior = NativeBehavior();

    behavior.codeTemplateText = codeString;
    behavior.codeTemplate = js.js.parseForeignJS(codeString);

    bool sideEffectsAreEncodedInSpecString = false;

    void setSideEffects(SideEffects newEffects) {
      sideEffectsAreEncodedInSpecString = true;
      behavior.sideEffects.setTo(newEffects);
    }

    bool throwBehaviorFromSpecString = false;
    void setThrows(NativeThrowBehavior throwBehavior) {
      throwBehaviorFromSpecString = true;
      behavior.throwBehavior = throwBehavior;
    }

    void setIsAllocation(bool isAllocation) {
      behavior.isAllocation = isAllocation;
    }

    void setUseGvn(bool useGvn) {
      behavior.useGvn = useGvn;
    }

    processSpecString(commonElements.dartTypes, reporter, spannable, specString,
        setSideEffects: setSideEffects,
        setThrows: setThrows,
        setIsAllocation: setIsAllocation,
        setUseGvn: setUseGvn,
        lookupType: lookupType,
        typesReturned: behavior.typesReturned,
        typesInstantiated: behavior.typesInstantiated,
        objectType: commonElements.objectType,
        nullType: commonElements.nullType);

    if (!sideEffectsAreEncodedInSpecString) {
      SideEffectsVisitor(behavior.sideEffects)
          .visit(behavior.codeTemplate!.ast);
    }
    if (!throwBehaviorFromSpecString) {
      behavior.throwBehavior =
          ThrowBehaviorVisitor().analyze(behavior.codeTemplate!.ast);
    }

    return behavior;
  }

  static void _fillNativeBehaviorOfBuiltinOrEmbeddedGlobal(
      NativeBehavior behavior,
      Spannable spannable,
      String specString,
      TypeLookup lookupType,
      DiagnosticReporter reporter,
      CommonElements commonElements,
      {List<String>? validTags}) {
    void setSideEffects(SideEffects newEffects) {
      behavior.sideEffects.setTo(newEffects);
    }

    processSpecString(commonElements.dartTypes, reporter, spannable, specString,
        validTags: validTags,
        lookupType: lookupType,
        setSideEffects: setSideEffects,
        typesReturned: behavior.typesReturned,
        typesInstantiated: behavior.typesInstantiated,
        objectType: commonElements.objectType,
        nullType: commonElements.nullType);
  }

  static NativeBehavior ofJsBuiltinCall(
      String specString,
      TypeLookup lookupType,
      Spannable spannable,
      DiagnosticReporter reporter,
      CommonElements commonElements) {
    NativeBehavior behavior = NativeBehavior();
    behavior.sideEffects.setTo(SideEffects());
    _fillNativeBehaviorOfBuiltinOrEmbeddedGlobal(
        behavior, spannable, specString, lookupType, reporter, commonElements);
    return behavior;
  }

  static NativeBehavior ofJsEmbeddedGlobalCall(
      String specString,
      TypeLookup lookupType,
      Spannable spannable,
      DiagnosticReporter reporter,
      CommonElements commonElements) {
    NativeBehavior behavior = NativeBehavior();
    // TODO(sra): Allow the use site to override these defaults.
    // Embedded globals are usually pre-computed data structures or JavaScript
    // functions that never change.
    behavior.sideEffects.setTo(SideEffects.empty());
    behavior.throwBehavior = NativeThrowBehavior.NEVER;
    _fillNativeBehaviorOfBuiltinOrEmbeddedGlobal(
        behavior, spannable, specString, lookupType, reporter, commonElements,
        validTags: ['returns', 'creates']);
    return behavior;
  }

  static Object /*DartType|SpecialType*/ _parseType(
      DartTypes dartTypes, String typeString, TypeLookup lookupType) {
    if (typeString == '=Object') return SpecialType.JsObject;
    if (typeString == 'dynamic') {
      return dartTypes.dynamicType();
    }
    int index = typeString.indexOf('<');
    var type = lookupType(typeString, required: index == -1);
    if (type != null) return type;

    if (index != -1) {
      type = lookupType(typeString.substring(0, index), required: true);
      if (type != null) {
        // TODO(sra): Parse type parameters.
        return type;
      }
    }
    return dartTypes.dynamicType();
  }

  Object _convertNativeBehaviorType(JsToFrontendMap map, Object type) {
    if (type is DartType) {
      // TODO(johnniwinther): Avoid free variables in types. If the type
      // pulled from a generic function type it might contain a function
      // type variable that should probably have been replaced by its bound.
      return map.toBackendType(type, allowFreeVariables: true)!;
    }
    assert(type is SpecialType);
    return type;
  }

  NativeBehavior convert(JsToFrontendMap map) {
    final newBehavior = NativeBehavior();
    for (Object type in typesReturned) {
      newBehavior.typesReturned.add(_convertNativeBehaviorType(map, type));
    }
    for (Object type in typesInstantiated) {
      newBehavior.typesInstantiated.add(_convertNativeBehaviorType(map, type));
    }
    newBehavior.codeTemplateText = codeTemplateText;
    newBehavior.codeTemplate = codeTemplate;
    newBehavior.throwBehavior = throwBehavior;
    newBehavior.isAllocation = isAllocation;
    newBehavior.useGvn = useGvn;
    newBehavior.sideEffects.add(sideEffects);
    return newBehavior;
  }
}

class BehaviorBuilder {
  final ElementEnvironment elementEnvironment;
  final CommonElements commonElements;
  final DiagnosticReporter reporter;
  final NativeBasicData nativeBasicData;
  final CompilerOptions options;
  DartTypes get dartTypes => commonElements.dartTypes;

  late NativeBehavior _behavior;

  BehaviorBuilder(this.elementEnvironment, this.commonElements,
      this.nativeBasicData, this.reporter, this.options);

  void _overrideWithAnnotations(Iterable<String> createsAnnotations,
      Iterable<String> returnsAnnotations, TypeLookup lookupType) {
    if (createsAnnotations.isEmpty && returnsAnnotations.isEmpty) return;

    List<Object>? creates = _collect(createsAnnotations, lookupType);
    List<Object>? returns = _collect(returnsAnnotations, lookupType);

    if (creates != null) {
      _behavior.typesInstantiated
        ..clear()
        ..addAll(creates);
    }
    if (returns != null) {
      _behavior.typesReturned
        ..clear()
        ..addAll(returns);
    }
  }

  /// Returns a list of type constraints from the annotations of
  /// [annotationClass].
  /// Returns `null` if no constraints.
  List<Object>? _collect(Iterable<String> annotations, TypeLookup lookupType) {
    List<Object>? types = null;
    for (String specString in annotations) {
      for (final typeString in specString.split('|')) {
        var type = NativeBehavior._parseType(
            commonElements.dartTypes, typeString, lookupType);
        (types ??= []).add(type);
      }
    }
    return types;
  }

  /// Models the behavior of having instances of [type] escape from Dart code
  /// into native code.
  void _escape(DartType type, bool isJsInterop) {
    type = type.withoutNullability;
    if (type is FunctionType) {
      // A function might be called from native code, passing us novel
      // parameters.
      _escape(type.returnType, isJsInterop);
      for (DartType parameter in type.parameterTypes) {
        _capture(parameter, isJsInterop);
      }
    }
  }

  /// Models the behavior of Dart code receiving instances and methods of [type]
  /// from native code.  We usually start the analysis by capturing a native
  /// method that has been used.
  ///
  /// We assume that JS-interop APIs cannot instantiate Dart types or
  /// non-JSInterop native types.
  void _capture(DartType type, bool isJsInterop) {
    type = type.withoutNullability;
    if (type is FunctionType) {
      FunctionType functionType = type;
      _capture(functionType.returnType, isJsInterop);
      for (DartType parameter in functionType.parameterTypes) {
        _escape(parameter, isJsInterop);
      }
    } else {
      if (!isJsInterop) {
        _behavior.typesInstantiated.add(type);
      } else {
        if (type is InterfaceType &&
            nativeBasicData.isNativeClass(type.element)) {
          // Any declared native or interop type (isNative implies isJsInterop)
          // is assumed to be allocated.
          _behavior.typesInstantiated.add(type);
        }

        // By saying that only JS-interop types can be created, we prevent
        // pulling in every other native type (e.g. all of dart:html) when a
        // JS interop API returns dynamic.  This means that to some degree we
        // still use the return type to decide whether to include native types,
        // even though we don't trust the type annotation.
        ClassEntity cls = commonElements.jsLegacyJavaScriptObjectClass;
        _behavior.typesInstantiated.add(elementEnvironment.getThisType(cls));
      }
    }
  }

  void _handleSideEffects() {
    // TODO(sra): We can probably assume DOM getters are idempotent.
    // TODO(sra): Add an annotation that includes other attributes, for example,
    // a @Behavior() annotation that supports the same language as JS().
    _behavior.sideEffects.setDependsOnSomething();
    _behavior.sideEffects.setAllSideEffects();
  }

  void _addReturnType(DartType type) {
    _behavior.typesReturned.add(type.withoutNullability);

    // Breakdown nullable type into TypeWithoutNullability|Null.
    // Unsound declared types are nullable, so we also add null in that case.
    // TODO(41960): Remove check for legacy subtyping. This was added as a
    // temporary workaround to unblock the null-safe unfork. At this time some
    // native APIs are typed unsoundly because they don't consider browser
    // compatibility or conditional support by context.
    if (type is NullableType ||
        type is LegacyType ||
        (options.useLegacySubtyping && type is! VoidType)) {
      _behavior.typesReturned.add(commonElements.nullType);
    }
  }

  NativeBehavior buildFieldLoadBehavior(
      DartType type,
      Iterable<String> createsAnnotations,
      Iterable<String> returnsAnnotations,
      TypeLookup lookupType,
      {required bool isJsInterop}) {
    _behavior = NativeBehavior();
    // TODO(sigmund,sra): consider doing something better for numeric types.
    _addReturnType(!isJsInterop ? type : commonElements.dynamicType);
    _capture(type, isJsInterop);
    _overrideWithAnnotations(
        createsAnnotations, returnsAnnotations, lookupType);
    _handleSideEffects();
    return _behavior;
  }

  NativeBehavior buildFieldStoreBehavior(DartType type) {
    _behavior = NativeBehavior();
    _escape(type, false);
    // We don't override the default behaviour - the annotations apply to
    // loading the field.
    _handleSideEffects();
    return _behavior;
  }

  NativeBehavior buildMethodBehavior(
      FunctionType type,
      Iterable<String> createAnnotations,
      Iterable<String> returnsAnnotations,
      TypeLookup lookupType,
      {required bool isJsInterop}) {
    _behavior = NativeBehavior();
    DartType returnType = type.returnType;
    // Note: For dart:html and other internal libraries we maintain, we can
    // trust the return type and use it to limit what we enqueue. We have to
    // be more conservative about JS interop types and assume they can return
    // anything. We do restrict the allocation effects and say that interop
    // calls create only interop types (which may be unsound if an interop call
    // returns a DOM type and declares a dynamic return type, but otherwise we
    // would include a lot of code by default).
    // TODO(sigmund,sra): consider doing something better for numeric types.
    _addReturnType(!isJsInterop ? returnType : commonElements.dynamicType);
    _capture(type, isJsInterop);

    for (DartType type in type.optionalParameterTypes) {
      _escape(type, isJsInterop);
    }
    for (DartType type in type.namedParameterTypes) {
      _escape(type, isJsInterop);
    }

    _overrideWithAnnotations(createAnnotations, returnsAnnotations, lookupType);
    _handleSideEffects();

    return _behavior;
  }
}

List<String> _getAnnotations(DartTypes dartTypes, DiagnosticReporter reporter,
    Iterable<ConstantValue> metadata, ClassEntity cls) {
  List<String> annotations = [];
  for (ConstantValue value in metadata) {
    if (value is ConstructedConstantValue) {
      if (value.type.element != cls) continue;

      Iterable<ConstantValue> fields = value.fields.values;
      // TODO(sra): Better validation of the constant.
      if (fields.length == 1) {
        ConstantValue field = fields.single;
        if (field is StringConstantValue) {
          annotations.add(field.stringValue);
          continue;
        }
      }

      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE,
          'Annotations needs one string: '
          '${value.toStructuredText(dartTypes)}');
    }
  }
  return annotations;
}

List<String> getCreatesAnnotations(
    DartTypes dartTypes,
    DiagnosticReporter reporter,
    CommonElements commonElements,
    Iterable<ConstantValue> metadata) {
  return _getAnnotations(
      dartTypes, reporter, metadata, commonElements.annotationCreatesClass);
}

List<String> getReturnsAnnotations(
    DartTypes dartTypes,
    DiagnosticReporter reporter,
    CommonElements commonElements,
    Iterable<ConstantValue> metadata) {
  return _getAnnotations(
      dartTypes, reporter, metadata, commonElements.annotationReturnsClass);
}
