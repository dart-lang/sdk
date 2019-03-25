// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.class_hierarchy;

import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'ast.dart';
import 'src/heap.dart';
import 'type_algebra.dart';

typedef HandleAmbiguousSupertypes = void Function(Class, Supertype, Supertype);

abstract class MixinInferrer {
  void infer(ClassHierarchy hierarchy, Class classNode);
}

/// Interface for answering various subclassing queries.
abstract class ClassHierarchy {
  factory ClassHierarchy(Component component,
      {HandleAmbiguousSupertypes onAmbiguousSupertypes,
      MixinInferrer mixinInferrer}) {
    onAmbiguousSupertypes ??= (Class cls, Supertype a, Supertype b) {
      // See https://github.com/dart-lang/sdk/issues/32091
      throw "$cls can't implement both $a and $b";
    };
    return new ClosedWorldClassHierarchy._internal(
        onAmbiguousSupertypes, mixinInferrer)
      .._initialize(component.libraries);
  }

  void set onAmbiguousSupertypes(
      HandleAmbiguousSupertypes onAmbiguousSupertypes);

  void set mixinInferrer(MixinInferrer mixinInferrer);

  /// Given the [unordered] classes, return them in such order that classes
  /// occur after their superclasses.  If some superclasses are not in
  /// [unordered], they are not included.
  Iterable<Class> getOrderedClasses(Iterable<Class> unordered);

  // Returns the instantition of each generic supertype implemented by this
  // class (e.g. getClassAsInstanceOf applied to all superclasses and
  // interfaces).
  List<Supertype> genericSupertypesOf(Class class_);

