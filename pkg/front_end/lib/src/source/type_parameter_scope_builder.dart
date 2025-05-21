// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;

import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/constructor/declaration.dart';
import '../fragment/factory/declaration.dart';
import '../fragment/field/declaration.dart';
import '../fragment/fragment.dart';
import '../fragment/getter/declaration.dart';
import '../fragment/method/declaration.dart';
import '../fragment/method/encoding.dart';
import '../fragment/setter/declaration.dart';
import 'builder_factory.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_constructor_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart';
import 'source_member_builder.dart';
import 'source_method_builder.dart';
import 'source_property_builder.dart';
import 'source_type_alias_builder.dart';
import 'source_type_parameter_builder.dart';

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
  final bool inPatch;
  final bool inLibrary;
  final bool isStatic;
  final _PropertyKind? propertyKind;

  _FragmentName(this.kind, this.fragment,
      {required this.fileUri,
      required this.name,
      required this.nameOffset,
      required this.nameLength,
      required this.isAugment,
      required this.inPatch,
      required this.inLibrary,
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
      void Function(Fragment,
              {bool conflictingSetter, List<Fragment>? augmentations})
          createBuilder);
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
      void Function(Fragment,
              {bool conflictingSetter, List<Fragment>? augmentations})
          createBuilder) {
    List<Fragment>? getterAugmentations;
    List<Fragment>? setterAugmentations;
    for (_FragmentName fragmentName in augmentations) {
      if (fragmentName.fragment is GetterFragment) {
        (getterAugmentations ??= []).add(fragmentName.fragment);
      } else if (fragmentName.fragment is SetterFragment) {
        (setterAugmentations ??= []).add(fragmentName.fragment);
      } else {
        throw new UnsupportedError("Unexpected augmentation $fragmentName");
      }
    }
    augmentations.clear();
    if (getter != null) {
      createBuilder(getter!.fragment, augmentations: getterAugmentations);
    }
    if (setter != null && setter!.propertyKind == _PropertyKind.Setter) {
      createBuilder(setter!.fragment, augmentations: setterAugmentations);
    }
    for (_FragmentName fragmentName in conflictingSetters) {
      createBuilder(fragmentName.fragment, conflictingSetter: true);
    }
    for (_FragmentName fragmentName in augmentations) {
      // Coverage-ignore-block(suite): Not run.
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
      void Function(Fragment,
              {bool conflictingSetter, List<Fragment>? augmentations})
          createBuilder) {
    createBuilder(fragment.fragment,
        augmentations: augmentations.map((f) => f.fragment).toList());
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
      void Function(Fragment,
              {bool conflictingSetter, List<Fragment>? augmentations})
          createBuilder) {
    createBuilder(fragment.fragment,
        augmentations: augmentations.map((f) => f.fragment).toList());
  }
}

