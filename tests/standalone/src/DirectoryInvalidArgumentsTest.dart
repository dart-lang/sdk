class DirectoryInvalidArgumentsTest {
  static void testFailingList(Directory d, var recursive) {
    int errors = 0;
    d.setErrorHandler((error) {
      errors += 1;
    });
    d.setDoneHandler((completed) {
      Expect.equals(1, errors);
      Expect.isFalse(completed);
    });
    Expect.equals(0, errors);
    d.list(recursive);
  }

  static void testInvalidArguments() {
    Directory d = new Directory(12);
    Expect.isFalse(d.exists());
    try {
      d.delete();
      Expect.fail("No exception thrown");
    } catch (var e) {
      Expect.isTrue(e is DirectoryException);
    }
    try {
      d.create();
      Expect.fail("No exception thrown");
    } catch (var e) {
      Expect.isTrue(e is DirectoryException);
    }
    testFailingList(d, false);
    d = new Directory(".");
    testFailingList(d, 1);
  }

  static void testMain() {
    testInvalidArguments();
  }
}

main() {
  DirectoryInvalidArgumentsTest.testMain();
}
