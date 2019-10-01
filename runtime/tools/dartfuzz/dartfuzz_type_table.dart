// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Class that represents some common Dart types.
///
/// NOTE: this code has been generated automatically.
///
class DartType {
  final String name;
  const DartType._withName(this.name);
  factory DartType.fromDartConfig(
      {bool enableFp = false, bool disableNesting = false}) {
    if (enableFp && !disableNesting) {
      return DartType();
    } else if (!enableFp && !disableNesting) {
      return DartTypeNoFp();
    } else if (enableFp && disableNesting) {
      return DartTypeFlatTp();
    } else {
      return DartTypeNoFpFlatTp();
    }
  }
  const DartType() : name = null;
  static bool isListType(DartType tp) {
    return DartType._listTypes.contains(tp);
  }

  static bool isMapType(DartType tp) {
    return DartType._mapTypes.contains(tp);
  }

  static bool isCollectionType(DartType tp) {
    return DartType._collectionTypes.contains(tp);
  }

  static bool isGrowableType(DartType tp) {
    return DartType._growableTypes.contains(tp);
  }

  static bool isComplexType(DartType tp) {
    return DartType._complexTypes.contains(tp);
  }

  bool isInterfaceOfType(DartType tp, DartType iTp) {
    return _interfaceRels.containsKey(iTp) && _interfaceRels[iTp].contains(tp);
  }

  Set<DartType> get mapTypes {
    return _mapTypes;
  }

  bool isSpecializable(DartType tp) {
    return _interfaceRels.containsKey(tp);
  }

  Set<DartType> interfaces(DartType tp) {
    if (_interfaceRels.containsKey(tp)) {
      return _interfaceRels[tp];
    }
    return null;
  }

  DartType indexType(DartType tp) {
    if (_indexedBy.containsKey(tp)) {
      return _indexedBy[tp];
    }
    return null;
  }

  Set<DartType> indexableElementTypes(DartType tp) {
    if (_indexableElementOf.containsKey(tp)) {
      return _indexableElementOf[tp];
    }
    return null;
  }

  bool isIndexableElementType(DartType tp) {
    return _indexableElementOf.containsKey(tp);
  }

  DartType elementType(DartType tp) {
    if (_subscriptsTo.containsKey(tp)) {
      return _subscriptsTo[tp];
    }
    return null;
  }

  Set<DartType> get iterableTypes1 {
    return _iterableTypes1;
  }

  Set<String> uniOps(DartType tp) {
    if (_uniOps.containsKey(tp)) {
      return _uniOps[tp];
    }
    return <String>{};
  }

