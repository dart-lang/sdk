// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Static implementation of smoke services using code-generated data.
library smoke.static;

import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:smoke/smoke.dart';

import 'src/common.dart';

typedef T Getter<T>(object);
typedef void Setter<T>(object, value);

class StaticConfiguration {
  /// Maps symbol to a function that reads that symbol of an object. For
  /// instance, `#i: (o) => o.i`.
  final Map<Symbol, Getter> getters;

  /// Maps symbol to a function that updates that symbol of an object. For
  /// instance, `#i: (o, v) { o.i = v; }`.
  final Map<Symbol, Setter> setters;

  /// Maps a type to its super class. For example, String: Object.
  final Map<Type, Type> parents;

  /// For each type, a map of declarations per symbol (property or method).
  final Map<Type, Map<Symbol, Declaration>> declarations;

  /// Static methods for each type.
  // TODO(sigmund): should we add static getters & setters too?
  final Map<Type, Map<Symbol, Function>> staticMethods;

  /// A map from symbol to strings.
  final Map<Symbol, String> names;

  /// A map from strings to symbols (the reverse of [names]).
  final Map<String, Symbol> _symbols = {};


  /// Whether to check for missing declarations, otherwise, return default
  /// values (for example a missing parent class can be treated as Object)
  final bool checkedMode;

  StaticConfiguration({
      Map<Symbol, Getter> getters,
      Map<Symbol, Setter> setters,
      Map<Type, Type> parents,
      Map<Type, Map<Symbol, Declaration>> declarations,
      Map<Type, Map<Symbol, Function>> staticMethods,
      Map<Symbol, String> names,
      this.checkedMode: true})
      : getters = getters != null ? getters : {},
        setters = setters != null ? setters : {},
        parents = parents != null ? parents : {},
        declarations = declarations != null ? declarations : {},
        staticMethods = staticMethods != null ? staticMethods : {},
        names = names != null ? names : {} {
    this.names.forEach((k, v) { _symbols[v] = k; });
  }

  void addAll(StaticConfiguration other) {
    getters.addAll(other.getters);
    setters.addAll(other.setters);
    parents.addAll(other.parents);
    _nestedAddAll(declarations, other.declarations);
    _nestedAddAll(staticMethods, other.staticMethods);
    names.addAll(other.names);
    other.names.forEach((k, v) { _symbols[v] = k; });
  }

  static _nestedAddAll(Map a, Map b) {
    for (var key in b.keys) {
      a.putIfAbsent(key, () => {});
      a[key].addAll(b[key]);
    }
  }
}

/// Set up the smoke package to use a static implementation based on the given
/// [configuration].
useGeneratedCode(StaticConfiguration configuration) {
  configure(new GeneratedObjectAccessorService(configuration),
      new GeneratedTypeInspectorService(configuration),
      new GeneratedSymbolConverterService(configuration));
}

/// Implements [ObjectAccessorService] using a static configuration.
class GeneratedObjectAccessorService implements ObjectAccessorService {
  final StaticConfiguration _configuration;
  Map<Symbol, Getter> get _getters => _configuration.getters;
  Map<Symbol, Setter> get _setters => _configuration.setters;
  Map<Type, Map<Symbol, Function>> get _staticMethods =>
      _configuration.staticMethods;

  GeneratedObjectAccessorService(this._configuration);

  read(Object object, Symbol name) {
    var getter = _getters[name];
    if (getter == null) {
      throw new MissingCodeException('getter "$name" in $object');
    }
    return getter(object);
  }

  void write(Object object, Symbol name, value) {
    var setter = _setters[name];
    if (setter == null) {
      throw new MissingCodeException('setter "$name" in $object');
    }
    setter(object, value);
  }

  invoke(object, Symbol name, List args, {Map namedArgs, bool adjust: false}) {
    var method;
    if (object is Type && name != #toString) {
      var classMethods = _staticMethods[object];
      method = classMethods == null ? null : classMethods[name];
    } else {
      var getter = _getters[name];
      method = getter == null ? null : getter(object);
    }
    if (method == null) {
      throw new MissingCodeException('method "$name" in $object');
    }
    var tentativeError;
    if (adjust) {
      var min = minArgs(method);
      if (min > SUPPORTED_ARGS) {
        tentativeError = 'we tried to adjust the arguments for calling "$name"'
            ', but we couldn\'t determine the exact number of arguments it '
            'expects (it is more than $SUPPORTED_ARGS).';
        // The argument list might be correct, so we still invoke the function
        // and let the user see the error.
        args = adjustList(args, min, math.max(min, args.length));
      } else {
        var max = maxArgs(method);
        args = adjustList(args, min, max >= 0 ? max : args.length);
      }
    }
    if (namedArgs != null) {
      throw new UnsupportedError(
          'smoke.static doesn\'t support namedArguments in invoke');
    }
    try {
      return Function.apply(method, args);
    } on NoSuchMethodError catch (e) {
      // TODO(sigmund): consider whether this should just be in a logger or if
      // we should wrap `e` as a new exception (what's the best way to let users
      // know about this tentativeError?)
      if (tentativeError != null) print(tentativeError);
      rethrow;
    }
  }
}