  /// Returns the least upper bound of two interface types, as defined by Dart
  /// 1.0.
  ///
  /// Given two interfaces I and J, let S_I be the set of superinterfaces of I,
  /// let S_J be the set of superinterfaces of J, and let
  /// S = (I union S_I) intersect (J union S_J).  Furthermore, we define
  /// S_n = {T | T in S and depth(T) = n} for any finite n where depth(T) is
  /// the number of steps in the longest inheritance path from T to Object.  Let
  /// q be the largest number such that S_q has cardinality one.  The least
  /// upper bound of I and J is the sole element of S_q.
  ///
  /// This is called the "legacy" least upper bound to distinguish it from the
  /// Dart 2 least upper bound, which has special behaviors in the case where
  /// one type is a subtype of the other, or where both types are based on the
  /// same class.
  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2);

  /// Returns the instantiation of [superclass] that is implemented by [class_],
  /// or `null` if [class_] does not implement [superclass] at all.
  Supertype getClassAsInstanceOf(Class class_, Class superclass);

  /// Returns the instantiation of [superclass] that is implemented by [type],
  /// or `null` if [type] does not implement [superclass] at all.
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass);

  /// Returns the instantiation of [superclass] that is implemented by [type],
  /// or `null` if [type] does not implement [superclass].  [superclass] must
  /// be a generic class.
  Supertype asInstantiationOf(Supertype type, Class superclass);

  /// Returns the instance member that would respond to a dynamic dispatch of
  /// [name] to an instance of [class_], or `null` if no such member exists.
  ///
  /// If [setter] is `false`, the name is dispatched as a getter or call,
  /// and will return a field, getter, method, or operator (or null).
  ///
  /// If [setter] is `true`, the name is dispatched as a setter, roughly
  /// corresponding to `name=` in the Dart specification, but note that the
  /// returned member will not have a name ending with `=`.  In this case,
  /// a non-final field or setter (or null) will be returned.
  ///
  /// If the class is abstract, abstract members are ignored and the dispatch
  /// is resolved if the class was not abstract.
  Member getDispatchTarget(Class class_, Name name, {bool setter: false});

  /// Returns the list of potential targets of dynamic dispatch to an instance
  /// of [class_].
  ///
  /// If [setters] is `false`, only potential targets of a getter or call
  /// dispatch are returned.  If [setters] is `true`, only potential targets
  /// of a setter dispatch are returned.
  ///
  /// See [getDispatchTarget] for more details.
  ///
  /// The returned list should not be modified.
  List<Member> getDispatchTargets(Class class_, {bool setters: false});

  /// Returns the possibly abstract interface member of [class_] with the given
  /// [name].
  ///
  /// If [setter] is `false`, only fields, methods, and getters with that name
  /// will be found.  If [setter] is `true`, only non-final fields and setters
  /// will be found.
  ///
  /// If multiple members with that name are inherited and not overridden, the
  /// member from the first declared supertype is returned.
  Member getInterfaceMember(Class class_, Name name, {bool setter: false});

  /// Returns the list of members denoting the interface for [class_], which
  /// may include abstract members.
  ///
  /// The list may contain multiple members with a given name.  This happens
  /// when members are inherited through different supertypes and not overridden
  /// in the class.
  ///
  /// Also see [getInterfaceMember].
  List<Member> getInterfaceMembers(Class class_, {bool setters: false});

  /// Returns the list of members declared in [class_], including abstract
  /// members.
  ///
  /// Members are sorted by name so that they may be efficiently compared across
  /// classes.
  List<Member> getDeclaredMembers(Class class_, {bool setters: false});

  /// True if [subclass] inherits from [superclass] though zero or more
  /// `extends` relationships.
  bool isSubclassOf(Class subclass, Class superclass);

  /// True if [subtype] inherits from [superclass] though zero or more
  /// `extends`, `with`, and `implements` relationships.
  bool isSubtypeOf(Class subtype, Class superclass);

  /// True if the given class is used as the right-hand operand to a
  /// mixin application (i.e. [Class.mixedInType]).
  bool isUsedAsMixin(Class class_);

  /// Invokes [callback] for every member declared in or inherited by [class_]
  /// that overrides or implements a member in a supertype of [class_]
  /// (or in rare cases, overrides a member declared in [class_]).
  ///
  /// We use the term "inheritable" for members that are candidates for
  /// inheritance but may have been overridden.  The "declared" members of a
  /// mixin application are those declared in the mixed-in type. The callback is
  /// invoked in the following cases:
  ///
  /// 1. A member declared in the class overrides a member inheritable through
  /// one of the supertypes of the class.
  ///
  /// 2. A non-abstract member is inherited from a superclass, and in the
  /// context of this class, it overrides an abstract member inheritable through
  /// one of its superinterfaces.
  ///
  /// 3. A non-abstract member is inherited from a superclass, and it overrides
  /// an abstract member declared in this class.
  ///
  /// This method will not report that a member overrides itself. A given pair
  /// may be reported multiple times when there are multiple inheritance paths
  /// to the overridden member.
  ///
  /// It is possible for two methods to override one another in both directions.
  ///
  /// By default getters and setters are overridden separately.  The [isSetter]
  /// callback parameter determines which type of access is being overridden.
  void forEachOverridePair(Class class_,
      callback(Member declaredMember, Member interfaceMember, bool isSetter));

  /// This method is invoked by the client after a change: removal, addition,
  /// or modification of classes (via libraries).
  ///
  /// For modified classes specify a class as both removed and added: Some of
  /// the information that this hierarchy might have cached, is not valid
  /// anymore.
  ///
  /// Note, that it is the clients responsibility to mark all subclasses as
  /// changed too.
  ClassHierarchy applyTreeChanges(Iterable<Library> removedLibraries,
      Iterable<Library> ensureKnownLibraries,
      {Component reissueAmbiguousSupertypesFor});

  /// This method is invoked by the client after a member change on classes:
  /// Some of the information that this hierarchy might have cached,
  /// is not valid anymore.
  /// Note, that it is the clients responsibility to mark all subclasses as
  /// changed too, or - if [findDescendants] is true, the ClassHierarchy will
  /// spend the time to find them for the caller.
  ClassHierarchy applyMemberChanges(Iterable<Class> classes,
      {bool findDescendants: false});

  /// Merges two sorted lists.
  ///
  /// If a given member occurs in both lists, the merge will attempt to exclude
  /// the duplicate member, but is not strictly guaranteed to do so.
  ///
  /// The sort has the following stability properties:
  ///
  /// - If both x and y came from the same input list, and x preceded y in the
  ///   input list, x will precede y in the output list.  This holds even if x
  ///   and y have matching names.
  ///
  /// - If m is a contiguous subsequence of the output list containing at least
  ///   one element from each input list, and all elements of m have matching
  ///   names, then the elements of m from [first] will precede the elements of
  ///   m from [second].
  static List<Member> mergeSortedLists(
      List<Member> first, List<Member> second) {
    if (first.isEmpty) return second;
    if (second.isEmpty) return first;
    List<Member> result = <Member>[]..length = first.length + second.length;
    int storeIndex = 0;
    int i = 0, j = 0;
    while (i < first.length && j < second.length) {
      Member firstMember = first[i];
      Member secondMember = second[j];
      int compare = ClassHierarchy.compareMembers(firstMember, secondMember);
      if (compare <= 0) {
        result[storeIndex++] = firstMember;
        ++i;
        // If the same member occurs in both lists, skip the duplicate.
        if (identical(firstMember, secondMember)) {
          ++j;
        }
      } else {
        result[storeIndex++] = secondMember;
        ++j;
      }
    }
    while (i < first.length) {
      result[storeIndex++] = first[i++];
    }
    while (j < second.length) {
      result[storeIndex++] = second[j++];
    }
    result.length = storeIndex;
    return result;
  }

  /// Compares members by name, using the same sort order as
  /// [getDeclaredMembers] and [getInterfaceMembers].
  static int compareMembers(Member first, Member second) {
    return _compareNames(first.name, second.name);
  }

  /// Compares names, using the same sort order as [getDeclaredMembers] and
  /// [getInterfaceMembers].
  ///
  /// This is an arbitrary as-fast-as-possible sorting criterion.
  static int _compareNames(Name firstName, Name secondName) {
    int firstHash = firstName.hashCode;
    int secondHash = secondName.hashCode;
    if (firstHash != secondHash) return firstHash - secondHash;
    String firstString = firstName.name;
    String secondString = secondName.name;
    int firstLength = firstString.length;
    int secondLength = secondString.length;
    if (firstLength != secondLength) {
      return firstLength - secondLength;
    }
    Library firstLibrary = firstName.library;
    Library secondLibrary = secondName.library;
    if (firstLibrary != secondLibrary) {
      if (firstLibrary == null) return -1;
      if (secondLibrary == null) return 1;
      return firstLibrary.compareTo(secondLibrary);
    }
    for (int i = 0; i < firstLength; ++i) {
      int firstUnit = firstString.codeUnitAt(i);
      int secondUnit = secondString.codeUnitAt(i);
      int delta = firstUnit - secondUnit;
      if (delta != 0) return delta;
    }
    return 0;
  }

  /// Returns the member with the given name, or `null` if no member has the
  /// name.  In case the list contains multiple members with the given name,
  /// the one that occurs first in the list is returned.
  ///
  /// The list is assumed to be sorted according to [compareMembers].
  static Member findMemberByName(List<Member> members, Name name) {
    int low = 0, high = members.length - 1;
    while (low <= high) {
      int mid = low + ((high - low) >> 1);
      Member pivot = members[mid];
      int comparison = _compareNames(name, pivot.name);
      if (comparison < 0) {
        high = mid - 1;
      } else if (comparison > 0) {
        low = mid + 1;
      } else if (high != mid) {
        // Ensure we find the first element of the given name.
        high = mid;
      } else {
        return pivot;
      }
    }
    return null;
  }
}

abstract class ClassHierarchySubtypes {
  /// Returns the subtypes of [class_] as an interval list.
  ClassSet getSubtypesOf(Class class_);

  /// Returns the single concrete target for invocation of the given interface
  /// target, or `null` if it could not be resolved or there are multiple
  /// possible targets.
  Member getSingleTargetForInterfaceInvocation(Member interfaceTarget,
      {bool setter: false});
}

class _ClassInfoSubtype {
  final _ClassInfo classInfo;
  int topDownIndex = -1;

  /// Top-down indices of all subclasses of this class, represented as
  /// interleaved begin/end interval end points.
  Uint32List subtypeIntervalList;

  _ClassInfoSubtype(this.classInfo);
}

class _ClosedWorldClassHierarchySubtypes implements ClassHierarchySubtypes {
  final ClosedWorldClassHierarchy hierarchy;
  final List<Class> _classesByTopDownIndex;
  final Map<Class, _ClassInfoSubtype> _infoFor = <Class, _ClassInfoSubtype>{};
  bool invalidated = false;

  _ClosedWorldClassHierarchySubtypes(this.hierarchy)
      : _classesByTopDownIndex = new List<Class>(hierarchy._infoFor.length) {
    if (hierarchy._infoFor.isNotEmpty) {
      for (Class class_ in hierarchy._infoFor.keys) {
        _infoFor[class_] = new _ClassInfoSubtype(hierarchy._infoFor[class_]);
      }

      _topDownSortVisit(_infoFor[hierarchy._infoFor.keys.first]);
    }
  }

