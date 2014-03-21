// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Collects services that can be used to access objects dynamically, inspect
/// type information, and convert between symbols and strings.
library smoke;

import 'src/implementation.dart' as implementation;

export 'src/common.dart' show minArgs, maxArgs, SUPPORTED_ARGS;
import 'src/common.dart' show compareLists;

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

/// Tells whether [type] is transitively a subclass of [supertype].
bool isSubclassOf(Type type, Type supertype) =>
    implementation.typeInspector.isSubclassOf(type, supertype);

// TODO(sigmund): consider adding also:
// * isImplementationOf(type, subtype) to tells whether [type] declares that it
//   implements the [supertype] interface.
// * isSubtypeOf(type, subtype): Tells whether [type]'s interface is a sybtype
//   of [supertype]. That is, whether it is a subclass or if [type] implements
//   [supertype].

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
  /// Whether to include fields (default is true).
  final bool includeFields;

  /// Whether to include getters and setters (default is true). Note that to
  /// include fields you also need to enable [includeFields].
  final bool includeProperties;

  /// Whether to include symbols from the given type and its superclasses
  /// (except [Object]).
  final bool includeInherited;

  /// If [includeInherited], walk up the type hierarchy up to this type
  /// (defaults to [Object]).
  final Type includeUpTo;

  /// Whether to include final fields and getter-only properties.
  final bool excludeFinal;

  /// Whether to include methods (default is false).
  final bool includeMethods;

  /// If [withAnnotation] is not null, then it should be a list of types, so
  /// only symbols that are annotated with instances of those types are
  /// included.
  final List withAnnotations;

  /// If [matches] is not null, then include only those fields, properties, or
  /// methods that match the predicate.
  final NameMatcher matches;

  const QueryOptions({
      this.includeFields: true,
      this.includeProperties: true,
      this.includeInherited: true,
      this.includeUpTo: Object,
      this.excludeFinal: false,
      this.includeMethods: false,
      this.withAnnotations: null,
      this.matches: null});

  String toString() => (new StringBuffer()
      ..write('(options:')
      ..write(includeFields ? 'fields ' : '')
      ..write(includeProperties ? 'properties ' : '')
      ..write(includeMethods ? 'methods ' : '')
      ..write(includeInherited ? 'inherited ' : '_')
      ..write(excludeFinal ? 'no finals ' : '')
      ..write('annotations: $withAnnotations')
      ..write(matches != null ? 'with matcher' : '')
      ..write(')')).toString();
}

/// Used to filter query results based on a predicate on [name]. Returns true if
/// [name] should be included in the query results.
typedef bool NameMatcher(Symbol name);

/// Information associated with a symbol declaration (like a property or
/// method).
class Declaration {
  /// Name of the property or method
  final Symbol name;

  /// Kind of declaration (field, property, or method).
  final DeclarationKind kind;

  /// Whether the symbol is a field (and not a getter/setter property).
  bool get isField => kind == FIELD;

  /// Whether the symbol is a getter/setter and not a field.
  bool get isProperty => kind == PROPERTY;

  /// Whether the symbol is a method.
  bool get isMethod => kind == METHOD;

  /// For fields, whether they are final, for properties, whether they are
  /// read-only (they have no setter).
  final bool isFinal;

  /// If this is a field or property, it's declared type (including dynamic if
  /// it's not declared). For methods, the returned type.
  final Type type;

  /// Whether this symbol is static.
  final bool isStatic;

  /// List of annotations in this declaration.
  final List annotations;

  const Declaration(this.name, this.type, {this.kind: FIELD,
      this.isFinal: false, this.isStatic: false, this.annotations: const []});

  int get hashCode => name.hashCode;
  operator ==(other) => other is Declaration && name == other.name &&
      kind == other.kind && isFinal == other.isFinal &&
      type == other.type && isStatic == other.isStatic &&
      compareLists(annotations, other.annotations);

  String toString() {
    return (new StringBuffer()
        ..write('(declaration ')
        ..write(name)
        ..write(isProperty ? ' (property) ' : ' (method) ')
        ..write(isFinal ? 'final ' : '')
        ..write(isStatic ? 'static ' : '')
        ..write(annotations)
        ..write(')')).toString();
  }
}

/// Enumeration for declaration kinds (field, property, or method)
class DeclarationKind {
  final int kind;
  const DeclarationKind(this.kind);
}

/// Declaration kind used to denote a raw field.
const FIELD = const DeclarationKind(0);

/// Declaration kind used to denote a getter/setter.
const PROPERTY = const DeclarationKind(1);

/// Declaration kind used to denote a method.
const METHOD = const DeclarationKind(2);


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
  /// Tells whether [type] is transitively a subclass of [supertype].
  bool isSubclassOf(Type type, Type supertype);

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
