// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File;
import 'dart:typed_data';

import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;
import 'package:kernel/src/equivalence.dart';
import 'package:kernel/target/targets.dart';

import 'incremental_suite.dart'
    show checkIsEqual, getOptions, initializedCompile, normalCompile;

late Directory outDir;

Future<void> main() async {
  outDir =
      Directory.systemTemp.createTempSync("incremental_load_from_dill_test");
  try {
    await testDart2jsCompile();
    print("----");
  } finally {
    outDir.deleteSync(recursive: true);
  }
}

Future<void> testDart2jsCompile() async {
  final Uri dart2jsUrl = Uri.base.resolve("pkg/compiler/lib/src/dart2js.dart");
  final Uri invalidateUri =
      Uri.parse("package:_fe_analyzer_shared/src/util/filenames.dart");
  Uri normalDill = outDir.uri.resolve("dart2js.full.dill");
  Uri fullDillFromInitialized =
      outDir.uri.resolve("dart2js.full_from_initialized.dill");
  Uri nonexisting = outDir.uri.resolve("dart2js.nonexisting.dill");

  // Compile dart2js without initializing from dill.
  // Note: Use none-target to avoid mismatches in "interface target" caused by
  // type inference occurring before or after mixin transformation.
  Stopwatch stopwatch = new Stopwatch()..start();
  await normalCompile(dart2jsUrl, normalDill,
      options: getOptions(target: new NoneTarget(new TargetFlags())));
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");
  {
    // Check that we don't include the source from files from the sdk.
    final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
    Uri platformUri = sdkRoot.resolve("vm_platform.dill");
    Component cSdk = new Component();
    new BinaryBuilder(new File.fromUri(platformUri).readAsBytesSync(),
            disableLazyReading: false)
        .readComponent(cSdk);

    Component c = new Component();
    new BinaryBuilder(new File.fromUri(normalDill).readAsBytesSync(),
            disableLazyReading: false)
        .readComponent(c);
    for (Uri uri in c.uriToSource.keys) {
      if (cSdk.uriToSource.containsKey(uri)) {
        if (c.uriToSource[uri]!.source.length != 0) {
          throw "Compile contained sources for the sdk $uri";
        }
        if ((c.uriToSource[uri]!.lineStarts?.length ?? 0) != 0) {
          throw "Compile contained line starts for the sdk $uri";
        }
      }
    }
  }

  // Compile dart2js, initializing from the just-compiled dill,
  // a nonexisting file.
  for (List<Object> initializationData in [
    [normalDill, true],
    [nonexisting, false],
  ]) {
    Uri initializeWith = initializationData[0] as Uri;
    bool initializeExpect = initializationData[1] as bool;
    stopwatch.reset();
    bool initializeResult = await initializedCompile(
        dart2jsUrl, fullDillFromInitialized, initializeWith, [invalidateUri],
        options: getOptions(target: new NoneTarget(new TargetFlags())));
    Expect.equals(initializeExpect, initializeResult);
    print("Initialized compile(s) from ${initializeWith.pathSegments.last} "
        "took ${stopwatch.elapsedMilliseconds} ms");

    // Compare the two files.
    Uint8List normalDillData = new File.fromUri(normalDill).readAsBytesSync();
    Uint8List initializedDillData =
        new File.fromUri(fullDillFromInitialized).readAsBytesSync();

    Component component1 = new Component();
    new BinaryBuilder(normalDillData).readComponent(component1);

    Component component2 = new Component();
    new BinaryBuilder(initializedDillData).readComponent(component2);
    EquivalenceResult result =
        checkEquivalence(component1, component2, strategy: const Strategy());
    Expect.isTrue(result.isEquivalent, result.toString());

    // TODO(johnniwinther): Reenable this check when the discrepancies have been
    // fixed.
    //checkIsEqual(normalDillData, initializedDillData);

    // Also try without invalidating anything.
    stopwatch.reset();
    initializeResult = await initializedCompile(
        dart2jsUrl, fullDillFromInitialized, initializeWith, [],
        options: getOptions(target: new NoneTarget(new TargetFlags())));
    Expect.equals(initializeExpect, initializeResult);
    print("Initialized compile(s) from ${initializeWith.pathSegments.last} "
        "took ${stopwatch.elapsedMilliseconds} ms");

    // Compare the two files.
    initializedDillData =
        new File.fromUri(fullDillFromInitialized).readAsBytesSync();
    checkIsEqual(normalDillData, initializedDillData);
  }
}

class Strategy extends EquivalenceStrategy {
  const Strategy();

  @override
  bool checkClass_procedures(
      EquivalenceVisitor visitor, Class node, Class other) {
    // Check procedures as a set instead of a list to allow for reordering.
    return visitor.checkSets(node.procedures.toSet(), other.procedures.toSet(),
        visitor.matchNamedNodes, visitor.checkNodes, 'procedures');
  }

  bool _isMixinOrCloneReference(EquivalenceVisitor visitor, Reference? a,
      Reference? b, String propertyName) {
    if (a != null && b != null) {
      ReferenceName thisName = ReferenceName.fromReference(a)!;
      ReferenceName otherName = ReferenceName.fromReference(b)!;
      if (thisName.isMember &&
          otherName.isMember &&
          thisName.memberName == otherName.memberName) {
        String? thisClassName = thisName.declarationName;
        String? otherClassName = otherName.declarationName;
        if (thisClassName != null &&
            otherClassName != null &&
            thisClassName.contains('&${otherClassName}')) {
          visitor.assumeReferences(a, b);
        }
      }
    }
    return visitor.checkReferences(a, b, propertyName);
  }

  @override
  bool checkProcedure_stubTargetReference(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return _isMixinOrCloneReference(visitor, node.stubTargetReference,
        other.stubTargetReference, 'stubTargetReference');
  }

  @override
  bool checkInstanceGet_interfaceTargetReference(
      EquivalenceVisitor visitor, InstanceGet node, InstanceGet other) {
    return _isMixinOrCloneReference(visitor, node.interfaceTargetReference,
        other.interfaceTargetReference, 'interfaceTargetReference');
  }
}
