// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Static implementation of smoke services that uses code-generated data and
/// verifies that the results match what we would get with a mirror-based
/// implementation.
library smoke.static_debug;

export 'package:smoke/static.dart' show StaticConfiguration, Getter, Setter;
import 'package:smoke/static.dart';
import 'package:smoke/mirrors.dart';
import 'package:smoke/smoke.dart';

import 'src/common.dart' show compareLists;

/// Set up the smoke package to use a static implementation based on the given
/// [configuration].
useGeneratedCode(StaticConfiguration configuration) {
  configure(new _DebugObjectAccessorService(configuration),
      new _DebugTypeInspectorService(configuration),
      new _DebugSymbolConverterService(configuration));
}

/// Implements [ObjectAccessorService] using a static configuration.
class _DebugObjectAccessorService implements ObjectAccessorService {
  GeneratedObjectAccessorService _static;
  ReflectiveObjectAccessorService _mirrors;

  _DebugObjectAccessorService(StaticConfiguration configuration)
      : _static = new GeneratedObjectAccessorService(configuration),
        _mirrors = new ReflectiveObjectAccessorService();

  read(Object object, Symbol name) =>
      _check('read', [object, name],
          _static.read(object, name),
          _mirrors.read(object, name));

  // Note: we can't verify operations with side-effects like write or invoke.
  void write(Object object, Symbol name, value) =>
    _static.write(object, name, value);

  invoke(object, Symbol name, List args, {Map namedArgs, bool adjust: false}) =>
    _static.invoke(object, name, args, namedArgs: namedArgs, adjust: adjust);
}

/// Implements [TypeInspectorService] using a static configuration.
class _DebugTypeInspectorService implements TypeInspectorService {
  GeneratedTypeInspectorService _static;
  ReflectiveTypeInspectorService _mirrors;

  _DebugTypeInspectorService(StaticConfiguration configuration)
      : _static = new GeneratedTypeInspectorService(configuration),
        _mirrors = new ReflectiveTypeInspectorService();

  bool isSubclassOf(Type type, Type supertype) =>
      _check('isSubclassOf', [type, supertype],
          _static.isSubclassOf(type, supertype),
          _mirrors.isSubclassOf(type, supertype));

  bool hasGetter(Type type, Symbol name) =>
      _check('hasGetter', [type, name],
          _static.hasGetter(type, name),
          _mirrors.hasGetter(type, name));

  bool hasSetter(Type type, Symbol name) =>
      _check('hasSetter', [type, name],
          _static.hasSetter(type, name),
          _mirrors.hasSetter(type, name));

  bool hasInstanceMethod(Type type, Symbol name) =>
      _check('hasInstanceMethod', [type, name],
          _static.hasInstanceMethod(type, name),
          _mirrors.hasInstanceMethod(type, name));

  bool hasStaticMethod(Type type, Symbol name) =>
      _check('hasStaticMethod', [type, name],
          _static.hasStaticMethod(type, name),
          _mirrors.hasStaticMethod(type, name));

  Declaration getDeclaration(Type type, Symbol name) =>
      _check('getDeclaration', [type, name],
          _static.getDeclaration(type, name),
          _mirrors.getDeclaration(type, name));

  List<Declaration> query(Type type, QueryOptions options) =>
      _check('query', [type, options],
          _static.query(type, options),
          _mirrors.query(type, options));
}

/// Implements [SymbolConverterService] using a static configuration.
class _DebugSymbolConverterService implements SymbolConverterService {
  GeneratedSymbolConverterService _static;
  ReflectiveSymbolConverterService _mirrors;

  _DebugSymbolConverterService(StaticConfiguration configuration)
      : _static = new GeneratedSymbolConverterService(configuration),
        _mirrors = new ReflectiveSymbolConverterService();

  String symbolToName(Symbol symbol) =>
      _check('symbolToName', [symbol],
          _static.symbolToName(symbol),
          _mirrors.symbolToName(symbol));

  Symbol nameToSymbol(String name) =>
      _check('nameToSymbol', [name],
          _static.nameToSymbol(name),
          _mirrors.nameToSymbol(name));
}

_check(String operation, List arguments, staticResult, mirrorResult) {
  if (staticResult == mirrorResult) return staticResult;
  if (staticResult is List && mirrorResult is List &&
      compareLists(staticResult, mirrorResult, unordered: true)) {
    return staticResult;
  }
  print('warning: inconsistent result on $operation(${arguments.join(', ')})\n'
      'smoke.mirrors result: $mirrorResult\n'
      'smoke.static result:  $staticResult\n');
  return staticResult;
}
