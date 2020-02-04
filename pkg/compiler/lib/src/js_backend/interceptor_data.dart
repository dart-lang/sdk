// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.interceptor_data;

import '../common/names.dart' show Identifiers;
import '../common_elements.dart'
    show CommonElements, KCommonElements, KElementEnvironment;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../js/js.dart' as jsAst;
import '../serialization/serialization.dart';
import '../universe/class_set.dart';
import '../universe/selector.dart';
import '../world.dart' show JClosedWorld;
import 'namer.dart' show ModularNamer, suffixForGetInterceptor;
import 'native_data.dart';

abstract class InterceptorData {
  /// Deserializes a [InterceptorData] object from [source].
  factory InterceptorData.readFromDataSource(
      DataSource source,
      NativeData nativeData,
      CommonElements commonElements) = InterceptorDataImpl.readFromDataSource;

  /// Serializes this [InterceptorData] to [sink].
  void writeToDataSink(DataSink sink);

  /// Returns `true` if [cls] is an intercepted class.
  bool isInterceptedClass(ClassEntity element);

  bool isInterceptedMethod(MemberEntity element);
  bool fieldHasInterceptedGetter(FieldEntity element);
  bool fieldHasInterceptedSetter(FieldEntity element);
  bool isInterceptedName(String name);
  bool isInterceptedSelector(Selector selector);

  /// Returns `true` iff [selector] matches an element defined in a class mixed
  /// into an intercepted class.
  ///
  /// These selectors are not eligible for the 'dummy explicit receiver'
  /// optimization.
  bool isInterceptedMixinSelector(
      Selector selector, AbstractValue mask, JClosedWorld closedWorld);

  /// Set of classes whose methods are intercepted.
  Iterable<ClassEntity> get interceptedClasses;
  bool isMixedIntoInterceptedClass(ClassEntity element);

  /// Returns a set of interceptor classes that contain a member named [name]
  ///
  /// Returns an empty set if there is no class. Do not modify the returned set.
  Set<ClassEntity> getInterceptedClassesOn(
      String name, JClosedWorld closedWorld);

  /// Whether the compiler can use the native `instanceof` check to test for
  /// instances of [type]. This is true for types that are not used as mixins or
  /// interfaces.
  bool mayGenerateInstanceofCheck(DartType type, JClosedWorld closedWorld);
}

abstract class InterceptorDataBuilder {
  void addInterceptors(ClassEntity cls);
  void addInterceptorsForNativeClassMembers(ClassEntity cls);
  InterceptorData close();
}

class InterceptorDataImpl implements InterceptorData {
  /// Tag used for identifying serialized [InterceptorData] objects in a
  /// debugging data stream.
  static const String tag = 'interceptor-data';

  final NativeBasicData _nativeData;
  final CommonElements _commonElements;

  /// The members of instantiated interceptor classes: maps a member name to the
  /// list of members that have that name. This map is used by the codegen to
  /// know whether a send must be intercepted or not.
  final Map<String, Set<MemberEntity>> interceptedMembers;

  @override
  final Set<ClassEntity> interceptedClasses;

  /// Set of classes used as mixins on intercepted (native and primitive)
  /// classes. Methods on these classes might also be mixed in to regular Dart
  /// (unintercepted) classes.
  final Set<ClassEntity> classesMixedIntoInterceptedClasses;

  /// The members of mixin classes that are mixed into an instantiated
  /// interceptor class.  This is a cached subset of [_interceptedElements].
  ///
  /// Mixin methods are not specialized for the class they are mixed into.
  /// Methods mixed into intercepted classes thus always make use of the
  /// explicit receiver argument, even when mixed into non-interceptor classes.
  ///
  /// These members must be invoked with a correct explicit receiver even when
  /// the receiver is not an intercepted class.
  final Map<String, Set<MemberEntity>> _interceptedMixinElements =
      new Map<String, Set<MemberEntity>>();

