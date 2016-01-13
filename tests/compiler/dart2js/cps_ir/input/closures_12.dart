class Foo {
  instanceMethod(x) => x;
}
main(x) {
  var tearOff = new Foo().instanceMethod;
  print(tearOff(123));
}

