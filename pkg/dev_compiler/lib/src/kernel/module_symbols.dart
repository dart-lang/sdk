// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Dart debug symbol information stored by DDC.
//
// The data format below stores descriptions of dart code objects and their
// mapping to JS that is generated by DDC. Every field, except ids, describes
// dart.
// Note that 'localId' and 'scopeId' combine into a unique id that is used for
// object lookup and mapping between JS and dart concepts. As a result, it
// needs to be either stored or easily computed for each corresponding JS object
// created by DDC, so the debugger is able to look up dart symbol from JS ones.
//
// For example, to detect all dart variables in current scope and display
// their values, the debugger can do the following:
//
// - map current JS location to dart location using source maps
// - find all nested dart scopes that include the current dart location
// - collect all dart variables in scope
// - look up corresponding variables and their values in JS scope by their
//   JS ids
// - display their values (non-expanded)
//
// To display a JS value of variable 'v' (non-expanded)
//
// - v: <dart type name> (jsvalue.toString())
//
// Where <dart type name> is the dart type of the dart variable 'v'
// at runtime.
//
// TODO: describe displaying specific non-expanded JS instances in dart
// way, for example, lists, maps, types - is JS toString() enough?
//
// To display a value (expanded)
//
// - look up the JS runtime type of the value
// - find the dart value's runtime type by JS id value's runtime type id
// - collect all dart fields of that type, including the inherited fields
// - map dart fields to JS field ids and look up their values using object
//   ids referenced by the original displayed value.
// - display their values (non-expanded)
class SemanticVersion {
  final int major;
  final int minor;
  final int patch;
  const SemanticVersion(
    this.major,
    this.minor,
    this.patch,
  );
  static SemanticVersion parse(String version) {
    var parts = version.split('.');
    if (parts.length != 3) {
      throw FormatException('Version: $version '
          'does not follow simple semantic versioning format');
    }
    var major = int.parse(parts[0]);
    var minor = int.parse(parts[1]);
    var patch = int.parse(parts[2]);
    return SemanticVersion(major, minor, patch);
  }

  /// Text version.
  String get version => '$major.$minor.$patch';

  /// True if this version is compatible with [version].
  ///
  /// The minor and patch version changes never remove any fields that current
  /// version supports, so the reader can create current metadata version from
  /// any file created with a later reader, as long as the major version does
  /// not change.
  bool isCompatibleWith(String version) {
    var other = parse(version);
    return other.major == major && other.minor >= minor && other.patch >= patch;
  }
}

abstract class SymbolTableElement {
  Map<String, dynamic> toJson();
}

class ModuleSymbols implements SymbolTableElement {
  /// Current symbol information version.
  ///
  /// Version follows simple semantic versioning format 'major.minor.patch'
  /// See https://semver.org
  static const SemanticVersion current = SemanticVersion(0, 0, 1);

  /// Semantic version of the format.
  String version;

  /// Module name as used in the module metadata
  String moduleName;

  /// All dart libraries included in the module.
  ///
  /// Note here and below that imported elements are not included in
  /// the current module but can be referenced by their ids.
  List<LibrarySymbol> libraries;

  /// All dart scripts included in the module.
  List<Script> scripts;

  /// All dart classes included in the module.
  List<ClassSymbol> classes;

  /// All dart function types included in the module.
  List<FunctionTypeSymbol> functionTypes;

  /// All dart function types included in the module.
  List<FunctionSymbol> functions;

  /// All dart scopes included in the module.
  ///
  /// Does not include scopes listed in other fields,
  /// such as libraries, classes, and functions.
  List<ScopeSymbol> scopes;

