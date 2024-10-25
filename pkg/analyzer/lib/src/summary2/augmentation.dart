// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

class AugmentedClassDeclarationBuilder
    extends AugmentedInstanceDeclarationBuilder<ClassElementImpl> {
  AugmentedClassDeclarationBuilder({
    required super.firstFragment,
    required MaybeAugmentedClassElementMixin element,
  }) {
    firstFragment.augmentedInternal = element;
    addFields(firstFragment.fields);
    addConstructors(firstFragment.constructors);
    addAccessors(firstFragment.accessors);
    addMethods(firstFragment.methods);
  }

  void augment(ClassElementImpl fragment) {
    lastFragment.augmentation = fragment;
    lastFragment = fragment;

    var element = _ensureAugmented(firstFragment);
    fragment.augmentedInternal = firstFragment.augmentedInternal;

    addFields(fragment.fields);
    addConstructors(fragment.constructors);
    addAccessors(fragment.accessors);
    addMethods(fragment.methods);
    _updatedAugmented(element, fragment);
  }
}

class AugmentedEnumDeclarationBuilder
    extends AugmentedInstanceDeclarationBuilder<EnumElementImpl> {
  AugmentedEnumDeclarationBuilder({
    required super.firstFragment,
  }) {
    addFields(firstFragment.fields);
    addConstructors(firstFragment.constructors);
    addAccessors(firstFragment.accessors);
    addMethods(firstFragment.methods);
  }

  void augment(EnumElementImpl element) {
    var augmented = _ensureAugmented(firstFragment);
    element.augmentedInternal = firstFragment.augmentedInternal;

    addFields(element.fields);
    addConstructors(element.constructors);
    addAccessors(element.accessors);
    addMethods(element.methods);
    _updatedAugmented(augmented, element);
  }
}

class AugmentedExtensionDeclarationBuilder
    extends AugmentedInstanceDeclarationBuilder<ExtensionElementImpl> {
  AugmentedExtensionDeclarationBuilder({
    required super.firstFragment,
  }) {
    addFields(firstFragment.fields);
    addAccessors(firstFragment.accessors);
    addMethods(firstFragment.methods);
  }

  void augment(ExtensionElementImpl element) {
    var augmented = _ensureAugmented(firstFragment);
    element.augmentedInternal = firstFragment.augmentedInternal;

    addFields(element.fields);
    addAccessors(element.accessors);
    addMethods(element.methods);
    _updatedAugmented(augmented, element);
  }
}

class AugmentedExtensionTypeDeclarationBuilder
    extends AugmentedInstanceDeclarationBuilder<ExtensionTypeElementImpl> {
  AugmentedExtensionTypeDeclarationBuilder({
    required super.firstFragment,
  }) {
    addFields(firstFragment.fields);
    addConstructors(firstFragment.constructors);
    addAccessors(firstFragment.accessors);
    addMethods(firstFragment.methods);
  }

  void augment(ExtensionTypeElementImpl element) {
    var augmented = _ensureAugmented(firstFragment);
    element.augmentedInternal = firstFragment.augmentedInternal;

    addFields(element.fields);
    addConstructors(element.constructors);
    addAccessors(element.accessors);
    addMethods(element.methods);
    _updatedAugmented(augmented, element);
  }
}