  final Map<String, Set<ClassEntity>> _interceptedClassesCache =
      new Map<String, Set<ClassEntity>>();

  final Set<ClassEntity> _noClasses = new Set<ClassEntity>();

  InterceptorDataImpl(
      this._nativeData,
      this._commonElements,
      this.interceptedMembers,
      this.interceptedClasses,
      this.classesMixedIntoInterceptedClasses);

  factory InterceptorDataImpl.readFromDataSource(
      DataSource source, NativeData nativeData, CommonElements commonElements) {
    source.begin(tag);
    int interceptedMembersCount = source.readInt();
    Map<String, Set<MemberEntity>> interceptedMembers = {};
    for (int i = 0; i < interceptedMembersCount; i++) {
      String name = source.readString();
      Set<MemberEntity> members = source.readMembers().toSet();
      interceptedMembers[name] = members;
    }
    Set<ClassEntity> interceptedClasses = source.readClasses().toSet();
    Set<ClassEntity> classesMixedIntoInterceptedClasses =
        source.readClasses().toSet();
    source.end(tag);
    return new InterceptorDataImpl(
        nativeData,
        commonElements,
        interceptedMembers,
        interceptedClasses,
        classesMixedIntoInterceptedClasses);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeInt(interceptedMembers.length);
    interceptedMembers.forEach((String name, Set<MemberEntity> members) {
      sink.writeString(name);
      sink.writeMembers(members);
    });
    sink.writeClasses(interceptedClasses);
    sink.writeClasses(classesMixedIntoInterceptedClasses);
    sink.end(tag);
  }

  @override
  bool isInterceptedMethod(MemberEntity element) {
    if (!element.isInstanceMember) return false;
    // TODO(johnniwinther): Avoid this hack.
    if (element is ConstructorBodyEntity) {
      return _nativeData.isNativeOrExtendsNative(element.enclosingClass);
    }
    return interceptedMembers[element.name] != null;
  }

  @override
  bool fieldHasInterceptedGetter(FieldEntity element) {
    return interceptedMembers[element.name] != null;
  }

  @override
  bool fieldHasInterceptedSetter(FieldEntity element) {
    return interceptedMembers[element.name] != null;
  }

  @override
  bool isInterceptedName(String name) {
    return interceptedMembers[name] != null;
  }

  @override
  bool isInterceptedSelector(Selector selector) {
    return interceptedMembers[selector.name] != null;
  }

