// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'package:test/fake.dart';

class FakeClassIntrospector with Fake implements ClassIntrospector {}

class FakeTypeDeclarationResolver with Fake implements TypeDeclarationResolver {
}

class TestTypeResolver implements TypeResolver {
  final Map<TypeAnnotation, StaticType> staticTypes;

  TestTypeResolver(this.staticTypes);

  @override
  Future<StaticType> resolve(covariant TypeAnnotation typeAnnotation) async {
    return staticTypes[typeAnnotation]!;
  }
}

// Doesn't handle generics etc but thats ok for now
class TestStaticType implements StaticType {
  final String library;
  final String name;
  final List<TestStaticType> superTypes;

  TestStaticType(this.library, this.name, this.superTypes);

  @override
  Future<bool> isExactly(TestStaticType other) async => _isExactly(other);

  @override
  Future<bool> isSubtypeOf(TestStaticType other) async =>
      _isExactly(other) ||
      superTypes.any((superType) => superType._isExactly(other));

  bool _isExactly(TestStaticType other) =>
      identical(other, this) ||
      (library == other.library && name == other.name);
}

extension DebugCodeString on Code {
  StringBuffer debugString([StringBuffer? buffer]) {
    buffer ??= StringBuffer();
    for (var part in parts) {
      if (part is Code) {
        part.debugString(buffer);
      } else if (part is TypeAnnotation) {
        part.code.debugString(buffer);
      } else {
        buffer.write(part.toString());
      }
    }
    return buffer;
  }
}