  /// All dart variables included in the module.
  List<VariableSymbol> variables;
  ModuleSymbols({
    this.version,
    this.moduleName,
    this.libraries,
    this.scripts,
    this.classes,
    this.functionTypes,
    this.functions,
    this.scopes,
    this.variables,
  });
  ModuleSymbols.fromJson(Map<String, dynamic> json) {
    version = _createValue(json['version'], ifNull: current.version);
    if (!current.isCompatibleWith(version)) {
      throw Exception('Unsupported version $version. '
          'Current version: ${current.version}');
    }
    moduleName = _createValue(json['moduleName']);
    libraries = _createObjectList(
        json['libraries'], (json) => LibrarySymbol.fromJson(json));
    scripts =
        _createObjectList(json['scripts'], (json) => Script.fromJson(json));
    classes = _createObjectList(
        json['classes'], (json) => ClassSymbol.fromJson(json));
    functionTypes = _createObjectList(
        json['functionTypes'], (json) => FunctionTypeSymbol.fromJson(json));
    functions = _createObjectList(
        json['functions'], (json) => FunctionSymbol.fromJson(json));
    scopes =
        _createObjectList(json['scopes'], (json) => ScopeSymbol.fromJson(json));
    variables = _createObjectList(
        json['variables'], (json) => VariableSymbol.fromJson(json));
  }
  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _setValueIfNotNull(json, 'version', version);
    _setValueIfNotNull(json, 'moduleName', moduleName);
    _setObjectListIfNotNull(json, 'libraries', libraries);
    _setObjectListIfNotNull(json, 'scripts', scripts);
    _setObjectListIfNotNull(json, 'classes', classes);
    _setObjectListIfNotNull(json, 'functionTypes', functionTypes);
    _setObjectListIfNotNull(json, 'functions', functions);
    _setObjectListIfNotNull(json, 'scopes', scopes);
    _setObjectListIfNotNull(json, 'variables', variables);
    return json;
  }
}

class Symbol implements SymbolTableElement {
  /// Local id (such as JS name) for the symbol.
  ///
  /// Used to map from dart objects to JS objects inside a scope.
  String localId;

  /// Enclosing scope of the symbol.
  String scopeId;

  /// Unique Id, shared with JS representation (if any).
  ///
  /// '<scope id>|<js name>'
  ///
  /// Where scope refers to a Library, Class, Function, or Scope.
  String get id => scopeId == null ? localId : '$scopeId|$localId';

  /// Source location of the symbol.
  SourceLocation location;
  Symbol({this.localId, this.scopeId, this.location});
  Symbol.fromJson(Map<String, dynamic> json) {
    localId = _createValue(json['localId']);
    scopeId = _createValue(json['scopeId']);
    location = _createObject(
        json['location'], (json) => SourceLocation.fromJson(json));
  }
  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _setValueIfNotNull(json, 'localId', localId);
    _setValueIfNotNull(json, 'scopeId', scopeId);
    _setObjectIfNotNull(json, 'location', location);
    return json;
  }
}

abstract class TypeSymbol {
  String get id;
}

enum VariableSymbolKind { global, local, property, field, formal, none }
VariableSymbolKind parseVariableSymbolKind(String value) {
  return VariableSymbolKind.values.singleWhere((e) => value == '$e',
      orElse: () {
    throw ArgumentError('$value is not VariableSymbolKind');
  });
}

class VariableSymbol extends Symbol {
  /// Variable name
  String name;

  /// Symbol kind.
  VariableSymbolKind kind;

  /// The declared type of this symbol.
  String typeId;

  /// Is this variable const?
  bool isConst;

  /// Is this variable final?
  bool isFinal;

  /// Is this variable static?
  bool isStatic;

  /// Property getter, if any.
  String getterId;

  /// Property setter, if any.
  String setterId;
  VariableSymbol({
    this.name,
    this.kind,
    this.isConst,
    this.isFinal,
    this.isStatic,
    this.typeId,
    String localId,
    String scopeId,
    SourceLocation location,
  }) : super(localId: localId, scopeId: scopeId, location: location);
  VariableSymbol.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    name = _createValue(json['name']);
    kind = _createValue(json['kind'],
        parse: parseVariableSymbolKind, ifNull: VariableSymbolKind.none);
    isConst = _createValue(json['isConst']);
    isFinal = _createValue(json['isFinal']);
    isStatic = _createValue(json['isStatic']);
    typeId = _createValue(json['typeId']);
    setterId = _createValue(json['setterId']);
    getterId = _createValue(json['getterId']);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    _setValueIfNotNull(json, 'name', name);
    _setValueIfNotNull(json, 'kind', kind.toString());
    _setValueIfNotNull(json, 'isConst', isConst);
    _setValueIfNotNull(json, 'isFinal', isFinal);
    _setValueIfNotNull(json, 'isStatic', isStatic);
    _setValueIfNotNull(json, 'typeId', typeId);
    _setValueIfNotNull(json, 'setterId', setterId);
    _setValueIfNotNull(json, 'getterId', getterId);
    return json;
  }
}

