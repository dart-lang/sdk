// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/compiler_options.dart' as api;
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/base/hybrid_file_system.dart';
import 'package:front_end/src/base/messages.dart';
import 'package:front_end/src/kernel/kernel_target.dart';
import 'package:kernel/ast.dart';

import '../test/compiler_test_helper.dart';
import 'unreachable_if_finder.dart';

Future<void> main() async {
  await simpleFinalCase();
  await simpleNonFinalCase();
}

Future<Component?> compileHelper(Map<Uri, String> data) async {
  MemoryFileSystem mfs =
      new MemoryFileSystem(new Uri(scheme: "org-dartlang-debug", path: "/"));
  for (MapEntry<Uri, String> entry in data.entries) {
    mfs.entityForUri(entry.key).writeAsStringSync(entry.value);
  }
  HybridFileSystem hfs = new HybridFileSystem(mfs);

  BuildResult result = await compile(
    inputs: [data.keys.first],
    onDiagnostic: (api.DiagnosticMessage message) {
      if (message.severity == Severity.error) {
        print(message.plainTextFormatted.join('\n'));
      }
    },
    fileSystem: hfs,
  );
  return result.component;
}

Uri testUri = Uri.parse("test://uri.dart");

Future<void> simpleFinalCase() async {
  Component? result = await compileHelper({
    testUri: r"""
main() {
  final bool foo = (1+1==2) ? true : false;
  if (foo) {
    print("hello #1");
    print("${foo ? "" : "!"}foo");
    if (foo) {
      print("always true");
    } else {
      print("Always false");
    }
    if (!foo) {
      print("always false");
    }
  } else {
    print("hello #2");
    print("${foo ? "" : "!"}foo");
    if (foo) {
      print("always false");
    } else {
      print("Always true");
    }
    if (!foo) {
      print("always true");
    }
  }
}
""",
  });
  if (result == null) throw "Got null component";
  print("Looking at component with ${result.libraries.length} libraries");
  List<Warning> warnings = UnreachableIfFinder.find(result);
  for (Warning warning in warnings) {
    print(warning);
  }
  expect(warnings.length, 6);
  expect(warnings[0].toString().contains("$testUri:5:"), true);
  expect(warnings[1].toString().contains("$testUri:6:"), true);
  expect(warnings[2].toString().contains("$testUri:11:"), true);
  expect(warnings[3].toString().contains("$testUri:16:"), true);
  expect(warnings[4].toString().contains("$testUri:17:"), true);
  expect(warnings[5].toString().contains("$testUri:22:"), true);
}

Future<void> simpleNonFinalCase() async {
  Component? result = await compileHelper({
    testUri: r"""
main() {
  bool foo = (1+1==2) ? true : false;
  if (foo) {
    print("hello #1");
    print("${foo ? "" : "!"}foo");
    if (foo) {
      print("always true");
    } else {
      print("Always false");
    }
    if (!foo) {
      print("always false");
    }
  } else {
    print("hello #2");
    print("${foo ? "" : "!"}foo");
    if (foo) {
      print("always false");
    } else {
      print("Always true");
    }
    if (!foo) {
      print("always true");
    }
  }
}
""",
  });
  if (result == null) throw "Got null component";
  print("Looking at component with ${result.libraries.length} libraries");
  List<Warning> warnings = UnreachableIfFinder.find(result);
  for (Warning warning in warnings) {
    print(warning);
  }
  expect(warnings.length, 6);
  expect(warnings[0].toString().contains("$testUri:5:"), true);
  expect(warnings[1].toString().contains("$testUri:6:"), true);
  expect(warnings[2].toString().contains("$testUri:11:"), true);
  expect(warnings[3].toString().contains("$testUri:16:"), true);
  expect(warnings[4].toString().contains("$testUri:17:"), true);
  expect(warnings[5].toString().contains("$testUri:22:"), true);
}

void expect(Object? actual, Object? expect) {
  if (expect != actual) throw "Expected $expect got $actual";
}
