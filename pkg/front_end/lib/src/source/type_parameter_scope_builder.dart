// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/reference_from_index.dart';

import '../api_prototype/lowering_predicates.dart';
import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/synthesized_type_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import 'builder_factory.dart';
import 'name_scheme.dart';
import 'source_builder_factory.dart';
import 'source_class_builder.dart';
import 'source_constructor_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart';
import 'source_procedure_builder.dart';
import 'source_property_builder.dart';
import 'source_type_alias_builder.dart';

enum _PropertyKind {
  Getter,
  Setter,
  Field,
  FinalField,
}

enum _FragmentKind {
  Constructor,
  Factory,
  Class,
  Mixin,
  NamedMixinApplication,
  Enum,
  Extension,
  ExtensionType,
  Typedef,
  Method,
  Property,
}

class _FragmentName {
  final _FragmentKind kind;
  final Fragment fragment;
  final Uri fileUri;
  final String name;
  final int nameOffset;
  final int nameLength;
  final bool isAugment;
  final bool isStatic;
  final _PropertyKind? propertyKind;

  _FragmentName(this.kind, this.fragment,
      {required this.fileUri,
      required this.name,
      required this.nameOffset,
      required this.nameLength,
      required this.isAugment,
      this.propertyKind,
      this.isStatic = true});
}

/// A [_PreBuilder] is a precursor to a [Builder] with subclasses for
/// properties, constructors, and other declarations.
sealed class _PreBuilder {
  /// Tries to include [fragmentName] in this [_PreBuilder].
  ///
  /// If [fragmentName] can be absorbed, `true` is returned. Otherwise an error
  /// is reported and `false` is returned.
  bool absorbFragment(
      ProblemReporting problemReporting, _FragmentName fragmentName);

  /// Checks with [fragmentName] conflicts with this [_PreBuilder].
  ///
  /// This is called between constructors and non-constructors which do not
  /// occupy the same name space but can only co-exist if the non-constructor
  /// is not static.
  void checkFragment(
      ProblemReporting problemReporting, _FragmentName fragmentName);

  /// Creates [Builder]s for the fragments absorbed into this [_PreBuilder],
  /// using [createBuilder] to create a [Builder] for a single [Fragment].
  ///
  /// If `conflictingSetter` is `true`, the created [Builder] must be marked
  /// as a conflicting setter. This is needed to ensure that we don't create
  /// conflicting AST nodes: Normally we only create [Builder]s for
  /// non-duplicate declarations, but because setters are store in a separate
  /// map the [NameSpace], they are not directly marked as duplicate if they
  /// do not conflict with other setters.
  void createBuilders(
      void Function(Fragment, {bool conflictingSetter}) createBuilder);
}

/// [_PreBuilder] for properties, i.e. fields, getters and setters.
class _PropertyPreBuilder extends _PreBuilder {
  final bool isStatic;
  _FragmentName? getter;
  _FragmentName? setter;
  List<_FragmentName> augmentations = [];
  List<_FragmentName> conflictingSetters = [];

  // TODO(johnniwinther): Report error if [getter] is augmenting.
  _PropertyPreBuilder.forGetter(_FragmentName this.getter)
      : isStatic = getter.isStatic;

  // TODO(johnniwinther): Report error if [setter] is augmenting.
  _PropertyPreBuilder.forSetter(_FragmentName this.setter)
      : isStatic = setter.isStatic;

  // TODO(johnniwinther): Report error if [getter] is augmenting.
  _PropertyPreBuilder.forField(_FragmentName this.getter)
      : isStatic = getter.isStatic {
    if (getter!.propertyKind == _PropertyKind.Field) {
      setter = getter;
    }
  }

  @override
  bool absorbFragment(
      ProblemReporting problemReporting, _FragmentName fragmentName) {
    _PropertyKind? propertyKind = fragmentName.propertyKind;
    if (propertyKind != null) {
      switch (propertyKind) {
        case _PropertyKind.Getter:
          if (getter == null) {
            // Example:
            //
            //    void set foo(_) {}
            //    int get foo => 42;
            //
            if (fragmentName.isAugment) {
              // Example:
              //
              //    void set foo(_) {}
              //    augment int get foo => 42;
              //
              // TODO(johnniwinther): Report error.
            }
            if (fragmentName.isStatic != isStatic) {
              if (fragmentName.isStatic) {
                // Coverage-ignore-block(suite): Not run.
                // Example:
                //
                //    class A {
                //      void set foo(_) {}
                //      static int get foo => 42;
                //    }
                //
                problemReporting.addProblem(
                    templateStaticConflictsWithInstance
                        .withArguments(fragmentName.name),
                    fragmentName.nameOffset,
                    fragmentName.nameLength,
                    fragmentName.fileUri,
                    context: [
                      templateStaticConflictsWithInstanceCause
                          .withArguments(setter!.name)
                          .withLocation(setter!.fileUri, setter!.nameOffset,
                              setter!.nameLength)
                    ]);
              } else {
                // Example:
                //
                //    class A {
                //      static void set foo(_) {}
                //      int get foo => 42;
                //    }
                //
                problemReporting.addProblem(
                    templateInstanceConflictsWithStatic
                        .withArguments(fragmentName.name),
                    fragmentName.nameOffset,
                    fragmentName.nameLength,
                    fragmentName.fileUri,
                    context: [
                      templateInstanceConflictsWithStaticCause
                          .withArguments(setter!.name)
                          .withLocation(setter!.fileUri, setter!.nameOffset,
                              setter!.nameLength)
                    ]);
              }
              return false;
            } else {
              getter = fragmentName;
              return true;
            }
          } else {
            if (fragmentName.isAugment) {
              // Coverage-ignore-block(suite): Not run.
              // Example:
              //
              //    int get foo => 42;
              //    augment int get foo => 87;
              //
              augmentations.add(fragmentName);
              return true;
            } else {
              // Example:
              //
              //    int get foo => 42;
              //    int get foo => 87;
              //
              problemReporting.addProblem(
                  templateDuplicatedDeclaration
                      .withArguments(fragmentName.name),
                  fragmentName.nameOffset,
                  fragmentName.nameLength,
                  fragmentName.fileUri,
                  context: <LocatedMessage>[
                    templateDuplicatedDeclarationCause
                        .withArguments(getter!.name)
                        .withLocation(getter!.fileUri, getter!.nameOffset,
                            getter!.nameLength)
                  ]);
              return false;
            }
          }
        case _PropertyKind.Setter:
          if (setter == null) {
            // Examples:
            //
            //    int get foo => 42;
            //    void set foo(_) {}
            //
            //    final int bar = 42;
            //    void set bar(_) {}
            //
            if (fragmentName.isAugment) {
              // Example:
              //
              //    int get foo => 42;
              //    augment void set foo(_) {}
              //
              // TODO(johnniwinther): Report error.
            }
            if (fragmentName.isStatic != isStatic) {
              if (fragmentName.isStatic) {
                // Example:
                //
                //    class A {
                //      int get foo => 42;
                //      static void set foo(_) {}
                //    }
                //
                problemReporting.addProblem(
                    templateStaticConflictsWithInstance
                        .withArguments(fragmentName.name),
                    fragmentName.nameOffset,
                    fragmentName.nameLength,
                    fragmentName.fileUri,
                    context: [
                      templateStaticConflictsWithInstanceCause
                          .withArguments(getter!.name)
                          .withLocation(getter!.fileUri, getter!.nameOffset,
                              getter!.nameLength)
                    ]);
                return false;
              } else {
                // Example:
                //
                //    class A {
                //      static int get foo => 42;
                //      void set foo(_) {}
                //    }
                //
                problemReporting.addProblem(
                    templateInstanceConflictsWithStatic
                        .withArguments(fragmentName.name),
                    fragmentName.nameOffset,
                    fragmentName.nameLength,
                    fragmentName.fileUri,
                    context: [
                      templateInstanceConflictsWithStaticCause
                          .withArguments(getter!.name)
                          .withLocation(getter!.fileUri, getter!.nameOffset,
                              getter!.nameLength)
                    ]);
                return false;
              }
            } else {
              setter = fragmentName;
              return true;
            }
          } else {
            if (fragmentName.isAugment) {
              // Example:
              //
              //    void set foo(_) {}
              //    augment void set foo(_) {}
              //
              augmentations.add(fragmentName);
              return true;
            } else {
              if (setter!.propertyKind == _PropertyKind.Field) {
                // Example:
                //
                //    int? foo;
                //    void set foo(_) {}
                //
                problemReporting.addProblem(
                    templateConflictsWithImplicitSetter
                        .withArguments(setter!.name),
                    fragmentName.nameOffset,
                    fragmentName.nameLength,
                    fragmentName.fileUri,
                    context: [
                      templateConflictsWithImplicitSetterCause
                          .withArguments(setter!.name)
                          .withLocation(setter!.fileUri, setter!.nameOffset,
                              setter!.nameLength)
                    ]);

                // Even though we have a conflict we absorb the conflicting
                // setter in order to ensure that the created [Builder] is
                // marked as a conflicting setter.
                // TODO(johnniwinther): Avoid the need for this.
                conflictingSetters.add(fragmentName);
                return true;
              } else {
                // Example:
                //
                //    void set foo(_) {}
                //    void set foo(_) {}
                //
                problemReporting.addProblem(
                    templateDuplicatedDeclaration
                        .withArguments(fragmentName.name),
                    fragmentName.nameOffset,
                    fragmentName.nameLength,
                    fragmentName.fileUri,
                    context: <LocatedMessage>[
                      templateDuplicatedDeclarationCause
                          .withArguments(setter!.name)
                          .withLocation(setter!.fileUri, setter!.nameOffset,
                              setter!.nameLength)
                    ]);
                return false;
              }
            }
          }
        case _PropertyKind.Field:
          if (getter == null) {
            // Example:
            //
            //    void set foo(_) {}
            //    int? foo;
            //
            assert(getter == null && setter != null);
            // We have an explicit setter.
            problemReporting.addProblem(
                templateConflictsWithSetter.withArguments(setter!.name),
                fragmentName.nameOffset,
                fragmentName.nameLength,
                fragmentName.fileUri,
                context: [
                  templateConflictsWithSetterCause
                      .withArguments(setter!.name)
                      .withLocation(setter!.fileUri, setter!.nameOffset,
                          setter!.nameLength)
                ]);

            // Even though we have a conflict we absorb the setter and replace
            // it with the field in order to ensure that the created setter
            // [Builder] is marked as a conflicting setter.
            // TODO(johnniwinther): Avoid the need for this.
            getter = fragmentName;
            conflictingSetters.add(setter!);
            setter = fragmentName;
            return true;
          } else if (setter != null) {
            // Examples:
            //
            //    int? foo;
            //    int? foo;
            //
            //    int get bar => 42;
            //    void set bar(_) {}
            //    int bar = 87;
            //
            //    final int baz = 42;
            //    void set baz(_) {}
            //    int baz = 87;
            //
            assert(getter != null && setter != null);
            // We have both getter and setter
            if (fragmentName.isAugment) {
              // Coverage-ignore-block(suite): Not run.
              if (getter!.propertyKind == fragmentName.propertyKind) {
                // Example:
                //
                //    int foo = 42;
                //    augment int foo = 87;
                //
                augmentations.add(fragmentName);
                return true;
              } else {
                // Example:
                //
                //    final int foo = 42;
                //    void set foo(_) {}
                //    augment int foo = 87;
                //
                // TODO(johnniwinther): Report error.
                // TODO(johnniwinther): Should the augment be absorbed in this
                //  case, as an erroneous augmentation?
                return false;
              }
            } else {
              // Examples:
              //
              //    int? foo;
              //    int? foo;
              //
              //    int? get bar => null;
              //    void set bar(_) {}
              //    int? bar;
              //
              problemReporting.addProblem(
                  templateDuplicatedDeclaration
                      .withArguments(fragmentName.name),
                  fragmentName.nameOffset,
                  fragmentName.nameLength,
                  fragmentName.fileUri,
                  context: <LocatedMessage>[
                    templateDuplicatedDeclarationCause
                        .withArguments(getter!.name)
                        .withLocation(getter!.fileUri, getter!.nameOffset,
                            getter!.nameLength)
                  ]);

              return false;
            }
          } else {
            // Examples:
            //
            //    int get foo => 42;
            //    int? foo;
            //
            //    final int bar = 42;
            //    int? bar;
            //
            assert(getter != null && setter == null);
            problemReporting.addProblem(
                templateDuplicatedDeclaration.withArguments(fragmentName.name),
                fragmentName.nameOffset,
                fragmentName.nameLength,
                fragmentName.fileUri,
                context: <LocatedMessage>[
                  templateDuplicatedDeclarationCause
                      .withArguments(getter!.name)
                      .withLocation(getter!.fileUri, getter!.nameOffset,
                          getter!.nameLength)
                ]);
            return false;
          }
        case _PropertyKind.FinalField:
          if (getter == null) {
            // Example:
            //
            //    void set foo(_) {}
            //    final int foo = 42;
            //
            assert(getter == null && setter != null);
            // We have an explicit setter.
            if (fragmentName.isAugment) {
              // Example:
              //
              //    void set foo(_) {}
              //    augment final int foo = 42;
              //
              // TODO(johnniwinther): Report error.
            }
            if (fragmentName.isStatic != isStatic) {
              // Coverage-ignore-block(suite): Not run.
              if (fragmentName.isStatic) {
                // Example:
                //
                //    class A {
                //      void set foo(_) {}
                //      static final int foo = 42;
                //    }
                //
                problemReporting.addProblem(
                    templateStaticConflictsWithInstance
                        .withArguments(fragmentName.name),
                    fragmentName.nameOffset,
                    fragmentName.nameLength,
                    fragmentName.fileUri,
                    context: [
                      templateStaticConflictsWithInstanceCause
                          .withArguments(setter!.name)
                          .withLocation(setter!.fileUri, setter!.nameOffset,
                              setter!.nameLength)
                    ]);
                return false;
              } else {
                // Example:
                //
                //    class A {
                //      static void set foo(_) {}
                //      final int foo = 42;
                //    }
                //
                problemReporting.addProblem(
                    templateInstanceConflictsWithStatic
                        .withArguments(fragmentName.name),
                    fragmentName.nameOffset,
                    fragmentName.nameLength,
                    fragmentName.fileUri,
                    context: [
                      templateInstanceConflictsWithStaticCause
                          .withArguments(setter!.name)
                          .withLocation(setter!.fileUri, setter!.nameOffset,
                              setter!.nameLength)
                    ]);
                return false;
              }
            } else {
              getter = fragmentName;
              return true;
            }
          } else {
            // Examples:
            //
            //    final int foo = 42;
            //    final int foo = 87;
            //
            //    int get bar => 42;
            //    final int bar = 87;
            //
            if (fragmentName.isAugment) {
              // Coverage-ignore-block(suite): Not run.
              if (getter!.propertyKind == fragmentName.propertyKind) {
                // Example:
                //
                //    final int foo = 42;
                //    augment final int foo = 87;
                //
                augmentations.add(fragmentName);
                return true;
              } else {
                // Example:
                //
                //    int foo = 42;
                //    augment final int foo = 87;
                //
                // TODO(johnniwinther): Report error.
                // TODO(johnniwinther): Should the augment be absorbed in this
                //  case, as an erroneous augmentation?
                return false;
              }
            } else {
              // Examples:
              //
              //    final int foo = 42;
              //    final int foo = 87;
              //
              //    int get bar => 42;
              //    final int bar = 87;
              //
              problemReporting.addProblem(
                  templateDuplicatedDeclaration
                      .withArguments(fragmentName.name),
                  fragmentName.nameOffset,
                  fragmentName.nameLength,
                  fragmentName.fileUri,
                  context: <LocatedMessage>[
                    templateDuplicatedDeclarationCause
                        .withArguments(getter!.name)
                        .withLocation(getter!.fileUri, getter!.nameOffset,
                            getter!.nameLength)
                  ]);
              return false;
            }
          }
      }
    } else {
      if (getter != null) {
        // Example:
        //
        //    int get foo => 42;
        //    void foo() {}
        //
        problemReporting.addProblem(
            templateDuplicatedDeclaration.withArguments(fragmentName.name),
            fragmentName.nameOffset,
            fragmentName.nameLength,
            fragmentName.fileUri,
            context: <LocatedMessage>[
              templateDuplicatedDeclarationCause
                  .withArguments(getter!.name)
                  .withLocation(
                      getter!.fileUri, getter!.nameOffset, getter!.nameLength)
            ]);
      } else {
        assert(setter != null);
        // Example:
        //
        //    void set foo(_) {}
        //    void foo() {}
        //
        problemReporting.addProblem(
            templateDeclarationConflictsWithSetter.withArguments(setter!.name),
            fragmentName.nameOffset,
            fragmentName.nameLength,
            fragmentName.fileUri,
            context: <LocatedMessage>[
              templateDeclarationConflictsWithSetterCause
                  .withArguments(setter!.name)
                  .withLocation(
                      setter!.fileUri, setter!.nameOffset, setter!.nameLength)
            ]);
      }
      return false;
    }
  }

