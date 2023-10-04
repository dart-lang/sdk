// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import "simple_stats.dart";
import "vm_service_helper.dart" as vmService;

const int limit = 10;

Future<void> main(List<String> args) async {
  LeakFinder heapHelper = new LeakFinder();

  await heapHelper.start([
    "--disable-dart-dev",
    "--enable-asserts",
    Platform.script.resolve("incremental_dart2js_tester.dart").toString(),
    "--addDebugBreaks",
    "--fast",
    "--limit=$limit",
  ]);
}

class LeakFinder extends vmService.LaunchingVMServiceHelper {
  @override
  Future<void> run() async {
    vmService.VM vm = await serviceClient.getVM();
    if (vm.isolates!.length != 1) {
      throw "Expected 1 isolate, got ${vm.isolates!.length}";
    }
    vmService.IsolateRef isolateRef = vm.isolates!.single;
    await waitUntilIsolateIsRunnable(isolateRef.id!);
    await serviceClient.resume(isolateRef.id!);

    Map<vmService.ClassRef, List<int>> instanceCounts =
        new Map<vmService.ClassRef, List<int>>();
    Map<vmService.ClassRef, vmService.Class> classInfo =
        new Map<vmService.ClassRef, vmService.Class>();

    Completer<String> cTimeout = new Completer();
    Timer timer = new Timer(new Duration(minutes: 6), () {
      cTimeout.complete("Timeout");
      killProcess();
    });

    Completer<String> cRunDone = new Completer();
    // ignore: unawaited_futures
    runInternal(
        isolateRef,
        classInfo,
        instanceCounts,
        (int iteration) =>
            // Subtract 2 as it's logically one ahead and asks _before_ the run.
            (iteration - 2) > limit ||
            cTimeout.isCompleted ||
            cProcessExited.isCompleted).then((value) {
      cRunDone.complete("Done");
    });

    await Future.any([cRunDone.future, cTimeout.future, cProcessExited.future]);
    timer.cancel();

    print("\n\n======================\n\n");

    findPossibleLeaks(instanceCounts, classInfo);

    // Make sure the process doesn't hang.
    killProcess();
  }

  void findPossibleLeaks(Map<vmService.ClassRef, List<int>> instanceCounts,
      Map<vmService.ClassRef, vmService.Class> classInfo) {
    bool foundLeak = false;
    for (vmService.ClassRef c in instanceCounts.keys) {
      List<int> listOfInstanceCounts = instanceCounts[c]!;

      // Ignore VM internal stuff like "PatchClass", "PcDescriptors" etc.
      // (they don't have a url).
      vmService.Class classDetails = classInfo[c]!;
      String? uriString = classDetails.location?.script?.uri;
      if (uriString == null) continue;

      // For now ignore anything not in package:kernel or package:front_end.
      if (ignoredClass(classDetails)) continue;

      bool isStrictClass = strictClass(classDetails);

      int expectedStrictClassNumber = -1;
      if (isStrictClass) {
        expectedStrictClassNumber = strictClassExpectedNumber(classDetails);
      }

      // If they're all equal there's nothing to talk about.
      bool sameAndAsExpected = true;
      for (int i = 0; i < listOfInstanceCounts.length; i++) {
        if (expectedStrictClassNumber > -1 &&
            expectedStrictClassNumber != listOfInstanceCounts[i]) {
          sameAndAsExpected = false;
          break;
        }
        if (listOfInstanceCounts[i] != listOfInstanceCounts[0]) {
          sameAndAsExpected = false;
          break;
        }
      }
      if (sameAndAsExpected) continue;

      int midPoint = listOfInstanceCounts.length ~/ 2;
      List<int> firstHalf = listOfInstanceCounts.sublist(0, midPoint);
      List<int> secondHalf = listOfInstanceCounts.sublist(midPoint);
      TTestResult ttestResult = SimpleTTestStat.ttest(secondHalf, firstHalf);

      if (!isStrictClass) {
        if (!ttestResult.significant) continue;

        // TODO(jensj): We could possibly also ignore if it's less (i.e. a
        // negative change), or if the change is < 1%, or the change minus the
        // confidence is < 1% etc.
      }
      if (expectedStrictClassNumber > -1) {
        print("Differences on ${c.name} (${uriString}): "
            "Expected exactly $expectedStrictClassNumber but found "
            "$listOfInstanceCounts ($ttestResult)");
      } else {
        print("Differences on ${c.name} (${uriString}): "
            "$listOfInstanceCounts ($ttestResult)");
      }
      foundLeak = true;
    }

    print("\n\n");

    if (foundLeak) {
      print("Possible leak(s) found.");
      print("(Note that this doesn't guarantee that there are any!)");
      exitCode = 1;
    } else {
      print("Didn't identify any leaks.");
      print("(Note that this doesn't guarantee that there are none!)");
      exitCode = 0;
    }
  }