  @override
  bool isInterceptedMixinSelector(
      Selector selector, AbstractValue mask, JClosedWorld closedWorld) {
    Set<MemberEntity> elements =
        _interceptedMixinElements.putIfAbsent(selector.name, () {
      Set<MemberEntity> elements = interceptedMembers[selector.name];
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
              closedWorld.abstractValueDomain
                  .isTargetingMember(mask, element, selector.memberName)
                  .isPotentiallyTrue);
    });
  }

  /// True if the given class is an internal class used for type inference
  /// and never exists at runtime.
  bool _isCompileTimeOnlyClass(ClassEntity class_) {
    return class_ == _commonElements.jsPositiveIntClass ||
        class_ == _commonElements.jsUInt32Class ||
        class_ == _commonElements.jsUInt31Class ||
        class_ == _commonElements.jsFixedArrayClass ||
        class_ == _commonElements.jsUnmodifiableArrayClass ||
        class_ == _commonElements.jsMutableArrayClass ||
        class_ == _commonElements.jsExtendableArrayClass;
  }

  /// Returns a set of interceptor classes that contain a member named [name]
  ///
  /// Returns an empty set if there is no class. Do not modify the returned set.
  @override
  Set<ClassEntity> getInterceptedClassesOn(
      String name, JClosedWorld closedWorld) {
    Set<MemberEntity> intercepted = interceptedMembers[name];
    if (intercepted == null) return _noClasses;
    return _interceptedClassesCache.putIfAbsent(name, () {
      // Populate the cache by running through all the elements and
      // determine if the given selector applies to them.
      Set<ClassEntity> result = new Set<ClassEntity>();
      for (MemberEntity element in intercepted) {
        ClassEntity classElement = element.enclosingClass;
        if (_isCompileTimeOnlyClass(classElement)) continue;
        if (_nativeData.isNativeOrExtendsNative(classElement) ||
            interceptedClasses.contains(classElement)) {
          result.add(classElement);
        }
        if (classesMixedIntoInterceptedClasses.contains(classElement)) {
          Set<ClassEntity> nativeSubclasses =
              nativeSubclassesOfMixin(classElement, closedWorld);
          if (nativeSubclasses != null) result.addAll(nativeSubclasses);
        }
      }
      return result;
    });
  }

  Set<ClassEntity> nativeSubclassesOfMixin(
      ClassEntity mixin, JClosedWorld closedWorld) {
    Iterable<ClassEntity> uses = closedWorld.mixinUsesOf(mixin);
    Set<ClassEntity> result = null;
    for (ClassEntity use in uses) {
      closedWorld.classHierarchy.forEachStrictSubclassOf(use,
          (ClassEntity subclass) {
        if (_nativeData.isNativeOrExtendsNative(subclass)) {
          if (result == null) result = new Set<ClassEntity>();
          result.add(subclass);
        }
        return IterationStep.CONTINUE;
      });
    }
    return result;
  }

  @override
  bool isInterceptedClass(ClassEntity element) {
    if (element == null) return false;
    if (_nativeData.isNativeOrExtendsNative(element)) return true;
    if (interceptedClasses.contains(element)) return true;
    if (classesMixedIntoInterceptedClasses.contains(element)) return true;
    return false;
  }

  @override
  bool isMixedIntoInterceptedClass(ClassEntity element) =>
      classesMixedIntoInterceptedClasses.contains(element);

  @override
  bool mayGenerateInstanceofCheck(DartType type, JClosedWorld closedWorld) {
    // We can use an instanceof check for raw types that have no subclass that
    // is mixed-in or in an implements clause.

    if (!closedWorld.dartTypes.treatAsRawType(type)) return false;
    if (type is FutureOrType) return false;
    InterfaceType interfaceType = type;
    ClassEntity classElement = interfaceType.element;
    if (isInterceptedClass(classElement)) return false;
    return closedWorld.classHierarchy.hasOnlySubclasses(classElement);
  }
}

class InterceptorDataBuilderImpl implements InterceptorDataBuilder {
  final NativeBasicData _nativeData;
  final KElementEnvironment _elementEnvironment;
  final KCommonElements _commonElements;

  /// The members of instantiated interceptor classes: maps a member name to the
  /// list of members that have that name. This map is used by the codegen to
  /// know whether a send must be intercepted or not.
  final Map<String, Set<MemberEntity>> _interceptedElements =
      <String, Set<MemberEntity>>{};

  /// Set of classes whose methods are intercepted.
  final Set<ClassEntity> _interceptedClasses = new Set<ClassEntity>();

  /// Set of classes used as mixins on intercepted (native and primitive)
  /// classes. Methods on these classes might also be mixed in to regular Dart
  /// (unintercepted) classes.
  final Set<ClassEntity> _classesMixedIntoInterceptedClasses =
      new Set<ClassEntity>();

  InterceptorDataBuilderImpl(
      this._nativeData, this._elementEnvironment, this._commonElements);

  @override
  InterceptorData close() {
    return new InterceptorDataImpl(
        _nativeData,
        _commonElements,
        _interceptedElements,
        _interceptedClasses,
        _classesMixedIntoInterceptedClasses);
  }

