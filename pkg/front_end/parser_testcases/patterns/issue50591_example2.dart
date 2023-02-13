void f(Object? x) {
  (switch (x) {
    const A() => 0,
    _ => 1,
  });