  @override
  void checkFragment(
      ProblemReporting problemReporting, _FragmentName constructorFragment) {
    // Check conflict with constructor.
    if (isStatic) {
      if (getter != null) {
        if (constructorFragment.kind == _FragmentKind.Constructor) {
          // Example:
          //
          //    class A {
          //      static int get foo => 42;
          //      A.foo();
          //    }
          //
          problemReporting.addProblem(
              templateConstructorConflictsWithMember
                  .withArguments(getter!.name),
              constructorFragment.nameOffset,
              constructorFragment.nameLength,
              constructorFragment.fileUri,
              context: [
                templateConstructorConflictsWithMemberCause
                    .withArguments(getter!.name)
                    .withLocation(
                        getter!.fileUri, getter!.nameOffset, getter!.nameLength)
              ]);
        } else {
          // Coverage-ignore-block(suite): Not run.
          assert(constructorFragment.kind == _FragmentKind.Factory,
              "Unexpected constructor kind $constructorFragment");
          // Example:
          //
          //    class A {
          //      static int get foo => 42;
          //      factory A.foo() => throw '';
          //    }
          //
          problemReporting.addProblem(
              templateFactoryConflictsWithMember.withArguments(getter!.name),
              constructorFragment.nameOffset,
              constructorFragment.nameLength,
              constructorFragment.fileUri,
              context: [
                templateFactoryConflictsWithMemberCause
                    .withArguments(getter!.name)
                    .withLocation(
                        getter!.fileUri, getter!.nameOffset, getter!.nameLength)
              ]);
        }
      } else {
        // Coverage-ignore-block(suite): Not run.
        if (constructorFragment.kind == _FragmentKind.Constructor) {
          // Example:
          //
          //    class A {
          //      static void set foo(_) {}
          //      A.foo();
          //    }
          //
          problemReporting.addProblem(
              templateConstructorConflictsWithMember
                  .withArguments(setter!.name),
              constructorFragment.nameOffset,
              constructorFragment.nameLength,
              constructorFragment.fileUri,
              context: [
                templateConstructorConflictsWithMemberCause
                    .withArguments(setter!.name)
                    .withLocation(
                        setter!.fileUri, setter!.nameOffset, setter!.nameLength)
              ]);
        } else {
          assert(constructorFragment.kind == _FragmentKind.Factory,
              "Unexpected constructor kind $constructorFragment");
          // Example:
          //
          //    class A {
          //      static void set foo(_) {}
          //      factory A.foo() => throw '';
          //    }
          //
          problemReporting.addProblem(
              templateFactoryConflictsWithMember.withArguments(setter!.name),
              constructorFragment.nameOffset,
              constructorFragment.nameLength,
              constructorFragment.fileUri,
              context: [
                templateFactoryConflictsWithMemberCause
                    .withArguments(setter!.name)
                    .withLocation(
                        setter!.fileUri, setter!.nameOffset, setter!.nameLength)
              ]);
        }
      }
    }
  }

  @override
  void createBuilders(
      void Function(Fragment, {bool conflictingSetter}) createBuilder) {
    if (getter != null) {
      createBuilder(getter!.fragment);
    }
    if (setter != null && setter!.propertyKind == _PropertyKind.Setter) {
      createBuilder(setter!.fragment);
    }
    for (_FragmentName fragmentName in conflictingSetters) {
      createBuilder(fragmentName.fragment, conflictingSetter: true);
    }
    for (_FragmentName fragmentName in augmentations) {
      createBuilder(fragmentName.fragment);
    }
  }
}

/// [_PreBuilder] for generative and factory constructors.
class _ConstructorPreBuilder extends _PreBuilder {
  final _FragmentName fragment;
  final List<_FragmentName> augmentations = [];

  // TODO(johnniwinther): Report error if [fragment] is augmenting.
  _ConstructorPreBuilder(this.fragment);

