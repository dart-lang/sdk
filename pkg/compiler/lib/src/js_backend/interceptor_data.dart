// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.interceptor_data;

import '../common/names.dart' show Identifiers;
import '../common_elements.dart' show CommonElements;
import '../elements/elements.dart';
import '../js/js.dart' as jsAst;
import '../types/types.dart' show TypeMask;
import '../universe/selector.dart';
import '../world.dart' show ClosedWorld;
import 'backend_helpers.dart';
import 'namer.dart';
import 'native_data.dart';

abstract class InterceptorData {
  /// Returns `true` if [cls] is an intercepted class.
  // TODO(johnniwinther): Rename this to `isInterceptedClass`.
  bool isInterceptorClass(ClassElement element);

  bool isInterceptedMethod(MemberElement element);
  bool fieldHasInterceptedGetter(Element element);
  bool fieldHasInterceptedSetter(Element element);
  bool isInterceptedName(String name);
  bool isInterceptedSelector(Selector selector);
  bool isInterceptedMixinSelector(Selector selector, TypeMask mask);
  Iterable<ClassElement> get interceptedClasses;
  bool isMixedIntoInterceptedClass(ClassElement element);

  /// Returns a set of interceptor classes that contain a member named [name]
  ///
  /// Returns an empty set if there is no class. Do not modify the returned set.
  Set<ClassElement> getInterceptedClassesOn(String name);
}

abstract class InterceptorDataBuilder {
  void addInterceptors(ClassElement cls);
  void addInterceptorsForNativeClassMembers(ClassElement cls);
  InterceptorData onResolutionComplete(ClosedWorld closedWorld);
}

class InterceptorDataImpl implements InterceptorData {
  final NativeData _nativeData;
  final BackendHelpers _helpers;
  final ClosedWorld _closedWorld;

  /// The members of instantiated interceptor classes: maps a member name to the
  /// list of members that have that name. This map is used by the codegen to
  /// know whether a send must be intercepted or not.
  final Map<String, Set<Element>> _interceptedElements;

  /// Set of classes whose methods are intercepted.
  final Set<ClassElement> _interceptedClasses;

  /// Set of classes used as mixins on intercepted (native and primitive)
  /// classes. Methods on these classes might also be mixed in to regular Dart
  /// (unintercepted) classes.
  final Set<ClassElement> _classesMixedIntoInterceptedClasses;

  /// The members of mixin classes that are mixed into an instantiated
  /// interceptor class.  This is a cached subset of [_interceptedElements].
  ///
  /// Mixin methods are not specialized for the class they are mixed into.
  /// Methods mixed into intercepted classes thus always make use of the
  /// explicit receiver argument, even when mixed into non-interceptor classes.
  ///
  /// These members must be invoked with a correct explicit receiver even when
  /// the receiver is not an intercepted class.
  final Map<String, Set<Element>> _interceptedMixinElements =
      new Map<String, Set<Element>>();

  final Map<String, Set<ClassElement>> _interceptedClassesCache =
      new Map<String, Set<ClassElement>>();

  final Set<ClassElement> _noClasses = new Set<ClassElement>();

  InterceptorDataImpl(
      this._nativeData,
      this._helpers,
      this._closedWorld,
      this._interceptedElements,
      this._interceptedClasses,
      this._classesMixedIntoInterceptedClasses);

