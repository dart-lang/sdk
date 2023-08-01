Future<void> main() async {
  try {
    await Future(() => throw Exception("async exception"));
  } catch (error) {
    print("Caught async exception: $error");
    try {
      throw 'foo';
    } on String catch (error) {
      print('Caught foo: $error');
    }
  }
}