  Set<String> binOps(DartType tp) {
    if (_binOps.containsKey(tp)) {
      return _binOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<List<DartType>> binOpParameters(DartType tp, String op) {
    if (_binOps.containsKey(tp) && _binOps[tp].containsKey(op)) {
      return _binOps[tp][op];
    }
    return null;
  }

  Set<String> assignOps(DartType tp) {
    if (_assignOps.containsKey(tp)) {
      return _assignOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<DartType> assignOpRhs(DartType tp, String op) {
    if (_assignOps.containsKey(tp) && _assignOps[tp].containsKey(op)) {
      return _assignOps[tp][op];
    }
    return <DartType>{};
  }

  bool hasConstructor(DartType tp) {
    return _constructors.containsKey(tp);
  }

  Set<String> constructors(DartType tp) {
    if (_constructors.containsKey(tp)) {
      return _constructors[tp].keys.toSet();
    }
    return <String>{};
  }

  List<DartType> constructorParameters(DartType tp, String constructor) {
    if (_constructors.containsKey(tp) &&
        _constructors[tp].containsKey(constructor)) {
      return _constructors[tp][constructor];
    }
    return null;
  }

  Set<DartType> get allTypes {
    return _allTypes;
  }

  static const INT8LIST = const DartType._withName("Int8List");
  static const UINT8LIST = const DartType._withName("Uint8List");
  static const UINT8CLAMPEDLIST = const DartType._withName("Uint8ClampedList");
  static const INT16LIST = const DartType._withName("Int16List");
  static const UINT16LIST = const DartType._withName("Uint16List");
  static const INT32LIST = const DartType._withName("Int32List");
  static const UINT32LIST = const DartType._withName("Uint32List");
  static const INT64LIST = const DartType._withName("Int64List");
  static const UINT64LIST = const DartType._withName("Uint64List");
  static const FLOAT32LIST = const DartType._withName("Float32List");
  static const FLOAT64LIST = const DartType._withName("Float64List");
  static const FLOAT32X4LIST = const DartType._withName("Float32x4List");
  static const INT32X4LIST = const DartType._withName("Int32x4List");
  static const FLOAT64X2LIST = const DartType._withName("Float64x2List");
  static const FLOAT32X4 = const DartType._withName("Float32x4");
  static const INT32X4 = const DartType._withName("Int32x4");
  static const FLOAT64X2 = const DartType._withName("Float64x2");
  static const BOOL = const DartType._withName("bool");
  static const DOUBLE = const DartType._withName("double");
  static const DURATION = const DartType._withName("Duration");
  static const INT = const DartType._withName("int");
  static const NUM = const DartType._withName("num");
  static const STRING = const DartType._withName("String");
  static const LIST_DOUBLE = const DartType._withName("List<double>");
  static const LIST_INT = const DartType._withName("List<int>");
  static const LIST_NUM = const DartType._withName("List<num>");
  static const LIST_STRING = const DartType._withName("List<String>");
  static const SET_BOOL = const DartType._withName("Set<bool>");
  static const SET_DOUBLE = const DartType._withName("Set<double>");
  static const SET_INT = const DartType._withName("Set<int>");
  static const SET_NUM = const DartType._withName("Set<num>");
  static const SET_STRING = const DartType._withName("Set<String>");
  static const MAP_BOOL_BOOL = const DartType._withName("Map<bool, bool>");
  static const MAP_BOOL_INT = const DartType._withName("Map<bool, int>");
  static const MAP_BOOL_NUM = const DartType._withName("Map<bool, num>");
  static const MAP_BOOL_STRING = const DartType._withName("Map<bool, String>");
  static const MAP_DOUBLE_BOOL = const DartType._withName("Map<double, bool>");
  static const MAP_DOUBLE_DOUBLE =
      const DartType._withName("Map<double, double>");
  static const MAP_DOUBLE_INT = const DartType._withName("Map<double, int>");
  static const MAP_DOUBLE_NUM = const DartType._withName("Map<double, num>");
  static const MAP_DOUBLE_STRING =
      const DartType._withName("Map<double, String>");
  static const MAP_INT_BOOL = const DartType._withName("Map<int, bool>");
  static const MAP_INT_DOUBLE = const DartType._withName("Map<int, double>");
  static const MAP_INT_INT = const DartType._withName("Map<int, int>");
  static const MAP_INT_STRING = const DartType._withName("Map<int, String>");
  static const MAP_NUM_BOOL = const DartType._withName("Map<num, bool>");
  static const MAP_NUM_DOUBLE = const DartType._withName("Map<num, double>");
  static const MAP_NUM_INT = const DartType._withName("Map<num, int>");
  static const MAP_NUM_NUM = const DartType._withName("Map<num, num>");
  static const MAP_NUM_STRING = const DartType._withName("Map<num, String>");
  static const MAP_STRING_BOOL = const DartType._withName("Map<String, bool>");
  static const MAP_STRING_DOUBLE =
      const DartType._withName("Map<String, double>");
  static const MAP_STRING_INT = const DartType._withName("Map<String, int>");
  static const MAP_STRING_NUM = const DartType._withName("Map<String, num>");
  static const SET_LIST_INT = const DartType._withName("Set<List<int>>");
  static const MAP_BOOL_SET_STRING =
      const DartType._withName("Map<bool, Set<String>>");
  static const MAP_DOUBLE_MAP_DOUBLE_INT =
      const DartType._withName("Map<double, Map<double, int>>");
  static const MAP_INT_MAP_NUM_BOOL =
      const DartType._withName("Map<int, Map<num, bool>>");
  static const MAP_NUM_MAP_STRING_DOUBLE =
      const DartType._withName("Map<num, Map<String, double>>");
  static const MAP_LIST_DOUBLE_STRING =
      const DartType._withName("Map<List<double>, String>");
  static const MAP_LIST_INT_SET_INT =
      const DartType._withName("Map<List<int>, Set<int>>");
  static const MAP_LIST_NUM_MAP_DOUBLE_BOOL =
      const DartType._withName("Map<List<num>, Map<double, bool>>");
  static const MAP_LIST_STRING_MAP_INT_DOUBLE =
      const DartType._withName("Map<List<String>, Map<int, double>>");
  static const MAP_SET_BOOL_MAP_NUM_STRING =
      const DartType._withName("Map<Set<bool>, Map<num, String>>");
  static const MAP_SET_INT_INT = const DartType._withName("Map<Set<int>, int>");
  static const MAP_SET_NUM_SET_BOOL =
      const DartType._withName("Map<Set<num>, Set<bool>>");
  static const MAP_SET_STRING_MAP_BOOL_INT =
      const DartType._withName("Map<Set<String>, Map<bool, int>>");
  static const MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING =
      const DartType._withName("Map<Map<bool, bool>, Map<double, String>>");
  static const MAP_MAP_BOOL_INT_MAP_NUM_INT =
      const DartType._withName("Map<Map<bool, int>, Map<num, int>>");
  static const MAP_MAP_BOOL_STRING_BOOL =
      const DartType._withName("Map<Map<bool, String>, bool>");
  static const MAP_MAP_DOUBLE_BOOL_LIST_INT =
      const DartType._withName("Map<Map<double, bool>, List<int>>");
  static const MAP_MAP_DOUBLE_DOUBLE_SET_STRING =
      const DartType._withName("Map<Map<double, double>, Set<String>>");
  static const MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT =
      const DartType._withName("Map<Map<double, int>, Map<double, int>>");
  static const MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL =
      const DartType._withName("Map<Map<double, num>, Map<num, bool>>");
  static const MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE =
      const DartType._withName("Map<Map<double, String>, Map<String, double>>");
  static const MAP_MAP_INT_DOUBLE_STRING =
      const DartType._withName("Map<Map<int, double>, String>");
  static const MAP_MAP_INT_INT_SET_INT =
      const DartType._withName("Map<Map<int, int>, Set<int>>");
  static const MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL =
      const DartType._withName("Map<Map<int, String>, Map<double, bool>>");
  static const MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE =
      const DartType._withName("Map<Map<num, bool>, Map<int, double>>");
  static const MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING =
      const DartType._withName("Map<Map<num, double>, Map<num, String>>");
  static const MAP_MAP_NUM_NUM_INT =
      const DartType._withName("Map<Map<num, num>, int>");
  static const MAP_MAP_NUM_STRING_SET_BOOL =
      const DartType._withName("Map<Map<num, String>, Set<bool>>");
  static const MAP_MAP_STRING_BOOL_MAP_BOOL_INT =
      const DartType._withName("Map<Map<String, bool>, Map<bool, int>>");
  static const MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING =
      const DartType._withName("Map<Map<String, double>, Map<double, String>>");
  static const MAP_MAP_STRING_INT_MAP_NUM_INT =
      const DartType._withName("Map<Map<String, int>, Map<num, int>>");

  // NON INSTANTIABLE
  static const EFFICIENTLENGTHITERABLE_INT =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_INT");
  static const _TYPEDINTLIST = const DartType._withName("___TYPEDINTLIST");
  static const OBJECT = const DartType._withName("__OBJECT");
  static const TYPEDDATA = const DartType._withName("__TYPEDDATA");
  static const ITERABLE_INT = const DartType._withName("__ITERABLE_INT");
  static const EFFICIENTLENGTHITERABLE_DOUBLE =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_DOUBLE");
  static const _TYPEDFLOATLIST = const DartType._withName("___TYPEDFLOATLIST");
  static const ITERABLE_DOUBLE = const DartType._withName("__ITERABLE_DOUBLE");
  static const LIST_FLOAT32X4 = const DartType._withName("__LIST_FLOAT32X4");
  static const EFFICIENTLENGTHITERABLE_FLOAT32X4 =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_FLOAT32X4");
  static const ITERABLE_FLOAT32X4 =
      const DartType._withName("__ITERABLE_FLOAT32X4");
  static const LIST_INT32X4 = const DartType._withName("__LIST_INT32X4");
  static const EFFICIENTLENGTHITERABLE_INT32X4 =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_INT32X4");
  static const ITERABLE_INT32X4 =
      const DartType._withName("__ITERABLE_INT32X4");
  static const LIST_FLOAT64X2 = const DartType._withName("__LIST_FLOAT64X2");
  static const EFFICIENTLENGTHITERABLE_FLOAT64X2 =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_FLOAT64X2");
  static const ITERABLE_FLOAT64X2 =
      const DartType._withName("__ITERABLE_FLOAT64X2");
  static const COMPARABLE_NUM = const DartType._withName("__COMPARABLE_NUM");
  static const COMPARABLE_DURATION =
      const DartType._withName("__COMPARABLE_DURATION");
  static const COMPARABLE_STRING =
      const DartType._withName("__COMPARABLE_STRING");
  static const PATTERN = const DartType._withName("__PATTERN");
  static const EFFICIENTLENGTHITERABLE_E =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_E");
  static const ITERABLE_E = const DartType._withName("__ITERABLE_E");
  static const EFFICIENTLENGTHITERABLE_NUM =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_NUM");
  static const EFFICIENTLENGTHITERABLE_STRING =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_STRING");

  // All types extracted from analyzer.
  static const _allTypes = {
    INT8LIST,
    UINT8LIST,
    UINT8CLAMPEDLIST,
    INT16LIST,
    UINT16LIST,
    INT32LIST,
    UINT32LIST,
    INT64LIST,
    UINT64LIST,
    FLOAT32LIST,
    FLOAT64LIST,
    FLOAT32X4LIST,
    INT32X4LIST,
    FLOAT64X2LIST,
    FLOAT32X4,
    INT32X4,
    FLOAT64X2,
    BOOL,
    DOUBLE,
    DURATION,
    INT,
    NUM,
    STRING,
    LIST_DOUBLE,
    LIST_INT,
    LIST_NUM,
    LIST_STRING,
    SET_BOOL,
    SET_DOUBLE,
    SET_INT,
    SET_NUM,
    SET_STRING,
    MAP_BOOL_BOOL,
    MAP_BOOL_INT,
    MAP_BOOL_NUM,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_NUM,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_STRING,
    MAP_NUM_BOOL,
    MAP_NUM_DOUBLE,
    MAP_NUM_INT,
    MAP_NUM_NUM,
    MAP_NUM_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_NUM,
    SET_LIST_INT,
    MAP_BOOL_SET_STRING,
    MAP_DOUBLE_MAP_DOUBLE_INT,
    MAP_INT_MAP_NUM_BOOL,
    MAP_NUM_MAP_STRING_DOUBLE,
    MAP_LIST_DOUBLE_STRING,
    MAP_LIST_INT_SET_INT,
    MAP_LIST_NUM_MAP_DOUBLE_BOOL,
    MAP_LIST_STRING_MAP_INT_DOUBLE,
    MAP_SET_BOOL_MAP_NUM_STRING,
    MAP_SET_INT_INT,
    MAP_SET_NUM_SET_BOOL,
    MAP_SET_STRING_MAP_BOOL_INT,
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
    MAP_MAP_BOOL_INT_MAP_NUM_INT,
    MAP_MAP_BOOL_STRING_BOOL,
    MAP_MAP_DOUBLE_BOOL_LIST_INT,
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
    MAP_MAP_INT_DOUBLE_STRING,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
    MAP_MAP_NUM_NUM_INT,
    MAP_MAP_NUM_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_STRING_INT_MAP_NUM_INT,
  };

  // All List<E> types: LIST_INT, LIST_STRING, etc.
  static const Set<DartType> _listTypes = {
    INT8LIST,
    UINT8LIST,
    UINT8CLAMPEDLIST,
    INT16LIST,
    UINT16LIST,
    INT32LIST,
    UINT32LIST,
    INT64LIST,
    UINT64LIST,
    FLOAT32LIST,
    FLOAT64LIST,
    FLOAT32X4LIST,
    INT32X4LIST,
    FLOAT64X2LIST,
    LIST_DOUBLE,
    LIST_INT,
    LIST_NUM,
    LIST_STRING,
  };

  // All Set types: SET_INT, SET_STRING, etc.
  static const Set<DartType> _setTypes = {
    SET_BOOL,
    SET_DOUBLE,
    SET_INT,
    SET_NUM,
    SET_STRING,
    SET_LIST_INT,
  };

  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
  static const Set<DartType> _mapTypes = {
    MAP_BOOL_BOOL,
    MAP_BOOL_INT,
    MAP_BOOL_NUM,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_NUM,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_STRING,
    MAP_NUM_BOOL,
    MAP_NUM_DOUBLE,
    MAP_NUM_INT,
    MAP_NUM_NUM,
    MAP_NUM_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_NUM,
    MAP_BOOL_SET_STRING,
    MAP_DOUBLE_MAP_DOUBLE_INT,
    MAP_INT_MAP_NUM_BOOL,
    MAP_NUM_MAP_STRING_DOUBLE,
    MAP_LIST_DOUBLE_STRING,
    MAP_LIST_INT_SET_INT,
    MAP_LIST_NUM_MAP_DOUBLE_BOOL,
    MAP_LIST_STRING_MAP_INT_DOUBLE,
    MAP_SET_BOOL_MAP_NUM_STRING,
    MAP_SET_INT_INT,
    MAP_SET_NUM_SET_BOOL,
    MAP_SET_STRING_MAP_BOOL_INT,
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
    MAP_MAP_BOOL_INT_MAP_NUM_INT,
    MAP_MAP_BOOL_STRING_BOOL,
    MAP_MAP_DOUBLE_BOOL_LIST_INT,
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
    MAP_MAP_INT_DOUBLE_STRING,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
    MAP_MAP_NUM_NUM_INT,
    MAP_MAP_NUM_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_STRING_INT_MAP_NUM_INT,
  };

  // All collection types: list, map and set types.
  static const Set<DartType> _collectionTypes = {
    INT8LIST,
    UINT8LIST,
    UINT8CLAMPEDLIST,
    INT16LIST,
    UINT16LIST,
    INT32LIST,
    UINT32LIST,
    INT64LIST,
    UINT64LIST,
    FLOAT32LIST,
    FLOAT64LIST,
    FLOAT32X4LIST,
    INT32X4LIST,
    FLOAT64X2LIST,
    LIST_DOUBLE,
    LIST_INT,
    LIST_NUM,
    LIST_STRING,
    SET_BOOL,
    SET_DOUBLE,
    SET_INT,
    SET_NUM,
    SET_STRING,
    SET_LIST_INT,
    MAP_BOOL_BOOL,
    MAP_BOOL_INT,
    MAP_BOOL_NUM,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_NUM,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_STRING,
    MAP_NUM_BOOL,
    MAP_NUM_DOUBLE,
    MAP_NUM_INT,
    MAP_NUM_NUM,
    MAP_NUM_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_NUM,
    MAP_BOOL_SET_STRING,
    MAP_DOUBLE_MAP_DOUBLE_INT,
    MAP_INT_MAP_NUM_BOOL,
    MAP_NUM_MAP_STRING_DOUBLE,
    MAP_LIST_DOUBLE_STRING,
    MAP_LIST_INT_SET_INT,
    MAP_LIST_NUM_MAP_DOUBLE_BOOL,
    MAP_LIST_STRING_MAP_INT_DOUBLE,
    MAP_SET_BOOL_MAP_NUM_STRING,
    MAP_SET_INT_INT,
    MAP_SET_NUM_SET_BOOL,
    MAP_SET_STRING_MAP_BOOL_INT,
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
    MAP_MAP_BOOL_INT_MAP_NUM_INT,
    MAP_MAP_BOOL_STRING_BOOL,
    MAP_MAP_DOUBLE_BOOL_LIST_INT,
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
    MAP_MAP_INT_DOUBLE_STRING,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
    MAP_MAP_NUM_NUM_INT,
    MAP_MAP_NUM_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_STRING_INT_MAP_NUM_INT,
  };

  // All growable types: list, map, set and string types.
  static const Set<DartType> _growableTypes = {
    INT8LIST,
    UINT8LIST,
    UINT8CLAMPEDLIST,
    INT16LIST,
    UINT16LIST,
    INT32LIST,
    UINT32LIST,
    INT64LIST,
    UINT64LIST,
    FLOAT32LIST,
    FLOAT64LIST,
    FLOAT32X4LIST,
    INT32X4LIST,
    FLOAT64X2LIST,
    LIST_DOUBLE,
    LIST_INT,
    LIST_NUM,
    LIST_STRING,
    SET_BOOL,
    SET_DOUBLE,
    SET_INT,
    SET_NUM,
    SET_STRING,
    SET_LIST_INT,
    MAP_BOOL_BOOL,
    MAP_BOOL_INT,
    MAP_BOOL_NUM,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_NUM,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_STRING,
    MAP_NUM_BOOL,
    MAP_NUM_DOUBLE,
    MAP_NUM_INT,
    MAP_NUM_NUM,
    MAP_NUM_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_NUM,
    MAP_BOOL_SET_STRING,
    MAP_DOUBLE_MAP_DOUBLE_INT,
    MAP_INT_MAP_NUM_BOOL,
    MAP_NUM_MAP_STRING_DOUBLE,
    MAP_LIST_DOUBLE_STRING,
    MAP_LIST_INT_SET_INT,
    MAP_LIST_NUM_MAP_DOUBLE_BOOL,
    MAP_LIST_STRING_MAP_INT_DOUBLE,
    MAP_SET_BOOL_MAP_NUM_STRING,
    MAP_SET_INT_INT,
    MAP_SET_NUM_SET_BOOL,
    MAP_SET_STRING_MAP_BOOL_INT,
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
    MAP_MAP_BOOL_INT_MAP_NUM_INT,
    MAP_MAP_BOOL_STRING_BOOL,
    MAP_MAP_DOUBLE_BOOL_LIST_INT,
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
    MAP_MAP_INT_DOUBLE_STRING,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
    MAP_MAP_NUM_NUM_INT,
    MAP_MAP_NUM_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_STRING_INT_MAP_NUM_INT,
    STRING,
  };

  // All floating point types: DOUBLE, SET_DOUBLE, MAP_X_DOUBLE, etc.
  static const Set<DartType> _fpTypes = {
    FLOAT32LIST,
    FLOAT64LIST,
    FLOAT32X4LIST,
    FLOAT64X2LIST,
    FLOAT32X4,
    FLOAT64X2,
    DOUBLE,
    LIST_DOUBLE,
    SET_DOUBLE,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_NUM,
    MAP_DOUBLE_STRING,
    MAP_INT_DOUBLE,
    MAP_NUM_DOUBLE,
    MAP_STRING_DOUBLE,
    MAP_DOUBLE_MAP_DOUBLE_INT,
    MAP_NUM_MAP_STRING_DOUBLE,
    MAP_LIST_DOUBLE_STRING,
    MAP_LIST_NUM_MAP_DOUBLE_BOOL,
    MAP_LIST_STRING_MAP_INT_DOUBLE,
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
    MAP_MAP_DOUBLE_BOOL_LIST_INT,
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
    MAP_MAP_INT_DOUBLE_STRING,
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
  };

  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.
  static const Set<DartType> _indexableTypes = {
    INT8LIST,
    UINT8LIST,
    UINT8CLAMPEDLIST,
    INT16LIST,
    UINT16LIST,
    INT32LIST,
    UINT32LIST,
    INT64LIST,
    UINT64LIST,
    FLOAT32LIST,
    FLOAT64LIST,
    FLOAT32X4LIST,
    INT32X4LIST,
    FLOAT64X2LIST,
    LIST_DOUBLE,
    LIST_INT,
    LIST_NUM,
    LIST_STRING,
    MAP_BOOL_BOOL,
    MAP_BOOL_INT,
    MAP_BOOL_NUM,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_NUM,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_STRING,
    MAP_NUM_BOOL,
    MAP_NUM_DOUBLE,
    MAP_NUM_INT,
    MAP_NUM_NUM,
    MAP_NUM_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_NUM,
    MAP_BOOL_SET_STRING,
    MAP_DOUBLE_MAP_DOUBLE_INT,
    MAP_INT_MAP_NUM_BOOL,
    MAP_NUM_MAP_STRING_DOUBLE,
    MAP_LIST_DOUBLE_STRING,
    MAP_LIST_INT_SET_INT,
    MAP_LIST_NUM_MAP_DOUBLE_BOOL,
    MAP_LIST_STRING_MAP_INT_DOUBLE,
    MAP_SET_BOOL_MAP_NUM_STRING,
    MAP_SET_INT_INT,
    MAP_SET_NUM_SET_BOOL,
    MAP_SET_STRING_MAP_BOOL_INT,
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
    MAP_MAP_BOOL_INT_MAP_NUM_INT,
    MAP_MAP_BOOL_STRING_BOOL,
    MAP_MAP_DOUBLE_BOOL_LIST_INT,
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
    MAP_MAP_INT_DOUBLE_STRING,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
    MAP_MAP_NUM_NUM_INT,
    MAP_MAP_NUM_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_STRING_INT_MAP_NUM_INT,
  };

  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.
  static const Map<DartType, DartType> _subscriptsTo = {
    INT8LIST: INT,
    UINT8LIST: INT,
    UINT8CLAMPEDLIST: INT,
    INT16LIST: INT,
    UINT16LIST: INT,
    INT32LIST: INT,
    UINT32LIST: INT,
    INT64LIST: INT,
    UINT64LIST: INT,
    FLOAT32LIST: DOUBLE,
    FLOAT64LIST: DOUBLE,
    FLOAT32X4LIST: FLOAT32X4,
    INT32X4LIST: INT32X4,
    FLOAT64X2LIST: FLOAT64X2,
    DURATION: DURATION,
    NUM: NUM,
    STRING: STRING,
    LIST_DOUBLE: DOUBLE,
    LIST_INT: INT,
    LIST_NUM: NUM,
    LIST_STRING: STRING,
    SET_BOOL: BOOL,
    SET_DOUBLE: DOUBLE,
    SET_INT: INT,
    SET_NUM: NUM,
    SET_STRING: STRING,
    MAP_BOOL_BOOL: BOOL,
    MAP_BOOL_INT: INT,
    MAP_BOOL_NUM: NUM,
    MAP_BOOL_STRING: STRING,
    MAP_DOUBLE_BOOL: BOOL,
    MAP_DOUBLE_DOUBLE: DOUBLE,
    MAP_DOUBLE_INT: INT,
    MAP_DOUBLE_NUM: NUM,
    MAP_DOUBLE_STRING: STRING,
    MAP_INT_BOOL: BOOL,
    MAP_INT_DOUBLE: DOUBLE,
    MAP_INT_INT: INT,
    MAP_INT_STRING: STRING,
    MAP_NUM_BOOL: BOOL,
    MAP_NUM_DOUBLE: DOUBLE,
    MAP_NUM_INT: INT,
    MAP_NUM_NUM: NUM,
    MAP_NUM_STRING: STRING,
    MAP_STRING_BOOL: BOOL,
    MAP_STRING_DOUBLE: DOUBLE,
    MAP_STRING_INT: INT,
    MAP_STRING_NUM: NUM,
    SET_LIST_INT: LIST_INT,
    MAP_BOOL_SET_STRING: SET_STRING,
    MAP_DOUBLE_MAP_DOUBLE_INT: MAP_DOUBLE_INT,
    MAP_INT_MAP_NUM_BOOL: MAP_NUM_BOOL,
    MAP_NUM_MAP_STRING_DOUBLE: MAP_STRING_DOUBLE,
    MAP_LIST_DOUBLE_STRING: STRING,
    MAP_LIST_INT_SET_INT: SET_INT,
    MAP_LIST_NUM_MAP_DOUBLE_BOOL: MAP_DOUBLE_BOOL,
    MAP_LIST_STRING_MAP_INT_DOUBLE: MAP_INT_DOUBLE,
    MAP_SET_BOOL_MAP_NUM_STRING: MAP_NUM_STRING,
    MAP_SET_INT_INT: INT,
    MAP_SET_NUM_SET_BOOL: SET_BOOL,
    MAP_SET_STRING_MAP_BOOL_INT: MAP_BOOL_INT,
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING: MAP_DOUBLE_STRING,
    MAP_MAP_BOOL_INT_MAP_NUM_INT: MAP_NUM_INT,
    MAP_MAP_BOOL_STRING_BOOL: BOOL,
    MAP_MAP_DOUBLE_BOOL_LIST_INT: LIST_INT,
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING: SET_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT: MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL: MAP_NUM_BOOL,
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE: MAP_STRING_DOUBLE,
    MAP_MAP_INT_DOUBLE_STRING: STRING,
    MAP_MAP_INT_INT_SET_INT: SET_INT,
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL: MAP_DOUBLE_BOOL,
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE: MAP_INT_DOUBLE,
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING: MAP_NUM_STRING,
    MAP_MAP_NUM_NUM_INT: INT,
    MAP_MAP_NUM_STRING_SET_BOOL: SET_BOOL,
    MAP_MAP_STRING_BOOL_MAP_BOOL_INT: MAP_BOOL_INT,
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING: MAP_DOUBLE_STRING,
    MAP_MAP_STRING_INT_MAP_NUM_INT: MAP_NUM_INT,
  };

  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.
  static const Map<DartType, DartType> _indexedBy = {
    INT8LIST: INT,
    UINT8LIST: INT,
    UINT8CLAMPEDLIST: INT,
    INT16LIST: INT,
    UINT16LIST: INT,
    INT32LIST: INT,
    UINT32LIST: INT,
    INT64LIST: INT,
    UINT64LIST: INT,
    FLOAT32LIST: INT,
    FLOAT64LIST: INT,
    FLOAT32X4LIST: INT,
    INT32X4LIST: INT,
    FLOAT64X2LIST: INT,
    LIST_DOUBLE: INT,
    LIST_INT: INT,
    LIST_NUM: INT,
    LIST_STRING: INT,
    MAP_BOOL_BOOL: BOOL,
    MAP_BOOL_INT: BOOL,
    MAP_BOOL_NUM: BOOL,
    MAP_BOOL_STRING: BOOL,
    MAP_DOUBLE_BOOL: DOUBLE,
    MAP_DOUBLE_DOUBLE: DOUBLE,
    MAP_DOUBLE_INT: DOUBLE,
    MAP_DOUBLE_NUM: DOUBLE,
    MAP_DOUBLE_STRING: DOUBLE,
    MAP_INT_BOOL: INT,
    MAP_INT_DOUBLE: INT,
    MAP_INT_INT: INT,
    MAP_INT_STRING: INT,
    MAP_NUM_BOOL: NUM,
    MAP_NUM_DOUBLE: NUM,
    MAP_NUM_INT: NUM,
    MAP_NUM_NUM: NUM,
    MAP_NUM_STRING: NUM,
    MAP_STRING_BOOL: STRING,
    MAP_STRING_DOUBLE: STRING,
    MAP_STRING_INT: STRING,
    MAP_STRING_NUM: STRING,
    MAP_BOOL_SET_STRING: BOOL,
    MAP_DOUBLE_MAP_DOUBLE_INT: DOUBLE,
    MAP_INT_MAP_NUM_BOOL: INT,
    MAP_NUM_MAP_STRING_DOUBLE: NUM,
    MAP_LIST_DOUBLE_STRING: LIST_DOUBLE,
    MAP_LIST_INT_SET_INT: LIST_INT,
    MAP_LIST_NUM_MAP_DOUBLE_BOOL: LIST_NUM,
    MAP_LIST_STRING_MAP_INT_DOUBLE: LIST_STRING,
    MAP_SET_BOOL_MAP_NUM_STRING: SET_BOOL,
    MAP_SET_INT_INT: SET_INT,
    MAP_SET_NUM_SET_BOOL: SET_NUM,
    MAP_SET_STRING_MAP_BOOL_INT: SET_STRING,
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING: MAP_BOOL_BOOL,
    MAP_MAP_BOOL_INT_MAP_NUM_INT: MAP_BOOL_INT,
    MAP_MAP_BOOL_STRING_BOOL: MAP_BOOL_STRING,
    MAP_MAP_DOUBLE_BOOL_LIST_INT: MAP_DOUBLE_BOOL,
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING: MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT: MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL: MAP_DOUBLE_NUM,
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE: MAP_DOUBLE_STRING,
    MAP_MAP_INT_DOUBLE_STRING: MAP_INT_DOUBLE,
    MAP_MAP_INT_INT_SET_INT: MAP_INT_INT,
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL: MAP_INT_STRING,
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE: MAP_NUM_BOOL,
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING: MAP_NUM_DOUBLE,
    MAP_MAP_NUM_NUM_INT: MAP_NUM_NUM,
    MAP_MAP_NUM_STRING_SET_BOOL: MAP_NUM_STRING,
    MAP_MAP_STRING_BOOL_MAP_BOOL_INT: MAP_STRING_BOOL,
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING: MAP_STRING_DOUBLE,
    MAP_MAP_STRING_INT_MAP_NUM_INT: MAP_STRING_INT,
  };

  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>
  static const Map<DartType, Set<DartType>> _elementOf = {
    INT: {
      INT8LIST,
      UINT8LIST,
      UINT8CLAMPEDLIST,
      INT16LIST,
      UINT16LIST,
      INT32LIST,
      UINT32LIST,
      INT64LIST,
      UINT64LIST,
      LIST_INT,
      SET_INT,
      MAP_BOOL_INT,
      MAP_DOUBLE_INT,
      MAP_INT_INT,
      MAP_NUM_INT,
      MAP_STRING_INT,
      MAP_SET_INT_INT,
      MAP_MAP_NUM_NUM_INT,
    },
    DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
      LIST_DOUBLE,
      SET_DOUBLE,
      MAP_DOUBLE_DOUBLE,
      MAP_INT_DOUBLE,
      MAP_NUM_DOUBLE,
      MAP_STRING_DOUBLE,
    },
    FLOAT32X4: {
      FLOAT32X4LIST,
    },
    INT32X4: {
      INT32X4LIST,
    },
    FLOAT64X2: {
      FLOAT64X2LIST,
    },
    DURATION: {
      DURATION,
    },
    NUM: {
      NUM,
      LIST_NUM,
      SET_NUM,
      MAP_BOOL_NUM,
      MAP_DOUBLE_NUM,
      MAP_NUM_NUM,
      MAP_STRING_NUM,
    },
    STRING: {
      STRING,
      LIST_STRING,
      SET_STRING,
      MAP_BOOL_STRING,
      MAP_DOUBLE_STRING,
      MAP_INT_STRING,
      MAP_NUM_STRING,
      MAP_LIST_DOUBLE_STRING,
      MAP_MAP_INT_DOUBLE_STRING,
    },
    BOOL: {
      SET_BOOL,
      MAP_BOOL_BOOL,
      MAP_DOUBLE_BOOL,
      MAP_INT_BOOL,
      MAP_NUM_BOOL,
      MAP_STRING_BOOL,
      MAP_MAP_BOOL_STRING_BOOL,
    },
    LIST_INT: {
      SET_LIST_INT,
      MAP_MAP_DOUBLE_BOOL_LIST_INT,
    },
    SET_STRING: {
      MAP_BOOL_SET_STRING,
      MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
    },
    MAP_DOUBLE_INT: {
      MAP_DOUBLE_MAP_DOUBLE_INT,
      MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
    },
    MAP_NUM_BOOL: {
      MAP_INT_MAP_NUM_BOOL,
      MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
    },
    MAP_STRING_DOUBLE: {
      MAP_NUM_MAP_STRING_DOUBLE,
      MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
    },
    SET_INT: {
      MAP_LIST_INT_SET_INT,
      MAP_MAP_INT_INT_SET_INT,
    },
    MAP_DOUBLE_BOOL: {
      MAP_LIST_NUM_MAP_DOUBLE_BOOL,
      MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
    },
    MAP_INT_DOUBLE: {
      MAP_LIST_STRING_MAP_INT_DOUBLE,
      MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
    },
    MAP_NUM_STRING: {
      MAP_SET_BOOL_MAP_NUM_STRING,
      MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
    },
    SET_BOOL: {
      MAP_SET_NUM_SET_BOOL,
      MAP_MAP_NUM_STRING_SET_BOOL,
    },
    MAP_BOOL_INT: {
      MAP_SET_STRING_MAP_BOOL_INT,
      MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    },
    MAP_DOUBLE_STRING: {
      MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
      MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
    },
    MAP_NUM_INT: {
      MAP_MAP_BOOL_INT_MAP_NUM_INT,
      MAP_MAP_STRING_INT_MAP_NUM_INT,
    },
  };

  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.
  static const Map<DartType, Set<DartType>> _indexableElementOf = {
    INT: {
      INT8LIST,
      UINT8LIST,
      UINT8CLAMPEDLIST,
      INT16LIST,
      UINT16LIST,
      INT32LIST,
      UINT32LIST,
      INT64LIST,
      UINT64LIST,
      LIST_INT,
      MAP_BOOL_INT,
      MAP_DOUBLE_INT,
      MAP_INT_INT,
      MAP_NUM_INT,
      MAP_STRING_INT,
      MAP_SET_INT_INT,
      MAP_MAP_NUM_NUM_INT,
    },
    DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
      LIST_DOUBLE,
      MAP_DOUBLE_DOUBLE,
      MAP_INT_DOUBLE,
      MAP_NUM_DOUBLE,
      MAP_STRING_DOUBLE,
    },
    FLOAT32X4: {
      FLOAT32X4LIST,
    },
    INT32X4: {
      INT32X4LIST,
    },
    FLOAT64X2: {
      FLOAT64X2LIST,
    },
    NUM: {
      LIST_NUM,
      MAP_BOOL_NUM,
      MAP_DOUBLE_NUM,
      MAP_NUM_NUM,
      MAP_STRING_NUM,
    },
    STRING: {
      LIST_STRING,
      MAP_BOOL_STRING,
      MAP_DOUBLE_STRING,
      MAP_INT_STRING,
      MAP_NUM_STRING,
      MAP_LIST_DOUBLE_STRING,
      MAP_MAP_INT_DOUBLE_STRING,
    },
    BOOL: {
      MAP_BOOL_BOOL,
      MAP_DOUBLE_BOOL,
      MAP_INT_BOOL,
      MAP_NUM_BOOL,
      MAP_STRING_BOOL,
      MAP_MAP_BOOL_STRING_BOOL,
    },
    SET_STRING: {
      MAP_BOOL_SET_STRING,
      MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
    },
    MAP_DOUBLE_INT: {
      MAP_DOUBLE_MAP_DOUBLE_INT,
      MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
    },
    MAP_NUM_BOOL: {
      MAP_INT_MAP_NUM_BOOL,
      MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
    },
    MAP_STRING_DOUBLE: {
      MAP_NUM_MAP_STRING_DOUBLE,
      MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
    },
    SET_INT: {
      MAP_LIST_INT_SET_INT,
      MAP_MAP_INT_INT_SET_INT,
    },
    MAP_DOUBLE_BOOL: {
      MAP_LIST_NUM_MAP_DOUBLE_BOOL,
      MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
    },
    MAP_INT_DOUBLE: {
      MAP_LIST_STRING_MAP_INT_DOUBLE,
      MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
    },
    MAP_NUM_STRING: {
      MAP_SET_BOOL_MAP_NUM_STRING,
      MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
    },
    SET_BOOL: {
      MAP_SET_NUM_SET_BOOL,
      MAP_MAP_NUM_STRING_SET_BOOL,
    },
    MAP_BOOL_INT: {
      MAP_SET_STRING_MAP_BOOL_INT,
      MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    },
    MAP_DOUBLE_STRING: {
      MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
      MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
    },
    MAP_NUM_INT: {
      MAP_MAP_BOOL_INT_MAP_NUM_INT,
      MAP_MAP_STRING_INT_MAP_NUM_INT,
    },
    LIST_INT: {
      MAP_MAP_DOUBLE_BOOL_LIST_INT,
    },
  };

  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.
  static const Set<DartType> _iterableTypes1 = {
    INT8LIST,
    UINT8LIST,
    UINT8CLAMPEDLIST,
    INT16LIST,
    UINT16LIST,
    INT32LIST,
    UINT32LIST,
    INT64LIST,
    UINT64LIST,
    FLOAT32LIST,
    FLOAT64LIST,
    FLOAT32X4LIST,
    INT32X4LIST,
    FLOAT64X2LIST,
    LIST_DOUBLE,
    LIST_INT,
    LIST_NUM,
    LIST_STRING,
  };

  // Complex types: Collection types instantiated with nested argument
  // e.g Map<List<>, >.
  static const Set<DartType> _complexTypes = {
    SET_LIST_INT,
    MAP_BOOL_SET_STRING,
    MAP_DOUBLE_MAP_DOUBLE_INT,
    MAP_INT_MAP_NUM_BOOL,
    MAP_NUM_MAP_STRING_DOUBLE,
    MAP_LIST_DOUBLE_STRING,
    MAP_LIST_INT_SET_INT,
    MAP_LIST_NUM_MAP_DOUBLE_BOOL,
    MAP_LIST_STRING_MAP_INT_DOUBLE,
    MAP_SET_BOOL_MAP_NUM_STRING,
    MAP_SET_INT_INT,
    MAP_SET_NUM_SET_BOOL,
    MAP_SET_STRING_MAP_BOOL_INT,
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
    MAP_MAP_BOOL_INT_MAP_NUM_INT,
    MAP_MAP_BOOL_STRING_BOOL,
    MAP_MAP_DOUBLE_BOOL_LIST_INT,
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
    MAP_MAP_INT_DOUBLE_STRING,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
    MAP_MAP_NUM_NUM_INT,
    MAP_MAP_NUM_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_STRING_INT_MAP_NUM_INT,
  };

  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.
  static const Map<DartType, Set<DartType>> _interfaceRels = {
    LIST_INT: {
      INT8LIST,
      UINT8LIST,
      UINT8CLAMPEDLIST,
      INT16LIST,
      UINT16LIST,
      INT32LIST,
      UINT32LIST,
      INT64LIST,
      UINT64LIST,
      LIST_INT,
    },
    EFFICIENTLENGTHITERABLE_INT: {
      INT8LIST,
      UINT8LIST,
      UINT8CLAMPEDLIST,
      INT16LIST,
      UINT16LIST,
      INT32LIST,
      UINT32LIST,
      INT64LIST,
      UINT64LIST,
      LIST_INT,
    },
    _TYPEDINTLIST: {
      INT8LIST,
      UINT8LIST,
      UINT8CLAMPEDLIST,
      INT16LIST,
      UINT16LIST,
      INT32LIST,
      UINT32LIST,
      INT64LIST,
      UINT64LIST,
    },
    OBJECT: {
      INT8LIST,
      UINT8LIST,
      UINT8CLAMPEDLIST,
      INT16LIST,
      UINT16LIST,
      INT32LIST,
      UINT32LIST,
      INT64LIST,
      UINT64LIST,
      FLOAT32LIST,
      FLOAT64LIST,
      FLOAT32X4LIST,
      INT32X4LIST,
      FLOAT64X2LIST,
      FLOAT32X4,
      INT32X4,
      FLOAT64X2,
      BOOL,
      DOUBLE,
      DURATION,
      INT,
      NUM,
      STRING,
      LIST_DOUBLE,
      LIST_INT,
      LIST_NUM,
      LIST_STRING,
      SET_BOOL,
      SET_DOUBLE,
      SET_INT,
      SET_NUM,
      SET_STRING,
      MAP_BOOL_BOOL,
      MAP_BOOL_INT,
      MAP_BOOL_NUM,
      MAP_BOOL_STRING,
      MAP_DOUBLE_BOOL,
      MAP_DOUBLE_DOUBLE,
      MAP_DOUBLE_INT,
      MAP_DOUBLE_NUM,
      MAP_DOUBLE_STRING,
      MAP_INT_BOOL,
      MAP_INT_DOUBLE,
      MAP_INT_INT,
      MAP_INT_STRING,
      MAP_NUM_BOOL,
      MAP_NUM_DOUBLE,
      MAP_NUM_INT,
      MAP_NUM_NUM,
      MAP_NUM_STRING,
      MAP_STRING_BOOL,
      MAP_STRING_DOUBLE,
      MAP_STRING_INT,
      MAP_STRING_NUM,
      SET_LIST_INT,
      MAP_BOOL_SET_STRING,
      MAP_DOUBLE_MAP_DOUBLE_INT,
      MAP_INT_MAP_NUM_BOOL,
      MAP_NUM_MAP_STRING_DOUBLE,
      MAP_LIST_DOUBLE_STRING,
      MAP_LIST_INT_SET_INT,
      MAP_LIST_NUM_MAP_DOUBLE_BOOL,
      MAP_LIST_STRING_MAP_INT_DOUBLE,
      MAP_SET_BOOL_MAP_NUM_STRING,
      MAP_SET_INT_INT,
      MAP_SET_NUM_SET_BOOL,
      MAP_SET_STRING_MAP_BOOL_INT,
      MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
      MAP_MAP_BOOL_INT_MAP_NUM_INT,
      MAP_MAP_BOOL_STRING_BOOL,
      MAP_MAP_DOUBLE_BOOL_LIST_INT,
      MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
      MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
      MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
      MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
      MAP_MAP_INT_DOUBLE_STRING,
      MAP_MAP_INT_INT_SET_INT,
      MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
      MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
      MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
      MAP_MAP_NUM_NUM_INT,
      MAP_MAP_NUM_STRING_SET_BOOL,
      MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
      MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
      MAP_MAP_STRING_INT_MAP_NUM_INT,
    },
    TYPEDDATA: {
      INT8LIST,
      UINT8LIST,
      UINT8CLAMPEDLIST,
      INT16LIST,
      UINT16LIST,
      INT32LIST,
      UINT32LIST,
      INT64LIST,
      UINT64LIST,
      FLOAT32LIST,
      FLOAT64LIST,
      FLOAT32X4LIST,
      INT32X4LIST,
      FLOAT64X2LIST,
    },
    ITERABLE_INT: {
      INT8LIST,
      UINT8LIST,
      UINT8CLAMPEDLIST,
      INT16LIST,
      UINT16LIST,
      INT32LIST,
      UINT32LIST,
      INT64LIST,
      UINT64LIST,
    },
    LIST_DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
      LIST_DOUBLE,
    },
    EFFICIENTLENGTHITERABLE_DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
      LIST_DOUBLE,
    },
    _TYPEDFLOATLIST: {
      FLOAT32LIST,
      FLOAT64LIST,
    },
    ITERABLE_DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
    },
    LIST_FLOAT32X4: {
      FLOAT32X4LIST,
    },
    EFFICIENTLENGTHITERABLE_FLOAT32X4: {
      FLOAT32X4LIST,
    },
    ITERABLE_FLOAT32X4: {
      FLOAT32X4LIST,
    },
    LIST_INT32X4: {
      INT32X4LIST,
    },
    EFFICIENTLENGTHITERABLE_INT32X4: {
      INT32X4LIST,
    },
    ITERABLE_INT32X4: {
      INT32X4LIST,
    },
    LIST_FLOAT64X2: {
      FLOAT64X2LIST,
    },
    EFFICIENTLENGTHITERABLE_FLOAT64X2: {
      FLOAT64X2LIST,
    },
    ITERABLE_FLOAT64X2: {
      FLOAT64X2LIST,
    },
    NUM: {
      DOUBLE,
      INT,
      NUM,
    },
    COMPARABLE_NUM: {
      DOUBLE,
      INT,
      NUM,
    },
    COMPARABLE_DURATION: {
      DURATION,
    },
    COMPARABLE_STRING: {
      STRING,
    },
    PATTERN: {
      STRING,
    },
    EFFICIENTLENGTHITERABLE_E: {
      LIST_DOUBLE,
      LIST_INT,
      LIST_NUM,
      LIST_STRING,
      SET_BOOL,
      SET_DOUBLE,
      SET_INT,
      SET_NUM,
      SET_STRING,
      SET_LIST_INT,
    },
    ITERABLE_E: {
      LIST_DOUBLE,
      LIST_INT,
      LIST_NUM,
      LIST_STRING,
      SET_BOOL,
      SET_DOUBLE,
      SET_INT,
      SET_NUM,
      SET_STRING,
      SET_LIST_INT,
    },
    EFFICIENTLENGTHITERABLE_NUM: {
      LIST_NUM,
    },
    EFFICIENTLENGTHITERABLE_STRING: {
      LIST_STRING,
    },
  };

  // Map type to a list of constructors names with a list of constructor
  // parameter types.
  static const Map<DartType, Map<String, List<DartType>>> _constructors = {
    INT8LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    UINT8LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    UINT8CLAMPEDLIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    INT16LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    UINT16LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    INT32LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    UINT32LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    INT64LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    UINT64LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    FLOAT32LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_DOUBLE,
      ],
    },
    FLOAT64LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_DOUBLE,
      ],
    },
    FLOAT32X4LIST: {
      '': [
        INT,
      ],
    },
    INT32X4LIST: {
      '': [
        INT,
      ],
    },
    FLOAT64X2LIST: {
      '': [
        INT,
      ],
    },
    FLOAT32X4: {
      '': [
        DOUBLE,
        DOUBLE,
        DOUBLE,
        DOUBLE,
      ],
      'splat': [
        DOUBLE,
      ],
      'zero': [],
    },
    INT32X4: {
      '': [
        INT,
        INT,
        INT,
        INT,
      ],
    },
    FLOAT64X2: {
      '': [
        DOUBLE,
        DOUBLE,
      ],
      'splat': [
        DOUBLE,
      ],
      'zero': [],
    },
    DURATION: {
      '': [],
    },
  };

  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.
  static const Map<DartType, Map<String, Set<List<DartType>>>> _binOps = {
    LIST_INT: {
      '+': {
        [
          LIST_INT,
          LIST_INT,
        ],
      },
      '??': {
        [
          LIST_INT,
          LIST_INT,
        ],
      },
    },
    LIST_FLOAT32X4: {
      '+': {
        [
          FLOAT32X4LIST,
          LIST_FLOAT32X4,
        ],
      },
      '??': {
        [
          LIST_FLOAT32X4,
          LIST_FLOAT32X4,
        ],
      },
    },
    LIST_INT32X4: {
      '+': {
        [
          INT32X4LIST,
          LIST_INT32X4,
        ],
      },
      '??': {
        [
          LIST_INT32X4,
          LIST_INT32X4,
        ],
      },
    },
    LIST_FLOAT64X2: {
      '+': {
        [
          FLOAT64X2LIST,
          LIST_FLOAT64X2,
        ],
      },
      '??': {
        [
          LIST_FLOAT64X2,
          LIST_FLOAT64X2,
        ],
      },
    },
    FLOAT32X4: {
      '+': {
        [
          FLOAT32X4,
          FLOAT32X4,
        ],
      },
      '-': {
        [
          FLOAT32X4,
          FLOAT32X4,
        ],
      },
      '*': {
        [
          FLOAT32X4,
          FLOAT32X4,
        ],
      },
      '/': {
        [
          FLOAT32X4,
          FLOAT32X4,
        ],
      },
      '??': {
        [
          FLOAT32X4,
          FLOAT32X4,
        ],
      },
    },
    INT32X4: {
      '|': {
        [
          INT32X4,
          INT32X4,
        ],
      },
      '&': {
        [
          INT32X4,
          INT32X4,
        ],
      },
      '^': {
        [
          INT32X4,
          INT32X4,
        ],
      },
      '+': {
        [
          INT32X4,
          INT32X4,
        ],
      },
      '-': {
        [
          INT32X4,
          INT32X4,
        ],
      },
      '??': {
        [
          INT32X4,
          INT32X4,
        ],
      },
    },
    FLOAT64X2: {
      '+': {
        [
          FLOAT64X2,
          FLOAT64X2,
        ],
      },
      '-': {
        [
          FLOAT64X2,
          FLOAT64X2,
        ],
      },
      '*': {
        [
          FLOAT64X2,
          FLOAT64X2,
        ],
      },
      '/': {
        [
          FLOAT64X2,
          FLOAT64X2,
        ],
      },
      '??': {
        [
          FLOAT64X2,
          FLOAT64X2,
        ],
      },
    },
    BOOL: {
      '&': {
        [
          BOOL,
          BOOL,
        ],
      },
      '|': {
        [
          BOOL,
          BOOL,
        ],
      },
      '^': {
        [
          BOOL,
          BOOL,
        ],
      },
      '<': {
        [
          DURATION,
          DURATION,
        ],
        [
          NUM,
          NUM,
        ],
      },
      '>': {
        [
          DURATION,
          DURATION,
        ],
        [
          NUM,
          NUM,
        ],
      },
      '<=': {
        [
          DURATION,
          DURATION,
        ],
        [
          NUM,
          NUM,
        ],
      },
      '>=': {
        [
          DURATION,
          DURATION,
        ],
        [
          NUM,
          NUM,
        ],
      },
      '==': {
        [
          NUM,
          OBJECT,
        ],
        [
          STRING,
          OBJECT,
        ],
        [
          LIST_DOUBLE,
          OBJECT,
        ],
        [
          LIST_INT,
          OBJECT,
        ],
        [
          LIST_NUM,
          OBJECT,
        ],
        [
          LIST_STRING,
          OBJECT,
        ],
      },
      '??': {
        [
          BOOL,
          BOOL,
        ],
      },
      '&&': {
        [
          BOOL,
          BOOL,
        ],
      },
      '||': {
        [
          BOOL,
          BOOL,
        ],
      },
    },
    DOUBLE: {
      '+': {
        [
          DOUBLE,
          NUM,
        ],
      },
      '-': {
        [
          DOUBLE,
          NUM,
        ],
      },
      '*': {
        [
          DOUBLE,
          NUM,
        ],
      },
      '%': {
        [
          DOUBLE,
          NUM,
        ],
      },
      '/': {
        [
          NUM,
          NUM,
        ],
      },
      '??': {
        [
          DOUBLE,
          DOUBLE,
        ],
      },
    },
    INT: {
      '~/': {
        [
          NUM,
          NUM,
        ],
      },
      '&': {
        [
          INT,
          INT,
        ],
      },
      '|': {
        [
          INT,
          INT,
        ],
      },
      '^': {
        [
          INT,
          INT,
        ],
      },
      '<<': {
        [
          INT,
          INT,
        ],
      },
      '>>': {
        [
          INT,
          INT,
        ],
      },
      '??': {
        [
          INT,
          INT,
        ],
      },
    },
    DURATION: {
      '+': {
        [
          DURATION,
          DURATION,
        ],
      },
      '-': {
        [
          DURATION,
          DURATION,
        ],
      },
      '*': {
        [
          DURATION,
          NUM,
        ],
      },
      '~/': {
        [
          DURATION,
          INT,
        ],
      },
      '??': {
        [
          DURATION,
          DURATION,
        ],
      },
    },
    NUM: {
      '+': {
        [
          NUM,
          NUM,
        ],
      },
      '-': {
        [
          NUM,
          NUM,
        ],
      },
      '*': {
        [
          NUM,
          NUM,
        ],
      },
      '%': {
        [
          NUM,
          NUM,
        ],
      },
      '??': {
        [
          NUM,
          NUM,
        ],
      },
    },
    STRING: {
      '+': {
        [
          STRING,
          STRING,
        ],
      },
      '*': {
        [
          STRING,
          INT,
        ],
      },
      '??': {
        [
          STRING,
          STRING,
        ],
      },
    },
    LIST_DOUBLE: {
      '+': {
        [
          LIST_DOUBLE,
          LIST_DOUBLE,
        ],
      },
      '??': {
        [
          LIST_DOUBLE,
          LIST_DOUBLE,
        ],
      },
    },
    LIST_NUM: {
      '+': {
        [
          LIST_NUM,
          LIST_NUM,
        ],
      },
      '??': {
        [
          LIST_NUM,
          LIST_NUM,
        ],
      },
    },
    LIST_STRING: {
      '+': {
        [
          LIST_STRING,
          LIST_STRING,
        ],
      },
      '??': {
        [
          LIST_STRING,
          LIST_STRING,
        ],
      },
    },
  };

  // Map type to a list of available unary operators.
  static const Map<DartType, Set<String>> _uniOps = {
    FLOAT32X4: {'-'},
    FLOAT64X2: {'-'},
    DOUBLE: {'-'},
    DURATION: {'-'},
    INT: {'~', '-'},
    NUM: {'-'},
    BOOL: {'!'},
  };

  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.
  static const Map<DartType, Map<String, Set<DartType>>> _assignOps = {
    INT8LIST: {
      '=': {
        INT8LIST,
      },
      '??=': {
        INT8LIST,
      },
    },
    UINT8LIST: {
      '=': {
        UINT8LIST,
      },
      '??=': {
        UINT8LIST,
      },
    },
    LIST_INT: {
      '+=': {
        LIST_INT,
      },
      '=': {
        LIST_INT,
      },
      '??=': {
        LIST_INT,
      },
    },
    UINT8CLAMPEDLIST: {
      '=': {
        UINT8CLAMPEDLIST,
      },
      '??=': {
        UINT8CLAMPEDLIST,
      },
    },
    INT16LIST: {
      '=': {
        INT16LIST,
      },
      '??=': {
        INT16LIST,
      },
    },
    UINT16LIST: {
      '=': {
        UINT16LIST,
      },
      '??=': {
        UINT16LIST,
      },
    },
    INT32LIST: {
      '=': {
        INT32LIST,
      },
      '??=': {
        INT32LIST,
      },
    },
    UINT32LIST: {
      '=': {
        UINT32LIST,
      },
      '??=': {
        UINT32LIST,
      },
    },
    INT64LIST: {
      '=': {
        INT64LIST,
      },
      '??=': {
        INT64LIST,
      },
    },
    UINT64LIST: {
      '=': {
        UINT64LIST,
      },
      '??=': {
        UINT64LIST,
      },
    },
    FLOAT32LIST: {
      '=': {
        FLOAT32LIST,
      },
      '??=': {
        FLOAT32LIST,
      },
    },
    FLOAT64LIST: {
      '=': {
        FLOAT64LIST,
      },
      '??=': {
        FLOAT64LIST,
      },
    },
    FLOAT32X4LIST: {
      '=': {
        FLOAT32X4LIST,
      },
      '??=': {
        FLOAT32X4LIST,
      },
    },
    LIST_FLOAT32X4: {
      '+=': {
        LIST_FLOAT32X4,
      },
    },
    INT32X4LIST: {
      '=': {
        INT32X4LIST,
      },
      '??=': {
        INT32X4LIST,
      },
    },
    LIST_INT32X4: {
      '+=': {
        LIST_INT32X4,
      },
    },
    FLOAT64X2LIST: {
      '=': {
        FLOAT64X2LIST,
      },
      '??=': {
        FLOAT64X2LIST,
      },
    },
    LIST_FLOAT64X2: {
      '+=': {
        LIST_FLOAT64X2,
      },
    },
    FLOAT32X4: {
      '=': {
        FLOAT32X4,
      },
      '??=': {
        FLOAT32X4,
      },
      '+=': {
        FLOAT32X4,
      },
      '-=': {
        FLOAT32X4,
      },
      '*=': {
        FLOAT32X4,
      },
      '/=': {
        FLOAT32X4,
      },
    },
    INT32X4: {
      '=': {
        INT32X4,
      },
      '??=': {
        INT32X4,
      },
      '|=': {
        INT32X4,
      },
      '&=': {
        INT32X4,
      },
      '^=': {
        INT32X4,
      },
      '+=': {
        INT32X4,
      },
      '-=': {
        INT32X4,
      },
    },
    FLOAT64X2: {
      '=': {
        FLOAT64X2,
      },
      '??=': {
        FLOAT64X2,
      },
      '+=': {
        FLOAT64X2,
      },
      '-=': {
        FLOAT64X2,
      },
      '*=': {
        FLOAT64X2,
      },
      '/=': {
        FLOAT64X2,
      },
    },
    BOOL: {
      '=': {
        BOOL,
      },
      '??=': {
        BOOL,
      },
    },
    DOUBLE: {
      '=': {
        DOUBLE,
      },
      '??=': {
        DOUBLE,
      },
      '+=': {
        NUM,
      },
      '-=': {
        NUM,
      },
      '*=': {
        NUM,
      },
      '%=': {
        NUM,
      },
      '/=': {
        NUM,
      },
    },
    INT: {
      '~/=': {
        NUM,
      },
      '=': {
        INT,
      },
      '??=': {
        INT,
      },
      '&=': {
        INT,
      },
      '|=': {
        INT,
      },
      '^=': {
        INT,
      },
      '<<=': {
        INT,
      },
      '>>=': {
        INT,
      },
    },
    DURATION: {
      '=': {
        DURATION,
      },
      '??=': {
        DURATION,
      },
      '+=': {
        DURATION,
      },
      '-=': {
        DURATION,
      },
      '*=': {
        NUM,
      },
      '~/=': {
        INT,
      },
    },
    NUM: {
      '=': {
        NUM,
      },
      '??=': {
        NUM,
      },
      '+=': {
        NUM,
      },
      '-=': {
        NUM,
      },
      '*=': {
        NUM,
      },
      '%=': {
        NUM,
      },
    },
    STRING: {
      '=': {
        STRING,
      },
      '??=': {
        STRING,
      },
      '+=': {
        STRING,
      },
      '*=': {
        INT,
      },
    },
    LIST_DOUBLE: {
      '=': {
        LIST_DOUBLE,
      },
      '??=': {
        LIST_DOUBLE,
      },
      '+=': {
        LIST_DOUBLE,
      },
    },
    LIST_NUM: {
      '=': {
        LIST_NUM,
      },
      '??=': {
        LIST_NUM,
      },
      '+=': {
        LIST_NUM,
      },
    },
    LIST_STRING: {
      '=': {
        LIST_STRING,
      },
      '??=': {
        LIST_STRING,
      },
      '+=': {
        LIST_STRING,
      },
    },
    SET_BOOL: {
      '=': {
        SET_BOOL,
      },
      '??=': {
        SET_BOOL,
      },
    },
    SET_DOUBLE: {
      '=': {
        SET_DOUBLE,
      },
      '??=': {
        SET_DOUBLE,
      },
    },
    SET_INT: {
      '=': {
        SET_INT,
      },
      '??=': {
        SET_INT,
      },
    },
    SET_NUM: {
      '=': {
        SET_NUM,
      },
      '??=': {
        SET_NUM,
      },
    },
    SET_STRING: {
      '=': {
        SET_STRING,
      },
      '??=': {
        SET_STRING,
      },
    },
    MAP_BOOL_BOOL: {
      '=': {
        MAP_BOOL_BOOL,
      },
      '??=': {
        MAP_BOOL_BOOL,
      },
    },
    MAP_BOOL_INT: {
      '=': {
        MAP_BOOL_INT,
      },
      '??=': {
        MAP_BOOL_INT,
      },
    },
    MAP_BOOL_NUM: {
      '=': {
        MAP_BOOL_NUM,
      },
      '??=': {
        MAP_BOOL_NUM,
      },
    },
    MAP_BOOL_STRING: {
      '=': {
        MAP_BOOL_STRING,
      },
      '??=': {
        MAP_BOOL_STRING,
      },
    },
    MAP_DOUBLE_BOOL: {
      '=': {
        MAP_DOUBLE_BOOL,
      },
      '??=': {
        MAP_DOUBLE_BOOL,
      },
    },
    MAP_DOUBLE_DOUBLE: {
      '=': {
        MAP_DOUBLE_DOUBLE,
      },
      '??=': {
        MAP_DOUBLE_DOUBLE,
      },
    },
    MAP_DOUBLE_INT: {
      '=': {
        MAP_DOUBLE_INT,
      },
      '??=': {
        MAP_DOUBLE_INT,
      },
    },
    MAP_DOUBLE_NUM: {
      '=': {
        MAP_DOUBLE_NUM,
      },
      '??=': {
        MAP_DOUBLE_NUM,
      },
    },
    MAP_DOUBLE_STRING: {
      '=': {
        MAP_DOUBLE_STRING,
      },
      '??=': {
        MAP_DOUBLE_STRING,
      },
    },
    MAP_INT_BOOL: {
      '=': {
        MAP_INT_BOOL,
      },
      '??=': {
        MAP_INT_BOOL,
      },
    },
    MAP_INT_DOUBLE: {
      '=': {
        MAP_INT_DOUBLE,
      },
      '??=': {
        MAP_INT_DOUBLE,
      },
    },
    MAP_INT_INT: {
      '=': {
        MAP_INT_INT,
      },
      '??=': {
        MAP_INT_INT,
      },
    },
    MAP_INT_STRING: {
      '=': {
        MAP_INT_STRING,
      },
      '??=': {
        MAP_INT_STRING,
      },
    },
    MAP_NUM_BOOL: {
      '=': {
        MAP_NUM_BOOL,
      },
      '??=': {
        MAP_NUM_BOOL,
      },
    },
    MAP_NUM_DOUBLE: {
      '=': {
        MAP_NUM_DOUBLE,
      },
      '??=': {
        MAP_NUM_DOUBLE,
      },
    },
    MAP_NUM_INT: {
      '=': {
        MAP_NUM_INT,
      },
      '??=': {
        MAP_NUM_INT,
      },
    },
    MAP_NUM_NUM: {
      '=': {
        MAP_NUM_NUM,
      },
      '??=': {
        MAP_NUM_NUM,
      },
    },
    MAP_NUM_STRING: {
      '=': {
        MAP_NUM_STRING,
      },
      '??=': {
        MAP_NUM_STRING,
      },
    },
    MAP_STRING_BOOL: {
      '=': {
        MAP_STRING_BOOL,
      },
      '??=': {
        MAP_STRING_BOOL,
      },
    },
    MAP_STRING_DOUBLE: {
      '=': {
        MAP_STRING_DOUBLE,
      },
      '??=': {
        MAP_STRING_DOUBLE,
      },
    },
    MAP_STRING_INT: {
      '=': {
        MAP_STRING_INT,
      },
      '??=': {
        MAP_STRING_INT,
      },
    },
    MAP_STRING_NUM: {
      '=': {
        MAP_STRING_NUM,
      },
      '??=': {
        MAP_STRING_NUM,
      },
    },
    SET_LIST_INT: {
      '=': {
        SET_LIST_INT,
      },
      '??=': {
        SET_LIST_INT,
      },
    },
    MAP_BOOL_SET_STRING: {
      '=': {
        MAP_BOOL_SET_STRING,
      },
      '??=': {
        MAP_BOOL_SET_STRING,
      },
    },
    MAP_DOUBLE_MAP_DOUBLE_INT: {
      '=': {
        MAP_DOUBLE_MAP_DOUBLE_INT,
      },
      '??=': {
        MAP_DOUBLE_MAP_DOUBLE_INT,
      },
    },
    MAP_INT_MAP_NUM_BOOL: {
      '=': {
        MAP_INT_MAP_NUM_BOOL,
      },
      '??=': {
        MAP_INT_MAP_NUM_BOOL,
      },
    },
    MAP_NUM_MAP_STRING_DOUBLE: {
      '=': {
        MAP_NUM_MAP_STRING_DOUBLE,
      },
      '??=': {
        MAP_NUM_MAP_STRING_DOUBLE,
      },
    },
    MAP_LIST_DOUBLE_STRING: {
      '=': {
        MAP_LIST_DOUBLE_STRING,
      },
      '??=': {
        MAP_LIST_DOUBLE_STRING,
      },
    },
    MAP_LIST_INT_SET_INT: {
      '=': {
        MAP_LIST_INT_SET_INT,
      },
      '??=': {
        MAP_LIST_INT_SET_INT,
      },
    },
    MAP_LIST_NUM_MAP_DOUBLE_BOOL: {
      '=': {
        MAP_LIST_NUM_MAP_DOUBLE_BOOL,
      },
      '??=': {
        MAP_LIST_NUM_MAP_DOUBLE_BOOL,
      },
    },
    MAP_LIST_STRING_MAP_INT_DOUBLE: {
      '=': {
        MAP_LIST_STRING_MAP_INT_DOUBLE,
      },
      '??=': {
        MAP_LIST_STRING_MAP_INT_DOUBLE,
      },
    },
    MAP_SET_BOOL_MAP_NUM_STRING: {
      '=': {
        MAP_SET_BOOL_MAP_NUM_STRING,
      },
      '??=': {
        MAP_SET_BOOL_MAP_NUM_STRING,
      },
    },
    MAP_SET_INT_INT: {
      '=': {
        MAP_SET_INT_INT,
      },
      '??=': {
        MAP_SET_INT_INT,
      },
    },
    MAP_SET_NUM_SET_BOOL: {
      '=': {
        MAP_SET_NUM_SET_BOOL,
      },
      '??=': {
        MAP_SET_NUM_SET_BOOL,
      },
    },
    MAP_SET_STRING_MAP_BOOL_INT: {
      '=': {
        MAP_SET_STRING_MAP_BOOL_INT,
      },
      '??=': {
        MAP_SET_STRING_MAP_BOOL_INT,
      },
    },
    MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING: {
      '=': {
        MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
      },
      '??=': {
        MAP_MAP_BOOL_BOOL_MAP_DOUBLE_STRING,
      },
    },
    MAP_MAP_BOOL_INT_MAP_NUM_INT: {
      '=': {
        MAP_MAP_BOOL_INT_MAP_NUM_INT,
      },
      '??=': {
        MAP_MAP_BOOL_INT_MAP_NUM_INT,
      },
    },
    MAP_MAP_BOOL_STRING_BOOL: {
      '=': {
        MAP_MAP_BOOL_STRING_BOOL,
      },
      '??=': {
        MAP_MAP_BOOL_STRING_BOOL,
      },
    },
    MAP_MAP_DOUBLE_BOOL_LIST_INT: {
      '=': {
        MAP_MAP_DOUBLE_BOOL_LIST_INT,
      },
      '??=': {
        MAP_MAP_DOUBLE_BOOL_LIST_INT,
      },
    },
    MAP_MAP_DOUBLE_DOUBLE_SET_STRING: {
      '=': {
        MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
      },
      '??=': {
        MAP_MAP_DOUBLE_DOUBLE_SET_STRING,
      },
    },
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT: {
      '=': {
        MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
      },
      '??=': {
        MAP_MAP_DOUBLE_INT_MAP_DOUBLE_INT,
      },
    },
    MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL: {
      '=': {
        MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
      },
      '??=': {
        MAP_MAP_DOUBLE_NUM_MAP_NUM_BOOL,
      },
    },
    MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE: {
      '=': {
        MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
      },
      '??=': {
        MAP_MAP_DOUBLE_STRING_MAP_STRING_DOUBLE,
      },
    },
    MAP_MAP_INT_DOUBLE_STRING: {
      '=': {
        MAP_MAP_INT_DOUBLE_STRING,
      },
      '??=': {
        MAP_MAP_INT_DOUBLE_STRING,
      },
    },
    MAP_MAP_INT_INT_SET_INT: {
      '=': {
        MAP_MAP_INT_INT_SET_INT,
      },
      '??=': {
        MAP_MAP_INT_INT_SET_INT,
      },
    },
    MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL: {
      '=': {
        MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
      },
      '??=': {
        MAP_MAP_INT_STRING_MAP_DOUBLE_BOOL,
      },
    },
    MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE: {
      '=': {
        MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
      },
      '??=': {
        MAP_MAP_NUM_BOOL_MAP_INT_DOUBLE,
      },
    },
    MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING: {
      '=': {
        MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
      },
      '??=': {
        MAP_MAP_NUM_DOUBLE_MAP_NUM_STRING,
      },
    },
    MAP_MAP_NUM_NUM_INT: {
      '=': {
        MAP_MAP_NUM_NUM_INT,
      },
      '??=': {
        MAP_MAP_NUM_NUM_INT,
      },
    },
    MAP_MAP_NUM_STRING_SET_BOOL: {
      '=': {
        MAP_MAP_NUM_STRING_SET_BOOL,
      },
      '??=': {
        MAP_MAP_NUM_STRING_SET_BOOL,
      },
    },
    MAP_MAP_STRING_BOOL_MAP_BOOL_INT: {
      '=': {
        MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
      },
      '??=': {
        MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
      },
    },
    MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING: {
      '=': {
        MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
      },
      '??=': {
        MAP_MAP_STRING_DOUBLE_MAP_DOUBLE_STRING,
      },
    },
    MAP_MAP_STRING_INT_MAP_NUM_INT: {
      '=': {
        MAP_MAP_STRING_INT_MAP_NUM_INT,
      },
      '??=': {
        MAP_MAP_STRING_INT_MAP_NUM_INT,
      },
    },
  };
}

