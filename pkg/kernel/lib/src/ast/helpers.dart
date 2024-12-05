// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

/// Sentinel value used to signal that a node cannot be removed through the
/// [RemovingTransformer].
const Null cannotRemoveSentinel = null;

/// Helper that can be used in asserts to check that [list] is mutable by
/// adding and removing [dummyElement].
bool checkListIsMutable<E>(List<E> list, E dummyElement) {
  list
    ..add(dummyElement)
    ..removeLast();
  return true;
}

abstract class BinarySink {
  void writeByte(int byte);
  void writeUInt32(int value);
  void writeUInt30(int value);

  /// Write List<Byte> into the sink.
  void writeByteList(List<int> bytes);

  void writeNullAllowedCanonicalNameReference(Reference? reference);
  void writeStringReference(String str);
  void writeDartType(DartType type);
  void writeConstantReference(Constant constant);
}

abstract class BinarySource {
  int readByte();
  int readUInt30();
  int readUint32();

  /// Read List<Byte> from the source.
  List<int> readByteList();

  CanonicalName? readNullableCanonicalNameReference();
  String readStringReference();
  DartType readDartType();
  Constant readConstantReference();
}

/// List-wrapper that marks the parent-class as dirty if the list is modified.
///
/// The idea being, that for non-dirty classes (classes just loaded from dill)
/// the canonical names has already been calculated, and recalculating them is
/// not needed. If, however, we change anything, recalculation of the canonical
/// names can be needed.
class DirtifyingList<E> extends ListBase<E> {
  final Class dirtifyClass;
  final List<E> wrapped;

  DirtifyingList(this.dirtifyClass, this.wrapped);

  @override
  int get length {
    return wrapped.length;
  }

  @override
  void set length(int length) {
    dirtifyClass.dirty = true;
    wrapped.length = length;
  }

  @override
  E operator [](int index) {
    return wrapped[index];
  }

  @override
  void operator []=(int index, E value) {
    dirtifyClass.dirty = true;
    wrapped[index] = value;
  }
}

void setParents(List<TreeNode> nodes, TreeNode parent) {
  for (int i = 0; i < nodes.length; ++i) {
    nodes[i].parent = parent;
  }
}

void visitList(List<Node> nodes, Visitor visitor) {
  for (int i = 0; i < nodes.length; ++i) {
    nodes[i].accept(visitor);
  }
}

void visitIterable(Iterable<Node> nodes, Visitor visitor) {
  for (Node node in nodes) {
    node.accept(visitor);
  }
}

class _ChildReplacer extends Transformer {
  final TreeNode child;
  final TreeNode replacement;

  _ChildReplacer(this.child, this.replacement);

  @override
  TreeNode defaultTreeNode(TreeNode node) {
    if (node == child) {
      return replacement;
    } else {
      return node;
    }
  }
}

/// Returns the [Reference] object for the given member based on the
/// ProcedureKind.
///
/// Returns `null` if the member is `null`.
Reference? getMemberReferenceBasedOnProcedureKind(
    Member? member, ProcedureKind kind) {
  if (member == null) return null;
  if (member is Field) {
    if (kind == ProcedureKind.Setter) return member.setterReference!;
    return member.getterReference;
  }
  return member.reference;
}

/// Returns the (getter) [Reference] object for the given member.
///
/// Returns `null` if the member is `null`.
/// TODO(jensj): Should it be called NotSetter instead of Getter?
Reference? getMemberReferenceGetter(Member? member) {
  if (member == null) return null;
  return getNonNullableMemberReferenceGetter(member);
}

Reference getNonNullableMemberReferenceGetter(Member member) {
  if (member is Field) return member.getterReference;
  return member.reference;
}

Reference getNonNullableMemberReferenceSetter(Member member) {
  if (member is Field) return member.setterReference!;
  return member.reference;
}

/// Murmur-inspired hashing, with a fall-back to Jenkins-inspired hashing when
/// compiled to JavaScript.
///
/// A hash function should be constructed of several [combine] calls followed by
/// a [finish] call.
class _Hash {
  static const int M = 0x9ddfea08eb382000 + 0xd69;
  static const bool intIs64Bit = (1 << 63) != 0;

  /// Primitive hash combining step.
  static int combine(int value, int hash) {
    if (intIs64Bit) {
      value *= M;
      value ^= _shru(value, 47);
      value *= M;
      hash ^= value;
      hash *= M;
    } else {
      // Fall back to Jenkins-inspired hashing on JavaScript platforms.
      hash = 0x1fffffff & (hash + value);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }
    return hash;
  }

