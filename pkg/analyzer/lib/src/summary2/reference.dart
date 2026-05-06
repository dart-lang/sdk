// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';

final class BuiltInReference extends Reference implements ExportableReference {
  final LibraryReference library;

  final _BuiltInReferenceKind _kind;

  BuiltInReference._({
    required this.library,
    required _BuiltInReferenceKind kind,
  }) : _kind = kind,
       super._();
}

sealed class DeclarationReference extends Reference {
  /// The stable identity component for this declaration under its enclosing
  /// reference.
  ///
  /// This key is internal to reference identity. It is not necessarily the
  /// user-visible name written in source, because unnamed and duplicate
  /// declarations receive generated keys.
  final String _key;

  DeclarationReference._({required String key}) : _key = key, super._();
}

sealed class ExportableReference implements Reference {}

final class LeafTopLevelReference extends TopLevelReference {
  LeafTopLevelReference._({
    required super.library,
    required super.key,
    required super.kind,
  }) : super._();
}

final class LibraryReference extends Reference {
  final String uriString;

  final List<Map<String, TopLevelReference>?> _topLevelsByKind = List.filled(
    _TopLevelReferenceKind.values.length,
    null,
  );
  List<BuiltInReference?>? _builtInByKind;

  LibraryReference._({required this.uriString}) : super._();

  @override
  List<Reference> get children => [
    for (var byKey in _topLevelsByKind) ...?byKey?.values,
    if (_builtInByKind case var builtInByKind?)
      for (var builtIn in builtInByKind) ?builtIn,
  ];

  BuiltInReference get dynamicRef {
    assert(uriString == 'dart:core');
    return _builtIn(_BuiltInReferenceKind.dynamic_);
  }

  BuiltInReference get neverRef {
    assert(uriString == 'dart:core');
    return _builtIn(_BuiltInReferenceKind.never_);
  }

  Uri get uri => uriCache.parse(uriString);

  MemberContainerReference declareClass(String key) {
    return _declareMemberContainer(
      kind: _TopLevelReferenceKind.class_,
      key: key,
    );
  }

  MemberContainerReference declareEnum(String key) {
    return _declareMemberContainer(
      kind: _TopLevelReferenceKind.enum_,
      key: key,
    );
  }

  MemberContainerReference declareExtension(String key) {
    return _declareMemberContainer(
      kind: _TopLevelReferenceKind.extension_,
      key: key,
    );
  }

  MemberContainerReference declareExtensionType(String key) {
    return _declareMemberContainer(
      kind: _TopLevelReferenceKind.extensionType,
      key: key,
    );
  }

  TopLevelReference declareGetter(String key) {
    return _declareTopLevel(kind: _TopLevelReferenceKind.getter, key: key);
  }

  MemberContainerReference declareMixin(String key) {
    return _declareMemberContainer(
      kind: _TopLevelReferenceKind.mixin_,
      key: key,
    );
  }

  TopLevelReference declareSetter(String key) {
    return _declareTopLevel(kind: _TopLevelReferenceKind.setter, key: key);
  }

  TopLevelReference declareTopLevelFunction(String key) {
    return _declareTopLevel(kind: _TopLevelReferenceKind.function, key: key);
  }

  TopLevelReference declareTopLevelVariable(String key) {
    return _declareTopLevel(
      kind: _TopLevelReferenceKind.topLevelVariable,
      key: key,
    );
  }

  TopLevelReference declareTypeAlias(String key) {
    return _declareTopLevel(kind: _TopLevelReferenceKind.typeAlias, key: key);
  }

  MemberContainerReference getOrCreateClass(String key) {
    return _getOrCreateMemberContainer(
      kind: _TopLevelReferenceKind.class_,
      key: key,
    );
  }

  MemberContainerReference getOrCreateEnum(String key) {
    return _getOrCreateMemberContainer(
      kind: _TopLevelReferenceKind.enum_,
      key: key,
    );
  }

  MemberContainerReference getOrCreateExtension(String key) {
    return _getOrCreateMemberContainer(
      kind: _TopLevelReferenceKind.extension_,
      key: key,
    );
  }

  MemberContainerReference getOrCreateExtensionType(String key) {
    return _getOrCreateMemberContainer(
      kind: _TopLevelReferenceKind.extensionType,
      key: key,
    );
  }

  TopLevelReference getOrCreateGetter(String key) {
    return _getOrCreateTopLevel(kind: _TopLevelReferenceKind.getter, key: key);
  }

