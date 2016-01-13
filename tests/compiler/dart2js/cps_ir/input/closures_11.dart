staticMethod(x) { print(x); return x; }
main(x) {
  var tearOff = staticMethod;
  print(tearOff(123));
}

