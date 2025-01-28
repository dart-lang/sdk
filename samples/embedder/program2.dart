void main(List<String> args) {
  throw 'Unimplemented';
}

@pragma('vm:entry-point', 'call')
void printValue(String value) {
  print('program2 received: $value');
}
