void foo() {
  (int, int) record1 = (1, 2);
  (int x, int y) record1Named = (1, 2);
  (int, int, ) record2 = (1, 2);
  (int x, int y, ) record2Named = (1, 2);
  (int, int, {int a, int b}) record3 = (1, 2, a: 3, b: 4);
  (int x, int y, {int a, int b}) record3Named = (1, 2, a: 3, b: 4);
  (int, int, {int a, int b, }) record4 = (1, 2, a: 3, b: 4);
  (int x, int y, {int a, int b, }) record4Named = (1, 2, a: 3, b: 4);

  void Function(int, int) foobar;

  ((int, int), int) record5 = ((1, 2), 2);

  int async (int x, int y) {
    print("sync named async with int return type taking 2 parameters");
  }

  (int x, int y) async (int x, int y) {
    print("sync named async with record type return type taking 2 parameters");
  }
  
  (int x, int y) async (int x, int y) => print("sync named async with record type return type taking 2 parameters");

  (int x, int y) {
    print("sync unnamed taking 2 parameters");
  }();

  (int x, int y) => print("sync unnamed taking 2 parameters");

  (int x, int y) async {
    print("async unnamed taking 2 parameters");
  }();

  (int x, int y) async => print("async unnamed taking 2 parameters");
}