  @override
  bool absorbFragment(
      ProblemReporting problemReporting, _FragmentName fragmentName) {
    if (fragmentName.isAugment) {
      // Coverage-ignore-block(suite): Not run.
      if (fragmentName.kind == fragment.kind) {
        // Example:
        //
        //    class A {
        //      A();
        //      augment A();
        //    }
        //
        augmentations.add(fragmentName);
        return true;
      } else {
        // Example:
        //
        //    class A {
        //      A();
        //      augment void A() {}
        //    }
        //
        // TODO(johnniwinther): Report augmentation conflict.
        return false;
      }
    } else {
      // Example:
      //
      //    class A {
      //      A();
      //      A();
      //    }
      //
      problemReporting.addProblem(
          templateDuplicatedDeclaration.withArguments(fragmentName.name),
          fragmentName.nameOffset,
          fragmentName.nameLength,
          fragmentName.fileUri,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause
                .withArguments(fragment.name)
                .withLocation(
                    fragment.fileUri, fragment.nameOffset, fragment.nameLength)
          ]);
      return false;
    }
  }

  @override
  void checkFragment(
      ProblemReporting problemReporting, _FragmentName nonConstructorFragment) {
    // Check conflict with non-constructor.
    if (nonConstructorFragment.isStatic) {
      // Coverage-ignore-block(suite): Not run.
      if (fragment.kind == _FragmentKind.Constructor) {
        // Example:
        //
        //    class A {
        //      A.foo();
        //      static void foo() {}
        //    }
        //
        problemReporting.addProblem(
            templateMemberConflictsWithConstructor.withArguments(fragment.name),
            nonConstructorFragment.nameOffset,
            nonConstructorFragment.nameLength,
            nonConstructorFragment.fileUri,
            context: [
              templateMemberConflictsWithConstructorCause
                  .withArguments(fragment.name)
                  .withLocation(fragment.fileUri, fragment.nameOffset,
                      fragment.nameLength)
            ]);
      } else {
        assert(fragment.kind == _FragmentKind.Factory,
            "Unexpected constructor kind $fragment");
        // Example:
        //
        //    class A {
        //      factory A.foo() => throw '';
        //      static void foo() {}
        //    }
        //
        problemReporting.addProblem(
            templateMemberConflictsWithFactory.withArguments(fragment.name),
            nonConstructorFragment.nameOffset,
            nonConstructorFragment.nameLength,
            nonConstructorFragment.fileUri,
            context: [
              templateMemberConflictsWithFactoryCause
                  .withArguments(fragment.name)
                  .withLocation(fragment.fileUri, fragment.nameOffset,
                      fragment.nameLength)
            ]);
      }
    }
  }

  @override
  void createBuilders(
      void Function(Fragment, {bool conflictingSetter}) createBuilder) {
    createBuilder(fragment.fragment);
    for (_FragmentName fragmentName in augmentations) {
      // Coverage-ignore-block(suite): Not run.
      createBuilder(fragmentName.fragment);
    }
  }
}

/// [_PreBuilder] for non-constructor, non-property declarations.
class _DeclarationPreBuilder extends _PreBuilder {
  final _FragmentName fragment;
  final List<_FragmentName> augmentations = [];

  // TODO(johnniwinther): Report error if [fragment] is augmenting.
  _DeclarationPreBuilder(this.fragment);

  @override
  bool absorbFragment(
      ProblemReporting problemReporting, _FragmentName fragmentName) {
    if (fragmentName.isAugment) {
      if (fragmentName.kind == fragment.kind) {
        // Example:
        //
        //    class Foo {}
        //    augment class Foo {}
        //
        augmentations.add(fragmentName);
        return true;
      } else {
        // Example:
        //
        //    class Foo {}
        //    augment extension Foo {}
        //
        // TODO(johnniwinther): Report augmentation conflict.
        return false;
      }
    } else {
      if (fragmentName.propertyKind == _PropertyKind.Setter) {
        // Example:
        //
        //    class Foo {}
        //    set Foo(_) {}
        //
        problemReporting.addProblem(
            templateSetterConflictsWithDeclaration.withArguments(fragment.name),
            fragmentName.nameOffset,
            fragmentName.nameLength,
            fragmentName.fileUri,
            context: [
              templateSetterConflictsWithDeclarationCause
                  .withArguments(fragment.name)
                  .withLocation(fragment.fileUri, fragment.nameOffset,
                      fragment.nameLength)
            ]);
      } else {
        // Example:
        //
        //    class Foo {}
        //    class Foo {}
        //
        problemReporting.addProblem(
            templateDuplicatedDeclaration.withArguments(fragmentName.name),
            fragmentName.nameOffset,
            fragmentName.nameLength,
            fragmentName.fileUri,
            context: <LocatedMessage>[
              templateDuplicatedDeclarationCause
                  .withArguments(fragment.name)
                  .withLocation(fragment.fileUri, fragment.nameOffset,
                      fragment.nameLength)
            ]);
      }
      return false;
    }
  }

  @override
  void checkFragment(
      ProblemReporting problemReporting, _FragmentName constructorFragment) {
    // Check conflict with constructor.
    if (fragment.isStatic) {
      if (constructorFragment.kind == _FragmentKind.Constructor) {
        // Example:
        //
        //    class A {
        //      static void foo() {}
        //      A.foo();
        //    }
        //
        problemReporting.addProblem(
            templateConstructorConflictsWithMember.withArguments(fragment.name),
            constructorFragment.nameOffset,
            constructorFragment.nameLength,
            constructorFragment.fileUri,
            context: [
              templateConstructorConflictsWithMemberCause
                  .withArguments(fragment.name)
                  .withLocation(fragment.fileUri, fragment.nameOffset,
                      fragment.nameLength)
            ]);
      } else {
        assert(constructorFragment.kind == _FragmentKind.Factory,
            "Unexpected constructor kind $constructorFragment");
        // Example:
        //
        //    class A {
        //      static void foo() {}
        //      factory A.foo() => throw '';
        //    }
        //
        problemReporting.addProblem(
            templateFactoryConflictsWithMember.withArguments(fragment.name),
            constructorFragment.nameOffset,
            constructorFragment.nameLength,
            constructorFragment.fileUri,
            context: [
              templateFactoryConflictsWithMemberCause
                  .withArguments(fragment.name)
                  .withLocation(fragment.fileUri, fragment.nameOffset,
                      fragment.nameLength)
            ]);
      }
    }
  }

  @override
  void createBuilders(
      void Function(Fragment, {bool conflictingSetter}) createBuilder) {
    createBuilder(fragment.fragment);
    for (_FragmentName fragmentName in augmentations) {
      createBuilder(fragmentName.fragment);
    }
  }
}

_PreBuilder _createPreBuilder(_FragmentName fragmentName) {
  switch (fragmentName.fragment) {
    case ClassFragment():
    case EnumFragment():
    case ExtensionFragment():
    case ExtensionTypeFragment():
    case MethodFragment():
    case MixinFragment():
    case NamedMixinApplicationFragment():
    case TypedefFragment():
      return new _DeclarationPreBuilder(fragmentName);
    case ConstructorFragment():
    case FactoryFragment():
    case PrimaryConstructorFragment():
      return new _ConstructorPreBuilder(fragmentName);
    case FieldFragment():
      return new _PropertyPreBuilder.forField(fragmentName);
    case GetterFragment():
      return new _PropertyPreBuilder.forGetter(fragmentName);
    case SetterFragment():
      return new _PropertyPreBuilder.forSetter(fragmentName);
  }
}

