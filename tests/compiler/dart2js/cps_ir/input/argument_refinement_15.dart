main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  var z = int.parse('1235');
  print(x is num);
  print(y is num);
  print(z is num);
  print(x.clamp(y, z));
  print(x is num);
  print(y is num);
  print(z is num);
}
