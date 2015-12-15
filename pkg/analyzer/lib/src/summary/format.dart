// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script "pkg/analyzer/tool/generate_files".

library analyzer.src.summary.format;

import 'dart:convert';
import 'builder.dart' as builder;

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

class PrelinkedDependency {
  String _uri;

  PrelinkedDependency.fromJson(Map json)
    : _uri = json["uri"];

  String get uri => _uri ?? '';
}

class PrelinkedDependencyBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedDependencyBuilder(builder.BuilderContext context);

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

PrelinkedDependencyBuilder encodePrelinkedDependency(builder.BuilderContext builderContext, {String uri}) {
  PrelinkedDependencyBuilder builder = new PrelinkedDependencyBuilder(builderContext);
  builder.uri = uri;
  return builder;
}

class PrelinkedLibrary {
  List<PrelinkedUnit> _units;
  List<PrelinkedDependency> _dependencies;
  List<int> _importDependencies;

  PrelinkedLibrary.fromJson(Map json)
    : _units = json["units"]?.map((x) => new PrelinkedUnit.fromJson(x))?.toList(),
      _dependencies = json["dependencies"]?.map((x) => new PrelinkedDependency.fromJson(x))?.toList(),
      _importDependencies = json["importDependencies"];

  PrelinkedLibrary.fromBuffer(List<int> buffer) : this.fromJson(JSON.decode(UTF8.decode(buffer)));

  List<PrelinkedUnit> get units => _units ?? const <PrelinkedUnit>[];
  List<PrelinkedDependency> get dependencies => _dependencies ?? const <PrelinkedDependency>[];
  List<int> get importDependencies => _importDependencies ?? const <int>[];
}

class PrelinkedLibraryBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedLibraryBuilder(builder.BuilderContext context);

  void set units(List<PrelinkedUnitBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("units"));
    if (_value != null || _value.isEmpty) {
      _json["units"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set dependencies(List<PrelinkedDependencyBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("dependencies"));
    if (_value != null || _value.isEmpty) {
      _json["dependencies"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set importDependencies(List<int> _value) {
    assert(!_finished);
    assert(!_json.containsKey("importDependencies"));
    if (_value != null || _value.isEmpty) {
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

PrelinkedLibraryBuilder encodePrelinkedLibrary(builder.BuilderContext builderContext, {List<PrelinkedUnitBuilder> units, List<PrelinkedDependencyBuilder> dependencies, List<int> importDependencies}) {
  PrelinkedLibraryBuilder builder = new PrelinkedLibraryBuilder(builderContext);
  builder.units = units;
  builder.dependencies = dependencies;
  builder.importDependencies = importDependencies;
  return builder;
}

class PrelinkedReference {
  int _dependency;
  PrelinkedReferenceKind _kind;
  int _unit;

  PrelinkedReference.fromJson(Map json)
    : _dependency = json["dependency"],
      _kind = json["kind"] == null ? null : PrelinkedReferenceKind.values[json["kind"]],
      _unit = json["unit"];

  int get dependency => _dependency ?? 0;
  PrelinkedReferenceKind get kind => _kind ?? PrelinkedReferenceKind.classOrEnum;
  int get unit => _unit ?? 0;
}

class PrelinkedReferenceBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedReferenceBuilder(builder.BuilderContext context);

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
    if (_value != null || _value == PrelinkedReferenceKind.classOrEnum) {
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

PrelinkedReferenceBuilder encodePrelinkedReference(builder.BuilderContext builderContext, {int dependency, PrelinkedReferenceKind kind, int unit}) {
  PrelinkedReferenceBuilder builder = new PrelinkedReferenceBuilder(builderContext);
  builder.dependency = dependency;
  builder.kind = kind;
  builder.unit = unit;
  return builder;
}

class PrelinkedUnit {
  UnlinkedUnit _unlinked;
  List<PrelinkedReference> _references;

  PrelinkedUnit.fromJson(Map json)
    : _unlinked = json["unlinked"] == null ? null : new UnlinkedUnit.fromJson(json["unlinked"]),
      _references = json["references"]?.map((x) => new PrelinkedReference.fromJson(x))?.toList();

  UnlinkedUnit get unlinked => _unlinked;
  List<PrelinkedReference> get references => _references ?? const <PrelinkedReference>[];
}

class PrelinkedUnitBuilder {
  final Map _json = {};

  bool _finished = false;

  PrelinkedUnitBuilder(builder.BuilderContext context);

  void set unlinked(UnlinkedUnitBuilder _value) {
    assert(!_finished);
    assert(!_json.containsKey("unlinked"));
    if (_value != null) {
      _json["unlinked"] = _value.finish();
    }
  }

  void set references(List<PrelinkedReferenceBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("references"));
    if (_value != null || _value.isEmpty) {
      _json["references"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

PrelinkedUnitBuilder encodePrelinkedUnit(builder.BuilderContext builderContext, {UnlinkedUnitBuilder unlinked, List<PrelinkedReferenceBuilder> references}) {
  PrelinkedUnitBuilder builder = new PrelinkedUnitBuilder(builderContext);
  builder.unlinked = unlinked;
  builder.references = references;
  return builder;
}

class UnlinkedClass {
  String _name;
  List<UnlinkedTypeParam> _typeParameters;
  UnlinkedTypeRef _supertype;
  List<UnlinkedTypeRef> _mixins;
  List<UnlinkedTypeRef> _interfaces;
  List<UnlinkedVariable> _fields;
  List<UnlinkedExecutable> _executables;
  bool _isAbstract;
  bool _isMixinApplication;

  UnlinkedClass.fromJson(Map json)
    : _name = json["name"],
      _typeParameters = json["typeParameters"]?.map((x) => new UnlinkedTypeParam.fromJson(x))?.toList(),
      _supertype = json["supertype"] == null ? null : new UnlinkedTypeRef.fromJson(json["supertype"]),
      _mixins = json["mixins"]?.map((x) => new UnlinkedTypeRef.fromJson(x))?.toList(),
      _interfaces = json["interfaces"]?.map((x) => new UnlinkedTypeRef.fromJson(x))?.toList(),
      _fields = json["fields"]?.map((x) => new UnlinkedVariable.fromJson(x))?.toList(),
      _executables = json["executables"]?.map((x) => new UnlinkedExecutable.fromJson(x))?.toList(),
      _isAbstract = json["isAbstract"],
      _isMixinApplication = json["isMixinApplication"];

  String get name => _name ?? '';
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];
  UnlinkedTypeRef get supertype => _supertype;
  List<UnlinkedTypeRef> get mixins => _mixins ?? const <UnlinkedTypeRef>[];
  List<UnlinkedTypeRef> get interfaces => _interfaces ?? const <UnlinkedTypeRef>[];
  List<UnlinkedVariable> get fields => _fields ?? const <UnlinkedVariable>[];
  List<UnlinkedExecutable> get executables => _executables ?? const <UnlinkedExecutable>[];
  bool get isAbstract => _isAbstract ?? false;
  bool get isMixinApplication => _isMixinApplication ?? false;
}

class UnlinkedClassBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedClassBuilder(builder.BuilderContext context);

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
    if (_value != null || _value.isEmpty) {
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
    if (_value != null || _value.isEmpty) {
      _json["mixins"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set interfaces(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("interfaces"));
    if (_value != null || _value.isEmpty) {
      _json["interfaces"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set fields(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("fields"));
    if (_value != null || _value.isEmpty) {
      _json["fields"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("executables"));
    if (_value != null || _value.isEmpty) {
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

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedClassBuilder encodeUnlinkedClass(builder.BuilderContext builderContext, {String name, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder supertype, List<UnlinkedTypeRefBuilder> mixins, List<UnlinkedTypeRefBuilder> interfaces, List<UnlinkedVariableBuilder> fields, List<UnlinkedExecutableBuilder> executables, bool isAbstract, bool isMixinApplication}) {
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
  return builder;
}

class UnlinkedCombinator {
  List<UnlinkedCombinatorName> _shows;
  List<UnlinkedCombinatorName> _hides;

  UnlinkedCombinator.fromJson(Map json)
    : _shows = json["shows"]?.map((x) => new UnlinkedCombinatorName.fromJson(x))?.toList(),
      _hides = json["hides"]?.map((x) => new UnlinkedCombinatorName.fromJson(x))?.toList();

  List<UnlinkedCombinatorName> get shows => _shows ?? const <UnlinkedCombinatorName>[];
  List<UnlinkedCombinatorName> get hides => _hides ?? const <UnlinkedCombinatorName>[];
}

class UnlinkedCombinatorBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedCombinatorBuilder(builder.BuilderContext context);

  void set shows(List<UnlinkedCombinatorNameBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("shows"));
    if (_value != null || _value.isEmpty) {
      _json["shows"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set hides(List<UnlinkedCombinatorNameBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("hides"));
    if (_value != null || _value.isEmpty) {
      _json["hides"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedCombinatorBuilder encodeUnlinkedCombinator(builder.BuilderContext builderContext, {List<UnlinkedCombinatorNameBuilder> shows, List<UnlinkedCombinatorNameBuilder> hides}) {
  UnlinkedCombinatorBuilder builder = new UnlinkedCombinatorBuilder(builderContext);
  builder.shows = shows;
  builder.hides = hides;
  return builder;
}

class UnlinkedCombinatorName {
  String _name;

  UnlinkedCombinatorName.fromJson(Map json)
    : _name = json["name"];

  String get name => _name ?? '';
}

class UnlinkedCombinatorNameBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedCombinatorNameBuilder(builder.BuilderContext context);

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

UnlinkedCombinatorNameBuilder encodeUnlinkedCombinatorName(builder.BuilderContext builderContext, {String name}) {
  UnlinkedCombinatorNameBuilder builder = new UnlinkedCombinatorNameBuilder(builderContext);
  builder.name = name;
  return builder;
}

class UnlinkedEnum {
  String _name;
  List<UnlinkedEnumValue> _values;

  UnlinkedEnum.fromJson(Map json)
    : _name = json["name"],
      _values = json["values"]?.map((x) => new UnlinkedEnumValue.fromJson(x))?.toList();

  String get name => _name ?? '';
  List<UnlinkedEnumValue> get values => _values ?? const <UnlinkedEnumValue>[];
}

class UnlinkedEnumBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedEnumBuilder(builder.BuilderContext context);

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
    if (_value != null || _value.isEmpty) {
      _json["values"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedEnumBuilder encodeUnlinkedEnum(builder.BuilderContext builderContext, {String name, List<UnlinkedEnumValueBuilder> values}) {
  UnlinkedEnumBuilder builder = new UnlinkedEnumBuilder(builderContext);
  builder.name = name;
  builder.values = values;
  return builder;
}

class UnlinkedEnumValue {
  String _name;

  UnlinkedEnumValue.fromJson(Map json)
    : _name = json["name"];

  String get name => _name ?? '';
}

class UnlinkedEnumValueBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedEnumValueBuilder(builder.BuilderContext context);

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

UnlinkedEnumValueBuilder encodeUnlinkedEnumValue(builder.BuilderContext builderContext, {String name}) {
  UnlinkedEnumValueBuilder builder = new UnlinkedEnumValueBuilder(builderContext);
  builder.name = name;
  return builder;
}

class UnlinkedExecutable {
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
      _hasImplicitReturnType = json["hasImplicitReturnType"];

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
}

class UnlinkedExecutableBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedExecutableBuilder(builder.BuilderContext context);

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
    if (_value != null || _value.isEmpty) {
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
    if (_value != null || _value.isEmpty) {
      _json["parameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set kind(UnlinkedExecutableKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (_value != null || _value == UnlinkedExecutableKind.functionOrMethod) {
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

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedExecutableBuilder encodeUnlinkedExecutable(builder.BuilderContext builderContext, {String name, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters, UnlinkedExecutableKind kind, bool isAbstract, bool isStatic, bool isConst, bool isFactory, bool hasImplicitReturnType}) {
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
  return builder;
}

class UnlinkedExport {
  String _uri;
  List<UnlinkedCombinator> _combinators;

  UnlinkedExport.fromJson(Map json)
    : _uri = json["uri"],
      _combinators = json["combinators"]?.map((x) => new UnlinkedCombinator.fromJson(x))?.toList();

  String get uri => _uri ?? '';
  List<UnlinkedCombinator> get combinators => _combinators ?? const <UnlinkedCombinator>[];
}

class UnlinkedExportBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedExportBuilder(builder.BuilderContext context);

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
    if (_value != null || _value.isEmpty) {
      _json["combinators"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedExportBuilder encodeUnlinkedExport(builder.BuilderContext builderContext, {String uri, List<UnlinkedCombinatorBuilder> combinators}) {
  UnlinkedExportBuilder builder = new UnlinkedExportBuilder(builderContext);
  builder.uri = uri;
  builder.combinators = combinators;
  return builder;
}

class UnlinkedImport {
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

  UnlinkedImportBuilder(builder.BuilderContext context);

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
    if (_value != null || _value.isEmpty) {
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

UnlinkedImportBuilder encodeUnlinkedImport(builder.BuilderContext builderContext, {String uri, int offset, int prefixReference, List<UnlinkedCombinatorBuilder> combinators, bool isDeferred, bool isImplicit}) {
  UnlinkedImportBuilder builder = new UnlinkedImportBuilder(builderContext);
  builder.uri = uri;
  builder.offset = offset;
  builder.prefixReference = prefixReference;
  builder.combinators = combinators;
  builder.isDeferred = isDeferred;
  builder.isImplicit = isImplicit;
  return builder;
}

class UnlinkedParam {
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

  UnlinkedParamBuilder(builder.BuilderContext context);

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
    if (_value != null || _value.isEmpty) {
      _json["parameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set kind(UnlinkedParamKind _value) {
    assert(!_finished);
    assert(!_json.containsKey("kind"));
    if (_value != null || _value == UnlinkedParamKind.required) {
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

UnlinkedParamBuilder encodeUnlinkedParam(builder.BuilderContext builderContext, {String name, UnlinkedTypeRefBuilder type, List<UnlinkedParamBuilder> parameters, UnlinkedParamKind kind, bool isFunctionTyped, bool isInitializingFormal, bool hasImplicitType}) {
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

class UnlinkedPart {
  String _uri;

  UnlinkedPart.fromJson(Map json)
    : _uri = json["uri"];

  String get uri => _uri ?? '';
}

class UnlinkedPartBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedPartBuilder(builder.BuilderContext context);

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

UnlinkedPartBuilder encodeUnlinkedPart(builder.BuilderContext builderContext, {String uri}) {
  UnlinkedPartBuilder builder = new UnlinkedPartBuilder(builderContext);
  builder.uri = uri;
  return builder;
}

class UnlinkedReference {
  String _name;
  int _prefixReference;

  UnlinkedReference.fromJson(Map json)
    : _name = json["name"],
      _prefixReference = json["prefixReference"];

  String get name => _name ?? '';
  int get prefixReference => _prefixReference ?? 0;
}

class UnlinkedReferenceBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedReferenceBuilder(builder.BuilderContext context);

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

UnlinkedReferenceBuilder encodeUnlinkedReference(builder.BuilderContext builderContext, {String name, int prefixReference}) {
  UnlinkedReferenceBuilder builder = new UnlinkedReferenceBuilder(builderContext);
  builder.name = name;
  builder.prefixReference = prefixReference;
  return builder;
}

class UnlinkedTypedef {
  String _name;
  List<UnlinkedTypeParam> _typeParameters;
  UnlinkedTypeRef _returnType;
  List<UnlinkedParam> _parameters;

  UnlinkedTypedef.fromJson(Map json)
    : _name = json["name"],
      _typeParameters = json["typeParameters"]?.map((x) => new UnlinkedTypeParam.fromJson(x))?.toList(),
      _returnType = json["returnType"] == null ? null : new UnlinkedTypeRef.fromJson(json["returnType"]),
      _parameters = json["parameters"]?.map((x) => new UnlinkedParam.fromJson(x))?.toList();

  String get name => _name ?? '';
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];
  UnlinkedTypeRef get returnType => _returnType;
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];
}

class UnlinkedTypedefBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedTypedefBuilder(builder.BuilderContext context);

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
    if (_value != null || _value.isEmpty) {
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
    if (_value != null || _value.isEmpty) {
      _json["parameters"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedTypedefBuilder encodeUnlinkedTypedef(builder.BuilderContext builderContext, {String name, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters}) {
  UnlinkedTypedefBuilder builder = new UnlinkedTypedefBuilder(builderContext);
  builder.name = name;
  builder.typeParameters = typeParameters;
  builder.returnType = returnType;
  builder.parameters = parameters;
  return builder;
}

class UnlinkedTypeParam {
  String _name;
  UnlinkedTypeRef _bound;

  UnlinkedTypeParam.fromJson(Map json)
    : _name = json["name"],
      _bound = json["bound"] == null ? null : new UnlinkedTypeRef.fromJson(json["bound"]);

  String get name => _name ?? '';
  UnlinkedTypeRef get bound => _bound;
}

class UnlinkedTypeParamBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedTypeParamBuilder(builder.BuilderContext context);

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

UnlinkedTypeParamBuilder encodeUnlinkedTypeParam(builder.BuilderContext builderContext, {String name, UnlinkedTypeRefBuilder bound}) {
  UnlinkedTypeParamBuilder builder = new UnlinkedTypeParamBuilder(builderContext);
  builder.name = name;
  builder.bound = bound;
  return builder;
}

class UnlinkedTypeRef {
  int _reference;
  int _paramReference;
  List<UnlinkedTypeRef> _typeArguments;

  UnlinkedTypeRef.fromJson(Map json)
    : _reference = json["reference"],
      _paramReference = json["paramReference"],
      _typeArguments = json["typeArguments"]?.map((x) => new UnlinkedTypeRef.fromJson(x))?.toList();

  int get reference => _reference ?? 0;
  int get paramReference => _paramReference ?? 0;
  List<UnlinkedTypeRef> get typeArguments => _typeArguments ?? const <UnlinkedTypeRef>[];
}

class UnlinkedTypeRefBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedTypeRefBuilder(builder.BuilderContext context);

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
    if (_value != null || _value.isEmpty) {
      _json["typeArguments"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedTypeRefBuilder encodeUnlinkedTypeRef(builder.BuilderContext builderContext, {int reference, int paramReference, List<UnlinkedTypeRefBuilder> typeArguments}) {
  UnlinkedTypeRefBuilder builder = new UnlinkedTypeRefBuilder(builderContext);
  builder.reference = reference;
  builder.paramReference = paramReference;
  builder.typeArguments = typeArguments;
  return builder;
}

class UnlinkedUnit {
  String _libraryName;
  List<UnlinkedReference> _references;
  List<UnlinkedClass> _classes;
  List<UnlinkedEnum> _enums;
  List<UnlinkedExecutable> _executables;
  List<UnlinkedExport> _exports;
  List<UnlinkedImport> _imports;
  List<UnlinkedPart> _parts;
  List<UnlinkedTypedef> _typedefs;
  List<UnlinkedVariable> _variables;

  UnlinkedUnit.fromJson(Map json)
    : _libraryName = json["libraryName"],
      _references = json["references"]?.map((x) => new UnlinkedReference.fromJson(x))?.toList(),
      _classes = json["classes"]?.map((x) => new UnlinkedClass.fromJson(x))?.toList(),
      _enums = json["enums"]?.map((x) => new UnlinkedEnum.fromJson(x))?.toList(),
      _executables = json["executables"]?.map((x) => new UnlinkedExecutable.fromJson(x))?.toList(),
      _exports = json["exports"]?.map((x) => new UnlinkedExport.fromJson(x))?.toList(),
      _imports = json["imports"]?.map((x) => new UnlinkedImport.fromJson(x))?.toList(),
      _parts = json["parts"]?.map((x) => new UnlinkedPart.fromJson(x))?.toList(),
      _typedefs = json["typedefs"]?.map((x) => new UnlinkedTypedef.fromJson(x))?.toList(),
      _variables = json["variables"]?.map((x) => new UnlinkedVariable.fromJson(x))?.toList();

  String get libraryName => _libraryName ?? '';
  List<UnlinkedReference> get references => _references ?? const <UnlinkedReference>[];
  List<UnlinkedClass> get classes => _classes ?? const <UnlinkedClass>[];
  List<UnlinkedEnum> get enums => _enums ?? const <UnlinkedEnum>[];
  List<UnlinkedExecutable> get executables => _executables ?? const <UnlinkedExecutable>[];
  List<UnlinkedExport> get exports => _exports ?? const <UnlinkedExport>[];
  List<UnlinkedImport> get imports => _imports ?? const <UnlinkedImport>[];
  List<UnlinkedPart> get parts => _parts ?? const <UnlinkedPart>[];
  List<UnlinkedTypedef> get typedefs => _typedefs ?? const <UnlinkedTypedef>[];
  List<UnlinkedVariable> get variables => _variables ?? const <UnlinkedVariable>[];
}

class UnlinkedUnitBuilder {
  final Map _json = {};

  bool _finished = false;

  UnlinkedUnitBuilder(builder.BuilderContext context);

  void set libraryName(String _value) {
    assert(!_finished);
    assert(!_json.containsKey("libraryName"));
    if (_value != null) {
      _json["libraryName"] = _value;
    }
  }

  void set references(List<UnlinkedReferenceBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("references"));
    if (_value != null || _value.isEmpty) {
      _json["references"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set classes(List<UnlinkedClassBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("classes"));
    if (_value != null || _value.isEmpty) {
      _json["classes"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set enums(List<UnlinkedEnumBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("enums"));
    if (_value != null || _value.isEmpty) {
      _json["enums"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("executables"));
    if (_value != null || _value.isEmpty) {
      _json["executables"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set exports(List<UnlinkedExportBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("exports"));
    if (_value != null || _value.isEmpty) {
      _json["exports"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set imports(List<UnlinkedImportBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("imports"));
    if (_value != null || _value.isEmpty) {
      _json["imports"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set parts(List<UnlinkedPartBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("parts"));
    if (_value != null || _value.isEmpty) {
      _json["parts"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set typedefs(List<UnlinkedTypedefBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("typedefs"));
    if (_value != null || _value.isEmpty) {
      _json["typedefs"] = _value.map((b) => b.finish()).toList();
    }
  }

  void set variables(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    assert(!_json.containsKey("variables"));
    if (_value != null || _value.isEmpty) {
      _json["variables"] = _value.map((b) => b.finish()).toList();
    }
  }

  Map finish() {
    assert(!_finished);
    _finished = true;
    return _json;
  }
}

UnlinkedUnitBuilder encodeUnlinkedUnit(builder.BuilderContext builderContext, {String libraryName, List<UnlinkedReferenceBuilder> references, List<UnlinkedClassBuilder> classes, List<UnlinkedEnumBuilder> enums, List<UnlinkedExecutableBuilder> executables, List<UnlinkedExportBuilder> exports, List<UnlinkedImportBuilder> imports, List<UnlinkedPartBuilder> parts, List<UnlinkedTypedefBuilder> typedefs, List<UnlinkedVariableBuilder> variables}) {
  UnlinkedUnitBuilder builder = new UnlinkedUnitBuilder(builderContext);
  builder.libraryName = libraryName;
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

class UnlinkedVariable {
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

  UnlinkedVariableBuilder(builder.BuilderContext context);

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

UnlinkedVariableBuilder encodeUnlinkedVariable(builder.BuilderContext builderContext, {String name, UnlinkedTypeRefBuilder type, bool isStatic, bool isFinal, bool isConst, bool hasImplicitType}) {
  UnlinkedVariableBuilder builder = new UnlinkedVariableBuilder(builderContext);
  builder.name = name;
  builder.type = type;
  builder.isStatic = isStatic;
  builder.isFinal = isFinal;
  builder.isConst = isConst;
  builder.hasImplicitType = hasImplicitType;
  return builder;
}

