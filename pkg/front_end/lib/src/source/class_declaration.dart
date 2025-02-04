// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../base/problems.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../builder/name_iterator.dart';
import 'source_factory_builder.dart';
import 'source_library_builder.dart';

/// Common interface for builders for a class declarations in source code, such
/// as a regular class declaration and an extension type declaration.
// TODO(johnniwinther): Should this be renamed now that inline classes are
//  renamed to extension type declarations?
// TODO(johnniwinther): Merge this with [IDeclarationBuilder]? Extensions are
// the only declarations without constructors, this might come with the static
// extension feature.
abstract class ClassDeclarationBuilder
    implements IDeclarationBuilder, ClassMemberAccess {
  @override
  SourceLibraryBuilder get libraryBuilder;

  bool get isMixinDeclaration;

  int resolveConstructors(SourceLibraryBuilder library);

  /// [Iterator] for all members declared directly in this class, including
  /// augmenting members.
  ///
  /// Duplicates are _not_ included.
  ///
  /// For instance:
  ///
  ///     class Class {
  ///       // Declared, so it is included for this class but not for the
  ///       // augmentation class below.
  ///       method() {}
  ///       // Declared, so it is included for this class but not for the
  ///       // augmentation class below.
  ///       method2() {}
  ///       method2() {} // Duplicate, so it is *not* included.
  ///     }
  ///
  ///     augment class Class {
  ///       // Augmenting, so it is included for this augmentation class but
  ///       // not for the origin class above.
  ///       augment method() {}
  ///       // Declared, so it is included for this augmentation class but not
  ///       // for the origin class above.
  ///       extra() {}
  ///     }
  ///
  Iterator<T> localMemberIterator<T extends Builder>();

  /// [Iterator] for all constructors declared directly in this class, including
  /// augmenting constructors.
  ///
  /// For instance:
  ///
  ///     class Class {
  ///       // Declared, so it is included for this class but not for the
  ///       // augmentation class below.
  ///       Class();
  ///       // Declared, so it is included for this class but not for the
  ///       // augmentation class below.
  ///       Class.named();
  ///       Class.named(); // Duplicate, so it is *not* included.
  ///     }
  ///
  ///     augment class Class {
  ///       // Augmenting, so it is included for this augmentation class but
  ///       // not for the origin class above.
  ///       augment Class();
  ///       // Declared, so it is included for this augmentation class but not
  ///       // for the origin class above.
  ///       Class.extra();
  ///     }
  ///
  Iterator<T> localConstructorIterator<T extends MemberBuilder>();
}

mixin ClassDeclarationBuilderMixin implements ClassDeclarationBuilder {
  List<ConstructorReferenceBuilder>? get constructorReferences;

  @override
  int resolveConstructors(SourceLibraryBuilder library) {
    if (constructorReferences == null) return 0;
    for (ConstructorReferenceBuilder ref in constructorReferences!) {
      ref.resolveIn(scope, library);
    }
    int count = constructorReferences!.length;
    if (count != 0) {
      Iterator<MemberBuilder> iterator = nameSpace.filteredConstructorIterator(
          parent: this, includeDuplicates: true, includeAugmentations: true);
      while (iterator.moveNext()) {
        MemberBuilder declaration = iterator.current;
        if (declaration.declarationBuilder?.origin != origin) {
          unexpected("$fileUri", "${declaration.declarationBuilder!.fileUri}",
              fileOffset, fileUri);
        }
        if (declaration is SourceFactoryBuilder) {
          declaration.resolveRedirectingFactory();
        }
      }
    }
    return count;
  }
}

abstract class ClassDeclarationAugmentationAccess<
    D extends ClassDeclarationBuilder> {
  D getOrigin(D classDeclaration);

  Iterable<D>? getAugmentations(D classDeclaration);
}