  MemberContainerReference getOrCreateMixin(String key) {
    return _getOrCreateMemberContainer(
      kind: _TopLevelReferenceKind.mixin_,
      key: key,
    );
  }

  TopLevelReference getOrCreateSetter(String key) {
    return _getOrCreateTopLevel(kind: _TopLevelReferenceKind.setter, key: key);
  }

  TopLevelReference getOrCreateTopLevelFunction(String key) {
    return _getOrCreateTopLevel(
      kind: _TopLevelReferenceKind.function,
      key: key,
    );
  }

  TopLevelReference getOrCreateTopLevelVariable(String key) {
    return _getOrCreateTopLevel(
      kind: _TopLevelReferenceKind.topLevelVariable,
      key: key,
    );
  }

  TopLevelReference getOrCreateTypeAlias(String key) {
    return _getOrCreateTopLevel(
      kind: _TopLevelReferenceKind.typeAlias,
      key: key,
    );
  }

  BuiltInReference _builtIn(_BuiltInReferenceKind kind) {
    var builtInByKind = _builtInByKind ??= List.filled(
      _BuiltInReferenceKind.values.length,
      null,
    );
    return builtInByKind[kind.index] ??= BuiltInReference._(
      library: this,
      kind: kind,
    );
  }

  TopLevelReference _createTopLevelReference(
    _TopLevelReferenceKind kind,
    String key,
  ) {
    if (kind.hasMembers) {
      return MemberContainerReference._(library: this, key: key, kind: kind);
    }
    return LeafTopLevelReference._(library: this, key: key, kind: kind);
  }

  MemberContainerReference _declareMemberContainer({
    required _TopLevelReferenceKind kind,
    required String key,
  }) {
    var byKey = _topLevelByKey(kind);
    if (byKey[key] != null) {
      throw StateError('Duplicate reference key: $key');
    }

    return byKey[key] = MemberContainerReference._(
      library: this,
      key: key,
      kind: kind,
    );
  }

  TopLevelReference _declareTopLevel({
    required _TopLevelReferenceKind kind,
    required String key,
  }) {
    return Reference._declare(
      byKey: _topLevelByKey(kind),
      key: key,
      create: (key) => _createTopLevelReference(kind, key),
    );
  }

  MemberContainerReference _getOrCreateMemberContainer({
    required _TopLevelReferenceKind kind,
    required String key,
  }) {
    var byKey = _topLevelByKey(kind);
    if (byKey[key] case MemberContainerReference existing) {
      return existing;
    }

    var result = MemberContainerReference._(
      library: this,
      key: key,
      kind: kind,
    );
    byKey[key] = result;
    return result;
  }

  TopLevelReference _getOrCreateTopLevel({
    required _TopLevelReferenceKind kind,
    required String key,
  }) {
    return _topLevelByKey(kind)[key] ??= _createTopLevelReference(kind, key);
  }

  Map<String, TopLevelReference> _topLevelByKey(_TopLevelReferenceKind kind) {
    return _topLevelsByKind[kind.index] ??= {};
  }
}

final class LibraryReferenceBuilder {
  final LibraryReference reference;
  final Map<Reference, _KeyAllocator> _keyAllocatorByReference = Map.identity();

  LibraryReferenceBuilder(this.reference);

  MemberContainerReference declareClass(String? name) {
    return reference.declareClass(
      _allocateTopLevelKey(kind: _TopLevelReferenceKind.class_, name: name),
    );
  }

  MemberContainerReference declareEnum(String? name) {
    return reference.declareEnum(
      _allocateTopLevelKey(kind: _TopLevelReferenceKind.enum_, name: name),
    );
  }

  MemberContainerReference declareExtension(String? name) {
    return reference.declareExtension(
      _allocateTopLevelKey(kind: _TopLevelReferenceKind.extension_, name: name),
    );
  }

  MemberContainerReference declareExtensionType(String? name) {
    return reference.declareExtensionType(
      _allocateTopLevelKey(
        kind: _TopLevelReferenceKind.extensionType,
        name: name,
      ),
    );
  }

  TopLevelReference declareGetter(String? name) {
    return reference.declareGetter(
      _allocateTopLevelKey(kind: _TopLevelReferenceKind.getter, name: name),
    );
  }

  MemberReference declareMemberConstructor({
    required MemberContainerReference container,
    required String? name,
  }) {
    return container.declareConstructor(
      _allocateMemberKey(
        container: container,
        kind: _MemberReferenceKind.constructor,
        name: name,
      ),
    );
  }

