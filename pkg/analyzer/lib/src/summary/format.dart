// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script "pkg/analyzer/tool/generate_files".

library analyzer.src.summary.format;

import 'base.dart' as base;
import 'flat_buffers.dart' as fb;

/**
 * Enum used to indicate the kind of entity referred to by a
 * [LinkedReference].
 */
enum ReferenceKind {
  /**
   * The entity is a class or enum.
   */
  classOrEnum,

  /**
   * The entity is a typedef.
   */
  typedef,

  /**
   * The entity is a top level function.
   */
  topLevelFunction,

  /**
   * The entity is a top level getter or setter.
   */
  topLevelPropertyAccessor,

  /**
   * The entity is a prefix.
   */
  prefix,

  /**
   * The entity being referred to does not exist.
   */
  unresolved
}

class _ReferenceKindReader extends fb.Reader<ReferenceKind> {
  const _ReferenceKindReader() : super();

  @override
  int get size => 4;

  @override
  ReferenceKind read(fb.BufferPointer bp) {
    int index = const fb.Uint32Reader().read(bp);
    return ReferenceKind.values[index];
  }
}

/**
 * Enum representing the various kinds of operations which may be performed to
 * produce a constant value.  These options are assumed to execute in the
 * context of a stack which is initially empty.
 */
enum UnlinkedConstOperation {
  /**
   * Push the value of the n-th constructor argument (where n is obtained from
   * [UnlinkedConst.ints]) onto the stack.
   */
  pushArgument,

  /**
   * Push the next value from [UnlinkedConst.ints] (a 32-bit unsigned integer)
   * onto the stack.
   *
   * Note that Dart supports integers larger than 32 bits; these are
   * represented by composing 32 bit values using the [shiftOr] operation.
   */
  pushInt,

  /**
   * Pop the top value off the stack, which should be an integer.  Multiply it
   * by 2^32, "or" in the next value from [UnlinkedConst.ints] (which is
   * interpreted as a 32-bit unsigned integer), and push the result back onto
   * the stack.
   */
  shiftOr,

  /**
   * Push the next value from [UnlinkedConst.doubles] (a double precision
   * floating point value) onto the stack.
   */
  pushDouble,

  /**
   * Push the constant `true` onto the stack.
   */
  pushTrue,

  /**
   * Push the constant `false` onto the stack.
   */
  pushFalse,

  /**
   * Push the next value from [UnlinkedConst.strings] onto the stack.
   */
  pushString,

  /**
   * Pop the top n values from the stack (where n is obtained from
   * [UnlinkedConst.ints]), convert them to strings (if they aren't already),
   * concatenate them into a single string, and push it back onto the stack.
   *
   * This operation is used to represent constants whose value is a literal
   * string containing string interpolations.
   */
  concatenate,

  /**
   * Pop the top value from the stack which should be string, convert it to
   * a symbol, and push it back onto the stack.
   */
  makeSymbol,

  /**
   * Push the constant `null` onto the stack.
   */
  pushNull,

  /**
   * Evaluate a (potentially qualified) identifier expression and push the
   * resulting value onto the stack.  The identifier to be evaluated is
   * obtained from [UnlinkedConst.references].
   *
   * This operation is used to represent the following kinds of constants
   * (which are indistinguishable from an unresolved AST alone):
   *
   * - A qualified reference to a static constant variable (e.g. `C.v`, where
   *   C is a class and `v` is a constant static variable in `C`).
   * - An identifier expression referring to a constant variable.
   * - A simple or qualified identifier denoting a class or type alias.
   * - A simple or qualified identifier denoting a top-level function or a
   *   static method.
   */
  pushReference,

  /**
   * Pop the top `n` values from the stack (where `n` is obtained from
   * [UnlinkedConst.ints]) into a list (filled from the end) and take the next
   * `n` values from [UnlinkedConst.strings] and use the lists of names and
   * values to create named arguments.  Then pop the top `m` values from the
   * stack (where `m` is obtained from [UnlinkedConst.ints]) into a list (filled
   * from the end) and use them as positional arguments.  Use the lists of
   * positional and names arguments to invoke a constant constructor whose name
   * is obtained from [UnlinkedConst.strings], and whose class is obtained from
   * [UnlinkedConst.references], and push the resulting value back onto the
   * stack.
   *
   * Note that for an invocation of the form `const a.b(...)` (where no type
   * arguments are specified), it is impossible to tell from the unresolved AST
   * alone whether `a` is a class name and `b` is a constructor name, or `a` is
   * a prefix name and `b` is a class name.  In this case it is presumed that
   * `a` is a prefix name and `b` is a class name.
   *
   * TODO(paulberry): figure out how to resolve this ambiguity in the
   * "prelinked" part of the summary.
   */
  invokeConstructor,

  /**
   * Pop the top n values from the stack (where n is obtained from
   * [UnlinkedConst.ints]), place them in a [List], and push the result back
   * onto the stack.  The type parameter for the [List] is obtained from
   * [UnlinkedConst.references].
   */
  makeList,

  /**
   * Pop the top 2*n values from the stack (where n is obtained from
   * [UnlinkedConst.ints]), interpret them as key/value pairs, place them in a
   * [Map], and push the result back onto the stack.  The two type parameters for
   * the [Map] are obtained from [UnlinkedConst.references].
   */
  makeMap,

  /**
   * Pop the top 2 values from the stack, pass them to the predefined Dart
   * function `identical`, and push the result back onto the stack.
   */
  identical,

  /**
   * Pop the top 2 values from the stack, evaluate `v1 == v2`, and push the
   * result back onto the stack.
   *
   * This is also used to represent `v1 != v2`, by composition with [not].
   */
  equal,

  /**
   * Pop the top value from the stack, compute its boolean negation, and push
   * the result back onto the stack.
   */
  not,

  /**
   * Pop the top 2 values from the stack, compute `v1 && v2`, and push the
   * result back onto the stack.
   */
  and,

  /**
   * Pop the top 2 values from the stack, compute `v1 || v2`, and push the
   * result back onto the stack.
   */
  or,

  /**
   * Pop the top value from the stack, compute its integer complement, and push
   * the result back onto the stack.
   */
  complement,

  /**
   * Pop the top 2 values from the stack, compute `v1 ^ v2`, and push the
   * result back onto the stack.
   */
  bitXor,

  /**
   * Pop the top 2 values from the stack, compute `v1 & v2`, and push the
   * result back onto the stack.
   */
  bitAnd,

  /**
   * Pop the top 2 values from the stack, compute `v1 | v2`, and push the
   * result back onto the stack.
   */
  bitOr,

  /**
   * Pop the top 2 values from the stack, compute `v1 >> v2`, and push the
   * result back onto the stack.
   */
  bitShiftRight,

  /**
   * Pop the top 2 values from the stack, compute `v1 << v2`, and push the
   * result back onto the stack.
   */
  bitShiftLeft,

  /**
   * Pop the top 2 values from the stack, compute `v1 + v2`, and push the
   * result back onto the stack.
   */
  add,

  /**
   * Pop the top value from the stack, compute its integer negation, and push
   * the result back onto the stack.
   */
  negate,

  /**
   * Pop the top 2 values from the stack, compute `v1 - v2`, and push the
   * result back onto the stack.
   */
  subtract,

  /**
   * Pop the top 2 values from the stack, compute `v1 * v2`, and push the
   * result back onto the stack.
   */
  multiply,

  /**
   * Pop the top 2 values from the stack, compute `v1 / v2`, and push the
   * result back onto the stack.
   */
  divide,

  /**
   * Pop the top 2 values from the stack, compute `v1 ~/ v2`, and push the
   * result back onto the stack.
   */
  floorDivide,

  /**
   * Pop the top 2 values from the stack, compute `v1 > v2`, and push the
   * result back onto the stack.
   */
  greater,

  /**
   * Pop the top 2 values from the stack, compute `v1 < v2`, and push the
   * result back onto the stack.
   */
  less,

  /**
   * Pop the top 2 values from the stack, compute `v1 >= v2`, and push the
   * result back onto the stack.
   */
  greaterEqual,

  /**
   * Pop the top 2 values from the stack, compute `v1 <= v2`, and push the
   * result back onto the stack.
   */
  lessEqual,

  /**
   * Pop the top 2 values from the stack, compute `v1 % v2`, and push the
   * result back onto the stack.
   */
  modulo,

  /**
   * Pop the top 3 values from the stack, compute `v1 ? v2 : v3`, and push the
   * result back onto the stack.
   */
  conditional,

  /**
   * Pop the top value from the stack, evaluate `v.length`, and push the result
   * back onto the stack.
   */
  length
}

class _UnlinkedConstOperationReader extends fb.Reader<UnlinkedConstOperation> {
  const _UnlinkedConstOperationReader() : super();

  @override
  int get size => 4;

  @override
  UnlinkedConstOperation read(fb.BufferPointer bp) {
    int index = const fb.Uint32Reader().read(bp);
    return UnlinkedConstOperation.values[index];
  }
}

/**
 * Enum used to indicate the kind of an executable.
 */
enum UnlinkedExecutableKind {
  /**
   * Executable is a function or method.
   */
  functionOrMethod,

  /**
   * Executable is a getter.
   */
  getter,

  /**
   * Executable is a setter.
   */
  setter,

  /**
   * Executable is a constructor.
   */
  constructor
}

class _UnlinkedExecutableKindReader extends fb.Reader<UnlinkedExecutableKind> {
  const _UnlinkedExecutableKindReader() : super();

  @override
  int get size => 4;

  @override
  UnlinkedExecutableKind read(fb.BufferPointer bp) {
    int index = const fb.Uint32Reader().read(bp);
    return UnlinkedExecutableKind.values[index];
  }
}

/**
 * Enum used to indicate the kind of a parameter.
 */
enum UnlinkedParamKind {
  /**
   * Parameter is required.
   */
  required,

  /**
   * Parameter is positional optional (enclosed in `[]`)
   */
  positional,

  /**
   * Parameter is named optional (enclosed in `{}`)
   */
  named
}

class _UnlinkedParamKindReader extends fb.Reader<UnlinkedParamKind> {
  const _UnlinkedParamKindReader() : super();

  @override
  int get size => 4;

  @override
  UnlinkedParamKind read(fb.BufferPointer bp) {
    int index = const fb.Uint32Reader().read(bp);
    return UnlinkedParamKind.values[index];
  }
}

class LinkedDependencyBuilder extends Object with _LinkedDependencyMixin implements LinkedDependency {
  bool _finished = false;

  String _uri;
  List<String> _parts;

  @override
  String get uri => _uri ??= '';

  /**
   * The relative URI of the dependent library.  This URI is relative to the
   * importing library, even if there are intervening `export` declarations.
   * So, for example, if `a.dart` imports `b/c.dart` and `b/c.dart` exports
   * `d/e.dart`, the URI listed for `a.dart`'s dependency on `e.dart` will be
   * `b/d/e.dart`.
   */
  void set uri(String _value) {
    assert(!_finished);
    _uri = _value;
  }

  @override
  List<String> get parts => _parts ??= <String>[];

  /**
   * URI for the compilation units listed in the library's `part` declarations.
   * These URIs are relative to the importing library.
   */
  void set parts(List<String> _value) {
    assert(!_finished);
    _parts = _value;
  }

  LinkedDependencyBuilder({String uri, List<String> parts})
    : _uri = uri,
      _parts = parts;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_uri;
    fb.Offset offset_parts;
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    if (!(_parts == null || _parts.isEmpty)) {
      offset_parts = fbBuilder.writeList(_parts.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_uri != null) {
      fbBuilder.addOffset(0, offset_uri);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(1, offset_parts);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Information about a dependency that exists between one library and another
 * due to an "import" declaration.
 */
abstract class LinkedDependency extends base.SummaryClass {

  /**
   * The relative URI of the dependent library.  This URI is relative to the
   * importing library, even if there are intervening `export` declarations.
   * So, for example, if `a.dart` imports `b/c.dart` and `b/c.dart` exports
   * `d/e.dart`, the URI listed for `a.dart`'s dependency on `e.dart` will be
   * `b/d/e.dart`.
   */
  String get uri;

  /**
   * URI for the compilation units listed in the library's `part` declarations.
   * These URIs are relative to the importing library.
   */
  List<String> get parts;
}

class _LinkedDependencyReader extends fb.TableReader<_LinkedDependencyImpl> {
  const _LinkedDependencyReader();

  @override
  _LinkedDependencyImpl createObject(fb.BufferPointer bp) => new _LinkedDependencyImpl(bp);
}

class _LinkedDependencyImpl extends Object with _LinkedDependencyMixin implements LinkedDependency {
  final fb.BufferPointer _bp;

  _LinkedDependencyImpl(this._bp);

  String _uri;
  List<String> _parts;

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _uri;
  }

  @override
  List<String> get parts {
    _parts ??= const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 1, const <String>[]);
    return _parts;
  }
}

abstract class _LinkedDependencyMixin implements LinkedDependency {
  @override
  Map<String, Object> toMap() => {
    "uri": uri,
    "parts": parts,
  };
}

class LinkedExportNameBuilder extends Object with _LinkedExportNameMixin implements LinkedExportName {
  bool _finished = false;

  String _name;
  int _dependency;
  int _unit;
  ReferenceKind _kind;

  @override
  String get name => _name ??= '';

  /**
   * Name of the exported entity.  TODO(paulberry): do we include the trailing
   * '=' for a setter?
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get dependency => _dependency ??= 0;

  /**
   * Index into [LinkedLibrary.dependencies] for the library in which the
   * entity is defined.
   */
  void set dependency(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _dependency = _value;
  }

  @override
  int get unit => _unit ??= 0;

  /**
   * Integer index indicating which unit in the exported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  void set unit(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _unit = _value;
  }

  @override
  ReferenceKind get kind => _kind ??= ReferenceKind.classOrEnum;

  /**
   * The kind of the entity being referred to.
   */
  void set kind(ReferenceKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  LinkedExportNameBuilder({String name, int dependency, int unit, ReferenceKind kind})
    : _name = name,
      _dependency = dependency,
      _unit = unit,
      _kind = kind;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_dependency != null && _dependency != 0) {
      fbBuilder.addUint32(1, _dependency);
    }
    if (_unit != null && _unit != 0) {
      fbBuilder.addUint32(2, _unit);
    }
    if (_kind != null && _kind != ReferenceKind.classOrEnum) {
      fbBuilder.addUint32(3, _kind.index);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Information about a single name in the export namespace of the library that
 * is not in the public namespace.
 */
abstract class LinkedExportName extends base.SummaryClass {

  /**
   * Name of the exported entity.  TODO(paulberry): do we include the trailing
   * '=' for a setter?
   */
  String get name;

  /**
   * Index into [LinkedLibrary.dependencies] for the library in which the
   * entity is defined.
   */
  int get dependency;

  /**
   * Integer index indicating which unit in the exported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  int get unit;

  /**
   * The kind of the entity being referred to.
   */
  ReferenceKind get kind;
}

class _LinkedExportNameReader extends fb.TableReader<_LinkedExportNameImpl> {
  const _LinkedExportNameReader();

  @override
  _LinkedExportNameImpl createObject(fb.BufferPointer bp) => new _LinkedExportNameImpl(bp);
}

class _LinkedExportNameImpl extends Object with _LinkedExportNameMixin implements LinkedExportName {
  final fb.BufferPointer _bp;

  _LinkedExportNameImpl(this._bp);

  String _name;
  int _dependency;
  int _unit;
  ReferenceKind _kind;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get dependency {
    _dependency ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _dependency;
  }

  @override
  int get unit {
    _unit ??= const fb.Uint32Reader().vTableGet(_bp, 2, 0);
    return _unit;
  }

  @override
  ReferenceKind get kind {
    _kind ??= const _ReferenceKindReader().vTableGet(_bp, 3, ReferenceKind.classOrEnum);
    return _kind;
  }
}

abstract class _LinkedExportNameMixin implements LinkedExportName {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "dependency": dependency,
    "unit": unit,
    "kind": kind,
  };
}

class LinkedLibraryBuilder extends Object with _LinkedLibraryMixin implements LinkedLibrary {
  bool _finished = false;

  List<LinkedUnitBuilder> _units;
  List<LinkedDependencyBuilder> _dependencies;
  List<int> _importDependencies;
  List<LinkedExportNameBuilder> _exportNames;
  int _numPrelinkedDependencies;

  @override
  List<LinkedUnitBuilder> get units => _units ??= <LinkedUnitBuilder>[];

  /**
   * The linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  void set units(List<LinkedUnitBuilder> _value) {
    assert(!_finished);
    _units = _value;
  }

  @override
  List<LinkedDependencyBuilder> get dependencies => _dependencies ??= <LinkedDependencyBuilder>[];

  /**
   * The libraries that this library depends on (either via an explicit import
   * statement or via the implicit dependencies on `dart:core` and
   * `dart:async`).  The first element of this array is a pseudo-dependency
   * representing the library itself (it is also used for "dynamic").  This is
   * followed by elements representing "prelinked" dependencies (direct imports
   * and the transitive closure of exports).  After the prelinked dependencies
   * are elements represent "linked" dependencies.
   *
   * A library is only included as a "linked" dependency if it is a true
   * dependency (e.g. a propagated or inferred type or constant value
   * implicitly refers to an element declared in the library) or
   * anti-dependency (e.g. the result of type propagation or type inference
   * depends on the lack of a certain declaration in the library).
   */
  void set dependencies(List<LinkedDependencyBuilder> _value) {
    assert(!_finished);
    _dependencies = _value;
  }

