dart_library.library('collection/src/queue_list', null, /* Imports */[
  "dart/_runtime",
  'dart/core',
  'dart/collection'
], /* Lazy imports */[
], function(exports, dart, core, collection) {
  'use strict';
  let dartx = dart.dartx;
  const _head = Symbol('_head');
  const _tail = Symbol('_tail');
  const _table = Symbol('_table');
  const _add = Symbol('_add');
  const _preGrow = Symbol('_preGrow');
  const _grow = Symbol('_grow');
  const _writeToList = Symbol('_writeToList');
  const QueueList$ = dart.generic(function(E) {
    class QueueList extends dart.mixin(core.Object, collection.ListMixin$(E)) {
      QueueList(initialCapacity) {
        if (initialCapacity === void 0)
          initialCapacity = null;
        this[_head] = 0;
        this[_tail] = 0;
        this[_table] = null;
        if (initialCapacity == null || dart.notNull(initialCapacity) < dart.notNull(QueueList$()._INITIAL_CAPACITY)) {
          initialCapacity = QueueList$()._INITIAL_CAPACITY;
        } else if (!dart.notNull(QueueList$()._isPowerOf2(initialCapacity))) {
          initialCapacity = QueueList$()._nextPowerOf2(initialCapacity);
        }
        dart.assert(QueueList$()._isPowerOf2(initialCapacity));
        this[_table] = core.List$(E).new(initialCapacity);
      }
      static from(source) {
        if (dart.is(source, core.List)) {
          let length = source[dartx.length];
          let queue = new (QueueList$(E))(dart.notNull(length) + 1);
          dart.assert(dart.notNull(queue[_table][dartx.length]) > dart.notNull(length));
          let sourceList = dart.as(source, core.List);
          queue[_table][dartx.setRange](0, length, dart.as(sourceList, core.Iterable$(E)), 0);
          queue[_tail] = length;
          return queue;
        } else {
          let _ = new (QueueList$(E))();
          _.addAll(source);
          return _;
        }
      }
      add(element) {
        dart.as(element, E);
        this[_add](element);
      }
      addAll(elements) {
        dart.as(elements, core.Iterable$(E));
        if (dart.is(elements, core.List)) {
          let list = dart.as(elements, core.List);
          let addCount = list[dartx.length];
          let length = this.length;
          if (dart.notNull(length) + dart.notNull(addCount) >= dart.notNull(this[_table][dartx.length])) {
            this[_preGrow](dart.notNull(length) + dart.notNull(addCount));
            this[_table][dartx.setRange](length, dart.notNull(length) + dart.notNull(addCount), dart.as(list, core.Iterable$(E)), 0);
            this[_tail] = dart.notNull(this[_tail]) + dart.notNull(addCount);
          } else {
            let endSpace = dart.notNull(this[_table][dartx.length]) - dart.notNull(this[_tail]);
            if (dart.notNull(addCount) < dart.notNull(endSpace)) {
              this[_table][dartx.setRange](this[_tail], dart.notNull(this[_tail]) + dart.notNull(addCount), dart.as(list, core.Iterable$(E)), 0);
              this[_tail] = dart.notNull(this[_tail]) + dart.notNull(addCount);
            } else {
              let preSpace = dart.notNull(addCount) - dart.notNull(endSpace);
              this[_table][dartx.setRange](this[_tail], dart.notNull(this[_tail]) + dart.notNull(endSpace), dart.as(list, core.Iterable$(E)), 0);
              this[_table][dartx.setRange](0, preSpace, dart.as(list, core.Iterable$(E)), endSpace);
              this[_tail] = preSpace;
            }
          }
        } else {
          for (let element of elements)
            this[_add](element);
        }
      }
      toString() {
        return collection.IterableBase.iterableToFullString(this, "{", "}");
      }
      addLast(element) {
        dart.as(element, E);
        this[_add](element);
      }
      addFirst(element) {
        dart.as(element, E);
        this[_head] = dart.notNull(this[_head]) - 1 & dart.notNull(this[_table][dartx.length]) - 1;
        this[_table][dartx.set](this[_head], element);
        if (this[_head] == this[_tail])
          this[_grow]();
      }
      removeFirst() {
        if (this[_head] == this[_tail])
          dart.throw(new core.StateError("No element"));
        let result = this[_table][dartx.get](this[_head]);
        this[_table][dartx.set](this[_head], null);
        this[_head] = dart.notNull(this[_head]) + 1 & dart.notNull(this[_table][dartx.length]) - 1;
        return result;
      }
      removeLast() {
        if (this[_head] == this[_tail])
          dart.throw(new core.StateError("No element"));
        this[_tail] = dart.notNull(this[_tail]) - 1 & dart.notNull(this[_table][dartx.length]) - 1;
        let result = this[_table][dartx.get](this[_tail]);
        this[_table][dartx.set](this[_tail], null);
        return result;
      }
      get length() {
        return dart.notNull(this[_tail]) - dart.notNull(this[_head]) & dart.notNull(this[_table][dartx.length]) - 1;
      }
      set length(value) {
        if (dart.notNull(value) < 0)
          dart.throw(new core.RangeError(`Length ${value} may not be negative.`));
        let delta = dart.notNull(value) - dart.notNull(this.length);
        if (dart.notNull(delta) >= 0) {
          if (dart.notNull(this[_table][dartx.length]) <= dart.notNull(value)) {
            this[_preGrow](value);
          }
          this[_tail] = dart.notNull(this[_tail]) + dart.notNull(delta) & dart.notNull(this[_table][dartx.length]) - 1;
          return;
        }
        let newTail = dart.notNull(this[_tail]) + dart.notNull(delta);
        if (dart.notNull(newTail) >= 0) {
          this[_table][dartx.fillRange](newTail, this[_tail], null);
        } else {
          newTail = dart.notNull(newTail) + dart.notNull(this[_table][dartx.length]);
          this[_table][dartx.fillRange](0, this[_tail], null);
          this[_table][dartx.fillRange](newTail, this[_table][dartx.length], null);
        }
        this[_tail] = newTail;
      }
      get(index) {
        if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(this.length)) {
          dart.throw(new core.RangeError(`Index ${index} must be in the range [0..${this.length}).`));
        }
        return this[_table][dartx.get](dart.notNull(this[_head]) + dart.notNull(index) & dart.notNull(this[_table][dartx.length]) - 1);
      }
      set(index, value) {
        dart.as(value, E);
        if (dart.notNull(index) < 0 || dart.notNull(index) >= dart.notNull(this.length)) {
          dart.throw(new core.RangeError(`Index ${index} must be in the range [0..${this.length}).`));
        }
        this[_table][dartx.set](dart.notNull(this[_head]) + dart.notNull(index) & dart.notNull(this[_table][dartx.length]) - 1, value);
        return value;
      }
      static _isPowerOf2(number) {
        return (dart.notNull(number) & dart.notNull(number) - 1) == 0;
      }
      static _nextPowerOf2(number) {
        dart.assert(dart.notNull(number) > 0);
        number = (dart.notNull(number) << 1) - 1;
        for (;;) {
          let nextNumber = dart.notNull(number) & dart.notNull(number) - 1;
          if (nextNumber == 0)
            return number;
          number = nextNumber;
        }
      }
      [_add](element) {
        dart.as(element, E);
        this[_table][dartx.set](this[_tail], element);
        this[_tail] = dart.notNull(this[_tail]) + 1 & dart.notNull(this[_table][dartx.length]) - 1;
        if (this[_head] == this[_tail])
          this[_grow]();
      }
      [_grow]() {
        let newTable = core.List$(E).new(dart.notNull(this[_table][dartx.length]) * 2);
        let split = dart.notNull(this[_table][dartx.length]) - dart.notNull(this[_head]);
        newTable[dartx.setRange](0, split, this[_table], this[_head]);
        newTable[dartx.setRange](split, dart.notNull(split) + dart.notNull(this[_head]), this[_table], 0);
        this[_head] = 0;
        this[_tail] = this[_table][dartx.length];
        this[_table] = newTable;
      }
      [_writeToList](target) {
        dart.as(target, core.List$(E));
        dart.assert(dart.notNull(target[dartx.length]) >= dart.notNull(this.length));
        if (dart.notNull(this[_head]) <= dart.notNull(this[_tail])) {
          let length = dart.notNull(this[_tail]) - dart.notNull(this[_head]);
          target[dartx.setRange](0, length, this[_table], this[_head]);
          return length;
        } else {
          let firstPartSize = dart.notNull(this[_table][dartx.length]) - dart.notNull(this[_head]);
          target[dartx.setRange](0, firstPartSize, this[_table], this[_head]);
          target[dartx.setRange](firstPartSize, dart.notNull(firstPartSize) + dart.notNull(this[_tail]), this[_table], 0);
          return dart.notNull(this[_tail]) + dart.notNull(firstPartSize);
        }
      }
      [_preGrow](newElementCount) {
        dart.assert(dart.notNull(newElementCount) >= dart.notNull(this.length));
        newElementCount = dart.notNull(newElementCount) + (dart.notNull(newElementCount) >> 1);
        let newCapacity = QueueList$()._nextPowerOf2(newElementCount);
        let newTable = core.List$(E).new(newCapacity);
        this[_tail] = this[_writeToList](newTable);
        this[_table] = newTable;
        this[_head] = 0;
      }
    }
    QueueList[dart.implements] = () => [collection.Queue$(E)];
    dart.setSignature(QueueList, {
      constructors: () => ({
        QueueList: [QueueList$(E), [], [core.int]],
        from: [QueueList$(E), [core.Iterable$(E)]]
      }),
      methods: () => ({
        add: [dart.void, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        addLast: [dart.void, [E]],
        addFirst: [dart.void, [E]],
        removeFirst: [E, []],
        removeLast: [E, []],
        get: [E, [core.int]],
        set: [dart.void, [core.int, E]],
        [_add]: [dart.void, [E]],
        [_grow]: [dart.void, []],
        [_writeToList]: [core.int, [core.List$(E)]],
        [_preGrow]: [dart.void, [core.int]]
      }),
      statics: () => ({
        _isPowerOf2: [core.bool, [core.int]],
        _nextPowerOf2: [core.int, [core.int]]
      }),
      names: ['_isPowerOf2', '_nextPowerOf2']
    });
    dart.defineExtensionMembers(QueueList, [
      'add',
      'addAll',
      'toString',
      'removeLast',
      'get',
      'set',
      'length',
      'length'
    ]);
    return QueueList;
  });
  let QueueList = QueueList$();
  QueueList._INITIAL_CAPACITY = 8;
  // Exports:
  exports.QueueList$ = QueueList$;
  exports.QueueList = QueueList;
});
