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

import 'package:utf/utf.dart' show stringToCodepoints;

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
        _path = new PropertyPath(path);

  PropertyPath get path => _path;

  /// Sets the value at this path.
  void set value(Object newValue) {
    if (_path != null) _path.setValueFrom(_object, newValue);
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

  void _iterateObjects(void observe(obj, prop)) {
    _path._iterateObjects(_object, observe);
  }

  bool _check({bool skipChanges: false}) {
    var oldValue = _value;
    _value = _path.getValueFrom(_object);
    if (skipChanges || _value == oldValue) return false;

    _report(_value, oldValue, this);
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
  // Dart note: this is ported from `function getPath`.
  factory PropertyPath([path]) {
    if (path is PropertyPath) return path;
    if (path == null || (path is List && path.isEmpty)) path = '';

    if (path is List) {
      var copy = new List.from(path, growable: false);
      for (var segment in copy) {
        // Dart note: unlike Javascript, we don't support arbitraty objects that
        // can be converted to a String.
        // TODO(sigmund): consider whether we should support that here. It might
        // be easier to add support for that if we switch first to use strings
        // for everything instead of symbols.
        if (segment is! int && segment is! String && segment is! Symbol) {
          throw new ArgumentError(
              'List must contain only ints, Strings, and Symbols');
        }
      }
      return new PropertyPath._(copy);
    }

    var pathObj = _pathCache[path];
    if (pathObj != null) return pathObj;


    final segments = new _PathParser().parse(path);
    if (segments == null) return _InvalidPropertyPath._instance;

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
    var sb = new StringBuffer();
    bool first = true;
    for (var key in _segments) {
      if (key is Symbol) {
        if (!first) sb.write('.');
        sb.write(smoke.symbolToName(key));
      } else {
        _formatAccessor(sb, key);
      }
      first = false;
    }
    return sb.toString();
  }

  _formatAccessor(StringBuffer sb, Object key) {
    if (key is int) {
      sb.write('[$key]');
    } else {
      sb.write('["${key.toString().replaceAll('"', '\\"')}"]');
    }
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

  void _iterateObjects(Object obj, void observe(obj, prop)) {
    if (!isValid || isEmpty) return;

    int i = 0, last = _segments.length - 1;
    while (obj != null) {
      // _segments[i] is passed to indicate that we are only observing that
      // property of obj. See observe declaration in _ObservedSet.
      observe(obj, _segments[i]);

      if (i >= last) break;
      obj = _getObjectProperty(obj, _segments[i++]);
    }
  }

  // Dart note: it doesn't make sense to have compiledGetValueFromFn in Dart.
}


/// Visible only for testing:
getSegmentsOfPropertyPathForTesting(p) => p._segments;

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
  } else if (property is String) {
    return object[property];
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

final _identRegExp = () {
  const identStart = '[\$_a-zA-Z]';
  const identPart = '[\$_a-zA-Z0-9]';
  return new RegExp('^$identStart+$identPart*\$');
}();

_isIdent(s) => _identRegExp.hasMatch(s);

// Dart note: refactored to convert to codepoints once and operate on codepoints
// rather than characters.
class _PathParser {
  List keys = [];
  int index = -1;
  String key;

  final Map<String, List<String>> _pathStateMachine = {
    'beforePath': {
      'ws': ['beforePath'],
      'ident': ['inIdent', 'append'],
      '[': ['beforeElement'],
      'eof': ['afterPath']
    },

    'inPath': {
      'ws': ['inPath'],
      '.': ['beforeIdent'],
      '[': ['beforeElement'],
      'eof': ['afterPath']
    },

    'beforeIdent': {
      'ws': ['beforeIdent'],
      'ident': ['inIdent', 'append']
    },

    'inIdent': {
      'ident': ['inIdent', 'append'],
      '0': ['inIdent', 'append'],
      'number': ['inIdent', 'append'],
      'ws': ['inPath', 'push'],
      '.': ['beforeIdent', 'push'],
      '[': ['beforeElement', 'push'],
      'eof': ['afterPath', 'push']
    },

    'beforeElement': {
      'ws': ['beforeElement'],
      '0': ['afterZero', 'append'],
      'number': ['inIndex', 'append'],
      "'": ['inSingleQuote', 'append', ''],
      '"': ['inDoubleQuote', 'append', '']
    },

    'afterZero': {
      'ws': ['afterElement', 'push'],
      ']': ['inPath', 'push']
    },

    'inIndex': {
      '0': ['inIndex', 'append'],
      'number': ['inIndex', 'append'],
      'ws': ['afterElement'],
      ']': ['inPath', 'push']
    },

    'inSingleQuote': {
      "'": ['afterElement'],
      'eof': ['error'],
      'else': ['inSingleQuote', 'append']
    },

    'inDoubleQuote': {
      '"': ['afterElement'],
      'eof': ['error'],
      'else': ['inDoubleQuote', 'append']
    },

    'afterElement': {
      'ws': ['afterElement'],
      ']': ['inPath', 'push']
    }
  };

  /// From getPathCharType: determines the type of a given [code]point.
  String _getPathCharType(code) {
    if (code == null) return 'eof';
    switch(code) {
      case 0x5B: // [
      case 0x5D: // ]
      case 0x2E: // .
      case 0x22: // "
      case 0x27: // '
      case 0x30: // 0
        return _char(code);

      case 0x5F: // _
      case 0x24: // $
        return 'ident';

      case 0x20: // Space
      case 0x09: // Tab
      case 0x0A: // Newline
      case 0x0D: // Return
      case 0xA0:  // No-break space
      case 0xFEFF:  // Byte Order Mark
      case 0x2028:  // Line Separator
      case 0x2029:  // Paragraph Separator
        return 'ws';
    }

    // a-z, A-Z
    if ((0x61 <= code && code <= 0x7A) || (0x41 <= code && code <= 0x5A))
      return 'ident';

    // 1-9
    if (0x31 <= code && code <= 0x39)
      return 'number';

    return 'else';
  }

  static String _char(int codepoint) => new String.fromCharCodes([codepoint]);

  void push() {
    if (key == null) return;

    // Dart note: we store the keys with different types, rather than
    // parsing/converting things later in toString.
    if (_isIdent(key)) {
      keys.add(smoke.nameToSymbol(key));
    } else {
      var index = int.parse(key, radix: 10, onError: (_) => null);
      keys.add(index != null ? index : key);
    }
    key = null;
  }

  void append(newChar) {
    key = (key == null) ? newChar : '$key$newChar';
  }

  bool _maybeUnescapeQuote(String mode, codePoints) {
    if (index >= codePoints.length) return false;
    var nextChar = _char(codePoints[index + 1]);
    if ((mode == 'inSingleQuote' && nextChar == "'") ||
        (mode == 'inDoubleQuote' && nextChar == '"')) {
      index++;
      append(nextChar);
      return true;
    }
    return false;
  }

  /// Returns the parsed keys, or null if there was a parse error.
  List<String> parse(String path) {
    var codePoints = stringToCodepoints(path);
    var mode = 'beforePath';

    while (mode != null) {
      index++;
      var c = index >= codePoints.length ? null : codePoints[index];

      if (c != null &&
          _char(c) == '\\' && _maybeUnescapeQuote(mode, codePoints)) continue;

      var type = _getPathCharType(c);
      if (mode == 'error') return null;

      var typeMap = _pathStateMachine[mode];
      var transition = typeMap[type];
      if (transition == null) transition = typeMap['else'];
      if (transition == null) return null; // parse error;

      mode = transition[0];
      var actionName = transition.length > 1 ? transition[1] : null;
      if (actionName == 'push' && key != null) push();
      if (actionName == 'append') {
        var newChar = transition.length > 2 && transition[2] != null
            ? transition[2] : _char(c);
        append(newChar);
      }

      if (mode == 'afterPath') return keys;
    }
    return null; // parse error
  }
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
  bool _reportChangesOnOpen;
  List _observed = [];

  CompoundObserver([this._reportChangesOnOpen = false]) {
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
    for (var i = 0; i < _observed.length; i += 2) {
      var object = _observed[i];
      if (!identical(object, _observerSentinel)) {
        _directObserver = new _ObservedSet(this, object);
        break;
      }
    }

    _check(skipChanges: !_reportChangesOnOpen);
  }

  void _disconnect() {
    for (var i = 0; i < _observed.length; i += 2) {
      if (identical(_observed[i], _observerSentinel)) {
        _observed[i + 1].close();
      }
    }

    _observed = null;
    _value = null;

    if (_directObserver != null) {
      _directObserver.close(this);
      _directObserver = null;
    }
  }

  /// Adds a dependency on the property [path] accessed from [object].
  /// [path] can be a [PropertyPath] or a [String]. If it is omitted an empty
  /// path will be used.
  void addPath(Object object, [path]) {
    if (_isOpen || _isClosed) {
      throw new StateError('Cannot add paths once started.');
    }

    path = new PropertyPath(path);
    _observed..add(object)..add(path);
    if (!_reportChangesOnOpen) return;
    _value.add(path.getValueFrom(object));
  }

  void addObserver(Bindable observer) {
    if (_isOpen || _isClosed) {
      throw new StateError('Cannot add observers once started.');
    }

    _observed..add(_observerSentinel)..add(observer);
    if (!_reportChangesOnOpen) return;
    _value.add(observer.open((_) => deliver()));
  }

  void _iterateObjects(void observe(obj, prop)) {
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
      var object = _observed[i];
      var path = _observed[i + 1];
      var value;
      if (identical(object, _observerSentinel)) {
        var observable = path as Bindable;
        value = _state == _Observer._UNOPENED ?
            observable.open((_) => this.deliver()) :
            observable.value;
      } else {
        value = (path as PropertyPath).getValueFrom(object);
      }

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

// Visible for testing
get observerSentinelForTesting => _observerSentinel;

// A base class for the shared API implemented by PathObserver and
// CompoundObserver and used in _ObservedSet.
abstract class _Observer extends Bindable {
  Function _notifyCallback;
  int _notifyArgumentCount;
  var _value;

  // abstract members
  void _iterateObjects(void observe(obj, prop));
  void _connect();
  void _disconnect();
  bool _check({bool skipChanges: false});

  static int _UNOPENED = 0;
  static int _OPENED = 1;
  static int _CLOSED = 2;
  int _state = _UNOPENED;
  bool get _isOpen => _state == _OPENED;
  bool get _isClosed => _state == _CLOSED;

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
    _state = _OPENED;
    return _value;
  }

  get value => _discardChanges();

  void close() {
    if (!_isOpen) return;

    _disconnect();
    _value = null;
    _notifyCallback = null;
    _state = _CLOSED;
  }

  _discardChanges() {
    _check(skipChanges: true);
    return _value;
  }

  void deliver() {
    if (_isOpen) _dirtyCheck();
  }

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

/// The observedSet abstraction is a perf optimization which reduces the total
/// number of Object.observe observations of a set of objects. The idea is that
/// groups of Observers will have some object dependencies in common and this
/// observed set ensures that each object in the transitive closure of
/// dependencies is only observed once. The observedSet acts as a write barrier
/// such that whenever any change comes through, all Observers are checked for
/// changed values.
///
/// Note that this optimization is explicitly moving work from setup-time to
/// change-time.
///
/// TODO(rafaelw): Implement "garbage collection". In order to move work off
/// the critical path, when Observers are closed, their observed objects are
/// not Object.unobserve(d). As a result, it's possible that if the observedSet
/// is kept open, but some Observers have been closed, it could cause "leaks"
/// (prevent otherwise collectable objects from being collected). At some
/// point, we should implement incremental "gc" which keeps a list of
/// observedSets which may need clean-up and does small amounts of cleanup on a
/// timeout until all is clean.
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

  /// Subset of properties in [_rootObject] that we care about.
  Set _rootObjectProperties;

  /// Observers associated with this root object, in birth order.
  final List<_Observer> _observers = [];

  // Dart note: the JS implementation is O(N^2) because Array.indexOf is used
  // for lookup in this array. We use HashMap to avoid this problem. It
  // also gives us a nice way of tracking the StreamSubscription.
  Map<Object, StreamSubscription> _objects;

  factory _ObservedSet(_Observer observer, Object rootObject) {
    if (_lastSet == null || !identical(_lastSet._rootObject, rootObject)) {
      _lastSet = new _ObservedSet._(rootObject);
    }
    _lastSet.open(observer, rootObject);
  }

  _ObservedSet._(rootObject)
      : _rootObject = rootObject,
        _rootObjectProperties = rootObject == null ? null : new Set();

  void open(_Observer obs, Object rootObject) {
    if (_rootObject == null) {
      _rootObject = rootObject;
      _rootObjectProperties = new Set();
    }

    _observers.add(obs);
    obs._iterateObjects(observe);
  }

  void close(_Observer obs) {
    if (_observers.isNotEmpty) return;

    if (_objects != null) {
      for (var sub in _objects) sub.cancel();
      _objects = null;
    }
    _rootObject = null;
    _rootObjectProperties = null;
    if (identical(_lastSet, this)) _lastSet = null;
  }

  /// Observe now takes a second argument to indicate which property of an
  /// object is being observed, so we don't trigger change notifications on
  /// changes to unrelated properties.
  void observe(Object obj, Object prop) {
    if (identical(obj, _rootObject)) _rootObjectProperties.add(prop);
    if (obj is ObservableList) _observeStream(obj.listChanges);
    if (obj is Observable) _observeStream(obj.changes);
  }

  void _observeStream(Stream stream) {
    // TODO(jmesserly): we hash on streams as we have two separate change
    // streams for ObservableList. Not sure if that is the design we will use
    // going forward.

    if (_objects == null) _objects = new HashMap();
    if (!_objects.containsKey(stream)) {
      _objects[stream] = stream.listen(_callback);
    }
  }

  /// Whether we can ignore all change events in [records]. This is true if all
  /// records are for properties in the [_rootObject] and we are not observing
  /// any of those properties. Changes on objects other than [_rootObject], or
  /// changes for properties in [_rootObjectProperties] can't be ignored.
  // Dart note: renamed from `allRootObjNonObservedProps` in the JS code.
  bool _canIgnoreRecords(List<ChangeRecord> records) {
    for (var rec in records) {
      if (rec is PropertyChangeRecord) {
        if (!identical(rec.object, _rootObject) ||
            _rootObjectProperties.contains(rec.name)) {
          return false;
        }
      } else if (rec is ListChangeRecord) {
        if (!identical(rec.object, _rootObject) ||
            _rootObjectProperties.contains(rec.index)) {
          return false;
        }
      } else {
        // TODO(sigmund): consider adding object to MapChangeRecord, and make
        // this more precise.
        return false;
      }
    }
    return true;
  }

  void _callback(records) {
    if (_canIgnoreRecords(records)) return;
    for (var observer in _observers.toList(growable: false)) {
      if (observer._isOpen) observer._iterateObjects(observe);
    }

    for (var observer in _observers.toList(growable: false)) {
      if (observer._isOpen) observer._check();
    }
  }
}

const int _MAX_DIRTY_CHECK_CYCLES = 1000;
