// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "vm_service_helper.dart" as vmService;

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
  VMServiceHeapHelperPrinter vm = VMServiceHeapHelperPrinter();
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

class VMServiceHeapHelperPrinter extends vmService.VMServiceHelper {
  Future<void> printAllocationProfile(String isolateId, {String filter}) async {
    await waitUntilIsolateIsRunnable(isolateId);
    vmService.AllocationProfile allocationProfile =
        await serviceClient.getAllocationProfile(isolateId);
    for (vmService.ClassHeapStats member in allocationProfile.members) {
      if (filter != null) {
        if (member.classRef.name != filter) continue;
      } else {
        if (member.classRef.name == "") continue;
        if (member.instancesCurrent == 0) continue;
      }
      vmService.Class c =
          await serviceClient.getObject(isolateId, member.classRef.id);
      if (c.location?.script?.uri == null) continue;
      print("${member.classRef.name}: ${member.instancesCurrent}");
    }
  }

  Future<void> filterAndPrintInstances(String isolateId, String filter,
      String fieldName, Set<String> fieldValues) async {
    await waitUntilIsolateIsRunnable(isolateId);
    vmService.AllocationProfile allocationProfile =
        await serviceClient.getAllocationProfile(isolateId);
    for (vmService.ClassHeapStats member in allocationProfile.members) {
      if (member.classRef.name != filter) continue;
      vmService.Class c =
          await serviceClient.getObject(isolateId, member.classRef.id);
      if (c.location?.script?.uri == null) continue;
      print("${member.classRef.name}: ${member.instancesCurrent}");
      print(c.location.script.uri);

      vmService.InstanceSet instances = await serviceClient.getInstances(
          isolateId, member.classRef.id, 10000);
      int instanceNum = 0;
      for (vmService.ObjRef instance in instances.instances) {
        instanceNum++;
        vmService.Obj receivedObject =
            await serviceClient.getObject(isolateId, instance.id);
        if (receivedObject is! vmService.Instance) continue;
        vmService.Instance object = receivedObject;
        for (vmService.BoundField field in object.fields) {
          if (field.decl.name == fieldName) {
            if (field.value is vmService.Sentinel) continue;
            vmService.Obj receivedValue =
                await serviceClient.getObject(isolateId, field.value.id);
            if (receivedValue is! vmService.Instance) continue;
            String value = (receivedValue as vmService.Instance).valueAsString;
            if (!fieldValues.contains(value)) continue;
            print("${instanceNum}: ${field.decl.name}: "
                "${value} --- ${instance.id}");
          }
        }
      }
    }
    print("Done!");
  }

  Future<void> printRetainingPaths(String isolateId, String filter) async {
    await waitUntilIsolateIsRunnable(isolateId);
    vmService.AllocationProfile allocationProfile =
        await serviceClient.getAllocationProfile(isolateId);
    for (vmService.ClassHeapStats member in allocationProfile.members) {
      if (member.classRef.name != filter) continue;
      vmService.Class c =
          await serviceClient.getObject(isolateId, member.classRef.id);
      print("Found ${c.name} (location: ${c.location})");
      print("${member.classRef.name}: "
          "(instancesCurrent: ${member.instancesCurrent})");
      print("");

      vmService.InstanceSet instances = await serviceClient.getInstances(
          isolateId, member.classRef.id, 10000);
      print(" => Got ${instances.instances.length} instances");
      print("");

      for (vmService.ObjRef instance in instances.instances) {
        vmService.Obj receivedObject =
            await serviceClient.getObject(isolateId, instance.id);
        print("Instance: $receivedObject");
        vmService.RetainingPath retainingPath =
            await serviceClient.getRetainingPath(isolateId, instance.id, 1000);
        print("Retaining path: (length ${retainingPath.length}");
        for (int i = 0; i < retainingPath.elements.length; i++) {
          print("  [$i] = ${retainingPath.elements[i]}");
        }

        print("");
      }
    }
    print("Done!");
  }
}