/// Reports an error if [fragmentName] is augmenting.
///
/// This is called when the first [_PreBuilder] is created, meaning that the
/// augmentation didn't correspond to an introductory declaration.
void _checkAugmentation(
    ProblemReporting problemReporting, _FragmentName fragmentName) {
  if (fragmentName.isAugment) {
    Message message;
    switch (fragmentName.fragment) {
      case ClassFragment():
        message = fragmentName.inPatch
            ? templateUnmatchedPatchClass.withArguments(fragmentName.name)
            :
            // Coverage-ignore(suite): Not run.
            templateUnmatchedAugmentationClass.withArguments(fragmentName.name);
      case ConstructorFragment():
      case FactoryFragment():
      case FieldFragment():
      case GetterFragment():
      case MethodFragment():
      case PrimaryConstructorFragment():
      case SetterFragment():
      case PrimaryConstructorFieldFragment():
        if (fragmentName.inLibrary) {
          message = fragmentName.inPatch
              ? templateUnmatchedPatchLibraryMember
                  .withArguments(fragmentName.name)
              :
              // Coverage-ignore(suite): Not run.
              templateUnmatchedAugmentationLibraryMember
                  .withArguments(fragmentName.name);
        } else {
          message = fragmentName.inPatch
              ? templateUnmatchedPatchClassMember
                  .withArguments(fragmentName.name)
              :
              // Coverage-ignore(suite): Not run.
              templateUnmatchedAugmentationClassMember
                  .withArguments(fragmentName.name);
        }
      case EnumFragment():
      case EnumElementFragment():
      case ExtensionFragment():
      // Coverage-ignore(suite): Not run.
      case ExtensionTypeFragment():
      // Coverage-ignore(suite): Not run.
      case MixinFragment():
      // Coverage-ignore(suite): Not run.
      case NamedMixinApplicationFragment():
      // Coverage-ignore(suite): Not run.
      case TypedefFragment():
        // TODO(johnniwinther): Specialize more messages.
        message = fragmentName.inPatch
            ? templateUnmatchedPatchDeclaration.withArguments(fragmentName.name)
            :
            // Coverage-ignore(suite): Not run.
            templateUnmatchedAugmentationDeclaration
                .withArguments(fragmentName.name);
    }
    problemReporting.addProblem(message, fragmentName.nameOffset,
        fragmentName.nameLength, fragmentName.fileUri);
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
    case PrimaryConstructorFieldFragment():
      return new _PropertyPreBuilder.forField(fragmentName);
    case GetterFragment():
      return new _PropertyPreBuilder.forGetter(fragmentName);
    case SetterFragment():
      return new _PropertyPreBuilder.forSetter(fragmentName);
    case EnumElementFragment():
      return new _PropertyPreBuilder.forField(fragmentName);
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
    _checkAugmentation(problemReporting, fragmentName);
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
        addFragment(new _FragmentName(
          _FragmentKind.Class,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        ));
      case EnumFragment():
        addFragment(new _FragmentName(
          _FragmentKind.Enum, fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          // TODO(johnniwinther): Support enum augmentations.
          isAugment: false,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        ));
      case ExtensionTypeFragment():
        addFragment(new _FragmentName(
          _FragmentKind.ExtensionType,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        ));
      case MethodFragment():
        addFragment(new _FragmentName(
          _FragmentKind.Method,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: fragment.modifiers.isAugment,
          isStatic: declarationBuilder == null || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: declarationBuilder == null,
        ));
      case MixinFragment():
        addFragment(new _FragmentName(
          _FragmentKind.Mixin,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        ));
      case NamedMixinApplicationFragment():
        addFragment(new _FragmentName(
          _FragmentKind.NamedMixinApplication,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        ));
      case TypedefFragment():
        addFragment(new _FragmentName(
          _FragmentKind.Typedef, fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          // TODO(johnniwinther): Support typedef augmentations.
          isAugment: false,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        ));
      case ExtensionFragment():
        if (!fragment.isUnnamed) {
          addFragment(new _FragmentName(
            _FragmentKind.Extension,
            fragment,
            fileUri: fragment.fileUri,
            name: fragment.name,
            nameOffset: fragment.fileOffset,
            nameLength: fragment.name.length,
            isAugment: fragment.modifiers.isAugment,
            inPatch: fragment.enclosingCompilationUnit.isPatch,
            inLibrary: true,
          ));
        } else {
          unnamedFragments.add(fragment);
        }
      case FactoryFragment():
        addFragment(new _FragmentName(
          _FragmentKind.Factory,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.constructorName.fullName,
          nameOffset: fragment.constructorName.fullNameOffset,
          nameLength: fragment.constructorName.fullNameLength,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: declarationBuilder == null,
        ));
      case ConstructorFragment():
        addFragment(new _FragmentName(
          _FragmentKind.Constructor,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.constructorName.fullName,
          nameOffset: fragment.constructorName.fullNameOffset,
          nameLength: fragment.constructorName.fullNameLength,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: declarationBuilder == null,
        ));
      case PrimaryConstructorFragment():
        addFragment(new _FragmentName(
          _FragmentKind.Constructor,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.constructorName.fullName,
          nameOffset: fragment.constructorName.fullNameOffset,
          nameLength: fragment.constructorName.fullNameLength,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: declarationBuilder == null,
        ));
      case FieldFragment():
        _FragmentName fragmentName = new _FragmentName(
          _FragmentKind.Property,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: fragment.hasSetter
              ? _PropertyKind.Field
              : _PropertyKind.FinalField,
          isStatic: declarationBuilder == null || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: declarationBuilder == null,
        );
        addFragment(fragmentName);
      case PrimaryConstructorFieldFragment():
        _FragmentName fragmentName = new _FragmentName(
          _FragmentKind.Property,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: false,
          propertyKind: _PropertyKind.FinalField,
          isStatic: false,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: false,
        );
        addFragment(fragmentName);
      case GetterFragment():
        _FragmentName fragmentName = new _FragmentName(
          _FragmentKind.Property,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: _PropertyKind.Getter,
          isStatic: declarationBuilder == null || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: declarationBuilder == null,
        );
        addFragment(fragmentName);
      case SetterFragment():
        _FragmentName fragmentName = new _FragmentName(
          _FragmentKind.Property,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: _PropertyKind.Setter,
          isStatic: declarationBuilder == null || fragment.modifiers.isStatic,
          inPatch: fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: declarationBuilder == null,
        );
        addFragment(fragmentName);
      case EnumElementFragment():
        _FragmentName fragmentName = new _FragmentName(
          _FragmentKind.Property,
          fragment,
          fileUri: fragment.fileUri,
          name: fragment.name,
          nameOffset: fragment.nameOffset,
          nameLength: fragment.name.length,
          isAugment: false,
          propertyKind: _PropertyKind.FinalField,
          isStatic: true,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: declarationBuilder == null,
        );
        addFragment(fragmentName);
    }
  }

  void createBuilder(Fragment fragment,
      {bool conflictingSetter = false, List<Fragment>? augmentations}) {
    switch (fragment) {
      case TypedefFragment():
        builders.add(_createTypedefBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary));
      case ClassFragment():
        builders.add(_createClassBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary));
      case MixinFragment():
        builders.add(_createMixinBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary));
      case NamedMixinApplicationFragment():
        builders.add(_createNamedMixinApplicationBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            mixinApplications: mixinApplications,
            indexedLibrary: indexedLibrary));
      case EnumFragment():
        builders.add(_createEnumBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary));
      case ExtensionFragment():
        builders.add(_createExtensionBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary));
      case ExtensionTypeFragment():
        builders.add(_createExtensionTypeBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary));
      case FieldFragment():
        builders.add(_createFieldBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName));
      case PrimaryConstructorFieldFragment():
        builders.add(_createPrimaryConstructorFieldBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder!,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName));
      case GetterFragment():
        builders.add(_createGetterBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName));
      case SetterFragment():
        builders.add(_createSetterBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName,
            conflictingSetter: conflictingSetter));
      case MethodFragment():
        builders.add(_createMethodBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName));
      case ConstructorFragment():
        builders.add(_createConstructorBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName));
      case PrimaryConstructorFragment():
        builders.add(_createPrimaryConstructorBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName));
      case FactoryFragment():
        builders.add(_createFactoryBuilder(fragment, augmentations,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName));
      case EnumElementFragment():
        builders.add(_createEnumElementBuilder(fragment,
            problemReporting: problemReporting,
            loader: loader,
            enclosingLibraryBuilder: enclosingLibraryBuilder,
            declarationBuilder: declarationBuilder,
            unboundNominalParameters: unboundNominalParameters,
            indexedLibrary: indexedLibrary,
            containerType: containerType,
            indexedContainer: indexedContainer,
            containerName: containerName));
    }
    if (augmentations != null) {
      for (Fragment augmentation in augmentations) {
        // Coverage-ignore-block(suite): Not run.
        createBuilder(augmentation);
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
  List<Fragment> _fragments = [];

  void addFragment(Fragment fragment) {
    _fragments.add(fragment);
  }

  void includeBuilders(LibraryNameSpaceBuilder other) {
    _fragments.addAll(other._fragments);
  }

  bool _allowInjectedPublicMember(
      SourceLibraryBuilder enclosingLibraryBuilder, Builder newBuilder) {
    return enclosingLibraryBuilder.importUri.isScheme("dart") &&
        enclosingLibraryBuilder.importUri.path.startsWith("_");
  }

  MutableNameSpace toNameSpace({
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required IndexedLibrary? indexedLibrary,
    required ProblemReporting problemReporting,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
    required List<NamedBuilder> memberBuilders,
  }) {
    Map<String, LookupResult> content = {};
    Map<String, NamedBuilder> getables = {};

    Map<String, NamedBuilder> setables = {};

    Set<ExtensionBuilder> extensions = {};

    void _addBuilder(_AddBuilder addBuilder) {
      String name = addBuilder.name;
      NamedBuilder declaration = addBuilder.declaration;
      Uri fileUri = addBuilder.fileUri;
      int charOffset = addBuilder.charOffset;

      memberBuilders.add(declaration);

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
              // Coverage-ignore(suite): Not run.
              (declaration is ConstructorBuilder ||
                  declaration is FactoryBuilder)),
          "Unexpected constructor in library: $declaration.");

      bool isSetter = isMappedAsSetter(declaration);

      Map<String, NamedBuilder> members = isSetter ? setables : getables;

      NamedBuilder? existing = members[name];

      if (existing == declaration) return;

      if (addBuilder.inPatch &&
          !name.startsWith('_') &&
          !_allowInjectedPublicMember(enclosingLibraryBuilder, declaration)) {
        problemReporting.addProblem(
            templatePatchInjectionFailed.withArguments(
                name, enclosingLibraryBuilder.importUri),
            charOffset,
            noLength,
            fileUri);
      }

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
      if (declaration is SourceExtensionBuilder && !declaration.isDuplicate) {
        // We add the extension declaration to the extension scope only if its
        // name is unique. Only the first of duplicate extensions is accessible
        // by name or by resolution and the remaining are dropped for the
        // output.
        extensions.add(declaration);
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
        _addBuilder(addBuilder);
      }
    }

    for (MapEntry<String, NamedBuilder> entry in getables.entries) {
      LookupResult.addNamedBuilder(content, entry.key, entry.value,
          setter: false);
    }
    for (MapEntry<String, NamedBuilder> entry in setables.entries) {
      LookupResult.addNamedBuilder(content, entry.key, entry.value,
          setter: true);
    }
    return new SourceLibraryNameSpace(content: content, extensions: extensions);
  }
}

class NominalParameterScope extends AbstractTypeParameterScope {
  final NominalParameterNameSpace _nameSpace;

  NominalParameterScope(super._parent, this._nameSpace);

  @override
  TypeParameterBuilder? getTypeParameter(String name) =>
      _nameSpace.getTypeParameter(name);
}

class NominalParameterNameSpace {
  Map<String, SourceNominalParameterBuilder> _typeParametersByName = {};

  SourceNominalParameterBuilder? getTypeParameter(String name) =>
      _typeParametersByName[name];