class ClassSymbol extends ScopeSymbol implements TypeSymbol {
  /// The name of this class.
  String name;

  /// Is this an abstract class?
  bool isAbstract;

  /// Is this a const class?
  bool isConst;

  /// The superclass of this class, if any.
  String superClassId;

  /// A list of interface types for this class.
  List<String> interfaceIds;

  /// Mapping of type parameter dart names to JS names.
  Map<String, String> typeParameters;

  /// Library that contains this class.
  String get libraryId => scopeId;

  /// Fields in this class.
  ///
  /// Including static fields, methods, and properties.
  List<String> get fieldIds => variableIds;

  /// A list of functions in this class.
  ///
  /// Includes all static functions, methods, getters,
  /// and setters in the current class.
  ///
  /// Does not include functions from superclasses.
  List<String> get functionIds => scopeIds;
  ClassSymbol({
    this.name,
    this.isAbstract,
    this.isConst,
    this.superClassId,
    this.interfaceIds,
    this.typeParameters,
    String localId,
    String scopeId,
    SourceLocation location,
    List<String> variableIds,
    List<String> scopeIds,
  }) : super(
            localId: localId,
            scopeId: scopeId,
            variableIds: variableIds,
            scopeIds: scopeIds,
            location: location);
  ClassSymbol.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    name = _createValue(json['name']);
    isAbstract = _createValue(json['isAbstract']);
    isConst = _createValue(json['isConst']);
    superClassId = _createValue(json['superClassId']);
    interfaceIds = _createValueList(json['interfaceIds']);
    typeParameters = _createValueMap(json['typeParameters']);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    _setValueIfNotNull(json, 'name', name);
    _setValueIfNotNull(json, 'isAbstract', isAbstract);
    _setValueIfNotNull(json, 'isConst', isConst);
    _setValueIfNotNull(json, 'superClassId', superClassId);
    _setValueIfNotNull(json, 'interfaceIds', interfaceIds);
    _setValueIfNotNull(json, 'typeParameters', typeParameters);
    return json;
  }
}

class FunctionTypeSymbol extends Symbol implements TypeSymbol {
  /// Mapping of dart type parameter names to JS names.
  Map<String, String> typeParameters;

  /// Types for positional parameters for this function.
  List<String> parameterTypeIds;

  /// Types for optional positional parameters for this function.
  List<String> optionalParameterTypeIds;

  /// Names and types for named parameters for this function.
  Map<String, String> namedParameterTypeIds;

  /// A return type for this function.
  String returnTypeId;
  FunctionTypeSymbol({
    this.typeParameters,
    this.parameterTypeIds,
    this.optionalParameterTypeIds,
    this.namedParameterTypeIds,
    this.returnTypeId,
    String localId,
    String scopeId,
    SourceLocation location,
  }) : super(localId: localId, scopeId: scopeId, location: location);
  FunctionTypeSymbol.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    parameterTypeIds = _createValueList(json['parameterTypeIds']);
    optionalParameterTypeIds =
        _createValueList(json['optionalParameterTypeIds']);
    typeParameters = _createValueMap(json['typeParameters']);
    namedParameterTypeIds = _createValueMap(json['namedParameterTypeIds']);
    returnTypeId = _createValue(json['returnTypeId']);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    _setValueIfNotNull(json, 'typeParameters', typeParameters);
    _setValueIfNotNull(json, 'parameterTypeIds', parameterTypeIds);
    _setValueIfNotNull(
        json, 'optionalParameterTypeIds', optionalParameterTypeIds);
    _setValueIfNotNull(json, 'namedParameterTypeIds', namedParameterTypeIds);
    _setValueIfNotNull(json, 'returnTypeId', returnTypeId);
    return json;
  }
}

