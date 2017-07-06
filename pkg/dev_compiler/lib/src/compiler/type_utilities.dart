// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart' show TypeParameterMember;
import 'package:analyzer/dart/element/type.dart';

import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;
import 'js_names.dart' as JS;

Set<TypeParameterElement> freeTypeParameters(DartType t) {
  var result = new Set<TypeParameterElement>();
  void find(DartType t) {
    if (t is TypeParameterType) {
      result.add(t.element);
    } else if (t is FunctionType) {
      find(t.returnType);
      t.parameters.forEach((p) => find(p.type));
      t.typeFormals.forEach((p) => find(p.bound));
      t.typeFormals.forEach(result.remove);
    } else if (t is InterfaceType) {
      t.typeArguments.forEach(find);
    }
  }

  find(t);
  return result;
}

/// _CacheTable tracks cache variables for variables that
/// are emitted in place with a hoisted variable for a cache.
class _CacheTable {
  /// Mapping from types to their canonical names.
  // Use a LinkedHashMap to maintain key insertion order so the generated code
  // is stable under slight perturbation.  (If this is not good enough we could
  // sort by name to canonicalize order.)
  final _names = <DartType, JS.TemporaryId>{};
  Iterable<DartType> get keys => _names.keys.toList();

  JS.Statement _dischargeType(DartType type) {
    var name = _names.remove(type);
    if (name != null) {
      return js.statement('let #;', [name]);
    }
    return null;
  }

  /// Emit a list of statements declaring the cache variables for
  /// types tracked by this table.  If [typeFilter] is given,
  /// only emit the types listed in the filter.
  List<JS.Statement> discharge([Iterable<DartType> typeFilter]) {
    var decls = <JS.Statement>[];
    var types = typeFilter ?? keys;
    for (var t in types) {
      var stmt = _dischargeType(t);
      if (stmt != null) decls.add(stmt);
    }
    return decls;
  }

  bool isNamed(DartType type) => _names.containsKey(type);

  /// If [type] is not already in the table, choose a new canonical
  /// variable to contain it. Emit an expression which uses [typeRep] to
  /// lazily initialize the cache in place.
  JS.Expression nameType(DartType type, JS.Expression typeRep) {
    var temp = _names[type];
    if (temp == null) {
      _names[type] = temp = chooseTypeName(type);
    }
    return js.call('# || (# = #)', [temp, temp, typeRep]);
  }

  String _safeTypeName(String name) {
    if (name == "<bottom>") return "bottom";
    return name;
  }

  String _typeString(DartType type, {bool flat: false}) {
    if (type is ParameterizedType && type.name != null) {
      var clazz = type.name;
      var params = type.typeArguments;
      if (params == null) return clazz;
      if (params.every((p) => p.isDynamic)) return clazz;
      var paramStrings = params.map(_typeString);
      var paramString = paramStrings.join("\$");
      return "${clazz}Of${paramString}";
    }
    if (type is FunctionType) {
      if (flat) return "Fn";
      var rType = _typeString(type.returnType, flat: true);
      var paramStrings = type.normalParameterTypes
          .take(3)
          .map((p) => _typeString(p, flat: true));
      var paramString = paramStrings.join("And");
      var count = type.normalParameterTypes.length;
      if (count > 3 ||
          type.namedParameterTypes.isNotEmpty ||
          type.optionalParameterTypes.isNotEmpty) {
        paramString = "${paramString}__";
      } else if (count == 0) {
        paramString = "Void";
      }
      return "${paramString}To${rType}";
    }
    if (type is TypeParameterType) return type.name;
    return _safeTypeName(type.name ?? "type");
  }

  /// Heuristically choose a good name for the cache and generator
  /// variables.
  JS.Identifier chooseTypeName(DartType type) {
    return new JS.TemporaryId(_typeString(type));
  }
}

/// _GeneratorTable tracks types which have been
/// named and hoisted.
class _GeneratorTable extends _CacheTable {
  final _defs = <DartType, JS.Expression>{};

  final JS.Identifier _runtimeModule;

  _GeneratorTable(this._runtimeModule);