class ClassDeclarationMemberIterator<D extends ClassDeclarationBuilder,
    T extends Builder> implements Iterator<T> {
  Iterator<T>? _iterator;
  Iterator<D>? augmentationBuilders;
  final bool includeDuplicates;

  factory ClassDeclarationMemberIterator.full(
      ClassDeclarationAugmentationAccess<D> access, D classBuilder,
      {required bool includeDuplicates}) {
    return new ClassDeclarationMemberIterator._(access.getOrigin(classBuilder),
        access.getAugmentations(classBuilder)?.iterator,
        includeDuplicates: includeDuplicates);
  }

  // Coverage-ignore(suite): Not run.
  factory ClassDeclarationMemberIterator.local(D classBuilder,
      {required bool includeDuplicates}) {
    return new ClassDeclarationMemberIterator._(classBuilder, null,
        includeDuplicates: includeDuplicates);
  }

  ClassDeclarationMemberIterator._(
      D classDeclaration, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = classDeclaration.nameSpace.filteredIterator<T>(
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
      _iterator = augmentationClassDeclaration.nameSpace.filteredIterator<T>(
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
  T get current =>
      _iterator?.current ?? // Coverage-ignore(suite): Not run.
      (throw new StateError('No element'));
}

// Coverage-ignore(suite): Not run.
class ClassDeclarationMemberNameIterator<D extends ClassDeclarationBuilder,
    T extends Builder> implements NameIterator<T> {
  NameIterator<T>? _iterator;
  Iterator<D>? augmentationBuilders;
  final bool includeDuplicates;

  factory ClassDeclarationMemberNameIterator(
      ClassDeclarationAugmentationAccess<D> access, D classBuilder,
      {required bool includeDuplicates}) {
    return new ClassDeclarationMemberNameIterator._(
        access.getOrigin(classBuilder),
        access.getAugmentations(classBuilder)?.iterator,
        includeDuplicates: includeDuplicates);
  }

  ClassDeclarationMemberNameIterator._(
      D classDeclaration, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = classDeclaration.nameSpace.filteredNameIterator<T>(
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
      _iterator = augmentationClassDeclaration.nameSpace
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

class ClassDeclarationConstructorIterator<D extends ClassDeclarationBuilder,
    T extends MemberBuilder> implements Iterator<T> {
  Iterator<T>? _iterator;
  Iterator<D>? augmentationBuilders;
  final bool includeDuplicates;

  factory ClassDeclarationConstructorIterator.full(
      ClassDeclarationAugmentationAccess<D> access, D classBuilder,
      {required bool includeDuplicates}) {
    return new ClassDeclarationConstructorIterator._(
        access.getOrigin(classBuilder),
        access.getAugmentations(classBuilder)?.iterator,
        includeDuplicates: includeDuplicates);
  }

  // Coverage-ignore(suite): Not run.
  factory ClassDeclarationConstructorIterator.local(D classBuilder,
      {required bool includeDuplicates}) {
    return new ClassDeclarationConstructorIterator._(classBuilder, null,
        includeDuplicates: includeDuplicates);
  }

  ClassDeclarationConstructorIterator._(
      D classDeclaration, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = classDeclaration.nameSpace.filteredConstructorIterator<T>(
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
      _iterator = augmentationClassDeclaration.nameSpace
          .filteredConstructorIterator<T>(
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
  T get current =>
      _iterator?.current ?? // Coverage-ignore(suite): Not run.
      (throw new StateError('No element'));
}

class ClassDeclarationConstructorNameIterator<D extends ClassDeclarationBuilder,
    T extends MemberBuilder> implements NameIterator<T> {
  NameIterator<T>? _iterator;
  Iterator<D>? augmentationBuilders;
  final bool includeDuplicates;

  factory ClassDeclarationConstructorNameIterator(
      ClassDeclarationAugmentationAccess<D> access, D classDeclaration,
      {required bool includeDuplicates}) {
    return new ClassDeclarationConstructorNameIterator._(
        access.getOrigin(classDeclaration),
        access.getAugmentations(classDeclaration)?.iterator,
        includeDuplicates: includeDuplicates);
  }

  ClassDeclarationConstructorNameIterator._(
      D classBuilder, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = classBuilder.nameSpace.filteredConstructorNameIterator<T>(
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
      _iterator = augmentationClassDeclaration.nameSpace
          .filteredConstructorNameIterator<T>(
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
  T get current =>
      _iterator?.current ?? // Coverage-ignore(suite): Not run.
      (throw new StateError('No element'));

  @override
  String get name =>
      _iterator?.name ?? // Coverage-ignore(suite): Not run.
      (throw new StateError('No element'));
}
