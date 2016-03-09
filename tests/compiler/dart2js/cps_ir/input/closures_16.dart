class Foo {
  get getter {
    print('getter');
    return (x) { try { return x; } finally { } };  // Inhibit inlining.
  }
}
main(x) {
  // Getter may or may not be inlined.
  var notTearOff = new Foo().getter;
  // Closure is not inlined.
  print(notTearOff(123));
}
