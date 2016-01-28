import 'dart:math';
main() {
  var x = int.parse('3');
  var y = int.parse('1234');
  var z = int.parse('1236');
  var w = int.parse('2');
  print(x is num);
  print(sin(x));
  print(x is num);

  print(y is num);
  print(log(y));
  print(y is num);

  print(z is num);
  print(w is num);
  print(pow(z, w));
  print(z is num);
  print(w is num);
}