class DartTypeNoFp extends DartType {
  final String name;
  const DartTypeNoFp._withName(this.name) : super._withName(name);
  const DartTypeNoFp() : name = null;
  static bool isListType(DartType tp) {
    return DartType._listTypes.contains(tp);
  }

  static bool isMapType(DartType tp) {
    return DartType._mapTypes.contains(tp);
  }

  static bool isCollectionType(DartType tp) {
    return DartType._collectionTypes.contains(tp);
  }

  static bool isGrowableType(DartType tp) {
    return DartType._growableTypes.contains(tp);
  }

  static bool isComplexType(DartType tp) {
    return DartType._complexTypes.contains(tp);
  }

  bool isInterfaceOfType(DartType tp, DartType iTp) {
    return _interfaceRels.containsKey(iTp) && _interfaceRels[iTp].contains(tp);
  }

  Set<DartType> get mapTypes {
    return _mapTypes;
  }

  bool isSpecializable(DartType tp) {
    return _interfaceRels.containsKey(tp);
  }

  Set<DartType> interfaces(DartType tp) {
    if (_interfaceRels.containsKey(tp)) {
      return _interfaceRels[tp];
    }
    return null;
  }

  DartType indexType(DartType tp) {
    if (_indexedBy.containsKey(tp)) {
      return _indexedBy[tp];
    }
    return null;
  }

