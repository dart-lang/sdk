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
 * [PrelinkedReference].
 */
enum PrelinkedReferenceKind {
  classOrEnum,
  typedef,
  other,
  prefix,
  unresolved,
}

/**
 * Enum used to indicate the kind of an executable.
 */
enum UnlinkedExecutableKind {
  functionOrMethod,
  getter,
  setter,
  constructor,
}

/**
 * Enum used to indicate the kind of a parameter.
 */
enum UnlinkedParamKind {
  required,
  positional,
  named,
}

class PrelinkedDependencyBuilder extends Object with _PrelinkedDependencyMixin implements PrelinkedDependency {
  bool _finished = false;

  String _uri;
  List<String> _parts;

  PrelinkedDependencyBuilder();

  @override
  String get uri => _uri ?? '';

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
  List<String> get parts => _parts ?? const <String>[];

  /**
   * URI for the compilation units listed in the library's `part` declarations.
   * These URIs are relative to the importing library.
   */
  void set parts(List<String> _value) {
    assert(!_finished);
    _parts = _value;
  }

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

PrelinkedDependencyBuilder encodePrelinkedDependency({String uri, List<String> parts}) {
  PrelinkedDependencyBuilder builder = new PrelinkedDependencyBuilder();
  builder.uri = uri;
  builder.parts = parts;
  return builder;
}

/**
 * Information about a dependency that exists between one library and another
 * due to an "import" declaration.
 */
abstract class PrelinkedDependency extends base.SummaryClass {

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

class _PrelinkedDependencyReader extends fb.TableReader<_PrelinkedDependencyImpl> {
  const _PrelinkedDependencyReader();

  @override
  _PrelinkedDependencyImpl createObject(fb.BufferPointer bp) => new _PrelinkedDependencyImpl(bp);
}

class _PrelinkedDependencyImpl extends Object with _PrelinkedDependencyMixin implements PrelinkedDependency {
  final fb.BufferPointer _bp;

  _PrelinkedDependencyImpl(this._bp);

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

abstract class _PrelinkedDependencyMixin implements PrelinkedDependency {
  @override
  Map<String, Object> toMap() => {
    "uri": uri,
    "parts": parts,
  };
}

class PrelinkedLibraryBuilder extends Object with _PrelinkedLibraryMixin implements PrelinkedLibrary {
  bool _finished = false;

  List<PrelinkedUnitBuilder> _units;
  List<PrelinkedDependencyBuilder> _dependencies;
  List<int> _importDependencies;

  PrelinkedLibraryBuilder();

  @override
  List<PrelinkedUnit> get units => _units ?? const <PrelinkedUnit>[];

  /**
   * The pre-linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  void set units(List<PrelinkedUnitBuilder> _value) {
    assert(!_finished);
    _units = _value;
  }

  @override
  List<PrelinkedDependency> get dependencies => _dependencies ?? const <PrelinkedDependency>[];

  /**
   * The libraries that this library depends on (either via an explicit import
   * statement or via the implicit dependencies on `dart:core` and
   * `dart:async`).  The first element of this array is a pseudo-dependency
   * representing the library itself (it is also used for "dynamic").
   *
   * TODO(paulberry): consider removing this entirely and just using
   * [UnlinkedLibrary.imports].
   */
  void set dependencies(List<PrelinkedDependencyBuilder> _value) {
    assert(!_finished);
    _dependencies = _value;
  }

  @override
  List<int> get importDependencies => _importDependencies ?? const <int>[];

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   *
   * TODO(paulberry): if [dependencies] is removed, this can be removed as
   * well, since there will effectively be a one-to-one mapping.
   */
  void set importDependencies(List<int> _value) {
    assert(!_finished);
    _importDependencies = _value;
  }

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
    if (!(_units == null || _units.isEmpty)) {
      offset_units = fbBuilder.writeList(_units.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_dependencies == null || _dependencies.isEmpty)) {
      offset_dependencies = fbBuilder.writeList(_dependencies.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_importDependencies == null || _importDependencies.isEmpty)) {
      offset_importDependencies = fbBuilder.writeListInt32(_importDependencies);
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
    return fbBuilder.endTable();
  }
}

PrelinkedLibraryBuilder encodePrelinkedLibrary({List<PrelinkedUnitBuilder> units, List<PrelinkedDependencyBuilder> dependencies, List<int> importDependencies}) {
  PrelinkedLibraryBuilder builder = new PrelinkedLibraryBuilder();
  builder.units = units;
  builder.dependencies = dependencies;
  builder.importDependencies = importDependencies;
  return builder;
}

/**
 * Pre-linked summary of a library.
 */
abstract class PrelinkedLibrary extends base.SummaryClass {
  factory PrelinkedLibrary.fromBuffer(List<int> buffer) {
    fb.BufferPointer rootRef = new fb.BufferPointer.fromBytes(buffer);
    return const _PrelinkedLibraryReader().read(rootRef);
  }

  /**
   * The pre-linked summary of all the compilation units constituting the
   * library.  The summary of the defining compilation unit is listed first,
   * followed by the summary of each part, in the order of the `part`
   * declarations in the defining compilation unit.
   */
  List<PrelinkedUnit> get units;

  /**
   * The libraries that this library depends on (either via an explicit import
   * statement or via the implicit dependencies on `dart:core` and
   * `dart:async`).  The first element of this array is a pseudo-dependency
   * representing the library itself (it is also used for "dynamic").
   *
   * TODO(paulberry): consider removing this entirely and just using
   * [UnlinkedLibrary.imports].
   */
  List<PrelinkedDependency> get dependencies;

  /**
   * For each import in [UnlinkedUnit.imports], an index into [dependencies]
   * of the library being imported.
   *
   * TODO(paulberry): if [dependencies] is removed, this can be removed as
   * well, since there will effectively be a one-to-one mapping.
   */
  List<int> get importDependencies;
}

class _PrelinkedLibraryReader extends fb.TableReader<_PrelinkedLibraryImpl> {
  const _PrelinkedLibraryReader();

  @override
  _PrelinkedLibraryImpl createObject(fb.BufferPointer bp) => new _PrelinkedLibraryImpl(bp);
}

class _PrelinkedLibraryImpl extends Object with _PrelinkedLibraryMixin implements PrelinkedLibrary {
  final fb.BufferPointer _bp;

  _PrelinkedLibraryImpl(this._bp);

  List<PrelinkedUnit> _units;
  List<PrelinkedDependency> _dependencies;
  List<int> _importDependencies;

  @override
  List<PrelinkedUnit> get units {
    _units ??= const fb.ListReader<PrelinkedUnit>(const _PrelinkedUnitReader()).vTableGet(_bp, 0, const <PrelinkedUnit>[]);
    return _units;
  }

  @override
  List<PrelinkedDependency> get dependencies {
    _dependencies ??= const fb.ListReader<PrelinkedDependency>(const _PrelinkedDependencyReader()).vTableGet(_bp, 1, const <PrelinkedDependency>[]);
    return _dependencies;
  }

  @override
  List<int> get importDependencies {
    _importDependencies ??= const fb.ListReader<int>(const fb.Int32Reader()).vTableGet(_bp, 2, const <int>[]);
    return _importDependencies;
  }
}

abstract class _PrelinkedLibraryMixin implements PrelinkedLibrary {
  @override
  Map<String, Object> toMap() => {
    "units": units,
    "dependencies": dependencies,
    "importDependencies": importDependencies,
  };
}

class PrelinkedReferenceBuilder extends Object with _PrelinkedReferenceMixin implements PrelinkedReference {
  bool _finished = false;