  MemberReference declareMemberField({
    required MemberContainerReference container,
    required String? name,
  }) {
    return container.declareField(
      _allocateMemberKey(
        container: container,
        kind: _MemberReferenceKind.field,
        name: name,
      ),
    );
  }

  MemberReference declareMemberGetter({
    required MemberContainerReference container,
    required String? name,
  }) {
    return container.declareGetter(
      _allocateMemberKey(
        container: container,
        kind: _MemberReferenceKind.getter,
        name: name,
      ),
    );
  }

  MemberReference declareMemberMethod({
    required MemberContainerReference container,
    required String? name,
  }) {
    return container.declareMethod(
      _allocateMemberKey(
        container: container,
        kind: _MemberReferenceKind.method,
        name: name,
      ),
    );
  }

  MemberReference declareMemberSetter({
    required MemberContainerReference container,
    required String? name,
  }) {
    return container.declareSetter(
      _allocateMemberKey(
        container: container,
        kind: _MemberReferenceKind.setter,
        name: name,
      ),
    );
  }

  MemberContainerReference declareMixin(String? name) {
    return reference.declareMixin(
      _allocateTopLevelKey(kind: _TopLevelReferenceKind.mixin_, name: name),
    );
  }

  TopLevelReference declareSetter(String? name) {
    return reference.declareSetter(
      _allocateTopLevelKey(kind: _TopLevelReferenceKind.setter, name: name),
    );
  }

  TopLevelReference declareTopLevelFunction(String? name) {
    return reference.declareTopLevelFunction(
      _allocateTopLevelKey(kind: _TopLevelReferenceKind.function, name: name),
    );
  }

  TopLevelReference declareTopLevelVariable(String? name) {
    return reference.declareTopLevelVariable(
      _allocateTopLevelKey(
        kind: _TopLevelReferenceKind.topLevelVariable,
        name: name,
      ),
    );
  }

  TopLevelReference declareTypeAlias(String? name) {
    return reference.declareTypeAlias(
      _allocateTopLevelKey(kind: _TopLevelReferenceKind.typeAlias, name: name),
    );
  }

  String _allocateMemberKey({
    required MemberContainerReference container,
    required _MemberReferenceKind kind,
    required String? name,
  }) {
    return (_keyAllocatorByReference[container] ??= _KeyAllocator(
      kindCount: _MemberReferenceKind.values.length,
    )).allocate(kindIndex: kind.index, name: name);
  }

  String _allocateTopLevelKey({
    required _TopLevelReferenceKind kind,
    required String? name,
  }) {
    return (_keyAllocatorByReference[reference] ??= _KeyAllocator(
      kindCount: _TopLevelReferenceKind.values.length,
    )).allocate(kindIndex: kind.index, name: name);
  }
}

final class MemberContainerReference extends TopLevelReference {
  final List<Map<String, MemberReference>?> _membersByKind = List.filled(
    _MemberReferenceKind.values.length,
    null,
  );

  MemberContainerReference._({
    required super.library,
    required super.key,
    required super.kind,
  }) : super._();

  @override
  List<Reference> get children => [
    for (var byKey in _membersByKind) ...?byKey?.values,
  ];

  MemberReference declareConstructor(String key) {
    return _declareMember(kind: _MemberReferenceKind.constructor, key: key);
  }

  MemberReference declareField(String key) {
    return _declareMember(kind: _MemberReferenceKind.field, key: key);
  }

  MemberReference declareGetter(String key) {
    return _declareMember(kind: _MemberReferenceKind.getter, key: key);
  }

  MemberReference declareMethod(String key) {
    return _declareMember(kind: _MemberReferenceKind.method, key: key);
  }

  MemberReference declareSetter(String key) {
    return _declareMember(kind: _MemberReferenceKind.setter, key: key);
  }

  MemberReference getOrCreateConstructor(String key) {
    return _getOrCreateMember(kind: _MemberReferenceKind.constructor, key: key);
  }

  MemberReference getOrCreateField(String key) {
    return _getOrCreateMember(kind: _MemberReferenceKind.field, key: key);
  }

  MemberReference getOrCreateGetter(String key) {
    return _getOrCreateMember(kind: _MemberReferenceKind.getter, key: key);
  }

  MemberReference getOrCreateMethod(String key) {
    return _getOrCreateMember(kind: _MemberReferenceKind.method, key: key);
  }

