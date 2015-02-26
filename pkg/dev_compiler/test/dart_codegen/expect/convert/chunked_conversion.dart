part of dart.convert;
 typedef void _ChunkedConversionCallback<T>(T accumulated);
 abstract class ChunkedConversionSink<T> implements Sink<T> {ChunkedConversionSink();
 factory ChunkedConversionSink.withCallback(void callback(List<T> accumulated)) = _SimpleCallbackSink;
 void add(T chunk);
 void close();
}
 class _SimpleCallbackSink<T> extends ChunkedConversionSink<T> {final _ChunkedConversionCallback<List<T>> _callback;
 final List<T> _accumulated = <T> [];
 _SimpleCallbackSink(this._callback);
 void add(T chunk) {
_accumulated.add(chunk);
}
 void close() {
_callback(_accumulated);
}
}
 class _EventSinkAdapter<T> implements ChunkedConversionSink<T> {final EventSink<T> _sink;
 _EventSinkAdapter(this._sink);
 void add(T data) => _sink.add(data);
 void close() => _sink.close();
}
 class _ConverterStreamEventSink<S, T> implements EventSink<S> {final EventSink<T> _eventSink;
 ChunkedConversionSink _chunkedSink;
 _ConverterStreamEventSink(Converter converter, EventSink<T> sink) : this._eventSink = sink, _chunkedSink = converter.startChunkedConversion(sink);
 void add(S o) => _chunkedSink.add(o);
 void addError(Object error, [StackTrace stackTrace]) {
_eventSink.addError(error, stackTrace);
}
 void close() => _chunkedSink.close();
}