  Set<DartType> indexableElementTypes(DartType tp) {
    if (_indexableElementOf.containsKey(tp)) {
      return _indexableElementOf[tp];
    }
    return null;
  }

  bool isIndexableElementType(DartType tp) {
    return _indexableElementOf.containsKey(tp);
  }

  DartType elementType(DartType tp) {
    if (_subscriptsTo.containsKey(tp)) {
      return _subscriptsTo[tp];
    }
    return null;
  }

  Set<DartType> get iterableTypes1 {
    return _iterableTypes1;
  }

  Set<String> uniOps(DartType tp) {
    if (_uniOps.containsKey(tp)) {
      return _uniOps[tp];
    }
    return <String>{};
  }

  Set<String> binOps(DartType tp) {
    if (_binOps.containsKey(tp)) {
      return _binOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<List<DartType>> binOpParameters(DartType tp, String op) {
    if (_binOps.containsKey(tp) && _binOps[tp].containsKey(op)) {
      return _binOps[tp][op];
    }
    return null;
  }

  Set<String> assignOps(DartType tp) {
    if (_assignOps.containsKey(tp)) {
      return _assignOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<DartType> assignOpRhs(DartType tp, String op) {
    if (_assignOps.containsKey(tp) && _assignOps[tp].containsKey(op)) {
      return _assignOps[tp][op];
    }
    return <DartType>{};
  }

  bool hasConstructor(DartType tp) {
    return _constructors.containsKey(tp);
  }

  Set<String> constructors(DartType tp) {
    if (_constructors.containsKey(tp)) {
      return _constructors[tp].keys.toSet();
    }
    return <String>{};
  }

  List<DartType> constructorParameters(DartType tp, String constructor) {
    if (_constructors.containsKey(tp) &&
        _constructors[tp].containsKey(constructor)) {
      return _constructors[tp][constructor];
    }
    return null;
  }

  Set<DartType> get allTypes {
    return _allTypes;
  }

  // All types extracted from analyzer.
  static const _allTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.INT32X4,
    DartType.BOOL,
    DartType.DURATION,
    DartType.INT,
    DartType.NUM,
    DartType.STRING,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
    DartType.SET_LIST_INT,
    DartType.MAP_BOOL_SET_STRING,
    DartType.MAP_INT_MAP_NUM_BOOL,
    DartType.MAP_LIST_INT_SET_INT,
    DartType.MAP_SET_BOOL_MAP_NUM_STRING,
    DartType.MAP_SET_INT_INT,
    DartType.MAP_SET_NUM_SET_BOOL,
    DartType.MAP_SET_STRING_MAP_BOOL_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
    DartType.MAP_MAP_BOOL_STRING_BOOL,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_NUM_NUM_INT,
    DartType.MAP_MAP_NUM_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
  };

  // All List<E> types: LIST_INT, LIST_STRING, etc.
  static const Set<DartType> _listTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
  };

  // All Set types: SET_INT, SET_STRING, etc.
  static const Set<DartType> _setTypes = {
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.SET_LIST_INT,
  };

  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
  static const Set<DartType> _mapTypes = {
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
    DartType.MAP_BOOL_SET_STRING,
    DartType.MAP_INT_MAP_NUM_BOOL,
    DartType.MAP_LIST_INT_SET_INT,
    DartType.MAP_SET_BOOL_MAP_NUM_STRING,
    DartType.MAP_SET_INT_INT,
    DartType.MAP_SET_NUM_SET_BOOL,
    DartType.MAP_SET_STRING_MAP_BOOL_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
    DartType.MAP_MAP_BOOL_STRING_BOOL,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_NUM_NUM_INT,
    DartType.MAP_MAP_NUM_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
  };

  // All collection types: list, map and set types.
  static const Set<DartType> _collectionTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.SET_LIST_INT,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
    DartType.MAP_BOOL_SET_STRING,
    DartType.MAP_INT_MAP_NUM_BOOL,
    DartType.MAP_LIST_INT_SET_INT,
    DartType.MAP_SET_BOOL_MAP_NUM_STRING,
    DartType.MAP_SET_INT_INT,
    DartType.MAP_SET_NUM_SET_BOOL,
    DartType.MAP_SET_STRING_MAP_BOOL_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
    DartType.MAP_MAP_BOOL_STRING_BOOL,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_NUM_NUM_INT,
    DartType.MAP_MAP_NUM_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
  };

  // All growable types: list, map, set and string types.
  static const Set<DartType> _growableTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.SET_LIST_INT,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
    DartType.MAP_BOOL_SET_STRING,
    DartType.MAP_INT_MAP_NUM_BOOL,
    DartType.MAP_LIST_INT_SET_INT,
    DartType.MAP_SET_BOOL_MAP_NUM_STRING,
    DartType.MAP_SET_INT_INT,
    DartType.MAP_SET_NUM_SET_BOOL,
    DartType.MAP_SET_STRING_MAP_BOOL_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
    DartType.MAP_MAP_BOOL_STRING_BOOL,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_NUM_NUM_INT,
    DartType.MAP_MAP_NUM_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
    DartType.STRING,
  };

  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.
  static const Set<DartType> _indexableTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
    DartType.MAP_BOOL_SET_STRING,
    DartType.MAP_INT_MAP_NUM_BOOL,
    DartType.MAP_LIST_INT_SET_INT,
    DartType.MAP_SET_BOOL_MAP_NUM_STRING,
    DartType.MAP_SET_INT_INT,
    DartType.MAP_SET_NUM_SET_BOOL,
    DartType.MAP_SET_STRING_MAP_BOOL_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
    DartType.MAP_MAP_BOOL_STRING_BOOL,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_NUM_NUM_INT,
    DartType.MAP_MAP_NUM_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
  };

  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.
  static const Map<DartType, DartType> _subscriptsTo = {
    DartType.INT8LIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.INT16LIST: DartType.INT,
    DartType.UINT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.INT64LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT32X4,
    DartType.DURATION: DartType.DURATION,
    DartType.NUM: DartType.NUM,
    DartType.STRING: DartType.STRING,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_NUM: DartType.NUM,
    DartType.LIST_STRING: DartType.STRING,
    DartType.SET_BOOL: DartType.BOOL,
    DartType.SET_INT: DartType.INT,
    DartType.SET_NUM: DartType.NUM,
    DartType.SET_STRING: DartType.STRING,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.INT,
    DartType.MAP_BOOL_NUM: DartType.NUM,
    DartType.MAP_BOOL_STRING: DartType.STRING,
    DartType.MAP_INT_BOOL: DartType.BOOL,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.STRING,
    DartType.MAP_NUM_BOOL: DartType.BOOL,
    DartType.MAP_NUM_INT: DartType.INT,
    DartType.MAP_NUM_NUM: DartType.NUM,
    DartType.MAP_NUM_STRING: DartType.STRING,
    DartType.MAP_STRING_BOOL: DartType.BOOL,
    DartType.MAP_STRING_INT: DartType.INT,
    DartType.MAP_STRING_NUM: DartType.NUM,
    DartType.SET_LIST_INT: DartType.LIST_INT,
    DartType.MAP_BOOL_SET_STRING: DartType.SET_STRING,
    DartType.MAP_INT_MAP_NUM_BOOL: DartType.MAP_NUM_BOOL,
    DartType.MAP_LIST_INT_SET_INT: DartType.SET_INT,
    DartType.MAP_SET_BOOL_MAP_NUM_STRING: DartType.MAP_NUM_STRING,
    DartType.MAP_SET_INT_INT: DartType.INT,
    DartType.MAP_SET_NUM_SET_BOOL: DartType.SET_BOOL,
    DartType.MAP_SET_STRING_MAP_BOOL_INT: DartType.MAP_BOOL_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT: DartType.MAP_NUM_INT,
    DartType.MAP_MAP_BOOL_STRING_BOOL: DartType.BOOL,
    DartType.MAP_MAP_INT_INT_SET_INT: DartType.SET_INT,
    DartType.MAP_MAP_NUM_NUM_INT: DartType.INT,
    DartType.MAP_MAP_NUM_STRING_SET_BOOL: DartType.SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT: DartType.MAP_BOOL_INT,
    DartType.MAP_MAP_STRING_INT_MAP_NUM_INT: DartType.MAP_NUM_INT,
  };

  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.
  static const Map<DartType, DartType> _indexedBy = {
    DartType.INT8LIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.INT16LIST: DartType.INT,
    DartType.UINT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.INT64LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_NUM: DartType.INT,
    DartType.LIST_STRING: DartType.INT,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.BOOL,
    DartType.MAP_BOOL_NUM: DartType.BOOL,
    DartType.MAP_BOOL_STRING: DartType.BOOL,
    DartType.MAP_INT_BOOL: DartType.INT,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.INT,
    DartType.MAP_NUM_BOOL: DartType.NUM,
    DartType.MAP_NUM_INT: DartType.NUM,
    DartType.MAP_NUM_NUM: DartType.NUM,
    DartType.MAP_NUM_STRING: DartType.NUM,
    DartType.MAP_STRING_BOOL: DartType.STRING,
    DartType.MAP_STRING_INT: DartType.STRING,
    DartType.MAP_STRING_NUM: DartType.STRING,
    DartType.MAP_BOOL_SET_STRING: DartType.BOOL,
    DartType.MAP_INT_MAP_NUM_BOOL: DartType.INT,
    DartType.MAP_LIST_INT_SET_INT: DartType.LIST_INT,
    DartType.MAP_SET_BOOL_MAP_NUM_STRING: DartType.SET_BOOL,
    DartType.MAP_SET_INT_INT: DartType.SET_INT,
    DartType.MAP_SET_NUM_SET_BOOL: DartType.SET_NUM,
    DartType.MAP_SET_STRING_MAP_BOOL_INT: DartType.SET_STRING,
    DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT: DartType.MAP_BOOL_INT,
    DartType.MAP_MAP_BOOL_STRING_BOOL: DartType.MAP_BOOL_STRING,
    DartType.MAP_MAP_INT_INT_SET_INT: DartType.MAP_INT_INT,
    DartType.MAP_MAP_NUM_NUM_INT: DartType.MAP_NUM_NUM,
    DartType.MAP_MAP_NUM_STRING_SET_BOOL: DartType.MAP_NUM_STRING,
    DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT: DartType.MAP_STRING_BOOL,
    DartType.MAP_MAP_STRING_INT_MAP_NUM_INT: DartType.MAP_STRING_INT,
  };

  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>
  static const Map<DartType, Set<DartType>> _elementOf = {
    DartType.INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
      DartType.SET_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_NUM_INT,
      DartType.MAP_STRING_INT,
      DartType.MAP_SET_INT_INT,
      DartType.MAP_MAP_NUM_NUM_INT,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.DURATION: {
      DartType.DURATION,
    },
    DartType.NUM: {
      DartType.NUM,
      DartType.LIST_NUM,
      DartType.SET_NUM,
      DartType.MAP_BOOL_NUM,
      DartType.MAP_NUM_NUM,
      DartType.MAP_STRING_NUM,
    },
    DartType.STRING: {
      DartType.STRING,
      DartType.LIST_STRING,
      DartType.SET_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_NUM_STRING,
    },
    DartType.BOOL: {
      DartType.SET_BOOL,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_NUM_BOOL,
      DartType.MAP_STRING_BOOL,
      DartType.MAP_MAP_BOOL_STRING_BOOL,
    },
    DartType.LIST_INT: {
      DartType.SET_LIST_INT,
    },
    DartType.SET_STRING: {
      DartType.MAP_BOOL_SET_STRING,
    },
    DartType.MAP_NUM_BOOL: {
      DartType.MAP_INT_MAP_NUM_BOOL,
    },
    DartType.SET_INT: {
      DartType.MAP_LIST_INT_SET_INT,
      DartType.MAP_MAP_INT_INT_SET_INT,
    },
    DartType.MAP_NUM_STRING: {
      DartType.MAP_SET_BOOL_MAP_NUM_STRING,
    },
    DartType.SET_BOOL: {
      DartType.MAP_SET_NUM_SET_BOOL,
      DartType.MAP_MAP_NUM_STRING_SET_BOOL,
    },
    DartType.MAP_BOOL_INT: {
      DartType.MAP_SET_STRING_MAP_BOOL_INT,
      DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    },
    DartType.MAP_NUM_INT: {
      DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
      DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
    },
  };

  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.
  static const Map<DartType, Set<DartType>> _indexableElementOf = {
    DartType.INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_NUM_INT,
      DartType.MAP_STRING_INT,
      DartType.MAP_SET_INT_INT,
      DartType.MAP_MAP_NUM_NUM_INT,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.NUM: {
      DartType.LIST_NUM,
      DartType.MAP_BOOL_NUM,
      DartType.MAP_NUM_NUM,
      DartType.MAP_STRING_NUM,
    },
    DartType.STRING: {
      DartType.LIST_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_NUM_STRING,
    },
    DartType.BOOL: {
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_NUM_BOOL,
      DartType.MAP_STRING_BOOL,
      DartType.MAP_MAP_BOOL_STRING_BOOL,
    },
    DartType.SET_STRING: {
      DartType.MAP_BOOL_SET_STRING,
    },
    DartType.MAP_NUM_BOOL: {
      DartType.MAP_INT_MAP_NUM_BOOL,
    },
    DartType.SET_INT: {
      DartType.MAP_LIST_INT_SET_INT,
      DartType.MAP_MAP_INT_INT_SET_INT,
    },
    DartType.MAP_NUM_STRING: {
      DartType.MAP_SET_BOOL_MAP_NUM_STRING,
    },
    DartType.SET_BOOL: {
      DartType.MAP_SET_NUM_SET_BOOL,
      DartType.MAP_MAP_NUM_STRING_SET_BOOL,
    },
    DartType.MAP_BOOL_INT: {
      DartType.MAP_SET_STRING_MAP_BOOL_INT,
      DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
    },
    DartType.MAP_NUM_INT: {
      DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
      DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
    },
  };

  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.
  static const Set<DartType> _iterableTypes1 = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
  };

  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.
  static const Map<DartType, Set<DartType>> _interfaceRels = {
    DartType.LIST_INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
    },
    DartType._TYPEDINTLIST: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
    },
    DartType.OBJECT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.INT32X4LIST,
      DartType.INT32X4,
      DartType.BOOL,
      DartType.DURATION,
      DartType.INT,
      DartType.NUM,
      DartType.STRING,
      DartType.LIST_INT,
      DartType.LIST_NUM,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_NUM,
      DartType.SET_STRING,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_BOOL_INT,
      DartType.MAP_BOOL_NUM,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_BOOL,
      DartType.MAP_INT_INT,
      DartType.MAP_INT_STRING,
      DartType.MAP_NUM_BOOL,
      DartType.MAP_NUM_INT,
      DartType.MAP_NUM_NUM,
      DartType.MAP_NUM_STRING,
      DartType.MAP_STRING_BOOL,
      DartType.MAP_STRING_INT,
      DartType.MAP_STRING_NUM,
      DartType.SET_LIST_INT,
      DartType.MAP_BOOL_SET_STRING,
      DartType.MAP_INT_MAP_NUM_BOOL,
      DartType.MAP_LIST_INT_SET_INT,
      DartType.MAP_SET_BOOL_MAP_NUM_STRING,
      DartType.MAP_SET_INT_INT,
      DartType.MAP_SET_NUM_SET_BOOL,
      DartType.MAP_SET_STRING_MAP_BOOL_INT,
      DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
      DartType.MAP_MAP_BOOL_STRING_BOOL,
      DartType.MAP_MAP_INT_INT_SET_INT,
      DartType.MAP_MAP_NUM_NUM_INT,
      DartType.MAP_MAP_NUM_STRING_SET_BOOL,
      DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
      DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
    },
    DartType.TYPEDDATA: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.INT32X4LIST,
    },
    DartType.ITERABLE_INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
    },
    DartType.LIST_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.ITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.NUM: {
      DartType.INT,
      DartType.NUM,
    },
    DartType.COMPARABLE_NUM: {
      DartType.INT,
      DartType.NUM,
    },
    DartType.COMPARABLE_DURATION: {
      DartType.DURATION,
    },
    DartType.COMPARABLE_STRING: {
      DartType.STRING,
    },
    DartType.PATTERN: {
      DartType.STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_E: {
      DartType.LIST_INT,
      DartType.LIST_NUM,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_NUM,
      DartType.SET_STRING,
      DartType.SET_LIST_INT,
    },
    DartType.ITERABLE_E: {
      DartType.LIST_INT,
      DartType.LIST_NUM,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_NUM,
      DartType.SET_STRING,
      DartType.SET_LIST_INT,
    },
    DartType.EFFICIENTLENGTHITERABLE_NUM: {
      DartType.LIST_NUM,
    },
    DartType.EFFICIENTLENGTHITERABLE_STRING: {
      DartType.LIST_STRING,
    },
  };

  // Map type to a list of constructors names with a list of constructor
  // parameter types.
  static const Map<DartType, Map<String, List<DartType>>> _constructors = {
    DartType.INT8LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT8LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT8CLAMPEDLIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT16LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT16LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT32LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT32LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT64LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT64LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT32X4LIST: {
      '': [
        DartType.INT,
      ],
    },
    DartType.INT32X4: {
      '': [
        DartType.INT,
        DartType.INT,
        DartType.INT,
        DartType.INT,
      ],
    },
    DartType.DURATION: {
      '': [],
    },
  };

  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.
  static const Map<DartType, Map<String, Set<List<DartType>>>> _binOps = {
    DartType.LIST_INT: {
      '+': {
        [
          DartType.LIST_INT,
          DartType.LIST_INT,
        ],
      },
      '??': {
        [
          DartType.LIST_INT,
          DartType.LIST_INT,
        ],
      },
    },
    DartType.LIST_FLOAT32X4: {
      '??': {
        [
          DartType.LIST_FLOAT32X4,
          DartType.LIST_FLOAT32X4,
        ],
      },
    },
    DartType.LIST_INT32X4: {
      '+': {
        [
          DartType.INT32X4LIST,
          DartType.LIST_INT32X4,
        ],
      },
      '??': {
        [
          DartType.LIST_INT32X4,
          DartType.LIST_INT32X4,
        ],
      },
    },
    DartType.LIST_FLOAT64X2: {
      '??': {
        [
          DartType.LIST_FLOAT64X2,
          DartType.LIST_FLOAT64X2,
        ],
      },
    },
    DartType.INT32X4: {
      '|': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '&': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '^': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '+': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '-': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '??': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
    },
    DartType.BOOL: {
      '&': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '|': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '^': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '<': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '>': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '<=': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '>=': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '==': {
        [
          DartType.NUM,
          DartType.OBJECT,
        ],
        [
          DartType.STRING,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_INT,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_NUM,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_STRING,
          DartType.OBJECT,
        ],
      },
      '??': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '&&': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '||': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
    },
    DartType.INT: {
      '~/': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '&': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '|': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '^': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '<<': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '>>': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '??': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
    },
    DartType.DURATION: {
      '+': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
      '-': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
      '*': {
        [
          DartType.DURATION,
          DartType.NUM,
        ],
      },
      '~/': {
        [
          DartType.DURATION,
          DartType.INT,
        ],
      },
      '??': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
    },
    DartType.NUM: {
      '+': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '-': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '*': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '%': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '??': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
    },
    DartType.STRING: {
      '+': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
      '*': {
        [
          DartType.STRING,
          DartType.INT,
        ],
      },
      '??': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
    },
    DartType.LIST_NUM: {
      '+': {
        [
          DartType.LIST_NUM,
          DartType.LIST_NUM,
        ],
      },
      '??': {
        [
          DartType.LIST_NUM,
          DartType.LIST_NUM,
        ],
      },
    },
    DartType.LIST_STRING: {
      '+': {
        [
          DartType.LIST_STRING,
          DartType.LIST_STRING,
        ],
      },
      '??': {
        [
          DartType.LIST_STRING,
          DartType.LIST_STRING,
        ],
      },
    },
  };

  // Map type to a list of available unary operators.
  static const Map<DartType, Set<String>> _uniOps = {
    DartType.DURATION: {'-'},
    DartType.INT: {'~', '-'},
    DartType.NUM: {'-'},
    DartType.BOOL: {'!'},
  };

  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.
  static const Map<DartType, Map<String, Set<DartType>>> _assignOps = {
    DartType.INT8LIST: {
      '=': {
        DartType.INT8LIST,
      },
      '??=': {
        DartType.INT8LIST,
      },
    },
    DartType.UINT8LIST: {
      '=': {
        DartType.UINT8LIST,
      },
      '??=': {
        DartType.UINT8LIST,
      },
    },
    DartType.LIST_INT: {
      '+=': {
        DartType.LIST_INT,
      },
      '=': {
        DartType.LIST_INT,
      },
      '??=': {
        DartType.LIST_INT,
      },
    },
    DartType.UINT8CLAMPEDLIST: {
      '=': {
        DartType.UINT8CLAMPEDLIST,
      },
      '??=': {
        DartType.UINT8CLAMPEDLIST,
      },
    },
    DartType.INT16LIST: {
      '=': {
        DartType.INT16LIST,
      },
      '??=': {
        DartType.INT16LIST,
      },
    },
    DartType.UINT16LIST: {
      '=': {
        DartType.UINT16LIST,
      },
      '??=': {
        DartType.UINT16LIST,
      },
    },
    DartType.INT32LIST: {
      '=': {
        DartType.INT32LIST,
      },
      '??=': {
        DartType.INT32LIST,
      },
    },
    DartType.UINT32LIST: {
      '=': {
        DartType.UINT32LIST,
      },
      '??=': {
        DartType.UINT32LIST,
      },
    },
    DartType.INT64LIST: {
      '=': {
        DartType.INT64LIST,
      },
      '??=': {
        DartType.INT64LIST,
      },
    },
    DartType.UINT64LIST: {
      '=': {
        DartType.UINT64LIST,
      },
      '??=': {
        DartType.UINT64LIST,
      },
    },
    DartType.LIST_FLOAT32X4: {
      '+=': {
        DartType.LIST_FLOAT32X4,
      },
    },
    DartType.INT32X4LIST: {
      '=': {
        DartType.INT32X4LIST,
      },
      '??=': {
        DartType.INT32X4LIST,
      },
    },
    DartType.LIST_INT32X4: {
      '+=': {
        DartType.LIST_INT32X4,
      },
    },
    DartType.LIST_FLOAT64X2: {
      '+=': {
        DartType.LIST_FLOAT64X2,
      },
    },
    DartType.INT32X4: {
      '=': {
        DartType.INT32X4,
      },
      '??=': {
        DartType.INT32X4,
      },
      '|=': {
        DartType.INT32X4,
      },
      '&=': {
        DartType.INT32X4,
      },
      '^=': {
        DartType.INT32X4,
      },
      '+=': {
        DartType.INT32X4,
      },
      '-=': {
        DartType.INT32X4,
      },
    },
    DartType.BOOL: {
      '=': {
        DartType.BOOL,
      },
      '??=': {
        DartType.BOOL,
      },
    },
    DartType.INT: {
      '~/=': {
        DartType.NUM,
      },
      '=': {
        DartType.INT,
      },
      '??=': {
        DartType.INT,
      },
      '&=': {
        DartType.INT,
      },
      '|=': {
        DartType.INT,
      },
      '^=': {
        DartType.INT,
      },
      '<<=': {
        DartType.INT,
      },
      '>>=': {
        DartType.INT,
      },
    },
    DartType.DURATION: {
      '=': {
        DartType.DURATION,
      },
      '??=': {
        DartType.DURATION,
      },
      '+=': {
        DartType.DURATION,
      },
      '-=': {
        DartType.DURATION,
      },
      '*=': {
        DartType.NUM,
      },
      '~/=': {
        DartType.INT,
      },
    },
    DartType.NUM: {
      '=': {
        DartType.NUM,
      },
      '??=': {
        DartType.NUM,
      },
      '+=': {
        DartType.NUM,
      },
      '-=': {
        DartType.NUM,
      },
      '*=': {
        DartType.NUM,
      },
      '%=': {
        DartType.NUM,
      },
    },
    DartType.STRING: {
      '=': {
        DartType.STRING,
      },
      '??=': {
        DartType.STRING,
      },
      '+=': {
        DartType.STRING,
      },
      '*=': {
        DartType.INT,
      },
    },
    DartType.LIST_NUM: {
      '=': {
        DartType.LIST_NUM,
      },
      '??=': {
        DartType.LIST_NUM,
      },
      '+=': {
        DartType.LIST_NUM,
      },
    },
    DartType.LIST_STRING: {
      '=': {
        DartType.LIST_STRING,
      },
      '??=': {
        DartType.LIST_STRING,
      },
      '+=': {
        DartType.LIST_STRING,
      },
    },
    DartType.SET_BOOL: {
      '=': {
        DartType.SET_BOOL,
      },
      '??=': {
        DartType.SET_BOOL,
      },
    },
    DartType.SET_INT: {
      '=': {
        DartType.SET_INT,
      },
      '??=': {
        DartType.SET_INT,
      },
    },
    DartType.SET_NUM: {
      '=': {
        DartType.SET_NUM,
      },
      '??=': {
        DartType.SET_NUM,
      },
    },
    DartType.SET_STRING: {
      '=': {
        DartType.SET_STRING,
      },
      '??=': {
        DartType.SET_STRING,
      },
    },
    DartType.MAP_BOOL_BOOL: {
      '=': {
        DartType.MAP_BOOL_BOOL,
      },
      '??=': {
        DartType.MAP_BOOL_BOOL,
      },
    },
    DartType.MAP_BOOL_INT: {
      '=': {
        DartType.MAP_BOOL_INT,
      },
      '??=': {
        DartType.MAP_BOOL_INT,
      },
    },
    DartType.MAP_BOOL_NUM: {
      '=': {
        DartType.MAP_BOOL_NUM,
      },
      '??=': {
        DartType.MAP_BOOL_NUM,
      },
    },
    DartType.MAP_BOOL_STRING: {
      '=': {
        DartType.MAP_BOOL_STRING,
      },
      '??=': {
        DartType.MAP_BOOL_STRING,
      },
    },
    DartType.MAP_INT_BOOL: {
      '=': {
        DartType.MAP_INT_BOOL,
      },
      '??=': {
        DartType.MAP_INT_BOOL,
      },
    },
    DartType.MAP_INT_INT: {
      '=': {
        DartType.MAP_INT_INT,
      },
      '??=': {
        DartType.MAP_INT_INT,
      },
    },
    DartType.MAP_INT_STRING: {
      '=': {
        DartType.MAP_INT_STRING,
      },
      '??=': {
        DartType.MAP_INT_STRING,
      },
    },
    DartType.MAP_NUM_BOOL: {
      '=': {
        DartType.MAP_NUM_BOOL,
      },
      '??=': {
        DartType.MAP_NUM_BOOL,
      },
    },
    DartType.MAP_NUM_INT: {
      '=': {
        DartType.MAP_NUM_INT,
      },
      '??=': {
        DartType.MAP_NUM_INT,
      },
    },
    DartType.MAP_NUM_NUM: {
      '=': {
        DartType.MAP_NUM_NUM,
      },
      '??=': {
        DartType.MAP_NUM_NUM,
      },
    },
    DartType.MAP_NUM_STRING: {
      '=': {
        DartType.MAP_NUM_STRING,
      },
      '??=': {
        DartType.MAP_NUM_STRING,
      },
    },
    DartType.MAP_STRING_BOOL: {
      '=': {
        DartType.MAP_STRING_BOOL,
      },
      '??=': {
        DartType.MAP_STRING_BOOL,
      },
    },
    DartType.MAP_STRING_INT: {
      '=': {
        DartType.MAP_STRING_INT,
      },
      '??=': {
        DartType.MAP_STRING_INT,
      },
    },
    DartType.MAP_STRING_NUM: {
      '=': {
        DartType.MAP_STRING_NUM,
      },
      '??=': {
        DartType.MAP_STRING_NUM,
      },
    },
    DartType.SET_LIST_INT: {
      '=': {
        DartType.SET_LIST_INT,
      },
      '??=': {
        DartType.SET_LIST_INT,
      },
    },
    DartType.MAP_BOOL_SET_STRING: {
      '=': {
        DartType.MAP_BOOL_SET_STRING,
      },
      '??=': {
        DartType.MAP_BOOL_SET_STRING,
      },
    },
    DartType.MAP_INT_MAP_NUM_BOOL: {
      '=': {
        DartType.MAP_INT_MAP_NUM_BOOL,
      },
      '??=': {
        DartType.MAP_INT_MAP_NUM_BOOL,
      },
    },
    DartType.MAP_LIST_INT_SET_INT: {
      '=': {
        DartType.MAP_LIST_INT_SET_INT,
      },
      '??=': {
        DartType.MAP_LIST_INT_SET_INT,
      },
    },
    DartType.MAP_SET_BOOL_MAP_NUM_STRING: {
      '=': {
        DartType.MAP_SET_BOOL_MAP_NUM_STRING,
      },
      '??=': {
        DartType.MAP_SET_BOOL_MAP_NUM_STRING,
      },
    },
    DartType.MAP_SET_INT_INT: {
      '=': {
        DartType.MAP_SET_INT_INT,
      },
      '??=': {
        DartType.MAP_SET_INT_INT,
      },
    },
    DartType.MAP_SET_NUM_SET_BOOL: {
      '=': {
        DartType.MAP_SET_NUM_SET_BOOL,
      },
      '??=': {
        DartType.MAP_SET_NUM_SET_BOOL,
      },
    },
    DartType.MAP_SET_STRING_MAP_BOOL_INT: {
      '=': {
        DartType.MAP_SET_STRING_MAP_BOOL_INT,
      },
      '??=': {
        DartType.MAP_SET_STRING_MAP_BOOL_INT,
      },
    },
    DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT: {
      '=': {
        DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
      },
      '??=': {
        DartType.MAP_MAP_BOOL_INT_MAP_NUM_INT,
      },
    },
    DartType.MAP_MAP_BOOL_STRING_BOOL: {
      '=': {
        DartType.MAP_MAP_BOOL_STRING_BOOL,
      },
      '??=': {
        DartType.MAP_MAP_BOOL_STRING_BOOL,
      },
    },
    DartType.MAP_MAP_INT_INT_SET_INT: {
      '=': {
        DartType.MAP_MAP_INT_INT_SET_INT,
      },
      '??=': {
        DartType.MAP_MAP_INT_INT_SET_INT,
      },
    },
    DartType.MAP_MAP_NUM_NUM_INT: {
      '=': {
        DartType.MAP_MAP_NUM_NUM_INT,
      },
      '??=': {
        DartType.MAP_MAP_NUM_NUM_INT,
      },
    },
    DartType.MAP_MAP_NUM_STRING_SET_BOOL: {
      '=': {
        DartType.MAP_MAP_NUM_STRING_SET_BOOL,
      },
      '??=': {
        DartType.MAP_MAP_NUM_STRING_SET_BOOL,
      },
    },
    DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT: {
      '=': {
        DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
      },
      '??=': {
        DartType.MAP_MAP_STRING_BOOL_MAP_BOOL_INT,
      },
    },
    DartType.MAP_MAP_STRING_INT_MAP_NUM_INT: {
      '=': {
        DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
      },
      '??=': {
        DartType.MAP_MAP_STRING_INT_MAP_NUM_INT,
      },
    },
  };
}

