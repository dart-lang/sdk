var collection;
(function(exports) {
  'use strict';
  let _length = Symbol('_length');
  let _strings = Symbol('_strings');
  let _nums = Symbol('_nums');
  let _rest = Symbol('_rest');
  let _keys = Symbol('_keys');
  let _containsKey = Symbol('_containsKey');
  let _getBucket = Symbol('_getBucket');
  let _findBucketIndex = Symbol('_findBucketIndex');
  let _computeKeys = Symbol('_computeKeys');
  let _get = Symbol('_get');
  let _addHashTableEntry = Symbol('_addHashTableEntry');
  let _set = Symbol('_set');
  let _computeHashCode = Symbol('_computeHashCode');
  let _removeHashTableEntry = Symbol('_removeHashTableEntry');
  let _remove = Symbol('_remove');
  let _isStringKey = Symbol('_isStringKey');
  let _isNumericKey = Symbol('_isNumericKey');
  let _hasTableEntry = Symbol('_hasTableEntry');
  let _getTableEntry = Symbol('_getTableEntry');
  let _setTableEntry = Symbol('_setTableEntry');
  let _deleteTableEntry = Symbol('_deleteTableEntry');
  let _newHashTable = Symbol('_newHashTable');
  let _HashMap$ = dart.generic(function(K, V) {
    class _HashMap extends dart.Object {
      _HashMap() {
        this[_length] = 0;
        this[_strings] = null;
        this[_nums] = null;
        this[_rest] = null;
        this[_keys] = null;
      }
      get length() {
        return this[_length];
      }
      get isEmpty() {
        return this[_length] === 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      get keys() {
        return new HashMapKeyIterable(this);
      }
      get values() {
        return new _internal.MappedIterable(this.keys, ((each) => this.get(each)).bind(this));
      }
      containsKey(key) {
        if (_isStringKey(key)) {
          let strings = this[_strings];
          return strings === null ? false : _hasTableEntry(strings, key);
        } else if (_isNumericKey(key)) {
          let nums = this[_nums];
          return nums === null ? false : _hasTableEntry(nums, key);
        } else {
          return this[_containsKey](key);
        }
      }
      [_containsKey](key) {
        let rest = this[_rest];
        if (rest === null)
          return false;
        let bucket = this[_getBucket](rest, key);
        return dart.notNull(this[_findBucketIndex](bucket, key)) >= 0;
      }
      containsValue(value) {
        return this[_computeKeys]().any(((each) => dart.equals(this.get(each), value)).bind(this));
      }
      addAll(other) {
        other.forEach(((key, value) => {
          this.set(key, value);
        }).bind(this));
      }
      get(key) {
        if (_isStringKey(key)) {
          let strings = this[_strings];
          return dart.as(strings === null ? null : _getTableEntry(strings, key), V);
        } else if (_isNumericKey(key)) {
          let nums = this[_nums];
          return dart.as(nums === null ? null : _getTableEntry(nums, key), V);
        } else {
          return this[_get](key);
        }
      }
      [_get](key) {
        let rest = this[_rest];
        if (rest === null)
          return null;
        let bucket = this[_getBucket](rest, key);
        let index = this[_findBucketIndex](bucket, key);
        return dart.as(dart.notNull(index) < 0 ? null : bucket[dart.notNull(index) + 1], V);
      }
      set(key, value) {
        if (_isStringKey(key)) {
          let strings = this[_strings];
          if (strings === null)
            this[_strings] = strings = _newHashTable();
          this[_addHashTableEntry](strings, key, value);
        } else if (_isNumericKey(key)) {
          let nums = this[_nums];
          if (nums === null)
            this[_nums] = nums = _newHashTable();
          this[_addHashTableEntry](nums, key, value);
        } else {
          this[_set](key, value);
        }
      }
      [_set](key, value) {
        let rest = this[_rest];
        if (rest === null)
          this[_rest] = rest = _newHashTable();
        let hash = this[_computeHashCode](key);
        let bucket = rest[hash];
        if (bucket === null) {
          _setTableEntry(rest, hash, [key, value]);
          dart.notNull(this[_length])++;
          this[_keys] = null;
        } else {
          let index = this[_findBucketIndex](bucket, key);
          if (dart.notNull(index) >= 0) {
            bucket[dart.notNull(index) + 1] = value;
          } else {
            bucket.push(key, value);
            dart.notNull(this[_length])++;
            this[_keys] = null;
          }
        }
      }
      putIfAbsent(key, ifAbsent) {
        if (this.containsKey(key))
          return this.get(key);
        let value = ifAbsent();
        this.set(key, value);
        return value;
      }
      remove(key) {
        if (_isStringKey(key)) {
          return this[_removeHashTableEntry](this[_strings], key);
        } else if (_isNumericKey(key)) {
          return this[_removeHashTableEntry](this[_nums], key);
        } else {
          return this[_remove](key);
        }
      }
      [_remove](key) {
        let rest = this[_rest];
        if (rest === null)
          return null;
        let bucket = this[_getBucket](rest, key);
        let index = this[_findBucketIndex](bucket, key);
        if (dart.notNull(index) < 0)
          return null;
        dart.notNull(this[_length])--;
        this[_keys] = null;
        return dart.as(bucket.splice(index, 2)[1], V);
      }
      clear() {
        if (dart.notNull(this[_length]) > 0) {
          this[_strings] = this[_nums] = this[_rest] = this[_keys] = null;
          this[_length] = 0;
        }
      }
      forEach(action) {
        let keys = this[_computeKeys]();
        for (let i = 0, length = keys.length; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let key = keys[i];
          action(dart.as(key, K), this.get(key));
          if (keys !== this[_keys]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
      }
      [_computeKeys]() {
        if (this[_keys] !== null)
          return this[_keys];
        let result = new core.List(this[_length]);
        let index = 0;
        let strings = this[_strings];
        if (strings !== null) {
          let names = Object.getOwnPropertyNames(strings);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); dart.notNull(i)++) {
            let key = names[i];
            result[index] = key;
            dart.notNull(index)++;
          }
        }
        let nums = this[_nums];
        if (nums !== null) {
          let names = Object.getOwnPropertyNames(nums);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); dart.notNull(i)++) {
            let key = +names[i];
            result[index] = key;
            dart.notNull(index)++;
          }
        }
        let rest = this[_rest];
        if (rest !== null) {
          let names = Object.getOwnPropertyNames(rest);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); dart.notNull(i)++) {
            let key = names[i];
            let bucket = rest[key];
            let length = bucket.length;
            for (let i = 0; dart.notNull(i) < dart.notNull(length); i = 2) {
              let key = bucket[i];
              result[index] = key;
              dart.notNull(index)++;
            }
          }
        }
        dart.assert(index === this[_length]);
        return this[_keys] = result;
      }
      [_addHashTableEntry](table, key, value) {
        if (!dart.notNull(_hasTableEntry(table, key))) {
          dart.notNull(this[_length])++;
          this[_keys] = null;
        }
        _setTableEntry(table, key, value);
      }
      [_removeHashTableEntry](table, key) {
        if (dart.notNull(table !== null) && dart.notNull(_hasTableEntry(table, key))) {
          let value = dart.as(_getTableEntry(table, key), V);
          _deleteTableEntry(table, key);
          dart.notNull(this[_length])--;
          this[_keys] = null;
          return value;
        } else {
          return null;
        }
      }
      static [_isStringKey](key) {
        return dart.notNull(typeof key == string) && dart.notNull(!dart.equals(key, '__proto__'));
      }
      static [_isNumericKey](key) {
        return dart.notNull(dart.is(key, core.num)) && (key & 0x3ffffff) === key;
      }
      [_computeHashCode](key) {
        return dart.dload(key, 'hashCode') & 0x3ffffff;
      }
      static [_hasTableEntry](table, key) {
        let entry = table[key];
        return entry !== null;
      }
      static [_getTableEntry](table, key) {
        let entry = table[key];
        return entry === table ? null : entry;
      }
      static [_setTableEntry](table, key, value) {
        if (value === null) {
          table[key] = table;
        } else {
          table[key] = value;
        }
      }
      static [_deleteTableEntry](table, key) {
        delete table[key];
      }
      [_getBucket](table, key) {
        let hash = this[_computeHashCode](key);
        return dart.as(table[hash], core.List);
      }
      [_findBucketIndex](bucket, key) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = 2) {
          if (dart.equals(bucket[i], key))
            return i;
        }
        return -1;
      }
      static [_newHashTable]() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _setTableEntry(table, temporaryKey, table);
        _deleteTableEntry(table, temporaryKey);
        return table;
      }
    }
    return _HashMap;
  });
  let _HashMap = _HashMap$(dynamic, dynamic);
  let _IdentityHashMap$ = dart.generic(function(K, V) {
    class _IdentityHashMap extends _HashMap$(K, V) {
      [_computeHashCode](key) {
        return core.identityHashCode(key) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, key) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = 2) {
          if (core.identical(bucket[i], key))
            return i;
        }
        return -1;
      }
    }
    return _IdentityHashMap;
  });
  let _IdentityHashMap = _IdentityHashMap$(dynamic, dynamic);
  let _equals = Symbol('_equals');
  let _hashCode = Symbol('_hashCode');
  let _validKey = Symbol('_validKey');
  let _CustomHashMap$ = dart.generic(function(K, V) {
    class _CustomHashMap extends _HashMap$(K, V) {
      _CustomHashMap($_equals, $_hashCode, validKey) {
        this[_equals] = $_equals;
        this[_hashCode] = $_hashCode;
        this[_validKey] = dart.as(validKey !== null ? validKey : (v) => dart.is(v, K), _Predicate);
        super._HashMap();
      }
      get(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        return super._get(key);
      }
      set(key, value) {
        super._set(key, value);
      }
      containsKey(key) {
        if (!dart.notNull(this[_validKey](key)))
          return false;
        return super._containsKey(key);
      }
      remove(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        return super._remove(key);
      }
      [_computeHashCode](key) {
        return this[_hashCode](dart.as(key, K)) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, key) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = 2) {
          if (this[_equals](dart.as(bucket[i], K), dart.as(key, K)))
            return i;
        }
        return -1;
      }
      toString() {
        return Maps.mapToString(this);
      }
    }
    return _CustomHashMap;
  });
  let _CustomHashMap = _CustomHashMap$(dynamic, dynamic);
  let _map = Symbol('_map');
  let HashMapKeyIterable$ = dart.generic(function(E) {
    class HashMapKeyIterable extends IterableBase$(E) {
      HashMapKeyIterable($_map) {
        this[_map] = $_map;
        super.IterableBase();
      }
      get length() {
        return dart.as(dart.dload(this[_map], '_length'), core.int);
      }
      get isEmpty() {
        return dart.equals(dart.dload(this[_map], '_length'), 0);
      }
      get iterator() {
        return new HashMapKeyIterator(this[_map], dart.as(dart.dinvoke(this[_map], '_computeKeys'), core.List));
      }
      contains(element) {
        return dart.as(dart.dinvoke(this[_map], 'containsKey', element), core.bool);
      }
      forEach(f) {
        let keys = dart.as(dart.dinvoke(this[_map], '_computeKeys'), core.List);
        for (let i = 0, length = keys.length; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          f(dart.as(keys[i], E));
          if (keys !== dart.dload(this[_map], '_keys')) {
            throw new core.ConcurrentModificationError(this[_map]);
          }
        }
      }
    }
    return HashMapKeyIterable;
  });
  let HashMapKeyIterable = HashMapKeyIterable$(dynamic);
  let _offset = Symbol('_offset');
  let _current = Symbol('_current');
  let HashMapKeyIterator$ = dart.generic(function(E) {
    class HashMapKeyIterator extends dart.Object {
      HashMapKeyIterator($_map, $_keys) {
        this[_map] = $_map;
        this[_keys] = $_keys;
        this[_offset] = 0;
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        let keys = this[_keys];
        let offset = this[_offset];
        if (keys !== dart.dload(this[_map], '_keys')) {
          throw new core.ConcurrentModificationError(this[_map]);
        } else if (dart.notNull(offset) >= keys.length) {
          this[_current] = null;
          return false;
        } else {
          this[_current] = dart.as(keys[offset], E);
          this[_offset] = dart.notNull(offset) + 1;
          return true;
        }
      }
    }
    return HashMapKeyIterator;
  });
  let HashMapKeyIterator = HashMapKeyIterator$(dynamic);
  let _first = Symbol('_first');
  let _last = Symbol('_last');
  let _modifications = Symbol('_modifications');
  let _value = Symbol('_value');
  let _newLinkedCell = Symbol('_newLinkedCell');
  let _unlinkCell = Symbol('_unlinkCell');
  let _modified = Symbol('_modified');
  let _key = Symbol('_key');
  let _next = Symbol('_next');
  let _previous = Symbol('_previous');
  let _LinkedHashMap$ = dart.generic(function(K, V) {
    class _LinkedHashMap extends dart.Object {
      _LinkedHashMap() {
        this[_length] = 0;
        this[_strings] = null;
        this[_nums] = null;
        this[_rest] = null;
        this[_first] = null;
        this[_last] = null;
        this[_modifications] = 0;
      }
      get length() {
        return this[_length];
      }
      get isEmpty() {
        return this[_length] === 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      get keys() {
        return new LinkedHashMapKeyIterable(this);
      }
      get values() {
        return new _internal.MappedIterable(this.keys, ((each) => this.get(each)).bind(this));
      }
      containsKey(key) {
        if (_isStringKey(key)) {
          let strings = this[_strings];
          if (strings === null)
            return false;
          let cell = dart.as(_getTableEntry(strings, key), LinkedHashMapCell);
          return cell !== null;
        } else if (_isNumericKey(key)) {
          let nums = this[_nums];
          if (nums === null)
            return false;
          let cell = dart.as(_getTableEntry(nums, key), LinkedHashMapCell);
          return cell !== null;
        } else {
          return this[_containsKey](key);
        }
      }
      [_containsKey](key) {
        let rest = this[_rest];
        if (rest === null)
          return false;
        let bucket = this[_getBucket](rest, key);
        return dart.notNull(this[_findBucketIndex](bucket, key)) >= 0;
      }
      containsValue(value) {
        return this.keys.any(((each) => dart.equals(this.get(each), value)).bind(this));
      }
      addAll(other) {
        other.forEach(((key, value) => {
          this.set(key, value);
        }).bind(this));
      }
      get(key) {
        if (_isStringKey(key)) {
          let strings = this[_strings];
          if (strings === null)
            return null;
          let cell = dart.as(_getTableEntry(strings, key), LinkedHashMapCell);
          return dart.as(cell === null ? null : cell[_value], V);
        } else if (_isNumericKey(key)) {
          let nums = this[_nums];
          if (nums === null)
            return null;
          let cell = dart.as(_getTableEntry(nums, key), LinkedHashMapCell);
          return dart.as(cell === null ? null : cell[_value], V);
        } else {
          return this[_get](key);
        }
      }
      [_get](key) {
        let rest = this[_rest];
        if (rest === null)
          return null;
        let bucket = this[_getBucket](rest, key);
        let index = this[_findBucketIndex](bucket, key);
        if (dart.notNull(index) < 0)
          return null;
        let cell = dart.as(bucket[index], LinkedHashMapCell);
        return dart.as(cell[_value], V);
      }
      set(key, value) {
        if (_isStringKey(key)) {
          let strings = this[_strings];
          if (strings === null)
            this[_strings] = strings = _newHashTable();
          this[_addHashTableEntry](strings, key, value);
        } else if (_isNumericKey(key)) {
          let nums = this[_nums];
          if (nums === null)
            this[_nums] = nums = _newHashTable();
          this[_addHashTableEntry](nums, key, value);
        } else {
          this[_set](key, value);
        }
      }
      [_set](key, value) {
        let rest = this[_rest];
        if (rest === null)
          this[_rest] = rest = _newHashTable();
        let hash = this[_computeHashCode](key);
        let bucket = rest[hash];
        if (bucket === null) {
          let cell = this[_newLinkedCell](key, value);
          _setTableEntry(rest, hash, [cell]);
        } else {
          let index = this[_findBucketIndex](bucket, key);
          if (dart.notNull(index) >= 0) {
            let cell = dart.as(bucket[index], LinkedHashMapCell);
            cell[_value] = value;
          } else {
            let cell = this[_newLinkedCell](key, value);
            bucket.push(cell);
          }
        }
      }
      putIfAbsent(key, ifAbsent) {
        if (this.containsKey(key))
          return this.get(key);
        let value = ifAbsent();
        this.set(key, value);
        return value;
      }
      remove(key) {
        if (_isStringKey(key)) {
          return this[_removeHashTableEntry](this[_strings], key);
        } else if (_isNumericKey(key)) {
          return this[_removeHashTableEntry](this[_nums], key);
        } else {
          return this[_remove](key);
        }
      }
      [_remove](key) {
        let rest = this[_rest];
        if (rest === null)
          return null;
        let bucket = this[_getBucket](rest, key);
        let index = this[_findBucketIndex](bucket, key);
        if (dart.notNull(index) < 0)
          return null;
        let cell = dart.as(bucket.splice(index, 1)[0], LinkedHashMapCell);
        this[_unlinkCell](cell);
        return dart.as(cell[_value], V);
      }
      clear() {
        if (dart.notNull(this[_length]) > 0) {
          this[_strings] = this[_nums] = this[_rest] = this[_first] = this[_last] = null;
          this[_length] = 0;
          this[_modified]();
        }
      }
      forEach(action) {
        let cell = this[_first];
        let modifications = this[_modifications];
        while (cell !== null) {
          action(dart.as(cell[_key], K), dart.as(cell[_value], V));
          if (modifications !== this[_modifications]) {
            throw new core.ConcurrentModificationError(this);
          }
          cell = cell[_next];
        }
      }
      [_addHashTableEntry](table, key, value) {
        let cell = dart.as(_getTableEntry(table, key), LinkedHashMapCell);
        if (cell === null) {
          _setTableEntry(table, key, this[_newLinkedCell](key, value));
        } else {
          cell[_value] = value;
        }
      }
      [_removeHashTableEntry](table, key) {
        if (table === null)
          return null;
        let cell = dart.as(_getTableEntry(table, key), LinkedHashMapCell);
        if (cell === null)
          return null;
        this[_unlinkCell](cell);
        _deleteTableEntry(table, key);
        return dart.as(cell[_value], V);
      }
      [_modified]() {
        this[_modifications] = dart.notNull(this[_modifications]) + 1 & 67108863;
      }
      [_newLinkedCell](key, value) {
        let cell = new LinkedHashMapCell(key, value);
        if (this[_first] === null) {
          this[_first] = this[_last] = cell;
        } else {
          let last = this[_last];
          cell[_previous] = last;
          this[_last] = last[_next] = cell;
        }
        dart.notNull(this[_length])++;
        this[_modified]();
        return cell;
      }
      [_unlinkCell](cell) {
        let previous = cell[_previous];
        let next = cell[_next];
        if (previous === null) {
          dart.assert(dart.equals(cell, this[_first]));
          this[_first] = next;
        } else {
          previous[_next] = next;
        }
        if (next === null) {
          dart.assert(dart.equals(cell, this[_last]));
          this[_last] = previous;
        } else {
          next[_previous] = previous;
        }
        dart.notNull(this[_length])--;
        this[_modified]();
      }
      static [_isStringKey](key) {
        return dart.notNull(typeof key == string) && dart.notNull(!dart.equals(key, '__proto__'));
      }
      static [_isNumericKey](key) {
        return dart.notNull(dart.is(key, core.num)) && (key & 0x3ffffff) === key;
      }
      [_computeHashCode](key) {
        return dart.dload(key, 'hashCode') & 0x3ffffff;
      }
      static [_getTableEntry](table, key) {
        return table[key];
      }
      static [_setTableEntry](table, key, value) {
        dart.assert(value !== null);
        table[key] = value;
      }
      static [_deleteTableEntry](table, key) {
        delete table[key];
      }
      [_getBucket](table, key) {
        let hash = this[_computeHashCode](key);
        return dart.as(table[hash], core.List);
      }
      [_findBucketIndex](bucket, key) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let cell = dart.as(bucket[i], LinkedHashMapCell);
          if (dart.equals(cell[_key], key))
            return i;
        }
        return -1;
      }
      static [_newHashTable]() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _setTableEntry(table, temporaryKey, table);
        _deleteTableEntry(table, temporaryKey);
        return table;
      }
      toString() {
        return Maps.mapToString(this);
      }
    }
    return _LinkedHashMap;
  });
  let _LinkedHashMap = _LinkedHashMap$(dynamic, dynamic);
  let _LinkedIdentityHashMap$ = dart.generic(function(K, V) {
    class _LinkedIdentityHashMap extends _LinkedHashMap$(K, V) {
      [_computeHashCode](key) {
        return core.identityHashCode(key) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, key) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let cell = dart.as(bucket[i], LinkedHashMapCell);
          if (core.identical(cell[_key], key))
            return i;
        }
        return -1;
      }
    }
    return _LinkedIdentityHashMap;
  });
  let _LinkedIdentityHashMap = _LinkedIdentityHashMap$(dynamic, dynamic);
  let _LinkedCustomHashMap$ = dart.generic(function(K, V) {
    class _LinkedCustomHashMap extends _LinkedHashMap$(K, V) {
      _LinkedCustomHashMap($_equals, $_hashCode, validKey) {
        this[_equals] = $_equals;
        this[_hashCode] = $_hashCode;
        this[_validKey] = dart.as(validKey !== null ? validKey : (v) => dart.is(v, K), _Predicate);
        super._LinkedHashMap();
      }
      get(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        return super._get(key);
      }
      set(key, value) {
        super._set(key, value);
      }
      containsKey(key) {
        if (!dart.notNull(this[_validKey](key)))
          return false;
        return super._containsKey(key);
      }
      remove(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        return super._remove(key);
      }
      [_computeHashCode](key) {
        return this[_hashCode](dart.as(key, K)) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, key) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let cell = dart.as(bucket[i], LinkedHashMapCell);
          if (this[_equals](dart.as(cell[_key], K), dart.as(key, K)))
            return i;
        }
        return -1;
      }
    }
    return _LinkedCustomHashMap;
  });
  let _LinkedCustomHashMap = _LinkedCustomHashMap$(dynamic, dynamic);
  class LinkedHashMapCell extends dart.Object {
    LinkedHashMapCell($_key, $_value) {
      this[_key] = $_key;
      this[_value] = $_value;
      this[_next] = null;
      this[_previous] = null;
    }
  }
  let LinkedHashMapKeyIterable$ = dart.generic(function(E) {
    class LinkedHashMapKeyIterable extends IterableBase$(E) {
      LinkedHashMapKeyIterable($_map) {
        this[_map] = $_map;
        super.IterableBase();
      }
      get length() {
        return dart.as(dart.dload(this[_map], '_length'), core.int);
      }
      get isEmpty() {
        return dart.equals(dart.dload(this[_map], '_length'), 0);
      }
      get iterator() {
        return new LinkedHashMapKeyIterator(this[_map], dart.as(dart.dload(this[_map], '_modifications'), core.int));
      }
      contains(element) {
        return dart.as(dart.dinvoke(this[_map], 'containsKey', element), core.bool);
      }
      forEach(f) {
        let cell = dart.as(dart.dload(this[_map], '_first'), LinkedHashMapCell);
        let modifications = dart.as(dart.dload(this[_map], '_modifications'), core.int);
        while (cell !== null) {
          f(dart.as(cell[_key], E));
          if (modifications !== dart.dload(this[_map], '_modifications')) {
            throw new core.ConcurrentModificationError(this[_map]);
          }
          cell = cell[_next];
        }
      }
    }
    return LinkedHashMapKeyIterable;
  });
  let LinkedHashMapKeyIterable = LinkedHashMapKeyIterable$(dynamic);
  let _cell = Symbol('_cell');
  let LinkedHashMapKeyIterator$ = dart.generic(function(E) {
    class LinkedHashMapKeyIterator extends dart.Object {
      LinkedHashMapKeyIterator($_map, $_modifications) {
        this[_map] = $_map;
        this[_modifications] = $_modifications;
        this[_cell] = null;
        this[_current] = null;
        this[_cell] = dart.as(dart.dload(this[_map], '_first'), LinkedHashMapCell);
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        if (this[_modifications] !== dart.dload(this[_map], '_modifications')) {
          throw new core.ConcurrentModificationError(this[_map]);
        } else if (this[_cell] === null) {
          this[_current] = null;
          return false;
        } else {
          this[_current] = dart.as(this[_cell][_key], E);
          this[_cell] = this[_cell][_next];
          return true;
        }
      }
    }
    return LinkedHashMapKeyIterator;
  });
  let LinkedHashMapKeyIterator = LinkedHashMapKeyIterator$(dynamic);
  let _elements = Symbol('_elements');
  let _newSet = Symbol('_newSet');
  let _computeElements = Symbol('_computeElements');
  let _contains = Symbol('_contains');
  let _lookup = Symbol('_lookup');
  let _add = Symbol('_add');
  let _isStringElement = Symbol('_isStringElement');
  let _isNumericElement = Symbol('_isNumericElement');
  let _HashSet$ = dart.generic(function(E) {
    class _HashSet extends _HashSetBase$(E) {
      _HashSet() {
        this[_length] = 0;
        this[_strings] = null;
        this[_nums] = null;
        this[_rest] = null;
        this[_elements] = null;
        super._HashSetBase();
      }
      [_newSet]() {
        return new _HashSet();
      }
      get iterator() {
        return new HashSetIterator(this, this[_computeElements]());
      }
      get length() {
        return this[_length];
      }
      get isEmpty() {
        return this[_length] === 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      contains(object) {
        if (_isStringElement(object)) {
          let strings = this[_strings];
          return strings === null ? false : _hasTableEntry(strings, object);
        } else if (_isNumericElement(object)) {
          let nums = this[_nums];
          return nums === null ? false : _hasTableEntry(nums, object);
        } else {
          return this[_contains](object);
        }
      }
      [_contains](object) {
        let rest = this[_rest];
        if (rest === null)
          return false;
        let bucket = this[_getBucket](rest, object);
        return dart.notNull(this[_findBucketIndex](bucket, object)) >= 0;
      }
      lookup(object) {
        if (dart.notNull(_isStringElement(object)) || dart.notNull(_isNumericElement(object))) {
          return dart.as(this.contains(object) ? object : null, E);
        }
        return this[_lookup](object);
      }
      [_lookup](object) {
        let rest = this[_rest];
        if (rest === null)
          return null;
        let bucket = this[_getBucket](rest, object);
        let index = this[_findBucketIndex](bucket, object);
        if (dart.notNull(index) < 0)
          return null;
        return dart.as(bucket.get(index), E);
      }
      add(element) {
        if (_isStringElement(element)) {
          let strings = this[_strings];
          if (strings === null)
            this[_strings] = strings = _newHashTable();
          return this[_addHashTableEntry](strings, element);
        } else if (_isNumericElement(element)) {
          let nums = this[_nums];
          if (nums === null)
            this[_nums] = nums = _newHashTable();
          return this[_addHashTableEntry](nums, element);
        } else {
          return this[_add](element);
        }
      }
      [_add](element) {
        let rest = this[_rest];
        if (rest === null)
          this[_rest] = rest = _newHashTable();
        let hash = this[_computeHashCode](element);
        let bucket = rest[hash];
        if (bucket === null) {
          _setTableEntry(rest, hash, [element]);
        } else {
          let index = this[_findBucketIndex](bucket, element);
          if (dart.notNull(index) >= 0)
            return false;
          bucket.push(element);
        }
        dart.notNull(this[_length])++;
        this[_elements] = null;
        return true;
      }
      addAll(objects) {
        for (let each of objects) {
          this.add(each);
        }
      }
      remove(object) {
        if (_isStringElement(object)) {
          return this[_removeHashTableEntry](this[_strings], object);
        } else if (_isNumericElement(object)) {
          return this[_removeHashTableEntry](this[_nums], object);
        } else {
          return this[_remove](object);
        }
      }
      [_remove](object) {
        let rest = this[_rest];
        if (rest === null)
          return false;
        let bucket = this[_getBucket](rest, object);
        let index = this[_findBucketIndex](bucket, object);
        if (dart.notNull(index) < 0)
          return false;
        dart.notNull(this[_length])--;
        this[_elements] = null;
        bucket.splice(index, 1);
        return true;
      }
      clear() {
        if (dart.notNull(this[_length]) > 0) {
          this[_strings] = this[_nums] = this[_rest] = this[_elements] = null;
          this[_length] = 0;
        }
      }
      [_computeElements]() {
        if (this[_elements] !== null)
          return this[_elements];
        let result = new core.List(this[_length]);
        let index = 0;
        let strings = this[_strings];
        if (strings !== null) {
          let names = Object.getOwnPropertyNames(strings);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); dart.notNull(i)++) {
            let element = names[i];
            result[index] = element;
            dart.notNull(index)++;
          }
        }
        let nums = this[_nums];
        if (nums !== null) {
          let names = Object.getOwnPropertyNames(nums);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); dart.notNull(i)++) {
            let element = +names[i];
            result[index] = element;
            dart.notNull(index)++;
          }
        }
        let rest = this[_rest];
        if (rest !== null) {
          let names = Object.getOwnPropertyNames(rest);
          let entries = names.length;
          for (let i = 0; dart.notNull(i) < dart.notNull(entries); dart.notNull(i)++) {
            let entry = names[i];
            let bucket = rest[entry];
            let length = bucket.length;
            for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
              result[index] = bucket[i];
              dart.notNull(index)++;
            }
          }
        }
        dart.assert(index === this[_length]);
        return this[_elements] = result;
      }
      [_addHashTableEntry](table, element) {
        if (_hasTableEntry(table, element))
          return false;
        _setTableEntry(table, element, 0);
        dart.notNull(this[_length])++;
        this[_elements] = null;
        return true;
      }
      [_removeHashTableEntry](table, element) {
        if (dart.notNull(table !== null) && dart.notNull(_hasTableEntry(table, element))) {
          _deleteTableEntry(table, element);
          dart.notNull(this[_length])--;
          this[_elements] = null;
          return true;
        } else {
          return false;
        }
      }
      static [_isStringElement](element) {
        return dart.notNull(typeof element == string) && dart.notNull(!dart.equals(element, '__proto__'));
      }
      static [_isNumericElement](element) {
        return dart.notNull(dart.is(element, core.num)) && (element & 0x3ffffff) === element;
      }
      [_computeHashCode](element) {
        return dart.dload(element, 'hashCode') & 0x3ffffff;
      }
      static [_hasTableEntry](table, key) {
        let entry = table[key];
        return entry !== null;
      }
      static [_setTableEntry](table, key, value) {
        dart.assert(value !== null);
        table[key] = value;
      }
      static [_deleteTableEntry](table, key) {
        delete table[key];
      }
      [_getBucket](table, element) {
        let hash = this[_computeHashCode](element);
        return dart.as(table[hash], core.List);
      }
      [_findBucketIndex](bucket, element) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          if (dart.equals(bucket[i], element))
            return i;
        }
        return -1;
      }
      static [_newHashTable]() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _setTableEntry(table, temporaryKey, table);
        _deleteTableEntry(table, temporaryKey);
        return table;
      }
    }
    return _HashSet;
  });
  let _HashSet = _HashSet$(dynamic);
  let _IdentityHashSet$ = dart.generic(function(E) {
    class _IdentityHashSet extends _HashSet$(E) {
      [_newSet]() {
        return new _IdentityHashSet();
      }
      [_computeHashCode](key) {
        return core.identityHashCode(key) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, element) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          if (core.identical(bucket[i], element))
            return i;
        }
        return -1;
      }
    }
    return _IdentityHashSet;
  });
  let _IdentityHashSet = _IdentityHashSet$(dynamic);
  let _equality = Symbol('_equality');
  let _hasher = Symbol('_hasher');
  let _CustomHashSet$ = dart.generic(function(E) {
    class _CustomHashSet extends _HashSet$(E) {
      _CustomHashSet($_equality, $_hasher, validKey) {
        this[_equality] = $_equality;
        this[_hasher] = $_hasher;
        this[_validKey] = dart.as(validKey !== null ? validKey : (x) => dart.is(x, E), _Predicate);
        super._HashSet();
      }
      [_newSet]() {
        return new _CustomHashSet(this[_equality], this[_hasher], this[_validKey]);
      }
      [_findBucketIndex](bucket, element) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          if (this[_equality](dart.as(bucket[i], E), dart.as(element, E)))
            return i;
        }
        return -1;
      }
      [_computeHashCode](element) {
        return this[_hasher](dart.as(element, E)) & 0x3ffffff;
      }
      add(object) {
        return super._add(object);
      }
      contains(object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return super._contains(object);
      }
      lookup(object) {
        if (!dart.notNull(this[_validKey](object)))
          return null;
        return super._lookup(object);
      }
      remove(object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return super._remove(object);
      }
    }
    return _CustomHashSet;
  });
  let _CustomHashSet = _CustomHashSet$(dynamic);
  let HashSetIterator$ = dart.generic(function(E) {
    class HashSetIterator extends dart.Object {
      HashSetIterator($_set, $_elements) {
        this[_set] = $_set;
        this[_elements] = $_elements;
        this[_offset] = 0;
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        let elements = this[_elements];
        let offset = this[_offset];
        if (elements !== dart.dload(this[_set], '_elements')) {
          throw new core.ConcurrentModificationError(this[_set]);
        } else if (dart.notNull(offset) >= elements.length) {
          this[_current] = null;
          return false;
        } else {
          this[_current] = dart.as(elements[offset], E);
          this[_offset] = dart.notNull(offset) + 1;
          return true;
        }
      }
    }
    return HashSetIterator;
  });
  let HashSetIterator = HashSetIterator$(dynamic);
  let _unsupported = Symbol('_unsupported');
  let _element = Symbol('_element');
  let _filterWhere = Symbol('_filterWhere');
  let _LinkedHashSet$ = dart.generic(function(E) {
    class _LinkedHashSet extends _HashSetBase$(E) {
      _LinkedHashSet() {
        this[_length] = 0;
        this[_strings] = null;
        this[_nums] = null;
        this[_rest] = null;
        this[_first] = null;
        this[_last] = null;
        this[_modifications] = 0;
        super._HashSetBase();
      }
      [_newSet]() {
        return new _LinkedHashSet();
      }
      [_unsupported](operation) {
        throw `LinkedHashSet: unsupported ${operation}`;
      }
      get iterator() {
        return dart.as(new LinkedHashSetIterator(this, this[_modifications]), core.Iterator$(E));
      }
      get length() {
        return this[_length];
      }
      get isEmpty() {
        return this[_length] === 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      contains(object) {
        if (_isStringElement(object)) {
          let strings = this[_strings];
          if (strings === null)
            return false;
          let cell = dart.as(_getTableEntry(strings, object), LinkedHashSetCell);
          return cell !== null;
        } else if (_isNumericElement(object)) {
          let nums = this[_nums];
          if (nums === null)
            return false;
          let cell = dart.as(_getTableEntry(nums, object), LinkedHashSetCell);
          return cell !== null;
        } else {
          return this[_contains](object);
        }
      }
      [_contains](object) {
        let rest = this[_rest];
        if (rest === null)
          return false;
        let bucket = this[_getBucket](rest, object);
        return dart.notNull(this[_findBucketIndex](bucket, object)) >= 0;
      }
      lookup(object) {
        if (dart.notNull(_isStringElement(object)) || dart.notNull(_isNumericElement(object))) {
          return dart.as(this.contains(object) ? object : null, E);
        } else {
          return this[_lookup](object);
        }
      }
      [_lookup](object) {
        let rest = this[_rest];
        if (rest === null)
          return null;
        let bucket = this[_getBucket](rest, object);
        let index = this[_findBucketIndex](bucket, object);
        if (dart.notNull(index) < 0)
          return null;
        return dart.as(dart.dload(bucket.get(index), '_element'), E);
      }
      forEach(action) {
        let cell = this[_first];
        let modifications = this[_modifications];
        while (cell !== null) {
          action(dart.as(cell[_element], E));
          if (modifications !== this[_modifications]) {
            throw new core.ConcurrentModificationError(this);
          }
          cell = cell[_next];
        }
      }
      get first() {
        if (this[_first] === null)
          throw new core.StateError("No elements");
        return dart.as(this[_first][_element], E);
      }
      get last() {
        if (this[_last] === null)
          throw new core.StateError("No elements");
        return dart.as(this[_last][_element], E);
      }
      add(element) {
        if (_isStringElement(element)) {
          let strings = this[_strings];
          if (strings === null)
            this[_strings] = strings = _newHashTable();
          return this[_addHashTableEntry](strings, element);
        } else if (_isNumericElement(element)) {
          let nums = this[_nums];
          if (nums === null)
            this[_nums] = nums = _newHashTable();
          return this[_addHashTableEntry](nums, element);
        } else {
          return this[_add](element);
        }
      }
      [_add](element) {
        let rest = this[_rest];
        if (rest === null)
          this[_rest] = rest = _newHashTable();
        let hash = this[_computeHashCode](element);
        let bucket = rest[hash];
        if (bucket === null) {
          let cell = this[_newLinkedCell](element);
          _setTableEntry(rest, hash, [cell]);
        } else {
          let index = this[_findBucketIndex](bucket, element);
          if (dart.notNull(index) >= 0)
            return false;
          let cell = this[_newLinkedCell](element);
          bucket.push(cell);
        }
        return true;
      }
      remove(object) {
        if (_isStringElement(object)) {
          return this[_removeHashTableEntry](this[_strings], object);
        } else if (_isNumericElement(object)) {
          return this[_removeHashTableEntry](this[_nums], object);
        } else {
          return this[_remove](object);
        }
      }
      [_remove](object) {
        let rest = this[_rest];
        if (rest === null)
          return false;
        let bucket = this[_getBucket](rest, object);
        let index = this[_findBucketIndex](bucket, object);
        if (dart.notNull(index) < 0)
          return false;
        let cell = dart.as(bucket.splice(index, 1)[0], LinkedHashSetCell);
        this[_unlinkCell](cell);
        return true;
      }
      removeWhere(test) {
        this[_filterWhere](test, true);
      }
      retainWhere(test) {
        this[_filterWhere](test, false);
      }
      [_filterWhere](test, removeMatching) {
        let cell = this[_first];
        while (cell !== null) {
          let element = dart.as(cell[_element], E);
          let next = cell[_next];
          let modifications = this[_modifications];
          let shouldRemove = removeMatching === test(element);
          if (modifications !== this[_modifications]) {
            throw new core.ConcurrentModificationError(this);
          }
          if (shouldRemove)
            this.remove(element);
          cell = next;
        }
      }
      clear() {
        if (dart.notNull(this[_length]) > 0) {
          this[_strings] = this[_nums] = this[_rest] = this[_first] = this[_last] = null;
          this[_length] = 0;
          this[_modified]();
        }
      }
      [_addHashTableEntry](table, element) {
        let cell = dart.as(_getTableEntry(table, element), LinkedHashSetCell);
        if (cell !== null)
          return false;
        _setTableEntry(table, element, this[_newLinkedCell](element));
        return true;
      }
      [_removeHashTableEntry](table, element) {
        if (table === null)
          return false;
        let cell = dart.as(_getTableEntry(table, element), LinkedHashSetCell);
        if (cell === null)
          return false;
        this[_unlinkCell](cell);
        _deleteTableEntry(table, element);
        return true;
      }
      [_modified]() {
        this[_modifications] = dart.notNull(this[_modifications]) + 1 & 67108863;
      }
      [_newLinkedCell](element) {
        let cell = new LinkedHashSetCell(element);
        if (this[_first] === null) {
          this[_first] = this[_last] = cell;
        } else {
          let last = this[_last];
          cell[_previous] = last;
          this[_last] = last[_next] = cell;
        }
        dart.notNull(this[_length])++;
        this[_modified]();
        return cell;
      }
      [_unlinkCell](cell) {
        let previous = cell[_previous];
        let next = cell[_next];
        if (previous === null) {
          dart.assert(dart.equals(cell, this[_first]));
          this[_first] = next;
        } else {
          previous[_next] = next;
        }
        if (next === null) {
          dart.assert(dart.equals(cell, this[_last]));
          this[_last] = previous;
        } else {
          next[_previous] = previous;
        }
        dart.notNull(this[_length])--;
        this[_modified]();
      }
      static [_isStringElement](element) {
        return dart.notNull(typeof element == string) && dart.notNull(!dart.equals(element, '__proto__'));
      }
      static [_isNumericElement](element) {
        return dart.notNull(dart.is(element, core.num)) && (element & 0x3ffffff) === element;
      }
      [_computeHashCode](element) {
        return dart.dload(element, 'hashCode') & 0x3ffffff;
      }
      static [_getTableEntry](table, key) {
        return table[key];
      }
      static [_setTableEntry](table, key, value) {
        dart.assert(value !== null);
        table[key] = value;
      }
      static [_deleteTableEntry](table, key) {
        delete table[key];
      }
      [_getBucket](table, element) {
        let hash = this[_computeHashCode](element);
        return dart.as(table[hash], core.List);
      }
      [_findBucketIndex](bucket, element) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let cell = dart.as(bucket[i], LinkedHashSetCell);
          if (dart.equals(cell[_element], element))
            return i;
        }
        return -1;
      }
      static [_newHashTable]() {
        let table = Object.create(null);
        let temporaryKey = '<non-identifier-key>';
        _setTableEntry(table, temporaryKey, table);
        _deleteTableEntry(table, temporaryKey);
        return table;
      }
    }
    return _LinkedHashSet;
  });
  let _LinkedHashSet = _LinkedHashSet$(dynamic);
  let _LinkedIdentityHashSet$ = dart.generic(function(E) {
    class _LinkedIdentityHashSet extends _LinkedHashSet$(E) {
      [_newSet]() {
        return new _LinkedIdentityHashSet();
      }
      [_computeHashCode](key) {
        return core.identityHashCode(key) & 0x3ffffff;
      }
      [_findBucketIndex](bucket, element) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let cell = dart.as(bucket[i], LinkedHashSetCell);
          if (core.identical(cell[_element], element))
            return i;
        }
        return -1;
      }
    }
    return _LinkedIdentityHashSet;
  });
  let _LinkedIdentityHashSet = _LinkedIdentityHashSet$(dynamic);
  let _LinkedCustomHashSet$ = dart.generic(function(E) {
    class _LinkedCustomHashSet extends _LinkedHashSet$(E) {
      _LinkedCustomHashSet($_equality, $_hasher, validKey) {
        this[_equality] = $_equality;
        this[_hasher] = $_hasher;
        this[_validKey] = dart.as(validKey !== null ? validKey : (x) => dart.is(x, E), _Predicate);
        super._LinkedHashSet();
      }
      [_newSet]() {
        return new _LinkedCustomHashSet(this[_equality], this[_hasher], this[_validKey]);
      }
      [_findBucketIndex](bucket, element) {
        if (bucket === null)
          return -1;
        let length = bucket.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let cell = dart.as(bucket[i], LinkedHashSetCell);
          if (this[_equality](dart.as(cell[_element], E), dart.as(element, E)))
            return i;
        }
        return -1;
      }
      [_computeHashCode](element) {
        return this[_hasher](dart.as(element, E)) & 0x3ffffff;
      }
      add(element) {
        return super._add(element);
      }
      contains(object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return super._contains(object);
      }
      lookup(object) {
        if (!dart.notNull(this[_validKey](object)))
          return null;
        return super._lookup(object);
      }
      remove(object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return super._remove(object);
      }
      containsAll(elements) {
        for (let element of elements) {
          if (!dart.notNull(this[_validKey](element)) || !dart.notNull(this.contains(element)))
            return false;
        }
        return true;
      }
      removeAll(elements) {
        for (let element of elements) {
          if (this[_validKey](element)) {
            super._remove(element);
          }
        }
      }
    }
    return _LinkedCustomHashSet;
  });
  let _LinkedCustomHashSet = _LinkedCustomHashSet$(dynamic);
  class LinkedHashSetCell extends dart.Object {
    LinkedHashSetCell($_element) {
      this[_element] = $_element;
      this[_next] = null;
      this[_previous] = null;
    }
  }
  let LinkedHashSetIterator$ = dart.generic(function(E) {
    class LinkedHashSetIterator extends dart.Object {
      LinkedHashSetIterator($_set, $_modifications) {
        this[_set] = $_set;
        this[_modifications] = $_modifications;
        this[_cell] = null;
        this[_current] = null;
        this[_cell] = dart.as(dart.dload(this[_set], '_first'), LinkedHashSetCell);
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        if (this[_modifications] !== dart.dload(this[_set], '_modifications')) {
          throw new core.ConcurrentModificationError(this[_set]);
        } else if (this[_cell] === null) {
          this[_current] = null;
          return false;
        } else {
          this[_current] = dart.as(this[_cell][_element], E);
          this[_cell] = this[_cell][_next];
          return true;
        }
      }
    }
    return LinkedHashSetIterator;
  });
  let LinkedHashSetIterator = LinkedHashSetIterator$(dynamic);
  let _source = Symbol('_source');
  let UnmodifiableListView$ = dart.generic(function(E) {
    class UnmodifiableListView extends _internal.UnmodifiableListBase$(E) {
      UnmodifiableListView(source) {
        this[_source] = source;
        super.UnmodifiableListBase();
      }
      get length() {
        return this[_source].length;
      }
      get(index) {
        return this[_source].elementAt(index);
      }
    }
    return UnmodifiableListView;
  });
  let UnmodifiableListView = UnmodifiableListView$(dynamic);
  // Function _defaultEquals: (dynamic, dynamic) → bool
  function _defaultEquals(a, b) {
    return dart.equals(a, b);
  }
  // Function _defaultHashCode: (dynamic) → int
  function _defaultHashCode(a) {
    return dart.as(dart.dload(a, 'hashCode'), core.int);
  }
  let HashMap$ = dart.generic(function(K, V) {
    class HashMap extends dart.Object {
      HashMap(opt$) {
        let equals = opt$.equals === void 0 ? null : opt$.equals;
        let hashCode = opt$.hashCode === void 0 ? null : opt$.hashCode;
        let isValidKey = opt$.isValidKey === void 0 ? null : opt$.isValidKey;
        if (isValidKey === null) {
          if (hashCode === null) {
            if (equals === null) {
              return new _HashMap();
            }
            hashCode = _defaultHashCode;
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new _IdentityHashMap();
            }
            if (equals === null) {
              equals = _defaultEquals;
            }
          }
        } else {
          if (hashCode === null) {
            hashCode = _defaultHashCode;
          }
          if (equals === null) {
            equals = _defaultEquals;
          }
        }
        return new _CustomHashMap(equals, hashCode, isValidKey);
      }
      HashMap$identity() {
        return new _IdentityHashMap();
      }
      HashMap$from(other) {
        let result = new HashMap();
        other.forEach((k, v) => {
          result.set(k, dart.as(v, V));
        });
        return result;
      }
      HashMap$fromIterable(iterable, opt$) {
        let key = opt$.key === void 0 ? null : opt$.key;
        let value = opt$.value === void 0 ? null : opt$.value;
        let map = new HashMap();
        Maps._fillMapWithMappedIterable(map, iterable, key, value);
        return map;
      }
      HashMap$fromIterables(keys, values) {
        let map = new HashMap();
        Maps._fillMapWithIterables(map, keys, values);
        return map;
      }
    }
    dart.defineNamedConstructor(HashMap, 'identity');
    dart.defineNamedConstructor(HashMap, 'from');
    dart.defineNamedConstructor(HashMap, 'fromIterable');
    dart.defineNamedConstructor(HashMap, 'fromIterables');
    return HashMap;
  });
  let HashMap = HashMap$(dynamic, dynamic);
  let _HashSetBase$ = dart.generic(function(E) {
    class _HashSetBase extends SetBase$(E) {
      difference(other) {
        let result = this[_newSet]();
        for (let element of this) {
          if (!dart.notNull(other.contains(element)))
            result.add(dart.as(element, E));
        }
        return result;
      }
      intersection(other) {
        let result = this[_newSet]();
        for (let element of this) {
          if (other.contains(element))
            result.add(dart.as(element, E));
        }
        return result;
      }
      toSet() {
        return ((_) => {
          _.addAll(this);
          return _;
        }).bind(this)(this[_newSet]());
      }
    }
    return _HashSetBase;
  });
  let _HashSetBase = _HashSetBase$(dynamic);
  let HashSet$ = dart.generic(function(E) {
    class HashSet extends dart.Object {
      HashSet(opt$) {
        let equals = opt$.equals === void 0 ? null : opt$.equals;
        let hashCode = opt$.hashCode === void 0 ? null : opt$.hashCode;
        let isValidKey = opt$.isValidKey === void 0 ? null : opt$.isValidKey;
        if (isValidKey === null) {
          if (hashCode === null) {
            if (equals === null) {
              return new _HashSet();
            }
            hashCode = _defaultHashCode;
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new _IdentityHashSet();
            }
            if (equals === null) {
              equals = _defaultEquals;
            }
          }
        } else {
          if (hashCode === null) {
            hashCode = _defaultHashCode;
          }
          if (equals === null) {
            equals = _defaultEquals;
          }
        }
        return new _CustomHashSet(equals, hashCode, isValidKey);
      }
      HashSet$identity() {
        return new _IdentityHashSet();
      }
      HashSet$from(elements) {
        let result = new HashSet();
        for (let e of elements)
          result.add(e);
        return result;
      }
    }
    dart.defineNamedConstructor(HashSet, 'identity');
    dart.defineNamedConstructor(HashSet, 'from');
    return HashSet;
  });
  let HashSet = HashSet$(dynamic);
  let IterableMixin$ = dart.generic(function(E) {
    class IterableMixin extends dart.Object {
      map(f) {
        return new _internal.MappedIterable(this, f);
      }
      where(f) {
        return new _internal.WhereIterable(this, f);
      }
      expand(f) {
        return new _internal.ExpandIterable(this, f);
      }
      contains(element) {
        for (let e of this) {
          if (dart.equals(e, element))
            return true;
        }
        return false;
      }
      forEach(f) {
        for (let element of this)
          f(element);
      }
      reduce(combine) {
        let iterator = this.iterator;
        if (!dart.notNull(iterator.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let value = iterator.current;
        while (iterator.moveNext()) {
          value = combine(value, iterator.current);
        }
        return value;
      }
      fold(initialValue, combine) {
        let value = initialValue;
        for (let element of this)
          value = combine(value, element);
        return value;
      }
      every(f) {
        for (let element of this) {
          if (!dart.notNull(f(element)))
            return false;
        }
        return true;
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        let iterator = this.iterator;
        if (!dart.notNull(iterator.moveNext()))
          return "";
        let buffer = new core.StringBuffer();
        if (dart.notNull(separator === null) || dart.notNull(dart.equals(separator, ""))) {
          do {
            buffer.write(`${iterator.current}`);
          } while (iterator.moveNext());
        } else {
          buffer.write(`${iterator.current}`);
          while (iterator.moveNext()) {
            buffer.write(separator);
            buffer.write(`${iterator.current}`);
          }
        }
        return buffer.toString();
      }
      any(f) {
        for (let element of this) {
          if (f(element))
            return true;
        }
        return false;
      }
      toList(opt$) {
        let growable = opt$.growable === void 0 ? true : opt$.growable;
        return new core.List.from(this, {growable: growable});
      }
      toSet() {
        return new core.Set.from(this);
      }
      get length() {
        dart.assert(!dart.is(this, _internal.EfficientLength));
        let count = 0;
        let it = this.iterator;
        while (it.moveNext()) {
          dart.notNull(count)++;
        }
        return count;
      }
      get isEmpty() {
        return !dart.notNull(this.iterator.moveNext());
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      take(n) {
        return new _internal.TakeIterable(this, n);
      }
      takeWhile(test) {
        return new _internal.TakeWhileIterable(this, test);
      }
      skip(n) {
        return new _internal.SkipIterable(this, n);
      }
      skipWhile(test) {
        return new _internal.SkipWhileIterable(this, test);
      }
      get first() {
        let it = this.iterator;
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        return dart.as(it.current, E);
      }
      get last() {
        let it = this.iterator;
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let result = null;
        do {
          result = dart.as(it.current, E);
        } while (it.moveNext());
        return result;
      }
      get single() {
        let it = this.iterator;
        if (!dart.notNull(it.moveNext()))
          throw _internal.IterableElementError.noElement();
        let result = dart.as(it.current, E);
        if (it.moveNext())
          throw _internal.IterableElementError.tooMany();
        return result;
      }
      firstWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        for (let element of this) {
          if (test(element))
            return element;
        }
        if (orElse !== null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      lastWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        if (orElse !== null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      singleWhere(test) {
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            if (foundMatching) {
              throw _internal.IterableElementError.tooMany();
            }
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        throw _internal.IterableElementError.noElement();
      }
      elementAt(index) {
        if (!(typeof index == number))
          throw new core.ArgumentError.notNull("index");
        core.RangeError.checkNotNegative(index, "index");
        let elementIndex = 0;
        for (let element of this) {
          if (index === elementIndex)
            return element;
          dart.notNull(elementIndex)++;
        }
        throw new core.RangeError.index(index, this, "index", null, elementIndex);
      }
      toString() {
        return IterableBase.iterableToShortString(this, '(', ')');
      }
    }
    return IterableMixin;
  });
  let IterableMixin = IterableMixin$(dynamic);
  let _isToStringVisiting = Symbol('_isToStringVisiting');
  let _iterablePartsToStrings = Symbol('_iterablePartsToStrings');
  let IterableBase$ = dart.generic(function(E) {
    class IterableBase extends dart.Object {
      IterableBase() {
      }
      map(f) {
        return new _internal.MappedIterable(this, f);
      }
      where(f) {
        return new _internal.WhereIterable(this, f);
      }
      expand(f) {
        return new _internal.ExpandIterable(this, f);
      }
      contains(element) {
        for (let e of this) {
          if (dart.equals(e, element))
            return true;
        }
        return false;
      }
      forEach(f) {
        for (let element of this)
          f(element);
      }
      reduce(combine) {
        let iterator = this.iterator;
        if (!dart.notNull(iterator.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let value = iterator.current;
        while (iterator.moveNext()) {
          value = combine(value, iterator.current);
        }
        return value;
      }
      fold(initialValue, combine) {
        let value = initialValue;
        for (let element of this)
          value = combine(value, element);
        return value;
      }
      every(f) {
        for (let element of this) {
          if (!dart.notNull(f(element)))
            return false;
        }
        return true;
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        let iterator = this.iterator;
        if (!dart.notNull(iterator.moveNext()))
          return "";
        let buffer = new core.StringBuffer();
        if (dart.notNull(separator === null) || dart.notNull(dart.equals(separator, ""))) {
          do {
            buffer.write(`${iterator.current}`);
          } while (iterator.moveNext());
        } else {
          buffer.write(`${iterator.current}`);
          while (iterator.moveNext()) {
            buffer.write(separator);
            buffer.write(`${iterator.current}`);
          }
        }
        return buffer.toString();
      }
      any(f) {
        for (let element of this) {
          if (f(element))
            return true;
        }
        return false;
      }
      toList(opt$) {
        let growable = opt$.growable === void 0 ? true : opt$.growable;
        return new core.List.from(this, {growable: growable});
      }
      toSet() {
        return new core.Set.from(this);
      }
      get length() {
        dart.assert(!dart.is(this, _internal.EfficientLength));
        let count = 0;
        let it = this.iterator;
        while (it.moveNext()) {
          dart.notNull(count)++;
        }
        return count;
      }
      get isEmpty() {
        return !dart.notNull(this.iterator.moveNext());
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      take(n) {
        return new _internal.TakeIterable(this, n);
      }
      takeWhile(test) {
        return new _internal.TakeWhileIterable(this, test);
      }
      skip(n) {
        return new _internal.SkipIterable(this, n);
      }
      skipWhile(test) {
        return new _internal.SkipWhileIterable(this, test);
      }
      get first() {
        let it = this.iterator;
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        return dart.as(it.current, E);
      }
      get last() {
        let it = this.iterator;
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let result = null;
        do {
          result = dart.as(it.current, E);
        } while (it.moveNext());
        return result;
      }
      get single() {
        let it = this.iterator;
        if (!dart.notNull(it.moveNext()))
          throw _internal.IterableElementError.noElement();
        let result = dart.as(it.current, E);
        if (it.moveNext())
          throw _internal.IterableElementError.tooMany();
        return result;
      }
      firstWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        for (let element of this) {
          if (test(element))
            return element;
        }
        if (orElse !== null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      lastWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        if (orElse !== null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      singleWhere(test) {
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            if (foundMatching) {
              throw _internal.IterableElementError.tooMany();
            }
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        throw _internal.IterableElementError.noElement();
      }
      elementAt(index) {
        if (!(typeof index == number))
          throw new core.ArgumentError.notNull("index");
        core.RangeError.checkNotNegative(index, "index");
        let elementIndex = 0;
        for (let element of this) {
          if (index === elementIndex)
            return element;
          dart.notNull(elementIndex)++;
        }
        throw new core.RangeError.index(index, this, "index", null, elementIndex);
      }
      toString() {
        return iterableToShortString(this, '(', ')');
      }
      static iterableToShortString(iterable, leftDelimiter, rightDelimiter) {
        if (leftDelimiter === void 0)
          leftDelimiter = '(';
        if (rightDelimiter === void 0)
          rightDelimiter = ')';
        if (_isToStringVisiting(iterable)) {
          if (dart.notNull(dart.equals(leftDelimiter, "(")) && dart.notNull(dart.equals(rightDelimiter, ")"))) {
            return "(...)";
          }
          return `${leftDelimiter}...${rightDelimiter}`;
        }
        let parts = new List.from([]);
        _toStringVisiting.add(iterable);
        try {
          _iterablePartsToStrings(iterable, parts);
        } finally {
          dart.assert(core.identical(_toStringVisiting.last, iterable));
          _toStringVisiting.removeLast();
        }
        return ((_) => {
          _.writeAll(parts, ", ");
          _.write(rightDelimiter);
          return _;
        }).bind(this)(new core.StringBuffer(leftDelimiter)).toString();
      }
      static iterableToFullString(iterable, leftDelimiter, rightDelimiter) {
        if (leftDelimiter === void 0)
          leftDelimiter = '(';
        if (rightDelimiter === void 0)
          rightDelimiter = ')';
        if (_isToStringVisiting(iterable)) {
          return `${leftDelimiter}...${rightDelimiter}`;
        }
        let buffer = new core.StringBuffer(leftDelimiter);
        _toStringVisiting.add(iterable);
        try {
          buffer.writeAll(iterable, ", ");
        } finally {
          dart.assert(core.identical(_toStringVisiting.last, iterable));
          _toStringVisiting.removeLast();
        }
        buffer.write(rightDelimiter);
        return buffer.toString();
      }
      static [_isToStringVisiting](o) {
        for (let i = 0; dart.notNull(i) < dart.notNull(_toStringVisiting.length); dart.notNull(i)++) {
          if (core.identical(o, _toStringVisiting.get(i)))
            return true;
        }
        return false;
      }
      static [_iterablePartsToStrings](iterable, parts) {
        let LENGTH_LIMIT = 80;
        let HEAD_COUNT = 3;
        let TAIL_COUNT = 2;
        let MAX_COUNT = 100;
        let OVERHEAD = 2;
        let ELLIPSIS_SIZE = 3;
        let length = 0;
        let count = 0;
        let it = iterable.iterator;
        while (dart.notNull(length) < dart.notNull(LENGTH_LIMIT) || dart.notNull(count) < dart.notNull(HEAD_COUNT)) {
          if (!dart.notNull(it.moveNext()))
            return;
          let next = `${it.current}`;
          parts.add(next);
          length = dart.notNull(next.length) + dart.notNull(OVERHEAD);
          dart.notNull(count)++;
        }
        let penultimateString = null;
        let ultimateString = null;
        let penultimate = null;
        let ultimate = null;
        if (!dart.notNull(it.moveNext())) {
          if (dart.notNull(count) <= dart.notNull(HEAD_COUNT) + dart.notNull(TAIL_COUNT))
            return;
          ultimateString = dart.as(parts.removeLast(), core.String);
          penultimateString = dart.as(parts.removeLast(), core.String);
        } else {
          penultimate = it.current;
          dart.notNull(count)++;
          if (!dart.notNull(it.moveNext())) {
            if (dart.notNull(count) <= dart.notNull(HEAD_COUNT) + 1) {
              parts.add(`${penultimate}`);
              return;
            }
            ultimateString = `${penultimate}`;
            penultimateString = dart.as(parts.removeLast(), core.String);
            length = dart.notNull(ultimateString.length) + dart.notNull(OVERHEAD);
          } else {
            ultimate = it.current;
            dart.notNull(count)++;
            dart.assert(dart.notNull(count) < dart.notNull(MAX_COUNT));
            while (it.moveNext()) {
              penultimate = ultimate;
              ultimate = it.current;
              dart.notNull(count)++;
              if (dart.notNull(count) > dart.notNull(MAX_COUNT)) {
                while (dart.notNull(length) > dart.notNull(LENGTH_LIMIT) - dart.notNull(ELLIPSIS_SIZE) - dart.notNull(OVERHEAD) && dart.notNull(count) > dart.notNull(HEAD_COUNT)) {
                  length = dart.as(dart.dbinary(dart.dload(parts.removeLast(), 'length'), '+', OVERHEAD), core.int);
                  dart.notNull(count)--;
                }
                parts.add("...");
                return;
              }
            }
            penultimateString = `${penultimate}`;
            ultimateString = `${ultimate}`;
            length = dart.notNull(ultimateString.length) + dart.notNull(penultimateString.length) + 2 * dart.notNull(OVERHEAD);
          }
        }
        let elision = null;
        if (dart.notNull(count) > dart.notNull(parts.length) + dart.notNull(TAIL_COUNT)) {
          elision = "...";
          length = dart.notNull(ELLIPSIS_SIZE) + dart.notNull(OVERHEAD);
        }
        while (dart.notNull(length) > dart.notNull(LENGTH_LIMIT) && dart.notNull(parts.length) > dart.notNull(HEAD_COUNT)) {
          length = dart.as(dart.dbinary(dart.dload(parts.removeLast(), 'length'), '+', OVERHEAD), core.int);
          if (elision === null) {
            elision = "...";
            length = dart.notNull(ELLIPSIS_SIZE) + dart.notNull(OVERHEAD);
          }
        }
        if (elision !== null) {
          parts.add(elision);
        }
        parts.add(penultimateString);
        parts.add(ultimateString);
      }
    }
    dart.defineLazyProperties(IterableBase, {
      get _toStringVisiting() {
        return new List.from([]);
      }
    });
    return IterableBase;
  });
  let IterableBase = IterableBase$(dynamic);
  let _iterator = Symbol('_iterator');
  let _state = Symbol('_state');
  let _move = Symbol('_move');
  let HasNextIterator$ = dart.generic(function(E) {
    class HasNextIterator extends dart.Object {
      HasNextIterator($_iterator) {
        this[_iterator] = $_iterator;
        this[_state] = _NOT_MOVED_YET;
      }
      get hasNext() {
        if (this[_state] === _NOT_MOVED_YET)
          this[_move]();
        return this[_state] === _HAS_NEXT_AND_NEXT_IN_CURRENT;
      }
      next() {
        if (!dart.notNull(this.hasNext))
          throw new core.StateError("No more elements");
        dart.assert(this[_state] === _HAS_NEXT_AND_NEXT_IN_CURRENT);
        let result = dart.as(this[_iterator].current, E);
        this[_move]();
        return result;
      }
      [_move]() {
        if (this[_iterator].moveNext()) {
          this[_state] = _HAS_NEXT_AND_NEXT_IN_CURRENT;
        } else {
          this[_state] = _NO_NEXT;
        }
      }
    }
    HasNextIterator._HAS_NEXT_AND_NEXT_IN_CURRENT = 0;
    HasNextIterator._NO_NEXT = 1;
    HasNextIterator._NOT_MOVED_YET = 2;
    return HasNextIterator;
  });
  let HasNextIterator = HasNextIterator$(dynamic);
  let LinkedHashMap$ = dart.generic(function(K, V) {
    class LinkedHashMap extends dart.Object {
      LinkedHashMap(opt$) {
        let equals = opt$.equals === void 0 ? null : opt$.equals;
        let hashCode = opt$.hashCode === void 0 ? null : opt$.hashCode;
        let isValidKey = opt$.isValidKey === void 0 ? null : opt$.isValidKey;
        if (isValidKey === null) {
          if (hashCode === null) {
            if (equals === null) {
              return new _LinkedHashMap();
            }
            hashCode = _defaultHashCode;
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new _LinkedIdentityHashMap();
            }
            if (equals === null) {
              equals = _defaultEquals;
            }
          }
        } else {
          if (hashCode === null) {
            hashCode = _defaultHashCode;
          }
          if (equals === null) {
            equals = _defaultEquals;
          }
        }
        return new _LinkedCustomHashMap(equals, hashCode, isValidKey);
      }
      LinkedHashMap$identity() {
        return new _LinkedIdentityHashMap();
      }
      LinkedHashMap$from(other) {
        let result = new LinkedHashMap();
        other.forEach((k, v) => {
          result.set(k, dart.as(v, V));
        });
        return result;
      }
      LinkedHashMap$fromIterable(iterable, opt$) {
        let key = opt$.key === void 0 ? null : opt$.key;
        let value = opt$.value === void 0 ? null : opt$.value;
        let map = new LinkedHashMap();
        Maps._fillMapWithMappedIterable(map, iterable, key, value);
        return map;
      }
      LinkedHashMap$fromIterables(keys, values) {
        let map = new LinkedHashMap();
        Maps._fillMapWithIterables(map, keys, values);
        return map;
      }
      LinkedHashMap$_literal(keyValuePairs) {
        return dart.as(_js_helper.fillLiteralMap(keyValuePairs, new _LinkedHashMap()), LinkedHashMap$(K, V));
      }
      LinkedHashMap$_empty() {
        return new _LinkedHashMap();
      }
    }
    dart.defineNamedConstructor(LinkedHashMap, 'identity');
    dart.defineNamedConstructor(LinkedHashMap, 'from');
    dart.defineNamedConstructor(LinkedHashMap, 'fromIterable');
    dart.defineNamedConstructor(LinkedHashMap, 'fromIterables');
    dart.defineNamedConstructor(LinkedHashMap, '_literal');
    dart.defineNamedConstructor(LinkedHashMap, '_empty');
    return LinkedHashMap;
  });
  let LinkedHashMap = LinkedHashMap$(dynamic, dynamic);
  let LinkedHashSet$ = dart.generic(function(E) {
    class LinkedHashSet extends dart.Object {
      LinkedHashSet(opt$) {
        let equals = opt$.equals === void 0 ? null : opt$.equals;
        let hashCode = opt$.hashCode === void 0 ? null : opt$.hashCode;
        let isValidKey = opt$.isValidKey === void 0 ? null : opt$.isValidKey;
        if (isValidKey === null) {
          if (hashCode === null) {
            if (equals === null) {
              return new _LinkedHashSet();
            }
            hashCode = _defaultHashCode;
          } else {
            if (dart.notNull(core.identical(core.identityHashCode, hashCode)) && dart.notNull(core.identical(core.identical, equals))) {
              return new _LinkedIdentityHashSet();
            }
            if (equals === null) {
              equals = _defaultEquals;
            }
          }
        } else {
          if (hashCode === null) {
            hashCode = _defaultHashCode;
          }
          if (equals === null) {
            equals = _defaultEquals;
          }
        }
        return new _LinkedCustomHashSet(equals, hashCode, isValidKey);
      }
      LinkedHashSet$identity() {
        return new _LinkedIdentityHashSet();
      }
      LinkedHashSet$from(elements) {
        let result = new LinkedHashSet();
        for (let element of elements) {
          result.add(element);
        }
        return result;
      }
    }
    dart.defineNamedConstructor(LinkedHashSet, 'identity');
    dart.defineNamedConstructor(LinkedHashSet, 'from');
    return LinkedHashSet;
  });
  let LinkedHashSet = LinkedHashSet$(dynamic);
  let _modificationCount = Symbol('_modificationCount');
  let _insertAfter = Symbol('_insertAfter');
  let _list = Symbol('_list');
  let _unlink = Symbol('_unlink');
  let LinkedList$ = dart.generic(function(E) {
    class LinkedList extends IterableBase$(E) {
      LinkedList() {
        this[_modificationCount] = 0;
        this[_length] = 0;
        this[_next] = null;
        this[_previous] = null;
        super.IterableBase();
        this[_next] = this[_previous] = this;
      }
      addFirst(entry) {
        this[_insertAfter](this, entry);
      }
      add(entry) {
        this[_insertAfter](this[_previous], entry);
      }
      addAll(entries) {
        entries.forEach(((entry) => this[_insertAfter](this[_previous], dart.as(entry, E))).bind(this));
      }
      remove(entry) {
        if (!dart.equals(entry[_list], this))
          return false;
        this[_unlink](entry);
        return true;
      }
      get iterator() {
        return new _LinkedListIterator(this);
      }
      get length() {
        return this[_length];
      }
      clear() {
        dart.notNull(this[_modificationCount])++;
        let next = this[_next];
        while (!dart.notNull(core.identical(next, this))) {
          let entry = dart.as(next, E);
          next = entry[_next];
          entry[_next] = entry[_previous] = entry[_list] = null;
        }
        this[_next] = this[_previous] = this;
        this[_length] = 0;
      }
      get first() {
        if (core.identical(this[_next], this)) {
          throw new core.StateError('No such element');
        }
        return dart.as(this[_next], E);
      }
      get last() {
        if (core.identical(this[_previous], this)) {
          throw new core.StateError('No such element');
        }
        return dart.as(this[_previous], E);
      }
      get single() {
        if (core.identical(this[_previous], this)) {
          throw new core.StateError('No such element');
        }
        if (!dart.notNull(core.identical(this[_previous], this[_next]))) {
          throw new core.StateError('Too many elements');
        }
        return dart.as(this[_next], E);
      }
      forEach(action) {
        let modificationCount = this[_modificationCount];
        let current = this[_next];
        while (!dart.notNull(core.identical(current, this))) {
          action(dart.as(current, E));
          if (modificationCount !== this[_modificationCount]) {
            throw new core.ConcurrentModificationError(this);
          }
          current = current[_next];
        }
      }
      get isEmpty() {
        return this[_length] === 0;
      }
      [_insertAfter](entry, newEntry) {
        if (newEntry.list !== null) {
          throw new core.StateError('LinkedListEntry is already in a LinkedList');
        }
        dart.notNull(this[_modificationCount])++;
        newEntry[_list] = this;
        let predecessor = entry;
        let successor = entry[_next];
        successor[_previous] = newEntry;
        newEntry[_previous] = predecessor;
        newEntry[_next] = successor;
        predecessor[_next] = newEntry;
        dart.notNull(this[_length])++;
      }
      [_unlink](entry) {
        dart.notNull(this[_modificationCount])++;
        entry[_next][_previous] = entry[_previous];
        entry[_previous][_next] = entry[_next];
        dart.notNull(this[_length])--;
        entry[_list] = entry[_next] = entry[_previous] = null;
      }
    }
    return LinkedList;
  });
  let LinkedList = LinkedList$(dynamic);
  let _LinkedListIterator$ = dart.generic(function(E) {
    class _LinkedListIterator extends dart.Object {
      _LinkedListIterator(list) {
        this[_list] = list;
        this[_modificationCount] = list[_modificationCount];
        this[_next] = list[_next];
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        if (core.identical(this[_next], this[_list])) {
          this[_current] = null;
          return false;
        }
        if (this[_modificationCount] !== this[_list][_modificationCount]) {
          throw new core.ConcurrentModificationError(this);
        }
        this[_current] = dart.as(this[_next], E);
        this[_next] = this[_next][_next];
        return true;
      }
    }
    return _LinkedListIterator;
  });
  let _LinkedListIterator = _LinkedListIterator$(dynamic);
  class _LinkedListLink extends dart.Object {
    _LinkedListLink() {
      this[_next] = null;
      this[_previous] = null;
    }
  }
  let LinkedListEntry$ = dart.generic(function(E) {
    class LinkedListEntry extends dart.Object {
      LinkedListEntry() {
        this[_list] = null;
        this[_next] = null;
        this[_previous] = null;
      }
      get list() {
        return this[_list];
      }
      unlink() {
        this[_list]._unlink(this);
      }
      get next() {
        if (core.identical(this[_next], this[_list]))
          return null;
        let result = dart.as(this[_next], E);
        return result;
      }
      get previous() {
        if (core.identical(this[_previous], this[_list]))
          return null;
        return dart.as(this[_previous], E);
      }
      insertAfter(entry) {
        this[_list]._insertAfter(this, entry);
      }
      insertBefore(entry) {
        this[_list]._insertAfter(this[_previous], entry);
      }
    }
    return LinkedListEntry;
  });
  let LinkedListEntry = LinkedListEntry$(dynamic);
  let ListBase$ = dart.generic(function(E) {
    class ListBase extends dart.mixin(core.Object, ListMixin$(E)) {
      static listToString(list) {
        return IterableBase.iterableToFullString(list, '[', ']');
      }
    }
    return ListBase;
  });
  let ListBase = ListBase$(dynamic);
  let _filter = Symbol('_filter');
  let ListMixin$ = dart.generic(function(E) {
    class ListMixin extends dart.Object {
      get iterator() {
        return new _internal.ListIterator(this);
      }
      elementAt(index) {
        return this.get(index);
      }
      forEach(action) {
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          action(this.get(i));
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
      }
      get isEmpty() {
        return this.length === 0;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      get first() {
        if (this.length === 0)
          throw _internal.IterableElementError.noElement();
        return this.get(0);
      }
      get last() {
        if (this.length === 0)
          throw _internal.IterableElementError.noElement();
        return this.get(dart.notNull(this.length) - 1);
      }
      get single() {
        if (this.length === 0)
          throw _internal.IterableElementError.noElement();
        if (dart.notNull(this.length) > 1)
          throw _internal.IterableElementError.tooMany();
        return this.get(0);
      }
      contains(element) {
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); dart.notNull(i)++) {
          if (dart.equals(this.get(i), element))
            return true;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return false;
      }
      every(test) {
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          if (!dart.notNull(test(this.get(i))))
            return false;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return true;
      }
      any(test) {
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          if (test(this.get(i)))
            return true;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return false;
      }
      firstWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let element = this.get(i);
          if (test(element))
            return element;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (orElse !== null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      lastWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        let length = this.length;
        for (let i = dart.notNull(length) - 1; dart.notNull(i) >= 0; dart.notNull(i)--) {
          let element = this.get(i);
          if (test(element))
            return element;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (orElse !== null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      singleWhere(test) {
        let length = this.length;
        let match = null;
        let matchFound = false;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let element = this.get(i);
          if (test(element)) {
            if (matchFound) {
              throw _internal.IterableElementError.tooMany();
            }
            matchFound = true;
            match = element;
          }
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (matchFound)
          return match;
        throw _internal.IterableElementError.noElement();
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        if (this.length === 0)
          return "";
        let buffer = new core.StringBuffer();
        buffer.writeAll(this, separator);
        return buffer.toString();
      }
      where(test) {
        return new _internal.WhereIterable(this, test);
      }
      map(f) {
        return new _internal.MappedListIterable(this, dart.as(f, dart.throw_("Unimplemented type (dynamic) → dynamic")));
      }
      expand(f) {
        return new _internal.ExpandIterable(this, f);
      }
      reduce(combine) {
        let length = this.length;
        if (length === 0)
          throw _internal.IterableElementError.noElement();
        let value = this.get(0);
        for (let i = 1; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          value = combine(value, this.get(i));
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return value;
      }
      fold(initialValue, combine) {
        let value = initialValue;
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          value = combine(value, this.get(i));
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return value;
      }
      skip(count) {
        return new _internal.SubListIterable(this, count, null);
      }
      skipWhile(test) {
        return new _internal.SkipWhileIterable(this, test);
      }
      take(count) {
        return new _internal.SubListIterable(this, 0, count);
      }
      takeWhile(test) {
        return new _internal.TakeWhileIterable(this, test);
      }
      toList(opt$) {
        let growable = opt$.growable === void 0 ? true : opt$.growable;
        let result = null;
        if (growable) {
          result = ((_) => {
            _.length = this.length;
            return _;
          }).bind(this)(new core.List());
        } else {
          result = new core.List(this.length);
        }
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); dart.notNull(i)++) {
          result.set(i, this.get(i));
        }
        return result;
      }
      toSet() {
        let result = new core.Set();
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); dart.notNull(i)++) {
          result.add(this.get(i));
        }
        return result;
      }
      add(element) {
        this.set(dart.notNull(this.length)++, element);
      }
      addAll(iterable) {
        for (let element of iterable) {
          this.set(dart.notNull(this.length)++, element);
        }
      }
      remove(element) {
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); dart.notNull(i)++) {
          if (dart.equals(this.get(i), element)) {
            this.setRange(i, dart.notNull(this.length) - 1, this, dart.notNull(i) + 1);
            this.length = 1;
            return true;
          }
        }
        return false;
      }
      removeWhere(test) {
        _filter(this, dart.as(test, dart.throw_("Unimplemented type (dynamic) → bool")), false);
      }
      retainWhere(test) {
        _filter(this, dart.as(test, dart.throw_("Unimplemented type (dynamic) → bool")), true);
      }
      static [_filter](source, test, retainMatching) {
        let retained = new List.from([]);
        let length = source.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          let element = source.get(i);
          if (test(element) === retainMatching) {
            retained.add(element);
          }
          if (length !== source.length) {
            throw new core.ConcurrentModificationError(source);
          }
        }
        if (retained.length !== source.length) {
          source.setRange(0, retained.length, retained);
          source.length = retained.length;
        }
      }
      clear() {
        this.length = 0;
      }
      removeLast() {
        if (this.length === 0) {
          throw _internal.IterableElementError.noElement();
        }
        let result = this.get(dart.notNull(this.length) - 1);
        dart.notNull(this.length)--;
        return result;
      }
      sort(compare) {
        if (compare === void 0)
          compare = null;
        if (compare === null) {
          let defaultCompare = core.Comparable.compare;
          compare = defaultCompare;
        }
        _internal.Sort.sort(this, dart.as(compare, dart.throw_("Unimplemented type (dynamic, dynamic) → int")));
      }
      shuffle(random) {
        if (random === void 0)
          random = null;
        if (random === null)
          random = new math.Random();
        let length = this.length;
        while (dart.notNull(length) > 1) {
          let pos = random.nextInt(length);
          length = 1;
          let tmp = this.get(length);
          this.set(length, this.get(pos));
          this.set(pos, tmp);
        }
      }
      asMap() {
        return new _internal.ListMapView(this);
      }
      sublist(start, end) {
        if (end === void 0)
          end = null;
        let listLength = this.length;
        if (end === null)
          end = listLength;
        core.RangeError.checkValidRange(start, end, listLength);
        let length = dart.notNull(end) - dart.notNull(start);
        let result = new core.List();
        result.length = length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
          result.set(i, this.get(dart.notNull(start) + dart.notNull(i)));
        }
        return result;
      }
      getRange(start, end) {
        core.RangeError.checkValidRange(start, end, this.length);
        return new _internal.SubListIterable(this, start, end);
      }
      removeRange(start, end) {
        core.RangeError.checkValidRange(start, end, this.length);
        let length = dart.notNull(end) - dart.notNull(start);
        this.setRange(start, dart.notNull(this.length) - dart.notNull(length), this, end);
        this.length = length;
      }
      fillRange(start, end, fill) {
        if (fill === void 0)
          fill = null;
        core.RangeError.checkValidRange(start, end, this.length);
        for (let i = start; dart.notNull(i) < dart.notNull(end); dart.notNull(i)++) {
          this.set(i, fill);
        }
      }
      setRange(start, end, iterable, skipCount) {
        if (skipCount === void 0)
          skipCount = 0;
        core.RangeError.checkValidRange(start, end, this.length);
        let length = dart.notNull(end) - dart.notNull(start);
        if (length === 0)
          return;
        core.RangeError.checkNotNegative(skipCount, "skipCount");
        let otherList = null;
        let otherStart = null;
        if (dart.is(iterable, core.List)) {
          otherList = dart.as(iterable, core.List);
          otherStart = skipCount;
        } else {
          otherList = iterable.skip(skipCount).toList({growable: false});
          otherStart = 0;
        }
        if (dart.notNull(otherStart) + dart.notNull(length) > dart.notNull(otherList.length)) {
          throw _internal.IterableElementError.tooFew();
        }
        if (dart.notNull(otherStart) < dart.notNull(start)) {
          for (let i = dart.notNull(length) - 1; dart.notNull(i) >= 0; dart.notNull(i)--) {
            this.set(dart.notNull(start) + dart.notNull(i), dart.as(otherList.get(dart.notNull(otherStart) + dart.notNull(i)), E));
          }
        } else {
          for (let i = 0; dart.notNull(i) < dart.notNull(length); dart.notNull(i)++) {
            this.set(dart.notNull(start) + dart.notNull(i), dart.as(otherList.get(dart.notNull(otherStart) + dart.notNull(i)), E));
          }
        }
      }
      replaceRange(start, end, newContents) {
        core.RangeError.checkValidRange(start, end, this.length);
        if (!dart.is(newContents, _internal.EfficientLength)) {
          newContents = newContents.toList();
        }
        let removeLength = dart.notNull(end) - dart.notNull(start);
        let insertLength = newContents.length;
        if (dart.notNull(removeLength) >= dart.notNull(insertLength)) {
          let delta = dart.notNull(removeLength) - dart.notNull(insertLength);
          let insertEnd = dart.notNull(start) + dart.notNull(insertLength);
          let newLength = dart.notNull(this.length) - dart.notNull(delta);
          this.setRange(start, insertEnd, newContents);
          if (delta !== 0) {
            this.setRange(insertEnd, newLength, this, end);
            this.length = newLength;
          }
        } else {
          let delta = dart.notNull(insertLength) - dart.notNull(removeLength);
          let newLength = dart.notNull(this.length) + dart.notNull(delta);
          let insertEnd = dart.notNull(start) + dart.notNull(insertLength);
          this.length = newLength;
          this.setRange(insertEnd, newLength, this, end);
          this.setRange(start, insertEnd, newContents);
        }
      }
      indexOf(element, startIndex) {
        if (startIndex === void 0)
          startIndex = 0;
        if (dart.notNull(startIndex) >= dart.notNull(this.length)) {
          return -1;
        }
        if (dart.notNull(startIndex) < 0) {
          startIndex = 0;
        }
        for (let i = startIndex; dart.notNull(i) < dart.notNull(this.length); dart.notNull(i)++) {
          if (dart.equals(this.get(i), element)) {
            return i;
          }
        }
        return -1;
      }
      lastIndexOf(element, startIndex) {
        if (startIndex === void 0)
          startIndex = null;
        if (startIndex === null) {
          startIndex = dart.notNull(this.length) - 1;
        } else {
          if (dart.notNull(startIndex) < 0) {
            return -1;
          }
          if (dart.notNull(startIndex) >= dart.notNull(this.length)) {
            startIndex = dart.notNull(this.length) - 1;
          }
        }
        for (let i = startIndex; dart.notNull(i) >= 0; dart.notNull(i)--) {
          if (dart.equals(this.get(i), element)) {
            return i;
          }
        }
        return -1;
      }
      insert(index, element) {
        core.RangeError.checkValueInInterval(index, 0, this.length, "index");
        if (index === this.length) {
          this.add(element);
          return;
        }
        if (!(typeof index == number))
          throw new core.ArgumentError(index);
        dart.notNull(this.length)++;
        this.setRange(dart.notNull(index) + 1, this.length, this, index);
        this.set(index, element);
      }
      removeAt(index) {
        let result = this.get(index);
        this.setRange(index, dart.notNull(this.length) - 1, this, dart.notNull(index) + 1);
        dart.notNull(this.length)--;
        return result;
      }
      insertAll(index, iterable) {
        core.RangeError.checkValueInInterval(index, 0, this.length, "index");
        if (dart.is(iterable, _internal.EfficientLength)) {
          iterable = iterable.toList();
        }
        let insertionLength = iterable.length;
        this.length = insertionLength;
        this.setRange(dart.notNull(index) + dart.notNull(insertionLength), this.length, this, index);
        this.setAll(index, iterable);
      }
      setAll(index, iterable) {
        if (dart.is(iterable, core.List)) {
          this.setRange(index, dart.notNull(index) + dart.notNull(iterable.length), iterable);
        } else {
          for (let element of iterable) {
            this.set(dart.notNull(index)++, element);
          }
        }
      }
      get reversed() {
        return new _internal.ReversedListIterable(this);
      }
      toString() {
        return IterableBase.iterableToFullString(this, '[', ']');
      }
    }
    return ListMixin;
  });
  let ListMixin = ListMixin$(dynamic);
  let MapBase$ = dart.generic(function(K, V) {
    class MapBase extends dart.mixin(MapMixin$(K, V)) {
    }
    return MapBase;
  });
  let MapBase = MapBase$(dynamic, dynamic);
  let MapMixin$ = dart.generic(function(K, V) {
    class MapMixin extends dart.Object {
      forEach(action) {
        for (let key of this.keys) {
          action(key, this.get(key));
        }
      }
      addAll(other) {
        for (let key of other.keys) {
          this.set(key, other.get(key));
        }
      }
      containsValue(value) {
        for (let key of this.keys) {
          if (dart.equals(this.get(key), value))
            return true;
        }
        return false;
      }
      putIfAbsent(key, ifAbsent) {
        if (this.keys.contains(key)) {
          return this.get(key);
        }
        return this.set(key, ifAbsent());
      }
      containsKey(key) {
        return this.keys.contains(key);
      }
      get length() {
        return this.keys.length;
      }
      get isEmpty() {
        return this.keys.isEmpty;
      }
      get isNotEmpty() {
        return this.keys.isNotEmpty;
      }
      get values() {
        return new _MapBaseValueIterable(this);
      }
      toString() {
        return Maps.mapToString(this);
      }
    }
    return MapMixin;
  });
  let MapMixin = MapMixin$(dynamic, dynamic);
  let UnmodifiableMapBase$ = dart.generic(function(K, V) {
    class UnmodifiableMapBase extends dart.mixin(_UnmodifiableMapMixin$(K, V)) {
    }
    return UnmodifiableMapBase;
  });
  let UnmodifiableMapBase = UnmodifiableMapBase$(dynamic, dynamic);
  let _MapBaseValueIterable$ = dart.generic(function(V) {
    class _MapBaseValueIterable extends IterableBase$(V) {
      _MapBaseValueIterable($_map) {
        this[_map] = $_map;
        super.IterableBase();
      }
      get length() {
        return this[_map].length;
      }
      get isEmpty() {
        return this[_map].isEmpty;
      }
      get isNotEmpty() {
        return this[_map].isNotEmpty;
      }
      get first() {
        return dart.as(this[_map].get(this[_map].keys.first), V);
      }
      get single() {
        return dart.as(this[_map].get(this[_map].keys.single), V);
      }
      get last() {
        return dart.as(this[_map].get(this[_map].keys.last), V);
      }
      get iterator() {
        return new _MapBaseValueIterator(this[_map]);
      }
    }
    return _MapBaseValueIterable;
  });
  let _MapBaseValueIterable = _MapBaseValueIterable$(dynamic);
  let _MapBaseValueIterator$ = dart.generic(function(V) {
    class _MapBaseValueIterator extends dart.Object {
      _MapBaseValueIterator(map) {
        this[_map] = map;
        this[_keys] = map.keys.iterator;
        this[_current] = null;
      }
      moveNext() {
        if (this[_keys].moveNext()) {
          this[_current] = dart.as(this[_map].get(this[_keys].current), V);
          return true;
        }
        this[_current] = null;
        return false;
      }
      get current() {
        return this[_current];
      }
    }
    return _MapBaseValueIterator;
  });
  let _MapBaseValueIterator = _MapBaseValueIterator$(dynamic);
  let _UnmodifiableMapMixin$ = dart.generic(function(K, V) {
    class _UnmodifiableMapMixin extends dart.Object {
      set(key, value) {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      addAll(other) {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      clear() {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      remove(key) {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
      putIfAbsent(key, ifAbsent) {
        throw new core.UnsupportedError("Cannot modify unmodifiable map");
      }
    }
    return _UnmodifiableMapMixin;
  });
  let _UnmodifiableMapMixin = _UnmodifiableMapMixin$(dynamic, dynamic);
  let MapView$ = dart.generic(function(K, V) {
    class MapView extends dart.Object {
      MapView(map) {
        this[_map] = map;
      }
      get(key) {
        return this[_map].get(key);
      }
      set(key, value) {
        this[_map].set(key, value);
      }
      addAll(other) {
        this[_map].addAll(other);
      }
      clear() {
        this[_map].clear();
      }
      putIfAbsent(key, ifAbsent) {
        return this[_map].putIfAbsent(key, ifAbsent);
      }
      containsKey(key) {
        return this[_map].containsKey(key);
      }
      containsValue(value) {
        return this[_map].containsValue(value);
      }
      forEach(action) {
        this[_map].forEach(action);
      }
      get isEmpty() {
        return this[_map].isEmpty;
      }
      get isNotEmpty() {
        return this[_map].isNotEmpty;
      }
      get length() {
        return this[_map].length;
      }
      get keys() {
        return this[_map].keys;
      }
      remove(key) {
        return this[_map].remove(key);
      }
      toString() {
        return this[_map].toString();
      }
      get values() {
        return this[_map].values;
      }
    }
    return MapView;
  });
  let MapView = MapView$(dynamic, dynamic);
  let UnmodifiableMapView$ = dart.generic(function(K, V) {
    class UnmodifiableMapView extends dart.mixin(_UnmodifiableMapMixin$(K, V)) {
    }
    return UnmodifiableMapView;
  });
  let UnmodifiableMapView = UnmodifiableMapView$(dynamic, dynamic);
  let _toStringVisiting = Symbol('_toStringVisiting');
  let _id = Symbol('_id');
  let _fillMapWithMappedIterable = Symbol('_fillMapWithMappedIterable');
  let _fillMapWithIterables = Symbol('_fillMapWithIterables');
  class Maps extends dart.Object {
    static containsValue(map, value) {
      for (let v of map.values) {
        if (dart.equals(value, v)) {
          return true;
        }
      }
      return false;
    }
    static containsKey(map, key) {
      for (let k of map.keys) {
        if (dart.equals(key, k)) {
          return true;
        }
      }
      return false;
    }
    static putIfAbsent(map, key, ifAbsent) {
      if (map.containsKey(key)) {
        return map.get(key);
      }
      let v = ifAbsent();
      map.set(key, v);
      return v;
    }
    static clear(map) {
      for (let k of map.keys.toList()) {
        map.remove(k);
      }
    }
    static forEach(map, f) {
      for (let k of map.keys) {
        f(k, map.get(k));
      }
    }
    static getValues(map) {
      return map.keys.map((key) => map.get(key));
    }
    static length(map) {
      return map.keys.length;
    }
    static isEmpty(map) {
      return map.keys.isEmpty;
    }
    static isNotEmpty(map) {
      return map.keys.isNotEmpty;
    }
    static mapToString(m) {
      if (IterableBase._isToStringVisiting(m)) {
        return '{...}';
      }
      let result = new core.StringBuffer();
      try {
        IterableBase[_toStringVisiting].add(m);
        result.write('{');
        let first = true;
        m.forEach(((k, v) => {
          if (!dart.notNull(first)) {
            result.write(', ');
          }
          first = false;
          result.write(k);
          result.write(': ');
          result.write(v);
        }).bind(this));
        result.write('}');
      } finally {
        dart.assert(core.identical(IterableBase[_toStringVisiting].last, m));
        IterableBase[_toStringVisiting].removeLast();
      }
      return result.toString();
    }
    static [_id](x) {
      return x;
    }
    static [_fillMapWithMappedIterable](map, iterable, key, value) {
      if (key === null)
        key = _id;
      if (value === null)
        value = _id;
      for (let element of iterable) {
        map.set(key(element), value(element));
      }
    }
    static [_fillMapWithIterables](map, keys, values) {
      let keyIterator = keys.iterator;
      let valueIterator = values.iterator;
      let hasNextKey = keyIterator.moveNext();
      let hasNextValue = valueIterator.moveNext();
      while (dart.notNull(hasNextKey) && dart.notNull(hasNextValue)) {
        map.set(keyIterator.current, valueIterator.current);
        hasNextKey = keyIterator.moveNext();
        hasNextValue = valueIterator.moveNext();
      }
      if (dart.notNull(hasNextKey) || dart.notNull(hasNextValue)) {
        throw new core.ArgumentError("Iterables do not have same length.");
      }
    }
  }
  let Queue$ = dart.generic(function(E) {
    class Queue extends dart.Object {
      Queue() {
        return new ListQueue();
      }
      Queue$from(elements) {
        return new ListQueue.from(elements);
      }
    }
    dart.defineNamedConstructor(Queue, 'from');
    return Queue;
  });
  let Queue = Queue$(dynamic);
  let _link = Symbol('_link');
  let _asNonSentinelEntry = Symbol('_asNonSentinelEntry');
  let DoubleLinkedQueueEntry$ = dart.generic(function(E) {
    class DoubleLinkedQueueEntry extends dart.Object {
      DoubleLinkedQueueEntry(e) {
        this[_element] = e;
        this[_previous] = null;
        this[_next] = null;
      }
      [_link](previous, next) {
        this[_next] = next;
        this[_previous] = previous;
        previous[_next] = this;
        next[_previous] = this;
      }
      append(e) {
        new DoubleLinkedQueueEntry(e)._link(this, this[_next]);
      }
      prepend(e) {
        new DoubleLinkedQueueEntry(e)._link(this[_previous], this);
      }
      remove() {
        this[_previous][_next] = this[_next];
        this[_next][_previous] = this[_previous];
        this[_next] = null;
        this[_previous] = null;
        return this[_element];
      }
      [_asNonSentinelEntry]() {
        return this;
      }
      previousEntry() {
        return this[_previous]._asNonSentinelEntry();
      }
      nextEntry() {
        return this[_next]._asNonSentinelEntry();
      }
      get element() {
        return this[_element];
      }
      set element(e) {
        this[_element] = e;
      }
    }
    return DoubleLinkedQueueEntry;
  });
  let DoubleLinkedQueueEntry = DoubleLinkedQueueEntry$(dynamic);
  let _DoubleLinkedQueueEntrySentinel$ = dart.generic(function(E) {
    class _DoubleLinkedQueueEntrySentinel extends DoubleLinkedQueueEntry$(E) {
      _DoubleLinkedQueueEntrySentinel() {
        super.DoubleLinkedQueueEntry(null);
        this[_link](this, this);
      }
      remove() {
        throw _internal.IterableElementError.noElement();
      }
      [_asNonSentinelEntry]() {
        return null;
      }
      set element(e) {
        dart.assert(false);
      }
      get element() {
        throw _internal.IterableElementError.noElement();
      }
    }
    return _DoubleLinkedQueueEntrySentinel;
  });
  let _DoubleLinkedQueueEntrySentinel = _DoubleLinkedQueueEntrySentinel$(dynamic);
  let _sentinel = Symbol('_sentinel');
  let _elementCount = Symbol('_elementCount');
  let DoubleLinkedQueue$ = dart.generic(function(E) {
    class DoubleLinkedQueue extends IterableBase$(E) {
      DoubleLinkedQueue() {
        this[_sentinel] = null;
        this[_elementCount] = 0;
        super.IterableBase();
        this[_sentinel] = new _DoubleLinkedQueueEntrySentinel();
      }
      DoubleLinkedQueue$from(elements) {
        let list = dart.as(new DoubleLinkedQueue(), Queue$(E));
        for (let e of elements) {
          list.addLast(e);
        }
        return dart.as(list, DoubleLinkedQueue$(E));
      }
      get length() {
        return this[_elementCount];
      }
      addLast(value) {
        this[_sentinel].prepend(value);
        dart.notNull(this[_elementCount])++;
      }
      addFirst(value) {
        this[_sentinel].append(value);
        dart.notNull(this[_elementCount])++;
      }
      add(value) {
        this[_sentinel].prepend(value);
        dart.notNull(this[_elementCount])++;
      }
      addAll(iterable) {
        for (let value of iterable) {
          this[_sentinel].prepend(value);
          dart.notNull(this[_elementCount])++;
        }
      }
      removeLast() {
        let result = this[_sentinel][_previous].remove();
        dart.notNull(this[_elementCount])--;
        return result;
      }
      removeFirst() {
        let result = this[_sentinel][_next].remove();
        dart.notNull(this[_elementCount])--;
        return result;
      }
      remove(o) {
        let entry = this[_sentinel][_next];
        while (!dart.notNull(core.identical(entry, this[_sentinel]))) {
          if (dart.equals(entry.element, o)) {
            entry.remove();
            dart.notNull(this[_elementCount])--;
            return true;
          }
          entry = entry[_next];
        }
        return false;
      }
      [_filter](test, removeMatching) {
        let entry = this[_sentinel][_next];
        while (!dart.notNull(core.identical(entry, this[_sentinel]))) {
          let next = entry[_next];
          if (core.identical(removeMatching, test(entry.element))) {
            entry.remove();
            dart.notNull(this[_elementCount])--;
          }
          entry = next;
        }
      }
      removeWhere(test) {
        this[_filter](test, true);
      }
      retainWhere(test) {
        this[_filter](test, false);
      }
      get first() {
        return this[_sentinel][_next].element;
      }
      get last() {
        return this[_sentinel][_previous].element;
      }
      get single() {
        if (core.identical(this[_sentinel][_next], this[_sentinel][_previous])) {
          return this[_sentinel][_next].element;
        }
        throw _internal.IterableElementError.tooMany();
      }
      lastEntry() {
        return this[_sentinel].previousEntry();
      }
      firstEntry() {
        return this[_sentinel].nextEntry();
      }
      get isEmpty() {
        return core.identical(this[_sentinel][_next], this[_sentinel]);
      }
      clear() {
        this[_sentinel][_next] = this[_sentinel];
        this[_sentinel][_previous] = this[_sentinel];
        this[_elementCount] = 0;
      }
      forEachEntry(f) {
        let entry = this[_sentinel][_next];
        while (!dart.notNull(core.identical(entry, this[_sentinel]))) {
          let nextEntry = entry[_next];
          f(entry);
          entry = nextEntry;
        }
      }
      get iterator() {
        return new _DoubleLinkedQueueIterator(this[_sentinel]);
      }
      toString() {
        return IterableBase.iterableToFullString(this, '{', '}');
      }
    }
    dart.defineNamedConstructor(DoubleLinkedQueue, 'from');
    return DoubleLinkedQueue;
  });
  let DoubleLinkedQueue = DoubleLinkedQueue$(dynamic);
  let _nextEntry = Symbol('_nextEntry');
  let _DoubleLinkedQueueIterator$ = dart.generic(function(E) {
    class _DoubleLinkedQueueIterator extends dart.Object {
      _DoubleLinkedQueueIterator(sentinel) {
        this[_sentinel] = sentinel;
        this[_nextEntry] = sentinel[_next];
        this[_current] = null;
      }
      moveNext() {
        if (!dart.notNull(core.identical(this[_nextEntry], this[_sentinel]))) {
          this[_current] = this[_nextEntry][_element];
          this[_nextEntry] = this[_nextEntry][_next];
          return true;
        }
        this[_current] = null;
        this[_nextEntry] = this[_sentinel] = null;
        return false;
      }
      get current() {
        return this[_current];
      }
    }
    return _DoubleLinkedQueueIterator;
  });
  let _DoubleLinkedQueueIterator = _DoubleLinkedQueueIterator$(dynamic);
  let _head = Symbol('_head');
  let _tail = Symbol('_tail');
  let _table = Symbol('_table');
  let _checkModification = Symbol('_checkModification');
  let _writeToList = Symbol('_writeToList');
  let _preGrow = Symbol('_preGrow');
  let _grow = Symbol('_grow');
  let _isPowerOf2 = Symbol('_isPowerOf2');
  let _nextPowerOf2 = Symbol('_nextPowerOf2');
  let ListQueue$ = dart.generic(function(E) {
    class ListQueue extends IterableBase$(E) {
      ListQueue(initialCapacity) {
        if (initialCapacity === void 0)
          initialCapacity = null;
        this[_head] = 0;
        this[_tail] = 0;
        this[_table] = null;
        this[_modificationCount] = 0;
        super.IterableBase();
        if (initialCapacity === null || dart.notNull(initialCapacity) < dart.notNull(_INITIAL_CAPACITY)) {
          initialCapacity = _INITIAL_CAPACITY;
        } else if (!dart.notNull(_isPowerOf2(initialCapacity))) {
          initialCapacity = _nextPowerOf2(initialCapacity);
        }
        dart.assert(_isPowerOf2(initialCapacity));
        this[_table] = new core.List(initialCapacity);
      }
      ListQueue$from(elements) {
        if (dart.is(elements, core.List)) {
          let length = elements.length;
          let queue = dart.as(new ListQueue(dart.notNull(length) + 1), ListQueue$(E));
          dart.assert(dart.notNull(queue[_table].length) > dart.notNull(length));
          let sourceList = elements;
          queue[_table].setRange(0, length, dart.as(sourceList, core.Iterable$(E)), 0);
          queue[_tail] = length;
          return queue;
        } else {
          let capacity = _INITIAL_CAPACITY;
          if (dart.is(elements, _internal.EfficientLength)) {
            capacity = elements.length;
          }
          let result = new ListQueue(capacity);
          for (let element of elements) {
            result.addLast(element);
          }
          return result;
        }
      }
      get iterator() {
        return new _ListQueueIterator(this);
      }
      forEach(action) {
        let modificationCount = this[_modificationCount];
        for (let i = this[_head]; i !== this[_tail]; i = dart.notNull(i) + 1 & dart.notNull(this[_table].length) - 1) {
          action(this[_table].get(i));
          this[_checkModification](modificationCount);
        }
      }
      get isEmpty() {
        return this[_head] === this[_tail];
      }
      get length() {
        return dart.notNull(this[_tail]) - dart.notNull(this[_head]) & dart.notNull(this[_table].length) - 1;
      }
      get first() {
        if (this[_head] === this[_tail])
          throw _internal.IterableElementError.noElement();
        return this[_table].get(this[_head]);
      }
      get last() {
        if (this[_head] === this[_tail])
          throw _internal.IterableElementError.noElement();
        return this[_table].get(dart.notNull(this[_tail]) - 1 & dart.notNull(this[_table].length) - 1);
      }
      get single() {
        if (this[_head] === this[_tail])
          throw _internal.IterableElementError.noElement();
        if (dart.notNull(this.length) > 1)
          throw _internal.IterableElementError.tooMany();
        return this[_table].get(this[_head]);
      }
      elementAt(index) {
        core.RangeError.checkValidIndex(index, this);
        return this[_table].get(dart.notNull(this[_head]) + dart.notNull(index) & dart.notNull(this[_table].length) - 1);
      }
      toList(opt$) {
        let growable = opt$.growable === void 0 ? true : opt$.growable;
        let list = null;
        if (growable) {
          list = ((_) => {
            _.length = this.length;
            return _;
          }).bind(this)(new core.List());
        } else {
          list = new core.List(this.length);
        }
        this[_writeToList](list);
        return list;
      }
      add(element) {
        this[_add](element);
      }
      addAll(elements) {
        if (dart.is(elements, core.List)) {
          let list = dart.as(elements, core.List);
          let addCount = list.length;
          let length = this.length;
          if (dart.notNull(length) + dart.notNull(addCount) >= dart.notNull(this[_table].length)) {
            this[_preGrow](dart.notNull(length) + dart.notNull(addCount));
            this[_table].setRange(length, dart.notNull(length) + dart.notNull(addCount), dart.as(list, core.Iterable$(E)), 0);
            this[_tail] = addCount;
          } else {
            let endSpace = dart.notNull(this[_table].length) - dart.notNull(this[_tail]);
            if (dart.notNull(addCount) < dart.notNull(endSpace)) {
              this[_table].setRange(this[_tail], dart.notNull(this[_tail]) + dart.notNull(addCount), dart.as(list, core.Iterable$(E)), 0);
              this[_tail] = addCount;
            } else {
              let preSpace = dart.notNull(addCount) - dart.notNull(endSpace);
              this[_table].setRange(this[_tail], dart.notNull(this[_tail]) + dart.notNull(endSpace), dart.as(list, core.Iterable$(E)), 0);
              this[_table].setRange(0, preSpace, dart.as(list, core.Iterable$(E)), endSpace);
              this[_tail] = preSpace;
            }
          }
          dart.notNull(this[_modificationCount])++;
        } else {
          for (let element of elements)
            this[_add](element);
        }
      }
      remove(object) {
        for (let i = this[_head]; i !== this[_tail]; i = dart.notNull(i) + 1 & dart.notNull(this[_table].length) - 1) {
          let element = this[_table].get(i);
          if (dart.equals(element, object)) {
            this[_remove](i);
            dart.notNull(this[_modificationCount])++;
            return true;
          }
        }
        return false;
      }
      [_filterWhere](test, removeMatching) {
        let index = this[_head];
        let modificationCount = this[_modificationCount];
        let i = this[_head];
        while (i !== this[_tail]) {
          let element = this[_table].get(i);
          let remove = core.identical(removeMatching, test(element));
          this[_checkModification](modificationCount);
          if (remove) {
            i = this[_remove](i);
            modificationCount = ++dart.notNull(this[_modificationCount]);
          } else {
            i = dart.notNull(i) + 1 & dart.notNull(this[_table].length) - 1;
          }
        }
      }
      removeWhere(test) {
        this[_filterWhere](test, true);
      }
      retainWhere(test) {
        this[_filterWhere](test, false);
      }
      clear() {
        if (this[_head] !== this[_tail]) {
          for (let i = this[_head]; i !== this[_tail]; i = dart.notNull(i) + 1 & dart.notNull(this[_table].length) - 1) {
            this[_table].set(i, null);
          }
          this[_head] = this[_tail] = 0;
          dart.notNull(this[_modificationCount])++;
        }
      }
      toString() {
        return IterableBase.iterableToFullString(this, "{", "}");
      }
      addLast(element) {
        this[_add](element);
      }
      addFirst(element) {
        this[_head] = dart.notNull(this[_head]) - 1 & dart.notNull(this[_table].length) - 1;
        this[_table].set(this[_head], element);
        if (this[_head] === this[_tail])
          this[_grow]();
        dart.notNull(this[_modificationCount])++;
      }
      removeFirst() {
        if (this[_head] === this[_tail])
          throw _internal.IterableElementError.noElement();
        dart.notNull(this[_modificationCount])++;
        let result = this[_table].get(this[_head]);
        this[_table].set(this[_head], null);
        this[_head] = dart.notNull(this[_head]) + 1 & dart.notNull(this[_table].length) - 1;
        return result;
      }
      removeLast() {
        if (this[_head] === this[_tail])
          throw _internal.IterableElementError.noElement();
        dart.notNull(this[_modificationCount])++;
        this[_tail] = dart.notNull(this[_tail]) - 1 & dart.notNull(this[_table].length) - 1;
        let result = this[_table].get(this[_tail]);
        this[_table].set(this[_tail], null);
        return result;
      }
      static [_isPowerOf2](number) {
        return (dart.notNull(number) & dart.notNull(number) - 1) === 0;
      }
      static [_nextPowerOf2](number) {
        dart.assert(dart.notNull(number) > 0);
        number = (dart.notNull(number) << 1) - 1;
        for (;;) {
          let nextNumber = dart.notNull(number) & dart.notNull(number) - 1;
          if (nextNumber === 0)
            return number;
          number = nextNumber;
        }
      }
      [_checkModification](expectedModificationCount) {
        if (expectedModificationCount !== this[_modificationCount]) {
          throw new core.ConcurrentModificationError(this);
        }
      }
      [_add](element) {
        this[_table].set(this[_tail], element);
        this[_tail] = dart.notNull(this[_tail]) + 1 & dart.notNull(this[_table].length) - 1;
        if (this[_head] === this[_tail])
          this[_grow]();
        dart.notNull(this[_modificationCount])++;
      }
      [_remove](offset) {
        let mask = dart.notNull(this[_table].length) - 1;
        let startDistance = dart.notNull(offset) - dart.notNull(this[_head]) & dart.notNull(mask);
        let endDistance = dart.notNull(this[_tail]) - dart.notNull(offset) & dart.notNull(mask);
        if (dart.notNull(startDistance) < dart.notNull(endDistance)) {
          let i = offset;
          while (i !== this[_head]) {
            let prevOffset = dart.notNull(i) - 1 & dart.notNull(mask);
            this[_table].set(i, this[_table].get(prevOffset));
            i = prevOffset;
          }
          this[_table].set(this[_head], null);
          this[_head] = dart.notNull(this[_head]) + 1 & dart.notNull(mask);
          return dart.notNull(offset) + 1 & dart.notNull(mask);
        } else {
          this[_tail] = dart.notNull(this[_tail]) - 1 & dart.notNull(mask);
          let i = offset;
          while (i !== this[_tail]) {
            let nextOffset = dart.notNull(i) + 1 & dart.notNull(mask);
            this[_table].set(i, this[_table].get(nextOffset));
            i = nextOffset;
          }
          this[_table].set(this[_tail], null);
          return offset;
        }
      }
      [_grow]() {
        let newTable = new core.List(dart.notNull(this[_table].length) * 2);
        let split = dart.notNull(this[_table].length) - dart.notNull(this[_head]);
        newTable.setRange(0, split, this[_table], this[_head]);
        newTable.setRange(split, dart.notNull(split) + dart.notNull(this[_head]), this[_table], 0);
        this[_head] = 0;
        this[_tail] = this[_table].length;
        this[_table] = newTable;
      }
      [_writeToList](target) {
        dart.assert(dart.notNull(target.length) >= dart.notNull(this.length));
        if (dart.notNull(this[_head]) <= dart.notNull(this[_tail])) {
          let length = dart.notNull(this[_tail]) - dart.notNull(this[_head]);
          target.setRange(0, length, this[_table], this[_head]);
          return length;
        } else {
          let firstPartSize = dart.notNull(this[_table].length) - dart.notNull(this[_head]);
          target.setRange(0, firstPartSize, this[_table], this[_head]);
          target.setRange(firstPartSize, dart.notNull(firstPartSize) + dart.notNull(this[_tail]), this[_table], 0);
          return dart.notNull(this[_tail]) + dart.notNull(firstPartSize);
        }
      }
      [_preGrow](newElementCount) {
        dart.assert(dart.notNull(newElementCount) >= dart.notNull(this.length));
        newElementCount = dart.notNull(newElementCount) >> 1;
        let newCapacity = _nextPowerOf2(newElementCount);
        let newTable = new core.List(newCapacity);
        this[_tail] = this[_writeToList](newTable);
        this[_table] = newTable;
        this[_head] = 0;
      }
    }
    dart.defineNamedConstructor(ListQueue, 'from');
    ListQueue._INITIAL_CAPACITY = 8;
    return ListQueue;
  });
  let ListQueue = ListQueue$(dynamic);
  let _queue = Symbol('_queue');
  let _end = Symbol('_end');
  let _position = Symbol('_position');
  let _ListQueueIterator$ = dart.generic(function(E) {
    class _ListQueueIterator extends dart.Object {
      _ListQueueIterator(queue) {
        this[_queue] = queue;
        this[_end] = queue[_tail];
        this[_modificationCount] = queue[_modificationCount];
        this[_position] = queue[_head];
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        this[_queue]._checkModification(this[_modificationCount]);
        if (this[_position] === this[_end]) {
          this[_current] = null;
          return false;
        }
        this[_current] = dart.as(this[_queue][_table].get(this[_position]), E);
        this[_position] = dart.notNull(this[_position]) + 1 & dart.notNull(this[_queue][_table].length) - 1;
        return true;
      }
    }
    return _ListQueueIterator;
  });
  let _ListQueueIterator = _ListQueueIterator$(dynamic);
  let SetMixin$ = dart.generic(function(E) {
    class SetMixin extends dart.Object {
      get isEmpty() {
        return this.length === 0;
      }
      get isNotEmpty() {
        return this.length !== 0;
      }
      clear() {
        this.removeAll(this.toList());
      }
      addAll(elements) {
        for (let element of elements)
          this.add(element);
      }
      removeAll(elements) {
        for (let element of elements)
          this.remove(element);
      }
      retainAll(elements) {
        let toRemove = this.toSet();
        for (let o of elements) {
          toRemove.remove(o);
        }
        this.removeAll(toRemove);
      }
      removeWhere(test) {
        let toRemove = new List.from([]);
        for (let element of this) {
          if (test(element))
            toRemove.add(element);
        }
        this.removeAll(dart.as(toRemove, core.Iterable$(core.Object)));
      }
      retainWhere(test) {
        let toRemove = new List.from([]);
        for (let element of this) {
          if (!dart.notNull(test(element)))
            toRemove.add(element);
        }
        this.removeAll(dart.as(toRemove, core.Iterable$(core.Object)));
      }
      containsAll(other) {
        for (let o of other) {
          if (!dart.notNull(this.contains(o)))
            return false;
        }
        return true;
      }
      union(other) {
        return ((_) => {
          _.addAll(other);
          return _;
        }).bind(this)(this.toSet());
      }
      intersection(other) {
        let result = this.toSet();
        for (let element of this) {
          if (!dart.notNull(other.contains(element)))
            result.remove(element);
        }
        return result;
      }
      difference(other) {
        let result = this.toSet();
        for (let element of this) {
          if (other.contains(element))
            result.remove(element);
        }
        return result;
      }
      toList(opt$) {
        let growable = opt$.growable === void 0 ? true : opt$.growable;
        let result = growable ? ((_) => {
          _.length = this.length;
          return _;
        }).bind(this)(new core.List()) : new core.List(this.length);
        let i = 0;
        for (let element of this)
          result.set(dart.notNull(i)++, element);
        return result;
      }
      map(f) {
        return new _internal.EfficientLengthMappedIterable(this, f);
      }
      get single() {
        if (dart.notNull(this.length) > 1)
          throw _internal.IterableElementError.tooMany();
        let it = this.iterator;
        if (!dart.notNull(it.moveNext()))
          throw _internal.IterableElementError.noElement();
        let result = dart.as(it.current, E);
        return result;
      }
      toString() {
        return IterableBase.iterableToFullString(this, '{', '}');
      }
      where(f) {
        return new _internal.WhereIterable(this, f);
      }
      expand(f) {
        return new _internal.ExpandIterable(this, f);
      }
      forEach(f) {
        for (let element of this)
          f(element);
      }
      reduce(combine) {
        let iterator = this.iterator;
        if (!dart.notNull(iterator.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let value = iterator.current;
        while (iterator.moveNext()) {
          value = combine(value, iterator.current);
        }
        return value;
      }
      fold(initialValue, combine) {
        let value = initialValue;
        for (let element of this)
          value = combine(value, element);
        return value;
      }
      every(f) {
        for (let element of this) {
          if (!dart.notNull(f(element)))
            return false;
        }
        return true;
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        let iterator = this.iterator;
        if (!dart.notNull(iterator.moveNext()))
          return "";
        let buffer = new core.StringBuffer();
        if (dart.notNull(separator === null) || dart.notNull(dart.equals(separator, ""))) {
          do {
            buffer.write(`${iterator.current}`);
          } while (iterator.moveNext());
        } else {
          buffer.write(`${iterator.current}`);
          while (iterator.moveNext()) {
            buffer.write(separator);
            buffer.write(`${iterator.current}`);
          }
        }
        return buffer.toString();
      }
      any(test) {
        for (let element of this) {
          if (test(element))
            return true;
        }
        return false;
      }
      take(n) {
        return new _internal.TakeIterable(this, n);
      }
      takeWhile(test) {
        return new _internal.TakeWhileIterable(this, test);
      }
      skip(n) {
        return new _internal.SkipIterable(this, n);
      }
      skipWhile(test) {
        return new _internal.SkipWhileIterable(this, test);
      }
      get first() {
        let it = this.iterator;
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        return dart.as(it.current, E);
      }
      get last() {
        let it = this.iterator;
        if (!dart.notNull(it.moveNext())) {
          throw _internal.IterableElementError.noElement();
        }
        let result = null;
        do {
          result = dart.as(it.current, E);
        } while (it.moveNext());
        return result;
      }
      firstWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        for (let element of this) {
          if (test(element))
            return element;
        }
        if (orElse !== null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      lastWhere(test, opt$) {
        let orElse = opt$.orElse === void 0 ? null : opt$.orElse;
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        if (orElse !== null)
          return orElse();
        throw _internal.IterableElementError.noElement();
      }
      singleWhere(test) {
        let result = null;
        let foundMatching = false;
        for (let element of this) {
          if (test(element)) {
            if (foundMatching) {
              throw _internal.IterableElementError.tooMany();
            }
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        throw _internal.IterableElementError.noElement();
      }
      elementAt(index) {
        if (!(typeof index == number))
          throw new core.ArgumentError.notNull("index");
        core.RangeError.checkNotNegative(index, "index");
        let elementIndex = 0;
        for (let element of this) {
          if (index === elementIndex)
            return element;
          dart.notNull(elementIndex)++;
        }
        throw new core.RangeError.index(index, this, "index", null, elementIndex);
      }
    }
    return SetMixin;
  });
  let SetMixin = SetMixin$(dynamic);
  let SetBase$ = dart.generic(function(E) {
    class SetBase extends SetMixin$(E) {
      static setToString(set) {
        return IterableBase.iterableToFullString(set, '{', '}');
      }
    }
    return SetBase;
  });
  let SetBase = SetBase$(dynamic);
  let _SplayTreeNode$ = dart.generic(function(K) {
    class _SplayTreeNode extends dart.Object {
      _SplayTreeNode(key) {
        this.key = key;
        this.left = null;
        this.right = null;
      }
    }
    return _SplayTreeNode;
  });
  let _SplayTreeNode = _SplayTreeNode$(dynamic);
  let _SplayTreeMapNode$ = dart.generic(function(K, V) {
    class _SplayTreeMapNode extends _SplayTreeNode$(K) {
      _SplayTreeMapNode(key, value) {
        this.value = value;
        super._SplayTreeNode(key);
      }
    }
    return _SplayTreeMapNode;
  });
  let _SplayTreeMapNode = _SplayTreeMapNode$(dynamic, dynamic);
  let _dummy = Symbol('_dummy');
  let _root = Symbol('_root');
  let _count = Symbol('_count');
  let _splayCount = Symbol('_splayCount');
  let _splay = Symbol('_splay');
  let _compare = Symbol('_compare');
  let _splayMin = Symbol('_splayMin');
  let _splayMax = Symbol('_splayMax');
  let _addNewRoot = Symbol('_addNewRoot');
  let _clear = Symbol('_clear');
  let _SplayTree$ = dart.generic(function(K) {
    class _SplayTree extends dart.Object {
      _SplayTree() {
        this[_dummy] = new _SplayTreeNode(null);
        this[_root] = null;
        this[_count] = 0;
        this[_modificationCount] = 0;
        this[_splayCount] = 0;
      }
      [_splay](key) {
        if (this[_root] === null)
          return -1;
        let left = this[_dummy];
        let right = this[_dummy];
        let current = this[_root];
        let comp = null;
        while (true) {
          comp = this[_compare](current.key, key);
          if (dart.notNull(comp) > 0) {
            if (current.left === null)
              break;
            comp = this[_compare](current.left.key, key);
            if (dart.notNull(comp) > 0) {
              let tmp = current.left;
              current.left = tmp.right;
              tmp.right = current;
              current = tmp;
              if (current.left === null)
                break;
            }
            right.left = current;
            right = current;
            current = current.left;
          } else if (dart.notNull(comp) < 0) {
            if (current.right === null)
              break;
            comp = this[_compare](current.right.key, key);
            if (dart.notNull(comp) < 0) {
              let tmp = current.right;
              current.right = tmp.left;
              tmp.left = current;
              current = tmp;
              if (current.right === null)
                break;
            }
            left.right = current;
            left = current;
            current = current.right;
          } else {
            break;
          }
        }
        left.right = current.left;
        right.left = current.right;
        current.left = this[_dummy].right;
        current.right = this[_dummy].left;
        this[_root] = current;
        this[_dummy].right = null;
        this[_dummy].left = null;
        dart.notNull(this[_splayCount])++;
        return comp;
      }
      [_splayMin](node) {
        let current = node;
        while (current.left !== null) {
          let left = current.left;
          current.left = left.right;
          left.right = current;
          current = left;
        }
        return dart.as(current, _SplayTreeNode$(K));
      }
      [_splayMax](node) {
        let current = node;
        while (current.right !== null) {
          let right = current.right;
          current.right = right.left;
          right.left = current;
          current = right;
        }
        return dart.as(current, _SplayTreeNode$(K));
      }
      [_remove](key) {
        if (this[_root] === null)
          return null;
        let comp = this[_splay](key);
        if (comp !== 0)
          return null;
        let result = this[_root];
        dart.notNull(this[_count])--;
        if (this[_root].left === null) {
          this[_root] = this[_root].right;
        } else {
          let right = this[_root].right;
          this[_root] = this[_splayMax](this[_root].left);
          this[_root].right = right;
        }
        dart.notNull(this[_modificationCount])++;
        return result;
      }
      [_addNewRoot](node, comp) {
        dart.notNull(this[_count])++;
        dart.notNull(this[_modificationCount])++;
        if (this[_root] === null) {
          this[_root] = node;
          return;
        }
        if (dart.notNull(comp) < 0) {
          node.left = this[_root];
          node.right = this[_root].right;
          this[_root].right = null;
        } else {
          node.right = this[_root];
          node.left = this[_root].left;
          this[_root].left = null;
        }
        this[_root] = node;
      }
      get [_first]() {
        if (this[_root] === null)
          return null;
        this[_root] = this[_splayMin](this[_root]);
        return this[_root];
      }
      get [_last]() {
        if (this[_root] === null)
          return null;
        this[_root] = this[_splayMax](this[_root]);
        return this[_root];
      }
      [_clear]() {
        this[_root] = null;
        this[_count] = 0;
        dart.notNull(this[_modificationCount])++;
      }
    }
    return _SplayTree;
  });
  let _SplayTree = _SplayTree$(dynamic);
  let _TypeTest$ = dart.generic(function(T) {
    class _TypeTest extends dart.Object {
      test(v) {
        return dart.is(v, T);
      }
    }
    return _TypeTest;
  });
  let _TypeTest = _TypeTest$(dynamic);
  let _comparator = Symbol('_comparator');
  let SplayTreeMap$ = dart.generic(function(K, V) {
    class SplayTreeMap extends _SplayTree$(K) {
      SplayTreeMap(compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        this[_comparator] = dart.as(compare === null ? core.Comparable.compare : compare, core.Comparator);
        this[_validKey] = dart.as(isValidKey !== null ? isValidKey : (v) => dart.is(v, K), _Predicate);
        super._SplayTree();
      }
      SplayTreeMap$from(other, compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        let result = new SplayTreeMap();
        other.forEach((k, v) => {
          result.set(k, dart.as(v, V));
        });
        return result;
      }
      SplayTreeMap$fromIterable(iterable, opt$) {
        let key = opt$.key === void 0 ? null : opt$.key;
        let value = opt$.value === void 0 ? null : opt$.value;
        let compare = opt$.compare === void 0 ? null : opt$.compare;
        let isValidKey = opt$.isValidKey === void 0 ? null : opt$.isValidKey;
        let map = new SplayTreeMap(compare, isValidKey);
        Maps._fillMapWithMappedIterable(map, iterable, key, value);
        return map;
      }
      SplayTreeMap$fromIterables(keys, values, compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        let map = new SplayTreeMap(compare, isValidKey);
        Maps._fillMapWithIterables(map, keys, values);
        return map;
      }
      [_compare](key1, key2) {
        return this[_comparator](key1, key2);
      }
      SplayTreeMap$_internal() {
        this[_comparator] = null;
        this[_validKey] = null;
        super._SplayTree();
      }
      get(key) {
        if (key === null)
          throw new core.ArgumentError(key);
        if (!dart.notNull(this[_validKey](key)))
          return null;
        if (this[_root] !== null) {
          let comp = this[_splay](dart.as(key, K));
          if (comp === 0) {
            let mapRoot = dart.as(this[_root], _SplayTreeMapNode);
            return dart.as(mapRoot.value, V);
          }
        }
        return null;
      }
      remove(key) {
        if (!dart.notNull(this[_validKey](key)))
          return null;
        let mapRoot = dart.as(this[_remove](dart.as(key, K)), _SplayTreeMapNode);
        if (mapRoot !== null)
          return dart.as(mapRoot.value, V);
        return null;
      }
      set(key, value) {
        if (key === null)
          throw new core.ArgumentError(key);
        let comp = this[_splay](key);
        if (comp === 0) {
          let mapRoot = dart.as(this[_root], _SplayTreeMapNode);
          mapRoot.value = value;
          return;
        }
        this[_addNewRoot](dart.as(new _SplayTreeMapNode(key, value), _SplayTreeNode$(K)), comp);
      }
      putIfAbsent(key, ifAbsent) {
        if (key === null)
          throw new core.ArgumentError(key);
        let comp = this[_splay](key);
        if (comp === 0) {
          let mapRoot = dart.as(this[_root], _SplayTreeMapNode);
          return dart.as(mapRoot.value, V);
        }
        let modificationCount = this[_modificationCount];
        let splayCount = this[_splayCount];
        let value = ifAbsent();
        if (modificationCount !== this[_modificationCount]) {
          throw new core.ConcurrentModificationError(this);
        }
        if (splayCount !== this[_splayCount]) {
          comp = this[_splay](key);
          dart.assert(comp !== 0);
        }
        this[_addNewRoot](dart.as(new _SplayTreeMapNode(key, value), _SplayTreeNode$(K)), comp);
        return value;
      }
      addAll(other) {
        other.forEach(((key, value) => {
          this.set(key, value);
        }).bind(this));
      }
      get isEmpty() {
        return this[_root] === null;
      }
      get isNotEmpty() {
        return !dart.notNull(this.isEmpty);
      }
      forEach(f) {
        let nodes = new _SplayTreeNodeIterator(this);
        while (nodes.moveNext()) {
          let node = dart.as(nodes.current, _SplayTreeMapNode$(K, V));
          f(node.key, node.value);
        }
      }
      get length() {
        return this[_count];
      }
      clear() {
        this[_clear]();
      }
      containsKey(key) {
        return dart.notNull(this[_validKey](key)) && this[_splay](dart.as(key, K)) === 0;
      }
      containsValue(value) {
        let found = false;
        let initialSplayCount = this[_splayCount];
        // Function visit: (_SplayTreeMapNode<dynamic, dynamic>) → bool
        function visit(node) {
          while (node !== null) {
            if (dart.equals(node.value, value))
              return true;
            if (initialSplayCount !== this[_splayCount]) {
              throw new core.ConcurrentModificationError(this);
            }
            if (dart.notNull(node.right !== null) && dart.notNull(visit(dart.as(node.right, _SplayTreeMapNode))))
              return true;
            node = dart.as(node.left, _SplayTreeMapNode);
          }
          return false;
        }
        return visit(dart.as(this[_root], _SplayTreeMapNode));
      }
      get keys() {
        return new _SplayTreeKeyIterable(this);
      }
      get values() {
        return new _SplayTreeValueIterable(this);
      }
      toString() {
        return Maps.mapToString(this);
      }
      firstKey() {
        if (this[_root] === null)
          return null;
        return dart.as(this[_first].key, K);
      }
      lastKey() {
        if (this[_root] === null)
          return null;
        return dart.as(this[_last].key, K);
      }
      lastKeyBefore(key) {
        if (key === null)
          throw new core.ArgumentError(key);
        if (this[_root] === null)
          return null;
        let comp = this[_splay](key);
        if (dart.notNull(comp) < 0)
          return this[_root].key;
        let node = this[_root].left;
        if (node === null)
          return null;
        while (node.right !== null) {
          node = node.right;
        }
        return node.key;
      }
      firstKeyAfter(key) {
        if (key === null)
          throw new core.ArgumentError(key);
        if (this[_root] === null)
          return null;
        let comp = this[_splay](key);
        if (dart.notNull(comp) > 0)
          return this[_root].key;
        let node = this[_root].right;
        if (node === null)
          return null;
        while (node.left !== null) {
          node = node.left;
        }
        return node.key;
      }
    }
    dart.defineNamedConstructor(SplayTreeMap, 'from');
    dart.defineNamedConstructor(SplayTreeMap, 'fromIterable');
    dart.defineNamedConstructor(SplayTreeMap, 'fromIterables');
    dart.defineNamedConstructor(SplayTreeMap, '_internal');
    return SplayTreeMap;
  });
  let SplayTreeMap = SplayTreeMap$(dynamic, dynamic);
  let _workList = Symbol('_workList');
  let _tree = Symbol('_tree');
  let _currentNode = Symbol('_currentNode');
  let _findLeftMostDescendent = Symbol('_findLeftMostDescendent');
  let _getValue = Symbol('_getValue');
  let _rebuildWorkList = Symbol('_rebuildWorkList');
  let _SplayTreeIterator$ = dart.generic(function(T) {
    class _SplayTreeIterator extends dart.Object {
      _SplayTreeIterator(tree) {
        this[_workList] = new List.from([]);
        this[_tree] = tree;
        this[_modificationCount] = tree[_modificationCount];
        this[_splayCount] = tree[_splayCount];
        this[_currentNode] = null;
        this[_findLeftMostDescendent](tree[_root]);
      }
      _SplayTreeIterator$startAt(tree, startKey) {
        this[_workList] = new List.from([]);
        this[_tree] = tree;
        this[_modificationCount] = tree[_modificationCount];
        this[_splayCount] = null;
        this[_currentNode] = null;
        if (tree[_root] === null)
          return;
        let compare = tree._splay(startKey);
        this[_splayCount] = tree[_splayCount];
        if (dart.notNull(compare) < 0) {
          this[_findLeftMostDescendent](tree[_root].right);
        } else {
          this[_workList].add(tree[_root]);
        }
      }
      get current() {
        if (this[_currentNode] === null)
          return null;
        return this[_getValue](this[_currentNode]);
      }
      [_findLeftMostDescendent](node) {
        while (node !== null) {
          this[_workList].add(node);
          node = node.left;
        }
      }
      [_rebuildWorkList](currentNode) {
        dart.assert(!dart.notNull(this[_workList].isEmpty));
        this[_workList].clear();
        if (currentNode === null) {
          this[_findLeftMostDescendent](this[_tree][_root]);
        } else {
          this[_tree]._splay(currentNode.key);
          this[_findLeftMostDescendent](this[_tree][_root].right);
          dart.assert(!dart.notNull(this[_workList].isEmpty));
        }
      }
      moveNext() {
        if (this[_modificationCount] !== this[_tree][_modificationCount]) {
          throw new core.ConcurrentModificationError(this[_tree]);
        }
        if (this[_workList].isEmpty) {
          this[_currentNode] = null;
          return false;
        }
        if (this[_tree][_splayCount] !== this[_splayCount] && dart.notNull(this[_currentNode] !== null)) {
          this[_rebuildWorkList](this[_currentNode]);
        }
        this[_currentNode] = this[_workList].removeLast();
        this[_findLeftMostDescendent](this[_currentNode].right);
        return true;
      }
    }
    dart.defineNamedConstructor(_SplayTreeIterator, 'startAt');
    return _SplayTreeIterator;
  });
  let _SplayTreeIterator = _SplayTreeIterator$(dynamic);
  let _SplayTreeKeyIterable$ = dart.generic(function(K) {
    class _SplayTreeKeyIterable extends IterableBase$(K) {
      _SplayTreeKeyIterable($_tree) {
        this[_tree] = $_tree;
        super.IterableBase();
      }
      get length() {
        return this[_tree][_count];
      }
      get isEmpty() {
        return this[_tree][_count] === 0;
      }
      get iterator() {
        return new _SplayTreeKeyIterator(this[_tree]);
      }
      toSet() {
        let setOrMap = this[_tree];
        let set = new SplayTreeSet(dart.as(setOrMap[_comparator], dart.throw_("Unimplemented type (K, K) → int")), dart.as(setOrMap[_validKey], dart.throw_("Unimplemented type (dynamic) → bool")));
        set[_count] = this[_tree][_count];
        set[_root] = set._copyNode(this[_tree][_root]);
        return set;
      }
    }
    return _SplayTreeKeyIterable;
  });
  let _SplayTreeKeyIterable = _SplayTreeKeyIterable$(dynamic);
  let _SplayTreeValueIterable$ = dart.generic(function(K, V) {
    class _SplayTreeValueIterable extends IterableBase$(V) {
      _SplayTreeValueIterable($_map) {
        this[_map] = $_map;
        super.IterableBase();
      }
      get length() {
        return this[_map][_count];
      }
      get isEmpty() {
        return this[_map][_count] === 0;
      }
      get iterator() {
        return new _SplayTreeValueIterator(this[_map]);
      }
    }
    return _SplayTreeValueIterable;
  });
  let _SplayTreeValueIterable = _SplayTreeValueIterable$(dynamic, dynamic);
  let _SplayTreeKeyIterator$ = dart.generic(function(K) {
    class _SplayTreeKeyIterator extends _SplayTreeIterator$(K) {
      _SplayTreeKeyIterator(map) {
        super._SplayTreeIterator(map);
      }
      [_getValue](node) {
        return dart.as(node.key, K);
      }
    }
    return _SplayTreeKeyIterator;
  });
  let _SplayTreeKeyIterator = _SplayTreeKeyIterator$(dynamic);
  let _SplayTreeValueIterator$ = dart.generic(function(K, V) {
    class _SplayTreeValueIterator extends _SplayTreeIterator$(V) {
      _SplayTreeValueIterator(map) {
        super._SplayTreeIterator(map);
      }
      [_getValue](node) {
        return dart.as(node.value, V);
      }
    }
    return _SplayTreeValueIterator;
  });
  let _SplayTreeValueIterator = _SplayTreeValueIterator$(dynamic, dynamic);
  let _SplayTreeNodeIterator$ = dart.generic(function(K) {
    class _SplayTreeNodeIterator extends _SplayTreeIterator$(_SplayTreeNode$(K)) {
      _SplayTreeNodeIterator(tree) {
        super._SplayTreeIterator(tree);
      }
      _SplayTreeNodeIterator$startAt(tree, startKey) {
        super._SplayTreeIterator$startAt(tree, startKey);
      }
      [_getValue](node) {
        return dart.as(node, _SplayTreeNode$(K));
      }
    }
    dart.defineNamedConstructor(_SplayTreeNodeIterator, 'startAt');
    return _SplayTreeNodeIterator;
  });
  let _SplayTreeNodeIterator = _SplayTreeNodeIterator$(dynamic);
  let _clone = Symbol('_clone');
  let _copyNode = Symbol('_copyNode');
  let SplayTreeSet$ = dart.generic(function(E) {
    class SplayTreeSet extends dart.mixin(_SplayTree$(E), IterableMixin$(E), SetMixin$(E)) {
      SplayTreeSet(compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        this[_comparator] = dart.as(compare === null ? core.Comparable.compare : compare, core.Comparator);
        this[_validKey] = dart.as(isValidKey !== null ? isValidKey : (v) => dart.is(v, E), _Predicate);
        super._SplayTree();
      }
      SplayTreeSet$from(elements, compare, isValidKey) {
        if (compare === void 0)
          compare = null;
        if (isValidKey === void 0)
          isValidKey = null;
        let result = new SplayTreeSet(compare, isValidKey);
        for (let element of elements) {
          result.add(element);
        }
        return result;
      }
      [_compare](e1, e2) {
        return this[_comparator](e1, e2);
      }
      get iterator() {
        return new _SplayTreeKeyIterator(this);
      }
      get length() {
        return this[_count];
      }
      get isEmpty() {
        return this[_root] === null;
      }
      get isNotEmpty() {
        return this[_root] !== null;
      }
      get first() {
        if (this[_count] === 0)
          throw _internal.IterableElementError.noElement();
        return dart.as(this[_first].key, E);
      }
      get last() {
        if (this[_count] === 0)
          throw _internal.IterableElementError.noElement();
        return dart.as(this[_last].key, E);
      }
      get single() {
        if (this[_count] === 0)
          throw _internal.IterableElementError.noElement();
        if (dart.notNull(this[_count]) > 1)
          throw _internal.IterableElementError.tooMany();
        return this[_root].key;
      }
      contains(object) {
        return dart.notNull(this[_validKey](object)) && this[_splay](dart.as(object, E)) === 0;
      }
      add(element) {
        let compare = this[_splay](element);
        if (compare === 0)
          return false;
        this[_addNewRoot](dart.as(new _SplayTreeNode(element), _SplayTreeNode$(E)), compare);
        return true;
      }
      remove(object) {
        if (!dart.notNull(this[_validKey](object)))
          return false;
        return this[_remove](dart.as(object, E)) !== null;
      }
      addAll(elements) {
        for (let element of elements) {
          let compare = this[_splay](element);
          if (compare !== 0) {
            this[_addNewRoot](dart.as(new _SplayTreeNode(element), _SplayTreeNode$(E)), compare);
          }
        }
      }
      removeAll(elements) {
        for (let element of elements) {
          if (this[_validKey](element))
            this[_remove](dart.as(element, E));
        }
      }
      retainAll(elements) {
        let retainSet = new SplayTreeSet(this[_comparator], this[_validKey]);
        let modificationCount = this[_modificationCount];
        for (let object of elements) {
          if (modificationCount !== this[_modificationCount]) {
            throw new core.ConcurrentModificationError(this);
          }
          if (dart.notNull(this[_validKey](object)) && this[_splay](dart.as(object, E)) === 0)
            retainSet.add(this[_root].key);
        }
        if (retainSet[_count] !== this[_count]) {
          this[_root] = retainSet[_root];
          this[_count] = retainSet[_count];
          dart.notNull(this[_modificationCount])++;
        }
      }
      lookup(object) {
        if (!dart.notNull(this[_validKey](object)))
          return null;
        let comp = this[_splay](dart.as(object, E));
        if (comp !== 0)
          return null;
        return this[_root].key;
      }
      intersection(other) {
        let result = new SplayTreeSet(this[_comparator], this[_validKey]);
        for (let element of this) {
          if (other.contains(element))
            result.add(element);
        }
        return result;
      }
      difference(other) {
        let result = new SplayTreeSet(this[_comparator], this[_validKey]);
        for (let element of this) {
          if (!dart.notNull(other.contains(element)))
            result.add(element);
        }
        return result;
      }
      union(other) {
        return ((_) => {
          _.addAll(other);
          return _;
        }).bind(this)(this[_clone]());
      }
      [_clone]() {
        let set = new SplayTreeSet(this[_comparator], this[_validKey]);
        set[_count] = this[_count];
        set[_root] = this[_copyNode](this[_root]);
        return set;
      }
      [_copyNode](node) {
        if (node === null)
          return null;
        return ((_) => {
          _.left = this[_copyNode](node.left);
          _.right = this[_copyNode](node.right);
          return _;
        }).bind(this)(new _SplayTreeNode(node.key));
      }
      clear() {
        this[_clear]();
      }
      toSet() {
        return this[_clone]();
      }
      toString() {
        return IterableBase.iterableToFullString(this, '{', '}');
      }
    }
    dart.defineNamedConstructor(SplayTreeSet, 'from');
    return SplayTreeSet;
  });
  let SplayTreeSet = SplayTreeSet$(dynamic);
  // Exports:
  exports.HashMapKeyIterable = HashMapKeyIterable;
  exports.HashMapKeyIterable$ = HashMapKeyIterable$;
  exports.HashMapKeyIterator = HashMapKeyIterator;
  exports.HashMapKeyIterator$ = HashMapKeyIterator$;
  exports.LinkedHashMapCell = LinkedHashMapCell;
  exports.LinkedHashMapKeyIterable = LinkedHashMapKeyIterable;
  exports.LinkedHashMapKeyIterable$ = LinkedHashMapKeyIterable$;
  exports.LinkedHashMapKeyIterator = LinkedHashMapKeyIterator;
  exports.LinkedHashMapKeyIterator$ = LinkedHashMapKeyIterator$;
  exports.HashSetIterator = HashSetIterator;
  exports.HashSetIterator$ = HashSetIterator$;
  exports.LinkedHashSetCell = LinkedHashSetCell;
  exports.LinkedHashSetIterator = LinkedHashSetIterator;
  exports.LinkedHashSetIterator$ = LinkedHashSetIterator$;
  exports.UnmodifiableListView = UnmodifiableListView;
  exports.UnmodifiableListView$ = UnmodifiableListView$;
  exports.HashMap = HashMap;
  exports.HashMap$ = HashMap$;
  exports.HashSet = HashSet;
  exports.HashSet$ = HashSet$;
  exports.IterableMixin = IterableMixin;
  exports.IterableMixin$ = IterableMixin$;
  exports.IterableBase = IterableBase;
  exports.IterableBase$ = IterableBase$;
  exports.HasNextIterator = HasNextIterator;
  exports.HasNextIterator$ = HasNextIterator$;
  exports.LinkedHashMap = LinkedHashMap;
  exports.LinkedHashMap$ = LinkedHashMap$;
  exports.LinkedHashSet = LinkedHashSet;
  exports.LinkedHashSet$ = LinkedHashSet$;
  exports.LinkedList = LinkedList;
  exports.LinkedList$ = LinkedList$;
  exports.LinkedListEntry = LinkedListEntry;
  exports.LinkedListEntry$ = LinkedListEntry$;
  exports.ListBase = ListBase;
  exports.ListBase$ = ListBase$;
  exports.ListMixin = ListMixin;
  exports.ListMixin$ = ListMixin$;
  exports.MapBase = MapBase;
  exports.MapBase$ = MapBase$;
  exports.MapMixin = MapMixin;
  exports.MapMixin$ = MapMixin$;
  exports.UnmodifiableMapBase = UnmodifiableMapBase;
  exports.UnmodifiableMapBase$ = UnmodifiableMapBase$;
  exports.MapView = MapView;
  exports.MapView$ = MapView$;
  exports.UnmodifiableMapView = UnmodifiableMapView;
  exports.UnmodifiableMapView$ = UnmodifiableMapView$;
  exports.Maps = Maps;
  exports.Queue = Queue;
  exports.Queue$ = Queue$;
  exports.DoubleLinkedQueueEntry = DoubleLinkedQueueEntry;
  exports.DoubleLinkedQueueEntry$ = DoubleLinkedQueueEntry$;
  exports.DoubleLinkedQueue = DoubleLinkedQueue;
  exports.DoubleLinkedQueue$ = DoubleLinkedQueue$;
  exports.ListQueue = ListQueue;
  exports.ListQueue$ = ListQueue$;
  exports.SetMixin = SetMixin;
  exports.SetMixin$ = SetMixin$;
  exports.SetBase = SetBase;
  exports.SetBase$ = SetBase$;
  exports.SplayTreeMap = SplayTreeMap;
  exports.SplayTreeMap$ = SplayTreeMap$;
  exports.SplayTreeSet = SplayTreeSet;
  exports.SplayTreeSet$ = SplayTreeSet$;
})(collection || (collection = {}));
