// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.interceptor_data;

import '../common/names.dart' show Identifiers;
import '../core_types.dart' show CommonElements;
import '../elements/elements.dart';
import '../js/js.dart' as jsAst;
import '../types/types.dart' show TypeMask;
import '../universe/selector.dart';
import '../world.dart' show ClosedWorld;
import 'backend_helpers.dart';
import 'namer.dart';
import 'native_data.dart';

class InterceptorData {
  final NativeData _nativeData;
  final BackendHelpers _helpers;
  final CommonElements _commonElements;
  ClosedWorld _closedWorld;

  /// A collection of selectors that must have a one shot interceptor generated.
  final Map<jsAst.Name, Selector> oneShotInterceptors =
      <jsAst.Name, Selector>{};

  /// The members of instantiated interceptor classes: maps a member name to the
  /// list of members that have that name. This map is used by the codegen to
  /// know whether a send must be intercepted or not.
  final Map<String, Set<Element>> interceptedElements =
      <String, Set<Element>>{};

  /// The members of mixin classes that are mixed into an instantiated
  /// interceptor class.  This is a cached subset of [interceptedElements].
  ///
  /// Mixin methods are not specialized for the class they are mixed into.
  /// Methods mixed into intercepted classes thus always make use of the
  /// explicit receiver argument, even when mixed into non-interceptor classes.
  ///
  /// These members must be invoked with a correct explicit receiver even when
  /// the receiver is not an intercepted class.
  final Map<String, Set<Element>> interceptedMixinElements =
      new Map<String, Set<Element>>();

  /// A map of specialized versions of the [getInterceptorMethod].
  ///
  /// Since [getInterceptorMethod] is a hot method at runtime, we're always
  /// specializing it based on the incoming type. The keys in the map are the
  /// names of these specialized versions. Note that the generic version that
  /// contains all possible type checks is also stored in this map.
  final Map<jsAst.Name, Set<ClassElement>> specializedGetInterceptors =
      <jsAst.Name, Set<ClassElement>>{};

  /// Set of classes whose methods are intercepted.
  final Set<ClassElement> _interceptedClasses = new Set<ClassElement>();

  /// Set of classes used as mixins on intercepted (native and primitive)
  /// classes. Methods on these classes might also be mixed in to regular Dart
  /// (unintercepted) classes.
  final Set<ClassElement> classesMixedIntoInterceptedClasses =
      new Set<ClassElement>();

  InterceptorData(this._nativeData, this._helpers, this._commonElements);

  void onResolutionComplete(ClosedWorld closedWorld) {
    _closedWorld = closedWorld;
  }

