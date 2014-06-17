// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.path_observer;

import 'dart:async';
import 'dart:collection';
import 'dart:math' show min;

import 'package:logging/logging.dart' show Logger, Level;
import 'package:observe/observe.dart';
import 'package:smoke/smoke.dart' as smoke;

/// A data-bound path starting from a view-model or model object, for example
/// `foo.bar.baz`.
///
/// When [open] is called, this will observe changes to the object and any
/// intermediate object along the path, and send updated values accordingly.
/// When [close] is called it will stop observing the objects.
///
/// This class is used to implement `Node.bind` and similar functionality in
/// the [template_binding](pub.dartlang.org/packages/template_binding) package.
class PathObserver extends _Observer implements Bindable {
  PropertyPath _path;
  Object _object;
  _ObservedSet _directObserver;

  /// Observes [path] on [object] for changes. This returns an object
  /// that can be used to get the changes and get/set the value at this path.
  ///
  /// The path can be a [PropertyPath], or a [String] used to construct it.
  ///
  /// See [open] and [value].
  PathObserver(Object object, [path])
      : _object = object,
        _path = path is PropertyPath ? path : new PropertyPath(path);

  bool get _isClosed => _path == null;

  /// Sets the value at this path.
  void set value(Object newValue) {
    if (_path != null) _path.setValueFrom(_object, newValue);
    _discardChanges();
  }

  int get _reportArgumentCount => 2;

  /// Initiates observation and returns the initial value.
  /// The callback will be passed the updated [value], and may optionally be
  /// declared to take a second argument, which will contain the previous value.
  open(callback) => super.open(callback);

  void _connect() {
    _directObserver = new _ObservedSet(this, _object);
    _check(skipChanges: true);
  }

  void _disconnect() {
    _value = null;
    if (_directObserver != null) {
      _directObserver.close(this);
      _directObserver = null;
    }
    // Dart note: the JS impl does not do this, but it seems consistent with
    // CompoundObserver. After closing the PathObserver can't be reopened.
    _path = null;
    _object = null;
  }

  void _iterateObjects(void observe(obj)) {
    _path._iterateObjects(_object, observe);
  }

  bool _check({bool skipChanges: false}) {
    var oldValue = _value;
    _value = _path.getValueFrom(_object);
    if (skipChanges || _value == oldValue) return false;

    _report(_value, oldValue);
    return true;
  }
}

/// A dot-delimieted property path such as "foo.bar" or "foo.10.bar".
///
/// The path specifies how to get a particular value from an object graph, where
/// the graph can include arrays and maps. Each segment of the path describes
/// how to take a single step in the object graph. Properties like 'foo' or
/// 'bar' are read as properties on objects, or as keys if the object is a [Map]
/// or a [Indexable], while integer values are read as indexes in a [List].
// TODO(jmesserly): consider specialized subclasses for:
// * empty path
// * "value"
// * single token in path, e.g. "foo"
class PropertyPath {
  /// The segments of the path.
  final List<Object> _segments;

  /// Creates a new [PropertyPath]. These can be stored to avoid excessive
  /// parsing of path strings.
  ///
  /// The provided [path] should be a String or a List. If it is a list it
  /// should contain only Symbols and integers. This can be used to avoid
  /// parsing.
  ///
  /// Note that this constructor will canonicalize identical paths in some cases
  /// to save memory, but this is not guaranteed. Use [==] for comparions
  /// purposes instead of [identical].
  factory PropertyPath([path]) {
    if (path is List) {
      var copy = new List.from(path, growable: false);
      for (var segment in copy) {
        if (segment is! int && segment is! Symbol) {
          throw new ArgumentError('List must contain only ints and Symbols');
        }
      }
      return new PropertyPath._(copy);
    }

    if (path == null) path = '';

    var pathObj = _pathCache[path];
    if (pathObj != null) return pathObj;

    if (!_isPathValid(path)) return _InvalidPropertyPath._instance;

    final segments = [];
    for (var segment in path.trim().split('.')) {
      if (segment == '') continue;
      var index = int.parse(segment, radix: 10, onError: (_) => null);
      segments.add(index != null ? index : smoke.nameToSymbol(segment));
    }

    // TODO(jmesserly): we could use an UnmodifiableListView here, but that adds
    // memory overhead.
    pathObj = new PropertyPath._(segments.toList(growable: false));
    if (_pathCache.length >= _pathCacheLimit) {
      _pathCache.remove(_pathCache.keys.first);
    }
    _pathCache[path] = pathObj;
    return pathObj;
  }

