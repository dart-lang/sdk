var _internal;
(function (_internal) {
  'use strict';
  let POWERS_OF_TEN = /* Unimplemented const */new List.from([1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 10000000.0, 100000000.0, 1000000000.0, 10000000000.0, 100000000000.0, 1000000000000.0, 10000000000000.0, 100000000000000.0, 1000000000000000.0, 10000000000000000.0, 100000000000000000.0, 1000000000000000000.0, 10000000000000000000.0, 100000000000000000000.0, 1e+21, 1e+22]);
  class EfficientLength extends dart.Object {
  }

  let ListIterable$ = dart.generic(function(E) {
    class ListIterable extends collection.IterableBase$(E) {
      ListIterable() {
        super.IterableBase();
      }
      get iterator() { return new ListIterator(this); }
      forEach(action) {
        let length = this.length;
        for (let i = 0; i < length; i++) {
          action(this.elementAt(i));
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
      }
      get isEmpty() { return this.length === 0; }
      get first() {
        if (this.length === 0) throw IterableElementError.noElement();
        return this.elementAt(0);
      }
      get last() {
        if (this.length === 0) throw IterableElementError.noElement();
        return this.elementAt(this.length - 1);
      }
      get single() {
        if (this.length === 0) throw IterableElementError.noElement();
        if (this.length > 1) throw IterableElementError.tooMany();
        return this.elementAt(0);
      }
      contains(element) {
        let length = this.length;
        for (let i = 0; i < length; i++) {
          if (dart.equals(this.elementAt(i), element)) return true;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return false;
      }
      every(test) {
        let length = this.length;
        for (let i = 0; i < length; i++) {
          if (!dart.notNull(test(this.elementAt(i)))) return false;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return true;
      }
      any(test) {
        let length = this.length;
        for (let i = 0; i < length; i++) {
          if (test(this.elementAt(i))) return true;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return false;
      }
      firstWhere(test, opt$) {
        let orElse = opt$.orElse === undefined ? null : opt$.orElse;
        let length = this.length;
        for (let i = 0; i < length; i++) {
          let element = this.elementAt(i);
          if (test(element)) return element;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (orElse !== null) return orElse();
        throw IterableElementError.noElement();
      }
      lastWhere(test, opt$) {
        let orElse = opt$.orElse === undefined ? null : opt$.orElse;
        let length = this.length;
        for (let i = length - 1; i >= 0; i--) {
          let element = this.elementAt(i);
          if (test(element)) return element;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (orElse !== null) return orElse();
        throw IterableElementError.noElement();
      }
      singleWhere(test) {
        let length = this.length;
        let match = dart.as(null, E);
        let matchFound = false;
        for (let i = 0; i < length; i++) {
          let element = this.elementAt(i);
          if (test(element)) {
            if (matchFound) {
              throw IterableElementError.tooMany();
            }
            matchFound = true;
            match = element;
          }
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        if (matchFound) return match;
        throw IterableElementError.noElement();
      }
      join(separator) {
        if (separator === undefined) separator = "";
        let length = this.length;
        if (!dart.notNull(separator.isEmpty)) {
          if (length === 0) return "";
          let first = `${this.elementAt(0)}`;
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
          let buffer = new core.StringBuffer(first);
          for (let i = 1; i < length; i++) {
            buffer.write(separator);
            buffer.write(this.elementAt(i));
            if (length !== this.length) {
              throw new core.ConcurrentModificationError(this);
            }
          }
          return buffer.toString();
        } else {
          let buffer = new core.StringBuffer();
          for (let i = 0; i < length; i++) {
            buffer.write(this.elementAt(i));
            if (length !== this.length) {
              throw new core.ConcurrentModificationError(this);
            }
          }
          return buffer.toString();
        }
      }
      where(test) { return super.where(test); }
      map(f) { return new MappedListIterable(this, f); }
      reduce(combine) {
        let length = this.length;
        if (length === 0) throw IterableElementError.noElement();
        let value = this.elementAt(0);
        for (let i = 1; i < length; i++) {
          value = combine(value, this.elementAt(i));
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return value;
      }
      fold(initialValue, combine) {
        let value = initialValue;
        let length = this.length;
        for (let i = 0; i < length; i++) {
          value = combine(value, this.elementAt(i));
          if (length !== this.length) {
            throw new core.ConcurrentModificationError(this);
          }
        }
        return value;
      }
      skip(count) { return new SubListIterable(this, count, null); }
      skipWhile(test) { return super.skipWhile(test); }
      take(count) { return new SubListIterable(this, 0, count); }
      takeWhile(test) { return super.takeWhile(test); }
      toList(opt$) {
        let growable = opt$.growable === undefined ? true : opt$.growable;
        let result = null;
        if (growable) {
          result = ((_) => {
            _.length = this.length;
            return _;
          }).bind(this)(new core.List());
        } else {
          result = new core.List(this.length);
        }
        for (let i = 0; i < this.length; i++) {
          result.set(i, this.elementAt(i));
        }
        return result;
      }
      toSet() {
        let result = new core.Set();
        for (let i = 0; i < this.length; i++) {
          result.add(this.elementAt(i));
        }
        return result;
      }
    }
    return ListIterable;
  });
  let ListIterable = ListIterable$(dynamic);

  let SubListIterable$ = dart.generic(function(E) {
    class SubListIterable extends ListIterable$(E) {
      SubListIterable(_iterable, _start, _endOrLength) {
        this._iterable = _iterable;
        this._start = _start;
        this._endOrLength = _endOrLength;
        super.ListIterable();
        core.RangeError.checkNotNegative(this._start, "start");
        if (this._endOrLength !== null) {
          core.RangeError.checkNotNegative(this._endOrLength, "end");
          if (this._start > this._endOrLength) {
            throw new core.RangeError.range(this._start, 0, this._endOrLength, "start");
          }
        }
      }
      get _endIndex() {
        let length = this._iterable.length;
        if (dart.notNull(this._endOrLength === null) || dart.notNull(this._endOrLength > length)) return length;
        return this._endOrLength;
      }
      get _startIndex() {
        let length = this._iterable.length;
        if (this._start > length) return length;
        return this._start;
      }
      get length() {
        let length = this._iterable.length;
        if (this._start >= length) return 0;
        if (dart.notNull(this._endOrLength === null) || dart.notNull(this._endOrLength >= length)) {
          return length - this._start;
        }
        return this._endOrLength - this._start;
      }
      elementAt(index) {
        let realIndex = this._startIndex + index;
        if (dart.notNull(index < 0) || dart.notNull(realIndex >= this._endIndex)) {
          throw new core.RangeError.index(index, this, "index");
        }
        return this._iterable.elementAt(realIndex);
      }
      skip(count) {
        core.RangeError.checkNotNegative(count, "count");
        let newStart = this._start + count;
        if (dart.notNull(this._endOrLength !== null) && dart.notNull(newStart >= this._endOrLength)) {
          return new EmptyIterable();
        }
        return new SubListIterable(this._iterable, newStart, this._endOrLength);
      }
      take(count) {
        core.RangeError.checkNotNegative(count, "count");
        if (this._endOrLength === null) {
          return new SubListIterable(this._iterable, this._start, this._start + count);
        } else {
          let newEnd = this._start + count;
          if (this._endOrLength < newEnd) return this;
          return new SubListIterable(this._iterable, this._start, newEnd);
        }
      }
      toList(opt$) {
        let growable = opt$.growable === undefined ? true : opt$.growable;
        let start = this._start;
        let end = this._iterable.length;
        if (dart.notNull(this._endOrLength !== null) && dart.notNull(this._endOrLength < end)) end = this._endOrLength;
        let length = end - start;
        if (length < 0) length = 0;
        let result = growable ? (((_) => {
          _.length = length;
          return _;
        }).bind(this)(new core.List())) : new core.List(length);
        for (let i = 0; i < length; i++) {
          result.set(i, this._iterable.elementAt(start + i));
          if (this._iterable.length < end) throw new core.ConcurrentModificationError(this);
        }
        return dart.as(result, core.List$(E));
      }
    }
    return SubListIterable;
  });
  let SubListIterable = SubListIterable$(dynamic);

  let ListIterator$ = dart.generic(function(E) {
    class ListIterator extends dart.Object {
      ListIterator(iterable) {
        this._iterable = iterable;
        this._length = iterable.length;
        this._index = 0;
        this._current = dart.as(null, E);
      }
      get current() { return this._current; }
      moveNext() {
        let length = this._iterable.length;
        if (this._length !== length) {
          throw new core.ConcurrentModificationError(this._iterable);
        }
        if (this._index >= length) {
          this._current = dart.as(null, E);
          return false;
        }
        this._current = this._iterable.elementAt(this._index);
        this._index++;
        return true;
      }
    }
    return ListIterator;
  });
  let ListIterator = ListIterator$(dynamic);

  let MappedIterable$ = dart.generic(function(S, T) {
    class MappedIterable extends collection.IterableBase$(T) {
      MappedIterable(iterable, function) {
        if (dart.is(iterable, EfficientLength)) {
          return new EfficientLengthMappedIterable(iterable, function);
        }
        return new MappedIterable._(iterable, function);
      }
      MappedIterable$_(_iterable, _f) {
        this._iterable = _iterable;
        this._f = _f;
        super.IterableBase();
      }
      get iterator() { return new MappedIterator(this._iterable.iterator, this._f); }
      get length() { return this._iterable.length; }
      get isEmpty() { return this._iterable.isEmpty; }
      get first() { return this._f(this._iterable.first); }
      get last() { return this._f(this._iterable.last); }
      get single() { return this._f(this._iterable.single); }
      elementAt(index) { return this._f(this._iterable.elementAt(index)); }
    }
    dart.defineNamedConstructor(MappedIterable, "_");
    return MappedIterable;
  });
  let MappedIterable = MappedIterable$(dynamic, dynamic);

  let EfficientLengthMappedIterable$ = dart.generic(function(S, T) {
    class EfficientLengthMappedIterable extends MappedIterable$(S, T) {
      EfficientLengthMappedIterable(iterable, function) {
        super.MappedIterable$_(dart.as(iterable, core.Iterable$(S)), function);
      }
    }
    return EfficientLengthMappedIterable;
  });
  let EfficientLengthMappedIterable = EfficientLengthMappedIterable$(dynamic, dynamic);

  let MappedIterator$ = dart.generic(function(S, T) {
    class MappedIterator extends core.Iterator$(T) {
      MappedIterator(_iterator, _f) {
        this._iterator = _iterator;
        this._f = _f;
        this._current = dart.as(null, T);
        super.Iterator();
      }
      moveNext() {
        if (this._iterator.moveNext()) {
          this._current = this._f(this._iterator.current);
          return true;
        }
        this._current = dart.as(null, T);
        return false;
      }
      get current() { return this._current; }
    }
    return MappedIterator;
  });
  let MappedIterator = MappedIterator$(dynamic, dynamic);

  let MappedListIterable$ = dart.generic(function(S, T) {
    class MappedListIterable extends ListIterable$(T) {
      MappedListIterable(_source, _f) {
        this._source = _source;
        this._f = _f;
        super.ListIterable();
      }
      get length() { return this._source.length; }
      elementAt(index) { return this._f(this._source.elementAt(index)); }
    }
    return MappedListIterable;
  });
  let MappedListIterable = MappedListIterable$(dynamic, dynamic);

  let WhereIterable$ = dart.generic(function(E) {
    class WhereIterable extends collection.IterableBase$(E) {
      WhereIterable(_iterable, _f) {
        this._iterable = _iterable;
        this._f = _f;
        super.IterableBase();
      }
      get iterator() { return new WhereIterator(this._iterable.iterator, this._f); }
    }
    return WhereIterable;
  });
  let WhereIterable = WhereIterable$(dynamic);

  let WhereIterator$ = dart.generic(function(E) {
    class WhereIterator extends core.Iterator$(E) {
      WhereIterator(_iterator, _f) {
        this._iterator = _iterator;
        this._f = _f;
        super.Iterator();
      }
      moveNext() {
        while (this._iterator.moveNext()) {
          if (this._f(this._iterator.current)) {
            return true;
          }
        }
        return false;
      }
      get current() { return this._iterator.current; }
    }
    return WhereIterator;
  });
  let WhereIterator = WhereIterator$(dynamic);

  let ExpandIterable$ = dart.generic(function(S, T) {
    class ExpandIterable extends collection.IterableBase$(T) {
      ExpandIterable(_iterable, _f) {
        this._iterable = _iterable;
        this._f = _f;
        super.IterableBase();
      }
      get iterator() { return new ExpandIterator(this._iterable.iterator, this._f); }
    }
    return ExpandIterable;
  });
  let ExpandIterable = ExpandIterable$(dynamic, dynamic);

  let ExpandIterator$ = dart.generic(function(S, T) {
    class ExpandIterator extends dart.Object {
      ExpandIterator(_iterator, _f) {
        this._iterator = _iterator;
        this._f = _f;
        this._currentExpansion = dart.as(new EmptyIterator(), core.Iterator$(T));
        this._current = dart.as(null, T);
      }
      _nextExpansion() {
      }
      get current() { return this._current; }
      moveNext() {
        if (this._currentExpansion === null) return false;
        while (!dart.notNull(this._currentExpansion.moveNext())) {
          this._current = dart.as(null, T);
          if (this._iterator.moveNext()) {
            this._currentExpansion = null;
            this._currentExpansion = dart.as(this._f(this._iterator.current).iterator, core.Iterator$(T));
          } else {
            return false;
          }
        }
        this._current = this._currentExpansion.current;
        return true;
      }
    }
    return ExpandIterator;
  });
  let ExpandIterator = ExpandIterator$(dynamic, dynamic);

  let TakeIterable$ = dart.generic(function(E) {
    class TakeIterable extends collection.IterableBase$(E) {
      TakeIterable(iterable, takeCount) {
        if (dart.notNull(!(typeof takeCount == "number")) || dart.notNull(takeCount < 0)) {
          throw new core.ArgumentError(takeCount);
        }
        if (dart.is(iterable, EfficientLength)) {
          return new EfficientLengthTakeIterable(iterable, takeCount);
        }
        return new TakeIterable._(iterable, takeCount);
      }
      TakeIterable$_(_iterable, _takeCount) {
        this._iterable = _iterable;
        this._takeCount = _takeCount;
        super.IterableBase();
      }
      get iterator() {
        return new TakeIterator(this._iterable.iterator, this._takeCount);
      }
    }
    dart.defineNamedConstructor(TakeIterable, "_");
    return TakeIterable;
  });
  let TakeIterable = TakeIterable$(dynamic);

  let EfficientLengthTakeIterable$ = dart.generic(function(E) {
    class EfficientLengthTakeIterable extends TakeIterable$(E) {
      EfficientLengthTakeIterable(iterable, takeCount) {
        super.TakeIterable$_(iterable, takeCount);
      }
      get length() {
        let iterableLength = this._iterable.length;
        if (iterableLength > this._takeCount) return this._takeCount;
        return iterableLength;
      }
    }
    return EfficientLengthTakeIterable;
  });
  let EfficientLengthTakeIterable = EfficientLengthTakeIterable$(dynamic);

  let TakeIterator$ = dart.generic(function(E) {
    class TakeIterator extends core.Iterator$(E) {
      TakeIterator(_iterator, _remaining) {
        this._iterator = _iterator;
        this._remaining = _remaining;
        super.Iterator();
        dart.assert(dart.notNull(typeof this._remaining == "number") && dart.notNull(this._remaining >= 0));
      }
      moveNext() {
        this._remaining--;
        if (this._remaining >= 0) {
          return this._iterator.moveNext();
        }
        this._remaining = -1;
        return false;
      }
      get current() {
        if (this._remaining < 0) return dart.as(null, E);
        return this._iterator.current;
      }
    }
    return TakeIterator;
  });
  let TakeIterator = TakeIterator$(dynamic);

  let TakeWhileIterable$ = dart.generic(function(E) {
    class TakeWhileIterable extends collection.IterableBase$(E) {
      TakeWhileIterable(_iterable, _f) {
        this._iterable = _iterable;
        this._f = _f;
        super.IterableBase();
      }
      get iterator() {
        return new TakeWhileIterator(this._iterable.iterator, this._f);
      }
    }
    return TakeWhileIterable;
  });
  let TakeWhileIterable = TakeWhileIterable$(dynamic);

  let TakeWhileIterator$ = dart.generic(function(E) {
    class TakeWhileIterator extends core.Iterator$(E) {
      TakeWhileIterator(_iterator, _f) {
        this._iterator = _iterator;
        this._f = _f;
        this._isFinished = false;
        super.Iterator();
      }
      moveNext() {
        if (this._isFinished) return false;
        if (dart.notNull(!dart.notNull(this._iterator.moveNext())) || dart.notNull(!dart.notNull(this._f(this._iterator.current)))) {
          this._isFinished = true;
          return false;
        }
        return true;
      }
      get current() {
        if (this._isFinished) return dart.as(null, E);
        return this._iterator.current;
      }
    }
    return TakeWhileIterator;
  });
  let TakeWhileIterator = TakeWhileIterator$(dynamic);

  let SkipIterable$ = dart.generic(function(E) {
    class SkipIterable extends collection.IterableBase$(E) {
      SkipIterable(iterable, count) {
        if (dart.is(iterable, EfficientLength)) {
          return new EfficientLengthSkipIterable(iterable, count);
        }
        return new SkipIterable._(iterable, count);
      }
      SkipIterable$_(_iterable, _skipCount) {
        this._iterable = _iterable;
        this._skipCount = _skipCount;
        super.IterableBase();
        if (!(typeof this._skipCount == "number")) {
          throw new core.ArgumentError.value(this._skipCount, "count is not an integer");
        }
        core.RangeError.checkNotNegative(this._skipCount, "count");
      }
      skip(count) {
        if (!(typeof this._skipCount == "number")) {
          throw new core.ArgumentError.value(this._skipCount, "count is not an integer");
        }
        core.RangeError.checkNotNegative(this._skipCount, "count");
        return new SkipIterable._(this._iterable, this._skipCount + count);
      }
      get iterator() {
        return new SkipIterator(this._iterable.iterator, this._skipCount);
      }
    }
    dart.defineNamedConstructor(SkipIterable, "_");
    return SkipIterable;
  });
  let SkipIterable = SkipIterable$(dynamic);

  let EfficientLengthSkipIterable$ = dart.generic(function(E) {
    class EfficientLengthSkipIterable extends SkipIterable$(E) {
      EfficientLengthSkipIterable(iterable, skipCount) {
        super.SkipIterable$_(iterable, skipCount);
      }
      get length() {
        let length = this._iterable.length - this._skipCount;
        if (length >= 0) return length;
        return 0;
      }
    }
    return EfficientLengthSkipIterable;
  });
  let EfficientLengthSkipIterable = EfficientLengthSkipIterable$(dynamic);

  let SkipIterator$ = dart.generic(function(E) {
    class SkipIterator extends core.Iterator$(E) {
      SkipIterator(_iterator, _skipCount) {
        this._iterator = _iterator;
        this._skipCount = _skipCount;
        super.Iterator();
        dart.assert(dart.notNull(typeof this._skipCount == "number") && dart.notNull(this._skipCount >= 0));
      }
      moveNext() {
        for (let i = 0; i < this._skipCount; i++) this._iterator.moveNext();
        this._skipCount = 0;
        return this._iterator.moveNext();
      }
      get current() { return this._iterator.current; }
    }
    return SkipIterator;
  });
  let SkipIterator = SkipIterator$(dynamic);

  let SkipWhileIterable$ = dart.generic(function(E) {
    class SkipWhileIterable extends collection.IterableBase$(E) {
      SkipWhileIterable(_iterable, _f) {
        this._iterable = _iterable;
        this._f = _f;
        super.IterableBase();
      }
      get iterator() {
        return new SkipWhileIterator(this._iterable.iterator, this._f);
      }
    }
    return SkipWhileIterable;
  });
  let SkipWhileIterable = SkipWhileIterable$(dynamic);

  let SkipWhileIterator$ = dart.generic(function(E) {
    class SkipWhileIterator extends core.Iterator$(E) {
      SkipWhileIterator(_iterator, _f) {
        this._iterator = _iterator;
        this._f = _f;
        this._hasSkipped = false;
        super.Iterator();
      }
      moveNext() {
        if (!dart.notNull(this._hasSkipped)) {
          this._hasSkipped = true;
          while (this._iterator.moveNext()) {
            if (!dart.notNull(this._f(this._iterator.current))) return true;
          }
        }
        return this._iterator.moveNext();
      }
      get current() { return this._iterator.current; }
    }
    return SkipWhileIterator;
  });
  let SkipWhileIterator = SkipWhileIterator$(dynamic);

  let EmptyIterable$ = dart.generic(function(E) {
    class EmptyIterable extends collection.IterableBase$(E) {
      EmptyIterable() {
        super.IterableBase();
      }
      get iterator() { return dart.as(new EmptyIterator(), core.Iterator$(E)); }
      forEach(action) {
      }
      get isEmpty() { return true; }
      get length() { return 0; }
      get first() {
        throw IterableElementError.noElement();
      }
      get last() {
        throw IterableElementError.noElement();
      }
      get single() {
        throw IterableElementError.noElement();
      }
      elementAt(index) {
        throw new core.RangeError.range(index, 0, 0, "index");
      }
      contains(element) { return false; }
      every(test) { return true; }
      any(test) { return false; }
      firstWhere(test, opt$) {
        let orElse = opt$.orElse === undefined ? null : opt$.orElse;
        if (orElse !== null) return orElse();
        throw IterableElementError.noElement();
      }
      lastWhere(test, opt$) {
        let orElse = opt$.orElse === undefined ? null : opt$.orElse;
        if (orElse !== null) return orElse();
        throw IterableElementError.noElement();
      }
      singleWhere(test, opt$) {
        let orElse = opt$.orElse === undefined ? null : opt$.orElse;
        if (orElse !== null) return orElse();
        throw IterableElementError.noElement();
      }
      join(separator) {
        if (separator === undefined) separator = "";
        return ""
      }
      where(test) { return this; }
      map(f) { return new EmptyIterable(); }
      reduce(combine) {
        throw IterableElementError.noElement();
      }
      fold(initialValue, combine) {
        return initialValue;
      }
      skip(count) {
        core.RangeError.checkNotNegative(count, "count");
        return this;
      }
      skipWhile(test) { return this; }
      take(count) {
        core.RangeError.checkNotNegative(count, "count");
        return this;
      }
      takeWhile(test) { return this; }
      toList(opt$) {
        let growable = opt$.growable === undefined ? true : opt$.growable;
        return growable ? new List.from([]) : new core.List(0)
      }
      toSet() { return new core.Set(); }
    }
    return EmptyIterable;
  });
  let EmptyIterable = EmptyIterable$(dynamic);

  let EmptyIterator$ = dart.generic(function(E) {
    class EmptyIterator extends dart.Object {
      EmptyIterator() {
      }
      moveNext() { return false; }
      get current() { return dart.as(null, E); }
    }
    return EmptyIterator;
  });
  let EmptyIterator = EmptyIterator$(dynamic);

  let BidirectionalIterator$ = dart.generic(function(T) {
    class BidirectionalIterator extends dart.Object {
    }
    return BidirectionalIterator;
  });
  let BidirectionalIterator = BidirectionalIterator$(dynamic);

  let IterableMixinWorkaround$ = dart.generic(function(T) {
    class IterableMixinWorkaround extends dart.Object {
      static contains(iterable, element) {
        for (let e of iterable) {
          if (dart.equals(e, element)) return true;
        }
        return false;
      }
      static forEach(iterable, f) {
        for (let e of iterable) {
          f(e);
        }
      }
      static any(iterable, f) {
        for (let e of iterable) {
          if (f(e)) return true;
        }
        return false;
      }
      static every(iterable, f) {
        for (let e of iterable) {
          if (!dart.notNull(f(e))) return false;
        }
        return true;
      }
      static reduce(iterable, combine) {
        let iterator = iterable.iterator;
        if (!dart.notNull(iterator.moveNext())) throw IterableElementError.noElement();
        let value = iterator.current;
        while (iterator.moveNext()) {
          value = combine(value, iterator.current);
        }
        return value;
      }
      static fold(iterable, initialValue, combine) {
        for (let element of iterable) {
          initialValue = combine(initialValue, element);
        }
        return initialValue;
      }
      static removeWhereList(list, test) {
        let retained = new List.from([]);
        let length = list.length;
        for (let i = 0; i < length; i++) {
          let element = list.get(i);
          if (!dart.notNull(test(element))) {
            retained.add(element);
          }
          if (length !== list.length) {
            throw new core.ConcurrentModificationError(list);
          }
        }
        if (retained.length === length) return;
        list.length = retained.length;
        for (let i = 0; i < retained.length; i++) {
          list.set(i, retained.get(i));
        }
      }
      static isEmpty(iterable) {
        return !dart.notNull(iterable.iterator.moveNext());
      }
      static first(iterable) {
        let it = iterable.iterator;
        if (!dart.notNull(it.moveNext())) {
          throw IterableElementError.noElement();
        }
        return it.current;
      }
      static last(iterable) {
        let it = iterable.iterator;
        if (!dart.notNull(it.moveNext())) {
          throw IterableElementError.noElement();
        }
        let result = null;
        do {
          result = it.current;
        }
        while (it.moveNext());
        return result;
      }
      static single(iterable) {
        let it = iterable.iterator;
        if (!dart.notNull(it.moveNext())) throw IterableElementError.noElement();
        let result = it.current;
        if (it.moveNext()) throw IterableElementError.tooMany();
        return result;
      }
      static firstWhere(iterable, test, orElse) {
        for (let element of iterable) {
          if (test(element)) return element;
        }
        if (orElse !== null) return orElse();
        throw IterableElementError.noElement();
      }
      static lastWhere(iterable, test, orElse) {
        let result = null;
        let foundMatching = false;
        for (let element of iterable) {
          if (test(element)) {
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching) return result;
        if (orElse !== null) return orElse();
        throw IterableElementError.noElement();
      }
      static lastWhereList(list, test, orElse) {
        for (let i = list.length - 1; i >= 0; i--) {
          let element = list.get(i);
          if (test(element)) return element;
        }
        if (orElse !== null) return orElse();
        throw IterableElementError.noElement();
      }
      static singleWhere(iterable, test) {
        let result = null;
        let foundMatching = false;
        for (let element of iterable) {
          if (test(element)) {
            if (foundMatching) {
              throw IterableElementError.tooMany();
            }
            result = element;
            foundMatching = true;
          }
        }
        if (foundMatching) return result;
        throw IterableElementError.noElement();
      }
      static elementAt(iterable, index) {
        if (!(typeof index == "number")) throw new core.ArgumentError.notNull("index");
        core.RangeError.checkNotNegative(index, "index");
        let elementIndex = 0;
        for (let element of iterable) {
          if (index === elementIndex) return element;
          elementIndex++;
        }
        throw new core.RangeError.index(index, iterable, "index", null, elementIndex);
      }
      static join(iterable, separator) {
        if (separator === undefined) separator = null;
        let buffer = new core.StringBuffer();
        buffer.writeAll(iterable, separator);
        return buffer.toString();
      }
      static joinList(list, separator) {
        if (separator === undefined) separator = null;
        if (list.isEmpty) return "";
        if (list.length === 1) return `${list.get(0)}`;
        let buffer = new core.StringBuffer();
        if (separator.isEmpty) {
          for (let i = 0; i < list.length; i++) {
            buffer.write(list.get(i));
          }
        } else {
          buffer.write(list.get(0));
          for (let i = 1; i < list.length; i++) {
            buffer.write(separator);
            buffer.write(list.get(i));
          }
        }
        return buffer.toString();
      }
      where(iterable, f) {
        return new WhereIterable(iterable, f);
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
        return new SubListIterable(list, 0, n);
      }
      takeWhile(iterable, test) {
        return new TakeWhileIterable(iterable, test);
      }
      skipList(list, n) {
        return new SubListIterable(list, n, null);
      }
      skipWhile(iterable, test) {
        return new SkipWhileIterable(iterable, test);
      }
      reversedList(list) {
        return new ReversedListIterable(list);
      }
      static sortList(list, compare) {
        if (compare === null) compare = dart.as(core.Comparable.compare, /* Unimplemented type (dynamic, dynamic) → int */);
        Sort.sort(list, compare);
      }
      static shuffleList(list, random) {
        if (random === null) random = new math.Random();
        let length = list.length;
        while (length > 1) {
          let pos = random.nextInt(length);
          length = 1;
          let tmp = list.get(length);
          list.set(length, list.get(pos));
          list.set(pos, tmp);
        }
      }
      static indexOfList(list, element, start) {
        return Lists.indexOf(list, element, start, list.length);
      }
      static lastIndexOfList(list, element, start) {
        if (start === null) start = list.length - 1;
        return Lists.lastIndexOf(list, element, start);
      }
      static _rangeCheck(list, start, end) {
        core.RangeError.checkValidRange(start, end, list.length);
      }
      getRangeList(list, start, end) {
        _rangeCheck(list, start, end);
        return new SubListIterable(list, start, end);
      }
      static setRangeList(list, start, end, from, skipCount) {
        _rangeCheck(list, start, end);
        let length = end - start;
        if (length === 0) return;
        if (skipCount < 0) throw new core.ArgumentError(skipCount);
        let otherList = null;
        let otherStart = null;
        if (dart.is(from, core.List)) {
          otherList = dart.as(from, core.List);
          otherStart = skipCount;
        } else {
          otherList = from.skip(skipCount).toList({growable: false});
          otherStart = 0;
        }
        if (otherStart + length > otherList.length) {
          throw IterableElementError.tooFew();
        }
        Lists.copy(otherList, otherStart, list, start, length);
      }
      static replaceRangeList(list, start, end, iterable) {
        _rangeCheck(list, start, end);
        if (!dart.is(iterable, EfficientLength)) {
          iterable = iterable.toList();
        }
        let removeLength = end - start;
        let insertLength = iterable.length;
        if (removeLength >= insertLength) {
          let delta = removeLength - insertLength;
          let insertEnd = start + insertLength;
          let newEnd = list.length - delta;
          list.setRange(start, insertEnd, iterable);
          if (delta !== 0) {
            list.setRange(insertEnd, newEnd, list, end);
            list.length = newEnd;
          }
        } else {
          let delta = insertLength - removeLength;
          let newLength = list.length + delta;
          let insertEnd = start + insertLength;
          list.length = newLength;
          list.setRange(insertEnd, newLength, list, end);
          list.setRange(start, insertEnd, iterable);
        }
      }
      static fillRangeList(list, start, end, fillValue) {
        _rangeCheck(list, start, end);
        for (let i = start; i < end; i++) {
          list.set(i, fillValue);
        }
      }
      static insertAllList(list, index, iterable) {
        core.RangeError.checkValueInInterval(index, 0, list.length, "index");
        if (!dart.is(iterable, EfficientLength)) {
          iterable = iterable.toList({growable: false});
        }
        let insertionLength = iterable.length;
        list.length = insertionLength;
        list.setRange(index + insertionLength, list.length, list, index);
        for (let element of iterable) {
          list.set(index++, element);
        }
      }
      static setAllList(list, index, iterable) {
        core.RangeError.checkValueInInterval(index, 0, list.length, "index");
        for (let element of iterable) {
          list.set(index++, element);
        }
      }
      asMapList(l) {
        return new ListMapView(l);
      }
      static setContainsAll(set, other) {
        for (let element of other) {
          if (!dart.notNull(set.contains(element))) return false;
        }
        return true;
      }
      static setIntersection(set, other, result) {
        let smaller = null;
        let larger = null;
        if (set.length < other.length) {
          smaller = set;
          larger = other;
        } else {
          smaller = other;
          larger = set;
        }
        for (let element of smaller) {
          if (larger.contains(element)) {
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
    return IterableMixinWorkaround;
  });
  let IterableMixinWorkaround = IterableMixinWorkaround$(dynamic);

  class IterableElementError extends dart.Object {
    static noElement() { return new core.StateError("No element"); }
    static tooMany() { return new core.StateError("Too many elements"); }
    static tooFew() { return new core.StateError("Too few elements"); }
  }

  let FixedLengthListMixin$ = dart.generic(function(E) {
    class FixedLengthListMixin extends dart.Object {
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
  let FixedLengthListMixin = FixedLengthListMixin$(dynamic);

  let UnmodifiableListMixin$ = dart.generic(function(E) {
    class UnmodifiableListMixin extends dart.Object {
      set(index, value) {
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      set length(newLength) {
        throw new core.UnsupportedError("Cannot change the length of an unmodifiable list");
      }
      setAll(at, iterable) {
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      add(value) {
        throw new core.UnsupportedError("Cannot add to an unmodifiable list");
      }
      insert(index, value) {
        throw new core.UnsupportedError("Cannot add to an unmodifiable list");
      }
      insertAll(at, iterable) {
        throw new core.UnsupportedError("Cannot add to an unmodifiable list");
      }
      addAll(iterable) {
        throw new core.UnsupportedError("Cannot add to an unmodifiable list");
      }
      remove(element) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      removeWhere(test) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      retainWhere(test) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      sort(compare) {
        if (compare === undefined) compare = null;
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      shuffle(random) {
        if (random === undefined) random = null;
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      clear() {
        throw new core.UnsupportedError("Cannot clear an unmodifiable list");
      }
      removeAt(index) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      removeLast() {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      setRange(start, end, iterable, skipCount) {
        if (skipCount === undefined) skipCount = 0;
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
      removeRange(start, end) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      replaceRange(start, end, iterable) {
        throw new core.UnsupportedError("Cannot remove from an unmodifiable list");
      }
      fillRange(start, end, fillValue) {
        if (fillValue === undefined) fillValue = null;
        throw new core.UnsupportedError("Cannot modify an unmodifiable list");
      }
    }
    return UnmodifiableListMixin;
  });
  let UnmodifiableListMixin = UnmodifiableListMixin$(dynamic);

  let FixedLengthListBase$ = dart.generic(function(E) {
    class FixedLengthListBase extends dart.mixin(FixedLengthListMixin$(E)) {}

    return FixedLengthListBase;
  });
  let FixedLengthListBase = FixedLengthListBase$(dynamic);
  let UnmodifiableListBase$ = dart.generic(function(E) {
    class UnmodifiableListBase extends dart.mixin(UnmodifiableListMixin$(E)) {}

    return UnmodifiableListBase;
  });
  let UnmodifiableListBase = UnmodifiableListBase$(dynamic);
  class _ListIndicesIterable extends ListIterable$(core.int) {
    _ListIndicesIterable(_backedList) {
      this._backedList = _backedList;
      super.ListIterable();
    }
    get length() { return this._backedList.length; }
    elementAt(index) {
      core.RangeError.checkValidIndex(index, this);
      return index;
    }
  }

  let ListMapView$ = dart.generic(function(E) {
    class ListMapView extends dart.Object {
      ListMapView(_values) {
        this._values = _values;
      }
      get(key) { return dart.as(this.containsKey(key) ? this._values.get(key) : null, E); }
      get length() { return this._values.length; }
      get values() { return new SubListIterable(this._values, 0, null); }
      get keys() { return new _ListIndicesIterable(this._values); }
      get isEmpty() { return this._values.isEmpty; }
      get isNotEmpty() { return this._values.isNotEmpty; }
      containsValue(value) { return this._values.contains(value); }
      containsKey(key) { return dart.notNull(dart.notNull(typeof key == "number") && dart.notNull(key >= 0)) && dart.notNull(key < this.length); }
      forEach(f) {
        let length = this._values.length;
        for (let i = 0; i < length; i++) {
          f(i, this._values.get(i));
          if (length !== this._values.length) {
            throw new core.ConcurrentModificationError(this._values);
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
      toString() { return collection.Maps.mapToString(this); }
    }
    return ListMapView;
  });
  let ListMapView = ListMapView$(dynamic);

  let ReversedListIterable$ = dart.generic(function(E) {
    class ReversedListIterable extends ListIterable$(E) {
      ReversedListIterable(_source) {
        this._source = _source;
        super.ListIterable();
      }
      get length() { return this._source.length; }
      elementAt(index) { return this._source.elementAt(this._source.length - 1 - index); }
    }
    return ReversedListIterable;
  });
  let ReversedListIterable = ReversedListIterable$(dynamic);

  class UnmodifiableListError extends dart.Object {
    static add() { return new core.UnsupportedError("Cannot add to unmodifiable List"); }
    static change() { return new core.UnsupportedError("Cannot change the content of an unmodifiable List"); }
    static length() { return new core.UnsupportedError("Cannot change length of unmodifiable List"); }
    static remove() { return new core.UnsupportedError("Cannot remove from unmodifiable List"); }
  }

  class NonGrowableListError extends dart.Object {
    static add() { return new core.UnsupportedError("Cannot add to non-growable List"); }
    static length() { return new core.UnsupportedError("Cannot change length of non-growable List"); }
    static remove() { return new core.UnsupportedError("Cannot remove from non-growable List"); }
  }

  /* Unimplemented external List makeListFixedLength(List growableList) ; */
  class Lists extends dart.Object {
    static copy(src, srcStart, dst, dstStart, count) {
      if (srcStart < dstStart) {
        for (let i = srcStart + count - 1, j = dstStart + count - 1; i >= srcStart; i--, j--) {
          dst.set(j, src.get(i));
        }
      } else {
        for (let i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
          dst.set(j, src.get(i));
        }
      }
    }
    static areEqual(a, b) {
      if (core.identical(a, b)) return true;
      if (!dart.notNull((dart.is(b, core.List)))) return false;
      let length = a.length;
      if (length !== dart.dload(b, "length")) return false;
      for (let i = 0; i < length; i++) {
        if (!dart.notNull(core.identical(a.get(i), dart.dindex(b, i)))) return false;
      }
      return true;
    }
    static indexOf(a, element, startIndex, endIndex) {
      if (startIndex >= a.length) {
        return -1;
      }
      if (startIndex < 0) {
        startIndex = 0;
      }
      for (let i = startIndex; i < endIndex; i++) {
        if (dart.equals(a.get(i), element)) {
          return i;
        }
      }
      return -1;
    }
    static lastIndexOf(a, element, startIndex) {
      if (startIndex < 0) {
        return -1;
      }
      if (startIndex >= a.length) {
        startIndex = a.length - 1;
      }
      for (let i = startIndex; i >= 0; i--) {
        if (dart.equals(a.get(i), element)) {
          return i;
        }
      }
      return -1;
    }
    static indicesCheck(a, start, end) {
      core.RangeError.checkValidRange(start, end, a.length);
    }
    static rangeCheck(a, start, length) {
      core.RangeError.checkNotNegative(length);
      core.RangeError.checkNotNegative(start);
      if (start + length > a.length) {
        let message = `${start} + ${length} must be in the range [0..${a.length}]`;
        throw new core.RangeError.range(length, 0, a.length - start, "length", message);
      }
    }
  }

  _internal.printToZone = null;
  /* Unimplemented external void printToConsole(String line) ; */
  class Sort extends dart.Object {
    static sort(a, compare) {
      _doSort(a, 0, a.length - 1, compare);
    }
    static sortRange(a, from, to, compare) {
      if (dart.notNull(dart.notNull((from < 0)) || dart.notNull((to > a.length))) || dart.notNull((to < from))) {
        throw "OutOfRange";
      }
      _doSort(a, from, to - 1, compare);
    }
    static _doSort(a, left, right, compare) {
      if ((right - left) <= _INSERTION_SORT_THRESHOLD) {
        _insertionSort(a, left, right, compare);
      } else {
        _dualPivotQuicksort(a, left, right, compare);
      }
    }
    static _insertionSort(a, left, right, compare) {
      for (let i = left + 1; i <= right; i++) {
        let el = a.get(i);
        let j = i;
        while (dart.notNull((j > left)) && dart.notNull((compare(a.get(j - 1), el) > 0))) {
          a.set(j, a.get(j - 1));
          j--;
        }
        a.set(j, el);
      }
    }
    static _dualPivotQuicksort(a, left, right, compare) {
      dart.assert(right - left > _INSERTION_SORT_THRESHOLD);
      let sixth = ((right - left + 1) / 6).truncate();
      let index1 = left + sixth;
      let index5 = right - sixth;
      let index3 = ((left + right) / 2).truncate();
      let index2 = index3 - sixth;
      let index4 = index3 + sixth;
      let el1 = a.get(index1);
      let el2 = a.get(index2);
      let el3 = a.get(index3);
      let el4 = a.get(index4);
      let el5 = a.get(index5);
      if (compare(el1, el2) > 0) {
        let t = el1;
        el1 = el2;
        el2 = t;
      }
      if (compare(el4, el5) > 0) {
        let t = el4;
        el4 = el5;
        el5 = t;
      }
      if (compare(el1, el3) > 0) {
        let t = el1;
        el1 = el3;
        el3 = t;
      }
      if (compare(el2, el3) > 0) {
        let t = el2;
        el2 = el3;
        el3 = t;
      }
      if (compare(el1, el4) > 0) {
        let t = el1;
        el1 = el4;
        el4 = t;
      }
      if (compare(el3, el4) > 0) {
        let t = el3;
        el3 = el4;
        el4 = t;
      }
      if (compare(el2, el5) > 0) {
        let t = el2;
        el2 = el5;
        el5 = t;
      }
      if (compare(el2, el3) > 0) {
        let t = el2;
        el2 = el3;
        el3 = t;
      }
      if (compare(el4, el5) > 0) {
        let t = el4;
        el4 = el5;
        el5 = t;
      }
      let pivot1 = el2;
      let pivot2 = el4;
      a.set(index1, el1);
      a.set(index3, el3);
      a.set(index5, el5);
      a.set(index2, a.get(left));
      a.set(index4, a.get(right));
      let less = left + 1;
      let great = right - 1;
      let pivots_are_equal = (compare(pivot1, pivot2) === 0);
      if (pivots_are_equal) {
        let pivot = pivot1;
        for (let k = less; k <= great; k++) {
          let ak = a.get(k);
          let comp = compare(ak, pivot);
          if (comp === 0) continue;
          if (comp < 0) {
            if (k !== less) {
              a.set(k, a.get(less));
              a.set(less, ak);
            }
            less++;
          } else {
            while (true) {
              comp = compare(a.get(great), pivot);
              if (comp > 0) {
                great--;
                continue;
              } else if (comp < 0) {
                a.set(k, a.get(less));
                a.set(less++, a.get(great));
                a.set(great--, ak);
                break;
              } else {
                a.set(k, a.get(great));
                a.set(great--, ak);
                break;
              }
            }
          }
        }
      } else {
        for (let k = less; k <= great; k++) {
          let ak = a.get(k);
          let comp_pivot1 = compare(ak, pivot1);
          if (comp_pivot1 < 0) {
            if (k !== less) {
              a.set(k, a.get(less));
              a.set(less, ak);
            }
            less++;
          } else {
            let comp_pivot2 = compare(ak, pivot2);
            if (comp_pivot2 > 0) {
              while (true) {
                let comp = compare(a.get(great), pivot2);
                if (comp > 0) {
                  great--;
                  if (great < k) break;
                  continue;
                } else {
                  comp = compare(a.get(great), pivot1);
                  if (comp < 0) {
                    a.set(k, a.get(less));
                    a.set(less++, a.get(great));
                    a.set(great--, ak);
                  } else {
                    a.set(k, a.get(great));
                    a.set(great--, ak);
                  }
                  break;
                }
              }
            }
          }
        }
      }
      a.set(left, a.get(less - 1));
      a.set(less - 1, pivot1);
      a.set(right, a.get(great + 1));
      a.set(great + 1, pivot2);
      _doSort(a, left, less - 2, compare);
      _doSort(a, great + 2, right, compare);
      if (pivots_are_equal) {
        return;
      }
      if (dart.notNull(less < index1) && dart.notNull(great > index5)) {
        while (compare(a.get(less), pivot1) === 0) {
          less++;
        }
        while (compare(a.get(great), pivot2) === 0) {
          great--;
        }
        for (let k = less; k <= great; k++) {
          let ak = a.get(k);
          let comp_pivot1 = compare(ak, pivot1);
          if (comp_pivot1 === 0) {
            if (k !== less) {
              a.set(k, a.get(less));
              a.set(less, ak);
            }
            less++;
          } else {
            let comp_pivot2 = compare(ak, pivot2);
            if (comp_pivot2 === 0) {
              while (true) {
                let comp = compare(a.get(great), pivot2);
                if (comp === 0) {
                  great--;
                  if (great < k) break;
                  continue;
                } else {
                  comp = compare(a.get(great), pivot1);
                  if (comp < 0) {
                    a.set(k, a.get(less));
                    a.set(less++, a.get(great));
                    a.set(great--, ak);
                  } else {
                    a.set(k, a.get(great));
                    a.set(great--, ak);
                  }
                  break;
                }
              }
            }
          }
        }
        _doSort(a, less, great, compare);
      } else {
        _doSort(a, less, great, compare);
      }
    }
  }
  Sort._INSERTION_SORT_THRESHOLD = 32;

  class Symbol extends dart.Object {
    /* Unimplemented external const Symbol(String name); */
    Symbol$unvalidated(_name) {
      this._name = _name;
    }
    Symbol$validated(name) {
      this._name = validatePublicSymbol(name);
    }
    ['=='](other) { return dart.notNull(dart.is(other, Symbol)) && dart.notNull(dart.equals(this._name, dart.dload(other, "_name"))); }
    get hashCode() {
      let arbitraryPrime = 664597;
      return 536870911 & (arbitraryPrime * this._name.hashCode);
    }
    toString() { return `Symbol("${this._name}")`; }
    static getName(symbol) { return symbol._name; }
    static validatePublicSymbol(name) {
      if (dart.notNull(name.isEmpty) || dart.notNull(publicSymbolPattern.hasMatch(name))) return name;
      if (name.startsWith('_')) {
        throw new core.ArgumentError(`"${name}" is a private identifier`);
      }
      throw new core.ArgumentError(`"${name}" is not a valid (qualified) symbol name`);
    }
    static isValidSymbol(name) {
      return (dart.notNull(name.isEmpty) || dart.notNull(symbolPattern.hasMatch(name)));
    }
  }
  dart.defineNamedConstructor(Symbol, "unvalidated");
  dart.defineNamedConstructor(Symbol, "validated");
  Symbol.reservedWordRE = '(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|d(?:efault|o)|' +
      'e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|i[fns]|n(?:ew|ull)|' +
      'ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|r(?:ue|y))|' +
      'v(?:ar|oid)|w(?:hile|ith))';
  Symbol.publicIdentifierRE = '(?!' +
      `${reservedWordRE}` +
      '\\b(?!\\$))[a-zA-Z$][\\w$]*';
  Symbol.identifierRE = '(?!' +
      `${reservedWordRE}` +
      '\\b(?!\\$))[a-zA-Z$_][\\w$]*';
  Symbol.operatorRE = '(?:[\\-+*/%&|^]|\\[\\]=?|==|~/?|<[<=]?|>[>=]?|unary-)';
  dart.defineLazyProperties(Symbol, {
    get publicSymbolPattern() { return new core.RegExp(`^(?:${operatorRE}$|${publicIdentifierRE}(?:=?$|[.](?!$)))+?$`) },
    get symbolPattern() { return new core.RegExp(`^(?:${operatorRE}$|${identifierRE}(?:=?$|[.](?!$)))+?$`) },
  });

  // Exports:
  _internal.POWERS_OF_TEN = POWERS_OF_TEN;
  _internal.EfficientLength = EfficientLength;
  _internal.ListIterable = ListIterable;
  _internal.ListIterable$ = ListIterable$;
  _internal.SubListIterable = SubListIterable;
  _internal.SubListIterable$ = SubListIterable$;
  _internal.ListIterator = ListIterator;
  _internal.ListIterator$ = ListIterator$;
  _internal.MappedIterable = MappedIterable;
  _internal.MappedIterable$ = MappedIterable$;
  _internal.EfficientLengthMappedIterable = EfficientLengthMappedIterable;
  _internal.EfficientLengthMappedIterable$ = EfficientLengthMappedIterable$;
  _internal.MappedIterator = MappedIterator;
  _internal.MappedIterator$ = MappedIterator$;
  _internal.MappedListIterable = MappedListIterable;
  _internal.MappedListIterable$ = MappedListIterable$;
  _internal.WhereIterable = WhereIterable;
  _internal.WhereIterable$ = WhereIterable$;
  _internal.WhereIterator = WhereIterator;
  _internal.WhereIterator$ = WhereIterator$;
  _internal.ExpandIterable = ExpandIterable;
  _internal.ExpandIterable$ = ExpandIterable$;
  _internal.ExpandIterator = ExpandIterator;
  _internal.ExpandIterator$ = ExpandIterator$;
  _internal.TakeIterable = TakeIterable;
  _internal.TakeIterable$ = TakeIterable$;
  _internal.EfficientLengthTakeIterable = EfficientLengthTakeIterable;
  _internal.EfficientLengthTakeIterable$ = EfficientLengthTakeIterable$;
  _internal.TakeIterator = TakeIterator;
  _internal.TakeIterator$ = TakeIterator$;
  _internal.TakeWhileIterable = TakeWhileIterable;
  _internal.TakeWhileIterable$ = TakeWhileIterable$;
  _internal.TakeWhileIterator = TakeWhileIterator;
  _internal.TakeWhileIterator$ = TakeWhileIterator$;
  _internal.SkipIterable = SkipIterable;
  _internal.SkipIterable$ = SkipIterable$;
  _internal.EfficientLengthSkipIterable = EfficientLengthSkipIterable;
  _internal.EfficientLengthSkipIterable$ = EfficientLengthSkipIterable$;
  _internal.SkipIterator = SkipIterator;
  _internal.SkipIterator$ = SkipIterator$;
  _internal.SkipWhileIterable = SkipWhileIterable;
  _internal.SkipWhileIterable$ = SkipWhileIterable$;
  _internal.SkipWhileIterator = SkipWhileIterator;
  _internal.SkipWhileIterator$ = SkipWhileIterator$;
  _internal.EmptyIterable = EmptyIterable;
  _internal.EmptyIterable$ = EmptyIterable$;
  _internal.EmptyIterator = EmptyIterator;
  _internal.EmptyIterator$ = EmptyIterator$;
  _internal.BidirectionalIterator = BidirectionalIterator;
  _internal.BidirectionalIterator$ = BidirectionalIterator$;
  _internal.IterableMixinWorkaround = IterableMixinWorkaround;
  _internal.IterableMixinWorkaround$ = IterableMixinWorkaround$;
  _internal.IterableElementError = IterableElementError;
  _internal.FixedLengthListMixin = FixedLengthListMixin;
  _internal.FixedLengthListMixin$ = FixedLengthListMixin$;
  _internal.UnmodifiableListMixin = UnmodifiableListMixin;
  _internal.UnmodifiableListMixin$ = UnmodifiableListMixin$;
  _internal.FixedLengthListBase$ = FixedLengthListBase$;
  _internal.FixedLengthListBase = FixedLengthListBase;
  _internal.UnmodifiableListBase$ = UnmodifiableListBase$;
  _internal.UnmodifiableListBase = UnmodifiableListBase;
  _internal.ListMapView = ListMapView;
  _internal.ListMapView$ = ListMapView$;
  _internal.ReversedListIterable = ReversedListIterable;
  _internal.ReversedListIterable$ = ReversedListIterable$;
  _internal.UnmodifiableListError = UnmodifiableListError;
  _internal.NonGrowableListError = NonGrowableListError;
  _internal.Lists = Lists;
  _internal.Sort = Sort;
  _internal.Symbol = Symbol;
})(_internal || (_internal = {}));