class DartTypeFlatTp extends DartType {
  final String name;
  const DartTypeFlatTp._withName(this.name) : super._withName(name);
  const DartTypeFlatTp() : name = null;
  static bool isListType(DartType tp) {
    return DartType._listTypes.contains(tp);
  }

  static bool isMapType(DartType tp) {
    return DartType._mapTypes.contains(tp);
  }

  static bool isCollectionType(DartType tp) {
    return DartType._collectionTypes.contains(tp);
  }

  static bool isGrowableType(DartType tp) {
    return DartType._growableTypes.contains(tp);
  }

  static bool isComplexType(DartType tp) {
    return DartType._complexTypes.contains(tp);
  }

  bool isInterfaceOfType(DartType tp, DartType iTp) {
    return _interfaceRels.containsKey(iTp) && _interfaceRels[iTp].contains(tp);
  }

  Set<DartType> get mapTypes {
    return _mapTypes;
  }

  bool isSpecializable(DartType tp) {
    return _interfaceRels.containsKey(tp);
  }

  Set<DartType> interfaces(DartType tp) {
    if (_interfaceRels.containsKey(tp)) {
      return _interfaceRels[tp];
    }
    return null;
  }

  DartType indexType(DartType tp) {
    if (_indexedBy.containsKey(tp)) {
      return _indexedBy[tp];
    }
    return null;
  }