  /// Downwards traversal of the class hierarchy that orders classes so local
  /// hierarchies have contiguous indices.
  int _topDownSortIndex = 0;
  void _topDownSortVisit(_ClassInfoSubtype subInfo) {
    if (subInfo.topDownIndex != -1) return;
    int index = _topDownSortIndex++;
    subInfo.topDownIndex = index;
    _classesByTopDownIndex[index] = subInfo.classInfo.classNode;
    var subtypeSetBuilder = new _IntervalListBuilder()..addSingleton(index);
    for (_ClassInfo subtype in subInfo.classInfo.directExtenders) {
      _ClassInfoSubtype subtypeInfo = _infoFor[subtype.classNode];
      _topDownSortVisit(subtypeInfo);
      subtypeSetBuilder.addIntervalList(subtypeInfo.subtypeIntervalList);
    }
    for (_ClassInfo subtype in subInfo.classInfo.directMixers) {
      _ClassInfoSubtype subtypeInfo = _infoFor[subtype.classNode];
      _topDownSortVisit(subtypeInfo);
      subtypeSetBuilder.addIntervalList(subtypeInfo.subtypeIntervalList);
    }
    for (_ClassInfo subtype in subInfo.classInfo.directImplementers) {
      _ClassInfoSubtype subtypeInfo = _infoFor[subtype.classNode];
      _topDownSortVisit(subtypeInfo);
      subtypeSetBuilder.addIntervalList(subtypeInfo.subtypeIntervalList);
    }
    subInfo.subtypeIntervalList = subtypeSetBuilder.buildIntervalList();
  }

  @override
  Member getSingleTargetForInterfaceInvocation(Member interfaceTarget,
      {bool setter: false}) {
    if (invalidated) throw "This datastructure has been invalidated";
    Name name = interfaceTarget.name;
    Member target = null;
    ClassSet subtypes = getSubtypesOf(interfaceTarget.enclosingClass);
    for (Class c in subtypes) {
      if (!c.isAbstract) {
        Member candidate = hierarchy.getDispatchTarget(c, name, setter: setter);
        if ((candidate != null) && !candidate.isAbstract) {
          if (target == null) {
            target = candidate;
          } else if (target != candidate) {
            return null;
          }
        }
      }
    }
    return target;
  }

  @override
  ClassSet getSubtypesOf(Class class_) {
    if (invalidated) throw "This datastructure has been invalidated";
    Set<Class> result = new Set<Class>();
    Uint32List list = _infoFor[class_].subtypeIntervalList;
    for (int i = 0; i < list.length; i += 2) {
      int from = list[i];
      int to = list[i + 1];
      for (int j = from; j < to; j++) {
        result.add(_classesByTopDownIndex[j]);
      }
    }
    return new ClassSet(result);
  }
}

/// Implementation of [ClassHierarchy] for closed world.
class ClosedWorldClassHierarchy implements ClassHierarchy {
  HandleAmbiguousSupertypes _onAmbiguousSupertypes;
  HandleAmbiguousSupertypes _onAmbiguousSupertypesNotWrapped;
  MixinInferrer mixinInferrer;

  void set onAmbiguousSupertypes(
      HandleAmbiguousSupertypes onAmbiguousSupertypes) {
    _onAmbiguousSupertypesNotWrapped = onAmbiguousSupertypes;
    _onAmbiguousSupertypes = (Class class_, Supertype a, Supertype b) {
      onAmbiguousSupertypes(class_, a, b);
      List<Supertype> recorded = _recordedAmbiguousSupertypes[class_];
      if (recorded == null) {
        recorded = new List<Supertype>();
        _recordedAmbiguousSupertypes[class_] = recorded;
      }
      recorded.add(a);
      recorded.add(b);
    };
  }

  /// The insert order is important.
  final Map<Class, _ClassInfo> _infoFor =
      new LinkedHashMap<Class, _ClassInfo>();
  final Set<Library> knownLibraries = new Set<Library>();

  /// Recorded errors for classes we have already calculated the class hierarchy
  /// for, but will have to be reissued when re-using the calculation.
  final Map<Class, List<Supertype>> _recordedAmbiguousSupertypes =
      new LinkedHashMap<Class, List<Supertype>>();

  Iterable<Class> get classes => _infoFor.keys;
  int get numberOfClasses => _infoFor.length;

  _ClosedWorldClassHierarchySubtypes _cachedClassHierarchySubtypes;

  ClosedWorldClassHierarchy._internal(
      HandleAmbiguousSupertypes onAmbiguousSupertypes, this.mixinInferrer) {
    this.onAmbiguousSupertypes = onAmbiguousSupertypes;
  }

  ClassHierarchySubtypes computeSubtypesInformation() {
    _cachedClassHierarchySubtypes ??=
        new _ClosedWorldClassHierarchySubtypes(this);
    return _cachedClassHierarchySubtypes;
  }

  @override
  Iterable<Class> getOrderedClasses(Iterable<Class> unordered) {
    var unorderedSet = unordered.toSet();
    return _infoFor.keys.where(unorderedSet.contains);
  }

  @override
  bool isSubclassOf(Class subclass, Class superclass) {
    if (identical(subclass, superclass)) return true;
    return _infoFor[subclass].isSubclassOf(_infoFor[superclass]);
  }

  @override
  bool isSubtypeOf(Class subtype, Class superclass) {
    if (identical(subtype, superclass)) return true;
    return _infoFor[subtype].isSubtypeOf(_infoFor[superclass]);
  }

  @override
  bool isUsedAsMixin(Class class_) {
    return _infoFor[class_].directMixers.isNotEmpty;
  }

  List<_ClassInfo> _getRankedSuperclassInfos(_ClassInfo info) {
    if (info.leastUpperBoundInfos != null) return info.leastUpperBoundInfos;
    var heap = new _LubHeap()..add(info);
    var chain = <_ClassInfo>[];
    info.leastUpperBoundInfos = chain;
    _ClassInfo lastInfo = null;
    while (heap.isNotEmpty) {
      var nextInfo = heap.remove();
      if (identical(nextInfo, lastInfo)) continue;
      chain.add(nextInfo);
      lastInfo = nextInfo;
      var classNode = nextInfo.classNode;
      void addToHeap(Supertype supertype) {
        heap.add(_infoFor[supertype.classNode]);
      }

      if (classNode.supertype != null) addToHeap(classNode.supertype);
      if (classNode.mixedInType != null) addToHeap(classNode.mixedInType);
      classNode.implementedTypes.forEach(addToHeap);
    }
    return chain;
  }

