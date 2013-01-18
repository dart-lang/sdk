// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection.dev;

typedef T _Transformation<S, T>(S value);

class MappedIterable<S, T> extends Iterable<T> {
  final Iterable<S> _iterable;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _Transformation<S, T> */ _f;

  MappedIterable(this._iterable, T this._f(S element));

  Iterator<T> get iterator => new MappedIterator<S, T>(_iterable.iterator, _f);

  // Length related functions are independent of the mapping.
  int get length => _iterable.length;
  bool get isEmpty => _iterable.isEmpty;
}

class MappedIterator<S, T> extends Iterator<T> {
  T _current;
  final Iterator<S> _iterator;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _Transformation<S, T> */ _f;

  MappedIterator(this._iterator, T this._f(S element));

  bool moveNext() {
    if (_iterator.moveNext()) {
      _current = _f(_iterator.current);
      return true;
    } else {
      _current = null;
      return false;
    }
  }

  T get current => _current;
}

typedef bool _ElementPredicate<E>(E element);

class WhereIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;

  WhereIterable(this._iterable, bool this._f(E element));

  Iterator<E> get iterator => new WhereIterator<E>(_iterable.iterator, _f);
}

class WhereIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;

  WhereIterator(this._iterator, bool this._f(E element));

  bool moveNext() {
    while (_iterator.moveNext()) {
      if (_f(_iterator.current)) {
        return true;
      }
    }
    return false;
  }

  E get current => _iterator.current;
}

class TakeIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  final int _takeCount;

  TakeIterable(this._iterable, this._takeCount) {
    if (_takeCount is! int || _takeCount < 0) {
      throw new ArgumentError(_takeCount);
    }
  }

  Iterator<E> get iterator {
    return new TakeIterator<E>(_iterable.iterator, _takeCount);
  }
}

class TakeIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  int _remaining;

  TakeIterator(this._iterator, this._remaining) {
    assert(_remaining is int && _remaining >= 0);
  }

  bool moveNext() {
    _remaining--;
    if (_remaining >= 0) {
      return _iterator.moveNext();
    }
    _remaining = -1;
    return false;
  }

  E get current {
    if (_remaining < 0) return null;
    return _iterator.current;
  }
}

class TakeWhileIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;

  TakeWhileIterable(this._iterable, bool this._f(E element));

  Iterator<E> get iterator {
    return new TakeWhileIterator<E>(_iterable.iterator, _f);
  }
}

class TakeWhileIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;
  bool _isFinished = false;

  TakeWhileIterator(this._iterator, bool this._f(E element));

  bool moveNext() {
    if (_isFinished) return false;
    if (!_iterator.moveNext() || !_f(_iterator.current)) {
      _isFinished = true;
      return false;
    }
    return true;
  }

  E get current {
    if (_isFinished) return null;
    return _iterator.current;
  }
}

class SkipIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  final int _skipCount;

  SkipIterable(this._iterable, this._skipCount) {
    if (_skipCount is! int || _skipCount < 0) {
      throw new ArgumentError(_skipCount);
    }
  }

  Iterable<E> skip(int n) {
    if (n is! int || n < 0) {
      throw new ArgumentError(n);
    }
    return new SkipIterable<E>(_iterable, _skipCount + n);
  }

  Iterator<E> get iterator {
    return new SkipIterator<E>(_iterable.iterator, _skipCount);
  }
}

class SkipIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  int _skipCount;

  SkipIterator(this._iterator, this._skipCount) {
    assert(_skipCount is int && _skipCount >= 0);
  }

  bool moveNext() {
    for (int i = 0; i < _skipCount; i++) _iterator.moveNext();
    _skipCount = 0;
    return _iterator.moveNext();
  }

  E get current => _iterator.current;
}

class SkipWhileIterable<E> extends Iterable<E> {
  final Iterable<E> _iterable;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;

  SkipWhileIterable(this._iterable, bool this._f(E element));

  Iterator<E> get iterator {
    return new SkipWhileIterator<E>(_iterable.iterator, _f);
  }
}

class SkipWhileIterator<E> extends Iterator<E> {
  final Iterator<E> _iterator;
  // TODO(ahe): Restore type when feature is implemented in dart2js
  // checked mode. http://dartbug.com/7733
  final /* _ElementPredicate */ _f;
  bool _hasSkipped = false;

  SkipWhileIterator(this._iterator, bool this._f(E element));

  bool moveNext() {
    if (!_hasSkipped) {
      _hasSkipped = true;
      while (_iterator.moveNext()) {
        if (!_f(_iterator.current)) return true;
      }
    }
    return _iterator.moveNext();
  }

  E get current => _iterator.current;
}