  Set<DartType> indexableElementTypes(DartType tp) {
    if (_indexableElementOf.containsKey(tp)) {
      return _indexableElementOf[tp];
    }
    return null;
  }

  bool isIndexableElementType(DartType tp) {
    return _indexableElementOf.containsKey(tp);
  }

  DartType elementType(DartType tp) {
    if (_subscriptsTo.containsKey(tp)) {
      return _subscriptsTo[tp];
    }
    return null;
  }

  Set<DartType> get iterableTypes1 {
    return _iterableTypes1;
  }

  Set<String> uniOps(DartType tp) {
    if (_uniOps.containsKey(tp)) {
      return _uniOps[tp];
    }
    return <String>{};
  }

  Set<String> binOps(DartType tp) {
    if (_binOps.containsKey(tp)) {
      return _binOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<List<DartType>> binOpParameters(DartType tp, String op) {
    if (_binOps.containsKey(tp) && _binOps[tp].containsKey(op)) {
      return _binOps[tp][op];
    }
    return null;
  }

  Set<String> assignOps(DartType tp) {
    if (_assignOps.containsKey(tp)) {
      return _assignOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<DartType> assignOpRhs(DartType tp, String op) {
    if (_assignOps.containsKey(tp) && _assignOps[tp].containsKey(op)) {
      return _assignOps[tp][op];
    }
    return <DartType>{};
  }

  bool hasConstructor(DartType tp) {
    return _constructors.containsKey(tp);
  }

  Set<String> constructors(DartType tp) {
    if (_constructors.containsKey(tp)) {
      return _constructors[tp].keys.toSet();
    }
    return <String>{};
  }

  List<DartType> constructorParameters(DartType tp, String constructor) {
    if (_constructors.containsKey(tp) &&
        _constructors[tp].containsKey(constructor)) {
      return _constructors[tp][constructor];
    }
    return null;
  }

  Set<DartType> get allTypes {
    return _allTypes;
  }

  // All types extracted from analyzer.
  static const _allTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.FLOAT32LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT32X4LIST,
    DartType.INT32X4LIST,
    DartType.FLOAT64X2LIST,
    DartType.FLOAT32X4,
    DartType.INT32X4,
    DartType.FLOAT64X2,
    DartType.BOOL,
    DartType.DOUBLE,
    DartType.DURATION,
    DartType.INT,
    DartType.NUM,
    DartType.STRING,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_DOUBLE,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_NUM,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_DOUBLE,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
  };

  // All List<E> types: LIST_INT, LIST_STRING, etc.
  static const Set<DartType> _listTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.FLOAT32LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT32X4LIST,
    DartType.INT32X4LIST,
    DartType.FLOAT64X2LIST,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
  };

  // All Set types: SET_INT, SET_STRING, etc.
  static const Set<DartType> _setTypes = {
    DartType.SET_BOOL,
    DartType.SET_DOUBLE,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
  };

  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
  static const Set<DartType> _mapTypes = {
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_NUM,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_DOUBLE,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
  };

  // All collection types: list, map and set types.
  static const Set<DartType> _collectionTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.FLOAT32LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT32X4LIST,
    DartType.INT32X4LIST,
    DartType.FLOAT64X2LIST,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_DOUBLE,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_NUM,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_DOUBLE,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
  };

  // All growable types: list, map, set and string types.
  static const Set<DartType> _growableTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.FLOAT32LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT32X4LIST,
    DartType.INT32X4LIST,
    DartType.FLOAT64X2LIST,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_DOUBLE,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_NUM,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_DOUBLE,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
    DartType.STRING,
  };

  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.
  static const Set<DartType> _indexableTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.FLOAT32LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT32X4LIST,
    DartType.INT32X4LIST,
    DartType.FLOAT64X2LIST,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_NUM,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_DOUBLE,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
  };

  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.
  static const Map<DartType, DartType> _subscriptsTo = {
    DartType.INT8LIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.INT16LIST: DartType.INT,
    DartType.UINT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.INT64LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.FLOAT32LIST: DartType.DOUBLE,
    DartType.FLOAT64LIST: DartType.DOUBLE,
    DartType.FLOAT32X4LIST: DartType.FLOAT32X4,
    DartType.INT32X4LIST: DartType.INT32X4,
    DartType.FLOAT64X2LIST: DartType.FLOAT64X2,
    DartType.DURATION: DartType.DURATION,
    DartType.NUM: DartType.NUM,
    DartType.STRING: DartType.STRING,
    DartType.LIST_DOUBLE: DartType.DOUBLE,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_NUM: DartType.NUM,
    DartType.LIST_STRING: DartType.STRING,
    DartType.SET_BOOL: DartType.BOOL,
    DartType.SET_DOUBLE: DartType.DOUBLE,
    DartType.SET_INT: DartType.INT,
    DartType.SET_NUM: DartType.NUM,
    DartType.SET_STRING: DartType.STRING,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.INT,
    DartType.MAP_BOOL_NUM: DartType.NUM,
    DartType.MAP_BOOL_STRING: DartType.STRING,
    DartType.MAP_DOUBLE_BOOL: DartType.BOOL,
    DartType.MAP_DOUBLE_DOUBLE: DartType.DOUBLE,
    DartType.MAP_DOUBLE_INT: DartType.INT,
    DartType.MAP_DOUBLE_NUM: DartType.NUM,
    DartType.MAP_DOUBLE_STRING: DartType.STRING,
    DartType.MAP_INT_BOOL: DartType.BOOL,
    DartType.MAP_INT_DOUBLE: DartType.DOUBLE,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.STRING,
    DartType.MAP_NUM_BOOL: DartType.BOOL,
    DartType.MAP_NUM_DOUBLE: DartType.DOUBLE,
    DartType.MAP_NUM_INT: DartType.INT,
    DartType.MAP_NUM_NUM: DartType.NUM,
    DartType.MAP_NUM_STRING: DartType.STRING,
    DartType.MAP_STRING_BOOL: DartType.BOOL,
    DartType.MAP_STRING_DOUBLE: DartType.DOUBLE,
    DartType.MAP_STRING_INT: DartType.INT,
    DartType.MAP_STRING_NUM: DartType.NUM,
  };

  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.
  static const Map<DartType, DartType> _indexedBy = {
    DartType.INT8LIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.INT16LIST: DartType.INT,
    DartType.UINT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.INT64LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.FLOAT32LIST: DartType.INT,
    DartType.FLOAT64LIST: DartType.INT,
    DartType.FLOAT32X4LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT,
    DartType.FLOAT64X2LIST: DartType.INT,
    DartType.LIST_DOUBLE: DartType.INT,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_NUM: DartType.INT,
    DartType.LIST_STRING: DartType.INT,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.BOOL,
    DartType.MAP_BOOL_NUM: DartType.BOOL,
    DartType.MAP_BOOL_STRING: DartType.BOOL,
    DartType.MAP_DOUBLE_BOOL: DartType.DOUBLE,
    DartType.MAP_DOUBLE_DOUBLE: DartType.DOUBLE,
    DartType.MAP_DOUBLE_INT: DartType.DOUBLE,
    DartType.MAP_DOUBLE_NUM: DartType.DOUBLE,
    DartType.MAP_DOUBLE_STRING: DartType.DOUBLE,
    DartType.MAP_INT_BOOL: DartType.INT,
    DartType.MAP_INT_DOUBLE: DartType.INT,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.INT,
    DartType.MAP_NUM_BOOL: DartType.NUM,
    DartType.MAP_NUM_DOUBLE: DartType.NUM,
    DartType.MAP_NUM_INT: DartType.NUM,
    DartType.MAP_NUM_NUM: DartType.NUM,
    DartType.MAP_NUM_STRING: DartType.NUM,
    DartType.MAP_STRING_BOOL: DartType.STRING,
    DartType.MAP_STRING_DOUBLE: DartType.STRING,
    DartType.MAP_STRING_INT: DartType.STRING,
    DartType.MAP_STRING_NUM: DartType.STRING,
  };

  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>
  static const Map<DartType, Set<DartType>> _elementOf = {
    DartType.INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
      DartType.SET_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_DOUBLE_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_NUM_INT,
      DartType.MAP_STRING_INT,
    },
    DartType.DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.LIST_DOUBLE,
      DartType.SET_DOUBLE,
      DartType.MAP_DOUBLE_DOUBLE,
      DartType.MAP_INT_DOUBLE,
      DartType.MAP_NUM_DOUBLE,
      DartType.MAP_STRING_DOUBLE,
    },
    DartType.FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.DURATION: {
      DartType.DURATION,
    },
    DartType.NUM: {
      DartType.NUM,
      DartType.LIST_NUM,
      DartType.SET_NUM,
      DartType.MAP_BOOL_NUM,
      DartType.MAP_DOUBLE_NUM,
      DartType.MAP_NUM_NUM,
      DartType.MAP_STRING_NUM,
    },
    DartType.STRING: {
      DartType.STRING,
      DartType.LIST_STRING,
      DartType.SET_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_DOUBLE_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_NUM_STRING,
    },
    DartType.BOOL: {
      DartType.SET_BOOL,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_DOUBLE_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_NUM_BOOL,
      DartType.MAP_STRING_BOOL,
    },
  };

  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.
  static const Map<DartType, Set<DartType>> _indexableElementOf = {
    DartType.INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_DOUBLE_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_NUM_INT,
      DartType.MAP_STRING_INT,
    },
    DartType.DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.LIST_DOUBLE,
      DartType.MAP_DOUBLE_DOUBLE,
      DartType.MAP_INT_DOUBLE,
      DartType.MAP_NUM_DOUBLE,
      DartType.MAP_STRING_DOUBLE,
    },
    DartType.FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.NUM: {
      DartType.LIST_NUM,
      DartType.MAP_BOOL_NUM,
      DartType.MAP_DOUBLE_NUM,
      DartType.MAP_NUM_NUM,
      DartType.MAP_STRING_NUM,
    },
    DartType.STRING: {
      DartType.LIST_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_DOUBLE_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_NUM_STRING,
    },
    DartType.BOOL: {
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_DOUBLE_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_NUM_BOOL,
      DartType.MAP_STRING_BOOL,
    },
  };

  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.
  static const Set<DartType> _iterableTypes1 = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.FLOAT32LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT32X4LIST,
    DartType.INT32X4LIST,
    DartType.FLOAT64X2LIST,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
  };

  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.
  static const Map<DartType, Set<DartType>> _interfaceRels = {
    DartType.LIST_INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
    },
    DartType._TYPEDINTLIST: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
    },
    DartType.OBJECT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.FLOAT32X4LIST,
      DartType.INT32X4LIST,
      DartType.FLOAT64X2LIST,
      DartType.FLOAT32X4,
      DartType.INT32X4,
      DartType.FLOAT64X2,
      DartType.BOOL,
      DartType.DOUBLE,
      DartType.DURATION,
      DartType.INT,
      DartType.NUM,
      DartType.STRING,
      DartType.LIST_DOUBLE,
      DartType.LIST_INT,
      DartType.LIST_NUM,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_DOUBLE,
      DartType.SET_INT,
      DartType.SET_NUM,
      DartType.SET_STRING,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_BOOL_INT,
      DartType.MAP_BOOL_NUM,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_DOUBLE_BOOL,
      DartType.MAP_DOUBLE_DOUBLE,
      DartType.MAP_DOUBLE_INT,
      DartType.MAP_DOUBLE_NUM,
      DartType.MAP_DOUBLE_STRING,
      DartType.MAP_INT_BOOL,
      DartType.MAP_INT_DOUBLE,
      DartType.MAP_INT_INT,
      DartType.MAP_INT_STRING,
      DartType.MAP_NUM_BOOL,
      DartType.MAP_NUM_DOUBLE,
      DartType.MAP_NUM_INT,
      DartType.MAP_NUM_NUM,
      DartType.MAP_NUM_STRING,
      DartType.MAP_STRING_BOOL,
      DartType.MAP_STRING_DOUBLE,
      DartType.MAP_STRING_INT,
      DartType.MAP_STRING_NUM,
    },
    DartType.TYPEDDATA: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.FLOAT32X4LIST,
      DartType.INT32X4LIST,
      DartType.FLOAT64X2LIST,
    },
    DartType.ITERABLE_INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
    },
    DartType.LIST_DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.LIST_DOUBLE,
    },
    DartType.EFFICIENTLENGTHITERABLE_DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.LIST_DOUBLE,
    },
    DartType._TYPEDFLOATLIST: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
    },
    DartType.ITERABLE_DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
    },
    DartType.LIST_FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.ITERABLE_FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.LIST_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.ITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.LIST_FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.ITERABLE_FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.NUM: {
      DartType.DOUBLE,
      DartType.INT,
      DartType.NUM,
    },
    DartType.COMPARABLE_NUM: {
      DartType.DOUBLE,
      DartType.INT,
      DartType.NUM,
    },
    DartType.COMPARABLE_DURATION: {
      DartType.DURATION,
    },
    DartType.COMPARABLE_STRING: {
      DartType.STRING,
    },
    DartType.PATTERN: {
      DartType.STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_E: {
      DartType.LIST_DOUBLE,
      DartType.LIST_INT,
      DartType.LIST_NUM,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_DOUBLE,
      DartType.SET_INT,
      DartType.SET_NUM,
      DartType.SET_STRING,
    },
    DartType.ITERABLE_E: {
      DartType.LIST_DOUBLE,
      DartType.LIST_INT,
      DartType.LIST_NUM,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_DOUBLE,
      DartType.SET_INT,
      DartType.SET_NUM,
      DartType.SET_STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_NUM: {
      DartType.LIST_NUM,
    },
    DartType.EFFICIENTLENGTHITERABLE_STRING: {
      DartType.LIST_STRING,
    },
  };

  // Map type to a list of constructors names with a list of constructor
  // parameter types.
  static const Map<DartType, Map<String, List<DartType>>> _constructors = {
    DartType.INT8LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT8LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT8CLAMPEDLIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT16LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT16LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT32LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT32LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT64LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT64LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.FLOAT32LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_DOUBLE,
      ],
    },
    DartType.FLOAT64LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_DOUBLE,
      ],
    },
    DartType.FLOAT32X4LIST: {
      '': [
        DartType.INT,
      ],
    },
    DartType.INT32X4LIST: {
      '': [
        DartType.INT,
      ],
    },
    DartType.FLOAT64X2LIST: {
      '': [
        DartType.INT,
      ],
    },
    DartType.FLOAT32X4: {
      '': [
        DartType.DOUBLE,
        DartType.DOUBLE,
        DartType.DOUBLE,
        DartType.DOUBLE,
      ],
      'splat': [
        DartType.DOUBLE,
      ],
      'zero': [],
    },
    DartType.INT32X4: {
      '': [
        DartType.INT,
        DartType.INT,
        DartType.INT,
        DartType.INT,
      ],
    },
    DartType.FLOAT64X2: {
      '': [
        DartType.DOUBLE,
        DartType.DOUBLE,
      ],
      'splat': [
        DartType.DOUBLE,
      ],
      'zero': [],
    },
    DartType.DURATION: {
      '': [],
    },
  };

  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.
  static const Map<DartType, Map<String, Set<List<DartType>>>> _binOps = {
    DartType.LIST_INT: {
      '+': {
        [
          DartType.LIST_INT,
          DartType.LIST_INT,
        ],
      },
      '??': {
        [
          DartType.LIST_INT,
          DartType.LIST_INT,
        ],
      },
    },
    DartType.LIST_FLOAT32X4: {
      '+': {
        [
          DartType.FLOAT32X4LIST,
          DartType.LIST_FLOAT32X4,
        ],
      },
      '??': {
        [
          DartType.LIST_FLOAT32X4,
          DartType.LIST_FLOAT32X4,
        ],
      },
    },
    DartType.LIST_INT32X4: {
      '+': {
        [
          DartType.INT32X4LIST,
          DartType.LIST_INT32X4,
        ],
      },
      '??': {
        [
          DartType.LIST_INT32X4,
          DartType.LIST_INT32X4,
        ],
      },
    },
    DartType.LIST_FLOAT64X2: {
      '+': {
        [
          DartType.FLOAT64X2LIST,
          DartType.LIST_FLOAT64X2,
        ],
      },
      '??': {
        [
          DartType.LIST_FLOAT64X2,
          DartType.LIST_FLOAT64X2,
        ],
      },
    },
    DartType.FLOAT32X4: {
      '+': {
        [
          DartType.FLOAT32X4,
          DartType.FLOAT32X4,
        ],
      },
      '-': {
        [
          DartType.FLOAT32X4,
          DartType.FLOAT32X4,
        ],
      },
      '*': {
        [
          DartType.FLOAT32X4,
          DartType.FLOAT32X4,
        ],
      },
      '/': {
        [
          DartType.FLOAT32X4,
          DartType.FLOAT32X4,
        ],
      },
      '??': {
        [
          DartType.FLOAT32X4,
          DartType.FLOAT32X4,
        ],
      },
    },
    DartType.INT32X4: {
      '|': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '&': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '^': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '+': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '-': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '??': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
    },
    DartType.FLOAT64X2: {
      '+': {
        [
          DartType.FLOAT64X2,
          DartType.FLOAT64X2,
        ],
      },
      '-': {
        [
          DartType.FLOAT64X2,
          DartType.FLOAT64X2,
        ],
      },
      '*': {
        [
          DartType.FLOAT64X2,
          DartType.FLOAT64X2,
        ],
      },
      '/': {
        [
          DartType.FLOAT64X2,
          DartType.FLOAT64X2,
        ],
      },
      '??': {
        [
          DartType.FLOAT64X2,
          DartType.FLOAT64X2,
        ],
      },
    },
    DartType.BOOL: {
      '&': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '|': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '^': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '<': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '>': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '<=': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '>=': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '==': {
        [
          DartType.NUM,
          DartType.OBJECT,
        ],
        [
          DartType.STRING,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_DOUBLE,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_INT,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_NUM,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_STRING,
          DartType.OBJECT,
        ],
      },
      '??': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '&&': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '||': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
    },
    DartType.DOUBLE: {
      '+': {
        [
          DartType.DOUBLE,
          DartType.NUM,
        ],
      },
      '-': {
        [
          DartType.DOUBLE,
          DartType.NUM,
        ],
      },
      '*': {
        [
          DartType.DOUBLE,
          DartType.NUM,
        ],
      },
      '%': {
        [
          DartType.DOUBLE,
          DartType.NUM,
        ],
      },
      '/': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '??': {
        [
          DartType.DOUBLE,
          DartType.DOUBLE,
        ],
      },
    },
    DartType.INT: {
      '~/': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '&': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '|': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '^': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '<<': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '>>': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '??': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
    },
    DartType.DURATION: {
      '+': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
      '-': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
      '*': {
        [
          DartType.DURATION,
          DartType.NUM,
        ],
      },
      '~/': {
        [
          DartType.DURATION,
          DartType.INT,
        ],
      },
      '??': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
    },
    DartType.NUM: {
      '+': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '-': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '*': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '%': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '??': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
    },
    DartType.STRING: {
      '+': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
      '*': {
        [
          DartType.STRING,
          DartType.INT,
        ],
      },
      '??': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
    },
    DartType.LIST_DOUBLE: {
      '+': {
        [
          DartType.LIST_DOUBLE,
          DartType.LIST_DOUBLE,
        ],
      },
      '??': {
        [
          DartType.LIST_DOUBLE,
          DartType.LIST_DOUBLE,
        ],
      },
    },
    DartType.LIST_NUM: {
      '+': {
        [
          DartType.LIST_NUM,
          DartType.LIST_NUM,
        ],
      },
      '??': {
        [
          DartType.LIST_NUM,
          DartType.LIST_NUM,
        ],
      },
    },
    DartType.LIST_STRING: {
      '+': {
        [
          DartType.LIST_STRING,
          DartType.LIST_STRING,
        ],
      },
      '??': {
        [
          DartType.LIST_STRING,
          DartType.LIST_STRING,
        ],
      },
    },
  };

  // Map type to a list of available unary operators.
  static const Map<DartType, Set<String>> _uniOps = {
    DartType.FLOAT32X4: {'-'},
    DartType.FLOAT64X2: {'-'},
    DartType.DOUBLE: {'-'},
    DartType.DURATION: {'-'},
    DartType.INT: {'~', '-'},
    DartType.NUM: {'-'},
    DartType.BOOL: {'!'},
  };

  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.
  static const Map<DartType, Map<String, Set<DartType>>> _assignOps = {
    DartType.INT8LIST: {
      '=': {
        DartType.INT8LIST,
      },
      '??=': {
        DartType.INT8LIST,
      },
    },
    DartType.UINT8LIST: {
      '=': {
        DartType.UINT8LIST,
      },
      '??=': {
        DartType.UINT8LIST,
      },
    },
    DartType.LIST_INT: {
      '+=': {
        DartType.LIST_INT,
      },
      '=': {
        DartType.LIST_INT,
      },
      '??=': {
        DartType.LIST_INT,
      },
    },
    DartType.UINT8CLAMPEDLIST: {
      '=': {
        DartType.UINT8CLAMPEDLIST,
      },
      '??=': {
        DartType.UINT8CLAMPEDLIST,
      },
    },
    DartType.INT16LIST: {
      '=': {
        DartType.INT16LIST,
      },
      '??=': {
        DartType.INT16LIST,
      },
    },
    DartType.UINT16LIST: {
      '=': {
        DartType.UINT16LIST,
      },
      '??=': {
        DartType.UINT16LIST,
      },
    },
    DartType.INT32LIST: {
      '=': {
        DartType.INT32LIST,
      },
      '??=': {
        DartType.INT32LIST,
      },
    },
    DartType.UINT32LIST: {
      '=': {
        DartType.UINT32LIST,
      },
      '??=': {
        DartType.UINT32LIST,
      },
    },
    DartType.INT64LIST: {
      '=': {
        DartType.INT64LIST,
      },
      '??=': {
        DartType.INT64LIST,
      },
    },
    DartType.UINT64LIST: {
      '=': {
        DartType.UINT64LIST,
      },
      '??=': {
        DartType.UINT64LIST,
      },
    },
    DartType.FLOAT32LIST: {
      '=': {
        DartType.FLOAT32LIST,
      },
      '??=': {
        DartType.FLOAT32LIST,
      },
    },
    DartType.FLOAT64LIST: {
      '=': {
        DartType.FLOAT64LIST,
      },
      '??=': {
        DartType.FLOAT64LIST,
      },
    },
    DartType.FLOAT32X4LIST: {
      '=': {
        DartType.FLOAT32X4LIST,
      },
      '??=': {
        DartType.FLOAT32X4LIST,
      },
    },
    DartType.LIST_FLOAT32X4: {
      '+=': {
        DartType.LIST_FLOAT32X4,
      },
    },
    DartType.INT32X4LIST: {
      '=': {
        DartType.INT32X4LIST,
      },
      '??=': {
        DartType.INT32X4LIST,
      },
    },
    DartType.LIST_INT32X4: {
      '+=': {
        DartType.LIST_INT32X4,
      },
    },
    DartType.FLOAT64X2LIST: {
      '=': {
        DartType.FLOAT64X2LIST,
      },
      '??=': {
        DartType.FLOAT64X2LIST,
      },
    },
    DartType.LIST_FLOAT64X2: {
      '+=': {
        DartType.LIST_FLOAT64X2,
      },
    },
    DartType.FLOAT32X4: {
      '=': {
        DartType.FLOAT32X4,
      },
      '??=': {
        DartType.FLOAT32X4,
      },
      '+=': {
        DartType.FLOAT32X4,
      },
      '-=': {
        DartType.FLOAT32X4,
      },
      '*=': {
        DartType.FLOAT32X4,
      },
      '/=': {
        DartType.FLOAT32X4,
      },
    },
    DartType.INT32X4: {
      '=': {
        DartType.INT32X4,
      },
      '??=': {
        DartType.INT32X4,
      },
      '|=': {
        DartType.INT32X4,
      },
      '&=': {
        DartType.INT32X4,
      },
      '^=': {
        DartType.INT32X4,
      },
      '+=': {
        DartType.INT32X4,
      },
      '-=': {
        DartType.INT32X4,
      },
    },
    DartType.FLOAT64X2: {
      '=': {
        DartType.FLOAT64X2,
      },
      '??=': {
        DartType.FLOAT64X2,
      },
      '+=': {
        DartType.FLOAT64X2,
      },
      '-=': {
        DartType.FLOAT64X2,
      },
      '*=': {
        DartType.FLOAT64X2,
      },
      '/=': {
        DartType.FLOAT64X2,
      },
    },
    DartType.BOOL: {
      '=': {
        DartType.BOOL,
      },
      '??=': {
        DartType.BOOL,
      },
    },
    DartType.DOUBLE: {
      '=': {
        DartType.DOUBLE,
      },
      '??=': {
        DartType.DOUBLE,
      },
      '+=': {
        DartType.NUM,
      },
      '-=': {
        DartType.NUM,
      },
      '*=': {
        DartType.NUM,
      },
      '%=': {
        DartType.NUM,
      },
      '/=': {
        DartType.NUM,
      },
    },
    DartType.INT: {
      '~/=': {
        DartType.NUM,
      },
      '=': {
        DartType.INT,
      },
      '??=': {
        DartType.INT,
      },
      '&=': {
        DartType.INT,
      },
      '|=': {
        DartType.INT,
      },
      '^=': {
        DartType.INT,
      },
      '<<=': {
        DartType.INT,
      },
      '>>=': {
        DartType.INT,
      },
    },
    DartType.DURATION: {
      '=': {
        DartType.DURATION,
      },
      '??=': {
        DartType.DURATION,
      },
      '+=': {
        DartType.DURATION,
      },
      '-=': {
        DartType.DURATION,
      },
      '*=': {
        DartType.NUM,
      },
      '~/=': {
        DartType.INT,
      },
    },
    DartType.NUM: {
      '=': {
        DartType.NUM,
      },
      '??=': {
        DartType.NUM,
      },
      '+=': {
        DartType.NUM,
      },
      '-=': {
        DartType.NUM,
      },
      '*=': {
        DartType.NUM,
      },
      '%=': {
        DartType.NUM,
      },
    },
    DartType.STRING: {
      '=': {
        DartType.STRING,
      },
      '??=': {
        DartType.STRING,
      },
      '+=': {
        DartType.STRING,
      },
      '*=': {
        DartType.INT,
      },
    },
    DartType.LIST_DOUBLE: {
      '=': {
        DartType.LIST_DOUBLE,
      },
      '??=': {
        DartType.LIST_DOUBLE,
      },
      '+=': {
        DartType.LIST_DOUBLE,
      },
    },
    DartType.LIST_NUM: {
      '=': {
        DartType.LIST_NUM,
      },
      '??=': {
        DartType.LIST_NUM,
      },
      '+=': {
        DartType.LIST_NUM,
      },
    },
    DartType.LIST_STRING: {
      '=': {
        DartType.LIST_STRING,
      },
      '??=': {
        DartType.LIST_STRING,
      },
      '+=': {
        DartType.LIST_STRING,
      },
    },
    DartType.SET_BOOL: {
      '=': {
        DartType.SET_BOOL,
      },
      '??=': {
        DartType.SET_BOOL,
      },
    },
    DartType.SET_DOUBLE: {
      '=': {
        DartType.SET_DOUBLE,
      },
      '??=': {
        DartType.SET_DOUBLE,
      },
    },
    DartType.SET_INT: {
      '=': {
        DartType.SET_INT,
      },
      '??=': {
        DartType.SET_INT,
      },
    },
    DartType.SET_NUM: {
      '=': {
        DartType.SET_NUM,
      },
      '??=': {
        DartType.SET_NUM,
      },
    },
    DartType.SET_STRING: {
      '=': {
        DartType.SET_STRING,
      },
      '??=': {
        DartType.SET_STRING,
      },
    },
    DartType.MAP_BOOL_BOOL: {
      '=': {
        DartType.MAP_BOOL_BOOL,
      },
      '??=': {
        DartType.MAP_BOOL_BOOL,
      },
    },
    DartType.MAP_BOOL_INT: {
      '=': {
        DartType.MAP_BOOL_INT,
      },
      '??=': {
        DartType.MAP_BOOL_INT,
      },
    },
    DartType.MAP_BOOL_NUM: {
      '=': {
        DartType.MAP_BOOL_NUM,
      },
      '??=': {
        DartType.MAP_BOOL_NUM,
      },
    },
    DartType.MAP_BOOL_STRING: {
      '=': {
        DartType.MAP_BOOL_STRING,
      },
      '??=': {
        DartType.MAP_BOOL_STRING,
      },
    },
    DartType.MAP_DOUBLE_BOOL: {
      '=': {
        DartType.MAP_DOUBLE_BOOL,
      },
      '??=': {
        DartType.MAP_DOUBLE_BOOL,
      },
    },
    DartType.MAP_DOUBLE_DOUBLE: {
      '=': {
        DartType.MAP_DOUBLE_DOUBLE,
      },
      '??=': {
        DartType.MAP_DOUBLE_DOUBLE,
      },
    },
    DartType.MAP_DOUBLE_INT: {
      '=': {
        DartType.MAP_DOUBLE_INT,
      },
      '??=': {
        DartType.MAP_DOUBLE_INT,
      },
    },
    DartType.MAP_DOUBLE_NUM: {
      '=': {
        DartType.MAP_DOUBLE_NUM,
      },
      '??=': {
        DartType.MAP_DOUBLE_NUM,
      },
    },
    DartType.MAP_DOUBLE_STRING: {
      '=': {
        DartType.MAP_DOUBLE_STRING,
      },
      '??=': {
        DartType.MAP_DOUBLE_STRING,
      },
    },
    DartType.MAP_INT_BOOL: {
      '=': {
        DartType.MAP_INT_BOOL,
      },
      '??=': {
        DartType.MAP_INT_BOOL,
      },
    },
    DartType.MAP_INT_DOUBLE: {
      '=': {
        DartType.MAP_INT_DOUBLE,
      },
      '??=': {
        DartType.MAP_INT_DOUBLE,
      },
    },
    DartType.MAP_INT_INT: {
      '=': {
        DartType.MAP_INT_INT,
      },
      '??=': {
        DartType.MAP_INT_INT,
      },
    },
    DartType.MAP_INT_STRING: {
      '=': {
        DartType.MAP_INT_STRING,
      },
      '??=': {
        DartType.MAP_INT_STRING,
      },
    },
    DartType.MAP_NUM_BOOL: {
      '=': {
        DartType.MAP_NUM_BOOL,
      },
      '??=': {
        DartType.MAP_NUM_BOOL,
      },
    },
    DartType.MAP_NUM_DOUBLE: {
      '=': {
        DartType.MAP_NUM_DOUBLE,
      },
      '??=': {
        DartType.MAP_NUM_DOUBLE,
      },
    },
    DartType.MAP_NUM_INT: {
      '=': {
        DartType.MAP_NUM_INT,
      },
      '??=': {
        DartType.MAP_NUM_INT,
      },
    },
    DartType.MAP_NUM_NUM: {
      '=': {
        DartType.MAP_NUM_NUM,
      },
      '??=': {
        DartType.MAP_NUM_NUM,
      },
    },
    DartType.MAP_NUM_STRING: {
      '=': {
        DartType.MAP_NUM_STRING,
      },
      '??=': {
        DartType.MAP_NUM_STRING,
      },
    },
    DartType.MAP_STRING_BOOL: {
      '=': {
        DartType.MAP_STRING_BOOL,
      },
      '??=': {
        DartType.MAP_STRING_BOOL,
      },
    },
    DartType.MAP_STRING_DOUBLE: {
      '=': {
        DartType.MAP_STRING_DOUBLE,
      },
      '??=': {
        DartType.MAP_STRING_DOUBLE,
      },
    },
    DartType.MAP_STRING_INT: {
      '=': {
        DartType.MAP_STRING_INT,
      },
      '??=': {
        DartType.MAP_STRING_INT,
      },
    },
    DartType.MAP_STRING_NUM: {
      '=': {
        DartType.MAP_STRING_NUM,
      },
      '??=': {
        DartType.MAP_STRING_NUM,
      },
    },
  };
}

