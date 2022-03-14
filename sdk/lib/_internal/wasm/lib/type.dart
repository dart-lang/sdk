// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Representation of runtime types. Can only represent interface types so far,
// and does not capture nullability.

@pragma("wasm:entry-point")
class _Type implements Type {
  final int classId;
  final List<_Type> typeArguments;

  @pragma("wasm:entry-point")
  const _Type(this.classId, [this.typeArguments = const []]);

  bool operator ==(Object other) {
    if (other is! _Type) return false;
    if (classId != other.classId) return false;
    for (int i = 0; i < typeArguments.length; i++) {
      if (typeArguments[i] != other.typeArguments[i]) return false;
    }
    return true;
  }

  int get hashCode {
    int hash = mix64(classId);
    for (int i = 0; i < typeArguments.length; i++) {
      hash = mix64(hash ^ typeArguments[i].hashCode);
    }
    return hash;
  }

  String toString() {
    StringBuffer s = StringBuffer();
    s.write("Type");
    s.write(classId);
    if (typeArguments.isNotEmpty) {
      s.write("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i > 0) s.write(",");
        s.write(typeArguments[i]);
      }
      s.write(">");
    }
    return s.toString();
  }
}