void _computeBuildersFromFragments(String name, List<Fragment> fragments,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
    required List<_AddBuilder> builders,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    IndexedContainer? indexedContainer,
    ContainerName? containerName}) {
  List<_PreBuilder> nonConstructorPreBuilders = [];
  List<_PreBuilder> constructorPreBuilders = [];
  List<Fragment> unnamedFragments = [];

  void addPreBuilder(_FragmentName fragmentName,
      List<_PreBuilder> thesePreBuilders, List<_PreBuilder> otherPreBuilders) {
    for (_PreBuilder existingPreBuilder in thesePreBuilders) {
      if (existingPreBuilder.absorbFragment(problemReporting, fragmentName)) {
        return;
      }
    }
    thesePreBuilders.add(_createPreBuilder(fragmentName));
    if (otherPreBuilders.isNotEmpty) {
      otherPreBuilders.first.checkFragment(problemReporting, fragmentName);
    }
  }

  void addNonConstructorPreBuilder(_FragmentName fragmentName) {
    addPreBuilder(
        fragmentName, nonConstructorPreBuilders, constructorPreBuilders);
  }

  void addConstructorPreBuilder(_FragmentName fragmentName) {
    addPreBuilder(
        fragmentName, constructorPreBuilders, nonConstructorPreBuilders);
  }

  void addFragment(_FragmentName fragmentName) {
    switch (fragmentName.kind) {
      case _FragmentKind.Constructor:
      case _FragmentKind.Factory:
        addConstructorPreBuilder(fragmentName);
      case _FragmentKind.Class:
      case _FragmentKind.Mixin:
      case _FragmentKind.NamedMixinApplication:
      case _FragmentKind.Enum:
      case _FragmentKind.Extension:
      case _FragmentKind.ExtensionType:
      case _FragmentKind.Typedef:
      case _FragmentKind.Method:
      case _FragmentKind.Property:
        addNonConstructorPreBuilder(fragmentName);
    }
  }

  for (Fragment fragment in fragments) {
    switch (fragment) {
      case ClassFragment():
        addFragment(new _FragmentName(_FragmentKind.Class, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            isAugment: fragment.modifiers.isAugment));
      case EnumFragment():
        addFragment(new _FragmentName(_FragmentKind.Enum, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            // TODO(johnniwinther): Support enum augmentations.
            isAugment: false));
      case ExtensionTypeFragment():
        addFragment(new _FragmentName(_FragmentKind.ExtensionType, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            isAugment: fragment.modifiers.isAugment));
      case MethodFragment():
        addFragment(new _FragmentName(_FragmentKind.Method, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            isAugment: fragment.modifiers.isAugment,
            isStatic:
                declarationBuilder == null || fragment.modifiers.isStatic));
      case MixinFragment():
        addFragment(new _FragmentName(_FragmentKind.Mixin, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            isAugment: fragment.modifiers.isAugment));
      case NamedMixinApplicationFragment():
        addFragment(new _FragmentName(
            _FragmentKind.NamedMixinApplication, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            isAugment: fragment.modifiers.isAugment));
      case TypedefFragment():
        addFragment(new _FragmentName(_FragmentKind.Typedef, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            // TODO(johnniwinther): Support typedef augmentations.
            isAugment: false));
      case ExtensionFragment():
        if (!fragment.isUnnamed) {
          addFragment(new _FragmentName(_FragmentKind.Extension, fragment,
              fileUri: fragment.fileUri,
              name: fragment.name,
              nameOffset: fragment.fileOffset,
              nameLength: fragment.name.length,
              isAugment: fragment.modifiers.isAugment));
        } else {
          unnamedFragments.add(fragment);
        }
      case FactoryFragment():
        addFragment(new _FragmentName(_FragmentKind.Factory, fragment,
            fileUri: fragment.fileUri,
            name: fragment.constructorName.fullName,
            nameOffset: fragment.constructorName.fullNameOffset,
            nameLength: fragment.constructorName.fullNameLength,
            isAugment: fragment.modifiers.isAugment));
      case ConstructorFragment():
        addFragment(new _FragmentName(_FragmentKind.Constructor, fragment,
            fileUri: fragment.fileUri,
            name: fragment.constructorName.fullName,
            nameOffset: fragment.constructorName.fullNameOffset,
            nameLength: fragment.constructorName.fullNameLength,
            isAugment: fragment.modifiers.isAugment));
      case PrimaryConstructorFragment():
        addFragment(new _FragmentName(_FragmentKind.Constructor, fragment,
            fileUri: fragment.fileUri,
            name: fragment.constructorName.fullName,
            nameOffset: fragment.constructorName.fullNameOffset,
            nameLength: fragment.constructorName.fullNameLength,
            isAugment: fragment.modifiers.isAugment));
      case FieldFragment():
        _FragmentName fragmentName = new _FragmentName(
            _FragmentKind.Property, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            isAugment: fragment.modifiers.isAugment,
            propertyKind: fragment.hasSetter
                ? _PropertyKind.Field
                : _PropertyKind.FinalField,
            isStatic:
                declarationBuilder == null || fragment.modifiers.isStatic);
        addFragment(fragmentName);
      case GetterFragment():
        _FragmentName fragmentName = new _FragmentName(
            _FragmentKind.Property, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            isAugment: fragment.modifiers.isAugment,
            propertyKind: _PropertyKind.Getter,
            isStatic:
                declarationBuilder == null || fragment.modifiers.isStatic);
        addFragment(fragmentName);
      case SetterFragment():
        _FragmentName fragmentName = new _FragmentName(
            _FragmentKind.Property, fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.nameOffset,
            nameLength: fragment.name.length,
            isAugment: fragment.modifiers.isAugment,
            propertyKind: _PropertyKind.Setter,
            isStatic:
                declarationBuilder == null || fragment.modifiers.isStatic);
        addFragment(fragmentName);
    }
  }

  void createBuilder(Fragment fragment, {bool conflictingSetter = false}) {
    switch (fragment) {
      case TypedefFragment():
        Reference? reference = indexedLibrary?.lookupTypedef(fragment.name);
        SourceTypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
            name: fragment.name,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            fileOffset: fragment.nameOffset,
            fragment: fragment,
            reference: reference);
        builders.add(new _AddBuilder(fragment.name, typedefBuilder,
            fragment.fileUri, fragment.nameOffset));
        if (reference != null) {
          loader.buildersCreatedWithReferences[reference] = typedefBuilder;
        }
      case ClassFragment():
        IndexedClass? indexedClass =
            indexedLibrary?.lookupIndexedClass(fragment.name);
        SourceClassBuilder classBuilder = new SourceClassBuilder(
            metadata: fragment.metadata,
            modifiers: fragment.modifiers,
            name: fragment.name,
            typeParameters: fragment.typeParameters,
            supertypeBuilder: BuilderFactoryImpl.applyMixins(
                unboundNominalParameters: unboundNominalParameters,
                compilationUnitScope: fragment.compilationUnitScope,
                problemReporting: problemReporting,
                objectTypeBuilder: loader.target.objectType,
                enclosingLibraryBuilder: enclosingLibraryBuilder,
                fileUri: fragment.fileUri,
                indexedLibrary: indexedLibrary,
                supertype: fragment.supertype,
                mixinApplicationBuilder: fragment.mixins,
                mixinApplications: mixinApplications,
                startOffset: fragment.startOffset,
                nameOffset: fragment.nameOffset,
                endOffset: fragment.endOffset,
                subclassName: fragment.name,
                isMixinDeclaration: false,
                typeParameters: fragment.typeParameters,
                modifiers: Modifiers.empty,
                addBuilder: (String name, Builder declaration, int charOffset,
                    {Reference? getterReference}) {
                  if (getterReference != null) {
                    loader.buildersCreatedWithReferences[getterReference] =
                        declaration;
                  }
                  builders.add(new _AddBuilder(
                      name, declaration, fragment.fileUri, charOffset));
                }),
            interfaceBuilders: fragment.interfaces,
            onTypes: null,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
            libraryBuilder: enclosingLibraryBuilder,
            constructorReferences: fragment.constructorReferences,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            indexedClass: indexedClass,
            isMixinDeclaration: false);
        fragment.builder = classBuilder;
        fragment.bodyScope.declarationBuilder = classBuilder;
        builders.add(new _AddBuilder(fragment.name, classBuilder,
            fragment.fileUri, fragment.fileOffset));
        if (indexedClass != null) {
          loader.buildersCreatedWithReferences[indexedClass.reference] =
              classBuilder;
        }
      case MixinFragment():
        IndexedClass? indexedClass =
            indexedLibrary?.lookupIndexedClass(fragment.name);
        SourceClassBuilder mixinBuilder = new SourceClassBuilder(
            metadata: fragment.metadata,
            modifiers: fragment.modifiers,
            name: fragment.name,
            typeParameters: fragment.typeParameters,
            supertypeBuilder: BuilderFactoryImpl.applyMixins(
                unboundNominalParameters: unboundNominalParameters,
                compilationUnitScope: fragment.compilationUnitScope,
                problemReporting: problemReporting,
                objectTypeBuilder: loader.target.objectType,
                enclosingLibraryBuilder: enclosingLibraryBuilder,
                fileUri: fragment.fileUri,
                indexedLibrary: indexedLibrary,
                supertype: fragment.supertype,
                mixinApplicationBuilder: fragment.mixins,
                mixinApplications: mixinApplications,
                startOffset: fragment.startOffset,
                nameOffset: fragment.nameOffset,
                endOffset: fragment.endOffset,
                subclassName: fragment.name,
                isMixinDeclaration: true,
                typeParameters: fragment.typeParameters,
                modifiers: Modifiers.empty,
                addBuilder: (String name, Builder declaration, int charOffset,
                    {Reference? getterReference}) {
                  if (getterReference != null) {
                    loader.buildersCreatedWithReferences[getterReference] =
                        declaration;
                  }
                  builders.add(new _AddBuilder(
                      name, declaration, fragment.fileUri, charOffset));
                }),
            interfaceBuilders: fragment.interfaces,
            // TODO(johnniwinther): Add the `on` clause types of a mixin
            //  declaration here.
            onTypes: null,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
            libraryBuilder: enclosingLibraryBuilder,
            constructorReferences: fragment.constructorReferences,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            indexedClass: indexedClass,
            isMixinDeclaration: true);
        fragment.builder = mixinBuilder;
        fragment.bodyScope.declarationBuilder = mixinBuilder;
        builders.add(new _AddBuilder(fragment.name, mixinBuilder,
            fragment.fileUri, fragment.fileOffset));
        if (indexedClass != null) {
          loader.buildersCreatedWithReferences[indexedClass.reference] =
              mixinBuilder;
        }
      case NamedMixinApplicationFragment():
        BuilderFactoryImpl.applyMixins(
            unboundNominalParameters: unboundNominalParameters,
            compilationUnitScope: fragment.compilationUnitScope,
            problemReporting: problemReporting,
            objectTypeBuilder: loader.target.objectType,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            indexedLibrary: indexedLibrary,
            supertype: fragment.supertype,
            mixinApplicationBuilder: fragment.mixins,
            mixinApplications: mixinApplications,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            subclassName: fragment.name,
            isMixinDeclaration: false,
            metadata: fragment.metadata,
            name: fragment.name,
            typeParameters: fragment.typeParameters,
            modifiers: fragment.modifiers,
            interfaces: fragment.interfaces,
            addBuilder: (String name, Builder declaration, int charOffset,
                {Reference? getterReference}) {
              if (getterReference != null) {
                loader.buildersCreatedWithReferences[getterReference] =
                    declaration;
              }
              builders.add(new _AddBuilder(
                  name, declaration, fragment.fileUri, charOffset));
            });

      case EnumFragment():
        IndexedClass? indexedClass =
            indexedLibrary?.lookupIndexedClass(fragment.name);
        SourceEnumBuilder enumBuilder = new SourceEnumBuilder(
            metadata: fragment.metadata,
            name: fragment.name,
            typeParameters: fragment.typeParameters,
            underscoreEnumTypeBuilder: loader.target.underscoreEnumType,
            supertypeBuilder: BuilderFactoryImpl.applyMixins(
                unboundNominalParameters: unboundNominalParameters,
                compilationUnitScope: fragment.compilationUnitScope,
                problemReporting: problemReporting,
                objectTypeBuilder: loader.target.objectType,
                enclosingLibraryBuilder: enclosingLibraryBuilder,
                fileUri: fragment.fileUri,
                indexedLibrary: indexedLibrary,
                supertype: loader.target.underscoreEnumType,
                mixinApplicationBuilder: fragment.supertypeBuilder,
                mixinApplications: mixinApplications,
                startOffset: fragment.startOffset,
                nameOffset: fragment.nameOffset,
                endOffset: fragment.endOffset,
                subclassName: fragment.name,
                isMixinDeclaration: false,
                typeParameters: fragment.typeParameters,
                modifiers: Modifiers.empty,
                addBuilder: (String name, Builder declaration, int charOffset,
                    {Reference? getterReference}) {
                  if (getterReference != null) {
                    loader.buildersCreatedWithReferences[getterReference] =
                        declaration;
                  }
                  builders.add(new _AddBuilder(
                      name, declaration, fragment.fileUri, charOffset));
                }),
            interfaceBuilders: fragment.interfaces,
            enumConstantInfos: fragment.enumConstantInfos,
            libraryBuilder: enclosingLibraryBuilder,
            constructorReferences: fragment.constructorReferences,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            indexedClass: indexedClass,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder());
        fragment.builder = enumBuilder;
        fragment.bodyScope.declarationBuilder = enumBuilder;
        builders.add(new _AddBuilder(
            fragment.name, enumBuilder, fragment.fileUri, fragment.fileOffset));
        if (indexedClass != null) {
          loader.buildersCreatedWithReferences[indexedClass.reference] =
              enumBuilder;
        }
      case ExtensionFragment():
        Reference? reference;
        if (!fragment.extensionName.isUnnamedExtension) {
          reference = indexedLibrary?.lookupExtension(fragment.name);
        }
        SourceExtensionBuilder extensionBuilder = new SourceExtensionBuilder(
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOrExtensionOffset,
            endOffset: fragment.endOffset,
            fragment: fragment,
            reference: reference);
        builders.add(new _AddBuilder(fragment.name, extensionBuilder,
            fragment.fileUri, fragment.fileOffset));
        if (reference != null) {
          loader.buildersCreatedWithReferences[reference] = extensionBuilder;
        }
      case ExtensionTypeFragment():
        IndexedContainer? indexedContainer = indexedLibrary
            ?.lookupIndexedExtensionTypeDeclaration(fragment.name);
        List<FieldFragment>? primaryConstructorFields =
            fragment.primaryConstructorFields;
        FieldFragment? representationFieldFragment;
        if (primaryConstructorFields != null &&
            primaryConstructorFields.isNotEmpty) {
          representationFieldFragment = primaryConstructorFields.first;
        }
        SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
            new SourceExtensionTypeDeclarationBuilder(
                name: fragment.name,
                enclosingLibraryBuilder: enclosingLibraryBuilder,
                constructorReferences: fragment.constructorReferences,
                fileUri: fragment.fileUri,
                startOffset: fragment.startOffset,
                nameOffset: fragment.nameOffset,
                endOffset: fragment.endOffset,
                fragment: fragment,
                indexedContainer: indexedContainer,
                representationFieldFragment: representationFieldFragment);
        builders.add(new _AddBuilder(
            fragment.name,
            extensionTypeDeclarationBuilder,
            fragment.fileUri,
            fragment.fileOffset));
      case FieldFragment():
        String name = fragment.name;

        final bool fieldIsLateWithLowering = fragment.modifiers.isLate &&
            (loader.target.backendTarget.isLateFieldLoweringEnabled(
                    hasInitializer: fragment.modifiers.hasInitializer,
                    isFinal: fragment.modifiers.isFinal,
                    isStatic:
                        fragment.isTopLevel || fragment.modifiers.isStatic) ||
                (loader.target.backendTarget.useStaticFieldLowering &&
                    // Coverage-ignore(suite): Not run.
                    (fragment.modifiers.isStatic || fragment.isTopLevel)));

        final bool isInstanceMember = containerType != ContainerType.Library &&
            !fragment.modifiers.isStatic;
        final bool isExtensionMember = containerType == ContainerType.Extension;
        final bool isExtensionTypeMember =
            containerType == ContainerType.ExtensionType;

        NameScheme nameScheme = new NameScheme(
            isInstanceMember: isInstanceMember,
            containerName: containerName,
            containerType: containerType,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.reference)
                : enclosingLibraryBuilder.libraryName);
        indexedContainer ??= indexedLibrary;

        Reference? fieldReference;
        Reference? fieldGetterReference;
        Reference? fieldSetterReference;
        Reference? lateIsSetFieldReference;
        Reference? lateIsSetGetterReference;
        Reference? lateIsSetSetterReference;
        Reference? lateGetterReference;
        Reference? lateSetterReference;
        if (indexedContainer != null) {
          if ((isExtensionMember || isExtensionTypeMember) &&
              isInstanceMember &&
              fragment.modifiers.isExternal) {
            /// An external extension (type) instance field is special. It is
            /// treated as an external getter/setter pair and is therefore
            /// encoded as a pair of top level methods using the extension
            /// instance member naming convention.
            fieldGetterReference = indexedContainer!.lookupGetterReference(
                nameScheme
                    .getProcedureMemberName(ProcedureKind.Getter, name)
                    .name);
            fieldSetterReference = indexedContainer!.lookupGetterReference(
                nameScheme
                    .getProcedureMemberName(ProcedureKind.Setter, name)
                    .name);
          } else if (isExtensionTypeMember && isInstanceMember) {
            Name nameToLookup = nameScheme
                .getFieldMemberName(FieldNameType.RepresentationField, name,
                    isSynthesized: true)
                .name;
            fieldGetterReference =
                indexedContainer!.lookupGetterReference(nameToLookup);
          } else {
            Name nameToLookup = nameScheme
                .getFieldMemberName(FieldNameType.Field, name,
                    isSynthesized: fieldIsLateWithLowering)
                .name;
            fieldReference =
                indexedContainer!.lookupFieldReference(nameToLookup);
            fieldGetterReference =
                indexedContainer!.lookupGetterReference(nameToLookup);
            fieldSetterReference =
                indexedContainer!.lookupSetterReference(nameToLookup);
          }

          if (fieldIsLateWithLowering) {
            Name lateIsSetName = nameScheme
                .getFieldMemberName(FieldNameType.IsSetField, name,
                    isSynthesized: fieldIsLateWithLowering)
                .name;
            lateIsSetFieldReference =
                indexedContainer!.lookupFieldReference(lateIsSetName);
            lateIsSetGetterReference =
                indexedContainer!.lookupGetterReference(lateIsSetName);
            lateIsSetSetterReference =
                indexedContainer!.lookupSetterReference(lateIsSetName);
            lateGetterReference = indexedContainer!.lookupGetterReference(
                nameScheme
                    .getFieldMemberName(FieldNameType.Getter, name,
                        isSynthesized: fieldIsLateWithLowering)
                    .name);
            lateSetterReference = indexedContainer!.lookupSetterReference(
                nameScheme
                    .getFieldMemberName(FieldNameType.Setter, name,
                        isSynthesized: fieldIsLateWithLowering)
                    .name);
          }
        }
        SourceFieldBuilder fieldBuilder = new SourceFieldBuilder(
            metadata: fragment.metadata,
            type: fragment.type,
            name: name,
            modifiers: fragment.modifiers,
            isTopLevel: fragment.isTopLevel,
            isPrimaryConstructorField: fragment.isPrimaryConstructorField,
            libraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            fileUri: fragment.fileUri,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            nameScheme: nameScheme,
            fieldReference: fieldReference,
            fieldGetterReference: fieldGetterReference,
            fieldSetterReference: fieldSetterReference,
            lateIsSetFieldReference: lateIsSetFieldReference,
            lateIsSetGetterReference: lateIsSetGetterReference,
            lateIsSetSetterReference: lateIsSetSetterReference,
            lateGetterReference: lateGetterReference,
            lateSetterReference: lateSetterReference,
            initializerToken: fragment.initializerToken,
            constInitializerToken: fragment.constInitializerToken);
        fragment.builder = fieldBuilder;
        builders.add(new _AddBuilder(fragment.name, fieldBuilder,
            fragment.fileUri, fragment.nameOffset));
        if (fieldGetterReference != null) {
          loader.buildersCreatedWithReferences[fieldGetterReference] =
              fieldBuilder;
        }
        if (fieldSetterReference != null) {
          loader.buildersCreatedWithReferences[fieldSetterReference] =
              fieldBuilder;
        }
      case GetterFragment():
        String name = fragment.name;
        final bool isInstanceMember = containerType != ContainerType.Library &&
            !fragment.modifiers.isStatic;

        var (
          List<NominalParameterBuilder>? typeParameters,
          List<FormalParameterBuilder>? formals
        ) = _createTypeParametersAndFormals(
            declarationBuilder, null, null, unboundNominalParameters,
            isInstanceMember: isInstanceMember,
            fileUri: fragment.fileUri,
            nameOffset: fragment.nameOffset);

        fragment.typeParameterNameSpace.addTypeParameters(
            problemReporting, typeParameters,
            ownerName: name, allowNameConflict: true);

        NameScheme nameScheme = new NameScheme(
            containerName: containerName,
            containerType: containerType,
            isInstanceMember: isInstanceMember,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? procedureReference;
        indexedContainer ??= indexedLibrary;

        bool isAugmentation = enclosingLibraryBuilder.isAugmenting &&
            fragment.modifiers.isAugment;

        ProcedureKind kind = ProcedureKind.Getter;
        if (indexedContainer != null && !isAugmentation) {
          Name nameToLookup =
              nameScheme.getProcedureMemberName(kind, name).name;
          procedureReference =
              indexedContainer!.lookupGetterReference(nameToLookup);
        }
        SourcePropertyBuilder propertyBuilder =
            new SourcePropertyBuilder.forGetter(
                fileUri: fragment.fileUri,
                fileOffset: fragment.nameOffset,
                name: name,
                libraryBuilder: enclosingLibraryBuilder,
                declarationBuilder: declarationBuilder,
                isStatic: fragment.modifiers.isStatic,
                fragment: fragment,
                nameScheme: nameScheme,
                getterReference: procedureReference);
        fragment.setBuilder(propertyBuilder, typeParameters, formals);
        builders.add(new _AddBuilder(fragment.name, propertyBuilder,
            fragment.fileUri, fragment.nameOffset));
        if (procedureReference != null) {
          loader.buildersCreatedWithReferences[procedureReference] =
              propertyBuilder;
        }
      case SetterFragment():
        String name = fragment.name;
        final bool isInstanceMember = containerType != ContainerType.Library &&
            !fragment.modifiers.isStatic;

        var (
          List<NominalParameterBuilder>? typeParameters,
          List<FormalParameterBuilder>? formals
        ) = _createTypeParametersAndFormals(
            declarationBuilder, null, null, unboundNominalParameters,
            isInstanceMember: isInstanceMember,
            fileUri: fragment.fileUri,
            nameOffset: fragment.nameOffset);

        fragment.typeParameterNameSpace.addTypeParameters(
            problemReporting, typeParameters,
            ownerName: name, allowNameConflict: true);

        final bool isExtensionMember = containerType == ContainerType.Extension;
        final bool isExtensionTypeMember =
            containerType == ContainerType.ExtensionType;

        NameScheme nameScheme = new NameScheme(
            containerName: containerName,
            containerType: containerType,
            isInstanceMember: isInstanceMember,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? procedureReference;
        indexedContainer ??= indexedLibrary;

        bool isAugmentation = enclosingLibraryBuilder.isAugmenting &&
            fragment.modifiers.isAugment;

        ProcedureKind kind = ProcedureKind.Setter;
        if (indexedContainer != null && !isAugmentation) {
          Name nameToLookup =
              nameScheme.getProcedureMemberName(kind, name).name;
          if ((isExtensionMember || isExtensionTypeMember) &&
              isInstanceMember) {
            // Extension (type) instance setters are encoded as methods.
            procedureReference =
                indexedContainer!.lookupGetterReference(nameToLookup);
          } else {
            procedureReference =
                indexedContainer!.lookupSetterReference(nameToLookup);
          }
        }
        SourcePropertyBuilder propertyBuilder =
            new SourcePropertyBuilder.forSetter(
                fileUri: fragment.fileUri,
                fileOffset: fragment.nameOffset,
                name: name,
                libraryBuilder: enclosingLibraryBuilder,
                declarationBuilder: declarationBuilder,
                isStatic: fragment.modifiers.isStatic,
                fragment: fragment,
                nameScheme: nameScheme,
                setterReference: procedureReference);
        fragment.setBuilder(propertyBuilder, typeParameters, formals);
        builders.add(new _AddBuilder(fragment.name, propertyBuilder,
            fragment.fileUri, fragment.nameOffset));
        if (procedureReference != null) {
          loader.buildersCreatedWithReferences[procedureReference] =
              propertyBuilder;
        }
        if (conflictingSetter) {
          propertyBuilder.isConflictingSetter = true;
        }
      case MethodFragment():
        String name = fragment.name;
        final bool isInstanceMember = containerType != ContainerType.Library &&
            !fragment.modifiers.isStatic;

        var (
          List<NominalParameterBuilder>? typeParameters,
          List<FormalParameterBuilder>? formals
        ) = _createTypeParametersAndFormals(declarationBuilder,
            fragment.typeParameters, fragment.formals, unboundNominalParameters,
            isInstanceMember: isInstanceMember,
            fileUri: fragment.fileUri,
            nameOffset: fragment.nameOffset);

        fragment.typeParameterNameSpace.addTypeParameters(
            problemReporting, typeParameters,
            ownerName: name, allowNameConflict: true);

        ProcedureKind kind = fragment.kind;
        assert(kind == ProcedureKind.Method || kind == ProcedureKind.Operator);

        final bool isExtensionMember = containerType == ContainerType.Extension;
        final bool isExtensionTypeMember =
            containerType == ContainerType.ExtensionType;

        NameScheme nameScheme = new NameScheme(
            containerName: containerName,
            containerType: containerType,
            isInstanceMember: isInstanceMember,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? procedureReference;
        Reference? tearOffReference;
        indexedContainer ??= indexedLibrary;

        bool isAugmentation = enclosingLibraryBuilder.isAugmenting &&
            fragment.modifiers.isAugment;
        if (indexedContainer != null && !isAugmentation) {
          Name nameToLookup =
              nameScheme.getProcedureMemberName(kind, name).name;
          procedureReference =
              indexedContainer!.lookupGetterReference(nameToLookup);
          if ((isExtensionMember || isExtensionTypeMember) &&
              kind == ProcedureKind.Method) {
            tearOffReference = indexedContainer!.lookupGetterReference(
                nameScheme
                    .getProcedureMemberName(ProcedureKind.Getter, name)
                    .name);
          }
        }

        SourceProcedureBuilder procedureBuilder = new SourceProcedureBuilder(
            metadata: fragment.metadata,
            modifiers: fragment.modifiers,
            returnType: fragment.returnType,
            name: name,
            typeParameters: typeParameters,
            formals: formals,
            kind: kind,
            libraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            formalsOffset: fragment.formalsOffset,
            endOffset: fragment.endOffset,
            procedureReference: procedureReference,
            tearOffReference: tearOffReference,
            asyncModifier: fragment.asyncModifier,
            nameScheme: nameScheme,
            nativeMethodName: fragment.nativeMethodName);
        fragment.builder = procedureBuilder;
        builders.add(new _AddBuilder(fragment.name, procedureBuilder,
            fragment.fileUri, fragment.nameOffset));
        if (procedureReference != null) {
          loader.buildersCreatedWithReferences[procedureReference] =
              procedureBuilder;
        }
      case ConstructorFragment():
        List<NominalParameterBuilder>? typeParameters = fragment.typeParameters;
        switch (declarationBuilder!) {
          case ExtensionBuilder():
          case ExtensionTypeDeclarationBuilder():
            NominalParameterCopy? nominalVariableCopy =
                BuilderFactoryImpl.copyTypeParameters(
                    unboundNominalParameters, declarationBuilder.typeParameters,
                    kind: TypeParameterKind.extensionSynthesized,
                    instanceTypeParameterAccess:
                        InstanceTypeParameterAccessState.Allowed);
            if (nominalVariableCopy != null) {
              if (typeParameters != null) {
                // Coverage-ignore-block(suite): Not run.
                typeParameters = nominalVariableCopy.newParameterBuilders
                  ..addAll(typeParameters);
              } else {
                typeParameters = nominalVariableCopy.newParameterBuilders;
              }
            }
          case ClassBuilder():
        }
        fragment.typeParameterNameSpace.addTypeParameters(
            problemReporting, typeParameters,
            ownerName: fragment.name, allowNameConflict: true);

        String name = fragment.name;
        NameScheme nameScheme = new NameScheme(
            isInstanceMember: false,
            containerName: containerName,
            containerType: containerType,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? constructorReference;
        Reference? tearOffReference;

        if (indexedContainer != null) {
          constructorReference = indexedContainer!.lookupConstructorReference(
              nameScheme.getConstructorMemberName(name, isTearOff: false).name);
          tearOffReference = indexedContainer!.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: true).name);
        }

        AbstractSourceConstructorBuilder constructorBuilder;
        if (declarationBuilder is SourceExtensionTypeDeclarationBuilder) {
          constructorBuilder = new SourceExtensionTypeConstructorBuilder(
              metadata: fragment.metadata,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: name,
              typeParameters: typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              fileOffset: fragment.fullNameOffset,
              formalsOffset: fragment.formalsOffset,
              endOffset: fragment.endOffset,
              constructorReference: constructorReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              nativeMethodName: fragment.nativeMethodName,
              forAbstractClassOrEnumOrMixin: fragment.forAbstractClassOrMixin,
              beginInitializers: fragment.beginInitializers);
        } else {
          constructorBuilder = new DeclaredSourceConstructorBuilder(
              metadata: fragment.metadata,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: fragment.name,
              typeParameters: typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              fileOffset: fragment.fullNameOffset,
              formalsOffset: fragment.formalsOffset,
              endOffset: fragment.endOffset,
              constructorReference: constructorReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              nativeMethodName: fragment.nativeMethodName,
              forAbstractClassOrEnumOrMixin: fragment.forAbstractClassOrMixin,
              beginInitializers: fragment.beginInitializers);
        }
        fragment.builder = constructorBuilder;
        builders.add(new _AddBuilder(fragment.name, constructorBuilder,
            fragment.fileUri, fragment.fullNameOffset));

        // TODO(johnniwinther): There is no way to pass the tear off reference
        //  here.
        if (constructorReference != null) {
          loader.buildersCreatedWithReferences[constructorReference] =
              constructorBuilder;
        }
      case PrimaryConstructorFragment():
        String name = fragment.name;

        NominalParameterCopy? nominalVariableCopy =
            BuilderFactoryImpl.copyTypeParameters(
                unboundNominalParameters, declarationBuilder!.typeParameters,
                kind: TypeParameterKind.extensionSynthesized,
                instanceTypeParameterAccess:
                    InstanceTypeParameterAccessState.Allowed);

        List<NominalParameterBuilder>? typeParameters =
            nominalVariableCopy?.newParameterBuilders;
        fragment.typeParameterNameSpace.addTypeParameters(
            problemReporting, typeParameters,
            ownerName: fragment.name, allowNameConflict: true);

        NameScheme nameScheme = new NameScheme(
            isInstanceMember: false,
            containerName: containerName,
            containerType: containerType,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? constructorReference;
        Reference? tearOffReference;

        if (indexedContainer != null) {
          constructorReference = indexedContainer!.lookupConstructorReference(
              nameScheme.getConstructorMemberName(name, isTearOff: false).name);
          tearOffReference = indexedContainer!.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: true).name);
        }

        AbstractSourceConstructorBuilder constructorBuilder;
        if (declarationBuilder is SourceExtensionTypeDeclarationBuilder) {
          constructorBuilder = new SourceExtensionTypeConstructorBuilder(
              metadata: null,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: name,
              typeParameters: typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              fileOffset: fragment.fileOffset,
              formalsOffset: fragment.formalsOffset,
              // TODO(johnniwinther): Provide `endOffset`.
              endOffset: fragment.formalsOffset,
              constructorReference: constructorReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              forAbstractClassOrEnumOrMixin: fragment.forAbstractClassOrMixin,
              beginInitializers: fragment.beginInitializers);
        } else {
          // Coverage-ignore-block(suite): Not run.
          constructorBuilder = new DeclaredSourceConstructorBuilder(
              metadata: null,
              modifiers: fragment.modifiers,
              returnType: fragment.returnType,
              name: fragment.name,
              typeParameters: typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              fileOffset: fragment.fileOffset,
              formalsOffset: fragment.formalsOffset,
              // TODO(johnniwinther): Provide `endOffset`.
              endOffset: fragment.formalsOffset,
              constructorReference: constructorReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              forAbstractClassOrEnumOrMixin: fragment.forAbstractClassOrMixin,
              beginInitializers: fragment.beginInitializers);
        }
        fragment.builder = constructorBuilder;
        builders.add(new _AddBuilder(fragment.name, constructorBuilder,
            fragment.fileUri, fragment.fileOffset));

        // TODO(johnniwinther): There is no way to pass the tear off reference
        //  here.
        if (constructorReference != null) {
          loader.buildersCreatedWithReferences[constructorReference] =
              constructorBuilder;
        }
      case FactoryFragment():
        String name = fragment.name;
        NominalParameterCopy? nominalParameterCopy =
            BuilderFactoryImpl.copyTypeParameters(
                unboundNominalParameters, declarationBuilder!.typeParameters,
                kind: TypeParameterKind.function,
                instanceTypeParameterAccess:
                    InstanceTypeParameterAccessState.Allowed);
        List<NominalParameterBuilder>? typeParameters =
            nominalParameterCopy?.newParameterBuilders;
        TypeBuilder returnType;
        switch (declarationBuilder) {
          case ExtensionBuilder():
            // Make the synthesized return type invalid for extensions.
            returnType = new NamedTypeBuilderImpl.forInvalidType(
                fragment.constructorName.fullName,
                const NullabilityBuilder.omitted(),
                messageExtensionDeclaresConstructor.withLocation(
                    fragment.fileUri,
                    fragment.constructorName.fullNameOffset,
                    fragment.constructorName.fullNameLength));
          case ClassBuilder():
          case ExtensionTypeDeclarationBuilder():
            returnType = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                declarationBuilder, const NullabilityBuilder.omitted(),
                arguments: nominalParameterCopy?.newTypeArguments,
                fileUri: fragment.fileUri,
                charOffset: fragment.constructorName.fullNameOffset,
                instanceTypeParameterAccess:
                    InstanceTypeParameterAccessState.Allowed);
        }

        fragment.typeParameterNameSpace.addTypeParameters(
            problemReporting, typeParameters,
            ownerName: fragment.name, allowNameConflict: true);

        NameScheme nameScheme = new NameScheme(
            containerName: containerName,
            containerType: containerType,
            isInstanceMember: false,
            libraryName: indexedLibrary != null
                ? new LibraryName(indexedLibrary.library.reference)
                : enclosingLibraryBuilder.libraryName);

        Reference? procedureReference;
        Reference? tearOffReference;
        if (indexedContainer != null) {
          procedureReference = indexedContainer!.lookupConstructorReference(
              nameScheme.getConstructorMemberName(name, isTearOff: false).name);
          tearOffReference = indexedContainer!.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: true).name);
        }
        // Coverage-ignore(suite): Not run.
        else if (indexedLibrary != null) {
          procedureReference = indexedLibrary.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: false).name);
          tearOffReference = indexedLibrary.lookupGetterReference(
              nameScheme.getConstructorMemberName(name, isTearOff: true).name);
        }

        SourceFactoryBuilder factoryBuilder;
        if (fragment.redirectionTarget != null) {
          factoryBuilder = new RedirectingFactoryBuilder(
              metadata: fragment.metadata,
              modifiers: fragment.modifiers,
              returnType: returnType,
              name: name,
              typeParameters: typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              nameOffset: fragment.fullNameOffset,
              formalsOffset: fragment.formalsOffset,
              endOffset: fragment.endOffset,
              procedureReference: procedureReference,
              tearOffReference: tearOffReference,
              nameScheme: nameScheme,
              nativeMethodName: fragment.nativeMethodName,
              redirectionTarget: fragment.redirectionTarget!);
          (enclosingLibraryBuilder.redirectingFactoryBuilders ??= [])
              .add(factoryBuilder as RedirectingFactoryBuilder);
        } else {
          factoryBuilder = new SourceFactoryBuilder(
              metadata: fragment.metadata,
              modifiers: fragment.modifiers,
              returnType: returnType,
              name: name,
              typeParameters: typeParameters,
              formals: fragment.formals,
              libraryBuilder: enclosingLibraryBuilder,
              declarationBuilder: declarationBuilder,
              fileUri: fragment.fileUri,
              startOffset: fragment.startOffset,
              nameOffset: fragment.fullNameOffset,
              formalsOffset: fragment.formalsOffset,
              endOffset: fragment.endOffset,
              procedureReference: procedureReference,
              tearOffReference: tearOffReference,
              asyncModifier: fragment.asyncModifier,
              nameScheme: nameScheme,
              nativeMethodName: fragment.nativeMethodName);
        }
        fragment.builder = factoryBuilder;
        builders.add(new _AddBuilder(fragment.name, factoryBuilder,
            fragment.fileUri, fragment.fullNameOffset));
        // TODO(johnniwinther): There is no way to pass the tear off reference
        //  here.
        if (procedureReference != null) {
          loader.buildersCreatedWithReferences[procedureReference] =
              factoryBuilder;
        }
    }
  }

  for (_PreBuilder preBuilder in nonConstructorPreBuilders) {
    preBuilder.createBuilders(createBuilder);
  }
  for (_PreBuilder preBuilder in constructorPreBuilders) {
    preBuilder.createBuilders(createBuilder);
  }
  for (Fragment fragment in unnamedFragments) {
    createBuilder(fragment);
  }
}

