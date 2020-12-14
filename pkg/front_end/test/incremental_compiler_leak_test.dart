import 'dart:async';
import 'dart:io';

import "simple_stats.dart";
import "vm_service_helper.dart" as vmService;

const int limit = 10;

main(List<String> args) async {
  LeakFinder heapHelper = new LeakFinder();

  heapHelper.start([
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
    if (vm.isolates.length != 1) {
      throw "Expected 1 isolate, got ${vm.isolates.length}";
    }
    vmService.IsolateRef isolateRef = vm.isolates.single;
    await waitUntilIsolateIsRunnable(isolateRef.id);
    await serviceClient.resume(isolateRef.id);

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
      List<int> listOfInstanceCounts = instanceCounts[c];

      // Ignore VM internal stuff like "PatchClass", "PcDescriptors" etc.
      // (they don't have a url).
      vmService.Class classDetails = classInfo[c];
      String uriString = classDetails.location?.script?.uri;
      if (uriString == null) continue;

      // For now ignore anything not in package:kernel or package:front_end.
      if (ignoredClass(classDetails)) continue;

      // If they're all equal there's nothing to talk about.
      bool same = true;
      for (int i = 1; i < listOfInstanceCounts.length; i++) {
        if (listOfInstanceCounts[i] != listOfInstanceCounts[0]) {
          same = false;
          break;
        }
      }
      if (same) continue;

      int midPoint = listOfInstanceCounts.length ~/ 2;
      List<int> firstHalf = listOfInstanceCounts.sublist(0, midPoint);
      List<int> secondHalf = listOfInstanceCounts.sublist(midPoint);
      TTestResult ttestResult = SimpleTTestStat.ttest(secondHalf, firstHalf);

      if (!strictClass(classDetails)) {
        if (!ttestResult.significant) continue;

        // TODO(jensj): We could possibly also ignore if it's less (i.e. a
        // negative change), or if the change is < 1%, or the change minus the
        // confidence is < 1% etc.
      }
      print("Differences on ${c.name} (${uriString}): "
          "$listOfInstanceCounts ($ttestResult)");
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
        if (!await waitUntilPaused(isolateRef.id)) break;
        print("\n\n====================\n\nIteration #$iterationNumber");
        iterationNumber++;
        vmService.AllocationProfile allocationProfile =
            await forceGC(isolateRef.id);
        for (vmService.ClassHeapStats member in allocationProfile.members) {
          if (!classInfo.containsKey(member.classRef)) {
            vmService.Class c = await serviceClient.getObject(
                isolateRef.id, member.classRef.id);
            classInfo[member.classRef] = c;
          }
          List<int> listOfInstanceCounts = instanceCounts[member.classRef];
          if (listOfInstanceCounts == null) {
            listOfInstanceCounts = instanceCounts[member.classRef] = <int>[];
          }
          while (listOfInstanceCounts.length < iterationNumber - 2) {
            listOfInstanceCounts.add(0);
          }
          listOfInstanceCounts.add(member.instancesCurrent);
          if (listOfInstanceCounts.length != iterationNumber - 1) {
            throw "Unexpected length";
          }
        }
        await serviceClient.resume(isolateRef.id);
      }
    } catch (e) {
      print("Got error: $e");
    }
  }

  Completer<String> cProcessExited = new Completer();
  void processExited(int exitCode) {
    cProcessExited.complete("Exit");
  }

  bool ignoredClass(vmService.Class classDetails) {
    String uriString = classDetails.location?.script?.uri;
    if (uriString == null) return true;
    if (uriString.startsWith("package:front_end/")) {
      // Classes used for lazy initialization will naturally fluctuate.
      if (classDetails.name == "DillClassBuilder") return true;
      if (classDetails.name == "DillExtensionBuilder") return true;
      if (classDetails.name == "DillExtensionMemberBuilder") return true;
      if (classDetails.name == "DillMemberBuilder") return true;
      if (classDetails.name == "DillTypeAliasBuilder") return true;

      // These classes have proved to fluctuate, although the reason is less
      // clear.
      if (classDetails.name == "InheritedImplementationInterfaceConflict") {
        return true;
      }
      if (classDetails.name == "AbstractMemberOverridingImplementation") {
        return true;
      }
      if (classDetails.name == "VoidTypeBuilder") return true;
      if (classDetails.name == "NamedTypeBuilder") return true;
      if (classDetails.name == "DillClassMember") return true;
      if (classDetails.name == "Scope") return true;
      if (classDetails.name == "ConstructorScope") return true;
      if (classDetails.name == "ScopeBuilder") return true;
      if (classDetails.name == "ConstructorScopeBuilder") return true;
      if (classDetails.name == "NullTypeDeclarationBuilder") return true;
      if (classDetails.name == "NullabilityBuilder") return true;

      return false;
    } else if (uriString.startsWith("package:kernel/")) {
      // DirtifyingList is used for lazy stuff and naturally change in numbers.
      if (classDetails.name == "DirtifyingList") return true;

      // Constants are canonicalized in their compilation run and will thus
      // naturally increase, e.g. we can get 2 more booleans every time (up to
      // a maximum of 2 per library or however many would have been there if we
      // didn't canonicalize at all).
      if (classDetails.name.endsWith("Constant")) return true;

      // These classes have proved to fluctuate, although the reason is less
      // clear.
      if (classDetails.name == "InterfaceType") return true;

      return false;
    }
    return true;
  }

  // I have commented out the lazy ones below.
  Set<String> frontEndStrictClasses = {
    // "DillClassBuilder",
    // "DillExtensionBuilder",
    // "DillExtensionMemberBuilder",
    "DillLibraryBuilder",
    "DillLoader",
    // "DillMemberBuilder",
    "DillTarget",
    // "DillTypeAliasBuilder",
    "SourceClassBuilder",
    "SourceExtensionBuilder",
    "SourceLibraryBuilder",
    "SourceLoader",
  };

  Set<String> kernelAstStrictClasses = {
    "Class",
    "Constructor",
    "Extension",
    "Field",
    "Library",
    "Procedure",
    "RedirectingFactoryConstructor",
    "Typedef",
  };

  bool strictClass(vmService.Class classDetails) {
    if (!kernelAstStrictClasses.contains(classDetails.name) &&
        !frontEndStrictClasses.contains(classDetails.name)) return false;

    if (kernelAstStrictClasses.contains(classDetails.name) &&
        classDetails.location?.script?.uri == "package:kernel/ast.dart") {
      return true;
    }
    if (frontEndStrictClasses.contains(classDetails.name) &&
        classDetails.location?.script?.uri?.startsWith("package:front_end/") ==
            true) {
      return true;
    }

    throw "$classDetails: ${classDetails.name} --- ${classDetails.location}";
  }
}
