main() {
  var a;
  for (var i=0; i<10; i++) {
    a = () => i;
  }
  print(a());
}

