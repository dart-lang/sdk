main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  var z = int.parse('1235');
  print(x is int);
  print(y is int);
  print(z is int);
  print(x.modPow(y, z));
  print(x is int);
  print(y is int);
  print(z is int);
}
