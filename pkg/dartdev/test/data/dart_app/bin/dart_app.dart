void main(List<String> args) {
  if (args.isEmpty) {
    print('Hello world');
  } else {
    print('Hello ${args.join(' ')}');
  }
}
