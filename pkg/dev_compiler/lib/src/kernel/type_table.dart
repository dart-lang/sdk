// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:collection';

import 'package:kernel/kernel.dart';

import '../compiler/js_names.dart' as js_ast;
import '../compiler/module_containers.dart' show ModuleItemContainer;
import '../js_ast/js_ast.dart' as js_ast;
import '../js_ast/js_ast.dart' show js;
import 'kernel_helpers.dart';

/// Returns all non-locally defined type parameters referred to by [t].
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

/// A name for a type made of JS identifier safe characters.
///
/// 'L' and 'N' are prepended to a type name to represent a legacy or nullable
/// flavor of a type.
String _typeString(DartType type, {bool flat = false}) {
  var nullability = type.declaredNullability == Nullability.legacy
      ? 'L'
      : type.declaredNullability == Nullability.nullable
          ? 'N'
          : '';
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
  if (type is NullType) return 'Null';
  return 'invalid';
}

class TypeTable {
  /// Mapping from type parameters to the types which must have their
  /// cache/generator variables discharged at the binding site for the
  /// type variable since the type definition depends on the type
  /// parameter.
  final _scopeDependencies = <TypeParameter, List<DartType>>{};

  /// Contains types with any free type parameters and maps them to a unique
  /// JS identifier.
  ///
  /// Used to reference types hoisted to the top of a generic class or generic
  /// function (as opposed to the top of the entire module).
  final _unboundTypeIds = HashMap<DartType, js_ast.Identifier>();

  /// Holds JS type generators keyed by their underlying DartType.
  final typeContainer = ModuleItemContainer<DartType>.asObject('T',
      keyToString: (DartType t) => escapeIdentifier(_typeString(t)));

  final js_ast.Identifier _runtimeModule;

  TypeTable(this._runtimeModule);

  /// Returns true if [type] is already recorded in the table.
  bool _isNamed(DartType type) =>
      typeContainer.contains(type) || _unboundTypeIds.containsKey(type);

  /// Emit the initializer statements for the type container, which contains
  /// all named types with fully bound type parameters.
  ///
  /// [incremental] is only used for expression evaluation.
  List<js_ast.Statement> dischargeBoundTypes({bool incremental = false}) {
    for (var t in typeContainer.keys) {
      typeContainer[t] = js.call('() => ((# = #.constFn(#))())',
          [typeContainer.access(t), _runtimeModule, typeContainer[t]]);
    }
    var boundTypes =
        incremental ? typeContainer.emitIncremental() : typeContainer.emit();
    // Bound types should only be emitted once (even across multiple evals).
    for (var t in typeContainer.keys) {
      typeContainer.setNoEmit(t);
    }
    return boundTypes;
  }

  js_ast.Statement _dischargeFreeType(DartType type) {
    typeContainer.setNoEmit(type);
    var init = typeContainer[type];
    var id = _unboundTypeIds[type];
    // TODO(vsm): Change back to `let`.
    // See https://github.com/dart-lang/sdk/issues/40380.
    return js.statement('var # = () => ((# = #.constFn(#))());',
        [id, id, _runtimeModule, init]);
  }

  /// Emit a list of statements declaring the cache variables and generator
  /// definitions tracked by the table so far.
  ///
  /// If [formals] is present, only emit the definitions which depend on the
  /// formals.
  List<js_ast.Statement> dischargeFreeTypes([Iterable<TypeParameter> formals]) {
    var decls = <js_ast.Statement>[];
    var types = formals == null
        ? typeContainer.keys.where((p) => freeTypeParameters(p).isNotEmpty)
        : formals.expand((p) => _scopeDependencies[p] ?? <DartType>[]).toSet();

    for (var t in types) {
      var stmt = _dischargeFreeType(t);
      if (stmt != null) decls.add(stmt);
    }
    return decls;
  }

  /// Emit a JS expression that evaluates to the generator for [type].
  ///
  /// If [type] does not already have a generator name chosen for it,
  /// assign it one, using [typeRep] as its initializer.
  js_ast.Expression _nameType(DartType type, js_ast.Expression typeRep) {
    if (!typeContainer.contains(type)) {
      typeContainer[type] = typeRep;
    }
    return _unboundTypeIds[type] ?? typeContainer.access(type);
  }

  /// Record the dependencies of the type on its free variables.
  ///
  /// Returns true if [type] is a free type parameter (but not a bound) and so
  /// is not locally hoisted.
  bool recordScopeDependencies(DartType type) {
    if (_isNamed(type)) {
      return false;
    }

    var freeVariables = freeTypeParameters(type);
    // TODO(leafp): This is a hack to avoid trying to hoist out of
    // generic functions and generic function types.  This often degrades
    // readability to little or no benefit.  It would be good to do this
    // when we know that we can hoist it to an outer scope, but for
    // now we just disable it.
    if (freeVariables.any((i) => i.parent is FunctionNode)) {
      return true;
    }

    // This is only reached when [type] is itself a bound that depends on a
    // free type parameter.
    // TODO(markzipan): Bounds are locally hoisted to their own JS identifiers,
    // but we don't do this this for other types that depend on free variables,
    // resulting in some duplicated runtime code. We may get some performance
    // wins if we just locally hoist everything.
    if (freeVariables.isNotEmpty) {
      _unboundTypeIds[type] =
          js_ast.TemporaryId(escapeIdentifier(_typeString(type)));
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
    if (recordScopeDependencies(type)) {
      return typeRep;
    }
    var name = _nameType(type, typeRep);
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
    if (recordScopeDependencies(type)) {
      return lazy ? js_ast.ArrowFun([], typeRep) : typeRep;
    }
    var name = _nameType(type, typeRep);
    return lazy ? name : js.call('#()', [name]);
  }
}
