// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.class_hierarchy;

import 'ast.dart';
import 'dart:math';
import 'dart:typed_data';
import 'type_algebra.dart';

/// Data structure for answering various subclassing queries.
class ClassHierarchy {
  /// All classes in the program.
  ///
  /// The list is ordered so that classes occur after their super classes.
  final List<Class> classes;

  final Map<Class, _ClassInfo> _infoFor = <Class, _ClassInfo>{};

  ClassHierarchy(Program program)
      : this._internal(program, _countClasses(program));

  Class get rootClass => classes[0];

  /// Returns the index of [class_] in the [classes] list.
  int getClassIndex(Class class_) => _infoFor[class_].topologicalIndex;

  /// True if [subclass] inherits from [superclass] though zero or more
  /// `extends` relationships.
  bool isSubclassOf(Class subclass, Class superclass) {
    if (identical(subclass, superclass)) return true;
    return _infoFor[subclass].isSubclassOf(_infoFor[superclass]);
  }

  /// True if [submixture] inherits from [superclass] though zero or more
  /// `extends` and `with` relationships.
  bool isSubmixtureOf(Class submixture, Class superclass) {
    if (identical(submixture, superclass)) return true;
    return _infoFor[submixture].isSubmixtureOf(_infoFor[superclass]);
  }

  /// True if [subtype] inherits from [superclass] though zero or more
  /// `extends`, `with`, and `implements` relationships.
  bool isSubtypeOf(Class subtype, Class superclass) {
    if (identical(subtype, superclass)) return true;
    return _infoFor[subtype].isSubtypeOf(_infoFor[superclass]);
  }

  /// True if the given class is the direct super class of another class.
  bool isUsedAsSuperClass(Class class_) {
    return _infoFor[class_].directExtenders.isNotEmpty;
  }

  /// True if the given class is used as the right-hand operand to a
  /// mixin application (i.e. [Class.mixedInType]).
  bool isUsedAsMixin(Class class_) {
    return _infoFor[class_].directMixers.isNotEmpty;
  }

  /// True if the given class is used in an `implements` clause.
  bool isUsedAsSuperInterface(Class class_) {
    return _infoFor[class_].directImplementers.isNotEmpty;
  }

  /// Returns the instantiation of [superclass] that is implemented by [class_],
  /// or `null` if [class_] does not implement [superclass] at all.
  InterfaceType getClassAsInstanceOf(Class class_, Class superclass) {
    if (identical(class_, superclass)) return class_.thisType;
    _ClassInfo info = _infoFor[class_];
    _ClassInfo superInfo = _infoFor[superclass];
    if (!info.isSubtypeOf(superInfo)) return null;
    if (superclass.typeParameters.isEmpty) return superclass.rawType;
    return info.genericSuperTypes[superclass];
  }

