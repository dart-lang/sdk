import "dart:io";
import "vm_service_heap_helper.dart";

class Foo {
  final String x;
  final int y;

  Foo(this.x, this.y);
}

main(List<String> args) async {
  String connectTo;
  String classToFind;
  String whatToDo;
  for (String arg in args) {
    if (arg.startsWith("--url=")) {
      connectTo = arg.substring("--url=".length);
    } else if (arg.startsWith("--find=")) {
      classToFind = arg.substring("--find=".length);
    } else if (arg.startsWith("--action=")) {
      whatToDo = arg.substring("--action=".length);
    }
  }
  List<Foo> foos = [];
  foos.add(new Foo("hello", 42));
  foos.add(new Foo("world", 43));
  foos.add(new Foo("!", 44));

  if (connectTo == null) connectTo = ask("Connect to");
  VMServiceHeapHelperBase vm = VMServiceHeapHelperBase();
  await vm.connect(Uri.parse(connectTo.trim()));
  String isolateId = await vm.getIsolateId();
  if (classToFind == null) classToFind = ask("Find what class");

  if (whatToDo == null) whatToDo = ask("What to do? (filter/retainingpath)");
  if (whatToDo == "retainingpath") {
    await vm.printRetainingPaths(isolateId, classToFind);
  } else {
    await vm.printAllocationProfile(isolateId, filter: classToFind);
    String fieldToFilter = ask("Filter on what field");
    Set<String> fieldValues = {};
    while (true) {
      String fieldValue = ask("Look for value in field (empty to stop)");
      if (fieldValue == "") break;
      fieldValues.add(fieldValue);
    }

    await vm.filterAndPrintInstances(
        isolateId, classToFind, fieldToFilter, fieldValues);
  }

  await vm.disconnect();
  print("Disconnect done!");
}

String ask(String question) {
  stdout.write("$question: ");
  return stdin.readLineSync();
}