class LibraryNameSpaceBuilder {
  final Map<String, List<Builder>> augmentations = {};

  final Map<String, List<Builder>> setterAugmentations = {};

  List<Fragment> _fragments = [];

  void addFragment(Fragment fragment) {
    _fragments.add(fragment);
  }

  void includeBuilders(LibraryNameSpaceBuilder other) {
    _fragments.addAll(other._fragments);
  }

  NameSpace toNameSpace({
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required IndexedLibrary? indexedLibrary,
    required ProblemReporting problemReporting,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
  }) {
    Map<String, Builder> getables = {};

    Map<String, MemberBuilder> setables = {};

    Set<ExtensionBuilder> extensions = {};

    NameSpace nameSpace = new NameSpaceImpl(
        getables: getables, setables: setables, extensions: extensions);

    void _addBuilder(
        String name, Builder declaration, Uri fileUri, int charOffset) {
      if (declaration is SourceExtensionBuilder &&
          declaration.isUnnamedExtension) {
        extensions.add(declaration);
        return;
      }

      if (declaration is MemberBuilder ||
          declaration is TypeDeclarationBuilder) {
        // Expected.
      } else {
        // Coverage-ignore-block(suite): Not run.
        // Prefix builders are added when computing the import scope.
        assert(declaration is! PrefixBuilder,
            "Unexpected prefix builder $declaration.");
        unhandled(
            "${declaration.runtimeType}", "addBuilder", charOffset, fileUri);
      }

      assert(
          !(declaration is FunctionBuilder &&
              (declaration.isConstructor || declaration.isFactory)),
          "Unexpected constructor in library: $declaration.");

      Map<String, Builder> members = declaration.isSetter ? setables : getables;

      Builder? existing = members[name];

      if (existing == declaration) return;

      if (declaration.next != null &&
          // Coverage-ignore(suite): Not run.
          declaration.next != existing) {
        unexpected(
            "${declaration.next!.fileUri}@${declaration.next!.fileOffset}",
            "${existing?.fileUri}@${existing?.fileOffset}",
            declaration.fileOffset,
            declaration.fileUri);
      }
      declaration.next = existing;
      if (isDuplicatedDeclaration(existing, declaration)) {
        // Error reporting in [_computeBuildersFromFragments].
        // TODO(johnniwinther): Avoid the use of [isDuplicatedDeclaration].
      } else if (declaration.isExtension) {
        // We add the extension declaration to the extension scope only if its
        // name is unique. Only the first of duplicate extensions is accessible
        // by name or by resolution and the remaining are dropped for the
        // output.
        extensions.add(declaration as SourceExtensionBuilder);
      } else if (declaration.isAugment) {
        if (existing != null) {
          if (declaration.isSetter) {
            (setterAugmentations[name] ??= []).add(declaration);
          } else {
            (augmentations[name] ??= []).add(declaration);
          }
        } else {
          // TODO(cstefantsova): Report an error.
        }
      }
      members[name] = declaration;
    }

    Map<String, List<Fragment>> fragmentsByName = {};
    for (Fragment fragment in _fragments) {
      (fragmentsByName[fragment.name] ??= []).add(fragment);
    }

    for (MapEntry<String, List<Fragment>> entry in fragmentsByName.entries) {
      List<_AddBuilder> addBuilders = [];
      _computeBuildersFromFragments(entry.key, entry.value,
          loader: enclosingLibraryBuilder.loader,
          problemReporting: problemReporting,
          enclosingLibraryBuilder: enclosingLibraryBuilder,
          unboundNominalParameters: unboundNominalParameters,
          mixinApplications: mixinApplications,
          builders: addBuilders,
          indexedLibrary: indexedLibrary,
          containerType: ContainerType.Library);
      for (_AddBuilder addBuilder in addBuilders) {
        _addBuilder(addBuilder.name, addBuilder.declaration, addBuilder.fileUri,
            addBuilder.charOffset);
      }
    }
    return nameSpace;
  }
}

