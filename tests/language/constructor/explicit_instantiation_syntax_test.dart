// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



import 'dart:core' hide dynamic;
import 'dart:core' as core show dynamic;

extension E<X> on X {
  X operator <(_) => this;
  X operator >(_) => this;
  X operator <=(_) => this;
  X operator >=(_) => this;
  // X operator ==(_) => this; Member of object, can't be extension method.
  X operator -(_) => this;
  X operator +(_) => this;
  X operator /(_) => this;
  X operator ~/(_) => this;
  X operator *(_) => this;
  X operator %(_) => this;
  X operator |(_) => this;
  X operator ^(_) => this;
  X operator &(_) => this;
  X operator <<(_) => this;
  X operator >>>(_) => this;
  X operator >>(_) => this;

  X operator -() => this;
  X operator ~() => this;
  X operator [](_) => this;
  operator []=(_1, _2) => this;
}

class C<X, Y> {
  C();
  C.named();
}

void f(_1, _2) {}
void g(_) {}
void h(_1, [_2]) {}

int i = 0;
bool boolVar = true;

class Test {
  var x;

  void test() {
    // Test the behavior of the parser on `id<id,id> ...` where the `...`
    // stands for each of the tokens in Dart. In each case, additional tokens
    // are added at the end, if this can make the construct parseable.
    // `f` is used to force the parse to be two expressions; `g` is used to
    // force the parse to be one expression; `h` is used to allow both (in
    // cases where both possibilities must be a dead end).

    f(C<int, int> !true);

    g(C<int, int> != 1);

    f(C<int, int> """ """);

    f(C<int, int> "");

    // `#!` is not a symbol, there's no way to make this work.
    h(C<int, int> #!); //# 1: syntax error

    f(C<int, int> #foo);

    h(C<int, int> % 1); //# 2: syntax error
    g((C<int, int>) % 1);

    h(C<int, int> %= 1); //# 3: syntax error

    h(true + C<int, int> && true); //# 4: syntax error
    g(true + (C<int, int>) && true);

    h(C<int, int> & 1); //# 5: syntax error
    g((C<int, int>) & 1);

    h(C<int, int> &= 1); //# 6: syntax error

    g(C<int, int>());

    g(C<int, int>);

    h(C<int, int> * 1); //# 7: syntax error
    g((C<int, int>) * 1);

    h(C<int, int> */ 1); //# 8: syntax error

    h(C<int, int> *= 1); //# 9: syntax error

    h(C<int, int> + 1); //# 10: syntax error
    g((C<int, int>) + 1);

    f(C<int, int> ++ i);

    h(C<int, int> += 1); //# 11: syntax error

    f(C<int, int> , 1);

    f(C<int, int> - 1);

    f(C<int, int> -- i);

    h(C<int, int> -= 1); //# 12: syntax error

    g(C<int, int> . named());

    h(C<int, int> .. toString()); //# 13: syntax error
    g((C<int, int>) .. toString());

    h(C<int, int> ...); //# 14: syntax error

    h(C<int, int> ...?); //# 15: syntax error

    h(C<int, int> / 1); //# 16: syntax error
    g((C<int, int>) / 1);

    g(C<int, int> /**/); //# 17: ok
    f(C<int, int> /**/ - 1);

    g(C<int, int> //
        );
    f(C<int, int> //
        -
        1);

    h(C<int, int> /= 1); //# 18: syntax error

    g({C<int, int> : 1});

    C<int, int> ; //# 19: ok

    h(C<int, int> < 1); //# 20: syntax error
    g((C<int, int>) < 1);

    h(C<int, int> << 1); //# 21: syntax error
    g((C<int, int>) << 1);

    h(C<int, int> <<= 1); //# 22: syntax error

    h(C<int, int> <= 1); //# 23: syntax error
    g((C<int, int>) <= 1);

    h(C<int, int> = 1); //# 24: syntax error

    g(C<int, int> == 1);

    h(C<int, int> =>); //# 25: syntax error

    // The operator `>>` is a single token in the grammar.
    h(C<int, int> > 1); //# 26: syntax error
    h((C<int, int>) > 1);

    h(true + C<int, int> ? 1 : 1); //# 27: syntax error
    g(true + (C<int, int>) ? 1 : 1);

    g(C<int, int> ?. toString()); //# 28: syntax error
    g((boolVar ? null : C<int, int>) ?. toString());

    h(C<int, int> ?.. toString()); //# 29: syntax error

    h(C<int, int> ?? 1); //# 30: syntax error
    g(null + (C<int, int>) ?? 1);

    h(C<int, int> ??= 1); //# 31: syntax error

    h(C<int, int> @deprecated 1); //# 32: syntax error

    f(C<int, int> [ 1 ]);

    f(C<int, int> '');

    f(C<int, int> ''' ''');

    g([ C<int, int> ]);

    h(C<int, int> ^ 1); //# 33: syntax error
    g((C<int, int>) ^ 1);

    h(C<int, int> ^= 1); //# 34: syntax error

    h(C<int, int> | 1); //# 35: syntax error
    g((C<int, int>) | 1);

    h(C<int, int> |= 1); //# 36: syntax error

    h(true + C<int, int> || true); //# 37: syntax error
    g(true + (C<int, int>) || true);

    f(C<int, int> ~ 1);

    h(C<int, int> ~/ 1); //# 38: syntax error
    g((C<int, int>) ~/ 1);

    h(C<int, int> ~/= 1); //# 39: syntax error

    f(C<int, int> {});
    g({ C<int, int> });

    // Keywords with no special status.
    {
      var async, hide, of, on, show, sync;
      f(C<int, int> async);
      f(C<int, int> hide);
      f(C<int, int> of);
      f(C<int, int> on);
      f(C<int, int> show);
      f(C<int, int> sync);
    }

    // Contextual reserved words (no special status here).
    {
      var await, yield;
      f(C<int, int> await);
      f(C<int, int> yield);
    }

    // Built-in identifiers.
    {
      var abstract, as, covariant, deferred, dynamic, export;
      var extension, external, factory, Function, get, implements;
      var import, interface, late, library, mixin, operator, part;
      var required, set, static, typedef;
      f(C<int, int> abstract);
      f(C<int, int> as);
      g((C<int, int>) as core.dynamic);
      f(C<int, int> covariant);
      f(C<int, int> deferred);
      f(C<int, int> dynamic);
      f(C<int, int> export);
      f(C<int, int> extension);
      f(C<int, int> external);
      f(C<int, int> factory);
      f(C<int, int> Function);
      f(C<int, int> get);
      f(C<int, int> implements);
      f(C<int, int> import);
      f(C<int, int> interface);
      f(C<int, int> late);
      f(C<int, int> library);
      f(C<int, int> mixin);
      f(C<int, int> operator);
      f(C<int, int> part);
      f(C<int, int> required);
      f(C<int, int> set);
      f(C<int, int> static);
      f(C<int, int> typedef);
    }

    // Reserved words.
    h(C<int, int> assert(true)); //# 40: syntax error
    switch (1) {
      case 0: C<int, int> break; //# 41: syntax error
      C<int, int> case 1: break; //# 42: syntax error
    }
    h(C<int, int> catch); //# 43: syntax error
    h(C<int, int> class D {}); //# 44: syntax error
    f(C<int, int> const []);
    while (++i < 10) {
      C<int, int> continue; //# 45: syntax error
    }
    h(C<int, int> default); //# 46: syntax error
    h(C<int, int> do); //# 47: syntax error
    h(C<int, int> else); //# 48: syntax error
    h(C<int, int> enum {}); //# 49: syntax error
    h(C<int, int> extends C); //# 50: syntax error
    f(C<int, int> false);
    h(C<int, int> final); //# 51: syntax error
    h(C<int, int> finally); //# 52: syntax error
    h(C<int, int> for); //# 53: syntax error
    h(C<int, int> if); //# 54: syntax error
    h(C<int, int> in); //# 55: syntax error
    h(C<int, int> is Object); //# 56: syntax error
    g((C<int, int>) is Object);
    f(C<int, int> new C());
    f(C<int, int> null);
    h(C<int, int> rethrow); //# 57: syntax error
    h(C<int, int> return); //# 58: syntax error
    f(C<int, int> super.toString);
    h(C<int, int> switch); //# 59: syntax error
    f(C<int, int> this.x);

    // Right operand of `>` is a `<bitwiseOrExpression>`, and `throw 0` isn't.
    h(C<int, int> throw 0); //# 60: syntax error

    f(C<int, int> true);
    h(C<int, int> try); //# 61: syntax error
    h(C<int, int> var); //# 62: syntax error
    h(C<int, int> void); //# 63: syntax error
    h(C<int, int> while); //# 64: syntax error
    h(C<int, int> with); //# 65: syntax error
  }
}

void main() {
  Test().test();
}