  /// Returns the instantiation of [superclass] that is implemented by [type],
  /// or `null` if [type] does not implement [superclass] at all.
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass) {
    InterfaceType castedType = getClassAsInstanceOf(type.classNode, superclass);
    if (castedType == null) return null;
    return substituteThisType(castedType, type);
  }

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
  Member getDispatchTarget(Class class_, Name name, {bool setter: false}) {
    _ClassInfo info = _infoFor[class_];
    List<Member> list =
        setter ? info.implementedSetters : info.implementedGettersAndCalls;
    return _findMemberByName(list, name);
  }

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
  List<Member> getDispatchTargets(Class class_, {bool setters: false}) {
    _ClassInfo info = _infoFor[class_];
    return setters ? info.implementedSetters : info.implementedGettersAndCalls;
  }

  /// Returns the possibly abstract interface member of [class_] with the given
  /// [name].
  ///
  /// If [setters] is `false`, only fields, methods, and getters with that name
  /// will be found.  If [setters] is `true`, only non-final fields and setters
  /// will be found.
  ///
  /// If multiple members with that name are inherited and not overidden, the
  /// member from the first declared supertype is returned.
  Member getInterfaceMember(Class class_, Name name, {bool setter: false}) {
    List<Member> list = getInterfaceMembers(class_, setters: setter);
    return _findMemberByName(list, name);
  }

  /// Returns the list of members denoting the interface for [class_], which
  /// may include abstract members.
  ///
  /// See [getInterfaceMember].
  List<Member> getInterfaceMembers(Class class_, {bool setters: false}) {
    return _buildInterfaceMembers(class_, _infoFor[class_], setters: setters);
  }

  ClassHierarchy._internal(Program program, int numberOfClasses)
      : classes = new List<Class>(numberOfClasses) {
    // Build the class ordering based on a topological sort.
    for (var library in program.libraries) {
      for (var classNode in library.classes) {
        _topologicalSortVisit(classNode);
      }
    }

    // Build index of direct children.  Do this after the topological sort so
    // that super types always occur before subtypes.
    for (int i = 0; i < classes.length; ++i) {
      var class_ = classes[i];
      var info = _infoFor[class_];
      if (class_.supertype != null) {
        _infoFor[class_.supertype.classNode].directExtenders.add(info);
      }
      if (class_.mixedInType != null) {
        _infoFor[class_.mixedInType.classNode].directMixers.add(info);
      }
      for (var supertype in class_.implementedTypes) {
        _infoFor[supertype.classNode].directImplementers.add(info);
      }
    }

    // Run a downward traversal from the root, compute preorder numbers for
    // each class, and build their subtype sets as interval lists.
    _topDownSortVisit(_infoFor[rootClass]);
  }

  /// Upwards traversal of the class hierarchy that orders classes so super
  /// types before their subtypes.
  int _topSortIndex = 0;
  void _topologicalSortVisit(Class classNode) {
    var info = _infoFor[classNode];
    if (info != null) {
      if (info.isBeingVisited) {
        throw 'Cyclic inheritance involving ${info.classNode.name}';
      }
      return; // Already built.
    }
    _infoFor[classNode] = info = new _ClassInfo(classNode);
    info.isBeingVisited = true;
    if (classNode.supertype != null) {
      _topologicalSortVisit(classNode.supertype.classNode);
      _recordSuperTypes(info, classNode.supertype);
    }
    if (classNode.mixedInType != null) {
      _topologicalSortVisit(classNode.mixedInType.classNode);
      _recordSuperTypes(info, classNode.mixedInType);
    }
    for (var supertype in classNode.implementedTypes) {
      _topologicalSortVisit(supertype.classNode);
      _recordSuperTypes(info, supertype);
    }
    _buildDeclaredMembers(classNode, info);
    _buildImplementedMembers(classNode, info);
    int id = _topSortIndex++;
    info.topologicalIndex = id;
    classes[id] = info.classNode;
    info.isBeingVisited = false;
  }

  void _buildDeclaredMembers(Class classNode, _ClassInfo info) {
    if (classNode.mixedInType != null) {
      _ClassInfo mixedInfo = _infoFor[classNode.mixedInType.classNode];
      info.declaredGettersAndCalls = mixedInfo.declaredGettersAndCalls;
      info.declaredSetters = mixedInfo.declaredSetters;
    } else {
      var members = info.declaredGettersAndCalls = <Member>[];
      var setters = info.declaredSetters = <Member>[];
      for (Procedure procedure in classNode.procedures) {
        if (procedure.isStatic || procedure.isAbstract) continue;
        if (procedure.kind == ProcedureKind.Setter) {
          setters.add(procedure);
        } else {
          members.add(procedure);
        }
      }
      for (Field field in classNode.fields) {
        if (field.isStatic) continue;
        members.add(field);
        if (!field.isFinal) {
          setters.add(field);
        }
      }
      members.sort(_compareMembers);
      setters.sort(_compareMembers);
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
    info.implementedGettersAndCalls =
        _inheritMembers(info.declaredGettersAndCalls, inheritedMembers);
    info.implementedSetters =
        _inheritMembers(info.declaredSetters, inheritedSetters);
  }

  List<Member> _buildInterfaceMembers(Class classNode, _ClassInfo info,
      {bool setters}) {
    List<Member> members =
        setters ? info.interfaceSetters : info.interfaceGettersAndCalls;
    if (members != null) return members;
    members = <Member>[];
    for (Procedure member in classNode.mixin.procedures) {
      if (member.isStatic) continue;
      if (setters != member.isSetter) continue;
      members.add(member);
    }
    for (Field member in classNode.mixin.fields) {
      if (member.isStatic) continue;
      if (setters && member.isFinal) continue;
      members.add(member);
    }
    members.sort(_compareMembers);
    void inheritFrom(InterfaceType type) {
      if (type == null) return;
      List<Member> inherited = _buildInterfaceMembers(type.classNode,
          _infoFor[type.classNode], setters: setters);
      members = _inheritMembers(members, inherited);
    }
    inheritFrom(classNode.supertype);
    inheritFrom(classNode.mixedInType);
    classNode.implementedTypes.forEach(inheritFrom);
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
  List<Member> _inheritMembers(List<Member> declared, List<Member> inherited) {
    List<Member> result = <Member>[]
      ..length = declared.length + inherited.length;
    // Since both lists are sorted, we can fuse them like in merge sort.
    int storeIndex = 0;
    int i = 0, j = 0;
    while (i < declared.length && j < inherited.length) {
      Member declaredMember = declared[i];
      Member inheritedMember = inherited[j];
      int comparison = _compareMembers(declaredMember, inheritedMember);
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
      result[storeIndex++] = declared[i++];
    }
    while (j < inherited.length) {
      result[storeIndex++] = inherited[j++];
    }
    result.length = storeIndex;
    return result;
  }

  void _recordSuperTypes(_ClassInfo subInfo, InterfaceType supertype) {
    _ClassInfo superInfo = _infoFor[supertype.classNode];
    if (supertype.typeArguments.isEmpty) {
      if (superInfo.genericSuperTypes == null) return;
      // Since the immediate super type is not generic, all entries in its
      // super type map are also valid entries for this class.
      if (subInfo.genericSuperTypes == null &&
          superInfo.ownsGenericSuperTypeMap) {
        // Instead of copying the map, take ownership of the map object.
        // This may result in more entries being added to the map later. Those
        // are not valid for the super type, but it works out because all
        // lookups in the map are guarded by a subtype check, so the super type
        // will not be bothered by the extra entries.
        subInfo.genericSuperTypes = superInfo.genericSuperTypes;
        superInfo.ownsGenericSuperTypeMap = false;
      } else {
        // Copy over the super type entries.
        subInfo.genericSuperTypes ??= <Class, InterfaceType>{};
        subInfo.genericSuperTypes.addAll(superInfo.genericSuperTypes);
      }
    } else {
      // Copy over all transitive generic super types, and substitute the
      // free variables with those provided in [supertype].
      Class superclass = supertype.classNode;
      var substitution = new Map<TypeParameter, DartType>.fromIterables(
          superclass.typeParameters, supertype.typeArguments);
      subInfo.genericSuperTypes ??= <Class, InterfaceType>{};
      superInfo.genericSuperTypes?.forEach((Class key, InterfaceType type) {
        subInfo.genericSuperTypes[key] = substitute(type, substitution);
      });
      subInfo.genericSuperTypes[superclass] = supertype;
    }
  }

  /// Downwards traversal of the class hierarchy that orders classes so local
  /// hierarchies have contiguous indices.
  int _topDownSortIndex = 0;
  void _topDownSortVisit(_ClassInfo info) {
    if (info.topDownIndex != -1) return;
    bool isMixedIn = info.directMixers.isNotEmpty;
    int index = _topDownSortIndex++;
    info.topDownIndex = index;
    var subclassSetBuilder = new _IntervalListBuilder()..addSingleton(index);
    var submixtureSetBuilder =
        isMixedIn ? (new _IntervalListBuilder()..addSingleton(index)) : null;
    var subtypeSetBuilder = new _IntervalListBuilder()..addSingleton(index);
    for (var subtype in info.directExtenders) {
      _topDownSortVisit(subtype);
      subclassSetBuilder.addIntervalList(subtype.subclassIntervalList);
      submixtureSetBuilder?.addIntervalList(subtype.submixtureIntervalList);
      subtypeSetBuilder.addIntervalList(subtype.subtypeIntervalList);
    }
    for (var subtype in info.directMixers) {
      _topDownSortVisit(subtype);
      submixtureSetBuilder.addIntervalList(subtype.submixtureIntervalList);
      subtypeSetBuilder.addIntervalList(subtype.subtypeIntervalList);
    }
    for (var subtype in info.directImplementers) {
      _topDownSortVisit(subtype);
      subtypeSetBuilder.addIntervalList(subtype.subtypeIntervalList);
    }
    info.subclassIntervalList = subclassSetBuilder.buildIntervalList();
    info.submixtureIntervalList = isMixedIn
        ? submixtureSetBuilder.buildIntervalList()
        : info.subclassIntervalList;
    info.subtypeIntervalList = subtypeSetBuilder.buildIntervalList();
  }

  static int _countClasses(Program program) {
    int count = 0;
    for (var library in program.libraries) {
      count += library.classes.length;
    }
    return count;
  }

  /// Creates a histogram such that index `N` contains the number of classes
  /// that have `N` intervals in its subclass or subtype set (whichever is
  /// larger).
  ///
  /// The more numbers are condensed near the beginning, the more efficient the
  /// internal data structure is.
  List<int> getExpenseHistogram() {
    var result = <int>[];
    for (Class class_ in classes) {
      var info = _infoFor[class_];
      int intervals = max(info.subclassIntervalList.length,
              info.subtypeIntervalList.length) ~/
          2;
      if (intervals >= result.length) {
        int oldLength = result.length;
        result.length = intervals + 1;
        result.fillRange(oldLength, result.length, 0);
      }
      result[intervals] += 1;
    }
    return result;
  }

  /// Returns the average number of intervals per subtype relation (less
  /// is better, 1.0 is bad).
  ///
  /// This is an estimate of the memory use compared to a data structure that
  /// enumerates all subclass/subtype pairs.
  double getCompressionRatio() {
    int intervals = 0;
    int sizes = 0;
    for (Class class_ in classes) {
      var info = _infoFor[class_];
      intervals += (info.subclassIntervalList.length +
              info.subtypeIntervalList.length) ~/
          2;
      sizes += _intervalListSize(info.subclassIntervalList) +
          _intervalListSize(info.subtypeIntervalList);
    }
    return sizes == 0 ? 1.0 : intervals / sizes;
  }

  /// Returns the number of entries in hash tables storing hierarchy data.
  int getSuperTypeHashTableSize() {
    int sum = 0;
    for (Class class_ in classes) {
      _ClassInfo info = _infoFor[class_];
      if (info.ownsGenericSuperTypeMap) {
        sum += _infoFor[class_].genericSuperTypes?.length ?? 0;
      }
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

  List<int> buildIntervalList() {
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

Member _findMemberByName(List<Member> members, Name name) {
  int low = 0, high = members.length - 1;
  while (low <= high) {
    int mid = low + ((high - low) >> 1);
    Member pivot = members[mid];
    int comparison = _compareNames(name, pivot.name);
    if (comparison < 0) {
      high = mid - 1;
    } else if (comparison > 0) {
      low = mid + 1;
    } else {
      return pivot;
    }
  }
  return null;
}

/// Compares members by name.
int _compareMembers(Member first, Member second) {
  return _compareNames(first.name, second.name);
}

/// Compares names using an arbitrary as-fast-as-possible sorting criterion.
int _compareNames(Name firstName, Name secondName) {
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

class _ClassInfo {
  final Class classNode;
  int topologicalIndex = 0;
  int topDownIndex = -1;
  bool isBeingVisited = false;

  // Super types must always occur before subtypes in these lists.
  // For example:
  //
  //   class A extends Object
  //   class B extends Object implements A
  //
  // Here `A` must occur before `B` in the list of direct extenders of Object,
  // because `B` is a subtype of `A`.
  final List<_ClassInfo> directExtenders = <_ClassInfo>[];
  final List<_ClassInfo> directMixers = <_ClassInfo>[];
  final List<_ClassInfo> directImplementers = <_ClassInfo>[];

  /// Top-down indices of all subclasses of this class, represented as
  /// interleaved begin/end interval end points.
  Uint32List subclassIntervalList;
  Uint32List submixtureIntervalList;
  Uint32List subtypeIntervalList;

  bool isSubclassOf(_ClassInfo other) {
    return _intervalListContains(other.subclassIntervalList, topDownIndex);
  }

  bool isSubmixtureOf(_ClassInfo other) {
    return _intervalListContains(other.submixtureIntervalList, topDownIndex);
  }

  bool isSubtypeOf(_ClassInfo other) {
    return _intervalListContains(other.subtypeIntervalList, topDownIndex);
  }

  /// Maps generic supertype classes to the instantiation implemented by this
  /// class.
  ///
  /// E.g. `List` maps to `List<String>` for a class that directly of indirectly
  /// implements `List<String>`.
  ///
  /// However, the map may contain additional entries for classes that are not
  /// supertypes of this class, so that a single map object can be shared
  /// between different classes.  Lookups into the map should therefore be
  /// guarded by a subtype check.
  ///
  /// For example:
  ///
  ///     class Q<T>
  ///     class A<T>
  ///
  ///     class B extends A<String>
  ///     class C extends B implements Q<int>
  ///
  /// In this case, a single map object `{A: A<String>, Q: Q<int>}` may be
  /// shared by the classes `B` and `C`.
  Map<Class, InterfaceType> genericSuperTypes;

  /// If true, this is the current "owner" of [genericSuperTypes], meaning
  /// we may add additional entries to the map or transfer ownership to another
  /// class.
  bool ownsGenericSuperTypeMap = true;

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
}
