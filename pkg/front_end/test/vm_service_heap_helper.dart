// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "vm_service_helper.dart" as vmService;

class VMServiceHeapHelperSpecificExactLeakFinder
    extends vmService.LaunchingVMServiceHelper {
  final Set _interestsClassNames = {};
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
      Map<String, List<String>>? classToFields = _interests[interest.uri];
      if (classToFields == null) {
        classToFields = Map<String, List<String>>();
        _interests[interest.uri] = classToFields;
      }
      _interestsClassNames.add(interest.className);
      List<String>? fields = classToFields[interest.className];
      if (fields == null) {
        fields = <String>[];
        classToFields[interest.className] = fields;
      }
      fields.addAll(interest.fieldNames);
    }
    for (Interest interest in prettyPrints) {
      Map<String, List<String>>? classToFields = _prettyPrints[interest.uri];
      if (classToFields == null) {
        classToFields = Map<String, List<String>>();
        _prettyPrints[interest.uri] = classToFields;
      }
      List<String>? fields = classToFields[interest.className];
      if (fields == null) {
        fields = <String>[];
        classToFields[interest.className] = fields;
      }
      fields.addAll(interest.fieldNames);
    }
  }

  Future<void> pause() async {
    await serviceClient.pause(_isolateRef.id!);
  }

  late vmService.VM _vm;
  late vmService.IsolateRef _isolateRef;
  late int _iterationNumber;
  int get iterationNumber => _iterationNumber;

  /// Best effort check if the isolate is idle.
  Future<bool> isIdle() async {
    dynamic tmp = await serviceClient.getIsolate(_isolateRef.id!);
    if (tmp is vmService.Isolate) {
      vmService.Isolate isolate = tmp;
      return isolate.pauseEvent!.topFrame == null;
    }
    return false;
  }

  @override
  Future<void> run() async {
    _vm = await serviceClient.getVM();
    if (_vm.isolates!.length == 0) {
      print("Didn't get any isolates. Will wait 1 second and retry.");
      await Future.delayed(new Duration(seconds: 1));
      _vm = await serviceClient.getVM();
    }
    if (_vm.isolates!.length != 1) {
      throw "Expected 1 isolate, got ${_vm.isolates!.length}";
    }
    _isolateRef = _vm.isolates!.single;
    await forceGC(_isolateRef.id!);

    assert(await isPausedAtStart(_isolateRef.id!));
    await serviceClient.resume(_isolateRef.id!);

    _iterationNumber = 1;
    while (true) {
      if (!shouldDoAnotherIteration(_iterationNumber)) break;
      await waitUntilPaused(_isolateRef.id!);
      print("Iteration: #$_iterationNumber");

      Stopwatch stopwatch = new Stopwatch()..start();

      vmService.AllocationProfile allocationProfile =
          await forceGC(_isolateRef.id!);
      print("Forced GC in ${stopwatch.elapsedMilliseconds} ms");

      stopwatch.reset();
      List<Leak> leaks = [];
      for (vmService.ClassHeapStats member in allocationProfile.members!) {
        if (_interestsClassNames.contains(member.classRef!.name)) {
          vmService.Class c = (await serviceClient.getObject(
              _isolateRef.id!, member.classRef!.id!)) as vmService.Class;
          String? uriString = c.location?.script?.uri;
          if (uriString == null) continue;
          Uri uri = Uri.parse(uriString);
          Map<String, List<String>>? uriInterest = _interests[uri];
          if (uriInterest == null) continue;
          List<String>? fieldsForClass = uriInterest[c.name];
          if (fieldsForClass == null) continue;

          List<String> fieldsForClassPrettyPrint = fieldsForClass;

          uriInterest = _prettyPrints[uri];
          if (uriInterest != null) {
            if (uriInterest[c.name] != null) {
              fieldsForClassPrettyPrint = uriInterest[c.name]!;
            }
          }

          leaks.addAll(await _findLeaks(_isolateRef, member.classRef!,
              fieldsForClass, fieldsForClassPrettyPrint));
        }
      }
      if (leaks.isNotEmpty) {
        for (Leak leak in leaks) {
          leakDetected(leak.duplicate, leak.count, leak.prettyPrints);
        }
        if (throwOnPossibleLeak) {
          throw "Leaks found";
        }
      } else {
        noLeakDetected();
      }

      print("Looked for leaks in ${stopwatch.elapsedMilliseconds} ms");

      await serviceClient.resume(_isolateRef.id!);
      _iterationNumber++;
    }
  }

  Future<List<Leak>> _findLeaks(
      vmService.IsolateRef isolateRef,
      vmService.ClassRef classRef,
      List<String> fieldsForClass,
      List<String> fieldsForClassPrettyPrint) async {
    // Use undocumented (/ private?) method to get all instances of this class.
    vmService.InstanceRef instancesAsList = (await serviceClient.callMethod(
      "_getInstancesAsArray",
      isolateId: isolateRef.id,
      args: {
        "objectId": classRef.id,
        "includeSubclasses": false,
        "includeImplementors": false,
      },
    )) as vmService.InstanceRef;

    // Create dart code that `toString`s a class instance according to
    // the fields given as wanting printed. Both for finding duplicates (1) and
    // for pretty printing entries (for instance to be able to differentiate
    // them) (2).

    // 1:
    String fieldsToStringCode = classRef.name! +
        "[" +
        fieldsForClass
            .map((value) => "$value: \"\${element.$value}\"")
            .join(", ") +
        "]";
    // 2:
    String fieldsToStringPrettyPrintCode = classRef.name! +
        "[" +
        fieldsForClassPrettyPrint
            .map((value) => "$value: \"\${element.$value}\"")
            .join(", ") +
        "]";

    // Expression evaluation to find duplicates: Put all entries into a map
    // indexed by the `toString` code created above, mapping to list of that
    // data.
    vmService.InstanceRef mappedData = (await serviceClient.evaluate(
      isolateRef.id!,
      instancesAsList.id!,
      """
          this
              .fold({}, (dynamic index, dynamic element) {
                String key = '$fieldsToStringCode';
                var list = index[key] ??= [];
                list.add(element);
                return index;
              })
        """,
    )) as vmService.InstanceRef;
    // Expression calculation to find if any of the lists created as values
    // above contains more than one entry (i.e. there's a duplicate).
    vmService.InstanceRef duplicatesLengthRef = (await serviceClient.evaluate(
      isolateRef.id!,
      mappedData.id!,
      """
          this
              .values
              .where((dynamic element) => (element.length > 1) as bool)
              .length
        """,
    )) as vmService.InstanceRef;
    vmService.Instance duplicatesLength = (await serviceClient.getObject(
        isolateRef.id!, duplicatesLengthRef.id!)) as vmService.Instance;
    int? duplicates = int.tryParse(duplicatesLength.valueAsString!);
    if (duplicates != 0) {
      // There are duplicates. Expression calculation to encode the duplication
      // data (both the string that caused it to be a duplicate and the pretty
      // prints) as a string (to be able to easily get a hold of it here).
      // It filters out the duplicates and then encodes it with a simple scheme
      // of length-prefixed strings (and with everything separated by colons),
      // e.g. encode the string "string" as "6:string" (length 6, string),
      // and the list ["foo", "bar"] as "2:3:foo:3:bar" (2 entries, length 3,
      // foo, length 3, bar).
      vmService.ObjRef duplicatesDataRef = (await serviceClient.evaluate(
        isolateRef.id!,
        mappedData.id!,
        """
          this
              .entries
              .where((element) => (element.value as List).length > 1)
              .map((dynamic e) {
            var keyPart = "\${e.key.length}:\${e.key}";
            List value = e.value as List;
            var valuePart1 = "\${value.length}";
            var valuePart2 = value
                .map((element) => '$fieldsToStringPrettyPrintCode')
                .map((element) => "\${element.length}:\$element")
                .join(":");
            return "\${keyPart}:\${valuePart1}:\${valuePart2}";
          }).join(":")
          """,
      )) as vmService.ObjRef;
      if (duplicatesDataRef is! vmService.InstanceRef) {
        if (duplicatesDataRef is vmService.ErrorRef) {
          vmService.Error error = (await serviceClient.getObject(
              isolateRef.id!, duplicatesDataRef.id!)) as vmService.Error;
          throw "Leak found, but trying to evaluate pretty printing "
              "didn't go as planned.\n"
              "Got error with message "
              "'${error.message}'";
        } else {
          throw "Leak found, but trying to evaluate pretty printing "
              "didn't go as planned.\n"
              "Got type '${duplicatesDataRef.runtimeType}':"
              "$duplicatesDataRef";
        }
      }

      vmService.Instance duplicatesData = (await serviceClient.getObject(
          isolateRef.id!, duplicatesDataRef.id!)) as vmService.Instance;
      String encodedData = duplicatesData.valueAsString!;
      try {
        return parseEncodedLeakString(encodedData);
      } catch (e) {
        print("Failure on decoding '$encodedData'");
        rethrow;
      }
    } else {
      // No leaks.
      return [];
    }
  }

  static List<Leak> parseEncodedLeakString(String leakString) {
    int index = 0;
    int parseInt() {
      int endPartIndex = leakString.indexOf(":", index);
      String part = leakString.substring(index, endPartIndex);
      int value = int.parse(part);
      index = endPartIndex + 1;
      return value;
    }

    String parseString() {
      int value = parseInt();
      String string = leakString.substring(index, index + value);
      index = index + value + 1;
      return string;
    }

    List<Leak> result = [];
    while (index < leakString.length) {
      String duplicate = parseString();
      int count = parseInt();

      List<String> prettyPrints = [];
      for (int i = 0; i < count; i++) {
        String data = parseString();
        prettyPrints.add(data);
      }
      result.add(new Leak(duplicate, count, prettyPrints));
    }
    return result;
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

class Leak {
  final String duplicate;
  final int count;
  final List<String> prettyPrints;

  Leak(this.duplicate, this.count, this.prettyPrints);
}
