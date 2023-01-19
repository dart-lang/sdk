// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

/// Base class for all records.
abstract class _Record implements Record {
  const _Record();

  int get _shapeTag => JS('JSUInt31', '#[#]', this,
      JS_GET_NAME(JsGetName.RECORD_SHAPE_TAG_PROPERTY));

  bool _sameShape(_Record other) => _shapeTag == other._shapeTag;

  /// Field values in canonical order.
  // TODO(50081): Replace with a Map view.
  List<Object?> _getFieldValues();

  @override
  String toString() {
    final keys = _fieldKeys();
    final values = _getFieldValues();
    assert(keys.length == values.length);
    final sb = StringBuffer();
    String separator = '';
    sb.write('(');
    for (int i = 0; i < keys.length; i++) {
      sb.write(separator);
      Object key = keys[i];
      if (key is String) {
        sb.write(key);
        sb.write(': ');
      }
      sb.write(values[i]);
      separator = ', ';
    }
    sb.write(')');
    return sb.toString();
  }

  /// Returns a list of integers and strings corresponding to the indexed and
  /// named fields of this record.
  List<Object> _fieldKeys() {
    int shapeTag = _shapeTag;
    while (_computedFieldKeys.length <= shapeTag) _computedFieldKeys.add(null);
    return _computedFieldKeys[shapeTag] ??= _computeFieldKeys();
  }

  List<Object> _computeFieldKeys() {
    String recipe =
        JS('', '#[#]', this, JS_GET_NAME(JsGetName.RECORD_SHAPE_TYPE_PROPERTY));

    // TODO(50081): The Rti recipe format is agnostic to what the record shape
    // key is. We happen to use a comma-separated list of the names for the
    // named arguments. `"+a,b(@,@,@,@)"` is the 4-record with two named fields
    // `a` and `b`. We should refactor the code so that rti.dart returns the
    // arity and the Rti's shape key which are interpreted here.
    String joinedNames =
        JS('', '#.substring(1, #.indexOf(#))', recipe, recipe, '(');
    String atSigns = JS('', '#.replace(/[^@]/g, "")', recipe);
    int arity = atSigns.length;

    List<Object> result = List.generate(arity, (i) => i);
    if (joinedNames != '') {
      List<String> names = joinedNames.split(',');
      int last = arity;
      int i = names.length;
      while (i > 0) result[--last] = names[--i];
    }

    return List.unmodifiable(result);
  }

  static final List<List<Object>?> _computedFieldKeys = [];
}

/// The empty record.
class _EmptyRecord extends _Record {
  const _EmptyRecord();

  @override
  List<Object?> _getFieldValues() => const [];

  @override
  String toString() => '()';

  @override
  bool operator ==(Object other) => identical(other, const _EmptyRecord());

  @override
  int get hashCode => 43 * 67;
}

/// Base class for all records with two fields.
// TODO(49718): Generate this class.
class _Record2 extends _Record {
  final Object? _0;
  final Object? _1;

  _Record2(this._0, this._1);

  @override
  List<Object?> _getFieldValues() => [_0, _1];

  bool _equalFields(_Record2 other) {
    return _0 == other._0 && _1 == other._1;
  }

  @override
  // TODO(49718): Add specializations in shape class that combines is-check with
  // shape check.
  //
  // TODO(49718): Add specializations in type specialization that that combines
  // is-check with shape check and inlines and specializes `_equalFields`.
  bool operator ==(Object other) {
    return other is _Record2 && _sameShape(other) && _equalFields(other);
  }

  @override
  int get hashCode => Object.hash(_shapeTag, _0, _1);
}

class _Record1 extends _Record {
  final Object? _0;

  _Record1(this._0);

  @override
  List<Object?> _getFieldValues() => [_0];

  bool _equalFields(_Record1 other) {
    return _0 == other._0;
  }

  @override
  // TODO(49718): Same as _Record2.
  bool operator ==(Object other) {
    return other is _Record1 && _sameShape(other) && _equalFields(other);
  }

  @override
  int get hashCode => Object.hash(_shapeTag, _0);
}

class _Record3 extends _Record {
  final Object? _0;
  final Object? _1;
  final Object? _2;

  _Record3(this._0, this._1, this._2);

  @override
  List<Object?> _getFieldValues() => [_0, _1, _2];

  bool _equalFields(_Record3 other) {
    return _0 == other._0 && _1 == other._1 && _2 == other._2;
  }

  @override
  // TODO(49718): Same as _Record2.
  bool operator ==(Object other) {
    return other is _Record3 && _sameShape(other) && _equalFields(other);
  }

  @override
  // TODO(49718): Incorporate shape in `hashCode`.
  int get hashCode => Object.hash(_shapeTag, _0, _1, _2);
}

class _RecordN extends _Record {
  final JSArray _values;

  _RecordN(this._values);

  @override
  List<Object?> _getFieldValues() => _values;

  bool _equalFields(_RecordN other) => _equalValues(_values, other._values);

  static bool _equalValues(JSArray a, JSArray b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    return other is _RecordN && _sameShape(other) && _equalFields(other);
  }

  @override
  int get hashCode => Object.hash(_shapeTag, Object.hashAll(_values));
}

/// This function models the use of `_Record` and its subclasses. In the
/// resolution phase this function is assumed to be called in order to add
/// impacts for all the uses in code injected in lowering from K-world to
/// J-world.
void _RecordImpactModel() {
  // Record classes are instantiated.
  Object? anything() => _inscrutable(0);
  final r0 = const _EmptyRecord();
  final r1 = _Record1(anything());
  final r2 = _Record2(anything(), anything());
  final r3 = _Record3(anything(), anything(), anything());
  final rN = _RecordN(anything() as JSArray);

  // Assume the `==` methods are called.
  r0 == anything();
  r1 == anything();
  r2 == anything();
  r3 == anything();
  rN == anything();
}

// TODO(50081): Can this be `external`?
@pragma('dart2js:assumeDynamic')
Object? _inscrutable(Object? x) => x;

// /// Class for all records with two unnamed fields.
// // TODO(49718): Generate this class.
// class _Record2$ extends _Record2 {
//   _Record2$(super._0, super._1);
//
//   bool operator ==(Object other) => other is _Record2$ && _equalFields(other);
//
//   // Dynamic getters. Static field access does not use these getters.
//   Object? get $0 => _0;
//   Object? get $1 => _1;
// }
//
// /// Class for all records with two unnamed fields containing `int`s.
// // TODO(49718): Generate this class.
// class _Record2$_int_int extends _Record2 {
//   _Record2$_int_int(super._0, super._1);
//
//   @pragma('dart2js:as:trust')
//   bool _equalFields(_Record2 other) =>
//       _0 as int == other._0 && _1 as int == other._1;
//
//   // Dynamic getters. Static field access does not use these getters.
//   @pragma('dart2js:as:trust')
//   int get $0 => _0 as int;
//   @pragma('dart2js:as:trust')
//   int get $1 => _1 as int;
// }
