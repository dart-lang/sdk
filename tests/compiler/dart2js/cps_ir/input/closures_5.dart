main() {
  var x = 122;
  var a = () => x;
  x = x + 1;
  print(a());
}