class DartTypeNoFpFlatTp extends DartType {
  final String name;
  const DartTypeNoFpFlatTp._withName(this.name) : super._withName(name);
  const DartTypeNoFpFlatTp() : name = null;
  static bool isListType(DartType tp) {
    return DartType._listTypes.contains(tp);
  }

  static bool isMapType(DartType tp) {
    return DartType._mapTypes.contains(tp);
  }

  static bool isCollectionType(DartType tp) {
    return DartType._collectionTypes.contains(tp);
  }

  static bool isGrowableType(DartType tp) {
    return DartType._growableTypes.contains(tp);
  }

  static bool isComplexType(DartType tp) {
    return DartType._complexTypes.contains(tp);
  }

  bool isInterfaceOfType(DartType tp, DartType iTp) {
    return _interfaceRels.containsKey(iTp) && _interfaceRels[iTp].contains(tp);
  }

  Set<DartType> get mapTypes {
    return _mapTypes;
  }

  bool isSpecializable(DartType tp) {
    return _interfaceRels.containsKey(tp);
  }

  Set<DartType> interfaces(DartType tp) {
    if (_interfaceRels.containsKey(tp)) {
      return _interfaceRels[tp];
    }
    return null;
  }

  DartType indexType(DartType tp) {
    if (_indexedBy.containsKey(tp)) {
      return _indexedBy[tp];
    }
    return null;
  }

  Set<DartType> indexableElementTypes(DartType tp) {
    if (_indexableElementOf.containsKey(tp)) {
      return _indexableElementOf[tp];
    }
    return null;
  }

  bool isIndexableElementType(DartType tp) {
    return _indexableElementOf.containsKey(tp);
  }