  @override
  List<int> get importDependencies => _importDependencies ??= <int>[];

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   */
  void set importDependencies(List<int> _value) {
    assert(!_finished);
    assert(_value == null || _value.every((e) => e >= 0));
    _importDependencies = _value;
  }

  @override
  List<LinkedExportNameBuilder> get exportNames => _exportNames ??= <LinkedExportNameBuilder>[];

  /**
   * Information about entities in the export namespace of the library that are
   * not in the public namespace of the library (that is, entities that are
   * brought into the namespace via `export` directives).
   *
   * Sorted by name.
   */
  void set exportNames(List<LinkedExportNameBuilder> _value) {
    assert(!_finished);
    _exportNames = _value;
  }

  @override
  int get numPrelinkedDependencies => _numPrelinkedDependencies ??= 0;

  /**
   * The number of elements in [dependencies] which are not "linked"
   * dependencies (that is, the number of libraries in the direct imports plus
   * the transitive closure of exports, plus the library itself).
   */
  void set numPrelinkedDependencies(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _numPrelinkedDependencies = _value;
  }

  LinkedLibraryBuilder({List<LinkedUnitBuilder> units, List<LinkedDependencyBuilder> dependencies, List<int> importDependencies, List<LinkedExportNameBuilder> exportNames, int numPrelinkedDependencies})
    : _units = units,
      _dependencies = dependencies,
      _importDependencies = importDependencies,
      _exportNames = exportNames,
      _numPrelinkedDependencies = numPrelinkedDependencies;

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder));
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_units;
    fb.Offset offset_dependencies;
    fb.Offset offset_importDependencies;
    fb.Offset offset_exportNames;
    if (!(_units == null || _units.isEmpty)) {
      offset_units = fbBuilder.writeList(_units.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_dependencies == null || _dependencies.isEmpty)) {
      offset_dependencies = fbBuilder.writeList(_dependencies.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_importDependencies == null || _importDependencies.isEmpty)) {
      offset_importDependencies = fbBuilder.writeListUint32(_importDependencies);
    }
    if (!(_exportNames == null || _exportNames.isEmpty)) {
      offset_exportNames = fbBuilder.writeList(_exportNames.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_units != null) {
      fbBuilder.addOffset(0, offset_units);
    }
    if (offset_dependencies != null) {
      fbBuilder.addOffset(1, offset_dependencies);
    }
    if (offset_importDependencies != null) {
      fbBuilder.addOffset(2, offset_importDependencies);
    }
    if (offset_exportNames != null) {
      fbBuilder.addOffset(3, offset_exportNames);
    }
    if (_numPrelinkedDependencies != null && _numPrelinkedDependencies != 0) {
      fbBuilder.addUint32(4, _numPrelinkedDependencies);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Linked summary of a library.
 */
abstract class LinkedLibrary extends base.SummaryClass {
  factory LinkedLibrary.fromBuffer(List<int> buffer) {
    fb.BufferPointer rootRef = new fb.BufferPointer.fromBytes(buffer);
    return const _LinkedLibraryReader().read(rootRef);
  }

  /**
   * The linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  List<LinkedUnit> get units;

  /**
   * The libraries that this library depends on (either via an explicit import
   * statement or via the implicit dependencies on `dart:core` and
   * `dart:async`).  The first element of this array is a pseudo-dependency
   * representing the library itself (it is also used for "dynamic").  This is
   * followed by elements representing "prelinked" dependencies (direct imports
   * and the transitive closure of exports).  After the prelinked dependencies
   * are elements represent "linked" dependencies.
   *
   * A library is only included as a "linked" dependency if it is a true
   * dependency (e.g. a propagated or inferred type or constant value
   * implicitly refers to an element declared in the library) or
   * anti-dependency (e.g. the result of type propagation or type inference
   * depends on the lack of a certain declaration in the library).
   */
  List<LinkedDependency> get dependencies;

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   */
  List<int> get importDependencies;

  /**
   * Information about entities in the export namespace of the library that are
   * not in the public namespace of the library (that is, entities that are
   * brought into the namespace via `export` directives).
   *
   * Sorted by name.
   */
  List<LinkedExportName> get exportNames;

  /**
   * The number of elements in [dependencies] which are not "linked"
   * dependencies (that is, the number of libraries in the direct imports plus
   * the transitive closure of exports, plus the library itself).
   */
  int get numPrelinkedDependencies;
}

class _LinkedLibraryReader extends fb.TableReader<_LinkedLibraryImpl> {
  const _LinkedLibraryReader();

  @override
  _LinkedLibraryImpl createObject(fb.BufferPointer bp) => new _LinkedLibraryImpl(bp);
}

class _LinkedLibraryImpl extends Object with _LinkedLibraryMixin implements LinkedLibrary {
  final fb.BufferPointer _bp;

  _LinkedLibraryImpl(this._bp);

  List<LinkedUnit> _units;
  List<LinkedDependency> _dependencies;
  List<int> _importDependencies;
  List<LinkedExportName> _exportNames;
  int _numPrelinkedDependencies;

  @override
  List<LinkedUnit> get units {
    _units ??= const fb.ListReader<LinkedUnit>(const _LinkedUnitReader()).vTableGet(_bp, 0, const <LinkedUnit>[]);
    return _units;
  }

  @override
  List<LinkedDependency> get dependencies {
    _dependencies ??= const fb.ListReader<LinkedDependency>(const _LinkedDependencyReader()).vTableGet(_bp, 1, const <LinkedDependency>[]);
    return _dependencies;
  }

  @override
  List<int> get importDependencies {
    _importDependencies ??= const fb.ListReader<int>(const fb.Uint32Reader()).vTableGet(_bp, 2, const <int>[]);
    return _importDependencies;
  }

  @override
  List<LinkedExportName> get exportNames {
    _exportNames ??= const fb.ListReader<LinkedExportName>(const _LinkedExportNameReader()).vTableGet(_bp, 3, const <LinkedExportName>[]);
    return _exportNames;
  }

  @override
  int get numPrelinkedDependencies {
    _numPrelinkedDependencies ??= const fb.Uint32Reader().vTableGet(_bp, 4, 0);
    return _numPrelinkedDependencies;
  }
}

abstract class _LinkedLibraryMixin implements LinkedLibrary {
  @override
  Map<String, Object> toMap() => {
    "units": units,
    "dependencies": dependencies,
    "importDependencies": importDependencies,
    "exportNames": exportNames,
    "numPrelinkedDependencies": numPrelinkedDependencies,
  };
}

class LinkedReferenceBuilder extends Object with _LinkedReferenceMixin implements LinkedReference {
  bool _finished = false;

  int _dependency;
  ReferenceKind _kind;
  int _unit;
  int _numTypeParameters;
  String _name;

  @override
  int get dependency => _dependency ??= 0;

  /**
   * Index into [LinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  void set dependency(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _dependency = _value;
  }

  @override
  ReferenceKind get kind => _kind ??= ReferenceKind.classOrEnum;

  /**
   * The kind of the entity being referred to.  For the pseudo-type `dynamic`,
   * the kind is [ReferenceKind.classOrEnum].
   */
  void set kind(ReferenceKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  @override
  int get unit => _unit ??= 0;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  void set unit(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _unit = _value;
  }

  @override
  int get numTypeParameters => _numTypeParameters ??= 0;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  void set numTypeParameters(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _numTypeParameters = _value;
  }

  @override
  String get name => _name ??= '';

  /**
   * If this [LinkedReference] doesn't have an associated [UnlinkedReference],
   * name of the entity being referred to.  The empty string refers to the
   * pseudo-type `dynamic`.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  LinkedReferenceBuilder({int dependency, ReferenceKind kind, int unit, int numTypeParameters, String name})
    : _dependency = dependency,
      _kind = kind,
      _unit = unit,
      _numTypeParameters = numTypeParameters,
      _name = name;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (_dependency != null && _dependency != 0) {
      fbBuilder.addUint32(0, _dependency);
    }
    if (_kind != null && _kind != ReferenceKind.classOrEnum) {
      fbBuilder.addUint32(1, _kind.index);
    }
    if (_unit != null && _unit != 0) {
      fbBuilder.addUint32(2, _unit);
    }
    if (_numTypeParameters != null && _numTypeParameters != 0) {
      fbBuilder.addUint32(3, _numTypeParameters);
    }
    if (offset_name != null) {
      fbBuilder.addOffset(4, offset_name);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Information about the resolution of an [UnlinkedReference].
 */
abstract class LinkedReference extends base.SummaryClass {

  /**
   * Index into [LinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  int get dependency;

  /**
   * The kind of the entity being referred to.  For the pseudo-type `dynamic`,
   * the kind is [ReferenceKind.classOrEnum].
   */
  ReferenceKind get kind;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [LinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  int get unit;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int get numTypeParameters;

  /**
   * If this [LinkedReference] doesn't have an associated [UnlinkedReference],
   * name of the entity being referred to.  The empty string refers to the
   * pseudo-type `dynamic`.
   */
  String get name;
}

class _LinkedReferenceReader extends fb.TableReader<_LinkedReferenceImpl> {
  const _LinkedReferenceReader();

  @override
  _LinkedReferenceImpl createObject(fb.BufferPointer bp) => new _LinkedReferenceImpl(bp);
}

class _LinkedReferenceImpl extends Object with _LinkedReferenceMixin implements LinkedReference {
  final fb.BufferPointer _bp;

  _LinkedReferenceImpl(this._bp);

  int _dependency;
  ReferenceKind _kind;
  int _unit;
  int _numTypeParameters;
  String _name;

  @override
  int get dependency {
    _dependency ??= const fb.Uint32Reader().vTableGet(_bp, 0, 0);
    return _dependency;
  }

  @override
  ReferenceKind get kind {
    _kind ??= const _ReferenceKindReader().vTableGet(_bp, 1, ReferenceKind.classOrEnum);
    return _kind;
  }

  @override
  int get unit {
    _unit ??= const fb.Uint32Reader().vTableGet(_bp, 2, 0);
    return _unit;
  }

  @override
  int get numTypeParameters {
    _numTypeParameters ??= const fb.Uint32Reader().vTableGet(_bp, 3, 0);
    return _numTypeParameters;
  }

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 4, '');
    return _name;
  }
}

abstract class _LinkedReferenceMixin implements LinkedReference {
  @override
  Map<String, Object> toMap() => {
    "dependency": dependency,
    "kind": kind,
    "unit": unit,
    "numTypeParameters": numTypeParameters,
    "name": name,
  };
}

class LinkedUnitBuilder extends Object with _LinkedUnitMixin implements LinkedUnit {
  bool _finished = false;

  List<LinkedReferenceBuilder> _references;
  List<TypeRefBuilder> _types;

  @override
  List<LinkedReferenceBuilder> get references => _references ??= <LinkedReferenceBuilder>[];

  /**
   * Information about the resolution of references within the compilation
   * unit.  Each element of [UnlinkedUnit.references] has a corresponding
   * element in this list (at the same index).  If this list has additional
   * elements beyond the number of elements in [UnlinkedUnit.references], those
   * additional elements are references that are only referred to implicitly
   * (e.g. elements involved in inferred or propagated types).
   */
  void set references(List<LinkedReferenceBuilder> _value) {
    assert(!_finished);
    _references = _value;
  }

  @override
  List<TypeRefBuilder> get types => _types ??= <TypeRefBuilder>[];

  /**
   * List associating slot ids found inside the unlinked summary for the
   * compilation unit with propagated and inferred types.
   */
  void set types(List<TypeRefBuilder> _value) {
    assert(!_finished);
    _types = _value;
  }

  LinkedUnitBuilder({List<LinkedReferenceBuilder> references, List<TypeRefBuilder> types})
    : _references = references,
      _types = types;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_references;
    fb.Offset offset_types;
    if (!(_references == null || _references.isEmpty)) {
      offset_references = fbBuilder.writeList(_references.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_types == null || _types.isEmpty)) {
      offset_types = fbBuilder.writeList(_types.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_references != null) {
      fbBuilder.addOffset(0, offset_references);
    }
    if (offset_types != null) {
      fbBuilder.addOffset(1, offset_types);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Linked summary of a compilation unit.
 */
abstract class LinkedUnit extends base.SummaryClass {

  /**
   * Information about the resolution of references within the compilation
   * unit.  Each element of [UnlinkedUnit.references] has a corresponding
   * element in this list (at the same index).  If this list has additional
   * elements beyond the number of elements in [UnlinkedUnit.references], those
   * additional elements are references that are only referred to implicitly
   * (e.g. elements involved in inferred or propagated types).
   */
  List<LinkedReference> get references;

  /**
   * List associating slot ids found inside the unlinked summary for the
   * compilation unit with propagated and inferred types.
   */
  List<TypeRef> get types;
}

class _LinkedUnitReader extends fb.TableReader<_LinkedUnitImpl> {
  const _LinkedUnitReader();

  @override
  _LinkedUnitImpl createObject(fb.BufferPointer bp) => new _LinkedUnitImpl(bp);
}

class _LinkedUnitImpl extends Object with _LinkedUnitMixin implements LinkedUnit {
  final fb.BufferPointer _bp;

  _LinkedUnitImpl(this._bp);

  List<LinkedReference> _references;
  List<TypeRef> _types;

  @override
  List<LinkedReference> get references {
    _references ??= const fb.ListReader<LinkedReference>(const _LinkedReferenceReader()).vTableGet(_bp, 0, const <LinkedReference>[]);
    return _references;
  }

  @override
  List<TypeRef> get types {
    _types ??= const fb.ListReader<TypeRef>(const _TypeRefReader()).vTableGet(_bp, 1, const <TypeRef>[]);
    return _types;
  }
}

abstract class _LinkedUnitMixin implements LinkedUnit {
  @override
  Map<String, Object> toMap() => {
    "references": references,
    "types": types,
  };
}

class SdkBundleBuilder extends Object with _SdkBundleMixin implements SdkBundle {
  bool _finished = false;

  List<String> _linkedLibraryUris;
  List<LinkedLibraryBuilder> _linkedLibraries;
  List<String> _unlinkedUnitUris;
  List<UnlinkedUnitBuilder> _unlinkedUnits;

  @override
  List<String> get linkedLibraryUris => _linkedLibraryUris ??= <String>[];

  /**
   * The list of URIs of items in [linkedLibraries], e.g. `dart:core`.
   */
  void set linkedLibraryUris(List<String> _value) {
    assert(!_finished);
    _linkedLibraryUris = _value;
  }

  @override
  List<LinkedLibraryBuilder> get linkedLibraries => _linkedLibraries ??= <LinkedLibraryBuilder>[];

  /**
   * Linked libraries.
   */
  void set linkedLibraries(List<LinkedLibraryBuilder> _value) {
    assert(!_finished);
    _linkedLibraries = _value;
  }

  @override
  List<String> get unlinkedUnitUris => _unlinkedUnitUris ??= <String>[];

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  void set unlinkedUnitUris(List<String> _value) {
    assert(!_finished);
    _unlinkedUnitUris = _value;
  }

  @override
  List<UnlinkedUnitBuilder> get unlinkedUnits => _unlinkedUnits ??= <UnlinkedUnitBuilder>[];

  /**
   * Unlinked information for the compilation units constituting the SDK.
   */
  void set unlinkedUnits(List<UnlinkedUnitBuilder> _value) {
    assert(!_finished);
    _unlinkedUnits = _value;
  }

  SdkBundleBuilder({List<String> linkedLibraryUris, List<LinkedLibraryBuilder> linkedLibraries, List<String> unlinkedUnitUris, List<UnlinkedUnitBuilder> unlinkedUnits})
    : _linkedLibraryUris = linkedLibraryUris,
      _linkedLibraries = linkedLibraries,
      _unlinkedUnitUris = unlinkedUnitUris,
      _unlinkedUnits = unlinkedUnits;

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder));
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_linkedLibraryUris;
    fb.Offset offset_linkedLibraries;
    fb.Offset offset_unlinkedUnitUris;
    fb.Offset offset_unlinkedUnits;
    if (!(_linkedLibraryUris == null || _linkedLibraryUris.isEmpty)) {
      offset_linkedLibraryUris = fbBuilder.writeList(_linkedLibraryUris.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_linkedLibraries == null || _linkedLibraries.isEmpty)) {
      offset_linkedLibraries = fbBuilder.writeList(_linkedLibraries.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_unlinkedUnitUris == null || _unlinkedUnitUris.isEmpty)) {
      offset_unlinkedUnitUris = fbBuilder.writeList(_unlinkedUnitUris.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_unlinkedUnits == null || _unlinkedUnits.isEmpty)) {
      offset_unlinkedUnits = fbBuilder.writeList(_unlinkedUnits.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_linkedLibraryUris != null) {
      fbBuilder.addOffset(0, offset_linkedLibraryUris);
    }
    if (offset_linkedLibraries != null) {
      fbBuilder.addOffset(1, offset_linkedLibraries);
    }
    if (offset_unlinkedUnitUris != null) {
      fbBuilder.addOffset(2, offset_unlinkedUnitUris);
    }
    if (offset_unlinkedUnits != null) {
      fbBuilder.addOffset(3, offset_unlinkedUnits);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Information about SDK.
 */
abstract class SdkBundle extends base.SummaryClass {
  factory SdkBundle.fromBuffer(List<int> buffer) {
    fb.BufferPointer rootRef = new fb.BufferPointer.fromBytes(buffer);
    return const _SdkBundleReader().read(rootRef);
  }

  /**
   * The list of URIs of items in [linkedLibraries], e.g. `dart:core`.
   */
  List<String> get linkedLibraryUris;

  /**
   * Linked libraries.
   */
  List<LinkedLibrary> get linkedLibraries;

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  List<String> get unlinkedUnitUris;

  /**
   * Unlinked information for the compilation units constituting the SDK.
   */
  List<UnlinkedUnit> get unlinkedUnits;
}

class _SdkBundleReader extends fb.TableReader<_SdkBundleImpl> {
  const _SdkBundleReader();

  @override
  _SdkBundleImpl createObject(fb.BufferPointer bp) => new _SdkBundleImpl(bp);
}

class _SdkBundleImpl extends Object with _SdkBundleMixin implements SdkBundle {
  final fb.BufferPointer _bp;

  _SdkBundleImpl(this._bp);

  List<String> _linkedLibraryUris;
  List<LinkedLibrary> _linkedLibraries;
  List<String> _unlinkedUnitUris;
  List<UnlinkedUnit> _unlinkedUnits;

  @override
  List<String> get linkedLibraryUris {
    _linkedLibraryUris ??= const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 0, const <String>[]);
    return _linkedLibraryUris;
  }

  @override
  List<LinkedLibrary> get linkedLibraries {
    _linkedLibraries ??= const fb.ListReader<LinkedLibrary>(const _LinkedLibraryReader()).vTableGet(_bp, 1, const <LinkedLibrary>[]);
    return _linkedLibraries;
  }

  @override
  List<String> get unlinkedUnitUris {
    _unlinkedUnitUris ??= const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 2, const <String>[]);
    return _unlinkedUnitUris;
  }

  @override
  List<UnlinkedUnit> get unlinkedUnits {
    _unlinkedUnits ??= const fb.ListReader<UnlinkedUnit>(const _UnlinkedUnitReader()).vTableGet(_bp, 3, const <UnlinkedUnit>[]);
    return _unlinkedUnits;
  }
}

abstract class _SdkBundleMixin implements SdkBundle {
  @override
  Map<String, Object> toMap() => {
    "linkedLibraryUris": linkedLibraryUris,
    "linkedLibraries": linkedLibraries,
    "unlinkedUnitUris": unlinkedUnitUris,
    "unlinkedUnits": unlinkedUnits,
  };
}

class TypeRefBuilder extends Object with _TypeRefMixin implements TypeRef {
  bool _finished = false;

  int _slot;
  int _reference;
  int _paramReference;
  List<TypeRefBuilder> _typeArguments;

  @override
  int get slot => _slot ??= 0;

  /**
   * If this [TypeRef] is contained within [LinkedUnit.types], slot id (which
   * is unique within the compilation unit) identifying the target of type
   * propagation or type inference with which this [TypeRef] is associated.
   *
   * Otherwise zero.
   */
  void set slot(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _slot = _value;
  }

  @override
  int get reference => _reference ??= 0;

  /**
   * Index into [UnlinkedUnit.references] for the type being referred to, or
   * zero if this is a reference to a type parameter.
   *
   * Note that since zero is also a valid index into
   * [UnlinkedUnit.references], we cannot distinguish between references to
   * type parameters and references to types by checking [reference] against
   * zero.  To distinguish between references to type parameters and references
   * to types, check whether [paramReference] is zero.
   */
  void set reference(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _reference = _value;
  }

  @override
  int get paramReference => _paramReference ??= 0;

  /**
   * If this is a reference to a type parameter, one-based index into the list
   * of [UnlinkedTypeParam]s currently in effect.  Indexing is done using De
   * Bruijn index conventions; that is, innermost parameters come first, and
   * if a class or method has multiple parameters, they are indexed from right
   * to left.  So for instance, if the enclosing declaration is
   *
   *     class C<T,U> {
   *       m<V,W> {
   *         ...
   *       }
   *     }
   *
   * Then [paramReference] values of 1, 2, 3, and 4 represent W, V, U, and T,
   * respectively.
   *
   * If the type being referred to is not a type parameter, [paramReference] is
   * zero.
   */
  void set paramReference(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _paramReference = _value;
  }

  @override
  List<TypeRefBuilder> get typeArguments => _typeArguments ??= <TypeRefBuilder>[];

  /**
   * If this is an instantiation of a generic type, the type arguments used to
   * instantiate it.  Trailing type arguments of type `dynamic` are omitted.
   */
  void set typeArguments(List<TypeRefBuilder> _value) {
    assert(!_finished);
    _typeArguments = _value;
  }

  TypeRefBuilder({int slot, int reference, int paramReference, List<TypeRefBuilder> typeArguments})
    : _slot = slot,
      _reference = reference,
      _paramReference = paramReference,
      _typeArguments = typeArguments;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_typeArguments;
    if (!(_typeArguments == null || _typeArguments.isEmpty)) {
      offset_typeArguments = fbBuilder.writeList(_typeArguments.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (_slot != null && _slot != 0) {
      fbBuilder.addUint32(0, _slot);
    }
    if (_reference != null && _reference != 0) {
      fbBuilder.addUint32(1, _reference);
    }
    if (_paramReference != null && _paramReference != 0) {
      fbBuilder.addUint32(2, _paramReference);
    }
    if (offset_typeArguments != null) {
      fbBuilder.addOffset(3, offset_typeArguments);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Summary information about a reference to a type.
 */
abstract class TypeRef extends base.SummaryClass {

  /**
   * If this [TypeRef] is contained within [LinkedUnit.types], slot id (which
   * is unique within the compilation unit) identifying the target of type
   * propagation or type inference with which this [TypeRef] is associated.
   *
   * Otherwise zero.
   */
  int get slot;

  /**
   * Index into [UnlinkedUnit.references] for the type being referred to, or
   * zero if this is a reference to a type parameter.
   *
   * Note that since zero is also a valid index into
   * [UnlinkedUnit.references], we cannot distinguish between references to
   * type parameters and references to types by checking [reference] against
   * zero.  To distinguish between references to type parameters and references
   * to types, check whether [paramReference] is zero.
   */
  int get reference;

  /**
   * If this is a reference to a type parameter, one-based index into the list
   * of [UnlinkedTypeParam]s currently in effect.  Indexing is done using De
   * Bruijn index conventions; that is, innermost parameters come first, and
   * if a class or method has multiple parameters, they are indexed from right
   * to left.  So for instance, if the enclosing declaration is
   *
   *     class C<T,U> {
   *       m<V,W> {
   *         ...
   *       }
   *     }
   *
   * Then [paramReference] values of 1, 2, 3, and 4 represent W, V, U, and T,
   * respectively.
   *
   * If the type being referred to is not a type parameter, [paramReference] is
   * zero.
   */
  int get paramReference;

  /**
   * If this is an instantiation of a generic type, the type arguments used to
   * instantiate it.  Trailing type arguments of type `dynamic` are omitted.
   */
  List<TypeRef> get typeArguments;
}

class _TypeRefReader extends fb.TableReader<_TypeRefImpl> {
  const _TypeRefReader();

  @override
  _TypeRefImpl createObject(fb.BufferPointer bp) => new _TypeRefImpl(bp);
}

class _TypeRefImpl extends Object with _TypeRefMixin implements TypeRef {
  final fb.BufferPointer _bp;

  _TypeRefImpl(this._bp);

  int _slot;
  int _reference;
  int _paramReference;
  List<TypeRef> _typeArguments;

  @override
  int get slot {
    _slot ??= const fb.Uint32Reader().vTableGet(_bp, 0, 0);
    return _slot;
  }

  @override
  int get reference {
    _reference ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _reference;
  }

  @override
  int get paramReference {
    _paramReference ??= const fb.Uint32Reader().vTableGet(_bp, 2, 0);
    return _paramReference;
  }

  @override
  List<TypeRef> get typeArguments {
    _typeArguments ??= const fb.ListReader<TypeRef>(const _TypeRefReader()).vTableGet(_bp, 3, const <TypeRef>[]);
    return _typeArguments;
  }
}

abstract class _TypeRefMixin implements TypeRef {
  @override
  Map<String, Object> toMap() => {
    "slot": slot,
    "reference": reference,
    "paramReference": paramReference,
    "typeArguments": typeArguments,
  };
}

class UnlinkedClassBuilder extends Object with _UnlinkedClassMixin implements UnlinkedClass {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  List<UnlinkedTypeParamBuilder> _typeParameters;
  TypeRefBuilder _supertype;
  List<TypeRefBuilder> _mixins;
  List<TypeRefBuilder> _interfaces;
  List<UnlinkedVariableBuilder> _fields;
  List<UnlinkedExecutableBuilder> _executables;
  bool _isAbstract;
  bool _isMixinApplication;
  bool _hasNoSupertype;

  @override
  String get name => _name ??= '';

  /**
   * Name of the class.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment => _documentationComment;

  /**
   * Documentation comment for the class, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters => _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /**
   * Type parameters of the class, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    _typeParameters = _value;
  }

  @override
  TypeRefBuilder get supertype => _supertype;

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  void set supertype(TypeRefBuilder _value) {
    assert(!_finished);
    _supertype = _value;
  }

  @override
  List<TypeRefBuilder> get mixins => _mixins ??= <TypeRefBuilder>[];

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  void set mixins(List<TypeRefBuilder> _value) {
    assert(!_finished);
    _mixins = _value;
  }

  @override
  List<TypeRefBuilder> get interfaces => _interfaces ??= <TypeRefBuilder>[];

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  void set interfaces(List<TypeRefBuilder> _value) {
    assert(!_finished);
    _interfaces = _value;
  }

  @override
  List<UnlinkedVariableBuilder> get fields => _fields ??= <UnlinkedVariableBuilder>[];

  /**
   * Field declarations contained in the class.
   */
  void set fields(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    _fields = _value;
  }

  @override
  List<UnlinkedExecutableBuilder> get executables => _executables ??= <UnlinkedExecutableBuilder>[];

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    _executables = _value;
  }

  @override
  bool get isAbstract => _isAbstract ??= false;

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  void set isAbstract(bool _value) {
    assert(!_finished);
    _isAbstract = _value;
  }

  @override
  bool get isMixinApplication => _isMixinApplication ??= false;

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  void set isMixinApplication(bool _value) {
    assert(!_finished);
    _isMixinApplication = _value;
  }

  @override
  bool get hasNoSupertype => _hasNoSupertype ??= false;

  /**
   * Indicates whether this class is the core "Object" class (and hence has no
   * supertype)
   */
  void set hasNoSupertype(bool _value) {
    assert(!_finished);
    _hasNoSupertype = _value;
  }

  UnlinkedClassBuilder({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedTypeParamBuilder> typeParameters, TypeRefBuilder supertype, List<TypeRefBuilder> mixins, List<TypeRefBuilder> interfaces, List<UnlinkedVariableBuilder> fields, List<UnlinkedExecutableBuilder> executables, bool isAbstract, bool isMixinApplication, bool hasNoSupertype})
    : _name = name,
      _nameOffset = nameOffset,
      _documentationComment = documentationComment,
      _typeParameters = typeParameters,
      _supertype = supertype,
      _mixins = mixins,
      _interfaces = interfaces,
      _fields = fields,
      _executables = executables,
      _isAbstract = isAbstract,
      _isMixinApplication = isMixinApplication,
      _hasNoSupertype = hasNoSupertype;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    fb.Offset offset_documentationComment;
    fb.Offset offset_typeParameters;
    fb.Offset offset_supertype;
    fb.Offset offset_mixins;
    fb.Offset offset_interfaces;
    fb.Offset offset_fields;
    fb.Offset offset_executables;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (!(_typeParameters == null || _typeParameters.isEmpty)) {
      offset_typeParameters = fbBuilder.writeList(_typeParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_supertype != null) {
      offset_supertype = _supertype.finish(fbBuilder);
    }
    if (!(_mixins == null || _mixins.isEmpty)) {
      offset_mixins = fbBuilder.writeList(_mixins.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_interfaces == null || _interfaces.isEmpty)) {
      offset_interfaces = fbBuilder.writeList(_interfaces.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_fields == null || _fields.isEmpty)) {
      offset_fields = fbBuilder.writeList(_fields.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_executables == null || _executables.isEmpty)) {
      offset_executables = fbBuilder.writeList(_executables.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(2, offset_documentationComment);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(3, offset_typeParameters);
    }
    if (offset_supertype != null) {
      fbBuilder.addOffset(4, offset_supertype);
    }
    if (offset_mixins != null) {
      fbBuilder.addOffset(5, offset_mixins);
    }
    if (offset_interfaces != null) {
      fbBuilder.addOffset(6, offset_interfaces);
    }
    if (offset_fields != null) {
      fbBuilder.addOffset(7, offset_fields);
    }
    if (offset_executables != null) {
      fbBuilder.addOffset(8, offset_executables);
    }
    if (_isAbstract == true) {
      fbBuilder.addBool(9, true);
    }
    if (_isMixinApplication == true) {
      fbBuilder.addBool(10, true);
    }
    if (_hasNoSupertype == true) {
      fbBuilder.addBool(11, true);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a class declaration.
 */
abstract class UnlinkedClass extends base.SummaryClass {

  /**
   * Name of the class.
   */
  String get name;

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  int get nameOffset;

  /**
   * Documentation comment for the class, or `null` if there is no
   * documentation comment.
   */
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Type parameters of the class, if any.
   */
  List<UnlinkedTypeParam> get typeParameters;

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  TypeRef get supertype;

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  List<TypeRef> get mixins;

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  List<TypeRef> get interfaces;

  /**
   * Field declarations contained in the class.
   */
  List<UnlinkedVariable> get fields;

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  List<UnlinkedExecutable> get executables;

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  bool get isAbstract;

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  bool get isMixinApplication;

  /**
   * Indicates whether this class is the core "Object" class (and hence has no
   * supertype)
   */
  bool get hasNoSupertype;
}

class _UnlinkedClassReader extends fb.TableReader<_UnlinkedClassImpl> {
  const _UnlinkedClassReader();

  @override
  _UnlinkedClassImpl createObject(fb.BufferPointer bp) => new _UnlinkedClassImpl(bp);
}

class _UnlinkedClassImpl extends Object with _UnlinkedClassMixin implements UnlinkedClass {
  final fb.BufferPointer _bp;

  _UnlinkedClassImpl(this._bp);

  String _name;
  int _nameOffset;
  UnlinkedDocumentationComment _documentationComment;
  List<UnlinkedTypeParam> _typeParameters;
  TypeRef _supertype;
  List<TypeRef> _mixins;
  List<TypeRef> _interfaces;
  List<UnlinkedVariable> _fields;
  List<UnlinkedExecutable> _executables;
  bool _isAbstract;
  bool _isMixinApplication;
  bool _hasNoSupertype;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);
    return _documentationComment;
  }

  @override
  List<UnlinkedTypeParam> get typeParameters {
    _typeParameters ??= const fb.ListReader<UnlinkedTypeParam>(const _UnlinkedTypeParamReader()).vTableGet(_bp, 3, const <UnlinkedTypeParam>[]);
    return _typeParameters;
  }

  @override
  TypeRef get supertype {
    _supertype ??= const _TypeRefReader().vTableGet(_bp, 4, null);
    return _supertype;
  }

  @override
  List<TypeRef> get mixins {
    _mixins ??= const fb.ListReader<TypeRef>(const _TypeRefReader()).vTableGet(_bp, 5, const <TypeRef>[]);
    return _mixins;
  }

  @override
  List<TypeRef> get interfaces {
    _interfaces ??= const fb.ListReader<TypeRef>(const _TypeRefReader()).vTableGet(_bp, 6, const <TypeRef>[]);
    return _interfaces;
  }

  @override
  List<UnlinkedVariable> get fields {
    _fields ??= const fb.ListReader<UnlinkedVariable>(const _UnlinkedVariableReader()).vTableGet(_bp, 7, const <UnlinkedVariable>[]);
    return _fields;
  }

  @override
  List<UnlinkedExecutable> get executables {
    _executables ??= const fb.ListReader<UnlinkedExecutable>(const _UnlinkedExecutableReader()).vTableGet(_bp, 8, const <UnlinkedExecutable>[]);
    return _executables;
  }

  @override
  bool get isAbstract {
    _isAbstract ??= const fb.BoolReader().vTableGet(_bp, 9, false);
    return _isAbstract;
  }

  @override
  bool get isMixinApplication {
    _isMixinApplication ??= const fb.BoolReader().vTableGet(_bp, 10, false);
    return _isMixinApplication;
  }

  @override
  bool get hasNoSupertype {
    _hasNoSupertype ??= const fb.BoolReader().vTableGet(_bp, 11, false);
    return _hasNoSupertype;
  }
}

abstract class _UnlinkedClassMixin implements UnlinkedClass {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
    "typeParameters": typeParameters,
    "supertype": supertype,
    "mixins": mixins,
    "interfaces": interfaces,
    "fields": fields,
    "executables": executables,
    "isAbstract": isAbstract,
    "isMixinApplication": isMixinApplication,
    "hasNoSupertype": hasNoSupertype,
  };
}

class UnlinkedCombinatorBuilder extends Object with _UnlinkedCombinatorMixin implements UnlinkedCombinator {
  bool _finished = false;

  List<String> _shows;
  List<String> _hides;

  @override
  List<String> get shows => _shows ??= <String>[];

  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  void set shows(List<String> _value) {
    assert(!_finished);
    _shows = _value;
  }

  @override
  List<String> get hides => _hides ??= <String>[];

  /**
   * List of names which are hidden.  Empty if this is a `show` combinator.
   */
  void set hides(List<String> _value) {
    assert(!_finished);
    _hides = _value;
  }

  UnlinkedCombinatorBuilder({List<String> shows, List<String> hides})
    : _shows = shows,
      _hides = hides;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_shows;
    fb.Offset offset_hides;
    if (!(_shows == null || _shows.isEmpty)) {
      offset_shows = fbBuilder.writeList(_shows.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_hides == null || _hides.isEmpty)) {
      offset_hides = fbBuilder.writeList(_hides.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_shows != null) {
      fbBuilder.addOffset(0, offset_shows);
    }
    if (offset_hides != null) {
      fbBuilder.addOffset(1, offset_hides);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a `show` or `hide` combinator in an
 * import or export declaration.
 */
abstract class UnlinkedCombinator extends base.SummaryClass {

  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  List<String> get shows;

  /**
   * List of names which are hidden.  Empty if this is a `show` combinator.
   */
  List<String> get hides;
}

class _UnlinkedCombinatorReader extends fb.TableReader<_UnlinkedCombinatorImpl> {
  const _UnlinkedCombinatorReader();

  @override
  _UnlinkedCombinatorImpl createObject(fb.BufferPointer bp) => new _UnlinkedCombinatorImpl(bp);
}

class _UnlinkedCombinatorImpl extends Object with _UnlinkedCombinatorMixin implements UnlinkedCombinator {
  final fb.BufferPointer _bp;

  _UnlinkedCombinatorImpl(this._bp);

  List<String> _shows;
  List<String> _hides;

  @override
  List<String> get shows {
    _shows ??= const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 0, const <String>[]);
    return _shows;
  }

  @override
  List<String> get hides {
    _hides ??= const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 1, const <String>[]);
    return _hides;
  }
}

abstract class _UnlinkedCombinatorMixin implements UnlinkedCombinator {
  @override
  Map<String, Object> toMap() => {
    "shows": shows,
    "hides": hides,
  };
}

class UnlinkedConstBuilder extends Object with _UnlinkedConstMixin implements UnlinkedConst {
  bool _finished = false;

  List<UnlinkedConstOperation> _operations;
  List<int> _ints;
  List<double> _doubles;
  List<String> _strings;
  List<TypeRefBuilder> _references;

  @override
  List<UnlinkedConstOperation> get operations => _operations ??= <UnlinkedConstOperation>[];

  /**
   * Sequence of operations to execute (starting with an empty stack) to form
   * the constant value.
   */
  void set operations(List<UnlinkedConstOperation> _value) {
    assert(!_finished);
    _operations = _value;
  }

  @override
  List<int> get ints => _ints ??= <int>[];

  /**
   * Sequence of unsigned 32-bit integers consumed by the operations
   * `pushArgument`, `pushInt`, `shiftOr`, `concatenate`, `invokeConstructor`,
   * `makeList`, and `makeMap`.
   */
  void set ints(List<int> _value) {
    assert(!_finished);
    assert(_value == null || _value.every((e) => e >= 0));
    _ints = _value;
  }

  @override
  List<double> get doubles => _doubles ??= <double>[];

  /**
   * Sequence of 64-bit doubles consumed by the operation `pushDouble`.
   */
  void set doubles(List<double> _value) {
    assert(!_finished);
    _doubles = _value;
  }

  @override
  List<String> get strings => _strings ??= <String>[];

  /**
   * Sequence of strings consumed by the operations `pushString` and
   * `invokeConstructor`.
   */
  void set strings(List<String> _value) {
    assert(!_finished);
    _strings = _value;
  }

  @override
  List<TypeRefBuilder> get references => _references ??= <TypeRefBuilder>[];

  /**
   * Sequence of language constructs consumed by the operations
   * `pushReference`, `invokeConstructor`, `makeList`, and `makeMap`.  Note
   * that in the case of `pushReference` (and sometimes `invokeConstructor` the
   * actual entity being referred to may be something other than a type.
   */
  void set references(List<TypeRefBuilder> _value) {
    assert(!_finished);
    _references = _value;
  }

  UnlinkedConstBuilder({List<UnlinkedConstOperation> operations, List<int> ints, List<double> doubles, List<String> strings, List<TypeRefBuilder> references})
    : _operations = operations,
      _ints = ints,
      _doubles = doubles,
      _strings = strings,
      _references = references;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_operations;
    fb.Offset offset_ints;
    fb.Offset offset_doubles;
    fb.Offset offset_strings;
    fb.Offset offset_references;
    if (!(_operations == null || _operations.isEmpty)) {
      offset_operations = fbBuilder.writeListUint32(_operations.map((b) => b.index).toList());
    }
    if (!(_ints == null || _ints.isEmpty)) {
      offset_ints = fbBuilder.writeListUint32(_ints);
    }
    if (!(_doubles == null || _doubles.isEmpty)) {
      offset_doubles = fbBuilder.writeListFloat64(_doubles);
    }
    if (!(_strings == null || _strings.isEmpty)) {
      offset_strings = fbBuilder.writeList(_strings.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_references == null || _references.isEmpty)) {
      offset_references = fbBuilder.writeList(_references.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_operations != null) {
      fbBuilder.addOffset(0, offset_operations);
    }
    if (offset_ints != null) {
      fbBuilder.addOffset(1, offset_ints);
    }
    if (offset_doubles != null) {
      fbBuilder.addOffset(2, offset_doubles);
    }
    if (offset_strings != null) {
      fbBuilder.addOffset(3, offset_strings);
    }
    if (offset_references != null) {
      fbBuilder.addOffset(4, offset_references);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a compile-time constant expression, or a
 * potentially constant expression.
 *
 * Constant expressions are represented using a simple stack-based language
 * where [operations] is a sequence of operations to execute starting with an
 * empty stack.  Once all operations have been executed, the stack should
 * contain a single value which is the value of the constant.  Note that some
 * operations consume additional data from the other fields of this class.
 */
abstract class UnlinkedConst extends base.SummaryClass {

  /**
   * Sequence of operations to execute (starting with an empty stack) to form
   * the constant value.
   */
  List<UnlinkedConstOperation> get operations;

  /**
   * Sequence of unsigned 32-bit integers consumed by the operations
   * `pushArgument`, `pushInt`, `shiftOr`, `concatenate`, `invokeConstructor`,
   * `makeList`, and `makeMap`.
   */
  List<int> get ints;

  /**
   * Sequence of 64-bit doubles consumed by the operation `pushDouble`.
   */
  List<double> get doubles;

  /**
   * Sequence of strings consumed by the operations `pushString` and
   * `invokeConstructor`.
   */
  List<String> get strings;

  /**
   * Sequence of language constructs consumed by the operations
   * `pushReference`, `invokeConstructor`, `makeList`, and `makeMap`.  Note
   * that in the case of `pushReference` (and sometimes `invokeConstructor` the
   * actual entity being referred to may be something other than a type.
   */
  List<TypeRef> get references;
}

class _UnlinkedConstReader extends fb.TableReader<_UnlinkedConstImpl> {
  const _UnlinkedConstReader();

  @override
  _UnlinkedConstImpl createObject(fb.BufferPointer bp) => new _UnlinkedConstImpl(bp);
}

class _UnlinkedConstImpl extends Object with _UnlinkedConstMixin implements UnlinkedConst {
  final fb.BufferPointer _bp;

  _UnlinkedConstImpl(this._bp);

  List<UnlinkedConstOperation> _operations;
  List<int> _ints;
  List<double> _doubles;
  List<String> _strings;
  List<TypeRef> _references;

  @override
  List<UnlinkedConstOperation> get operations {
    _operations ??= const fb.ListReader<UnlinkedConstOperation>(const _UnlinkedConstOperationReader()).vTableGet(_bp, 0, const <UnlinkedConstOperation>[]);
    return _operations;
  }

  @override
  List<int> get ints {
    _ints ??= const fb.ListReader<int>(const fb.Uint32Reader()).vTableGet(_bp, 1, const <int>[]);
    return _ints;
  }

  @override
  List<double> get doubles {
    _doubles ??= const fb.Float64ListReader().vTableGet(_bp, 2, const <double>[]);
    return _doubles;
  }

  @override
  List<String> get strings {
    _strings ??= const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 3, const <String>[]);
    return _strings;
  }

  @override
  List<TypeRef> get references {
    _references ??= const fb.ListReader<TypeRef>(const _TypeRefReader()).vTableGet(_bp, 4, const <TypeRef>[]);
    return _references;
  }
}

abstract class _UnlinkedConstMixin implements UnlinkedConst {
  @override
  Map<String, Object> toMap() => {
    "operations": operations,
    "ints": ints,
    "doubles": doubles,
    "strings": strings,
    "references": references,
  };
}

class UnlinkedDocumentationCommentBuilder extends Object with _UnlinkedDocumentationCommentMixin implements UnlinkedDocumentationComment {
  bool _finished = false;

  String _text;
  int _offset;
  int _length;

  @override
  String get text => _text ??= '';

  /**
   * Text of the documentation comment, with '\r\n' replaced by '\n'.
   *
   * References appearing within the doc comment in square brackets are not
   * specially encoded.
   */
  void set text(String _value) {
    assert(!_finished);
    _text = _value;
  }

  @override
  int get offset => _offset ??= 0;

  /**
   * Offset of the beginning of the documentation comment relative to the
   * beginning of the file.
   */
  void set offset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _offset = _value;
  }

  @override
  int get length => _length ??= 0;

  /**
   * Length of the documentation comment (prior to replacing '\r\n' with '\n').
   */
  void set length(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _length = _value;
  }

  UnlinkedDocumentationCommentBuilder({String text, int offset, int length})
    : _text = text,
      _offset = offset,
      _length = length;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_text;
    if (_text != null) {
      offset_text = fbBuilder.writeString(_text);
    }
    fbBuilder.startTable();
    if (offset_text != null) {
      fbBuilder.addOffset(0, offset_text);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(1, _offset);
    }
    if (_length != null && _length != 0) {
      fbBuilder.addUint32(2, _length);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a documentation comment.
 */
abstract class UnlinkedDocumentationComment extends base.SummaryClass {

  /**
   * Text of the documentation comment, with '\r\n' replaced by '\n'.
   *
   * References appearing within the doc comment in square brackets are not
   * specially encoded.
   */
  String get text;

  /**
   * Offset of the beginning of the documentation comment relative to the
   * beginning of the file.
   */
  int get offset;

  /**
   * Length of the documentation comment (prior to replacing '\r\n' with '\n').
   */
  int get length;
}

class _UnlinkedDocumentationCommentReader extends fb.TableReader<_UnlinkedDocumentationCommentImpl> {
  const _UnlinkedDocumentationCommentReader();

  @override
  _UnlinkedDocumentationCommentImpl createObject(fb.BufferPointer bp) => new _UnlinkedDocumentationCommentImpl(bp);
}

class _UnlinkedDocumentationCommentImpl extends Object with _UnlinkedDocumentationCommentMixin implements UnlinkedDocumentationComment {
  final fb.BufferPointer _bp;

  _UnlinkedDocumentationCommentImpl(this._bp);

  String _text;
  int _offset;
  int _length;

  @override
  String get text {
    _text ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _text;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _offset;
  }

  @override
  int get length {
    _length ??= const fb.Uint32Reader().vTableGet(_bp, 2, 0);
    return _length;
  }
}

abstract class _UnlinkedDocumentationCommentMixin implements UnlinkedDocumentationComment {
  @override
  Map<String, Object> toMap() => {
    "text": text,
    "offset": offset,
    "length": length,
  };
}

class UnlinkedEnumBuilder extends Object with _UnlinkedEnumMixin implements UnlinkedEnum {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  List<UnlinkedEnumValueBuilder> _values;

  @override
  String get name => _name ??= '';

  /**
   * Name of the enum type.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment => _documentationComment;

  /**
   * Documentation comment for the enum, or `null` if there is no documentation
   * comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  List<UnlinkedEnumValueBuilder> get values => _values ??= <UnlinkedEnumValueBuilder>[];

  /**
   * Values listed in the enum declaration, in declaration order.
   */
  void set values(List<UnlinkedEnumValueBuilder> _value) {
    assert(!_finished);
    _values = _value;
  }

  UnlinkedEnumBuilder({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedEnumValueBuilder> values})
    : _name = name,
      _nameOffset = nameOffset,
      _documentationComment = documentationComment,
      _values = values;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    fb.Offset offset_documentationComment;
    fb.Offset offset_values;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (!(_values == null || _values.isEmpty)) {
      offset_values = fbBuilder.writeList(_values.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(2, offset_documentationComment);
    }
    if (offset_values != null) {
      fbBuilder.addOffset(3, offset_values);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about an enum declaration.
 */
abstract class UnlinkedEnum extends base.SummaryClass {

  /**
   * Name of the enum type.
   */
  String get name;

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  int get nameOffset;

  /**
   * Documentation comment for the enum, or `null` if there is no documentation
   * comment.
   */
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Values listed in the enum declaration, in declaration order.
   */
  List<UnlinkedEnumValue> get values;
}

class _UnlinkedEnumReader extends fb.TableReader<_UnlinkedEnumImpl> {
  const _UnlinkedEnumReader();

  @override
  _UnlinkedEnumImpl createObject(fb.BufferPointer bp) => new _UnlinkedEnumImpl(bp);
}

class _UnlinkedEnumImpl extends Object with _UnlinkedEnumMixin implements UnlinkedEnum {
  final fb.BufferPointer _bp;

  _UnlinkedEnumImpl(this._bp);

  String _name;
  int _nameOffset;
  UnlinkedDocumentationComment _documentationComment;
  List<UnlinkedEnumValue> _values;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);
    return _documentationComment;
  }

  @override
  List<UnlinkedEnumValue> get values {
    _values ??= const fb.ListReader<UnlinkedEnumValue>(const _UnlinkedEnumValueReader()).vTableGet(_bp, 3, const <UnlinkedEnumValue>[]);
    return _values;
  }
}

abstract class _UnlinkedEnumMixin implements UnlinkedEnum {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
    "values": values,
  };
}

class UnlinkedEnumValueBuilder extends Object with _UnlinkedEnumValueMixin implements UnlinkedEnumValue {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;

  @override
  String get name => _name ??= '';

  /**
   * Name of the enumerated value.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment => _documentationComment;

  /**
   * Documentation comment for the enum value, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  UnlinkedEnumValueBuilder({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment})
    : _name = name,
      _nameOffset = nameOffset,
      _documentationComment = documentationComment;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    fb.Offset offset_documentationComment;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(2, offset_documentationComment);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a single enumerated value in an enum
 * declaration.
 */
abstract class UnlinkedEnumValue extends base.SummaryClass {

  /**
   * Name of the enumerated value.
   */
  String get name;

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  int get nameOffset;

  /**
   * Documentation comment for the enum value, or `null` if there is no
   * documentation comment.
   */
  UnlinkedDocumentationComment get documentationComment;
}

class _UnlinkedEnumValueReader extends fb.TableReader<_UnlinkedEnumValueImpl> {
  const _UnlinkedEnumValueReader();

  @override
  _UnlinkedEnumValueImpl createObject(fb.BufferPointer bp) => new _UnlinkedEnumValueImpl(bp);
}

class _UnlinkedEnumValueImpl extends Object with _UnlinkedEnumValueMixin implements UnlinkedEnumValue {
  final fb.BufferPointer _bp;

  _UnlinkedEnumValueImpl(this._bp);

  String _name;
  int _nameOffset;
  UnlinkedDocumentationComment _documentationComment;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);
    return _documentationComment;
  }
}

abstract class _UnlinkedEnumValueMixin implements UnlinkedEnumValue {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
  };
}

class UnlinkedExecutableBuilder extends Object with _UnlinkedExecutableMixin implements UnlinkedExecutable {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  List<UnlinkedTypeParamBuilder> _typeParameters;
  TypeRefBuilder _returnType;
  List<UnlinkedParamBuilder> _parameters;
  UnlinkedExecutableKind _kind;
  bool _isAbstract;
  bool _isStatic;
  bool _isConst;
  bool _isFactory;
  bool _hasImplicitReturnType;
  bool _isExternal;

  @override
  String get name => _name ??= '';

  /**
   * Name of the executable.  For setters, this includes the trailing "=".  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the empty string.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the executable name relative to the beginning of the file.  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the offset of the class name (i.e. the
   * offset of the second "C" in "class C { C(); }").
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment => _documentationComment;

  /**
   * Documentation comment for the executable, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters => _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    _typeParameters = _value;
  }

  @override
  TypeRefBuilder get returnType => _returnType;

  /**
   * Declared return type of the executable.  Absent if the return type is
   * `void` or the executable is a constructor.  Note that when strong mode is
   * enabled, the actual return type may be different due to type inference.
   */
  void set returnType(TypeRefBuilder _value) {
    assert(!_finished);
    _returnType = _value;
  }

  @override
  List<UnlinkedParamBuilder> get parameters => _parameters ??= <UnlinkedParamBuilder>[];

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters (hence this will be the empty list), and setters have a single
   * parameter.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    _parameters = _value;
  }

  @override
  UnlinkedExecutableKind get kind => _kind ??= UnlinkedExecutableKind.functionOrMethod;

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  void set kind(UnlinkedExecutableKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  @override
  bool get isAbstract => _isAbstract ??= false;

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  void set isAbstract(bool _value) {
    assert(!_finished);
    _isAbstract = _value;
  }

  @override
  bool get isStatic => _isStatic ??= false;

  /**
   * Indicates whether the executable is declared using the `static` keyword.
   *
   * Note that for top level executables, this flag is false, since they are
   * not declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  void set isStatic(bool _value) {
    assert(!_finished);
    _isStatic = _value;
  }

  @override
  bool get isConst => _isConst ??= false;

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  void set isConst(bool _value) {
    assert(!_finished);
    _isConst = _value;
  }

  @override
  bool get isFactory => _isFactory ??= false;

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  void set isFactory(bool _value) {
    assert(!_finished);
    _isFactory = _value;
  }

  @override
  bool get hasImplicitReturnType => _hasImplicitReturnType ??= false;

  /**
   * Indicates whether the executable lacks an explicit return type
   * declaration.  False for constructors and setters.
   */
  void set hasImplicitReturnType(bool _value) {
    assert(!_finished);
    _hasImplicitReturnType = _value;
  }

  @override
  bool get isExternal => _isExternal ??= false;

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  void set isExternal(bool _value) {
    assert(!_finished);
    _isExternal = _value;
  }

  UnlinkedExecutableBuilder({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedTypeParamBuilder> typeParameters, TypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters, UnlinkedExecutableKind kind, bool isAbstract, bool isStatic, bool isConst, bool isFactory, bool hasImplicitReturnType, bool isExternal})
    : _name = name,
      _nameOffset = nameOffset,
      _documentationComment = documentationComment,
      _typeParameters = typeParameters,
      _returnType = returnType,
      _parameters = parameters,
      _kind = kind,
      _isAbstract = isAbstract,
      _isStatic = isStatic,
      _isConst = isConst,
      _isFactory = isFactory,
      _hasImplicitReturnType = hasImplicitReturnType,
      _isExternal = isExternal;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    fb.Offset offset_documentationComment;
    fb.Offset offset_typeParameters;
    fb.Offset offset_returnType;
    fb.Offset offset_parameters;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (!(_typeParameters == null || _typeParameters.isEmpty)) {
      offset_typeParameters = fbBuilder.writeList(_typeParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_returnType != null) {
      offset_returnType = _returnType.finish(fbBuilder);
    }
    if (!(_parameters == null || _parameters.isEmpty)) {
      offset_parameters = fbBuilder.writeList(_parameters.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(2, offset_documentationComment);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(3, offset_typeParameters);
    }
    if (offset_returnType != null) {
      fbBuilder.addOffset(4, offset_returnType);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(5, offset_parameters);
    }
    if (_kind != null && _kind != UnlinkedExecutableKind.functionOrMethod) {
      fbBuilder.addUint32(6, _kind.index);
    }
    if (_isAbstract == true) {
      fbBuilder.addBool(7, true);
    }
    if (_isStatic == true) {
      fbBuilder.addBool(8, true);
    }
    if (_isConst == true) {
      fbBuilder.addBool(9, true);
    }
    if (_isFactory == true) {
      fbBuilder.addBool(10, true);
    }
    if (_hasImplicitReturnType == true) {
      fbBuilder.addBool(11, true);
    }
    if (_isExternal == true) {
      fbBuilder.addBool(12, true);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a function, method, getter, or setter
 * declaration.
 */
abstract class UnlinkedExecutable extends base.SummaryClass {

  /**
   * Name of the executable.  For setters, this includes the trailing "=".  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the empty string.
   */
  String get name;

  /**
   * Offset of the executable name relative to the beginning of the file.  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the offset of the class name (i.e. the
   * offset of the second "C" in "class C { C(); }").
   */
  int get nameOffset;

  /**
   * Documentation comment for the executable, or `null` if there is no
   * documentation comment.
   */
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  List<UnlinkedTypeParam> get typeParameters;

  /**
   * Declared return type of the executable.  Absent if the return type is
   * `void` or the executable is a constructor.  Note that when strong mode is
   * enabled, the actual return type may be different due to type inference.
   */
  TypeRef get returnType;

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters (hence this will be the empty list), and setters have a single
   * parameter.
   */
  List<UnlinkedParam> get parameters;

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  UnlinkedExecutableKind get kind;

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  bool get isAbstract;

  /**
   * Indicates whether the executable is declared using the `static` keyword.
   *
   * Note that for top level executables, this flag is false, since they are
   * not declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  bool get isStatic;

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  bool get isConst;

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  bool get isFactory;

  /**
   * Indicates whether the executable lacks an explicit return type
   * declaration.  False for constructors and setters.
   */
  bool get hasImplicitReturnType;

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  bool get isExternal;
}

class _UnlinkedExecutableReader extends fb.TableReader<_UnlinkedExecutableImpl> {
  const _UnlinkedExecutableReader();

  @override
  _UnlinkedExecutableImpl createObject(fb.BufferPointer bp) => new _UnlinkedExecutableImpl(bp);
}

class _UnlinkedExecutableImpl extends Object with _UnlinkedExecutableMixin implements UnlinkedExecutable {
  final fb.BufferPointer _bp;

  _UnlinkedExecutableImpl(this._bp);

  String _name;
  int _nameOffset;
  UnlinkedDocumentationComment _documentationComment;
  List<UnlinkedTypeParam> _typeParameters;
  TypeRef _returnType;
  List<UnlinkedParam> _parameters;
  UnlinkedExecutableKind _kind;
  bool _isAbstract;
  bool _isStatic;
  bool _isConst;
  bool _isFactory;
  bool _hasImplicitReturnType;
  bool _isExternal;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);
    return _documentationComment;
  }

  @override
  List<UnlinkedTypeParam> get typeParameters {
    _typeParameters ??= const fb.ListReader<UnlinkedTypeParam>(const _UnlinkedTypeParamReader()).vTableGet(_bp, 3, const <UnlinkedTypeParam>[]);
    return _typeParameters;
  }

  @override
  TypeRef get returnType {
    _returnType ??= const _TypeRefReader().vTableGet(_bp, 4, null);
    return _returnType;
  }

  @override
  List<UnlinkedParam> get parameters {
    _parameters ??= const fb.ListReader<UnlinkedParam>(const _UnlinkedParamReader()).vTableGet(_bp, 5, const <UnlinkedParam>[]);
    return _parameters;
  }

  @override
  UnlinkedExecutableKind get kind {
    _kind ??= const _UnlinkedExecutableKindReader().vTableGet(_bp, 6, UnlinkedExecutableKind.functionOrMethod);
    return _kind;
  }

  @override
  bool get isAbstract {
    _isAbstract ??= const fb.BoolReader().vTableGet(_bp, 7, false);
    return _isAbstract;
  }

  @override
  bool get isStatic {
    _isStatic ??= const fb.BoolReader().vTableGet(_bp, 8, false);
    return _isStatic;
  }

  @override
  bool get isConst {
    _isConst ??= const fb.BoolReader().vTableGet(_bp, 9, false);
    return _isConst;
  }

  @override
  bool get isFactory {
    _isFactory ??= const fb.BoolReader().vTableGet(_bp, 10, false);
    return _isFactory;
  }

  @override
  bool get hasImplicitReturnType {
    _hasImplicitReturnType ??= const fb.BoolReader().vTableGet(_bp, 11, false);
    return _hasImplicitReturnType;
  }

  @override
  bool get isExternal {
    _isExternal ??= const fb.BoolReader().vTableGet(_bp, 12, false);
    return _isExternal;
  }
}

abstract class _UnlinkedExecutableMixin implements UnlinkedExecutable {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
    "typeParameters": typeParameters,
    "returnType": returnType,
    "parameters": parameters,
    "kind": kind,
    "isAbstract": isAbstract,
    "isStatic": isStatic,
    "isConst": isConst,
    "isFactory": isFactory,
    "hasImplicitReturnType": hasImplicitReturnType,
    "isExternal": isExternal,
  };
}

class UnlinkedExportNonPublicBuilder extends Object with _UnlinkedExportNonPublicMixin implements UnlinkedExportNonPublic {
  bool _finished = false;

  int _offset;
  int _uriOffset;
  int _uriEnd;

  @override
  int get offset => _offset ??= 0;

  /**
   * Offset of the "export" keyword.
   */
  void set offset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _offset = _value;
  }

  @override
  int get uriOffset => _uriOffset ??= 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _uriOffset = _value;
  }

  @override
  int get uriEnd => _uriEnd ??= 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _uriEnd = _value;
  }

  UnlinkedExportNonPublicBuilder({int offset, int uriOffset, int uriEnd})
    : _offset = offset,
      _uriOffset = uriOffset,
      _uriEnd = uriEnd;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fbBuilder.startTable();
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(0, _offset);
    }
    if (_uriOffset != null && _uriOffset != 0) {
      fbBuilder.addUint32(1, _uriOffset);
    }
    if (_uriEnd != null && _uriEnd != 0) {
      fbBuilder.addUint32(2, _uriEnd);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about an export declaration (stored outside
 * [UnlinkedPublicNamespace]).
 */
abstract class UnlinkedExportNonPublic extends base.SummaryClass {

  /**
   * Offset of the "export" keyword.
   */
  int get offset;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  int get uriOffset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  int get uriEnd;
}

class _UnlinkedExportNonPublicReader extends fb.TableReader<_UnlinkedExportNonPublicImpl> {
  const _UnlinkedExportNonPublicReader();

  @override
  _UnlinkedExportNonPublicImpl createObject(fb.BufferPointer bp) => new _UnlinkedExportNonPublicImpl(bp);
}

class _UnlinkedExportNonPublicImpl extends Object with _UnlinkedExportNonPublicMixin implements UnlinkedExportNonPublic {
  final fb.BufferPointer _bp;

  _UnlinkedExportNonPublicImpl(this._bp);

  int _offset;
  int _uriOffset;
  int _uriEnd;

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bp, 0, 0);
    return _offset;
  }

  @override
  int get uriOffset {
    _uriOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _uriOffset;
  }

  @override
  int get uriEnd {
    _uriEnd ??= const fb.Uint32Reader().vTableGet(_bp, 2, 0);
    return _uriEnd;
  }
}

abstract class _UnlinkedExportNonPublicMixin implements UnlinkedExportNonPublic {
  @override
  Map<String, Object> toMap() => {
    "offset": offset,
    "uriOffset": uriOffset,
    "uriEnd": uriEnd,
  };
}

class UnlinkedExportPublicBuilder extends Object with _UnlinkedExportPublicMixin implements UnlinkedExportPublic {
  bool _finished = false;

  String _uri;
  List<UnlinkedCombinatorBuilder> _combinators;

  @override
  String get uri => _uri ??= '';

  /**
   * URI used in the source code to reference the exported library.
   */
  void set uri(String _value) {
    assert(!_finished);
    _uri = _value;
  }

  @override
  List<UnlinkedCombinatorBuilder> get combinators => _combinators ??= <UnlinkedCombinatorBuilder>[];

  /**
   * Combinators contained in this import declaration.
   */
  void set combinators(List<UnlinkedCombinatorBuilder> _value) {
    assert(!_finished);
    _combinators = _value;
  }

  UnlinkedExportPublicBuilder({String uri, List<UnlinkedCombinatorBuilder> combinators})
    : _uri = uri,
      _combinators = combinators;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_uri;
    fb.Offset offset_combinators;
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    if (!(_combinators == null || _combinators.isEmpty)) {
      offset_combinators = fbBuilder.writeList(_combinators.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_uri != null) {
      fbBuilder.addOffset(0, offset_uri);
    }
    if (offset_combinators != null) {
      fbBuilder.addOffset(1, offset_combinators);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about an export declaration (stored inside
 * [UnlinkedPublicNamespace]).
 */
abstract class UnlinkedExportPublic extends base.SummaryClass {

  /**
   * URI used in the source code to reference the exported library.
   */
  String get uri;

  /**
   * Combinators contained in this import declaration.
   */
  List<UnlinkedCombinator> get combinators;
}

class _UnlinkedExportPublicReader extends fb.TableReader<_UnlinkedExportPublicImpl> {
  const _UnlinkedExportPublicReader();

  @override
  _UnlinkedExportPublicImpl createObject(fb.BufferPointer bp) => new _UnlinkedExportPublicImpl(bp);
}

class _UnlinkedExportPublicImpl extends Object with _UnlinkedExportPublicMixin implements UnlinkedExportPublic {
  final fb.BufferPointer _bp;

  _UnlinkedExportPublicImpl(this._bp);

  String _uri;
  List<UnlinkedCombinator> _combinators;

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _uri;
  }

  @override
  List<UnlinkedCombinator> get combinators {
    _combinators ??= const fb.ListReader<UnlinkedCombinator>(const _UnlinkedCombinatorReader()).vTableGet(_bp, 1, const <UnlinkedCombinator>[]);
    return _combinators;
  }
}

abstract class _UnlinkedExportPublicMixin implements UnlinkedExportPublic {
  @override
  Map<String, Object> toMap() => {
    "uri": uri,
    "combinators": combinators,
  };
}

class UnlinkedImportBuilder extends Object with _UnlinkedImportMixin implements UnlinkedImport {
  bool _finished = false;

  String _uri;
  int _offset;
  int _prefixReference;
  List<UnlinkedCombinatorBuilder> _combinators;
  bool _isDeferred;
  bool _isImplicit;
  int _uriOffset;
  int _uriEnd;
  int _prefixOffset;

  @override
  String get uri => _uri ??= '';

  /**
   * URI used in the source code to reference the imported library.
   */
  void set uri(String _value) {
    assert(!_finished);
    _uri = _value;
  }

  @override
  int get offset => _offset ??= 0;

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  void set offset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _offset = _value;
  }

  @override
  int get prefixReference => _prefixReference ??= 0;

  /**
   * Index into [UnlinkedUnit.references] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  void set prefixReference(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _prefixReference = _value;
  }

  @override
  List<UnlinkedCombinatorBuilder> get combinators => _combinators ??= <UnlinkedCombinatorBuilder>[];

  /**
   * Combinators contained in this import declaration.
   */
  void set combinators(List<UnlinkedCombinatorBuilder> _value) {
    assert(!_finished);
    _combinators = _value;
  }

  @override
  bool get isDeferred => _isDeferred ??= false;

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  void set isDeferred(bool _value) {
    assert(!_finished);
    _isDeferred = _value;
  }

  @override
  bool get isImplicit => _isImplicit ??= false;

  /**
   * Indicates whether the import declaration is implicit.
   */
  void set isImplicit(bool _value) {
    assert(!_finished);
    _isImplicit = _value;
  }

  @override
  int get uriOffset => _uriOffset ??= 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _uriOffset = _value;
  }

  @override
  int get uriEnd => _uriEnd ??= 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _uriEnd = _value;
  }

  @override
  int get prefixOffset => _prefixOffset ??= 0;

  /**
   * Offset of the prefix name relative to the beginning of the file, or zero
   * if there is no prefix.
   */
  void set prefixOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _prefixOffset = _value;
  }

  UnlinkedImportBuilder({String uri, int offset, int prefixReference, List<UnlinkedCombinatorBuilder> combinators, bool isDeferred, bool isImplicit, int uriOffset, int uriEnd, int prefixOffset})
    : _uri = uri,
      _offset = offset,
      _prefixReference = prefixReference,
      _combinators = combinators,
      _isDeferred = isDeferred,
      _isImplicit = isImplicit,
      _uriOffset = uriOffset,
      _uriEnd = uriEnd,
      _prefixOffset = prefixOffset;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_uri;
    fb.Offset offset_combinators;
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    if (!(_combinators == null || _combinators.isEmpty)) {
      offset_combinators = fbBuilder.writeList(_combinators.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_uri != null) {
      fbBuilder.addOffset(0, offset_uri);
    }
    if (_offset != null && _offset != 0) {
      fbBuilder.addUint32(1, _offset);
    }
    if (_prefixReference != null && _prefixReference != 0) {
      fbBuilder.addUint32(2, _prefixReference);
    }
    if (offset_combinators != null) {
      fbBuilder.addOffset(3, offset_combinators);
    }
    if (_isDeferred == true) {
      fbBuilder.addBool(4, true);
    }
    if (_isImplicit == true) {
      fbBuilder.addBool(5, true);
    }
    if (_uriOffset != null && _uriOffset != 0) {
      fbBuilder.addUint32(6, _uriOffset);
    }
    if (_uriEnd != null && _uriEnd != 0) {
      fbBuilder.addUint32(7, _uriEnd);
    }
    if (_prefixOffset != null && _prefixOffset != 0) {
      fbBuilder.addUint32(8, _prefixOffset);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about an import declaration.
 */
abstract class UnlinkedImport extends base.SummaryClass {

  /**
   * URI used in the source code to reference the imported library.
   */
  String get uri;

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  int get offset;

  /**
   * Index into [UnlinkedUnit.references] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  int get prefixReference;

  /**
   * Combinators contained in this import declaration.
   */
  List<UnlinkedCombinator> get combinators;

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  bool get isDeferred;

  /**
   * Indicates whether the import declaration is implicit.
   */
  bool get isImplicit;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  int get uriOffset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  int get uriEnd;

  /**
   * Offset of the prefix name relative to the beginning of the file, or zero
   * if there is no prefix.
   */
  int get prefixOffset;
}

class _UnlinkedImportReader extends fb.TableReader<_UnlinkedImportImpl> {
  const _UnlinkedImportReader();

  @override
  _UnlinkedImportImpl createObject(fb.BufferPointer bp) => new _UnlinkedImportImpl(bp);
}

class _UnlinkedImportImpl extends Object with _UnlinkedImportMixin implements UnlinkedImport {
  final fb.BufferPointer _bp;

  _UnlinkedImportImpl(this._bp);

  String _uri;
  int _offset;
  int _prefixReference;
  List<UnlinkedCombinator> _combinators;
  bool _isDeferred;
  bool _isImplicit;
  int _uriOffset;
  int _uriEnd;
  int _prefixOffset;

  @override
  String get uri {
    _uri ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _uri;
  }

  @override
  int get offset {
    _offset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _offset;
  }

  @override
  int get prefixReference {
    _prefixReference ??= const fb.Uint32Reader().vTableGet(_bp, 2, 0);
    return _prefixReference;
  }

  @override
  List<UnlinkedCombinator> get combinators {
    _combinators ??= const fb.ListReader<UnlinkedCombinator>(const _UnlinkedCombinatorReader()).vTableGet(_bp, 3, const <UnlinkedCombinator>[]);
    return _combinators;
  }

  @override
  bool get isDeferred {
    _isDeferred ??= const fb.BoolReader().vTableGet(_bp, 4, false);
    return _isDeferred;
  }

  @override
  bool get isImplicit {
    _isImplicit ??= const fb.BoolReader().vTableGet(_bp, 5, false);
    return _isImplicit;
  }

  @override
  int get uriOffset {
    _uriOffset ??= const fb.Uint32Reader().vTableGet(_bp, 6, 0);
    return _uriOffset;
  }

  @override
  int get uriEnd {
    _uriEnd ??= const fb.Uint32Reader().vTableGet(_bp, 7, 0);
    return _uriEnd;
  }

  @override
  int get prefixOffset {
    _prefixOffset ??= const fb.Uint32Reader().vTableGet(_bp, 8, 0);
    return _prefixOffset;
  }
}

abstract class _UnlinkedImportMixin implements UnlinkedImport {
  @override
  Map<String, Object> toMap() => {
    "uri": uri,
    "offset": offset,
    "prefixReference": prefixReference,
    "combinators": combinators,
    "isDeferred": isDeferred,
    "isImplicit": isImplicit,
    "uriOffset": uriOffset,
    "uriEnd": uriEnd,
    "prefixOffset": prefixOffset,
  };
}

class UnlinkedParamBuilder extends Object with _UnlinkedParamMixin implements UnlinkedParam {
  bool _finished = false;

  String _name;
  int _nameOffset;
  TypeRefBuilder _type;
  List<UnlinkedParamBuilder> _parameters;
  UnlinkedParamKind _kind;
  bool _isFunctionTyped;
  bool _isInitializingFormal;
  bool _hasImplicitType;

  @override
  String get name => _name ??= '';

  /**
   * Name of the parameter.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _nameOffset = _value;
  }

  @override
  TypeRefBuilder get type => _type;

  /**
   * If [isFunctionTyped] is `true`, the declared return type.  If
   * [isFunctionTyped] is `false`, the declared type.  Absent if
   * [isFunctionTyped] is `true` and the declared return type is `void`.  Note
   * that when strong mode is enabled, the actual type may be different due to
   * type inference.
   */
  void set type(TypeRefBuilder _value) {
    assert(!_finished);
    _type = _value;
  }

  @override
  List<UnlinkedParamBuilder> get parameters => _parameters ??= <UnlinkedParamBuilder>[];

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    _parameters = _value;
  }

  @override
  UnlinkedParamKind get kind => _kind ??= UnlinkedParamKind.required;

  /**
   * Kind of the parameter.
   */
  void set kind(UnlinkedParamKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  @override
  bool get isFunctionTyped => _isFunctionTyped ??= false;

  /**
   * Indicates whether this is a function-typed parameter.
   */
  void set isFunctionTyped(bool _value) {
    assert(!_finished);
    _isFunctionTyped = _value;
  }

  @override
  bool get isInitializingFormal => _isInitializingFormal ??= false;

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  void set isInitializingFormal(bool _value) {
    assert(!_finished);
    _isInitializingFormal = _value;
  }

  @override
  bool get hasImplicitType => _hasImplicitType ??= false;

  /**
   * Indicates whether this parameter lacks an explicit type declaration.
   * Always false for a function-typed parameter.
   */
  void set hasImplicitType(bool _value) {
    assert(!_finished);
    _hasImplicitType = _value;
  }

  UnlinkedParamBuilder({String name, int nameOffset, TypeRefBuilder type, List<UnlinkedParamBuilder> parameters, UnlinkedParamKind kind, bool isFunctionTyped, bool isInitializingFormal, bool hasImplicitType})
    : _name = name,
      _nameOffset = nameOffset,
      _type = type,
      _parameters = parameters,
      _kind = kind,
      _isFunctionTyped = isFunctionTyped,
      _isInitializingFormal = isInitializingFormal,
      _hasImplicitType = hasImplicitType;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    fb.Offset offset_type;
    fb.Offset offset_parameters;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_type != null) {
      offset_type = _type.finish(fbBuilder);
    }
    if (!(_parameters == null || _parameters.isEmpty)) {
      offset_parameters = fbBuilder.writeList(_parameters.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_type != null) {
      fbBuilder.addOffset(2, offset_type);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(3, offset_parameters);
    }
    if (_kind != null && _kind != UnlinkedParamKind.required) {
      fbBuilder.addUint32(4, _kind.index);
    }
    if (_isFunctionTyped == true) {
      fbBuilder.addBool(5, true);
    }
    if (_isInitializingFormal == true) {
      fbBuilder.addBool(6, true);
    }
    if (_hasImplicitType == true) {
      fbBuilder.addBool(7, true);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a function parameter.
 */
abstract class UnlinkedParam extends base.SummaryClass {

  /**
   * Name of the parameter.
   */
  String get name;

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  int get nameOffset;

  /**
   * If [isFunctionTyped] is `true`, the declared return type.  If
   * [isFunctionTyped] is `false`, the declared type.  Absent if
   * [isFunctionTyped] is `true` and the declared return type is `void`.  Note
   * that when strong mode is enabled, the actual type may be different due to
   * type inference.
   */
  TypeRef get type;

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  List<UnlinkedParam> get parameters;

  /**
   * Kind of the parameter.
   */
  UnlinkedParamKind get kind;

  /**
   * Indicates whether this is a function-typed parameter.
   */
  bool get isFunctionTyped;

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  bool get isInitializingFormal;

  /**
   * Indicates whether this parameter lacks an explicit type declaration.
   * Always false for a function-typed parameter.
   */
  bool get hasImplicitType;
}

class _UnlinkedParamReader extends fb.TableReader<_UnlinkedParamImpl> {
  const _UnlinkedParamReader();

  @override
  _UnlinkedParamImpl createObject(fb.BufferPointer bp) => new _UnlinkedParamImpl(bp);
}

class _UnlinkedParamImpl extends Object with _UnlinkedParamMixin implements UnlinkedParam {
  final fb.BufferPointer _bp;

  _UnlinkedParamImpl(this._bp);

  String _name;
  int _nameOffset;
  TypeRef _type;
  List<UnlinkedParam> _parameters;
  UnlinkedParamKind _kind;
  bool _isFunctionTyped;
  bool _isInitializingFormal;
  bool _hasImplicitType;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  TypeRef get type {
    _type ??= const _TypeRefReader().vTableGet(_bp, 2, null);
    return _type;
  }

  @override
  List<UnlinkedParam> get parameters {
    _parameters ??= const fb.ListReader<UnlinkedParam>(const _UnlinkedParamReader()).vTableGet(_bp, 3, const <UnlinkedParam>[]);
    return _parameters;
  }

  @override
  UnlinkedParamKind get kind {
    _kind ??= const _UnlinkedParamKindReader().vTableGet(_bp, 4, UnlinkedParamKind.required);
    return _kind;
  }

  @override
  bool get isFunctionTyped {
    _isFunctionTyped ??= const fb.BoolReader().vTableGet(_bp, 5, false);
    return _isFunctionTyped;
  }

  @override
  bool get isInitializingFormal {
    _isInitializingFormal ??= const fb.BoolReader().vTableGet(_bp, 6, false);
    return _isInitializingFormal;
  }

  @override
  bool get hasImplicitType {
    _hasImplicitType ??= const fb.BoolReader().vTableGet(_bp, 7, false);
    return _hasImplicitType;
  }
}

abstract class _UnlinkedParamMixin implements UnlinkedParam {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "type": type,
    "parameters": parameters,
    "kind": kind,
    "isFunctionTyped": isFunctionTyped,
    "isInitializingFormal": isInitializingFormal,
    "hasImplicitType": hasImplicitType,
  };
}

class UnlinkedPartBuilder extends Object with _UnlinkedPartMixin implements UnlinkedPart {
  bool _finished = false;

  int _uriOffset;
  int _uriEnd;

  @override
  int get uriOffset => _uriOffset ??= 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _uriOffset = _value;
  }

  @override
  int get uriEnd => _uriEnd ??= 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _uriEnd = _value;
  }

  UnlinkedPartBuilder({int uriOffset, int uriEnd})
    : _uriOffset = uriOffset,
      _uriEnd = uriEnd;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fbBuilder.startTable();
    if (_uriOffset != null && _uriOffset != 0) {
      fbBuilder.addUint32(0, _uriOffset);
    }
    if (_uriEnd != null && _uriEnd != 0) {
      fbBuilder.addUint32(1, _uriEnd);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a part declaration.
 */
abstract class UnlinkedPart extends base.SummaryClass {

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  int get uriOffset;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  int get uriEnd;
}

class _UnlinkedPartReader extends fb.TableReader<_UnlinkedPartImpl> {
  const _UnlinkedPartReader();

  @override
  _UnlinkedPartImpl createObject(fb.BufferPointer bp) => new _UnlinkedPartImpl(bp);
}

class _UnlinkedPartImpl extends Object with _UnlinkedPartMixin implements UnlinkedPart {
  final fb.BufferPointer _bp;

  _UnlinkedPartImpl(this._bp);

  int _uriOffset;
  int _uriEnd;

  @override
  int get uriOffset {
    _uriOffset ??= const fb.Uint32Reader().vTableGet(_bp, 0, 0);
    return _uriOffset;
  }

  @override
  int get uriEnd {
    _uriEnd ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _uriEnd;
  }
}

abstract class _UnlinkedPartMixin implements UnlinkedPart {
  @override
  Map<String, Object> toMap() => {
    "uriOffset": uriOffset,
    "uriEnd": uriEnd,
  };
}

class UnlinkedPublicNameBuilder extends Object with _UnlinkedPublicNameMixin implements UnlinkedPublicName {
  bool _finished = false;

  String _name;
  ReferenceKind _kind;
  int _numTypeParameters;

  @override
  String get name => _name ??= '';

  /**
   * The name itself.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  ReferenceKind get kind => _kind ??= ReferenceKind.classOrEnum;

  /**
   * The kind of object referred to by the name.
   */
  void set kind(ReferenceKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  @override
  int get numTypeParameters => _numTypeParameters ??= 0;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  void set numTypeParameters(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _numTypeParameters = _value;
  }

  UnlinkedPublicNameBuilder({String name, ReferenceKind kind, int numTypeParameters})
    : _name = name,
      _kind = kind,
      _numTypeParameters = numTypeParameters;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_kind != null && _kind != ReferenceKind.classOrEnum) {
      fbBuilder.addUint32(1, _kind.index);
    }
    if (_numTypeParameters != null && _numTypeParameters != 0) {
      fbBuilder.addUint32(2, _numTypeParameters);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a specific name contributed by a
 * compilation unit to a library's public namespace.
 *
 * TODO(paulberry): add a count of generic parameters, so that resynthesis
 * doesn't have to peek into the library to obtain this info.
 *
 * TODO(paulberry): for classes, add info about static members and
 * constructors, since this will be needed to prelink info about constants.
 *
 * TODO(paulberry): some of this information is redundant with information
 * elsewhere in the summary.  Consider reducing the redundancy to reduce
 * summary size.
 */
abstract class UnlinkedPublicName extends base.SummaryClass {

  /**
   * The name itself.
   */
  String get name;

  /**
   * The kind of object referred to by the name.
   */
  ReferenceKind get kind;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int get numTypeParameters;
}

class _UnlinkedPublicNameReader extends fb.TableReader<_UnlinkedPublicNameImpl> {
  const _UnlinkedPublicNameReader();

  @override
  _UnlinkedPublicNameImpl createObject(fb.BufferPointer bp) => new _UnlinkedPublicNameImpl(bp);
}

class _UnlinkedPublicNameImpl extends Object with _UnlinkedPublicNameMixin implements UnlinkedPublicName {
  final fb.BufferPointer _bp;

  _UnlinkedPublicNameImpl(this._bp);

  String _name;
  ReferenceKind _kind;
  int _numTypeParameters;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  ReferenceKind get kind {
    _kind ??= const _ReferenceKindReader().vTableGet(_bp, 1, ReferenceKind.classOrEnum);
    return _kind;
  }

  @override
  int get numTypeParameters {
    _numTypeParameters ??= const fb.Uint32Reader().vTableGet(_bp, 2, 0);
    return _numTypeParameters;
  }
}

abstract class _UnlinkedPublicNameMixin implements UnlinkedPublicName {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "kind": kind,
    "numTypeParameters": numTypeParameters,
  };
}

class UnlinkedPublicNamespaceBuilder extends Object with _UnlinkedPublicNamespaceMixin implements UnlinkedPublicNamespace {
  bool _finished = false;

  List<UnlinkedPublicNameBuilder> _names;
  List<UnlinkedExportPublicBuilder> _exports;
  List<String> _parts;

  @override
  List<UnlinkedPublicNameBuilder> get names => _names ??= <UnlinkedPublicNameBuilder>[];

  /**
   * Public names defined in the compilation unit.
   *
   * TODO(paulberry): consider sorting these names to reduce unnecessary
   * relinking.
   */
  void set names(List<UnlinkedPublicNameBuilder> _value) {
    assert(!_finished);
    _names = _value;
  }

  @override
  List<UnlinkedExportPublicBuilder> get exports => _exports ??= <UnlinkedExportPublicBuilder>[];

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportPublicBuilder> _value) {
    assert(!_finished);
    _exports = _value;
  }

  @override
  List<String> get parts => _parts ??= <String>[];

  /**
   * URIs referenced by part declarations in the compilation unit.
   */
  void set parts(List<String> _value) {
    assert(!_finished);
    _parts = _value;
  }

  UnlinkedPublicNamespaceBuilder({List<UnlinkedPublicNameBuilder> names, List<UnlinkedExportPublicBuilder> exports, List<String> parts})
    : _names = names,
      _exports = exports,
      _parts = parts;

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder));
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_names;
    fb.Offset offset_exports;
    fb.Offset offset_parts;
    if (!(_names == null || _names.isEmpty)) {
      offset_names = fbBuilder.writeList(_names.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder.writeList(_exports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_parts == null || _parts.isEmpty)) {
      offset_parts = fbBuilder.writeList(_parts.map((b) => fbBuilder.writeString(b)).toList());
    }
    fbBuilder.startTable();
    if (offset_names != null) {
      fbBuilder.addOffset(0, offset_names);
    }
    if (offset_exports != null) {
      fbBuilder.addOffset(1, offset_exports);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(2, offset_parts);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about what a compilation unit contributes to a
 * library's public namespace.  This is the subset of [UnlinkedUnit] that is
 * required from dependent libraries in order to perform prelinking.
 */
abstract class UnlinkedPublicNamespace extends base.SummaryClass {
  factory UnlinkedPublicNamespace.fromBuffer(List<int> buffer) {
    fb.BufferPointer rootRef = new fb.BufferPointer.fromBytes(buffer);
    return const _UnlinkedPublicNamespaceReader().read(rootRef);
  }

  /**
   * Public names defined in the compilation unit.
   *
   * TODO(paulberry): consider sorting these names to reduce unnecessary
   * relinking.
   */
  List<UnlinkedPublicName> get names;

  /**
   * Export declarations in the compilation unit.
   */
  List<UnlinkedExportPublic> get exports;

  /**
   * URIs referenced by part declarations in the compilation unit.
   */
  List<String> get parts;
}

class _UnlinkedPublicNamespaceReader extends fb.TableReader<_UnlinkedPublicNamespaceImpl> {
  const _UnlinkedPublicNamespaceReader();

  @override
  _UnlinkedPublicNamespaceImpl createObject(fb.BufferPointer bp) => new _UnlinkedPublicNamespaceImpl(bp);
}

class _UnlinkedPublicNamespaceImpl extends Object with _UnlinkedPublicNamespaceMixin implements UnlinkedPublicNamespace {
  final fb.BufferPointer _bp;

  _UnlinkedPublicNamespaceImpl(this._bp);

  List<UnlinkedPublicName> _names;
  List<UnlinkedExportPublic> _exports;
  List<String> _parts;

  @override
  List<UnlinkedPublicName> get names {
    _names ??= const fb.ListReader<UnlinkedPublicName>(const _UnlinkedPublicNameReader()).vTableGet(_bp, 0, const <UnlinkedPublicName>[]);
    return _names;
  }

  @override
  List<UnlinkedExportPublic> get exports {
    _exports ??= const fb.ListReader<UnlinkedExportPublic>(const _UnlinkedExportPublicReader()).vTableGet(_bp, 1, const <UnlinkedExportPublic>[]);
    return _exports;
  }

  @override
  List<String> get parts {
    _parts ??= const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 2, const <String>[]);
    return _parts;
  }
}

abstract class _UnlinkedPublicNamespaceMixin implements UnlinkedPublicNamespace {
  @override
  Map<String, Object> toMap() => {
    "names": names,
    "exports": exports,
    "parts": parts,
  };
}

class UnlinkedReferenceBuilder extends Object with _UnlinkedReferenceMixin implements UnlinkedReference {
  bool _finished = false;

  String _name;
  int _prefixReference;

  @override
  String get name => _name ??= '';

  /**
   * Name of the entity being referred to.  The empty string refers to the
   * pseudo-type `dynamic`.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get prefixReference => _prefixReference ??= 0;

  /**
   * Prefix used to refer to the entity, or zero if no prefix is used.  This is
   * an index into [UnlinkedUnit.references].
   *
   * Prefix references must always point backward; that is, for all i, if
   * UnlinkedUnit.references[i].prefixReference != 0, then
   * UnlinkedUnit.references[i].prefixReference < i.
   */
  void set prefixReference(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _prefixReference = _value;
  }

  UnlinkedReferenceBuilder({String name, int prefixReference})
    : _name = name,
      _prefixReference = prefixReference;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_prefixReference != null && _prefixReference != 0) {
      fbBuilder.addUint32(1, _prefixReference);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a name referred to in one library that
 * might be defined in another.
 */
abstract class UnlinkedReference extends base.SummaryClass {

  /**
   * Name of the entity being referred to.  The empty string refers to the
   * pseudo-type `dynamic`.
   */
  String get name;

  /**
   * Prefix used to refer to the entity, or zero if no prefix is used.  This is
   * an index into [UnlinkedUnit.references].
   *
   * Prefix references must always point backward; that is, for all i, if
   * UnlinkedUnit.references[i].prefixReference != 0, then
   * UnlinkedUnit.references[i].prefixReference < i.
   */
  int get prefixReference;
}

class _UnlinkedReferenceReader extends fb.TableReader<_UnlinkedReferenceImpl> {
  const _UnlinkedReferenceReader();

  @override
  _UnlinkedReferenceImpl createObject(fb.BufferPointer bp) => new _UnlinkedReferenceImpl(bp);
}

class _UnlinkedReferenceImpl extends Object with _UnlinkedReferenceMixin implements UnlinkedReference {
  final fb.BufferPointer _bp;

  _UnlinkedReferenceImpl(this._bp);

  String _name;
  int _prefixReference;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get prefixReference {
    _prefixReference ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _prefixReference;
  }
}

abstract class _UnlinkedReferenceMixin implements UnlinkedReference {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "prefixReference": prefixReference,
  };
}

class UnlinkedTypedefBuilder extends Object with _UnlinkedTypedefMixin implements UnlinkedTypedef {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  List<UnlinkedTypeParamBuilder> _typeParameters;
  TypeRefBuilder _returnType;
  List<UnlinkedParamBuilder> _parameters;

  @override
  String get name => _name ??= '';

  /**
   * Name of the typedef.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment => _documentationComment;

  /**
   * Documentation comment for the typedef, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  List<UnlinkedTypeParamBuilder> get typeParameters => _typeParameters ??= <UnlinkedTypeParamBuilder>[];

  /**
   * Type parameters of the typedef, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    _typeParameters = _value;
  }

  @override
  TypeRefBuilder get returnType => _returnType;

  /**
   * Return type of the typedef.  Absent if the return type is `void`.
   */
  void set returnType(TypeRefBuilder _value) {
    assert(!_finished);
    _returnType = _value;
  }

  @override
  List<UnlinkedParamBuilder> get parameters => _parameters ??= <UnlinkedParamBuilder>[];

  /**
   * Parameters of the executable, if any.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    _parameters = _value;
  }

  UnlinkedTypedefBuilder({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedTypeParamBuilder> typeParameters, TypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters})
    : _name = name,
      _nameOffset = nameOffset,
      _documentationComment = documentationComment,
      _typeParameters = typeParameters,
      _returnType = returnType,
      _parameters = parameters;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    fb.Offset offset_documentationComment;
    fb.Offset offset_typeParameters;
    fb.Offset offset_returnType;
    fb.Offset offset_parameters;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (!(_typeParameters == null || _typeParameters.isEmpty)) {
      offset_typeParameters = fbBuilder.writeList(_typeParameters.map((b) => b.finish(fbBuilder)).toList());
    }
    if (_returnType != null) {
      offset_returnType = _returnType.finish(fbBuilder);
    }
    if (!(_parameters == null || _parameters.isEmpty)) {
      offset_parameters = fbBuilder.writeList(_parameters.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(2, offset_documentationComment);
    }
    if (offset_typeParameters != null) {
      fbBuilder.addOffset(3, offset_typeParameters);
    }
    if (offset_returnType != null) {
      fbBuilder.addOffset(4, offset_returnType);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(5, offset_parameters);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a typedef declaration.
 */
abstract class UnlinkedTypedef extends base.SummaryClass {

  /**
   * Name of the typedef.
   */
  String get name;

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  int get nameOffset;

  /**
   * Documentation comment for the typedef, or `null` if there is no
   * documentation comment.
   */
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Type parameters of the typedef, if any.
   */
  List<UnlinkedTypeParam> get typeParameters;

  /**
   * Return type of the typedef.  Absent if the return type is `void`.
   */
  TypeRef get returnType;

  /**
   * Parameters of the executable, if any.
   */
  List<UnlinkedParam> get parameters;
}

class _UnlinkedTypedefReader extends fb.TableReader<_UnlinkedTypedefImpl> {
  const _UnlinkedTypedefReader();

  @override
  _UnlinkedTypedefImpl createObject(fb.BufferPointer bp) => new _UnlinkedTypedefImpl(bp);
}

class _UnlinkedTypedefImpl extends Object with _UnlinkedTypedefMixin implements UnlinkedTypedef {
  final fb.BufferPointer _bp;

  _UnlinkedTypedefImpl(this._bp);

  String _name;
  int _nameOffset;
  UnlinkedDocumentationComment _documentationComment;
  List<UnlinkedTypeParam> _typeParameters;
  TypeRef _returnType;
  List<UnlinkedParam> _parameters;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);
    return _documentationComment;
  }

  @override
  List<UnlinkedTypeParam> get typeParameters {
    _typeParameters ??= const fb.ListReader<UnlinkedTypeParam>(const _UnlinkedTypeParamReader()).vTableGet(_bp, 3, const <UnlinkedTypeParam>[]);
    return _typeParameters;
  }

  @override
  TypeRef get returnType {
    _returnType ??= const _TypeRefReader().vTableGet(_bp, 4, null);
    return _returnType;
  }

  @override
  List<UnlinkedParam> get parameters {
    _parameters ??= const fb.ListReader<UnlinkedParam>(const _UnlinkedParamReader()).vTableGet(_bp, 5, const <UnlinkedParam>[]);
    return _parameters;
  }
}

abstract class _UnlinkedTypedefMixin implements UnlinkedTypedef {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
    "typeParameters": typeParameters,
    "returnType": returnType,
    "parameters": parameters,
  };
}

class UnlinkedTypeParamBuilder extends Object with _UnlinkedTypeParamMixin implements UnlinkedTypeParam {
  bool _finished = false;

  String _name;
  int _nameOffset;
  TypeRefBuilder _bound;

  @override
  String get name => _name ??= '';

  /**
   * Name of the type parameter.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _nameOffset = _value;
  }

  @override
  TypeRefBuilder get bound => _bound;

  /**
   * Bound of the type parameter, if a bound is explicitly declared.  Otherwise
   * null.
   */
  void set bound(TypeRefBuilder _value) {
    assert(!_finished);
    _bound = _value;
  }

  UnlinkedTypeParamBuilder({String name, int nameOffset, TypeRefBuilder bound})
    : _name = name,
      _nameOffset = nameOffset,
      _bound = bound;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    fb.Offset offset_bound;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_bound != null) {
      offset_bound = _bound.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_bound != null) {
      fbBuilder.addOffset(2, offset_bound);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a type parameter declaration.
 */
abstract class UnlinkedTypeParam extends base.SummaryClass {

  /**
   * Name of the type parameter.
   */
  String get name;

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  int get nameOffset;

  /**
   * Bound of the type parameter, if a bound is explicitly declared.  Otherwise
   * null.
   */
  TypeRef get bound;
}

class _UnlinkedTypeParamReader extends fb.TableReader<_UnlinkedTypeParamImpl> {
  const _UnlinkedTypeParamReader();

  @override
  _UnlinkedTypeParamImpl createObject(fb.BufferPointer bp) => new _UnlinkedTypeParamImpl(bp);
}

class _UnlinkedTypeParamImpl extends Object with _UnlinkedTypeParamMixin implements UnlinkedTypeParam {
  final fb.BufferPointer _bp;

  _UnlinkedTypeParamImpl(this._bp);

  String _name;
  int _nameOffset;
  TypeRef _bound;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  TypeRef get bound {
    _bound ??= const _TypeRefReader().vTableGet(_bp, 2, null);
    return _bound;
  }
}

abstract class _UnlinkedTypeParamMixin implements UnlinkedTypeParam {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "bound": bound,
  };
}

class UnlinkedUnitBuilder extends Object with _UnlinkedUnitMixin implements UnlinkedUnit {
  bool _finished = false;

  String _libraryName;
  int _libraryNameOffset;
  int _libraryNameLength;
  UnlinkedDocumentationCommentBuilder _libraryDocumentationComment;
  UnlinkedPublicNamespaceBuilder _publicNamespace;
  List<UnlinkedReferenceBuilder> _references;
  List<UnlinkedClassBuilder> _classes;
  List<UnlinkedEnumBuilder> _enums;
  List<UnlinkedExecutableBuilder> _executables;
  List<UnlinkedExportNonPublicBuilder> _exports;
  List<UnlinkedImportBuilder> _imports;
  List<UnlinkedPartBuilder> _parts;
  List<UnlinkedTypedefBuilder> _typedefs;
  List<UnlinkedVariableBuilder> _variables;

  @override
  String get libraryName => _libraryName ??= '';

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  void set libraryName(String _value) {
    assert(!_finished);
    _libraryName = _value;
  }

  @override
  int get libraryNameOffset => _libraryNameOffset ??= 0;

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  void set libraryNameOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _libraryNameOffset = _value;
  }

  @override
  int get libraryNameLength => _libraryNameLength ??= 0;

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  void set libraryNameLength(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _libraryNameLength = _value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get libraryDocumentationComment => _libraryDocumentationComment;

  /**
   * Documentation comment for the library, or `null` if there is no
   * documentation comment.
   */
  void set libraryDocumentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _libraryDocumentationComment = _value;
  }

  @override
  UnlinkedPublicNamespaceBuilder get publicNamespace => _publicNamespace;

  /**
   * Unlinked public namespace of this compilation unit.
   */
  void set publicNamespace(UnlinkedPublicNamespaceBuilder _value) {
    assert(!_finished);
    _publicNamespace = _value;
  }

  @override
  List<UnlinkedReferenceBuilder> get references => _references ??= <UnlinkedReferenceBuilder>[];

  /**
   * Top level and prefixed names referred to by this compilation unit.  The
   * zeroth element of this array is always populated and always represents a
   * reference to the pseudo-type "dynamic".
   */
  void set references(List<UnlinkedReferenceBuilder> _value) {
    assert(!_finished);
    _references = _value;
  }

  @override
  List<UnlinkedClassBuilder> get classes => _classes ??= <UnlinkedClassBuilder>[];

  /**
   * Classes declared in the compilation unit.
   */
  void set classes(List<UnlinkedClassBuilder> _value) {
    assert(!_finished);
    _classes = _value;
  }

  @override
  List<UnlinkedEnumBuilder> get enums => _enums ??= <UnlinkedEnumBuilder>[];

  /**
   * Enums declared in the compilation unit.
   */
  void set enums(List<UnlinkedEnumBuilder> _value) {
    assert(!_finished);
    _enums = _value;
  }

  @override
  List<UnlinkedExecutableBuilder> get executables => _executables ??= <UnlinkedExecutableBuilder>[];

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    _executables = _value;
  }

  @override
  List<UnlinkedExportNonPublicBuilder> get exports => _exports ??= <UnlinkedExportNonPublicBuilder>[];

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportNonPublicBuilder> _value) {
    assert(!_finished);
    _exports = _value;
  }

  @override
  List<UnlinkedImportBuilder> get imports => _imports ??= <UnlinkedImportBuilder>[];

  /**
   * Import declarations in the compilation unit.
   */
  void set imports(List<UnlinkedImportBuilder> _value) {
    assert(!_finished);
    _imports = _value;
  }

  @override
  List<UnlinkedPartBuilder> get parts => _parts ??= <UnlinkedPartBuilder>[];

  /**
   * Part declarations in the compilation unit.
   */
  void set parts(List<UnlinkedPartBuilder> _value) {
    assert(!_finished);
    _parts = _value;
  }

  @override
  List<UnlinkedTypedefBuilder> get typedefs => _typedefs ??= <UnlinkedTypedefBuilder>[];

  /**
   * Typedefs declared in the compilation unit.
   */
  void set typedefs(List<UnlinkedTypedefBuilder> _value) {
    assert(!_finished);
    _typedefs = _value;
  }

  @override
  List<UnlinkedVariableBuilder> get variables => _variables ??= <UnlinkedVariableBuilder>[];

  /**
   * Top level variables declared in the compilation unit.
   */
  void set variables(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    _variables = _value;
  }

  UnlinkedUnitBuilder({String libraryName, int libraryNameOffset, int libraryNameLength, UnlinkedDocumentationCommentBuilder libraryDocumentationComment, UnlinkedPublicNamespaceBuilder publicNamespace, List<UnlinkedReferenceBuilder> references, List<UnlinkedClassBuilder> classes, List<UnlinkedEnumBuilder> enums, List<UnlinkedExecutableBuilder> executables, List<UnlinkedExportNonPublicBuilder> exports, List<UnlinkedImportBuilder> imports, List<UnlinkedPartBuilder> parts, List<UnlinkedTypedefBuilder> typedefs, List<UnlinkedVariableBuilder> variables})
    : _libraryName = libraryName,
      _libraryNameOffset = libraryNameOffset,
      _libraryNameLength = libraryNameLength,
      _libraryDocumentationComment = libraryDocumentationComment,
      _publicNamespace = publicNamespace,
      _references = references,
      _classes = classes,
      _enums = enums,
      _executables = executables,
      _exports = exports,
      _imports = imports,
      _parts = parts,
      _typedefs = typedefs,
      _variables = variables;

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder));
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_libraryName;
    fb.Offset offset_libraryDocumentationComment;
    fb.Offset offset_publicNamespace;
    fb.Offset offset_references;
    fb.Offset offset_classes;
    fb.Offset offset_enums;
    fb.Offset offset_executables;
    fb.Offset offset_exports;
    fb.Offset offset_imports;
    fb.Offset offset_parts;
    fb.Offset offset_typedefs;
    fb.Offset offset_variables;
    if (_libraryName != null) {
      offset_libraryName = fbBuilder.writeString(_libraryName);
    }
    if (_libraryDocumentationComment != null) {
      offset_libraryDocumentationComment = _libraryDocumentationComment.finish(fbBuilder);
    }
    if (_publicNamespace != null) {
      offset_publicNamespace = _publicNamespace.finish(fbBuilder);
    }
    if (!(_references == null || _references.isEmpty)) {
      offset_references = fbBuilder.writeList(_references.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_classes == null || _classes.isEmpty)) {
      offset_classes = fbBuilder.writeList(_classes.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_enums == null || _enums.isEmpty)) {
      offset_enums = fbBuilder.writeList(_enums.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_executables == null || _executables.isEmpty)) {
      offset_executables = fbBuilder.writeList(_executables.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_exports == null || _exports.isEmpty)) {
      offset_exports = fbBuilder.writeList(_exports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_imports == null || _imports.isEmpty)) {
      offset_imports = fbBuilder.writeList(_imports.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_parts == null || _parts.isEmpty)) {
      offset_parts = fbBuilder.writeList(_parts.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_typedefs == null || _typedefs.isEmpty)) {
      offset_typedefs = fbBuilder.writeList(_typedefs.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_variables == null || _variables.isEmpty)) {
      offset_variables = fbBuilder.writeList(_variables.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_libraryName != null) {
      fbBuilder.addOffset(0, offset_libraryName);
    }
    if (_libraryNameOffset != null && _libraryNameOffset != 0) {
      fbBuilder.addUint32(1, _libraryNameOffset);
    }
    if (_libraryNameLength != null && _libraryNameLength != 0) {
      fbBuilder.addUint32(2, _libraryNameLength);
    }
    if (offset_libraryDocumentationComment != null) {
      fbBuilder.addOffset(3, offset_libraryDocumentationComment);
    }
    if (offset_publicNamespace != null) {
      fbBuilder.addOffset(4, offset_publicNamespace);
    }
    if (offset_references != null) {
      fbBuilder.addOffset(5, offset_references);
    }
    if (offset_classes != null) {
      fbBuilder.addOffset(6, offset_classes);
    }
    if (offset_enums != null) {
      fbBuilder.addOffset(7, offset_enums);
    }
    if (offset_executables != null) {
      fbBuilder.addOffset(8, offset_executables);
    }
    if (offset_exports != null) {
      fbBuilder.addOffset(9, offset_exports);
    }
    if (offset_imports != null) {
      fbBuilder.addOffset(10, offset_imports);
    }
    if (offset_parts != null) {
      fbBuilder.addOffset(11, offset_parts);
    }
    if (offset_typedefs != null) {
      fbBuilder.addOffset(12, offset_typedefs);
    }
    if (offset_variables != null) {
      fbBuilder.addOffset(13, offset_variables);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a compilation unit ("part file").
 */
abstract class UnlinkedUnit extends base.SummaryClass {
  factory UnlinkedUnit.fromBuffer(List<int> buffer) {
    fb.BufferPointer rootRef = new fb.BufferPointer.fromBytes(buffer);
    return const _UnlinkedUnitReader().read(rootRef);
  }

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  String get libraryName;

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  int get libraryNameOffset;

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  int get libraryNameLength;

  /**
   * Documentation comment for the library, or `null` if there is no
   * documentation comment.
   */
  UnlinkedDocumentationComment get libraryDocumentationComment;

  /**
   * Unlinked public namespace of this compilation unit.
   */
  UnlinkedPublicNamespace get publicNamespace;

  /**
   * Top level and prefixed names referred to by this compilation unit.  The
   * zeroth element of this array is always populated and always represents a
   * reference to the pseudo-type "dynamic".
   */
  List<UnlinkedReference> get references;

  /**
   * Classes declared in the compilation unit.
   */
  List<UnlinkedClass> get classes;

  /**
   * Enums declared in the compilation unit.
   */
  List<UnlinkedEnum> get enums;

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  List<UnlinkedExecutable> get executables;

  /**
   * Export declarations in the compilation unit.
   */
  List<UnlinkedExportNonPublic> get exports;

  /**
   * Import declarations in the compilation unit.
   */
  List<UnlinkedImport> get imports;

  /**
   * Part declarations in the compilation unit.
   */
  List<UnlinkedPart> get parts;

  /**
   * Typedefs declared in the compilation unit.
   */
  List<UnlinkedTypedef> get typedefs;

  /**
   * Top level variables declared in the compilation unit.
   */
  List<UnlinkedVariable> get variables;
}

class _UnlinkedUnitReader extends fb.TableReader<_UnlinkedUnitImpl> {
  const _UnlinkedUnitReader();

  @override
  _UnlinkedUnitImpl createObject(fb.BufferPointer bp) => new _UnlinkedUnitImpl(bp);
}

class _UnlinkedUnitImpl extends Object with _UnlinkedUnitMixin implements UnlinkedUnit {
  final fb.BufferPointer _bp;

  _UnlinkedUnitImpl(this._bp);

  String _libraryName;
  int _libraryNameOffset;
  int _libraryNameLength;
  UnlinkedDocumentationComment _libraryDocumentationComment;
  UnlinkedPublicNamespace _publicNamespace;
  List<UnlinkedReference> _references;
  List<UnlinkedClass> _classes;
  List<UnlinkedEnum> _enums;
  List<UnlinkedExecutable> _executables;
  List<UnlinkedExportNonPublic> _exports;
  List<UnlinkedImport> _imports;
  List<UnlinkedPart> _parts;
  List<UnlinkedTypedef> _typedefs;
  List<UnlinkedVariable> _variables;

  @override
  String get libraryName {
    _libraryName ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _libraryName;
  }

  @override
  int get libraryNameOffset {
    _libraryNameOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _libraryNameOffset;
  }

  @override
  int get libraryNameLength {
    _libraryNameLength ??= const fb.Uint32Reader().vTableGet(_bp, 2, 0);
    return _libraryNameLength;
  }

  @override
  UnlinkedDocumentationComment get libraryDocumentationComment {
    _libraryDocumentationComment ??= const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 3, null);
    return _libraryDocumentationComment;
  }

  @override
  UnlinkedPublicNamespace get publicNamespace {
    _publicNamespace ??= const _UnlinkedPublicNamespaceReader().vTableGet(_bp, 4, null);
    return _publicNamespace;
  }

  @override
  List<UnlinkedReference> get references {
    _references ??= const fb.ListReader<UnlinkedReference>(const _UnlinkedReferenceReader()).vTableGet(_bp, 5, const <UnlinkedReference>[]);
    return _references;
  }

  @override
  List<UnlinkedClass> get classes {
    _classes ??= const fb.ListReader<UnlinkedClass>(const _UnlinkedClassReader()).vTableGet(_bp, 6, const <UnlinkedClass>[]);
    return _classes;
  }

  @override
  List<UnlinkedEnum> get enums {
    _enums ??= const fb.ListReader<UnlinkedEnum>(const _UnlinkedEnumReader()).vTableGet(_bp, 7, const <UnlinkedEnum>[]);
    return _enums;
  }

  @override
  List<UnlinkedExecutable> get executables {
    _executables ??= const fb.ListReader<UnlinkedExecutable>(const _UnlinkedExecutableReader()).vTableGet(_bp, 8, const <UnlinkedExecutable>[]);
    return _executables;
  }

  @override
  List<UnlinkedExportNonPublic> get exports {
    _exports ??= const fb.ListReader<UnlinkedExportNonPublic>(const _UnlinkedExportNonPublicReader()).vTableGet(_bp, 9, const <UnlinkedExportNonPublic>[]);
    return _exports;
  }

  @override
  List<UnlinkedImport> get imports {
    _imports ??= const fb.ListReader<UnlinkedImport>(const _UnlinkedImportReader()).vTableGet(_bp, 10, const <UnlinkedImport>[]);
    return _imports;
  }

  @override
  List<UnlinkedPart> get parts {
    _parts ??= const fb.ListReader<UnlinkedPart>(const _UnlinkedPartReader()).vTableGet(_bp, 11, const <UnlinkedPart>[]);
    return _parts;
  }

  @override
  List<UnlinkedTypedef> get typedefs {
    _typedefs ??= const fb.ListReader<UnlinkedTypedef>(const _UnlinkedTypedefReader()).vTableGet(_bp, 12, const <UnlinkedTypedef>[]);
    return _typedefs;
  }

  @override
  List<UnlinkedVariable> get variables {
    _variables ??= const fb.ListReader<UnlinkedVariable>(const _UnlinkedVariableReader()).vTableGet(_bp, 13, const <UnlinkedVariable>[]);
    return _variables;
  }
}

abstract class _UnlinkedUnitMixin implements UnlinkedUnit {
  @override
  Map<String, Object> toMap() => {
    "libraryName": libraryName,
    "libraryNameOffset": libraryNameOffset,
    "libraryNameLength": libraryNameLength,
    "libraryDocumentationComment": libraryDocumentationComment,
    "publicNamespace": publicNamespace,
    "references": references,
    "classes": classes,
    "enums": enums,
    "executables": executables,
    "exports": exports,
    "imports": imports,
    "parts": parts,
    "typedefs": typedefs,
    "variables": variables,
  };
}

class UnlinkedVariableBuilder extends Object with _UnlinkedVariableMixin implements UnlinkedVariable {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  TypeRefBuilder _type;
  UnlinkedConstBuilder _constExpr;
  bool _isStatic;
  bool _isFinal;
  bool _isConst;
  bool _hasImplicitType;
  int _propagatedTypeSlot;

  @override
  String get name => _name ??= '';

  /**
   * Name of the variable.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ??= 0;

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationCommentBuilder get documentationComment => _documentationComment;

  /**
   * Documentation comment for the variable, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  TypeRefBuilder get type => _type;

  /**
   * Declared type of the variable.  Note that when strong mode is enabled, the
   * actual type of the variable may be different due to type inference.
   */
  void set type(TypeRefBuilder _value) {
    assert(!_finished);
    _type = _value;
  }

  @override
  UnlinkedConstBuilder get constExpr => _constExpr;

  /**
   * If [isConst] is true, and the variable has an initializer, the constant
   * expression in the initializer.
   */
  void set constExpr(UnlinkedConstBuilder _value) {
    assert(!_finished);
    _constExpr = _value;
  }

  @override
  bool get isStatic => _isStatic ??= false;

  /**
   * Indicates whether the variable is declared using the `static` keyword.
   *
   * Note that for top level variables, this flag is false, since they are not
   * declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  void set isStatic(bool _value) {
    assert(!_finished);
    _isStatic = _value;
  }

  @override
  bool get isFinal => _isFinal ??= false;

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  void set isFinal(bool _value) {
    assert(!_finished);
    _isFinal = _value;
  }

  @override
  bool get isConst => _isConst ??= false;

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  void set isConst(bool _value) {
    assert(!_finished);
    _isConst = _value;
  }

  @override
  bool get hasImplicitType => _hasImplicitType ??= false;

  /**
   * Indicates whether this variable lacks an explicit type declaration.
   */
  void set hasImplicitType(bool _value) {
    assert(!_finished);
    _hasImplicitType = _value;
  }

  @override
  int get propagatedTypeSlot => _propagatedTypeSlot ??= 0;

  /**
   * If this variable is propagable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the propagated type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then this variable's
   * propagated type is the same as its declared type.
   *
   * Non-propagable variables have a [propagatedTypeSlot] of zero.
   */
  void set propagatedTypeSlot(int _value) {
    assert(!_finished);
    assert(_value == null || _value >= 0);
    _propagatedTypeSlot = _value;
  }

  UnlinkedVariableBuilder({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, TypeRefBuilder type, UnlinkedConstBuilder constExpr, bool isStatic, bool isFinal, bool isConst, bool hasImplicitType, int propagatedTypeSlot})
    : _name = name,
      _nameOffset = nameOffset,
      _documentationComment = documentationComment,
      _type = type,
      _constExpr = constExpr,
      _isStatic = isStatic,
      _isFinal = isFinal,
      _isConst = isConst,
      _hasImplicitType = hasImplicitType,
      _propagatedTypeSlot = propagatedTypeSlot;

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    fb.Offset offset_documentationComment;
    fb.Offset offset_type;
    fb.Offset offset_constExpr;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (_type != null) {
      offset_type = _type.finish(fbBuilder);
    }
    if (_constExpr != null) {
      offset_constExpr = _constExpr.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addUint32(1, _nameOffset);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(2, offset_documentationComment);
    }
    if (offset_type != null) {
      fbBuilder.addOffset(3, offset_type);
    }
    if (offset_constExpr != null) {
      fbBuilder.addOffset(4, offset_constExpr);
    }
    if (_isStatic == true) {
      fbBuilder.addBool(5, true);
    }
    if (_isFinal == true) {
      fbBuilder.addBool(6, true);
    }
    if (_isConst == true) {
      fbBuilder.addBool(7, true);
    }
    if (_hasImplicitType == true) {
      fbBuilder.addBool(8, true);
    }
    if (_propagatedTypeSlot != null && _propagatedTypeSlot != 0) {
      fbBuilder.addUint32(9, _propagatedTypeSlot);
    }
    return fbBuilder.endTable();
  }
}

/**
 * Unlinked summary information about a top level variable, local variable, or
 * a field.
 */
abstract class UnlinkedVariable extends base.SummaryClass {

  /**
   * Name of the variable.
   */
  String get name;

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  int get nameOffset;

  /**
   * Documentation comment for the variable, or `null` if there is no
   * documentation comment.
   */
  UnlinkedDocumentationComment get documentationComment;

  /**
   * Declared type of the variable.  Note that when strong mode is enabled, the
   * actual type of the variable may be different due to type inference.
   */
  TypeRef get type;

  /**
   * If [isConst] is true, and the variable has an initializer, the constant
   * expression in the initializer.
   */
  UnlinkedConst get constExpr;

  /**
   * Indicates whether the variable is declared using the `static` keyword.
   *
   * Note that for top level variables, this flag is false, since they are not
   * declared using the `static` keyword (even though they are considered
   * static for semantic purposes).
   */
  bool get isStatic;

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  bool get isFinal;

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  bool get isConst;

  /**
   * Indicates whether this variable lacks an explicit type declaration.
   */
  bool get hasImplicitType;

  /**
   * If this variable is propagable, nonzero slot id identifying which entry in
   * [LinkedLibrary.types] contains the propagated type for this variable.  If
   * there is no matching entry in [LinkedLibrary.types], then this variable's
   * propagated type is the same as its declared type.
   *
   * Non-propagable variables have a [propagatedTypeSlot] of zero.
   */
  int get propagatedTypeSlot;
}

class _UnlinkedVariableReader extends fb.TableReader<_UnlinkedVariableImpl> {
  const _UnlinkedVariableReader();

  @override
  _UnlinkedVariableImpl createObject(fb.BufferPointer bp) => new _UnlinkedVariableImpl(bp);
}

class _UnlinkedVariableImpl extends Object with _UnlinkedVariableMixin implements UnlinkedVariable {
  final fb.BufferPointer _bp;

  _UnlinkedVariableImpl(this._bp);

  String _name;
  int _nameOffset;
  UnlinkedDocumentationComment _documentationComment;
  TypeRef _type;
  UnlinkedConst _constExpr;
  bool _isStatic;
  bool _isFinal;
  bool _isConst;
  bool _hasImplicitType;
  int _propagatedTypeSlot;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Uint32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);
    return _documentationComment;
  }

  @override
  TypeRef get type {
    _type ??= const _TypeRefReader().vTableGet(_bp, 3, null);
    return _type;
  }

  @override
  UnlinkedConst get constExpr {
    _constExpr ??= const _UnlinkedConstReader().vTableGet(_bp, 4, null);
    return _constExpr;
  }

  @override
  bool get isStatic {
    _isStatic ??= const fb.BoolReader().vTableGet(_bp, 5, false);
    return _isStatic;
  }

  @override
  bool get isFinal {
    _isFinal ??= const fb.BoolReader().vTableGet(_bp, 6, false);
    return _isFinal;
  }

  @override
  bool get isConst {
    _isConst ??= const fb.BoolReader().vTableGet(_bp, 7, false);
    return _isConst;
  }

  @override
  bool get hasImplicitType {
    _hasImplicitType ??= const fb.BoolReader().vTableGet(_bp, 8, false);
    return _hasImplicitType;
  }

  @override
  int get propagatedTypeSlot {
    _propagatedTypeSlot ??= const fb.Uint32Reader().vTableGet(_bp, 9, 0);
    return _propagatedTypeSlot;
  }
}

abstract class _UnlinkedVariableMixin implements UnlinkedVariable {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
    "type": type,
    "constExpr": constExpr,
    "isStatic": isStatic,
    "isFinal": isFinal,
    "isConst": isConst,
    "hasImplicitType": hasImplicitType,
    "propagatedTypeSlot": propagatedTypeSlot,
  };
}

