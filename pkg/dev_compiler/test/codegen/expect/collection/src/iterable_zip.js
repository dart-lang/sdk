dart_library.library('collection/src/iterable_zip', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/collection'
], /* Lazy imports */[
], function(exports, dart, core, collection) {
  'use strict';
  let dartx = dart.dartx;
  const _iterables = Symbol('_iterables');
  const IterableZip$ = dart.generic(function(T) {
    class IterableZip extends collection.IterableBase$(core.List$(T)) {
      IterableZip(iterables) {
        this[_iterables] = iterables;
        super.IterableBase();
      }
      get iterator() {
        let iterators = this[_iterables][dartx.map](dart.fn(x => {
          dart.as(x, core.Iterable$(T));
          return x[dartx.iterator];
        }, core.Iterator$(T), [core.Iterable$(T)]))[dartx.toList]({growable: false});
        return new (_IteratorZip$(T))(iterators);
      }
    }
    dart.setSignature(IterableZip, {
      constructors: () => ({IterableZip: [IterableZip$(T), [core.Iterable$(core.Iterable$(T))]]})
    });
    dart.defineExtensionMembers(IterableZip, ['iterator']);
    return IterableZip;
  });
  let IterableZip = IterableZip$();
  const _iterators = Symbol('_iterators');
  const _current = Symbol('_current');
  const _IteratorZip$ = dart.generic(function(T) {
    class _IteratorZip extends core.Object {
      _IteratorZip(iterators) {
        this[_iterators] = iterators;
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
        this[_current] = core.List$(T).new(this[_iterators][dartx.length]);
        for (let i = 0; i < dart.notNull(this[_iterators][dartx.length]); i++) {
          this[_current][dartx.set](i, this[_iterators][dartx.get](i).current);
        }
        return true;
      }
      get current() {
        return this[_current];
      }
    }
    _IteratorZip[dart.implements] = () => [core.Iterator$(core.List$(T))];
    dart.setSignature(_IteratorZip, {
      constructors: () => ({_IteratorZip: [_IteratorZip$(T), [core.List$(core.Iterator$(T))]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return _IteratorZip;
  });
  let _IteratorZip = _IteratorZip$();
  // Exports:
  exports.IterableZip$ = IterableZip$;
  exports.IterableZip = IterableZip;
});
