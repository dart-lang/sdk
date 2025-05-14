// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/element/element.dart';

class ClassElementBuilder
    extends InstanceElementBuilder<ClassElementImpl2, ClassElementImpl> {
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
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
    }
  }
}

class EnumElementBuilder
    extends InstanceElementBuilder<EnumElementImpl2, EnumElementImpl> {
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
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
    }
  }
}

class ExtensionElementBuilder extends InstanceElementBuilder<
    ExtensionElementImpl2, ExtensionElementImpl> {
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
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
    }
  }
}

class ExtensionTypeElementBuilder extends InstanceElementBuilder<
    ExtensionTypeElementImpl2, ExtensionTypeElementImpl> {
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
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
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
  void setPreviousFor(Object fragment) {}
}

class GetterElementBuilder
    extends FragmentedElementBuilder<GetterElementImpl, GetterFragmentImpl> {
  GetterElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(GetterFragmentImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}

abstract class InstanceElementBuilder<E extends InstanceElementImpl2,
    F extends InstanceElementImpl> extends FragmentedElementBuilder<E, F> {
  final Map<String, FieldElementImpl> fields = {};
  final Map<String, ConstructorElementImpl> constructors = {};
  final Map<String, GetterFragmentImpl> getters = {};
  final Map<String, SetterFragmentImpl> setters = {};
  final Map<String, MethodElementImpl> methods = {};

  final Map<String, ElementImpl> fragmentGetters = {};
  final Map<String, ElementImpl> fragmentSetters = {};
  final List<MethodElementImpl2> methods2 = [];

  InstanceElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addAccessors(List<PropertyAccessorElementImpl> fragments) {
    for (var fragment in fragments) {
      var name = fragment.name;
      switch (fragment) {
        case GetterFragmentImpl():
          if (fragment.isAugmentation) {
            if (getters[name] case var target?) {
              target.nextFragment = fragment;
              fragment.previousFragment = target;
            }
          }
          getters[name] = fragment;
        case SetterFragmentImpl():
          if (fragment.isAugmentation) {
            if (setters[name] case var target?) {
              target.nextFragment = fragment;
              fragment.previousFragment = target;
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
          target.nextFragment = fragment;
          fragment.previousFragment = target;
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
          target.nextFragment = fragment;
          fragment.previousFragment = target;
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
          target.nextFragment = fragment;
          fragment.previousFragment = target;
        }
      }
      methods[name] = fragment;
    }
  }

  ElementImpl? replaceGetter<T extends ElementImpl>(T fragment) {
    var name = (fragment as Fragment).name2;
    if (name == null) {
      return null;
    }

    var lastFragment = fragmentGetters[name];
    lastFragment ??= fragmentSetters[name];

    fragmentGetters[name] = fragment;
    fragmentSetters.remove(name);

    return lastFragment;
  }

  void _addFirstFragment() {
    var firstFragment = this.firstFragment;
    var element = firstFragment.element;

    if (element is MixinElementImpl2) {
      if (firstFragment is MixinElementImpl) {
        element.superclassConstraints.addAll(
          firstFragment.superclassConstraints,
        );
      }
    }
  }
}

class MixinElementBuilder
    extends InstanceElementBuilder<MixinElementImpl2, MixinElementImpl> {
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
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;

      fragment.augmentedInternal = element;
    }
  }
}

class SetterElementBuilder
    extends FragmentedElementBuilder<SetterElementImpl, SetterFragmentImpl> {
  SetterElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(SetterFragmentImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}

class TopLevelFunctionElementBuilder extends FragmentedElementBuilder<
    TopLevelFunctionElementImpl, TopLevelFunctionFragmentImpl> {
  TopLevelFunctionElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(TopLevelFunctionFragmentImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.nextFragment = fragment;
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
      lastFragment.nextFragment = fragment;
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
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}