  void addTypeParameters(ProblemReporting _problemReporting,
      List<SourceNominalParameterBuilder>? typeParameters,
      {required String? ownerName, required bool allowNameConflict}) {
    if (typeParameters == null || typeParameters.isEmpty) return;
    for (SourceNominalParameterBuilder tv in typeParameters) {
      SourceNominalParameterBuilder? existing = _typeParametersByName[tv.name];
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
                    .withLocation(existing.fileUri, existing.fileOffset,
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

abstract class DeclarationFragmentImpl implements DeclarationFragment {
  final Uri fileUri;

  /// The scope in which the declaration is declared.
  ///
  /// This is the scope of the enclosing compilation unit and it's used for
  /// resolving metadata on the declaration.
  final LookupScope enclosingScope;

  final LookupScope typeParameterScope;
  final DeclarationBuilderScope bodyScope;
  final List<Fragment> _fragments = [];

  @override
  final List<TypeParameterFragment>? typeParameters;

  final NominalParameterNameSpace nominalParameterNameSpace;

  final LibraryFragment enclosingCompilationUnit;

  DeclarationFragmentImpl({
    required this.fileUri,
    required this.typeParameters,
    required this.enclosingScope,
    required this.typeParameterScope,
    required NominalParameterNameSpace nominalParameterNameSpace,
    required this.enclosingCompilationUnit,
  })  : nominalParameterNameSpace = nominalParameterNameSpace,
        bodyScope = new DeclarationBuilderScope(typeParameterScope);

  String get name;

  int get fileOffset;

  DeclarationFragmentKind get kind;

  bool declaresConstConstructor = false;

  DeclarationBuilder get builder;

  void addPrimaryConstructorField(PrimaryConstructorFieldFragment fragment) {
    throw new UnsupportedError(
        "Unexpected primary constructor field in $this.");
  }

  void addEnumElement(EnumElementFragment fragment) {
    throw new UnsupportedError("Unexpected enum element in $this.");
  }

  void addFragment(Fragment fragment) {
    _fragments.add(fragment);
  }

  DeclarationNameSpaceBuilder toDeclarationNameSpaceBuilder() {
    return new DeclarationNameSpaceBuilder._(
        name, nominalParameterNameSpace, _fragments);
  }
}

class _AddBuilder {
  final String name;
  final NamedBuilder declaration;
  final Uri fileUri;
  final int charOffset;
  final bool inPatch;

  _AddBuilder(this.name, this.declaration, this.fileUri, this.charOffset,
      {required this.inPatch});
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

  void includeBuilders(DeclarationNameSpaceBuilder other) {
    _fragments.addAll(other._fragments);
    other._fragments.clear();
  }

  bool _allowInjectedPublicMember(
      SourceLibraryBuilder enclosingLibraryBuilder, Builder newBuilder) {
    if (enclosingLibraryBuilder.importUri.isScheme("dart") &&
        enclosingLibraryBuilder.importUri.path.startsWith("_")) {
      return true;
    }
    if (newBuilder.isStatic) {
      return _name.startsWith('_');
    }
    // TODO(johnniwinther): Restrict the use of injected public class members.
    return true;
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

  MutableDeclarationNameSpace buildNameSpace(
      {required SourceLoader loader,
      required ProblemReporting problemReporting,
      required SourceLibraryBuilder enclosingLibraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required IndexedLibrary? indexedLibrary,
      required IndexedContainer? indexedContainer,
      required ContainerType containerType,
      required ContainerName containerName,
      bool includeConstructors = true,
      required List<SourceMemberBuilder> constructorBuilders,
      required List<SourceMemberBuilder> memberBuilders}) {
    List<NominalParameterBuilder> unboundNominalParameters = [];
    Map<String, LookupResult> content = {};
    Map<String, NamedBuilder> getables = {};
    Map<String, NamedBuilder> setables = {};
    Map<String, MemberBuilder> constructors = {};

    Map<String, List<Fragment>> fragmentsByName = {};
    for (Fragment fragment in _fragments) {
      (fragmentsByName[fragment.name] ??= []).add(fragment);
    }

    void _addBuilder(_AddBuilder addBuilder) {
      String name = addBuilder.name;
      NamedBuilder declaration = addBuilder.declaration;
      Uri fileUri = addBuilder.fileUri;
      int charOffset = addBuilder.charOffset;

      bool isConstructor =
          declaration is ConstructorBuilder || declaration is FactoryBuilder;
      if (!isConstructor && name == _name) {
        problemReporting.addProblem(
            messageMemberWithSameNameAsClass, charOffset, noLength, fileUri);
      }
      if (isConstructor) {
        if (includeConstructors) {
          constructorBuilders.add(declaration as SourceMemberBuilder);
        }
      } else {
        memberBuilders.add(declaration as SourceMemberBuilder);
      }

      bool isSetter = isMappedAsSetter(declaration);

      Map<String, NamedBuilder> members =
          isConstructor ? constructors : (isSetter ? setables : getables);

      NamedBuilder? existing = members[name];

      if (existing == declaration) return;

      if (addBuilder.inPatch &&
          !name.startsWith('_') &&
          !_allowInjectedPublicMember(enclosingLibraryBuilder, declaration)) {
        // TODO(johnniwinther): Test adding a no-name constructor in the patch,
        // either as an injected or duplicated constructor.
        problemReporting.addProblem(
            templatePatchInjectionFailed.withArguments(
                name, enclosingLibraryBuilder.importUri),
            charOffset,
            noLength,
            fileUri);
      }

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
      members[name] = declaration;
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
        _addBuilder(addBuilder);
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

    for (MapEntry<String, NamedBuilder> entry in getables.entries) {
      LookupResult.addNamedBuilder(content, entry.key, entry.value,
          setter: false);
    }
    for (MapEntry<String, NamedBuilder> entry in setables.entries) {
      LookupResult.addNamedBuilder(content, entry.key, entry.value,
          setter: true);
    }

    return new SourceDeclarationNameSpace(
        content: content,
        // TODO(johnniwinther): Handle constructors in extensions consistently.
        // Currently they are not part of the name space but still processed
        // for instance when inferring redirecting factories.
        // They are part of the name space for extension types though.
        // Note that we have to remove [SourceFactoryBuilder]s in
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

List<SourceNominalParameterBuilder>? createNominalParameterBuilders(
    List<TypeParameterFragment>? fragments,
    List<NominalParameterBuilder> unboundNominalParameters) {
  if (fragments == null) return null;
  List<SourceNominalParameterBuilder> list = [];
  for (TypeParameterFragment fragment in fragments) {
    list.add(createNominalParameterBuilder(fragment, unboundNominalParameters));
  }
  return list;
}

SourceNominalParameterBuilder createNominalParameterBuilder(
    TypeParameterFragment fragment,
    List<NominalParameterBuilder> unboundNominalParameters) {
  SourceNominalParameterBuilder builder = new SourceNominalParameterBuilder(
      new RegularNominalParameterDeclaration(fragment),
      bound: fragment.bound,
      variableVariance: fragment.variance);

  unboundNominalParameters.add(builder);
  fragment.builder = builder;
  return builder;
}

_AddBuilder _createTypedefBuilder(TypedefFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  List<SourceNominalParameterBuilder>? nominalParameters =
      createNominalParameterBuilders(
          fragment.typeParameters, unboundNominalParameters);
  if (nominalParameters != null) {
    for (SourceNominalParameterBuilder typeParameter in nominalParameters) {
      typeParameter.varianceCalculationValue = VarianceCalculationValue.pending;
    }
  }
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, nominalParameters,
      ownerName: fragment.name, allowNameConflict: true);

  Reference? reference = indexedLibrary?.lookupTypedef(fragment.name);
  SourceTypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
      name: fragment.name,
      enclosingLibraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      fragment: fragment,
      reference: reference);
  if (reference != null) {
    loader.buildersCreatedWithReferences[reference] = typedefBuilder;
  }
  return new _AddBuilder(
      fragment.name, typedefBuilder, fragment.fileUri, fragment.nameOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createClassBuilder(
    ClassFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  String name = fragment.name;
  DeclarationNameSpaceBuilder nameSpaceBuilder =
      fragment.toDeclarationNameSpaceBuilder();
  ClassDeclaration introductoryDeclaration =
      new RegularClassDeclaration(fragment);
  List<SourceNominalParameterBuilder>? nominalParameters =
      createNominalParameterBuilders(
          fragment.typeParameters, unboundNominalParameters);
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, nominalParameters,
      ownerName: fragment.name, allowNameConflict: false);

  Modifiers modifiers = fragment.modifiers;
  List<ClassDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    int introductoryTypeParameterCount = fragment.typeParameters?.length ?? 0;
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [ClassFragment].
      augmentation as ClassFragment;

      // TODO(johnniwinther): Check that other modifiers are consistent.
      if (augmentation.modifiers.declaresConstConstructor) {
        modifiers |= Modifiers.DeclaresConstConstructor;
      }
      augmentationDeclarations.add(new RegularClassDeclaration(augmentation));
      nameSpaceBuilder
          .includeBuilders(augmentation.toDeclarationNameSpaceBuilder());

      int augmentationTypeParameterCount =
          augmentation.typeParameters?.length ?? 0;
      if (introductoryTypeParameterCount != augmentationTypeParameterCount) {
        problemReporting.addProblem(messagePatchClassTypeParametersMismatch,
            augmentation.nameOffset, name.length, augmentation.fileUri,
            context: [
              messagePatchClassOrigin.withLocation(
                  fragment.fileUri, fragment.nameOffset, name.length)
            ]);

        // Error recovery. Create fresh type parameters for the
        // augmentation.
        augmentation.nominalParameterNameSpace.addTypeParameters(
            problemReporting,
            createNominalParameterBuilders(
                augmentation.typeParameters, unboundNominalParameters),
            ownerName: augmentation.name,
            allowNameConflict: false);
      } else if (augmentation.typeParameters != null) {
        for (int index = 0; index < introductoryTypeParameterCount; index++) {
          SourceNominalParameterBuilder nominalParameterBuilder =
              nominalParameters![index];
          TypeParameterFragment typeParameterFragment =
              augmentation.typeParameters![index];
          nominalParameterBuilder.addAugmentingDeclaration(
              new RegularNominalParameterDeclaration(typeParameterFragment));
          typeParameterFragment.builder = nominalParameterBuilder;
        }
        augmentation.nominalParameterNameSpace.addTypeParameters(
            problemReporting, nominalParameters,
            ownerName: augmentation.name, allowNameConflict: false);
      }
    }
  }
  IndexedClass? indexedClass = indexedLibrary?.lookupIndexedClass(name);
  SourceClassBuilder classBuilder = new SourceClassBuilder(
      modifiers: modifiers,
      name: name,
      typeParameters: fragment.typeParameters?.builders,
      typeParameterScope: fragment.typeParameterScope,
      nameSpaceBuilder: nameSpaceBuilder,
      libraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      nameOffset: fragment.nameOffset,
      indexedClass: indexedClass,
      introductory: introductoryDeclaration,
      augmentations: augmentationDeclarations);
  fragment.builder = classBuilder;
  fragment.bodyScope.declarationBuilder = classBuilder;
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      augmentation as ClassFragment;
      augmentation.builder = classBuilder;
      augmentation.bodyScope.declarationBuilder = classBuilder;
    }
    augmentations.clear();
  }
  if (indexedClass != null) {
    loader.buildersCreatedWithReferences[indexedClass.reference] = classBuilder;
  }
  return new _AddBuilder(
      fragment.name, classBuilder, fragment.fileUri, fragment.fileOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createMixinBuilder(MixinFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  IndexedClass? indexedClass =
      indexedLibrary?.lookupIndexedClass(fragment.name);
  createNominalParameterBuilders(
      fragment.typeParameters, unboundNominalParameters);
  List<SourceNominalParameterBuilder>? typeParameters =
      fragment.typeParameters?.builders;
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, typeParameters,
      ownerName: fragment.name, allowNameConflict: false);
  SourceClassBuilder mixinBuilder = new SourceClassBuilder(
      modifiers: fragment.modifiers,
      name: fragment.name,
      typeParameters: typeParameters,
      typeParameterScope: fragment.typeParameterScope,
      nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
      libraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      nameOffset: fragment.nameOffset,
      indexedClass: indexedClass,
      introductory: new MixinDeclaration(fragment));
  fragment.builder = mixinBuilder;
  fragment.bodyScope.declarationBuilder = mixinBuilder;
  if (indexedClass != null) {
    loader.buildersCreatedWithReferences[indexedClass.reference] = mixinBuilder;
  }
  return new _AddBuilder(
      fragment.name, mixinBuilder, fragment.fileUri, fragment.fileOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createNamedMixinApplicationBuilder(
    NamedMixinApplicationFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
    required IndexedLibrary? indexedLibrary}) {
  List<TypeBuilder> mixins = fragment.mixins.toList();
  TypeBuilder mixin = mixins.removeLast();
  ClassDeclaration classDeclaration =
      new NamedMixinApplication(fragment, mixins);

  String name = fragment.name;

  IndexedClass? referencesFromIndexedClass;
  if (indexedLibrary != null) {
    referencesFromIndexedClass = indexedLibrary.lookupIndexedClass(name);
  }

  createNominalParameterBuilders(
      fragment.typeParameters, unboundNominalParameters);
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, fragment.typeParameters?.builders,
      ownerName: name, allowNameConflict: false);
  LookupScope typeParameterScope = TypeParameterScope.fromList(
      fragment.enclosingScope, fragment.typeParameters?.builders);
  DeclarationNameSpaceBuilder nameSpaceBuilder =
      new DeclarationNameSpaceBuilder.empty();
  SourceClassBuilder classBuilder = new SourceClassBuilder(
      modifiers: fragment.modifiers | Modifiers.NamedMixinApplication,
      name: name,
      typeParameters: fragment.typeParameters?.builders,
      typeParameterScope: typeParameterScope,
      nameSpaceBuilder: nameSpaceBuilder,
      libraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      nameOffset: fragment.nameOffset,
      indexedClass: referencesFromIndexedClass,
      mixedInTypeBuilder: mixin,
      introductory: classDeclaration);
  mixinApplications[classBuilder] = mixin;
  fragment.builder = classBuilder;
  if (referencesFromIndexedClass != null) {
    loader.buildersCreatedWithReferences[referencesFromIndexedClass.reference] =
        classBuilder;
  }
  return new _AddBuilder(
      fragment.name, classBuilder, fragment.fileUri, fragment.nameOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createEnumBuilder(EnumFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  IndexedClass? indexedClass =
      indexedLibrary?.lookupIndexedClass(fragment.name);
  createNominalParameterBuilders(
      fragment.typeParameters, unboundNominalParameters);
  List<SourceNominalParameterBuilder>? typeParameters =
      fragment.typeParameters?.builders;
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, typeParameters,
      ownerName: fragment.name, allowNameConflict: false);
  SourceEnumBuilder enumBuilder = new SourceEnumBuilder(
      name: fragment.name,
      typeParameters: typeParameters,
      underscoreEnumTypeBuilder: loader.target.underscoreEnumType,
      interfaceBuilders: fragment.interfaces,
      enumElements: fragment.enumElements,
      libraryBuilder: enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      startOffset: fragment.startOffset,
      nameOffset: fragment.nameOffset,
      endOffset: fragment.endOffset,
      indexedClass: indexedClass,
      typeParameterScope: fragment.typeParameterScope,
      nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
      classDeclaration:
          new EnumDeclaration(fragment, loader.target.underscoreEnumType));
  fragment.builder = enumBuilder;
  fragment.bodyScope.declarationBuilder = enumBuilder;
  if (indexedClass != null) {
    loader.buildersCreatedWithReferences[indexedClass.reference] = enumBuilder;
  }
  return new _AddBuilder(
      fragment.name, enumBuilder, fragment.fileUri, fragment.fileOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createExtensionBuilder(
    ExtensionFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  DeclarationNameSpaceBuilder nameSpaceBuilder =
      fragment.toDeclarationNameSpaceBuilder();
  List<SourceNominalParameterBuilder>? nominalParameters =
      createNominalParameterBuilders(
          fragment.typeParameters, unboundNominalParameters);
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, nominalParameters,
      ownerName: fragment.name, allowNameConflict: false);

  List<ExtensionFragment> augmentationFragments = [];
  if (augmentations != null) {
    int introductoryTypeParameterCount = fragment.typeParameters?.length ?? 0;
    int nameLength = fragment.isUnnamed ? noLength : fragment.name.length;

    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [ExtensionFragment].
      augmentation as ExtensionFragment;

      augmentationFragments.add(augmentation);
      nameSpaceBuilder
          .includeBuilders(augmentation.toDeclarationNameSpaceBuilder());

      int augmentationTypeParameterCount =
          augmentation.typeParameters?.length ?? 0;
      if (introductoryTypeParameterCount != augmentationTypeParameterCount) {
        problemReporting.addProblem(
            messagePatchExtensionTypeParametersMismatch,
            augmentation.nameOrExtensionOffset,
            nameLength,
            augmentation.fileUri,
            context: [
              messagePatchExtensionOrigin.withLocation(
                  fragment.fileUri, fragment.nameOrExtensionOffset, nameLength)
            ]);

        // Error recovery. Create fresh type parameters for the
        // augmentation.
        augmentation.nominalParameterNameSpace.addTypeParameters(
            problemReporting,
            createNominalParameterBuilders(
                augmentation.typeParameters, unboundNominalParameters),
            ownerName: augmentation.name,
            allowNameConflict: false);
      } else if (augmentation.typeParameters != null) {
        for (int index = 0; index < introductoryTypeParameterCount; index++) {
          SourceNominalParameterBuilder nominalParameterBuilder =
              nominalParameters![index];
          TypeParameterFragment typeParameterFragment =
              augmentation.typeParameters![index];
          nominalParameterBuilder.addAugmentingDeclaration(
              new RegularNominalParameterDeclaration(typeParameterFragment));
          typeParameterFragment.builder = nominalParameterBuilder;
        }
        augmentation.nominalParameterNameSpace.addTypeParameters(
            problemReporting, nominalParameters,
            ownerName: augmentation.name, allowNameConflict: false);
      }
    }
    augmentations.clear();
  }
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
      introductory: fragment,
      augmentations: augmentationFragments,
      nameSpaceBuilder: nameSpaceBuilder,
      reference: reference);
  if (reference != null) {
    loader.buildersCreatedWithReferences[reference] = extensionBuilder;
  }
  return new _AddBuilder(
      fragment.name, extensionBuilder, fragment.fileUri, fragment.fileOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createExtensionTypeBuilder(ExtensionTypeFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary}) {
  IndexedContainer? indexedContainer =
      indexedLibrary?.lookupIndexedExtensionTypeDeclaration(fragment.name);
  List<PrimaryConstructorFieldFragment> primaryConstructorFields =
      fragment.primaryConstructorFields;
  PrimaryConstructorFieldFragment? representationFieldFragment;
  if (primaryConstructorFields.isNotEmpty) {
    representationFieldFragment = primaryConstructorFields.first;
  }
  createNominalParameterBuilders(
      fragment.typeParameters, unboundNominalParameters);
  fragment.nominalParameterNameSpace.addTypeParameters(
      problemReporting, fragment.typeParameters?.builders,
      ownerName: fragment.name, allowNameConflict: false);
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
  return new _AddBuilder(fragment.name, extensionTypeDeclarationBuilder,
      fragment.fileUri, fragment.fileOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createFieldBuilder(FieldFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;

  final bool fieldIsLateWithLowering = fragment.modifiers.isLate &&
      (loader.target.backendTarget.isLateFieldLoweringEnabled(
              hasInitializer: fragment.modifiers.hasInitializer,
              isFinal: fragment.modifiers.isFinal,
              isStatic: fragment.isTopLevel || fragment.modifiers.isStatic) ||
          (loader.target.backendTarget.useStaticFieldLowering &&
              // Coverage-ignore(suite): Not run.
              (fragment.modifiers.isStatic || fragment.isTopLevel)));

  final bool isInstanceMember =
      containerType != ContainerType.Library && !fragment.modifiers.isStatic;

  PropertyEncodingStrategy propertyEncodingStrategy =
      new PropertyEncodingStrategy(declarationBuilder,
          isInstanceMember: isInstanceMember);

  NameScheme nameScheme = new NameScheme(
      isInstanceMember: isInstanceMember,
      containerName: containerName,
      containerType: containerType,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.reference)
          : enclosingLibraryBuilder.libraryName);
  indexedContainer ??= indexedLibrary;

  PropertyReferences references = new PropertyReferences(
      name, nameScheme, indexedContainer,
      fieldIsLateWithLowering: fieldIsLateWithLowering);

  RegularFieldDeclaration declaration = new RegularFieldDeclaration(fragment);
  SourcePropertyBuilder propertyBuilder = new SourcePropertyBuilder.forField(
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      nameScheme: nameScheme,
      fieldDeclaration: declaration,
      getterDeclaration: declaration,
      setterDeclaration: fragment.hasSetter ? declaration : null,
      modifiers: fragment.modifiers,
      references: references);
  fragment.builder = propertyBuilder;
  declaration.createEncoding(propertyBuilder);
  declaration.createGetterEncoding(problemReporting, propertyBuilder,
      propertyEncodingStrategy, unboundNominalParameters);
  if (fragment.hasSetter) {
    declaration.createSetterEncoding(problemReporting, propertyBuilder,
        propertyEncodingStrategy, unboundNominalParameters);
  }
  references.registerReference(loader, propertyBuilder);
  return new _AddBuilder(
      fragment.name, propertyBuilder, fragment.fileUri, fragment.nameOffset,
      inPatch: fragment.enclosingDeclaration?.isPatch ??
          fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createPrimaryConstructorFieldBuilder(
    PrimaryConstructorFieldFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;

  final bool isInstanceMember = true;

  PropertyEncodingStrategy propertyEncodingStrategy =
      new PropertyEncodingStrategy(declarationBuilder,
          isInstanceMember: isInstanceMember);

  NameScheme nameScheme = new NameScheme(
      isInstanceMember: isInstanceMember,
      containerName: containerName,
      containerType: containerType,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.reference)
          : enclosingLibraryBuilder.libraryName);
  indexedContainer ??= indexedLibrary;

  PropertyReferences references = new PropertyReferences(
      name, nameScheme, indexedContainer,
      fieldIsLateWithLowering: false);

  PrimaryConstructorFieldDeclaration declaration =
      new PrimaryConstructorFieldDeclaration(fragment);
  SourcePropertyBuilder propertyBuilder = new SourcePropertyBuilder.forField(
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      nameScheme: nameScheme,
      fieldDeclaration: declaration,
      getterDeclaration: declaration,
      setterDeclaration: null,
      modifiers: Modifiers.Final,
      references: references);
  fragment.builder = propertyBuilder;
  declaration.createEncoding(propertyBuilder);
  declaration.createGetterEncoding(problemReporting, propertyBuilder,
      propertyEncodingStrategy, unboundNominalParameters);
  references.registerReference(loader, propertyBuilder);
  return new _AddBuilder(
      fragment.name, propertyBuilder, fragment.fileUri, fragment.nameOffset,
      inPatch: fragment.enclosingDeclaration.isPatch);
}

_AddBuilder _createGetterBuilder(
    GetterFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;
  final bool isInstanceMember =
      containerType != ContainerType.Library && !fragment.modifiers.isStatic;

  Modifiers modifiers = fragment.modifiers;

  createNominalParameterBuilders(
      fragment.declaredTypeParameters, unboundNominalParameters);

  PropertyEncodingStrategy propertyEncodingStrategy =
      new PropertyEncodingStrategy(declarationBuilder,
          isInstanceMember: isInstanceMember);

  NameScheme nameScheme = new NameScheme(
      containerName: containerName,
      containerType: containerType,
      isInstanceMember: isInstanceMember,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.library.reference)
          : enclosingLibraryBuilder.libraryName);

  indexedContainer ??= indexedLibrary;

  PropertyReferences references = new PropertyReferences(
      name, nameScheme, indexedContainer,
      fieldIsLateWithLowering: false);

  GetterDeclaration declaration = new GetterDeclarationImpl(fragment);
  List<GetterDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [GetterFragment].
      augmentation as GetterFragment;

      augmentationDeclarations.add(new GetterDeclarationImpl(augmentation));
      if (!(augmentation.modifiers.isAbstract ||
          augmentation.modifiers.isExternal)) {
        modifiers -= Modifiers.Abstract;
        modifiers -= Modifiers.External;
      }
    }
  }

  SourcePropertyBuilder propertyBuilder = new SourcePropertyBuilder.forGetter(
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      declaration: declaration,
      augmentations: augmentationDeclarations,
      modifiers: modifiers,
      nameScheme: nameScheme,
      references: references);
  fragment.builder = propertyBuilder;
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [GetterFragment].
      augmentation as GetterFragment;

      augmentation.builder = propertyBuilder;

      createNominalParameterBuilders(
          augmentation.declaredTypeParameters, unboundNominalParameters);
    }
    augmentations.clear();
  }

  declaration.createGetterEncoding(problemReporting, propertyBuilder,
      propertyEncodingStrategy, unboundNominalParameters);
  for (GetterDeclaration augmentation in augmentationDeclarations) {
    augmentation.createGetterEncoding(problemReporting, propertyBuilder,
        propertyEncodingStrategy, unboundNominalParameters);
  }

  references.registerReference(loader, propertyBuilder);
  return new _AddBuilder(
      fragment.name, propertyBuilder, fragment.fileUri, fragment.nameOffset,
      inPatch: fragment.enclosingDeclaration?.isPatch ??
          fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createSetterBuilder(
    SetterFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName,
    required bool conflictingSetter}) {
  String name = fragment.name;
  final bool isInstanceMember =
      containerType != ContainerType.Library && !fragment.modifiers.isStatic;

  Modifiers modifiers = fragment.modifiers;
  createNominalParameterBuilders(
      fragment.declaredTypeParameters, unboundNominalParameters);

  PropertyEncodingStrategy propertyEncodingStrategy =
      new PropertyEncodingStrategy(declarationBuilder,
          isInstanceMember: isInstanceMember);

  NameScheme nameScheme = new NameScheme(
      containerName: containerName,
      containerType: containerType,
      isInstanceMember: isInstanceMember,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.library.reference)
          : enclosingLibraryBuilder.libraryName);

  indexedContainer ??= indexedLibrary;

  PropertyReferences references = new PropertyReferences(
      name, nameScheme, indexedContainer,
      fieldIsLateWithLowering: false);

  SetterDeclaration declaration = new SetterDeclarationImpl(fragment);
  List<SetterDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [SetterFragment].
      augmentation as SetterFragment;

      augmentationDeclarations.add(new SetterDeclarationImpl(augmentation));

      createNominalParameterBuilders(
          augmentation.declaredTypeParameters, unboundNominalParameters);

      if (!(augmentation.modifiers.isAbstract ||
          augmentation.modifiers.isExternal)) {
        modifiers -= Modifiers.Abstract;
        modifiers -= Modifiers.External;
      }
    }
  }

  SourcePropertyBuilder propertyBuilder = new SourcePropertyBuilder.forSetter(
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      declaration: declaration,
      augmentations: augmentationDeclarations,
      modifiers: modifiers,
      nameScheme: nameScheme,
      references: references);
  fragment.builder = propertyBuilder;
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [SetterFragment].
      augmentation as SetterFragment;

      augmentation.builder = propertyBuilder;
    }
    augmentations.clear();
  }

  declaration.createSetterEncoding(problemReporting, propertyBuilder,
      propertyEncodingStrategy, unboundNominalParameters);
  for (SetterDeclaration augmentation in augmentationDeclarations) {
    augmentation.createSetterEncoding(problemReporting, propertyBuilder,
        propertyEncodingStrategy, unboundNominalParameters);
  }

  references.registerReference(loader, propertyBuilder);
  if (conflictingSetter) {
    propertyBuilder.isConflictingSetter = true;
  }
  return new _AddBuilder(
      fragment.name, propertyBuilder, fragment.fileUri, fragment.nameOffset,
      inPatch: fragment.enclosingDeclaration?.isPatch ??
          fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createMethodBuilder(
    MethodFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;
  final bool isInstanceMember =
      containerType != ContainerType.Library && !fragment.modifiers.isStatic;

  createNominalParameterBuilders(
      fragment.declaredTypeParameters, unboundNominalParameters);

  MethodEncodingStrategy encodingStrategy = new MethodEncodingStrategy(
      declarationBuilder,
      isInstanceMember: isInstanceMember);

  ProcedureKind kind =
      fragment.isOperator ? ProcedureKind.Operator : ProcedureKind.Method;

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

  if (indexedContainer != null) {
    Name nameToLookup = nameScheme.getProcedureMemberName(kind, name).name;
    procedureReference = indexedContainer.lookupGetterReference(nameToLookup);
    if ((isExtensionMember || isExtensionTypeMember) &&
        kind == ProcedureKind.Method) {
      tearOffReference = indexedContainer.lookupGetterReference(
          nameScheme.getProcedureMemberName(ProcedureKind.Getter, name).name);
    }
  }

  Modifiers modifiers = fragment.modifiers;
  MethodDeclaration introductoryDeclaration =
      new MethodDeclarationImpl(fragment);

  List<MethodDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [MethodFragment].
      augmentation as MethodFragment;

      augmentationDeclarations.add(new MethodDeclarationImpl(augmentation));

      createNominalParameterBuilders(
          augmentation.declaredTypeParameters, unboundNominalParameters);

      if (!(augmentation.modifiers.isAbstract ||
          augmentation.modifiers.isExternal)) {
        modifiers -= Modifiers.Abstract;
        modifiers -= Modifiers.External;
      }
    }
  }

  SourceMethodBuilder methodBuilder = new SourceMethodBuilder(
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      isStatic: modifiers.isStatic,
      modifiers: modifiers,
      introductory: introductoryDeclaration,
      augmentations: augmentationDeclarations,
      nameScheme: nameScheme,
      reference: procedureReference,
      tearOffReference: tearOffReference);
  fragment.builder = methodBuilder;
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [MethodFragment].
      augmentation as MethodFragment;

      augmentation.builder = methodBuilder;
    }
    augmentations.clear();
  }
  introductoryDeclaration.createEncoding(problemReporting, methodBuilder,
      encodingStrategy, unboundNominalParameters);
  for (MethodDeclaration augmentation in augmentationDeclarations) {
    augmentation.createEncoding(problemReporting, methodBuilder,
        encodingStrategy, unboundNominalParameters);
  }

  if (procedureReference != null) {
    loader.buildersCreatedWithReferences[procedureReference] = methodBuilder;
  }
  return new _AddBuilder(
      fragment.name, methodBuilder, fragment.fileUri, fragment.nameOffset,
      inPatch: fragment.enclosingDeclaration?.isPatch ??
          fragment.enclosingCompilationUnit.isPatch);
}

