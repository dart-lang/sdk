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

class ClassElementBuilder extends InstanceElementBuilder<
    AugmentedClassElementImpl, ClassElementImpl> {
  ClassElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(ClassElementImpl fragment) {
    addFields(fragment.fields);
    addConstructors(fragment.constructors);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (identical(fragment, firstFragment)) {
      _addFirstFragment();
    } else {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
      _updatedAugmented(fragment);
    }
  }
}

class EnumElementBuilder
    extends InstanceElementBuilder<AugmentedEnumElementImpl, EnumElementImpl> {
  EnumElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(EnumElementImpl fragment) {
    addFields(fragment.fields);
    addConstructors(fragment.constructors);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (identical(fragment, firstFragment)) {
      _addFirstFragment();
    } else {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
      _updatedAugmented(fragment);
    }
  }
}

class ExtensionElementBuilder extends InstanceElementBuilder<
    AugmentedExtensionElementImpl, ExtensionElementImpl> {
  ExtensionElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(ExtensionElementImpl fragment) {
    addFields(fragment.fields);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (identical(fragment, firstFragment)) {
      _addFirstFragment();
    } else {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
      _updatedAugmented(fragment);
    }
  }
}

class ExtensionTypeElementBuilder extends InstanceElementBuilder<
    AugmentedExtensionTypeElementImpl, ExtensionTypeElementImpl> {
  ExtensionTypeElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(ExtensionTypeElementImpl fragment) {
    addFields(fragment.fields);
    addConstructors(fragment.constructors);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (identical(fragment, firstFragment)) {
      _addFirstFragment();
    } else {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
      _updatedAugmented(fragment);
    }
  }
}

/// A builder for top-level fragmented elements, e.g. classes.
class FragmentedElementBuilder<E extends Element2, F extends Fragment> {
  final E element;
  final F firstFragment;
  F lastFragment;

  FragmentedElementBuilder({
    required this.element,
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

class GetterElementBuilder extends FragmentedElementBuilder<GetterElementImpl,
    PropertyAccessorElementImpl> {
  GetterElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(PropertyAccessorElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}

abstract class InstanceElementBuilder<E extends AugmentedInstanceElementImpl,
    F extends InstanceElementImpl> extends FragmentedElementBuilder<E, F> {
  final Map<String, FieldElementImpl> fields = {};
  final Map<String, ConstructorElementImpl> constructors = {};
  final Map<String, PropertyAccessorElementImpl> getters = {};
  final Map<String, PropertyAccessorElementImpl> setters = {};
  final Map<String, MethodElementImpl> methods = {};

  InstanceElementBuilder({
    required super.element,
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

  void _addFirstFragment() {
    var firstFragment = this.firstFragment;
    var augmented = firstFragment.augmented;

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

  void _updatedAugmented(InstanceElementImpl augmentation) {
    var element = this.element;
    var firstFragment = this.firstFragment;
    var firstTypeParameters = firstFragment.typeParameters;

    MapSubstitution toFirstFragment;
    var augmentationTypeParameters = augmentation.typeParameters;
    if (augmentationTypeParameters.length == firstTypeParameters.length) {
      toFirstFragment = Substitution.fromPairs(
        augmentationTypeParameters,
        firstTypeParameters.instantiateNone(),
      );
    } else {
      toFirstFragment = Substitution.fromPairs(
        augmentationTypeParameters,
        List.filled(
          augmentationTypeParameters.length,
          InvalidTypeImpl.instance,
        ),
      );
    }

    if (augmentation is InterfaceElementImpl &&
        firstFragment is InterfaceElementImpl &&
        element is AugmentedInterfaceElementImpl) {
      element.constructors = [
        ...element.constructors.notAugmented,
        ...augmentation.constructors.notAugmented.map((element) {
          if (toFirstFragment.map.isEmpty) {
            return element;
          }
          return ConstructorMember(
            declaration: element,
            augmentationSubstitution: toFirstFragment,
            substitution: Substitution.empty,
          );
        }),
      ];
    }

    element.fields = [
      ...element.fields.notAugmented,
      ...augmentation.fields.notAugmented.map((element) {
        if (toFirstFragment.map.isEmpty) {
          return element;
        }
        return FieldMember(element, toFirstFragment, Substitution.empty);
      }),
    ];

    element.accessors = [
      ...element.accessors.notAugmented,
      ...augmentation.accessors.notAugmented.map((element) {
        if (toFirstFragment.map.isEmpty) {
          return element;
        }
        return PropertyAccessorMember(
            element, toFirstFragment, Substitution.empty);
      }),
    ];

    element.methods = [
      ...element.methods.notAugmented,
      ...augmentation.methods.notAugmented.map((element) {
        if (toFirstFragment.map.isEmpty) {
          return element;
        }
        return MethodMember(element, toFirstFragment, Substitution.empty);
      }),
    ];
  }
}

class MixinElementBuilder extends InstanceElementBuilder<
    AugmentedMixinElementImpl, MixinElementImpl> {
  MixinElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(MixinElementImpl fragment) {
    addFields(fragment.fields);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);

    if (identical(fragment, firstFragment)) {
      _addFirstFragment();
    } else {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
      _updatedAugmented(fragment);
    }
  }
}

class SetterElementBuilder extends FragmentedElementBuilder<SetterElementImpl,
    PropertyAccessorElementImpl> {
  SetterElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(PropertyAccessorElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}

class TopLevelFunctionElementBuilder extends FragmentedElementBuilder<
    TopLevelFunctionElementImpl, FunctionElementImpl> {
  TopLevelFunctionElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(FunctionElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}

class TopLevelVariableElementBuilder extends FragmentedElementBuilder<
    TopLevelVariableElementImpl2, TopLevelVariableElementImpl> {
  TopLevelVariableElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(TopLevelVariableElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}

class TypeAliasElementBuilder extends FragmentedElementBuilder<
    TypeAliasElementImpl2, TypeAliasElementImpl> {
  TypeAliasElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(TypeAliasElementImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.augmentation = fragment;
      lastFragment = fragment;
      // fragment.element = element;
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
