// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

// This code is inspired by ChangeSummary:
// https://github.com/rafaelw/ChangeSummary/blob/master/change_summary.js
// ...which underlies MDV. Since we don't need the functionality of
// ChangeSummary, we just implement what we need for data bindings.
// This allows our implementation to be much simpler.

/**
 * A data-bound path starting from a view-model or model object, for example
 * `foo.bar.baz`.
 *
 * When the [values] stream is being listened to, this will observe changes to
 * the object and any intermediate object along the path, and send [values]
 * accordingly. When all listeners are unregistered it will stop observing
 * the objects.
 *
 * This class is used to implement [Node.bind] and similar functionality.
 */
class PathObserver extends ChangeNotifier {
  /** The path string. */
  final String path;

  /** True if the path is valid, otherwise false. */
  final bool _isValid;

  final List<Object> _segments;
  List<Object> _values;
  List<StreamSubscription> _subs;

  /**
   * Observes [path] on [object] for changes. This returns an object that can be
   * used to get the changes and get/set the value at this path.
   * See [PathObserver.bindSync] and [PathObserver.value].
   */
  PathObserver(Object object, String path)
      : path = path,
        _isValid = _isPathValid(path),
        _segments = <Object>[] {

    if (_isValid) {
      for (var segment in path.trim().split('.')) {
        if (segment == '') continue;
        var index = int.parse(segment, radix: 10, onError: (_) => null);
        _segments.add(index != null ? index : new Symbol(segment));
      }
    }

    // Initialize arrays.
    // Note that the path itself can't change after it is initially
    // constructed, even though the objects along the path can change.
    _values = new List<Object>(_segments.length + 1);
    _values[0] = object;
    _subs = new List<StreamSubscription>(_segments.length);
  }

  /** The object being observed. */
  get object => _values[0];

  /** Gets the last reported value at this path. */
  @reflectable get value {
    if (!_isValid) return null;
    if (!hasObservers) _updateValues();
    return _values.last;
  }

  /** Sets the value at this path. */
  @reflectable void set value(Object value) {
    int len = _segments.length;

    // TODO(jmesserly): throw if property cannot be set?
    // MDV seems tolerant of these errors.
    if (len == 0) return;
    if (!hasObservers) _updateValues();

    if (_setObjectProperty(_values[len - 1], _segments[len - 1], value)) {
      // Technically, this would get updated asynchronously via a change record.
      // However, it is nice if calling the getter will yield the same value
      // that was just set. So we use this opportunity to update our cache.
      _values[len] = value;
    }
  }

  /**
   * Invokes the [callback] immediately with the current [value], and every time
   * the value changes. This is useful for bindings, which want to be up-to-date
   * immediately and stay bound to the value of the path.
   */
  StreamSubscription bindSync(void callback(value)) {
    var result = changes.listen((records) { callback(value); });
    callback(value);
    return result;
  }

  void _observed() {
    super._observed();
    _updateValues();
    _observePath();
  }

  void _unobserved() {
    for (int i = 0; i < _subs.length; i++) {
      if (_subs[i] != null) {
        _subs[i].cancel();
        _subs[i] = null;
      }
    }
  }

  // TODO(jmesserly): should we be caching these values if not observing?
  void _updateValues() {
    for (int i = 0; i < _segments.length; i++) {
      _values[i + 1] = _getObjectProperty(_values[i], _segments[i]);
    }
  }