  MemberReference getOrCreateSetter(String key) {
    return _getOrCreateMember(kind: _MemberReferenceKind.setter, key: key);
  }

  MemberReference _declareMember({
    required _MemberReferenceKind kind,
    required String key,
  }) {
    return Reference._declare(
      byKey: _memberByKey(kind),
      key: key,
      create: (key) => MemberReference._(container: this, key: key, kind: kind),
    );
  }

  MemberReference _getOrCreateMember({
    required _MemberReferenceKind kind,
    required String key,
  }) {
    return _memberByKey(kind)[key] ??= MemberReference._(
      container: this,
      key: key,
      kind: kind,
    );
  }

  Map<String, MemberReference> _memberByKey(_MemberReferenceKind kind) {
    return _membersByKind[kind.index] ??= {};
  }
}

final class MemberReference extends DeclarationReference {
  final MemberContainerReference container;
  final _MemberReferenceKind _kind;

  MemberReference._({
    required this.container,
    required super.key,
    required _MemberReferenceKind kind,
  }) : _kind = kind,
       super._();
}

/// A canonical identity node for an analyzer element.
///
/// References are the lightweight tree that summary reading and writing use to
/// name elements without requiring the corresponding [ElementImpl] to be built
/// yet. When an element is materialized, [element] is filled in with that
/// implementation object.
///
/// The tree shape is intentionally small:
///
/// - [RootReference] owns libraries.
/// - [LibraryReference] owns top-level declarations and `dart:core` built-ins.
/// - [MemberContainerReference] owns members of classes, enums, mixins,
///   extensions, and extension types.
/// - [LeafTopLevelReference], [MemberReference], and [BuiltInReference] have no
///   children.
///
/// Declaration references are identified under their enclosing reference by
/// kind and by an internal key. The key is not always the source name;
/// generated keys are used for unnamed declarations and duplicate source names.
sealed class Reference {
  /// The corresponding [ElementImpl], or `null` if not created yet.
  ElementImpl? element;

  Reference._();

  List<Reference> get children => const [];

  /// The reference that must be materialized before this reference, or `null`
  /// if this reference can be materialized directly.
  Reference? get enclosingReference {
    return switch (this) {
      TopLevelReference(:var library) => library,
      MemberReference(:var container) => container,
      BuiltInReference(:var library) => library,
      _ => null,
    };
  }

  String debugString({String Function(String uriString)? formatLibraryUri}) {
    String recurse(Reference reference) {
      return reference.debugString(formatLibraryUri: formatLibraryUri);
    }

    switch (this) {
      case RootReference():
        return 'root';
      case LibraryReference ref:
        return formatLibraryUri?.call(ref.uriString) ?? ref.uriString;
      case TopLevelReference ref:
        var libraryStr = recurse(ref.library);
        var kindStr = ref._kind.debugName;
        return '$libraryStr::$kindStr::${ref._key}';
      case MemberReference ref:
        var containerStr = recurse(ref.container);
        var kindStr = ref._kind.debugName;
        return '$containerStr::$kindStr::${ref._key}';
      case BuiltInReference ref:
        var libraryStr = recurse(ref.library);
        return '$libraryStr::${ref._kind.identifier}';
    }
  }

  @override
  String toString() => debugString();

  static T _declare<T extends Reference>({
    required Map<String, T> byKey,
    required String key,
    required T Function(String key) create,
  }) {
    if (byKey[key] != null) {
      throw StateError('Duplicate reference key: $key');
    }
    return byKey[key] = create(key);
  }
}

final class ReferenceTableReader {
  final String Function(int index) _stringOfIndex;
  final RootReference _rootReference;
  late final Uint8List _tagIndexes;
  late final Uint32List _parentIndexes;
  late final Uint8List _kindIndexes;
  late final Uint32List _keyStringIndexes;
  late final Uint32List _uriStringIndexes;
  late final List<Reference?> _referenceByIndex;

  ReferenceTableReader({
    required BinaryReader reader,
    required RootReference rootReference,
  }) : _stringOfIndex = reader.stringOfIndex,
       _rootReference = rootReference {
    _tagIndexes = reader.readUint8List();
    _parentIndexes = reader.readUint30List();
    _kindIndexes = reader.readUint8List();
    _keyStringIndexes = reader.readUint30List();
    _uriStringIndexes = reader.readUint30List();
    assert(_tagIndexes.length == _parentIndexes.length);
    assert(_tagIndexes.length == _kindIndexes.length);
    assert(_tagIndexes.length == _keyStringIndexes.length);
    assert(_tagIndexes.length == _uriStringIndexes.length);

    _referenceByIndex = List.filled(_tagIndexes.length, null);
    _referenceByIndex[0] = _rootReference;
  }