  @override
  void addInterceptorsForNativeClassMembers(ClassEntity cls) {
    _elementEnvironment.forEachClassMember(cls,
        (ClassEntity cls, MemberEntity member) {
      if (member.name == Identifiers.call) return;
      // All methods on [Object] are shadowed by [Interceptor].
      if (cls == _commonElements.objectClass) return;
      Set<MemberEntity> set =
          _interceptedElements[member.name] ??= new Set<MemberEntity>();
      set.add(member);
    });

    // Walk superclass chain to find mixins.
    _elementEnvironment.forEachMixin(cls, (ClassEntity mixin) {
      _classesMixedIntoInterceptedClasses.add(mixin);
    });
  }

  @override
  void addInterceptors(ClassEntity cls) {
    if (_interceptedClasses.add(cls)) {
      _elementEnvironment.forEachClassMember(cls,
          (ClassEntity cls, MemberEntity member) {
        // All methods on [Object] are shadowed by [Interceptor].
        if (cls == _commonElements.objectClass) return;
        Set<MemberEntity> set =
            _interceptedElements[member.name] ??= new Set<MemberEntity>();
        set.add(member);
      });
    }
    _interceptedClasses.add(_commonElements.jsInterceptorClass);
  }
}

class OneShotInterceptorData {
  final InterceptorData _interceptorData;
  final CommonElements _commonElements;
  final NativeData _nativeData;

  OneShotInterceptorData(
      this._interceptorData, this._commonElements, this._nativeData);

  Iterable<OneShotInterceptor> get oneShotInterceptors {
    List<OneShotInterceptor> interceptors = [];
    for (var map in _oneShotInterceptors.values) {
      interceptors.addAll(map.values);
    }
    return interceptors;
  }

  Map<Selector, Map<String, OneShotInterceptor>> _oneShotInterceptors = {};

  /// A set of specialized versions of the [getInterceptorMethod].
  ///
  /// Since [getInterceptorMethod] is a hot method at runtime, we're always
  /// specializing it based on the incoming type. The keys in the map are the
  /// names of these specialized versions. Note that the generic version that
  /// contains all possible type checks is also stored in this map.
  Iterable<SpecializedGetInterceptor> get specializedGetInterceptors =>
      _specializedGetInterceptors.values;

  Map<String, SpecializedGetInterceptor> _specializedGetInterceptors = {};

  jsAst.Name registerOneShotInterceptor(
      Selector selector, ModularNamer namer, JClosedWorld closedWorld) {
    selector = selector.toNormalized();
    Set<ClassEntity> classes =
        _interceptorData.getInterceptedClassesOn(selector.name, closedWorld);
    String key = suffixForGetInterceptor(_commonElements, _nativeData, classes);
    Map<String, OneShotInterceptor> interceptors =
        _oneShotInterceptors[selector] ??= {};
    OneShotInterceptor interceptor =
        interceptors[key] ??= new OneShotInterceptor(key, selector);
    interceptor.classes.addAll(classes);
    registerSpecializedGetInterceptor(classes, namer);
    return namer.nameForOneShotInterceptor(selector, classes);
  }

  void registerSpecializedGetInterceptor(
      Set<ClassEntity> classes, ModularNamer namer) {
    if (classes.contains(_commonElements.jsInterceptorClass)) {
      // We can't use a specialized [getInterceptorMethod], so we make
      // sure we emit the one with all checks.
      classes = _interceptorData.interceptedClasses;
    }
    String key = suffixForGetInterceptor(_commonElements, _nativeData, classes);
    SpecializedGetInterceptor interceptor =
        _specializedGetInterceptors[key] ??= new SpecializedGetInterceptor(key);
    interceptor.classes.addAll(classes);
  }
}

class OneShotInterceptor {
  final Selector selector;
  final String key;
  final Set<ClassEntity> classes = {};

  OneShotInterceptor(this.key, this.selector);

  @override
  String toString() =>
      'OneShotInterceptor(selector=$selector,key=$key,classes=$classes)';
}

class SpecializedGetInterceptor {
  final String key;
  final Set<ClassEntity> classes = {};

  SpecializedGetInterceptor(this.key);

  @override
  String toString() => 'SpecializedGetInterceptor(key=$key,classes=$classes)';
}
