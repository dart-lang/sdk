// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F<T> = void Function(T chunk);
typedef A<T> = ({F<T> sendChunk, int whatever});

class M {
  final List<String> content;
  M({required this.content});
}

class G {
  final M _chunk;
  G(this._chunk);

  String get text => _chunk.content.join('');
}

void produceIt(A<M> ctx) {
  int base(A<M> b) {
    b.sendChunk(M(content: ["content-value"]));
    return 1;
  }

  final composeModel = _values.fold(
    base,
    (next, mw) =>
        (c) => mw.f(c, next),
  );
  composeModel((
    whatever: 1,
    sendChunk: (c) => ctx.sendChunk(M(content: c.content)),
  ));
}

void useIt(G g) {
  print(g.text);
}

class Wrapper {
  int f(A<M> c, int Function(A<M>) next) {
    return next(c);
  }
}

List<Wrapper> _values = [Wrapper(), Wrapper(), Wrapper()];

void main() {
  produceIt((
    whatever: 2,
    sendChunk: (c) {
      useIt(G(c));
    },
  ));
}