  @override
  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    // The algorithm is: first we compute a list of superclasses for both types,
    // ordered from greatest to least depth, and ordered by topological sort
    // index within each depth.  Due to the sort order, we can find the
    // intersection of these lists by a simple walk.
    //
    // Then, for each class in the intersection, determine the exact type that
    // is implemented by type1 and type2.  If the types match, that type is a
    // candidate (it's a member of S_n).  As soon as we find a candidate which
    // is unique for its depth, we return it.
    //
    // As an optimization, if the class for I is a subtype of the class for J,
    // then we know that the list of superclasses of J is a subset of the list
    // of superclasses for I; therefore it is sufficient to compute just the
    // list of superclasses for J.  To avoid complicating the code below (which
    // intersects the two lists), we set both lists equal to the list of
    // superclasses for J.  And vice versa with the role of I and J swapped.

    // Compute the list of superclasses for both types, with the above
    // optimization.
    _ClassInfo info1 = _infoFor[type1.classNode];
    _ClassInfo info2 = _infoFor[type2.classNode];
    List<_ClassInfo> classes1;
    List<_ClassInfo> classes2;
    if (identical(info1, info2) || info1.isSubtypeOf(info2)) {
      classes1 = classes2 = _getRankedSuperclassInfos(info2);
    } else if (info2.isSubtypeOf(info1)) {
      classes1 = classes2 = _getRankedSuperclassInfos(info1);
    } else {
      classes1 = _getRankedSuperclassInfos(info1);
      classes2 = _getRankedSuperclassInfos(info2);
    }

