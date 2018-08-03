// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test carefully reproduces subtle situation when TFA fails to converge
// unless result types are saturated.
// * There is a loop in dependencies (or even multiple loops).
// * There is a recursive invocation which may result in a type approximation.
// * Invalidation of results of certain invocations cause types to bounce
//   between approximated and non-approximated results, causing more
//   self-induced invalidations.
//

class StreamSubscription {}

class _BufferingStreamSubscription extends StreamSubscription {}

class _BroadcastSubscription extends StreamSubscription {}

abstract class Stream {
  StreamSubscription foobar(void onData(event), {Function onError});
}

abstract class _StreamImpl extends Stream {
  StreamSubscription foobar(void onData(data), {Function onError}) {
    return _createSubscription();
  }

  StreamSubscription _createSubscription() {
    return new _BufferingStreamSubscription();
  }
}

class _ControllerStream extends _StreamImpl {
  StreamSubscription _createSubscription() {
    return new _BroadcastSubscription();
  }
}

class _GeneratedStreamImpl extends _StreamImpl {}

class StreamView extends Stream {
  final Stream _stream;

  StreamView(Stream stream) : _stream = stream;

  StreamSubscription foobar(void onData(value), {Function onError}) {
    return _stream.foobar(onData, onError: onError);
  }
}

class ByteStream extends StreamView {
  ByteStream(Stream stream) : super(stream);

  super_foobar1(void onData(value)) {
    super.foobar(onData);
  }

  super_foobar2(void onData(value)) {
    super.foobar(onData);
  }

  super_foobar3({void onData(value), Function onError}) {
    super.foobar(onData, onError: onError);
  }

  Stream get super_stream => super._stream;
}

class _HandleErrorStream extends Stream {
  StreamSubscription foobar(void onData(event), {Function onError}) {
    return new _BufferingStreamSubscription();
  }
}

void round0() {
  new ByteStream(new ByteStream(new _GeneratedStreamImpl()));
}

void round1({void onData(value)}) {
  var x = new ByteStream(new ByteStream(new _GeneratedStreamImpl()));
  x.super_foobar1(onData);
}

void round2({void onData(value), Function onError}) {
  new _ControllerStream();
  Stream x = new _GeneratedStreamImpl();
  x = new ByteStream(x);
  x.foobar(onData, onError: onError);
}

void round3({void onData(value), Function onError}) {
  Stream x = new _GeneratedStreamImpl();
  x = new ByteStream(x);
  x = new _ControllerStream();
  x.foobar(onData, onError: onError);
}

void round4({void onData(value)}) {
  var x = new ByteStream(new _ControllerStream());
  var y = x.super_stream;
  var z = x._stream;
  if (y == z) {
    x.super_foobar2(onData);
  }
}

void round5() {
  var x = new ByteStream(new _GeneratedStreamImpl());
  new _HandleErrorStream();
  x.super_foobar3();
}

main(List<String> args) {
  new _GeneratedStreamImpl();
  round0();
  round1();
  round2();
  round3();
  round4();
  round5();
}