class FunctionSymbol extends ScopeSymbol {
  /// The name of this function.
  String name;

  /// Unique Id, shared with JS representation (if any).
  ///
  /// Format:
  ///   '<scope id>|<js name>'
  ///
  /// Where scope refers to a Library, Class, Function, or Scope.
  /// String id;
  /// Declared type of this function.
  String typeId;

  /// Is this function static?
  bool isStatic;

  /// Is this function const?
  bool isConst;
  FunctionSymbol({
    this.name,
    this.typeId,
    this.isStatic,
    this.isConst,
    String localId,
    String scopeId,
    List<String> variableIds,
    List<String> scopeIds,
    SourceLocation location,
  }) : super(
          localId: localId,
          scopeId: scopeId,
          variableIds: variableIds,
          scopeIds: scopeIds,
          location: location,
        );
  FunctionSymbol.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    name = _createValue(json['name']);
    typeId = _createValue(json['typeId']);
    isStatic = _createValue(json['isStatic']);
    isConst = _createValue(json['isConst']);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    _setValueIfNotNull(json, 'name', name);
    _setValueIfNotNull(json, 'typeId', typeId);
    _setValueIfNotNull(json, 'isStatic', isStatic);
    _setValueIfNotNull(json, 'isConst', isConst);
    return json;
  }
}

class LibrarySymbol extends ScopeSymbol {
  /// The name of this library.
  String name;

  /// Unique Id.
  ///
  /// Currently the debugger can find the library uri from JS location
  /// using source maps and module metadata.
  ///
  /// Can be same as library uri.
  /// String id;
  /// The uri of this library.
  String uri;

  /// A list of the imports for this library.
  List<LibrarySymbolDependency> dependencies;

  /// A list of the scripts which constitute this library.
  List<String> scriptIds;
  LibrarySymbol({
    this.name,
    this.uri,
    this.dependencies,
    this.scriptIds,
    List<String> variableIds,
    List<String> scopeIds,
  }) : super(
          localId: uri,
          variableIds: variableIds,
          scopeIds: scopeIds,
        );

  LibrarySymbol.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    name = _createValue(json['name'], ifNull: '');
    uri = _createValue(json['uri']);
    scriptIds = _createValueList(json['scriptIds']);
    dependencies = _createObjectList(
        json['dependencies'], (json) => LibrarySymbolDependency.fromJson(json));
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    _setValueIfNotNull(json, 'name', name);
    _setValueIfNotNull(json, 'uri', uri);
    _setValueIfNotNull(json, 'scriptIds', scriptIds);
    _setObjectListIfNotNull(json, 'dependencies', dependencies);
    return json;
  }
}

class LibrarySymbolDependency implements SymbolTableElement {
  /// Is this dependency an import (rather than an export)?
  bool isImport;

  /// Is this dependency deferred?
  bool isDeferred;

  /// The prefix of an 'as' import, or null.
  String prefix;

  /// The library being imported or exported.
  String targetId;
  LibrarySymbolDependency({
    this.isImport,
    this.isDeferred,
    this.prefix,
    this.targetId,
  });
  LibrarySymbolDependency.fromJson(Map<String, dynamic> json) {
    isImport = _createValue(json['isImport']);
    isDeferred = _createValue(json['isDeferred']);
    prefix = _createValue(json['prefix']);
    targetId = _createValue(json['targetId']);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _setValueIfNotNull(json, 'isImport', isImport);
    _setValueIfNotNull(json, 'isDeferred', isDeferred);
    _setValueIfNotNull(json, 'prefix', prefix);
    _setValueIfNotNull(json, 'targetId', targetId);
    return json;
  }
}

class Script implements SymbolTableElement {
  /// The uri from which this script was loaded.
  String uri;