  bool isInterceptedMethod(MemberElement element) {
    if (!element.isInstanceMember) return false;
    if (element.isGenerativeConstructorBody) {
      return _nativeData.isNativeOrExtendsNative(element.enclosingClass);
    }
    return _interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedGetter(Element element) {
    assert(element.isField);
    return _interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedSetter(Element element) {
    assert(element.isField);
    return _interceptedElements[element.name] != null;
  }

  bool isInterceptedName(String name) {
    return _interceptedElements[name] != null;
  }

  bool isInterceptedSelector(Selector selector) {
    return _interceptedElements[selector.name] != null;
  }

  /// Returns `true` iff [selector] matches an element defined in a class mixed
  /// into an intercepted class.  These selectors are not eligible for the
  /// 'dummy explicit receiver' optimization.
  bool isInterceptedMixinSelector(Selector selector, TypeMask mask) {
    Set<Element> elements =
        _interceptedMixinElements.putIfAbsent(selector.name, () {
      Set<Element> elements = _interceptedElements[selector.name];
      if (elements == null) return null;
      return elements
          .where((element) => _classesMixedIntoInterceptedClasses
              .contains(element.enclosingClass))
          .toSet();
    });

    if (elements == null) return false;
    if (elements.isEmpty) return false;
    return elements.any((element) {
      return selector.applies(element) &&
          (mask == null ||
              mask.canHit(element as MemberElement, selector, _closedWorld));
    });
  }

  /// True if the given class is an internal class used for type inference
  /// and never exists at runtime.
  bool _isCompileTimeOnlyClass(ClassElement class_) {
    return class_ == _helpers.jsPositiveIntClass ||
        class_ == _helpers.jsUInt32Class ||
        class_ == _helpers.jsUInt31Class ||
        class_ == _helpers.jsFixedArrayClass ||
        class_ == _helpers.jsUnmodifiableArrayClass ||
        class_ == _helpers.jsMutableArrayClass ||
        class_ == _helpers.jsExtendableArrayClass;
  }

  /// Returns a set of interceptor classes that contain a member named [name]
  ///
  /// Returns an empty set if there is no class. Do not modify the returned set.
  Set<ClassElement> getInterceptedClassesOn(String name) {
    Set<Element> intercepted = _interceptedElements[name];
    if (intercepted == null) return _noClasses;
    return _interceptedClassesCache.putIfAbsent(name, () {
      // Populate the cache by running through all the elements and
      // determine if the given selector applies to them.
      Set<ClassElement> result = new Set<ClassElement>();
      for (Element element in intercepted) {
        ClassElement classElement = element.enclosingClass;
        if (_isCompileTimeOnlyClass(classElement)) continue;
        if (_nativeData.isNativeOrExtendsNative(classElement) ||
            interceptedClasses.contains(classElement)) {
          result.add(classElement);
        }
        if (_classesMixedIntoInterceptedClasses.contains(classElement)) {
          Set<ClassElement> nativeSubclasses =
              nativeSubclassesOfMixin(classElement);
          if (nativeSubclasses != null) result.addAll(nativeSubclasses);
        }
      }
      return result;
    });
  }

  Set<ClassElement> nativeSubclassesOfMixin(ClassElement mixin) {
    Iterable<MixinApplicationElement> uses = _closedWorld.mixinUsesOf(mixin);
    Set<ClassElement> result = null;
    for (MixinApplicationElement use in uses) {
      _closedWorld.forEachStrictSubclassOf(use, (ClassElement subclass) {
        if (_nativeData.isNativeOrExtendsNative(subclass)) {
          if (result == null) result = new Set<ClassElement>();
          result.add(subclass);
        }
      });
    }
    return result;
  }

  bool isInterceptorClass(ClassElement element) {
    if (element == null) return false;
    if (_nativeData.isNativeOrExtendsNative(element)) return true;
    if (interceptedClasses.contains(element)) return true;
    if (_classesMixedIntoInterceptedClasses.contains(element)) return true;
    return false;
  }

  bool isMixedIntoInterceptedClass(ClassElement element) =>
      _classesMixedIntoInterceptedClasses.contains(element);

  Iterable<ClassElement> get interceptedClasses => _interceptedClasses;
}

class InterceptorDataBuilderImpl implements InterceptorDataBuilder {
  final NativeData _nativeData;
  final BackendHelpers _helpers;
  final CommonElements _commonElements;

  /// The members of instantiated interceptor classes: maps a member name to the
  /// list of members that have that name. This map is used by the codegen to
  /// know whether a send must be intercepted or not.
  final Map<String, Set<Element>> _interceptedElements =
      <String, Set<Element>>{};

  /// Set of classes whose methods are intercepted.
  final Set<ClassElement> _interceptedClasses = new Set<ClassElement>();

  /// Set of classes used as mixins on intercepted (native and primitive)
  /// classes. Methods on these classes might also be mixed in to regular Dart
  /// (unintercepted) classes.
  final Set<ClassElement> _classesMixedIntoInterceptedClasses =
      new Set<ClassElement>();

  InterceptorDataBuilderImpl(
      this._nativeData, this._helpers, this._commonElements);

  InterceptorData onResolutionComplete(ClosedWorld closedWorld) {
    return new InterceptorDataImpl(
        _nativeData,
        _helpers,
        closedWorld,
        _interceptedElements,
        _interceptedClasses,
        _classesMixedIntoInterceptedClasses);
  }

  void addInterceptorsForNativeClassMembers(ClassElement cls) {
    cls.forEachMember((ClassElement classElement, Element member) {
      if (member.name == Identifiers.call) {
        return;
      }
      if (member.isSynthesized) return;
      // All methods on [Object] are shadowed by [Interceptor].
      if (classElement == _commonElements.objectClass) return;
      Set<Element> set = _interceptedElements.putIfAbsent(
          member.name, () => new Set<Element>());
      set.add(member);
    }, includeSuperAndInjectedMembers: true);

    // Walk superclass chain to find mixins.
    for (; cls != null; cls = cls.superclass) {
      if (cls.isMixinApplication) {
        MixinApplicationElement mixinApplication = cls;
        _classesMixedIntoInterceptedClasses.add(mixinApplication.mixin);
      }
    }
  }

  void addInterceptors(ClassElement cls) {
    if (_interceptedClasses.add(cls)) {
      cls.forEachMember((ClassElement classElement, Element member) {
        // All methods on [Object] are shadowed by [Interceptor].
        if (classElement == _commonElements.objectClass) return;
        Set<Element> set = _interceptedElements.putIfAbsent(
            member.name, () => new Set<Element>());
        set.add(member);
      }, includeSuperAndInjectedMembers: true);
    }
    _interceptedClasses.add(_helpers.jsInterceptorClass);
  }
}

class OneShotInterceptorData {
  final InterceptorData _interceptorData;
  final BackendHelpers _helpers;

  OneShotInterceptorData(this._interceptorData, this._helpers);

  /// A collection of selectors that must have a one shot interceptor generated.
  final Map<jsAst.Name, Selector> _oneShotInterceptors =
      <jsAst.Name, Selector>{};

  Selector getOneShotInterceptorSelector(jsAst.Name name) =>
      _oneShotInterceptors[name];

  Iterable<jsAst.Name> get oneShotInterceptorNames =>
      _oneShotInterceptors.keys.toList()..sort();

  /// A map of specialized versions of the [getInterceptorMethod].
  ///
  /// Since [getInterceptorMethod] is a hot method at runtime, we're always
  /// specializing it based on the incoming type. The keys in the map are the
  /// names of these specialized versions. Note that the generic version that
  /// contains all possible type checks is also stored in this map.
  final Map<jsAst.Name, Set<ClassElement>> _specializedGetInterceptors =
      <jsAst.Name, Set<ClassElement>>{};

  Iterable<jsAst.Name> get specializedGetInterceptorNames =>
      _specializedGetInterceptors.keys.toList()..sort();

  Set<ClassElement> getSpecializedGetInterceptorsFor(jsAst.Name name) =>
      _specializedGetInterceptors[name];

  jsAst.Name registerOneShotInterceptor(Selector selector, Namer namer) {
    Set<ClassElement> classes =
        _interceptorData.getInterceptedClassesOn(selector.name);
    jsAst.Name name = namer.nameForGetOneShotInterceptor(selector, classes);
    if (!_oneShotInterceptors.containsKey(name)) {
      registerSpecializedGetInterceptor(classes, namer);
      _oneShotInterceptors[name] = selector;
    }
    return name;
  }

  void registerSpecializedGetInterceptor(
      Set<ClassElement> classes, Namer namer) {
    jsAst.Name name = namer.nameForGetInterceptor(classes);
    if (classes.contains(_helpers.jsInterceptorClass)) {
      // We can't use a specialized [getInterceptorMethod], so we make
      // sure we emit the one with all checks.
      _specializedGetInterceptors[name] = _interceptorData.interceptedClasses;
    } else {
      _specializedGetInterceptors[name] = classes;
    }
  }
}
