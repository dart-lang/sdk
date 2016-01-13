// Bounds checking
foo(s) {
  var sum = 0;
  for (int i = 0; i < s.length; i++) sum += s.codeUnitAt(i);
  return sum;
}
main() {
  print(foo('ABC'));
  print(foo('Hello'));
}
