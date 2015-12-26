// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script "pkg/analyzer/tool/generate_files".

library analyzer.src.summary.format;

import 'dart:convert';
import 'base.dart' as base;

enum PrelinkedReferenceKind {
  classOrEnum,
  typedef,
  other,
  prefix,
  unresolved,
}

enum UnlinkedExecutableKind {
  functionOrMethod,
  getter,
  setter,
  constructor,
}

enum UnlinkedParamKind {
  required,
  positional,
  named,
}

class PrelinkedDependency extends base.SummaryClass {
  String _uri;

  PrelinkedDependency.fromJson(Map json)
    : _uri = json["uri"];

  @override
  Map<String, Object> toMap() => {
    "uri": uri,
  };

  String get uri => _uri ?? '';
}

class PrelinkedDependencyBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedDependencyBuilder(base.BuilderContext context);

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

  List<PrelinkedUnit> get units => _units ?? const <PrelinkedUnit>[];
  List<PrelinkedDependency> get dependencies => _dependencies ?? const <PrelinkedDependency>[];
  List<int> get importDependencies => _importDependencies ?? const <int>[];
}

class PrelinkedLibraryBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedLibraryBuilder(base.BuilderContext context);

  void set units(List<PrelinkedUnitBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("units"));
    if (!(_value == null || _value.isEmpty)) {
      _json["units"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set dependencies(List<PrelinkedDependencyBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("dependencies"));
    if (!(_value == null || _value.isEmpty)) {
      _json["dependencies"] = _value.map((b) => b.finish()).toList();
    }
  }

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

class PrelinkedReference extends base.SummaryClass {
  int _dependency;
  PrelinkedReferenceKind _kind;
  int _unit;

  PrelinkedReference.fromJson(Map json)
    : _dependency = json["dependency"],
      _kind = json["kind"] == null ? null : PrelinkedReferenceKind.values[json["kind"]],
      _unit = json["unit"];

  @override
  Map<String, Object> toMap() => {
    "dependency": dependency,
    "kind": kind,
    "unit": unit,
  };

  int get dependency => _dependency ?? 0;
  PrelinkedReferenceKind get kind => _kind ?? PrelinkedReferenceKind.classOrEnum;
  int get unit => _unit ?? 0;
}

class PrelinkedReferenceBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedReferenceBuilder(base.BuilderContext context);

  void set dependency(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("dependency"));
    if (_value != null) {
      _json["dependency"] = _value;
    }
  }

  void set kind(PrelinkedReferenceKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (!(_value == null || _value == PrelinkedReferenceKind.classOrEnum)) {
      _json["kind"] = _value.index;
    }
  }

  void set unit(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("unit"));
    if (_value != null) {
      _json["unit"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

PrelinkedReferenceBuilder encodePrelinkedReference(base.BuilderContext builderContext, {int dependency, PrelinkedReferenceKind kind, int unit}) {
  PrelinkedReferenceBuilder builder = new PrelinkedReferenceBuilder(builderContext);
  builder.dependency = dependency;
  builder.kind = kind;
  builder.unit = unit;
  return builder;
}

class PrelinkedUnit extends base.SummaryClass {
  List<PrelinkedReference> _references;

  PrelinkedUnit.fromJson(Map json)
    : _references = json["references"]?.map((x) => new PrelinkedReference.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "references": references,
  };

  List<PrelinkedReference> get references => _references ?? const <PrelinkedReference>[];
}

class PrelinkedUnitBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedUnitBuilder(base.BuilderContext context);

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

  List<String> get prelinkedLibraryUris => _prelinkedLibraryUris ?? const <String>[];
  List<PrelinkedLibrary> get prelinkedLibraries => _prelinkedLibraries ?? const <PrelinkedLibrary>[];
  List<String> get unlinkedUnitUris => _unlinkedUnitUris ?? const <String>[];
  List<UnlinkedUnit> get unlinkedUnits => _unlinkedUnits ?? const <UnlinkedUnit>[];
}

class SdkBundleBuilder {
  final Map _json = {};

  bool _finished = false;

  SdkBundleBuilder(base.BuilderContext context);

  void set prelinkedLibraryUris(List<String> _value) {
    assert(!_finished);
    assert(!_json.containsKey("prelinkedLibraryUris"));
    if (!(_value == null || _value.isEmpty)) {
      _json["prelinkedLibraryUris"] = _value.toList();
    }
  }

  void set prelinkedLibraries(List<PrelinkedLibraryBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("prelinkedLibraries"));
    if (!(_value == null || _value.isEmpty)) {
      _json["prelinkedLibraries"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set unlinkedUnitUris(List<String> _value) {
    assert(!_finished);
    assert(!_json.containsKey("unlinkedUnitUris"));
    if (!(_value == null || _value.isEmpty)) {
      _json["unlinkedUnitUris"] = _value.toList();
    }
  }

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

class UnlinkedClass extends base.SummaryClass {
  String _name;
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

  String get name => _name ?? '';
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];
  UnlinkedTypeRef get supertype => _supertype;
  List<UnlinkedTypeRef> get mixins => _mixins ?? const <UnlinkedTypeRef>[];
  List<UnlinkedTypeRef> get interfaces => _interfaces ?? const <UnlinkedTypeRef>[];
  List<UnlinkedVariable> get fields => _fields ?? const <UnlinkedVariable>[];
  List<UnlinkedExecutable> get executables => _executables ?? const <UnlinkedExecutable>[];
  bool get isAbstract => _isAbstract ?? false;
  bool get isMixinApplication => _isMixinApplication ?? false;
  bool get hasNoSupertype => _hasNoSupertype ?? false;
}

class UnlinkedClassBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedClassBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typeParameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["typeParameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set supertype(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("supertype"));
    if (_value != null) {
      _json["supertype"] = _value.finish();
    }
  }

  void set mixins(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("mixins"));
    if (!(_value == null || _value.isEmpty)) {
      _json["mixins"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set interfaces(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("interfaces"));
    if (!(_value == null || _value.isEmpty)) {
      _json["interfaces"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set fields(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("fields"));
    if (!(_value == null || _value.isEmpty)) {
      _json["fields"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("executables"));
    if (!(_value == null || _value.isEmpty)) {
      _json["executables"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set isAbstract(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isAbstract"));
    if (_value != null) {
      _json["isAbstract"] = _value;
    }
  }

  void set isMixinApplication(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isMixinApplication"));
    if (_value != null) {
      _json["isMixinApplication"] = _value;
    }
  }

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

UnlinkedClassBuilder encodeUnlinkedClass(base.BuilderContext builderContext, {String name, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder supertype, List<UnlinkedTypeRefBuilder> mixins, List<UnlinkedTypeRefBuilder> interfaces, List<UnlinkedVariableBuilder> fields, List<UnlinkedExecutableBuilder> executables, bool isAbstract, bool isMixinApplication, bool hasNoSupertype}) {
  UnlinkedClassBuilder builder = new UnlinkedClassBuilder(builderContext);
  builder.name = name;
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

class UnlinkedCombinator extends base.SummaryClass {
  List<UnlinkedCombinatorName> _shows;
  List<UnlinkedCombinatorName> _hides;

  UnlinkedCombinator.fromJson(Map json)
    : _shows = json["shows"]?.map((x) => new UnlinkedCombinatorName.fromJson(x))?.toList(),
      _hides = json["hides"]?.map((x) => new UnlinkedCombinatorName.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "shows": shows,
    "hides": hides,
  };

  List<UnlinkedCombinatorName> get shows => _shows ?? const <UnlinkedCombinatorName>[];
  List<UnlinkedCombinatorName> get hides => _hides ?? const <UnlinkedCombinatorName>[];
}

class UnlinkedCombinatorBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedCombinatorBuilder(base.BuilderContext context);

  void set shows(List<UnlinkedCombinatorNameBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("shows"));
    if (!(_value == null || _value.isEmpty)) {
      _json["shows"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set hides(List<UnlinkedCombinatorNameBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("hides"));
    if (!(_value == null || _value.isEmpty)) {
      _json["hides"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedCombinatorBuilder encodeUnlinkedCombinator(base.BuilderContext builderContext, {List<UnlinkedCombinatorNameBuilder> shows, List<UnlinkedCombinatorNameBuilder> hides}) {
  UnlinkedCombinatorBuilder builder = new UnlinkedCombinatorBuilder(builderContext);
  builder.shows = shows;
  builder.hides = hides;
  return builder;
}

class UnlinkedCombinatorName extends base.SummaryClass {
  String _name;

  UnlinkedCombinatorName.fromJson(Map json)
    : _name = json["name"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
  };

  String get name => _name ?? '';
}

class UnlinkedCombinatorNameBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedCombinatorNameBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedCombinatorNameBuilder encodeUnlinkedCombinatorName(base.BuilderContext builderContext, {String name}) {
  UnlinkedCombinatorNameBuilder builder = new UnlinkedCombinatorNameBuilder(builderContext);
  builder.name = name;
  return builder;
}

class UnlinkedEnum extends base.SummaryClass {
  String _name;
  List<UnlinkedEnumValue> _values;

  UnlinkedEnum.fromJson(Map json)
    : _name = json["name"],
      _values = json["values"]?.map((x) => new UnlinkedEnumValue.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "values": values,
  };

  String get name => _name ?? '';
  List<UnlinkedEnumValue> get values => _values ?? const <UnlinkedEnumValue>[];
}

class UnlinkedEnumBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedEnumBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

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

UnlinkedEnumBuilder encodeUnlinkedEnum(base.BuilderContext builderContext, {String name, List<UnlinkedEnumValueBuilder> values}) {
  UnlinkedEnumBuilder builder = new UnlinkedEnumBuilder(builderContext);
  builder.name = name;
  builder.values = values;
  return builder;
}

class UnlinkedEnumValue extends base.SummaryClass {
  String _name;

  UnlinkedEnumValue.fromJson(Map json)
    : _name = json["name"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
  };

  String get name => _name ?? '';
}

class UnlinkedEnumValueBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedEnumValueBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedEnumValueBuilder encodeUnlinkedEnumValue(base.BuilderContext builderContext, {String name}) {
  UnlinkedEnumValueBuilder builder = new UnlinkedEnumValueBuilder(builderContext);
  builder.name = name;
  return builder;
}

class UnlinkedExecutable extends base.SummaryClass {
  String _name;
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

  String get name => _name ?? '';
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];
  UnlinkedTypeRef get returnType => _returnType;
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];
  UnlinkedExecutableKind get kind => _kind ?? UnlinkedExecutableKind.functionOrMethod;
  bool get isAbstract => _isAbstract ?? false;
  bool get isStatic => _isStatic ?? false;
  bool get isConst => _isConst ?? false;
  bool get isFactory => _isFactory ?? false;
  bool get hasImplicitReturnType => _hasImplicitReturnType ?? false;
  bool get isExternal => _isExternal ?? false;
}

class UnlinkedExecutableBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedExecutableBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typeParameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["typeParameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set returnType(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("returnType"));
    if (_value != null) {
      _json["returnType"] = _value.finish();
    }
  }

  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("parameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["parameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set kind(UnlinkedExecutableKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (!(_value == null || _value == UnlinkedExecutableKind.functionOrMethod)) {
      _json["kind"] = _value.index;
    }
  }

  void set isAbstract(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isAbstract"));
    if (_value != null) {
      _json["isAbstract"] = _value;
    }
  }

  void set isStatic(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isStatic"));
    if (_value != null) {
      _json["isStatic"] = _value;
    }
  }

  void set isConst(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isConst"));
    if (_value != null) {
      _json["isConst"] = _value;
    }
  }

  void set isFactory(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isFactory"));
    if (_value != null) {
      _json["isFactory"] = _value;
    }
  }

  void set hasImplicitReturnType(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("hasImplicitReturnType"));
    if (_value != null) {
      _json["hasImplicitReturnType"] = _value;
    }
  }

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

UnlinkedExecutableBuilder encodeUnlinkedExecutable(base.BuilderContext builderContext, {String name, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters, UnlinkedExecutableKind kind, bool isAbstract, bool isStatic, bool isConst, bool isFactory, bool hasImplicitReturnType, bool isExternal}) {
  UnlinkedExecutableBuilder builder = new UnlinkedExecutableBuilder(builderContext);
  builder.name = name;
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

class UnlinkedExport extends base.SummaryClass {
  String _uri;
  List<UnlinkedCombinator> _combinators;

  UnlinkedExport.fromJson(Map json)
    : _uri = json["uri"],
      _combinators = json["combinators"]?.map((x) => new UnlinkedCombinator.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "uri": uri,
    "combinators": combinators,
  };

  String get uri => _uri ?? '';
  List<UnlinkedCombinator> get combinators => _combinators ?? const <UnlinkedCombinator>[];
}

class UnlinkedExportBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedExportBuilder(base.BuilderContext context);

  void set uri(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("uri"));
    if (_value != null) {
      _json["uri"] = _value;
    }
  }

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

UnlinkedExportBuilder encodeUnlinkedExport(base.BuilderContext builderContext, {String uri, List<UnlinkedCombinatorBuilder> combinators}) {
  UnlinkedExportBuilder builder = new UnlinkedExportBuilder(builderContext);
  builder.uri = uri;
  builder.combinators = combinators;
  return builder;
}

class UnlinkedImport extends base.SummaryClass {
  String _uri;
  int _offset;
  int _prefixReference;
  List<UnlinkedCombinator> _combinators;
  bool _isDeferred;
  bool _isImplicit;

  UnlinkedImport.fromJson(Map json)
    : _uri = json["uri"],
      _offset = json["offset"],
      _prefixReference = json["prefixReference"],
      _combinators = json["combinators"]?.map((x) => new UnlinkedCombinator.fromJson(x))?.toList(),
      _isDeferred = json["isDeferred"],
      _isImplicit = json["isImplicit"];

  @override
  Map<String, Object> toMap() => {
    "uri": uri,
    "offset": offset,
    "prefixReference": prefixReference,
    "combinators": combinators,
    "isDeferred": isDeferred,
    "isImplicit": isImplicit,
  };

  String get uri => _uri ?? '';
  int get offset => _offset ?? 0;
  int get prefixReference => _prefixReference ?? 0;
  List<UnlinkedCombinator> get combinators => _combinators ?? const <UnlinkedCombinator>[];
  bool get isDeferred => _isDeferred ?? false;
  bool get isImplicit => _isImplicit ?? false;
}

class UnlinkedImportBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedImportBuilder(base.BuilderContext context);

  void set uri(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("uri"));
    if (_value != null) {
      _json["uri"] = _value;
    }
  }

  void set offset(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("offset"));
    if (_value != null) {
      _json["offset"] = _value;
    }
  }

  void set prefixReference(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("prefixReference"));
    if (_value != null) {
      _json["prefixReference"] = _value;
    }
  }

  void set combinators(List<UnlinkedCombinatorBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("combinators"));
    if (!(_value == null || _value.isEmpty)) {
      _json["combinators"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set isDeferred(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isDeferred"));
    if (_value != null) {
      _json["isDeferred"] = _value;
    }
  }

  void set isImplicit(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isImplicit"));
    if (_value != null) {
      _json["isImplicit"] = _value;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedImportBuilder encodeUnlinkedImport(base.BuilderContext builderContext, {String uri, int offset, int prefixReference, List<UnlinkedCombinatorBuilder> combinators, bool isDeferred, bool isImplicit}) {
  UnlinkedImportBuilder builder = new UnlinkedImportBuilder(builderContext);
  builder.uri = uri;
  builder.offset = offset;
  builder.prefixReference = prefixReference;
  builder.combinators = combinators;
  builder.isDeferred = isDeferred;
  builder.isImplicit = isImplicit;
  return builder;
}

class UnlinkedParam extends base.SummaryClass {
  String _name;
  UnlinkedTypeRef _type;
  List<UnlinkedParam> _parameters;
  UnlinkedParamKind _kind;
  bool _isFunctionTyped;
  bool _isInitializingFormal;
  bool _hasImplicitType;

  UnlinkedParam.fromJson(Map json)
    : _name = json["name"],
      _type = json["type"] == null ? null : new UnlinkedTypeRef.fromJson(json["type"]),
      _parameters = json["parameters"]?.map((x) => new UnlinkedParam.fromJson(x))?.toList(),
      _kind = json["kind"] == null ? null : UnlinkedParamKind.values[json["kind"]],
      _isFunctionTyped = json["isFunctionTyped"],
      _isInitializingFormal = json["isInitializingFormal"],
      _hasImplicitType = json["hasImplicitType"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "type": type,
    "parameters": parameters,
    "kind": kind,
    "isFunctionTyped": isFunctionTyped,
    "isInitializingFormal": isInitializingFormal,
    "hasImplicitType": hasImplicitType,
  };

  String get name => _name ?? '';
  UnlinkedTypeRef get type => _type;
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];
  UnlinkedParamKind get kind => _kind ?? UnlinkedParamKind.required;
  bool get isFunctionTyped => _isFunctionTyped ?? false;
  bool get isInitializingFormal => _isInitializingFormal ?? false;
  bool get hasImplicitType => _hasImplicitType ?? false;
}

class UnlinkedParamBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedParamBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set type(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("type"));
    if (_value != null) {
      _json["type"] = _value.finish();
    }
  }

  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("parameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["parameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set kind(UnlinkedParamKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (!(_value == null || _value == UnlinkedParamKind.required)) {
      _json["kind"] = _value.index;
    }
  }

  void set isFunctionTyped(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isFunctionTyped"));
    if (_value != null) {
      _json["isFunctionTyped"] = _value;
    }
  }

  void set isInitializingFormal(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isInitializingFormal"));
    if (_value != null) {
      _json["isInitializingFormal"] = _value;
    }
  }

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

UnlinkedParamBuilder encodeUnlinkedParam(base.BuilderContext builderContext, {String name, UnlinkedTypeRefBuilder type, List<UnlinkedParamBuilder> parameters, UnlinkedParamKind kind, bool isFunctionTyped, bool isInitializingFormal, bool hasImplicitType}) {
  UnlinkedParamBuilder builder = new UnlinkedParamBuilder(builderContext);
  builder.name = name;
  builder.type = type;
  builder.parameters = parameters;
  builder.kind = kind;
  builder.isFunctionTyped = isFunctionTyped;
  builder.isInitializingFormal = isInitializingFormal;
  builder.hasImplicitType = hasImplicitType;
  return builder;
}

class UnlinkedPart extends base.SummaryClass {
  String _uri;

  UnlinkedPart.fromJson(Map json)
    : _uri = json["uri"];

  @override
  Map<String, Object> toMap() => {
    "uri": uri,
  };

  String get uri => _uri ?? '';
}

class UnlinkedPartBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedPartBuilder(base.BuilderContext context);

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

UnlinkedPartBuilder encodeUnlinkedPart(base.BuilderContext builderContext, {String uri}) {
  UnlinkedPartBuilder builder = new UnlinkedPartBuilder(builderContext);
  builder.uri = uri;
  return builder;
}

class UnlinkedPublicName extends base.SummaryClass {
  String _name;
  PrelinkedReferenceKind _kind;

  UnlinkedPublicName.fromJson(Map json)
    : _name = json["name"],
      _kind = json["kind"] == null ? null : PrelinkedReferenceKind.values[json["kind"]];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "kind": kind,
  };

  String get name => _name ?? '';
  PrelinkedReferenceKind get kind => _kind ?? PrelinkedReferenceKind.classOrEnum;
}

class UnlinkedPublicNameBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedPublicNameBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set kind(PrelinkedReferenceKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (!(_value == null || _value == PrelinkedReferenceKind.classOrEnum)) {
      _json["kind"] = _value.index;
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedPublicNameBuilder encodeUnlinkedPublicName(base.BuilderContext builderContext, {String name, PrelinkedReferenceKind kind}) {
  UnlinkedPublicNameBuilder builder = new UnlinkedPublicNameBuilder(builderContext);
  builder.name = name;
  builder.kind = kind;
  return builder;
}

class UnlinkedPublicNamespace extends base.SummaryClass {
  List<UnlinkedPublicName> _names;
  List<UnlinkedExport> _exports;
  List<UnlinkedPart> _parts;

  UnlinkedPublicNamespace.fromJson(Map json)
    : _names = json["names"]?.map((x) => new UnlinkedPublicName.fromJson(x))?.toList(),
      _exports = json["exports"]?.map((x) => new UnlinkedExport.fromJson(x))?.toList(),
      _parts = json["parts"]?.map((x) => new UnlinkedPart.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "names": names,
    "exports": exports,
    "parts": parts,
  };

  UnlinkedPublicNamespace.fromBuffer(List<int> buffer) : this.fromJson(JSON.decode(UTF8.decode(buffer)));

  List<UnlinkedPublicName> get names => _names ?? const <UnlinkedPublicName>[];
  List<UnlinkedExport> get exports => _exports ?? const <UnlinkedExport>[];
  List<UnlinkedPart> get parts => _parts ?? const <UnlinkedPart>[];
}

class UnlinkedPublicNamespaceBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedPublicNamespaceBuilder(base.BuilderContext context);

  void set names(List<UnlinkedPublicNameBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("names"));
    if (!(_value == null || _value.isEmpty)) {
      _json["names"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set exports(List<UnlinkedExportBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("exports"));
    if (!(_value == null || _value.isEmpty)) {
      _json["exports"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set parts(List<UnlinkedPartBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("parts"));
    if (!(_value == null || _value.isEmpty)) {
      _json["parts"] = _value.map((b) => b.finish()).toList();
    }
  }

  List<int> toBuffer() => UTF8.encode(JSON.encode(finish()));

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedPublicNamespaceBuilder encodeUnlinkedPublicNamespace(base.BuilderContext builderContext, {List<UnlinkedPublicNameBuilder> names, List<UnlinkedExportBuilder> exports, List<UnlinkedPartBuilder> parts}) {
  UnlinkedPublicNamespaceBuilder builder = new UnlinkedPublicNamespaceBuilder(builderContext);
  builder.names = names;
  builder.exports = exports;
  builder.parts = parts;
  return builder;
}

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

  String get name => _name ?? '';
  int get prefixReference => _prefixReference ?? 0;
}

class UnlinkedReferenceBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedReferenceBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

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

class UnlinkedTypedef extends base.SummaryClass {
  String _name;
  List<UnlinkedTypeParam> _typeParameters;
  UnlinkedTypeRef _returnType;
  List<UnlinkedParam> _parameters;

  UnlinkedTypedef.fromJson(Map json)
    : _name = json["name"],
      _typeParameters = json["typeParameters"]?.map((x) => new UnlinkedTypeParam.fromJson(x))?.toList(),
      _returnType = json["returnType"] == null ? null : new UnlinkedTypeRef.fromJson(json["returnType"]),
      _parameters = json["parameters"]?.map((x) => new UnlinkedParam.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "typeParameters": typeParameters,
    "returnType": returnType,
    "parameters": parameters,
  };

  String get name => _name ?? '';
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];
  UnlinkedTypeRef get returnType => _returnType;
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];
}

class UnlinkedTypedefBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedTypedefBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typeParameters"));
    if (!(_value == null || _value.isEmpty)) {
      _json["typeParameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set returnType(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("returnType"));
    if (_value != null) {
      _json["returnType"] = _value.finish();
    }
  }

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

UnlinkedTypedefBuilder encodeUnlinkedTypedef(base.BuilderContext builderContext, {String name, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters}) {
  UnlinkedTypedefBuilder builder = new UnlinkedTypedefBuilder(builderContext);
  builder.name = name;
  builder.typeParameters = typeParameters;
  builder.returnType = returnType;
  builder.parameters = parameters;
  return builder;
}

class UnlinkedTypeParam extends base.SummaryClass {
  String _name;
  UnlinkedTypeRef _bound;

  UnlinkedTypeParam.fromJson(Map json)
    : _name = json["name"],
      _bound = json["bound"] == null ? null : new UnlinkedTypeRef.fromJson(json["bound"]);

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "bound": bound,
  };

  String get name => _name ?? '';
  UnlinkedTypeRef get bound => _bound;
}

class UnlinkedTypeParamBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedTypeParamBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

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

UnlinkedTypeParamBuilder encodeUnlinkedTypeParam(base.BuilderContext builderContext, {String name, UnlinkedTypeRefBuilder bound}) {
  UnlinkedTypeParamBuilder builder = new UnlinkedTypeParamBuilder(builderContext);
  builder.name = name;
  builder.bound = bound;
  return builder;
}

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

  int get reference => _reference ?? 0;
  int get paramReference => _paramReference ?? 0;
  List<UnlinkedTypeRef> get typeArguments => _typeArguments ?? const <UnlinkedTypeRef>[];
}

class UnlinkedTypeRefBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedTypeRefBuilder(base.BuilderContext context);

  void set reference(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("reference"));
    if (_value != null) {
      _json["reference"] = _value;
    }
  }

  void set paramReference(int _value) {
    assert(!_finished);
    assert(!_json.containsKey("paramReference"));
    if (_value != null) {
      _json["paramReference"] = _value;
    }
  }

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

class UnlinkedUnit extends base.SummaryClass {
  String _libraryName;
  UnlinkedPublicNamespace _publicNamespace;
  List<UnlinkedReference> _references;
  List<UnlinkedClass> _classes;
  List<UnlinkedEnum> _enums;
  List<UnlinkedExecutable> _executables;
  List<UnlinkedImport> _imports;
  List<UnlinkedTypedef> _typedefs;
  List<UnlinkedVariable> _variables;

  UnlinkedUnit.fromJson(Map json)
    : _libraryName = json["libraryName"],
      _publicNamespace = json["publicNamespace"] == null ? null : new UnlinkedPublicNamespace.fromJson(json["publicNamespace"]),
      _references = json["references"]?.map((x) => new UnlinkedReference.fromJson(x))?.toList(),
      _classes = json["classes"]?.map((x) => new UnlinkedClass.fromJson(x))?.toList(),
      _enums = json["enums"]?.map((x) => new UnlinkedEnum.fromJson(x))?.toList(),
      _executables = json["executables"]?.map((x) => new UnlinkedExecutable.fromJson(x))?.toList(),
      _imports = json["imports"]?.map((x) => new UnlinkedImport.fromJson(x))?.toList(),
      _typedefs = json["typedefs"]?.map((x) => new UnlinkedTypedef.fromJson(x))?.toList(),
      _variables = json["variables"]?.map((x) => new UnlinkedVariable.fromJson(x))?.toList();

  @override
  Map<String, Object> toMap() => {
    "libraryName": libraryName,
    "publicNamespace": publicNamespace,
    "references": references,
    "classes": classes,
    "enums": enums,
    "executables": executables,
    "imports": imports,
    "typedefs": typedefs,
    "variables": variables,
  };

  UnlinkedUnit.fromBuffer(List<int> buffer) : this.fromJson(JSON.decode(UTF8.decode(buffer)));

  String get libraryName => _libraryName ?? '';
  UnlinkedPublicNamespace get publicNamespace => _publicNamespace;
  List<UnlinkedReference> get references => _references ?? const <UnlinkedReference>[];
  List<UnlinkedClass> get classes => _classes ?? const <UnlinkedClass>[];
  List<UnlinkedEnum> get enums => _enums ?? const <UnlinkedEnum>[];
  List<UnlinkedExecutable> get executables => _executables ?? const <UnlinkedExecutable>[];
  List<UnlinkedImport> get imports => _imports ?? const <UnlinkedImport>[];
  List<UnlinkedTypedef> get typedefs => _typedefs ?? const <UnlinkedTypedef>[];
  List<UnlinkedVariable> get variables => _variables ?? const <UnlinkedVariable>[];
}

class UnlinkedUnitBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedUnitBuilder(base.BuilderContext context);

  void set libraryName(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("libraryName"));
    if (_value != null) {
      _json["libraryName"] = _value;
    }
  }

  void set publicNamespace(UnlinkedPublicNamespaceBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("publicNamespace"));
    if (_value != null) {
      _json["publicNamespace"] = _value.finish();
    }
  }

  void set references(List<UnlinkedReferenceBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("references"));
    if (!(_value == null || _value.isEmpty)) {
      _json["references"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set classes(List<UnlinkedClassBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("classes"));
    if (!(_value == null || _value.isEmpty)) {
      _json["classes"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set enums(List<UnlinkedEnumBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("enums"));
    if (!(_value == null || _value.isEmpty)) {
      _json["enums"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("executables"));
    if (!(_value == null || _value.isEmpty)) {
      _json["executables"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set imports(List<UnlinkedImportBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("imports"));
    if (!(_value == null || _value.isEmpty)) {
      _json["imports"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set typedefs(List<UnlinkedTypedefBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typedefs"));
    if (!(_value == null || _value.isEmpty)) {
      _json["typedefs"] = _value.map((b) => b.finish()).toList();
    }
  }

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

UnlinkedUnitBuilder encodeUnlinkedUnit(base.BuilderContext builderContext, {String libraryName, UnlinkedPublicNamespaceBuilder publicNamespace, List<UnlinkedReferenceBuilder> references, List<UnlinkedClassBuilder> classes, List<UnlinkedEnumBuilder> enums, List<UnlinkedExecutableBuilder> executables, List<UnlinkedImportBuilder> imports, List<UnlinkedTypedefBuilder> typedefs, List<UnlinkedVariableBuilder> variables}) {
  UnlinkedUnitBuilder builder = new UnlinkedUnitBuilder(builderContext);
  builder.libraryName = libraryName;
  builder.publicNamespace = publicNamespace;
  builder.references = references;
  builder.classes = classes;
  builder.enums = enums;
  builder.executables = executables;
  builder.imports = imports;
  builder.typedefs = typedefs;
  builder.variables = variables;
  return builder;
}

class UnlinkedVariable extends base.SummaryClass {
  String _name;
  UnlinkedTypeRef _type;
  bool _isStatic;
  bool _isFinal;
  bool _isConst;
  bool _hasImplicitType;

  UnlinkedVariable.fromJson(Map json)
    : _name = json["name"],
      _type = json["type"] == null ? null : new UnlinkedTypeRef.fromJson(json["type"]),
      _isStatic = json["isStatic"],
      _isFinal = json["isFinal"],
      _isConst = json["isConst"],
      _hasImplicitType = json["hasImplicitType"];

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "type": type,
    "isStatic": isStatic,
    "isFinal": isFinal,
    "isConst": isConst,
    "hasImplicitType": hasImplicitType,
  };

  String get name => _name ?? '';
  UnlinkedTypeRef get type => _type;
  bool get isStatic => _isStatic ?? false;
  bool get isFinal => _isFinal ?? false;
  bool get isConst => _isConst ?? false;
  bool get hasImplicitType => _hasImplicitType ?? false;
}

class UnlinkedVariableBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedVariableBuilder(base.BuilderContext context);

  void set name(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set type(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("type"));
    if (_value != null) {
      _json["type"] = _value.finish();
    }
  }

  void set isStatic(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isStatic"));
    if (_value != null) {
      _json["isStatic"] = _value;
    }
  }

  void set isFinal(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isFinal"));
    if (_value != null) {
      _json["isFinal"] = _value;
    }
  }

  void set isConst(bool _value) {
    assert(!_finished);
    assert(!_json.containsKey("isConst"));
    if (_value != null) {
      _json["isConst"] = _value;
    }
  }

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

UnlinkedVariableBuilder encodeUnlinkedVariable(base.BuilderContext builderContext, {String name, UnlinkedTypeRefBuilder type, bool isStatic, bool isFinal, bool isConst, bool hasImplicitType}) {
  UnlinkedVariableBuilder builder = new UnlinkedVariableBuilder(builderContext);
  builder.name = name;
  builder.type = type;
  builder.isStatic = isStatic;
  builder.isFinal = isFinal;
  builder.isConst = isConst;
  builder.hasImplicitType = hasImplicitType;
  return builder;
}