  PropertyPath._(this._segments);

  int get length => _segments.length;
  bool get isEmpty => _segments.isEmpty;
  bool get isValid => true;

  String toString() {
    if (!isValid) return '<invalid path>';
    return _segments
        .map((s) => s is Symbol ? smoke.symbolToName(s) : s)
        .join('.');
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! PropertyPath) return false;
    if (isValid != other.isValid) return false;

    int len = _segments.length;
    if (len != other._segments.length) return false;
    for (int i = 0; i < len; i++) {
      if (_segments[i] != other._segments[i]) return false;
    }
    return true;
  }

  /// This is the [Jenkins hash function][1] but using masking to keep
  /// values in SMI range.
  /// [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
  // TODO(jmesserly): should reuse this instead, see
  // https://code.google.com/p/dart/issues/detail?id=11617
  int get hashCode {
    int hash = 0;
    for (int i = 0, len = _segments.length; i < len; i++) {
      hash = 0x1fffffff & (hash + _segments[i].hashCode);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) <<  3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  /// Returns the current value of the path from the provided [obj]ect.
  getValueFrom(Object obj) {
    if (!isValid) return null;
    for (var segment in _segments) {
      if (obj == null) return null;
      obj = _getObjectProperty(obj, segment);
    }
    return obj;
  }

  /// Attempts to set the [value] of the path from the provided [obj]ect.
  /// Returns true if and only if the path was reachable and set.
  bool setValueFrom(Object obj, Object value) {
    var end = _segments.length - 1;
    if (end < 0) return false;
    for (int i = 0; i < end; i++) {
      if (obj == null) return false;
      obj = _getObjectProperty(obj, _segments[i]);
    }
    return _setObjectProperty(obj, _segments[end], value);
  }

  void _iterateObjects(Object obj, void observe(obj)) {
    if (!isValid || isEmpty) return;

    int i = 0, last = _segments.length - 1;
    while (obj != null) {
      observe(obj);

      if (i >= last) break;
      obj = _getObjectProperty(obj, _segments[i++]);
    }
  }
}

class _InvalidPropertyPath extends PropertyPath {
  static final _instance = new _InvalidPropertyPath();

  bool get isValid => false;
  _InvalidPropertyPath() : super._([]);
}

bool _changeRecordMatches(record, key) {
  if (record is PropertyChangeRecord) {
    return (record as PropertyChangeRecord).name == key;
  }
  if (record is MapChangeRecord) {
    if (key is Symbol) key = smoke.symbolToName(key);
    return (record as MapChangeRecord).key == key;
  }
  return false;
}

