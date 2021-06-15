// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "vm_service_helper.dart" as vmService;

class VMServiceHeapHelperSpecificExactLeakFinder
    extends vmService.LaunchingVMServiceHelper {
  final Map<Uri, Map<String, List<String>>> _interests =
      new Map<Uri, Map<String, List<String>>>();
  final Map<Uri, Map<String, List<String>>> _prettyPrints =
      new Map<Uri, Map<String, List<String>>>();
  final bool throwOnPossibleLeak;

  VMServiceHeapHelperSpecificExactLeakFinder({
    List<Interest> interests: const [],
    List<Interest> prettyPrints: const [],
    this.throwOnPossibleLeak: false,
  }) {
    if (interests.isEmpty) throw "Empty list of interests given";
    for (Interest interest in interests) {
      Map<String, List<String>> classToFields = _interests[interest.uri];
      if (classToFields == null) {
        classToFields = Map<String, List<String>>();
        _interests[interest.uri] = classToFields;
      }
      List<String> fields = classToFields[interest.className];
      if (fields == null) {
        fields = <String>[];
        classToFields[interest.className] = fields;
      }
      fields.addAll(interest.fieldNames);
    }
    for (Interest interest in prettyPrints) {
      Map<String, List<String>> classToFields = _prettyPrints[interest.uri];
      if (classToFields == null) {
        classToFields = Map<String, List<String>>();
        _prettyPrints[interest.uri] = classToFields;
      }
      List<String> fields = classToFields[interest.className];
      if (fields == null) {
        fields = <String>[];
        classToFields[interest.className] = fields;
      }
      fields.addAll(interest.fieldNames);
    }
  }

  void pause() async {
    await serviceClient.pause(_isolateRef.id);
  }

  vmService.VM _vm;
  vmService.IsolateRef _isolateRef;
  int _iterationNumber;
  int get iterationNumber => _iterationNumber;

  /// Best effort check if the isolate is idle.
  Future<bool> isIdle() async {
    dynamic tmp = await serviceClient.getIsolate(_isolateRef.id);
    if (tmp is vmService.Isolate) {
      vmService.Isolate isolate = tmp;
      return isolate.pauseEvent.topFrame == null;
    }
    return false;
  }

  @override
  Future<void> run() async {
    _vm = await serviceClient.getVM();
    if (_vm.isolates.length == 0) {
      print("Didn't get any isolates. Will wait 1 second and retry.");
      await Future.delayed(new Duration(seconds: 1));
      _vm = await serviceClient.getVM();
    }
    if (_vm.isolates.length != 1) {
      throw "Expected 1 isolate, got ${_vm.isolates.length}";
    }
    _isolateRef = _vm.isolates.single;
    await forceGC(_isolateRef.id);

    assert(await isPausedAtStart(_isolateRef.id));
    await serviceClient.resume(_isolateRef.id);

    _iterationNumber = 1;
    while (true) {
      if (!shouldDoAnotherIteration(_iterationNumber)) break;
      await waitUntilPaused(_isolateRef.id);
      print("Iteration: #$_iterationNumber");
      await forceGC(_isolateRef.id);

      vmService.HeapSnapshotGraph heapSnapshotGraph =
          await vmService.HeapSnapshotGraph.getSnapshot(
              serviceClient, _isolateRef);

      Set<String> duplicatePrints = {};
      Map<String, List<vmService.HeapSnapshotObject>> groupedByToString = {};
      _usingUnconvertedGraph(
          heapSnapshotGraph, duplicatePrints, groupedByToString);

      if (duplicatePrints.isNotEmpty) {
        for (String s in duplicatePrints) {
          int count = groupedByToString[s].length;
          List<String> prettyPrints = [];
          for (vmService.HeapSnapshotObject duplicate in groupedByToString[s]) {
            String prettyPrint = _heapObjectPrettyPrint(
                duplicate, heapSnapshotGraph, _prettyPrints);
            prettyPrints.add(prettyPrint);
          }
          leakDetected(s, count, prettyPrints);
        }

        if (throwOnPossibleLeak) {
          throw "Possible leak detected.";
        }
      } else {
        noLeakDetected();
      }

      await serviceClient.resume(_isolateRef.id);
      _iterationNumber++;
    }
  }

  String _heapObjectToString(
      vmService.HeapSnapshotObject o, vmService.HeapSnapshotClass class_) {
    if (o == null) return "Sentinel";
    if (o.data is vmService.HeapSnapshotObjectNoData) {
      return "Instance of ${class_.name}";
    }
    if (o.data is vmService.HeapSnapshotObjectLengthData) {
      vmService.HeapSnapshotObjectLengthData data = o.data;
      return "Instance of ${class_.name} length = ${data.length}";
    }
    return "Instance of ${class_.name}; data: '${o.data}'";
  }

  vmService.HeapSnapshotObject _heapObjectGetField(
      String name,
      vmService.HeapSnapshotObject o,
      vmService.HeapSnapshotClass class_,
      vmService.HeapSnapshotGraph graph) {
    for (vmService.HeapSnapshotField field in class_.fields) {
      if (field.name == name) {
        int index = o.references[field.index];
        if (index < 0) {
          // Sentinel object.
          return null;
        }
        return graph.objects[index];
      }
    }
    return null;
  }

  String _heapObjectPrettyPrint(
      vmService.HeapSnapshotObject o,
      vmService.HeapSnapshotGraph graph,
      Map<Uri, Map<String, List<String>>> prettyPrints) {
    if (o.classId <= 0) {
      return "Class sentinel";
    }
    vmService.HeapSnapshotClass class_ = o.klass;

    if (class_.name == "_OneByteString") {
      return '"${o.data}"';
    }

    if (class_.name == "_SimpleUri") {
      vmService.HeapSnapshotObject fieldValueObject =
          _heapObjectGetField("_uri", o, class_, graph);
      String prettyPrinted =
          _heapObjectPrettyPrint(fieldValueObject, graph, prettyPrints);
      return "_SimpleUri[${prettyPrinted}]";
    }

    if (class_.name == "_Uri") {
      vmService.HeapSnapshotObject schemeValueObject =
          _heapObjectGetField("scheme", o, class_, graph);
      String schemePrettyPrinted =
          _heapObjectPrettyPrint(schemeValueObject, graph, prettyPrints);

      vmService.HeapSnapshotObject pathValueObject =
          _heapObjectGetField("path", o, class_, graph);
      String pathPrettyPrinted =
          _heapObjectPrettyPrint(pathValueObject, graph, prettyPrints);

      return "_Uri[${schemePrettyPrinted}:${pathPrettyPrinted}]";
    }

    Map<String, List<String>> classToFields = prettyPrints[class_.libraryUri];
    if (classToFields != null) {
      List<String> fields = classToFields[class_.name];
      if (fields != null) {
        return "${class_.name}[" +
            fields.map((field) {
              vmService.HeapSnapshotObject fieldValueObject =
                  _heapObjectGetField(field, o, class_, graph);
              String prettyPrinted = fieldValueObject == null
                  ? null
                  : _heapObjectPrettyPrint(
                      fieldValueObject, graph, prettyPrints);
              return "$field: ${prettyPrinted}";
            }).join(", ") +
            "]";
      }
    }
    return _heapObjectToString(o, class_);
  }

  void _usingUnconvertedGraph(
      vmService.HeapSnapshotGraph graph,
      Set<String> duplicatePrints,
      Map<String, List<vmService.HeapSnapshotObject>> groupedByToString) {
    Set<String> seenPrints = {};
    List<bool> ignoredClasses =
        new List<bool>.filled(graph.classes.length, false);
    for (int i = 0; i < graph.objects.length; i++) {
      vmService.HeapSnapshotObject o = graph.objects[i];
      if (o.classId <= 0) {
        // Sentinel.
        continue;
      }
      if (ignoredClasses[o.classId - 1]) {
        // Class is not interesting.
        continue;
      }
      vmService.HeapSnapshotClass c = o.klass;
      Map<String, List<String>> interests = _interests[c.libraryUri];
      if (interests == null || interests.isEmpty) {
        // Not an object we care about.
        ignoredClasses[o.classId - 1] = true;
        continue;
      }

      List<String> fieldsToUse = interests[c.name];
      if (fieldsToUse == null || fieldsToUse.isEmpty) {
        // Not an object we care about.
        ignoredClasses[o.classId - 1] = true;
        continue;
      }

      StringBuffer sb = new StringBuffer();
      sb.writeln("Instance: ${_heapObjectToString(o, c)}");
      for (String fieldName in fieldsToUse) {
        vmService.HeapSnapshotObject fieldValueObject =
            _heapObjectGetField(fieldName, o, c, graph);
        String prettyPrinted =
            _heapObjectPrettyPrint(fieldValueObject, graph, _prettyPrints);
        sb.writeln("  $fieldName: ${prettyPrinted}");
      }
      String sbToString = sb.toString();
      if (!seenPrints.add(sbToString)) {
        duplicatePrints.add(sbToString);
      }
      groupedByToString[sbToString] ??= [];
      groupedByToString[sbToString].add(o);
    }
  }

  int _latestLeakIteration = -1;

  void leakDetected(String duplicate, int count, List<String> prettyPrints) {
    if (_iterationNumber != _latestLeakIteration) {
      print("======================================");
      print("WARNING: Duplicated pretty prints of objects.");
      print("This might be a memory leak!");
      print("");
    }
    _latestLeakIteration = _iterationNumber;
    print("$duplicate ($count)");
    for (String prettyPrint in prettyPrints) {
      print(" => ${prettyPrint}");
    }
    print("");
  }

  void noLeakDetected() {}

  bool shouldDoAnotherIteration(int iterationNumber) {
    return true;
  }
}

class Interest {
  final Uri uri;
  final String className;
  final List<String> fieldNames;

  Interest(this.uri, this.className, this.fieldNames);
}
