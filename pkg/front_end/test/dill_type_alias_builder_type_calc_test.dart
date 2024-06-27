// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/base/hybrid_file_system.dart';
import 'package:front_end/src/builder/library_builder.dart';
import 'package:front_end/src/dill/dill_library_builder.dart';
import 'package:front_end/src/dill/dill_type_alias_builder.dart';

import 'incremental_suite.dart' as helper;

Future<void> main(List<String> args) async {
  MemoryFileSystem memoryFileSystem =
      new MemoryFileSystem(new Uri(scheme: "darttest", path: "/"));
  HybridFileSystem hybridFileSystem = new HybridFileSystem(memoryFileSystem);

  Uri testUri = new Uri(scheme: "darttest", path: "/test1.dart");
  memoryFileSystem.entityForUri(testUri).writeAsStringSync("""
typedef Foo = R Function<R>(R Function() f);
void main() {}
""");

  Uri input = testUri;
  CompilerOptions options = helper.getOptions();
  options.omitPlatform = false;
  options.fileSystem = hybridFileSystem;
  helper.TestIncrementalCompiler compiler =
      new helper.TestIncrementalCompiler(options, input);

  await compiler.computeDelta(fullComponent: true);

  List<DillTypeAliasBuilder> failures = [];

  List<LibraryBuilder>? builders = [
    ...?compiler.platformBuildersForTesting,
    ...?compiler.userBuildersForTesting?.values
  ];
  for (LibraryBuilder builder in builders) {
    if (builder is! DillLibraryBuilder) continue;
    builder.scope.forEachLocalMember((name, member) {
      if (member is! DillTypeAliasBuilder) return;
      try {
        member.type;
      } catch (e) {
        failures.add(member);
      }
    });
  }

  if (failures.isNotEmpty) {
    print("Found ${failures.length} failures:\n");
    for (DillTypeAliasBuilder failure in failures) {
      print("$failure");
      print("${failure.typedef}");
      print("${failure.typedef.location}");
      try {
        failure.type;
        print("Weird --- didn't crash now...");
      } catch (e, st) {
        print("Crashing with message '$e' at:");
        print(st);
      }
      print("\n---------------\n");
    }
    throw "Failures found.";
  }
}
