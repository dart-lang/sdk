// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';

class ClassElementBuilder
    extends InstanceElementBuilder<ClassElementImpl, ClassFragmentImpl> {
  ClassElementBuilder({required super.element, required super.firstFragment});

  void addFragment(ClassFragmentImpl fragment) {
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
    extends InstanceElementBuilder<EnumElementImpl, EnumFragmentImpl> {
  EnumElementBuilder({required super.element, required super.firstFragment});

  void addFragment(EnumFragmentImpl fragment) {
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

class ExtensionElementBuilder
    extends
        InstanceElementBuilder<ExtensionElementImpl, ExtensionFragmentImpl> {
  ExtensionElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(ExtensionFragmentImpl fragment) {
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

class ExtensionTypeElementBuilder
    extends
        InstanceElementBuilder<
          ExtensionTypeElementImpl,
          ExtensionTypeFragmentImpl
        > {
  ExtensionTypeElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(ExtensionTypeFragmentImpl fragment) {
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
class FragmentedElementBuilder<E extends Element, F extends Fragment> {
  final E element;
  final F firstFragment;
  F lastFragment;

  FragmentedElementBuilder({required this.element, required this.firstFragment})
    : lastFragment = firstFragment;

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
  GetterElementBuilder({required super.element, required super.firstFragment});

  void addFragment(GetterFragmentImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}

abstract class InstanceElementBuilder<
  E extends InstanceElementImpl,
  F extends InstanceFragmentImpl
>
    extends FragmentedElementBuilder<E, F> {
  final Map<String, FieldFragmentImpl> fields = {};
  final Map<String, ConstructorFragmentImpl> constructors = {};
  final Map<String, GetterFragmentImpl> getters = {};
  final Map<String, SetterFragmentImpl> setters = {};
  final Map<String, MethodFragmentImpl> methods = {};

  final Map<String, FragmentImpl> fragmentGetters = {};
  final Map<String, FragmentImpl> fragmentSetters = {};
  final List<MethodElementImpl> methods2 = [];

  InstanceElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addAccessors(List<PropertyAccessorFragmentImpl> fragments) {
    for (var fragment in fragments) {
      var name = fragment.name2;
      if (name != null) {
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
  }

  void addConstructors(List<ConstructorFragmentImpl> fragments) {
    for (var fragment in fragments) {
      var name = fragment.name2;
      if (fragment.isAugmentation) {
        if (constructors[name] case var target?) {
          target.nextFragment = fragment;
          fragment.previousFragment = target;
        }
      }
      constructors[name] = fragment;
    }
  }

  void addFields(List<FieldFragmentImpl> fragments) {
    for (var fragment in fragments) {
      var name = fragment.name2;
      if (name != null) {
        if (fragment.isAugmentation) {
          if (fields[name] case var target?) {
            target.nextFragment = fragment;
            fragment.previousFragment = target;
          }
        }
        fields[name] = fragment;
      }
    }
  }

  void addMethods(List<MethodFragmentImpl> fragments) {
    for (var fragment in fragments) {
      var name = fragment.name2;
      if (name != null) {
        if (fragment.isAugmentation) {
          if (methods[name] case var target?) {
            target.nextFragment = fragment;
            fragment.previousFragment = target;
          }
        }
        methods[name] = fragment;
      }
    }
  }

  FragmentImpl? replaceGetter<T extends FragmentImpl>(T fragment) {
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
    // TODO(scheglov): restore eventually
    // var firstFragment = this.firstFragment;
    // var element = firstFragment.element;
    // if (element is MixinElementImpl2) {
    //   if (firstFragment is MixinFragmentImpl) {
    //     element.superclassConstraints.addAll(
    //       firstFragment.superclassConstraints,
    //     );
    //   }
    // }
  }
}

class MixinElementBuilder
    extends InstanceElementBuilder<MixinElementImpl, MixinFragmentImpl> {
  MixinElementBuilder({required super.element, required super.firstFragment});

  void addFragment(MixinFragmentImpl fragment) {
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
  SetterElementBuilder({required super.element, required super.firstFragment});

  void addFragment(SetterFragmentImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}

class TopLevelFunctionElementBuilder
    extends
        FragmentedElementBuilder<
          TopLevelFunctionElementImpl,
          TopLevelFunctionFragmentImpl
        > {
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

class TopLevelVariableElementBuilder
    extends
        FragmentedElementBuilder<
          TopLevelVariableElementImpl,
          TopLevelVariableFragmentImpl
        > {
  TopLevelVariableElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(TopLevelVariableFragmentImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}

class TypeAliasElementBuilder
    extends
        FragmentedElementBuilder<TypeAliasElementImpl, TypeAliasFragmentImpl> {
  TypeAliasElementBuilder({
    required super.element,
    required super.firstFragment,
  });

  void addFragment(TypeAliasFragmentImpl fragment) {
    if (!identical(fragment, firstFragment)) {
      lastFragment.nextFragment = fragment;
      lastFragment = fragment;
      fragment.element = element;
    }
  }
}
