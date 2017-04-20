// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

typedef void Func();

class C<T> {
  test() {
    // Note: we cannot write a type literal with generic type arguments. For
    // example, `C<String>` isn't a valid expression.
    C;
    use(C);
    dynamic;
    use(dynamic);
    T;
    use(T);
    Func;
    use(Func);

    C();
    use(C());
    dynamic();
    use(dynamic());
    T();
    use(T());
    Func();
    use(Func());

    C = 42;
    use(C = 42);
    dynamic = 42;
    use(dynamic = 42);
    T = 42;
    use(T = 42);
    Func = 42;
    use(Func = 42);

    C++;
    use(C++);
    dynamic++;
    use(dynamic++);
    T++;
    use(T++);
    Func++;
    use(Func++);

    ++C;
    use(++C);
    ++dynamic;
    use(++dynamic);
    ++T;
    use(++T);
    ++Func;
    use(++Func);

    C--;
    use(C--);
    dynamic--;
    use(dynamic--);
    T--;
    use(T--);
    Func--;
    use(Func--);

    --C;
    use(--C);
    --dynamic;
    use(--dynamic);
    --T;
    use(--T);
    --Func;
    use(--Func);

    C ??= 42;
    use(C ??= 42);
    dynamic ??= 42;
    use(dynamic ??= 42);
    T ??= 42;
    use(T ??= 42);
    Func ??= 42;
    use(Func ??= 42);

    C += 42;
    use(C += 42);
    dynamic += 42;
    use(dynamic += 42);
    T += 42;
    use(T += 42);
    Func += 42;
    use(Func += 42);

    C -= 42;
    use(C -= 42);
    dynamic -= 42;
    use(dynamic -= 42);
    T -= 42;
    use(T -= 42);
    Func -= 42;
    use(Func -= 42);
  }
}

use(x) {
  if (x == new DateTime.now().millisecondsSinceEpoch) throw "Shouldn't happen";
}

main() {
  new C().test();
}