  bool isInterceptedMethod(MemberElement element) {
    if (!element.isInstanceMember) return false;
    if (element.isGenerativeConstructorBody) {
      return _nativeData.isNativeOrExtendsNative(element.enclosingClass);
    }
    return interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedGetter(Element element) {
    assert(element.isField);
    return interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedSetter(Element element) {
    assert(element.isField);
    return interceptedElements[element.name] != null;
  }

  bool isInterceptedName(String name) {
    return interceptedElements[name] != null;
  }

  bool isInterceptedSelector(Selector selector) {
    return interceptedElements[selector.name] != null;
  }

  /// Returns `true` iff [selector] matches an element defined in a class mixed
  /// into an intercepted class.  These selectors are not eligible for the
  /// 'dummy explicit receiver' optimization.
  bool isInterceptedMixinSelector(Selector selector, TypeMask mask) {
    Set<Element> elements =
        interceptedMixinElements.putIfAbsent(selector.name, () {
      Set<Element> elements = interceptedElements[selector.name];
      if (elements == null) return null;
      return elements
          .where((element) => classesMixedIntoInterceptedClasses
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
  bool isCompileTimeOnlyClass(ClassElement class_) {
    return class_ == _helpers.jsPositiveIntClass ||
        class_ == _helpers.jsUInt32Class ||
        class_ == _helpers.jsUInt31Class ||
        class_ == _helpers.jsFixedArrayClass ||
        class_ == _helpers.jsUnmodifiableArrayClass ||
        class_ == _helpers.jsMutableArrayClass ||
        class_ == _helpers.jsExtendableArrayClass;
  }

  final Map<String, Set<ClassElement>> interceptedClassesCache =
      new Map<String, Set<ClassElement>>();
  final Set<ClassElement> _noClasses = new Set<ClassElement>();

  /// Returns a set of interceptor classes that contain a member named [name]
  ///
  /// Returns an empty set if there is no class. Do not modify the returned set.
  Set<ClassElement> getInterceptedClassesOn(String name) {
    Set<Element> intercepted = interceptedElements[name];
    if (intercepted == null) return _noClasses;
    return interceptedClassesCache.putIfAbsent(name, () {
      // Populate the cache by running through all the elements and
      // determine if the given selector applies to them.
      Set<ClassElement> result = new Set<ClassElement>();
      for (Element element in intercepted) {
        ClassElement classElement = element.enclosingClass;
        if (isCompileTimeOnlyClass(classElement)) continue;
        if (_nativeData.isNativeOrExtendsNative(classElement) ||
            interceptedClasses.contains(classElement)) {
          result.add(classElement);
        }
        if (classesMixedIntoInterceptedClasses.contains(classElement)) {
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
    if (classesMixedIntoInterceptedClasses.contains(element)) return true;
    return false;
  }

  jsAst.Name registerOneShotInterceptor(Selector selector, Namer namer) {
    Set<ClassElement> classes = getInterceptedClassesOn(selector.name);
    jsAst.Name name = namer.nameForGetOneShotInterceptor(selector, classes);
    if (!oneShotInterceptors.containsKey(name)) {
      registerSpecializedGetInterceptor(classes, namer);
      oneShotInterceptors[name] = selector;
    }
    return name;
  }

  void addInterceptorsForNativeClassMembers(ClassElement cls) {
    cls.forEachMember((ClassElement classElement, Element member) {
      if (member.name == Identifiers.call) {
        return;
      }
      if (member.isSynthesized) return;
      // All methods on [Object] are shadowed by [Interceptor].
      if (classElement == _commonElements.objectClass) return;
      Set<Element> set = interceptedElements.putIfAbsent(
          member.name, () => new Set<Element>());
      set.add(member);
    }, includeSuperAndInjectedMembers: true);

    // Walk superclass chain to find mixins.
    for (; cls != null; cls = cls.superclass) {
      if (cls.isMixinApplication) {
        MixinApplicationElement mixinApplication = cls;
        classesMixedIntoInterceptedClasses.add(mixinApplication.mixin);
      }
    }
  }

  void addInterceptors(ClassElement cls) {
    if (_interceptedClasses.add(cls)) {
      cls.forEachMember((ClassElement classElement, Element member) {
        // All methods on [Object] are shadowed by [Interceptor].
        if (classElement == _commonElements.objectClass) return;
        Set<Element> set = interceptedElements.putIfAbsent(
            member.name, () => new Set<Element>());
        set.add(member);
      }, includeSuperAndInjectedMembers: true);
    }
    _interceptedClasses.add(_helpers.jsInterceptorClass);
  }

  Set<ClassElement> get interceptedClasses {
    assert(_closedWorld != null);
    return _interceptedClasses;
  }

  void registerSpecializedGetInterceptor(
      Set<ClassElement> classes, Namer namer) {
    jsAst.Name name = namer.nameForGetInterceptor(classes);
    if (classes.contains(_helpers.jsInterceptorClass)) {
      // We can't use a specialized [getInterceptorMethod], so we make
      // sure we emit the one with all checks.
      specializedGetInterceptors[name] = interceptedClasses;
    } else {
      specializedGetInterceptors[name] = classes;
    }
  }
}
