// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

class ClassElementBuilder extends InstanceElementBuilder<ClassElementImpl> {
  ClassElementBuilder({
    required super.firstFragment,
    required MaybeAugmentedClassElementMixin element,
  }) {
    firstFragment.augmentedInternal = element;
  }

  void addFragment(ClassElementImpl fragment) {
    addFields(fragment.fields);
    addConstructors(fragment.constructors);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      var element = _ensureAugmented();
      fragment.augmentedInternal = firstFragment.augmentedInternal;

      _updatedAugmented(element, fragment);
    }
  }
}

class EnumElementBuilder extends InstanceElementBuilder<EnumElementImpl> {
  EnumElementBuilder({
    required super.firstFragment,
    required MaybeAugmentedEnumElementMixin element,
  }) {
    firstFragment.augmentedInternal = element;
  }

  void addFragment(EnumElementImpl fragment) {
    addFields(fragment.fields);
    addConstructors(fragment.constructors);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      var element = _ensureAugmented();
      fragment.augmentedInternal = firstFragment.augmentedInternal;

      _updatedAugmented(element, fragment);
    }
  }
}

class ExtensionElementBuilder
    extends InstanceElementBuilder<ExtensionElementImpl> {
  ExtensionElementBuilder({
    required super.firstFragment,
    required MaybeAugmentedExtensionElementMixin element,
  }) {
    firstFragment.augmentedInternal = element;
  }

  void addFragment(ExtensionElementImpl fragment) {
    addFields(fragment.fields);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      var element = _ensureAugmented();
      fragment.augmentedInternal = firstFragment.augmentedInternal;

      _updatedAugmented(element, fragment);
    }
  }
}

class ExtensionTypeElementBuilder
    extends InstanceElementBuilder<ExtensionTypeElementImpl> {
  ExtensionTypeElementBuilder({
    required super.firstFragment,
    required MaybeAugmentedExtensionTypeElementMixin element,
  }) {
    firstFragment.augmentedInternal = element;
  }

  void addFragment(ExtensionTypeElementImpl fragment) {
    addFields(fragment.fields);
    addConstructors(fragment.constructors);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      var element = _ensureAugmented();
      fragment.augmentedInternal = firstFragment.augmentedInternal;

      _updatedAugmented(element, fragment);
    }
  }
}

/// A builder for top-level fragmented elements, e.g. classes.
class FragmentedElementBuilder<F extends Fragment> {
  final F firstFragment;
  F lastFragment;

  FragmentedElementBuilder({
    required this.firstFragment,
  }) : lastFragment = firstFragment;

  /// If [fragment] is an augmentation, set its previous fragment to
  /// [lastFragment].
  ///
  /// We invoke this method on any [FragmentedElementBuilder] associated with
  /// the name of [fragment], even if it is not a correct builder for this
  /// [fragment]. So, the [lastFragment] might have a wrong type, but we still
  /// want to remember it for generating the corresponding diagnostic.
  void setPreviousFor(AugmentableElement fragment) {
    if (fragment.isAugmentation) {
      // TODO(scheglov): hopefully the type check can be removed in the future.
      if (lastFragment case ElementImpl lastFragment) {
        fragment.augmentationTargetAny = lastFragment;
      }
    }
  }
}

class FunctionElementBuilder
    extends FragmentedElementBuilder<FunctionElementImpl> {
  FunctionElementBuilder({
    required super.firstFragment,
  });

  void addFragment(FunctionElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
    }
  }
}

class GetterElementBuilder
    extends FragmentedElementBuilder<PropertyAccessorElementImpl> {
  GetterElementBuilder({
    required super.firstFragment,
  });

  void addFragment(PropertyAccessorElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
    }
  }
}