  DartType elementType(DartType tp) {
    if (_subscriptsTo.containsKey(tp)) {
      return _subscriptsTo[tp];
    }
    return null;
  }

  Set<DartType> get iterableTypes1 {
    return _iterableTypes1;
  }

  Set<String> uniOps(DartType tp) {
    if (_uniOps.containsKey(tp)) {
      return _uniOps[tp];
    }
    return <String>{};
  }

  Set<String> binOps(DartType tp) {
    if (_binOps.containsKey(tp)) {
      return _binOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<List<DartType>> binOpParameters(DartType tp, String op) {
    if (_binOps.containsKey(tp) && _binOps[tp].containsKey(op)) {
      return _binOps[tp][op];
    }
    return null;
  }

  Set<String> assignOps(DartType tp) {
    if (_assignOps.containsKey(tp)) {
      return _assignOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<DartType> assignOpRhs(DartType tp, String op) {
    if (_assignOps.containsKey(tp) && _assignOps[tp].containsKey(op)) {
      return _assignOps[tp][op];
    }
    return <DartType>{};
  }

  bool hasConstructor(DartType tp) {
    return _constructors.containsKey(tp);
  }

  Set<String> constructors(DartType tp) {
    if (_constructors.containsKey(tp)) {
      return _constructors[tp].keys.toSet();
    }
    return <String>{};
  }

  List<DartType> constructorParameters(DartType tp, String constructor) {
    if (_constructors.containsKey(tp) &&
        _constructors[tp].containsKey(constructor)) {
      return _constructors[tp][constructor];
    }
    return null;
  }

  Set<DartType> get allTypes {
    return _allTypes;
  }

  // All types extracted from analyzer.
  static const _allTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.INT32X4,
    DartType.BOOL,
    DartType.DURATION,
    DartType.INT,
    DartType.NUM,
    DartType.STRING,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
  };

  // All List<E> types: LIST_INT, LIST_STRING, etc.
  static const Set<DartType> _listTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
  };

  // All Set types: SET_INT, SET_STRING, etc.
  static const Set<DartType> _setTypes = {
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
  };

  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
  static const Set<DartType> _mapTypes = {
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
  };

  // All collection types: list, map and set types.
  static const Set<DartType> _collectionTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
  };

  // All growable types: list, map, set and string types.
  static const Set<DartType> _growableTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_NUM,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
    DartType.STRING,
  };

  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.
  static const Set<DartType> _indexableTypes = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_NUM,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_NUM_BOOL,
    DartType.MAP_NUM_INT,
    DartType.MAP_NUM_NUM,
    DartType.MAP_NUM_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_NUM,
  };

  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.
  static const Map<DartType, DartType> _subscriptsTo = {
    DartType.INT8LIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.INT16LIST: DartType.INT,
    DartType.UINT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.INT64LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT32X4,
    DartType.DURATION: DartType.DURATION,
    DartType.NUM: DartType.NUM,
    DartType.STRING: DartType.STRING,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_NUM: DartType.NUM,
    DartType.LIST_STRING: DartType.STRING,
    DartType.SET_BOOL: DartType.BOOL,
    DartType.SET_INT: DartType.INT,
    DartType.SET_NUM: DartType.NUM,
    DartType.SET_STRING: DartType.STRING,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.INT,
    DartType.MAP_BOOL_NUM: DartType.NUM,
    DartType.MAP_BOOL_STRING: DartType.STRING,
    DartType.MAP_INT_BOOL: DartType.BOOL,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.STRING,
    DartType.MAP_NUM_BOOL: DartType.BOOL,
    DartType.MAP_NUM_INT: DartType.INT,
    DartType.MAP_NUM_NUM: DartType.NUM,
    DartType.MAP_NUM_STRING: DartType.STRING,
    DartType.MAP_STRING_BOOL: DartType.BOOL,
    DartType.MAP_STRING_INT: DartType.INT,
    DartType.MAP_STRING_NUM: DartType.NUM,
  };

  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.
  static const Map<DartType, DartType> _indexedBy = {
    DartType.INT8LIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.INT16LIST: DartType.INT,
    DartType.UINT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.INT64LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_NUM: DartType.INT,
    DartType.LIST_STRING: DartType.INT,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.BOOL,
    DartType.MAP_BOOL_NUM: DartType.BOOL,
    DartType.MAP_BOOL_STRING: DartType.BOOL,
    DartType.MAP_INT_BOOL: DartType.INT,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.INT,
    DartType.MAP_NUM_BOOL: DartType.NUM,
    DartType.MAP_NUM_INT: DartType.NUM,
    DartType.MAP_NUM_NUM: DartType.NUM,
    DartType.MAP_NUM_STRING: DartType.NUM,
    DartType.MAP_STRING_BOOL: DartType.STRING,
    DartType.MAP_STRING_INT: DartType.STRING,
    DartType.MAP_STRING_NUM: DartType.STRING,
  };

  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>
  static const Map<DartType, Set<DartType>> _elementOf = {
    DartType.INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
      DartType.SET_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_NUM_INT,
      DartType.MAP_STRING_INT,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.DURATION: {
      DartType.DURATION,
    },
    DartType.NUM: {
      DartType.NUM,
      DartType.LIST_NUM,
      DartType.SET_NUM,
      DartType.MAP_BOOL_NUM,
      DartType.MAP_NUM_NUM,
      DartType.MAP_STRING_NUM,
    },
    DartType.STRING: {
      DartType.STRING,
      DartType.LIST_STRING,
      DartType.SET_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_NUM_STRING,
    },
    DartType.BOOL: {
      DartType.SET_BOOL,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_NUM_BOOL,
      DartType.MAP_STRING_BOOL,
    },
  };

  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.
  static const Map<DartType, Set<DartType>> _indexableElementOf = {
    DartType.INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_NUM_INT,
      DartType.MAP_STRING_INT,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.NUM: {
      DartType.LIST_NUM,
      DartType.MAP_BOOL_NUM,
      DartType.MAP_NUM_NUM,
      DartType.MAP_STRING_NUM,
    },
    DartType.STRING: {
      DartType.LIST_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_NUM_STRING,
    },
    DartType.BOOL: {
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_NUM_BOOL,
      DartType.MAP_STRING_BOOL,
    },
  };

  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.
  static const Set<DartType> _iterableTypes1 = {
    DartType.INT8LIST,
    DartType.UINT8LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.INT16LIST,
    DartType.UINT16LIST,
    DartType.INT32LIST,
    DartType.UINT32LIST,
    DartType.INT64LIST,
    DartType.UINT64LIST,
    DartType.INT32X4LIST,
    DartType.LIST_INT,
    DartType.LIST_NUM,
    DartType.LIST_STRING,
  };

  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.
  static const Map<DartType, Set<DartType>> _interfaceRels = {
    DartType.LIST_INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.LIST_INT,
    },
    DartType._TYPEDINTLIST: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
    },
    DartType.OBJECT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.INT32X4LIST,
      DartType.INT32X4,
      DartType.BOOL,
      DartType.DURATION,
      DartType.INT,
      DartType.NUM,
      DartType.STRING,
      DartType.LIST_INT,
      DartType.LIST_NUM,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_NUM,
      DartType.SET_STRING,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_BOOL_INT,
      DartType.MAP_BOOL_NUM,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_BOOL,
      DartType.MAP_INT_INT,
      DartType.MAP_INT_STRING,
      DartType.MAP_NUM_BOOL,
      DartType.MAP_NUM_INT,
      DartType.MAP_NUM_NUM,
      DartType.MAP_NUM_STRING,
      DartType.MAP_STRING_BOOL,
      DartType.MAP_STRING_INT,
      DartType.MAP_STRING_NUM,
    },
    DartType.TYPEDDATA: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
      DartType.INT32X4LIST,
    },
    DartType.ITERABLE_INT: {
      DartType.INT8LIST,
      DartType.UINT8LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.INT16LIST,
      DartType.UINT16LIST,
      DartType.INT32LIST,
      DartType.UINT32LIST,
      DartType.INT64LIST,
      DartType.UINT64LIST,
    },
    DartType.LIST_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.ITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.NUM: {
      DartType.INT,
      DartType.NUM,
    },
    DartType.COMPARABLE_NUM: {
      DartType.INT,
      DartType.NUM,
    },
    DartType.COMPARABLE_DURATION: {
      DartType.DURATION,
    },
    DartType.COMPARABLE_STRING: {
      DartType.STRING,
    },
    DartType.PATTERN: {
      DartType.STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_E: {
      DartType.LIST_INT,
      DartType.LIST_NUM,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_NUM,
      DartType.SET_STRING,
    },
    DartType.ITERABLE_E: {
      DartType.LIST_INT,
      DartType.LIST_NUM,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_NUM,
      DartType.SET_STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_NUM: {
      DartType.LIST_NUM,
    },
    DartType.EFFICIENTLENGTHITERABLE_STRING: {
      DartType.LIST_STRING,
    },
  };

  // Map type to a list of constructors names with a list of constructor
  // parameter types.
  static const Map<DartType, Map<String, List<DartType>>> _constructors = {
    DartType.INT8LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT8LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT8CLAMPEDLIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT16LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT16LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT32LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT32LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT64LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.UINT64LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
      ],
    },
    DartType.INT32X4LIST: {
      '': [
        DartType.INT,
      ],
    },
    DartType.INT32X4: {
      '': [
        DartType.INT,
        DartType.INT,
        DartType.INT,
        DartType.INT,
      ],
    },
    DartType.DURATION: {
      '': [],
    },
  };

  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.
  static const Map<DartType, Map<String, Set<List<DartType>>>> _binOps = {
    DartType.LIST_INT: {
      '+': {
        [
          DartType.LIST_INT,
          DartType.LIST_INT,
        ],
      },
      '??': {
        [
          DartType.LIST_INT,
          DartType.LIST_INT,
        ],
      },
    },
    DartType.LIST_FLOAT32X4: {
      '??': {
        [
          DartType.LIST_FLOAT32X4,
          DartType.LIST_FLOAT32X4,
        ],
      },
    },
    DartType.LIST_INT32X4: {
      '+': {
        [
          DartType.INT32X4LIST,
          DartType.LIST_INT32X4,
        ],
      },
      '??': {
        [
          DartType.LIST_INT32X4,
          DartType.LIST_INT32X4,
        ],
      },
    },
    DartType.LIST_FLOAT64X2: {
      '??': {
        [
          DartType.LIST_FLOAT64X2,
          DartType.LIST_FLOAT64X2,
        ],
      },
    },
    DartType.INT32X4: {
      '|': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '&': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '^': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '+': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '-': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '??': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
    },
    DartType.BOOL: {
      '&': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '|': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '^': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '<': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '>': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '<=': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '>=': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '==': {
        [
          DartType.NUM,
          DartType.OBJECT,
        ],
        [
          DartType.STRING,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_INT,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_NUM,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_STRING,
          DartType.OBJECT,
        ],
      },
      '??': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '&&': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
      '||': {
        [
          DartType.BOOL,
          DartType.BOOL,
        ],
      },
    },
    DartType.INT: {
      '~/': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '&': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '|': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '^': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '<<': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '>>': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
      '??': {
        [
          DartType.INT,
          DartType.INT,
        ],
      },
    },
    DartType.DURATION: {
      '+': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
      '-': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
      '*': {
        [
          DartType.DURATION,
          DartType.NUM,
        ],
      },
      '~/': {
        [
          DartType.DURATION,
          DartType.INT,
        ],
      },
      '??': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
    },
    DartType.NUM: {
      '+': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '-': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '*': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '%': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
      '??': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
    },
    DartType.STRING: {
      '+': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
      '*': {
        [
          DartType.STRING,
          DartType.INT,
        ],
      },
      '??': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
    },
    DartType.LIST_NUM: {
      '+': {
        [
          DartType.LIST_NUM,
          DartType.LIST_NUM,
        ],
      },
      '??': {
        [
          DartType.LIST_NUM,
          DartType.LIST_NUM,
        ],
      },
    },
    DartType.LIST_STRING: {
      '+': {
        [
          DartType.LIST_STRING,
          DartType.LIST_STRING,
        ],
      },
      '??': {
        [
          DartType.LIST_STRING,
          DartType.LIST_STRING,
        ],
      },
    },
  };

  // Map type to a list of available unary operators.
  static const Map<DartType, Set<String>> _uniOps = {
    DartType.DURATION: {'-'},
    DartType.INT: {'~', '-'},
    DartType.NUM: {'-'},
    DartType.BOOL: {'!'},
  };

  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.
  static const Map<DartType, Map<String, Set<DartType>>> _assignOps = {
    DartType.INT8LIST: {
      '=': {
        DartType.INT8LIST,
      },
      '??=': {
        DartType.INT8LIST,
      },
    },
    DartType.UINT8LIST: {
      '=': {
        DartType.UINT8LIST,
      },
      '??=': {
        DartType.UINT8LIST,
      },
    },
    DartType.LIST_INT: {
      '+=': {
        DartType.LIST_INT,
      },
      '=': {
        DartType.LIST_INT,
      },
      '??=': {
        DartType.LIST_INT,
      },
    },
    DartType.UINT8CLAMPEDLIST: {
      '=': {
        DartType.UINT8CLAMPEDLIST,
      },
      '??=': {
        DartType.UINT8CLAMPEDLIST,
      },
    },
    DartType.INT16LIST: {
      '=': {
        DartType.INT16LIST,
      },
      '??=': {
        DartType.INT16LIST,
      },
    },
    DartType.UINT16LIST: {
      '=': {
        DartType.UINT16LIST,
      },
      '??=': {
        DartType.UINT16LIST,
      },
    },
    DartType.INT32LIST: {
      '=': {
        DartType.INT32LIST,
      },
      '??=': {
        DartType.INT32LIST,
      },
    },
    DartType.UINT32LIST: {
      '=': {
        DartType.UINT32LIST,
      },
      '??=': {
        DartType.UINT32LIST,
      },
    },
    DartType.INT64LIST: {
      '=': {
        DartType.INT64LIST,
      },
      '??=': {
        DartType.INT64LIST,
      },
    },
    DartType.UINT64LIST: {
      '=': {
        DartType.UINT64LIST,
      },
      '??=': {
        DartType.UINT64LIST,
      },
    },
    DartType.LIST_FLOAT32X4: {
      '+=': {
        DartType.LIST_FLOAT32X4,
      },
    },
    DartType.INT32X4LIST: {
      '=': {
        DartType.INT32X4LIST,
      },
      '??=': {
        DartType.INT32X4LIST,
      },
    },
    DartType.LIST_INT32X4: {
      '+=': {
        DartType.LIST_INT32X4,
      },
    },
    DartType.LIST_FLOAT64X2: {
      '+=': {
        DartType.LIST_FLOAT64X2,
      },
    },
    DartType.INT32X4: {
      '=': {
        DartType.INT32X4,
      },
      '??=': {
        DartType.INT32X4,
      },
      '|=': {
        DartType.INT32X4,
      },
      '&=': {
        DartType.INT32X4,
      },
      '^=': {
        DartType.INT32X4,
      },
      '+=': {
        DartType.INT32X4,
      },
      '-=': {
        DartType.INT32X4,
      },
    },
    DartType.BOOL: {
      '=': {
        DartType.BOOL,
      },
      '??=': {
        DartType.BOOL,
      },
    },
    DartType.INT: {
      '~/=': {
        DartType.NUM,
      },
      '=': {
        DartType.INT,
      },
      '??=': {
        DartType.INT,
      },
      '&=': {
        DartType.INT,
      },
      '|=': {
        DartType.INT,
      },
      '^=': {
        DartType.INT,
      },
      '<<=': {
        DartType.INT,
      },
      '>>=': {
        DartType.INT,
      },
    },
    DartType.DURATION: {
      '=': {
        DartType.DURATION,
      },
      '??=': {
        DartType.DURATION,
      },
      '+=': {
        DartType.DURATION,
      },
      '-=': {
        DartType.DURATION,
      },
      '*=': {
        DartType.NUM,
      },
      '~/=': {
        DartType.INT,
      },
    },
    DartType.NUM: {
      '=': {
        DartType.NUM,
      },
      '??=': {
        DartType.NUM,
      },
      '+=': {
        DartType.NUM,
      },
      '-=': {
        DartType.NUM,
      },
      '*=': {
        DartType.NUM,
      },
      '%=': {
        DartType.NUM,
      },
    },
    DartType.STRING: {
      '=': {
        DartType.STRING,
      },
      '??=': {
        DartType.STRING,
      },
      '+=': {
        DartType.STRING,
      },
      '*=': {
        DartType.INT,
      },
    },
    DartType.LIST_NUM: {
      '=': {
        DartType.LIST_NUM,
      },
      '??=': {
        DartType.LIST_NUM,
      },
      '+=': {
        DartType.LIST_NUM,
      },
    },
    DartType.LIST_STRING: {
      '=': {
        DartType.LIST_STRING,
      },
      '??=': {
        DartType.LIST_STRING,
      },
      '+=': {
        DartType.LIST_STRING,
      },
    },
    DartType.SET_BOOL: {
      '=': {
        DartType.SET_BOOL,
      },
      '??=': {
        DartType.SET_BOOL,
      },
    },
    DartType.SET_INT: {
      '=': {
        DartType.SET_INT,
      },
      '??=': {
        DartType.SET_INT,
      },
    },
    DartType.SET_NUM: {
      '=': {
        DartType.SET_NUM,
      },
      '??=': {
        DartType.SET_NUM,
      },
    },
    DartType.SET_STRING: {
      '=': {
        DartType.SET_STRING,
      },
      '??=': {
        DartType.SET_STRING,
      },
    },
    DartType.MAP_BOOL_BOOL: {
      '=': {
        DartType.MAP_BOOL_BOOL,
      },
      '??=': {
        DartType.MAP_BOOL_BOOL,
      },
    },
    DartType.MAP_BOOL_INT: {
      '=': {
        DartType.MAP_BOOL_INT,
      },
      '??=': {
        DartType.MAP_BOOL_INT,
      },
    },
    DartType.MAP_BOOL_NUM: {
      '=': {
        DartType.MAP_BOOL_NUM,
      },
      '??=': {
        DartType.MAP_BOOL_NUM,
      },
    },
    DartType.MAP_BOOL_STRING: {
      '=': {
        DartType.MAP_BOOL_STRING,
      },
      '??=': {
        DartType.MAP_BOOL_STRING,
      },
    },
    DartType.MAP_INT_BOOL: {
      '=': {
        DartType.MAP_INT_BOOL,
      },
      '??=': {
        DartType.MAP_INT_BOOL,
      },
    },
    DartType.MAP_INT_INT: {
      '=': {
        DartType.MAP_INT_INT,
      },
      '??=': {
        DartType.MAP_INT_INT,
      },
    },
    DartType.MAP_INT_STRING: {
      '=': {
        DartType.MAP_INT_STRING,
      },
      '??=': {
        DartType.MAP_INT_STRING,
      },
    },
    DartType.MAP_NUM_BOOL: {
      '=': {
        DartType.MAP_NUM_BOOL,
      },
      '??=': {
        DartType.MAP_NUM_BOOL,
      },
    },
    DartType.MAP_NUM_INT: {
      '=': {
        DartType.MAP_NUM_INT,
      },
      '??=': {
        DartType.MAP_NUM_INT,
      },
    },
    DartType.MAP_NUM_NUM: {
      '=': {
        DartType.MAP_NUM_NUM,
      },
      '??=': {
        DartType.MAP_NUM_NUM,
      },
    },
    DartType.MAP_NUM_STRING: {
      '=': {
        DartType.MAP_NUM_STRING,
      },
      '??=': {
        DartType.MAP_NUM_STRING,
      },
    },
    DartType.MAP_STRING_BOOL: {
      '=': {
        DartType.MAP_STRING_BOOL,
      },
      '??=': {
        DartType.MAP_STRING_BOOL,
      },
    },
    DartType.MAP_STRING_INT: {
      '=': {
        DartType.MAP_STRING_INT,
      },
      '??=': {
        DartType.MAP_STRING_INT,
      },
    },
    DartType.MAP_STRING_NUM: {
      '=': {
        DartType.MAP_STRING_NUM,
      },
      '??=': {
        DartType.MAP_STRING_NUM,
      },
    },
  };
}
