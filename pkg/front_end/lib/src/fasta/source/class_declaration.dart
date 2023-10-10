// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/function_builder.dart';
import '../builder/member_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/type_builder.dart';
import '../dill/dill_member_builder.dart';
import '../fasta_codes.dart';
import '../problems.dart';
import '../scope.dart';
import '../type_inference/type_schema.dart';
import 'source_factory_builder.dart';
import 'source_library_builder.dart';

/// Common interface for builders for a class declarations in source code, such
/// as a regular class declaration and an extension type declaration.
// TODO(johnniwinther): Should this be renamed now that inline classes are
//  renamed to extension type declarations?
abstract class ClassDeclaration
    implements IDeclarationBuilder, ClassMemberAccess {
  @override
  SourceLibraryBuilder get libraryBuilder;

  bool get isMixinDeclaration;

  /// Returns `true` if this class declaration has a generative constructor,
  /// either explicitly or implicitly through a no-name default constructor.
  bool get hasGenerativeConstructor;

  int resolveConstructors(SourceLibraryBuilder library);
}

mixin ClassDeclarationMixin implements ClassDeclaration {
  List<ConstructorReferenceBuilder>? get constructorReferences;

  @override
  int resolveConstructors(SourceLibraryBuilder library) {
    if (constructorReferences == null) return 0;
    for (ConstructorReferenceBuilder ref in constructorReferences!) {
      ref.resolveIn(scope, library);
    }
    int count = constructorReferences!.length;
    if (count != 0) {
      Iterator<MemberBuilder> iterator = constructorScope.filteredIterator(
          parent: this, includeDuplicates: true, includeAugmentations: true);
      while (iterator.moveNext()) {
        MemberBuilder declaration = iterator.current;
        if (declaration.parent?.origin != origin) {
          unexpected("$fileUri", "${declaration.parent!.fileUri}", charOffset,
              fileUri);
        }
        if (declaration is RedirectingFactoryBuilder) {
          // Compute the immediate redirection target, not the effective.

          ConstructorReferenceBuilder redirectionTarget =
              declaration.redirectionTarget;
          List<TypeBuilder>? typeArguments = redirectionTarget.typeArguments;
          Builder? target = redirectionTarget.target;
          if (typeArguments != null && target is MemberBuilder) {
            TypeName redirectionTargetName = redirectionTarget.typeName;
            if (redirectionTargetName.qualifier == null) {
              // Do nothing. This is the case of an identifier followed by
              // type arguments, such as the following:
              //   B<T>
              //   B<T>.named
            } else {
              if (target.name.isEmpty) {
                // Do nothing. This is the case of a qualified
                // non-constructor prefix (for example, with a library
                // qualifier) followed by type arguments, such as the
                // following:
                //   lib.B<T>
              } else if (target.name != redirectionTargetName.name) {
                // Do nothing. This is the case of a qualified
                // non-constructor prefix followed by type arguments followed
                // by a constructor name, such as the following:
                //   lib.B<T>.named
              } else {
                // TODO(cstefantsova,johnniwinther): Handle this in case in
                // ConstructorReferenceBuilder.resolveIn and unify with other
                // cases of handling of type arguments after constructor
                // names.
                addProblem(
                    messageConstructorWithTypeArguments,
                    redirectionTargetName.nameOffset,
                    redirectionTargetName.nameLength);
              }
            }
          }

          Builder? targetBuilder = redirectionTarget.target;
          Member? targetNode;
          if (targetBuilder is FunctionBuilder) {
            targetNode = targetBuilder.member;
          } else if (targetBuilder is DillMemberBuilder) {
            targetNode = targetBuilder.member;
          } else if (targetBuilder is AmbiguousBuilder) {
            libraryBuilder.addProblemForRedirectingFactory(
                declaration,
                templateDuplicatedDeclarationUse
                    .withArguments(redirectionTarget.fullNameForErrors),
                redirectionTarget.charOffset,
                noLength,
                redirectionTarget.fileUri);
          } else {
            libraryBuilder.addProblemForRedirectingFactory(
                declaration,
                templateRedirectionTargetNotFound
                    .withArguments(redirectionTarget.fullNameForErrors),
                redirectionTarget.charOffset,
                noLength,
                redirectionTarget.fileUri);
          }
          if (targetNode != null &&
              targetNode is Constructor &&
              targetNode.enclosingClass.isAbstract) {
            libraryBuilder.addProblemForRedirectingFactory(
                declaration,
                templateAbstractRedirectedClassInstantiation
                    .withArguments(redirectionTarget.fullNameForErrors),
                redirectionTarget.charOffset,
                noLength,
                redirectionTarget.fileUri);
            targetNode = null;
          }
          if (targetNode != null &&
              targetNode is Constructor &&
              targetNode.enclosingClass.isEnum) {
            libraryBuilder.addProblemForRedirectingFactory(
                declaration,
                messageEnumFactoryRedirectsToConstructor,
                redirectionTarget.charOffset,
                noLength,
                redirectionTarget.fileUri);
            targetNode = null;
          }
          if (targetNode != null) {
            List<DartType>? typeArguments = declaration.typeArguments;
            if (typeArguments == null) {
              int typeArgumentCount;
              if (targetBuilder!.isExtensionTypeMember) {
                ExtensionTypeDeclarationBuilder
                    extensionTypeDeclarationBuilder =
                    targetBuilder.parent as ExtensionTypeDeclarationBuilder;
                typeArgumentCount =
                    extensionTypeDeclarationBuilder.typeVariablesCount;
              } else {
                typeArgumentCount =
                    targetNode.enclosingClass!.typeParameters.length;
              }
              typeArguments = new List<DartType>.filled(
                  typeArgumentCount, const UnknownType());
            }
            declaration.setRedirectingFactoryBody(targetNode, typeArguments);
          }
        }
      }
    }
    return count;
  }
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
