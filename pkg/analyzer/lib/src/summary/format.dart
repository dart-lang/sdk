// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script "pkg/analyzer/tool/generate_files".

library analyzer.src.summary.format;

import 'dart:convert';
import 'base.dart' as base;

/**
 * Enum used to indicate the kind of entity referred to by a
 * [PrelinkedReference].
 */
enum PrelinkedReferenceKind {
  classOrEnum,
  typedef,
  other,
  prefix,
  unresolved,
}

/**
 * Enum used to indicate the kind of an executable.
 */
enum UnlinkedExecutableKind {
  functionOrMethod,
  getter,
  setter,
  constructor,
}

/**
 * Enum used to indicate the kind of a parameter.
 */
enum UnlinkedParamKind {
  required,
  positional,
  named,
}

/**
 * Information about a dependency that exists between one library and another
 * due to an "import" declaration.
 */
class PrelinkedDependency extends base.SummaryClass {
  String _uri;

  PrelinkedDependency.fromJson(Map json)
    : _uri = json["uri"];

  @override
  Map<String, Object> toMap() => {
    "uri": uri,
  };

  /**
   * The relative URI used to import one library from the other.
   */
  String get uri => _uri ?? '';
}

class PrelinkedDependencyBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedDependencyBuilder(base.BuilderContext context);

  /**
   * The relative URI used to import one library from the other.
   */
  void set uri(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("uri"));
    if (_value != null) {
      _json["uri"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

PrelinkedDependencyBuilder encodePrelinkedDependency(base.BuilderContext builderContext, {String uri}) {
  PrelinkedDependencyBuilder builder = new PrelinkedDependencyBuilder(builderContext);
  builder.uri = uri;
  return builder;
}

/**
 * Pre-linked summary of a library.
 */
class PrelinkedLibrary extends base.SummaryClass {
  List<PrelinkedUnit> _units;
  List<PrelinkedDependency> _dependencies;
  List<int> _importDependencies;

  PrelinkedLibrary.fromJson(Map json)
    : _units = json["units"]?.map((x) => new PrelinkedUnit.fromJson(x))?.toList(),
      _dependencies = json["dependencies"]?.map((x) => new PrelinkedDependency.fromJson(x))?.toList(),
      _importDependencies = json["importDependencies"];

  @override
  Map<String, Object> toMap() => {
    "units": units,
    "dependencies": dependencies,
    "importDependencies": importDependencies,
  };

  PrelinkedLibrary.fromBuffer(List<int> buffer) : this.fromJson(JSON.decode(UTF8.decode(buffer)));

  /**
   * The pre-linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  List<PrelinkedUnit> get units => _units ?? const <PrelinkedUnit>[];

  /**
   * The libraries that this library depends on (either via an explicit import
   * statement or via the implicit dependencies on `dart:core` and
   * `dart:async`).  The first element of this array is a pseudo-dependency
   * representing the library itself (it is also used for "dynamic").
   *
   * TODO(paulberry): consider removing this entirely and just using
   * [UnlinkedLibrary.imports].
   */
  List<PrelinkedDependency> get dependencies => _dependencies ?? const <PrelinkedDependency>[];

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   *
   * TODO(paulberry): if [dependencies] is removed, this can be removed as
   * well, since there will effectively be a one-to-one mapping.
   */
  List<int> get importDependencies => _importDependencies ?? const <int>[];
}

class PrelinkedLibraryBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedLibraryBuilder(base.BuilderContext context);

  /**
   * The pre-linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  void set units(List<PrelinkedUnitBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("units"));
    if (!(_value == null || _value.isEmpty)) {
      _json["units"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * The libraries that this library depends on (either via an explicit import
   * statement or via the implicit dependencies on `dart:core` and
   * `dart:async`).  The first element of this array is a pseudo-dependency
   * representing the library itself (it is also used for "dynamic").
   *
   * TODO(paulberry): consider removing this entirely and just using
   * [UnlinkedLibrary.imports].
   */
  void set dependencies(List<PrelinkedDependencyBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("dependencies"));
    if (!(_value == null || _value.isEmpty)) {
      _json["dependencies"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   *
   * TODO(paulberry): if [dependencies] is removed, this can be removed as
   * well, since there will effectively be a one-to-one mapping.
   */
  void set importDependencies(List<int> _value) {
    assert(!_finished);
    assert(!_json.containsKey("importDependencies"));
    if (!(_value == null || _value.isEmpty)) {
      _json["importDependencies"] = _value.toList();
    }
  }

  List<int> toBuffer() => UTF8.encode(JSON.encode(finish()));

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

PrelinkedLibraryBuilder encodePrelinkedLibrary(base.BuilderContext builderContext, {List<PrelinkedUnitBuilder> units, List<PrelinkedDependencyBuilder> dependencies, List<int> importDependencies}) {
  PrelinkedLibraryBuilder builder = new PrelinkedLibraryBuilder(builderContext);
  builder.units = units;
  builder.dependencies = dependencies;
  builder.importDependencies = importDependencies;
  return builder;
}

/**
 * Information about the resolution of an [UnlinkedReference].
 */
class PrelinkedReference extends base.SummaryClass {
  int _dependency;
  PrelinkedReferenceKind _kind;
  int _unit;
  int _numTypeParameters;

  PrelinkedReference.fromJson(Map json)
    : _dependency = json["dependency"],
      _kind = json["kind"] == null ? null : PrelinkedReferenceKind.values[json["kind"]],
      _unit = json["unit"],
      _numTypeParameters = json["numTypeParameters"];

  @override
  Map<String, Object> toMap() => {
    "dependency": dependency,
    "kind": kind,
    "unit": unit,
    "numTypeParameters": numTypeParameters,
  };

  /**
   * Index into [PrelinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  int get dependency => _dependency ?? 0;

  /**
   * The kind of the entity being referred to.  For the pseudo-type `dynamic`,
   * the kind is [PrelinkedReferenceKind.classOrEnum].
   */
  PrelinkedReferenceKind get kind => _kind ?? PrelinkedReferenceKind.classOrEnum;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [PrelinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  int get unit => _unit ?? 0;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int get numTypeParameters => _numTypeParameters ?? 0;
}

class PrelinkedReferenceBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedReferenceBuilder(base.BuilderContext context);

  /**
   * Index into [PrelinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  void set dependency(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("dependency"));
    if (_value != null) {
      _json["dependency"] = _value;
    }
  }

  /**
   * The kind of the entity being referred to.  For the pseudo-type `dynamic`,
   * the kind is [PrelinkedReferenceKind.classOrEnum].
   */
  void set kind(PrelinkedReferenceKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (!(_value == null || _value == PrelinkedReferenceKind.classOrEnum)) {
      _json["kind"] = _value.index;
    }
  }

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [PrelinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  void set unit(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("unit"));
    if (_value != null) {
      _json["unit"] = _value;
    }
  }

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  void set numTypeParameters(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("numTypeParameters"));
    if (_value != null) {
      _json["numTypeParameters"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

PrelinkedReferenceBuilder encodePrelinkedReference(base.BuilderContext builderContext, {int dependency, PrelinkedReferenceKind kind, int unit, int numTypeParameters}) {
  PrelinkedReferenceBuilder builder = new PrelinkedReferenceBuilder(builderContext);
  builder.dependency = dependency;
  builder.kind = kind;
  builder.unit = unit;
  builder.numTypeParameters = numTypeParameters;
  return builder;
}

/**
 * Pre-linked summary of a compilation unit.
 */
class PrelinkedUnit extends base.SummaryClass {
  List<PrelinkedReference> _references;

  PrelinkedUnit.fromJson(Map json)
    : _references = json["references"]?.map((x) => new PrelinkedReference.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "references": references,
  };

  /**
   * For each reference in [UnlinkedUnit.references], information about how
   * that reference is resolved.
   */
  List<PrelinkedReference> get references => _references ?? const <PrelinkedReference>[];
}

class PrelinkedUnitBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedUnitBuilder(base.BuilderContext context);

  /**
   * For each reference in [UnlinkedUnit.references], information about how
   * that reference is resolved.
   */
  void set references(List<PrelinkedReferenceBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("references"));
    if (!(_value == null || _value.isEmpty)) {
      _json["references"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

PrelinkedUnitBuilder encodePrelinkedUnit(base.BuilderContext builderContext, {List<PrelinkedReferenceBuilder> references}) {
  PrelinkedUnitBuilder builder = new PrelinkedUnitBuilder(builderContext);
  builder.references = references;
  return builder;
}

/**
 * Information about SDK.
 */
class SdkBundle extends base.SummaryClass {
  List<String> _prelinkedLibraryUris;
  List<PrelinkedLibrary> _prelinkedLibraries;
  List<String> _unlinkedUnitUris;
  List<UnlinkedUnit> _unlinkedUnits;

  SdkBundle.fromJson(Map json)
    : _prelinkedLibraryUris = json["prelinkedLibraryUris"],
      _prelinkedLibraries = json["prelinkedLibraries"]?.map((x) => new PrelinkedLibrary.fromJson(x))?.toList(),
      _unlinkedUnitUris = json["unlinkedUnitUris"],
      _unlinkedUnits = json["unlinkedUnits"]?.map((x) => new UnlinkedUnit.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "prelinkedLibraryUris": prelinkedLibraryUris,
    "prelinkedLibraries": prelinkedLibraries,
    "unlinkedUnitUris": unlinkedUnitUris,
    "unlinkedUnits": unlinkedUnits,
  };

  SdkBundle.fromBuffer(List<int> buffer) : this.fromJson(JSON.decode(UTF8.decode(buffer)));

  /**
   * The list of URIs of items in [prelinkedLibraries], e.g. `dart:core`.
   */
  List<String> get prelinkedLibraryUris => _prelinkedLibraryUris ?? const <String>[];

  /**
   * Pre-linked libraries.
   */
  List<PrelinkedLibrary> get prelinkedLibraries => _prelinkedLibraries ?? const <PrelinkedLibrary>[];

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  List<String> get unlinkedUnitUris => _unlinkedUnitUris ?? const <String>[];

  /**
   * Unlinked information for the compilation units constituting the SDK.
   */
  List<UnlinkedUnit> get unlinkedUnits => _unlinkedUnits ?? const <UnlinkedUnit>[];
}

class SdkBundleBuilder {
  final Map _json = {};

  bool _finished = false;

  SdkBundleBuilder(base.BuilderContext context);

  /**
   * The list of URIs of items in [prelinkedLibraries], e.g. `dart:core`.
   */
  void set prelinkedLibraryUris(List<String> _value) {
    assert(!_finished);
    assert(!_json.containsKey("prelinkedLibraryUris"));
    if (!(_value == null || _value.isEmpty)) {
      _json["prelinkedLibraryUris"] = _value.toList();
    }
  }

  /**
   * Pre-linked libraries.
   */
  void set prelinkedLibraries(List<PrelinkedLibraryBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("prelinkedLibraries"));
    if (!(_value == null || _value.isEmpty)) {
      _json["prelinkedLibraries"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  void set unlinkedUnitUris(List<String> _value) {
    assert(!_finished);
    assert(!_json.containsKey("unlinkedUnitUris"));
    if (!(_value == null || _value.isEmpty)) {
      _json["unlinkedUnitUris"] = _value.toList();
    }
  }

  /**
   * Unlinked information for the compilation units constituting the SDK.
   */
  void set unlinkedUnits(List<UnlinkedUnitBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("unlinkedUnits"));
    if (!(_value == null || _value.isEmpty)) {
      _json["unlinkedUnits"] = _value.map((b) => b.finish()).toList();
    }
  }

  List<int> toBuffer() => UTF8.encode(JSON.encode(finish()));

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

SdkBundleBuilder encodeSdkBundle(base.BuilderContext builderContext, {List<String> prelinkedLibraryUris, List<PrelinkedLibraryBuilder> prelinkedLibraries, List<String> unlinkedUnitUris, List<UnlinkedUnitBuilder> unlinkedUnits}) {
  SdkBundleBuilder builder = new SdkBundleBuilder(builderContext);
  builder.prelinkedLibraryUris = prelinkedLibraryUris;
  builder.prelinkedLibraries = prelinkedLibraries;
  builder.unlinkedUnitUris = unlinkedUnitUris;
  builder.unlinkedUnits = unlinkedUnits;
  return builder;
}

/**
 * Unlinked summary information about a class declaration.
 */
class UnlinkedClass extends base.SummaryClass {
  String _name;
  int _nameOffset;
  List<UnlinkedTypeParam> _typeParameters;
  UnlinkedTypeRef _supertype;
  List<UnlinkedTypeRef> _mixins;
  List<UnlinkedTypeRef> _interfaces;
  List<UnlinkedVariable> _fields;
  List<UnlinkedExecutable> _executables;
  bool _isAbstract;
  bool _isMixinApplication;
  bool _hasNoSupertype;

  UnlinkedClass.fromJson(Map json)
    : _name = json["name"],
      _nameOffset = json["nameOffset"],
      _typeParameters = json["typeParameters"]?.map((x) => new UnlinkedTypeParam.fromJson(x))?.toList(),
      _supertype = json["supertype"] == null ? null : new UnlinkedTypeRef.fromJson(json["supertype"]),
      _mixins = json["mixins"]?.map((x) => new UnlinkedTypeRef.fromJson(x))?.toList(),
      _interfaces = json["interfaces"]?.map((x) => new UnlinkedTypeRef.fromJson(x))?.toList(),
      _fields = json["fields"]?.map((x) => new UnlinkedVariable.fromJson(x))?.toList(),
      _executables = json["executables"]?.map((x) => new UnlinkedExecutable.fromJson(x))?.toList(),
      _isAbstract = json["isAbstract"],
      _isMixinApplication = json["isMixinApplication"],
      _hasNoSupertype = json["hasNoSupertype"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "typeParameters": typeParameters,
    "supertype": supertype,
    "mixins": mixins,
    "interfaces": interfaces,
    "fields": fields,
    "executables": executables,
    "isAbstract": isAbstract,
    "isMixinApplication": isMixinApplication,
    "hasNoSupertype": hasNoSupertype,
  };

  /**
   * Name of the class.
   */
  String get name => _name ?? '';

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Type parameters of the class, if any.
   */
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  UnlinkedTypeRef get supertype => _supertype;

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  List<UnlinkedTypeRef> get mixins => _mixins ?? const <UnlinkedTypeRef>[];

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  List<UnlinkedTypeRef> get interfaces => _interfaces ?? const <UnlinkedTypeRef>[];

  /**
   * Field declarations contained in the class.
   */
  List<UnlinkedVariable> get fields => _fields ?? const <UnlinkedVariable>[];

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  List<UnlinkedExecutable> get executables => _executables ?? const <UnlinkedExecutable>[];

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  bool get isAbstract => _isAbstract ?? false;

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  bool get isMixinApplication => _isMixinApplication ?? false;

  /**
   * Indicates whether this class is the core "Object" class (and hence has no
   * supertype)
   */
  bool get hasNoSupertype => _hasNoSupertype ?? false;
}

class UnlinkedClassBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedClassBuilder(base.BuilderContext context);

  /**
   * Name of the class.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("nameOffset"));
    if (_value != null) {
      _json["nameOffset"] = _value;
    }
  }

  /**
   * Type parameters of the class, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typeParameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["typeParameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  void set supertype(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("supertype"));
    if (_value != null) {
      _json["supertype"] = _value.finish();
    }
  }

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  void set mixins(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("mixins"));
    if (!(_value == null || _value.isEmpty)) {
      _json["mixins"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  void set interfaces(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("interfaces"));
    if (!(_value == null || _value.isEmpty)) {
      _json["interfaces"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Field declarations contained in the class.
   */
  void set fields(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("fields"));
    if (!(_value == null || _value.isEmpty)) {
      _json["fields"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("executables"));
    if (!(_value == null || _value.isEmpty)) {
      _json["executables"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  void set isAbstract(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isAbstract"));
    if (_value != null) {
      _json["isAbstract"] = _value;
    }
  }

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  void set isMixinApplication(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isMixinApplication"));
    if (_value != null) {
      _json["isMixinApplication"] = _value;
    }
  }

  /**
   * Indicates whether this class is the core "Object" class (and hence has no
   * supertype)
   */
  void set hasNoSupertype(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("hasNoSupertype"));
    if (_value != null) {
      _json["hasNoSupertype"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedClassBuilder encodeUnlinkedClass(base.BuilderContext builderContext, {String name, int nameOffset, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder supertype, List<UnlinkedTypeRefBuilder> mixins, List<UnlinkedTypeRefBuilder> interfaces, List<UnlinkedVariableBuilder> fields, List<UnlinkedExecutableBuilder> executables, bool isAbstract, bool isMixinApplication, bool hasNoSupertype}) {
  UnlinkedClassBuilder builder = new UnlinkedClassBuilder(builderContext);
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.typeParameters = typeParameters;
  builder.supertype = supertype;
  builder.mixins = mixins;
  builder.interfaces = interfaces;
  builder.fields = fields;
  builder.executables = executables;
  builder.isAbstract = isAbstract;
  builder.isMixinApplication = isMixinApplication;
  builder.hasNoSupertype = hasNoSupertype;
  return builder;
}

/**
 * Unlinked summary information about a `show` or `hide` combinator in an
 * import or export declaration.
 */
class UnlinkedCombinator extends base.SummaryClass {
  List<String> _shows;
  List<String> _hides;

  UnlinkedCombinator.fromJson(Map json)
    : _shows = json["shows"],
      _hides = json["hides"];

  @override
  Map<String, Object> toMap() => {
    "shows": shows,
    "hides": hides,
  };

  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  List<String> get shows => _shows ?? const <String>[];

  /**
   * List of names which are hidden.  Empty if this is a `show` combinator.
   */
  List<String> get hides => _hides ?? const <String>[];
}

class UnlinkedCombinatorBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedCombinatorBuilder(base.BuilderContext context);

  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  void set shows(List<String> _value) {
    assert(!_finished);
    assert(!_json.containsKey("shows"));
    if (!(_value == null || _value.isEmpty)) {
      _json["shows"] = _value.toList();
    }
  }

  /**
   * List of names which are hidden.  Empty if this is a `show` combinator.
   */
  void set hides(List<String> _value) {
    assert(!_finished);
    assert(!_json.containsKey("hides"));
    if (!(_value == null || _value.isEmpty)) {
      _json["hides"] = _value.toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedCombinatorBuilder encodeUnlinkedCombinator(base.BuilderContext builderContext, {List<String> shows, List<String> hides}) {
  UnlinkedCombinatorBuilder builder = new UnlinkedCombinatorBuilder(builderContext);
  builder.shows = shows;
  builder.hides = hides;
  return builder;
}

/**
 * Unlinked summary information about an enum declaration.
 */
class UnlinkedEnum extends base.SummaryClass {
  String _name;
  int _nameOffset;
  List<UnlinkedEnumValue> _values;

  UnlinkedEnum.fromJson(Map json)
    : _name = json["name"],
      _nameOffset = json["nameOffset"],
      _values = json["values"]?.map((x) => new UnlinkedEnumValue.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "values": values,
  };

  /**
   * Name of the enum type.
   */
  String get name => _name ?? '';

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Values listed in the enum declaration, in declaration order.
   */
  List<UnlinkedEnumValue> get values => _values ?? const <UnlinkedEnumValue>[];
}

class UnlinkedEnumBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedEnumBuilder(base.BuilderContext context);

  /**
   * Name of the enum type.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("nameOffset"));
    if (_value != null) {
      _json["nameOffset"] = _value;
    }
  }

  /**
   * Values listed in the enum declaration, in declaration order.
   */
  void set values(List<UnlinkedEnumValueBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("values"));
    if (!(_value == null || _value.isEmpty)) {
      _json["values"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedEnumBuilder encodeUnlinkedEnum(base.BuilderContext builderContext, {String name, int nameOffset, List<UnlinkedEnumValueBuilder> values}) {
  UnlinkedEnumBuilder builder = new UnlinkedEnumBuilder(builderContext);
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.values = values;
  return builder;
}

/**
 * Unlinked summary information about a single enumerated value in an enum
 * declaration.
 */
class UnlinkedEnumValue extends base.SummaryClass {
  String _name;
  int _nameOffset;

  UnlinkedEnumValue.fromJson(Map json)
    : _name = json["name"],
      _nameOffset = json["nameOffset"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
  };

  /**
   * Name of the enumerated value.
   */
  String get name => _name ?? '';

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  int get nameOffset => _nameOffset ?? 0;
}

class UnlinkedEnumValueBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedEnumValueBuilder(base.BuilderContext context);

  /**
   * Name of the enumerated value.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("nameOffset"));
    if (_value != null) {
      _json["nameOffset"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedEnumValueBuilder encodeUnlinkedEnumValue(base.BuilderContext builderContext, {String name, int nameOffset}) {
  UnlinkedEnumValueBuilder builder = new UnlinkedEnumValueBuilder(builderContext);
  builder.name = name;
  builder.nameOffset = nameOffset;
  return builder;
}

/**
 * Unlinked summary information about a function, method, getter, or setter
 * declaration.
 */
class UnlinkedExecutable extends base.SummaryClass {
  String _name;
  int _nameOffset;
  List<UnlinkedTypeParam> _typeParameters;
  UnlinkedTypeRef _returnType;
  List<UnlinkedParam> _parameters;
  UnlinkedExecutableKind _kind;
  bool _isAbstract;
  bool _isStatic;
  bool _isConst;
  bool _isFactory;
  bool _hasImplicitReturnType;
  bool _isExternal;

  UnlinkedExecutable.fromJson(Map json)
    : _name = json["name"],
      _nameOffset = json["nameOffset"],
      _typeParameters = json["typeParameters"]?.map((x) => new UnlinkedTypeParam.fromJson(x))?.toList(),
      _returnType = json["returnType"] == null ? null : new UnlinkedTypeRef.fromJson(json["returnType"]),
      _parameters = json["parameters"]?.map((x) => new UnlinkedParam.fromJson(x))?.toList(),
      _kind = json["kind"] == null ? null : UnlinkedExecutableKind.values[json["kind"]],
      _isAbstract = json["isAbstract"],
      _isStatic = json["isStatic"],
      _isConst = json["isConst"],
      _isFactory = json["isFactory"],
      _hasImplicitReturnType = json["hasImplicitReturnType"],
      _isExternal = json["isExternal"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "typeParameters": typeParameters,
    "returnType": returnType,
    "parameters": parameters,
    "kind": kind,
    "isAbstract": isAbstract,
    "isStatic": isStatic,
    "isConst": isConst,
    "isFactory": isFactory,
    "hasImplicitReturnType": hasImplicitReturnType,
    "isExternal": isExternal,
  };

  /**
   * Name of the executable.  For setters, this includes the trailing "=".  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the empty string.
   */
  String get name => _name ?? '';

  /**
   * Offset of the executable name relative to the beginning of the file.  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the offset of the class name (i.e. the
   * offset of the second "C" in "class C { C(); }").
   */
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];

  /**
   * Declared return type of the executable.  Absent if the return type is
   * `void` or the executable is a constructor.  Note that when strong mode is
   * enabled, the actual return type may be different due to type inference.
   */
  UnlinkedTypeRef get returnType => _returnType;

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters (hence this will be the empty list), and setters have a single
   * parameter.
   */
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  UnlinkedExecutableKind get kind => _kind ?? UnlinkedExecutableKind.functionOrMethod;

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  bool get isAbstract => _isAbstract ?? false;

  /**
   * Indicates whether the executable is declared using the `static` keyword.
   *
   * Note that for top level executables, this flag is false, since they are
   * not declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  bool get isStatic => _isStatic ?? false;

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  bool get isConst => _isConst ?? false;

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  bool get isFactory => _isFactory ?? false;

  /**
   * Indicates whether the executable lacks an explicit return type
   * declaration.  False for constructors and setters.
   */
  bool get hasImplicitReturnType => _hasImplicitReturnType ?? false;

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  bool get isExternal => _isExternal ?? false;
}

class UnlinkedExecutableBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedExecutableBuilder(base.BuilderContext context);

  /**
   * Name of the executable.  For setters, this includes the trailing "=".  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the empty string.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * Offset of the executable name relative to the beginning of the file.  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the offset of the class name (i.e. the
   * offset of the second "C" in "class C { C(); }").
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("nameOffset"));
    if (_value != null) {
      _json["nameOffset"] = _value;
    }
  }

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typeParameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["typeParameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Declared return type of the executable.  Absent if the return type is
   * `void` or the executable is a constructor.  Note that when strong mode is
   * enabled, the actual return type may be different due to type inference.
   */
  void set returnType(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("returnType"));
    if (_value != null) {
      _json["returnType"] = _value.finish();
    }
  }

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters (hence this will be the empty list), and setters have a single
   * parameter.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("parameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["parameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  void set kind(UnlinkedExecutableKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (!(_value == null || _value == UnlinkedExecutableKind.functionOrMethod)) {
      _json["kind"] = _value.index;
    }
  }

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  void set isAbstract(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isAbstract"));
    if (_value != null) {
      _json["isAbstract"] = _value;
    }
  }

  /**
   * Indicates whether the executable is declared using the `static` keyword.
   *
   * Note that for top level executables, this flag is false, since they are
   * not declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  void set isStatic(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isStatic"));
    if (_value != null) {
      _json["isStatic"] = _value;
    }
  }

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  void set isConst(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isConst"));
    if (_value != null) {
      _json["isConst"] = _value;
    }
  }

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  void set isFactory(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isFactory"));
    if (_value != null) {
      _json["isFactory"] = _value;
    }
  }

  /**
   * Indicates whether the executable lacks an explicit return type
   * declaration.  False for constructors and setters.
   */
  void set hasImplicitReturnType(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("hasImplicitReturnType"));
    if (_value != null) {
      _json["hasImplicitReturnType"] = _value;
    }
  }

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  void set isExternal(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isExternal"));
    if (_value != null) {
      _json["isExternal"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedExecutableBuilder encodeUnlinkedExecutable(base.BuilderContext builderContext, {String name, int nameOffset, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters, UnlinkedExecutableKind kind, bool isAbstract, bool isStatic, bool isConst, bool isFactory, bool hasImplicitReturnType, bool isExternal}) {
  UnlinkedExecutableBuilder builder = new UnlinkedExecutableBuilder(builderContext);
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.typeParameters = typeParameters;
  builder.returnType = returnType;
  builder.parameters = parameters;
  builder.kind = kind;
  builder.isAbstract = isAbstract;
  builder.isStatic = isStatic;
  builder.isConst = isConst;
  builder.isFactory = isFactory;
  builder.hasImplicitReturnType = hasImplicitReturnType;
  builder.isExternal = isExternal;
  return builder;
}

/**
 * Unlinked summary information about an export declaration (stored outside
 * [UnlinkedPublicNamespace]).
 */
class UnlinkedExportNonPublic extends base.SummaryClass {
  int _offset;
  int _uriOffset;
  int _uriEnd;

  UnlinkedExportNonPublic.fromJson(Map json)
    : _offset = json["offset"],
      _uriOffset = json["uriOffset"],
      _uriEnd = json["uriEnd"];

  @override
  Map<String, Object> toMap() => {
    "offset": offset,
    "uriOffset": uriOffset,
    "uriEnd": uriEnd,
  };

  /**
   * Offset of the "export" keyword.
   */
  int get offset => _offset ?? 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  int get uriOffset => _uriOffset ?? 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  int get uriEnd => _uriEnd ?? 0;
}

class UnlinkedExportNonPublicBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedExportNonPublicBuilder(base.BuilderContext context);

  /**
   * Offset of the "export" keyword.
   */
  void set offset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("offset"));
    if (_value != null) {
      _json["offset"] = _value;
    }
  }

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("uriOffset"));
    if (_value != null) {
      _json["uriOffset"] = _value;
    }
  }

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("uriEnd"));
    if (_value != null) {
      _json["uriEnd"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedExportNonPublicBuilder encodeUnlinkedExportNonPublic(base.BuilderContext builderContext, {int offset, int uriOffset, int uriEnd}) {
  UnlinkedExportNonPublicBuilder builder = new UnlinkedExportNonPublicBuilder(builderContext);
  builder.offset = offset;
  builder.uriOffset = uriOffset;
  builder.uriEnd = uriEnd;
  return builder;
}

/**
 * Unlinked summary information about an export declaration (stored inside
 * [UnlinkedPublicNamespace]).
 */
class UnlinkedExportPublic extends base.SummaryClass {
  String _uri;
  List<UnlinkedCombinator> _combinators;

  UnlinkedExportPublic.fromJson(Map json)
    : _uri = json["uri"],
      _combinators = json["combinators"]?.map((x) => new UnlinkedCombinator.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "uri": uri,
    "combinators": combinators,
  };

  /**
   * URI used in the source code to reference the exported library.
   */
  String get uri => _uri ?? '';

  /**
   * Combinators contained in this import declaration.
   */
  List<UnlinkedCombinator> get combinators => _combinators ?? const <UnlinkedCombinator>[];
}

class UnlinkedExportPublicBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedExportPublicBuilder(base.BuilderContext context);

  /**
   * URI used in the source code to reference the exported library.
   */
  void set uri(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("uri"));
    if (_value != null) {
      _json["uri"] = _value;
    }
  }

  /**
   * Combinators contained in this import declaration.
   */
  void set combinators(List<UnlinkedCombinatorBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("combinators"));
    if (!(_value == null || _value.isEmpty)) {
      _json["combinators"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedExportPublicBuilder encodeUnlinkedExportPublic(base.BuilderContext builderContext, {String uri, List<UnlinkedCombinatorBuilder> combinators}) {
  UnlinkedExportPublicBuilder builder = new UnlinkedExportPublicBuilder(builderContext);
  builder.uri = uri;
  builder.combinators = combinators;
  return builder;
}

/**
 * Unlinked summary information about an import declaration.
 */
class UnlinkedImport extends base.SummaryClass {
  String _uri;
  int _offset;
  int _prefixReference;
  List<UnlinkedCombinator> _combinators;
  bool _isDeferred;
  bool _isImplicit;
  int _uriOffset;
  int _uriEnd;
  int _prefixOffset;

  UnlinkedImport.fromJson(Map json)
    : _uri = json["uri"],
      _offset = json["offset"],
      _prefixReference = json["prefixReference"],
      _combinators = json["combinators"]?.map((x) => new UnlinkedCombinator.fromJson(x))?.toList(),
      _isDeferred = json["isDeferred"],
      _isImplicit = json["isImplicit"],
      _uriOffset = json["uriOffset"],
      _uriEnd = json["uriEnd"],
      _prefixOffset = json["prefixOffset"];

  @override
  Map<String, Object> toMap() => {
    "uri": uri,
    "offset": offset,
    "prefixReference": prefixReference,
    "combinators": combinators,
    "isDeferred": isDeferred,
    "isImplicit": isImplicit,
    "uriOffset": uriOffset,
    "uriEnd": uriEnd,
    "prefixOffset": prefixOffset,
  };

  /**
   * URI used in the source code to reference the imported library.
   */
  String get uri => _uri ?? '';

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  int get offset => _offset ?? 0;

  /**
   * Index into [UnlinkedUnit.references] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  int get prefixReference => _prefixReference ?? 0;

  /**
   * Combinators contained in this import declaration.
   */
  List<UnlinkedCombinator> get combinators => _combinators ?? const <UnlinkedCombinator>[];

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  bool get isDeferred => _isDeferred ?? false;

  /**
   * Indicates whether the import declaration is implicit.
   */
  bool get isImplicit => _isImplicit ?? false;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  int get uriOffset => _uriOffset ?? 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  int get uriEnd => _uriEnd ?? 0;

  /**
   * Offset of the prefix name relative to the beginning of the file, or zero
   * if there is no prefix.
   */
  int get prefixOffset => _prefixOffset ?? 0;
}

class UnlinkedImportBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedImportBuilder(base.BuilderContext context);

  /**
   * URI used in the source code to reference the imported library.
   */
  void set uri(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("uri"));
    if (_value != null) {
      _json["uri"] = _value;
    }
  }

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  void set offset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("offset"));
    if (_value != null) {
      _json["offset"] = _value;
    }
  }

  /**
   * Index into [UnlinkedUnit.references] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  void set prefixReference(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("prefixReference"));
    if (_value != null) {
      _json["prefixReference"] = _value;
    }
  }

  /**
   * Combinators contained in this import declaration.
   */
  void set combinators(List<UnlinkedCombinatorBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("combinators"));
    if (!(_value == null || _value.isEmpty)) {
      _json["combinators"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  void set isDeferred(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isDeferred"));
    if (_value != null) {
      _json["isDeferred"] = _value;
    }
  }

  /**
   * Indicates whether the import declaration is implicit.
   */
  void set isImplicit(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isImplicit"));
    if (_value != null) {
      _json["isImplicit"] = _value;
    }
  }

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("uriOffset"));
    if (_value != null) {
      _json["uriOffset"] = _value;
    }
  }

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("uriEnd"));
    if (_value != null) {
      _json["uriEnd"] = _value;
    }
  }

  /**
   * Offset of the prefix name relative to the beginning of the file, or zero
   * if there is no prefix.
   */
  void set prefixOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("prefixOffset"));
    if (_value != null) {
      _json["prefixOffset"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedImportBuilder encodeUnlinkedImport(base.BuilderContext builderContext, {String uri, int offset, int prefixReference, List<UnlinkedCombinatorBuilder> combinators, bool isDeferred, bool isImplicit, int uriOffset, int uriEnd, int prefixOffset}) {
  UnlinkedImportBuilder builder = new UnlinkedImportBuilder(builderContext);
  builder.uri = uri;
  builder.offset = offset;
  builder.prefixReference = prefixReference;
  builder.combinators = combinators;
  builder.isDeferred = isDeferred;
  builder.isImplicit = isImplicit;
  builder.uriOffset = uriOffset;
  builder.uriEnd = uriEnd;
  builder.prefixOffset = prefixOffset;
  return builder;
}

/**
 * Unlinked summary information about a function parameter.
 */
class UnlinkedParam extends base.SummaryClass {
  String _name;
  int _nameOffset;
  UnlinkedTypeRef _type;
  List<UnlinkedParam> _parameters;
  UnlinkedParamKind _kind;
  bool _isFunctionTyped;
  bool _isInitializingFormal;
  bool _hasImplicitType;

  UnlinkedParam.fromJson(Map json)
    : _name = json["name"],
      _nameOffset = json["nameOffset"],
      _type = json["type"] == null ? null : new UnlinkedTypeRef.fromJson(json["type"]),
      _parameters = json["parameters"]?.map((x) => new UnlinkedParam.fromJson(x))?.toList(),
      _kind = json["kind"] == null ? null : UnlinkedParamKind.values[json["kind"]],
      _isFunctionTyped = json["isFunctionTyped"],
      _isInitializingFormal = json["isInitializingFormal"],
      _hasImplicitType = json["hasImplicitType"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "type": type,
    "parameters": parameters,
    "kind": kind,
    "isFunctionTyped": isFunctionTyped,
    "isInitializingFormal": isInitializingFormal,
    "hasImplicitType": hasImplicitType,
  };

  /**
   * Name of the parameter.
   */
  String get name => _name ?? '';

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  int get nameOffset => _nameOffset ?? 0;

  /**
   * If [isFunctionTyped] is `true`, the declared return type.  If
   * [isFunctionTyped] is `false`, the declared type.  Absent if
   * [isFunctionTyped] is `true` and the declared return type is `void`.  Note
   * that when strong mode is enabled, the actual type may be different due to
   * type inference.
   */
  UnlinkedTypeRef get type => _type;

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];

  /**
   * Kind of the parameter.
   */
  UnlinkedParamKind get kind => _kind ?? UnlinkedParamKind.required;

  /**
   * Indicates whether this is a function-typed parameter.
   */
  bool get isFunctionTyped => _isFunctionTyped ?? false;

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  bool get isInitializingFormal => _isInitializingFormal ?? false;

  /**
   * Indicates whether this parameter lacks an explicit type declaration.
   * Always false for a function-typed parameter.
   */
  bool get hasImplicitType => _hasImplicitType ?? false;
}

class UnlinkedParamBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedParamBuilder(base.BuilderContext context);

  /**
   * Name of the parameter.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("nameOffset"));
    if (_value != null) {
      _json["nameOffset"] = _value;
    }
  }

  /**
   * If [isFunctionTyped] is `true`, the declared return type.  If
   * [isFunctionTyped] is `false`, the declared type.  Absent if
   * [isFunctionTyped] is `true` and the declared return type is `void`.  Note
   * that when strong mode is enabled, the actual type may be different due to
   * type inference.
   */
  void set type(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("type"));
    if (_value != null) {
      _json["type"] = _value.finish();
    }
  }

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("parameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["parameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Kind of the parameter.
   */
  void set kind(UnlinkedParamKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (!(_value == null || _value == UnlinkedParamKind.required)) {
      _json["kind"] = _value.index;
    }
  }

  /**
   * Indicates whether this is a function-typed parameter.
   */
  void set isFunctionTyped(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isFunctionTyped"));
    if (_value != null) {
      _json["isFunctionTyped"] = _value;
    }
  }

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  void set isInitializingFormal(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isInitializingFormal"));
    if (_value != null) {
      _json["isInitializingFormal"] = _value;
    }
  }

  /**
   * Indicates whether this parameter lacks an explicit type declaration.
   * Always false for a function-typed parameter.
   */
  void set hasImplicitType(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("hasImplicitType"));
    if (_value != null) {
      _json["hasImplicitType"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedParamBuilder encodeUnlinkedParam(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedTypeRefBuilder type, List<UnlinkedParamBuilder> parameters, UnlinkedParamKind kind, bool isFunctionTyped, bool isInitializingFormal, bool hasImplicitType}) {
  UnlinkedParamBuilder builder = new UnlinkedParamBuilder(builderContext);
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.type = type;
  builder.parameters = parameters;
  builder.kind = kind;
  builder.isFunctionTyped = isFunctionTyped;
  builder.isInitializingFormal = isInitializingFormal;
  builder.hasImplicitType = hasImplicitType;
  return builder;
}

/**
 * Unlinked summary information about a part declaration.
 */
class UnlinkedPart extends base.SummaryClass {
  int _uriOffset;
  int _uriEnd;

  UnlinkedPart.fromJson(Map json)
    : _uriOffset = json["uriOffset"],
      _uriEnd = json["uriEnd"];

  @override
  Map<String, Object> toMap() => {
    "uriOffset": uriOffset,
    "uriEnd": uriEnd,
  };

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  int get uriOffset => _uriOffset ?? 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  int get uriEnd => _uriEnd ?? 0;
}

class UnlinkedPartBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedPartBuilder(base.BuilderContext context);

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("uriOffset"));
    if (_value != null) {
      _json["uriOffset"] = _value;
    }
  }

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("uriEnd"));
    if (_value != null) {
      _json["uriEnd"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedPartBuilder encodeUnlinkedPart(base.BuilderContext builderContext, {int uriOffset, int uriEnd}) {
  UnlinkedPartBuilder builder = new UnlinkedPartBuilder(builderContext);
  builder.uriOffset = uriOffset;
  builder.uriEnd = uriEnd;
  return builder;
}

/**
 * Unlinked summary information about a specific name contributed by a
 * compilation unit to a library's public namespace.
 *
 * TODO(paulberry): add a count of generic parameters, so that resynthesis
 * doesn't have to peek into the library to obtain this info.
 *
 * TODO(paulberry): for classes, add info about static members and
 * constructors, since this will be needed to prelink info about constants.
 *
 * TODO(paulberry): some of this information is redundant with information
 * elsewhere in the summary.  Consider reducing the redundancy to reduce
 * summary size.
 */
class UnlinkedPublicName extends base.SummaryClass {
  String _name;
  PrelinkedReferenceKind _kind;
  int _numTypeParameters;

  UnlinkedPublicName.fromJson(Map json)
    : _name = json["name"],
      _kind = json["kind"] == null ? null : PrelinkedReferenceKind.values[json["kind"]],
      _numTypeParameters = json["numTypeParameters"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "kind": kind,
    "numTypeParameters": numTypeParameters,
  };

  /**
   * The name itself.
   */
  String get name => _name ?? '';

  /**
   * The kind of object referred to by the name.
   */
  PrelinkedReferenceKind get kind => _kind ?? PrelinkedReferenceKind.classOrEnum;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int get numTypeParameters => _numTypeParameters ?? 0;
}

class UnlinkedPublicNameBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedPublicNameBuilder(base.BuilderContext context);

  /**
   * The name itself.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * The kind of object referred to by the name.
   */
  void set kind(PrelinkedReferenceKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (!(_value == null || _value == PrelinkedReferenceKind.classOrEnum)) {
      _json["kind"] = _value.index;
    }
  }

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  void set numTypeParameters(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("numTypeParameters"));
    if (_value != null) {
      _json["numTypeParameters"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedPublicNameBuilder encodeUnlinkedPublicName(base.BuilderContext builderContext, {String name, PrelinkedReferenceKind kind, int numTypeParameters}) {
  UnlinkedPublicNameBuilder builder = new UnlinkedPublicNameBuilder(builderContext);
  builder.name = name;
  builder.kind = kind;
  builder.numTypeParameters = numTypeParameters;
  return builder;
}

/**
 * Unlinked summary information about what a compilation unit contributes to a
 * library's public namespace.  This is the subset of [UnlinkedUnit] that is
 * required from dependent libraries in order to perform prelinking.
 */
class UnlinkedPublicNamespace extends base.SummaryClass {
  List<UnlinkedPublicName> _names;
  List<UnlinkedExportPublic> _exports;
  List<String> _parts;

  UnlinkedPublicNamespace.fromJson(Map json)
    : _names = json["names"]?.map((x) => new UnlinkedPublicName.fromJson(x))?.toList(),
      _exports = json["exports"]?.map((x) => new UnlinkedExportPublic.fromJson(x))?.toList(),
      _parts = json["parts"];

  @override
  Map<String, Object> toMap() => {
    "names": names,
    "exports": exports,
    "parts": parts,
  };

  UnlinkedPublicNamespace.fromBuffer(List<int> buffer) : this.fromJson(JSON.decode(UTF8.decode(buffer)));

  /**
   * Public names defined in the compilation unit.
   *
   * TODO(paulberry): consider sorting these names to reduce unnecessary
   * relinking.
   */
  List<UnlinkedPublicName> get names => _names ?? const <UnlinkedPublicName>[];

  /**
   * Export declarations in the compilation unit.
   */
  List<UnlinkedExportPublic> get exports => _exports ?? const <UnlinkedExportPublic>[];

  /**
   * URIs referenced by part declarations in the compilation unit.
   */
  List<String> get parts => _parts ?? const <String>[];
}

class UnlinkedPublicNamespaceBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedPublicNamespaceBuilder(base.BuilderContext context);

  /**
   * Public names defined in the compilation unit.
   *
   * TODO(paulberry): consider sorting these names to reduce unnecessary
   * relinking.
   */
  void set names(List<UnlinkedPublicNameBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("names"));
    if (!(_value == null || _value.isEmpty)) {
      _json["names"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportPublicBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("exports"));
    if (!(_value == null || _value.isEmpty)) {
      _json["exports"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * URIs referenced by part declarations in the compilation unit.
   */
  void set parts(List<String> _value) {
    assert(!_finished);
    assert(!_json.containsKey("parts"));
    if (!(_value == null || _value.isEmpty)) {
      _json["parts"] = _value.toList();
    }
  }

  List<int> toBuffer() => UTF8.encode(JSON.encode(finish()));

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedPublicNamespaceBuilder encodeUnlinkedPublicNamespace(base.BuilderContext builderContext, {List<UnlinkedPublicNameBuilder> names, List<UnlinkedExportPublicBuilder> exports, List<String> parts}) {
  UnlinkedPublicNamespaceBuilder builder = new UnlinkedPublicNamespaceBuilder(builderContext);
  builder.names = names;
  builder.exports = exports;
  builder.parts = parts;
  return builder;
}

/**
 * Unlinked summary information about a name referred to in one library that
 * might be defined in another.
 */
class UnlinkedReference extends base.SummaryClass {
  String _name;
  int _prefixReference;

  UnlinkedReference.fromJson(Map json)
    : _name = json["name"],
      _prefixReference = json["prefixReference"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "prefixReference": prefixReference,
  };

  /**
   * Name of the entity being referred to.  The empty string refers to the
   * pseudo-type `dynamic`.
   */
  String get name => _name ?? '';

  /**
   * Prefix used to refer to the entity, or zero if no prefix is used.  This is
   * an index into [UnlinkedUnit.references].
   */
  int get prefixReference => _prefixReference ?? 0;
}

class UnlinkedReferenceBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedReferenceBuilder(base.BuilderContext context);

  /**
   * Name of the entity being referred to.  The empty string refers to the
   * pseudo-type `dynamic`.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * Prefix used to refer to the entity, or zero if no prefix is used.  This is
   * an index into [UnlinkedUnit.references].
   */
  void set prefixReference(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("prefixReference"));
    if (_value != null) {
      _json["prefixReference"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedReferenceBuilder encodeUnlinkedReference(base.BuilderContext builderContext, {String name, int prefixReference}) {
  UnlinkedReferenceBuilder builder = new UnlinkedReferenceBuilder(builderContext);
  builder.name = name;
  builder.prefixReference = prefixReference;
  return builder;
}

/**
 * Unlinked summary information about a typedef declaration.
 */
class UnlinkedTypedef extends base.SummaryClass {
  String _name;
  int _nameOffset;
  List<UnlinkedTypeParam> _typeParameters;
  UnlinkedTypeRef _returnType;
  List<UnlinkedParam> _parameters;

  UnlinkedTypedef.fromJson(Map json)
    : _name = json["name"],
      _nameOffset = json["nameOffset"],
      _typeParameters = json["typeParameters"]?.map((x) => new UnlinkedTypeParam.fromJson(x))?.toList(),
      _returnType = json["returnType"] == null ? null : new UnlinkedTypeRef.fromJson(json["returnType"]),
      _parameters = json["parameters"]?.map((x) => new UnlinkedParam.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "typeParameters": typeParameters,
    "returnType": returnType,
    "parameters": parameters,
  };

  /**
   * Name of the typedef.
   */
  String get name => _name ?? '';

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Type parameters of the typedef, if any.
   */
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];

  /**
   * Return type of the typedef.  Absent if the return type is `void`.
   */
  UnlinkedTypeRef get returnType => _returnType;

  /**
   * Parameters of the executable, if any.
   */
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];
}

class UnlinkedTypedefBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedTypedefBuilder(base.BuilderContext context);

  /**
   * Name of the typedef.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("nameOffset"));
    if (_value != null) {
      _json["nameOffset"] = _value;
    }
  }

  /**
   * Type parameters of the typedef, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typeParameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["typeParameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Return type of the typedef.  Absent if the return type is `void`.
   */
  void set returnType(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("returnType"));
    if (_value != null) {
      _json["returnType"] = _value.finish();
    }
  }

  /**
   * Parameters of the executable, if any.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("parameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["parameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedTypedefBuilder encodeUnlinkedTypedef(base.BuilderContext builderContext, {String name, int nameOffset, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters}) {
  UnlinkedTypedefBuilder builder = new UnlinkedTypedefBuilder(builderContext);
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.typeParameters = typeParameters;
  builder.returnType = returnType;
  builder.parameters = parameters;
  return builder;
}

/**
 * Unlinked summary information about a type parameter declaration.
 */
class UnlinkedTypeParam extends base.SummaryClass {
  String _name;
  int _nameOffset;
  UnlinkedTypeRef _bound;

  UnlinkedTypeParam.fromJson(Map json)
    : _name = json["name"],
      _nameOffset = json["nameOffset"],
      _bound = json["bound"] == null ? null : new UnlinkedTypeRef.fromJson(json["bound"]);

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "bound": bound,
  };

  /**
   * Name of the type parameter.
   */
  String get name => _name ?? '';

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Bound of the type parameter, if a bound is explicitly declared.  Otherwise
   * null.
   */
  UnlinkedTypeRef get bound => _bound;
}

class UnlinkedTypeParamBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedTypeParamBuilder(base.BuilderContext context);

  /**
   * Name of the type parameter.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("nameOffset"));
    if (_value != null) {
      _json["nameOffset"] = _value;
    }
  }

  /**
   * Bound of the type parameter, if a bound is explicitly declared.  Otherwise
   * null.
   */
  void set bound(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("bound"));
    if (_value != null) {
      _json["bound"] = _value.finish();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedTypeParamBuilder encodeUnlinkedTypeParam(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedTypeRefBuilder bound}) {
  UnlinkedTypeParamBuilder builder = new UnlinkedTypeParamBuilder(builderContext);
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.bound = bound;
  return builder;
}

/**
 * Unlinked summary information about a reference to a type.
 */
class UnlinkedTypeRef extends base.SummaryClass {
  int _reference;
  int _paramReference;
  List<UnlinkedTypeRef> _typeArguments;

  UnlinkedTypeRef.fromJson(Map json)
    : _reference = json["reference"],
      _paramReference = json["paramReference"],
      _typeArguments = json["typeArguments"]?.map((x) => new UnlinkedTypeRef.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "reference": reference,
    "paramReference": paramReference,
    "typeArguments": typeArguments,
  };

  /**
   * Index into [UnlinkedUnit.references] for the type being referred to, or
   * zero if this is a reference to a type parameter.
   *
   * Note that since zero is also a valid index into
   * [UnlinkedUnit.references], we cannot distinguish between references to
   * type parameters and references to types by checking [reference] against
   * zero.  To distinguish between references to type parameters and references
   * to types, check whether [paramReference] is zero.
   */
  int get reference => _reference ?? 0;

  /**
   * If this is a reference to a type parameter, one-based index into the list
   * of [UnlinkedTypeParam]s currently in effect.  Indexing is done using De
   * Bruijn index conventions; that is, innermost parameters come first, and
   * if a class or method has multiple parameters, they are indexed from right
   * to left.  So for instance, if the enclosing declaration is
   *
   *     class C<T,U> {
   *       m<V,W> {
   *         ...
   *       }
   *     }
   *
   * Then [paramReference] values of 1, 2, 3, and 4 represent W, V, U, and T,
   * respectively.
   *
   * If the type being referred to is not a type parameter, [paramReference] is
   * zero.
   */
  int get paramReference => _paramReference ?? 0;

  /**
   * If this is an instantiation of a generic type, the type arguments used to
   * instantiate it.  Trailing type arguments of type `dynamic` are omitted.
   */
  List<UnlinkedTypeRef> get typeArguments => _typeArguments ?? const <UnlinkedTypeRef>[];
}

class UnlinkedTypeRefBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedTypeRefBuilder(base.BuilderContext context);

  /**
   * Index into [UnlinkedUnit.references] for the type being referred to, or
   * zero if this is a reference to a type parameter.
   *
   * Note that since zero is also a valid index into
   * [UnlinkedUnit.references], we cannot distinguish between references to
   * type parameters and references to types by checking [reference] against
   * zero.  To distinguish between references to type parameters and references
   * to types, check whether [paramReference] is zero.
   */
  void set reference(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("reference"));
    if (_value != null) {
      _json["reference"] = _value;
    }
  }

  /**
   * If this is a reference to a type parameter, one-based index into the list
   * of [UnlinkedTypeParam]s currently in effect.  Indexing is done using De
   * Bruijn index conventions; that is, innermost parameters come first, and
   * if a class or method has multiple parameters, they are indexed from right
   * to left.  So for instance, if the enclosing declaration is
   *
   *     class C<T,U> {
   *       m<V,W> {
   *         ...
   *       }
   *     }
   *
   * Then [paramReference] values of 1, 2, 3, and 4 represent W, V, U, and T,
   * respectively.
   *
   * If the type being referred to is not a type parameter, [paramReference] is
   * zero.
   */
  void set paramReference(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("paramReference"));
    if (_value != null) {
      _json["paramReference"] = _value;
    }
  }

  /**
   * If this is an instantiation of a generic type, the type arguments used to
   * instantiate it.  Trailing type arguments of type `dynamic` are omitted.
   */
  void set typeArguments(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typeArguments"));
    if (!(_value == null || _value.isEmpty)) {
      _json["typeArguments"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedTypeRefBuilder encodeUnlinkedTypeRef(base.BuilderContext builderContext, {int reference, int paramReference, List<UnlinkedTypeRefBuilder> typeArguments}) {
  UnlinkedTypeRefBuilder builder = new UnlinkedTypeRefBuilder(builderContext);
  builder.reference = reference;
  builder.paramReference = paramReference;
  builder.typeArguments = typeArguments;
  return builder;
}

/**
 * Unlinked summary information about a compilation unit ("part file").
 */
class UnlinkedUnit extends base.SummaryClass {
  String _libraryName;
  int _libraryNameOffset;
  int _libraryNameLength;
  UnlinkedPublicNamespace _publicNamespace;
  List<UnlinkedReference> _references;
  List<UnlinkedClass> _classes;
  List<UnlinkedEnum> _enums;
  List<UnlinkedExecutable> _executables;
  List<UnlinkedExportNonPublic> _exports;
  List<UnlinkedImport> _imports;
  List<UnlinkedPart> _parts;
  List<UnlinkedTypedef> _typedefs;
  List<UnlinkedVariable> _variables;

  UnlinkedUnit.fromJson(Map json)
    : _libraryName = json["libraryName"],
      _libraryNameOffset = json["libraryNameOffset"],
      _libraryNameLength = json["libraryNameLength"],
      _publicNamespace = json["publicNamespace"] == null ? null : new UnlinkedPublicNamespace.fromJson(json["publicNamespace"]),
      _references = json["references"]?.map((x) => new UnlinkedReference.fromJson(x))?.toList(),
      _classes = json["classes"]?.map((x) => new UnlinkedClass.fromJson(x))?.toList(),
      _enums = json["enums"]?.map((x) => new UnlinkedEnum.fromJson(x))?.toList(),
      _executables = json["executables"]?.map((x) => new UnlinkedExecutable.fromJson(x))?.toList(),
      _exports = json["exports"]?.map((x) => new UnlinkedExportNonPublic.fromJson(x))?.toList(),
      _imports = json["imports"]?.map((x) => new UnlinkedImport.fromJson(x))?.toList(),
      _parts = json["parts"]?.map((x) => new UnlinkedPart.fromJson(x))?.toList(),
      _typedefs = json["typedefs"]?.map((x) => new UnlinkedTypedef.fromJson(x))?.toList(),
      _variables = json["variables"]?.map((x) => new UnlinkedVariable.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "libraryName": libraryName,
    "libraryNameOffset": libraryNameOffset,
    "libraryNameLength": libraryNameLength,
    "publicNamespace": publicNamespace,
    "references": references,
    "classes": classes,
    "enums": enums,
    "executables": executables,
    "exports": exports,
    "imports": imports,
    "parts": parts,
    "typedefs": typedefs,
    "variables": variables,
  };

  UnlinkedUnit.fromBuffer(List<int> buffer) : this.fromJson(JSON.decode(UTF8.decode(buffer)));

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  String get libraryName => _libraryName ?? '';

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  int get libraryNameOffset => _libraryNameOffset ?? 0;

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  int get libraryNameLength => _libraryNameLength ?? 0;

  /**
   * Unlinked public namespace of this compilation unit.
   */
  UnlinkedPublicNamespace get publicNamespace => _publicNamespace;

  /**
   * Top level and prefixed names referred to by this compilation unit.  The
   * zeroth element of this array is always populated and always represents a
   * reference to the pseudo-type "dynamic".
   */
  List<UnlinkedReference> get references => _references ?? const <UnlinkedReference>[];

  /**
   * Classes declared in the compilation unit.
   */
  List<UnlinkedClass> get classes => _classes ?? const <UnlinkedClass>[];

  /**
   * Enums declared in the compilation unit.
   */
  List<UnlinkedEnum> get enums => _enums ?? const <UnlinkedEnum>[];

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  List<UnlinkedExecutable> get executables => _executables ?? const <UnlinkedExecutable>[];

  /**
   * Export declarations in the compilation unit.
   */
  List<UnlinkedExportNonPublic> get exports => _exports ?? const <UnlinkedExportNonPublic>[];

  /**
   * Import declarations in the compilation unit.
   */
  List<UnlinkedImport> get imports => _imports ?? const <UnlinkedImport>[];

  /**
   * Part declarations in the compilation unit.
   */
  List<UnlinkedPart> get parts => _parts ?? const <UnlinkedPart>[];

  /**
   * Typedefs declared in the compilation unit.
   */
  List<UnlinkedTypedef> get typedefs => _typedefs ?? const <UnlinkedTypedef>[];

  /**
   * Top level variables declared in the compilation unit.
   */
  List<UnlinkedVariable> get variables => _variables ?? const <UnlinkedVariable>[];
}

class UnlinkedUnitBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedUnitBuilder(base.BuilderContext context);

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  void set libraryName(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("libraryName"));
    if (_value != null) {
      _json["libraryName"] = _value;
    }
  }

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  void set libraryNameOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("libraryNameOffset"));
    if (_value != null) {
      _json["libraryNameOffset"] = _value;
    }
  }

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  void set libraryNameLength(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("libraryNameLength"));
    if (_value != null) {
      _json["libraryNameLength"] = _value;
    }
  }

  /**
   * Unlinked public namespace of this compilation unit.
   */
  void set publicNamespace(UnlinkedPublicNamespaceBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("publicNamespace"));
    if (_value != null) {
      _json["publicNamespace"] = _value.finish();
    }
  }

  /**
   * Top level and prefixed names referred to by this compilation unit.  The
   * zeroth element of this array is always populated and always represents a
   * reference to the pseudo-type "dynamic".
   */
  void set references(List<UnlinkedReferenceBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("references"));
    if (!(_value == null || _value.isEmpty)) {
      _json["references"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Classes declared in the compilation unit.
   */
  void set classes(List<UnlinkedClassBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("classes"));
    if (!(_value == null || _value.isEmpty)) {
      _json["classes"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Enums declared in the compilation unit.
   */
  void set enums(List<UnlinkedEnumBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("enums"));
    if (!(_value == null || _value.isEmpty)) {
      _json["enums"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("executables"));
    if (!(_value == null || _value.isEmpty)) {
      _json["executables"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportNonPublicBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("exports"));
    if (!(_value == null || _value.isEmpty)) {
      _json["exports"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Import declarations in the compilation unit.
   */
  void set imports(List<UnlinkedImportBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("imports"));
    if (!(_value == null || _value.isEmpty)) {
      _json["imports"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Part declarations in the compilation unit.
   */
  void set parts(List<UnlinkedPartBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("parts"));
    if (!(_value == null || _value.isEmpty)) {
      _json["parts"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Typedefs declared in the compilation unit.
   */
  void set typedefs(List<UnlinkedTypedefBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typedefs"));
    if (!(_value == null || _value.isEmpty)) {
      _json["typedefs"] = _value.map((b) => b.finish()).toList();
    }
  }

  /**
   * Top level variables declared in the compilation unit.
   */
  void set variables(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("variables"));
    if (!(_value == null || _value.isEmpty)) {
      _json["variables"] = _value.map((b) => b.finish()).toList();
    }
  }

  List<int> toBuffer() => UTF8.encode(JSON.encode(finish()));

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedUnitBuilder encodeUnlinkedUnit(base.BuilderContext builderContext, {String libraryName, int libraryNameOffset, int libraryNameLength, UnlinkedPublicNamespaceBuilder publicNamespace, List<UnlinkedReferenceBuilder> references, List<UnlinkedClassBuilder> classes, List<UnlinkedEnumBuilder> enums, List<UnlinkedExecutableBuilder> executables, List<UnlinkedExportNonPublicBuilder> exports, List<UnlinkedImportBuilder> imports, List<UnlinkedPartBuilder> parts, List<UnlinkedTypedefBuilder> typedefs, List<UnlinkedVariableBuilder> variables}) {
  UnlinkedUnitBuilder builder = new UnlinkedUnitBuilder(builderContext);
  builder.libraryName = libraryName;
  builder.libraryNameOffset = libraryNameOffset;
  builder.libraryNameLength = libraryNameLength;
  builder.publicNamespace = publicNamespace;
  builder.references = references;
  builder.classes = classes;
  builder.enums = enums;
  builder.executables = executables;
  builder.exports = exports;
  builder.imports = imports;
  builder.parts = parts;
  builder.typedefs = typedefs;
  builder.variables = variables;
  return builder;
}

/**
 * Unlinked summary information about a top level variable, local variable, or
 * a field.
 */
class UnlinkedVariable extends base.SummaryClass {
  String _name;
  int _nameOffset;
  UnlinkedTypeRef _type;
  bool _isStatic;
  bool _isFinal;
  bool _isConst;
  bool _hasImplicitType;

  UnlinkedVariable.fromJson(Map json)
    : _name = json["name"],
      _nameOffset = json["nameOffset"],
      _type = json["type"] == null ? null : new UnlinkedTypeRef.fromJson(json["type"]),
      _isStatic = json["isStatic"],
      _isFinal = json["isFinal"],
      _isConst = json["isConst"],
      _hasImplicitType = json["hasImplicitType"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "type": type,
    "isStatic": isStatic,
    "isFinal": isFinal,
    "isConst": isConst,
    "hasImplicitType": hasImplicitType,
  };

  /**
   * Name of the variable.
   */
  String get name => _name ?? '';

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Declared type of the variable.  Note that when strong mode is enabled, the
   * actual type of the variable may be different due to type inference.
   */
  UnlinkedTypeRef get type => _type;

  /**
   * Indicates whether the variable is declared using the `static` keyword.
   *
   * Note that for top level variables, this flag is false, since they are not
   * declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  bool get isStatic => _isStatic ?? false;

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  bool get isFinal => _isFinal ?? false;

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  bool get isConst => _isConst ?? false;

  /**
   * Indicates whether this variable lacks an explicit type declaration.
   */
  bool get hasImplicitType => _hasImplicitType ?? false;
}

class UnlinkedVariableBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedVariableBuilder(base.BuilderContext context);

  /**
   * Name of the variable.
   */
  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("nameOffset"));
    if (_value != null) {
      _json["nameOffset"] = _value;
    }
  }

  /**
   * Declared type of the variable.  Note that when strong mode is enabled, the
   * actual type of the variable may be different due to type inference.
   */
  void set type(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("type"));
    if (_value != null) {
      _json["type"] = _value.finish();
    }
  }

  /**
   * Indicates whether the variable is declared using the `static` keyword.
   *
   * Note that for top level variables, this flag is false, since they are not
   * declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  void set isStatic(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isStatic"));
    if (_value != null) {
      _json["isStatic"] = _value;
    }
  }

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  void set isFinal(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isFinal"));
    if (_value != null) {
      _json["isFinal"] = _value;
    }
  }

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  void set isConst(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isConst"));
    if (_value != null) {
      _json["isConst"] = _value;
    }
  }

  /**
   * Indicates whether this variable lacks an explicit type declaration.
   */
  void set hasImplicitType(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("hasImplicitType"));
    if (_value != null) {
      _json["hasImplicitType"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedVariableBuilder encodeUnlinkedVariable(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedTypeRefBuilder type, bool isStatic, bool isFinal, bool isConst, bool hasImplicitType}) {
  UnlinkedVariableBuilder builder = new UnlinkedVariableBuilder(builderContext);
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.type = type;
  builder.isStatic = isStatic;
  builder.isFinal = isFinal;
  builder.isConst = isConst;
  builder.hasImplicitType = hasImplicitType;
  return builder;
}