    // Walk the lists finding their intersection, looking for a depth that has a
    // single candidate.
    int i1 = 0;
    int i2 = 0;
    InterfaceType candidate = null;
    int currentDepth = -1;
    int numCandidatesAtThisDepth = 0;
    while (true) {
      _ClassInfo next = classes1[i1];
      _ClassInfo next2 = classes2[i2];
      if (!identical(next, next2)) {
        if (_LubHeap.sortsBeforeStatic(next, next2)) {
          ++i1;
        } else {
          ++i2;
        }
        continue;
      }
      ++i2;
      ++i1;
      if (next.depth != currentDepth) {
        if (numCandidatesAtThisDepth == 1) return candidate;
        currentDepth = next.depth;
        numCandidatesAtThisDepth = 0;
        candidate = null;
      } else if (numCandidatesAtThisDepth > 1) {
        continue;
      }

      // For each class in the intersection, find the exact type that is
      // implemented by type1 and type2.  If they match, it's a candidate.
      //
      // Two additional optimizations:
      //
      // - If this class lacks type parameters, we know there is a match without
      //   needing to substitute.
      //
      // - If the depth is 0, we have reached Object, so we can return it
      //   immediately.  Since all interface types are subtypes of Object, this
      //   ensures the loop terminates.
      if (next.classNode.typeParameters.isEmpty) {
        candidate = next.classNode.rawType;
        if (currentDepth == 0) return candidate;
        ++numCandidatesAtThisDepth;
      } else {
        var superType1 = identical(info1, next)
            ? type1
            : Substitution.fromInterfaceType(type1).substituteType(
                info1.genericSuperTypes[next.classNode].first.asInterfaceType);
        var superType2 = identical(info2, next)
            ? type2
            : Substitution.fromInterfaceType(type2).substituteType(
                info2.genericSuperTypes[next.classNode].first.asInterfaceType);
        if (superType1 == superType2) {
          candidate = superType1;
          ++numCandidatesAtThisDepth;
        }
      }
    }
  }

  @override
  Supertype getClassAsInstanceOf(Class class_, Class superclass) {
    if (identical(class_, superclass)) return class_.asThisSupertype;
    _ClassInfo info = _infoFor[class_];
    if (info == null) {
      throw "${class_.fileUri}: No class info for ${class_.name}";
    }
    _ClassInfo superInfo = _infoFor[superclass];
    if (superInfo == null) {
      throw "${superclass.fileUri}: No class info for ${superclass.name}";
    }
    if (!info.isSubtypeOf(superInfo)) return null;
    if (superclass.typeParameters.isEmpty) return superclass.asRawSupertype;
    return info.genericSuperTypes[superclass]?.first;
  }

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass) {
    Supertype castedType = getClassAsInstanceOf(type.classNode, superclass);
    if (castedType == null) return null;
    return Substitution.fromInterfaceType(type)
        .substituteType(castedType.asInterfaceType);
  }

  @override
  Member getDispatchTarget(Class class_, Name name, {bool setter: false}) {
    _ClassInfo info = _infoFor[class_];
    List<Member> list =
        setter ? info.implementedSetters : info.implementedGettersAndCalls;
    return ClassHierarchy.findMemberByName(list, name);
  }

  @override
  List<Member> getDispatchTargets(Class class_, {bool setters: false}) {
    _ClassInfo info = _infoFor[class_];
    return setters ? info.implementedSetters : info.implementedGettersAndCalls;
  }

  @override
  Member getInterfaceMember(Class class_, Name name, {bool setter: false}) {
    List<Member> list = getInterfaceMembers(class_, setters: setter);
    return ClassHierarchy.findMemberByName(list, name);
  }

  @override
  List<Member> getInterfaceMembers(Class class_, {bool setters: false}) {
    return _buildInterfaceMembers(class_, _infoFor[class_], setters: setters);
  }

  @override
  List<Member> getDeclaredMembers(Class class_, {bool setters: false}) {
    var info = _infoFor[class_];
    return setters ? info.declaredSetters : info.declaredGettersAndCalls;
  }

  @override
  void forEachOverridePair(Class class_,
      callback(Member declaredMember, Member interfaceMember, bool isSetter),
      {bool crossGettersSetters: false}) {
    _ClassInfo info = _infoFor[class_];
    for (var supertype in class_.supers) {
      var superclass = supertype.classNode;
      var superGetters = getInterfaceMembers(superclass);
      var superSetters = getInterfaceMembers(superclass, setters: true);
      _reportOverrides(info.declaredGettersAndCalls, superGetters, callback);
      _reportOverrides(info.declaredSetters, superSetters, callback,
          isSetter: true);
    }
  }

  static void _reportOverrides(
      List<Member> declaredList,
      List<Member> inheritedList,
      callback(Member declaredMember, Member interfaceMember, bool isSetter),
      {bool isSetter: false}) {
    int i = 0, j = 0;
    while (i < declaredList.length && j < inheritedList.length) {
      Member declared = declaredList[i];
      Member inherited = inheritedList[j];
      int comparison = ClassHierarchy.compareMembers(declared, inherited);
      if (comparison < 0) {
        ++i;
      } else if (comparison > 0) {
        ++j;
      } else {
        if (!identical(declared, inherited)) {
          callback(declared, inherited, isSetter);
        }
        // A given declared member may override multiple interface members,
        // so only move past the interface member.
        ++j;
      }
    }
  }

  @override
  List<Supertype> genericSupertypesOf(Class class_) {
    final supertypes = _infoFor[class_].genericSuperTypes;
    if (supertypes == null) return const <Supertype>[];
    // Multiple supertypes can arise from ambiguous supertypes. The first
    // supertype is the real one; the others are purely informational.
    return supertypes.values.map((v) => v.first).toList();
  }

  @override
  ClassHierarchy applyTreeChanges(Iterable<Library> removedLibraries,
      Iterable<Library> ensureKnownLibraries,
      {Component reissueAmbiguousSupertypesFor}) {
    // Remove all references to the removed classes.
    for (Library lib in removedLibraries) {
      if (!knownLibraries.contains(lib)) continue;
      for (Class class_ in lib.classes) {
        _ClassInfo info = _infoFor[class_];
        if (class_.supertype != null) {
          _infoFor[class_.supertype.classNode]?.directExtenders?.remove(info);
        }
        if (class_.mixedInType != null) {
          _infoFor[class_.mixedInType.classNode]?.directMixers?.remove(info);
        }
        for (var supertype in class_.implementedTypes) {
          _infoFor[supertype.classNode]?.directImplementers?.remove(info);
        }

        _infoFor.remove(class_);
        _recordedAmbiguousSupertypes.remove(class_);
      }
      knownLibraries.remove(lib);
    }

    // If we have a cached computation of subtypes, invalidate it and stop
    // caching it.
    if (_cachedClassHierarchySubtypes != null) {
      _cachedClassHierarchySubtypes.invalidated = true;
    }

    if (_recordedAmbiguousSupertypes.isNotEmpty &&
        reissueAmbiguousSupertypesFor != null) {
      Set<Library> libs =
          new Set<Library>.from(reissueAmbiguousSupertypesFor.libraries);
      for (Class class_ in _recordedAmbiguousSupertypes.keys) {
        if (!libs.contains(class_.enclosingLibrary)) continue;
        List<Supertype> recorded = _recordedAmbiguousSupertypes[class_];
        for (int i = 0; i < recorded.length; i += 2) {
          _onAmbiguousSupertypesNotWrapped(
              class_, recorded[i], recorded[i + 1]);
        }
      }
    }

    // Add the new classes.
    List<Class> addedClassesSorted = new List<Class>();
    int expectedStartIndex = _topSortIndex;
    for (Library lib in ensureKnownLibraries) {
      if (knownLibraries.contains(lib)) continue;
      for (Class class_ in lib.classes) {
        _topologicalSortVisit(class_, new Set<Class>(),
            orderedList: addedClassesSorted);
      }
      knownLibraries.add(lib);
    }
    _initializeTopologicallySortedClasses(
        addedClassesSorted, expectedStartIndex);

    return this;
  }

  @override
  ClassHierarchy applyMemberChanges(Iterable<Class> classes,
      {bool findDescendants: false}) {
    if (classes.isEmpty) return this;

    List<_ClassInfo> infos = new List<_ClassInfo>();
    if (findDescendants) {
      Set<_ClassInfo> processedClasses = new Set<_ClassInfo>();
      List<_ClassInfo> worklist = <_ClassInfo>[];
      for (Class class_ in classes) {
        _ClassInfo info = _infoFor[class_];
        worklist.add(info);
      }

      while (worklist.isNotEmpty) {
        _ClassInfo info = worklist.removeLast();
        if (processedClasses.add(info)) {
          worklist.addAll(info.directExtenders);
          worklist.addAll(info.directImplementers);
          worklist.addAll(info.directMixers);
        }
      }
      infos.addAll(processedClasses);
    } else {
      for (Class class_ in classes) {
        _ClassInfo info = _infoFor[class_];
        infos.add(info);
      }
    }

    infos.sort((_ClassInfo a, _ClassInfo b) {
      return a.topologicalIndex - b.topologicalIndex;
    });

    for (_ClassInfo info in infos) {
      Class class_ = info.classNode;
      _buildDeclaredMembers(class_, info);
      _buildImplementedMembers(class_, info);
      info.interfaceSetters = null;
      info.interfaceGettersAndCalls = null;
      _buildInterfaceMembers(class_, info, setters: true);
      _buildInterfaceMembers(class_, info, setters: false);
    }

    return this;
  }

  @override
  Supertype asInstantiationOf(Supertype type, Class superclass) {
    // This is similar to getTypeAsInstanceOf, except that it assumes that
    // superclass is a generic class.  It thus does not rely on being able
    // to answer isSubtypeOf queries and so can be used before we have built
    // the intervals needed for those queries.
    assert(superclass.typeParameters.isNotEmpty);
    if (type.classNode == superclass) {
      return superclass.asThisSupertype;
    }
    var map = _infoFor[type.classNode]?.genericSuperTypes;
    return map == null ? null : map[superclass]?.first;
  }

  void _initialize(List<Library> libraries) {
    // Build the class ordering based on a topological sort.
    for (var library in libraries) {
      for (var classNode in library.classes) {
        _topologicalSortVisit(classNode, new Set<Class>());
      }
      knownLibraries.add(library);
    }

    _initializeTopologicallySortedClasses(_infoFor.keys, 0);
  }

  /// - Build index of direct children.
  /// - Build list of super classes and super types.
  /// - Infer and record supertypes for the classes.
  /// - Record interface members.
  /// - Perform some sanity checking.
  /// Do this after the topological sort so that super types always occur
  /// before subtypes.
  void _initializeTopologicallySortedClasses(
      Iterable<Class> classes, int expectedStartingTopologicalIndex) {
    int i = expectedStartingTopologicalIndex;
    for (Class class_ in classes) {
      _ClassInfo info = _infoFor[class_];
      if (class_.supertype != null) {
        _infoFor[class_.supertype.classNode].directExtenders.add(info);
      }
      if (class_.mixedInType != null) {
        _infoFor[class_.mixedInType.classNode].directMixers.add(info);
      }
      for (var supertype in class_.implementedTypes) {
        _infoFor[supertype.classNode].directImplementers.add(info);
      }
      _collectSupersForClass(class_);

      if (class_.supertype != null) {
        _recordSuperTypes(info, class_.supertype);
      }
      if (class_.mixedInType != null) {
        mixinInferrer?.infer(this, class_);
        _recordSuperTypes(info, class_.mixedInType);
      }
      for (Supertype supertype in class_.implementedTypes) {
        _recordSuperTypes(info, supertype);
      }

      _buildInterfaceMembers(class_, info, setters: true);
      _buildInterfaceMembers(class_, info, setters: false);

      if (info == null) {
        throw "No info for ${class_.name} from ${class_.fileUri}.";
      }
      if (info.topologicalIndex != i) {
        throw "Unexpected topologicalIndex (${info.topologicalIndex} != $i) "
            "for ${class_.name} from ${class_.fileUri}.";
      }
      i++;
    }
  }

  /// Upwards traversal of the class hierarchy that orders classes so super
  /// types before their subtypes.
  ///
  /// Returns the depth of the visited class (the number of steps in the longest
  /// inheritance path to the root class).
  int _topSortIndex = 0;
  int _topologicalSortVisit(Class classNode, Set<Class> beingVisited,
      {List<Class> orderedList}) {
    var info = _infoFor[classNode];
    if (info != null) {
      return info.depth;
    }

    if (!beingVisited.add(classNode)) {
      throw 'Cyclic inheritance involving ${classNode.name}';
    }

    info = new _ClassInfo(classNode);

    int superDepth = -1;
    if (classNode.supertype != null) {
      superDepth = max(
          superDepth,
          _topologicalSortVisit(classNode.supertype.classNode, beingVisited,
              orderedList: orderedList));
    }
    if (classNode.mixedInType != null) {
      superDepth = max(
          superDepth,
          _topologicalSortVisit(classNode.mixedInType.classNode, beingVisited,
              orderedList: orderedList));
    }
    for (var supertype in classNode.implementedTypes) {
      superDepth = max(
          superDepth,
          _topologicalSortVisit(supertype.classNode, beingVisited,
              orderedList: orderedList));
    }
    _buildDeclaredMembers(classNode, info);
    _buildImplementedMembers(classNode, info);
    info.topologicalIndex = _topSortIndex++;

    _infoFor[classNode] = info;
    orderedList?.add(classNode);
    beingVisited.remove(classNode);
    return info.depth = superDepth + 1;
  }

  void _buildDeclaredMembers(Class classNode, _ClassInfo info) {
    if (classNode.mixedInType != null) {
      _ClassInfo mixedInfo = _infoFor[classNode.mixedInType.classNode];

      List<Member> declaredGettersAndCalls = <Member>[];
      for (Member mixinMember in mixedInfo.declaredGettersAndCalls) {
        if (mixinMember is! Procedure ||
            (mixinMember is Procedure &&
                !mixinMember.isNoSuchMethodForwarder)) {
          declaredGettersAndCalls.add(mixinMember);
        }
      }

      List<Member> declaredSetters = <Member>[];
      for (Member mixinMember in mixedInfo.declaredSetters) {
        if (mixinMember is! Procedure ||
            (mixinMember is Procedure &&
                !mixinMember.isNoSuchMethodForwarder)) {
          declaredSetters.add(mixinMember);
        }
      }

      info.declaredGettersAndCalls = declaredGettersAndCalls;
      info.declaredSetters = declaredSetters;
    } else {
      var members = info.declaredGettersAndCalls = <Member>[];
      var setters = info.declaredSetters = <Member>[];
      for (Procedure procedure in classNode.procedures) {
        if (procedure.isStatic) continue;
        if (procedure.kind == ProcedureKind.Setter) {
          setters.add(procedure);
        } else {
          members.add(procedure);
        }
      }
      for (Field field in classNode.fields) {
        if (field.isStatic) continue;
        if (field.hasImplicitGetter) {
          members.add(field);
        }
        if (field.hasImplicitSetter) {
          setters.add(field);
        }
      }
      members.sort(ClassHierarchy.compareMembers);
      setters.sort(ClassHierarchy.compareMembers);
    }
  }

  void _buildImplementedMembers(Class classNode, _ClassInfo info) {
    List<Member> inheritedMembers;
    List<Member> inheritedSetters;
    if (classNode.supertype == null) {
      inheritedMembers = inheritedSetters = const <Member>[];
    } else {
      _ClassInfo superInfo = _infoFor[classNode.supertype.classNode];
      inheritedMembers = superInfo.implementedGettersAndCalls;
      inheritedSetters = superInfo.implementedSetters;
    }
    info.implementedGettersAndCalls = _inheritMembers(
        info.declaredGettersAndCalls, inheritedMembers,
        skipAbstractMembers: true);
    info.implementedSetters = _inheritMembers(
        info.declaredSetters, inheritedSetters,
        skipAbstractMembers: true);
  }

  List<Member> _buildInterfaceMembers(Class classNode, _ClassInfo info,
      {bool setters}) {
    if (info == null) {
      throw "${classNode.fileUri}: No class info for ${classNode.name}";
    }
    List<Member> members =
        setters ? info.interfaceSetters : info.interfaceGettersAndCalls;
    if (members != null) return members;
    List<Member> allInheritedMembers = <Member>[];
    List<Member> declared =
        setters ? info.declaredSetters : info.declaredGettersAndCalls;
    void inheritFrom(Supertype type) {
      if (type == null) return;
      List<Member> inherited = _buildInterfaceMembers(
          type.classNode, _infoFor[type.classNode],
          setters: setters);
      inherited = _getUnshadowedInheritedMembers(declared, inherited);
      allInheritedMembers =
          ClassHierarchy.mergeSortedLists(allInheritedMembers, inherited);
    }

    inheritFrom(classNode.supertype);
    inheritFrom(classNode.mixedInType);
    classNode.implementedTypes.forEach(inheritFrom);
    members = _inheritMembers(declared, allInheritedMembers);
    if (setters) {
      info.interfaceSetters = members;
    } else {
      info.interfaceGettersAndCalls = members;
    }
    return members;
  }

  /// Computes the list of implemented members, based on the declared instance
  /// members and inherited instance members.
  ///
  /// Both lists must be sorted by name beforehand.
  static List<Member> _inheritMembers(
      List<Member> declared, List<Member> inherited,
      {bool skipAbstractMembers: false}) {
    List<Member> result = <Member>[]..length =
        declared.length + inherited.length;
    // Since both lists are sorted, we can fuse them like in merge sort.
    int storeIndex = 0;
    int i = 0, j = 0;
    while (i < declared.length && j < inherited.length) {
      Member declaredMember = declared[i];
      Member inheritedMember = inherited[j];
      if (skipAbstractMembers && declaredMember.isAbstract) {
        ++i;
        continue;
      }
      if (skipAbstractMembers && inheritedMember.isAbstract) {
        ++j;
        continue;
      }
      int comparison =
          ClassHierarchy.compareMembers(declaredMember, inheritedMember);
      if (comparison < 0) {
        result[storeIndex++] = declaredMember;
        ++i;
      } else if (comparison > 0) {
        result[storeIndex++] = inheritedMember;
        ++j;
      } else {
        result[storeIndex++] = declaredMember;
        ++i;
        ++j; // Move past overridden member.
      }
    }
    // One of the two lists is now exhausted, copy over the remains.
    while (i < declared.length) {
      Member declaredMember = declared[i++];
      if (skipAbstractMembers && declaredMember.isAbstract) continue;
      result[storeIndex++] = declaredMember;
    }
    while (j < inherited.length) {
      Member inheritedMember = inherited[j++];
      if (skipAbstractMembers && inheritedMember.isAbstract) continue;
      result[storeIndex++] = inheritedMember;
    }
    result.length = storeIndex;
    return result;
  }

  /// Returns the subset of members in [inherited] for which a member with the
  /// same name does not occur in [declared].
  ///
  /// The input lists must be sorted, and the returned list is sorted.
  static List<Member> _getUnshadowedInheritedMembers(
      List<Member> declared, List<Member> inherited) {
    List<Member> result = <Member>[]..length = inherited.length;
    int storeIndex = 0;
    int i = 0, j = 0;
    while (i < declared.length && j < inherited.length) {
      Member declaredMember = declared[i];
      Member inheritedMember = inherited[j];
      int comparison =
          ClassHierarchy.compareMembers(declaredMember, inheritedMember);
      if (comparison < 0) {
        ++i;
      } else if (comparison > 0) {
        result[storeIndex++] = inheritedMember;
        ++j;
      } else {
        // Move past the shadowed member, but retain the declared member, as
        // it may shadow multiple members.
        ++j;
      }
    }
    // If the list of declared members is exhausted, copy over the remains of
    // the inherited members.
    while (j < inherited.length) {
      result[storeIndex++] = inherited[j++];
    }
    result.length = storeIndex;
    return result;
  }

  void _recordSuperTypes(_ClassInfo subInfo, Supertype supertype) {
    _ClassInfo superInfo = _infoFor[supertype.classNode];
    if (supertype.typeArguments.isEmpty) {
      if (superInfo.genericSuperTypes == null) return;
      // Copy over the super type entries.
      subInfo.genericSuperTypes ??= <Class, List<Supertype>>{};
      superInfo.genericSuperTypes?.forEach((Class key, List<Supertype> types) {
        for (Supertype type in types) {
          subInfo.recordGenericSuperType(key, type, _onAmbiguousSupertypes);
        }
      });
    } else {
      // Copy over all transitive generic super types, and substitute the
      // free variables with those provided in [supertype].
      Class superclass = supertype.classNode;
      var substitution = Substitution.fromPairs(
          superclass.typeParameters, supertype.typeArguments);
      subInfo.genericSuperTypes ??= <Class, List<Supertype>>{};
      superInfo.genericSuperTypes?.forEach((Class key, List<Supertype> types) {
        for (Supertype type in types) {
          subInfo.recordGenericSuperType(key,
              substitution.substituteSupertype(type), _onAmbiguousSupertypes);
        }
      });

      subInfo.recordGenericSuperType(
          superclass, supertype, _onAmbiguousSupertypes);
    }
  }

  /// Build lists of super types and super classes.
  /// Note that the super class and super types of the class must already have
  /// had their supers collected.
  void _collectSupersForClass(Class class_) {
    _ClassInfo info = _infoFor[class_];

    var superclassSetBuilder = new _IntervalListBuilder()
      ..addSingleton(info.topologicalIndex);
    var supertypeSetBuilder = new _IntervalListBuilder()
      ..addSingleton(info.topologicalIndex);

    if (class_.supertype != null) {
      _ClassInfo supertypeInfo = _infoFor[class_.supertype.classNode];
      superclassSetBuilder
          .addIntervalList(supertypeInfo.superclassIntervalList);
      supertypeSetBuilder.addIntervalList(supertypeInfo.supertypeIntervalList);
    }

    if (class_.mixedInType != null) {
      _ClassInfo mixedInTypeInfo = _infoFor[class_.mixedInType.classNode];
      supertypeSetBuilder
          .addIntervalList(mixedInTypeInfo.supertypeIntervalList);
    }

    for (Supertype supertype in class_.implementedTypes) {
      _ClassInfo supertypeInfo = _infoFor[supertype.classNode];
      supertypeSetBuilder.addIntervalList(supertypeInfo.supertypeIntervalList);
    }

    info.superclassIntervalList = superclassSetBuilder.buildIntervalList();
    info.supertypeIntervalList = supertypeSetBuilder.buildIntervalList();
  }

  /// Creates a histogram such that index `N` contains the number of classes
  /// that have `N` intervals in its supertype set.
  ///
  /// The more numbers are condensed near the beginning, the more efficient the
  /// internal data structure is.
  List<int> getExpenseHistogram() {
    var result = <int>[];
    for (Class class_ in _infoFor.keys) {
      var info = _infoFor[class_];
      int intervals = info.supertypeIntervalList.length ~/ 2;
      if (intervals >= result.length) {
        int oldLength = result.length;
        result.length = intervals + 1;
        result.fillRange(oldLength, result.length, 0);
      }
      result[intervals] += 1;
    }
    return result;
  }

  /// Returns the average number of intervals per supertype relation (less
  /// is better, 1.0 is bad).
  ///
  /// This is an estimate of the memory use compared to a data structure that
  /// enumerates all superclass/supertype pairs.
  double getCompressionRatio() {
    int intervals = 0;
    int sizes = 0;
    for (Class class_ in _infoFor.keys) {
      var info = _infoFor[class_];
      intervals += (info.superclassIntervalList.length +
              info.supertypeIntervalList.length) ~/
          2;
      sizes += _intervalListSize(info.superclassIntervalList) +
          _intervalListSize(info.supertypeIntervalList);
    }

    return sizes == 0 ? 1.0 : intervals / sizes;
  }

  /// Returns the number of entries in hash tables storing hierarchy data.
  int getSuperTypeHashTableSize() {
    int sum = 0;
    for (Class class_ in _infoFor.keys) {
      sum += _infoFor[class_].genericSuperTypes?.length ?? 0;
    }
    return sum;
  }
}

