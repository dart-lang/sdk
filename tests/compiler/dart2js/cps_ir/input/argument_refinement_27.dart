main() {
  var x = int.parse('3');
  var y = int.parse('a', onError: (e) => 'abcde');
  print(x is int);
  print(y is String);
  print(y.codeUnitAt(x));
  print(x is int);
  print(y is String);
}
