// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script "pkg/analyzer/tool/generate_files".

library analyzer.src.summary.format;

import 'builder.dart' as builder;

enum PrelinkedReferenceKind {
  classOrEnum,
  typedef,
  other,
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

  PrelinkedDependencyBuilder(builder.BuilderContext context);

  void set uri(String _value) {
    assert(!_json.containsKey("uri"));
    if (_value != null) {
      _json["uri"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodePrelinkedDependency(builder.BuilderContext builderContext, {String uri}) {
  PrelinkedDependencyBuilder builder = new PrelinkedDependencyBuilder(builderContext);
  builder.uri = uri;
  return builder.finish();
}

class PrelinkedLibrary {
  UnlinkedLibrary _unlinked;
  List<PrelinkedDependency> _dependencies;
  List<int> _importDependencies;
  List<PrelinkedReference> _references;

  PrelinkedLibrary.fromJson(Map json)
    : _unlinked = json["unlinked"] == null ? null : new UnlinkedLibrary.fromJson(json["unlinked"]),
      _dependencies = json["dependencies"]?.map((x) => new PrelinkedDependency.fromJson(x))?.toList(),
      _importDependencies = json["importDependencies"],
      _references = json["references"]?.map((x) => new PrelinkedReference.fromJson(x))?.toList();

  UnlinkedLibrary get unlinked => _unlinked;
  List<PrelinkedDependency> get dependencies => _dependencies ?? const <PrelinkedDependency>[];
  List<int> get importDependencies => _importDependencies ?? const <int>[];
  List<PrelinkedReference> get references => _references ?? const <PrelinkedReference>[];
}

class PrelinkedLibraryBuilder {
  final Map _json = {};

  PrelinkedLibraryBuilder(builder.BuilderContext context);

  void set unlinked(Object _value) {
    assert(!_json.containsKey("unlinked"));
    if (_value != null) {
      _json["unlinked"] = _value;
    }
  }

  void set dependencies(List<Object> _value) {
    assert(!_json.containsKey("dependencies"));
    if (_value != null || _value.isEmpty) {
      _json["dependencies"] = _value.toList();
    }
  }

  void set importDependencies(List<int> _value) {
    assert(!_json.containsKey("importDependencies"));
    if (_value != null || _value.isEmpty) {
      _json["importDependencies"] = _value.toList();
    }
  }

  void set references(List<Object> _value) {
    assert(!_json.containsKey("references"));
    if (_value != null || _value.isEmpty) {
      _json["references"] = _value.toList();
    }
  }

  Object finish() => _json;
}

Object encodePrelinkedLibrary(builder.BuilderContext builderContext, {Object unlinked, List<Object> dependencies, List<int> importDependencies, List<Object> references}) {
  PrelinkedLibraryBuilder builder = new PrelinkedLibraryBuilder(builderContext);
  builder.unlinked = unlinked;
  builder.dependencies = dependencies;
  builder.importDependencies = importDependencies;
  builder.references = references;
  return builder.finish();
}

class PrelinkedReference {
  int _dependency;
  PrelinkedReferenceKind _kind;

  PrelinkedReference.fromJson(Map json)
    : _dependency = json["dependency"],
      _kind = json["kind"] == null ? null : PrelinkedReferenceKind.values[json["kind"]];

  int get dependency => _dependency ?? 0;
  PrelinkedReferenceKind get kind => _kind ?? PrelinkedReferenceKind.classOrEnum;
}

class PrelinkedReferenceBuilder {
  final Map _json = {};

  PrelinkedReferenceBuilder(builder.BuilderContext context);

  void set dependency(int _value) {
    assert(!_json.containsKey("dependency"));
    if (_value != null) {
      _json["dependency"] = _value;
    }
  }

  void set kind(PrelinkedReferenceKind _value) {
    assert(!_json.containsKey("kind"));
    if (_value != null || _value == PrelinkedReferenceKind.classOrEnum) {
      _json["kind"] = _value.index;
    }
  }

  Object finish() => _json;
}

Object encodePrelinkedReference(builder.BuilderContext builderContext, {int dependency, PrelinkedReferenceKind kind}) {
  PrelinkedReferenceBuilder builder = new PrelinkedReferenceBuilder(builderContext);
  builder.dependency = dependency;
  builder.kind = kind;
  return builder.finish();
}

class UnlinkedClass {
  String _name;
  int _unit;
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
      _unit = json["unit"],
      _typeParameters = json["typeParameters"]?.map((x) => new UnlinkedTypeParam.fromJson(x))?.toList(),
      _supertype = json["supertype"] == null ? null : new UnlinkedTypeRef.fromJson(json["supertype"]),
      _mixins = json["mixins"]?.map((x) => new UnlinkedTypeRef.fromJson(x))?.toList(),
      _interfaces = json["interfaces"]?.map((x) => new UnlinkedTypeRef.fromJson(x))?.toList(),
      _fields = json["fields"]?.map((x) => new UnlinkedVariable.fromJson(x))?.toList(),
      _executables = json["executables"]?.map((x) => new UnlinkedExecutable.fromJson(x))?.toList(),
      _isAbstract = json["isAbstract"],
      _isMixinApplication = json["isMixinApplication"];

  String get name => _name ?? '';
  int get unit => _unit ?? 0;
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

  UnlinkedClassBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set unit(int _value) {
    assert(!_json.containsKey("unit"));
    if (_value != null) {
      _json["unit"] = _value;
    }
  }

  void set typeParameters(List<Object> _value) {
    assert(!_json.containsKey("typeParameters"));
    if (_value != null || _value.isEmpty) {
      _json["typeParameters"] = _value.toList();
    }
  }

  void set supertype(Object _value) {
    assert(!_json.containsKey("supertype"));
    if (_value != null) {
      _json["supertype"] = _value;
    }
  }

  void set mixins(List<Object> _value) {
    assert(!_json.containsKey("mixins"));
    if (_value != null || _value.isEmpty) {
      _json["mixins"] = _value.toList();
    }
  }

  void set interfaces(List<Object> _value) {
    assert(!_json.containsKey("interfaces"));
    if (_value != null || _value.isEmpty) {
      _json["interfaces"] = _value.toList();
    }
  }

  void set fields(List<Object> _value) {
    assert(!_json.containsKey("fields"));
    if (_value != null || _value.isEmpty) {
      _json["fields"] = _value.toList();
    }
  }

  void set executables(List<Object> _value) {
    assert(!_json.containsKey("executables"));
    if (_value != null || _value.isEmpty) {
      _json["executables"] = _value.toList();
    }
  }

  void set isAbstract(bool _value) {
    assert(!_json.containsKey("isAbstract"));
    if (_value != null) {
      _json["isAbstract"] = _value;
    }
  }

  void set isMixinApplication(bool _value) {
    assert(!_json.containsKey("isMixinApplication"));
    if (_value != null) {
      _json["isMixinApplication"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedClass(builder.BuilderContext builderContext, {String name, int unit, List<Object> typeParameters, Object supertype, List<Object> mixins, List<Object> interfaces, List<Object> fields, List<Object> executables, bool isAbstract, bool isMixinApplication}) {
  UnlinkedClassBuilder builder = new UnlinkedClassBuilder(builderContext);
  builder.name = name;
  builder.unit = unit;
  builder.typeParameters = typeParameters;
  builder.supertype = supertype;
  builder.mixins = mixins;
  builder.interfaces = interfaces;
  builder.fields = fields;
  builder.executables = executables;
  builder.isAbstract = isAbstract;
  builder.isMixinApplication = isMixinApplication;
  return builder.finish();
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

  UnlinkedCombinatorBuilder(builder.BuilderContext context);

  void set shows(List<Object> _value) {
    assert(!_json.containsKey("shows"));
    if (_value != null || _value.isEmpty) {
      _json["shows"] = _value.toList();
    }
  }

  void set hides(List<Object> _value) {
    assert(!_json.containsKey("hides"));
    if (_value != null || _value.isEmpty) {
      _json["hides"] = _value.toList();
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedCombinator(builder.BuilderContext builderContext, {List<Object> shows, List<Object> hides}) {
  UnlinkedCombinatorBuilder builder = new UnlinkedCombinatorBuilder(builderContext);
  builder.shows = shows;
  builder.hides = hides;
  return builder.finish();
}

class UnlinkedCombinatorName {
  String _name;

  UnlinkedCombinatorName.fromJson(Map json)
    : _name = json["name"];

  String get name => _name ?? '';
}

class UnlinkedCombinatorNameBuilder {
  final Map _json = {};

  UnlinkedCombinatorNameBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedCombinatorName(builder.BuilderContext builderContext, {String name}) {
  UnlinkedCombinatorNameBuilder builder = new UnlinkedCombinatorNameBuilder(builderContext);
  builder.name = name;
  return builder.finish();
}

class UnlinkedEnum {
  String _name;
  List<UnlinkedEnumValue> _values;
  int _unit;

  UnlinkedEnum.fromJson(Map json)
    : _name = json["name"],
      _values = json["values"]?.map((x) => new UnlinkedEnumValue.fromJson(x))?.toList(),
      _unit = json["unit"];

  String get name => _name ?? '';
  List<UnlinkedEnumValue> get values => _values ?? const <UnlinkedEnumValue>[];
  int get unit => _unit ?? 0;
}

class UnlinkedEnumBuilder {
  final Map _json = {};

  UnlinkedEnumBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set values(List<Object> _value) {
    assert(!_json.containsKey("values"));
    if (_value != null || _value.isEmpty) {
      _json["values"] = _value.toList();
    }
  }

  void set unit(int _value) {
    assert(!_json.containsKey("unit"));
    if (_value != null) {
      _json["unit"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedEnum(builder.BuilderContext builderContext, {String name, List<Object> values, int unit}) {
  UnlinkedEnumBuilder builder = new UnlinkedEnumBuilder(builderContext);
  builder.name = name;
  builder.values = values;
  builder.unit = unit;
  return builder.finish();
}

class UnlinkedEnumValue {
  String _name;

  UnlinkedEnumValue.fromJson(Map json)
    : _name = json["name"];

  String get name => _name ?? '';
}

class UnlinkedEnumValueBuilder {
  final Map _json = {};

  UnlinkedEnumValueBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedEnumValue(builder.BuilderContext builderContext, {String name}) {
  UnlinkedEnumValueBuilder builder = new UnlinkedEnumValueBuilder(builderContext);
  builder.name = name;
  return builder.finish();
}

class UnlinkedExecutable {
  String _name;
  int _unit;
  List<UnlinkedTypeParam> _typeParameters;
  UnlinkedTypeRef _returnType;
  List<UnlinkedParam> _parameters;
  UnlinkedExecutableKind _kind;
  bool _isAbstract;
  bool _isStatic;
  bool _isConst;
  bool _isFactory;

  UnlinkedExecutable.fromJson(Map json)
    : _name = json["name"],
      _unit = json["unit"],
      _typeParameters = json["typeParameters"]?.map((x) => new UnlinkedTypeParam.fromJson(x))?.toList(),
      _returnType = json["returnType"] == null ? null : new UnlinkedTypeRef.fromJson(json["returnType"]),
      _parameters = json["parameters"]?.map((x) => new UnlinkedParam.fromJson(x))?.toList(),
      _kind = json["kind"] == null ? null : UnlinkedExecutableKind.values[json["kind"]],
      _isAbstract = json["isAbstract"],
      _isStatic = json["isStatic"],
      _isConst = json["isConst"],
      _isFactory = json["isFactory"];

  String get name => _name ?? '';
  int get unit => _unit ?? 0;
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];
  UnlinkedTypeRef get returnType => _returnType;
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];
  UnlinkedExecutableKind get kind => _kind ?? UnlinkedExecutableKind.functionOrMethod;
  bool get isAbstract => _isAbstract ?? false;
  bool get isStatic => _isStatic ?? false;
  bool get isConst => _isConst ?? false;
  bool get isFactory => _isFactory ?? false;
}

class UnlinkedExecutableBuilder {
  final Map _json = {};

  UnlinkedExecutableBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set unit(int _value) {
    assert(!_json.containsKey("unit"));
    if (_value != null) {
      _json["unit"] = _value;
    }
  }

  void set typeParameters(List<Object> _value) {
    assert(!_json.containsKey("typeParameters"));
    if (_value != null || _value.isEmpty) {
      _json["typeParameters"] = _value.toList();
    }
  }

  void set returnType(Object _value) {
    assert(!_json.containsKey("returnType"));
    if (_value != null) {
      _json["returnType"] = _value;
    }
  }

  void set parameters(List<Object> _value) {
    assert(!_json.containsKey("parameters"));
    if (_value != null || _value.isEmpty) {
      _json["parameters"] = _value.toList();
    }
  }

  void set kind(UnlinkedExecutableKind _value) {
    assert(!_json.containsKey("kind"));
    if (_value != null || _value == UnlinkedExecutableKind.functionOrMethod) {
      _json["kind"] = _value.index;
    }
  }

  void set isAbstract(bool _value) {
    assert(!_json.containsKey("isAbstract"));
    if (_value != null) {
      _json["isAbstract"] = _value;
    }
  }

  void set isStatic(bool _value) {
    assert(!_json.containsKey("isStatic"));
    if (_value != null) {
      _json["isStatic"] = _value;
    }
  }

  void set isConst(bool _value) {
    assert(!_json.containsKey("isConst"));
    if (_value != null) {
      _json["isConst"] = _value;
    }
  }

  void set isFactory(bool _value) {
    assert(!_json.containsKey("isFactory"));
    if (_value != null) {
      _json["isFactory"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedExecutable(builder.BuilderContext builderContext, {String name, int unit, List<Object> typeParameters, Object returnType, List<Object> parameters, UnlinkedExecutableKind kind, bool isAbstract, bool isStatic, bool isConst, bool isFactory}) {
  UnlinkedExecutableBuilder builder = new UnlinkedExecutableBuilder(builderContext);
  builder.name = name;
  builder.unit = unit;
  builder.typeParameters = typeParameters;
  builder.returnType = returnType;
  builder.parameters = parameters;
  builder.kind = kind;
  builder.isAbstract = isAbstract;
  builder.isStatic = isStatic;
  builder.isConst = isConst;
  builder.isFactory = isFactory;
  return builder.finish();
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

  UnlinkedExportBuilder(builder.BuilderContext context);

  void set uri(String _value) {
    assert(!_json.containsKey("uri"));
    if (_value != null) {
      _json["uri"] = _value;
    }
  }

  void set combinators(List<Object> _value) {
    assert(!_json.containsKey("combinators"));
    if (_value != null || _value.isEmpty) {
      _json["combinators"] = _value.toList();
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedExport(builder.BuilderContext builderContext, {String uri, List<Object> combinators}) {
  UnlinkedExportBuilder builder = new UnlinkedExportBuilder(builderContext);
  builder.uri = uri;
  builder.combinators = combinators;
  return builder.finish();
}

class UnlinkedImport {
  String _uri;
  int _offset;
  int _prefix;
  List<UnlinkedCombinator> _combinators;
  bool _isDeferred;
  bool _isImplicit;

  UnlinkedImport.fromJson(Map json)
    : _uri = json["uri"],
      _offset = json["offset"],
      _prefix = json["prefix"],
      _combinators = json["combinators"]?.map((x) => new UnlinkedCombinator.fromJson(x))?.toList(),
      _isDeferred = json["isDeferred"],
      _isImplicit = json["isImplicit"];

  String get uri => _uri ?? '';
  int get offset => _offset ?? 0;
  int get prefix => _prefix ?? 0;
  List<UnlinkedCombinator> get combinators => _combinators ?? const <UnlinkedCombinator>[];
  bool get isDeferred => _isDeferred ?? false;
  bool get isImplicit => _isImplicit ?? false;
}

class UnlinkedImportBuilder {
  final Map _json = {};

  UnlinkedImportBuilder(builder.BuilderContext context);

  void set uri(String _value) {
    assert(!_json.containsKey("uri"));
    if (_value != null) {
      _json["uri"] = _value;
    }
  }

  void set offset(int _value) {
    assert(!_json.containsKey("offset"));
    if (_value != null) {
      _json["offset"] = _value;
    }
  }

  void set prefix(int _value) {
    assert(!_json.containsKey("prefix"));
    if (_value != null) {
      _json["prefix"] = _value;
    }
  }

  void set combinators(List<Object> _value) {
    assert(!_json.containsKey("combinators"));
    if (_value != null || _value.isEmpty) {
      _json["combinators"] = _value.toList();
    }
  }

  void set isDeferred(bool _value) {
    assert(!_json.containsKey("isDeferred"));
    if (_value != null) {
      _json["isDeferred"] = _value;
    }
  }

  void set isImplicit(bool _value) {
    assert(!_json.containsKey("isImplicit"));
    if (_value != null) {
      _json["isImplicit"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedImport(builder.BuilderContext builderContext, {String uri, int offset, int prefix, List<Object> combinators, bool isDeferred, bool isImplicit}) {
  UnlinkedImportBuilder builder = new UnlinkedImportBuilder(builderContext);
  builder.uri = uri;
  builder.offset = offset;
  builder.prefix = prefix;
  builder.combinators = combinators;
  builder.isDeferred = isDeferred;
  builder.isImplicit = isImplicit;
  return builder.finish();
}

class UnlinkedLibrary {
  List<UnlinkedReference> _references;
  List<UnlinkedUnit> _units;
  String _name;
  List<UnlinkedClass> _classes;
  List<UnlinkedEnum> _enums;
  List<UnlinkedExecutable> _executables;
  List<UnlinkedExport> _exports;
  List<UnlinkedImport> _imports;
  List<UnlinkedTypedef> _typedefs;
  List<UnlinkedVariable> _variables;
  List<UnlinkedPrefix> _prefixes;

  UnlinkedLibrary.fromJson(Map json)
    : _references = json["references"]?.map((x) => new UnlinkedReference.fromJson(x))?.toList(),
      _units = json["units"]?.map((x) => new UnlinkedUnit.fromJson(x))?.toList(),
      _name = json["name"],
      _classes = json["classes"]?.map((x) => new UnlinkedClass.fromJson(x))?.toList(),
      _enums = json["enums"]?.map((x) => new UnlinkedEnum.fromJson(x))?.toList(),
      _executables = json["executables"]?.map((x) => new UnlinkedExecutable.fromJson(x))?.toList(),
      _exports = json["exports"]?.map((x) => new UnlinkedExport.fromJson(x))?.toList(),
      _imports = json["imports"]?.map((x) => new UnlinkedImport.fromJson(x))?.toList(),
      _typedefs = json["typedefs"]?.map((x) => new UnlinkedTypedef.fromJson(x))?.toList(),
      _variables = json["variables"]?.map((x) => new UnlinkedVariable.fromJson(x))?.toList(),
      _prefixes = json["prefixes"]?.map((x) => new UnlinkedPrefix.fromJson(x))?.toList();

  List<UnlinkedReference> get references => _references ?? const <UnlinkedReference>[];
  List<UnlinkedUnit> get units => _units ?? const <UnlinkedUnit>[];
  String get name => _name ?? '';
  List<UnlinkedClass> get classes => _classes ?? const <UnlinkedClass>[];
  List<UnlinkedEnum> get enums => _enums ?? const <UnlinkedEnum>[];
  List<UnlinkedExecutable> get executables => _executables ?? const <UnlinkedExecutable>[];
  List<UnlinkedExport> get exports => _exports ?? const <UnlinkedExport>[];
  List<UnlinkedImport> get imports => _imports ?? const <UnlinkedImport>[];
  List<UnlinkedTypedef> get typedefs => _typedefs ?? const <UnlinkedTypedef>[];
  List<UnlinkedVariable> get variables => _variables ?? const <UnlinkedVariable>[];
  List<UnlinkedPrefix> get prefixes => _prefixes ?? const <UnlinkedPrefix>[];
}

class UnlinkedLibraryBuilder {
  final Map _json = {};

  UnlinkedLibraryBuilder(builder.BuilderContext context);

  void set references(List<Object> _value) {
    assert(!_json.containsKey("references"));
    if (_value != null || _value.isEmpty) {
      _json["references"] = _value.toList();
    }
  }

  void set units(List<Object> _value) {
    assert(!_json.containsKey("units"));
    if (_value != null || _value.isEmpty) {
      _json["units"] = _value.toList();
    }
  }

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set classes(List<Object> _value) {
    assert(!_json.containsKey("classes"));
    if (_value != null || _value.isEmpty) {
      _json["classes"] = _value.toList();
    }
  }

  void set enums(List<Object> _value) {
    assert(!_json.containsKey("enums"));
    if (_value != null || _value.isEmpty) {
      _json["enums"] = _value.toList();
    }
  }

  void set executables(List<Object> _value) {
    assert(!_json.containsKey("executables"));
    if (_value != null || _value.isEmpty) {
      _json["executables"] = _value.toList();
    }
  }

  void set exports(List<Object> _value) {
    assert(!_json.containsKey("exports"));
    if (_value != null || _value.isEmpty) {
      _json["exports"] = _value.toList();
    }
  }

  void set imports(List<Object> _value) {
    assert(!_json.containsKey("imports"));
    if (_value != null || _value.isEmpty) {
      _json["imports"] = _value.toList();
    }
  }

  void set typedefs(List<Object> _value) {
    assert(!_json.containsKey("typedefs"));
    if (_value != null || _value.isEmpty) {
      _json["typedefs"] = _value.toList();
    }
  }

  void set variables(List<Object> _value) {
    assert(!_json.containsKey("variables"));
    if (_value != null || _value.isEmpty) {
      _json["variables"] = _value.toList();
    }
  }

  void set prefixes(List<Object> _value) {
    assert(!_json.containsKey("prefixes"));
    if (_value != null || _value.isEmpty) {
      _json["prefixes"] = _value.toList();
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedLibrary(builder.BuilderContext builderContext, {List<Object> references, List<Object> units, String name, List<Object> classes, List<Object> enums, List<Object> executables, List<Object> exports, List<Object> imports, List<Object> typedefs, List<Object> variables, List<Object> prefixes}) {
  UnlinkedLibraryBuilder builder = new UnlinkedLibraryBuilder(builderContext);
  builder.references = references;
  builder.units = units;
  builder.name = name;
  builder.classes = classes;
  builder.enums = enums;
  builder.executables = executables;
  builder.exports = exports;
  builder.imports = imports;
  builder.typedefs = typedefs;
  builder.variables = variables;
  builder.prefixes = prefixes;
  return builder.finish();
}

class UnlinkedParam {
  String _name;
  UnlinkedTypeRef _type;
  List<UnlinkedParam> _parameters;
  UnlinkedParamKind _kind;
  bool _isFunctionTyped;
  bool _isInitializingFormal;

  UnlinkedParam.fromJson(Map json)
    : _name = json["name"],
      _type = json["type"] == null ? null : new UnlinkedTypeRef.fromJson(json["type"]),
      _parameters = json["parameters"]?.map((x) => new UnlinkedParam.fromJson(x))?.toList(),
      _kind = json["kind"] == null ? null : UnlinkedParamKind.values[json["kind"]],
      _isFunctionTyped = json["isFunctionTyped"],
      _isInitializingFormal = json["isInitializingFormal"];

  String get name => _name ?? '';
  UnlinkedTypeRef get type => _type;
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];
  UnlinkedParamKind get kind => _kind ?? UnlinkedParamKind.required;
  bool get isFunctionTyped => _isFunctionTyped ?? false;
  bool get isInitializingFormal => _isInitializingFormal ?? false;
}

class UnlinkedParamBuilder {
  final Map _json = {};

  UnlinkedParamBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set type(Object _value) {
    assert(!_json.containsKey("type"));
    if (_value != null) {
      _json["type"] = _value;
    }
  }

  void set parameters(List<Object> _value) {
    assert(!_json.containsKey("parameters"));
    if (_value != null || _value.isEmpty) {
      _json["parameters"] = _value.toList();
    }
  }

  void set kind(UnlinkedParamKind _value) {
    assert(!_json.containsKey("kind"));
    if (_value != null || _value == UnlinkedParamKind.required) {
      _json["kind"] = _value.index;
    }
  }

  void set isFunctionTyped(bool _value) {
    assert(!_json.containsKey("isFunctionTyped"));
    if (_value != null) {
      _json["isFunctionTyped"] = _value;
    }
  }

  void set isInitializingFormal(bool _value) {
    assert(!_json.containsKey("isInitializingFormal"));
    if (_value != null) {
      _json["isInitializingFormal"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedParam(builder.BuilderContext builderContext, {String name, Object type, List<Object> parameters, UnlinkedParamKind kind, bool isFunctionTyped, bool isInitializingFormal}) {
  UnlinkedParamBuilder builder = new UnlinkedParamBuilder(builderContext);
  builder.name = name;
  builder.type = type;
  builder.parameters = parameters;
  builder.kind = kind;
  builder.isFunctionTyped = isFunctionTyped;
  builder.isInitializingFormal = isInitializingFormal;
  return builder.finish();
}

class UnlinkedPrefix {
  String _name;

  UnlinkedPrefix.fromJson(Map json)
    : _name = json["name"];

  String get name => _name ?? '';
}

class UnlinkedPrefixBuilder {
  final Map _json = {};

  UnlinkedPrefixBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedPrefix(builder.BuilderContext builderContext, {String name}) {
  UnlinkedPrefixBuilder builder = new UnlinkedPrefixBuilder(builderContext);
  builder.name = name;
  return builder.finish();
}

class UnlinkedReference {
  String _name;
  int _prefix;

  UnlinkedReference.fromJson(Map json)
    : _name = json["name"],
      _prefix = json["prefix"];

  String get name => _name ?? '';
  int get prefix => _prefix ?? 0;
}

class UnlinkedReferenceBuilder {
  final Map _json = {};

  UnlinkedReferenceBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set prefix(int _value) {
    assert(!_json.containsKey("prefix"));
    if (_value != null) {
      _json["prefix"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedReference(builder.BuilderContext builderContext, {String name, int prefix}) {
  UnlinkedReferenceBuilder builder = new UnlinkedReferenceBuilder(builderContext);
  builder.name = name;
  builder.prefix = prefix;
  return builder.finish();
}

class UnlinkedTypedef {
  String _name;
  int _unit;
  List<UnlinkedTypeParam> _typeParameters;
  UnlinkedTypeRef _returnType;
  List<UnlinkedParam> _parameters;

  UnlinkedTypedef.fromJson(Map json)
    : _name = json["name"],
      _unit = json["unit"],
      _typeParameters = json["typeParameters"]?.map((x) => new UnlinkedTypeParam.fromJson(x))?.toList(),
      _returnType = json["returnType"] == null ? null : new UnlinkedTypeRef.fromJson(json["returnType"]),
      _parameters = json["parameters"]?.map((x) => new UnlinkedParam.fromJson(x))?.toList();

  String get name => _name ?? '';
  int get unit => _unit ?? 0;
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];
  UnlinkedTypeRef get returnType => _returnType;
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];
}

class UnlinkedTypedefBuilder {
  final Map _json = {};

  UnlinkedTypedefBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set unit(int _value) {
    assert(!_json.containsKey("unit"));
    if (_value != null) {
      _json["unit"] = _value;
    }
  }

  void set typeParameters(List<Object> _value) {
    assert(!_json.containsKey("typeParameters"));
    if (_value != null || _value.isEmpty) {
      _json["typeParameters"] = _value.toList();
    }
  }

  void set returnType(Object _value) {
    assert(!_json.containsKey("returnType"));
    if (_value != null) {
      _json["returnType"] = _value;
    }
  }

  void set parameters(List<Object> _value) {
    assert(!_json.containsKey("parameters"));
    if (_value != null || _value.isEmpty) {
      _json["parameters"] = _value.toList();
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedTypedef(builder.BuilderContext builderContext, {String name, int unit, List<Object> typeParameters, Object returnType, List<Object> parameters}) {
  UnlinkedTypedefBuilder builder = new UnlinkedTypedefBuilder(builderContext);
  builder.name = name;
  builder.unit = unit;
  builder.typeParameters = typeParameters;
  builder.returnType = returnType;
  builder.parameters = parameters;
  return builder.finish();
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

  UnlinkedTypeParamBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set bound(Object _value) {
    assert(!_json.containsKey("bound"));
    if (_value != null) {
      _json["bound"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedTypeParam(builder.BuilderContext builderContext, {String name, Object bound}) {
  UnlinkedTypeParamBuilder builder = new UnlinkedTypeParamBuilder(builderContext);
  builder.name = name;
  builder.bound = bound;
  return builder.finish();
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

  UnlinkedTypeRefBuilder(builder.BuilderContext context);

  void set reference(int _value) {
    assert(!_json.containsKey("reference"));
    if (_value != null) {
      _json["reference"] = _value;
    }
  }

  void set paramReference(int _value) {
    assert(!_json.containsKey("paramReference"));
    if (_value != null) {
      _json["paramReference"] = _value;
    }
  }

  void set typeArguments(List<Object> _value) {
    assert(!_json.containsKey("typeArguments"));
    if (_value != null || _value.isEmpty) {
      _json["typeArguments"] = _value.toList();
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedTypeRef(builder.BuilderContext builderContext, {int reference, int paramReference, List<Object> typeArguments}) {
  UnlinkedTypeRefBuilder builder = new UnlinkedTypeRefBuilder(builderContext);
  builder.reference = reference;
  builder.paramReference = paramReference;
  builder.typeArguments = typeArguments;
  return builder.finish();
}

class UnlinkedUnit {
  String _uri;

  UnlinkedUnit.fromJson(Map json)
    : _uri = json["uri"];

  String get uri => _uri ?? '';
}

class UnlinkedUnitBuilder {
  final Map _json = {};

  UnlinkedUnitBuilder(builder.BuilderContext context);

  void set uri(String _value) {
    assert(!_json.containsKey("uri"));
    if (_value != null) {
      _json["uri"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedUnit(builder.BuilderContext builderContext, {String uri}) {
  UnlinkedUnitBuilder builder = new UnlinkedUnitBuilder(builderContext);
  builder.uri = uri;
  return builder.finish();
}

class UnlinkedVariable {
  String _name;
  int _unit;
  UnlinkedTypeRef _type;
  bool _isStatic;
  bool _isFinal;
  bool _isConst;

  UnlinkedVariable.fromJson(Map json)
    : _name = json["name"],
      _unit = json["unit"],
      _type = json["type"] == null ? null : new UnlinkedTypeRef.fromJson(json["type"]),
      _isStatic = json["isStatic"],
      _isFinal = json["isFinal"],
      _isConst = json["isConst"];

  String get name => _name ?? '';
  int get unit => _unit ?? 0;
  UnlinkedTypeRef get type => _type;
  bool get isStatic => _isStatic ?? false;
  bool get isFinal => _isFinal ?? false;
  bool get isConst => _isConst ?? false;
}

class UnlinkedVariableBuilder {
  final Map _json = {};

  UnlinkedVariableBuilder(builder.BuilderContext context);

  void set name(String _value) {
    assert(!_json.containsKey("name"));
    if (_value != null) {
      _json["name"] = _value;
    }
  }

  void set unit(int _value) {
    assert(!_json.containsKey("unit"));
    if (_value != null) {
      _json["unit"] = _value;
    }
  }

  void set type(Object _value) {
    assert(!_json.containsKey("type"));
    if (_value != null) {
      _json["type"] = _value;
    }
  }

  void set isStatic(bool _value) {
    assert(!_json.containsKey("isStatic"));
    if (_value != null) {
      _json["isStatic"] = _value;
    }
  }

  void set isFinal(bool _value) {
    assert(!_json.containsKey("isFinal"));
    if (_value != null) {
      _json["isFinal"] = _value;
    }
  }

  void set isConst(bool _value) {
    assert(!_json.containsKey("isConst"));
    if (_value != null) {
      _json["isConst"] = _value;
    }
  }

  Object finish() => _json;
}

Object encodeUnlinkedVariable(builder.BuilderContext builderContext, {String name, int unit, Object type, bool isStatic, bool isFinal, bool isConst}) {
  UnlinkedVariableBuilder builder = new UnlinkedVariableBuilder(builderContext);
  builder.name = name;
  builder.unit = unit;
  builder.type = type;
  builder.isStatic = isStatic;
  builder.isFinal = isFinal;
  builder.isConst = isConst;
  return builder.finish();
}

