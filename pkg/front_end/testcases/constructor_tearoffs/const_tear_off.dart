// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  A();
  factory A.fact() => new A();
  factory A.redirect() = A;
}

typedef B<T> = A<T>;
typedef C<T> = A<int>;

const a = A.new;
const b = A<int>.new;
const c = A.fact;
const d = A<int>.fact;
const e = A.redirect;
const f = A<int>.redirect;
const g = B.new;
const h = B<int>.new;
const i = B.fact;
const j = B<int>.fact;
const k = B.redirect;
const l = B<int>.redirect;
const m = C.new;
const n = C<int>.new;
const o = C.fact;
const p = C<int>.fact;
const q = C.redirect;
const r = C<int>.redirect;

test() {
  var a = A.new;
  var b = A<int>.new;
  var c = A.fact;
  var d = A<int>.fact;
  var e = A.redirect;
  var f = A<int>.redirect;
  var g = B.new;
  var h = B<int>.new;
  var i = B.fact;
  var j = B<int>.fact;
  var k = B.redirect;
  var l = B<int>.redirect;
  var m = C.new;
  var n = C<int>.new;
  var o = C.fact;
  var p = C<int>.fact;
  var q = C.redirect;
  var r = C<int>.redirect;
}

main() {}