abstract class InstanceElementBuilder<F extends InstanceElementImpl>
    extends FragmentedElementBuilder<F> {
  final Map<String, FieldElementImpl> fields = {};
  final Map<String, ConstructorElementImpl> constructors = {};
  final Map<String, PropertyAccessorElementImpl> getters = {};
  final Map<String, PropertyAccessorElementImpl> setters = {};
  final Map<String, MethodElementImpl> methods = {};

  InstanceElementBuilder({
    required super.firstFragment,
  });

  void addAccessors(List<PropertyAccessorElementImpl> fragments) {
    for (var fragment in fragments) {
      var name = fragment.name;
      if (fragment.isGetter) {
        if (fragment.isAugmentation) {
          if (getters[name] case var target?) {
            target.augmentation = fragment;
            fragment.augmentationTargetAny = target;
          } else {
            var target = _recoveryAugmentationTarget(name);
            fragment.augmentationTargetAny = target;
          }
        }
        getters[name] = fragment;
      } else {
        if (fragment.isAugmentation) {
          if (setters[name] case var target?) {
            target.augmentation = fragment;
            fragment.augmentationTargetAny = target;
          } else {
            var target = _recoveryAugmentationTarget(name);
            fragment.augmentationTargetAny = target;
          }
        }
        setters[name] = fragment;
      }
    }
  }

  void addConstructors(List<ConstructorElementImpl> fragments) {
    for (var fragment in fragments) {
      var name = fragment.name;
      if (fragment.isAugmentation) {
        if (constructors[name] case var target?) {
          target.augmentation = fragment;
          fragment.augmentationTargetAny = target;
        } else {
          var target = _recoveryAugmentationTarget(name);
          fragment.augmentationTargetAny = target;
        }
      }
      constructors[name] = fragment;
    }
  }

  void addFields(List<FieldElementImpl> fragments) {
    for (var fragment in fragments) {
      var name = fragment.name;
      if (fragment.isAugmentation) {
        if (fields[name] case var target?) {
          target.augmentation = fragment;
          fragment.augmentationTargetAny = target;
        } else {
          var target = _recoveryAugmentationTarget(name);
          fragment.augmentationTargetAny = target;
        }
      }
      fields[name] = fragment;
    }
  }

  void addMethods(List<MethodElementImpl> fragments) {
    for (var fragment in fragments) {
      var name = fragment.name;
      if (fragment.isAugmentation) {
        if (methods[name] case var target?) {
          target.augmentation = fragment;
          fragment.augmentationTargetAny = target;
        } else {
          var target = _recoveryAugmentationTarget(name);
          fragment.augmentationTargetAny = target;
        }
      }
      methods[name] = fragment;
    }
  }

  AugmentedInstanceElementImpl _ensureAugmented() {
    var firstFragment = this.firstFragment;
    var maybeAugmented = firstFragment.augmented;
    if (maybeAugmented is AugmentedInstanceElementImpl) {
      return maybeAugmented;
    }

    maybeAugmented as NotAugmentedInstanceElementImpl;
    var augmented = maybeAugmented.toAugmented();

    augmented.fields.addAll(firstFragment.fields);
    augmented.accessors.addAll(firstFragment.accessors);
    augmented.methods.addAll(firstFragment.methods);

    if (augmented is AugmentedInterfaceElementImpl) {
      if (firstFragment is InterfaceElementImpl) {
        augmented.mixins.addAll(firstFragment.mixins);
        augmented.interfaces.addAll(firstFragment.interfaces);
        augmented.constructors.addAll(firstFragment.constructors);
      }
    }

    if (augmented is AugmentedMixinElementImpl) {
      if (firstFragment is MixinElementImpl) {
        augmented.superclassConstraints.addAll(
          firstFragment.superclassConstraints,
        );
      }
    }

    return augmented;
  }

  ElementImpl? _recoveryAugmentationTarget(String name) {
    name = name.removeSuffix('=') ?? name;

    ElementImpl? target;
    target ??= getters[name];
    target ??= setters['$name='];
    target ??= constructors[name];
    target ??= methods[name];
    return target;
  }

  void _updatedAugmented(
    AugmentedInstanceElementImpl augmented,
    InstanceElementImpl augmentation,
  ) {
    var declaration = firstFragment;
    var declarationTypeParameters = declaration.typeParameters;

    MapSubstitution toDeclaration;
    var augmentationTypeParameters = augmentation.typeParameters;
    if (augmentationTypeParameters.length == declarationTypeParameters.length) {
      toDeclaration = Substitution.fromPairs(
        augmentationTypeParameters,
        declarationTypeParameters.instantiateNone(),
      );
    } else {
      toDeclaration = Substitution.fromPairs(
        augmentationTypeParameters,
        List.filled(
          augmentationTypeParameters.length,
          InvalidTypeImpl.instance,
        ),
      );
    }

    if (augmentation is InterfaceElementImpl &&
        declaration is InterfaceElementImpl &&
        augmented is AugmentedInterfaceElementImpl) {
      augmented.constructors = [
        ...augmented.constructors.notAugmented,
        ...augmentation.constructors.notAugmented.map((element) {
          if (toDeclaration.map.isEmpty) {
            return element;
          }
          return ConstructorMember(
            declaration: element,
            augmentationSubstitution: toDeclaration,
            substitution: Substitution.empty,
          );
        }),
      ];
    }

    augmented.fields = [
      ...augmented.fields.notAugmented,
      ...augmentation.fields.notAugmented.map((element) {
        if (toDeclaration.map.isEmpty) {
          return element;
        }
        return FieldMember(element, toDeclaration, Substitution.empty);
      }),
    ];

    augmented.accessors = [
      ...augmented.accessors.notAugmented,
      ...augmentation.accessors.notAugmented.map((element) {
        if (toDeclaration.map.isEmpty) {
          return element;
        }
        return PropertyAccessorMember(
            element, toDeclaration, Substitution.empty);
      }),
    ];

    augmented.methods = [
      ...augmented.methods.notAugmented,
      ...augmentation.methods.notAugmented.map((element) {
        if (toDeclaration.map.isEmpty) {
          return element;
        }
        return MethodMember(element, toDeclaration, Substitution.empty);
      }),
    ];
  }
}

class MixinElementBuilder extends InstanceElementBuilder<MixinElementImpl> {
  MixinElementBuilder({
    required super.firstFragment,
    required MaybeAugmentedMixinElementMixin element,
  }) {
    firstFragment.augmentedInternal = element;
  }

  void addFragment(MixinElementImpl fragment) {
    addFields(fragment.fields);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      var element = _ensureAugmented();
      fragment.augmentedInternal = firstFragment.augmentedInternal;

      _updatedAugmented(element, fragment);
    }
  }
}

class SetterElementBuilder
    extends FragmentedElementBuilder<PropertyAccessorElementImpl> {
  SetterElementBuilder({
    required super.firstFragment,
  });

  void addFragment(PropertyAccessorElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
    }
  }
}

class TopLevelVariableElementBuilder
    extends FragmentedElementBuilder<TopLevelVariableElementImpl> {
  TopLevelVariableElementBuilder({
    required super.firstFragment,
  });

  void addFragment(TopLevelVariableElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
    }
  }
}

class TypeAliasElementBuilder
    extends FragmentedElementBuilder<TypeAliasElementImpl> {
  TypeAliasElementBuilder({
    required super.firstFragment,
  });

  void addFragment(TypeAliasElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
    }
  }
}

extension<T extends ExecutableElement> on List<T> {
  Iterable<T> get notAugmented {
    return where((e) => e.augmentation == null);
  }
}

extension<T extends PropertyInducingElement> on List<T> {
  Iterable<T> get notAugmented {
    return where((e) => e.augmentation == null);
  }
}
