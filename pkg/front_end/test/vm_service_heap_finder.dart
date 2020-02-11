import "dart:io";
import "vm_service_heap_helper.dart";

class Foo {
  final String x;
  final int y;

  Foo(this.x, this.y);
}

main() async {
  List<Foo> foos = [];
  foos.add(new Foo("hello", 42));
  foos.add(new Foo("world", 43));
  foos.add(new Foo("!", 44));
  String connectTo = ask("Connect to");
  VMServiceHeapHelperBase vm = VMServiceHeapHelperBase();
  await vm.connect(Uri.parse(connectTo));
  String isolateId = await vm.getIsolateId();
  String classToFind = ask("Find what class");
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

  await vm.disconnect();
  print("Disconnect done!");
}

String ask(String question) {
  stdout.write("$question: ");
  return stdin.readLineSync();
}
