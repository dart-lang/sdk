// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'typedef_from_lib.dart';

part 'typedef_from_part.dart';

main() {
  var aNew = A.new;
  var aNamed = A.named;
  var aFact = A.fact;
  var aRedirect = A.redirect;

  aNew('', '');
  aNew(0, '');
  aNamed('');
  aNamed(0, '');
  aNamed('', '', 87);
  aFact(0);
  aFact('', b: '');
  aFact(0, c: 87);
  aFact('', c: 87, b: '');
  aRedirect('');
  aRedirect(0);

  var aNewInst = aNew<bool>;
  var aNamedInst = aNamed<bool>;
  var aFactInst = aFact<bool>;
  var aRedirectInst = aRedirect<bool>;

  aNewInst(true, '');
  aNamedInst(false);
  aNamedInst(true, '');
  aNamedInst(false, '', 87);
  aFactInst(true);
  aFactInst(false, b: '');
  aFactInst(true, c: 87);
  aFactInst(false, c: 87, b: '');
  aRedirectInst(true);
  
  var bNew = B.new;
  var bNamed = B.named;
  var bFact = B.fact;
  var bRedirect = B.redirect;

  bNew('', 0);
  bNew(0, 0);
  bNamed('');
  bNamed(0, 0);
  bNamed('', 0, 87);
  bFact(0);
  bFact('', b: 0);
  bFact(0, c: 87);
  bFact('', c: 87, b: 0);
  bRedirect('');
  bRedirect(0);

  var bNewInst = bNew<bool>;
  var bNamedInst = bNamed<bool>;
  var bFactInst = bFact<bool>;
  var bRedirectInst = bRedirect<bool>;

  bNewInst(true, 0);
  bNamedInst(false);
  bNamedInst(true, 0);
  bNamedInst(false, 0, 87);
  bFactInst(true);
  bFactInst(false, b: 0);
  bFactInst(true, c: 87);
  bFactInst(false, c: 87, b: 0);
  bRedirectInst(true);
}

class Class<S, T> {
  Class(S a, T b);
  Class.named(S a, [T? b, int c = 42]);
  factory Class.fact(S a, {T? b, int c: 42}) => Class.named(a, b, c);
  factory Class.redirect(S a) = Class.named;
}