class NominalParameterScope extends AbstractTypeParameterScope {
  final NominalParameterNameSpace _nameSpace;

  NominalParameterScope(super._parent, this._nameSpace);

  @override
  Builder? getTypeParameter(String name) => _nameSpace.getTypeParameter(name);
}

class NominalParameterNameSpace {
  Map<String, NominalParameterBuilder> _typeParametersByName = {};

  NominalParameterBuilder? getTypeParameter(String name) =>
      _typeParametersByName[name];

  void addTypeParameters(ProblemReporting _problemReporting,
      List<NominalParameterBuilder>? typeParameters,
      {required String? ownerName, required bool allowNameConflict}) {
    if (typeParameters == null || typeParameters.isEmpty) return;
    for (NominalParameterBuilder tv in typeParameters) {
      NominalParameterBuilder? existing = _typeParametersByName[tv.name];
      if (tv.isWildcard) continue;
      if (existing != null) {
        if (existing.kind == TypeParameterKind.extensionSynthesized) {
          // The type parameter from the extension is shadowed by the type
          // parameter from the member. Rename the shadowed type parameter.
          existing.parameter.name = '#${existing.name}';
          _typeParametersByName[tv.name] = tv;
        } else {
          _problemReporting.addProblem(messageTypeParameterDuplicatedName,
              tv.fileOffset, tv.name.length, tv.fileUri,
              context: [
                templateTypeParameterDuplicatedNameCause
                    .withArguments(tv.name)
                    .withLocation(existing.fileUri!, existing.fileOffset,
                        existing.name.length)
              ]);
        }
      } else {
        _typeParametersByName[tv.name] = tv;
        // Only classes and extension types and type parameters can't have the
        // same name. See
        // [#29555](https://github.com/dart-lang/sdk/issues/29555) and
        // [#54602](https://github.com/dart-lang/sdk/issues/54602).
        if (tv.name == ownerName && !allowNameConflict) {
          _problemReporting.addProblem(messageTypeParameterSameNameAsEnclosing,
              tv.fileOffset, tv.name.length, tv.fileUri);
        }
      }
    }
  }
}