  JS.Statement _dischargeType(DartType t) {
    var name = _names.remove(t);
    if (name != null) {
      JS.Expression init = _defs.remove(t);
      assert(init != null);
      return js.statement('let # = () => ((# = #.constFn(#))());',
          [name, name, _runtimeModule, init]);
    }
    return null;
  }

  /// If [type] does not already have a generator name chosen for it,
  /// assign it one, using [typeRep] as the initializer for it.
  /// Emit an expression which calls the generator name.
  JS.Expression nameType(DartType type, JS.Expression typeRep) {
    var temp = _names[type];
    if (temp == null) {
      _names[type] = temp = chooseTypeName(type);
      _defs[type] = typeRep;
    }
    return js.call('#()', [temp]);
  }
}

class TypeTable {
  /// Cache variable names for types emitted in place.
  final _cacheNames = new _CacheTable();

  /// Cache variable names for definite function types emitted in place.
  final _definiteCacheNames = new _CacheTable();

  /// Generator variable names for hoisted types.
  final _GeneratorTable _generators;

  /// Generator variable names for hoisted definite function types.
  final _GeneratorTable _definiteGenerators;

  /// Mapping from type parameters to the types which must have their
  /// cache/generator variables discharged at the binding site for the
  /// type variable since the type definition depends on the type
  /// parameter.
  final _scopeDependencies = <TypeParameterElement, List<DartType>>{};

  TypeTable(JS.Identifier runtime)
      : _generators = new _GeneratorTable(runtime),
        _definiteGenerators = new _GeneratorTable(runtime);

  /// Emit a list of statements declaring the cache variables and generator
  /// definitions tracked by the table.  If [formals] is present, only
  /// emit the definitions which depend on the formals.
  List<JS.Statement> discharge([List<TypeParameterElement> formals]) {
    var filter = formals?.expand((p) => _scopeDependencies[p] ?? <DartType>[]);
    var stmts = [
      _cacheNames,
      _definiteCacheNames,
      _generators,
      _definiteGenerators
    ].expand((c) => c.discharge(filter)).toList();
    formals?.forEach(_scopeDependencies.remove);
    return stmts;
  }

  /// Record the dependencies of the type on its free variables
  bool recordScopeDependencies(DartType type) {
    var freeVariables = freeTypeParameters(type);
    // TODO(leafp): This is a hack to avoid trying to hoist out of
    // generic functions and generic function types.  This often degrades
    // readability to little or no benefit.  It would be good to do this
    // when we know that we can hoist it to an outer scope, but for
    // now we just disable it.
    if (freeVariables.any((i) => i.enclosingElement is FunctionTypedElement)) {
      return true;
    }

    for (var free in freeVariables) {
      // If `free` is a promoted type parameter, get the original one so we can
      // find it in our map.
      var key = free is TypeParameterMember ? free.baseElement : free;
      _scopeDependencies.putIfAbsent(key, () => []).add(type);
    }
    return false;
  }

  /// Given a type [type], and a JS expression [typeRep] which implements it,
  /// add the type and its representation to the table, returning an
  /// expression which implements the type (but which caches the value).
  ///
  /// If [hoist] is true, then the JS representation will be hoisted up
  /// as far as possible and shared between instances of the type.  For
  /// example, the generated code for dart.is(x, type) ends up as:
  ///   let cacheVar;
  ///   ...
  ///   dart.is(x, (cacheVar || cacheVar = type))
  ///
  /// If [hoist] is false, the cache variable will be hoisted up as
  /// far as possible and shared between instances of the type, but the
  /// initializer expression will be emitted in place.  The generated code
  /// for dart.is(x, type) in this case ends up as:
  ///   let generator = () => (generator = dart.constFn(type))()
  ///   ....
  ///   dart.is(x, generator())
  ///
  /// The boolean parameter [definite] distinguishes between definite function
  /// types and other types (since the same DartType may have different
  /// representations as definite and indefinite function types).
  JS.Expression nameType(DartType type, JS.Expression typeRep,
      {bool hoistType, bool definite: false}) {
    assert(hoistType != null);
    var table = hoistType
        ? (definite ? _definiteGenerators : _generators)
        : (definite ? _definiteCacheNames : _cacheNames);
    if (!table.isNamed(type)) {
      if (recordScopeDependencies(type)) return typeRep;
    }
    return table.nameType(type, typeRep);
  }
}
