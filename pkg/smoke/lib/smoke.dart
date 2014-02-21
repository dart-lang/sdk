// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Collects services that can be used to access objects dynamically, inspect
/// type information, and convert between symbols and strings.
library smoke;

import 'src/implementation.dart' as implementation;

export 'src/common.dart' show minArgs, maxArgs, SUPPORTED_ARGS;

/// Configures this library to use [objectAccessor] for all read/write/invoke
/// APIs, [typeInspector] for all type query APIs, and [symbolConverter] for all
/// symbol convertion operations.
///
/// This function doesn't need to be called during development, but frameworks
/// should autogenerate a call to this function when running in deployment.
void configure(ObjectAccessorService objectAccessor,
    TypeInspectorService typeInspector,
    SymbolConverterService symbolConverter) {
  implementation.objectAccessor = objectAccessor;
  implementation.typeInspector = typeInspector;
  implementation.symbolConverter = symbolConverter;
}

/// Return the value of [field] in [object].
read(Object object, Symbol field) =>
    implementation.objectAccessor.read(object, field);

/// Update the [value] of [field] in [object].
void write(Object object, Symbol field, value) =>
    implementation.objectAccessor.write(object, field, value);

/// Invoke [method] in [receiver] with [args]. The [receiver] can be either an
/// object (to invoke instance methods) or a type (to invoke static methods).
/// This function optionally [adjust]s the list of arguments to match the number
/// of formal parameters by either adding nulls for missing arguments, or by
/// truncating the list.
invoke(receiver, Symbol method, List args,
    {Map namedArgs, bool adjust: false}) =>
    implementation.objectAccessor.invoke(
        receiver, method, args, namedArgs: namedArgs, adjust: adjust);

/// Tells whether [type] has a field or getter for [field].
bool hasGetter(Type type, Symbol field) =>
    implementation.typeInspector.hasGetter(type, field);

/// Tells whether [type] has a field or setter for [field].
bool hasSetter(Type type, Symbol field) =>
    implementation.typeInspector.hasSetter(type, field);

/// Tells whether [type] or a superclass (other than [Object]) defines
/// `noSuchMethod`.
bool hasNoSuchMethod(Type type) => hasInstanceMethod(type, #noSuchMethod);

/// Tells whether [type] has or a superclass contains a specific instance
/// [method] (excluding methods in [Object]).
bool hasInstanceMethod(Type type, Symbol method) =>
    implementation.typeInspector.hasInstanceMethod(type, method);

/// Tells whether [type] has a specific static [method].
bool hasStaticMethod(Type type, Symbol method) =>
    implementation.typeInspector.hasStaticMethod(type, method);

/// Get the declaration associated with field [name] found in [type] or a
/// superclass of [type].
Declaration getDeclaration(Type type, Symbol name) =>
    implementation.typeInspector.getDeclaration(type, name);

/// Retrieve all symbols of [type] that match [options].
List<Declaration> query(Type type, QueryOptions options) =>
    implementation.typeInspector.query(type, options);

/// Returns the name associated with a [symbol].
String symbolToName(Symbol symbol) =>
    implementation.symbolConverter.symbolToName(symbol);

/// Returns the symbol associated with a [name].
Symbol nameToSymbol(String name) =>
    implementation.symbolConverter.nameToSymbol(name);

/// Establishes the parameters for [query] to search for symbols in a type
/// hierarchy. For now only public instance symbols can be queried (no private,
/// no static).
class QueryOptions {
  /// Whether to include fields, getters, and setters.
  final bool includeProperties;

  /// Whether to include symbols from the given type and its superclasses
  /// (except [Object]).
  final bool includeInherited;

  /// Whether to include final fields.
  // TODO(sigmund): should this exclude getter-only properties too?
  final bool excludeFinal;

  /// Whether to include methods (default is false).
  final bool includeMethods;

  /// If [withAnnotation] is not null, then it should be a list of types, so
  /// only symbols that are annotated with instances of those types are
  /// included.
  final List withAnnotations;

  const QueryOptions({this.includeProperties: true, this.includeInherited: true,
      this.excludeFinal: false, this.includeMethods: false,
      this.withAnnotations: null});
}

/// Information associated with a symbol declaration (like a property or
/// method).
class Declaration {
  /// Name of the property or method
  final Symbol name;

  /// Whether the symbol is a property (either this or [isMethod] is true).
  bool get isProperty => !isMethod;

  /// Whether the symbol is a method (either this or [isProperty] is true)
  final bool isMethod;

  /// If this is a property, whether it's read only (final fields or properties
  /// with no setter).
  final bool isFinal;

  /// If this is a property, it's declared type (including dynamic if it's not
  /// declared). For methods, the returned type.
  final Type type;

  /// Whether this symbol is static.
  final bool isStatic;

  /// List of annotations in this declaration.
  final List annotations;

  const Declaration(this.name, this.type, {this.isMethod:false,
      this.isFinal: false, this.isStatic: false, this.annotations: const []});

  String toString() {
    return (new StringBuffer()
        ..write('[declaration ')
        ..write(name)
        ..write(isProperty ? ' (property) ' : ' (method) ')
        ..write(isFinal ? 'final ' : '')
        ..write(isStatic ? 'static ' : '')
        ..write(annotations)
        ..write(']')).toString();
  }
}


/// A service that provides a way to implement simple operations on objects like
/// read, write, and invoke.
abstract class ObjectAccessorService {
  /// Return the value of [field] in [object].
  read(Object object, Symbol field);

  /// Update the [value] of [field] in [object].
  void write(Object object, Symbol field, value);

  /// Invoke [method] in [object] with [args]. It optionally [adjust]s the list
  /// of arguments to match the number of formal parameters by either adding
  /// nulls for missing arguments, or by truncating the list.
  invoke(Object object, Symbol method, List args,
      {Map namedArgs, bool adjust: false});
}


/// A service that provides partial inspection into Dart types.
abstract class TypeInspectorService {
  /// Tells whether [type] has a field or getter for [name].
  bool hasGetter(Type type, Symbol name);

  /// Tells whether [type] has a field or setter for [name].
  bool hasSetter(Type type, Symbol name);

  /// Tells whether [type] has a specific instance [method].
  bool hasInstanceMethod(Type type, Symbol method);

  /// Tells whether [type] has a specific static [method].
  bool hasStaticMethod(Type type, Symbol method);

  /// Get the declaration associated with field [name] in [type].
  Declaration getDeclaration(Type type, Symbol name);

  /// Retrieve all symbols of [type] that match [options].
  List<Declaration> query(Type type, QueryOptions options);
}


/// A service that converts between [Symbol]s and [String]s. 
abstract class SymbolConverterService {
  /// Returns the name associated with a [symbol].
  String symbolToName(Symbol symbol);

  /// Returns the symbol associated with a [name].
  Symbol nameToSymbol(String name);
}
