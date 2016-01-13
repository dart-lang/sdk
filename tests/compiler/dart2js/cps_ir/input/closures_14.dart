class Foo {
  get getter {
    print('getter');
    return (x) => x;
  }
}
main(x) {
  var notTearOff = new Foo().getter;
  print(notTearOff(123));
  print(notTearOff(321));
}

