dart_library.library('collection/src/iterable_zip', null, /* Imports */[
  'dart/_runtime',
  'dart/collection',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, collection, core) {
  'use strict';
  let dartx = dart.dartx;
  const _iterables = Symbol('_iterables');
  class IterableZip extends collection.IterableBase$(core.List) {
    IterableZip(iterables) {
      this[_iterables] = iterables;
      super.IterableBase();
    }
    get iterator() {
      let iterators = this[_iterables][dartx.map](dart.fn(x => x[dartx.iterator], core.Iterator, [core.Iterable]))[dartx.toList]({growable: false});
      return new _IteratorZip(iterators);
    }
  }
  dart.setSignature(IterableZip, {
    constructors: () => ({IterableZip: [IterableZip, [core.Iterable$(core.Iterable)]]})
  });
  dart.defineExtensionMembers(IterableZip, ['iterator']);
  const _iterators = Symbol('_iterators');
  const _current = Symbol('_current');
  class _IteratorZip extends core.Object {
    _IteratorZip(iterators) {
      this[_iterators] = dart.as(iterators, core.List$(core.Iterator));
      this[_current] = null;
    }
    moveNext() {
      if (dart.notNull(this[_iterators][dartx.isEmpty])) return false;
      for (let i = 0; i < dart.notNull(this[_iterators][dartx.length]); i++) {
        if (!dart.notNull(this[_iterators][dartx.get](i).moveNext())) {
          this[_current] = null;
          return false;
        }
      }
      this[_current] = core.List.new(this[_iterators][dartx.length]);
      for (let i = 0; i < dart.notNull(this[_iterators][dartx.length]); i++) {
        this[_current][dartx.set](i, this[_iterators][dartx.get](i).current);
      }
      return true;
    }
    get current() {
      return this[_current];
    }
  }
  _IteratorZip[dart.implements] = () => [core.Iterator$(core.List)];
  dart.setSignature(_IteratorZip, {
    constructors: () => ({_IteratorZip: [_IteratorZip, [core.List]]}),
    methods: () => ({moveNext: [core.bool, []]})
  });
  // Exports:
  exports.IterableZip = IterableZip;
});
