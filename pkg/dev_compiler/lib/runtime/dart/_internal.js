var _internal;
(function(exports) {
  'use strict';
  class EfficientLength extends core.Object {}
  let ListIterable$ = dart.generic(function(E) {
    class ListIterable extends collection.IterableBase$(E) {
      ListIterable() {
        super.IterableBase();
      }
      get [core.$iterator]() {
        return new (ListIterator$(E))(this);
      }
      [core.$forEach](action) {
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          action(this.elementAt(i));
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
      }
      get [core.$isEmpty]() {
        return this.length == 0;
      }
      get [core.$first]() {
        if (this.length == 0)
          throw IterableElementError.noElement();
        return this.elementAt(0);
      }
      get [core.$last]() {
        if (this.length == 0)
          throw IterableElementError.noElement();
        return this.elementAt(dart.notNull(this.length) - 1);
      }
      get [core.$single]() {
        if (this.length == 0)
          throw IterableElementError.noElement();
        if (dart.notNull(this.length) > 1)
          throw IterableElementError.tooMany();
        return this.elementAt(0);
      }
      [core.$contains](element) {
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (dart.equals(this.elementAt(i), element))
            return true;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return false;
      }
      [core.$every](test) {
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (!dart.notNull(test(this.elementAt(i))))
            return false;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return true;
      }
      [core.$any](test) {
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          if (test(this.elementAt(i)))
            return true;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return false;
      }
      [core.$firstWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let element = this.elementAt(i);
          if (test(element))
            return element;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (orElse != null)
          return orElse();
        throw IterableElementError.noElement();
      }
      [core.$lastWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        let length = this[core.$length];
        for (let i = dart.notNull(length) - 1; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
          let element = this.elementAt(i);
          if (test(element))
            return element;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (orElse != null)
          return orElse();
        throw IterableElementError.noElement();
      }
      [core.$singleWhere](test) {
        let length = this[core.$length];
        let match = null;
        let matchFound = false;
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let element = this.elementAt(i);
          if (test(element)) {
            if (matchFound) {
              throw IterableElementError.tooMany();
            }
            matchFound = true;
            match = element;
          }
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (matchFound)
          return match;
        throw IterableElementError.noElement();
      }
      [core.$join](separator) {
        if (separator === void 0)
          separator = "";
        let length = this[core.$length];
        if (!dart.notNull(separator.isEmpty)) {
          if (length == 0)
            return "";
          let first = `${this.elementAt(0)}`;
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
          let buffer = new core.StringBuffer(first);
          for (let i = 1; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
            buffer.write(separator);
            buffer.write(this.elementAt(i));
            if (length != this[core.$length]) {
              throw new core.ConcurrentModificationError(this);
            }
          }
          return buffer.toString();
        } else {
          let buffer = new core.StringBuffer();
          for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
            buffer.write(this.elementAt(i));
            if (length != this[core.$length]) {
              throw new core.ConcurrentModificationError(this);
            }
          }
          return buffer.toString();
        }
      }
      [core.$where](test) {
        return super[core.$where](test);
      }
      [core.$map](f) {
        return new MappedListIterable(this, f);
      }
      [core.$reduce](combine) {
        let length = this[core.$length];
        if (length == 0)
          throw IterableElementError.noElement();
        let value = this.elementAt(0);
        for (let i = 1; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          value = dart.dinvokef(combine, value, this.elementAt(i));
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return value;
      }
      [core.$fold](initialValue, combine) {
        let value = initialValue;
        let length = this[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          value = dart.dinvokef(combine, value, this.elementAt(i));
          if (length != this[core.$length]) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return value;
      }
      [core.$skip](count) {
        return new (SubListIterable$(E))(this, count, null);
      }
      [core.$skipWhile](test) {
        return super[core.$skipWhile](test);
      }
      [core.$take](count) {
        return new (SubListIterable$(E))(this, 0, count);
      }
      [core.$takeWhile](test) {
        return super[core.$takeWhile](test);
      }
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let result = null;
        if (growable) {
          result = ((_) => {
            _[core.$length] = this.length;
            return _;
          }).bind(this)(new (core.List$(E))());
        } else {
          result = new (core.List$(E))(this.length);
        }
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); i = dart.notNull(i) + 1) {
          result[core.$set](i, this.elementAt(i));
        }
        return result;
      }
      [core.$toSet]() {
        let result = new (core.Set$(E))();
        for (let i = 0; dart.notNull(i) < dart.notNull(this.length); i = dart.notNull(i) + 1) {
          result.add(this.elementAt(i));
        }
        return result;
      }
    }
    ListIterable[dart.implements] = () => [EfficientLength];
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
      SubListIterable(iterable$, start$, endOrLength) {
        this[_iterable] = iterable$;
        this[_start] = start$;
        this[_endOrLength] = endOrLength;
        super.ListIterable();
        core.RangeError.checkNotNegative(this[_start], "start");
        if (this[_endOrLength] != null) {
          core.RangeError.checkNotNegative(this[_endOrLength], "end");
          if (dart.notNull(this[_start]) > dart.notNull(this[_endOrLength])) {
            throw new core.RangeError.range(this[_start], 0, this[_endOrLength], "start");
          }
        }
      }
      get [_endIndex]() {
        let length = this[_iterable][core.$length];
        if (this[_endOrLength] == null || dart.notNull(this[_endOrLength]) > dart.notNull(length))
          return length;
        return this[_endOrLength];
      }
      get [_startIndex]() {
        let length = this[_iterable][core.$length];
        if (dart.notNull(this[_start]) > dart.notNull(length))
          return length;
        return this[_start];
      }
      get [core.$length]() {
        let length = this[_iterable][core.$length];
        if (dart.notNull(this[_start]) >= dart.notNull(length))
          return 0;
        if (this[_endOrLength] == null || dart.notNull(this[_endOrLength]) >= dart.notNull(length)) {
          return dart.notNull(length) - dart.notNull(this[_start]);
        }
        return dart.notNull(this[_endOrLength]) - dart.notNull(this[_start]);
      }
      [core.$elementAt](index) {
        let realIndex = dart.notNull(this[_startIndex]) + dart.notNull(index);
        if (dart.notNull(index) < 0 || dart.notNull(realIndex) >= dart.notNull(this[_endIndex])) {
          throw new core.RangeError.index(index, this, "index");
        }
        return this[_iterable][core.$elementAt](realIndex);
      }
      [core.$skip](count) {
        core.RangeError.checkNotNegative(count, "count");
        let newStart = dart.notNull(this[_start]) + dart.notNull(count);
        if (this[_endOrLength] != null && dart.notNull(newStart) >= dart.notNull(this[_endOrLength])) {
          return new (EmptyIterable$(E))();
        }
        return new (SubListIterable$(E))(this[_iterable], newStart, this[_endOrLength]);
      }
      [core.$take](count) {
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
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        let start = this[_start];
        let end = this[_iterable][core.$length];
        if (this[_endOrLength] != null && dart.notNull(this[_endOrLength]) < dart.notNull(end))
          end = this[_endOrLength];
        let length = dart.notNull(end) - dart.notNull(start);
        if (dart.notNull(length) < 0)
          length = 0;
        let result = growable ? ((_) => {
          _[core.$length] = length;
          return _;
        })(new (core.List$(E))()) : new (core.List$(E))(length);
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          result[core.$set](i, this[_iterable][core.$elementAt](dart.notNull(start) + dart.notNull(i)));
          if (dart.notNull(this[_iterable][core.$length]) < dart.notNull(end))
            throw new core.ConcurrentModificationError(this);
        }
        return dart.as(result, core.List$(E));
      }
    }
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
        this[_length] = iterable[core.$length];
        this[_index] = 0;
        this[_current] = null;
      }
      get current() {
        return this[_current];
      }
      moveNext() {
        let length = this[_iterable][core.$length];
        if (this[_length] != length) {
          throw new core.ConcurrentModificationError(this[_iterable]);
        }
        if (dart.notNull(this[_index]) >= dart.notNull(length)) {
          this[_current] = null;
          return false;
        }
        this[_current] = this[_iterable][core.$elementAt](this[_index]);
        this[_index] = dart.notNull(this[_index]) + 1;
        return true;
      }
    }
    ListIterator[dart.implements] = () => [core.Iterator$(E)];
    return ListIterator;
  });
  let ListIterator = ListIterator$();
  let _Transformation$ = dart.generic(function(S, T) {
    class _Transformation extends core.Function {}
    return _Transformation;
  });
  let _Transformation = _Transformation$();
  let _ = dart.JsSymbol('_');
  let _f = dart.JsSymbol('_f');
  let MappedIterable$ = dart.generic(function(S, T) {
    class MappedIterable extends collection.IterableBase$(T) {
      MappedIterable(iterable, func) {
        if (dart.is(iterable, EfficientLength)) {
          return new (EfficientLengthMappedIterable$(S, T))(iterable, func);
        }
        return new MappedIterable$(S, T)[_](dart.as(iterable, core.Iterable$(S)), func);
      }
      [_](iterable$, f$) {
        this[_iterable] = iterable$;
        this[_f] = f$;
        super.IterableBase();
      }
      get [core.$iterator]() {
        return new (MappedIterator$(S, T))(this[_iterable][core.$iterator], this[_f]);
      }
      get [core.$length]() {
        return this[_iterable][core.$length];
      }
      get [core.$isEmpty]() {
        return this[_iterable][core.$isEmpty];
      }
      get [core.$first]() {
        return this[_f](this[_iterable][core.$first]);
      }
      get [core.$last]() {
        return this[_f](this[_iterable][core.$last]);
      }
      get [core.$single]() {
        return this[_f](this[_iterable][core.$single]);
      }
      [core.$elementAt](index) {
        return this[_f](this[_iterable][core.$elementAt](index));
      }
    }
    dart.defineNamedConstructor(MappedIterable, _);
    return MappedIterable;
  });
  let MappedIterable = MappedIterable$();
  let EfficientLengthMappedIterable$ = dart.generic(function(S, T) {
    class EfficientLengthMappedIterable extends MappedIterable$(S, T) {
      EfficientLengthMappedIterable(iterable, func) {
        super[_](dart.as(iterable, core.Iterable$(S)), func);
      }
    }
    EfficientLengthMappedIterable[dart.implements] = () => [EfficientLength];
    return EfficientLengthMappedIterable;
  });
  let EfficientLengthMappedIterable = EfficientLengthMappedIterable$();
  let _iterator = dart.JsSymbol('_iterator');
  let MappedIterator$ = dart.generic(function(S, T) {
    class MappedIterator extends core.Iterator$(T) {
      MappedIterator(iterator$, f$) {
        this[_iterator] = iterator$;
        this[_f] = f$;
        this[_current] = null;
        super.Iterator();
      }
      moveNext() {
        if (this[_iterator].moveNext()) {
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
    return MappedIterator;
  });
  let MappedIterator = MappedIterator$();
  let _source = dart.JsSymbol('_source');
  let MappedListIterable$ = dart.generic(function(S, T) {
    class MappedListIterable extends ListIterable$(T) {
      MappedListIterable(source, f$) {
        this[_source] = source;
        this[_f] = f$;
        super.ListIterable();
      }
      get [core.$length]() {
        return this[_source][core.$length];
      }
      [core.$elementAt](index) {
        return this[_f](this[_source][core.$elementAt](index));
      }
    }
    MappedListIterable[dart.implements] = () => [EfficientLength];
    return MappedListIterable;
  });
  let MappedListIterable = MappedListIterable$();
  let _ElementPredicate$ = dart.generic(function(E) {
    class _ElementPredicate extends core.Function {}
    return _ElementPredicate;
  });
  let _ElementPredicate = _ElementPredicate$();
  let WhereIterable$ = dart.generic(function(E) {
    class WhereIterable extends collection.IterableBase$(E) {
      WhereIterable(iterable$, f$) {
        this[_iterable] = iterable$;
        this[_f] = f$;
        super.IterableBase();
      }
      get [core.$iterator]() {
        return new (WhereIterator$(E))(this[_iterable][core.$iterator], this[_f]);
      }
    }
    return WhereIterable;
  });
  let WhereIterable = WhereIterable$();
  let WhereIterator$ = dart.generic(function(E) {
    class WhereIterator extends core.Iterator$(E) {
      WhereIterator(iterator$, f$) {
        this[_iterator] = iterator$;
        this[_f] = f$;
        super.Iterator();
      }
      moveNext() {
        while (this[_iterator].moveNext()) {
          if (this[_f](this[_iterator].current)) {
            return true;
          }
        }
        return false;
      }
      get current() {
        return this[_iterator].current;
      }
    }
    return WhereIterator;
  });
  let WhereIterator = WhereIterator$();
  let _ExpandFunction$ = dart.generic(function(S, T) {
    class _ExpandFunction extends core.Function {}
    return _ExpandFunction;
  });
  let _ExpandFunction = _ExpandFunction$();
  let ExpandIterable$ = dart.generic(function(S, T) {
    class ExpandIterable extends collection.IterableBase$(T) {
      ExpandIterable(iterable$, f$) {
        this[_iterable] = iterable$;
        this[_f] = f$;
        super.IterableBase();
      }
      get [core.$iterator]() {
        return new (ExpandIterator$(S, T))(this[_iterable][core.$iterator], dart.as(this[_f], dart.throw_("Unimplemented type (S) → Iterable<T>")));
      }
    }
    return ExpandIterable;
  });
  let ExpandIterable = ExpandIterable$();
  let _currentExpansion = dart.JsSymbol('_currentExpansion');
  let _nextExpansion = dart.JsSymbol('_nextExpansion');
  let ExpandIterator$ = dart.generic(function(S, T) {
    class ExpandIterator extends core.Object {
      ExpandIterator(iterator$, f$) {
        this[_iterator] = iterator$;
        this[_f] = f$;
        this[_currentExpansion] = dart.as(new EmptyIterator(), core.Iterator$(T));
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
          if (this[_iterator].moveNext()) {
            this[_currentExpansion] = null;
            this[_currentExpansion] = dart.as(dart.dinvokef(this[_f], this[_iterator].current)[core.$iterator], core.Iterator$(T));
          } else {
            return false;
          }
        }
        this[_current] = this[_currentExpansion].current;
        return true;
      }
    }
    ExpandIterator[dart.implements] = () => [core.Iterator$(T)];
    return ExpandIterator;
  });
  let ExpandIterator = ExpandIterator$();
  let _takeCount = dart.JsSymbol('_takeCount');
  let TakeIterable$ = dart.generic(function(E) {
    class TakeIterable extends collection.IterableBase$(E) {
      TakeIterable(iterable, takeCount) {
        if (dart.notNull(!(typeof takeCount == 'number')) || dart.notNull(takeCount) < 0) {
          throw new core.ArgumentError(takeCount);
        }
        if (dart.is(iterable, EfficientLength)) {
          return new (EfficientLengthTakeIterable$(E))(iterable, takeCount);
        }
        return new TakeIterable$(E)[_](iterable, takeCount);
      }
      [_](iterable$, takeCount$) {
        this[_iterable] = iterable$;
        this[_takeCount] = takeCount$;
        super.IterableBase();
      }
      get [core.$iterator]() {
        return new (TakeIterator$(E))(this[_iterable][core.$iterator], this[_takeCount]);
      }
    }
    dart.defineNamedConstructor(TakeIterable, _);
    return TakeIterable;
  });
  let TakeIterable = TakeIterable$();
  let EfficientLengthTakeIterable$ = dart.generic(function(E) {
    class EfficientLengthTakeIterable extends TakeIterable$(E) {
      EfficientLengthTakeIterable(iterable, takeCount) {
        super[_](iterable, takeCount);
      }
      get [core.$length]() {
        let iterableLength = this[_iterable][core.$length];
        if (dart.notNull(iterableLength) > dart.notNull(this[_takeCount]))
          return this[_takeCount];
        return iterableLength;
      }
    }
    EfficientLengthTakeIterable[dart.implements] = () => [EfficientLength];
    return EfficientLengthTakeIterable;
  });
  let EfficientLengthTakeIterable = EfficientLengthTakeIterable$();
  let _remaining = dart.JsSymbol('_remaining');
  let TakeIterator$ = dart.generic(function(E) {
    class TakeIterator extends core.Iterator$(E) {
      TakeIterator(iterator$, remaining) {
        this[_iterator] = iterator$;
        this[_remaining] = remaining;
        super.Iterator();
        dart.assert(dart.notNull(typeof this[_remaining] == 'number') && dart.notNull(this[_remaining]) >= 0);
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
    return TakeIterator;
  });
  let TakeIterator = TakeIterator$();
  let TakeWhileIterable$ = dart.generic(function(E) {
    class TakeWhileIterable extends collection.IterableBase$(E) {
      TakeWhileIterable(iterable$, f$) {
        this[_iterable] = iterable$;
        this[_f] = f$;
        super.IterableBase();
      }
      get [core.$iterator]() {
        return new (TakeWhileIterator$(E))(this[_iterable][core.$iterator], dart.as(this[_f], dart.throw_("Unimplemented type (E) → bool")));
      }
    }
    return TakeWhileIterable;
  });
  let TakeWhileIterable = TakeWhileIterable$();
  let _isFinished = dart.JsSymbol('_isFinished');
  let TakeWhileIterator$ = dart.generic(function(E) {
    class TakeWhileIterator extends core.Iterator$(E) {
      TakeWhileIterator(iterator$, f$) {
        this[_iterator] = iterator$;
        this[_f] = f$;
        this[_isFinished] = false;
        super.Iterator();
      }
      moveNext() {
        if (this[_isFinished])
          return false;
        if (!dart.notNull(this[_iterator].moveNext()) || !dart.notNull(dart.dinvokef(this[_f], this[_iterator].current))) {
          this[_isFinished] = true;
          return false;
        }
        return true;
      }
      get current() {
        if (this[_isFinished])
          return null;
        return this[_iterator].current;
      }
    }
    return TakeWhileIterator;
  });
  let TakeWhileIterator = TakeWhileIterator$();
  let _skipCount = dart.JsSymbol('_skipCount');
  let SkipIterable$ = dart.generic(function(E) {
    class SkipIterable extends collection.IterableBase$(E) {
      SkipIterable(iterable, count) {
        if (dart.is(iterable, EfficientLength)) {
          return new (EfficientLengthSkipIterable$(E))(iterable, count);
        }
        return new SkipIterable$(E)[_](iterable, count);
      }
      [_](iterable$, skipCount$) {
        this[_iterable] = iterable$;
        this[_skipCount] = skipCount$;
        super.IterableBase();
        if (!(typeof this[_skipCount] == 'number')) {
          throw new core.ArgumentError.value(this[_skipCount], "count is not an integer");
        }
        core.RangeError.checkNotNegative(this[_skipCount], "count");
      }
      [core.$skip](count) {
        if (!(typeof this[_skipCount] == 'number')) {
          throw new core.ArgumentError.value(this[_skipCount], "count is not an integer");
        }
        core.RangeError.checkNotNegative(this[_skipCount], "count");
        return new SkipIterable$(E)[_](this[_iterable], dart.notNull(this[_skipCount]) + dart.notNull(count));
      }
      get [core.$iterator]() {
        return new (SkipIterator$(E))(this[_iterable][core.$iterator], this[_skipCount]);
      }
    }
    dart.defineNamedConstructor(SkipIterable, _);
    return SkipIterable;
  });
  let SkipIterable = SkipIterable$();
  let EfficientLengthSkipIterable$ = dart.generic(function(E) {
    class EfficientLengthSkipIterable extends SkipIterable$(E) {
      EfficientLengthSkipIterable(iterable, skipCount) {
        super[_](iterable, skipCount);
      }
      get [core.$length]() {
        let length = dart.notNull(this[_iterable][core.$length]) - dart.notNull(this[_skipCount]);
        if (dart.notNull(length) >= 0)
          return length;
        return 0;
      }
    }
    EfficientLengthSkipIterable[dart.implements] = () => [EfficientLength];
    return EfficientLengthSkipIterable;
  });
  let EfficientLengthSkipIterable = EfficientLengthSkipIterable$();
  let SkipIterator$ = dart.generic(function(E) {
    class SkipIterator extends core.Iterator$(E) {
      SkipIterator(iterator$, skipCount$) {
        this[_iterator] = iterator$;
        this[_skipCount] = skipCount$;
        super.Iterator();
        dart.assert(dart.notNull(typeof this[_skipCount] == 'number') && dart.notNull(this[_skipCount]) >= 0);
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
    return SkipIterator;
  });
  let SkipIterator = SkipIterator$();
  let SkipWhileIterable$ = dart.generic(function(E) {
    class SkipWhileIterable extends collection.IterableBase$(E) {
      SkipWhileIterable(iterable$, f$) {
        this[_iterable] = iterable$;
        this[_f] = f$;
        super.IterableBase();
      }
      get [core.$iterator]() {
        return new (SkipWhileIterator$(E))(this[_iterable][core.$iterator], dart.as(this[_f], dart.throw_("Unimplemented type (E) → bool")));
      }
    }
    return SkipWhileIterable;
  });
  let SkipWhileIterable = SkipWhileIterable$();
  let _hasSkipped = dart.JsSymbol('_hasSkipped');
  let SkipWhileIterator$ = dart.generic(function(E) {
    class SkipWhileIterator extends core.Iterator$(E) {
      SkipWhileIterator(iterator$, f$) {
        this[_iterator] = iterator$;
        this[_f] = f$;
        this[_hasSkipped] = false;
        super.Iterator();
      }
      moveNext() {
        if (!dart.notNull(this[_hasSkipped])) {
          this[_hasSkipped] = true;
          while (this[_iterator].moveNext()) {
            if (!dart.notNull(dart.dinvokef(this[_f], this[_iterator].current)))
              return true;
          }
        }
        return this[_iterator].moveNext();
      }
      get current() {
        return this[_iterator].current;
      }
    }
    return SkipWhileIterator;
  });
  let SkipWhileIterator = SkipWhileIterator$();
  let EmptyIterable$ = dart.generic(function(E) {
    class EmptyIterable extends collection.IterableBase$(E) {
      EmptyIterable() {
        super.IterableBase();
      }
      get [core.$iterator]() {
        return dart.as(new EmptyIterator(), core.Iterator$(E));
      }
      [core.$forEach](action) {}
      get [core.$isEmpty]() {
        return true;
      }
      get [core.$length]() {
        return 0;
      }
      get [core.$first]() {
        throw IterableElementError.noElement();
      }
      get [core.$last]() {
        throw IterableElementError.noElement();
      }
      get [core.$single]() {
        throw IterableElementError.noElement();
      }
      [core.$elementAt](index) {
        throw new core.RangeError.range(index, 0, 0, "index");
      }
      [core.$contains](element) {
        return false;
      }
      [core.$every](test) {
        return true;
      }
      [core.$any](test) {
        return false;
      }
      [core.$firstWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        if (orElse != null)
          return orElse();
        throw IterableElementError.noElement();
      }
      [core.$lastWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        if (orElse != null)
          return orElse();
        throw IterableElementError.noElement();
      }
      [core.$singleWhere](test, opts) {
        let orElse = opts && 'orElse' in opts ? opts.orElse : null;
        if (orElse != null)
          return orElse();
        throw IterableElementError.noElement();
      }
      [core.$join](separator) {
        if (separator === void 0)
          separator = "";
        return "";
      }
      [core.$where](test) {
        return this;
      }
      [core.$map](f) {
        return new EmptyIterable();
      }
      [core.$reduce](combine) {
        throw IterableElementError.noElement();
      }
      [core.$fold](initialValue, combine) {
        return initialValue;
      }
      [core.$skip](count) {
        core.RangeError.checkNotNegative(count, "count");
        return this;
      }
      [core.$skipWhile](test) {
        return this;
      }
      [core.$take](count) {
        core.RangeError.checkNotNegative(count, "count");
        return this;
      }
      [core.$takeWhile](test) {
        return this;
      }
      [core.$toList](opts) {
        let growable = opts && 'growable' in opts ? opts.growable : true;
        return growable ? new core.List$(E).from([]) : new (core.List$(E))(0);
      }
      [core.$toSet]() {
        return new (core.Set$(E))();
      }
    }
    EmptyIterable[dart.implements] = () => [EfficientLength];
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
    return EmptyIterator;
  });
  let EmptyIterator = EmptyIterator$();
  let BidirectionalIterator$ = dart.generic(function(T) {
    class BidirectionalIterator extends core.Object {}
    BidirectionalIterator[dart.implements] = () => [core.Iterator$(T)];
    return BidirectionalIterator;
  });
  let BidirectionalIterator = BidirectionalIterator$();
  let _rangeCheck = dart.JsSymbol('_rangeCheck');
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
        for (let e of iterable) {
          dart.dinvokef(f, e);
        }
      }
      static any(iterable, f) {
        for (let e of iterable) {
          if (dart.dinvokef(f, e))
            return true;
        }
        return false;
      }
      static every(iterable, f) {
        for (let e of iterable) {
          if (!dart.notNull(dart.dinvokef(f, e)))
            return false;
        }
        return true;
      }
      static reduce(iterable, combine) {
        let iterator = iterable[core.$iterator];
        if (!dart.notNull(iterator.moveNext()))
          throw IterableElementError.noElement();
        let value = iterator.current;
        while (iterator.moveNext()) {
          value = dart.dinvokef(combine, value, iterator.current);
        }
        return value;
      }
      static fold(iterable, initialValue, combine) {
        for (let element of iterable) {
          initialValue = dart.dinvokef(combine, initialValue, element);
        }
        return initialValue;
      }
      static removeWhereList(list, test) {
        let retained = new core.List.from([]);
        let length = list[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          let element = list[core.$get](i);
          if (!dart.notNull(dart.dinvokef(test, element))) {
            retained[core.$add](element);
          }
          if (length != list[core.$length]) {
            throw new core.ConcurrentModificationError(list);
          }
        }
        if (retained[core.$length] == length)
          return;
        list[core.$length] = retained[core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(retained[core.$length]); i = dart.notNull(i) + 1) {
          list[core.$set](i, retained[core.$get](i));
        }
      }
      static isEmpty(iterable) {
        return !dart.notNull(iterable[core.$iterator].moveNext());
      }
      static first(iterable) {
        let it = iterable[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw IterableElementError.noElement();
        }
        return it.current;
      }
      static last(iterable) {
        let it = iterable[core.$iterator];
        if (!dart.notNull(it.moveNext())) {
          throw IterableElementError.noElement();
        }
        let result = null;
        do {
          result = it.current;
        } while (it.moveNext());
        return result;
      }
      static single(iterable) {
        let it = iterable[core.$iterator];
        if (!dart.notNull(it.moveNext()))
          throw IterableElementError.noElement();
        let result = it.current;
        if (it.moveNext())
          throw IterableElementError.tooMany();
        return result;
      }
      static firstWhere(iterable, test, orElse) {
        for (let element of iterable) {
          if (dart.dinvokef(test, element))
            return element;
        }
        if (orElse != null)
          return orElse();
        throw IterableElementError.noElement();
      }
      static lastWhere(iterable, test, orElse) {
        let result = null;
        let foundMatching = false;
        for (let element of iterable) {
          if (dart.dinvokef(test, element)) {
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        if (orElse != null)
          return orElse();
        throw IterableElementError.noElement();
      }
      static lastWhereList(list, test, orElse) {
        for (let i = dart.notNull(list[core.$length]) - 1; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
          let element = list[core.$get](i);
          if (dart.dinvokef(test, element))
            return element;
        }
        if (orElse != null)
          return orElse();
        throw IterableElementError.noElement();
      }
      static singleWhere(iterable, test) {
        let result = null;
        let foundMatching = false;
        for (let element of iterable) {
          if (dart.dinvokef(test, element)) {
            if (foundMatching) {
              throw IterableElementError.tooMany();
            }
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching)
          return result;
        throw IterableElementError.noElement();
      }
      static elementAt(iterable, index) {
        if (!(typeof index == 'number'))
          throw new core.ArgumentError.notNull("index");
        core.RangeError.checkNotNegative(index, "index");
        let elementIndex = 0;
        for (let element of iterable) {
          if (index == elementIndex)
            return element;
          elementIndex = dart.notNull(elementIndex) + 1;
        }
        throw new core.RangeError.index(index, iterable, "index", null, elementIndex);
      }
      static join(iterable, separator) {
        if (separator === void 0)
          separator = null;
        let buffer = new core.StringBuffer();
        buffer.writeAll(iterable, separator);
        return buffer.toString();
      }
      static joinList(list, separator) {
        if (separator === void 0)
          separator = null;
        if (list[core.$isEmpty])
          return "";
        if (list[core.$length] == 1)
          return `${list[core.$get](0)}`;
        let buffer = new core.StringBuffer();
        if (separator.isEmpty) {
          for (let i = 0; dart.notNull(i) < dart.notNull(list[core.$length]); i = dart.notNull(i) + 1) {
            buffer.write(list[core.$get](i));
          }
        } else {
          buffer.write(list[core.$get](0));
          for (let i = 1; dart.notNull(i) < dart.notNull(list[core.$length]); i = dart.notNull(i) + 1) {
            buffer.write(separator);
            buffer.write(list[core.$get](i));
          }
        }
        return buffer.toString();
      }
      where(iterable, f) {
        return new (WhereIterable$(T))(dart.as(iterable, core.Iterable$(T)), dart.as(f, dart.throw_("Unimplemented type (T) → bool")));
      }
      static map(iterable, f) {
        return new MappedIterable(iterable, f);
      }
      static mapList(list, f) {
        return new MappedListIterable(list, f);
      }
      static expand(iterable, f) {
        return new ExpandIterable(iterable, f);
      }
      takeList(list, n) {
        return new (SubListIterable$(T))(dart.as(list, core.Iterable$(T)), 0, n);
      }
      takeWhile(iterable, test) {
        return new (TakeWhileIterable$(T))(dart.as(iterable, core.Iterable$(T)), dart.as(test, dart.throw_("Unimplemented type (T) → bool")));
      }
      skipList(list, n) {
        return new (SubListIterable$(T))(dart.as(list, core.Iterable$(T)), n, null);
      }
      skipWhile(iterable, test) {
        return new (SkipWhileIterable$(T))(dart.as(iterable, core.Iterable$(T)), dart.as(test, dart.throw_("Unimplemented type (T) → bool")));
      }
      reversedList(list) {
        return new (ReversedListIterable$(T))(dart.as(list, core.Iterable$(T)));
      }
      static sortList(list, compare) {
        if (compare == null)
          compare = core.Comparable.compare;
        Sort.sort(list, compare);
      }
      static shuffleList(list, random) {
        if (random == null)
          random = new math.Random();
        let length = list[core.$length];
        while (dart.notNull(length) > 1) {
          let pos = random.nextInt(length);
          length = 1;
          let tmp = list[core.$get](length);
          list[core.$set](length, list[core.$get](pos));
          list[core.$set](pos, tmp);
        }
      }
      static indexOfList(list, element, start) {
        return Lists.indexOf(list, element, start, list[core.$length]);
      }
      static lastIndexOfList(list, element, start) {
        if (start == null)
          start = dart.notNull(list[core.$length]) - 1;
        return Lists.lastIndexOf(list, element, start);
      }
      static [_rangeCheck](list, start, end) {
        core.RangeError.checkValidRange(start, end, list[core.$length]);
      }
      getRangeList(list, start, end) {
        IterableMixinWorkaround[_rangeCheck](list, start, end);
        return new (SubListIterable$(T))(dart.as(list, core.Iterable$(T)), start, end);
      }
      static setRangeList(list, start, end, from, skipCount) {
        IterableMixinWorkaround[_rangeCheck](list, start, end);
        let length = dart.notNull(end) - dart.notNull(start);
        if (length == 0)
          return;
        if (dart.notNull(skipCount) < 0)
          throw new core.ArgumentError(skipCount);
        let otherList = null;
        let otherStart = null;
        if (dart.is(from, core.List)) {
          otherList = from;
          otherStart = skipCount;
        } else {
          otherList = from[core.$skip](skipCount)[core.$toList]({growable: false});
          otherStart = 0;
        }
        if (dart.notNull(otherStart) + dart.notNull(length) > dart.notNull(otherList[core.$length])) {
          throw IterableElementError.tooFew();
        }
        Lists.copy(otherList, otherStart, list, start, length);
      }
      static replaceRangeList(list, start, end, iterable) {
        IterableMixinWorkaround[_rangeCheck](list, start, end);
        if (!dart.is(iterable, EfficientLength)) {
          iterable = iterable[core.$toList]();
        }
        let removeLength = dart.notNull(end) - dart.notNull(start);
        let insertLength = iterable[core.$length];
        if (dart.notNull(removeLength) >= dart.notNull(insertLength)) {
          let delta = dart.notNull(removeLength) - dart.notNull(insertLength);
          let insertEnd = dart.notNull(start) + dart.notNull(insertLength);
          let newEnd = dart.notNull(list[core.$length]) - dart.notNull(delta);
          list[core.$setRange](start, insertEnd, iterable);
          if (delta != 0) {
            list[core.$setRange](insertEnd, newEnd, list, end);
            list[core.$length] = newEnd;
          }
        } else {
          let delta = dart.notNull(insertLength) - dart.notNull(removeLength);
          let newLength = dart.notNull(list[core.$length]) + dart.notNull(delta);
          let insertEnd = dart.notNull(start) + dart.notNull(insertLength);
          list[core.$length] = newLength;
          list[core.$setRange](insertEnd, newLength, list, end);
          list[core.$setRange](start, insertEnd, iterable);
        }
      }
      static fillRangeList(list, start, end, fillValue) {
        IterableMixinWorkaround[_rangeCheck](list, start, end);
        for (let i = start; dart.notNull(i) < dart.notNull(end); i = dart.notNull(i) + 1) {
          list[core.$set](i, fillValue);
        }
      }
      static insertAllList(list, index, iterable) {
        core.RangeError.checkValueInInterval(index, 0, list[core.$length], "index");
        if (!dart.is(iterable, EfficientLength)) {
          iterable = iterable[core.$toList]({growable: false});
        }
        let insertionLength = iterable[core.$length];
        list[core.$length] = insertionLength;
        list[core.$setRange](dart.notNull(index) + dart.notNull(insertionLength), list[core.$length], list, index);
        for (let element of iterable) {
          list[core.$set](((x) => index = dart.notNull(x) + 1, x)(index), element);
        }
      }
      static setAllList(list, index, iterable) {
        core.RangeError.checkValueInInterval(index, 0, list[core.$length], "index");
        for (let element of iterable) {
          list[core.$set](((x) => index = dart.notNull(x) + 1, x)(index), element);
        }
      }
      asMapList(l) {
        return new (ListMapView$(T))(dart.as(l, core.List$(T)));
      }
      static setContainsAll(set, other) {
        for (let element of other) {
          if (!dart.notNull(set[core.$contains](element)))
            return false;
        }
        return true;
      }
      static setIntersection(set, other, result) {
        let smaller = null;
        let larger = null;
        if (dart.notNull(set[core.$length]) < dart.notNull(other[core.$length])) {
          smaller = set;
          larger = other;
        } else {
          smaller = other;
          larger = set;
        }
        for (let element of smaller) {
          if (larger[core.$contains](element)) {
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
          if (!dart.notNull(other[core.$contains](element))) {
            result.add(element);
          }
        }
        return result;
      }
    }
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
  let FixedLengthListMixin$ = dart.generic(function(E) {
    class FixedLengthListMixin extends core.Object {
      set length(newLength) {
        throw new core.UnsupportedError("Cannot change the length of a fixed-length list");
      }
      add(value) {
        throw new core.UnsupportedError("Cannot add to a fixed-length list");
      }
      insert(index, value) {
        throw new core.UnsupportedError("Cannot add to a fixed-length list");
      }
      insertAll(at, iterable) {
        throw new core.UnsupportedError("Cannot add to a fixed-length list");
      }
      addAll(iterable) {
        throw new core.UnsupportedError("Cannot add to a fixed-length list");
      }
      remove(element) {
        throw new core.UnsupportedError("Cannot remove from a fixed-length list");
      }
      removeWhere(test) {
        throw new core.UnsupportedError("Cannot remove from a fixed-length list");
      }
      retainWhere(test) {
        throw new core.UnsupportedError("Cannot remove from a fixed-length list");
      }
      clear() {
        throw new core.UnsupportedError("Cannot clear a fixed-length list");
      }
      removeAt(index) {
        throw new core.UnsupportedError("Cannot remove from a fixed-length list");
      }
      removeLast() {
        throw new core.UnsupportedError("Cannot remove from a fixed-length list");
      }
      removeRange(start, end) {
        throw new core.UnsupportedError("Cannot remove from a fixed-length list");
      }
      replaceRange(start, end, iterable) {
        throw new core.UnsupportedError("Cannot remove from a fixed-length list");
      }
    }
    return FixedLengthListMixin;
  });
  let FixedLengthListMixin = FixedLengthListMixin$();
  let UnmodifiableListMixin$ = dart.generic(function(E) {
    class UnmodifiableListMixin extends core.Object {
      [core.$set](index, value) {
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      set [core.$length](newLength) {
        throw new core.UnsupportedError("Cannot change the length of an unmodifiable list");
      }
      [core.$setAll](at, iterable) {
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      [core.$add](value) {
        throw new core.UnsupportedError("Cannot add to an unmodifiable list");
      }
      [core.$insert](index, value) {
        throw new core.UnsupportedError("Cannot add to an unmodifiable list");
      }
      [core.$insertAll](at, iterable) {
        throw new core.UnsupportedError("Cannot add to an unmodifiable list");
      }
      [core.$addAll](iterable) {
        throw new core.UnsupportedError("Cannot add to an unmodifiable list");
      }
      [core.$remove](element) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      [core.$removeWhere](test) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      [core.$retainWhere](test) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      [core.$sort](compare) {
        if (compare === void 0)
          compare = null;
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      [core.$shuffle](random) {
        if (random === void 0)
          random = null;
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      [core.$clear]() {
        throw new core.UnsupportedError("Cannot clear an unmodifiable list");
      }
      [core.$removeAt](index) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      [core.$removeLast]() {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      [core.$setRange](start, end, iterable, skipCount) {
        if (skipCount === void 0)
          skipCount = 0;
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      [core.$removeRange](start, end) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      [core.$replaceRange](start, end, iterable) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      [core.$fillRange](start, end, fillValue) {
        if (fillValue === void 0)
          fillValue = null;
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
    }
    UnmodifiableListMixin[dart.implements] = () => [core.List$(E)];
    return UnmodifiableListMixin;
  });
  let UnmodifiableListMixin = UnmodifiableListMixin$();
  let FixedLengthListBase$ = dart.generic(function(E) {
    class FixedLengthListBase extends dart.mixin(FixedLengthListMixin$(E)) {}
    return FixedLengthListBase;
  });
  let FixedLengthListBase = FixedLengthListBase$();
  let UnmodifiableListBase$ = dart.generic(function(E) {
    class UnmodifiableListBase extends dart.mixin(UnmodifiableListMixin$(E)) {}
    return UnmodifiableListBase;
  });
  let UnmodifiableListBase = UnmodifiableListBase$();
  let _backedList = dart.JsSymbol('_backedList');
  class _ListIndicesIterable extends ListIterable$(core.int) {
    _ListIndicesIterable(backedList) {
      this[_backedList] = backedList;
      super.ListIterable();
    }
    get [core.$length]() {
      return this[_backedList][core.$length];
    }
    [core.$elementAt](index) {
      core.RangeError.checkValidIndex(index, this);
      return index;
    }
  }
  let _values = dart.JsSymbol('_values');
  let ListMapView$ = dart.generic(function(E) {
    class ListMapView extends core.Object {
      ListMapView(values) {
        this[_values] = values;
      }
      get(key) {
        return this.containsKey(key) ? this[_values][core.$get](key) : null;
      }
      get length() {
        return this[_values][core.$length];
      }
      get values() {
        return new (SubListIterable$(E))(this[_values], 0, null);
      }
      get keys() {
        return new _ListIndicesIterable(this[_values]);
      }
      get isEmpty() {
        return this[_values][core.$isEmpty];
      }
      get isNotEmpty() {
        return this[_values][core.$isNotEmpty];
      }
      containsValue(value) {
        return this[_values][core.$contains](value);
      }
      containsKey(key) {
        return dart.notNull(typeof key == 'number') && dart.notNull(key) >= 0 && dart.notNull(key) < dart.notNull(this.length);
      }
      forEach(f) {
        let length = this[_values][core.$length];
        for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
          f(i, this[_values][core.$get](i));
          if (length != this[_values][core.$length]) {
            throw new core.ConcurrentModificationError(this[_values]);
          }
        }
      }
      set(key, value) {
        throw new core.UnsupportedError("Cannot modify an unmodifiable map");
      }
      putIfAbsent(key, ifAbsent) {
        throw new core.UnsupportedError("Cannot modify an unmodifiable map");
      }
      remove(key) {
        throw new core.UnsupportedError("Cannot modify an unmodifiable map");
      }
      clear() {
        throw new core.UnsupportedError("Cannot modify an unmodifiable map");
      }
      addAll(other) {
        throw new core.UnsupportedError("Cannot modify an unmodifiable map");
      }
      toString() {
        return collection.Maps.mapToString(this);
      }
    }
    ListMapView[dart.implements] = () => [core.Map$(core.int, E)];
    return ListMapView;
  });
  let ListMapView = ListMapView$();
  let ReversedListIterable$ = dart.generic(function(E) {
    class ReversedListIterable extends ListIterable$(E) {
      ReversedListIterable(source) {
        this[_source] = source;
        super.ListIterable();
      }
      get [core.$length]() {
        return this[_source][core.$length];
      }
      [core.$elementAt](index) {
        return this[_source][core.$elementAt](dart.notNull(this[_source][core.$length]) - 1 - dart.notNull(index));
      }
    }
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
  // Function makeListFixedLength: (List<dynamic>) → List
  function makeListFixedLength(growableList) {
    _interceptors.JSArray.markFixedList(growableList);
    return growableList;
  }
  class Lists extends core.Object {
    static copy(src, srcStart, dst, dstStart, count) {
      if (dart.notNull(srcStart) < dart.notNull(dstStart)) {
        for (let i = dart.notNull(srcStart) + dart.notNull(count) - 1, j = dart.notNull(dstStart) + dart.notNull(count) - 1; dart.notNull(i) >= dart.notNull(srcStart); i = dart.notNull(i) - 1, j = dart.notNull(j) - 1) {
          dst[core.$set](j, src[core.$get](i));
        }
      } else {
        for (let i = srcStart, j = dstStart; dart.notNull(i) < dart.notNull(srcStart) + dart.notNull(count); i = dart.notNull(i) + 1, j = dart.notNull(j) + 1) {
          dst[core.$set](j, src[core.$get](i));
        }
      }
    }
    static areEqual(a, b) {
      if (core.identical(a, b))
        return true;
      if (!dart.notNull(dart.is(b, core.List)))
        return false;
      let length = a[core.$length];
      if (!dart.equals(length, dart.dload(b, 'length')))
        return false;
      for (let i = 0; dart.notNull(i) < dart.notNull(length); i = dart.notNull(i) + 1) {
        if (!dart.notNull(core.identical(a[core.$get](i), dart.dindex(b, i))))
          return false;
      }
      return true;
    }
    static indexOf(a, element, startIndex, endIndex) {
      if (dart.notNull(startIndex) >= dart.notNull(a[core.$length])) {
        return -1;
      }
      if (dart.notNull(startIndex) < 0) {
        startIndex = 0;
      }
      for (let i = startIndex; dart.notNull(i) < dart.notNull(endIndex); i = dart.notNull(i) + 1) {
        if (dart.equals(a[core.$get](i), element)) {
          return i;
        }
      }
      return -1;
    }
    static lastIndexOf(a, element, startIndex) {
      if (dart.notNull(startIndex) < 0) {
        return -1;
      }
      if (dart.notNull(startIndex) >= dart.notNull(a[core.$length])) {
        startIndex = dart.notNull(a[core.$length]) - 1;
      }
      for (let i = startIndex; dart.notNull(i) >= 0; i = dart.notNull(i) - 1) {
        if (dart.equals(a[core.$get](i), element)) {
          return i;
        }
      }
      return -1;
    }
    static indicesCheck(a, start, end) {
      core.RangeError.checkValidRange(start, end, a[core.$length]);
    }
    static rangeCheck(a, start, length) {
      core.RangeError.checkNotNegative(length);
      core.RangeError.checkNotNegative(start);
      if (dart.notNull(start) + dart.notNull(length) > dart.notNull(a[core.$length])) {
        let message = `${start} + ${length} must be in the range [0..${a[core.$length]}]`;
        throw new core.RangeError.range(length, 0, dart.notNull(a[core.$length]) - dart.notNull(start), "length", message);
      }
    }
  }
  exports.printToZone = null;
  // Function printToConsole: (String) → void
  function printToConsole(line) {
    _js_primitives.printString(`${line}`);
  }
  let _doSort = dart.JsSymbol('_doSort');
  let _INSERTION_SORT_THRESHOLD = dart.JsSymbol('_INSERTION_SORT_THRESHOLD');
  let _insertionSort = dart.JsSymbol('_insertionSort');
  let _dualPivotQuicksort = dart.JsSymbol('_dualPivotQuicksort');
  class Sort extends core.Object {
    static sort(a, compare) {
      Sort[_doSort](a, 0, dart.notNull(a[core.$length]) - 1, compare);
    }
    static sortRange(a, from, to, compare) {
      if (dart.notNull(from) < 0 || dart.notNull(to) > dart.notNull(a[core.$length]) || dart.notNull(to) < dart.notNull(from)) {
        throw "OutOfRange";
      }
      Sort[_doSort](a, from, dart.notNull(to) - 1, compare);
    }
    static [_doSort](a, left, right, compare) {
      if (dart.notNull(right) - dart.notNull(left) <= dart.notNull(Sort[_INSERTION_SORT_THRESHOLD])) {
        Sort[_insertionSort](a, left, right, compare);
      } else {
        Sort[_dualPivotQuicksort](a, left, right, compare);
      }
    }
    static [_insertionSort](a, left, right, compare) {
      for (let i = dart.notNull(left) + 1; dart.notNull(i) <= dart.notNull(right); i = dart.notNull(i) + 1) {
        let el = a[core.$get](i);
        let j = i;
        while (dart.notNull(j) > dart.notNull(left) && dart.notNull(dart.dinvokef(compare, a[core.$get](dart.notNull(j) - 1), el)) > 0) {
          a[core.$set](j, a[core.$get](dart.notNull(j) - 1));
          j = dart.notNull(j) - 1;
        }
        a[core.$set](j, el);
      }
    }
    static [_dualPivotQuicksort](a, left, right, compare) {
      dart.assert(dart.notNull(right) - dart.notNull(left) > dart.notNull(Sort[_INSERTION_SORT_THRESHOLD]));
      let sixth = ((dart.notNull(right) - dart.notNull(left) + 1) / 6).truncate();
      let index1 = dart.notNull(left) + dart.notNull(sixth);
      let index5 = dart.notNull(right) - dart.notNull(sixth);
      let index3 = ((dart.notNull(left) + dart.notNull(right)) / 2).truncate();
      let index2 = dart.notNull(index3) - dart.notNull(sixth);
      let index4 = dart.notNull(index3) + dart.notNull(sixth);
      let el1 = a[core.$get](index1);
      let el2 = a[core.$get](index2);
      let el3 = a[core.$get](index3);
      let el4 = a[core.$get](index4);
      let el5 = a[core.$get](index5);
      if (dart.notNull(dart.dinvokef(compare, el1, el2)) > 0) {
        let t = el1;
        el1 = el2;
        el2 = t;
      }
      if (dart.notNull(dart.dinvokef(compare, el4, el5)) > 0) {
        let t = el4;
        el4 = el5;
        el5 = t;
      }
      if (dart.notNull(dart.dinvokef(compare, el1, el3)) > 0) {
        let t = el1;
        el1 = el3;
        el3 = t;
      }
      if (dart.notNull(dart.dinvokef(compare, el2, el3)) > 0) {
        let t = el2;
        el2 = el3;
        el3 = t;
      }
      if (dart.notNull(dart.dinvokef(compare, el1, el4)) > 0) {
        let t = el1;
        el1 = el4;
        el4 = t;
      }
      if (dart.notNull(dart.dinvokef(compare, el3, el4)) > 0) {
        let t = el3;
        el3 = el4;
        el4 = t;
      }
      if (dart.notNull(dart.dinvokef(compare, el2, el5)) > 0) {
        let t = el2;
        el2 = el5;
        el5 = t;
      }
      if (dart.notNull(dart.dinvokef(compare, el2, el3)) > 0) {
        let t = el2;
        el2 = el3;
        el3 = t;
      }
      if (dart.notNull(dart.dinvokef(compare, el4, el5)) > 0) {
        let t = el4;
        el4 = el5;
        el5 = t;
      }
      let pivot1 = el2;
      let pivot2 = el4;
      a[core.$set](index1, el1);
      a[core.$set](index3, el3);
      a[core.$set](index5, el5);
      a[core.$set](index2, a[core.$get](left));
      a[core.$set](index4, a[core.$get](right));
      let less = dart.notNull(left) + 1;
      let great = dart.notNull(right) - 1;
      let pivots_are_equal = dart.dinvokef(compare, pivot1, pivot2) == 0;
      if (pivots_are_equal) {
        let pivot = pivot1;
        for (let k = less; dart.notNull(k) <= dart.notNull(great); k = dart.notNull(k) + 1) {
          let ak = a[core.$get](k);
          let comp = dart.dinvokef(compare, ak, pivot);
          if (comp == 0)
            continue;
          if (dart.notNull(comp) < 0) {
            if (k != less) {
              a[core.$set](k, a[core.$get](less));
              a[core.$set](less, ak);
            }
            less = dart.notNull(less) + 1;
          } else {
            while (true) {
              comp = dart.dinvokef(compare, a[core.$get](great), pivot);
              if (dart.notNull(comp) > 0) {
                great = dart.notNull(great) - 1;
                continue;
              } else if (dart.notNull(comp) < 0) {
                a[core.$set](k, a[core.$get](less));
                a[core.$set](((x) => less = dart.notNull(x) + 1, x)(less), a[core.$get](great));
                a[core.$set](((x) => great = dart.notNull(x) - 1, x)(great), ak);
                break;
              } else {
                a[core.$set](k, a[core.$get](great));
                a[core.$set](((x) => great = dart.notNull(x) - 1, x)(great), ak);
                break;
              }
            }
          }
        }
      } else {
        for (let k = less; dart.notNull(k) <= dart.notNull(great); k = dart.notNull(k) + 1) {
          let ak = a[core.$get](k);
          let comp_pivot1 = dart.dinvokef(compare, ak, pivot1);
          if (dart.notNull(comp_pivot1) < 0) {
            if (k != less) {
              a[core.$set](k, a[core.$get](less));
              a[core.$set](less, ak);
            }
            less = dart.notNull(less) + 1;
          } else {
            let comp_pivot2 = dart.dinvokef(compare, ak, pivot2);
            if (dart.notNull(comp_pivot2) > 0) {
              while (true) {
                let comp = dart.dinvokef(compare, a[core.$get](great), pivot2);
                if (dart.notNull(comp) > 0) {
                  great = dart.notNull(great) - 1;
                  if (dart.notNull(great) < dart.notNull(k))
                    break;
                  continue;
                } else {
                  comp = dart.dinvokef(compare, a[core.$get](great), pivot1);
                  if (dart.notNull(comp) < 0) {
                    a[core.$set](k, a[core.$get](less));
                    a[core.$set](((x) => less = dart.notNull(x) + 1, x)(less), a[core.$get](great));
                    a[core.$set](((x) => great = dart.notNull(x) - 1, x)(great), ak);
                  } else {
                    a[core.$set](k, a[core.$get](great));
                    a[core.$set](((x) => great = dart.notNull(x) - 1, x)(great), ak);
                  }
                  break;
                }
              }
            }
          }
        }
      }
      a[core.$set](left, a[core.$get](dart.notNull(less) - 1));
      a[core.$set](dart.notNull(less) - 1, pivot1);
      a[core.$set](right, a[core.$get](dart.notNull(great) + 1));
      a[core.$set](dart.notNull(great) + 1, pivot2);
      Sort[_doSort](a, left, dart.notNull(less) - 2, compare);
      Sort[_doSort](a, dart.notNull(great) + 2, right, compare);
      if (pivots_are_equal) {
        return;
      }
      if (dart.notNull(less) < dart.notNull(index1) && dart.notNull(great) > dart.notNull(index5)) {
        while (dart.dinvokef(compare, a[core.$get](less), pivot1) == 0) {
          less = dart.notNull(less) + 1;
        }
        while (dart.dinvokef(compare, a[core.$get](great), pivot2) == 0) {
          great = dart.notNull(great) - 1;
        }
        for (let k = less; dart.notNull(k) <= dart.notNull(great); k = dart.notNull(k) + 1) {
          let ak = a[core.$get](k);
          let comp_pivot1 = dart.dinvokef(compare, ak, pivot1);
          if (comp_pivot1 == 0) {
            if (k != less) {
              a[core.$set](k, a[core.$get](less));
              a[core.$set](less, ak);
            }
            less = dart.notNull(less) + 1;
          } else {
            let comp_pivot2 = dart.dinvokef(compare, ak, pivot2);
            if (comp_pivot2 == 0) {
              while (true) {
                let comp = dart.dinvokef(compare, a[core.$get](great), pivot2);
                if (comp == 0) {
                  great = dart.notNull(great) - 1;
                  if (dart.notNull(great) < dart.notNull(k))
                    break;
                  continue;
                } else {
                  comp = dart.dinvokef(compare, a[core.$get](great), pivot1);
                  if (dart.notNull(comp) < 0) {
                    a[core.$set](k, a[core.$get](less));
                    a[core.$set](((x) => less = dart.notNull(x) + 1, x)(less), a[core.$get](great));
                    a[core.$set](((x) => great = dart.notNull(x) - 1, x)(great), ak);
                  } else {
                    a[core.$set](k, a[core.$get](great));
                    a[core.$set](((x) => great = dart.notNull(x) - 1, x)(great), ak);
                  }
                  break;
                }
              }
            }
          }
        }
        Sort[_doSort](a, less, great, compare);
      } else {
        Sort[_doSort](a, less, great, compare);
      }
    }
  }
  Sort._INSERTION_SORT_THRESHOLD = 32;
  let _name = dart.JsSymbol('_name');
  class Symbol extends core.Object {
    Symbol(name) {
      this[_name] = name;
    }
    unvalidated(name$) {
      this[_name] = name$;
    }
    validated(name) {
      this[_name] = Symbol.validatePublicSymbol(name);
    }
    ['=='](other) {
      return dart.notNull(dart.is(other, Symbol)) && dart.notNull(dart.equals(this[_name], dart.dload(other, '_name')));
    }
    get hashCode() {
      let arbitraryPrime = 664597;
      return 536870911 & dart.notNull(arbitraryPrime) * dart.notNull(this[_name].hashCode);
    }
    toString() {
      return `Symbol("${this[_name]}")`;
    }
    static getName(symbol) {
      return symbol[_name];
    }
    static validatePublicSymbol(name) {
      if (dart.notNull(name.isEmpty) || dart.notNull(Symbol.publicSymbolPattern.hasMatch(name)))
        return name;
      if (name.startsWith('_')) {
        throw new core.ArgumentError(`"${name}" is a private identifier`);
      }
      throw new core.ArgumentError(`"${name}" is not a valid (qualified) symbol name`);
    }
    static isValidSymbol(name) {
      return dart.notNull(name.isEmpty) || dart.notNull(Symbol.symbolPattern.hasMatch(name));
    }
  }
  Symbol[dart.implements] = () => [core.Symbol];
  dart.defineNamedConstructor(Symbol, 'unvalidated');
  dart.defineNamedConstructor(Symbol, 'validated');
  Symbol.reservedWordRE = '(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|d(?:efault|o)|' + 'e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|i[fns]|n(?:ew|ull)|' + 'ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|r(?:ue|y))|' + 'v(?:ar|oid)|w(?:hile|ith))';
  Symbol.publicIdentifierRE = '(?!' + `${Symbol.reservedWordRE}` + '\\b(?!\\$))[a-zA-Z$][\\w$]*';
  Symbol.identifierRE = '(?!' + `${Symbol.reservedWordRE}` + '\\b(?!\\$))[a-zA-Z$_][\\w$]*';
  Symbol.operatorRE = '(?:[\\-+*/%&|^]|\\[\\]=?|==|~/?|<[<=]?|>[>=]?|unary-)';
  dart.defineLazyProperties(Symbol, {
    get publicSymbolPattern() {
      return new core.RegExp(`^(?:${Symbol.operatorRE}$|${Symbol.publicIdentifierRE}(?:=?$|[.](?!$)))+?$`);
    },
    get symbolPattern() {
      return new core.RegExp(`^(?:${Symbol.operatorRE}$|${Symbol.identifierRE}(?:=?$|[.](?!$)))+?$`);
    }
  });
  let POWERS_OF_TEN = /* Unimplemented const */new core.List.from([1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0, 1000000000.0, 10000000000.0, 100000000000.0, 1000000000000.0, 10000000000000.0, 100000000000000.0, 1000000000000000.0, 10000000000000000.0, 100000000000000000.0, 1000000000000000000.0, 10000000000000000000.0, 100000000000000000000.0, 1e+21, 1e+22]);
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
})(_internal || (_internal = {}));