  DeclarationReference readDeclarationReference(BinaryReader reader) {
    var index = reader.readUint30();
    return _referenceOfIndex(index) as DeclarationReference;
  }

  ExportableReference readExportableReference(BinaryReader reader) {
    var index = reader.readUint30();
    return _referenceOfIndex(index) as ExportableReference;
  }

  LibraryReference readLibraryReference(BinaryReader reader) {
    var index = reader.readUint30();
    return _referenceOfIndex(index) as LibraryReference;
  }

  MemberContainerReference readMemberContainerReference(BinaryReader reader) {
    var index = reader.readUint30();
    return _referenceOfIndex(index) as MemberContainerReference;
  }

  MemberReference readMemberReference(BinaryReader reader) {
    var index = reader.readUint30();
    return _referenceOfIndex(index) as MemberReference;
  }

  Reference readReference(BinaryReader reader) {
    var index = reader.readUint30();
    return _referenceOfIndex(index);
  }

  TopLevelReference readTopLevelReference(BinaryReader reader) {
    var index = reader.readUint30();
    return _referenceOfIndex(index) as TopLevelReference;
  }

  LibraryReference _libraryReferenceOfIndex(int index) {
    return _referenceOfIndex(index) as LibraryReference;
  }

  MemberContainerReference _memberContainerReferenceOfIndex(int index) {
    return _referenceOfIndex(index) as MemberContainerReference;
  }

  Reference _referenceOfIndex(int index) {
    var reference = _referenceByIndex[index];
    if (reference != null) {
      return reference;
    }

    var tag = _SerializedReferenceTag.values[_tagIndexes[index]];
    switch (tag) {
      case _SerializedReferenceTag.root:
        reference = _rootReference;
      case _SerializedReferenceTag.library:
        var uriString = _stringOfIndex(_uriStringIndexes[index]);
        reference = _rootReference.getOrCreateLibrary(
          uriCache.parse(uriString),
        );
      case _SerializedReferenceTag.topLevel:
        var library = _libraryReferenceOfIndex(_parentIndexes[index]);
        var kind = _TopLevelReferenceKind.values[_kindIndexes[index]];
        var key = _stringOfIndex(_keyStringIndexes[index]);
        reference = library._getOrCreateTopLevel(kind: kind, key: key);
      case _SerializedReferenceTag.member:
        var container = _memberContainerReferenceOfIndex(_parentIndexes[index]);
        reference = container._getOrCreateMember(
          kind: _MemberReferenceKind.values[_kindIndexes[index]],
          key: _stringOfIndex(_keyStringIndexes[index]),
        );
      case _SerializedReferenceTag.builtIn:
        var library = _libraryReferenceOfIndex(_parentIndexes[index]);
        var kind = _BuiltInReferenceKind.values[_kindIndexes[index]];
        reference = library._builtIn(kind);
    }
    _referenceByIndex[index] = reference;

    return reference;
  }
}

final class ReferenceTableWriter {
  static const int _rootIndex = 0;

  final Map<Reference, int> _indexByReference = Map.identity();

  final List<int> _tagIndexes = [];
  final List<int> _parentIndexes = [];
  final List<int> _kindIndexes = [];
  final List<String> _keyStrings = [];
  final List<String> _uriStrings = [];

  ReferenceTableWriter() {
    _appendRow(
      reference: null,
      tag: _SerializedReferenceTag.root,
      parentIndex: _rootIndex,
      kindIndex: 0,
      key: '',
      uriString: '',
    );
  }

  void write(BinaryWriter sink) {
    sink.writeUint8List(Uint8List.fromList(_tagIndexes));
    sink.writeUint30List(_parentIndexes);
    sink.writeUint8List(Uint8List.fromList(_kindIndexes));
    sink.writeStringList(_keyStrings);
    sink.writeStringList(_uriStrings);
  }

  void writeReference(BinaryWriter sink, Reference reference) {
    var index = _indexOfReference(reference);
    sink.writeUint30(index);
  }