_AddBuilder _createConstructorBuilder(
    ConstructorFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;
  Modifiers modifiers = fragment.modifiers;
  NameScheme nameScheme = new NameScheme(
      isInstanceMember: false,
      containerName: containerName,
      containerType: containerType,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.library.reference)
          : enclosingLibraryBuilder.libraryName);

  createNominalParameterBuilders(
      fragment.typeParameters, unboundNominalParameters);

  Reference? constructorReference;
  Reference? tearOffReference;

  if (indexedContainer != null) {
    constructorReference = indexedContainer.lookupConstructorReference(
        nameScheme.getConstructorMemberName(name, isTearOff: false).name);
    tearOffReference = indexedContainer.lookupGetterReference(
        nameScheme.getConstructorMemberName(name, isTearOff: true).name);
  }

  ConstructorDeclaration createConstructorDeclaration(
      ConstructorFragment fragment) {
    switch (declarationBuilder!) {
      case ExtensionTypeDeclarationBuilder():
        List<SourceNominalParameterBuilder>? typeParameters = fragment
            .typeParameters
            // Coverage-ignore(suite): Not run.
            ?.builders;
        NominalParameterCopy? nominalVariableCopy =
            NominalParameterCopy.copyTypeParameters(
                unboundNominalParameters: unboundNominalParameters,
                oldParameterBuilders: declarationBuilder.typeParameters,
                oldParameterFragments:
                    fragment.enclosingDeclaration.typeParameters,
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
        fragment.typeParameterNameSpace.addTypeParameters(
            problemReporting, typeParameters,
            ownerName: fragment.name, allowNameConflict: true);
        return new ExtensionTypeConstructorDeclaration(fragment,
            typeParameters: typeParameters);
      case ClassBuilder():
        List<FormalParameterBuilder>? syntheticFormals;
        if (declarationBuilder.isEnum) {
          syntheticFormals = [
            new FormalParameterBuilder(
                FormalParameterKind.requiredPositional,
                Modifiers.empty,
                loader.target.intType,
                "#index",
                fragment.fullNameOffset,
                fileUri: fragment.fileUri,
                hasImmediatelyDeclaredInitializer: false),
            new FormalParameterBuilder(
                FormalParameterKind.requiredPositional,
                Modifiers.empty,
                loader.target.stringType,
                "#name",
                fragment.fullNameOffset,
                fileUri: fragment.fileUri,
                hasImmediatelyDeclaredInitializer: false),
          ];
        }
        List<SourceNominalParameterBuilder>? typeParameters =
            fragment.typeParameters?.builders;
        fragment.typeParameterNameSpace.addTypeParameters(
            problemReporting, typeParameters,
            ownerName: fragment.name, allowNameConflict: true);
        return new RegularConstructorDeclaration(fragment,
            typeParameters: typeParameters,
            syntheticFormals: syntheticFormals,
            isEnumConstructor: declarationBuilder.isEnum);
      case ExtensionBuilder():
        List<SourceNominalParameterBuilder>? typeParameters = fragment
            .typeParameters
            // Coverage-ignore(suite): Not run.
            ?.builders;
        NominalParameterCopy? nominalVariableCopy =
            NominalParameterCopy.copyTypeParameters(
                unboundNominalParameters: unboundNominalParameters,
                oldParameterBuilders: declarationBuilder.typeParameters,
                oldParameterFragments:
                    fragment.enclosingDeclaration.typeParameters,
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
        fragment.typeParameterNameSpace.addTypeParameters(
            problemReporting, typeParameters,
            ownerName: fragment.name, allowNameConflict: true);
        return new RegularConstructorDeclaration(fragment,
            typeParameters: typeParameters,
            syntheticFormals: null,
            isEnumConstructor: false);
    }
  }

  ConstructorDeclaration constructorDeclaration =
      createConstructorDeclaration(fragment);

  List<ConstructorDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [ConstructorFragment].
      augmentation as ConstructorFragment;

      createNominalParameterBuilders(
          augmentation.typeParameters, unboundNominalParameters);

      augmentationDeclarations.add(createConstructorDeclaration(augmentation));

      if (!augmentation.modifiers.isExternal) {
        modifiers -= Modifiers.External;
      }
    }
  }

  SourceConstructorBuilderImpl constructorBuilder =
      new SourceConstructorBuilderImpl(
          modifiers: modifiers,
          name: name,
          libraryBuilder: enclosingLibraryBuilder,
          declarationBuilder: declarationBuilder!,
          fileUri: fragment.fileUri,
          fileOffset: fragment.fullNameOffset,
          constructorReference: constructorReference,
          tearOffReference: tearOffReference,
          nameScheme: nameScheme,
          nativeMethodName: fragment.nativeMethodName,
          introductory: constructorDeclaration,
          augmentations: augmentationDeclarations);
  fragment.builder = constructorBuilder;
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [ConstructorFragment].
      augmentation as ConstructorFragment;
      augmentation.builder = constructorBuilder;
    }
    augmentations.clear();
  }
  // TODO(johnniwinther): There is no way to pass the tear off reference
  //  here.
  if (constructorReference != null) {
    loader.buildersCreatedWithReferences[constructorReference] =
        constructorBuilder;
  }

  return new _AddBuilder(fragment.name, constructorBuilder, fragment.fileUri,
      fragment.fullNameOffset,
      inPatch: fragment.enclosingDeclaration.isPatch);
}

