// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "dart:io";

import "package:vm_service/vm_service.dart" as vmService;
import "package:vm_service/vm_service_io.dart" as vmService;

import "dijkstras_sssp_algorithm.dart";

class VMServiceHeapHelperBase {
  vmService.VmService _serviceClient;
  vmService.VmService get serviceClient => _serviceClient;

  VMServiceHeapHelperBase();

  Future connect(Uri observatoryUri) async {
    String path = observatoryUri.path;
    if (!path.endsWith("/")) path += "/";
    String wsUriString = 'ws://${observatoryUri.authority}${path}ws';
    _serviceClient = await vmService.vmServiceConnectUri(wsUriString,
        log: const StdOutLog());
  }

  Future disconnect() async {
    await _serviceClient.dispose();
  }

  Future<bool> waitUntilPaused(String isolateId) async {
    int nulls = 0;
    while (true) {
      bool result = await _isPaused(isolateId);
      if (result == null) {
        nulls++;
        if (nulls > 5) {
          // We've now asked for the isolate 5 times and in all cases gotten
          // `Sentinel`. Most likely things aren't working for whatever reason.
          return false;
        }
      } else if (result) {
        return true;
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<bool> _isPaused(String isolateId) async {
    dynamic tmp = await _serviceClient.getIsolate(isolateId);
    if (tmp is vmService.Isolate) {
      vmService.Isolate isolate = tmp;
      if (isolate.pauseEvent.kind != "Resume") return true;
      return false;
    }
    return null;
  }

  Future<bool> _isPausedAtStart(String isolateId) async {
    dynamic tmp = await _serviceClient.getIsolate(isolateId);
    if (tmp is vmService.Isolate) {
      vmService.Isolate isolate = tmp;
      return isolate.pauseEvent.kind == "PauseStart";
    }
    return false;
  }

  Future<vmService.AllocationProfile> forceGC(String isolateId) async {
    await waitUntilIsolateIsRunnable(isolateId);
    int expectGcAfter = new DateTime.now().millisecondsSinceEpoch;
    while (true) {
      vmService.AllocationProfile allocationProfile;
      try {
        allocationProfile =
            await _serviceClient.getAllocationProfile(isolateId, gc: true);
      } catch (e) {
        print(e.runtimeType);
        rethrow;
      }
      if (allocationProfile.dateLastServiceGC != null &&
          allocationProfile.dateLastServiceGC >= expectGcAfter) {
        return allocationProfile;
      }
    }
  }

  Future<bool> isIsolateRunnable(String isolateId) async {
    dynamic tmp = await _serviceClient.getIsolate(isolateId);
    if (tmp is vmService.Isolate) {
      vmService.Isolate isolate = tmp;
      return isolate.runnable;
    }
    return null;
  }

  Future<void> waitUntilIsolateIsRunnable(String isolateId) async {
    int nulls = 0;
    while (true) {
      bool result = await isIsolateRunnable(isolateId);
      if (result == null) {
        nulls++;
        if (nulls > 5) {
          // We've now asked for the isolate 5 times and in all cases gotten
          // `Sentinel`. Most likely things aren't working for whatever reason.
          return;
        }
      } else if (result) {
        return;
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> printAllocationProfile(String isolateId, {String filter}) async {
    await waitUntilIsolateIsRunnable(isolateId);
    vmService.AllocationProfile allocationProfile =
        await _serviceClient.getAllocationProfile(isolateId);
    for (vmService.ClassHeapStats member in allocationProfile.members) {
      if (filter != null) {
        if (member.classRef.name != filter) continue;
      } else {
        if (member.classRef.name == "") continue;
        if (member.instancesCurrent == 0) continue;
      }
      vmService.Class c =
          await _serviceClient.getObject(isolateId, member.classRef.id);
      if (c.location?.script?.uri == null) continue;
      print("${member.classRef.name}: ${member.instancesCurrent}");
    }
  }

  Future<void> filterAndPrintInstances(String isolateId, String filter,
      String fieldName, Set<String> fieldValues) async {
    await waitUntilIsolateIsRunnable(isolateId);
    vmService.AllocationProfile allocationProfile =
        await _serviceClient.getAllocationProfile(isolateId);
    for (vmService.ClassHeapStats member in allocationProfile.members) {
      if (member.classRef.name != filter) continue;
      vmService.Class c =
          await _serviceClient.getObject(isolateId, member.classRef.id);
      if (c.location?.script?.uri == null) continue;
      print("${member.classRef.name}: ${member.instancesCurrent}");
      print(c.location.script.uri);

      vmService.InstanceSet instances = await _serviceClient.getInstances(
          isolateId, member.classRef.id, 10000);
      int instanceNum = 0;
      for (vmService.ObjRef instance in instances.instances) {
        instanceNum++;
        var receivedObject =
            await _serviceClient.getObject(isolateId, instance.id);
        if (receivedObject is! vmService.Instance) continue;
        vmService.Instance object = receivedObject;
        for (vmService.BoundField field in object.fields) {
          if (field.decl.name == fieldName) {
            if (field.value is vmService.Sentinel) continue;
            var receivedValue =
                await _serviceClient.getObject(isolateId, field.value.id);
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
        await _serviceClient.getAllocationProfile(isolateId);
    for (vmService.ClassHeapStats member in allocationProfile.members) {
      if (member.classRef.name != filter) continue;
      vmService.Class c =
          await _serviceClient.getObject(isolateId, member.classRef.id);
      print("Found ${c.name} (location: ${c.location})");
      print("${member.classRef.name}: "
          "(instancesCurrent: ${member.instancesCurrent})");
      print("");

      vmService.InstanceSet instances = await _serviceClient.getInstances(
          isolateId, member.classRef.id, 10000);
      print(" => Got ${instances.instances.length} instances");
      print("");

      for (vmService.ObjRef instance in instances.instances) {
        var receivedObject =
            await _serviceClient.getObject(isolateId, instance.id);
        print("Instance: $receivedObject");
        vmService.RetainingPath retainingPath =
            await _serviceClient.getRetainingPath(isolateId, instance.id, 1000);
        print("Retaining path: (length ${retainingPath.length}");
        for (int i = 0; i < retainingPath.elements.length; i++) {
          print("  [$i] = ${retainingPath.elements[i]}");
        }

        print("");
      }
    }
    print("Done!");
  }

  Future<String> getIsolateId() async {
    vmService.VM vm = await _serviceClient.getVM();
    if (vm.isolates.length != 1) {
      throw "Expected 1 isolate, got ${vm.isolates.length}";
    }
    vmService.IsolateRef isolateRef = vm.isolates.single;
    return isolateRef.id;
  }
}

abstract class LaunchingVMServiceHeapHelper extends VMServiceHeapHelperBase {
  Process _process;
  Process get process => _process;

  bool _started = false;

  void start(List<String> scriptAndArgs,
      {void stdinReceiver(String line),
      void stderrReceiver(String line)}) async {
    if (_started) throw "Already started";
    _started = true;
    _process = await Process.start(
        Platform.resolvedExecutable,
        ["--pause_isolates_on_start", "--enable-vm-service=0"]
          ..addAll(scriptAndArgs));
    _process.stdout
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .listen((line) {
      const kObservatoryListening = 'Observatory listening on ';
      if (line.startsWith(kObservatoryListening)) {
        Uri observatoryUri =
            Uri.parse(line.substring(kObservatoryListening.length));
        _setupAndRun(observatoryUri).catchError((e, st) {
          // Manually kill the process or it will leak,
          // see http://dartbug.com/42918
          killProcess();
          // This seems to rethrow.
          throw e;
        });
      }
      if (stdinReceiver != null) {
        stdinReceiver(line);
      } else {
        stdout.writeln("> $line");
      }
    });
    _process.stderr
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .listen((line) {
      if (stderrReceiver != null) {
        stderrReceiver(line);
      } else {
        stderr.writeln("> $line");
      }
    });
    // ignore: unawaited_futures
    _process.exitCode.then((value) {
      processExited(value);
    });
  }

  void processExited(int exitCode) {}

  void killProcess() {
    _process.kill();
  }

  Future _setupAndRun(Uri observatoryUri) async {
    await connect(observatoryUri);
    await run();
  }

  Future<void> run();
}

class VMServiceHeapHelperSpecificExactLeakFinder
    extends LaunchingVMServiceHeapHelper {
  final Map<Uri, Map<String, List<String>>> _interests =
      new Map<Uri, Map<String, List<String>>>();
  final Map<Uri, Map<String, List<String>>> _prettyPrints =
      new Map<Uri, Map<String, List<String>>>();
  final bool throwOnPossibleLeak;
  final bool tryToFindShortestPathToLeaks;

  VMServiceHeapHelperSpecificExactLeakFinder(
      List<Interest> interests,
      List<Interest> prettyPrints,
      this.throwOnPossibleLeak,
      this.tryToFindShortestPathToLeaks) {
    if (interests.isEmpty) throw "Empty list of interests given";
    for (Interest interest in interests) {
      Map<String, List<String>> classToFields = _interests[interest.uri];
      if (classToFields == null) {
        classToFields = Map<String, List<String>>();
        _interests[interest.uri] = classToFields;
      }
      List<String> fields = classToFields[interest.className];
      if (fields == null) {
        fields = new List<String>();
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
        fields = new List<String>();
        classToFields[interest.className] = fields;
      }
      fields.addAll(interest.fieldNames);
    }
  }

  void pause() async {
    await _serviceClient.pause(_isolateRef.id);
  }

  vmService.VM _vm;
  vmService.IsolateRef _isolateRef;
  int _iterationNumber;
  int get iterationNumber => _iterationNumber;

  /// Best effort check if the isolate is idle.
  Future<bool> isIdle() async {
    dynamic tmp = await _serviceClient.getIsolate(_isolateRef.id);
    if (tmp is vmService.Isolate) {
      vmService.Isolate isolate = tmp;
      return isolate.pauseEvent.topFrame == null;
    }
    return false;
  }

  @override
  Future<void> run() async {
    _vm = await _serviceClient.getVM();
    if (_vm.isolates.length != 1) {
      throw "Expected 1 isolate, got ${_vm.isolates.length}";
    }
    _isolateRef = _vm.isolates.single;
    await forceGC(_isolateRef.id);

    assert(await _isPausedAtStart(_isolateRef.id));
    await _serviceClient.resume(_isolateRef.id);

    _iterationNumber = 1;
    while (true) {
      await waitUntilPaused(_isolateRef.id);
      print("Iteration: #$_iterationNumber");
      await forceGC(_isolateRef.id);

      vmService.HeapSnapshotGraph heapSnapshotGraph =
          await vmService.HeapSnapshotGraph.getSnapshot(
              _serviceClient, _isolateRef);

      Set<String> duplicatePrints = {};
      Map<String, List<vmService.HeapSnapshotObject>> groupedByToString = {};
      _usingUnconvertedGraph(
          heapSnapshotGraph, duplicatePrints, groupedByToString);

      if (duplicatePrints.isNotEmpty) {
        print("======================================");
        print("WARNING: Duplicated pretty prints of objects.");
        print("This might be a memory leak!");
        print("");
        for (String s in duplicatePrints) {
          int count = groupedByToString[s].length;
          print("$s ($count)");
          for (vmService.HeapSnapshotObject duplicate in groupedByToString[s]) {
            String prettyPrint = _heapObjectPrettyPrint(
                duplicate, heapSnapshotGraph, _prettyPrints);
            print(" => ${prettyPrint}");
          }
          print("");
        }

        if (tryToFindShortestPathToLeaks) {
          _tryToFindShortestPath(heapSnapshotGraph);
        }

        if (throwOnPossibleLeak) {
          throw "Possible leak detected.";
        }
      }

      await _serviceClient.resume(_isolateRef.id);
      _iterationNumber++;
    }
  }

  void _tryToFindShortestPath(vmService.HeapSnapshotGraph heapSnapshotGraph) {
    HeapGraph graph = convertHeapGraph(heapSnapshotGraph);
    Set<String> duplicatePrints = {};
    Map<String, List<HeapGraphElement>> groupedByToString = {};
    _usingConvertedGraph(graph, duplicatePrints, groupedByToString);

    print("======================================");

    for (String duplicateString in duplicatePrints) {
      print("$duplicateString:");
      List<HeapGraphElement> Function(HeapGraphElement target) dijkstraTarget =
          dijkstra(graph.elements.first, graph);
      for (HeapGraphElement duplicate in groupedByToString[duplicateString]) {
        print("${duplicate} pointed to from:");
        print(duplicate.getPrettyPrint(_prettyPrints));
        List<HeapGraphElement> shortestPath = dijkstraTarget(duplicate);
        for (int i = 0; i < shortestPath.length - 1; i++) {
          HeapGraphElement thisOne = shortestPath[i];
          HeapGraphElement nextOne = shortestPath[i + 1];
          String indexFieldName;
          if (thisOne is HeapGraphElementActual) {
            HeapGraphClass c = thisOne.class_;
            if (c is HeapGraphClassActual) {
              for (vmService.HeapSnapshotField field in c.origin.fields) {
                if (thisOne.references[field.index] == nextOne) {
                  indexFieldName = field.name;
                }
              }
            }
          }
          if (indexFieldName == null) {
            indexFieldName = "no field found; index "
                "${thisOne.references.indexOf(nextOne)}";
          }
          print("  $thisOne -> $nextOne ($indexFieldName)");
        }
        print("---------------------------");
      }
    }
  }

  void _usingConvertedGraph(HeapGraph graph, Set<String> duplicatePrints,
      Map<String, List<HeapGraphElement>> groupedByToString) {
    Set<String> seenPrints = {};
    for (HeapGraphClassActual c in graph.classes) {
      Map<String, List<String>> interests = _interests[c.libraryUri];
      if (interests != null && interests.isNotEmpty) {
        List<String> fieldsToUse = interests[c.name];
        if (fieldsToUse != null && fieldsToUse.isNotEmpty) {
          for (HeapGraphElement instance in c.getInstances(graph)) {
            StringBuffer sb = new StringBuffer();
            sb.writeln("Instance: ${instance}");
            if (instance is HeapGraphElementActual) {
              for (String fieldName in fieldsToUse) {
                String prettyPrinted =
                    instance.getField(fieldName).getPrettyPrint(_prettyPrints);
                sb.writeln("  $fieldName: "
                    "${prettyPrinted}");
              }
            }
            String sbToString = sb.toString();
            if (!seenPrints.add(sbToString)) {
              duplicatePrints.add(sbToString);
            }
            groupedByToString[sbToString] ??= [];
            groupedByToString[sbToString].add(instance);
          }
        }
      }
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
        int index = o.references[field.index] - 1;
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
    if (o.classId == 0) {
      return "Class sentinel";
    }
    vmService.HeapSnapshotClass class_ = graph.classes[o.classId - 1];

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
      if (o.classId == 0) {
        // Sentinel.
        continue;
      }
      if (ignoredClasses[o.classId - 1]) {
        // Class is not interesting.
        continue;
      }
      vmService.HeapSnapshotClass c = graph.classes[o.classId - 1];
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

  List<HeapGraphElement> Function(HeapGraphElement target) dijkstra(
      HeapGraphElement source, HeapGraph heapGraph) {
    Map<HeapGraphElement, int> elementNum = {};
    Map<HeapGraphElement, GraphNode<HeapGraphElement>> elements = {};
    elements[heapGraph.elementSentinel] =
        new GraphNode<HeapGraphElement>(heapGraph.elementSentinel);
    elementNum[heapGraph.elementSentinel] = elements.length;
    for (HeapGraphElementActual element in heapGraph.elements) {
      elements[element] = new GraphNode<HeapGraphElement>(element);
      elementNum[element] = elements.length;
    }

    for (HeapGraphElementActual element in heapGraph.elements) {
      GraphNode<HeapGraphElement> node = elements[element];
      for (HeapGraphElement out in element.references) {
        node.addOutgoing(elements[out]);
      }
    }

    DijkstrasAlgorithm<HeapGraphElement> result =
        new DijkstrasAlgorithm<HeapGraphElement>(
      elements.values,
      elements[source],
      (HeapGraphElement a, HeapGraphElement b) {
        if (identical(a, b)) {
          throw "Comparing two identical ones was unexpected";
        }
        return elementNum[a] - elementNum[b];
      },
      (HeapGraphElement a, HeapGraphElement b) {
        if (identical(a, b)) return 0;

        // Prefer going via actual field.
        if (a is HeapGraphElementActual) {
          HeapGraphClass c = a.class_;
          if (c is HeapGraphClassActual) {
            for (vmService.HeapSnapshotField field in c.origin.fields) {
              if (a.references[field.index] == b) {
                // Via actual field!
                return 1;
              }
            }
          }
        }

        // Prefer not to go directly from HeapGraphClassSentinel to Procedure.
        if (a is HeapGraphElementActual && b is HeapGraphElementActual) {
          HeapGraphElementActual aa = a;
          HeapGraphElementActual bb = b;
          if (aa.class_ is HeapGraphClassSentinel &&
              bb.class_ is HeapGraphClassActual) {
            HeapGraphClassActual c = bb.class_;
            if (c.name == "Procedure") {
              return 1000;
            }
          }
        }

        // Prefer not to go via sentinel and via "Context".
        if (b is HeapGraphElementSentinel) return 100;
        HeapGraphElementActual bb = b;
        if (bb.class_ is HeapGraphClassSentinel) return 100;
        HeapGraphClassActual c = bb.class_;
        if (c.name == "Context") {
          if (c.libraryUri.toString().isEmpty) return 100;
        }

        // Not via actual field.
        return 10;
      },
    );

    return (HeapGraphElement target) {
      return result.getPathFromTarget(elements[source], elements[target]);
    };
  }
}

class Interest {
  final Uri uri;
  final String className;
  final List<String> fieldNames;

  Interest(this.uri, this.className, this.fieldNames);
}

class StdOutLog implements vmService.Log {
  const StdOutLog();

  @override
  void severe(String message) {
    print("> SEVERE: $message");
  }

  @override
  void warning(String message) {
    print("> WARNING: $message");
  }
}

HeapGraph convertHeapGraph(vmService.HeapSnapshotGraph graph) {
  HeapGraphClassSentinel classSentinel = new HeapGraphClassSentinel();
  List<HeapGraphClassActual> classes =
      new List<HeapGraphClassActual>(graph.classes.length);
  for (int i = 0; i < graph.classes.length; i++) {
    vmService.HeapSnapshotClass c = graph.classes[i];
    classes[i] = new HeapGraphClassActual(c);
  }

  HeapGraphElementSentinel elementSentinel = new HeapGraphElementSentinel();
  List<HeapGraphElementActual> elements =
      new List<HeapGraphElementActual>(graph.objects.length);
  for (int i = 0; i < graph.objects.length; i++) {
    vmService.HeapSnapshotObject o = graph.objects[i];
    elements[i] = new HeapGraphElementActual(o);
  }

  for (int i = 0; i < graph.objects.length; i++) {
    vmService.HeapSnapshotObject o = graph.objects[i];
    HeapGraphElementActual converted = elements[i];
    if (o.classId == 0) {
      converted.class_ = classSentinel;
    } else {
      converted.class_ = classes[o.classId - 1];
    }
    converted.referencesFiller = () {
      for (int refId in o.references) {
        HeapGraphElement ref;
        if (refId == 0) {
          ref = elementSentinel;
        } else {
          ref = elements[refId - 1];
        }
        converted.references.add(ref);
      }
    };
  }
  return new HeapGraph(classSentinel, classes, elementSentinel, elements);
}

class HeapGraph {
  final HeapGraphClassSentinel classSentinel;
  final List<HeapGraphClassActual> classes;
  final HeapGraphElementSentinel elementSentinel;
  final List<HeapGraphElementActual> elements;

  HeapGraph(
      this.classSentinel, this.classes, this.elementSentinel, this.elements);
}

abstract class HeapGraphElement {
  /// Outbound references, i.e. this element points to elements in this list.
  List<HeapGraphElement> _references;
  void Function() referencesFiller;
  List<HeapGraphElement> get references {
    if (_references == null && referencesFiller != null) {
      _references = new List<HeapGraphElement>();
      referencesFiller();
    }
    return _references;
  }

  String getPrettyPrint(Map<Uri, Map<String, List<String>>> prettyPrints) {
    if (this is HeapGraphElementActual) {
      HeapGraphElementActual me = this;
      if (me.class_.toString() == "_OneByteString") {
        return '"${me.origin.data}"';
      }
      if (me.class_.toString() == "_SimpleUri") {
        return "_SimpleUri["
            "${me.getField("_uri").getPrettyPrint(prettyPrints)}]";
      }
      if (me.class_.toString() == "_Uri") {
        return "_Uri[${me.getField("scheme").getPrettyPrint(prettyPrints)}:"
            "${me.getField("path").getPrettyPrint(prettyPrints)}]";
      }
      if (me.class_ is HeapGraphClassActual) {
        HeapGraphClassActual c = me.class_;
        Map<String, List<String>> classToFields = prettyPrints[c.libraryUri];
        if (classToFields != null) {
          List<String> fields = classToFields[c.name];
          if (fields != null) {
            return "${c.name}[" +
                fields.map((field) {
                  return "$field: "
                      "${me.getField(field)?.getPrettyPrint(prettyPrints)}";
                }).join(", ") +
                "]";
          }
        }
      }
    }
    return toString();
  }
}

class HeapGraphElementSentinel extends HeapGraphElement {
  String toString() => "HeapGraphElementSentinel";
}

class HeapGraphElementActual extends HeapGraphElement {
  final vmService.HeapSnapshotObject origin;
  HeapGraphClass class_;

  HeapGraphElementActual(this.origin);

  HeapGraphElement getField(String name) {
    if (class_ is HeapGraphClassActual) {
      HeapGraphClassActual c = class_;
      for (vmService.HeapSnapshotField field in c.origin.fields) {
        if (field.name == name) {
          return references[field.index];
        }
      }
    }
    return null;
  }

  String toString() {
    if (origin.data is vmService.HeapSnapshotObjectNoData) {
      return "Instance of $class_";
    }
    if (origin.data is vmService.HeapSnapshotObjectLengthData) {
      vmService.HeapSnapshotObjectLengthData data = origin.data;
      return "Instance of $class_ length = ${data.length}";
    }
    return "Instance of $class_; data: '${origin.data}'";
  }
}

abstract class HeapGraphClass {
  List<HeapGraphElement> _instances;
  List<HeapGraphElement> getInstances(HeapGraph graph) {
    if (_instances == null) {
      _instances = new List<HeapGraphElement>();
      for (int i = 0; i < graph.elements.length; i++) {
        HeapGraphElementActual converted = graph.elements[i];
        if (converted.class_ == this) {
          _instances.add(converted);
        }
      }
    }
    return _instances;
  }
}

class HeapGraphClassSentinel extends HeapGraphClass {
  String toString() => "HeapGraphClassSentinel";
}

class HeapGraphClassActual extends HeapGraphClass {
  final vmService.HeapSnapshotClass origin;

  HeapGraphClassActual(this.origin) {
    assert(origin != null);
  }

  String get name => origin.name;

  Uri get libraryUri => origin.libraryUri;

  String toString() => name;
}
