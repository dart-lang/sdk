// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Alias<T extends num> = Class<T>;

class Class<T> {
  Class();
  factory Class.fact() => Class<T>();
  factory Class.redirect() = Class<T>;
}

const a = Class.new;
const b = Class.fact;
const c = Class.redirect;
const d = Alias.new;
const e = Alias.fact;
const f = Alias.redirect;

main() {
  print('$a$b$c$d$e$f');
}
