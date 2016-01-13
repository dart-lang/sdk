main() {
  var x = 122;
  var a = () {
    var y = x;
    return () => y;
  };
  x = x + 1;
  print(a()());
}

