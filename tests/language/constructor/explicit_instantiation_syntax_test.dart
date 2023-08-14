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

void twoArgs(_1, _2) {}
void oneArg(_) {}
void anyArgs(_1, [_2]) {}

int i = 0;
bool boolVar = true;

class Test {
  var x;

  void test() {
    // Test the behavior of the parser on `id<id,id> ...` where the `...`
    // stands for each of the tokens in Dart. In each case, additional tokens
    // are added at the end, if this can make the construct parseable.
    // `twoArgs` is used to force the parse to be two expressions; `oneArg`
    // is used to force the parse to be one expression; `anyArgs` is used to
    // allow both (in cases where both possibilities must be a dead end).

    // In each case where the resulting code is a syntax error, there are
    // two cases: (1) the given token sequence can be parsed with
    // `C<int, int>` as a `postfixExpression` if we add parentheses around
    // it; (2) it can not. In case (1) there is an extra case after each
    // 'syntax error', adding those parentheses and checking that it is now
    // syntactically correct. In case (2) the result is still a syntax error,
    // so the parenthesized variant is omitted. The first example of (1)
    // below is the case with `%`; the first (2) is the one with `#!`.

    // Disambiguation is based on the notion of `<stopToken>` and
    // `<continuationToken>`: `C<int, int>` can be parsed as one term only if
    // it is followed by a stop token or a continuation token.
    //
    //   <continuationToken> ::= `(' | `.' | `==' | `!='
    //   <stopToken> ::= `)' | `]' | `}' | `;' | `:' | `,'

    twoArgs(C<int, int> !true);

    oneArg(C<int, int> != 1);

    twoArgs(C<int, int> """ """);

    twoArgs(C<int, int> "");

    // `#!` is not a symbol, there's no way to make this work.
    anyArgs(C<int, int> #!); //# 1: syntax error

    twoArgs(C<int, int> #foo);

    anyArgs(C<int, int> % 1); //# 2: syntax error
    oneArg((C<int, int>) % 1);

    anyArgs(C<int, int> %= 1); //# 3: syntax error

    anyArgs(true + C<int, int> && true); //# 4: syntax error
    oneArg(true + (C<int, int>) && true);

    anyArgs(C<int, int> & 1); //# 5: syntax error
    oneArg((C<int, int>) & 1);

    anyArgs(C<int, int> &= 1); //# 6: syntax error

    oneArg(C<int, int>());

    oneArg(C<int, int>);

    anyArgs(C<int, int> * 1); //# 7: syntax error
    oneArg((C<int, int>) * 1);

    anyArgs(C<int, int> */ 1); //# 8: syntax error

    anyArgs(C<int, int> *= 1); //# 9: syntax error

    anyArgs(C<int, int> + 1); //# 10: syntax error
    oneArg((C<int, int>) + 1);

    twoArgs(C<int, int> ++ i);

    anyArgs(C<int, int> += 1); //# 11: syntax error

    // Special case: This is two actual arguments due to the last `,`.
    twoArgs(C<int, int> , 1);

    twoArgs(C<int, int> - 1);

    twoArgs(C<int, int> -- i);

    anyArgs(C<int, int> -= 1); //# 12: syntax error

    oneArg(C<int, int> . named());

    anyArgs(C<int, int> .. toString()); //# 13: syntax error
    oneArg((C<int, int>) .. toString());

    anyArgs(C<int, int> ...); //# 14: syntax error

    anyArgs(C<int, int> ...?); //# 15: syntax error

    anyArgs(C<int, int> / 1); //# 16: syntax error
    oneArg((C<int, int>) / 1);

    oneArg(C<int, int> /**/); //# 17: ok
    twoArgs(C<int, int> /**/ - 1);

    oneArg(C<int, int> //
        );
    twoArgs(C<int, int> //
        -
        1);

    anyArgs(C<int, int> /= 1); //# 18: syntax error

    oneArg({C<int, int> : 1});

    C<int, int> ; //# 19: ok

    anyArgs(C<int, int> < 1); //# 20: syntax error
    oneArg((C<int, int>) < 1);

    anyArgs(C<int, int> << 1); //# 21: syntax error
    oneArg((C<int, int>) << 1);

    anyArgs(C<int, int> <<= 1); //# 22: syntax error

    anyArgs(C<int, int> <= 1); //# 23: syntax error
    oneArg((C<int, int>) <= 1);

    anyArgs(C<int, int> = 1); //# 24: syntax error

    oneArg(C<int, int> == 1);

    anyArgs(C<int, int> =>); //# 25: syntax error

    // The operator `>>` is a single token in the grammar.
    anyArgs(C<int, int> > 1); //# 26: syntax error
    oneArg((C<int, int>) > 1);

    anyArgs(true + C<int, int> ? 1 : 1); //# 27: syntax error
    oneArg(true + (C<int, int>) ? 1 : 1);

    anyArgs(C<int, int> ?. toString()); //# 28: syntax error
    oneArg((boolVar ? null : C<int, int>) ?. toString());

    anyArgs(C<int, int> ?.. toString()); //# 29: syntax error

    anyArgs(C<int, int> ?? 1); //# 30: syntax error

    anyArgs(C<int, int> ??= 1); //# 31: syntax error

    anyArgs(C<int, int> @deprecated 1); //# 32: syntax error

    twoArgs(C<int, int> [ 1 ]);

    twoArgs(C<int, int> '');

    twoArgs(C<int, int> ''' ''');

    oneArg([ C<int, int> ]);

    anyArgs(C<int, int> ^ 1); //# 33: syntax error
    oneArg((C<int, int>) ^ 1);

    anyArgs(C<int, int> ^= 1); //# 34: syntax error

    anyArgs(C<int, int> | 1); //# 35: syntax error
    oneArg((C<int, int>) | 1);

    anyArgs(C<int, int> |= 1); //# 36: syntax error

    anyArgs(true + C<int, int> || true); //# 37: syntax error
    oneArg(true + (C<int, int>) || true);

    twoArgs(C<int, int> ~ 1);

    anyArgs(C<int, int> ~/ 1); //# 38: syntax error
    oneArg((C<int, int>) ~/ 1);

    anyArgs(C<int, int> ~/= 1); //# 39: syntax error

    twoArgs(C<int, int> {});
    oneArg({ C<int, int> });

    // Keywords with no special status.
    {
      var async, hide, of, on, show, sync;
      twoArgs(C<int, int> async);
      twoArgs(C<int, int> hide);
      twoArgs(C<int, int> of);
      twoArgs(C<int, int> on);
      twoArgs(C<int, int> show);
      twoArgs(C<int, int> sync);
    }

    // Contextual reserved words (no special status here).
    {
      var await, yield;
      twoArgs(C<int, int> await);
      twoArgs(C<int, int> yield);
    }

    // Built-in identifiers.
    {
      var abstract, as, covariant, deferred, dynamic, export;
      var extension, external, factory, Function, get, implements;
      var import, interface, late, library, mixin, operator, part;
      var required, set, static, typedef;
      twoArgs(C<int, int> abstract);
      twoArgs(C<int, int> as);
      oneArg((C<int, int>) as core.dynamic);
      twoArgs(C<int, int> covariant);
      twoArgs(C<int, int> deferred);
      twoArgs(C<int, int> dynamic);
      twoArgs(C<int, int> export);
      twoArgs(C<int, int> extension);
      twoArgs(C<int, int> external);
      twoArgs(C<int, int> factory);
      twoArgs(C<int, int> Function);
      twoArgs(C<int, int> get);
      twoArgs(C<int, int> implements);
      twoArgs(C<int, int> import);
      twoArgs(C<int, int> interface);
      twoArgs(C<int, int> late);
      twoArgs(C<int, int> library);
      twoArgs(C<int, int> mixin);
      twoArgs(C<int, int> operator);
      twoArgs(C<int, int> part);
      twoArgs(C<int, int> required);
      twoArgs(C<int, int> set);
      twoArgs(C<int, int> static);
      twoArgs(C<int, int> typedef);
    }

    // Reserved words.
    anyArgs(C<int, int> assert(true)); //# 40: syntax error
    switch (1) {
      case 0: C<int, int> break; //# 41: syntax error
      C<int, int> case 1: break; //# 42: syntax error
    }
    anyArgs(C<int, int> catch); //# 43: syntax error
    anyArgs(C<int, int> class D {}); //# 44: syntax error
    twoArgs(C<int, int> const []);
    while (++i < 10) {
      C<int, int> continue; //# 45: syntax error
    }
    anyArgs(C<int, int> default); //# 46: syntax error
    anyArgs(C<int, int> do); //# 47: syntax error
    anyArgs(C<int, int> else); //# 48: syntax error
    anyArgs(C<int, int> enum {}); //# 49: syntax error
    anyArgs(C<int, int> extends C); //# 50: syntax error
    twoArgs(C<int, int> false);
    anyArgs(C<int, int> final); //# 51: syntax error
    anyArgs(C<int, int> finally); //# 52: syntax error
    anyArgs(C<int, int> for); //# 53: syntax error
    anyArgs(C<int, int> if); //# 54: syntax error
    anyArgs(C<int, int> in); //# 55: syntax error
    anyArgs(C<int, int> is Object); //# 56: syntax error
    oneArg((C<int, int>) is Object);
    twoArgs(C<int, int> new C());
    twoArgs(C<int, int> null);
    anyArgs(C<int, int> rethrow); //# 57: syntax error
    anyArgs(C<int, int> return); //# 58: syntax error
    twoArgs(C<int, int> super.toString);
    anyArgs(C<int, int> switch); //# 59: syntax error
    twoArgs(C<int, int> this.x);

    // Right operand of `>` is a `<bitwiseOrExpression>`, and `throw 0` isn't.
    anyArgs(C<int, int> throw 0); //# 60: syntax error

    twoArgs(C<int, int> true);
    anyArgs(C<int, int> try); //# 61: syntax error
    anyArgs(C<int, int> var); //# 62: syntax error
    anyArgs(C<int, int> void); //# 63: syntax error
    anyArgs(C<int, int> while); //# 64: syntax error
    anyArgs(C<int, int> with); //# 65: syntax error
  }
}

void main() {
  Test().test();
}