  /// Primitive hash finalization step.
  static int finish(int hash) {
    if (intIs64Bit) {
      hash ^= _shru(hash, 44);
      hash *= M;
      hash ^= _shru(hash, 41);
    } else {
      // Fall back to Jenkins-inspired hashing on JavaScript platforms.
      hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
      hash = hash ^ (hash >> 11);
      hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    }
    return hash;
  }

  static int combineFinish(int value, int hash) {
    return finish(combine(value, hash));
  }

  static int combine2(int value1, int value2, int hash) {
    return combine(value2, combine(value1, hash));
  }

  static int combine2Finish(int value1, int value2, int hash) {
    return finish(combine2(value1, value2, hash));
  }

  static int hash2(Object object1, Object? object2) {
    return combine2Finish(object2.hashCode, object2.hashCode, 0);
  }

  static int combineListHash(List<Object> list, [int hash = 1]) {
    for (Object item in list) {
      hash = _Hash.combine(item.hashCode, hash);
    }
    return hash;
  }

  static int combineList(List<int> hashes, int hash) {
    for (int item in hashes) {
      hash = combine(item, hash);
    }
    return hash;
  }

  static int combineMapHashUnordered(Map? map, [int hash = 2]) {
    if (map == null || map.isEmpty) return hash;
    List<int> entryHashes = List.filled(
        map.length,
        // `-1` is used as a dummy default value.
        -1);
    int i = 0;
    for (MapEntry entry in map.entries) {
      entryHashes[i++] = combine(entry.key.hashCode, entry.value.hashCode);
    }
    entryHashes.sort();
    return combineList(entryHashes, hash);
  }

  // TODO(sra): Replace with '>>>'.
  static int _shru(int v, int n) {
    assert(n >= 1);
    assert(intIs64Bit);
    return ((v >> 1) & (0x7fffFFFFffffF000 + 0xFFF)) >> (n - 1);
  }
}

int listHashCode(List<Object> list) {
  return _Hash.finish(_Hash.combineListHash(list));
}

bool listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool mapEquals(Map a, Map b) {
  if (a.length != b.length) return false;
  for (final Object key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

/// Annotation describing information which is not part of Dart semantics; in
/// other words, if this information (or any information it refers to) changes,
/// static analysis and runtime behavior of the library are unaffected.
const Null informative = null;

Location? _getLocationInComponent(Component? component, Uri fileUri, int offset,
    {required String viaForErrorMessage}) {
  if (component != null) {
    return component.getLocation(fileUri, offset,
        viaForErrorMessage: viaForErrorMessage);
  } else {
    return new Location(fileUri, TreeNode.noOffset, TreeNode.noOffset);
  }
}

/// Convert the synthetic name of an implicit mixin application class
/// into a name suitable for user-faced strings.
///
/// For example, when compiling "class A extends S with M1, M2", the
/// two synthetic classes will be named "_A&S&M1" and "_A&S&M1&M2".
/// This function will return "S with M1" and "S with M1, M2", respectively.
String demangleMixinApplicationName(String name) {
  List<String> nameParts = name.split('&');
  if (nameParts.length < 2 || name == "&") return name;
  String demangledName = nameParts[1];
  for (int i = 2; i < nameParts.length; i++) {
    demangledName += (i == 2 ? " with " : ", ") + nameParts[i];
  }
  return demangledName;
}

/// Extract from the synthetic name of an implicit mixin application class
/// the name of the final subclass of the mixin application.
///
/// For example, when compiling "class A extends S with M1, M2", the
/// two synthetic classes will be named "_A&S&M1" and "_A&S&M1&M2".
/// This function will return "A" for both classes.
String demangleMixinApplicationSubclassName(String name) {
  List<String> nameParts = name.split('&');
  if (nameParts.length < 2) return name;
  assert(nameParts[0].startsWith('_'));
  return nameParts[0].substring(1);
}

/// Computes a list of [typeParameters] taken as types.
List<DartType> getAsTypeArguments(
    List<TypeParameter> typeParameters, Library library) {
  if (typeParameters.isEmpty) return const <DartType>[];
  return new List<DartType>.generate(
      typeParameters.length,
      (int i) => new TypeParameterType.withDefaultNullabilityForLibrary(
          typeParameters[i], library),
      growable: false);
}