_AddBuilder _createPrimaryConstructorBuilder(
    PrimaryConstructorFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
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
    constructorReference = indexedContainer.lookupConstructorReference(
        nameScheme.getConstructorMemberName(name, isTearOff: false).name);
    tearOffReference = indexedContainer.lookupGetterReference(
        nameScheme.getConstructorMemberName(name, isTearOff: true).name);
  }

  SourceConstructorBuilderImpl constructorBuilder;
  switch (declarationBuilder!) {
    case ExtensionTypeDeclarationBuilder():
      NominalParameterCopy? nominalVariableCopy =
          NominalParameterCopy.copyTypeParameters(
              unboundNominalParameters: unboundNominalParameters,
              oldParameterBuilders: declarationBuilder.typeParameters,
              oldParameterFragments:
                  fragment.enclosingDeclaration.typeParameters,
              kind: TypeParameterKind.extensionSynthesized,
              instanceTypeParameterAccess:
                  InstanceTypeParameterAccessState.Allowed);

      List<SourceNominalParameterBuilder>? typeParameters =
          nominalVariableCopy?.newParameterBuilders;
      fragment.typeParameterNameSpace.addTypeParameters(
          problemReporting, typeParameters,
          ownerName: fragment.name, allowNameConflict: true);
      ConstructorDeclaration constructorDeclaration =
          new ExtensionTypePrimaryConstructorDeclaration(fragment,
              typeParameters: typeParameters);
      constructorBuilder = new SourceConstructorBuilderImpl(
          modifiers: fragment.modifiers,
          name: name,
          libraryBuilder: enclosingLibraryBuilder,
          declarationBuilder:
              declarationBuilder as SourceExtensionTypeDeclarationBuilder,
          fileUri: fragment.fileUri,
          fileOffset: fragment.fileOffset,
          constructorReference: constructorReference,
          tearOffReference: tearOffReference,
          nameScheme: nameScheme,
          introductory: constructorDeclaration);
    // Coverage-ignore(suite): Not run.
    case ClassBuilder():
      ConstructorDeclaration constructorDeclaration =
          new PrimaryConstructorDeclaration(fragment);
      constructorBuilder = new SourceConstructorBuilderImpl(
          modifiers: fragment.modifiers,
          name: fragment.name,
          libraryBuilder: enclosingLibraryBuilder,
          declarationBuilder: declarationBuilder,
          fileUri: fragment.fileUri,
          fileOffset: fragment.fileOffset,
          constructorReference: constructorReference,
          tearOffReference: tearOffReference,
          nameScheme: nameScheme,
          introductory: constructorDeclaration);
    // Coverage-ignore(suite): Not run.
    case ExtensionBuilder():
      throw new UnsupportedError(
          'Unexpected extension primary constructor $fragment');
  }
  fragment.builder = constructorBuilder;

  // TODO(johnniwinther): There is no way to pass the tear off reference
  //  here.
  if (constructorReference != null) {
    loader.buildersCreatedWithReferences[constructorReference] =
        constructorBuilder;
  }
  return new _AddBuilder(
      fragment.name, constructorBuilder, fragment.fileUri, fragment.fileOffset,
      inPatch: fragment.enclosingDeclaration.isPatch);
}

