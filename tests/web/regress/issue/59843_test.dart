import 'package:expect/expect.dart';

void testBlock() {
  List<void Function()> functions = [];
  {
    var sub;
    functions.add(() {
      Expect.isNull(sub);
      sub = 1;
    });
  }
  {
    var sub;
    functions.add(() {
      Expect.equals(sub, 2);
    });
    sub = 2;
  }
  for (var function in functions) function();
}

void testIf() {
  List<void Function()> functions = [];
  if ('1234'.length > 2) {
    var sub;
    functions.add(() {
      Expect.isNull(sub);
      sub = 1;
    });
  }
  if ('1234'.length > 2) {
    var sub;
    functions.add(() {
      Expect.equals(sub, 2);
    });
    sub = 2;
  }
  for (var function in functions) function();
}

void testTry() {
  List<void Function()> functions = [];
  try {
    var sub;
    functions.add(() {
      Expect.isNull(sub);
      sub = 1;
    });
  } catch (e) {}
  try {
    var sub;
    functions.add(() {
      Expect.equals(sub, 2);
    });
    sub = 2;
  } catch (e) {}
  for (var function in functions) function();
}

void main() {
  testBlock();
  testIf();
  testTry();
}
