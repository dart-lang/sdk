// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirror_system_helper;

import 'dart:async';
import 'package:compiler/src/mirrors/source_mirrors.dart';
import 'package:compiler/src/mirrors/dart2js_mirrors.dart';
import 'mock_compiler.dart';

export 'package:compiler/src/mirrors/source_mirrors.dart';
export 'package:compiler/src/mirrors/mirrors_util.dart';

const String SOURCE = 'source';
final Uri SOURCE_URI = new Uri(scheme: SOURCE, path: SOURCE);

// TODO(johnniwinther): Move this to a mirrors helper library.
Future<MirrorSystem> createMirrorSystem(String source) {
  MockCompiler compiler = new MockCompiler.internal(
      analyzeOnly: true,
      analyzeAll: true,
      preserveComments: true);
    compiler.registerSource(SOURCE_URI, source);
    compiler.librariesToAnalyzeWhenRun = <Uri>[SOURCE_URI];
  return compiler.runCompiler(null).then((_) {
    return new Dart2JsMirrorSystem(compiler);
  });
}

/**
 * Returns [:true:] if [type] is an instance of [:decl:] with type arguments
 * equal to [typeArgument].
 */
bool isInstance(ClassMirror decl, List<TypeMirror> typeArguments,
            ClassMirror type) {
  if (type.isOriginalDeclaration) return false;
  if (!isSameDeclaration(decl, type)) return false;
  return areEqualsTypes(typeArguments, type.typeArguments);
}

/**
 * Returns [:true:] if [type] is the same type as [expected]. This method
 * equates a non-generic declaration with its instantiation.
 */
bool isEqualType(TypeMirror expected, TypeMirror type) {
  if (expected == type) return true;
  if (expected is ClassMirror && type is ClassMirror) {
    if (!isSameDeclaration(expected, type)) return false;
    if (expected.isOriginalDeclaration || expected.typeArguments.isEmpty) {
      return type.isOriginalDeclaration || type.typeArguments.isEmpty;
    }
    return areEqualsTypes(expected.typeArguments, type.typeArguments);
  }
  return true;
}

/**
 * Returns [:true:] if [types] are equals to [expected] using the equalitry
 * defined by [isEqualType].
 */
bool areEqualsTypes(List<TypeMirror> expected, List<TypeMirror> types) {
  return checkSameList(expected, types, isEqualType);
}

/**
 * Returns [:true:] if an instance of [type] with type arguments equal to
 * [typeArguments] is found in [types].
 */
bool containsType(ClassMirror decl, List<TypeMirror> typeArguments,
                  Iterable<TypeMirror> types) {
  return types.any((type) => isInstance(decl, typeArguments, type));
}

/**
 * Returns the declaration of [type].
 */
TypeMirror toDeclaration(TypeMirror type) {
  return type is ClassMirror ? type.originalDeclaration : type;
}

/**
 * Returns [:true:] if [type] is of the same declaration as [expected].
 */
bool isSameDeclaration(TypeMirror expected, TypeMirror type) {
  return toDeclaration(expected) == toDeclaration(type);
}

/**
 * Returns [:true:] if a type of the declaration of [expected] is in [types].
 */
bool containsDeclaration(TypeMirror expected, Iterable<TypeMirror> types) {
  for (var type in types) {
    if (isSameDeclaration(expected, type)) {
      return true;
    }
  }
  return false;
}

/**
 * Returns [:true:] if declarations of [expected] are the same as those of
 * [types], taking order into account.
 */
bool isSameDeclarationList(Iterable<TypeMirror> expected,
                           Iterable<TypeMirror> types) {
  return checkSameList(expected, types, isSameDeclaration);
}

/**
 * Returns [:true:] if declarations of [expected] are the same as those of
 * [iterable], not taking order into account.
 */
bool isSameDeclarationSet(Iterable<TypeMirror> expected,
                          Iterable<TypeMirror> types) {
   Set<TypeMirror> expectedSet = expected.map(toDeclaration).toSet();
   Set<TypeMirror> typesSet = types.map(toDeclaration).toSet();
   return expectedSet.length == typesSet.length &&
          expectedSet.containsAll(typesSet);
}

/**
 * Utility method for checking whether [expected] and [iterable] contains the
 * same elements with respect to the checking function [check], takin order
 * into account.
 */
bool checkSameList(Iterable<TypeMirror> expected,
                   Iterable<TypeMirror> types,
                   bool check(TypeMirror a, TypeMirror b)) {
  if (expected.length != types.length) return false;
  Iterator<TypeMirror> expectedIterator = expected.iterator;
  Iterator<TypeMirror> typesIterator = types.iterator;
  while (expectedIterator.moveNext() && typesIterator.moveNext()) {
    if (!check(expectedIterator.current, typesIterator.current)) {
      return false;
    }
  }
  return true;
}