_AddBuilder _createFactoryBuilder(
    FactoryFragment fragment, List<Fragment>? augmentations,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  String name = fragment.name;
  Modifiers modifiers = fragment.modifiers;

  FactoryDeclaration createFactoryDeclaration(FactoryFragment fragment) {
    NominalParameterCopy? nominalParameterCopy =
        NominalParameterCopy.copyTypeParameters(
            unboundNominalParameters: unboundNominalParameters,
            oldParameterBuilders: declarationBuilder!.typeParameters,
            oldParameterFragments: fragment.enclosingDeclaration.typeParameters,
            kind: TypeParameterKind.function,
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Allowed);
    List<SourceNominalParameterBuilder>? typeParameters =
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
    return new FactoryDeclarationImpl(fragment,
        returnType: returnType, typeParameters: typeParameters);
  }

  FactoryDeclaration introductoryDeclaration =
      createFactoryDeclaration(fragment);

  bool isRedirectingFactory = fragment.redirectionTarget != null;
  List<FactoryDeclaration> augmentationDeclarations = [];
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [FactoryFragment].
      augmentation as FactoryFragment;

      augmentationDeclarations.add(createFactoryDeclaration(augmentation));

      isRedirectingFactory |= augmentation.redirectionTarget != null;

      if (!augmentation.modifiers.isExternal) {
        modifiers -= Modifiers.External;
      }
    }
  }

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
    procedureReference = indexedContainer.lookupConstructorReference(
        nameScheme.getConstructorMemberName(name, isTearOff: false).name);
    tearOffReference = indexedContainer.lookupGetterReference(
        nameScheme.getConstructorMemberName(name, isTearOff: true).name);
  }
  // Coverage-ignore(suite): Not run.
  else if (indexedLibrary != null) {
    procedureReference = indexedLibrary.lookupGetterReference(
        nameScheme.getConstructorMemberName(name, isTearOff: false).name);
    tearOffReference = indexedLibrary.lookupGetterReference(
        nameScheme.getConstructorMemberName(name, isTearOff: true).name);
  }

  SourceFactoryBuilder factoryBuilder = new SourceFactoryBuilder(
      modifiers: modifiers,
      name: name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder!,
      fileUri: fragment.fileUri,
      fileOffset: fragment.fullNameOffset,
      procedureReference: procedureReference,
      tearOffReference: tearOffReference,
      nameScheme: nameScheme,
      introductory: introductoryDeclaration,
      augmentations: augmentationDeclarations);
  if (isRedirectingFactory) {
    (enclosingLibraryBuilder.redirectingFactoryBuilders ??= [])
        .add(factoryBuilder);
  }
  fragment.builder = factoryBuilder;
  if (augmentations != null) {
    for (Fragment augmentation in augmentations) {
      // Promote [augmentation] to [FactoryFragment].
      augmentation as FactoryFragment;

      augmentation.builder = factoryBuilder;
    }
    augmentations.clear();
  }
  // TODO(johnniwinther): There is no way to pass the tear off reference
  //  here.
  if (procedureReference != null) {
    loader.buildersCreatedWithReferences[procedureReference] = factoryBuilder;
  }
  return new _AddBuilder(
      fragment.name, factoryBuilder, fragment.fileUri, fragment.fullNameOffset,
      inPatch: fragment.enclosingDeclaration.isPatch);
}