  int _appendRow({
    required Reference? reference,
    required _SerializedReferenceTag tag,
    required int parentIndex,
    required int kindIndex,
    required String key,
    required String uriString,
  }) {
    assert(tag.index <= 0xFF);
    assert(kindIndex <= 0xFF);
    var index = _tagIndexes.length;
    _tagIndexes.add(tag.index);
    _parentIndexes.add(parentIndex);
    _kindIndexes.add(kindIndex);
    _keyStrings.add(key);
    _uriStrings.add(uriString);
    if (reference != null) {
      _indexByReference[reference] = index;
    }
    return index;
  }

  int _indexOfReference(Reference reference) {
    var index = _indexByReference[reference];
    if (index != null) return index;

    switch (reference) {
      case RootReference():
        return _rootIndex;
      case LibraryReference():
        return _appendRow(
          reference: reference,
          tag: _SerializedReferenceTag.library,
          parentIndex: _rootIndex,
          kindIndex: 0,
          key: '',
          uriString: reference.uriString,
        );
      case TopLevelReference():
        return _appendRow(
          reference: reference,
          tag: _SerializedReferenceTag.topLevel,
          parentIndex: _indexOfReference(reference.library),
          kindIndex: reference._kind.index,
          key: reference._key,
          uriString: '',
        );
      case MemberReference():
        return _appendRow(
          reference: reference,
          tag: _SerializedReferenceTag.member,
          parentIndex: _indexOfReference(reference.container),
          kindIndex: reference._kind.index,
          key: reference._key,
          uriString: '',
        );
      case BuiltInReference():
        return _appendRow(
          reference: reference,
          tag: _SerializedReferenceTag.builtIn,
          parentIndex: _indexOfReference(reference.library),
          kindIndex: reference._kind.index,
          key: '',
          uriString: '',
        );
    }
  }
}

final class RootReference extends Reference {
  final Map<String, LibraryReference> _libraries = {};

  RootReference() : super._();

  @override
  List<LibraryReference> get children => [..._libraries.values];

  LibraryReference getOrCreateLibrary(Uri uri) {
    var uriString = '$uri';
    return _libraries[uriString] ??= LibraryReference._(uriString: uriString);
  }

  LibraryReference? libraryIfExists(Uri uri) {
    var uriString = '$uri';
    return _libraries[uriString];
  }

  LibraryReference? removeLibrary(Uri uri) {
    var uriString = '$uri';
    return _libraries.remove(uriString);
  }
}

sealed class TopLevelReference extends DeclarationReference
    implements ExportableReference {
  final LibraryReference library;
  final _TopLevelReferenceKind _kind;

  TopLevelReference._({
    required this.library,
    required super.key,
    required _TopLevelReferenceKind kind,
  }) : _kind = kind,
       super._();
}

enum _BuiltInReferenceKind {
  dynamic_('dynamic'),
  never_('Never');

  final String identifier;

  const _BuiltInReferenceKind(this.identifier);
}

final class _KeyAllocator {
  final List<Map<String, int>?> _nextDuplicateIndexByKind;
  int _nextUnnamedIndex = 0;

  _KeyAllocator({required int kindCount})
    : _nextDuplicateIndexByKind = List.filled(kindCount, null);

  String allocate({required int kindIndex, required String? name}) {
    var baseName = name ?? _unnamedName(_nextUnnamedIndex++);
    var byBaseName = _nextDuplicateIndexByKind[kindIndex] ??= {};
    var duplicateIndex = byBaseName[baseName] ?? 0;
    byBaseName[baseName] = duplicateIndex + 1;

    if (duplicateIndex == 0) {
      return baseName;
    }
    return _duplicateName(baseName, duplicateIndex);
  }

  String _duplicateName(String baseName, int index) => '$baseName#$index';

  String _unnamedName(int index) => '#$index';
}

enum _MemberReferenceKind {
  constructor('@constructor'),
  field('@field'),
  getter('@getter'),
  setter('@setter'),
  method('@method');

  final String debugName;

  const _MemberReferenceKind(this.debugName);
}

enum _SerializedReferenceTag { root, library, topLevel, member, builtIn }

enum _TopLevelReferenceKind {
  class_('@class', hasMembers: true),
  enum_('@enum', hasMembers: true),
  extension_('@extension', hasMembers: true),
  extensionType('@extensionType', hasMembers: true),
  mixin_('@mixin', hasMembers: true),
  typeAlias('@typeAlias'),
  function('@function'),
  getter('@getter'),
  setter('@setter'),
  topLevelVariable('@topLevelVariable');

  final String debugName;
  final bool hasMembers;

  const _TopLevelReferenceKind(this.debugName, {this.hasMembers = false});
}
