main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  print(x is num);
  print(y is num);
  print(x + y);
  print(x is num);
  print(y is num); // will stay as is-num because String could be a target of +
}