/// Implements [TypeInspectorService] using a static configuration.
class GeneratedTypeInspectorService implements TypeInspectorService {
  final StaticConfiguration _configuration;

  Map<Type, Type> get _parents => _configuration.parents;
  Map<Type, Map<Symbol, Declaration>> get _declarations =>
      _configuration.declarations;
  bool get _checkedMode => _configuration.checkedMode;

  GeneratedTypeInspectorService(this._configuration);

  bool isSubclassOf(Type type, Type supertype) {
    if (type == supertype || supertype == Object) return true;
    while (type != Object) {
      var parentType = _parents[type];
      if (parentType == supertype) return true;
      if (parentType == null) {
        if (!_checkedMode) return false;
        throw new MissingCodeException('superclass of "$type" ($parentType)');
      }
      type = parentType;
    }
    return false;
  }

  bool hasGetter(Type type, Symbol name) {
    var decl = _findDeclaration(type, name);
    // No need to check decl.isProperty because methods are also automatically
    // considered getters (auto-closures).
    return decl != null && !decl.isStatic;
  }

  bool hasSetter(Type type, Symbol name) {
    var decl = _findDeclaration(type, name);
    return decl != null && !decl.isMethod && !decl.isFinal && !decl.isStatic;
  }

  bool hasInstanceMethod(Type type, Symbol name) {
    var decl = _findDeclaration(type, name);
    return decl != null && decl.isMethod && !decl.isStatic;
  }

  bool hasStaticMethod(Type type, Symbol name) {
    final map = _declarations[type];
    if (map == null) {
      if (!_checkedMode) return false;
      throw new MissingCodeException('declarations for $type');
    }
    final decl = map[name];
    return decl != null && decl.isMethod && decl.isStatic;
  }

  Declaration getDeclaration(Type type, Symbol name) {
    var decl = _findDeclaration(type, name);
    if (decl == null) {
      if (!_checkedMode) return null;
      throw new MissingCodeException('declaration for $type.$name');
    }
    return decl;
  }

  List<Declaration> query(Type type, QueryOptions options) {
    var result = [];
    if (options.includeInherited) {
      var superclass = _parents[type];
      if (superclass == null) {
        if (_checkedMode) {
          throw new MissingCodeException('superclass of "$type"');
        }
      } else if (superclass != options.includeUpTo) {
        result = query(superclass, options);
      }
    }
    var map = _declarations[type];
    if (map == null) {
      if (!_checkedMode) return result;
      throw new MissingCodeException('declarations for $type');
    }
    for (var decl in map.values) {
      if (!options.includeFields && decl.isField) continue;
      if (!options.includeProperties && decl.isProperty) continue;
      if (options.excludeFinal && decl.isFinal) continue;
      if (!options.includeMethods && decl.isMethod) continue;
      if (options.matches != null && !options.matches(decl.name)) continue;
      if (options.withAnnotations != null &&
          !matchesAnnotation(decl.annotations, options.withAnnotations)) {
        continue;
      }
      result.add(decl);
    }
    return result;
  }

  Declaration _findDeclaration(Type type, Symbol name) {
    while (type != Object) {
      final declarations = _declarations[type];
      if (declarations != null) {
        final declaration = declarations[name];
        if (declaration != null) return declaration;
      }
      var parentType = _parents[type];
      if (parentType == null) {
        if (!_checkedMode) return null;
        throw new MissingCodeException('superclass of "$type"');
      }
      type = parentType;
    }
    return null;
  }
}

/// Implements [SymbolConverterService] using a static configuration.
class GeneratedSymbolConverterService implements SymbolConverterService {
  final StaticConfiguration _configuration;
  Map<Symbol, String> get _names => _configuration.names;
  Map<String, Symbol> get _symbols => _configuration._symbols;

  GeneratedSymbolConverterService(this._configuration);

  String symbolToName(Symbol symbol) => _names[symbol];
  Symbol nameToSymbol(String name) => _symbols[name];
}


/// Exception thrown when trynig to access something that should be there, but
/// the code generator didn't include it.
class MissingCodeException implements Exception {
  final String description;
  MissingCodeException(this.description);

  String toString() => 'Missing $description. '
      'Code generation for the smoke package seems incomplete.';
}
