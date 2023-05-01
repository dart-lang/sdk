// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._runtime;

/// Describes the shape of a record value.
class Shape {
  /// The number of positional elements in the record.
  int positionals;

  /// The names of the named elements in the record in alphabetical order.
  List<String>? named;

  Shape(this.positionals, this.named);

  @override
  String toString() {
    return 'Shape($positionals, [${named?.join(", ")}])';
  }
}

/// Internal base class for all concrete records.
final class RecordImpl implements Record {
  Shape shape;

  /// Stores the elements of this record.
  ///
  /// Contains all positional elements followed by all named elements in the
  /// order corresponding to names as they appear in [shape].
  List values;

  /// Cache for faster access after the first call of [hashCode].
  int? _hashCode;

  /// Cache for faster access after the first call of [toString].
  ///
  /// NOTE: Does not contain the cached result of the "safe" [_toString] call.
  String? _printed;

  RecordImpl(this.shape, this.values);

  @override
  bool operator ==(Object? other) {
    if (!(other is RecordImpl)) return false;
    if (shape != other.shape) return false;
    if (values.length != other.values.length) {
      return false;
    }
    for (var i = 0; i < values.length; i++) {
      if (values[i] != other.values[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    if (_hashCode == null) {
      _hashCode = Object.hashAll([shape, ...values]);
    }
    return _hashCode!;
  }

  @override
  String toString() => _toString(false);

  /// Returns the string representation of this record.
  ///
  /// Will recursively call [toString] on the elements when [safe] is `false`
  /// or [Primitives.safeToString] when [safe] is `true`.
  String _toString(bool safe) {
    if (!safe && _printed != null) return _printed!;
    var buffer = StringBuffer();
    var posCount = shape.positionals;
    var count = values.length;

    if (safe) buffer.write('Record ');
    buffer.write('(');
    for (var i = 0; i < count; i++) {
      if (i >= posCount) {
        buffer.write('${shape.named![i - posCount]}');
        buffer.write(': ');
      }
      var value = values[i];
      buffer.write(safe ? Primitives.safeToString(value) : '${value}');
      if (i < count - 1) buffer.write(', ');
    }
    buffer.write(')');
    var result = buffer.toString();
    if (!safe) _printed = result;
    return result;
  }
}

/// Cache used to canonicalize all Record shapes in the program.
///
/// These are keyed by a distinct shape recipe String, which consists of an
/// integer followed by space-separated named labels.
final _shapes = JS('!', 'new Map()');

/// Cache used to canonicalize all Record representation classes in the program.
///
/// These are keyed by a distinct shape recipe String, which consists of an
/// integer followed by space-separated named labels.
final _records = JS('!', 'new Map()');

/// Returns a canonicalized shape for the provided number of [positionals] and
/// [named] elements as described by the [shapeRecipe].
Shape registerShape(@notNull String shapeRecipe, @notNull int positionals,
    List<String>? named) {
  var cached = JS<Shape?>('', '#.get(#)', _shapes, shapeRecipe);
  if (cached != null) {
    return cached;
  }

  var shape = Shape(positionals, named);
  JS('', '#.set(#, #)', _shapes, shapeRecipe, shape);
  return shape;
}

/// Returns a canonicalized Record class with the provided number of
/// [positionals] and [named] elements.
///
/// The class can be used to construct record values of the shape described by
/// the [shapeRecipe].
Object registerRecord(@notNull String shapeRecipe, @notNull int positionals,
    List<String>? named) {
  var cached = JS('', '#.get(#)', _records, shapeRecipe);
  if (cached != null) {
    return cached;
  }

  Object recordClass =
      JS('!', 'class _Record extends # {}', JS_CLASS_REF(RecordImpl));
  // Add a 'new' function to be used instead of a constructor
  // (which is disallowed on dart objects).
  Object newRecord = JS(
      '!',
      '''
    #.new = function (shape, values) {
      #.__proto__.new.call(this, shape, values);
    }
  ''',
      recordClass,
      recordClass);

  JS('!', '#.prototype = #.prototype', newRecord, recordClass);
  var recordPrototype = JS('', '#.prototype', recordClass);

  _recordGet(@notNull int index) =>
      JS('!', 'function recordGet() {return this.values[#];}', index);

  // Add convenience getters for accessing the record's field values.
  var count = 0;
  while (count < positionals) {
    var name = '\$${count + 1}';
    defineAccessor(recordPrototype, name,
        get: _recordGet(count), enumerable: true);
    count++;
  }
  if (named != null) {
    for (final name in named) {
      defineAccessor(recordPrototype, name,
          get: _recordGet(count), enumerable: true);
      count++;
    }
  }

  JS('', '#.set(#, #)', _records, shapeRecipe, newRecord);
  return newRecord;
}

/// Creates a shape and binds it to [values].
///
/// [shapeRecipe] consists of a space-separated list of elements, where the
/// first element is the number of positional elements, followed by every
/// named element in sorted order.
Object recordLiteral(@notNull String shapeRecipe, @notNull int positionals,
    List<String>? named, @notNull List values) {
  var shape = registerShape(shapeRecipe, positionals, named);
  var record = registerRecord(shapeRecipe, positionals, named);
  return JS('!', 'new #(#, #)', record, shape, values);
}

String recordSafeToString(RecordImpl rec) => rec._toString(true);
