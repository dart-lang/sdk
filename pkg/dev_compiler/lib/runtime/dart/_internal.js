dart_library.library('dart/_internal', null, /* Imports */[
  "dart/_runtime",
  'dart/core',
  'dart/collection'
], /* Lazy imports */[
  'dart/math',
  'dart/_interceptors',
  'dart/_js_primitives'
], function(exports, dart, core, collection, math, _interceptors, _js_primitives) {
  'use strict';
  let dartx = dart.dartx;
  class EfficientLength extends core.Object {}
  let ListIterable$ = dart.generic(function(E) {
    class ListIterable extends collection.IterableBase$(E) {
      ListIterable() {
        super.IterableBase();
      }
      get iterator() {
        return new (ListIterator$(E))(this);
      }
      forEach(action) {
        dart.as(action, dart.functionType(dart.void, [E]));
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          action(this.elementAt(i));
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
      }
      get isEmpty() {
        return this.length == 0;
      }
      get first() {
        if (this.length == 0)
          dart.throw(IterableElementError.noElement());
        return this.elementAt(0);
      }
      get last() {
        if (this.length == 0)
          dart.throw(IterableElementError.noElement());
        return this.elementAt(dart.notNull(this.length) - 1);
      }
      get single() {
        if (this.length == 0)
          dart.throw(IterableElementError.noElement());
        if (dart.notNull(this.length) > 1)
          dart.throw(IterableElementError.tooMany());
        return this.elementAt(0);
      }
      contains(element) {
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (dart.equals(this.elementAt(i), element))
            return true;
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
        return false;
      }
      every(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (!dart.notNull(test(this.elementAt(i))))
            return false;
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
        return true;
      }
      any(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (dart.notNull(test(this.elementAt(i))))
            return true;
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
        return false;
      }
      firstWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let element = this.elementAt(i);
          if (dart.notNull(test(element)))
            return element;
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
        if (orElse != null)
          return orElse();
        dart.throw(IterableElementError.noElement());
      }
      lastWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        let length = this.length;
        for (let i = dart.notNull(length) - 1; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
          let element = this.elementAt(i);
          if (dart.notNull(test(element)))
            return element;
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
        if (orElse != null)
          return orElse();
        dart.throw(IterableElementError.noElement());
      }
      singleWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let length = this.length;
        let match = null;
        let matchFound = false;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let element = this.elementAt(i);
          if (dart.notNull(test(element))) {
            if (dart.notNull(matchFound)) {
              dart.throw(IterableElementError.tooMany());
            }
            matchFound = true;
            match = element;
          }
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
        if (dart.notNull(matchFound))
          return match;
        dart.throw(IterableElementError.noElement());
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        let length = this.length;
        if (!dart.notNull(separator[dartx.isEmpty])) {
          if (length == 0)
            return "";
          let first = `${this.elementAt(0)}`;
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
          let buffer = new core.StringBuffer(first);
          for (let i = 1; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
            buffer.write(separator);
            buffer.write(this.elementAt(i));
            if (length != this.length) {
              dart.throw(new core.ConcurrentModificationError(this));
            }
          }
          return dart.toString(buffer);
        } else {
          let buffer = new core.StringBuffer();
          for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
            buffer.write(this.elementAt(i));
            if (length != this.length) {
              dart.throw(new core.ConcurrentModificationError(this));
            }
          }
          return dart.toString(buffer);
        }
      }
      where(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return super.where(test);
      }
      map(f) {
        dart.as(f, dart.functionType(dart.dynamic, [E]));
        return new MappedListIterable(this, f);
      }
      reduce(combine) {
        dart.as(combine, dart.functionType(E, [dart.dynamic, E]));
        let length = this.length;
        if (length == 0)
          dart.throw(IterableElementError.noElement());
        let value = this.elementAt(0);
        for (let i = 1; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          value = dart.dcall(combine, value, this.elementAt(i));
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
        return value;
      }
      fold(initialValue, combine) {
        dart.as(combine, dart.functionType(dart.dynamic, [dart.dynamic, E]));
        let value = initialValue;
        let length = this.length;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          value = dart.dcall(combine, value, this.elementAt(i));
          if (length != this.length) {
            dart.throw(new core.ConcurrentModificationError(this));
          }
        }
        return value;
      }
      skip(count) {
        return new (SubListIterable$(E))(this, count, null);
      }
      skipWhile(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return super.skipWhile(test);
      }
      take(count) {
        return new (SubListIterable$(E))(this, 0, count);
      }
      takeWhile(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return super.takeWhile(test);
      }
      toList(opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let result = null;
        if (dart.notNull(growable)) {
          result = core.List$(E).new();
          result[dartx.length] = this.length;
        } else {
          result = core.List$(E).new(this.length);
        }
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); i = dart.notNull(i) + 1) {
          result[dartx.set](i, this.elementAt(i));
        }
        return result;
      }
      toSet() {
        let result = core.Set$(E).new();
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); i = dart.notNull(i) + 1) {
          result.add(this.elementAt(i));
        }
        return result;
      }
    }
    ListIterable[dart.implements] = () => [EfficientLength];
    dart.setSignature(ListIterable, {
      constructors: () => ({ListIterable: [ListIterable$(E), []]}),
      methods: () => ({
        forEach: [dart.void, [dart.functionType(dart.void, [E])]],
        every: [core.bool, [dart.functionType(core.bool, [E])]],
        any: [core.bool, [dart.functionType(core.bool, [E])]],
        firstWhere: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        lastWhere: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        singleWhere: [E, [dart.functionType(core.bool, [E])]],
        where: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        map: [core.Iterable, [dart.functionType(dart.dynamic, [E])]],
        reduce: [E, [dart.functionType(E, [dart.dynamic, E])]],
        fold: [dart.dynamic, [dart.dynamic, dart.functionType(dart.dynamic, [dart.dynamic, E])]],
        skip: [core.Iterable$(E), [core.int]],
        skipWhile: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        take: [core.Iterable$(E), [core.int]],
        takeWhile: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        toList: [core.List$(E), [], {growable: core.bool}],
        toSet: [core.Set$(E), []]
      })
    });
    dart.defineExtensionMembers(ListIterable, [
      'forEach',
      'contains',
      'every',
      'any',
      'firstWhere',
      'lastWhere',
      'singleWhere',
      'join',
      'where',
      'map',
      'reduce',
      'fold',
      'skip',
      'skipWhile',
      'take',
      'takeWhile',
      'toList',
      'toSet',
      'iterator',
      'isEmpty',
      'first',
      'last',
      'single'
    ]);
    return ListIterable;
  });
  let ListIterable = ListIterable$();
  let _iterable = dart.JsSymbol('_iterable');
  let _start = dart.JsSymbol('_start');
  let _endOrLength = dart.JsSymbol('_endOrLength');
  let _endIndex = dart.JsSymbol('_endIndex');
  let _startIndex = dart.JsSymbol('_startIndex');
  let SubListIterable$ = dart.generic(function(E) {
    class SubListIterable extends ListIterable$(E) {
      SubListIterable(iterable, start, endOrLength) {
        this[_iterable] = iterable;
        this[_start] = start;
        this[_endOrLength] = endOrLength;
        super.ListIterable();
        core.RangeError.checkNotNegative(this[_start], "start");
        if (this[_endOrLength] != null) {
          core.RangeError.checkNotNegative(this[_endOrLength], "end");
          if (dart.notNull(this[_start]) > dart.notNull(this[_endOrLength])) {
            dart.throw(new core.RangeError.range(this[_start], 0, this[_endOrLength], "start"));
          }
        }
      }
      get [_endIndex]() {
        let length = this[_iterable][dartx.length];
        if (this[_endOrLength] == null || dart.notNull(this[_endOrLength]) > dart.notNull(length))
          return length;
        return this[_endOrLength];
      }
      get [_startIndex]() {
        let length = this[_iterable][dartx.length];
        if (dart.notNull(this[_start]) > dart.notNull(length))
          return length;
        return this[_start];
      }
      get length() {
        let length = this[_iterable][dartx.length];
        if (dart.notNull(this[_start]) >= dart.notNull(length))
          return 0;
        if (this[_endOrLength] == null || dart.notNull(this[_endOrLength]) >= dart.notNull(length)) {
          return dart.notNull(length) - dart.notNull(this[_start]);
        }
        return dart.notNull(this[_endOrLength]) - dart.notNull(this[_start]);
      }
      elementAt(index) {
        let realIndex = dart.notNull(this[_startIndex]) + dart.notNull(index);
        if (dart.notNull(index) < 0 || dart.notNull(realIndex) >= dart.notNull(this[_endIndex])) {
          dart.throw(core.RangeError.index(index, this, "index"));
        }
        return this[_iterable][dartx.elementAt](realIndex);
      }
      skip(count) {
        core.RangeError.checkNotNegative(count, "count");
        let newStart = dart.notNull(this[_start]) + dart.notNull(count);
        if (this[_endOrLength] != null && dart.notNull(newStart) >= dart.notNull(this[_endOrLength])) {
          return new (EmptyIterable$(E))();
        }
        return new (SubListIterable$(E))(this[_iterable], newStart, this[_endOrLength]);
      }
      take(count) {
        core.RangeError.checkNotNegative(count, "count");
        if (this[_endOrLength] == null) {
          return new (SubListIterable$(E))(this[_iterable], this[_start], dart.notNull(this[_start]) + dart.notNull(count));
        } else {
          let newEnd = dart.notNull(this[_start]) + dart.notNull(count);
          if (dart.notNull(this[_endOrLength]) < dart.notNull(newEnd))
            return this;
          return new (SubListIterable$(E))(this[_iterable], this[_start], newEnd);
        }
      }
      toList(opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let start = this[_start];
        let end = this[_iterable][dartx.length];
        if (this[_endOrLength] != null && dart.notNull(this[_endOrLength]) < dart.notNull(end))
          end = this[_endOrLength];
        let length = dart.notNull(end) - dart.notNull(start);
        if (dart.notNull(length) < 0)
          length = 0;
        let result = dart.notNull(growable) ? (() => {
          let _ = core.List$(E).new();
          _[dartx.length] = length;
          return _;
        })() : core.List$(E).new(length);
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          result[dartx.set](i, this[_iterable][dartx.elementAt](dart.notNull(start) + dart.notNull(i)));
          if (dart.notNull(this[_iterable][dartx.length]) < dart.notNull(end))
            dart.throw(new core.ConcurrentModificationError(this));
        }
        return dart.as(result, core.List$(E));
      }
    }
    dart.setSignature(SubListIterable, {
      constructors: () => ({SubListIterable: [SubListIterable$(E), [core.Iterable$(E), core.int, core.int]]}),
      methods: () => ({
        elementAt: [E, [core.int]],
        skip: [core.Iterable$(E), [core.int]],
        take: [core.Iterable$(E), [core.int]],
        toList: [core.List$(E), [], {growable: core.bool}]
      })
    });
    dart.defineExtensionMembers(SubListIterable, [
      'elementAt',
      'skip',
      'take',
      'toList',
      'length'
    ]);
    return SubListIterable;
  });
  let SubListIterable = SubListIterable$();
  let _length = dart.JsSymbol('_length');
  let _index = dart.JsSymbol('_index');
  let _current = dart.JsSymbol('_current');
  let ListIterator$ = dart.generic(function(E) {
    class ListIterator extends core.Object {
      ListIterator(iterable) {
        this[_iterable] = iterable;
        this[_length] = iterable[dartx.length];
        this[_index] = 0;
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        let length = this[_iterable][dartx.length];
        if (this[_length] != length) {
          dart.throw(new core.ConcurrentModificationError(this[_iterable]));
        }
        if (dart.notNull(this[_index]) >= dart.notNull(length)) {
          this[_current] = null;
          return false;
        }
        this[_current] = this[_iterable][dartx.elementAt](this[_index]);
        this[_index] = dart.notNull(this[_index]) + 1;
        return true;
      }
    }
    ListIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(ListIterator, {
      constructors: () => ({ListIterator: [ListIterator$(E), [core.Iterable$(E)]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return ListIterator;
  });
  let ListIterator = ListIterator$();
  let _Transformation$ = dart.generic(function(S, T) {
    let _Transformation = dart.typedef('_Transformation', () => dart.functionType(T, [S]));
    return _Transformation;
  });
  let _Transformation = _Transformation$();
  let _f = dart.JsSymbol('_f');
  let MappedIterable$ = dart.generic(function(S, T) {
    class MappedIterable extends collection.IterableBase$(T) {
      static new(iterable, func) {
        if (dart.is(iterable, EfficientLength)) {
          return new (EfficientLengthMappedIterable$(S, T))(iterable, func);
        }
        return new (MappedIterable$(S, T))._(dart.as(iterable, core.Iterable$(S)), func);
      }
      _(iterable, f) {
        this[_iterable] = iterable;
        this[_f] = f;
        super.IterableBase();
      }
      get iterator() {
        return new (MappedIterator$(S, T))(this[_iterable][dartx.iterator], this[_f]);
      }
      get length() {
        return this[_iterable][dartx.length];
      }
      get isEmpty() {
        return this[_iterable][dartx.isEmpty];
      }
      get first() {
        return this[_f](this[_iterable][dartx.first]);
      }
      get last() {
        return this[_f](this[_iterable][dartx.last]);
      }
      get single() {
        return this[_f](this[_iterable][dartx.single]);
      }
      elementAt(index) {
        return this[_f](this[_iterable][dartx.elementAt](index));
      }
    }
    dart.defineNamedConstructor(MappedIterable, '_');
    dart.setSignature(MappedIterable, {
      constructors: () => ({
        new: [MappedIterable$(S, T), [core.Iterable, dart.functionType(T, [S])]],
        _: [MappedIterable$(S, T), [core.Iterable$(S), dart.functionType(T, [S])]]
      }),
      methods: () => ({elementAt: [T, [core.int]]})
    });
    dart.defineExtensionMembers(MappedIterable, [
      'elementAt',
      'iterator',
      'length',
      'isEmpty',
      'first',
      'last',
      'single'
    ]);
    return MappedIterable;
  });
  let MappedIterable = MappedIterable$();
  let EfficientLengthMappedIterable$ = dart.generic(function(S, T) {
    class EfficientLengthMappedIterable extends MappedIterable$(S, T) {
      EfficientLengthMappedIterable(iterable, func) {
        super._(dart.as(iterable, core.Iterable$(S)), func);
      }
    }
    EfficientLengthMappedIterable[dart.implements] = () => [EfficientLength];
    dart.setSignature(EfficientLengthMappedIterable, {
      constructors: () => ({EfficientLengthMappedIterable: [EfficientLengthMappedIterable$(S, T), [core.Iterable, dart.functionType(T, [S])]]})
    });
    return EfficientLengthMappedIterable;
  });
  let EfficientLengthMappedIterable = EfficientLengthMappedIterable$();
  let _iterator = dart.JsSymbol('_iterator');
  let MappedIterator$ = dart.generic(function(S, T) {
    class MappedIterator extends core.Iterator$(T) {
      MappedIterator(iterator, f) {
        this[_iterator] = iterator;
        this[_f] = f;
        this[_current] = null;
      }
      moveNext() {
        if (dart.notNull(this[_iterator].moveNext())) {
          this[_current] = this[_f](this[_iterator].current);
          return true;
        }
        this[_current] = null;
        return false;
      }
      get current() {
        return this[_current];
      }
    }
    dart.setSignature(MappedIterator, {
      constructors: () => ({MappedIterator: [MappedIterator$(S, T), [core.Iterator$(S), dart.functionType(T, [S])]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return MappedIterator;
  });
  let MappedIterator = MappedIterator$();
  let _source = dart.JsSymbol('_source');
  let MappedListIterable$ = dart.generic(function(S, T) {
    class MappedListIterable extends ListIterable$(T) {
      MappedListIterable(source, f) {
        this[_source] = source;
        this[_f] = f;
        super.ListIterable();
      }
      get length() {
        return this[_source][dartx.length];
      }
      elementAt(index) {
        return this[_f](this[_source][dartx.elementAt](index));
      }
    }
    MappedListIterable[dart.implements] = () => [EfficientLength];
    dart.setSignature(MappedListIterable, {
      constructors: () => ({MappedListIterable: [MappedListIterable$(S, T), [core.Iterable$(S), dart.functionType(T, [S])]]}),
      methods: () => ({elementAt: [T, [core.int]]})
    });
    dart.defineExtensionMembers(MappedListIterable, ['elementAt', 'length']);
    return MappedListIterable;
  });
  let MappedListIterable = MappedListIterable$();
  let _ElementPredicate$ = dart.generic(function(E) {
    let _ElementPredicate = dart.typedef('_ElementPredicate', () => dart.functionType(core.bool, [E]));
    return _ElementPredicate;
  });
  let _ElementPredicate = _ElementPredicate$();
  let WhereIterable$ = dart.generic(function(E) {
    class WhereIterable extends collection.IterableBase$(E) {
      WhereIterable(iterable, f) {
        this[_iterable] = iterable;
        this[_f] = f;
        super.IterableBase();
      }
      get iterator() {
        return new (WhereIterator$(E))(this[_iterable][dartx.iterator], this[_f]);
      }
    }
    dart.setSignature(WhereIterable, {
      constructors: () => ({WhereIterable: [WhereIterable$(E), [core.Iterable$(E), dart.functionType(core.bool, [E])]]})
    });
    dart.defineExtensionMembers(WhereIterable, ['iterator']);
    return WhereIterable;
  });
  let WhereIterable = WhereIterable$();
  let WhereIterator$ = dart.generic(function(E) {
    class WhereIterator extends core.Iterator$(E) {
      WhereIterator(iterator, f) {
        this[_iterator] = iterator;
        this[_f] = f;
      }
      moveNext() {
        while (dart.notNull(this[_iterator].moveNext())) {
          if (dart.notNull(this[_f](this[_iterator].current))) {
            return true;
          }
        }
        return false;
      }
      get current() {
        return this[_iterator].current;
      }
    }
    dart.setSignature(WhereIterator, {
      constructors: () => ({WhereIterator: [WhereIterator$(E), [core.Iterator$(E), dart.functionType(core.bool, [E])]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return WhereIterator;
  });
  let WhereIterator = WhereIterator$();
  let _ExpandFunction$ = dart.generic(function(S, T) {
    let _ExpandFunction = dart.typedef('_ExpandFunction', () => dart.functionType(core.Iterable$(T), [S]));
    return _ExpandFunction;
  });
  let _ExpandFunction = _ExpandFunction$();
  let ExpandIterable$ = dart.generic(function(S, T) {
    class ExpandIterable extends collection.IterableBase$(T) {
      ExpandIterable(iterable, f) {
        this[_iterable] = iterable;
        this[_f] = f;
        super.IterableBase();
      }
      get iterator() {
        return new (ExpandIterator$(S, T))(this[_iterable][dartx.iterator], dart.as(this[_f], __CastType0));
      }
    }
    dart.setSignature(ExpandIterable, {
      constructors: () => ({ExpandIterable: [ExpandIterable$(S, T), [core.Iterable$(S), dart.functionType(core.Iterable$(T), [S])]]})
    });
    dart.defineExtensionMembers(ExpandIterable, ['iterator']);
    return ExpandIterable;
  });
  let ExpandIterable = ExpandIterable$();
  let _currentExpansion = dart.JsSymbol('_currentExpansion');
  let _nextExpansion = dart.JsSymbol('_nextExpansion');
  let ExpandIterator$ = dart.generic(function(S, T) {
    class ExpandIterator extends core.Object {
      ExpandIterator(iterator, f) {
        this[_iterator] = iterator;
        this[_f] = f;
        this[_currentExpansion] = dart.const(new (EmptyIterator$(T))());
        this[_current] = null;
      }
      [_nextExpansion]() {}
      get current() {
        return this[_current];
      }
      moveNext() {
        if (this[_currentExpansion] == null)
          return false;
        while (!dart.notNull(this[_currentExpansion].moveNext())) {
          this[_current] = null;
          if (dart.notNull(this[_iterator].moveNext())) {
            this[_currentExpansion] = null;
            this[_currentExpansion] = dart.as(dart.dcall(this[_f], this[_iterator].current)[dartx.iterator], core.Iterator$(T));
          } else {
            return false;
          }
        }
        this[_current] = this[_currentExpansion].current;
        return true;
      }
    }
    ExpandIterator[dart.implements] = () => [core.Iterator$(T)];
    dart.setSignature(ExpandIterator, {
      constructors: () => ({ExpandIterator: [ExpandIterator$(S, T), [core.Iterator$(S), dart.functionType(core.Iterable$(T), [S])]]}),
      methods: () => ({
        [_nextExpansion]: [dart.void, []],
        moveNext: [core.bool, []]
      })
    });
    return ExpandIterator;
  });
  let ExpandIterator = ExpandIterator$();
  let _takeCount = dart.JsSymbol('_takeCount');
  let TakeIterable$ = dart.generic(function(E) {
    class TakeIterable extends collection.IterableBase$(E) {
      static new(iterable, takeCount) {
        if (!(typeof takeCount == 'number') || dart.notNull(takeCount) < 0) {
          dart.throw(new core.ArgumentError(takeCount));
        }
        if (dart.is(iterable, EfficientLength)) {
          return new (EfficientLengthTakeIterable$(E))(iterable, takeCount);
        }
        return new (TakeIterable$(E))._(iterable, takeCount);
      }
      _(iterable, takeCount) {
        this[_iterable] = iterable;
        this[_takeCount] = takeCount;
        super.IterableBase();
      }
      get iterator() {
        return new (TakeIterator$(E))(this[_iterable][dartx.iterator], this[_takeCount]);
      }
    }
    dart.defineNamedConstructor(TakeIterable, '_');
    dart.setSignature(TakeIterable, {
      constructors: () => ({
        new: [TakeIterable$(E), [core.Iterable$(E), core.int]],
        _: [TakeIterable$(E), [core.Iterable$(E), core.int]]
      })
    });
    dart.defineExtensionMembers(TakeIterable, ['iterator']);
    return TakeIterable;
  });
  let TakeIterable = TakeIterable$();
  let EfficientLengthTakeIterable$ = dart.generic(function(E) {
    class EfficientLengthTakeIterable extends TakeIterable$(E) {
      EfficientLengthTakeIterable(iterable, takeCount) {
        super._(iterable, takeCount);
      }
      get length() {
        let iterableLength = this[_iterable][dartx.length];
        if (dart.notNull(iterableLength) > dart.notNull(this[_takeCount]))
          return this[_takeCount];
        return iterableLength;
      }
    }
    EfficientLengthTakeIterable[dart.implements] = () => [EfficientLength];
    dart.setSignature(EfficientLengthTakeIterable, {
      constructors: () => ({EfficientLengthTakeIterable: [EfficientLengthTakeIterable$(E), [core.Iterable$(E), core.int]]})
    });
    dart.defineExtensionMembers(EfficientLengthTakeIterable, ['length']);
    return EfficientLengthTakeIterable;
  });
  let EfficientLengthTakeIterable = EfficientLengthTakeIterable$();
  let _remaining = dart.JsSymbol('_remaining');
  let TakeIterator$ = dart.generic(function(E) {
    class TakeIterator extends core.Iterator$(E) {
      TakeIterator(iterator, remaining) {
        this[_iterator] = iterator;
        this[_remaining] = remaining;
        dart.assert(typeof this[_remaining] == 'number' && dart.notNull(this[_remaining]) >= 0);
      }
      moveNext() {
        this[_remaining] = dart.notNull(this[_remaining]) - 1;
        if (dart.notNull(this[_remaining]) >= 0) {
          return this[_iterator].moveNext();
        }
        this[_remaining] = -1;
        return false;
      }
      get current() {
        if (dart.notNull(this[_remaining]) < 0)
          return null;
        return this[_iterator].current;
      }
    }
    dart.setSignature(TakeIterator, {
      constructors: () => ({TakeIterator: [TakeIterator$(E), [core.Iterator$(E), core.int]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return TakeIterator;
  });
  let TakeIterator = TakeIterator$();
  let TakeWhileIterable$ = dart.generic(function(E) {
    class TakeWhileIterable extends collection.IterableBase$(E) {
      TakeWhileIterable(iterable, f) {
        this[_iterable] = iterable;
        this[_f] = f;
        super.IterableBase();
      }
      get iterator() {
        return new (TakeWhileIterator$(E))(this[_iterable][dartx.iterator], this[_f]);
      }
    }
    dart.setSignature(TakeWhileIterable, {
      constructors: () => ({TakeWhileIterable: [TakeWhileIterable$(E), [core.Iterable$(E), dart.functionType(core.bool, [E])]]})
    });
    dart.defineExtensionMembers(TakeWhileIterable, ['iterator']);
    return TakeWhileIterable;
  });
  let TakeWhileIterable = TakeWhileIterable$();
  let _isFinished = dart.JsSymbol('_isFinished');
  let TakeWhileIterator$ = dart.generic(function(E) {
    class TakeWhileIterator extends core.Iterator$(E) {
      TakeWhileIterator(iterator, f) {
        this[_iterator] = iterator;
        this[_f] = f;
        this[_isFinished] = false;
      }
      moveNext() {
        if (dart.notNull(this[_isFinished]))
          return false;
        if (!dart.notNull(this[_iterator].moveNext()) || !dart.notNull(this[_f](this[_iterator].current))) {
          this[_isFinished] = true;
          return false;
        }
        return true;
      }
      get current() {
        if (dart.notNull(this[_isFinished]))
          return null;
        return this[_iterator].current;
      }
    }
    dart.setSignature(TakeWhileIterator, {
      constructors: () => ({TakeWhileIterator: [TakeWhileIterator$(E), [core.Iterator$(E), dart.functionType(core.bool, [E])]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return TakeWhileIterator;
  });
  let TakeWhileIterator = TakeWhileIterator$();
  let _skipCount = dart.JsSymbol('_skipCount');
  let SkipIterable$ = dart.generic(function(E) {
    class SkipIterable extends collection.IterableBase$(E) {
      static new(iterable, count) {
        if (dart.is(iterable, EfficientLength)) {
          return new (EfficientLengthSkipIterable$(E))(iterable, count);
        }
        return new (SkipIterable$(E))._(iterable, count);
      }
      _(iterable, skipCount) {
        this[_iterable] = iterable;
        this[_skipCount] = skipCount;
        super.IterableBase();
        if (!(typeof this[_skipCount] == 'number')) {
          dart.throw(new core.ArgumentError.value(this[_skipCount], "count is not an integer"));
        }
        core.RangeError.checkNotNegative(this[_skipCount], "count");
      }
      skip(count) {
        if (!(typeof this[_skipCount] == 'number')) {
          dart.throw(new core.ArgumentError.value(this[_skipCount], "count is not an integer"));
        }
        core.RangeError.checkNotNegative(this[_skipCount], "count");
        return new (SkipIterable$(E))._(this[_iterable], dart.notNull(this[_skipCount]) + dart.notNull(count));
      }
      get iterator() {
        return new (SkipIterator$(E))(this[_iterable][dartx.iterator], this[_skipCount]);
      }
    }
    dart.defineNamedConstructor(SkipIterable, '_');
    dart.setSignature(SkipIterable, {
      constructors: () => ({
        new: [SkipIterable$(E), [core.Iterable$(E), core.int]],
        _: [SkipIterable$(E), [core.Iterable$(E), core.int]]
      }),
      methods: () => ({skip: [core.Iterable$(E), [core.int]]})
    });
    dart.defineExtensionMembers(SkipIterable, ['skip', 'iterator']);
    return SkipIterable;
  });
  let SkipIterable = SkipIterable$();
  let EfficientLengthSkipIterable$ = dart.generic(function(E) {
    class EfficientLengthSkipIterable extends SkipIterable$(E) {
      EfficientLengthSkipIterable(iterable, skipCount) {
        super._(iterable, skipCount);
      }
      get length() {
        let length = dart.notNull(this[_iterable][dartx.length]) - dart.notNull(this[_skipCount]);
        if (dart.notNull(length) >= 0)
          return length;
        return 0;
      }
    }
    EfficientLengthSkipIterable[dart.implements] = () => [EfficientLength];
    dart.setSignature(EfficientLengthSkipIterable, {
      constructors: () => ({EfficientLengthSkipIterable: [EfficientLengthSkipIterable$(E), [core.Iterable$(E), core.int]]})
    });
    dart.defineExtensionMembers(EfficientLengthSkipIterable, ['length']);
    return EfficientLengthSkipIterable;
  });
  let EfficientLengthSkipIterable = EfficientLengthSkipIterable$();
  let SkipIterator$ = dart.generic(function(E) {
    class SkipIterator extends core.Iterator$(E) {
      SkipIterator(iterator, skipCount) {
        this[_iterator] = iterator;
        this[_skipCount] = skipCount;
        dart.assert(typeof this[_skipCount] == 'number' && dart.notNull(this[_skipCount]) >= 0);
      }
      moveNext() {
        for (let i = 0; dart.notNull(i) < dart.notNull(this[_skipCount]); i = dart.notNull(i) + 1)
          this[_iterator].moveNext();
        this[_skipCount] = 0;
        return this[_iterator].moveNext();
      }
      get current() {
        return this[_iterator].current;
      }
    }
    dart.setSignature(SkipIterator, {
      constructors: () => ({SkipIterator: [SkipIterator$(E), [core.Iterator$(E), core.int]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return SkipIterator;
  });
  let SkipIterator = SkipIterator$();
  let SkipWhileIterable$ = dart.generic(function(E) {
    class SkipWhileIterable extends collection.IterableBase$(E) {
      SkipWhileIterable(iterable, f) {
        this[_iterable] = iterable;
        this[_f] = f;
        super.IterableBase();
      }
      get iterator() {
        return new (SkipWhileIterator$(E))(this[_iterable][dartx.iterator], this[_f]);
      }
    }
    dart.setSignature(SkipWhileIterable, {
      constructors: () => ({SkipWhileIterable: [SkipWhileIterable$(E), [core.Iterable$(E), dart.functionType(core.bool, [E])]]})
    });
    dart.defineExtensionMembers(SkipWhileIterable, ['iterator']);
    return SkipWhileIterable;
  });
  let SkipWhileIterable = SkipWhileIterable$();
  let _hasSkipped = dart.JsSymbol('_hasSkipped');
  let SkipWhileIterator$ = dart.generic(function(E) {
    class SkipWhileIterator extends core.Iterator$(E) {
      SkipWhileIterator(iterator, f) {
        this[_iterator] = iterator;
        this[_f] = f;
        this[_hasSkipped] = false;
      }
      moveNext() {
        if (!dart.notNull(this[_hasSkipped])) {
          this[_hasSkipped] = true;
          while (dart.notNull(this[_iterator].moveNext())) {
            if (!dart.notNull(this[_f](this[_iterator].current)))
              return true;
          }
        }
        return this[_iterator].moveNext();
      }
      get current() {
        return this[_iterator].current;
      }
    }
    dart.setSignature(SkipWhileIterator, {
      constructors: () => ({SkipWhileIterator: [SkipWhileIterator$(E), [core.Iterator$(E), dart.functionType(core.bool, [E])]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return SkipWhileIterator;
  });
  let SkipWhileIterator = SkipWhileIterator$();
  let EmptyIterable$ = dart.generic(function(E) {
    class EmptyIterable extends collection.IterableBase$(E) {
      EmptyIterable() {
        super.IterableBase();
      }
      get iterator() {
        return dart.const(new (EmptyIterator$(E))());
      }
      forEach(action) {
        dart.as(action, dart.functionType(dart.void, [E]));
      }
      get isEmpty() {
        return true;
      }
      get length() {
        return 0;
      }
      get first() {
        dart.throw(IterableElementError.noElement());
      }
      get last() {
        dart.throw(IterableElementError.noElement());
      }
      get single() {
        dart.throw(IterableElementError.noElement());
      }
      elementAt(index) {
        dart.throw(new core.RangeError.range(index, 0, 0, "index"));
      }
      contains(element) {
        return false;
      }
      every(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return true;
      }
      any(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return false;
      }
      firstWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        if (orElse != null)
          return orElse();
        dart.throw(IterableElementError.noElement());
      }
      lastWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        if (orElse != null)
          return orElse();
        dart.throw(IterableElementError.noElement());
      }
      singleWhere(test, opts) {
        dart.as(test, dart.functionType(core.bool, [E]));
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        dart.as(orElse, dart.functionType(E, []));
        if (orElse != null)
          return orElse();
        dart.throw(IterableElementError.noElement());
      }
      join(separator) {
        if (separator === void 0)
          separator = "";
        return "";
      }
      where(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this;
      }
      map(f) {
        dart.as(f, dart.functionType(dart.dynamic, [E]));
        return dart.const(new (EmptyIterable$())());
      }
      reduce(combine) {
        dart.as(combine, dart.functionType(E, [E, E]));
        dart.throw(IterableElementError.noElement());
      }
      fold(initialValue, combine) {
        dart.as(combine, dart.functionType(dart.dynamic, [dart.dynamic, E]));
        return initialValue;
      }
      skip(count) {
        core.RangeError.checkNotNegative(count, "count");
        return this;
      }
      skipWhile(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this;
      }
      take(count) {
        core.RangeError.checkNotNegative(count, "count");
        return this;
      }
      takeWhile(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        return this;
      }
      toList(opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        return dart.notNull(growable) ? dart.list([], E) : core.List$(E).new(0);
      }
      toSet() {
        return core.Set$(E).new();
      }
    }
    EmptyIterable[dart.implements] = () => [EfficientLength];
    dart.setSignature(EmptyIterable, {
      constructors: () => ({EmptyIterable: [EmptyIterable$(E), []]}),
      methods: () => ({
        forEach: [dart.void, [dart.functionType(dart.void, [E])]],
        elementAt: [E, [core.int]],
        every: [core.bool, [dart.functionType(core.bool, [E])]],
        any: [core.bool, [dart.functionType(core.bool, [E])]],
        firstWhere: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        lastWhere: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        singleWhere: [E, [dart.functionType(core.bool, [E])], {orElse: dart.functionType(E, [])}],
        where: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        map: [core.Iterable, [dart.functionType(dart.dynamic, [E])]],
        reduce: [E, [dart.functionType(E, [E, E])]],
        fold: [dart.dynamic, [dart.dynamic, dart.functionType(dart.dynamic, [dart.dynamic, E])]],
        skip: [core.Iterable$(E), [core.int]],
        skipWhile: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        take: [core.Iterable$(E), [core.int]],
        takeWhile: [core.Iterable$(E), [dart.functionType(core.bool, [E])]],
        toList: [core.List$(E), [], {growable: core.bool}],
        toSet: [core.Set$(E), []]
      })
    });
    dart.defineExtensionMembers(EmptyIterable, [
      'forEach',
      'elementAt',
      'contains',
      'every',
      'any',
      'firstWhere',
      'lastWhere',
      'singleWhere',
      'join',
      'where',
      'map',
      'reduce',
      'fold',
      'skip',
      'skipWhile',
      'take',
      'takeWhile',
      'toList',
      'toSet',
      'iterator',
      'isEmpty',
      'length',
      'first',
      'last',
      'single'
    ]);
    return EmptyIterable;
  });
  let EmptyIterable = EmptyIterable$();
  let EmptyIterator$ = dart.generic(function(E) {
    class EmptyIterator extends core.Object {
      EmptyIterator() {
      }
      moveNext() {
        return false;
      }
      get current() {
        return null;
      }
    }
    EmptyIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(EmptyIterator, {
      constructors: () => ({EmptyIterator: [EmptyIterator$(E), []]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return EmptyIterator;
  });
  let EmptyIterator = EmptyIterator$();
  let BidirectionalIterator$ = dart.generic(function(T) {
    class BidirectionalIterator extends core.Object {}
    BidirectionalIterator[dart.implements] = () => [core.Iterator$(T)];
    return BidirectionalIterator;
  });
  let BidirectionalIterator = BidirectionalIterator$();
  let IterableMixinWorkaround$ = dart.generic(function(T) {
    class IterableMixinWorkaround extends core.Object {
      static contains(iterable, element) {
        for (let e of iterable) {
          if (dart.equals(e, element))
            return true;
        }
        return false;
      }
      static forEach(iterable, f) {
        dart.as(f, dart.functionType(dart.void, [dart.dynamic]));
        for (let e of iterable) {
          dart.dcall(f, e);
        }
      }
      static any(iterable, f) {
        dart.as(f, dart.functionType(core.bool, [dart.dynamic]));
        for (let e of iterable) {
          if (dart.notNull(dart.dcall(f, e)))
            return true;
        }
        return false;
      }
      static every(iterable, f) {
        dart.as(f, dart.functionType(core.bool, [dart.dynamic]));
        for (let e of iterable) {
          if (!dart.notNull(dart.dcall(f, e)))
            return false;
        }
        return true;
      }
      static reduce(iterable, combine) {
        dart.as(combine, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
        let iterator = iterable[dartx.iterator];
        if (!dart.notNull(iterator.moveNext()))
          dart.throw(IterableElementError.noElement());
        let value = iterator.current;
        while (dart.notNull(iterator.moveNext())) {
          value = dart.dcall(combine, value, iterator.current);
        }
        return value;
      }
      static fold(iterable, initialValue, combine) {
        dart.as(combine, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
        for (let element of iterable) {
          initialValue = dart.dcall(combine, initialValue, element);
        }
        return initialValue;
      }
      static removeWhereList(list, test) {
        dart.as(test, dart.functionType(core.bool, [dart.dynamic]));
        let retained = [];
        let length = list[dartx.length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let element = list[dartx.get](i);
          if (!dart.notNull(dart.dcall(test, element))) {
            retained[dartx.add](element);
          }
          if (length != list[dartx.length]) {
            dart.throw(new core.ConcurrentModificationError(list));
          }
        }
        if (retained[dartx.length] == length)
          return;
        list[dartx.length] = retained[dartx.length];
        for (let i = 0; dart.notNull(i) < dart.notNull(retained[dartx.length]); i = dart.notNull(i) + 1) {
          list[dartx.set](i, retained[dartx.get](i));
        }
      }
      static isEmpty(iterable) {
        return !dart.notNull(iterable[dartx.iterator].moveNext());
      }
      static first(iterable) {
        let it = iterable[dartx.iterator];
        if (!dart.notNull(it.moveNext())) {
          dart.throw(IterableElementError.noElement());
        }
        return it.current;
      }
      static last(iterable) {
        let it = iterable[dartx.iterator];
        if (!dart.notNull(it.moveNext())) {
          dart.throw(IterableElementError.noElement());
        }
        let result = null;
        do {
          result = it.current;
        } while (dart.notNull(it.moveNext()));
        return result;
      }
      static single(iterable) {
        let it = iterable[dartx.iterator];
        if (!dart.notNull(it.moveNext()))
          dart.throw(IterableElementError.noElement());
        let result = it.current;
        if (dart.notNull(it.moveNext()))
          dart.throw(IterableElementError.tooMany());
        return result;
      }
      static firstWhere(iterable, test, orElse) {
        dart.as(test, dart.functionType(core.bool, [dart.dynamic]));
        dart.as(orElse, dart.functionType(dart.dynamic, []));
        for (let element of iterable) {
          if (dart.notNull(dart.dcall(test, element)))
            return element;
        }
        if (orElse != null)
          return orElse();
        dart.throw(IterableElementError.noElement());
      }
      static lastWhere(iterable, test, orElse) {
        dart.as(test, dart.functionType(core.bool, [dart.dynamic]));
        dart.as(orElse, dart.functionType(dart.dynamic, []));
        let result = null;
        let foundMatching = false;
        for (let element of iterable) {
          if (dart.notNull(dart.dcall(test, element))) {
            result = element;
            foundMatching = true;
          }
        }
        if (dart.notNull(foundMatching))
          return result;
        if (orElse != null)
          return orElse();
        dart.throw(IterableElementError.noElement());
      }
      static lastWhereList(list, test, orElse) {
        dart.as(test, dart.functionType(core.bool, [dart.dynamic]));
        dart.as(orElse, dart.functionType(dart.dynamic, []));
        for (let i = dart.notNull(list[dartx.length]) - 1; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
          let element = list[dartx.get](i);
          if (dart.notNull(dart.dcall(test, element)))
            return element;
        }
        if (orElse != null)
          return orElse();
        dart.throw(IterableElementError.noElement());
      }
      static singleWhere(iterable, test) {
        dart.as(test, dart.functionType(core.bool, [dart.dynamic]));
        let result = null;
        let foundMatching = false;
        for (let element of iterable) {
          if (dart.notNull(dart.dcall(test, element))) {
            if (dart.notNull(foundMatching)) {
              dart.throw(IterableElementError.tooMany());
            }
            result = element;
            foundMatching = true;
          }
        }
        if (dart.notNull(foundMatching))
          return result;
        dart.throw(IterableElementError.noElement());
      }
      static elementAt(iterable, index) {
        if (!(typeof index == 'number'))
          dart.throw(new core.ArgumentError.notNull("index"));
        core.RangeError.checkNotNegative(index, "index");
        let elementIndex = 0;
        for (let element of iterable) {
          if (index == elementIndex)
            return element;
          elementIndex = dart.notNull(elementIndex) + 1;
        }
        dart.throw(core.RangeError.index(index, iterable, "index", null, elementIndex));
      }
      static join(iterable, separator) {
        if (separator === void 0)
          separator = null;
        let buffer = new core.StringBuffer();
        buffer.writeAll(iterable, separator);
        return dart.toString(buffer);
      }
      static joinList(list, separator) {
        if (separator === void 0)
          separator = null;
        if (dart.notNull(list[dartx.isEmpty]))
          return "";
        if (list[dartx.length] == 1)
          return `${list[dartx.get](0)}`;
        let buffer = new core.StringBuffer();
        if (dart.notNull(separator[dartx.isEmpty])) {
          for (let i = 0; dart.notNull(i) < dart.notNull(list[dartx.length]); i = dart.notNull(i) + 1) {
            buffer.write(list[dartx.get](i));
          }
        } else {
          buffer.write(list[dartx.get](0));
          for (let i = 1; dart.notNull(i) < dart.notNull(list[dartx.length]); i = dart.notNull(i) + 1) {
            buffer.write(separator);
            buffer.write(list[dartx.get](i));
          }
        }
        return dart.toString(buffer);
      }
      where(iterable, f) {
        dart.as(f, dart.functionType(core.bool, [dart.dynamic]));
        return new (WhereIterable$(T))(dart.as(iterable, core.Iterable$(T)), dart.as(f, __CastType2));
      }
      static map(iterable, f) {
        dart.as(f, dart.functionType(dart.dynamic, [dart.dynamic]));
        return MappedIterable.new(iterable, f);
      }
      static mapList(list, f) {
        dart.as(f, dart.functionType(dart.dynamic, [dart.dynamic]));
        return new MappedListIterable(list, f);
      }
      static expand(iterable, f) {
        dart.as(f, dart.functionType(core.Iterable, [dart.dynamic]));
        return new ExpandIterable(iterable, f);
      }
      takeList(list, n) {
        return new (SubListIterable$(T))(dart.as(list, core.Iterable$(T)), 0, n);
      }
      takeWhile(iterable, test) {
        dart.as(test, dart.functionType(core.bool, [dart.dynamic]));
        return new (TakeWhileIterable$(T))(dart.as(iterable, core.Iterable$(T)), dart.as(test, dart.functionType(core.bool, [T])));
      }
      skipList(list, n) {
        return new (SubListIterable$(T))(dart.as(list, core.Iterable$(T)), n, null);
      }
      skipWhile(iterable, test) {
        dart.as(test, dart.functionType(core.bool, [dart.dynamic]));
        return new (SkipWhileIterable$(T))(dart.as(iterable, core.Iterable$(T)), dart.as(test, dart.functionType(core.bool, [T])));
      }
      reversedList(list) {
        return new (ReversedListIterable$(T))(dart.as(list, core.Iterable$(T)));
      }
      static sortList(list, compare) {
        dart.as(compare, dart.functionType(core.int, [dart.dynamic, dart.dynamic]));
        if (compare == null)
          compare = core.Comparable.compare;
        Sort.sort(list, compare);
      }
      static shuffleList(list, random) {
        if (random == null)
          random = math.Random.new();
        let length = list[dartx.length];
        while (dart.notNull(length) > 1) {
          let pos = random.nextInt(length);
          length = dart.notNull(length) - 1;
          let tmp = list[dartx.get](length);
          list[dartx.set](length, list[dartx.get](pos));
          list[dartx.set](pos, tmp);
        }
      }
      static indexOfList(list, element, start) {
        return Lists.indexOf(list, element, start, list[dartx.length]);
      }
      static lastIndexOfList(list, element, start) {
        if (start == null)
          start = dart.notNull(list[dartx.length]) - 1;
        return Lists.lastIndexOf(list, element, start);
      }
      static _rangeCheck(list, start, end) {
        core.RangeError.checkValidRange(start, end, list[dartx.length]);
      }
      getRangeList(list, start, end) {
        IterableMixinWorkaround$()._rangeCheck(list, start, end);
        return new (SubListIterable$(T))(dart.as(list, core.Iterable$(T)), start, end);
      }
      static setRangeList(list, start, end, from, skipCount) {
        IterableMixinWorkaround$()._rangeCheck(list, start, end);
        let length = dart.notNull(end) - dart.notNull(start);
        if (length == 0)
          return;
        if (dart.notNull(skipCount) < 0)
          dart.throw(new core.ArgumentError(skipCount));
        let otherList = null;
        let otherStart = null;
        if (dart.is(from, core.List)) {
          otherList = from;
          otherStart = skipCount;
        } else {
          otherList = from[dartx.skip](skipCount)[dartx.toList]({growable: false});
          otherStart = 0;
        }
        if (dart.notNull(otherStart) + dart.notNull(length) > dart.notNull(otherList[dartx.length])) {
          dart.throw(IterableElementError.tooFew());
        }
        Lists.copy(otherList, otherStart, list, start, length);
      }
      static replaceRangeList(list, start, end, iterable) {
        IterableMixinWorkaround$()._rangeCheck(list, start, end);
        if (!dart.is(iterable, EfficientLength)) {
          iterable = iterable[dartx.toList]();
        }
        let removeLength = dart.notNull(end) - dart.notNull(start);
        let insertLength = iterable[dartx.length];
        if (dart.notNull(removeLength) >= dart.notNull(insertLength)) {
          let delta = dart.notNull(removeLength) - dart.notNull(insertLength);
          let insertEnd = dart.notNull(start) + dart.notNull(insertLength);
          let newEnd = dart.notNull(list[dartx.length]) - dart.notNull(delta);
          list[dartx.setRange](start, insertEnd, iterable);
          if (delta != 0) {
            list[dartx.setRange](insertEnd, newEnd, list, end);
            list[dartx.length] = newEnd;
          }
        } else {
          let delta = dart.notNull(insertLength) - dart.notNull(removeLength);
          let newLength = dart.notNull(list[dartx.length]) + dart.notNull(delta);
          let insertEnd = dart.notNull(start) + dart.notNull(insertLength);
          list[dartx.length] = newLength;
          list[dartx.setRange](insertEnd, newLength, list, end);
          list[dartx.setRange](start, insertEnd, iterable);
        }
      }
      static fillRangeList(list, start, end, fillValue) {
        IterableMixinWorkaround$()._rangeCheck(list, start, end);
        for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
          list[dartx.set](i, fillValue);
        }
      }
      static insertAllList(list, index, iterable) {
        core.RangeError.checkValueInInterval(index, 0, list[dartx.length], "index");
        if (!dart.is(iterable, EfficientLength)) {
          iterable = iterable[dartx.toList]({growable: false});
        }
        let insertionLength = iterable[dartx.length];
        list[dartx.length] = dart.notNull(list[dartx.length]) + dart.notNull(insertionLength);
        list[dartx.setRange](dart.notNull(index) + dart.notNull(insertionLength), list[dartx.length], list, index);
        for (let element of iterable) {
          list[dartx.set]((() => {
            let x = index;
            index = dart.notNull(x) + 1;
            return x;
          })(), element);
        }
      }
      static setAllList(list, index, iterable) {
        core.RangeError.checkValueInInterval(index, 0, list[dartx.length], "index");
        for (let element of iterable) {
          list[dartx.set]((() => {
            let x = index;
            index = dart.notNull(x) + 1;
            return x;
          })(), element);
        }
      }
      asMapList(l) {
        return new (ListMapView$(T))(dart.as(l, core.List$(T)));
      }
      static setContainsAll(set, other) {
        for (let element of other) {
          if (!dart.notNull(set.contains(element)))
            return false;
        }
        return true;
      }
      static setIntersection(set, other, result) {
        let smaller = null;
        let larger = null;
        if (dart.notNull(set.length) < dart.notNull(other.length)) {
          smaller = set;
          larger = other;
        } else {
          smaller = other;
          larger = set;
        }
        for (let element of smaller) {
          if (dart.notNull(larger.contains(element))) {
            result.add(element);
          }
        }
        return result;
      }
      static setUnion(set, other, result) {
        result.addAll(set);
        result.addAll(other);
        return result;
      }
      static setDifference(set, other, result) {
        for (let element of set) {
          if (!dart.notNull(other.contains(element))) {
            result.add(element);
          }
        }
        return result;
      }
    }
    dart.setSignature(IterableMixinWorkaround, {
      methods: () => ({
        where: [core.Iterable$(T), [core.Iterable, dart.functionType(core.bool, [dart.dynamic])]],
        takeList: [core.Iterable$(T), [core.List, core.int]],
        takeWhile: [core.Iterable$(T), [core.Iterable, dart.functionType(core.bool, [dart.dynamic])]],
        skipList: [core.Iterable$(T), [core.List, core.int]],
        skipWhile: [core.Iterable$(T), [core.Iterable, dart.functionType(core.bool, [dart.dynamic])]],
        reversedList: [core.Iterable$(T), [core.List]],
        getRangeList: [core.Iterable$(T), [core.List, core.int, core.int]],
        asMapList: [core.Map$(core.int, T), [core.List]]
      }),
      statics: () => ({
        contains: [core.bool, [core.Iterable, dart.dynamic]],
        forEach: [dart.void, [core.Iterable, dart.functionType(dart.void, [dart.dynamic])]],
        any: [core.bool, [core.Iterable, dart.functionType(core.bool, [dart.dynamic])]],
        every: [core.bool, [core.Iterable, dart.functionType(core.bool, [dart.dynamic])]],
        reduce: [dart.dynamic, [core.Iterable, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]],
        fold: [dart.dynamic, [core.Iterable, dart.dynamic, dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]],
        removeWhereList: [dart.void, [core.List, dart.functionType(core.bool, [dart.dynamic])]],
        isEmpty: [core.bool, [core.Iterable]],
        first: [dart.dynamic, [core.Iterable]],
        last: [dart.dynamic, [core.Iterable]],
        single: [dart.dynamic, [core.Iterable]],
        firstWhere: [dart.dynamic, [core.Iterable, dart.functionType(core.bool, [dart.dynamic]), dart.functionType(dart.dynamic, [])]],
        lastWhere: [dart.dynamic, [core.Iterable, dart.functionType(core.bool, [dart.dynamic]), dart.functionType(dart.dynamic, [])]],
        lastWhereList: [dart.dynamic, [core.List, dart.functionType(core.bool, [dart.dynamic]), dart.functionType(dart.dynamic, [])]],
        singleWhere: [dart.dynamic, [core.Iterable, dart.functionType(core.bool, [dart.dynamic])]],
        elementAt: [dart.dynamic, [core.Iterable, core.int]],
        join: [core.String, [core.Iterable], [core.String]],
        joinList: [core.String, [core.List], [core.String]],
        map: [core.Iterable, [core.Iterable, dart.functionType(dart.dynamic, [dart.dynamic])]],
        mapList: [core.Iterable, [core.List, dart.functionType(dart.dynamic, [dart.dynamic])]],
        expand: [core.Iterable, [core.Iterable, dart.functionType(core.Iterable, [dart.dynamic])]],
        sortList: [dart.void, [core.List, dart.functionType(core.int, [dart.dynamic, dart.dynamic])]],
        shuffleList: [dart.void, [core.List, math.Random]],
        indexOfList: [core.int, [core.List, dart.dynamic, core.int]],
        lastIndexOfList: [core.int, [core.List, dart.dynamic, core.int]],
        _rangeCheck: [dart.void, [core.List, core.int, core.int]],
        setRangeList: [dart.void, [core.List, core.int, core.int, core.Iterable, core.int]],
        replaceRangeList: [dart.void, [core.List, core.int, core.int, core.Iterable]],
        fillRangeList: [dart.void, [core.List, core.int, core.int, dart.dynamic]],
        insertAllList: [dart.void, [core.List, core.int, core.Iterable]],
        setAllList: [dart.void, [core.List, core.int, core.Iterable]],
        setContainsAll: [core.bool, [core.Set, core.Iterable]],
        setIntersection: [core.Set, [core.Set, core.Set, core.Set]],
        setUnion: [core.Set, [core.Set, core.Set, core.Set]],
        setDifference: [core.Set, [core.Set, core.Set, core.Set]]
      }),
      names: ['contains', 'forEach', 'any', 'every', 'reduce', 'fold', 'removeWhereList', 'isEmpty', 'first', 'last', 'single', 'firstWhere', 'lastWhere', 'lastWhereList', 'singleWhere', 'elementAt', 'join', 'joinList', 'map', 'mapList', 'expand', 'sortList', 'shuffleList', 'indexOfList', 'lastIndexOfList', '_rangeCheck', 'setRangeList', 'replaceRangeList', 'fillRangeList', 'insertAllList', 'setAllList', 'setContainsAll', 'setIntersection', 'setUnion', 'setDifference']
    });
    return IterableMixinWorkaround;
  });
  let IterableMixinWorkaround = IterableMixinWorkaround$();
  class IterableElementError extends core.Object {
    static noElement() {
      return new core.StateError("No element");
    }
    static tooMany() {
      return new core.StateError("Too many elements");
    }
    static tooFew() {
      return new core.StateError("Too few elements");
    }
  }
  dart.setSignature(IterableElementError, {
    statics: () => ({
      noElement: [core.StateError, []],
      tooMany: [core.StateError, []],
      tooFew: [core.StateError, []]
    }),
    names: ['noElement', 'tooMany', 'tooFew']
  });
  let __CastType0$ = dart.generic(function(S, T) {
    let __CastType0 = dart.typedef('__CastType0', () => dart.functionType(core.Iterable$(T), [S]));
    return __CastType0;
  });
  let __CastType0 = __CastType0$();
  let __CastType2$ = dart.generic(function(T) {
    let __CastType2 = dart.typedef('__CastType2', () => dart.functionType(core.bool, [T]));
    return __CastType2;
  });
  let __CastType2 = __CastType2$();
  let FixedLengthListMixin$ = dart.generic(function(E) {
    class FixedLengthListMixin extends core.Object {
      set length(newLength) {
        dart.throw(new core.UnsupportedError("Cannot change the length of a fixed-length list"));
      }
      add(value) {
        dart.as(value, E);
        dart.throw(new core.UnsupportedError("Cannot add to a fixed-length list"));
      }
      insert(index, value) {
        dart.as(value, E);
        dart.throw(new core.UnsupportedError("Cannot add to a fixed-length list"));
      }
      insertAll(at, iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot add to a fixed-length list"));
      }
      addAll(iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot add to a fixed-length list"));
      }
      remove(element) {
        dart.throw(new core.UnsupportedError("Cannot remove from a fixed-length list"));
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        dart.throw(new core.UnsupportedError("Cannot remove from a fixed-length list"));
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        dart.throw(new core.UnsupportedError("Cannot remove from a fixed-length list"));
      }
      clear() {
        dart.throw(new core.UnsupportedError("Cannot clear a fixed-length list"));
      }
      removeAt(index) {
        dart.throw(new core.UnsupportedError("Cannot remove from a fixed-length list"));
      }
      removeLast() {
        dart.throw(new core.UnsupportedError("Cannot remove from a fixed-length list"));
      }
      removeRange(start, end) {
        dart.throw(new core.UnsupportedError("Cannot remove from a fixed-length list"));
      }
      replaceRange(start, end, iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot remove from a fixed-length list"));
      }
    }
    dart.setSignature(FixedLengthListMixin, {
      methods: () => ({
        add: [dart.void, [E]],
        insert: [dart.void, [core.int, E]],
        insertAll: [dart.void, [core.int, core.Iterable$(E)]],
        addAll: [dart.void, [core.Iterable$(E)]],
        remove: [core.bool, [core.Object]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        clear: [dart.void, []],
        removeAt: [E, [core.int]],
        removeLast: [E, []],
        removeRange: [dart.void, [core.int, core.int]],
        replaceRange: [dart.void, [core.int, core.int, core.Iterable$(E)]]
      })
    });
    return FixedLengthListMixin;
  });
  let FixedLengthListMixin = FixedLengthListMixin$();
  let UnmodifiableListMixin$ = dart.generic(function(E) {
    class UnmodifiableListMixin extends core.Object {
      set(index, value) {
        dart.as(value, E);
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable list"));
        return value;
      }
      set length(newLength) {
        dart.throw(new core.UnsupportedError("Cannot change the length of an unmodifiable list"));
      }
      setAll(at, iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable list"));
      }
      add(value) {
        dart.as(value, E);
        dart.throw(new core.UnsupportedError("Cannot add to an unmodifiable list"));
      }
      insert(index, value) {
        dart.as(value, E);
        dart.throw(new core.UnsupportedError("Cannot add to an unmodifiable list"));
      }
      insertAll(at, iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot add to an unmodifiable list"));
      }
      addAll(iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot add to an unmodifiable list"));
      }
      remove(element) {
        dart.throw(new core.UnsupportedError("Cannot remove from an unmodifiable list"));
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        dart.throw(new core.UnsupportedError("Cannot remove from an unmodifiable list"));
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        dart.throw(new core.UnsupportedError("Cannot remove from an unmodifiable list"));
      }
      sort(compare) {
        if (compare === void 0)
          compare = null;
        dart.as(compare, core.Comparator$(E));
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable list"));
      }
      shuffle(random) {
        if (random === void 0)
          random = null;
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable list"));
      }
      clear() {
        dart.throw(new core.UnsupportedError("Cannot clear an unmodifiable list"));
      }
      removeAt(index) {
        dart.throw(new core.UnsupportedError("Cannot remove from an unmodifiable list"));
      }
      removeLast() {
        dart.throw(new core.UnsupportedError("Cannot remove from an unmodifiable list"));
      }
      setRange(start, end, iterable, skipCount) {
        dart.as(iterable, core.Iterable$(E));
        if (skipCount === void 0)
          skipCount = 0;
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable list"));
      }
      removeRange(start, end) {
        dart.throw(new core.UnsupportedError("Cannot remove from an unmodifiable list"));
      }
      replaceRange(start, end, iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot remove from an unmodifiable list"));
      }
      fillRange(start, end, fillValue) {
        if (fillValue === void 0)
          fillValue = null;
        dart.as(fillValue, E);
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable list"));
      }
    }
    UnmodifiableListMixin[dart.implements] = () => [core.List$(E)];
    dart.setSignature(UnmodifiableListMixin, {
      methods: () => ({
        set: [dart.void, [core.int, E]],
        setAll: [dart.void, [core.int, core.Iterable$(E)]],
        add: [dart.void, [E]],
        insert: [E, [core.int, E]],
        insertAll: [dart.void, [core.int, core.Iterable$(E)]],
        addAll: [dart.void, [core.Iterable$(E)]],
        remove: [core.bool, [core.Object]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        sort: [dart.void, [], [core.Comparator$(E)]],
        shuffle: [dart.void, [], [math.Random]],
        clear: [dart.void, []],
        removeAt: [E, [core.int]],
        removeLast: [E, []],
        setRange: [dart.void, [core.int, core.int, core.Iterable$(E)], [core.int]],
        removeRange: [dart.void, [core.int, core.int]],
        replaceRange: [dart.void, [core.int, core.int, core.Iterable$(E)]],
        fillRange: [dart.void, [core.int, core.int], [E]]
      })
    });
    dart.defineExtensionMembers(UnmodifiableListMixin, [
      'set',
      'setAll',
      'add',
      'insert',
      'insertAll',
      'addAll',
      'remove',
      'removeWhere',
      'retainWhere',
      'sort',
      'shuffle',
      'clear',
      'removeAt',
      'removeLast',
      'setRange',
      'removeRange',
      'replaceRange',
      'fillRange',
      'length'
    ]);
    return UnmodifiableListMixin;
  });
  let UnmodifiableListMixin = UnmodifiableListMixin$();
  let FixedLengthListBase$ = dart.generic(function(E) {
    class FixedLengthListBase extends dart.mixin(collection.ListBase$(E), FixedLengthListMixin$(E)) {
      FixedLengthListBase() {
        super.ListBase(...arguments);
      }
    }
    return FixedLengthListBase;
  });
  let FixedLengthListBase = FixedLengthListBase$();
  let UnmodifiableListBase$ = dart.generic(function(E) {
    class UnmodifiableListBase extends dart.mixin(collection.ListBase$(E), UnmodifiableListMixin$(E)) {
      UnmodifiableListBase() {
        super.ListBase(...arguments);
      }
    }
    return UnmodifiableListBase;
  });
  let UnmodifiableListBase = UnmodifiableListBase$();
  let _backedList = dart.JsSymbol('_backedList');
  class _ListIndicesIterable extends ListIterable$(core.int) {
    _ListIndicesIterable(backedList) {
      this[_backedList] = backedList;
      super.ListIterable();
    }
    get length() {
      return this[_backedList][dartx.length];
    }
    elementAt(index) {
      core.RangeError.checkValidIndex(index, this);
      return index;
    }
  }
  dart.setSignature(_ListIndicesIterable, {
    constructors: () => ({_ListIndicesIterable: [_ListIndicesIterable, [core.List]]}),
    methods: () => ({elementAt: [core.int, [core.int]]})
  });
  dart.defineExtensionMembers(_ListIndicesIterable, ['elementAt', 'length']);
  let _values = dart.JsSymbol('_values');
  let ListMapView$ = dart.generic(function(E) {
    class ListMapView extends core.Object {
      ListMapView(values) {
        this[_values] = values;
      }
      get(key) {
        return dart.notNull(this.containsKey(key)) ? this[_values][dartx.get](dart.as(key, core.int)) : null;
      }
      get length() {
        return this[_values][dartx.length];
      }
      get values() {
        return new (SubListIterable$(E))(this[_values], 0, null);
      }
      get keys() {
        return new _ListIndicesIterable(this[_values]);
      }
      get isEmpty() {
        return this[_values][dartx.isEmpty];
      }
      get isNotEmpty() {
        return this[_values][dartx.isNotEmpty];
      }
      containsValue(value) {
        return this[_values][dartx.contains](value);
      }
      containsKey(key) {
        return typeof key == 'number' && dart.notNull(key) >= 0 && dart.notNull(key) < dart.notNull(this.length);
      }
      forEach(f) {
        dart.as(f, dart.functionType(dart.void, [core.int, E]));
        let length = this[_values][dartx.length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          f(i, this[_values][dartx.get](i));
          if (length != this[_values][dartx.length]) {
            dart.throw(new core.ConcurrentModificationError(this[_values]));
          }
        }
      }
      set(key, value) {
        dart.as(value, E);
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable map"));
        return value;
      }
      putIfAbsent(key, ifAbsent) {
        dart.as(ifAbsent, dart.functionType(E, []));
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable map"));
      }
      remove(key) {
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable map"));
      }
      clear() {
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable map"));
      }
      addAll(other) {
        dart.as(other, core.Map$(core.int, E));
        dart.throw(new core.UnsupportedError("Cannot modify an unmodifiable map"));
      }
      toString() {
        return collection.Maps.mapToString(this);
      }
    }
    ListMapView[dart.implements] = () => [core.Map$(core.int, E)];
    dart.setSignature(ListMapView, {
      constructors: () => ({ListMapView: [ListMapView$(E), [core.List$(E)]]}),
      methods: () => ({
        get: [E, [core.Object]],
        containsValue: [core.bool, [core.Object]],
        containsKey: [core.bool, [core.Object]],
        forEach: [dart.void, [dart.functionType(dart.void, [core.int, E])]],
        set: [dart.void, [core.int, E]],
        putIfAbsent: [E, [core.int, dart.functionType(E, [])]],
        remove: [E, [core.Object]],
        clear: [dart.void, []],
        addAll: [dart.void, [core.Map$(core.int, E)]]
      })
    });
    return ListMapView;
  });
  let ListMapView = ListMapView$();
  let ReversedListIterable$ = dart.generic(function(E) {
    class ReversedListIterable extends ListIterable$(E) {
      ReversedListIterable(source) {
        this[_source] = source;
        super.ListIterable();
      }
      get length() {
        return this[_source][dartx.length];
      }
      elementAt(index) {
        return this[_source][dartx.elementAt](dart.notNull(this[_source][dartx.length]) - 1 - dart.notNull(index));
      }
    }
    dart.setSignature(ReversedListIterable, {
      constructors: () => ({ReversedListIterable: [ReversedListIterable$(E), [core.Iterable$(E)]]}),
      methods: () => ({elementAt: [E, [core.int]]})
    });
    dart.defineExtensionMembers(ReversedListIterable, ['elementAt', 'length']);
    return ReversedListIterable;
  });
  let ReversedListIterable = ReversedListIterable$();
  class UnmodifiableListError extends core.Object {
    static add() {
      return new core.UnsupportedError("Cannot add to unmodifiable List");
    }
    static change() {
      return new core.UnsupportedError("Cannot change the content of an unmodifiable List");
    }
    static length() {
      return new core.UnsupportedError("Cannot change length of unmodifiable List");
    }
    static remove() {
      return new core.UnsupportedError("Cannot remove from unmodifiable List");
    }
  }
  dart.setSignature(UnmodifiableListError, {
    statics: () => ({
      add: [core.UnsupportedError, []],
      change: [core.UnsupportedError, []],
      length: [core.UnsupportedError, []],
      remove: [core.UnsupportedError, []]
    }),
    names: ['add', 'change', 'length', 'remove']
  });
  class NonGrowableListError extends core.Object {
    static add() {
      return new core.UnsupportedError("Cannot add to non-growable List");
    }
    static length() {
      return new core.UnsupportedError("Cannot change length of non-growable List");
    }
    static remove() {
      return new core.UnsupportedError("Cannot remove from non-growable List");
    }
  }
  dart.setSignature(NonGrowableListError, {
    statics: () => ({
      add: [core.UnsupportedError, []],
      length: [core.UnsupportedError, []],
      remove: [core.UnsupportedError, []]
    }),
    names: ['add', 'length', 'remove']
  });
  function makeListFixedLength(growableList) {
    _interceptors.JSArray.markFixedList(growableList);
    return growableList;
  }
  dart.fn(makeListFixedLength, core.List, [core.List]);
  class Lists extends core.Object {
    static copy(src, srcStart, dst, dstStart, count) {
      if (dart.notNull(srcStart) < dart.notNull(dstStart)) {
        for (let i = dart.notNull(srcStart) + dart.notNull(count) - 1, j = dart.notNull(dstStart) + dart.notNull(count) - 1; dart.notNull(i) >= dart.notNull(srcStart); i = dart.notNull(i) - 1, j = dart.notNull(j) - 1) {
          dst[dartx.set](j, src[dartx.get](i));
        }
      } else {
        for (let i = srcStart, j = dstStart; dart.notNull(i) < dart.notNull(srcStart) + dart.notNull(count); i = dart.notNull(i) + 1, j = dart.notNull(j) + 1) {
          dst[dartx.set](j, src[dartx.get](i));
        }
      }
    }
    static areEqual(a, b) {
      if (dart.notNull(core.identical(a, b)))
        return true;
      if (!dart.is(b, core.List))
        return false;
      let length = a[dartx.length];
      if (!dart.equals(length, dart.dload(b, 'length')))
        return false;
      for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
        if (!dart.notNull(core.identical(a[dartx.get](i), dart.dindex(b, i))))
          return false;
      }
      return true;
    }
    static indexOf(a, element, startIndex, endIndex) {
      if (dart.notNull(startIndex) >= dart.notNull(a[dartx.length])) {
        return -1;
      }
      if (dart.notNull(startIndex) < 0) {
        startIndex = 0;
      }
      for (let i = startIndex; dart.notNull(i) < dart.notNull(endIndex); i = dart.notNull(i) + 1) {
        if (dart.equals(a[dartx.get](i), element)) {
          return i;
        }
      }
      return -1;
    }
    static lastIndexOf(a, element, startIndex) {
      if (dart.notNull(startIndex) < 0) {
        return -1;
      }
      if (dart.notNull(startIndex) >= dart.notNull(a[dartx.length])) {
        startIndex = dart.notNull(a[dartx.length]) - 1;
      }
      for (let i = startIndex; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
        if (dart.equals(a[dartx.get](i), element)) {
          return i;
        }
      }
      return -1;
    }
    static indicesCheck(a, start, end) {
      core.RangeError.checkValidRange(start, end, a[dartx.length]);
    }
    static rangeCheck(a, start, length) {
      core.RangeError.checkNotNegative(length);
      core.RangeError.checkNotNegative(start);
      if (dart.notNull(start) + dart.notNull(length) > dart.notNull(a[dartx.length])) {
        let message = `${start} + ${length} must be in the range [0..${a[dartx.length]}]`;
        dart.throw(new core.RangeError.range(length, 0, dart.notNull(a[dartx.length]) - dart.notNull(start), "length", message));
      }
    }
  }
  dart.setSignature(Lists, {
    statics: () => ({
      copy: [dart.void, [core.List, core.int, core.List, core.int, core.int]],
      areEqual: [core.bool, [core.List, dart.dynamic]],
      indexOf: [core.int, [core.List, core.Object, core.int, core.int]],
      lastIndexOf: [core.int, [core.List, core.Object, core.int]],
      indicesCheck: [dart.void, [core.List, core.int, core.int]],
      rangeCheck: [dart.void, [core.List, core.int, core.int]]
    }),
    names: ['copy', 'areEqual', 'indexOf', 'lastIndexOf', 'indicesCheck', 'rangeCheck']
  });
  exports.printToZone = null;
  function printToConsole(line) {
    _js_primitives.printString(`${line}`);
  }
  dart.fn(printToConsole, dart.void, [core.String]);
  class Sort extends core.Object {
    static sort(a, compare) {
      Sort._doSort(a, 0, dart.notNull(a[dartx.length]) - 1, compare);
    }
    static sortRange(a, from, to, compare) {
      if (dart.notNull(from) < 0 || dart.notNull(to) > dart.notNull(a[dartx.length]) || dart.notNull(to) < dart.notNull(from)) {
        dart.throw("OutOfRange");
      }
      Sort._doSort(a, from, dart.notNull(to) - 1, compare);
    }
    static _doSort(a, left, right, compare) {
      if (dart.notNull(right) - dart.notNull(left) <= dart.notNull(Sort._INSERTION_SORT_THRESHOLD)) {
        Sort._insertionSort(a, left, right, compare);
      } else {
        Sort._dualPivotQuicksort(a, left, right, compare);
      }
    }
    static _insertionSort(a, left, right, compare) {
      for (let i = dart.notNull(left) + 1; dart.notNull(i) <= dart.notNull(right); i = dart.notNull(i) + 1) {
        let el = a[dartx.get](i);
        let j = i;
        while (dart.notNull(j) > dart.notNull(left) && dart.notNull(dart.dcall(compare, a[dartx.get](dart.notNull(j) - 1), el)) > 0) {
          a[dartx.set](j, a[dartx.get](dart.notNull(j) - 1));
          j = dart.notNull(j) - 1;
        }
        a[dartx.set](j, el);
      }
    }
    static _dualPivotQuicksort(a, left, right, compare) {
      dart.assert(dart.notNull(right) - dart.notNull(left) > dart.notNull(Sort._INSERTION_SORT_THRESHOLD));
      let sixth = ((dart.notNull(right) - dart.notNull(left) + 1) / 6)[dartx.truncate]();
      let index1 = dart.notNull(left) + dart.notNull(sixth);
      let index5 = dart.notNull(right) - dart.notNull(sixth);
      let index3 = ((dart.notNull(left) + dart.notNull(right)) / 2)[dartx.truncate]();
      let index2 = dart.notNull(index3) - dart.notNull(sixth);
      let index4 = dart.notNull(index3) + dart.notNull(sixth);
      let el1 = a[dartx.get](index1);
      let el2 = a[dartx.get](index2);
      let el3 = a[dartx.get](index3);
      let el4 = a[dartx.get](index4);
      let el5 = a[dartx.get](index5);
      if (dart.notNull(dart.dcall(compare, el1, el2)) > 0) {
        let t = el1;
        el1 = el2;
        el2 = t;
      }
      if (dart.notNull(dart.dcall(compare, el4, el5)) > 0) {
        let t = el4;
        el4 = el5;
        el5 = t;
      }
      if (dart.notNull(dart.dcall(compare, el1, el3)) > 0) {
        let t = el1;
        el1 = el3;
        el3 = t;
      }
      if (dart.notNull(dart.dcall(compare, el2, el3)) > 0) {
        let t = el2;
        el2 = el3;
        el3 = t;
      }
      if (dart.notNull(dart.dcall(compare, el1, el4)) > 0) {
        let t = el1;
        el1 = el4;
        el4 = t;
      }
      if (dart.notNull(dart.dcall(compare, el3, el4)) > 0) {
        let t = el3;
        el3 = el4;
        el4 = t;
      }
      if (dart.notNull(dart.dcall(compare, el2, el5)) > 0) {
        let t = el2;
        el2 = el5;
        el5 = t;
      }
      if (dart.notNull(dart.dcall(compare, el2, el3)) > 0) {
        let t = el2;
        el2 = el3;
        el3 = t;
      }
      if (dart.notNull(dart.dcall(compare, el4, el5)) > 0) {
        let t = el4;
        el4 = el5;
        el5 = t;
      }
      let pivot1 = el2;
      let pivot2 = el4;
      a[dartx.set](index1, el1);
      a[dartx.set](index3, el3);
      a[dartx.set](index5, el5);
      a[dartx.set](index2, a[dartx.get](left));
      a[dartx.set](index4, a[dartx.get](right));
      let less = dart.notNull(left) + 1;
      let great = dart.notNull(right) - 1;
      let pivots_are_equal = dart.dcall(compare, pivot1, pivot2) == 0;
      if (dart.notNull(pivots_are_equal)) {
        let pivot = pivot1;
        for (let k = less; dart.notNull(k) <= dart.notNull(great); k = dart.notNull(k) + 1) {
          let ak = a[dartx.get](k);
          let comp = dart.dcall(compare, ak, pivot);
          if (comp == 0)
            continue;
          if (dart.notNull(comp) < 0) {
            if (k != less) {
              a[dartx.set](k, a[dartx.get](less));
              a[dartx.set](less, ak);
            }
            less = dart.notNull(less) + 1;
          } else {
            while (true) {
              comp = dart.dcall(compare, a[dartx.get](great), pivot);
              if (dart.notNull(comp) > 0) {
                great = dart.notNull(great) - 1;
                continue;
              } else if (dart.notNull(comp) < 0) {
                a[dartx.set](k, a[dartx.get](less));
                a[dartx.set]((() => {
                  let x = less;
                  less = dart.notNull(x) + 1;
                  return x;
                })(), a[dartx.get](great));
                a[dartx.set]((() => {
                  let x = great;
                  great = dart.notNull(x) - 1;
                  return x;
                })(), ak);
                break;
              } else {
                a[dartx.set](k, a[dartx.get](great));
                a[dartx.set]((() => {
                  let x = great;
                  great = dart.notNull(x) - 1;
                  return x;
                })(), ak);
                break;
              }
            }
          }
        }
      } else {
        for (let k = less; dart.notNull(k) <= dart.notNull(great); k = dart.notNull(k) + 1) {
          let ak = a[dartx.get](k);
          let comp_pivot1 = dart.dcall(compare, ak, pivot1);
          if (dart.notNull(comp_pivot1) < 0) {
            if (k != less) {
              a[dartx.set](k, a[dartx.get](less));
              a[dartx.set](less, ak);
            }
            less = dart.notNull(less) + 1;
          } else {
            let comp_pivot2 = dart.dcall(compare, ak, pivot2);
            if (dart.notNull(comp_pivot2) > 0) {
              while (true) {
                let comp = dart.dcall(compare, a[dartx.get](great), pivot2);
                if (dart.notNull(comp) > 0) {
                  great = dart.notNull(great) - 1;
                  if (dart.notNull(great) < dart.notNull(k))
                    break;
                  continue;
                } else {
                  comp = dart.dcall(compare, a[dartx.get](great), pivot1);
                  if (dart.notNull(comp) < 0) {
                    a[dartx.set](k, a[dartx.get](less));
                    a[dartx.set]((() => {
                      let x = less;
                      less = dart.notNull(x) + 1;
                      return x;
                    })(), a[dartx.get](great));
                    a[dartx.set]((() => {
                      let x = great;
                      great = dart.notNull(x) - 1;
                      return x;
                    })(), ak);
                  } else {
                    a[dartx.set](k, a[dartx.get](great));
                    a[dartx.set]((() => {
                      let x = great;
                      great = dart.notNull(x) - 1;
                      return x;
                    })(), ak);
                  }
                  break;
                }
              }
            }
          }
        }
      }
      a[dartx.set](left, a[dartx.get](dart.notNull(less) - 1));
      a[dartx.set](dart.notNull(less) - 1, pivot1);
      a[dartx.set](right, a[dartx.get](dart.notNull(great) + 1));
      a[dartx.set](dart.notNull(great) + 1, pivot2);
      Sort._doSort(a, left, dart.notNull(less) - 2, compare);
      Sort._doSort(a, dart.notNull(great) + 2, right, compare);
      if (dart.notNull(pivots_are_equal)) {
        return;
      }
      if (dart.notNull(less) < dart.notNull(index1) && dart.notNull(great) > dart.notNull(index5)) {
        while (dart.dcall(compare, a[dartx.get](less), pivot1) == 0) {
          less = dart.notNull(less) + 1;
        }
        while (dart.dcall(compare, a[dartx.get](great), pivot2) == 0) {
          great = dart.notNull(great) - 1;
        }
        for (let k = less; dart.notNull(k) <= dart.notNull(great); k = dart.notNull(k) + 1) {
          let ak = a[dartx.get](k);
          let comp_pivot1 = dart.dcall(compare, ak, pivot1);
          if (comp_pivot1 == 0) {
            if (k != less) {
              a[dartx.set](k, a[dartx.get](less));
              a[dartx.set](less, ak);
            }
            less = dart.notNull(less) + 1;
          } else {
            let comp_pivot2 = dart.dcall(compare, ak, pivot2);
            if (comp_pivot2 == 0) {
              while (true) {
                let comp = dart.dcall(compare, a[dartx.get](great), pivot2);
                if (comp == 0) {
                  great = dart.notNull(great) - 1;
                  if (dart.notNull(great) < dart.notNull(k))
                    break;
                  continue;
                } else {
                  comp = dart.dcall(compare, a[dartx.get](great), pivot1);
                  if (dart.notNull(comp) < 0) {
                    a[dartx.set](k, a[dartx.get](less));
                    a[dartx.set]((() => {
                      let x = less;
                      less = dart.notNull(x) + 1;
                      return x;
                    })(), a[dartx.get](great));
                    a[dartx.set]((() => {
                      let x = great;
                      great = dart.notNull(x) - 1;
                      return x;
                    })(), ak);
                  } else {
                    a[dartx.set](k, a[dartx.get](great));
                    a[dartx.set]((() => {
                      let x = great;
                      great = dart.notNull(x) - 1;
                      return x;
                    })(), ak);
                  }
                  break;
                }
              }
            }
          }
        }
        Sort._doSort(a, less, great, compare);
      } else {
        Sort._doSort(a, less, great, compare);
      }
    }
  }
  dart.setSignature(Sort, {
    statics: () => ({
      sort: [dart.void, [core.List, dart.functionType(core.int, [dart.dynamic, dart.dynamic])]],
      sortRange: [dart.void, [core.List, core.int, core.int, dart.functionType(core.int, [dart.dynamic, dart.dynamic])]],
      _doSort: [dart.void, [core.List, core.int, core.int, dart.functionType(core.int, [dart.dynamic, dart.dynamic])]],
      _insertionSort: [dart.void, [core.List, core.int, core.int, dart.functionType(core.int, [dart.dynamic, dart.dynamic])]],
      _dualPivotQuicksort: [dart.void, [core.List, core.int, core.int, dart.functionType(core.int, [dart.dynamic, dart.dynamic])]]
    }),
    names: ['sort', 'sortRange', '_doSort', '_insertionSort', '_dualPivotQuicksort']
  });
  Sort._INSERTION_SORT_THRESHOLD = 32;
  let _name = dart.JsSymbol('_name');
  class Symbol extends core.Object {
    Symbol(name) {
      this[_name] = name;
    }
    unvalidated(name) {
      this[_name] = name;
    }
    validated(name) {
      this[_name] = Symbol.validatePublicSymbol(name);
    }
    ['=='](other) {
      return dart.is(other, Symbol) && this[_name] == other[_name];
    }
    get hashCode() {
      let arbitraryPrime = 664597;
      return 536870911 & dart.notNull(arbitraryPrime) * dart.notNull(dart.hashCode(this[_name]));
    }
    toString() {
      return `Symbol("${this[_name]}")`;
    }
    static getName(symbol) {
      return symbol[_name];
    }
    static validatePublicSymbol(name) {
      if (dart.notNull(name[dartx.isEmpty]) || dart.notNull(Symbol.publicSymbolPattern.hasMatch(name)))
        return name;
      if (dart.notNull(name[dartx.startsWith]('_'))) {
        dart.throw(new core.ArgumentError(`"${name}" is a private identifier`));
      }
      dart.throw(new core.ArgumentError(`"${name}" is not a valid (qualified) symbol name`));
    }
    static isValidSymbol(name) {
      return dart.notNull(name[dartx.isEmpty]) || dart.notNull(Symbol.symbolPattern.hasMatch(name));
    }
  }
  Symbol[dart.implements] = () => [core.Symbol];
  dart.defineNamedConstructor(Symbol, 'unvalidated');
  dart.defineNamedConstructor(Symbol, 'validated');
  dart.setSignature(Symbol, {
    constructors: () => ({
      Symbol: [Symbol, [core.String]],
      unvalidated: [Symbol, [core.String]],
      validated: [Symbol, [core.String]]
    }),
    methods: () => ({'==': [core.bool, [core.Object]]}),
    statics: () => ({
      getName: [core.String, [Symbol]],
      validatePublicSymbol: [core.String, [core.String]],
      isValidSymbol: [core.bool, [core.String]]
    }),
    names: ['getName', 'validatePublicSymbol', 'isValidSymbol']
  });
  Symbol.reservedWordRE = '(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|d(?:efault|o)|' + 'e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|i[fns]|n(?:ew|ull)|' + 'ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|r(?:ue|y))|' + 'v(?:ar|oid)|w(?:hile|ith))';
  Symbol.publicIdentifierRE = '(?!' + `${Symbol.reservedWordRE}` + '\\b(?!\\$))[a-zA-Z$][\\w$]*';
  Symbol.identifierRE = '(?!' + `${Symbol.reservedWordRE}` + '\\b(?!\\$))[a-zA-Z$_][\\w$]*';
  Symbol.operatorRE = '(?:[\\-+*/%&|^]|\\[\\]=?|==|~/?|<[<=]?|>[>=]?|unary-)';
  let POWERS_OF_TEN = dart.const([1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0, 1000000000.0, 10000000000.0, 100000000000.0, 1000000000000.0, 10000000000000.0, 100000000000000.0, 1000000000000000.0, 10000000000000000.0, 100000000000000000.0, 1000000000000000000.0, 10000000000000000000.0, 100000000000000000000.0, 1e+21, 1e+22]);
  dart.defineLazyProperties(Symbol, {
    get publicSymbolPattern() {
      return core.RegExp.new(`^(?:${Symbol.operatorRE}\$|${Symbol.publicIdentifierRE}(?:=?\$|[.](?!\$)))+?\$`);
    },
    get symbolPattern() {
      return core.RegExp.new(`^(?:${Symbol.operatorRE}\$|${Symbol.identifierRE}(?:=?\$|[.](?!\$)))+?\$`);
    }
  });
  // Exports:
  exports.EfficientLength = EfficientLength;
  exports.ListIterable$ = ListIterable$;
  exports.ListIterable = ListIterable;
  exports.SubListIterable$ = SubListIterable$;
  exports.SubListIterable = SubListIterable;
  exports.ListIterator$ = ListIterator$;
  exports.ListIterator = ListIterator;
  exports.MappedIterable$ = MappedIterable$;
  exports.MappedIterable = MappedIterable;
  exports.EfficientLengthMappedIterable$ = EfficientLengthMappedIterable$;
  exports.EfficientLengthMappedIterable = EfficientLengthMappedIterable;
  exports.MappedIterator$ = MappedIterator$;
  exports.MappedIterator = MappedIterator;
  exports.MappedListIterable$ = MappedListIterable$;
  exports.MappedListIterable = MappedListIterable;
  exports.WhereIterable$ = WhereIterable$;
  exports.WhereIterable = WhereIterable;
  exports.WhereIterator$ = WhereIterator$;
  exports.WhereIterator = WhereIterator;
  exports.ExpandIterable$ = ExpandIterable$;
  exports.ExpandIterable = ExpandIterable;
  exports.ExpandIterator$ = ExpandIterator$;
  exports.ExpandIterator = ExpandIterator;
  exports.TakeIterable$ = TakeIterable$;
  exports.TakeIterable = TakeIterable;
  exports.EfficientLengthTakeIterable$ = EfficientLengthTakeIterable$;
  exports.EfficientLengthTakeIterable = EfficientLengthTakeIterable;
  exports.TakeIterator$ = TakeIterator$;
  exports.TakeIterator = TakeIterator;
  exports.TakeWhileIterable$ = TakeWhileIterable$;
  exports.TakeWhileIterable = TakeWhileIterable;
  exports.TakeWhileIterator$ = TakeWhileIterator$;
  exports.TakeWhileIterator = TakeWhileIterator;
  exports.SkipIterable$ = SkipIterable$;
  exports.SkipIterable = SkipIterable;
  exports.EfficientLengthSkipIterable$ = EfficientLengthSkipIterable$;
  exports.EfficientLengthSkipIterable = EfficientLengthSkipIterable;
  exports.SkipIterator$ = SkipIterator$;
  exports.SkipIterator = SkipIterator;
  exports.SkipWhileIterable$ = SkipWhileIterable$;
  exports.SkipWhileIterable = SkipWhileIterable;
  exports.SkipWhileIterator$ = SkipWhileIterator$;
  exports.SkipWhileIterator = SkipWhileIterator;
  exports.EmptyIterable$ = EmptyIterable$;
  exports.EmptyIterable = EmptyIterable;
  exports.EmptyIterator$ = EmptyIterator$;
  exports.EmptyIterator = EmptyIterator;
  exports.BidirectionalIterator$ = BidirectionalIterator$;
  exports.BidirectionalIterator = BidirectionalIterator;
  exports.IterableMixinWorkaround$ = IterableMixinWorkaround$;
  exports.IterableMixinWorkaround = IterableMixinWorkaround;
  exports.IterableElementError = IterableElementError;
  exports.FixedLengthListMixin$ = FixedLengthListMixin$;
  exports.FixedLengthListMixin = FixedLengthListMixin;
  exports.UnmodifiableListMixin$ = UnmodifiableListMixin$;
  exports.UnmodifiableListMixin = UnmodifiableListMixin;
  exports.FixedLengthListBase$ = FixedLengthListBase$;
  exports.FixedLengthListBase = FixedLengthListBase;
  exports.UnmodifiableListBase$ = UnmodifiableListBase$;
  exports.UnmodifiableListBase = UnmodifiableListBase;
  exports.ListMapView$ = ListMapView$;
  exports.ListMapView = ListMapView;
  exports.ReversedListIterable$ = ReversedListIterable$;
  exports.ReversedListIterable = ReversedListIterable;
  exports.UnmodifiableListError = UnmodifiableListError;
  exports.NonGrowableListError = NonGrowableListError;
  exports.makeListFixedLength = makeListFixedLength;
  exports.Lists = Lists;
  exports.printToConsole = printToConsole;
  exports.Sort = Sort;
  exports.Symbol = Symbol;
  exports.POWERS_OF_TEN = POWERS_OF_TEN;
});
