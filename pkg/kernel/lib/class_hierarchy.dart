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

  NormalClass get rootClass => classes[0];

  int indexOf(Class class_) => _infoFor[class_].topologicalIndex;

  /// True if [subclass] inherits from [superClass] though zero or more
  /// `extends` relationships.
  bool isSubclassOf(Class subclass, Class superClass) {
    if (identical(subclass, superClass)) return true;
    return _infoFor[subclass].isSubclassOf(_infoFor[superClass]);
  }

  /// True if [submixture] inherits from [superClass] though zero or more
  /// `extends` and `with` relationships.
  bool isSubmixtureOf(Class submixture, Class superClass) {
    if (identical(submixture, superClass)) return true;
    return _infoFor[submixture].isSubmixtureOf(_infoFor[superClass]);
  }

  /// True if [subtype] inherits from [superClass] though zero or more
  /// `extends`, `with`, and `implements` relationships.
  bool isSubtypeOf(Class subtype, Class superClass) {
    if (identical(subtype, superClass)) return true;
    return _infoFor[subtype].isSubtypeOf(_infoFor[superClass]);
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

  /// Returns the instantiation of [superType] that is implemented by [type],
  /// or `null` if [type] does not implement [superType] at all.
  InterfaceType getClassAsInstanceOf(Class type, Class superType) {
    if (identical(type, superType)) return type.thisType;
    _ClassInfo info = _infoFor[type];
    _ClassInfo superInfo = _infoFor[superType];
    if (!info.isSubtypeOf(superInfo)) return null;
    if (superType.typeParameters.isEmpty) return superType.rawType;
    return info.genericSuperTypes[superType];
  }

  /// Returns the instantiation of [superType] that is implemented by [type],
  /// or `null` if [type] does not implement [superType] at all.
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superType) {
    InterfaceType castedType = getClassAsInstanceOf(type.classNode, superType);
    if (castedType == null) return null;
    return substitutePairwise(castedType,
        type.classNode.typeParameters,
        type.typeArguments);
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
      if (class_.superType != null) {
        _infoFor[class_.superType.classNode].directExtenders.add(info);
      }
      if (class_.mixedInType != null) {
        _infoFor[class_.mixedInType.classNode].directMixers.add(info);
      }
      for (var superType in class_.implementedTypes) {
        _infoFor[superType.classNode].directImplementers.add(info);
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
    if (classNode.superType != null) {
      _topologicalSortVisit(classNode.superType.classNode);
      _recordSuperTypes(info, classNode.superType);
    }
    if (classNode.mixedInType != null) {
      _topologicalSortVisit(classNode.mixedInType.classNode);
      _recordSuperTypes(info, classNode.mixedInType);
    }
    for (var superType in classNode.implementedTypes) {
      _topologicalSortVisit(superType.classNode);
      _recordSuperTypes(info, superType);
    }
    int id = _topSortIndex++;
    info.topologicalIndex = id;
    classes[id] = info.classNode;
    info.isBeingVisited = false;
  }

  void _recordSuperTypes(_ClassInfo subInfo, InterfaceType superType) {
    _ClassInfo superInfo = _infoFor[superType.classNode];
    if (superType.typeArguments.isEmpty) {
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
      // free variables with those provided in [superType].
      Class superClass = superType.classNode;
      var substitution = new Map<TypeParameter, DartType>.fromIterables(
          superClass.typeParameters, superType.typeArguments);
      subInfo.genericSuperTypes ??= <Class, InterfaceType>{};
      superInfo.genericSuperTypes?.forEach((Class key, InterfaceType type) {
        subInfo.genericSuperTypes[key] = substitute(type, substitution);
      });
      subInfo.genericSuperTypes[superClass] = superType;
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

  _ClassInfo(this.classNode);
}
