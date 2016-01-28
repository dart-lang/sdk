main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  print(x is int);
  print(y is int);
  print(x.toSigned(y));
  print(x is int);
  print(y is int);
}