class _IntervalListBuilder {
  final List<int> events = <int>[];

  void addInterval(int start, int end) {
    // Add an event point for each interval end point, using the low bit to
    // distinguish opening from closing end points. Closing end points should
    // have the high bit to ensure they occur after an opening end point.
    events.add(start << 1);
    events.add((end << 1) + 1);
  }

  void addSingleton(int x) {
    addInterval(x, x + 1);
  }

  void addIntervalList(Uint32List intervals) {
    for (int i = 0; i < intervals.length; i += 2) {
      addInterval(intervals[i], intervals[i + 1]);
    }
  }

  Uint32List buildIntervalList() {
    // Sort the event points and sweep left to right while tracking how many
    // intervals we are currently inside.  Record an interval end point when the
    // number of intervals drop to zero or increase from zero to one.
    // Event points are encoded so that an opening end point occur before a
    // closing end point at the same value.
    events.sort();
    int insideCount = 0; // The number of intervals we are currently inside.
    int storeIndex = 0;
    for (int i = 0; i < events.length; ++i) {
      int event = events[i];
      if (event & 1 == 0) {
        // Start point
        ++insideCount;
        if (insideCount == 1) {
          // Store the results temporarily back in the event array.
          events[storeIndex++] = event >> 1;
        }
      } else {
        // End point
        --insideCount;
        if (insideCount == 0) {
          events[storeIndex++] = event >> 1;
        }
      }
    }
    // Copy the results over to a typed array of the correct length.
    var result = new Uint32List(storeIndex);
    for (int i = 0; i < storeIndex; ++i) {
      result[i] = events[i];
    }
    return result;
  }
}