  void _updateObservedValues([int start = 0]) {
    var oldValue, newValue;
    for (int i = start; i < _segments.length; i++) {
      oldValue = _values[i + 1];
      newValue = _getObjectProperty(_values[i], _segments[i]);
      if (identical(oldValue, newValue)) {
        _observePath(start, i);
        return;
      }
      _values[i + 1] = newValue;
    }

    _observePath(start);
    notifyPropertyChange(#value, oldValue, newValue);
  }

  void _observePath([int start = 0, int end]) {
    if (end == null) end = _segments.length;

    for (int i = start; i < end; i++) {
      if (_subs[i] != null) _subs[i].cancel();
      _observeIndex(i);
    }
  }

  void _observeIndex(int i) {
    final object = _values[i];
    if (object is Observable) {
      // TODO(jmesserly): rather than allocating a new closure for each
      // property, we could try and have one for the entire path. In that case,
      // we would lose information about which object changed (note: unless
      // PropertyChangeRecord is modified to includes the sender object), so
      // we would need to re-evaluate the entire path. Need to evaluate perf.
      _subs[i] = object.changes.listen((List<ChangeRecord> records) {
        if (!identical(_values[i], object)) {
          // Ignore this object if we're now tracking something else.
          return;
        }

        for (var record in records) {
          if (_changeRecordMatches(record, _segments[i])) {
            _updateObservedValues(i);
            return;
          }
        }
      });
    }
  }
}

bool _changeRecordMatches(record, key) {
  if (record is ListChangeRecord) {
    return key is int && (record as ListChangeRecord).indexChanged(key);
  }
  if (record is PropertyChangeRecord) {
    return (record as PropertyChangeRecord).name == key;
  }
  if (record is MapChangeRecord) {
    if (key is Symbol) key = MirrorSystem.getName(key);
    return (record as MapChangeRecord).key == key;
  }
  return false;
}

_getObjectProperty(object, property) {
  if (object == null) {
    return null;
  }

  if (object is List && property is int) {
    if (property >= 0 && property < object.length) {
      return object[property];
    } else {
      return null;
    }
  }

  if (property is Symbol) {
    var mirror = reflect(object);
    var result = _tryGetField(mirror, property);
    if (result != null) return result.reflectee;
  }

  if (object is Map) {
    if (property is Symbol) property = MirrorSystem.getName(property);
    return object[property];
  }

  return null;
}

bool _setObjectProperty(object, property, value) {
  if (object is List && property is int) {
    if (property >= 0 && property < object.length) {
      object[property] = value;
      return true;
    } else {
      return false;
    }
  }

  if (property is Symbol) {
    var mirror = reflect(object);
    if (_trySetField(mirror, property, value)) return true;
  }

  if (object is Map) {
    if (property is Symbol) property = MirrorSystem.getName(property);
    object[property] = value;
    return true;
  }

  return false;
}

InstanceMirror _tryGetField(InstanceMirror mirror, Symbol name) {
  try {
    return mirror.getField(name);
  } on NoSuchMethodError catch (e) {
    if (_hasMember(mirror, name, (m) =>
        m is VariableMirror || m is MethodMirror && m.isGetter)) {
      // The field/getter is there but threw a NoSuchMethod exception.
      // This is a legitimate error in the code so rethrow.
      rethrow;
    }
    // The field isn't there. PathObserver does not treat this as an error.
    return null;
  }
}

bool _trySetField(InstanceMirror mirror, Symbol name, Object value) {
  try {
    mirror.setField(name, value);
    return true;
  } on NoSuchMethodError catch (e) {
    if (_hasMember(mirror, name, (m) => m is VariableMirror) ||
        _hasMember(mirror, _setterName(name))) {
      // The field/setter is there but threw a NoSuchMethod exception.
      // This is a legitimate error in the code so rethrow.
      rethrow;
    }
    // The field isn't there. PathObserver does not treat this as an error.
    return false;
  }
}

// TODO(jmesserly): workaround for:
// https://code.google.com/p/dart/issues/detail?id=10029
Symbol _setterName(Symbol getter) =>
    new Symbol('${MirrorSystem.getName(getter)}=');

bool _hasMember(InstanceMirror mirror, Symbol name, [bool test(member)]) {
  var type = mirror.type;
  while (type != null) {
    final member = type.members[name];
    if (member != null && (test == null || test(member))) return true;

    try {
      type = type.superclass;
    } on UnsupportedError catch (e) {
      // TODO(jmesserly): dart2js throws this error when the type is not
      // reflectable.
      return false;
    }
  }
  return false;
}

// From: https://github.com/rafaelw/ChangeSummary/blob/master/change_summary.js

final _pathRegExp = () {
  const identStart = '[\$_a-zA-Z]';
  const identPart = '[\$_a-zA-Z0-9]';
  const ident = '$identStart+$identPart*';
  const elementIndex = '(?:[0-9]|[1-9]+[0-9]+)';
  const identOrElementIndex = '(?:$ident|$elementIndex)';
  const path = '(?:$identOrElementIndex)(?:\\.$identOrElementIndex)*';
  return new RegExp('^$path\$');
}();

final _spacesRegExp = new RegExp(r'\s');

bool _isPathValid(String s) {
  s = s.replaceAll(_spacesRegExp, '');

  if (s == '') return true;
  if (s[0] == '.') return false;
  return _pathRegExp.hasMatch(s);
}