  /// Unique Id.
  ///
  /// This can be just an integer. The mapping from JS to dart script
  /// happens using the source map. The id is only used for references
  /// in other elements.
  String localId;

  String libraryId;

  String get id => '$libraryId|$localId';

  Script({
    this.uri,
    this.localId,
    this.libraryId,
  });
  Script.fromJson(Map<String, dynamic> json) {
    uri = _createValue(json['uri']);
    localId = _createValue(json['localId']);
    libraryId = _createValue(json['libraryId']);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _setValueIfNotNull(json, 'uri', uri);
    _setValueIfNotNull(json, 'localId', localId);
    _setValueIfNotNull(json, 'libraryId', libraryId);

    return json;
  }
}

class ScopeSymbol extends Symbol {
  /// A list of the top-level variables in this scope.
  List<String> variableIds;

  /// Enclosed scopes.
  ///
  /// Includes all top classes, functions, inner scopes.
  List<String> scopeIds;
  ScopeSymbol({
    this.variableIds,
    this.scopeIds,
    String localId,
    String scopeId,
    SourceLocation location,
  }) : super(
          localId: localId,
          scopeId: scopeId,
          location: location,
        );
  ScopeSymbol.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    variableIds = _createValueList(json['variableIds']);
    scopeIds = _createValueList(json['scopeIds']);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    _setValueIfNotNull(json, 'variableIds', variableIds);
    _setValueIfNotNull(json, 'scopeIds', scopeIds);
    return json;
  }
}

class SourceLocation implements SymbolTableElement {
  /// The script containing the source location.
  String scriptId;

  /// The first token of the location.
  int tokenPos;

  /// The last token of the location if this is a range.
  int endTokenPos;
  SourceLocation({
    this.scriptId,
    this.tokenPos,
    this.endTokenPos,
  });
  SourceLocation.fromJson(Map<String, dynamic> json) {
    scriptId = _createValue(json['scriptId']);
    tokenPos = _createValue(json['tokenPos']);
    endTokenPos = _createValue(json['endTokenPos']);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _setValueIfNotNull(json, 'scriptId', scriptId);
    _setValueIfNotNull(json, 'tokenPos', tokenPos);
    _setValueIfNotNull(json, 'endTokenPos', endTokenPos);
    return json;
  }
}

List<T> _createObjectList<T>(
    dynamic json, T Function(Map<String, dynamic>) creator) {
  if (json == null) return null;
  if (json is List) {
    return json.map((e) => _createObject(e, creator)).toList();
  }
  throw ArgumentError('Not a list: $json');
}

T _createObject<T>(dynamic json, T Function(Map<String, dynamic>) creator) {
  if (json == null) return null;
  if (json is Map<String, dynamic>) {
    return creator(json);
  }
  throw ArgumentError('Not a map: $json');
}

List<T> _createValueList<T>(dynamic json,
    {T ifNull, T Function(String) parse}) {
  if (json == null) return null;
  if (json is List) {
    return json
        .map((e) => _createValue<T>(e, ifNull: ifNull, parse: parse))
        .toList();
  }
  throw ArgumentError('Not a list: $json');
}

Map<String, T> _createValueMap<T>(dynamic json) {
  if (json == null) return null;
  return Map<String, T>.from(json as Map<String, dynamic>);
}

T _createValue<T>(dynamic json, {T ifNull, T Function(String) parse}) {
  if (json == null) return ifNull;
  if (json is T) {
    return json;
  }
  if (json is String && parse != null) {
    return parse(json);
  }
  throw ArgumentError('Cannot parse $json as $T');
}

void _setObjectListIfNotNull<T extends SymbolTableElement>(
    Map<String, dynamic> json, String key, List<T> values) {
  if (values == null) return;
  json[key] = values.map((e) => e?.toJson()).toList();
}

void _setObjectIfNotNull<T extends SymbolTableElement>(
    Map<String, dynamic> json, String key, T value) {
  if (value == null) return;
  json[key] = value?.toJson();
}

void _setValueIfNotNull<T>(Map<String, dynamic> json, String key, T value) {
  if (value == null) return;
  json[key] = value;
}
