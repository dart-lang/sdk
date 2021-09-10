// From https://github.com/dart-lang/sdk/issues/46886

void main(List<String> arguments) {
  var x = 10 >>> 2;
  print('x: $x');
}
