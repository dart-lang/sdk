// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The track map is a simple wrapper around a map that keeps track
/// of the 'final' size of maps grouped by description. It allows
/// determining the distribution of sizes for a specific allocation
/// site and it can be used like this:
///
///    Map<String, int> map = new TrackMap<String, int>("my-map");
///
/// After finishing the compilaton, the histogram of track map sizes
/// is printed but only when running in verbose mode.
class TrackMap<K, V> implements Map<K, V> {
  final Map<K, V> _map;
  final List _counts;
  static final Map<String, List<int>> _countsMap = {};

  TrackMap._internal(this._counts) : _map = new Map<K, V>();

  factory TrackMap(String description) {
    List counts = _countsMap.putIfAbsent(description, () => [0]);
    Map result = new TrackMap<K, V>._internal(counts);
    counts[0]++;
    return result;
  }

  static void printHistogram() {
    _countsMap.forEach((description, counts) {
      print('$description -- ${counts.length} maps');

      // Count the total number of maps.
      int sum = 0;
      for (int i = 0; i < counts.length; i++) {
        sum += counts[i];
      }
      int increment = sum ~/ 10;
      int target = increment;
      int accumulated = 0;
      for (int i = 0; i < counts.length; i++) {
        accumulated += counts[i];
        if (accumulated >= target) {
          String percent = (accumulated / sum * 100).toStringAsFixed(1);
          print('  -- $percent%: length <= $i');
          target += increment;
        }
      }
    });
  }

  @override
  int get length => _map.length;
  @override
  bool get isEmpty => _map.isEmpty;
  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  Iterable<K> get keys => _map.keys;
  @override
  Iterable<V> get values => _map.values;

  @override
  bool containsKey(Object key) => _map.containsKey(key);
  @override
  bool containsValue(Object value) => _map.containsValue(value);

  @override
  V operator [](Object key) => _map[key];
  @override
  String toString() => _map.toString();

  @override
  void forEach(void action(K key, V value)) {
    _map.forEach(action);
  }

  @override
  void operator []=(K key, V value) {
    if (!_map.containsKey(key)) {
      _notifyLengthChanged(1);
      _map[key] = value;
    }
  }

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) return this[key];
    V value = ifAbsent();
    this[key] = value;
    return value;
  }

  @override
  V remove(Object key) {
    if (_map.containsKey(key)) {
      _notifyLengthChanged(-1);
    }
    return _map.remove(key);
  }

  @override
  void addAll(Map<K, V> other) {
    other.forEach((key, value) => this[key] = value);
  }

  @override
  void clear() {
    _notifyLengthChanged(-_map.length);
    _map.clear();
  }

  @override
  Map<KR, VR> cast<KR, VR>() => _map.cast<KR, VR>();
  @override
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  @override
  void addEntries(Iterable<MapEntry<K, V>> entries) {
    for (var entry in entries) this[entry.key] = entry.value;
  }

  @override
  Map<KR, VR> map<KR, VR>(MapEntry<KR, VR> transform(K key, V value)) =>
      _map.map(transform);

  @override
  V update(K key, V update(V value), {V ifAbsent()}) =>
      _map.update(key, update, ifAbsent: ifAbsent);

  @override
  void updateAll(V update(K key, V value)) {
    _map.updateAll(update);
  }

  @override
  void removeWhere(bool test(K key, V value)) {
    int before = _map.length;
    _map.removeWhere(test);
    _notifyLengthChanged(_map.length - before);
  }

  void _notifyLengthChanged(int delta) {
    int oldLength = _map.length;
    int newLength = oldLength + delta;
    _counts[oldLength]--;
    if (newLength < _counts.length) {
      _counts[newLength]++;
    } else {
      _counts.add(1);
      assert(newLength == _counts.length - 1);
    }
  }
}