enum DeclarationFragmentKind {
  classDeclaration,
  mixinDeclaration,
  enumDeclaration,
  extensionDeclaration,
  extensionTypeDeclaration,
}

abstract class DeclarationFragment {
  final Uri fileUri;
  final LookupScope typeParameterScope;
  final DeclarationBuilderScope bodyScope = new DeclarationBuilderScope();
  final List<Fragment> _fragments = [];

  List<FieldFragment>? primaryConstructorFields;

  final List<NominalParameterBuilder>? typeParameters;

  final NominalParameterNameSpace _nominalParameterNameSpace;

  DeclarationFragment(this.fileUri, this.typeParameters,
      this.typeParameterScope, this._nominalParameterNameSpace);

  String get name;

  int get fileOffset;

  DeclarationFragmentKind get kind;

  bool declaresConstConstructor = false;

  DeclarationBuilder get builder;

  void addPrimaryConstructorField(FieldFragment builder) {
    (primaryConstructorFields ??= []).add(builder);
  }

  void addFragment(Fragment fragment) {
    _fragments.add(fragment);
  }

  DeclarationNameSpaceBuilder toDeclarationNameSpaceBuilder() {
    return new DeclarationNameSpaceBuilder._(
        name, _nominalParameterNameSpace, _fragments);
  }
}

class _AddBuilder {
  final String name;
  final Builder declaration;
  final Uri fileUri;
  final int charOffset;

  _AddBuilder(this.name, this.declaration, this.fileUri, this.charOffset);
}

class DeclarationNameSpaceBuilder {
  final String _name;
  final NominalParameterNameSpace? _nominalParameterNameSpace;
  final List<Fragment> _fragments;

  DeclarationNameSpaceBuilder.empty()
      : _name = '',
        _nominalParameterNameSpace = null,
        _fragments = const [];

  DeclarationNameSpaceBuilder._(
      this._name, this._nominalParameterNameSpace, this._fragments);

  void _addBuilder(
      ProblemReporting problemReporting,
      Map<String, Builder> getables,
      Map<String, MemberBuilder> setables,
      Map<String, MemberBuilder> constructors,
      _AddBuilder addBuilder) {
    String name = addBuilder.name;
    Builder declaration = addBuilder.declaration;
    Uri fileUri = addBuilder.fileUri;
    int charOffset = addBuilder.charOffset;

    bool isConstructor = declaration is FunctionBuilder &&
        (declaration.isConstructor || declaration.isFactory);
    if (!isConstructor && name == _name) {
      problemReporting.addProblem(
          messageMemberWithSameNameAsClass, charOffset, noLength, fileUri);
    }
    Map<String, Builder> members = isConstructor
        ? constructors
        : (declaration.isSetter ? setables : getables);

    Builder? existing = members[name];

    if (existing == declaration) return;

    if (declaration.next != null &&
        // Coverage-ignore(suite): Not run.
        declaration.next != existing) {
      unexpected(
          "${declaration.next!.fileUri}@${declaration.next!.fileOffset}",
          "${existing?.fileUri}@${existing?.fileOffset}",
          declaration.fileOffset,
          declaration.fileUri);
    }
    declaration.next = existing;
    if (isDuplicatedDeclaration(existing, declaration)) {
      // Error reporting in [_computeBuildersFromFragments].
      // TODO(johnniwinther): Avoid the use of [isDuplicatedDeclaration].
    } else if (declaration.isAugment) {
      // Coverage-ignore-block(suite): Not run.
      if (existing != null) {
        if (declaration.isSetter) {
          // TODO(johnniwinther): Collection augment setables.
        } else {
          // TODO(johnniwinther): Collection augment getables.
        }
      } else {
        // TODO(cstefantsova): Report an error.
      }
    }
    members[name] = declaration;
  }

