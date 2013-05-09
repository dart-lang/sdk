// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * *Warning*: this library is experimental, and APIs are subject to change.
 *
 * This library is used to observe changes to [Observable] types. It also
 * has helpers to implement [Observable] objects.
 *
 * For example:
 *
 *     class Monster extends Object with ObservableMixin {
 *       static const _HEALTH = const Symbol('health');
 *
 *       int _health = 100;
 *       get health => _health;
 *       set health(value) {
 *         _health = notifyChange(_HEALTH, _health, value);
 *       }
 *
 *       void damage(int amount) {
 *         print('$this takes $amount damage!');
 *         health -= amount;
 *       }
 *
 *       toString() => 'Monster with $health hit points';
 *
 *       // These methods are temporary until dart2js supports mirrors.
 *       getValueWorkaround(key) {
 *         if (key == _HEALTH) return health;
 *         return null;
 *       }
 *       setValueWorkaround(key, val) {
 *         if (key == _HEALTH) health = val;
 *       }
 *     }
 *
 *     main() {
 *       var obj = new Monster();
 *       obj.changes.listen((records) {
 *         print('Changes to $obj were: $records');
 *       });
 *       // Schedules asynchronous delivery of these changes
 *       obj.damage(10);
 *       obj.damage(20);
 *       print('done!');
 *     }
 */
library mdv_observe;

import 'dart:collection';

// Import and reexport the observe implementation library. It contains the types
// that are required to implement Model-Driven-Views in dart:html.
// NOTE: always use package:mdv_observe (this package) in your code!
// DO NOT import mdv_observe_impl; it may break unpredictably.
import 'dart:mdv_observe_impl';
export 'dart:mdv_observe_impl';

part 'src/observable_box.dart';
part 'src/observable_list.dart';
part 'src/observable_map.dart';


/**
 * Converts the [Iterable] or [Map] to an [ObservableList] or [ObservableMap],
 * respectively. This is a convenience function to make it easier to convert
 * literals into the corresponding observable collection type.
 *
 * If [value] is not one of those collection types, or is already [Observable],
 * it will be returned unmodified.
 *
 * If [value] is a [Map], the resulting value will use the appropriate kind of
 * backing map: either [HashMap], [LinkedHashMap], or [SplayTreeMap].
 *
 * By default this performs a deep conversion, but you can set [deep] to false
 * for a shallow conversion. This does not handle circular data structures.
 */
// TODO(jmesserly): ObservableSet?
toObservable(value, {bool deep: true}) =>
    deep ? _toObservableDeep(value) : _toObservableShallow(value);

_toObservableShallow(value) {
  if (value is Observable) return value;
  if (value is Map) return new ObservableMap.from(value);
  if (value is Iterable) return new ObservableList.from(value);
  return value;
}

_toObservableDeep(value) {
  if (value is Observable) return value;
  if (value is Map) {
    var result = new ObservableMap._createFromType(value);
    value.forEach((k, v) {
      result[_toObservableDeep(k)] = _toObservableDeep(v);
    });
    return result;
  }
  if (value is Iterable) {
    return new ObservableList.from(value.map(_toObservableDeep));
  }
  return value;
}
