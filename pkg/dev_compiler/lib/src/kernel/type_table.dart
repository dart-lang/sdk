// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';

import '../compiler/js_names.dart' as js_ast;
import '../js_ast/js_ast.dart' as js_ast;
import '../js_ast/js_ast.dart' show js;
import 'kernel_helpers.dart';

Set<TypeParameter> freeTypeParameters(DartType t) {
  assert(isKnownDartTypeImplementor(t));
  var result = <TypeParameter>{};
  void find(DartType t) {
    if (t is TypeParameterType) {
      result.add(t.parameter);
    } else if (t is InterfaceType) {
      t.typeArguments.forEach(find);
    } else if (t is FutureOrType) {
      find(t.typeArgument);
    } else if (t is TypedefType) {
      t.typeArguments.forEach(find);
    } else if (t is FunctionType) {
      find(t.returnType);
      t.positionalParameters.forEach(find);
      t.namedParameters.forEach((n) => find(n.type));
      t.typeParameters.forEach((p) => find(p.bound));
      t.typeParameters.forEach(result.remove);
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
  final _names = <DartType, js_ast.TemporaryId>{};
  Iterable<DartType> get keys => _names.keys.toList();

  js_ast.Statement _dischargeType(DartType type) {
    var name = _names.remove(type);
    if (name != null) {
      return js.statement('let #;', [name]);
    }
    return null;
  }

  /// Emit a list of statements declaring the cache variables for
  /// types tracked by this table.  If [typeFilter] is given,
  /// only emit the types listed in the filter.
  List<js_ast.Statement> discharge([Iterable<DartType> typeFilter]) {
    var decls = <js_ast.Statement>[];
    var types = typeFilter ?? keys;
    for (var t in types) {
      var stmt = _dischargeType(t);
      if (stmt != null) decls.add(stmt);
    }
    return decls;
  }

  bool isNamed(DartType type) => _names.containsKey(type);

  /// A name for a type made of JS identifier safe characters.
  ///
  /// 'L' and 'N' are prepended to a type name to represent a legacy or nullable
  /// flavor of a type.
  String _typeString(DartType type, {bool flat = false}) {
    var nullability = type.declaredNullability == Nullability.legacy
        ? 'L'
        : type.declaredNullability == Nullability.nullable ? 'N' : '';
    assert(isKnownDartTypeImplementor(type));
    if (type is InterfaceType) {
      var name = '${type.classNode.name}$nullability';
      var typeArgs = type.typeArguments;
      if (typeArgs == null) return name;
      if (typeArgs.every((p) => p == const DynamicType())) return name;
      return "${name}Of${typeArgs.map(_typeString).join("\$")}";
    }
    if (type is FutureOrType) {
      var name = 'FutureOr$nullability';
      if (type.typeArgument == const DynamicType()) return name;
      return '${name}Of${_typeString(type.typeArgument)}';
    }
    if (type is TypedefType) {
      var name = '${type.typedefNode.name}$nullability';
      var typeArgs = type.typeArguments;
      if (typeArgs == null) return name;
      if (typeArgs.every((p) => p == const DynamicType())) return name;
      return "${name}Of${typeArgs.map(_typeString).join("\$")}";
    }
    if (type is FunctionType) {
      if (flat) return 'Fn';
      var rType = _typeString(type.returnType, flat: true);
      var params = type.positionalParameters
          .take(3)
          .map((p) => _typeString(p, flat: true));
      var paramList = params.join('And');
      var count = type.positionalParameters.length;
      if (count > 3 || type.namedParameters.isNotEmpty) {
        paramList = '${paramList}__';
      } else if (count == 0) {
        paramList = 'Void';
      }
      return '${paramList}To$nullability$rType';
    }
    if (type is TypeParameterType) return '${type.parameter.name}$nullability';
    if (type is DynamicType) return 'dynamic';
    if (type is VoidType) return 'void';
    if (type is NeverType) return 'Never$nullability';
    if (type is BottomType) return 'bottom';
    return 'invalid';
  }

  /// Heuristically choose a good name for the cache and generator
  /// variables.
  js_ast.TemporaryId chooseTypeName(DartType type) {
    return js_ast.TemporaryId(_typeString(type));
  }
}

/// _GeneratorTable tracks types which have been
/// named and hoisted.
class _GeneratorTable extends _CacheTable {
  final _defs = <DartType, js_ast.Expression>{};

  final js_ast.Identifier _runtimeModule;

  _GeneratorTable(this._runtimeModule);

  @override
  js_ast.Statement _dischargeType(DartType t) {
    var name = _names.remove(t);
    if (name != null) {
      var init = _defs.remove(t);
      assert(init != null);
      // TODO(vsm): Change back to `let`.
      // See https://github.com/dart-lang/sdk/issues/40380.
      return js.statement('var # = () => ((# = #.constFn(#))());',
          [name, name, _runtimeModule, init]);
    }
    return null;
  }

  /// If [type] does not already have a generator name chosen for it,
  /// assign it one, using [typeRep] as the initializer for it.
  /// Emit the generator name.
  js_ast.TemporaryId _nameType(DartType type, js_ast.Expression typeRep) {
    var temp = _names[type];
    if (temp == null) {
      _names[type] = temp = chooseTypeName(type);
      _defs[type] = typeRep;
    }
    return temp;
  }
}

class TypeTable {
  /// Generator variable names for hoisted types.
  final _GeneratorTable _generators;

  /// Mapping from type parameters to the types which must have their
  /// cache/generator variables discharged at the binding site for the
  /// type variable since the type definition depends on the type
  /// parameter.
  final _scopeDependencies = <TypeParameter, List<DartType>>{};

  TypeTable(js_ast.Identifier runtime) : _generators = _GeneratorTable(runtime);

  /// Emit a list of statements declaring the cache variables and generator
  /// definitions tracked by the table.  If [formals] is present, only
  /// emit the definitions which depend on the formals.
  List<js_ast.Statement> discharge([List<TypeParameter> formals]) {
    var filter = formals?.expand((p) => _scopeDependencies[p] ?? <DartType>[]);
    var stmts = _generators.discharge(filter);
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
    if (freeVariables.any((i) => i.parent is FunctionNode)) {
      return true;
    }

    for (var free in freeVariables) {
      // If `free` is a promoted type parameter, get the original one so we can
      // find it in our map.
      _scopeDependencies.putIfAbsent(free, () => []).add(type);
    }
    return false;
  }

  /// Given a type [type], and a JS expression [typeRep] which implements it,
  /// add the type and its representation to the table, returning an
  /// expression which implements the type (but which caches the value).
  js_ast.Expression nameType(DartType type, js_ast.Expression typeRep) {
    if (!_generators.isNamed(type) && recordScopeDependencies(type)) {
      return typeRep;
    }
    var name = _generators._nameType(type, typeRep);
    return js.call('#()', [name]);
  }

  /// Like [nameType] but for function types.
  ///
  /// The boolean parameter [lazy] indicates that the resulting expression
  /// should be a function that is invoked to compute the type, rather than the
  /// type itself. This allows better integration with `lazyFn`, avoiding an
  /// extra level of indirection.
  js_ast.Expression nameFunctionType(
      FunctionType type, js_ast.Expression typeRep,
      {bool lazy = false}) {
    if (!_generators.isNamed(type) && recordScopeDependencies(type)) {
      return lazy ? js_ast.ArrowFun([], typeRep) : typeRep;
    }
    var name = _generators._nameType(type, typeRep);
    return lazy ? name : js.call('#()', [name]);
  }
}
