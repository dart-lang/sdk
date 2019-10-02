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
  static const LIST_BOOL = const DartType._withName("List<bool>");
  static const LIST_DOUBLE = const DartType._withName("List<double>");
  static const LIST_INT = const DartType._withName("List<int>");
  static const LIST_STRING = const DartType._withName("List<String>");
  static const SET_BOOL = const DartType._withName("Set<bool>");
  static const SET_DOUBLE = const DartType._withName("Set<double>");
  static const SET_INT = const DartType._withName("Set<int>");
  static const SET_STRING = const DartType._withName("Set<String>");
  static const MAP_BOOL_BOOL = const DartType._withName("Map<bool, bool>");
  static const MAP_BOOL_DOUBLE = const DartType._withName("Map<bool, double>");
  static const MAP_BOOL_INT = const DartType._withName("Map<bool, int>");
  static const MAP_BOOL_STRING = const DartType._withName("Map<bool, String>");
  static const MAP_DOUBLE_BOOL = const DartType._withName("Map<double, bool>");
  static const MAP_DOUBLE_DOUBLE =
      const DartType._withName("Map<double, double>");
  static const MAP_DOUBLE_INT = const DartType._withName("Map<double, int>");
  static const MAP_DOUBLE_STRING =
      const DartType._withName("Map<double, String>");
  static const MAP_INT_BOOL = const DartType._withName("Map<int, bool>");
  static const MAP_INT_DOUBLE = const DartType._withName("Map<int, double>");
  static const MAP_INT_INT = const DartType._withName("Map<int, int>");
  static const MAP_INT_STRING = const DartType._withName("Map<int, String>");
  static const MAP_STRING_BOOL = const DartType._withName("Map<String, bool>");
  static const MAP_STRING_DOUBLE =
      const DartType._withName("Map<String, double>");
  static const MAP_STRING_INT = const DartType._withName("Map<String, int>");
  static const MAP_STRING_STRING =
      const DartType._withName("Map<String, String>");
  static const LIST_MAP_STRING_INT =
      const DartType._withName("List<Map<String, int>>");
  static const SET_MAP_STRING_BOOL =
      const DartType._withName("Set<Map<String, bool>>");
  static const MAP_BOOL_MAP_INT_INT =
      const DartType._withName("Map<bool, Map<int, int>>");
  static const MAP_DOUBLE_MAP_INT_DOUBLE =
      const DartType._withName("Map<double, Map<int, double>>");
  static const MAP_INT_MAP_DOUBLE_STRING =
      const DartType._withName("Map<int, Map<double, String>>");
  static const MAP_STRING_MAP_DOUBLE_DOUBLE =
      const DartType._withName("Map<String, Map<double, double>>");
  static const MAP_LIST_BOOL_MAP_BOOL_STRING =
      const DartType._withName("Map<List<bool>, Map<bool, String>>");
  static const MAP_LIST_DOUBLE_MAP_BOOL_INT =
      const DartType._withName("Map<List<double>, Map<bool, int>>");
  static const MAP_LIST_INT_MAP_BOOL_BOOL =
      const DartType._withName("Map<List<int>, Map<bool, bool>>");
  static const MAP_LIST_STRING_SET_INT =
      const DartType._withName("Map<List<String>, Set<int>>");
  static const MAP_SET_BOOL_SET_BOOL =
      const DartType._withName("Map<Set<bool>, Set<bool>>");
  static const MAP_SET_DOUBLE_LIST_STRING =
      const DartType._withName("Map<Set<double>, List<String>>");
  static const MAP_SET_INT_LIST_DOUBLE =
      const DartType._withName("Map<Set<int>, List<double>>");
  static const MAP_SET_STRING_STRING =
      const DartType._withName("Map<Set<String>, String>");
  static const MAP_MAP_BOOL_BOOL_DOUBLE =
      const DartType._withName("Map<Map<bool, bool>, double>");
  static const MAP_MAP_BOOL_DOUBLE_BOOL =
      const DartType._withName("Map<Map<bool, double>, bool>");
  static const MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT =
      const DartType._withName("Map<Map<bool, double>, Map<String, int>>");
  static const MAP_MAP_BOOL_INT_MAP_STRING_BOOL =
      const DartType._withName("Map<Map<bool, int>, Map<String, bool>>");
  static const MAP_MAP_BOOL_STRING_MAP_INT_INT =
      const DartType._withName("Map<Map<bool, String>, Map<int, int>>");
  static const MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE =
      const DartType._withName("Map<Map<double, bool>, Map<int, double>>");
  static const MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING =
      const DartType._withName("Map<Map<double, double>, Map<double, String>>");
  static const MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE =
      const DartType._withName("Map<Map<double, int>, Map<double, double>>");
  static const MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING =
      const DartType._withName("Map<Map<double, String>, Map<bool, String>>");
  static const MAP_MAP_INT_BOOL_MAP_BOOL_INT =
      const DartType._withName("Map<Map<int, bool>, Map<bool, int>>");
  static const MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL =
      const DartType._withName("Map<Map<int, double>, Map<bool, bool>>");
  static const MAP_MAP_INT_INT_SET_INT =
      const DartType._withName("Map<Map<int, int>, Set<int>>");
  static const MAP_MAP_INT_STRING_SET_BOOL =
      const DartType._withName("Map<Map<int, String>, Set<bool>>");
  static const MAP_MAP_STRING_BOOL_LIST_STRING =
      const DartType._withName("Map<Map<String, bool>, List<String>>");
  static const MAP_MAP_STRING_DOUBLE_LIST_DOUBLE =
      const DartType._withName("Map<Map<String, double>, List<double>>");
  static const MAP_MAP_STRING_INT_STRING =
      const DartType._withName("Map<Map<String, int>, String>");
  static const MAP_MAP_STRING_STRING_DOUBLE =
      const DartType._withName("Map<Map<String, String>, double>");

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
  static const EFFICIENTLENGTHITERABLE_BOOL =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_BOOL");
  static const EFFICIENTLENGTHITERABLE_E =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_E");
  static const ITERABLE_E = const DartType._withName("__ITERABLE_E");
  static const EFFICIENTLENGTHITERABLE_STRING =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_STRING");
  static const EFFICIENTLENGTHITERABLE_MAP_STRING_INT =
      const DartType._withName("__EFFICIENTLENGTHITERABLE_MAP_STRING_INT");

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
    LIST_BOOL,
    LIST_DOUBLE,
    LIST_INT,
    LIST_STRING,
    SET_BOOL,
    SET_DOUBLE,
    SET_INT,
    SET_STRING,
    MAP_BOOL_BOOL,
    MAP_BOOL_DOUBLE,
    MAP_BOOL_INT,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_STRING,
    LIST_MAP_STRING_INT,
    SET_MAP_STRING_BOOL,
    MAP_BOOL_MAP_INT_INT,
    MAP_DOUBLE_MAP_INT_DOUBLE,
    MAP_INT_MAP_DOUBLE_STRING,
    MAP_STRING_MAP_DOUBLE_DOUBLE,
    MAP_LIST_BOOL_MAP_BOOL_STRING,
    MAP_LIST_DOUBLE_MAP_BOOL_INT,
    MAP_LIST_INT_MAP_BOOL_BOOL,
    MAP_LIST_STRING_SET_INT,
    MAP_SET_BOOL_SET_BOOL,
    MAP_SET_DOUBLE_LIST_STRING,
    MAP_SET_INT_LIST_DOUBLE,
    MAP_SET_STRING_STRING,
    MAP_MAP_BOOL_BOOL_DOUBLE,
    MAP_MAP_BOOL_DOUBLE_BOOL,
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
    MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    MAP_MAP_BOOL_STRING_MAP_INT_INT,
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
    MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_LIST_STRING,
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
    MAP_MAP_STRING_INT_STRING,
    MAP_MAP_STRING_STRING_DOUBLE,
  };

  // All List<E> types: LIST_INT, LIST_STRING, etc.
  static const Set<DartType> _listTypes = {
    FLOAT32LIST,
    FLOAT32X4LIST,
    FLOAT64LIST,
    FLOAT64X2LIST,
    INT16LIST,
    INT32LIST,
    INT32X4LIST,
    INT64LIST,
    INT8LIST,
    LIST_BOOL,
    LIST_DOUBLE,
    LIST_INT,
    LIST_MAP_STRING_INT,
    LIST_STRING,
    UINT16LIST,
    UINT32LIST,
    UINT64LIST,
    UINT8CLAMPEDLIST,
    UINT8LIST,
  };

  // All Set types: SET_INT, SET_STRING, etc.
  static const Set<DartType> _setTypes = {
    SET_BOOL,
    SET_DOUBLE,
    SET_INT,
    SET_MAP_STRING_BOOL,
    SET_STRING,
  };

  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
  static const Set<DartType> _mapTypes = {
    MAP_BOOL_BOOL,
    MAP_BOOL_DOUBLE,
    MAP_BOOL_INT,
    MAP_BOOL_MAP_INT_INT,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_MAP_INT_DOUBLE,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_MAP_DOUBLE_STRING,
    MAP_INT_STRING,
    MAP_LIST_BOOL_MAP_BOOL_STRING,
    MAP_LIST_DOUBLE_MAP_BOOL_INT,
    MAP_LIST_INT_MAP_BOOL_BOOL,
    MAP_LIST_STRING_SET_INT,
    MAP_MAP_BOOL_BOOL_DOUBLE,
    MAP_MAP_BOOL_DOUBLE_BOOL,
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
    MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    MAP_MAP_BOOL_STRING_MAP_INT_INT,
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
    MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_LIST_STRING,
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
    MAP_MAP_STRING_INT_STRING,
    MAP_MAP_STRING_STRING_DOUBLE,
    MAP_SET_BOOL_SET_BOOL,
    MAP_SET_DOUBLE_LIST_STRING,
    MAP_SET_INT_LIST_DOUBLE,
    MAP_SET_STRING_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_MAP_DOUBLE_DOUBLE,
    MAP_STRING_STRING,
  };

  // All collection types: list, map and set types.
  static const Set<DartType> _collectionTypes = {
    FLOAT32LIST,
    FLOAT32X4LIST,
    FLOAT64LIST,
    FLOAT64X2LIST,
    INT16LIST,
    INT32LIST,
    INT32X4LIST,
    INT64LIST,
    INT8LIST,
    LIST_BOOL,
    LIST_DOUBLE,
    LIST_INT,
    LIST_MAP_STRING_INT,
    LIST_STRING,
    MAP_BOOL_BOOL,
    MAP_BOOL_DOUBLE,
    MAP_BOOL_INT,
    MAP_BOOL_MAP_INT_INT,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_MAP_INT_DOUBLE,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_MAP_DOUBLE_STRING,
    MAP_INT_STRING,
    MAP_LIST_BOOL_MAP_BOOL_STRING,
    MAP_LIST_DOUBLE_MAP_BOOL_INT,
    MAP_LIST_INT_MAP_BOOL_BOOL,
    MAP_LIST_STRING_SET_INT,
    MAP_MAP_BOOL_BOOL_DOUBLE,
    MAP_MAP_BOOL_DOUBLE_BOOL,
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
    MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    MAP_MAP_BOOL_STRING_MAP_INT_INT,
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
    MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_LIST_STRING,
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
    MAP_MAP_STRING_INT_STRING,
    MAP_MAP_STRING_STRING_DOUBLE,
    MAP_SET_BOOL_SET_BOOL,
    MAP_SET_DOUBLE_LIST_STRING,
    MAP_SET_INT_LIST_DOUBLE,
    MAP_SET_STRING_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_MAP_DOUBLE_DOUBLE,
    MAP_STRING_STRING,
    SET_BOOL,
    SET_DOUBLE,
    SET_INT,
    SET_MAP_STRING_BOOL,
    SET_STRING,
    UINT16LIST,
    UINT32LIST,
    UINT64LIST,
    UINT8CLAMPEDLIST,
    UINT8LIST,
  };

  // All growable types: list, map, set and string types.
  static const Set<DartType> _growableTypes = {
    FLOAT32LIST,
    FLOAT32X4LIST,
    FLOAT64LIST,
    FLOAT64X2LIST,
    INT16LIST,
    INT32LIST,
    INT32X4LIST,
    INT64LIST,
    INT8LIST,
    LIST_BOOL,
    LIST_DOUBLE,
    LIST_INT,
    LIST_MAP_STRING_INT,
    LIST_STRING,
    MAP_BOOL_BOOL,
    MAP_BOOL_DOUBLE,
    MAP_BOOL_INT,
    MAP_BOOL_MAP_INT_INT,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_MAP_INT_DOUBLE,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_MAP_DOUBLE_STRING,
    MAP_INT_STRING,
    MAP_LIST_BOOL_MAP_BOOL_STRING,
    MAP_LIST_DOUBLE_MAP_BOOL_INT,
    MAP_LIST_INT_MAP_BOOL_BOOL,
    MAP_LIST_STRING_SET_INT,
    MAP_MAP_BOOL_BOOL_DOUBLE,
    MAP_MAP_BOOL_DOUBLE_BOOL,
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
    MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    MAP_MAP_BOOL_STRING_MAP_INT_INT,
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
    MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_LIST_STRING,
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
    MAP_MAP_STRING_INT_STRING,
    MAP_MAP_STRING_STRING_DOUBLE,
    MAP_SET_BOOL_SET_BOOL,
    MAP_SET_DOUBLE_LIST_STRING,
    MAP_SET_INT_LIST_DOUBLE,
    MAP_SET_STRING_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_MAP_DOUBLE_DOUBLE,
    MAP_STRING_STRING,
    SET_BOOL,
    SET_DOUBLE,
    SET_INT,
    SET_MAP_STRING_BOOL,
    SET_STRING,
    STRING,
    UINT16LIST,
    UINT32LIST,
    UINT64LIST,
    UINT8CLAMPEDLIST,
    UINT8LIST,
  };

  // All floating point types: DOUBLE, SET_DOUBLE, MAP_X_DOUBLE, etc.
  static const Set<DartType> _fpTypes = {
    DOUBLE,
    FLOAT32LIST,
    FLOAT32X4,
    FLOAT32X4LIST,
    FLOAT64LIST,
    FLOAT64X2,
    FLOAT64X2LIST,
    LIST_DOUBLE,
    MAP_BOOL_DOUBLE,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_MAP_INT_DOUBLE,
    MAP_DOUBLE_STRING,
    MAP_INT_DOUBLE,
    MAP_INT_MAP_DOUBLE_STRING,
    MAP_LIST_DOUBLE_MAP_BOOL_INT,
    MAP_MAP_BOOL_BOOL_DOUBLE,
    MAP_MAP_BOOL_DOUBLE_BOOL,
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
    MAP_MAP_STRING_STRING_DOUBLE,
    MAP_SET_DOUBLE_LIST_STRING,
    MAP_SET_INT_LIST_DOUBLE,
    MAP_STRING_DOUBLE,
    MAP_STRING_MAP_DOUBLE_DOUBLE,
    SET_DOUBLE,
  };

  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.
  static const Set<DartType> _indexableTypes = {
    FLOAT32LIST,
    FLOAT32X4LIST,
    FLOAT64LIST,
    FLOAT64X2LIST,
    INT16LIST,
    INT32LIST,
    INT32X4LIST,
    INT64LIST,
    INT8LIST,
    LIST_BOOL,
    LIST_DOUBLE,
    LIST_INT,
    LIST_MAP_STRING_INT,
    LIST_STRING,
    MAP_BOOL_BOOL,
    MAP_BOOL_DOUBLE,
    MAP_BOOL_INT,
    MAP_BOOL_MAP_INT_INT,
    MAP_BOOL_STRING,
    MAP_DOUBLE_BOOL,
    MAP_DOUBLE_DOUBLE,
    MAP_DOUBLE_INT,
    MAP_DOUBLE_MAP_INT_DOUBLE,
    MAP_DOUBLE_STRING,
    MAP_INT_BOOL,
    MAP_INT_DOUBLE,
    MAP_INT_INT,
    MAP_INT_MAP_DOUBLE_STRING,
    MAP_INT_STRING,
    MAP_LIST_BOOL_MAP_BOOL_STRING,
    MAP_LIST_DOUBLE_MAP_BOOL_INT,
    MAP_LIST_INT_MAP_BOOL_BOOL,
    MAP_LIST_STRING_SET_INT,
    MAP_MAP_BOOL_BOOL_DOUBLE,
    MAP_MAP_BOOL_DOUBLE_BOOL,
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
    MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    MAP_MAP_BOOL_STRING_MAP_INT_INT,
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
    MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_LIST_STRING,
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
    MAP_MAP_STRING_INT_STRING,
    MAP_MAP_STRING_STRING_DOUBLE,
    MAP_SET_BOOL_SET_BOOL,
    MAP_SET_DOUBLE_LIST_STRING,
    MAP_SET_INT_LIST_DOUBLE,
    MAP_SET_STRING_STRING,
    MAP_STRING_BOOL,
    MAP_STRING_DOUBLE,
    MAP_STRING_INT,
    MAP_STRING_MAP_DOUBLE_DOUBLE,
    MAP_STRING_STRING,
    UINT16LIST,
    UINT32LIST,
    UINT64LIST,
    UINT8CLAMPEDLIST,
    UINT8LIST,
  };

  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.
  static const Map<DartType, DartType> _subscriptsTo = {
    DURATION: DURATION,
    FLOAT32LIST: DOUBLE,
    FLOAT32X4LIST: FLOAT32X4,
    FLOAT64LIST: DOUBLE,
    FLOAT64X2LIST: FLOAT64X2,
    INT16LIST: INT,
    INT32LIST: INT,
    INT32X4LIST: INT32X4,
    INT64LIST: INT,
    INT8LIST: INT,
    LIST_BOOL: BOOL,
    LIST_DOUBLE: DOUBLE,
    LIST_INT: INT,
    LIST_MAP_STRING_INT: MAP_STRING_INT,
    LIST_STRING: STRING,
    MAP_BOOL_BOOL: BOOL,
    MAP_BOOL_DOUBLE: DOUBLE,
    MAP_BOOL_INT: INT,
    MAP_BOOL_MAP_INT_INT: MAP_INT_INT,
    MAP_BOOL_STRING: STRING,
    MAP_DOUBLE_BOOL: BOOL,
    MAP_DOUBLE_DOUBLE: DOUBLE,
    MAP_DOUBLE_INT: INT,
    MAP_DOUBLE_MAP_INT_DOUBLE: MAP_INT_DOUBLE,
    MAP_DOUBLE_STRING: STRING,
    MAP_INT_BOOL: BOOL,
    MAP_INT_DOUBLE: DOUBLE,
    MAP_INT_INT: INT,
    MAP_INT_MAP_DOUBLE_STRING: MAP_DOUBLE_STRING,
    MAP_INT_STRING: STRING,
    MAP_LIST_BOOL_MAP_BOOL_STRING: MAP_BOOL_STRING,
    MAP_LIST_DOUBLE_MAP_BOOL_INT: MAP_BOOL_INT,
    MAP_LIST_INT_MAP_BOOL_BOOL: MAP_BOOL_BOOL,
    MAP_LIST_STRING_SET_INT: SET_INT,
    MAP_MAP_BOOL_BOOL_DOUBLE: DOUBLE,
    MAP_MAP_BOOL_DOUBLE_BOOL: BOOL,
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT: MAP_STRING_INT,
    MAP_MAP_BOOL_INT_MAP_STRING_BOOL: MAP_STRING_BOOL,
    MAP_MAP_BOOL_STRING_MAP_INT_INT: MAP_INT_INT,
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE: MAP_INT_DOUBLE,
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING: MAP_DOUBLE_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE: MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING: MAP_BOOL_STRING,
    MAP_MAP_INT_BOOL_MAP_BOOL_INT: MAP_BOOL_INT,
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL: MAP_BOOL_BOOL,
    MAP_MAP_INT_INT_SET_INT: SET_INT,
    MAP_MAP_INT_STRING_SET_BOOL: SET_BOOL,
    MAP_MAP_STRING_BOOL_LIST_STRING: LIST_STRING,
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE: LIST_DOUBLE,
    MAP_MAP_STRING_INT_STRING: STRING,
    MAP_MAP_STRING_STRING_DOUBLE: DOUBLE,
    MAP_SET_BOOL_SET_BOOL: SET_BOOL,
    MAP_SET_DOUBLE_LIST_STRING: LIST_STRING,
    MAP_SET_INT_LIST_DOUBLE: LIST_DOUBLE,
    MAP_SET_STRING_STRING: STRING,
    MAP_STRING_BOOL: BOOL,
    MAP_STRING_DOUBLE: DOUBLE,
    MAP_STRING_INT: INT,
    MAP_STRING_MAP_DOUBLE_DOUBLE: MAP_DOUBLE_DOUBLE,
    MAP_STRING_STRING: STRING,
    NUM: NUM,
    SET_BOOL: BOOL,
    SET_DOUBLE: DOUBLE,
    SET_INT: INT,
    SET_MAP_STRING_BOOL: MAP_STRING_BOOL,
    SET_STRING: STRING,
    STRING: STRING,
    UINT16LIST: INT,
    UINT32LIST: INT,
    UINT64LIST: INT,
    UINT8CLAMPEDLIST: INT,
    UINT8LIST: INT,
  };

  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.
  static const Map<DartType, DartType> _indexedBy = {
    FLOAT32LIST: INT,
    FLOAT32X4LIST: INT,
    FLOAT64LIST: INT,
    FLOAT64X2LIST: INT,
    INT16LIST: INT,
    INT32LIST: INT,
    INT32X4LIST: INT,
    INT64LIST: INT,
    INT8LIST: INT,
    LIST_BOOL: INT,
    LIST_DOUBLE: INT,
    LIST_INT: INT,
    LIST_MAP_STRING_INT: INT,
    LIST_STRING: INT,
    MAP_BOOL_BOOL: BOOL,
    MAP_BOOL_DOUBLE: BOOL,
    MAP_BOOL_INT: BOOL,
    MAP_BOOL_MAP_INT_INT: BOOL,
    MAP_BOOL_STRING: BOOL,
    MAP_DOUBLE_BOOL: DOUBLE,
    MAP_DOUBLE_DOUBLE: DOUBLE,
    MAP_DOUBLE_INT: DOUBLE,
    MAP_DOUBLE_MAP_INT_DOUBLE: DOUBLE,
    MAP_DOUBLE_STRING: DOUBLE,
    MAP_INT_BOOL: INT,
    MAP_INT_DOUBLE: INT,
    MAP_INT_INT: INT,
    MAP_INT_MAP_DOUBLE_STRING: INT,
    MAP_INT_STRING: INT,
    MAP_LIST_BOOL_MAP_BOOL_STRING: LIST_BOOL,
    MAP_LIST_DOUBLE_MAP_BOOL_INT: LIST_DOUBLE,
    MAP_LIST_INT_MAP_BOOL_BOOL: LIST_INT,
    MAP_LIST_STRING_SET_INT: LIST_STRING,
    MAP_MAP_BOOL_BOOL_DOUBLE: MAP_BOOL_BOOL,
    MAP_MAP_BOOL_DOUBLE_BOOL: MAP_BOOL_DOUBLE,
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT: MAP_BOOL_DOUBLE,
    MAP_MAP_BOOL_INT_MAP_STRING_BOOL: MAP_BOOL_INT,
    MAP_MAP_BOOL_STRING_MAP_INT_INT: MAP_BOOL_STRING,
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE: MAP_DOUBLE_BOOL,
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING: MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE: MAP_DOUBLE_INT,
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING: MAP_DOUBLE_STRING,
    MAP_MAP_INT_BOOL_MAP_BOOL_INT: MAP_INT_BOOL,
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL: MAP_INT_DOUBLE,
    MAP_MAP_INT_INT_SET_INT: MAP_INT_INT,
    MAP_MAP_INT_STRING_SET_BOOL: MAP_INT_STRING,
    MAP_MAP_STRING_BOOL_LIST_STRING: MAP_STRING_BOOL,
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE: MAP_STRING_DOUBLE,
    MAP_MAP_STRING_INT_STRING: MAP_STRING_INT,
    MAP_MAP_STRING_STRING_DOUBLE: MAP_STRING_STRING,
    MAP_SET_BOOL_SET_BOOL: SET_BOOL,
    MAP_SET_DOUBLE_LIST_STRING: SET_DOUBLE,
    MAP_SET_INT_LIST_DOUBLE: SET_INT,
    MAP_SET_STRING_STRING: SET_STRING,
    MAP_STRING_BOOL: STRING,
    MAP_STRING_DOUBLE: STRING,
    MAP_STRING_INT: STRING,
    MAP_STRING_MAP_DOUBLE_DOUBLE: STRING,
    MAP_STRING_STRING: STRING,
    UINT16LIST: INT,
    UINT32LIST: INT,
    UINT64LIST: INT,
    UINT8CLAMPEDLIST: INT,
    UINT8LIST: INT,
  };

  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>
  static const Map<DartType, Set<DartType>> _elementOf = {
    BOOL: {
      LIST_BOOL,
      MAP_BOOL_BOOL,
      MAP_DOUBLE_BOOL,
      MAP_INT_BOOL,
      MAP_MAP_BOOL_DOUBLE_BOOL,
      MAP_STRING_BOOL,
      SET_BOOL,
    },
    DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
      LIST_DOUBLE,
      MAP_BOOL_DOUBLE,
      MAP_DOUBLE_DOUBLE,
      MAP_INT_DOUBLE,
      MAP_MAP_BOOL_BOOL_DOUBLE,
      MAP_MAP_STRING_STRING_DOUBLE,
      MAP_STRING_DOUBLE,
      SET_DOUBLE,
    },
    DURATION: {
      DURATION,
    },
    FLOAT32X4: {
      FLOAT32X4LIST,
    },
    FLOAT64X2: {
      FLOAT64X2LIST,
    },
    INT: {
      INT16LIST,
      INT32LIST,
      INT64LIST,
      INT8LIST,
      LIST_INT,
      MAP_BOOL_INT,
      MAP_DOUBLE_INT,
      MAP_INT_INT,
      MAP_STRING_INT,
      SET_INT,
      UINT16LIST,
      UINT32LIST,
      UINT64LIST,
      UINT8CLAMPEDLIST,
      UINT8LIST,
    },
    INT32X4: {
      INT32X4LIST,
    },
    LIST_DOUBLE: {
      MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
      MAP_SET_INT_LIST_DOUBLE,
    },
    LIST_STRING: {
      MAP_MAP_STRING_BOOL_LIST_STRING,
      MAP_SET_DOUBLE_LIST_STRING,
    },
    MAP_BOOL_BOOL: {
      MAP_LIST_INT_MAP_BOOL_BOOL,
      MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
    },
    MAP_BOOL_INT: {
      MAP_LIST_DOUBLE_MAP_BOOL_INT,
      MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    },
    MAP_BOOL_STRING: {
      MAP_LIST_BOOL_MAP_BOOL_STRING,
      MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
    },
    MAP_DOUBLE_DOUBLE: {
      MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
      MAP_STRING_MAP_DOUBLE_DOUBLE,
    },
    MAP_DOUBLE_STRING: {
      MAP_INT_MAP_DOUBLE_STRING,
      MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
    },
    MAP_INT_DOUBLE: {
      MAP_DOUBLE_MAP_INT_DOUBLE,
      MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
    },
    MAP_INT_INT: {
      MAP_BOOL_MAP_INT_INT,
      MAP_MAP_BOOL_STRING_MAP_INT_INT,
    },
    MAP_STRING_BOOL: {
      MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
      SET_MAP_STRING_BOOL,
    },
    MAP_STRING_INT: {
      LIST_MAP_STRING_INT,
      MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
    },
    NUM: {
      NUM,
    },
    SET_BOOL: {
      MAP_MAP_INT_STRING_SET_BOOL,
      MAP_SET_BOOL_SET_BOOL,
    },
    SET_INT: {
      MAP_LIST_STRING_SET_INT,
      MAP_MAP_INT_INT_SET_INT,
    },
    STRING: {
      LIST_STRING,
      MAP_BOOL_STRING,
      MAP_DOUBLE_STRING,
      MAP_INT_STRING,
      MAP_MAP_STRING_INT_STRING,
      MAP_SET_STRING_STRING,
      MAP_STRING_STRING,
      SET_STRING,
      STRING,
    },
  };

  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.
  static const Map<DartType, Set<DartType>> _indexableElementOf = {
    BOOL: {
      LIST_BOOL,
      MAP_BOOL_BOOL,
      MAP_DOUBLE_BOOL,
      MAP_INT_BOOL,
      MAP_MAP_BOOL_DOUBLE_BOOL,
      MAP_STRING_BOOL,
    },
    DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
      LIST_DOUBLE,
      MAP_BOOL_DOUBLE,
      MAP_DOUBLE_DOUBLE,
      MAP_INT_DOUBLE,
      MAP_MAP_BOOL_BOOL_DOUBLE,
      MAP_MAP_STRING_STRING_DOUBLE,
      MAP_STRING_DOUBLE,
    },
    FLOAT32X4: {
      FLOAT32X4LIST,
    },
    FLOAT64X2: {
      FLOAT64X2LIST,
    },
    INT: {
      INT16LIST,
      INT32LIST,
      INT64LIST,
      INT8LIST,
      LIST_INT,
      MAP_BOOL_INT,
      MAP_DOUBLE_INT,
      MAP_INT_INT,
      MAP_STRING_INT,
      UINT16LIST,
      UINT32LIST,
      UINT64LIST,
      UINT8CLAMPEDLIST,
      UINT8LIST,
    },
    INT32X4: {
      INT32X4LIST,
    },
    LIST_DOUBLE: {
      MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
      MAP_SET_INT_LIST_DOUBLE,
    },
    LIST_STRING: {
      MAP_MAP_STRING_BOOL_LIST_STRING,
      MAP_SET_DOUBLE_LIST_STRING,
    },
    MAP_BOOL_BOOL: {
      MAP_LIST_INT_MAP_BOOL_BOOL,
      MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
    },
    MAP_BOOL_INT: {
      MAP_LIST_DOUBLE_MAP_BOOL_INT,
      MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    },
    MAP_BOOL_STRING: {
      MAP_LIST_BOOL_MAP_BOOL_STRING,
      MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
    },
    MAP_DOUBLE_DOUBLE: {
      MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
      MAP_STRING_MAP_DOUBLE_DOUBLE,
    },
    MAP_DOUBLE_STRING: {
      MAP_INT_MAP_DOUBLE_STRING,
      MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
    },
    MAP_INT_DOUBLE: {
      MAP_DOUBLE_MAP_INT_DOUBLE,
      MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
    },
    MAP_INT_INT: {
      MAP_BOOL_MAP_INT_INT,
      MAP_MAP_BOOL_STRING_MAP_INT_INT,
    },
    MAP_STRING_BOOL: {
      MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    },
    MAP_STRING_INT: {
      LIST_MAP_STRING_INT,
      MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
    },
    SET_BOOL: {
      MAP_MAP_INT_STRING_SET_BOOL,
      MAP_SET_BOOL_SET_BOOL,
    },
    SET_INT: {
      MAP_LIST_STRING_SET_INT,
      MAP_MAP_INT_INT_SET_INT,
    },
    STRING: {
      LIST_STRING,
      MAP_BOOL_STRING,
      MAP_DOUBLE_STRING,
      MAP_INT_STRING,
      MAP_MAP_STRING_INT_STRING,
      MAP_SET_STRING_STRING,
      MAP_STRING_STRING,
    },
  };

  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.
  static const Set<DartType> _iterableTypes1 = {
    FLOAT32LIST,
    FLOAT32X4LIST,
    FLOAT64LIST,
    FLOAT64X2LIST,
    INT16LIST,
    INT32LIST,
    INT32X4LIST,
    INT64LIST,
    INT8LIST,
    LIST_BOOL,
    LIST_DOUBLE,
    LIST_INT,
    LIST_MAP_STRING_INT,
    LIST_STRING,
    UINT16LIST,
    UINT32LIST,
    UINT64LIST,
    UINT8CLAMPEDLIST,
    UINT8LIST,
  };

  // Complex types: Collection types instantiated with nested argument
  // e.g Map<List<>, >.
  static const Set<DartType> _complexTypes = {
    LIST_MAP_STRING_INT,
    MAP_BOOL_MAP_INT_INT,
    MAP_DOUBLE_MAP_INT_DOUBLE,
    MAP_INT_MAP_DOUBLE_STRING,
    MAP_LIST_BOOL_MAP_BOOL_STRING,
    MAP_LIST_DOUBLE_MAP_BOOL_INT,
    MAP_LIST_INT_MAP_BOOL_BOOL,
    MAP_LIST_STRING_SET_INT,
    MAP_MAP_BOOL_BOOL_DOUBLE,
    MAP_MAP_BOOL_DOUBLE_BOOL,
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
    MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    MAP_MAP_BOOL_STRING_MAP_INT_INT,
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
    MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
    MAP_MAP_INT_INT_SET_INT,
    MAP_MAP_INT_STRING_SET_BOOL,
    MAP_MAP_STRING_BOOL_LIST_STRING,
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
    MAP_MAP_STRING_INT_STRING,
    MAP_MAP_STRING_STRING_DOUBLE,
    MAP_SET_BOOL_SET_BOOL,
    MAP_SET_DOUBLE_LIST_STRING,
    MAP_SET_INT_LIST_DOUBLE,
    MAP_SET_STRING_STRING,
    MAP_STRING_MAP_DOUBLE_DOUBLE,
    SET_MAP_STRING_BOOL,
  };

  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.
  static const Map<DartType, Set<DartType>> _interfaceRels = {
    COMPARABLE_DURATION: {
      DURATION,
    },
    COMPARABLE_NUM: {
      DOUBLE,
      INT,
      NUM,
    },
    COMPARABLE_STRING: {
      STRING,
    },
    EFFICIENTLENGTHITERABLE_BOOL: {
      LIST_BOOL,
    },
    EFFICIENTLENGTHITERABLE_DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
      LIST_DOUBLE,
    },
    EFFICIENTLENGTHITERABLE_E: {
      LIST_BOOL,
      LIST_DOUBLE,
      LIST_INT,
      LIST_MAP_STRING_INT,
      LIST_STRING,
      SET_BOOL,
      SET_DOUBLE,
      SET_INT,
      SET_MAP_STRING_BOOL,
      SET_STRING,
    },
    EFFICIENTLENGTHITERABLE_FLOAT32X4: {
      FLOAT32X4LIST,
    },
    EFFICIENTLENGTHITERABLE_FLOAT64X2: {
      FLOAT64X2LIST,
    },
    EFFICIENTLENGTHITERABLE_INT: {
      INT16LIST,
      INT32LIST,
      INT64LIST,
      INT8LIST,
      LIST_INT,
      UINT16LIST,
      UINT32LIST,
      UINT64LIST,
      UINT8CLAMPEDLIST,
      UINT8LIST,
    },
    EFFICIENTLENGTHITERABLE_INT32X4: {
      INT32X4LIST,
    },
    EFFICIENTLENGTHITERABLE_MAP_STRING_INT: {
      LIST_MAP_STRING_INT,
    },
    EFFICIENTLENGTHITERABLE_STRING: {
      LIST_STRING,
    },
    ITERABLE_DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
    },
    ITERABLE_E: {
      LIST_BOOL,
      LIST_DOUBLE,
      LIST_INT,
      LIST_MAP_STRING_INT,
      LIST_STRING,
      SET_BOOL,
      SET_DOUBLE,
      SET_INT,
      SET_MAP_STRING_BOOL,
      SET_STRING,
    },
    ITERABLE_FLOAT32X4: {
      FLOAT32X4LIST,
    },
    ITERABLE_FLOAT64X2: {
      FLOAT64X2LIST,
    },
    ITERABLE_INT: {
      INT16LIST,
      INT32LIST,
      INT64LIST,
      INT8LIST,
      UINT16LIST,
      UINT32LIST,
      UINT64LIST,
      UINT8CLAMPEDLIST,
      UINT8LIST,
    },
    ITERABLE_INT32X4: {
      INT32X4LIST,
    },
    LIST_DOUBLE: {
      FLOAT32LIST,
      FLOAT64LIST,
      LIST_DOUBLE,
    },
    LIST_FLOAT32X4: {
      FLOAT32X4LIST,
    },
    LIST_FLOAT64X2: {
      FLOAT64X2LIST,
    },
    LIST_INT: {
      INT16LIST,
      INT32LIST,
      INT64LIST,
      INT8LIST,
      LIST_INT,
      UINT16LIST,
      UINT32LIST,
      UINT64LIST,
      UINT8CLAMPEDLIST,
      UINT8LIST,
    },
    LIST_INT32X4: {
      INT32X4LIST,
    },
    NUM: {
      DOUBLE,
      INT,
      NUM,
    },
    OBJECT: {
      BOOL,
      DOUBLE,
      DURATION,
      FLOAT32LIST,
      FLOAT32X4,
      FLOAT32X4LIST,
      FLOAT64LIST,
      FLOAT64X2,
      FLOAT64X2LIST,
      INT,
      INT16LIST,
      INT32LIST,
      INT32X4,
      INT32X4LIST,
      INT64LIST,
      INT8LIST,
      LIST_BOOL,
      LIST_DOUBLE,
      LIST_INT,
      LIST_MAP_STRING_INT,
      LIST_STRING,
      MAP_BOOL_BOOL,
      MAP_BOOL_DOUBLE,
      MAP_BOOL_INT,
      MAP_BOOL_MAP_INT_INT,
      MAP_BOOL_STRING,
      MAP_DOUBLE_BOOL,
      MAP_DOUBLE_DOUBLE,
      MAP_DOUBLE_INT,
      MAP_DOUBLE_MAP_INT_DOUBLE,
      MAP_DOUBLE_STRING,
      MAP_INT_BOOL,
      MAP_INT_DOUBLE,
      MAP_INT_INT,
      MAP_INT_MAP_DOUBLE_STRING,
      MAP_INT_STRING,
      MAP_LIST_BOOL_MAP_BOOL_STRING,
      MAP_LIST_DOUBLE_MAP_BOOL_INT,
      MAP_LIST_INT_MAP_BOOL_BOOL,
      MAP_LIST_STRING_SET_INT,
      MAP_MAP_BOOL_BOOL_DOUBLE,
      MAP_MAP_BOOL_DOUBLE_BOOL,
      MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
      MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
      MAP_MAP_BOOL_STRING_MAP_INT_INT,
      MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
      MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
      MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
      MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
      MAP_MAP_INT_BOOL_MAP_BOOL_INT,
      MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
      MAP_MAP_INT_INT_SET_INT,
      MAP_MAP_INT_STRING_SET_BOOL,
      MAP_MAP_STRING_BOOL_LIST_STRING,
      MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
      MAP_MAP_STRING_INT_STRING,
      MAP_MAP_STRING_STRING_DOUBLE,
      MAP_SET_BOOL_SET_BOOL,
      MAP_SET_DOUBLE_LIST_STRING,
      MAP_SET_INT_LIST_DOUBLE,
      MAP_SET_STRING_STRING,
      MAP_STRING_BOOL,
      MAP_STRING_DOUBLE,
      MAP_STRING_INT,
      MAP_STRING_MAP_DOUBLE_DOUBLE,
      MAP_STRING_STRING,
      NUM,
      SET_BOOL,
      SET_DOUBLE,
      SET_INT,
      SET_MAP_STRING_BOOL,
      SET_STRING,
      STRING,
      UINT16LIST,
      UINT32LIST,
      UINT64LIST,
      UINT8CLAMPEDLIST,
      UINT8LIST,
    },
    PATTERN: {
      STRING,
    },
    TYPEDDATA: {
      FLOAT32LIST,
      FLOAT32X4LIST,
      FLOAT64LIST,
      FLOAT64X2LIST,
      INT16LIST,
      INT32LIST,
      INT32X4LIST,
      INT64LIST,
      INT8LIST,
      UINT16LIST,
      UINT32LIST,
      UINT64LIST,
      UINT8CLAMPEDLIST,
      UINT8LIST,
    },
    _TYPEDFLOATLIST: {
      FLOAT32LIST,
      FLOAT64LIST,
    },
    _TYPEDINTLIST: {
      INT16LIST,
      INT32LIST,
      INT64LIST,
      INT8LIST,
      UINT16LIST,
      UINT32LIST,
      UINT64LIST,
      UINT8CLAMPEDLIST,
      UINT8LIST,
    },
  };

  // Map type to a list of constructors names with a list of constructor
  // parameter types.
  static const Map<DartType, Map<String, List<DartType>>> _constructors = {
    DURATION: {
      '': [],
    },
    FLOAT32LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_DOUBLE,
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
    FLOAT32X4LIST: {
      '': [
        INT,
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
    FLOAT64X2LIST: {
      '': [
        INT,
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
    INT32LIST: {
      '': [
        INT,
      ],
      'fromList': [
        LIST_INT,
      ],
    },
    INT32X4: {
      '': [
        INT,
        INT,
        INT,
        INT,
      ],
    },
    INT32X4LIST: {
      '': [
        INT,
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
    INT8LIST: {
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
    UINT32LIST: {
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
    UINT8CLAMPEDLIST: {
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
  };

  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.
  static const Map<DartType, Map<String, Set<List<DartType>>>> _binOps = {
    BOOL: {
      '&': {
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
          LIST_BOOL,
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
          LIST_STRING,
          OBJECT,
        ],
        [
          LIST_MAP_STRING_INT,
          OBJECT,
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
      '??': {
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
      '|': {
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
      '%': {
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
    DURATION: {
      '*': {
        [
          DURATION,
          NUM,
        ],
      },
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
      '??': {
        [
          DURATION,
          DURATION,
        ],
      },
      '~/': {
        [
          DURATION,
          INT,
        ],
      },
    },
    FLOAT32X4: {
      '*': {
        [
          FLOAT32X4,
          FLOAT32X4,
        ],
      },
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
    FLOAT64X2: {
      '*': {
        [
          FLOAT64X2,
          FLOAT64X2,
        ],
      },
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
    INT: {
      '&': {
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
      '^': {
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
      '~/': {
        [
          NUM,
          NUM,
        ],
      },
    },
    INT32X4: {
      '&': {
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
      '^': {
        [
          INT32X4,
          INT32X4,
        ],
      },
      '|': {
        [
          INT32X4,
          INT32X4,
        ],
      },
    },
    LIST_BOOL: {
      '+': {
        [
          LIST_BOOL,
          LIST_BOOL,
        ],
      },
      '??': {
        [
          LIST_BOOL,
          LIST_BOOL,
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
    LIST_MAP_STRING_INT: {
      '+': {
        [
          LIST_MAP_STRING_INT,
          LIST_MAP_STRING_INT,
        ],
      },
      '??': {
        [
          LIST_MAP_STRING_INT,
          LIST_MAP_STRING_INT,
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
    NUM: {
      '%': {
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
      '??': {
        [
          NUM,
          NUM,
        ],
      },
    },
    STRING: {
      '*': {
        [
          STRING,
          INT,
        ],
      },
      '+': {
        [
          STRING,
          STRING,
        ],
      },
      '??': {
        [
          STRING,
          STRING,
        ],
      },
    },
  };

  // Map type to a list of available unary operators.
  static const Map<DartType, Set<String>> _uniOps = {
    BOOL: {'!'},
    DOUBLE: {'-'},
    DURATION: {'-'},
    FLOAT32X4: {'-'},
    FLOAT64X2: {'-'},
    INT: {'-', '~'},
    NUM: {'-'},
  };

  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.
  static const Map<DartType, Map<String, Set<DartType>>> _assignOps = {
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
    FLOAT32LIST: {
      '=': {
        FLOAT32LIST,
      },
      '??=': {
        FLOAT32LIST,
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
    FLOAT32X4LIST: {
      '=': {
        FLOAT32X4LIST,
      },
      '??=': {
        FLOAT32X4LIST,
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
    FLOAT64X2LIST: {
      '=': {
        FLOAT64X2LIST,
      },
      '??=': {
        FLOAT64X2LIST,
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
    INT16LIST: {
      '=': {
        INT16LIST,
      },
      '??=': {
        INT16LIST,
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
    INT32X4LIST: {
      '=': {
        INT32X4LIST,
      },
      '??=': {
        INT32X4LIST,
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
    INT8LIST: {
      '=': {
        INT8LIST,
      },
      '??=': {
        INT8LIST,
      },
    },
    LIST_BOOL: {
      '=': {
        LIST_BOOL,
      },
      '??=': {
        LIST_BOOL,
      },
      '+=': {
        LIST_BOOL,
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
    LIST_FLOAT32X4: {
      '+=': {
        LIST_FLOAT32X4,
      },
    },
    LIST_FLOAT64X2: {
      '+=': {
        LIST_FLOAT64X2,
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
    LIST_INT32X4: {
      '+=': {
        LIST_INT32X4,
      },
    },
    LIST_MAP_STRING_INT: {
      '=': {
        LIST_MAP_STRING_INT,
      },
      '??=': {
        LIST_MAP_STRING_INT,
      },
      '+=': {
        LIST_MAP_STRING_INT,
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
    MAP_BOOL_BOOL: {
      '=': {
        MAP_BOOL_BOOL,
      },
      '??=': {
        MAP_BOOL_BOOL,
      },
    },
    MAP_BOOL_DOUBLE: {
      '=': {
        MAP_BOOL_DOUBLE,
      },
      '??=': {
        MAP_BOOL_DOUBLE,
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
    MAP_BOOL_MAP_INT_INT: {
      '=': {
        MAP_BOOL_MAP_INT_INT,
      },
      '??=': {
        MAP_BOOL_MAP_INT_INT,
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
    MAP_DOUBLE_MAP_INT_DOUBLE: {
      '=': {
        MAP_DOUBLE_MAP_INT_DOUBLE,
      },
      '??=': {
        MAP_DOUBLE_MAP_INT_DOUBLE,
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
    MAP_INT_MAP_DOUBLE_STRING: {
      '=': {
        MAP_INT_MAP_DOUBLE_STRING,
      },
      '??=': {
        MAP_INT_MAP_DOUBLE_STRING,
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
    MAP_LIST_BOOL_MAP_BOOL_STRING: {
      '=': {
        MAP_LIST_BOOL_MAP_BOOL_STRING,
      },
      '??=': {
        MAP_LIST_BOOL_MAP_BOOL_STRING,
      },
    },
    MAP_LIST_DOUBLE_MAP_BOOL_INT: {
      '=': {
        MAP_LIST_DOUBLE_MAP_BOOL_INT,
      },
      '??=': {
        MAP_LIST_DOUBLE_MAP_BOOL_INT,
      },
    },
    MAP_LIST_INT_MAP_BOOL_BOOL: {
      '=': {
        MAP_LIST_INT_MAP_BOOL_BOOL,
      },
      '??=': {
        MAP_LIST_INT_MAP_BOOL_BOOL,
      },
    },
    MAP_LIST_STRING_SET_INT: {
      '=': {
        MAP_LIST_STRING_SET_INT,
      },
      '??=': {
        MAP_LIST_STRING_SET_INT,
      },
    },
    MAP_MAP_BOOL_BOOL_DOUBLE: {
      '=': {
        MAP_MAP_BOOL_BOOL_DOUBLE,
      },
      '??=': {
        MAP_MAP_BOOL_BOOL_DOUBLE,
      },
    },
    MAP_MAP_BOOL_DOUBLE_BOOL: {
      '=': {
        MAP_MAP_BOOL_DOUBLE_BOOL,
      },
      '??=': {
        MAP_MAP_BOOL_DOUBLE_BOOL,
      },
    },
    MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT: {
      '=': {
        MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
      },
      '??=': {
        MAP_MAP_BOOL_DOUBLE_MAP_STRING_INT,
      },
    },
    MAP_MAP_BOOL_INT_MAP_STRING_BOOL: {
      '=': {
        MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
      },
      '??=': {
        MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
      },
    },
    MAP_MAP_BOOL_STRING_MAP_INT_INT: {
      '=': {
        MAP_MAP_BOOL_STRING_MAP_INT_INT,
      },
      '??=': {
        MAP_MAP_BOOL_STRING_MAP_INT_INT,
      },
    },
    MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE: {
      '=': {
        MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
      },
      '??=': {
        MAP_MAP_DOUBLE_BOOL_MAP_INT_DOUBLE,
      },
    },
    MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING: {
      '=': {
        MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
      },
      '??=': {
        MAP_MAP_DOUBLE_DOUBLE_MAP_DOUBLE_STRING,
      },
    },
    MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE: {
      '=': {
        MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
      },
      '??=': {
        MAP_MAP_DOUBLE_INT_MAP_DOUBLE_DOUBLE,
      },
    },
    MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING: {
      '=': {
        MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
      },
      '??=': {
        MAP_MAP_DOUBLE_STRING_MAP_BOOL_STRING,
      },
    },
    MAP_MAP_INT_BOOL_MAP_BOOL_INT: {
      '=': {
        MAP_MAP_INT_BOOL_MAP_BOOL_INT,
      },
      '??=': {
        MAP_MAP_INT_BOOL_MAP_BOOL_INT,
      },
    },
    MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL: {
      '=': {
        MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
      },
      '??=': {
        MAP_MAP_INT_DOUBLE_MAP_BOOL_BOOL,
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
    MAP_MAP_INT_STRING_SET_BOOL: {
      '=': {
        MAP_MAP_INT_STRING_SET_BOOL,
      },
      '??=': {
        MAP_MAP_INT_STRING_SET_BOOL,
      },
    },
    MAP_MAP_STRING_BOOL_LIST_STRING: {
      '=': {
        MAP_MAP_STRING_BOOL_LIST_STRING,
      },
      '??=': {
        MAP_MAP_STRING_BOOL_LIST_STRING,
      },
    },
    MAP_MAP_STRING_DOUBLE_LIST_DOUBLE: {
      '=': {
        MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
      },
      '??=': {
        MAP_MAP_STRING_DOUBLE_LIST_DOUBLE,
      },
    },
    MAP_MAP_STRING_INT_STRING: {
      '=': {
        MAP_MAP_STRING_INT_STRING,
      },
      '??=': {
        MAP_MAP_STRING_INT_STRING,
      },
    },
    MAP_MAP_STRING_STRING_DOUBLE: {
      '=': {
        MAP_MAP_STRING_STRING_DOUBLE,
      },
      '??=': {
        MAP_MAP_STRING_STRING_DOUBLE,
      },
    },
    MAP_SET_BOOL_SET_BOOL: {
      '=': {
        MAP_SET_BOOL_SET_BOOL,
      },
      '??=': {
        MAP_SET_BOOL_SET_BOOL,
      },
    },
    MAP_SET_DOUBLE_LIST_STRING: {
      '=': {
        MAP_SET_DOUBLE_LIST_STRING,
      },
      '??=': {
        MAP_SET_DOUBLE_LIST_STRING,
      },
    },
    MAP_SET_INT_LIST_DOUBLE: {
      '=': {
        MAP_SET_INT_LIST_DOUBLE,
      },
      '??=': {
        MAP_SET_INT_LIST_DOUBLE,
      },
    },
    MAP_SET_STRING_STRING: {
      '=': {
        MAP_SET_STRING_STRING,
      },
      '??=': {
        MAP_SET_STRING_STRING,
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
    MAP_STRING_MAP_DOUBLE_DOUBLE: {
      '=': {
        MAP_STRING_MAP_DOUBLE_DOUBLE,
      },
      '??=': {
        MAP_STRING_MAP_DOUBLE_DOUBLE,
      },
    },
    MAP_STRING_STRING: {
      '=': {
        MAP_STRING_STRING,
      },
      '??=': {
        MAP_STRING_STRING,
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
    SET_MAP_STRING_BOOL: {
      '=': {
        SET_MAP_STRING_BOOL,
      },
      '??=': {
        SET_MAP_STRING_BOOL,
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
    UINT16LIST: {
      '=': {
        UINT16LIST,
      },
      '??=': {
        UINT16LIST,
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
    UINT64LIST: {
      '=': {
        UINT64LIST,
      },
      '??=': {
        UINT64LIST,
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
    UINT8LIST: {
      '=': {
        UINT8LIST,
      },
      '??=': {
        UINT8LIST,
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
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.LIST_MAP_STRING_INT,
    DartType.SET_MAP_STRING_BOOL,
    DartType.MAP_BOOL_MAP_INT_INT,
    DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
    DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
    DartType.MAP_LIST_STRING_SET_INT,
    DartType.MAP_SET_BOOL_SET_BOOL,
    DartType.MAP_SET_STRING_STRING,
    DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
    DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_INT_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
    DartType.MAP_MAP_STRING_INT_STRING,
  };

  // All List<E> types: LIST_INT, LIST_STRING, etc.
  static const Set<DartType> _listTypes = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_MAP_STRING_INT,
    DartType.LIST_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // All Set types: SET_INT, SET_STRING, etc.
  static const Set<DartType> _setTypes = {
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_MAP_STRING_BOOL,
    DartType.SET_STRING,
  };

  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
  static const Set<DartType> _mapTypes = {
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_MAP_INT_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
    DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
    DartType.MAP_LIST_STRING_SET_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
    DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_INT_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
    DartType.MAP_MAP_STRING_INT_STRING,
    DartType.MAP_SET_BOOL_SET_BOOL,
    DartType.MAP_SET_STRING_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
  };

  // All collection types: list, map and set types.
  static const Set<DartType> _collectionTypes = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_MAP_STRING_INT,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_MAP_INT_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
    DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
    DartType.MAP_LIST_STRING_SET_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
    DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_INT_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
    DartType.MAP_MAP_STRING_INT_STRING,
    DartType.MAP_SET_BOOL_SET_BOOL,
    DartType.MAP_SET_STRING_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_MAP_STRING_BOOL,
    DartType.SET_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // All growable types: list, map, set and string types.
  static const Set<DartType> _growableTypes = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_MAP_STRING_INT,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_MAP_INT_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
    DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
    DartType.MAP_LIST_STRING_SET_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
    DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_INT_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
    DartType.MAP_MAP_STRING_INT_STRING,
    DartType.MAP_SET_BOOL_SET_BOOL,
    DartType.MAP_SET_STRING_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_MAP_STRING_BOOL,
    DartType.SET_STRING,
    DartType.STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.
  static const Set<DartType> _indexableTypes = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_MAP_STRING_INT,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_MAP_INT_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
    DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
    DartType.MAP_LIST_STRING_SET_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
    DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    DartType.MAP_MAP_INT_INT_SET_INT,
    DartType.MAP_MAP_INT_STRING_SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
    DartType.MAP_MAP_STRING_INT_STRING,
    DartType.MAP_SET_BOOL_SET_BOOL,
    DartType.MAP_SET_STRING_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.
  static const Map<DartType, DartType> _subscriptsTo = {
    DartType.DURATION: DartType.DURATION,
    DartType.INT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT32X4,
    DartType.INT64LIST: DartType.INT,
    DartType.INT8LIST: DartType.INT,
    DartType.LIST_BOOL: DartType.BOOL,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_MAP_STRING_INT: DartType.MAP_STRING_INT,
    DartType.LIST_STRING: DartType.STRING,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.INT,
    DartType.MAP_BOOL_MAP_INT_INT: DartType.MAP_INT_INT,
    DartType.MAP_BOOL_STRING: DartType.STRING,
    DartType.MAP_INT_BOOL: DartType.BOOL,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.STRING,
    DartType.MAP_LIST_BOOL_MAP_BOOL_STRING: DartType.MAP_BOOL_STRING,
    DartType.MAP_LIST_INT_MAP_BOOL_BOOL: DartType.MAP_BOOL_BOOL,
    DartType.MAP_LIST_STRING_SET_INT: DartType.SET_INT,
    DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL: DartType.MAP_STRING_BOOL,
    DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT: DartType.MAP_INT_INT,
    DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT: DartType.MAP_BOOL_INT,
    DartType.MAP_MAP_INT_INT_SET_INT: DartType.SET_INT,
    DartType.MAP_MAP_INT_STRING_SET_BOOL: DartType.SET_BOOL,
    DartType.MAP_MAP_STRING_BOOL_LIST_STRING: DartType.LIST_STRING,
    DartType.MAP_MAP_STRING_INT_STRING: DartType.STRING,
    DartType.MAP_SET_BOOL_SET_BOOL: DartType.SET_BOOL,
    DartType.MAP_SET_STRING_STRING: DartType.STRING,
    DartType.MAP_STRING_BOOL: DartType.BOOL,
    DartType.MAP_STRING_INT: DartType.INT,
    DartType.MAP_STRING_STRING: DartType.STRING,
    DartType.NUM: DartType.NUM,
    DartType.SET_BOOL: DartType.BOOL,
    DartType.SET_INT: DartType.INT,
    DartType.SET_MAP_STRING_BOOL: DartType.MAP_STRING_BOOL,
    DartType.SET_STRING: DartType.STRING,
    DartType.STRING: DartType.STRING,
    DartType.UINT16LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
  };

  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.
  static const Map<DartType, DartType> _indexedBy = {
    DartType.INT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT,
    DartType.INT64LIST: DartType.INT,
    DartType.INT8LIST: DartType.INT,
    DartType.LIST_BOOL: DartType.INT,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_MAP_STRING_INT: DartType.INT,
    DartType.LIST_STRING: DartType.INT,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.BOOL,
    DartType.MAP_BOOL_MAP_INT_INT: DartType.BOOL,
    DartType.MAP_BOOL_STRING: DartType.BOOL,
    DartType.MAP_INT_BOOL: DartType.INT,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.INT,
    DartType.MAP_LIST_BOOL_MAP_BOOL_STRING: DartType.LIST_BOOL,
    DartType.MAP_LIST_INT_MAP_BOOL_BOOL: DartType.LIST_INT,
    DartType.MAP_LIST_STRING_SET_INT: DartType.LIST_STRING,
    DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL: DartType.MAP_BOOL_INT,
    DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT: DartType.MAP_BOOL_STRING,
    DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT: DartType.MAP_INT_BOOL,
    DartType.MAP_MAP_INT_INT_SET_INT: DartType.MAP_INT_INT,
    DartType.MAP_MAP_INT_STRING_SET_BOOL: DartType.MAP_INT_STRING,
    DartType.MAP_MAP_STRING_BOOL_LIST_STRING: DartType.MAP_STRING_BOOL,
    DartType.MAP_MAP_STRING_INT_STRING: DartType.MAP_STRING_INT,
    DartType.MAP_SET_BOOL_SET_BOOL: DartType.SET_BOOL,
    DartType.MAP_SET_STRING_STRING: DartType.SET_STRING,
    DartType.MAP_STRING_BOOL: DartType.STRING,
    DartType.MAP_STRING_INT: DartType.STRING,
    DartType.MAP_STRING_STRING: DartType.STRING,
    DartType.UINT16LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
  };

  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>
  static const Map<DartType, Set<DartType>> _elementOf = {
    DartType.BOOL: {
      DartType.LIST_BOOL,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_STRING_BOOL,
      DartType.SET_BOOL,
    },
    DartType.DURATION: {
      DartType.DURATION,
    },
    DartType.INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_STRING_INT,
      DartType.SET_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.LIST_STRING: {
      DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
    },
    DartType.MAP_BOOL_BOOL: {
      DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
    },
    DartType.MAP_BOOL_INT: {
      DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    },
    DartType.MAP_BOOL_STRING: {
      DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
    },
    DartType.MAP_INT_INT: {
      DartType.MAP_BOOL_MAP_INT_INT,
      DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
    },
    DartType.MAP_STRING_BOOL: {
      DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
      DartType.SET_MAP_STRING_BOOL,
    },
    DartType.MAP_STRING_INT: {
      DartType.LIST_MAP_STRING_INT,
    },
    DartType.NUM: {
      DartType.NUM,
    },
    DartType.SET_BOOL: {
      DartType.MAP_MAP_INT_STRING_SET_BOOL,
      DartType.MAP_SET_BOOL_SET_BOOL,
    },
    DartType.SET_INT: {
      DartType.MAP_LIST_STRING_SET_INT,
      DartType.MAP_MAP_INT_INT_SET_INT,
    },
    DartType.STRING: {
      DartType.LIST_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_MAP_STRING_INT_STRING,
      DartType.MAP_SET_STRING_STRING,
      DartType.MAP_STRING_STRING,
      DartType.SET_STRING,
      DartType.STRING,
    },
  };

  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.
  static const Map<DartType, Set<DartType>> _indexableElementOf = {
    DartType.BOOL: {
      DartType.LIST_BOOL,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_STRING_BOOL,
    },
    DartType.INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_STRING_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.LIST_STRING: {
      DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
    },
    DartType.MAP_BOOL_BOOL: {
      DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
    },
    DartType.MAP_BOOL_INT: {
      DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
    },
    DartType.MAP_BOOL_STRING: {
      DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
    },
    DartType.MAP_INT_INT: {
      DartType.MAP_BOOL_MAP_INT_INT,
      DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
    },
    DartType.MAP_STRING_BOOL: {
      DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
    },
    DartType.MAP_STRING_INT: {
      DartType.LIST_MAP_STRING_INT,
    },
    DartType.SET_BOOL: {
      DartType.MAP_MAP_INT_STRING_SET_BOOL,
      DartType.MAP_SET_BOOL_SET_BOOL,
    },
    DartType.SET_INT: {
      DartType.MAP_LIST_STRING_SET_INT,
      DartType.MAP_MAP_INT_INT_SET_INT,
    },
    DartType.STRING: {
      DartType.LIST_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_MAP_STRING_INT_STRING,
      DartType.MAP_SET_STRING_STRING,
      DartType.MAP_STRING_STRING,
    },
  };

  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.
  static const Set<DartType> _iterableTypes1 = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_MAP_STRING_INT,
    DartType.LIST_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.
  static const Map<DartType, Set<DartType>> _interfaceRels = {
    DartType.COMPARABLE_DURATION: {
      DartType.DURATION,
    },
    DartType.COMPARABLE_NUM: {
      DartType.INT,
      DartType.NUM,
    },
    DartType.COMPARABLE_STRING: {
      DartType.STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_BOOL: {
      DartType.LIST_BOOL,
    },
    DartType.EFFICIENTLENGTHITERABLE_E: {
      DartType.LIST_BOOL,
      DartType.LIST_INT,
      DartType.LIST_MAP_STRING_INT,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_MAP_STRING_BOOL,
      DartType.SET_STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_MAP_STRING_INT: {
      DartType.LIST_MAP_STRING_INT,
    },
    DartType.EFFICIENTLENGTHITERABLE_STRING: {
      DartType.LIST_STRING,
    },
    DartType.ITERABLE_E: {
      DartType.LIST_BOOL,
      DartType.LIST_INT,
      DartType.LIST_MAP_STRING_INT,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_MAP_STRING_BOOL,
      DartType.SET_STRING,
    },
    DartType.ITERABLE_INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.ITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.LIST_INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.LIST_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.NUM: {
      DartType.INT,
      DartType.NUM,
    },
    DartType.OBJECT: {
      DartType.BOOL,
      DartType.DURATION,
      DartType.INT,
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT32X4,
      DartType.INT32X4LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_BOOL,
      DartType.LIST_INT,
      DartType.LIST_MAP_STRING_INT,
      DartType.LIST_STRING,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_BOOL_INT,
      DartType.MAP_BOOL_MAP_INT_INT,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_BOOL,
      DartType.MAP_INT_INT,
      DartType.MAP_INT_STRING,
      DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
      DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
      DartType.MAP_LIST_STRING_SET_INT,
      DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
      DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
      DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
      DartType.MAP_MAP_INT_INT_SET_INT,
      DartType.MAP_MAP_INT_STRING_SET_BOOL,
      DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
      DartType.MAP_MAP_STRING_INT_STRING,
      DartType.MAP_SET_BOOL_SET_BOOL,
      DartType.MAP_SET_STRING_STRING,
      DartType.MAP_STRING_BOOL,
      DartType.MAP_STRING_INT,
      DartType.MAP_STRING_STRING,
      DartType.NUM,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_MAP_STRING_BOOL,
      DartType.SET_STRING,
      DartType.STRING,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.PATTERN: {
      DartType.STRING,
    },
    DartType.TYPEDDATA: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT32X4LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType._TYPEDINTLIST: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
  };

  // Map type to a list of constructors names with a list of constructor
  // parameter types.
  static const Map<DartType, Map<String, List<DartType>>> _constructors = {
    DartType.DURATION: {
      '': [],
    },
    DartType.INT16LIST: {
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
    DartType.INT32X4: {
      '': [
        DartType.INT,
        DartType.INT,
        DartType.INT,
        DartType.INT,
      ],
    },
    DartType.INT32X4LIST: {
      '': [
        DartType.INT,
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
    DartType.INT8LIST: {
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
    DartType.UINT32LIST: {
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
    DartType.UINT8CLAMPEDLIST: {
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
  };

  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.
  static const Map<DartType, Map<String, Set<List<DartType>>>> _binOps = {
    DartType.BOOL: {
      '&': {
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
          DartType.LIST_BOOL,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_INT,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_STRING,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_MAP_STRING_INT,
          DartType.OBJECT,
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
      '??': {
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
      '|': {
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
    DartType.DURATION: {
      '*': {
        [
          DartType.DURATION,
          DartType.NUM,
        ],
      },
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
      '??': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
      '~/': {
        [
          DartType.DURATION,
          DartType.INT,
        ],
      },
    },
    DartType.INT: {
      '&': {
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
      '^': {
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
      '~/': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
    },
    DartType.INT32X4: {
      '&': {
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
      '^': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '|': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
    },
    DartType.LIST_BOOL: {
      '+': {
        [
          DartType.LIST_BOOL,
          DartType.LIST_BOOL,
        ],
      },
      '??': {
        [
          DartType.LIST_BOOL,
          DartType.LIST_BOOL,
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
    DartType.LIST_FLOAT64X2: {
      '??': {
        [
          DartType.LIST_FLOAT64X2,
          DartType.LIST_FLOAT64X2,
        ],
      },
    },
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
    DartType.LIST_MAP_STRING_INT: {
      '+': {
        [
          DartType.LIST_MAP_STRING_INT,
          DartType.LIST_MAP_STRING_INT,
        ],
      },
      '??': {
        [
          DartType.LIST_MAP_STRING_INT,
          DartType.LIST_MAP_STRING_INT,
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
    DartType.NUM: {
      '%': {
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
      '??': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
    },
    DartType.STRING: {
      '*': {
        [
          DartType.STRING,
          DartType.INT,
        ],
      },
      '+': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
      '??': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
    },
  };

  // Map type to a list of available unary operators.
  static const Map<DartType, Set<String>> _uniOps = {
    DartType.BOOL: {'!'},
    DartType.DURATION: {'-'},
    DartType.INT: {'-', '~'},
    DartType.NUM: {'-'},
  };

  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.
  static const Map<DartType, Map<String, Set<DartType>>> _assignOps = {
    DartType.BOOL: {
      '=': {
        DartType.BOOL,
      },
      '??=': {
        DartType.BOOL,
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
    DartType.INT16LIST: {
      '=': {
        DartType.INT16LIST,
      },
      '??=': {
        DartType.INT16LIST,
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
    DartType.INT32X4LIST: {
      '=': {
        DartType.INT32X4LIST,
      },
      '??=': {
        DartType.INT32X4LIST,
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
    DartType.INT8LIST: {
      '=': {
        DartType.INT8LIST,
      },
      '??=': {
        DartType.INT8LIST,
      },
    },
    DartType.LIST_BOOL: {
      '=': {
        DartType.LIST_BOOL,
      },
      '??=': {
        DartType.LIST_BOOL,
      },
      '+=': {
        DartType.LIST_BOOL,
      },
    },
    DartType.LIST_FLOAT32X4: {
      '+=': {
        DartType.LIST_FLOAT32X4,
      },
    },
    DartType.LIST_FLOAT64X2: {
      '+=': {
        DartType.LIST_FLOAT64X2,
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
    DartType.LIST_INT32X4: {
      '+=': {
        DartType.LIST_INT32X4,
      },
    },
    DartType.LIST_MAP_STRING_INT: {
      '=': {
        DartType.LIST_MAP_STRING_INT,
      },
      '??=': {
        DartType.LIST_MAP_STRING_INT,
      },
      '+=': {
        DartType.LIST_MAP_STRING_INT,
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
    DartType.MAP_BOOL_MAP_INT_INT: {
      '=': {
        DartType.MAP_BOOL_MAP_INT_INT,
      },
      '??=': {
        DartType.MAP_BOOL_MAP_INT_INT,
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
    DartType.MAP_LIST_BOOL_MAP_BOOL_STRING: {
      '=': {
        DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
      },
      '??=': {
        DartType.MAP_LIST_BOOL_MAP_BOOL_STRING,
      },
    },
    DartType.MAP_LIST_INT_MAP_BOOL_BOOL: {
      '=': {
        DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
      },
      '??=': {
        DartType.MAP_LIST_INT_MAP_BOOL_BOOL,
      },
    },
    DartType.MAP_LIST_STRING_SET_INT: {
      '=': {
        DartType.MAP_LIST_STRING_SET_INT,
      },
      '??=': {
        DartType.MAP_LIST_STRING_SET_INT,
      },
    },
    DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL: {
      '=': {
        DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
      },
      '??=': {
        DartType.MAP_MAP_BOOL_INT_MAP_STRING_BOOL,
      },
    },
    DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT: {
      '=': {
        DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
      },
      '??=': {
        DartType.MAP_MAP_BOOL_STRING_MAP_INT_INT,
      },
    },
    DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT: {
      '=': {
        DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
      },
      '??=': {
        DartType.MAP_MAP_INT_BOOL_MAP_BOOL_INT,
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
    DartType.MAP_MAP_INT_STRING_SET_BOOL: {
      '=': {
        DartType.MAP_MAP_INT_STRING_SET_BOOL,
      },
      '??=': {
        DartType.MAP_MAP_INT_STRING_SET_BOOL,
      },
    },
    DartType.MAP_MAP_STRING_BOOL_LIST_STRING: {
      '=': {
        DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
      },
      '??=': {
        DartType.MAP_MAP_STRING_BOOL_LIST_STRING,
      },
    },
    DartType.MAP_MAP_STRING_INT_STRING: {
      '=': {
        DartType.MAP_MAP_STRING_INT_STRING,
      },
      '??=': {
        DartType.MAP_MAP_STRING_INT_STRING,
      },
    },
    DartType.MAP_SET_BOOL_SET_BOOL: {
      '=': {
        DartType.MAP_SET_BOOL_SET_BOOL,
      },
      '??=': {
        DartType.MAP_SET_BOOL_SET_BOOL,
      },
    },
    DartType.MAP_SET_STRING_STRING: {
      '=': {
        DartType.MAP_SET_STRING_STRING,
      },
      '??=': {
        DartType.MAP_SET_STRING_STRING,
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
    DartType.MAP_STRING_STRING: {
      '=': {
        DartType.MAP_STRING_STRING,
      },
      '??=': {
        DartType.MAP_STRING_STRING,
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
    DartType.SET_MAP_STRING_BOOL: {
      '=': {
        DartType.SET_MAP_STRING_BOOL,
      },
      '??=': {
        DartType.SET_MAP_STRING_BOOL,
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
    DartType.UINT16LIST: {
      '=': {
        DartType.UINT16LIST,
      },
      '??=': {
        DartType.UINT16LIST,
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
    DartType.UINT64LIST: {
      '=': {
        DartType.UINT64LIST,
      },
      '??=': {
        DartType.UINT64LIST,
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
    DartType.UINT8LIST: {
      '=': {
        DartType.UINT8LIST,
      },
      '??=': {
        DartType.UINT8LIST,
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
    DartType.LIST_BOOL,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_DOUBLE,
    DartType.SET_INT,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_DOUBLE,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
  };

  // All List<E> types: LIST_INT, LIST_STRING, etc.
  static const Set<DartType> _listTypes = {
    DartType.FLOAT32LIST,
    DartType.FLOAT32X4LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT64X2LIST,
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // All Set types: SET_INT, SET_STRING, etc.
  static const Set<DartType> _setTypes = {
    DartType.SET_BOOL,
    DartType.SET_DOUBLE,
    DartType.SET_INT,
    DartType.SET_STRING,
  };

  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
  static const Set<DartType> _mapTypes = {
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_DOUBLE,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
  };

  // All collection types: list, map and set types.
  static const Set<DartType> _collectionTypes = {
    DartType.FLOAT32LIST,
    DartType.FLOAT32X4LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT64X2LIST,
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_DOUBLE,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.SET_BOOL,
    DartType.SET_DOUBLE,
    DartType.SET_INT,
    DartType.SET_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // All growable types: list, map, set and string types.
  static const Set<DartType> _growableTypes = {
    DartType.FLOAT32LIST,
    DartType.FLOAT32X4LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT64X2LIST,
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_DOUBLE,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.SET_BOOL,
    DartType.SET_DOUBLE,
    DartType.SET_INT,
    DartType.SET_STRING,
    DartType.STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.
  static const Set<DartType> _indexableTypes = {
    DartType.FLOAT32LIST,
    DartType.FLOAT32X4LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT64X2LIST,
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_DOUBLE,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_DOUBLE_BOOL,
    DartType.MAP_DOUBLE_DOUBLE,
    DartType.MAP_DOUBLE_INT,
    DartType.MAP_DOUBLE_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_DOUBLE,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_DOUBLE,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.
  static const Map<DartType, DartType> _subscriptsTo = {
    DartType.DURATION: DartType.DURATION,
    DartType.FLOAT32LIST: DartType.DOUBLE,
    DartType.FLOAT32X4LIST: DartType.FLOAT32X4,
    DartType.FLOAT64LIST: DartType.DOUBLE,
    DartType.FLOAT64X2LIST: DartType.FLOAT64X2,
    DartType.INT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT32X4,
    DartType.INT64LIST: DartType.INT,
    DartType.INT8LIST: DartType.INT,
    DartType.LIST_BOOL: DartType.BOOL,
    DartType.LIST_DOUBLE: DartType.DOUBLE,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_STRING: DartType.STRING,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_DOUBLE: DartType.DOUBLE,
    DartType.MAP_BOOL_INT: DartType.INT,
    DartType.MAP_BOOL_STRING: DartType.STRING,
    DartType.MAP_DOUBLE_BOOL: DartType.BOOL,
    DartType.MAP_DOUBLE_DOUBLE: DartType.DOUBLE,
    DartType.MAP_DOUBLE_INT: DartType.INT,
    DartType.MAP_DOUBLE_STRING: DartType.STRING,
    DartType.MAP_INT_BOOL: DartType.BOOL,
    DartType.MAP_INT_DOUBLE: DartType.DOUBLE,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.STRING,
    DartType.MAP_STRING_BOOL: DartType.BOOL,
    DartType.MAP_STRING_DOUBLE: DartType.DOUBLE,
    DartType.MAP_STRING_INT: DartType.INT,
    DartType.MAP_STRING_STRING: DartType.STRING,
    DartType.NUM: DartType.NUM,
    DartType.SET_BOOL: DartType.BOOL,
    DartType.SET_DOUBLE: DartType.DOUBLE,
    DartType.SET_INT: DartType.INT,
    DartType.SET_STRING: DartType.STRING,
    DartType.STRING: DartType.STRING,
    DartType.UINT16LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
  };

  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.
  static const Map<DartType, DartType> _indexedBy = {
    DartType.FLOAT32LIST: DartType.INT,
    DartType.FLOAT32X4LIST: DartType.INT,
    DartType.FLOAT64LIST: DartType.INT,
    DartType.FLOAT64X2LIST: DartType.INT,
    DartType.INT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT,
    DartType.INT64LIST: DartType.INT,
    DartType.INT8LIST: DartType.INT,
    DartType.LIST_BOOL: DartType.INT,
    DartType.LIST_DOUBLE: DartType.INT,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_STRING: DartType.INT,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_DOUBLE: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.BOOL,
    DartType.MAP_BOOL_STRING: DartType.BOOL,
    DartType.MAP_DOUBLE_BOOL: DartType.DOUBLE,
    DartType.MAP_DOUBLE_DOUBLE: DartType.DOUBLE,
    DartType.MAP_DOUBLE_INT: DartType.DOUBLE,
    DartType.MAP_DOUBLE_STRING: DartType.DOUBLE,
    DartType.MAP_INT_BOOL: DartType.INT,
    DartType.MAP_INT_DOUBLE: DartType.INT,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.INT,
    DartType.MAP_STRING_BOOL: DartType.STRING,
    DartType.MAP_STRING_DOUBLE: DartType.STRING,
    DartType.MAP_STRING_INT: DartType.STRING,
    DartType.MAP_STRING_STRING: DartType.STRING,
    DartType.UINT16LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
  };

  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>
  static const Map<DartType, Set<DartType>> _elementOf = {
    DartType.BOOL: {
      DartType.LIST_BOOL,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_DOUBLE_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_STRING_BOOL,
      DartType.SET_BOOL,
    },
    DartType.DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.LIST_DOUBLE,
      DartType.MAP_BOOL_DOUBLE,
      DartType.MAP_DOUBLE_DOUBLE,
      DartType.MAP_INT_DOUBLE,
      DartType.MAP_STRING_DOUBLE,
      DartType.SET_DOUBLE,
    },
    DartType.DURATION: {
      DartType.DURATION,
    },
    DartType.FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_DOUBLE_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_STRING_INT,
      DartType.SET_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.NUM: {
      DartType.NUM,
    },
    DartType.STRING: {
      DartType.LIST_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_DOUBLE_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_STRING_STRING,
      DartType.SET_STRING,
      DartType.STRING,
    },
  };

  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.
  static const Map<DartType, Set<DartType>> _indexableElementOf = {
    DartType.BOOL: {
      DartType.LIST_BOOL,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_DOUBLE_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_STRING_BOOL,
    },
    DartType.DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.LIST_DOUBLE,
      DartType.MAP_BOOL_DOUBLE,
      DartType.MAP_DOUBLE_DOUBLE,
      DartType.MAP_INT_DOUBLE,
      DartType.MAP_STRING_DOUBLE,
    },
    DartType.FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_DOUBLE_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_STRING_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.STRING: {
      DartType.LIST_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_DOUBLE_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_STRING_STRING,
    },
  };

  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.
  static const Set<DartType> _iterableTypes1 = {
    DartType.FLOAT32LIST,
    DartType.FLOAT32X4LIST,
    DartType.FLOAT64LIST,
    DartType.FLOAT64X2LIST,
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_DOUBLE,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.
  static const Map<DartType, Set<DartType>> _interfaceRels = {
    DartType.COMPARABLE_DURATION: {
      DartType.DURATION,
    },
    DartType.COMPARABLE_NUM: {
      DartType.DOUBLE,
      DartType.INT,
      DartType.NUM,
    },
    DartType.COMPARABLE_STRING: {
      DartType.STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_BOOL: {
      DartType.LIST_BOOL,
    },
    DartType.EFFICIENTLENGTHITERABLE_DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.LIST_DOUBLE,
    },
    DartType.EFFICIENTLENGTHITERABLE_E: {
      DartType.LIST_BOOL,
      DartType.LIST_DOUBLE,
      DartType.LIST_INT,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_DOUBLE,
      DartType.SET_INT,
      DartType.SET_STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_STRING: {
      DartType.LIST_STRING,
    },
    DartType.ITERABLE_DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
    },
    DartType.ITERABLE_E: {
      DartType.LIST_BOOL,
      DartType.LIST_DOUBLE,
      DartType.LIST_INT,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_DOUBLE,
      DartType.SET_INT,
      DartType.SET_STRING,
    },
    DartType.ITERABLE_FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.ITERABLE_FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.ITERABLE_INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.ITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.LIST_DOUBLE: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
      DartType.LIST_DOUBLE,
    },
    DartType.LIST_FLOAT32X4: {
      DartType.FLOAT32X4LIST,
    },
    DartType.LIST_FLOAT64X2: {
      DartType.FLOAT64X2LIST,
    },
    DartType.LIST_INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.LIST_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.NUM: {
      DartType.DOUBLE,
      DartType.INT,
      DartType.NUM,
    },
    DartType.OBJECT: {
      DartType.BOOL,
      DartType.DOUBLE,
      DartType.DURATION,
      DartType.FLOAT32LIST,
      DartType.FLOAT32X4,
      DartType.FLOAT32X4LIST,
      DartType.FLOAT64LIST,
      DartType.FLOAT64X2,
      DartType.FLOAT64X2LIST,
      DartType.INT,
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT32X4,
      DartType.INT32X4LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_BOOL,
      DartType.LIST_DOUBLE,
      DartType.LIST_INT,
      DartType.LIST_STRING,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_BOOL_DOUBLE,
      DartType.MAP_BOOL_INT,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_DOUBLE_BOOL,
      DartType.MAP_DOUBLE_DOUBLE,
      DartType.MAP_DOUBLE_INT,
      DartType.MAP_DOUBLE_STRING,
      DartType.MAP_INT_BOOL,
      DartType.MAP_INT_DOUBLE,
      DartType.MAP_INT_INT,
      DartType.MAP_INT_STRING,
      DartType.MAP_STRING_BOOL,
      DartType.MAP_STRING_DOUBLE,
      DartType.MAP_STRING_INT,
      DartType.MAP_STRING_STRING,
      DartType.NUM,
      DartType.SET_BOOL,
      DartType.SET_DOUBLE,
      DartType.SET_INT,
      DartType.SET_STRING,
      DartType.STRING,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.PATTERN: {
      DartType.STRING,
    },
    DartType.TYPEDDATA: {
      DartType.FLOAT32LIST,
      DartType.FLOAT32X4LIST,
      DartType.FLOAT64LIST,
      DartType.FLOAT64X2LIST,
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT32X4LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType._TYPEDFLOATLIST: {
      DartType.FLOAT32LIST,
      DartType.FLOAT64LIST,
    },
    DartType._TYPEDINTLIST: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
  };

  // Map type to a list of constructors names with a list of constructor
  // parameter types.
  static const Map<DartType, Map<String, List<DartType>>> _constructors = {
    DartType.DURATION: {
      '': [],
    },
    DartType.FLOAT32LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_DOUBLE,
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
    DartType.FLOAT32X4LIST: {
      '': [
        DartType.INT,
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
    DartType.FLOAT64X2LIST: {
      '': [
        DartType.INT,
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
    DartType.INT32LIST: {
      '': [
        DartType.INT,
      ],
      'fromList': [
        DartType.LIST_INT,
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
    DartType.INT32X4LIST: {
      '': [
        DartType.INT,
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
    DartType.INT8LIST: {
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
    DartType.UINT32LIST: {
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
    DartType.UINT8CLAMPEDLIST: {
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
  };

  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.
  static const Map<DartType, Map<String, Set<List<DartType>>>> _binOps = {
    DartType.BOOL: {
      '&': {
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
          DartType.LIST_BOOL,
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
          DartType.LIST_STRING,
          DartType.OBJECT,
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
      '??': {
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
      '|': {
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
      '%': {
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
    DartType.DURATION: {
      '*': {
        [
          DartType.DURATION,
          DartType.NUM,
        ],
      },
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
      '??': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
      '~/': {
        [
          DartType.DURATION,
          DartType.INT,
        ],
      },
    },
    DartType.FLOAT32X4: {
      '*': {
        [
          DartType.FLOAT32X4,
          DartType.FLOAT32X4,
        ],
      },
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
    DartType.FLOAT64X2: {
      '*': {
        [
          DartType.FLOAT64X2,
          DartType.FLOAT64X2,
        ],
      },
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
    DartType.INT: {
      '&': {
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
      '^': {
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
      '~/': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
    },
    DartType.INT32X4: {
      '&': {
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
      '^': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '|': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
    },
    DartType.LIST_BOOL: {
      '+': {
        [
          DartType.LIST_BOOL,
          DartType.LIST_BOOL,
        ],
      },
      '??': {
        [
          DartType.LIST_BOOL,
          DartType.LIST_BOOL,
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
    DartType.NUM: {
      '%': {
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
      '??': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
    },
    DartType.STRING: {
      '*': {
        [
          DartType.STRING,
          DartType.INT,
        ],
      },
      '+': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
      '??': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
    },
  };

  // Map type to a list of available unary operators.
  static const Map<DartType, Set<String>> _uniOps = {
    DartType.BOOL: {'!'},
    DartType.DOUBLE: {'-'},
    DartType.DURATION: {'-'},
    DartType.FLOAT32X4: {'-'},
    DartType.FLOAT64X2: {'-'},
    DartType.INT: {'-', '~'},
    DartType.NUM: {'-'},
  };

  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.
  static const Map<DartType, Map<String, Set<DartType>>> _assignOps = {
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
    DartType.FLOAT32LIST: {
      '=': {
        DartType.FLOAT32LIST,
      },
      '??=': {
        DartType.FLOAT32LIST,
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
    DartType.FLOAT32X4LIST: {
      '=': {
        DartType.FLOAT32X4LIST,
      },
      '??=': {
        DartType.FLOAT32X4LIST,
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
    DartType.FLOAT64X2LIST: {
      '=': {
        DartType.FLOAT64X2LIST,
      },
      '??=': {
        DartType.FLOAT64X2LIST,
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
    DartType.INT16LIST: {
      '=': {
        DartType.INT16LIST,
      },
      '??=': {
        DartType.INT16LIST,
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
    DartType.INT32X4LIST: {
      '=': {
        DartType.INT32X4LIST,
      },
      '??=': {
        DartType.INT32X4LIST,
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
    DartType.INT8LIST: {
      '=': {
        DartType.INT8LIST,
      },
      '??=': {
        DartType.INT8LIST,
      },
    },
    DartType.LIST_BOOL: {
      '=': {
        DartType.LIST_BOOL,
      },
      '??=': {
        DartType.LIST_BOOL,
      },
      '+=': {
        DartType.LIST_BOOL,
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
    DartType.LIST_FLOAT32X4: {
      '+=': {
        DartType.LIST_FLOAT32X4,
      },
    },
    DartType.LIST_FLOAT64X2: {
      '+=': {
        DartType.LIST_FLOAT64X2,
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
    DartType.LIST_INT32X4: {
      '+=': {
        DartType.LIST_INT32X4,
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
    DartType.MAP_BOOL_BOOL: {
      '=': {
        DartType.MAP_BOOL_BOOL,
      },
      '??=': {
        DartType.MAP_BOOL_BOOL,
      },
    },
    DartType.MAP_BOOL_DOUBLE: {
      '=': {
        DartType.MAP_BOOL_DOUBLE,
      },
      '??=': {
        DartType.MAP_BOOL_DOUBLE,
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
    DartType.MAP_STRING_STRING: {
      '=': {
        DartType.MAP_STRING_STRING,
      },
      '??=': {
        DartType.MAP_STRING_STRING,
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
    DartType.SET_STRING: {
      '=': {
        DartType.SET_STRING,
      },
      '??=': {
        DartType.SET_STRING,
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
    DartType.UINT16LIST: {
      '=': {
        DartType.UINT16LIST,
      },
      '??=': {
        DartType.UINT16LIST,
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
    DartType.UINT64LIST: {
      '=': {
        DartType.UINT64LIST,
      },
      '??=': {
        DartType.UINT64LIST,
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
    DartType.UINT8LIST: {
      '=': {
        DartType.UINT8LIST,
      },
      '??=': {
        DartType.UINT8LIST,
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
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
  };

  // All List<E> types: LIST_INT, LIST_STRING, etc.
  static const Set<DartType> _listTypes = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // All Set types: SET_INT, SET_STRING, etc.
  static const Set<DartType> _setTypes = {
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_STRING,
  };

  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
  static const Set<DartType> _mapTypes = {
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
  };

  // All collection types: list, map and set types.
  static const Set<DartType> _collectionTypes = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // All growable types: list, map, set and string types.
  static const Set<DartType> _growableTypes = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.SET_BOOL,
    DartType.SET_INT,
    DartType.SET_STRING,
    DartType.STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.
  static const Set<DartType> _indexableTypes = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.MAP_BOOL_BOOL,
    DartType.MAP_BOOL_INT,
    DartType.MAP_BOOL_STRING,
    DartType.MAP_INT_BOOL,
    DartType.MAP_INT_INT,
    DartType.MAP_INT_STRING,
    DartType.MAP_STRING_BOOL,
    DartType.MAP_STRING_INT,
    DartType.MAP_STRING_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.
  static const Map<DartType, DartType> _subscriptsTo = {
    DartType.DURATION: DartType.DURATION,
    DartType.INT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT32X4,
    DartType.INT64LIST: DartType.INT,
    DartType.INT8LIST: DartType.INT,
    DartType.LIST_BOOL: DartType.BOOL,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_STRING: DartType.STRING,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.INT,
    DartType.MAP_BOOL_STRING: DartType.STRING,
    DartType.MAP_INT_BOOL: DartType.BOOL,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.STRING,
    DartType.MAP_STRING_BOOL: DartType.BOOL,
    DartType.MAP_STRING_INT: DartType.INT,
    DartType.MAP_STRING_STRING: DartType.STRING,
    DartType.NUM: DartType.NUM,
    DartType.SET_BOOL: DartType.BOOL,
    DartType.SET_INT: DartType.INT,
    DartType.SET_STRING: DartType.STRING,
    DartType.STRING: DartType.STRING,
    DartType.UINT16LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
  };

  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.
  static const Map<DartType, DartType> _indexedBy = {
    DartType.INT16LIST: DartType.INT,
    DartType.INT32LIST: DartType.INT,
    DartType.INT32X4LIST: DartType.INT,
    DartType.INT64LIST: DartType.INT,
    DartType.INT8LIST: DartType.INT,
    DartType.LIST_BOOL: DartType.INT,
    DartType.LIST_INT: DartType.INT,
    DartType.LIST_STRING: DartType.INT,
    DartType.MAP_BOOL_BOOL: DartType.BOOL,
    DartType.MAP_BOOL_INT: DartType.BOOL,
    DartType.MAP_BOOL_STRING: DartType.BOOL,
    DartType.MAP_INT_BOOL: DartType.INT,
    DartType.MAP_INT_INT: DartType.INT,
    DartType.MAP_INT_STRING: DartType.INT,
    DartType.MAP_STRING_BOOL: DartType.STRING,
    DartType.MAP_STRING_INT: DartType.STRING,
    DartType.MAP_STRING_STRING: DartType.STRING,
    DartType.UINT16LIST: DartType.INT,
    DartType.UINT32LIST: DartType.INT,
    DartType.UINT64LIST: DartType.INT,
    DartType.UINT8CLAMPEDLIST: DartType.INT,
    DartType.UINT8LIST: DartType.INT,
  };

  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>
  static const Map<DartType, Set<DartType>> _elementOf = {
    DartType.BOOL: {
      DartType.LIST_BOOL,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_STRING_BOOL,
      DartType.SET_BOOL,
    },
    DartType.DURATION: {
      DartType.DURATION,
    },
    DartType.INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_STRING_INT,
      DartType.SET_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.NUM: {
      DartType.NUM,
    },
    DartType.STRING: {
      DartType.LIST_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_STRING_STRING,
      DartType.SET_STRING,
      DartType.STRING,
    },
  };

  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.
  static const Map<DartType, Set<DartType>> _indexableElementOf = {
    DartType.BOOL: {
      DartType.LIST_BOOL,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_INT_BOOL,
      DartType.MAP_STRING_BOOL,
    },
    DartType.INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.MAP_BOOL_INT,
      DartType.MAP_INT_INT,
      DartType.MAP_STRING_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.STRING: {
      DartType.LIST_STRING,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_STRING,
      DartType.MAP_STRING_STRING,
    },
  };

  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.
  static const Set<DartType> _iterableTypes1 = {
    DartType.INT16LIST,
    DartType.INT32LIST,
    DartType.INT32X4LIST,
    DartType.INT64LIST,
    DartType.INT8LIST,
    DartType.LIST_BOOL,
    DartType.LIST_INT,
    DartType.LIST_STRING,
    DartType.UINT16LIST,
    DartType.UINT32LIST,
    DartType.UINT64LIST,
    DartType.UINT8CLAMPEDLIST,
    DartType.UINT8LIST,
  };

  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.
  static const Map<DartType, Set<DartType>> _interfaceRels = {
    DartType.COMPARABLE_DURATION: {
      DartType.DURATION,
    },
    DartType.COMPARABLE_NUM: {
      DartType.INT,
      DartType.NUM,
    },
    DartType.COMPARABLE_STRING: {
      DartType.STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_BOOL: {
      DartType.LIST_BOOL,
    },
    DartType.EFFICIENTLENGTHITERABLE_E: {
      DartType.LIST_BOOL,
      DartType.LIST_INT,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_STRING,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.EFFICIENTLENGTHITERABLE_STRING: {
      DartType.LIST_STRING,
    },
    DartType.ITERABLE_E: {
      DartType.LIST_BOOL,
      DartType.LIST_INT,
      DartType.LIST_STRING,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_STRING,
    },
    DartType.ITERABLE_INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.ITERABLE_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.LIST_INT: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_INT,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.LIST_INT32X4: {
      DartType.INT32X4LIST,
    },
    DartType.NUM: {
      DartType.INT,
      DartType.NUM,
    },
    DartType.OBJECT: {
      DartType.BOOL,
      DartType.DURATION,
      DartType.INT,
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT32X4,
      DartType.INT32X4LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.LIST_BOOL,
      DartType.LIST_INT,
      DartType.LIST_STRING,
      DartType.MAP_BOOL_BOOL,
      DartType.MAP_BOOL_INT,
      DartType.MAP_BOOL_STRING,
      DartType.MAP_INT_BOOL,
      DartType.MAP_INT_INT,
      DartType.MAP_INT_STRING,
      DartType.MAP_STRING_BOOL,
      DartType.MAP_STRING_INT,
      DartType.MAP_STRING_STRING,
      DartType.NUM,
      DartType.SET_BOOL,
      DartType.SET_INT,
      DartType.SET_STRING,
      DartType.STRING,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType.PATTERN: {
      DartType.STRING,
    },
    DartType.TYPEDDATA: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT32X4LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
    DartType._TYPEDINTLIST: {
      DartType.INT16LIST,
      DartType.INT32LIST,
      DartType.INT64LIST,
      DartType.INT8LIST,
      DartType.UINT16LIST,
      DartType.UINT32LIST,
      DartType.UINT64LIST,
      DartType.UINT8CLAMPEDLIST,
      DartType.UINT8LIST,
    },
  };

  // Map type to a list of constructors names with a list of constructor
  // parameter types.
  static const Map<DartType, Map<String, List<DartType>>> _constructors = {
    DartType.DURATION: {
      '': [],
    },
    DartType.INT16LIST: {
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
    DartType.INT32X4: {
      '': [
        DartType.INT,
        DartType.INT,
        DartType.INT,
        DartType.INT,
      ],
    },
    DartType.INT32X4LIST: {
      '': [
        DartType.INT,
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
    DartType.INT8LIST: {
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
    DartType.UINT32LIST: {
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
    DartType.UINT8CLAMPEDLIST: {
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
  };

  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.
  static const Map<DartType, Map<String, Set<List<DartType>>>> _binOps = {
    DartType.BOOL: {
      '&': {
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
          DartType.LIST_BOOL,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_INT,
          DartType.OBJECT,
        ],
        [
          DartType.LIST_STRING,
          DartType.OBJECT,
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
      '??': {
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
      '|': {
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
    DartType.DURATION: {
      '*': {
        [
          DartType.DURATION,
          DartType.NUM,
        ],
      },
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
      '??': {
        [
          DartType.DURATION,
          DartType.DURATION,
        ],
      },
      '~/': {
        [
          DartType.DURATION,
          DartType.INT,
        ],
      },
    },
    DartType.INT: {
      '&': {
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
      '^': {
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
      '~/': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
    },
    DartType.INT32X4: {
      '&': {
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
      '^': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
      '|': {
        [
          DartType.INT32X4,
          DartType.INT32X4,
        ],
      },
    },
    DartType.LIST_BOOL: {
      '+': {
        [
          DartType.LIST_BOOL,
          DartType.LIST_BOOL,
        ],
      },
      '??': {
        [
          DartType.LIST_BOOL,
          DartType.LIST_BOOL,
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
    DartType.LIST_FLOAT64X2: {
      '??': {
        [
          DartType.LIST_FLOAT64X2,
          DartType.LIST_FLOAT64X2,
        ],
      },
    },
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
    DartType.NUM: {
      '%': {
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
      '??': {
        [
          DartType.NUM,
          DartType.NUM,
        ],
      },
    },
    DartType.STRING: {
      '*': {
        [
          DartType.STRING,
          DartType.INT,
        ],
      },
      '+': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
      '??': {
        [
          DartType.STRING,
          DartType.STRING,
        ],
      },
    },
  };

  // Map type to a list of available unary operators.
  static const Map<DartType, Set<String>> _uniOps = {
    DartType.BOOL: {'!'},
    DartType.DURATION: {'-'},
    DartType.INT: {'-', '~'},
    DartType.NUM: {'-'},
  };

  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.
  static const Map<DartType, Map<String, Set<DartType>>> _assignOps = {
    DartType.BOOL: {
      '=': {
        DartType.BOOL,
      },
      '??=': {
        DartType.BOOL,
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
    DartType.INT16LIST: {
      '=': {
        DartType.INT16LIST,
      },
      '??=': {
        DartType.INT16LIST,
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
    DartType.INT32X4LIST: {
      '=': {
        DartType.INT32X4LIST,
      },
      '??=': {
        DartType.INT32X4LIST,
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
    DartType.INT8LIST: {
      '=': {
        DartType.INT8LIST,
      },
      '??=': {
        DartType.INT8LIST,
      },
    },
    DartType.LIST_BOOL: {
      '=': {
        DartType.LIST_BOOL,
      },
      '??=': {
        DartType.LIST_BOOL,
      },
      '+=': {
        DartType.LIST_BOOL,
      },
    },
    DartType.LIST_FLOAT32X4: {
      '+=': {
        DartType.LIST_FLOAT32X4,
      },
    },
    DartType.LIST_FLOAT64X2: {
      '+=': {
        DartType.LIST_FLOAT64X2,
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
    DartType.LIST_INT32X4: {
      '+=': {
        DartType.LIST_INT32X4,
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
    DartType.MAP_STRING_STRING: {
      '=': {
        DartType.MAP_STRING_STRING,
      },
      '??=': {
        DartType.MAP_STRING_STRING,
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
    DartType.SET_STRING: {
      '=': {
        DartType.SET_STRING,
      },
      '??=': {
        DartType.SET_STRING,
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
    DartType.UINT16LIST: {
      '=': {
        DartType.UINT16LIST,
      },
      '??=': {
        DartType.UINT16LIST,
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
    DartType.UINT64LIST: {
      '=': {
        DartType.UINT64LIST,
      },
      '??=': {
        DartType.UINT64LIST,
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
    DartType.UINT8LIST: {
      '=': {
        DartType.UINT8LIST,
      },
      '??=': {
        DartType.UINT8LIST,
      },
    },
  };
}
