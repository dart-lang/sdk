dart_library.library('collection/src/priority_queue', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/collection'
], /* Lazy imports */[
], function(exports, dart, core, collection) {
  'use strict';
  let dartx = dart.dartx;
  const PriorityQueue$ = dart.generic(function(E) {
    class PriorityQueue extends core.Object {
      static new(comparison) {
        return new (HeapPriorityQueue$(E))(comparison);
      }
    }
    dart.setSignature(PriorityQueue, {
      constructors: () => ({new: [PriorityQueue$(E), [], [dart.functionType(core.int, [E, E])]]})
    });
    return PriorityQueue;
  });
  let PriorityQueue = PriorityQueue$();
  const _queue = Symbol('_queue');
  const _length = Symbol('_length');
  const _add = Symbol('_add');
  const _locate = Symbol('_locate');
  const _removeLast = Symbol('_removeLast');
  const _bubbleUp = Symbol('_bubbleUp');
  const _bubbleDown = Symbol('_bubbleDown');
  const _grow = Symbol('_grow');
  const HeapPriorityQueue$ = dart.generic(function(E) {
    class HeapPriorityQueue extends core.Object {
      HeapPriorityQueue(comparison) {
        if (comparison === void 0) comparison = null;
        this[_queue] = core.List$(E).new(HeapPriorityQueue$()._INITIAL_CAPACITY);
        this.comparison = dart.as(comparison != null ? comparison : core.Comparable.compare, core.Comparator);
        this[_length] = 0;
      }
      add(element) {
        dart.as(element, E);
        this[_add](element);
      }
      addAll(elements) {
        dart.as(elements, core.Iterable$(E));
        for (let element of elements) {
          this[_add](element);
        }
      }
      clear() {
        this[_queue] = dart.const(dart.list([], E));
        this[_length] = 0;
      }
      contains(object) {
        dart.as(object, E);
        return dart.notNull(this[_locate](object)) >= 0;
      }
      get first() {
        if (this[_length] == 0) dart.throw(new core.StateError("No such element"));
        return this[_queue][dartx.get](0);
      }
      get isEmpty() {
        return this[_length] == 0;
      }
      get isNotEmpty() {
        return this[_length] != 0;
      }
      get length() {
        return this[_length];
      }
      remove(element) {
        dart.as(element, E);
        let index = this[_locate](element);
        if (dart.notNull(index) < 0) return false;
        let last = this[_removeLast]();
        if (dart.notNull(index) < dart.notNull(this[_length])) {
          let comp = dart.dcall(this.comparison, last, element);
          if (dart.notNull(comp) <= 0) {
            this[_bubbleUp](last, index);
          } else {
            this[_bubbleDown](last, index);
          }
        }
        return true;
      }
      removeAll() {
        let result = this[_queue];
        let length = this[_length];
        this[_queue] = dart.const(dart.list([], E));
        this[_length] = 0;
        return result[dartx.take](length);
      }
      removeFirst() {
        if (this[_length] == 0) dart.throw(new core.StateError("No such element"));
        let result = this[_queue][dartx.get](0);
        let last = this[_removeLast]();
        if (dart.notNull(this[_length]) > 0) {
          this[_bubbleDown](last, 0);
        }
        return result;
      }
      toList() {
        let list = core.List$(E).new();
        list[dartx.length] = this[_length];
        list[dartx.setRange](0, this[_length], this[_queue]);
        list[dartx.sort](dart.as(this.comparison, __CastType0));
        return list;
      }
      toSet() {
        let set = new (collection.SplayTreeSet$(E))(dart.as(this.comparison, dart.functionType(core.int, [E, E])));
        for (let i = 0; i < dart.notNull(this[_length]); i++) {
          set.add(this[_queue][dartx.get](i));
        }
        return set;
      }
      toString() {
        return dart.toString(this[_queue][dartx.take](this[_length]));
      }
      [_add](element) {
        dart.as(element, E);
        if (this[_length] == this[_queue][dartx.length]) this[_grow]();
        this[_bubbleUp](element, (() => {
          let x = this[_length];
          this[_length] = dart.notNull(x) + 1;
          return x;
        })());
      }
      [_locate](object) {
        dart.as(object, E);
        if (this[_length] == 0) return -1;
        let position = 1;
        do {
          let index = position - 1;
          let element = this[_queue][dartx.get](index);
          let comp = dart.dcall(this.comparison, element, object);
          if (comp == 0) return index;
          if (dart.notNull(comp) < 0) {
            let leftChildPosition = position * 2;
            if (leftChildPosition <= dart.notNull(this[_length])) {
              position = leftChildPosition;
              continue;
            }
          }
          do {
            while (dart.notNull(position[dartx.isOdd])) {
              position = position >> 1;
            }
            position = position + 1;
          } while (position > dart.notNull(this[_length]));
        } while (position != 1);
        return -1;
      }
      [_removeLast]() {
        let newLength = dart.notNull(this[_length]) - 1;
        let last = this[_queue][dartx.get](newLength);
        this[_queue][dartx.set](newLength, null);
        this[_length] = newLength;
        return last;
      }
      [_bubbleUp](element, index) {
        dart.as(element, E);
        while (dart.notNull(index) > 0) {
          let parentIndex = ((dart.notNull(index) - 1) / 2)[dartx.truncate]();
          let parent = this[_queue][dartx.get](parentIndex);
          if (dart.notNull(dart.dcall(this.comparison, element, parent)) > 0) break;
          this[_queue][dartx.set](index, parent);
          index = parentIndex;
        }
        this[_queue][dartx.set](index, element);
      }
      [_bubbleDown](element, index) {
        dart.as(element, E);
        let rightChildIndex = dart.notNull(index) * 2 + 2;
        while (rightChildIndex < dart.notNull(this[_length])) {
          let leftChildIndex = rightChildIndex - 1;
          let leftChild = this[_queue][dartx.get](leftChildIndex);
          let rightChild = this[_queue][dartx.get](rightChildIndex);
          let comp = dart.dcall(this.comparison, leftChild, rightChild);
          let minChildIndex = null;
          let minChild = null;
          if (dart.notNull(comp) < 0) {
            minChild = leftChild;
            minChildIndex = leftChildIndex;
          } else {
            minChild = rightChild;
            minChildIndex = rightChildIndex;
          }
          comp = dart.dcall(this.comparison, element, minChild);
          if (dart.notNull(comp) <= 0) {
            this[_queue][dartx.set](index, element);
            return;
          }
          this[_queue][dartx.set](index, minChild);
          index = minChildIndex;
          rightChildIndex = dart.notNull(index) * 2 + 2;
        }
        let leftChildIndex = rightChildIndex - 1;
        if (leftChildIndex < dart.notNull(this[_length])) {
          let child = this[_queue][dartx.get](leftChildIndex);
          let comp = dart.dcall(this.comparison, element, child);
          if (dart.notNull(comp) > 0) {
            this[_queue][dartx.set](index, child);
            index = leftChildIndex;
          }
        }
        this[_queue][dartx.set](index, element);
      }
      [_grow]() {
        let newCapacity = dart.notNull(this[_queue][dartx.length]) * 2 + 1;
        if (dart.notNull(newCapacity) < dart.notNull(HeapPriorityQueue$()._INITIAL_CAPACITY)) newCapacity = HeapPriorityQueue$()._INITIAL_CAPACITY;
        let newQueue = core.List$(E).new(newCapacity);
        newQueue[dartx.setRange](0, this[_length], this[_queue]);
        this[_queue] = newQueue;
      }
    }
    HeapPriorityQueue[dart.implements] = () => [PriorityQueue$(E)];
    dart.setSignature(HeapPriorityQueue, {
      constructors: () => ({HeapPriorityQueue: [HeapPriorityQueue$(E), [], [dart.functionType(core.int, [E, E])]]}),
      methods: () => ({
        add: [dart.void, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        clear: [dart.void, []],
        contains: [core.bool, [E]],
        remove: [core.bool, [E]],
        removeAll: [core.Iterable$(E), []],
        removeFirst: [E, []],
        toList: [core.List$(E), []],
        toSet: [core.Set$(E), []],
        [_add]: [dart.void, [E]],
        [_locate]: [core.int, [E]],
        [_removeLast]: [E, []],
        [_bubbleUp]: [dart.void, [E, core.int]],
        [_bubbleDown]: [dart.void, [E, core.int]],
        [_grow]: [dart.void, []]
      })
    });
    HeapPriorityQueue._INITIAL_CAPACITY = 7;
    return HeapPriorityQueue;
  });
  let HeapPriorityQueue = HeapPriorityQueue$();
  const __CastType0$ = dart.generic(function(E) {
    const __CastType0 = dart.typedef('__CastType0', () => dart.functionType(core.int, [E, E]));
    return __CastType0;
  });
  let __CastType0 = __CastType0$();
  // Exports:
  exports.PriorityQueue$ = PriorityQueue$;
  exports.PriorityQueue = PriorityQueue;
  exports.HeapPriorityQueue$ = HeapPriorityQueue$;
  exports.HeapPriorityQueue = HeapPriorityQueue;
});
