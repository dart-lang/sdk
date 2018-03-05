// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

// Casting wrappers for asynchronous classes.

class CastStream<S, T> extends Stream<T> {
  final Stream<S> _source;
  CastStream(this._source);
  bool get isBroadcast => _source.isBroadcast;

  StreamSubscription<T> listen(void onData(T data),
      {Function onError, void onDone(), bool cancelOnError}) {
    return new CastStreamSubscription<S, T>(_source.listen(null,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError))
      ..onData(onData);
  }

  Stream<R> cast<R>() {
    Stream<Object> self = this;
    return self is Stream<R> ? self : this.retype<R>();
  }

  Stream<R> retype<R>() => new CastStream<S, R>(_source);
}

class CastStreamSubscription<S, T> implements StreamSubscription<T> {
  final StreamSubscription<S> _source;

  CastStreamSubscription(this._source);

  Future cancel() => _source.cancel();

  void onData(void handleData(T data)) {
    _source.onData((S data) => handleData(data as T));
  }

  void onError(Function handleError) {
    _source.onError(handleError);
  }

  void onDone(void handleDone()) {
    _source.onDone(handleDone);
  }

  void pause([Future resumeSignal]) {
    _source.pause(resumeSignal);
  }

  void resume() {
    _source.resume();
  }

  bool get isPaused => _source.isPaused;

  Future<E> asFuture<E>([E futureValue]) => _source.asFuture<E>(futureValue);
}

class CastStreamTransformer<SS, ST, TS, TT>
    extends StreamTransformerBase<TS, TT> {
  final StreamTransformer<SS, ST> _source;
  CastStreamTransformer(this._source);

  // cast is inherited from StreamTransformerBase.

  StreamTransformer<RS, RT> retype<RS, RT>() =>
      new CastStreamTransformer<SS, ST, RS, RT>(_source);

  Stream<TT> bind(Stream<TS> stream) =>
      _source.bind(stream.cast<SS>()).cast<TT>();
}

class CastConverter<SS, ST, TS, TT> extends Converter<TS, TT> {
  final Converter<SS, ST> _source;
  CastConverter(this._source);

  TT convert(TS input) => _source.convert(input as SS) as TT;

  // cast is inherited from Converter.

  Stream<TT> bind(Stream<TS> stream) =>
      _source.bind(stream.cast<SS>()).cast<TT>();

  Converter<RS, RT> retype<RS, RT>() =>
      new CastConverter<SS, ST, RS, RT>(_source);
}
