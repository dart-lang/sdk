main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  print(x is num);
  print(y is num);
  print(x ~/ y);
  print(x is num);
  print(y is num); // will be compiled to `true` if we know the type of `y`.
}
