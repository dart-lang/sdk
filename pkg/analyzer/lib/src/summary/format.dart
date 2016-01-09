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

class PrelinkedDependencyBuilder {
  bool _finished = false;

  String _uri;

  PrelinkedDependencyBuilder(base.BuilderContext context);

  /**
   * The relative URI used to import one library from the other.
   */
  void set uri(String _value) {
    assert(!_finished);
    _uri = _value;
  }

  fb.Offset finish(fb.Builder fbBuilder) {
    assert(!_finished);
    _finished = true;
    fb.Offset offset_uri;
    if (_uri != null) {
      offset_uri = fbBuilder.writeString(_uri);
    }
    fbBuilder.startTable();
    if (offset_uri != null) {
      fbBuilder.addOffset(0, offset_uri);
    }
    return fbBuilder.endTable();
  }
}

PrelinkedDependencyBuilder encodePrelinkedDependency(base.BuilderContext builderContext, {String uri}) {
  PrelinkedDependencyBuilder builder = new PrelinkedDependencyBuilder(builderContext);
  builder.uri = uri;
  return builder;
}

/**
 * Information about a dependency that exists between one library and another
 * due to an "import" declaration.
 */
abstract class PrelinkedDependency extends base.SummaryClass {

  /**
   * The relative URI used to import one library from the other.
   */
  String get uri;
}

class _PrelinkedDependencyReader extends fb.TableReader<_PrelinkedDependencyReader> implements PrelinkedDependency {
  final fb.BufferPointer _bp;

  const _PrelinkedDependencyReader([this._bp]);

  @override
  _PrelinkedDependencyReader createReader(fb.BufferPointer bp) => new _PrelinkedDependencyReader(bp);

  @override
  Map<String, Object> toMap() => {
    "uri": uri,
  };

  @override
  String get uri => const fb.StringReader().vTableGet(_bp, 0, '');
}

class PrelinkedLibraryBuilder {
  bool _finished = false;

  List<PrelinkedUnitBuilder> _units;
  List<PrelinkedDependencyBuilder> _dependencies;
  List<int> _importDependencies;