  Future<void> runInternal(
      vmService.IsolateRef isolateRef,
      Map<vmService.ClassRef, vmService.Class> classInfo,
      Map<vmService.ClassRef, List<int>> instanceCounts,
      bool Function(int iteration) shouldBail) async {
    int iterationNumber = 1;
    try {
      while (true) {
        if (shouldBail(iterationNumber)) break;
        if (!await waitUntilPaused(isolateRef.id!)) break;
        print("\n\n====================\n\nIteration #$iterationNumber");
        iterationNumber++;
        vmService.AllocationProfile allocationProfile =
            await forceGC(isolateRef.id!);
        for (vmService.ClassHeapStats member in allocationProfile.members!) {
          if (!classInfo.containsKey(member.classRef)) {
            vmService.Class c = (await serviceClient.getObject(
                isolateRef.id!, member.classRef!.id!)) as vmService.Class;
            classInfo[member.classRef!] = c;
          }
          List<int>? listOfInstanceCounts = instanceCounts[member.classRef];
          if (listOfInstanceCounts == null) {
            listOfInstanceCounts = instanceCounts[member.classRef!] = <int>[];
          }
          while (listOfInstanceCounts.length < iterationNumber - 2) {
            listOfInstanceCounts.add(0);
          }
          listOfInstanceCounts.add(member.instancesCurrent!);
          if (listOfInstanceCounts.length != iterationNumber - 1) {
            throw "Unexpected length";
          }
        }
        await serviceClient.resume(isolateRef.id!);
      }
    } catch (e) {
      print("Got error: $e");
    }
  }

  Completer<String> cProcessExited = new Completer();
  @override
  void processExited(int exitCode) {
    cProcessExited.complete("Exit");
  }

  bool ignoredClass(vmService.Class classDetails) {
    String? uriString = classDetails.location?.script?.uri;
    if (uriString == null) return true;
    if (uriString.startsWith("package:front_end/")) {
      // Because of lazy loading many things naturally fluctuate.
      // We'll therefore restrict this to Source* stuff and
      // DillLibraryBuilder for front_end stuff.
      if (classDetails.name?.startsWith("Source") ?? false) return false;
      if (classDetails.name == "DillLibraryBuilder") return false;
      return true;
    } else if (uriString.startsWith("package:kernel/")) {
      // DirtifyingList is used for lazy stuff and naturally change in numbers.
      if (classDetails.name == "DirtifyingList") return true;

      // Constants are canonicalized in their compilation run and will thus
      // naturally increase, e.g. we can get 2 more booleans every time (up to
      // a maximum of 2 per library or however many would have been there if we
      // didn't canonicalize at all).
      if (classDetails.name!.endsWith("Constant")) return true;

      // These classes have proved to fluctuate, although the reason is less
      // clear.
      if (classDetails.name == "InterfaceType") return true;

      return false;
    }
    return true;
  }

  Map<String, int> frontEndStrictClasses = {
    // The inner working of dills are created lazily:
    // "DillClassBuilder",
    // "DillExtensionBuilder",
    // "DillExtensionMemberBuilder",
    // "DillMemberBuilder",
    // "DillTypeAliasBuilder",

    "DillLibraryBuilder": -1 /* unknown amount */,
    "DillLoader": 1,
    "DillTarget": 1,

    // We convert all source builders to dill builders so we expect none to
    // exist after that.
    "SourceClassBuilder": 0,
    "SourceExtensionBuilder": 0,
    "SourceLibraryBuilder": 0,

    // We still expect exactly 1 source loader though.
    "SourceLoader": 1,
  };

  Set<String> kernelAstStrictClasses = {
    "Class",
    "Constructor",
    "Extension",
    "Field",
    "Library",
    "Procedure",
    "RedirectingFactory",
    "Typedef",
  };

  bool strictClass(vmService.Class classDetails) {
    if (!kernelAstStrictClasses.contains(classDetails.name) &&
        !frontEndStrictClasses.containsKey(classDetails.name)) return false;

    if (kernelAstStrictClasses.contains(classDetails.name) &&
        classDetails.location?.script?.uri == "package:kernel/ast.dart") {
      return true;
    }
    if (frontEndStrictClasses.containsKey(classDetails.name) &&
        classDetails.location?.script?.uri?.startsWith("package:front_end/") ==
            true) {
      return true;
    }

    throw "$classDetails: ${classDetails.name} --- ${classDetails.location}";
  }

  int strictClassExpectedNumber(vmService.Class classDetails) {
    if (!strictClass(classDetails)) return -1;
    if (kernelAstStrictClasses.contains(classDetails.name) &&
        classDetails.location?.script?.uri == "package:kernel/ast.dart") {
      return -1;
    }
    int? result = frontEndStrictClasses[classDetails.name];
    if (result != null &&
        classDetails.location?.script?.uri?.startsWith("package:front_end/") ==
            true) {
      return result;
    }

    throw "$classDetails: ${classDetails.name} --- ${classDetails.location}";
  }
}