bool _intervalListContains(Uint32List intervalList, int x) {
  int low = 0, high = intervalList.length - 1;
  if (high == -1 || x < intervalList[0] || intervalList[high] <= x) {
    return false;
  }
  // Find the lower bound of x in the list.
  // If the lower bound is at an even index, the lower bound is an opening point
  // of an interval that contains x, otherwise it is a closing point of an
  // interval below x and there is no interval containing x.
  while (low < high) {
    int mid = high - ((high - low) >> 1); // Get middle, rounding up.
    int pivot = intervalList[mid];
    if (pivot <= x) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return low == high && (low & 1) == 0;
}

int _intervalListSize(Uint32List intervalList) {
  int size = 0;
  for (int i = 0; i < intervalList.length; i += 2) {
    size += intervalList[i + 1] - intervalList[i];
  }
  return size;
}

class _ClassInfo {
  final Class classNode;
  int topologicalIndex = 0;
  int depth = 0;

  // Super types must always occur before subtypes in these lists.
  // For example:
  //
  //   class A extends Object
  //   class B extends Object implements A
  //
  // Here `A` must occur before `B` in the list of direct extenders of Object,
  // because `B` is a subtype of `A`.
  final Set<_ClassInfo> directExtenders = new LinkedHashSet<_ClassInfo>();
  final Set<_ClassInfo> directMixers = new LinkedHashSet<_ClassInfo>();
  final Set<_ClassInfo> directImplementers = new LinkedHashSet<_ClassInfo>();

  Uint32List superclassIntervalList;
  Uint32List supertypeIntervalList;

  List<_ClassInfo> leastUpperBoundInfos;

  /// Maps generic supertype classes to the instantiation implemented by this
  /// class.
  ///
  /// E.g. `List` maps to `List<String>` for a class that directly or indirectly
  /// implements `List<String>`.
  Map<Class, List<Supertype>> genericSuperTypes;

  /// Instance fields, getters, methods, and operators declared in this class
  /// or its mixed-in class, sorted according to [_compareMembers].
  List<Member> declaredGettersAndCalls;

  /// Non-final instance fields and setters declared in this class or its
  /// mixed-in class, sorted according to [_compareMembers].
  List<Member> declaredSetters;

  /// Instance fields, getters, methods, and operators implemented by this class
  /// (declared or inherited).
  List<Member> implementedGettersAndCalls;

  /// Non-final instance fields and setters implemented by this class
  /// (declared or inherited).
  List<Member> implementedSetters;

  List<Member> interfaceGettersAndCalls;
  List<Member> interfaceSetters;

  _ClassInfo(this.classNode);

  bool isSubclassOf(_ClassInfo other) {
    return _intervalListContains(
        superclassIntervalList, other.topologicalIndex);
  }

  bool isSubtypeOf(_ClassInfo other) {
    return _intervalListContains(supertypeIntervalList, other.topologicalIndex);
  }

  void recordGenericSuperType(Class cls, Supertype type,
      HandleAmbiguousSupertypes onAmbiguousSupertypes) {
    List<Supertype> existing = genericSuperTypes[cls];
    if (existing == null) {
      genericSuperTypes[cls] = <Supertype>[type];
    } else if (type != existing.first) {
      existing.add(type);
      onAmbiguousSupertypes(classNode, existing.first, type);
    }
  }
}

/// An immutable set of classes.
class ClassSet extends IterableBase<Class> {
  final Set<Class> _classes;
  ClassSet(this._classes);

  bool contains(Object class_) {
    return _classes.contains(class_);
  }

  ClassSet union(ClassSet other) {
    Set<Class> result = new Set<Class>.from(_classes);
    result.addAll(other._classes);
    return new ClassSet(result);
  }

  @override
  Iterator<Class> get iterator => _classes.iterator;
}

/// Heap for use in computing least upper bounds.
///
/// The heap is sorted such that classes that are deepest in the hierarchy
/// are removed first; in the case of ties, classes with lower topological sort
/// index are removed first.
class _LubHeap extends Heap<_ClassInfo> {
  @override
  bool sortsBefore(_ClassInfo a, _ClassInfo b) => sortsBeforeStatic(a, b);

  static bool sortsBeforeStatic(_ClassInfo a, _ClassInfo b) {
    if (a.depth > b.depth) return true;
    if (a.depth < b.depth) return false;
    return a.topologicalIndex < b.topologicalIndex;
  }
}