abstract class AugmentedInstanceDeclarationBuilder<
    F extends InstanceElementImpl> extends FragmentedElementBuilder<F> {
  final Map<String, FieldElementImpl> fields = {};
  final Map<String, ConstructorElementImpl> constructors = {};
  final Map<String, PropertyAccessorElementImpl> getters = {};
  final Map<String, PropertyAccessorElementImpl> setters = {};
  final Map<String, MethodElementImpl> methods = {};

  AugmentedInstanceDeclarationBuilder({
    required super.firstFragment,
  });

  void addAccessors(List<PropertyAccessorElementImpl> elements) {
    for (var element in elements) {
      var name = element.name;
      if (element.isGetter) {
        if (element.isAugmentation) {
          if (getters[name] case var target?) {
            target.augmentation = element;
            element.augmentationTargetAny = target;
            element.variable2 = target.variable2;
          } else {
            var target = _recoveryAugmentationTarget(name);
            element.augmentationTargetAny = target;
          }
        }
        getters[name] = element;
      } else {
        if (element.isAugmentation) {
          if (setters[name] case var target?) {
            target.augmentation = element;
            element.augmentationTargetAny = target;
            element.variable2 = target.variable2;
          } else {
            var target = _recoveryAugmentationTarget(name);
            element.augmentationTargetAny = target;
          }
        }
        setters[name] = element;
      }
    }
  }

  void addConstructors(List<ConstructorElementImpl> elements) {
    for (var element in elements) {
      var name = element.name;
      if (element.isAugmentation) {
        if (constructors[name] case var target?) {
          target.augmentation = element;
          element.augmentationTargetAny = target;
        } else {
          var target = _recoveryAugmentationTarget(name);
          element.augmentationTargetAny = target;
        }
      }
      constructors[name] = element;
    }
  }

  void addFields(List<FieldElementImpl> elements) {
    for (var element in elements) {
      var name = element.name;
      if (element.isAugmentation) {
        if (fields[name] case var target?) {
          target.augmentation = element;
          element.augmentationTargetAny = target;
        } else {
          var target = _recoveryAugmentationTarget(name);
          element.augmentationTargetAny = target;
        }
      }
      fields[name] = element;
    }
  }

  void addMethods(List<MethodElementImpl> elements) {
    for (var element in elements) {
      var name = element.name;
      if (element.isAugmentation) {
        if (methods[name] case var target?) {
          target.augmentation = element;
          element.augmentationTargetAny = target;
        } else {
          var target = _recoveryAugmentationTarget(name);
          element.augmentationTargetAny = target;
        }
      }
      methods[name] = element;
    }
  }

  AugmentedInstanceElementImpl _ensureAugmented(
    InstanceElementImpl augmentation,
  ) {
    var maybeAugmented = augmentation.augmented;
    if (maybeAugmented is AugmentedInstanceElementImpl) {
      return maybeAugmented;
    }

    maybeAugmented as NotAugmentedInstanceElementImpl;
    var declaration = maybeAugmented.declaration;
    var augmented = maybeAugmented.toAugmented();

    augmented.fields.addAll(declaration.fields.notAugmented);
    augmented.accessors.addAll(declaration.accessors.notAugmented);
    augmented.methods.addAll(declaration.methods.notAugmented);

    if (augmented is AugmentedInterfaceElementImpl) {
      if (declaration is InterfaceElementImpl) {
        augmented.mixins.addAll(declaration.mixins);
        augmented.interfaces.addAll(declaration.interfaces);
        augmented.constructors.addAll(declaration.constructors.notAugmented);
      }
    }

    if (augmented is AugmentedMixinElementImpl) {
      if (declaration is MixinElementImpl) {
        augmented.superclassConstraints.addAll(
          declaration.superclassConstraints,
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
    var declaration = augmented.declaration;
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

class AugmentedMixinDeclarationBuilder
    extends AugmentedInstanceDeclarationBuilder<MixinElementImpl> {
  AugmentedMixinDeclarationBuilder({
    required super.firstFragment,
  }) {
    addFields(firstFragment.fields);
    addAccessors(firstFragment.accessors);
    addMethods(firstFragment.methods);
  }

  void augment(MixinElementImpl element) {
    var augmented = _ensureAugmented(firstFragment);
    element.augmentedInternal = firstFragment.augmentedInternal;

    addFields(element.fields);
    addAccessors(element.accessors);
    addMethods(element.methods);
    _updatedAugmented(augmented, element);
  }
}

class AugmentedTopVariablesBuilder {
  /// This map is shared with [LibraryBuilder].
  final Map<String, ElementImpl> augmentationTargets;

  final Map<String, TopLevelVariableElementImpl> variables = {};
  final Map<String, PropertyAccessorElementImpl> accessors = {};

  AugmentedTopVariablesBuilder(this.augmentationTargets);

  void addAccessor(PropertyAccessorElementImpl element) {
    var name = element.name;
    if (element.isAugmentation) {
      ElementImpl? target = accessors[name];
      // Recovery.
      if (target == null) {
        if (name.removeSuffix('=') case var getterName?) {
          target ??= accessors[getterName];
          target ??= augmentationTargets[getterName];
        } else {
          target ??= accessors['$name='];
          target ??= augmentationTargets[name];
        }
      }

      if (target is PropertyAccessorElementImpl &&
          target.isGetter == element.isGetter) {
        target.augmentation = element;
        element.augmentationTargetAny = target;
        element.variable2 = target.variable2;
      } else {
        element.augmentationTargetAny = target;
      }
    }
    accessors[name] = element;
  }

  void addVariable(TopLevelVariableElementImpl element) {
    var name = element.name;
    if (element.isAugmentation) {
      ElementImpl? target = variables[name];
      // Recovery.
      target ??= accessors[name];
      target ??= accessors['$name='];
      target ??= augmentationTargets[name];

      element.augmentationTargetAny = target;
      if (target is TopLevelVariableElementImpl) {
        target.augmentation = element;
      }
    }
    variables[name] = element;

    if (element.getter case var getter?) {
      addAccessor(getter);
    }
    if (element.setter case var setter?) {
      addAccessor(setter);
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