  PrelinkedLibraryBuilder(base.BuilderContext context);

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

PrelinkedLibraryBuilder encodePrelinkedLibrary(base.BuilderContext builderContext, {List<PrelinkedUnitBuilder> units, List<PrelinkedDependencyBuilder> dependencies, List<int> importDependencies}) {
  PrelinkedLibraryBuilder builder = new PrelinkedLibraryBuilder(builderContext);
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

class _PrelinkedLibraryReader extends fb.TableReader<_PrelinkedLibraryReader> implements PrelinkedLibrary {
  final fb.BufferPointer _bp;

  const _PrelinkedLibraryReader([this._bp]);

  @override
  _PrelinkedLibraryReader createReader(fb.BufferPointer bp) => new _PrelinkedLibraryReader(bp);

  @override
  Map<String, Object> toMap() => {
    "units": units,
    "dependencies": dependencies,
    "importDependencies": importDependencies,
  };

  @override
  List<PrelinkedUnit> get units => const fb.ListReader<PrelinkedUnit>(const _PrelinkedUnitReader()).vTableGet(_bp, 0, const <PrelinkedUnit>[]);

  @override
  List<PrelinkedDependency> get dependencies => const fb.ListReader<PrelinkedDependency>(const _PrelinkedDependencyReader()).vTableGet(_bp, 1, const <PrelinkedDependency>[]);

  @override
  List<int> get importDependencies => const fb.ListReader<int>(const fb.Int32Reader()).vTableGet(_bp, 2, const <int>[]);
}

class PrelinkedReferenceBuilder {
  bool _finished = false;

  int _dependency;
  PrelinkedReferenceKind _kind;
  int _unit;
  int _numTypeParameters;

  PrelinkedReferenceBuilder(base.BuilderContext context);

  /**
   * Index into [PrelinkedLibrary.dependencies] indicating which imported library
   * declares the entity being referred to.
   */
  void set dependency(int _value) {
    assert(!_finished);
    _dependency = _value;
  }

  /**
   * The kind of the entity being referred to.  For the pseudo-type `dynamic`,
   * the kind is [PrelinkedReferenceKind.classOrEnum].
   */
  void set kind(PrelinkedReferenceKind _value) {
    assert(!_finished);
    _kind = _value;
  }

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

PrelinkedReferenceBuilder encodePrelinkedReference(base.BuilderContext builderContext, {int dependency, PrelinkedReferenceKind kind, int unit, int numTypeParameters}) {
  PrelinkedReferenceBuilder builder = new PrelinkedReferenceBuilder(builderContext);
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

class _PrelinkedReferenceReader extends fb.TableReader<_PrelinkedReferenceReader> implements PrelinkedReference {
  final fb.BufferPointer _bp;

  const _PrelinkedReferenceReader([this._bp]);

  @override
  _PrelinkedReferenceReader createReader(fb.BufferPointer bp) => new _PrelinkedReferenceReader(bp);

  @override
  Map<String, Object> toMap() => {
    "dependency": dependency,
    "kind": kind,
    "unit": unit,
    "numTypeParameters": numTypeParameters,
  };

  @override
  int get dependency => const fb.Int32Reader().vTableGet(_bp, 0, 0);

  @override
  PrelinkedReferenceKind get kind {
    int index = const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return PrelinkedReferenceKind.values[index];
  }

  @override
  int get unit => const fb.Int32Reader().vTableGet(_bp, 2, 0);

  @override
  int get numTypeParameters => const fb.Int32Reader().vTableGet(_bp, 3, 0);
}

class PrelinkedUnitBuilder {
  bool _finished = false;

  List<PrelinkedReferenceBuilder> _references;

  PrelinkedUnitBuilder(base.BuilderContext context);

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

PrelinkedUnitBuilder encodePrelinkedUnit(base.BuilderContext builderContext, {List<PrelinkedReferenceBuilder> references}) {
  PrelinkedUnitBuilder builder = new PrelinkedUnitBuilder(builderContext);
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

class _PrelinkedUnitReader extends fb.TableReader<_PrelinkedUnitReader> implements PrelinkedUnit {
  final fb.BufferPointer _bp;

  const _PrelinkedUnitReader([this._bp]);

  @override
  _PrelinkedUnitReader createReader(fb.BufferPointer bp) => new _PrelinkedUnitReader(bp);

  @override
  Map<String, Object> toMap() => {
    "references": references,
  };

  @override
  List<PrelinkedReference> get references => const fb.ListReader<PrelinkedReference>(const _PrelinkedReferenceReader()).vTableGet(_bp, 0, const <PrelinkedReference>[]);
}

class SdkBundleBuilder {
  bool _finished = false;

  List<String> _prelinkedLibraryUris;
  List<PrelinkedLibraryBuilder> _prelinkedLibraries;
  List<String> _unlinkedUnitUris;
  List<UnlinkedUnitBuilder> _unlinkedUnits;

  SdkBundleBuilder(base.BuilderContext context);

  /**
   * The list of URIs of items in [prelinkedLibraries], e.g. `dart:core`.
   */
  void set prelinkedLibraryUris(List<String> _value) {
    assert(!_finished);
    _prelinkedLibraryUris = _value;
  }

  /**
   * Pre-linked libraries.
   */
  void set prelinkedLibraries(List<PrelinkedLibraryBuilder> _value) {
    assert(!_finished);
    _prelinkedLibraries = _value;
  }

  /**
   * The list of URIs of items in [unlinkedUnits], e.g. `dart:core/bool.dart`.
   */
  void set unlinkedUnitUris(List<String> _value) {
    assert(!_finished);
    _unlinkedUnitUris = _value;
  }

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

SdkBundleBuilder encodeSdkBundle(base.BuilderContext builderContext, {List<String> prelinkedLibraryUris, List<PrelinkedLibraryBuilder> prelinkedLibraries, List<String> unlinkedUnitUris, List<UnlinkedUnitBuilder> unlinkedUnits}) {
  SdkBundleBuilder builder = new SdkBundleBuilder(builderContext);
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

class _SdkBundleReader extends fb.TableReader<_SdkBundleReader> implements SdkBundle {
  final fb.BufferPointer _bp;

  const _SdkBundleReader([this._bp]);

  @override
  _SdkBundleReader createReader(fb.BufferPointer bp) => new _SdkBundleReader(bp);

  @override
  Map<String, Object> toMap() => {
    "prelinkedLibraryUris": prelinkedLibraryUris,
    "prelinkedLibraries": prelinkedLibraries,
    "unlinkedUnitUris": unlinkedUnitUris,
    "unlinkedUnits": unlinkedUnits,
  };

  @override
  List<String> get prelinkedLibraryUris => const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 0, const <String>[]);

  @override
  List<PrelinkedLibrary> get prelinkedLibraries => const fb.ListReader<PrelinkedLibrary>(const _PrelinkedLibraryReader()).vTableGet(_bp, 1, const <PrelinkedLibrary>[]);

  @override
  List<String> get unlinkedUnitUris => const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 2, const <String>[]);

  @override
  List<UnlinkedUnit> get unlinkedUnits => const fb.ListReader<UnlinkedUnit>(const _UnlinkedUnitReader()).vTableGet(_bp, 3, const <UnlinkedUnit>[]);
}

class UnlinkedClassBuilder {
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

  UnlinkedClassBuilder(base.BuilderContext context);

  /**
   * Name of the class.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  /**
   * Offset of the class name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  /**
   * Documentation comment for the class, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  /**
   * Type parameters of the class, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    _typeParameters = _value;
  }

  /**
   * Supertype of the class, or `null` if either (a) the class doesn't
   * explicitly declare a supertype (and hence has supertype `Object`), or (b)
   * the class *is* `Object` (and hence has no supertype).
   */
  void set supertype(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _supertype = _value;
  }

  /**
   * Mixins appearing in a `with` clause, if any.
   */
  void set mixins(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    _mixins = _value;
  }

  /**
   * Interfaces appearing in an `implements` clause, if any.
   */
  void set interfaces(List<UnlinkedTypeRefBuilder> _value) {
    assert(!_finished);
    _interfaces = _value;
  }

  /**
   * Field declarations contained in the class.
   */
  void set fields(List<UnlinkedVariableBuilder> _value) {
    assert(!_finished);
    _fields = _value;
  }

  /**
   * Executable objects (methods, getters, and setters) contained in the class.
   */
  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    _executables = _value;
  }

  /**
   * Indicates whether the class is declared with the `abstract` keyword.
   */
  void set isAbstract(bool _value) {
    assert(!_finished);
    _isAbstract = _value;
  }

  /**
   * Indicates whether the class is declared using mixin application syntax.
   */
  void set isMixinApplication(bool _value) {
    assert(!_finished);
    _isMixinApplication = _value;
  }

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
      fbBuilder.addInt8(9, 1);
    }
    if (_isMixinApplication == true) {
      fbBuilder.addInt8(10, 1);
    }
    if (_hasNoSupertype == true) {
      fbBuilder.addInt8(11, 1);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedClassBuilder encodeUnlinkedClass(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder supertype, List<UnlinkedTypeRefBuilder> mixins, List<UnlinkedTypeRefBuilder> interfaces, List<UnlinkedVariableBuilder> fields, List<UnlinkedExecutableBuilder> executables, bool isAbstract, bool isMixinApplication, bool hasNoSupertype}) {
  UnlinkedClassBuilder builder = new UnlinkedClassBuilder(builderContext);
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

class _UnlinkedClassReader extends fb.TableReader<_UnlinkedClassReader> implements UnlinkedClass {
  final fb.BufferPointer _bp;

  const _UnlinkedClassReader([this._bp]);

  @override
  _UnlinkedClassReader createReader(fb.BufferPointer bp) => new _UnlinkedClassReader(bp);

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

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get nameOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  UnlinkedDocumentationComment get documentationComment => const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);

  @override
  List<UnlinkedTypeParam> get typeParameters => const fb.ListReader<UnlinkedTypeParam>(const _UnlinkedTypeParamReader()).vTableGet(_bp, 3, const <UnlinkedTypeParam>[]);

  @override
  UnlinkedTypeRef get supertype => const _UnlinkedTypeRefReader().vTableGet(_bp, 4, null);

  @override
  List<UnlinkedTypeRef> get mixins => const fb.ListReader<UnlinkedTypeRef>(const _UnlinkedTypeRefReader()).vTableGet(_bp, 5, const <UnlinkedTypeRef>[]);

  @override
  List<UnlinkedTypeRef> get interfaces => const fb.ListReader<UnlinkedTypeRef>(const _UnlinkedTypeRefReader()).vTableGet(_bp, 6, const <UnlinkedTypeRef>[]);

  @override
  List<UnlinkedVariable> get fields => const fb.ListReader<UnlinkedVariable>(const _UnlinkedVariableReader()).vTableGet(_bp, 7, const <UnlinkedVariable>[]);

  @override
  List<UnlinkedExecutable> get executables => const fb.ListReader<UnlinkedExecutable>(const _UnlinkedExecutableReader()).vTableGet(_bp, 8, const <UnlinkedExecutable>[]);

  @override
  bool get isAbstract => const fb.Int8Reader().vTableGet(_bp, 9, 0) == 1;

  @override
  bool get isMixinApplication => const fb.Int8Reader().vTableGet(_bp, 10, 0) == 1;

  @override
  bool get hasNoSupertype => const fb.Int8Reader().vTableGet(_bp, 11, 0) == 1;
}

class UnlinkedCombinatorBuilder {
  bool _finished = false;

  List<String> _shows;
  List<String> _hides;

  UnlinkedCombinatorBuilder(base.BuilderContext context);

  /**
   * List of names which are shown.  Empty if this is a `hide` combinator.
   */
  void set shows(List<String> _value) {
    assert(!_finished);
    _shows = _value;
  }

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

UnlinkedCombinatorBuilder encodeUnlinkedCombinator(base.BuilderContext builderContext, {List<String> shows, List<String> hides}) {
  UnlinkedCombinatorBuilder builder = new UnlinkedCombinatorBuilder(builderContext);
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

class _UnlinkedCombinatorReader extends fb.TableReader<_UnlinkedCombinatorReader> implements UnlinkedCombinator {
  final fb.BufferPointer _bp;

  const _UnlinkedCombinatorReader([this._bp]);

  @override
  _UnlinkedCombinatorReader createReader(fb.BufferPointer bp) => new _UnlinkedCombinatorReader(bp);

  @override
  Map<String, Object> toMap() => {
    "shows": shows,
    "hides": hides,
  };

  @override
  List<String> get shows => const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 0, const <String>[]);

  @override
  List<String> get hides => const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 1, const <String>[]);
}

class UnlinkedDocumentationCommentBuilder {
  bool _finished = false;

  String _text;
  int _offset;
  int _length;

  UnlinkedDocumentationCommentBuilder(base.BuilderContext context);

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

  /**
   * Offset of the beginning of the documentation comment relative to the
   * beginning of the file.
   */
  void set offset(int _value) {
    assert(!_finished);
    _offset = _value;
  }

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

UnlinkedDocumentationCommentBuilder encodeUnlinkedDocumentationComment(base.BuilderContext builderContext, {String text, int offset, int length}) {
  UnlinkedDocumentationCommentBuilder builder = new UnlinkedDocumentationCommentBuilder(builderContext);
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

class _UnlinkedDocumentationCommentReader extends fb.TableReader<_UnlinkedDocumentationCommentReader> implements UnlinkedDocumentationComment {
  final fb.BufferPointer _bp;

  const _UnlinkedDocumentationCommentReader([this._bp]);

  @override
  _UnlinkedDocumentationCommentReader createReader(fb.BufferPointer bp) => new _UnlinkedDocumentationCommentReader(bp);

  @override
  Map<String, Object> toMap() => {
    "text": text,
    "offset": offset,
    "length": length,
  };

  @override
  String get text => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get offset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  int get length => const fb.Int32Reader().vTableGet(_bp, 2, 0);
}

class UnlinkedEnumBuilder {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  List<UnlinkedEnumValueBuilder> _values;

  UnlinkedEnumBuilder(base.BuilderContext context);

  /**
   * Name of the enum type.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  /**
   * Offset of the enum name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  /**
   * Documentation comment for the enum, or `null` if there is no documentation
   * comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

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

UnlinkedEnumBuilder encodeUnlinkedEnum(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedEnumValueBuilder> values}) {
  UnlinkedEnumBuilder builder = new UnlinkedEnumBuilder(builderContext);
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

class _UnlinkedEnumReader extends fb.TableReader<_UnlinkedEnumReader> implements UnlinkedEnum {
  final fb.BufferPointer _bp;

  const _UnlinkedEnumReader([this._bp]);

  @override
  _UnlinkedEnumReader createReader(fb.BufferPointer bp) => new _UnlinkedEnumReader(bp);

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
    "values": values,
  };

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get nameOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  UnlinkedDocumentationComment get documentationComment => const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);

  @override
  List<UnlinkedEnumValue> get values => const fb.ListReader<UnlinkedEnumValue>(const _UnlinkedEnumValueReader()).vTableGet(_bp, 3, const <UnlinkedEnumValue>[]);
}

class UnlinkedEnumValueBuilder {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;

  UnlinkedEnumValueBuilder(base.BuilderContext context);

  /**
   * Name of the enumerated value.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  /**
   * Offset of the enum value name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

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

UnlinkedEnumValueBuilder encodeUnlinkedEnumValue(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment}) {
  UnlinkedEnumValueBuilder builder = new UnlinkedEnumValueBuilder(builderContext);
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

class _UnlinkedEnumValueReader extends fb.TableReader<_UnlinkedEnumValueReader> implements UnlinkedEnumValue {
  final fb.BufferPointer _bp;

  const _UnlinkedEnumValueReader([this._bp]);

  @override
  _UnlinkedEnumValueReader createReader(fb.BufferPointer bp) => new _UnlinkedEnumValueReader(bp);

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
  };

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get nameOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  UnlinkedDocumentationComment get documentationComment => const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);
}

class UnlinkedExecutableBuilder {
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

  UnlinkedExecutableBuilder(base.BuilderContext context);

  /**
   * Name of the executable.  For setters, this includes the trailing "=".  For
   * named constructors, this excludes the class name and excludes the ".".
   * For unnamed constructors, this is the empty string.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

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

  /**
   * Documentation comment for the executable, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  /**
   * Type parameters of the executable, if any.  Empty if support for generic
   * method syntax is disabled.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    _typeParameters = _value;
  }

  /**
   * Declared return type of the executable.  Absent if the return type is
   * `void` or the executable is a constructor.  Note that when strong mode is
   * enabled, the actual return type may be different due to type inference.
   */
  void set returnType(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _returnType = _value;
  }

  /**
   * Parameters of the executable, if any.  Note that getters have no
   * parameters (hence this will be the empty list), and setters have a single
   * parameter.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    _parameters = _value;
  }

  /**
   * The kind of the executable (function/method, getter, setter, or
   * constructor).
   */
  void set kind(UnlinkedExecutableKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  /**
   * Indicates whether the executable is declared using the `abstract` keyword.
   */
  void set isAbstract(bool _value) {
    assert(!_finished);
    _isAbstract = _value;
  }

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

  /**
   * Indicates whether the executable is declared using the `const` keyword.
   */
  void set isConst(bool _value) {
    assert(!_finished);
    _isConst = _value;
  }

  /**
   * Indicates whether the executable is declared using the `factory` keyword.
   */
  void set isFactory(bool _value) {
    assert(!_finished);
    _isFactory = _value;
  }

  /**
   * Indicates whether the executable lacks an explicit return type
   * declaration.  False for constructors and setters.
   */
  void set hasImplicitReturnType(bool _value) {
    assert(!_finished);
    _hasImplicitReturnType = _value;
  }

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
      fbBuilder.addInt8(7, 1);
    }
    if (_isStatic == true) {
      fbBuilder.addInt8(8, 1);
    }
    if (_isConst == true) {
      fbBuilder.addInt8(9, 1);
    }
    if (_isFactory == true) {
      fbBuilder.addInt8(10, 1);
    }
    if (_hasImplicitReturnType == true) {
      fbBuilder.addInt8(11, 1);
    }
    if (_isExternal == true) {
      fbBuilder.addInt8(12, 1);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedExecutableBuilder encodeUnlinkedExecutable(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters, UnlinkedExecutableKind kind, bool isAbstract, bool isStatic, bool isConst, bool isFactory, bool hasImplicitReturnType, bool isExternal}) {
  UnlinkedExecutableBuilder builder = new UnlinkedExecutableBuilder(builderContext);
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

class _UnlinkedExecutableReader extends fb.TableReader<_UnlinkedExecutableReader> implements UnlinkedExecutable {
  final fb.BufferPointer _bp;

  const _UnlinkedExecutableReader([this._bp]);

  @override
  _UnlinkedExecutableReader createReader(fb.BufferPointer bp) => new _UnlinkedExecutableReader(bp);

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

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get nameOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  UnlinkedDocumentationComment get documentationComment => const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);

  @override
  List<UnlinkedTypeParam> get typeParameters => const fb.ListReader<UnlinkedTypeParam>(const _UnlinkedTypeParamReader()).vTableGet(_bp, 3, const <UnlinkedTypeParam>[]);

  @override
  UnlinkedTypeRef get returnType => const _UnlinkedTypeRefReader().vTableGet(_bp, 4, null);

  @override
  List<UnlinkedParam> get parameters => const fb.ListReader<UnlinkedParam>(const _UnlinkedParamReader()).vTableGet(_bp, 5, const <UnlinkedParam>[]);

  @override
  UnlinkedExecutableKind get kind {
    int index = const fb.Int32Reader().vTableGet(_bp, 6, 0);
    return UnlinkedExecutableKind.values[index];
  }

  @override
  bool get isAbstract => const fb.Int8Reader().vTableGet(_bp, 7, 0) == 1;

  @override
  bool get isStatic => const fb.Int8Reader().vTableGet(_bp, 8, 0) == 1;

  @override
  bool get isConst => const fb.Int8Reader().vTableGet(_bp, 9, 0) == 1;

  @override
  bool get isFactory => const fb.Int8Reader().vTableGet(_bp, 10, 0) == 1;

  @override
  bool get hasImplicitReturnType => const fb.Int8Reader().vTableGet(_bp, 11, 0) == 1;

  @override
  bool get isExternal => const fb.Int8Reader().vTableGet(_bp, 12, 0) == 1;
}

class UnlinkedExportNonPublicBuilder {
  bool _finished = false;

  int _offset;
  int _uriOffset;
  int _uriEnd;

  UnlinkedExportNonPublicBuilder(base.BuilderContext context);

  /**
   * Offset of the "export" keyword.
   */
  void set offset(int _value) {
    assert(!_finished);
    _offset = _value;
  }

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    _uriOffset = _value;
  }

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

UnlinkedExportNonPublicBuilder encodeUnlinkedExportNonPublic(base.BuilderContext builderContext, {int offset, int uriOffset, int uriEnd}) {
  UnlinkedExportNonPublicBuilder builder = new UnlinkedExportNonPublicBuilder(builderContext);
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

class _UnlinkedExportNonPublicReader extends fb.TableReader<_UnlinkedExportNonPublicReader> implements UnlinkedExportNonPublic {
  final fb.BufferPointer _bp;

  const _UnlinkedExportNonPublicReader([this._bp]);

  @override
  _UnlinkedExportNonPublicReader createReader(fb.BufferPointer bp) => new _UnlinkedExportNonPublicReader(bp);

  @override
  Map<String, Object> toMap() => {
    "offset": offset,
    "uriOffset": uriOffset,
    "uriEnd": uriEnd,
  };

  @override
  int get offset => const fb.Int32Reader().vTableGet(_bp, 0, 0);

  @override
  int get uriOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  int get uriEnd => const fb.Int32Reader().vTableGet(_bp, 2, 0);
}

class UnlinkedExportPublicBuilder {
  bool _finished = false;

  String _uri;
  List<UnlinkedCombinatorBuilder> _combinators;

  UnlinkedExportPublicBuilder(base.BuilderContext context);

  /**
   * URI used in the source code to reference the exported library.
   */
  void set uri(String _value) {
    assert(!_finished);
    _uri = _value;
  }

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

UnlinkedExportPublicBuilder encodeUnlinkedExportPublic(base.BuilderContext builderContext, {String uri, List<UnlinkedCombinatorBuilder> combinators}) {
  UnlinkedExportPublicBuilder builder = new UnlinkedExportPublicBuilder(builderContext);
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

class _UnlinkedExportPublicReader extends fb.TableReader<_UnlinkedExportPublicReader> implements UnlinkedExportPublic {
  final fb.BufferPointer _bp;

  const _UnlinkedExportPublicReader([this._bp]);

  @override
  _UnlinkedExportPublicReader createReader(fb.BufferPointer bp) => new _UnlinkedExportPublicReader(bp);

  @override
  Map<String, Object> toMap() => {
    "uri": uri,
    "combinators": combinators,
  };

  @override
  String get uri => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  List<UnlinkedCombinator> get combinators => const fb.ListReader<UnlinkedCombinator>(const _UnlinkedCombinatorReader()).vTableGet(_bp, 1, const <UnlinkedCombinator>[]);
}

class UnlinkedImportBuilder {
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

  UnlinkedImportBuilder(base.BuilderContext context);

  /**
   * URI used in the source code to reference the imported library.
   */
  void set uri(String _value) {
    assert(!_finished);
    _uri = _value;
  }

  /**
   * If [isImplicit] is false, offset of the "import" keyword.  If [isImplicit]
   * is true, zero.
   */
  void set offset(int _value) {
    assert(!_finished);
    _offset = _value;
  }

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

  /**
   * Combinators contained in this import declaration.
   */
  void set combinators(List<UnlinkedCombinatorBuilder> _value) {
    assert(!_finished);
    _combinators = _value;
  }

  /**
   * Indicates whether the import declaration uses the `deferred` keyword.
   */
  void set isDeferred(bool _value) {
    assert(!_finished);
    _isDeferred = _value;
  }

  /**
   * Indicates whether the import declaration is implicit.
   */
  void set isImplicit(bool _value) {
    assert(!_finished);
    _isImplicit = _value;
  }

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.  If [isImplicit] is true, zero.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    _uriOffset = _value;
  }

  /**
   * End of the URI string (including quotes) relative to the beginning of the
   * file.  If [isImplicit] is true, zero.
   */
  void set uriEnd(int _value) {
    assert(!_finished);
    _uriEnd = _value;
  }

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
      fbBuilder.addInt8(4, 1);
    }
    if (_isImplicit == true) {
      fbBuilder.addInt8(5, 1);
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

UnlinkedImportBuilder encodeUnlinkedImport(base.BuilderContext builderContext, {String uri, int offset, int prefixReference, List<UnlinkedCombinatorBuilder> combinators, bool isDeferred, bool isImplicit, int uriOffset, int uriEnd, int prefixOffset}) {
  UnlinkedImportBuilder builder = new UnlinkedImportBuilder(builderContext);
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

class _UnlinkedImportReader extends fb.TableReader<_UnlinkedImportReader> implements UnlinkedImport {
  final fb.BufferPointer _bp;

  const _UnlinkedImportReader([this._bp]);

  @override
  _UnlinkedImportReader createReader(fb.BufferPointer bp) => new _UnlinkedImportReader(bp);

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

  @override
  String get uri => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get offset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  int get prefixReference => const fb.Int32Reader().vTableGet(_bp, 2, 0);

  @override
  List<UnlinkedCombinator> get combinators => const fb.ListReader<UnlinkedCombinator>(const _UnlinkedCombinatorReader()).vTableGet(_bp, 3, const <UnlinkedCombinator>[]);

  @override
  bool get isDeferred => const fb.Int8Reader().vTableGet(_bp, 4, 0) == 1;

  @override
  bool get isImplicit => const fb.Int8Reader().vTableGet(_bp, 5, 0) == 1;

  @override
  int get uriOffset => const fb.Int32Reader().vTableGet(_bp, 6, 0);

  @override
  int get uriEnd => const fb.Int32Reader().vTableGet(_bp, 7, 0);

  @override
  int get prefixOffset => const fb.Int32Reader().vTableGet(_bp, 8, 0);
}

class UnlinkedParamBuilder {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedTypeRefBuilder _type;
  List<UnlinkedParamBuilder> _parameters;
  UnlinkedParamKind _kind;
  bool _isFunctionTyped;
  bool _isInitializingFormal;
  bool _hasImplicitType;

  UnlinkedParamBuilder(base.BuilderContext context);

  /**
   * Name of the parameter.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  /**
   * Offset of the parameter name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

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

  /**
   * If [isFunctionTyped] is `true`, the parameters of the function type.
   */
  void set parameters(List<UnlinkedParamBuilder> _value) {
    assert(!_finished);
    _parameters = _value;
  }

  /**
   * Kind of the parameter.
   */
  void set kind(UnlinkedParamKind _value) {
    assert(!_finished);
    _kind = _value;
  }

  /**
   * Indicates whether this is a function-typed parameter.
   */
  void set isFunctionTyped(bool _value) {
    assert(!_finished);
    _isFunctionTyped = _value;
  }

  /**
   * Indicates whether this is an initializing formal parameter (i.e. it is
   * declared using `this.` syntax).
   */
  void set isInitializingFormal(bool _value) {
    assert(!_finished);
    _isInitializingFormal = _value;
  }

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
      fbBuilder.addInt8(5, 1);
    }
    if (_isInitializingFormal == true) {
      fbBuilder.addInt8(6, 1);
    }
    if (_hasImplicitType == true) {
      fbBuilder.addInt8(7, 1);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedParamBuilder encodeUnlinkedParam(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedTypeRefBuilder type, List<UnlinkedParamBuilder> parameters, UnlinkedParamKind kind, bool isFunctionTyped, bool isInitializingFormal, bool hasImplicitType}) {
  UnlinkedParamBuilder builder = new UnlinkedParamBuilder(builderContext);
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

class _UnlinkedParamReader extends fb.TableReader<_UnlinkedParamReader> implements UnlinkedParam {
  final fb.BufferPointer _bp;

  const _UnlinkedParamReader([this._bp]);

  @override
  _UnlinkedParamReader createReader(fb.BufferPointer bp) => new _UnlinkedParamReader(bp);

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

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get nameOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  UnlinkedTypeRef get type => const _UnlinkedTypeRefReader().vTableGet(_bp, 2, null);

  @override
  List<UnlinkedParam> get parameters => const fb.ListReader<UnlinkedParam>(const _UnlinkedParamReader()).vTableGet(_bp, 3, const <UnlinkedParam>[]);

  @override
  UnlinkedParamKind get kind {
    int index = const fb.Int32Reader().vTableGet(_bp, 4, 0);
    return UnlinkedParamKind.values[index];
  }

  @override
  bool get isFunctionTyped => const fb.Int8Reader().vTableGet(_bp, 5, 0) == 1;

  @override
  bool get isInitializingFormal => const fb.Int8Reader().vTableGet(_bp, 6, 0) == 1;

  @override
  bool get hasImplicitType => const fb.Int8Reader().vTableGet(_bp, 7, 0) == 1;
}

class UnlinkedPartBuilder {
  bool _finished = false;

  int _uriOffset;
  int _uriEnd;

  UnlinkedPartBuilder(base.BuilderContext context);

  /**
   * Offset of the URI string (including quotes) relative to the beginning of
   * the file.
   */
  void set uriOffset(int _value) {
    assert(!_finished);
    _uriOffset = _value;
  }

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

UnlinkedPartBuilder encodeUnlinkedPart(base.BuilderContext builderContext, {int uriOffset, int uriEnd}) {
  UnlinkedPartBuilder builder = new UnlinkedPartBuilder(builderContext);
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

class _UnlinkedPartReader extends fb.TableReader<_UnlinkedPartReader> implements UnlinkedPart {
  final fb.BufferPointer _bp;

  const _UnlinkedPartReader([this._bp]);

  @override
  _UnlinkedPartReader createReader(fb.BufferPointer bp) => new _UnlinkedPartReader(bp);

  @override
  Map<String, Object> toMap() => {
    "uriOffset": uriOffset,
    "uriEnd": uriEnd,
  };

  @override
  int get uriOffset => const fb.Int32Reader().vTableGet(_bp, 0, 0);

  @override
  int get uriEnd => const fb.Int32Reader().vTableGet(_bp, 1, 0);
}

class UnlinkedPublicNameBuilder {
  bool _finished = false;

  String _name;
  PrelinkedReferenceKind _kind;
  int _numTypeParameters;

  UnlinkedPublicNameBuilder(base.BuilderContext context);

  /**
   * The name itself.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  /**
   * The kind of object referred to by the name.
   */
  void set kind(PrelinkedReferenceKind _value) {
    assert(!_finished);
    _kind = _value;
  }

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

UnlinkedPublicNameBuilder encodeUnlinkedPublicName(base.BuilderContext builderContext, {String name, PrelinkedReferenceKind kind, int numTypeParameters}) {
  UnlinkedPublicNameBuilder builder = new UnlinkedPublicNameBuilder(builderContext);
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

class _UnlinkedPublicNameReader extends fb.TableReader<_UnlinkedPublicNameReader> implements UnlinkedPublicName {
  final fb.BufferPointer _bp;

  const _UnlinkedPublicNameReader([this._bp]);

  @override
  _UnlinkedPublicNameReader createReader(fb.BufferPointer bp) => new _UnlinkedPublicNameReader(bp);

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "kind": kind,
    "numTypeParameters": numTypeParameters,
  };

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  PrelinkedReferenceKind get kind {
    int index = const fb.Int32Reader().vTableGet(_bp, 1, 0);
    return PrelinkedReferenceKind.values[index];
  }

  @override
  int get numTypeParameters => const fb.Int32Reader().vTableGet(_bp, 2, 0);
}

class UnlinkedPublicNamespaceBuilder {
  bool _finished = false;

  List<UnlinkedPublicNameBuilder> _names;
  List<UnlinkedExportPublicBuilder> _exports;
  List<String> _parts;

  UnlinkedPublicNamespaceBuilder(base.BuilderContext context);

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

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportPublicBuilder> _value) {
    assert(!_finished);
    _exports = _value;
  }

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

UnlinkedPublicNamespaceBuilder encodeUnlinkedPublicNamespace(base.BuilderContext builderContext, {List<UnlinkedPublicNameBuilder> names, List<UnlinkedExportPublicBuilder> exports, List<String> parts}) {
  UnlinkedPublicNamespaceBuilder builder = new UnlinkedPublicNamespaceBuilder(builderContext);
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

class _UnlinkedPublicNamespaceReader extends fb.TableReader<_UnlinkedPublicNamespaceReader> implements UnlinkedPublicNamespace {
  final fb.BufferPointer _bp;

  const _UnlinkedPublicNamespaceReader([this._bp]);

  @override
  _UnlinkedPublicNamespaceReader createReader(fb.BufferPointer bp) => new _UnlinkedPublicNamespaceReader(bp);

  @override
  Map<String, Object> toMap() => {
    "names": names,
    "exports": exports,
    "parts": parts,
  };

  @override
  List<UnlinkedPublicName> get names => const fb.ListReader<UnlinkedPublicName>(const _UnlinkedPublicNameReader()).vTableGet(_bp, 0, const <UnlinkedPublicName>[]);

  @override
  List<UnlinkedExportPublic> get exports => const fb.ListReader<UnlinkedExportPublic>(const _UnlinkedExportPublicReader()).vTableGet(_bp, 1, const <UnlinkedExportPublic>[]);

  @override
  List<String> get parts => const fb.ListReader<String>(const fb.StringReader()).vTableGet(_bp, 2, const <String>[]);
}

class UnlinkedReferenceBuilder {
  bool _finished = false;

  String _name;
  int _prefixReference;

  UnlinkedReferenceBuilder(base.BuilderContext context);

  /**
   * Name of the entity being referred to.  The empty string refers to the
   * pseudo-type `dynamic`.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  /**
   * Prefix used to refer to the entity, or zero if no prefix is used.  This is
   * an index into [UnlinkedUnit.references].
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

UnlinkedReferenceBuilder encodeUnlinkedReference(base.BuilderContext builderContext, {String name, int prefixReference}) {
  UnlinkedReferenceBuilder builder = new UnlinkedReferenceBuilder(builderContext);
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
   */
  int get prefixReference;
}

class _UnlinkedReferenceReader extends fb.TableReader<_UnlinkedReferenceReader> implements UnlinkedReference {
  final fb.BufferPointer _bp;

  const _UnlinkedReferenceReader([this._bp]);

  @override
  _UnlinkedReferenceReader createReader(fb.BufferPointer bp) => new _UnlinkedReferenceReader(bp);

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "prefixReference": prefixReference,
  };

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get prefixReference => const fb.Int32Reader().vTableGet(_bp, 1, 0);
}

class UnlinkedTypedefBuilder {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  List<UnlinkedTypeParamBuilder> _typeParameters;
  UnlinkedTypeRefBuilder _returnType;
  List<UnlinkedParamBuilder> _parameters;

  UnlinkedTypedefBuilder(base.BuilderContext context);

  /**
   * Name of the typedef.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  /**
   * Offset of the typedef name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  /**
   * Documentation comment for the typedef, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  /**
   * Type parameters of the typedef, if any.
   */
  void set typeParameters(List<UnlinkedTypeParamBuilder> _value) {
    assert(!_finished);
    _typeParameters = _value;
  }

  /**
   * Return type of the typedef.  Absent if the return type is `void`.
   */
  void set returnType(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _returnType = _value;
  }

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

UnlinkedTypedefBuilder encodeUnlinkedTypedef(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, List<UnlinkedTypeParamBuilder> typeParameters, UnlinkedTypeRefBuilder returnType, List<UnlinkedParamBuilder> parameters}) {
  UnlinkedTypedefBuilder builder = new UnlinkedTypedefBuilder(builderContext);
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

class _UnlinkedTypedefReader extends fb.TableReader<_UnlinkedTypedefReader> implements UnlinkedTypedef {
  final fb.BufferPointer _bp;

  const _UnlinkedTypedefReader([this._bp]);

  @override
  _UnlinkedTypedefReader createReader(fb.BufferPointer bp) => new _UnlinkedTypedefReader(bp);

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "documentationComment": documentationComment,
    "typeParameters": typeParameters,
    "returnType": returnType,
    "parameters": parameters,
  };

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get nameOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  UnlinkedDocumentationComment get documentationComment => const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);

  @override
  List<UnlinkedTypeParam> get typeParameters => const fb.ListReader<UnlinkedTypeParam>(const _UnlinkedTypeParamReader()).vTableGet(_bp, 3, const <UnlinkedTypeParam>[]);

  @override
  UnlinkedTypeRef get returnType => const _UnlinkedTypeRefReader().vTableGet(_bp, 4, null);

  @override
  List<UnlinkedParam> get parameters => const fb.ListReader<UnlinkedParam>(const _UnlinkedParamReader()).vTableGet(_bp, 5, const <UnlinkedParam>[]);
}

class UnlinkedTypeParamBuilder {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedTypeRefBuilder _bound;

  UnlinkedTypeParamBuilder(base.BuilderContext context);

  /**
   * Name of the type parameter.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  /**
   * Offset of the type parameter name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

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

UnlinkedTypeParamBuilder encodeUnlinkedTypeParam(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedTypeRefBuilder bound}) {
  UnlinkedTypeParamBuilder builder = new UnlinkedTypeParamBuilder(builderContext);
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

class _UnlinkedTypeParamReader extends fb.TableReader<_UnlinkedTypeParamReader> implements UnlinkedTypeParam {
  final fb.BufferPointer _bp;

  const _UnlinkedTypeParamReader([this._bp]);

  @override
  _UnlinkedTypeParamReader createReader(fb.BufferPointer bp) => new _UnlinkedTypeParamReader(bp);

  @override
  Map<String, Object> toMap() => {
    "name": name,
    "nameOffset": nameOffset,
    "bound": bound,
  };

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get nameOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  UnlinkedTypeRef get bound => const _UnlinkedTypeRefReader().vTableGet(_bp, 2, null);
}

class UnlinkedTypeRefBuilder {
  bool _finished = false;

  int _reference;
  int _paramReference;
  List<UnlinkedTypeRefBuilder> _typeArguments;

  UnlinkedTypeRefBuilder(base.BuilderContext context);

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

UnlinkedTypeRefBuilder encodeUnlinkedTypeRef(base.BuilderContext builderContext, {int reference, int paramReference, List<UnlinkedTypeRefBuilder> typeArguments}) {
  UnlinkedTypeRefBuilder builder = new UnlinkedTypeRefBuilder(builderContext);
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

class _UnlinkedTypeRefReader extends fb.TableReader<_UnlinkedTypeRefReader> implements UnlinkedTypeRef {
  final fb.BufferPointer _bp;

  const _UnlinkedTypeRefReader([this._bp]);

  @override
  _UnlinkedTypeRefReader createReader(fb.BufferPointer bp) => new _UnlinkedTypeRefReader(bp);

  @override
  Map<String, Object> toMap() => {
    "reference": reference,
    "paramReference": paramReference,
    "typeArguments": typeArguments,
  };

  @override
  int get reference => const fb.Int32Reader().vTableGet(_bp, 0, 0);

  @override
  int get paramReference => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  List<UnlinkedTypeRef> get typeArguments => const fb.ListReader<UnlinkedTypeRef>(const _UnlinkedTypeRefReader()).vTableGet(_bp, 2, const <UnlinkedTypeRef>[]);
}

class UnlinkedUnitBuilder {
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

  UnlinkedUnitBuilder(base.BuilderContext context);

  /**
   * Name of the library (from a "library" declaration, if present).
   */
  void set libraryName(String _value) {
    assert(!_finished);
    _libraryName = _value;
  }

  /**
   * Offset of the library name relative to the beginning of the file (or 0 if
   * the library has no name).
   */
  void set libraryNameOffset(int _value) {
    assert(!_finished);
    _libraryNameOffset = _value;
  }

  /**
   * Length of the library name as it appears in the source code (or 0 if the
   * library has no name).
   */
  void set libraryNameLength(int _value) {
    assert(!_finished);
    _libraryNameLength = _value;
  }

  /**
   * Documentation comment for the library, or `null` if there is no
   * documentation comment.
   */
  void set libraryDocumentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _libraryDocumentationComment = _value;
  }

  /**
   * Unlinked public namespace of this compilation unit.
   */
  void set publicNamespace(UnlinkedPublicNamespaceBuilder _value) {
    assert(!_finished);
    _publicNamespace = _value;
  }

  /**
   * Top level and prefixed names referred to by this compilation unit.  The
   * zeroth element of this array is always populated and always represents a
   * reference to the pseudo-type "dynamic".
   */
  void set references(List<UnlinkedReferenceBuilder> _value) {
    assert(!_finished);
    _references = _value;
  }

  /**
   * Classes declared in the compilation unit.
   */
  void set classes(List<UnlinkedClassBuilder> _value) {
    assert(!_finished);
    _classes = _value;
  }

  /**
   * Enums declared in the compilation unit.
   */
  void set enums(List<UnlinkedEnumBuilder> _value) {
    assert(!_finished);
    _enums = _value;
  }

  /**
   * Top level executable objects (functions, getters, and setters) declared in
   * the compilation unit.
   */
  void set executables(List<UnlinkedExecutableBuilder> _value) {
    assert(!_finished);
    _executables = _value;
  }

  /**
   * Export declarations in the compilation unit.
   */
  void set exports(List<UnlinkedExportNonPublicBuilder> _value) {
    assert(!_finished);
    _exports = _value;
  }

  /**
   * Import declarations in the compilation unit.
   */
  void set imports(List<UnlinkedImportBuilder> _value) {
    assert(!_finished);
    _imports = _value;
  }

  /**
   * Part declarations in the compilation unit.
   */
  void set parts(List<UnlinkedPartBuilder> _value) {
    assert(!_finished);
    _parts = _value;
  }

  /**
   * Typedefs declared in the compilation unit.
   */
  void set typedefs(List<UnlinkedTypedefBuilder> _value) {
    assert(!_finished);
    _typedefs = _value;
  }

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

UnlinkedUnitBuilder encodeUnlinkedUnit(base.BuilderContext builderContext, {String libraryName, int libraryNameOffset, int libraryNameLength, UnlinkedDocumentationCommentBuilder libraryDocumentationComment, UnlinkedPublicNamespaceBuilder publicNamespace, List<UnlinkedReferenceBuilder> references, List<UnlinkedClassBuilder> classes, List<UnlinkedEnumBuilder> enums, List<UnlinkedExecutableBuilder> executables, List<UnlinkedExportNonPublicBuilder> exports, List<UnlinkedImportBuilder> imports, List<UnlinkedPartBuilder> parts, List<UnlinkedTypedefBuilder> typedefs, List<UnlinkedVariableBuilder> variables}) {
  UnlinkedUnitBuilder builder = new UnlinkedUnitBuilder(builderContext);
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

class _UnlinkedUnitReader extends fb.TableReader<_UnlinkedUnitReader> implements UnlinkedUnit {
  final fb.BufferPointer _bp;

  const _UnlinkedUnitReader([this._bp]);

  @override
  _UnlinkedUnitReader createReader(fb.BufferPointer bp) => new _UnlinkedUnitReader(bp);

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

  @override
  String get libraryName => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get libraryNameOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  int get libraryNameLength => const fb.Int32Reader().vTableGet(_bp, 2, 0);

  @override
  UnlinkedDocumentationComment get libraryDocumentationComment => const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 3, null);

  @override
  UnlinkedPublicNamespace get publicNamespace => const _UnlinkedPublicNamespaceReader().vTableGet(_bp, 4, null);

  @override
  List<UnlinkedReference> get references => const fb.ListReader<UnlinkedReference>(const _UnlinkedReferenceReader()).vTableGet(_bp, 5, const <UnlinkedReference>[]);

  @override
  List<UnlinkedClass> get classes => const fb.ListReader<UnlinkedClass>(const _UnlinkedClassReader()).vTableGet(_bp, 6, const <UnlinkedClass>[]);

  @override
  List<UnlinkedEnum> get enums => const fb.ListReader<UnlinkedEnum>(const _UnlinkedEnumReader()).vTableGet(_bp, 7, const <UnlinkedEnum>[]);

  @override
  List<UnlinkedExecutable> get executables => const fb.ListReader<UnlinkedExecutable>(const _UnlinkedExecutableReader()).vTableGet(_bp, 8, const <UnlinkedExecutable>[]);

  @override
  List<UnlinkedExportNonPublic> get exports => const fb.ListReader<UnlinkedExportNonPublic>(const _UnlinkedExportNonPublicReader()).vTableGet(_bp, 9, const <UnlinkedExportNonPublic>[]);

  @override
  List<UnlinkedImport> get imports => const fb.ListReader<UnlinkedImport>(const _UnlinkedImportReader()).vTableGet(_bp, 10, const <UnlinkedImport>[]);

  @override
  List<UnlinkedPart> get parts => const fb.ListReader<UnlinkedPart>(const _UnlinkedPartReader()).vTableGet(_bp, 11, const <UnlinkedPart>[]);

  @override
  List<UnlinkedTypedef> get typedefs => const fb.ListReader<UnlinkedTypedef>(const _UnlinkedTypedefReader()).vTableGet(_bp, 12, const <UnlinkedTypedef>[]);

  @override
  List<UnlinkedVariable> get variables => const fb.ListReader<UnlinkedVariable>(const _UnlinkedVariableReader()).vTableGet(_bp, 13, const <UnlinkedVariable>[]);
}

class UnlinkedVariableBuilder {
  bool _finished = false;

  String _name;
  int _nameOffset;
  UnlinkedDocumentationCommentBuilder _documentationComment;
  UnlinkedTypeRefBuilder _type;
  bool _isStatic;
  bool _isFinal;
  bool _isConst;
  bool _hasImplicitType;

  UnlinkedVariableBuilder(base.BuilderContext context);

  /**
   * Name of the variable.
   */
  void set name(String _value) {
    assert(!_finished);
    _name = _value;
  }

  /**
   * Offset of the variable name relative to the beginning of the file.
   */
  void set nameOffset(int _value) {
    assert(!_finished);
    _nameOffset = _value;
  }

  /**
   * Documentation comment for the variable, or `null` if there is no
   * documentation comment.
   */
  void set documentationComment(UnlinkedDocumentationCommentBuilder _value) {
    assert(!_finished);
    _documentationComment = _value;
  }

  /**
   * Declared type of the variable.  Note that when strong mode is enabled, the
   * actual type of the variable may be different due to type inference.
   */
  void set type(UnlinkedTypeRefBuilder _value) {
    assert(!_finished);
    _type = _value;
  }

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

  /**
   * Indicates whether the variable is declared using the `final` keyword.
   */
  void set isFinal(bool _value) {
    assert(!_finished);
    _isFinal = _value;
  }

  /**
   * Indicates whether the variable is declared using the `const` keyword.
   */
  void set isConst(bool _value) {
    assert(!_finished);
    _isConst = _value;
  }

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
      fbBuilder.addInt8(4, 1);
    }
    if (_isFinal == true) {
      fbBuilder.addInt8(5, 1);
    }
    if (_isConst == true) {
      fbBuilder.addInt8(6, 1);
    }
    if (_hasImplicitType == true) {
      fbBuilder.addInt8(7, 1);
    }
    return fbBuilder.endTable();
  }
}

UnlinkedVariableBuilder encodeUnlinkedVariable(base.BuilderContext builderContext, {String name, int nameOffset, UnlinkedDocumentationCommentBuilder documentationComment, UnlinkedTypeRefBuilder type, bool isStatic, bool isFinal, bool isConst, bool hasImplicitType}) {
  UnlinkedVariableBuilder builder = new UnlinkedVariableBuilder(builderContext);
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

class _UnlinkedVariableReader extends fb.TableReader<_UnlinkedVariableReader> implements UnlinkedVariable {
  final fb.BufferPointer _bp;

  const _UnlinkedVariableReader([this._bp]);

  @override
  _UnlinkedVariableReader createReader(fb.BufferPointer bp) => new _UnlinkedVariableReader(bp);

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

  @override
  String get name => const fb.StringReader().vTableGet(_bp, 0, '');

  @override
  int get nameOffset => const fb.Int32Reader().vTableGet(_bp, 1, 0);

  @override
  UnlinkedDocumentationComment get documentationComment => const _UnlinkedDocumentationCommentReader().vTableGet(_bp, 2, null);

  @override
  UnlinkedTypeRef get type => const _UnlinkedTypeRefReader().vTableGet(_bp, 3, null);

  @override
  bool get isStatic => const fb.Int8Reader().vTableGet(_bp, 4, 0) == 1;

  @override
  bool get isFinal => const fb.Int8Reader().vTableGet(_bp, 5, 0) == 1;

  @override
  bool get isConst => const fb.Int8Reader().vTableGet(_bp, 6, 0) == 1;

  @override
  bool get hasImplicitType => const fb.Int8Reader().vTableGet(_bp, 7, 0) == 1;
}

