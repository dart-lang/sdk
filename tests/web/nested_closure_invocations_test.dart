// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Either<L, R> {
  Either();

  B fold<B>(B ifLeft(L l), B ifRight(R r));

  static Either<L, U> map20<
    L,
    A,
    A2 extends A,
    B,
    B2 extends B,
    C,
    C2 extends C,
    D,
    D2 extends D,
    E,
    E2 extends E,
    F,
    F2 extends F,
    G,
    G2 extends G,
    H,
    H2 extends H,
    I,
    I2 extends I,
    J,
    J2 extends J,
    K,
    K2 extends K,
    LL,
    LL2 extends LL,
    M,
    M2 extends M,
    N,
    N2 extends N,
    O,
    O2 extends O,
    P,
    P2 extends P,
    Q,
    Q2 extends Q,
    R,
    R2 extends R,
    S,
    S2 extends S,
    T,
    T2 extends T,
    U
  >(
    Either<L, A2> fa,
    Either<L, B2> fb,
    Either<L, C2> fc,
    Either<L, D2> fd,
    Either<L, E2> fe,
    Either<L, F2> ff,
    Either<L, G2> fg,
    Either<L, H2> fh,
    Either<L, I2> fi,
    Either<L, J2> fj,
    Either<L, K2> fk,
    Either<L, LL> fl,
    Either<L, M> fm,
    Either<L, N> fn,
    Either<L, O> fo,
    Either<L, P> fp,
    Either<L, Q> fq,
    Either<L, R> fr,
    Either<L, S> fs,
    Either<L, T> ft,
    U fun(
      A a,
      B b,
      C c,
      D d,
      E e,
      F f,
      G g,
      H h,
      I i,
      J j,
      K k,
      LL l,
      M m,
      N n,
      O o,
      P p,
      Q q,
      R r,
      S s,
      T t,
    ),
  ) => fa.fold(
    left,
    (a) => fb.fold(
      left,
      (b) => fc.fold(
        left,
        (c) => fd.fold(
          left,
          (d) => fe.fold(
            left,
            (e) => ff.fold(
              left,
              (f) => fg.fold(
                left,
                (g) => fh.fold(
                  left,
                  (h) => fi.fold(
                    left,
                    (i) => fj.fold(
                      left,
                      (j) => fk.fold(
                        left,
                        (k) => fl.fold(
                          left,
                          (l) => fm.fold(
                            left,
                            (m) => fn.fold(
                              left,
                              (n) => fo.fold(
                                left,
                                (o) => fp.fold(
                                  left,
                                  (p) => fq.fold(
                                    left,
                                    (q) => fr.fold(
                                      left,
                                      (r) => fs.fold(
                                        left,
                                        (s) => ft.fold(
                                          left,
                                          (t) => right(
                                            fun(
                                              a,
                                              b,
                                              c,
                                              d,
                                              e,
                                              f,
                                              g,
                                              h,
                                              i,
                                              j,
                                              k,
                                              l,
                                              m,
                                              n,
                                              o,
                                              p,
                                              q,
                                              r,
                                              s,
                                              t,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Either<L, R> left<L, R>(L l) => new Left(l);
Either<L, R> right<L, R>(R r) => new Right(r);

class Left<L, R> extends Either<L, R> {
  final L _l;

  B fold<B>(B ifLeft(L l), B ifRight(R r)) => ifLeft(_l);

  Left(this._l);
}

class Right<L, R> extends Either<L, R> {
  final R _r;

  B fold<B>(B ifLeft(L l), B ifRight(R r)) => ifRight(_r);

  Right(this._r);
}

void main() {
  Either.map20(
    left(0),
    left(1),
    left(2),
    left(3),
    left(4),
    left(5),
    left(6),
    left(7),
    left(8),
    left(9),
    left(10),
    left(11),
    left(12),
    left(13),
    left(14),
    left(15),
    left(16),
    left(17),
    left(18),
    left(19),
    (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) => 20,
  );
}