  void checkTypeParameterConflict(ProblemReporting _problemReporting,
      String name, Builder member, Uri fileUri) {
    if (_nominalParameterNameSpace != null) {
      NominalParameterBuilder? tv =
          _nominalParameterNameSpace.getTypeParameter(name);
      if (tv != null) {
        _problemReporting.addProblem(
            templateConflictsWithTypeParameter.withArguments(name),
            member.fileOffset,
            name.length,
            fileUri,
            context: [
              messageConflictsWithTypeParameterCause.withLocation(
                  tv.fileUri!, tv.fileOffset, name.length)
            ]);
      }
    }
  }

  DeclarationNameSpace buildNameSpace(
      {required SourceLoader loader,
      required ProblemReporting problemReporting,
      required SourceLibraryBuilder enclosingLibraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required IndexedLibrary? indexedLibrary,
      required IndexedContainer? indexedContainer,
      required ContainerType containerType,
      required ContainerName containerName,
      bool includeConstructors = true}) {
    List<NominalParameterBuilder> unboundNominalParameters = [];
    Map<String, Builder> getables = {};
    Map<String, MemberBuilder> setables = {};
    Map<String, MemberBuilder> constructors = {};

    Map<String, List<Fragment>> fragmentsByName = {};
    for (Fragment fragment in _fragments) {
      (fragmentsByName[fragment.name] ??= []).add(fragment);
    }

    for (MapEntry<String, List<Fragment>> entry in fragmentsByName.entries) {
      List<_AddBuilder> addBuilders = [];
      _computeBuildersFromFragments(entry.key, entry.value,
          loader: loader,
          problemReporting: problemReporting,
          enclosingLibraryBuilder: enclosingLibraryBuilder,
          declarationBuilder: declarationBuilder,
          builders: addBuilders,
          unboundNominalParameters: unboundNominalParameters,
          // TODO(johnniwinther): Avoid passing this:
          mixinApplications: const {},
          indexedLibrary: indexedLibrary,
          indexedContainer: indexedContainer,
          containerType: containerType,
          containerName: containerName);
      for (_AddBuilder addBuilder in addBuilders) {
        _addBuilder(
            problemReporting, getables, setables, constructors, addBuilder);
      }
    }

    void checkConflicts(String name, Builder member) {
      checkTypeParameterConflict(
          problemReporting, name, member, member.fileUri!);
    }

    getables.forEach(checkConflicts);
    setables.forEach(checkConflicts);
    constructors.forEach(checkConflicts);

    enclosingLibraryBuilder
        .registerUnboundNominalParameters(unboundNominalParameters);

    return new DeclarationNameSpaceImpl(
        getables: getables,
        setables: setables,
        // TODO(johnniwinther): Handle constructors in extensions consistently.
        // Currently they are not part of the name space but still processed
        // for instance when inferring redirecting factories.
        // They are part of the name space for extension types though.
        // Note that we have to remove [RedirectingFactoryBuilder]s in
        // [SourceLoader.inferRedirectingFactories] as we don't build them
        // because we don't add them here.
        constructors: includeConstructors ? constructors : null);
  }
}

enum TypeScopeKind {
  library,
  declarationTypeParameters,
  classDeclaration,
  mixinDeclaration,
  enumDeclaration,
  extensionDeclaration,
  extensionTypeDeclaration,
  memberTypeParameters,
  functionTypeParameters,
  unnamedMixinApplication,
}

class TypeScope {
  final TypeScopeKind kind;

  List<NamedTypeBuilder> _unresolvedNamedTypes = [];

  List<TypeScope> _childScopes = [];

  final LookupScope lookupScope;

  TypeScope(this.kind, this.lookupScope, [TypeScope? parent]) {
    parent?._childScopes.add(this);
  }

  void registerUnresolvedNamedType(NamedTypeBuilder namedTypeBuilder) {
    _unresolvedNamedTypes.add(namedTypeBuilder);
  }

  int resolveTypes(ProblemReporting problemReporting) {
    int typeCount = _unresolvedNamedTypes.length;
    if (_unresolvedNamedTypes.isNotEmpty) {
      for (NamedTypeBuilder namedTypeBuilder in _unresolvedNamedTypes) {
        namedTypeBuilder.resolveIn(lookupScope, namedTypeBuilder.charOffset!,
            namedTypeBuilder.fileUri!, problemReporting);
      }
      _unresolvedNamedTypes.clear();
    }
    for (TypeScope childScope in _childScopes) {
      typeCount += childScope.resolveTypes(problemReporting);
    }
    return typeCount;
  }

  // Coverage-ignore(suite): Not run.
  bool get isEmpty => _unresolvedNamedTypes.isEmpty && _childScopes.isEmpty;

  @override
  String toString() => 'TypeScope($kind,$_unresolvedNamedTypes)';
}

class DeclarationBuilderScope implements LookupScope {
  DeclarationBuilder? _declarationBuilder;

  DeclarationBuilderScope();

  @override
  // Coverage-ignore(suite): Not run.
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _declarationBuilder?.scope.forEachExtension(f);
  }

  void set declarationBuilder(DeclarationBuilder value) {
    assert(_declarationBuilder == null,
        "declarationBuilder has already been set.");
    _declarationBuilder = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  ScopeKind get kind =>
      _declarationBuilder?.scope.kind ?? ScopeKind.declaration;

  @override
  Builder? lookupGetable(String name, int charOffset, Uri fileUri) {
    return _declarationBuilder?.scope.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    return _declarationBuilder?.scope.lookupSetable(name, charOffset, fileUri);
  }
}

bool isDuplicatedDeclaration(Builder? existing, Builder other) {
  if (existing == null) return false;
  if (other.isAugment) return false;
  Builder? next = existing.next;
  if (next == null) {
    if (existing.isGetter && other.isSetter) return false;
    if (existing.isSetter && other.isGetter) return false;
  } else {
    if (next is ClassBuilder && !next.isMixinApplication) return true;
  }
  if (existing is ClassBuilder && other is ClassBuilder) {
    // We allow multiple mixin applications with the same name. An
    // alternative is to share these mixin applications. This situation can
    // happen if you have `class A extends Object with Mixin {}` and `class B
    // extends Object with Mixin {}` in the same library.
    return !existing.isMixinApplication ||
        // Coverage-ignore(suite): Not run.
        !other.isMixinApplication;
  }
  return true;
}

/// Creates synthesized type parameters and formals for extension and extension
/// type instance members.
(
  List<NominalParameterBuilder>? typeParameters,
  List<FormalParameterBuilder>? formals
) _createTypeParametersAndFormals(
    DeclarationBuilder? declarationBuilder,
    List<NominalParameterBuilder>? typeParameters,
    List<FormalParameterBuilder>? formals,
    List<NominalParameterBuilder> _unboundNominalVariables,
    {required bool isInstanceMember,
    required Uri fileUri,
    required int nameOffset}) {
  if (isInstanceMember) {
    switch (declarationBuilder) {
      case ExtensionBuilder():
        NominalParameterCopy? nominalVariableCopy =
            BuilderFactoryImpl.copyTypeParameters(
                _unboundNominalVariables, declarationBuilder.typeParameters,
                kind: TypeParameterKind.extensionSynthesized,
                instanceTypeParameterAccess:
                    InstanceTypeParameterAccessState.Allowed);

        if (nominalVariableCopy != null) {
          if (typeParameters != null) {
            typeParameters = nominalVariableCopy.newParameterBuilders
              ..addAll(typeParameters);
          } else {
            typeParameters = nominalVariableCopy.newParameterBuilders;
          }
        }

        TypeBuilder thisType = declarationBuilder.onType;
        if (nominalVariableCopy != null) {
          thisType = new SynthesizedTypeBuilder(
              thisType,
              nominalVariableCopy.newToOldParameterMap,
              nominalVariableCopy.substitutionMap);
        }
        List<FormalParameterBuilder> synthesizedFormals = [
          new FormalParameterBuilder(FormalParameterKind.requiredPositional,
              Modifiers.Final, thisType, syntheticThisName, nameOffset,
              fileUri: fileUri,
              isExtensionThis: true,
              hasImmediatelyDeclaredInitializer: false)
        ];
        if (formals != null) {
          synthesizedFormals.addAll(formals);
        }
        formals = synthesizedFormals;
      case ExtensionTypeDeclarationBuilder():
        NominalParameterCopy? nominalVariableCopy =
            BuilderFactoryImpl.copyTypeParameters(
                _unboundNominalVariables, declarationBuilder.typeParameters,
                kind: TypeParameterKind.extensionSynthesized,
                instanceTypeParameterAccess:
                    InstanceTypeParameterAccessState.Allowed);

        if (nominalVariableCopy != null) {
          if (typeParameters != null) {
            typeParameters = nominalVariableCopy.newParameterBuilders
              ..addAll(typeParameters);
          } else {
            typeParameters = nominalVariableCopy.newParameterBuilders;
          }
        }

        TypeBuilder thisType =
            new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                declarationBuilder, const NullabilityBuilder.omitted(),
                arguments: declarationBuilder.typeParameters != null
                    ? new List<TypeBuilder>.generate(
                        declarationBuilder.typeParameters!.length,
                        (int index) =>
                            new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                                typeParameters![index],
                                const NullabilityBuilder.omitted(),
                                instanceTypeParameterAccess:
                                    InstanceTypeParameterAccessState.Allowed))
                    : null,
                instanceTypeParameterAccess:
                    InstanceTypeParameterAccessState.Allowed);

        if (nominalVariableCopy != null) {
          thisType = new SynthesizedTypeBuilder(
              thisType,
              nominalVariableCopy.newToOldParameterMap,
              nominalVariableCopy.substitutionMap);
        }
        List<FormalParameterBuilder> synthesizedFormals = [
          new FormalParameterBuilder(FormalParameterKind.requiredPositional,
              Modifiers.Final, thisType, syntheticThisName, nameOffset,
              fileUri: fileUri,
              isExtensionThis: true,
              hasImmediatelyDeclaredInitializer: false)
        ];
        if (formals != null) {
          synthesizedFormals.addAll(formals);
        }
        formals = synthesizedFormals;
      case ClassFragment():
      case MixinFragment():
      case EnumFragment():
      case ClassBuilder():
      case null:
    }
  }
  return (typeParameters, formals);
}
