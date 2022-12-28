// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/declaration_builder.dart';
import '../builder/member_builder.dart';
import '../builder/name_iterator.dart';
import 'source_library_builder.dart';

/// Common interface for builders for a class declarations in source code, such
/// as a regular class declaration and an inline class declaration.
abstract class ClassDeclaration
    implements DeclarationBuilder, ClassMemberAccess {
  @override
  SourceLibraryBuilder get libraryBuilder;

  bool get isMixinDeclaration;

  /// Returns `true` if this class declaration has a generative constructor,
  /// either explicitly or implicitly through a no-name default constructor.
  bool get hasGenerativeConstructor;
}

abstract class ClassDeclarationAugmentationAccess<D extends ClassDeclaration> {
  D getOrigin(D classDeclaration);
  Iterable<D>? getAugmentations(D classDeclaration);
}

class ClassDeclarationMemberIterator<D extends ClassDeclaration,
    T extends Builder> implements Iterator<T> {
  Iterator<T>? _iterator;
  Iterator<D>? augmentationBuilders;
  final bool includeDuplicates;

  factory ClassDeclarationMemberIterator(
      ClassDeclarationAugmentationAccess<D> patching, D classBuilder,
      {required bool includeDuplicates}) {
    return new ClassDeclarationMemberIterator._(
        patching.getOrigin(classBuilder),
        patching.getAugmentations(classBuilder)?.iterator,
        includeDuplicates: includeDuplicates);
  }

  ClassDeclarationMemberIterator._(
      D classDeclaration, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = classDeclaration.scope.filteredIterator<T>(
            parent: classDeclaration,
            includeDuplicates: includeDuplicates,
            includeAugmentations: false);

  @override
  bool moveNext() {
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    if (augmentationBuilders != null && augmentationBuilders!.moveNext()) {
      D augmentationClassDeclaration = augmentationBuilders!.current;
      _iterator = augmentationClassDeclaration.scope.filteredIterator<T>(
          parent: augmentationClassDeclaration,
          includeDuplicates: includeDuplicates,
          includeAugmentations: false);
    }
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    return false;
  }

  @override
  T get current => _iterator?.current ?? (throw new StateError('No element'));
}

class ClassDeclarationMemberNameIterator<D extends ClassDeclaration,
    T extends Builder> implements NameIterator<T> {
  NameIterator<T>? _iterator;
  Iterator<D>? augmentationBuilders;
  final bool includeDuplicates;

  factory ClassDeclarationMemberNameIterator(
      ClassDeclarationAugmentationAccess<D> patching, D classBuilder,
      {required bool includeDuplicates}) {
    return new ClassDeclarationMemberNameIterator._(
        patching.getOrigin(classBuilder),
        patching.getAugmentations(classBuilder)?.iterator,
        includeDuplicates: includeDuplicates);
  }

  ClassDeclarationMemberNameIterator._(
      D classDeclaration, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = classDeclaration.scope.filteredNameIterator<T>(
            parent: classDeclaration,
            includeDuplicates: includeDuplicates,
            includeAugmentations: false);

  @override
  bool moveNext() {
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    if (augmentationBuilders != null && augmentationBuilders!.moveNext()) {
      D augmentationClassDeclaration = augmentationBuilders!.current;
      _iterator = augmentationClassDeclaration.scope.filteredNameIterator<T>(
          parent: augmentationClassDeclaration,
          includeDuplicates: includeDuplicates,
          includeAugmentations: false);
    }
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    return false;
  }

  @override
  T get current => _iterator?.current ?? (throw new StateError('No element'));

  @override
  String get name => _iterator?.name ?? (throw new StateError('No element'));
}

class ClassDeclarationConstructorIterator<D extends ClassDeclaration,
    T extends MemberBuilder> implements Iterator<T> {
  Iterator<T>? _iterator;
  Iterator<D>? augmentationBuilders;
  final bool includeDuplicates;

  factory ClassDeclarationConstructorIterator(
      ClassDeclarationAugmentationAccess<D> patching, D classBuilder,
      {required bool includeDuplicates}) {
    return new ClassDeclarationConstructorIterator._(
        patching.getOrigin(classBuilder),
        patching.getAugmentations(classBuilder)?.iterator,
        includeDuplicates: includeDuplicates);
  }

  ClassDeclarationConstructorIterator._(
      D classDeclaration, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = classDeclaration.constructorScope.filteredIterator<T>(
            parent: classDeclaration,
            includeDuplicates: includeDuplicates,
            includeAugmentations: false);

  @override
  bool moveNext() {
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    if (augmentationBuilders != null && augmentationBuilders!.moveNext()) {
      D augmentationClassDeclaration = augmentationBuilders!.current;
      _iterator = augmentationClassDeclaration.constructorScope
          .filteredIterator<T>(
              parent: augmentationClassDeclaration,
              includeDuplicates: includeDuplicates,
              includeAugmentations: false);
    }
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    return false;
  }

  @override
  T get current => _iterator?.current ?? (throw new StateError('No element'));
}

class ClassDeclarationConstructorNameIterator<D extends ClassDeclaration,
    T extends MemberBuilder> implements NameIterator<T> {
  NameIterator<T>? _iterator;
  Iterator<D>? augmentationBuilders;
  final bool includeDuplicates;

  factory ClassDeclarationConstructorNameIterator(
      ClassDeclarationAugmentationAccess<D> patching, D classDeclaration,
      {required bool includeDuplicates}) {
    return new ClassDeclarationConstructorNameIterator._(
        patching.getOrigin(classDeclaration),
        patching.getAugmentations(classDeclaration)?.iterator,
        includeDuplicates: includeDuplicates);
  }

  ClassDeclarationConstructorNameIterator._(
      D classBuilder, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = classBuilder.constructorScope.filteredNameIterator<T>(
            parent: classBuilder,
            includeDuplicates: includeDuplicates,
            includeAugmentations: false);

  @override
  bool moveNext() {
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    if (augmentationBuilders != null && augmentationBuilders!.moveNext()) {
      D augmentationClassDeclaration = augmentationBuilders!.current;
      _iterator = augmentationClassDeclaration.constructorScope
          .filteredNameIterator<T>(
              parent: augmentationClassDeclaration,
              includeDuplicates: includeDuplicates,
              includeAugmentations: false);
    }
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    return false;
  }

  @override
  T get current => _iterator?.current ?? (throw new StateError('No element'));

  @override
  String get name => _iterator?.name ?? (throw new StateError('No element'));
}
