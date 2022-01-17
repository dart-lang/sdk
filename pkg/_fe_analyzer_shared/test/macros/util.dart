// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'package:test/fake.dart';
import 'package:test/test.dart';

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

/// Checks if two [Code] objectss are of the same type and all their fields are
/// equal.
Matcher deepEqualsCode(Code other) => _DeepEqualityMatcher(other);

/// Checks if two [Declaration]s are of the same type and all their fields are
/// equal.
Matcher deepEqualsDeclaration(Declaration declaration) =>
    _DeepEqualityMatcher(declaration);

/// Checks if two [TypeAnnotation]s are of the same type and all their fields are
/// equal.
Matcher deepEqualsTypeAnnotation(TypeAnnotation declaration) =>
    _DeepEqualityMatcher(declaration);

/// Checks if two [Declaration]s, [TypeAnnotation]s, or [Code] objects are of
/// the same type and all their fields are equal.
class _DeepEqualityMatcher extends Matcher {
  final Object? instance;

  _DeepEqualityMatcher(this.instance);

  @override
  Description describe(Description description) => description;

  @override
  bool matches(item, Map matchState) {
    if (item.runtimeType != instance.runtimeType) {
      return false;
    }

    if (instance is Declaration || instance is TypeAnnotation) {
      var instanceReflector = reflect(instance);
      var itemReflector = reflect(item);

      var type = instanceReflector.type;
      for (var getter
          in type.instanceMembers.values.where((member) => member.isGetter)) {
        // We only care about synthetic field getters
        if (!getter.isSynthetic) continue;

        var instanceField = instanceReflector.getField(getter.simpleName);
        var itemField = itemReflector.getField(getter.simpleName);
        var instanceValue = instanceField.reflectee;
        var itemValue = itemField.reflectee;

        // Handle lists of things
        if (instanceValue is List) {
          if (!_listEquals(instanceValue, itemValue, matchState)) {
            return false;
          }
        } else if (instanceValue is Declaration ||
            instanceValue is Code ||
            instanceValue is TypeAnnotation) {
          // Handle nested declarations and code objects
          if (!_DeepEqualityMatcher(instanceValue)
              .matches(itemValue, matchState)) {
            return false;
          }
        } else {
          // Handles basic values and identity
          if (instanceValue != itemValue) {
            return false;
          }
        }
      }
    } else if (instance is Code) {
      if (!_listEquals(
          (instance as Code).parts, (item as Code).parts, matchState)) {
        return false;
      }
    } else {
      // Handles basic values and identity
      if (instance != item) {
        return false;
      }
    }
    return true;
  }

  bool _listEquals(List instanceValue, List itemValue, Map matchState) {
    if (instanceValue.length != itemValue.length) {
      return false;
    }
    for (var i = 0; i < instanceValue.length; i++) {
      if (!_DeepEqualityMatcher(instanceValue[i])
          .matches(itemValue[i], matchState)) {
        return false;
      }
    }
    return true;
  }
}