/// Properties in [Map] that need to be read as properties and not as keys in
/// the map. We exclude methods ('containsValue', 'containsKey', 'putIfAbsent',
/// 'addAll', 'remove', 'clear', 'forEach') because there is no use in reading
/// them as part of path-observer segments.
const _MAP_PROPERTIES = const [#keys, #values, #length, #isEmpty, #isNotEmpty];

_getObjectProperty(object, property) {
  if (object == null) return null;

  if (property is int) {
    if (object is List && property >= 0 && property < object.length) {
      return object[property];
    }
  } else if (property is Symbol) {
    // Support indexer if available, e.g. Maps or polymer_expressions Scope.
    // This is the default syntax used by polymer/nodebind and
    // polymer/observe-js PathObserver.
    // TODO(sigmund): should we also support using checking dynamically for
    // whether the type practically implements the indexer API
    // (smoke.hasInstanceMethod(type, const Symbol('[]')))?
    if (object is Indexable<String, dynamic> ||
        object is Map<String, dynamic> && !_MAP_PROPERTIES.contains(property)) {
      return object[smoke.symbolToName(property)];
    }
    try {
      return smoke.read(object, property);
    } on NoSuchMethodError catch (e) {
      // Rethrow, unless the type implements noSuchMethod, in which case we
      // interpret the exception as a signal that the method was not found.
      // Dart note: getting invalid properties is an error, unlike in JS where
      // it returns undefined.
      if (!smoke.hasNoSuchMethod(object.runtimeType)) rethrow;
    }
  }

  if (_logger.isLoggable(Level.FINER)) {
    _logger.finer("can't get $property in $object");
  }
  return null;
}

bool _setObjectProperty(object, property, value) {
  if (object == null) return false;

  if (property is int) {
    if (object is List && property >= 0 && property < object.length) {
      object[property] = value;
      return true;
    }
  } else if (property is Symbol) {
    // Support indexer if available, e.g. Maps or polymer_expressions Scope.
    if (object is Indexable<String, dynamic> ||
        object is Map<String, dynamic> && !_MAP_PROPERTIES.contains(property)) {
      object[smoke.symbolToName(property)] = value;
      return true;
    }
    try {
      smoke.write(object, property, value);
      return true;
    } on NoSuchMethodError catch (e, s) {
      if (!smoke.hasNoSuchMethod(object.runtimeType)) rethrow;
    }
  }

  if (_logger.isLoggable(Level.FINER)) {
    _logger.finer("can't set $property in $object");
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

bool _isPathValid(String s) {
  s = s.trim();
  if (s == '') return true;
  if (s[0] == '.') return false;
  return _pathRegExp.hasMatch(s);
}

final Logger _logger = new Logger('observe.PathObserver');


/// This is a simple cache. It's like LRU but we don't update an item on a
/// cache hit, because that would require allocation. Better to let it expire
/// and reallocate the PropertyPath.
// TODO(jmesserly): this optimization is from observe-js, how valuable is it in
// practice?
final _pathCache = new LinkedHashMap<String, PropertyPath>();

/// The size of a path like "foo.bar" is approximately 160 bytes, so this
/// reserves ~16Kb of memory for recently used paths. Since paths are frequently
/// reused, the theory is that this ends up being a good tradeoff in practice.
// (Note: the 160 byte estimate is from Dart VM 1.0.0.10_r30798 on x64 without
// using UnmodifiableListView in PropertyPath)
const int _pathCacheLimit = 100;

/// [CompoundObserver] is a [Bindable] object which knows how to listen to
/// multiple values (registered via [addPath] or [addObserver]) and invoke a
/// callback when one or more of the values have changed.
///
///    var obj = new ObservableMap.from({'a': 1, 'b': 2});
///    var otherObj = new ObservableMap.from({'c': 3});
///
///    var observer = new CompoundObserver()
///      ..addPath(obj, 'a');
///      ..addObserver(new PathObserver(obj, 'b'));
///      ..addPath(otherObj, 'c');
///      ..open((values) {
///        for (int i = 0; i < values.length; i++) {
///          print('The value at index $i is now ${values[i]}');
///        }
///      });
///
///   obj['a'] = 10; // print will be triggered async
///
class CompoundObserver extends _Observer implements Bindable {
  _ObservedSet _directObserver;
  List _observed = [];

  bool get _isClosed => _observed == null;

  CompoundObserver() {
    _value = [];
  }

  int get _reportArgumentCount => 3;

  /// Initiates observation and returns the initial value.
  /// The callback will be passed the updated [value], and may optionally be
  /// declared to take a second argument, which will contain the previous value.
  ///
  /// Implementation note: a third argument can also be declared, which will
  /// receive a list of objects and paths, such that `list[2 * i]` will access
  /// the object and `list[2 * i + 1]` will access the path, where `i` is the
  /// order of the [addPath] call. This parameter is only used by
  /// `package:polymer` as a performance optimization, and should not be relied
  /// on in new code.
  open(callback) => super.open(callback);

  void _connect() {
    _check(skipChanges: true);

    for (var i = 0; i < _observed.length; i += 2) {
      var object = _observed[i];
      if (!identical(object, _observerSentinel)) {
        _directObserver = new _ObservedSet(this, object);
        break;
      }
    }
  }

  void _disconnect() {
    _value = null;

    if (_directObserver != null) {
      _directObserver.close(this);
      _directObserver = null;
    }

    for (var i = 0; i < _observed.length; i += 2) {
      if (identical(_observed[i], _observerSentinel)) {
        _observed[i + 1].close();
      }
    }
    _observed = null;
  }

  /// Adds a dependency on the property [path] accessed from [object].
  /// [path] can be a [PropertyPath] or a [String]. If it is omitted an empty
  /// path will be used.
  void addPath(Object object, [path]) {
    if (_isOpen || _isClosed) {
      throw new StateError('Cannot add paths once started.');
    }

    if (path is! PropertyPath) path = new PropertyPath(path);
    _observed..add(object)..add(path);
  }

  void addObserver(Bindable observer) {
    if (_isOpen || _isClosed) {
      throw new StateError('Cannot add observers once started.');
    }

    observer.open((_) => deliver());
    _observed..add(_observerSentinel)..add(observer);
  }

  void _iterateObjects(void observe(obj)) {
    for (var i = 0; i < _observed.length; i += 2) {
      var object = _observed[i];
      if (!identical(object, _observerSentinel)) {
        (_observed[i + 1] as PropertyPath)._iterateObjects(object, observe);
      }
    }
  }

  bool _check({bool skipChanges: false}) {
    bool changed = false;
    _value.length = _observed.length ~/ 2;
    var oldValues = null;
    for (var i = 0; i < _observed.length; i += 2) {
      var pathOrObserver = _observed[i + 1];
      var object = _observed[i];
      var value = identical(object, _observerSentinel) ?
          (pathOrObserver as Bindable).value :
          (pathOrObserver as PropertyPath).getValueFrom(object);

      if (skipChanges) {
        _value[i ~/ 2] = value;
        continue;
      }

      if (value == _value[i ~/ 2]) continue;

      // don't allocate this unless necessary.
      if (_notifyArgumentCount >= 2) {
        if (oldValues == null) oldValues = new Map();
        oldValues[i ~/ 2] = _value[i ~/ 2];
      }

      changed = true;
      _value[i ~/ 2] = value;
    }

    if (!changed) return false;

    // TODO(rafaelw): Having _observed as the third callback arg here is
    // pretty lame API. Fix.
    _report(_value, oldValues, _observed);
    return true;
  }
}

/// An object accepted by [PropertyPath] where properties are read and written
/// as indexing operations, just like a [Map].
abstract class Indexable<K, V> {
  V operator [](K key);
  operator []=(K key, V value);
}

const _observerSentinel = const _ObserverSentinel();
class _ObserverSentinel { const _ObserverSentinel(); }

// A base class for the shared API implemented by PathObserver and
// CompoundObserver and used in _ObservedSet.
abstract class _Observer extends Bindable {
  static int _nextBirthId = 0;

  /// A number indicating when the object was created.
  final int _birthId = _nextBirthId++;

  Function _notifyCallback;
  int _notifyArgumentCount;
  var _value;

  // abstract members
  void _iterateObjects(void observe(obj));
  void _connect();
  void _disconnect();
  bool get _isClosed;
  _check({bool skipChanges: false});

  bool get _isOpen => _notifyCallback != null;

  /// The number of arguments the subclass will pass to [_report].
  int get _reportArgumentCount;

  open(callback) {
    if (_isOpen || _isClosed) {
      throw new StateError('Observer has already been opened.');
    }

    if (smoke.minArgs(callback) > _reportArgumentCount) {
      throw new ArgumentError('callback should take $_reportArgumentCount or '
          'fewer arguments');
    }

    _notifyCallback = callback;
    _notifyArgumentCount = min(_reportArgumentCount, smoke.maxArgs(callback));

    _connect();
    return _value;
  }

  get value => _discardChanges();

  void close() {
    if (!_isOpen) return;

    _disconnect();
    _value = null;
    _notifyCallback = null;
  }

  _discardChanges() {
    _check(skipChanges: true);
    return _value;
  }

  bool deliver() => _isOpen ? _dirtyCheck() : false;

  bool _dirtyCheck() {
    var cycles = 0;
    while (cycles < _MAX_DIRTY_CHECK_CYCLES && _check()) {
      cycles++;
    }
    return cycles > 0;
  }

  void _report(newValue, oldValue, [extraArg]) {
    try {
      switch (_notifyArgumentCount) {
        case 0: _notifyCallback(); break;
        case 1: _notifyCallback(newValue); break;
        case 2: _notifyCallback(newValue, oldValue); break;
        case 3: _notifyCallback(newValue, oldValue, extraArg); break;
      }
    } catch (e, s) {
      // Deliver errors async, so if a single callback fails it doesn't prevent
      // other things from working.
      new Completer().completeError(e, s);
    }
  }
}

class _ObservedSet {
  /// To prevent sequential [PathObserver]s and [CompoundObserver]s from
  /// observing the same object, we check if they are observing the same root
  /// as the most recently created observer, and if so merge it into the
  /// existing _ObservedSet.
  ///
  /// See <https://github.com/Polymer/observe-js/commit/f0990b1> and
  /// <https://codereview.appspot.com/46780044/>.
  static _ObservedSet _lastSet;

  /// The root object for a [PathObserver]. For a [CompoundObserver], the root
  /// object of the first path observed. This is used by the constructor to
  /// reuse an [_ObservedSet] that starts from the same object.
  Object _rootObject;

  /// Observers associated with this root object, in birth order.
  final Map<int, _Observer> _observers = new SplayTreeMap();

  // Dart note: the JS implementation is O(N^2) because Array.indexOf is used
  // for lookup in these two arrays. We use HashMap to avoid this problem. It
  // also gives us a nice way of tracking the StreamSubscription.
  Map<Object, StreamSubscription> _objects;
  Map<Object, StreamSubscription> _toRemove;

  bool _resetNeeded = false;

  factory _ObservedSet(_Observer observer, Object rootObj) {
    if (_lastSet == null || !identical(_lastSet._rootObject, rootObj)) {
      _lastSet = new _ObservedSet._(rootObj);
    }
    _lastSet.open(observer);
  }

  _ObservedSet._(this._rootObject);

  void open(_Observer obs) {
    _observers[obs._birthId] = obs;
    obs._iterateObjects(observe);
  }

  void close(_Observer obs) {
    var anyLeft = false;

    _observers.remove(obs._birthId);

    if (_observers.isNotEmpty) {
      _resetNeeded = true;
      scheduleMicrotask(reset);
      return;
    }
    _resetNeeded = false;

    if (_objects != null) {
      for (var sub in _objects) sub.cancel();
      _objects = null;
    }
  }

  void observe(Object obj) {
    if (obj is ObservableList) _observeStream(obj.listChanges);
    if (obj is Observable) _observeStream(obj.changes);
  }

  void _observeStream(Stream stream) {
    // TODO(jmesserly): we hash on streams as we have two separate change
    // streams for ObservableList. Not sure if that is the design we will use
    // going forward.

    if (_objects == null) _objects = new HashMap();
    StreamSubscription sub = null;
    if (_toRemove != null) sub = _toRemove.remove(stream);
    if (sub != null) {
      _objects[stream] = sub;
    } else if (!_objects.containsKey(stream)) {
      _objects[stream] = stream.listen(_callback);
    }
  }

  void reset() {
    if (!_resetNeeded) return;

    var objs = _toRemove == null ? new HashMap() : _toRemove;
    _toRemove = _objects;
    _objects = objs;
    for (var observer in _observers.values) {
      if (observer._isOpen) observer._iterateObjects(observe);
    }

    for (var sub in _toRemove.values) sub.cancel();

    _toRemove = null;
  }

  void _callback(records) {
    for (var observer in _observers.values.toList(growable: false)) {
      if (observer._isOpen) observer._check();
    }

    _resetNeeded = true;
    scheduleMicrotask(reset);
  }
}

const int _MAX_DIRTY_CHECK_CYCLES = 1000;