_AddBuilder _createEnumElementBuilder(EnumElementFragment fragment,
    {required ProblemReporting problemReporting,
    required SourceLoader loader,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<NominalParameterBuilder> unboundNominalParameters,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    required IndexedContainer? indexedContainer,
    required ContainerName? containerName}) {
  NameScheme nameScheme = new NameScheme(
      containerName: containerName,
      containerType: containerType,
      isInstanceMember: false,
      libraryName: indexedLibrary != null
          ? new LibraryName(indexedLibrary.library.reference)
          : enclosingLibraryBuilder.libraryName);
  PropertyReferences references = new PropertyReferences(
      fragment.name, nameScheme, indexedContainer,
      fieldIsLateWithLowering: false);
  EnumElementDeclaration enumElementDeclaration =
      new EnumElementDeclaration(fragment);
  SourcePropertyBuilder propertyBuilder = new SourcePropertyBuilder.forField(
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      name: fragment.name,
      libraryBuilder: enclosingLibraryBuilder,
      declarationBuilder: declarationBuilder,
      nameScheme: nameScheme,
      fieldDeclaration: enumElementDeclaration,
      getterDeclaration: enumElementDeclaration,
      setterDeclaration: null,
      modifiers: Modifiers.Const | Modifiers.Static | Modifiers.HasInitializer,
      references: references);
  fragment.builder = propertyBuilder;
  return new _AddBuilder(
      fragment.name, propertyBuilder, fragment.fileUri, fragment.nameOffset,
      inPatch: fragment.enclosingDeclaration.isPatch);
}