  int _dependency;
  PrelinkedReferenceKind _kind;
  int _unit;
  int _numTypeParameters;

  PrelinkedReferenceBuilder();

  @override
  int get dependency => _dependency ?? 0;

  /**
   * Index into [PrelinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  void set dependency(int _value) {
    assert(!_finished);
    _dependency = _value;
  }

  @override
  PrelinkedReferenceKind get kind => _kind ?? PrelinkedReferenceKind.classOrEnum;

  /**
   * The kind of the entity being referred to.  For the pseudo-type `dynamic`,
   * the kind is [PrelinkedReferenceKind.classOrEnum].
   */
  void set kind(PrelinkedReferenceKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  @override
  int get unit => _unit ?? 0;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [PrelinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  void set unit(int _value) {
    assert(!_finished);
    _unit = _value;
  }

  @override
  int get numTypeParameters => _numTypeParameters ?? 0;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  void set numTypeParameters(int _value) {
    assert(!_finished);
    _numTypeParameters = _value;
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fbBuilder.startTable();
    if (_dependency != null && _dependency != 0) {
      fbBuilder.addInt32(0, _dependency);
    }
    if (_kind != null && _kind != PrelinkedReferenceKind.classOrEnum) {
      fbBuilder.addInt32(1, _kind.index);
    }
    if (_unit != null && _unit != 0) {
      fbBuilder.addInt32(2, _unit);
    }
    if (_numTypeParameters != null && _numTypeParameters != 0) {
      fbBuilder.addInt32(3, _numTypeParameters);
    }
    return fbBuilder.endTable();
  }
}

PrelinkedReferenceBuilder encodePrelinkedReference({int dependency, PrelinkedReferenceKind kind, int unit, int numTypeParameters}) {
  PrelinkedReferenceBuilder builder = new PrelinkedReferenceBuilder();
  builder.dependency = dependency;
  builder.kind = kind;
  builder.unit = unit;
  builder.numTypeParameters = numTypeParameters;
  return builder;
}

/**
 * Information about the resolution of an [UnlinkedReference].
 */
abstract class PrelinkedReference extends base.SummaryClass {

  /**
   * Index into [PrelinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  int get dependency;

  /**
   * The kind of the entity being referred to.  For the pseudo-type `dynamic`,
   * the kind is [PrelinkedReferenceKind.classOrEnum].
   */
  PrelinkedReferenceKind get kind;

  /**
   * Integer index indicating which unit in the imported library contains the
   * definition of the entity.  As with indices into [PrelinkedLibrary.units],
   * zero represents the defining compilation unit, and nonzero values
   * represent parts in the order of the corresponding `part` declarations.
   */
  int get unit;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  int get numTypeParameters;
}

class _PrelinkedReferenceReader extends fb.TableReader<_PrelinkedReferenceImpl> {
  const _PrelinkedReferenceReader();

  @override
  _PrelinkedReferenceImpl createObject(fb.BufferPointer bp) => new _PrelinkedReferenceImpl(bp);
}

class _PrelinkedReferenceImpl extends Object with _PrelinkedReferenceMixin implements PrelinkedReference {
  final fb.BufferPointer _bp;

  _PrelinkedReferenceImpl(this._bp);

  int _dependency;
  PrelinkedReferenceKind _kind;
  int _unit;
  int _numTypeParameters;

  @override
  int get dependency {
    _dependency ??= const fb.Int32Reader().vTableGet(_bp, 0, 0);
    return _dependency;
  }

  @override
  PrelinkedReferenceKind get kind {
    _kind ??= PrelinkedReferenceKind.values[const fb.Int32Reader().vTableGet(_bp, 1, 0)];
    return _kind;
  }

  @override
  int get unit {
    _unit ??= const fb.Int32Reader().vTableGet(_bp, 2, 0);
    return _unit;
  }

  @override
  int get numTypeParameters {
    _numTypeParameters ??= const fb.Int32Reader().vTableGet(_bp, 3, 0);
    return _numTypeParameters;
  }
}

abstract class _PrelinkedReferenceMixin implements PrelinkedReference {
  @override
  Map<String, Object> toMap() => {
    "dependency": dependency,
    "kind": kind,
    "unit": unit,
    "numTypeParameters": numTypeParameters,
  };
}

class PrelinkedUnitBuilder extends Object with _PrelinkedUnitMixin implements PrelinkedUnit {
  bool _finished = false;

  List<PrelinkedReferenceBuilder> _references;

  PrelinkedUnitBuilder();

  @override
  List<PrelinkedReference> get references => _references ?? const <PrelinkedReference>[];

  /**
   * For each reference in [UnlinkedUnit.references], information about how
   * that reference is resolved.
   */
  void set references(List<PrelinkedReferenceBuilder> _value) {
    assert(!_finished);
    _references = _value;
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_references;
    if (!(_references == null || _references.isEmpty)) {
      offset_references = fbBuilder.writeList(_references.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_references != null) {
      fbBuilder.addOffset(0, offset_references);
    }
    return fbBuilder.endTable();
  }
}

PrelinkedUnitBuilder encodePrelinkedUnit({List<PrelinkedReferenceBuilder> references}) {
  PrelinkedUnitBuilder builder = new PrelinkedUnitBuilder();
  builder.references = references;
  return builder;
}

/**
 * Pre-linked summary of a compilation unit.
 */
abstract class PrelinkedUnit extends base.SummaryClass {

  /**
   * For each reference in [UnlinkedUnit.references], information about how
   * that reference is resolved.
   */
  List<PrelinkedReference> get references;
}

class _PrelinkedUnitReader extends fb.TableReader<_PrelinkedUnitImpl> {
  const _PrelinkedUnitReader();

  @override
  _PrelinkedUnitImpl createObject(fb.BufferPointer bp) => new _PrelinkedUnitImpl(bp);
}

class _PrelinkedUnitImpl extends Object with _PrelinkedUnitMixin implements PrelinkedUnit {
  final fb.BufferPointer _bp;

  _PrelinkedUnitImpl(this._bp);

  List<PrelinkedReference> _references;

  @override
  List<PrelinkedReference> get references {
    _references ??= const fb.ListReader<PrelinkedReference>(const _PrelinkedReferenceReader()).vTableGet(_bp, 0, const <PrelinkedReference>[]);
    return _references;
  }
}

abstract class _PrelinkedUnitMixin implements PrelinkedUnit {
  @override
  Map<String, Object> toMap() => {
    "references": references,
  };
}

class SdkBundleBuilder extends Object with _SdkBundleMixin implements SdkBundle {
  bool _finished = false;

  List<String> _prelinkedLibraryUris;
  List<PrelinkedLibraryBuilder> _prelinkedLibraries;
  List<String> _unlinkedUnitUris;
  List<UnlinkedUnitBuilder> _unlinkedUnits;

  SdkBundleBuilder();

  @override
  List<String> get prelinkedLibraryUris => _prelinkedLibraryUris ?? const <String>[];

  /**
   * The list of URIs of items in [prelinkedLibraries], e.g. `dart:core`.
   */
  void set prelinkedLibraryUris(List<String> _value) {
    assert(!_finished);
    _prelinkedLibraryUris = _value;
  }

  @override
  List<PrelinkedLibrary> get prelinkedLibraries => _prelinkedLibraries ?? const <PrelinkedLibrary>[];

  /**
   * Pre-linked libraries.
   */
  void set prelinkedLibraries(List<PrelinkedLibraryBuilder> _value) {
    assert(!_finished);
    _prelinkedLibraries = _value;
  }

  @override
  List<String> get unlinkedUnitUris => _unlinkedUnitUris ?? const <String>[];

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  void set unlinkedUnitUris(List<String> _value) {
    assert(!_finished);
    _unlinkedUnitUris = _value;
  }

  @override
  List<UnlinkedUnit> get unlinkedUnits => _unlinkedUnits ?? const <UnlinkedUnit>[];

  /**
   * Unlinked information for the compilation units constituting the SDK.
   */
  void set unlinkedUnits(List<UnlinkedUnitBuilder> _value) {
    assert(!_finished);
    _unlinkedUnits = _value;
  }

  List<int> toBuffer() {
    fb.Builder fbBuilder = new fb.Builder();
    return fbBuilder.finish(finish(fbBuilder));
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_prelinkedLibraryUris;
    fb.Offset offset_prelinkedLibraries;
    fb.Offset offset_unlinkedUnitUris;
    fb.Offset offset_unlinkedUnits;
    if (!(_prelinkedLibraryUris == null || _prelinkedLibraryUris.isEmpty)) {
      offset_prelinkedLibraryUris = fbBuilder.writeList(_prelinkedLibraryUris.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_prelinkedLibraries == null || _prelinkedLibraries.isEmpty)) {
      offset_prelinkedLibraries = fbBuilder.writeList(_prelinkedLibraries.map((b) => b.finish(fbBuilder)).toList());
    }
    if (!(_unlinkedUnitUris == null || _unlinkedUnitUris.isEmpty)) {
      offset_unlinkedUnitUris = fbBuilder.writeList(_unlinkedUnitUris.map((b) => fbBuilder.writeString(b)).toList());
    }
    if (!(_unlinkedUnits == null || _unlinkedUnits.isEmpty)) {
      offset_unlinkedUnits = fbBuilder.writeList(_unlinkedUnits.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (offset_prelinkedLibraryUris != null) {
      fbBuilder.addOffset(0, offset_prelinkedLibraryUris);
    }
    if (offset_prelinkedLibraries != null) {
      fbBuilder.addOffset(1, offset_prelinkedLibraries);
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

SdkBundleBuilder encodeSdkBundle({List<String> prelinkedLibraryUris, List<PrelinkedLibraryBuilder> prelinkedLibraries, List<String> unlinkedUnitUris, List<UnlinkedUnitBuilder> unlinkedUnits}) {
  SdkBundleBuilder builder = new SdkBundleBuilder();
  builder.prelinkedLibraryUris = prelinkedLibraryUris;
  builder.prelinkedLibraries = prelinkedLibraries;
  builder.unlinkedUnitUris = unlinkedUnitUris;
  builder.unlinkedUnits = unlinkedUnits;
  return builder;
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
   * The list of URIs of items in [prelinkedLibraries], e.g. `dart:core`.
   */
  List<String> get prelinkedLibraryUris;

  /**
   * Pre-linked libraries.
   */
  List<PrelinkedLibrary> get prelinkedLibraries;

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

  List<String> _prelinkedLibraryUris;
  List<PrelinkedLibrary> _prelinkedLibraries;
  List<String> _unlinkedUnitUris;
  List<UnlinkedUnit> _unlinkedUnits;

  @override
  List<String> get prelinkedLibraryUris {
    _prelinkedLibraryUris ??= const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 0, const <String>[]);
    return _prelinkedLibraryUris;
  }

  @override
  List<PrelinkedLibrary> get prelinkedLibraries {
    _prelinkedLibraries ??= const fb.ListReader<PrelinkedLibrary>(const _PrelinkedLibraryReader()).vTableGet(_bp, 1, const <PrelinkedLibrary>[]);
    return _prelinkedLibraries;
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
    "prelinkedLibraryUris": prelinkedLibraryUris,
    "prelinkedLibraries": prelinkedLibraries,
    "unlinkedUnitUris": unlinkedUnitUris,
    "unlinkedUnits": unlinkedUnits,
  };
}

class UnlinkedClassBuilder extends Object with _UnlinkedClassMixin implements UnlinkedClass {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  List<UnlinkedTypeParamBuilder> _typeParameters;
  UnlinkedTypeRefBuilder _supertype;
  List<UnlinkedTypeRefBuilder> _mixins;
  List<UnlinkedTypeRefBuilder> _interfaces;
  List<UnlinkedVariableBuilder> _fields;
  List<UnlinkedExecutableBuilder> _executables;
  bool _isAbstract;
  bool _isMixinApplication;
  bool _hasNoSupertype;

  UnlinkedClassBuilder();

  @override
  String get name => _name ?? '';

  /**
   * Name of the class.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationComment get documentationComment => _documentationComment;

  /**
   * Documentation comment for the class, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];

  /**
   * Type parameters of the class, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    _typeParameters = _value;
  }

  @override
  UnlinkedTypeRef get supertype => _supertype;

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  void set supertype(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _supertype = _value;
  }

  @override
  List<UnlinkedTypeRef> get mixins => _mixins ?? const <UnlinkedTypeRef>[];

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  void set mixins(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    _mixins = _value;
  }

  @override
  List<UnlinkedTypeRef> get interfaces => _interfaces ?? const <UnlinkedTypeRef>[];

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  void set interfaces(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    _interfaces = _value;
  }

  @override
  List<UnlinkedVariable> get fields => _fields ?? const <UnlinkedVariable>[];

  /**
   * Field declarations contained in the class.
   */
  void set fields(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    _fields = _value;
  }

  @override
  List<UnlinkedExecutable> get executables => _executables ?? const <UnlinkedExecutable>[];

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    _executables = _value;
  }

  @override
  bool get isAbstract => _isAbstract ?? false;

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  void set isAbstract(bool _value) {
    assert(!_finished);
    _isAbstract = _value;
  }

  @override
  bool get isMixinApplication => _isMixinApplication ?? false;

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  void set isMixinApplication(bool _value) {
    assert(!_finished);
    _isMixinApplication = _value;
  }

  @override
  bool get hasNoSupertype => _hasNoSupertype ?? false;

  /**
   * Indicates whether this class is the core "Object" class (and hence has no
   * supertype)
   */
  void set hasNoSupertype(bool _value) {
    assert(!_finished);
    _hasNoSupertype = _value;
  }

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
      fbBuilder.addInt32(1, _nameOffset);
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

UnlinkedClassBuilder encodeUnlinkedClass({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder supertype, List<UnlinkedTypeRefBuilder> mixins, List<UnlinkedTypeRefBuilder> interfaces, List<UnlinkedVariableBuilder> fields, List<UnlinkedExecutableBuilder> executables, bool isAbstract, bool isMixinApplication, bool hasNoSupertype}) {
  UnlinkedClassBuilder builder = new UnlinkedClassBuilder();
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.documentationComment = documentationComment;
  builder.typeParameters = typeParameters;
  builder.supertype = supertype;
  builder.mixins = mixins;
  builder.interfaces = interfaces;
  builder.fields = fields;
  builder.executables = executables;
  builder.isAbstract = isAbstract;
  builder.isMixinApplication = isMixinApplication;
  builder.hasNoSupertype = hasNoSupertype;
  return builder;
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
  UnlinkedTypeRef get supertype;

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  List<UnlinkedTypeRef> get mixins;

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  List<UnlinkedTypeRef> get interfaces;

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
  UnlinkedTypeRef _supertype;
  List<UnlinkedTypeRef> _mixins;
  List<UnlinkedTypeRef> _interfaces;
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
    _nameOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
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
  UnlinkedTypeRef get supertype {
    _supertype ??= const _UnlinkedTypeRefReader().vTableGet(_bp, 4, null);
    return _supertype;
  }

  @override
  List<UnlinkedTypeRef> get mixins {
    _mixins ??= const fb.ListReader<UnlinkedTypeRef>(const _UnlinkedTypeRefReader()).vTableGet(_bp, 5, const <UnlinkedTypeRef>[]);
    return _mixins;
  }

  @override
  List<UnlinkedTypeRef> get interfaces {
    _interfaces ??= const fb.ListReader<UnlinkedTypeRef>(const _UnlinkedTypeRefReader()).vTableGet(_bp, 6, const <UnlinkedTypeRef>[]);
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

  UnlinkedCombinatorBuilder();

  @override
  List<String> get shows => _shows ?? const <String>[];

  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  void set shows(List<String> _value) {
    assert(!_finished);
    _shows = _value;
  }

  @override
  List<String> get hides => _hides ?? const <String>[];

  /**
   * List of names which are hidden.  Empty if this is a `show` combinator.
   */
  void set hides(List<String> _value) {
    assert(!_finished);
    _hides = _value;
  }

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

UnlinkedCombinatorBuilder encodeUnlinkedCombinator({List<String> shows, List<String> hides}) {
  UnlinkedCombinatorBuilder builder = new UnlinkedCombinatorBuilder();
  builder.shows = shows;
  builder.hides = hides;
  return builder;
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

class UnlinkedDocumentationCommentBuilder extends Object with _UnlinkedDocumentationCommentMixin implements UnlinkedDocumentationComment {
  bool _finished = false;

  String _text;
  int _offset;
  int _length;

  UnlinkedDocumentationCommentBuilder();

  @override
  String get text => _text ?? '';

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
  int get offset => _offset ?? 0;

  /**
   * Offset of the beginning of the documentation comment relative to the
   * beginning of the file.
   */
  void set offset(int _value) {
    assert(!_finished);
    _offset = _value;
  }

  @override
  int get length => _length ?? 0;

  /**
   * Length of the documentation comment (prior to replacing '\r\n' with '\n').
   */
  void set length(int _value) {
    assert(!_finished);
    _length = _value;
  }

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
      fbBuilder.addInt32(1, _offset);
    }
    if (_length != null && _length != 0) {
      fbBuilder.addInt32(2, _length);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedDocumentationCommentBuilder encodeUnlinkedDocumentationComment({String text, int offset, int length}) {
  UnlinkedDocumentationCommentBuilder builder = new UnlinkedDocumentationCommentBuilder();
  builder.text = text;
  builder.offset = offset;
  builder.length = length;
  return builder;
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
    _offset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return _offset;
  }

  @override
  int get length {
    _length ??= const fb.Int32Reader().vTableGet(_bp, 2, 0);
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

  UnlinkedEnumBuilder();

  @override
  String get name => _name ?? '';

  /**
   * Name of the enum type.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationComment get documentationComment => _documentationComment;

  /**
   * Documentation comment for the enum, or `null` if there is no documentation
   * comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  List<UnlinkedEnumValue> get values => _values ?? const <UnlinkedEnumValue>[];

  /**
   * Values listed in the enum declaration, in declaration order.
   */
  void set values(List<UnlinkedEnumValueBuilder> _value) {
    assert(!_finished);
    _values = _value;
  }

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
      fbBuilder.addInt32(1, _nameOffset);
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

UnlinkedEnumBuilder encodeUnlinkedEnum({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedEnumValueBuilder> values}) {
  UnlinkedEnumBuilder builder = new UnlinkedEnumBuilder();
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.documentationComment = documentationComment;
  builder.values = values;
  return builder;
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
    _nameOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
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

  UnlinkedEnumValueBuilder();

  @override
  String get name => _name ?? '';

  /**
   * Name of the enumerated value.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationComment get documentationComment => _documentationComment;

  /**
   * Documentation comment for the enum value, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

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
      fbBuilder.addInt32(1, _nameOffset);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(2, offset_documentationComment);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedEnumValueBuilder encodeUnlinkedEnumValue({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment}) {
  UnlinkedEnumValueBuilder builder = new UnlinkedEnumValueBuilder();
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.documentationComment = documentationComment;
  return builder;
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
    _nameOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
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
  UnlinkedTypeRefBuilder _returnType;
  List<UnlinkedParamBuilder> _parameters;
  UnlinkedExecutableKind _kind;
  bool _isAbstract;
  bool _isStatic;
  bool _isConst;
  bool _isFactory;
  bool _hasImplicitReturnType;
  bool _isExternal;

  UnlinkedExecutableBuilder();

  @override
  String get name => _name ?? '';

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
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Offset of the executable name relative to the beginning of the file.  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the offset of the class name (i.e. the
   * offset of the second "C" in "class C { C(); }").
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationComment get documentationComment => _documentationComment;

  /**
   * Documentation comment for the executable, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    _typeParameters = _value;
  }

  @override
  UnlinkedTypeRef get returnType => _returnType;

  /**
   * Declared return type of the executable.  Absent if the return type is
   * `void` or the executable is a constructor.  Note that when strong mode is
   * enabled, the actual return type may be different due to type inference.
   */
  void set returnType(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _returnType = _value;
  }

  @override
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];

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
  UnlinkedExecutableKind get kind => _kind ?? UnlinkedExecutableKind.functionOrMethod;

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  void set kind(UnlinkedExecutableKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  @override
  bool get isAbstract => _isAbstract ?? false;

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  void set isAbstract(bool _value) {
    assert(!_finished);
    _isAbstract = _value;
  }

  @override
  bool get isStatic => _isStatic ?? false;

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
  bool get isConst => _isConst ?? false;

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  void set isConst(bool _value) {
    assert(!_finished);
    _isConst = _value;
  }

  @override
  bool get isFactory => _isFactory ?? false;

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  void set isFactory(bool _value) {
    assert(!_finished);
    _isFactory = _value;
  }

  @override
  bool get hasImplicitReturnType => _hasImplicitReturnType ?? false;

  /**
   * Indicates whether the executable lacks an explicit return type
   * declaration.  False for constructors and setters.
   */
  void set hasImplicitReturnType(bool _value) {
    assert(!_finished);
    _hasImplicitReturnType = _value;
  }

  @override
  bool get isExternal => _isExternal ?? false;

  /**
   * Indicates whether the executable is declared using the `external` keyword.
   */
  void set isExternal(bool _value) {
    assert(!_finished);
    _isExternal = _value;
  }

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
      fbBuilder.addInt32(1, _nameOffset);
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
      fbBuilder.addInt32(6, _kind.index);
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

UnlinkedExecutableBuilder encodeUnlinkedExecutable({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters, UnlinkedExecutableKind kind, bool isAbstract, bool isStatic, bool isConst, bool isFactory, bool hasImplicitReturnType, bool isExternal}) {
  UnlinkedExecutableBuilder builder = new UnlinkedExecutableBuilder();
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.documentationComment = documentationComment;
  builder.typeParameters = typeParameters;
  builder.returnType = returnType;
  builder.parameters = parameters;
  builder.kind = kind;
  builder.isAbstract = isAbstract;
  builder.isStatic = isStatic;
  builder.isConst = isConst;
  builder.isFactory = isFactory;
  builder.hasImplicitReturnType = hasImplicitReturnType;
  builder.isExternal = isExternal;
  return builder;
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
  UnlinkedTypeRef get returnType;

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
  UnlinkedTypeRef _returnType;
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
    _nameOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
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
  UnlinkedTypeRef get returnType {
    _returnType ??= const _UnlinkedTypeRefReader().vTableGet(_bp, 4, null);
    return _returnType;
  }

  @override
  List<UnlinkedParam> get parameters {
    _parameters ??= const fb.ListReader<UnlinkedParam>(const _UnlinkedParamReader()).vTableGet(_bp, 5, const <UnlinkedParam>[]);
    return _parameters;
  }

  @override
  UnlinkedExecutableKind get kind {
    _kind ??= UnlinkedExecutableKind.values[const fb.Int32Reader().vTableGet(_bp, 6, 0)];
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

  UnlinkedExportNonPublicBuilder();

  @override
  int get offset => _offset ?? 0;

  /**
   * Offset of the "export" keyword.
   */
  void set offset(int _value) {
    assert(!_finished);
    _offset = _value;
  }

  @override
  int get uriOffset => _uriOffset ?? 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    _uriOffset = _value;
  }

  @override
  int get uriEnd => _uriEnd ?? 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    _uriEnd = _value;
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fbBuilder.startTable();
    if (_offset != null && _offset != 0) {
      fbBuilder.addInt32(0, _offset);
    }
    if (_uriOffset != null && _uriOffset != 0) {
      fbBuilder.addInt32(1, _uriOffset);
    }
    if (_uriEnd != null && _uriEnd != 0) {
      fbBuilder.addInt32(2, _uriEnd);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedExportNonPublicBuilder encodeUnlinkedExportNonPublic({int offset, int uriOffset, int uriEnd}) {
  UnlinkedExportNonPublicBuilder builder = new UnlinkedExportNonPublicBuilder();
  builder.offset = offset;
  builder.uriOffset = uriOffset;
  builder.uriEnd = uriEnd;
  return builder;
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
    _offset ??= const fb.Int32Reader().vTableGet(_bp, 0, 0);
    return _offset;
  }

  @override
  int get uriOffset {
    _uriOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return _uriOffset;
  }

  @override
  int get uriEnd {
    _uriEnd ??= const fb.Int32Reader().vTableGet(_bp, 2, 0);
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

  UnlinkedExportPublicBuilder();

  @override
  String get uri => _uri ?? '';

  /**
   * URI used in the source code to reference the exported library.
   */
  void set uri(String _value) {
    assert(!_finished);
    _uri = _value;
  }

  @override
  List<UnlinkedCombinator> get combinators => _combinators ?? const <UnlinkedCombinator>[];

  /**
   * Combinators contained in this import declaration.
   */
  void set combinators(List<UnlinkedCombinatorBuilder> _value) {
    assert(!_finished);
    _combinators = _value;
  }

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

UnlinkedExportPublicBuilder encodeUnlinkedExportPublic({String uri, List<UnlinkedCombinatorBuilder> combinators}) {
  UnlinkedExportPublicBuilder builder = new UnlinkedExportPublicBuilder();
  builder.uri = uri;
  builder.combinators = combinators;
  return builder;
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

  UnlinkedImportBuilder();

  @override
  String get uri => _uri ?? '';

  /**
   * URI used in the source code to reference the imported library.
   */
  void set uri(String _value) {
    assert(!_finished);
    _uri = _value;
  }

  @override
  int get offset => _offset ?? 0;

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  void set offset(int _value) {
    assert(!_finished);
    _offset = _value;
  }

  @override
  int get prefixReference => _prefixReference ?? 0;

  /**
   * Index into [UnlinkedUnit.references] of the prefix declared by this
   * import declaration, or zero if this import declaration declares no prefix.
   *
   * Note that multiple imports can declare the same prefix.
   */
  void set prefixReference(int _value) {
    assert(!_finished);
    _prefixReference = _value;
  }

  @override
  List<UnlinkedCombinator> get combinators => _combinators ?? const <UnlinkedCombinator>[];

  /**
   * Combinators contained in this import declaration.
   */
  void set combinators(List<UnlinkedCombinatorBuilder> _value) {
    assert(!_finished);
    _combinators = _value;
  }

  @override
  bool get isDeferred => _isDeferred ?? false;

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  void set isDeferred(bool _value) {
    assert(!_finished);
    _isDeferred = _value;
  }

  @override
  bool get isImplicit => _isImplicit ?? false;

  /**
   * Indicates whether the import declaration is implicit.
   */
  void set isImplicit(bool _value) {
    assert(!_finished);
    _isImplicit = _value;
  }

  @override
  int get uriOffset => _uriOffset ?? 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    _uriOffset = _value;
  }

  @override
  int get uriEnd => _uriEnd ?? 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    _uriEnd = _value;
  }

  @override
  int get prefixOffset => _prefixOffset ?? 0;

  /**
   * Offset of the prefix name relative to the beginning of the file, or zero
   * if there is no prefix.
   */
  void set prefixOffset(int _value) {
    assert(!_finished);
    _prefixOffset = _value;
  }

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
      fbBuilder.addInt32(1, _offset);
    }
    if (_prefixReference != null && _prefixReference != 0) {
      fbBuilder.addInt32(2, _prefixReference);
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
      fbBuilder.addInt32(6, _uriOffset);
    }
    if (_uriEnd != null && _uriEnd != 0) {
      fbBuilder.addInt32(7, _uriEnd);
    }
    if (_prefixOffset != null && _prefixOffset != 0) {
      fbBuilder.addInt32(8, _prefixOffset);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedImportBuilder encodeUnlinkedImport({String uri, int offset, int prefixReference, List<UnlinkedCombinatorBuilder> combinators, bool isDeferred, bool isImplicit, int uriOffset, int uriEnd, int prefixOffset}) {
  UnlinkedImportBuilder builder = new UnlinkedImportBuilder();
  builder.uri = uri;
  builder.offset = offset;
  builder.prefixReference = prefixReference;
  builder.combinators = combinators;
  builder.isDeferred = isDeferred;
  builder.isImplicit = isImplicit;
  builder.uriOffset = uriOffset;
  builder.uriEnd = uriEnd;
  builder.prefixOffset = prefixOffset;
  return builder;
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
    _offset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return _offset;
  }

  @override
  int get prefixReference {
    _prefixReference ??= const fb.Int32Reader().vTableGet(_bp, 2, 0);
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
    _uriOffset ??= const fb.Int32Reader().vTableGet(_bp, 6, 0);
    return _uriOffset;
  }

  @override
  int get uriEnd {
    _uriEnd ??= const fb.Int32Reader().vTableGet(_bp, 7, 0);
    return _uriEnd;
  }

  @override
  int get prefixOffset {
    _prefixOffset ??= const fb.Int32Reader().vTableGet(_bp, 8, 0);
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
  UnlinkedTypeRefBuilder _type;
  List<UnlinkedParamBuilder> _parameters;
  UnlinkedParamKind _kind;
  bool _isFunctionTyped;
  bool _isInitializingFormal;
  bool _hasImplicitType;

  UnlinkedParamBuilder();

  @override
  String get name => _name ?? '';

  /**
   * Name of the parameter.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  @override
  UnlinkedTypeRef get type => _type;

  /**
   * If [isFunctionTyped] is `true`, the declared return type.  If
   * [isFunctionTyped] is `false`, the declared type.  Absent if
   * [isFunctionTyped] is `true` and the declared return type is `void`.  Note
   * that when strong mode is enabled, the actual type may be different due to
   * type inference.
   */
  void set type(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _type = _value;
  }

  @override
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    _parameters = _value;
  }

  @override
  UnlinkedParamKind get kind => _kind ?? UnlinkedParamKind.required;

  /**
   * Kind of the parameter.
   */
  void set kind(UnlinkedParamKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  @override
  bool get isFunctionTyped => _isFunctionTyped ?? false;

  /**
   * Indicates whether this is a function-typed parameter.
   */
  void set isFunctionTyped(bool _value) {
    assert(!_finished);
    _isFunctionTyped = _value;
  }

  @override
  bool get isInitializingFormal => _isInitializingFormal ?? false;

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  void set isInitializingFormal(bool _value) {
    assert(!_finished);
    _isInitializingFormal = _value;
  }

  @override
  bool get hasImplicitType => _hasImplicitType ?? false;

  /**
   * Indicates whether this parameter lacks an explicit type declaration.
   * Always false for a function-typed parameter.
   */
  void set hasImplicitType(bool _value) {
    assert(!_finished);
    _hasImplicitType = _value;
  }

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
      fbBuilder.addInt32(1, _nameOffset);
    }
    if (offset_type != null) {
      fbBuilder.addOffset(2, offset_type);
    }
    if (offset_parameters != null) {
      fbBuilder.addOffset(3, offset_parameters);
    }
    if (_kind != null && _kind != UnlinkedParamKind.required) {
      fbBuilder.addInt32(4, _kind.index);
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

UnlinkedParamBuilder encodeUnlinkedParam({String name, int nameOffset, UnlinkedTypeRefBuilder type, List<UnlinkedParamBuilder> parameters, UnlinkedParamKind kind, bool isFunctionTyped, bool isInitializingFormal, bool hasImplicitType}) {
  UnlinkedParamBuilder builder = new UnlinkedParamBuilder();
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.type = type;
  builder.parameters = parameters;
  builder.kind = kind;
  builder.isFunctionTyped = isFunctionTyped;
  builder.isInitializingFormal = isInitializingFormal;
  builder.hasImplicitType = hasImplicitType;
  return builder;
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
  UnlinkedTypeRef get type;

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
  UnlinkedTypeRef _type;
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
    _nameOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  UnlinkedTypeRef get type {
    _type ??= const _UnlinkedTypeRefReader().vTableGet(_bp, 2, null);
    return _type;
  }

  @override
  List<UnlinkedParam> get parameters {
    _parameters ??= const fb.ListReader<UnlinkedParam>(const _UnlinkedParamReader()).vTableGet(_bp, 3, const <UnlinkedParam>[]);
    return _parameters;
  }

  @override
  UnlinkedParamKind get kind {
    _kind ??= UnlinkedParamKind.values[const fb.Int32Reader().vTableGet(_bp, 4, 0)];
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

  UnlinkedPartBuilder();

  @override
  int get uriOffset => _uriOffset ?? 0;

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    _uriOffset = _value;
  }

  @override
  int get uriEnd => _uriEnd ?? 0;

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    _uriEnd = _value;
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fbBuilder.startTable();
    if (_uriOffset != null && _uriOffset != 0) {
      fbBuilder.addInt32(0, _uriOffset);
    }
    if (_uriEnd != null && _uriEnd != 0) {
      fbBuilder.addInt32(1, _uriEnd);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedPartBuilder encodeUnlinkedPart({int uriOffset, int uriEnd}) {
  UnlinkedPartBuilder builder = new UnlinkedPartBuilder();
  builder.uriOffset = uriOffset;
  builder.uriEnd = uriEnd;
  return builder;
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
    _uriOffset ??= const fb.Int32Reader().vTableGet(_bp, 0, 0);
    return _uriOffset;
  }

  @override
  int get uriEnd {
    _uriEnd ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
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
  PrelinkedReferenceKind _kind;
  int _numTypeParameters;

  UnlinkedPublicNameBuilder();

  @override
  String get name => _name ?? '';

  /**
   * The name itself.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  PrelinkedReferenceKind get kind => _kind ?? PrelinkedReferenceKind.classOrEnum;

  /**
   * The kind of object referred to by the name.
   */
  void set kind(PrelinkedReferenceKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  @override
  int get numTypeParameters => _numTypeParameters ?? 0;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  void set numTypeParameters(int _value) {
    assert(!_finished);
    _numTypeParameters = _value;
  }

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
    if (_kind != null && _kind != PrelinkedReferenceKind.classOrEnum) {
      fbBuilder.addInt32(1, _kind.index);
    }
    if (_numTypeParameters != null && _numTypeParameters != 0) {
      fbBuilder.addInt32(2, _numTypeParameters);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedPublicNameBuilder encodeUnlinkedPublicName({String name, PrelinkedReferenceKind kind, int numTypeParameters}) {
  UnlinkedPublicNameBuilder builder = new UnlinkedPublicNameBuilder();
  builder.name = name;
  builder.kind = kind;
  builder.numTypeParameters = numTypeParameters;
  return builder;
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
  PrelinkedReferenceKind get kind;

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
  PrelinkedReferenceKind _kind;
  int _numTypeParameters;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  PrelinkedReferenceKind get kind {
    _kind ??= PrelinkedReferenceKind.values[const fb.Int32Reader().vTableGet(_bp, 1, 0)];
    return _kind;
  }

  @override
  int get numTypeParameters {
    _numTypeParameters ??= const fb.Int32Reader().vTableGet(_bp, 2, 0);
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

  UnlinkedPublicNamespaceBuilder();

  @override
  List<UnlinkedPublicName> get names => _names ?? const <UnlinkedPublicName>[];

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
  List<UnlinkedExportPublic> get exports => _exports ?? const <UnlinkedExportPublic>[];

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportPublicBuilder> _value) {
    assert(!_finished);
    _exports = _value;
  }

  @override
  List<String> get parts => _parts ?? const <String>[];

  /**
   * URIs referenced by part declarations in the compilation unit.
   */
  void set parts(List<String> _value) {
    assert(!_finished);
    _parts = _value;
  }

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

UnlinkedPublicNamespaceBuilder encodeUnlinkedPublicNamespace({List<UnlinkedPublicNameBuilder> names, List<UnlinkedExportPublicBuilder> exports, List<String> parts}) {
  UnlinkedPublicNamespaceBuilder builder = new UnlinkedPublicNamespaceBuilder();
  builder.names = names;
  builder.exports = exports;
  builder.parts = parts;
  return builder;
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

  UnlinkedReferenceBuilder();

  @override
  String get name => _name ?? '';

  /**
   * Name of the entity being referred to.  The empty string refers to the
   * pseudo-type `dynamic`.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get prefixReference => _prefixReference ?? 0;

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
    _prefixReference = _value;
  }

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
      fbBuilder.addInt32(1, _prefixReference);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedReferenceBuilder encodeUnlinkedReference({String name, int prefixReference}) {
  UnlinkedReferenceBuilder builder = new UnlinkedReferenceBuilder();
  builder.name = name;
  builder.prefixReference = prefixReference;
  return builder;
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
    _prefixReference ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
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
  UnlinkedTypeRefBuilder _returnType;
  List<UnlinkedParamBuilder> _parameters;

  UnlinkedTypedefBuilder();

  @override
  String get name => _name ?? '';

  /**
   * Name of the typedef.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationComment get documentationComment => _documentationComment;

  /**
   * Documentation comment for the typedef, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  List<UnlinkedTypeParam> get typeParameters => _typeParameters ?? const <UnlinkedTypeParam>[];

  /**
   * Type parameters of the typedef, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    _typeParameters = _value;
  }

  @override
  UnlinkedTypeRef get returnType => _returnType;

  /**
   * Return type of the typedef.  Absent if the return type is `void`.
   */
  void set returnType(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _returnType = _value;
  }

  @override
  List<UnlinkedParam> get parameters => _parameters ?? const <UnlinkedParam>[];

  /**
   * Parameters of the executable, if any.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    _parameters = _value;
  }

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
      fbBuilder.addInt32(1, _nameOffset);
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

UnlinkedTypedefBuilder encodeUnlinkedTypedef({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters}) {
  UnlinkedTypedefBuilder builder = new UnlinkedTypedefBuilder();
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.documentationComment = documentationComment;
  builder.typeParameters = typeParameters;
  builder.returnType = returnType;
  builder.parameters = parameters;
  return builder;
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
  UnlinkedTypeRef get returnType;

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
  UnlinkedTypeRef _returnType;
  List<UnlinkedParam> _parameters;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
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
  UnlinkedTypeRef get returnType {
    _returnType ??= const _UnlinkedTypeRefReader().vTableGet(_bp, 4, null);
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
  UnlinkedTypeRefBuilder _bound;

  UnlinkedTypeParamBuilder();

  @override
  String get name => _name ?? '';

  /**
   * Name of the type parameter.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  @override
  UnlinkedTypeRef get bound => _bound;

  /**
   * Bound of the type parameter, if a bound is explicitly declared.  Otherwise
   * null.
   */
  void set bound(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _bound = _value;
  }

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
      fbBuilder.addInt32(1, _nameOffset);
    }
    if (offset_bound != null) {
      fbBuilder.addOffset(2, offset_bound);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedTypeParamBuilder encodeUnlinkedTypeParam({String name, int nameOffset, UnlinkedTypeRefBuilder bound}) {
  UnlinkedTypeParamBuilder builder = new UnlinkedTypeParamBuilder();
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.bound = bound;
  return builder;
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
  UnlinkedTypeRef get bound;
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
  UnlinkedTypeRef _bound;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  UnlinkedTypeRef get bound {
    _bound ??= const _UnlinkedTypeRefReader().vTableGet(_bp, 2, null);
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

class UnlinkedTypeRefBuilder extends Object with _UnlinkedTypeRefMixin implements UnlinkedTypeRef {
  bool _finished = false;

  int _reference;
  int _paramReference;
  List<UnlinkedTypeRefBuilder> _typeArguments;

  UnlinkedTypeRefBuilder();

  @override
  int get reference => _reference ?? 0;

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
    _reference = _value;
  }

  @override
  int get paramReference => _paramReference ?? 0;

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
    _paramReference = _value;
  }

  @override
  List<UnlinkedTypeRef> get typeArguments => _typeArguments ?? const <UnlinkedTypeRef>[];

  /**
   * If this is an instantiation of a generic type, the type arguments used to
   * instantiate it.  Trailing type arguments of type `dynamic` are omitted.
   */
  void set typeArguments(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    _typeArguments = _value;
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_typeArguments;
    if (!(_typeArguments == null || _typeArguments.isEmpty)) {
      offset_typeArguments = fbBuilder.writeList(_typeArguments.map((b) => b.finish(fbBuilder)).toList());
    }
    fbBuilder.startTable();
    if (_reference != null && _reference != 0) {
      fbBuilder.addInt32(0, _reference);
    }
    if (_paramReference != null && _paramReference != 0) {
      fbBuilder.addInt32(1, _paramReference);
    }
    if (offset_typeArguments != null) {
      fbBuilder.addOffset(2, offset_typeArguments);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedTypeRefBuilder encodeUnlinkedTypeRef({int reference, int paramReference, List<UnlinkedTypeRefBuilder> typeArguments}) {
  UnlinkedTypeRefBuilder builder = new UnlinkedTypeRefBuilder();
  builder.reference = reference;
  builder.paramReference = paramReference;
  builder.typeArguments = typeArguments;
  return builder;
}

/**
 * Unlinked summary information about a reference to a type.
 */
abstract class UnlinkedTypeRef extends base.SummaryClass {

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
  List<UnlinkedTypeRef> get typeArguments;
}

class _UnlinkedTypeRefReader extends fb.TableReader<_UnlinkedTypeRefImpl> {
  const _UnlinkedTypeRefReader();

  @override
  _UnlinkedTypeRefImpl createObject(fb.BufferPointer bp) => new _UnlinkedTypeRefImpl(bp);
}

class _UnlinkedTypeRefImpl extends Object with _UnlinkedTypeRefMixin implements UnlinkedTypeRef {
  final fb.BufferPointer _bp;

  _UnlinkedTypeRefImpl(this._bp);

  int _reference;
  int _paramReference;
  List<UnlinkedTypeRef> _typeArguments;

  @override
  int get reference {
    _reference ??= const fb.Int32Reader().vTableGet(_bp, 0, 0);
    return _reference;
  }

  @override
  int get paramReference {
    _paramReference ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return _paramReference;
  }

  @override
  List<UnlinkedTypeRef> get typeArguments {
    _typeArguments ??= const fb.ListReader<UnlinkedTypeRef>(const _UnlinkedTypeRefReader()).vTableGet(_bp, 2, const <UnlinkedTypeRef>[]);
    return _typeArguments;
  }
}

abstract class _UnlinkedTypeRefMixin implements UnlinkedTypeRef {
  @override
  Map<String, Object> toMap() => {
    "reference": reference,
    "paramReference": paramReference,
    "typeArguments": typeArguments,
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

  UnlinkedUnitBuilder();

  @override
  String get libraryName => _libraryName ?? '';

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  void set libraryName(String _value) {
    assert(!_finished);
    _libraryName = _value;
  }

  @override
  int get libraryNameOffset => _libraryNameOffset ?? 0;

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  void set libraryNameOffset(int _value) {
    assert(!_finished);
    _libraryNameOffset = _value;
  }

  @override
  int get libraryNameLength => _libraryNameLength ?? 0;

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  void set libraryNameLength(int _value) {
    assert(!_finished);
    _libraryNameLength = _value;
  }

  @override
  UnlinkedDocumentationComment get libraryDocumentationComment => _libraryDocumentationComment;

  /**
   * Documentation comment for the library, or `null` if there is no
   * documentation comment.
   */
  void set libraryDocumentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _libraryDocumentationComment = _value;
  }

  @override
  UnlinkedPublicNamespace get publicNamespace => _publicNamespace;

  /**
   * Unlinked public namespace of this compilation unit.
   */
  void set publicNamespace(UnlinkedPublicNamespaceBuilder _value) {
    assert(!_finished);
    _publicNamespace = _value;
  }

  @override
  List<UnlinkedReference> get references => _references ?? const <UnlinkedReference>[];

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
  List<UnlinkedClass> get classes => _classes ?? const <UnlinkedClass>[];

  /**
   * Classes declared in the compilation unit.
   */
  void set classes(List<UnlinkedClassBuilder> _value) {
    assert(!_finished);
    _classes = _value;
  }

  @override
  List<UnlinkedEnum> get enums => _enums ?? const <UnlinkedEnum>[];

  /**
   * Enums declared in the compilation unit.
   */
  void set enums(List<UnlinkedEnumBuilder> _value) {
    assert(!_finished);
    _enums = _value;
  }

  @override
  List<UnlinkedExecutable> get executables => _executables ?? const <UnlinkedExecutable>[];

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    _executables = _value;
  }

  @override
  List<UnlinkedExportNonPublic> get exports => _exports ?? const <UnlinkedExportNonPublic>[];

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportNonPublicBuilder> _value) {
    assert(!_finished);
    _exports = _value;
  }

  @override
  List<UnlinkedImport> get imports => _imports ?? const <UnlinkedImport>[];

  /**
   * Import declarations in the compilation unit.
   */
  void set imports(List<UnlinkedImportBuilder> _value) {
    assert(!_finished);
    _imports = _value;
  }

  @override
  List<UnlinkedPart> get parts => _parts ?? const <UnlinkedPart>[];

  /**
   * Part declarations in the compilation unit.
   */
  void set parts(List<UnlinkedPartBuilder> _value) {
    assert(!_finished);
    _parts = _value;
  }

  @override
  List<UnlinkedTypedef> get typedefs => _typedefs ?? const <UnlinkedTypedef>[];

  /**
   * Typedefs declared in the compilation unit.
   */
  void set typedefs(List<UnlinkedTypedefBuilder> _value) {
    assert(!_finished);
    _typedefs = _value;
  }

  @override
  List<UnlinkedVariable> get variables => _variables ?? const <UnlinkedVariable>[];

  /**
   * Top level variables declared in the compilation unit.
   */
  void set variables(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    _variables = _value;
  }

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
      fbBuilder.addInt32(1, _libraryNameOffset);
    }
    if (_libraryNameLength != null && _libraryNameLength != 0) {
      fbBuilder.addInt32(2, _libraryNameLength);
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

UnlinkedUnitBuilder encodeUnlinkedUnit({String libraryName, int libraryNameOffset, int libraryNameLength, UnlinkedDocumentationCommentBuilder libraryDocumentationComment, UnlinkedPublicNamespaceBuilder publicNamespace, List<UnlinkedReferenceBuilder> references, List<UnlinkedClassBuilder> classes, List<UnlinkedEnumBuilder> enums, List<UnlinkedExecutableBuilder> executables, List<UnlinkedExportNonPublicBuilder> exports, List<UnlinkedImportBuilder> imports, List<UnlinkedPartBuilder> parts, List<UnlinkedTypedefBuilder> typedefs, List<UnlinkedVariableBuilder> variables}) {
  UnlinkedUnitBuilder builder = new UnlinkedUnitBuilder();
  builder.libraryName = libraryName;
  builder.libraryNameOffset = libraryNameOffset;
  builder.libraryNameLength = libraryNameLength;
  builder.libraryDocumentationComment = libraryDocumentationComment;
  builder.publicNamespace = publicNamespace;
  builder.references = references;
  builder.classes = classes;
  builder.enums = enums;
  builder.executables = executables;
  builder.exports = exports;
  builder.imports = imports;
  builder.parts = parts;
  builder.typedefs = typedefs;
  builder.variables = variables;
  return builder;
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
    _libraryNameOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return _libraryNameOffset;
  }

  @override
  int get libraryNameLength {
    _libraryNameLength ??= const fb.Int32Reader().vTableGet(_bp, 2, 0);
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
  UnlinkedTypeRefBuilder _type;
  bool _isStatic;
  bool _isFinal;
  bool _isConst;
  bool _hasImplicitType;

  UnlinkedVariableBuilder();

  @override
  String get name => _name ?? '';

  /**
   * Name of the variable.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  @override
  int get nameOffset => _nameOffset ?? 0;

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  @override
  UnlinkedDocumentationComment get documentationComment => _documentationComment;

  /**
   * Documentation comment for the variable, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  @override
  UnlinkedTypeRef get type => _type;

  /**
   * Declared type of the variable.  Note that when strong mode is enabled, the
   * actual type of the variable may be different due to type inference.
   */
  void set type(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _type = _value;
  }

  @override
  bool get isStatic => _isStatic ?? false;

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
  bool get isFinal => _isFinal ?? false;

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  void set isFinal(bool _value) {
    assert(!_finished);
    _isFinal = _value;
  }

  @override
  bool get isConst => _isConst ?? false;

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  void set isConst(bool _value) {
    assert(!_finished);
    _isConst = _value;
  }

  @override
  bool get hasImplicitType => _hasImplicitType ?? false;

  /**
   * Indicates whether this variable lacks an explicit type declaration.
   */
  void set hasImplicitType(bool _value) {
    assert(!_finished);
    _hasImplicitType = _value;
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_name;
    fb.Offset offset_documentationComment;
    fb.Offset offset_type;
    if (_name != null) {
      offset_name = fbBuilder.writeString(_name);
    }
    if (_documentationComment != null) {
      offset_documentationComment = _documentationComment.finish(fbBuilder);
    }
    if (_type != null) {
      offset_type = _type.finish(fbBuilder);
    }
    fbBuilder.startTable();
    if (offset_name != null) {
      fbBuilder.addOffset(0, offset_name);
    }
    if (_nameOffset != null && _nameOffset != 0) {
      fbBuilder.addInt32(1, _nameOffset);
    }
    if (offset_documentationComment != null) {
      fbBuilder.addOffset(2, offset_documentationComment);
    }
    if (offset_type != null) {
      fbBuilder.addOffset(3, offset_type);
    }
    if (_isStatic == true) {
      fbBuilder.addBool(4, true);
    }
    if (_isFinal == true) {
      fbBuilder.addBool(5, true);
    }
    if (_isConst == true) {
      fbBuilder.addBool(6, true);
    }
    if (_hasImplicitType == true) {
      fbBuilder.addBool(7, true);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedVariableBuilder encodeUnlinkedVariable({String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, UnlinkedTypeRefBuilder type, bool isStatic, bool isFinal, bool isConst, bool hasImplicitType}) {
  UnlinkedVariableBuilder builder = new UnlinkedVariableBuilder();
  builder.name = name;
  builder.nameOffset = nameOffset;
  builder.documentationComment = documentationComment;
  builder.type = type;
  builder.isStatic = isStatic;
  builder.isFinal = isFinal;
  builder.isConst = isConst;
  builder.hasImplicitType = hasImplicitType;
  return builder;
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
  UnlinkedTypeRef get type;

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
  UnlinkedTypeRef _type;
  bool _isStatic;
  bool _isFinal;
  bool _isConst;
  bool _hasImplicitType;

  @override
  String get name {
    _name ??= const fb.StringReader().vTableGet(_bp, 0, '');
    return _name;
  }

  @override
  int get nameOffset {
    _nameOffset ??= const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return _nameOffset;
  }

  @override
  UnlinkedDocumentationComment get documentationComment {
    _documentationComment ??= const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);
    return _documentationComment;
  }

  @override
  UnlinkedTypeRef get type {
    _type ??= const _UnlinkedTypeRefReader().vTableGet(_bp, 3, null);
    return _type;
  }

  @override
  bool get isStatic {
    _isStatic ??= const fb.BoolReader().vTableGet(_bp, 4, false);
    return _isStatic;
  }

  @override
  bool get isFinal {
    _isFinal ??= const fb.BoolReader().vTableGet(_bp, 5, false);
    return _isFinal;
  }

  @override
  bool get isConst {
    _isConst ??= const fb.BoolReader().vTableGet(_bp, 6, false);
    return _isConst;
  }

  @override
  bool get hasImplicitType {
    _hasImplicitType ??= const fb.BoolReader().vTableGet(_bp, 7, false);
    return _hasImplicitType;
  }
}

abstract class _UnlinkedVariableMixin implements UnlinkedVariable {
  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
    "type": type,
    "isStatic": isStatic,
    "isFinal": isFinal,
    "isConst": isConst,
    "hasImplicitType": hasImplicitType,
  };
}

