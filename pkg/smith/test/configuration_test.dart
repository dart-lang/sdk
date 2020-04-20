// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/minitest.dart';

import 'package:smith/smith.dart';

import 'test_helpers.dart';

void main() {
  group("Configuration", () {
    test("equality", () {
      // Same.
      expect(
          Configuration("name", Architecture.x64, Compiler.dart2js, Mode.debug,
              Runtime.vm, System.linux),
          equals(Configuration("name", Architecture.x64, Compiler.dart2js,
              Mode.debug, Runtime.vm, System.linux)));

      // Mode debug != release.
      expect(
          Configuration("name", Architecture.x64, Compiler.dart2js, Mode.debug,
              Runtime.vm, System.linux),
          notEquals(Configuration("name", Architecture.x64, Compiler.dart2js,
              Mode.release, Runtime.vm, System.linux)));

      // Differ by non-required option.
      expect(
          Configuration("name", Architecture.x64, Compiler.dart2js, Mode.debug,
              Runtime.vm, System.linux, enableAsserts: true),
          notEquals(Configuration("name", Architecture.x64, Compiler.dart2js,
              Mode.debug, Runtime.vm, System.linux,
              enableAsserts: false)));
    });

    group(".expandTemplate()", () {
      test("empty string", () {
        expectExpandError("", {}, 'Template must not be empty.');
      });

      test("missing ')'", () {
        expectExpandError(
            "before-(oops", {}, 'Missing ")" in name template "before-(oops".');
      });

      test("no parentheses", () {
        expect(
            Configuration.expandTemplate("x64-dart2js-debug-vm-linux", {}),
            equals([
              Configuration("x64-dart2js-debug-vm-linux", Architecture.x64,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.linux)
            ]));
      });

      test("parentheses at beginning", () {
        expect(
            Configuration.expandTemplate(
                "(ia32|x64)-dart2js-debug-vm-linux", {}),
            equals([
              Configuration("ia32-dart2js-debug-vm-linux", Architecture.ia32,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.linux),
              Configuration("x64-dart2js-debug-vm-linux", Architecture.x64,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.linux)
            ]));
      });

      test("parentheses at end", () {
        expect(
            Configuration.expandTemplate(
                "x64-dart2js-debug-vm-(linux|mac|win)", {}),
            equals([
              Configuration("x64-dart2js-debug-vm-linux", Architecture.x64,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.linux),
              Configuration("x64-dart2js-debug-vm-mac", Architecture.x64,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.mac),
              Configuration("x64-dart2js-debug-vm-win", Architecture.x64,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.win)
            ]));
      });

      test("expands all parenthesized sections", () {
        expect(
            Configuration.expandTemplate(
                "(ia32|x64)-dart2js-(debug|release)-vm-(linux|mac|win)", {}),
            equals([
              Configuration("ia32-dart2js-debug-vm-linux", Architecture.ia32,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.linux),
              Configuration("ia32-dart2js-debug-vm-mac", Architecture.ia32,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.mac),
              Configuration("ia32-dart2js-debug-vm-win", Architecture.ia32,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.win),
              Configuration("ia32-dart2js-release-vm-linux", Architecture.ia32,
                  Compiler.dart2js, Mode.release, Runtime.vm, System.linux),
              Configuration("ia32-dart2js-release-vm-mac", Architecture.ia32,
                  Compiler.dart2js, Mode.release, Runtime.vm, System.mac),
              Configuration("ia32-dart2js-release-vm-win", Architecture.ia32,
                  Compiler.dart2js, Mode.release, Runtime.vm, System.win),
              Configuration("x64-dart2js-debug-vm-linux", Architecture.x64,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.linux),
              Configuration("x64-dart2js-debug-vm-mac", Architecture.x64,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.mac),
              Configuration("x64-dart2js-debug-vm-win", Architecture.x64,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.win),
              Configuration("x64-dart2js-release-vm-linux", Architecture.x64,
                  Compiler.dart2js, Mode.release, Runtime.vm, System.linux),
              Configuration("x64-dart2js-release-vm-mac", Architecture.x64,
                  Compiler.dart2js, Mode.release, Runtime.vm, System.mac),
              Configuration("x64-dart2js-release-vm-win", Architecture.x64,
                  Compiler.dart2js, Mode.release, Runtime.vm, System.win)
            ]));
      });
      test("empty '()' is treated as empty string", () {
        expect(
            Configuration.expandTemplate("x64-()dart2js-debug-vm-linux", {}),
            equals([
              Configuration("x64-dart2js-debug-vm-linux", Architecture.x64,
                  Compiler.dart2js, Mode.debug, Runtime.vm, System.linux)
            ]));
      });
    });

    group(".parse()", () {
      test("infer required fields from name", () {
        expect(
            Configuration.parse("ia32-dart2js-debug-vm-linux", {}),
            equals(Configuration(
                "ia32-dart2js-debug-vm-linux",
                Architecture.ia32,
                Compiler.dart2js,
                Mode.debug,
                Runtime.vm,
                System.linux)));
      });

      test("read required fields from options", () {
        expect(
            Configuration.parse("something", {
              "architecture": "x64",
              "compiler": "dart2js",
              "mode": "debug",
              "runtime": "vm",
              "system": "linux"
            }),
            equals(Configuration("something", Architecture.x64,
                Compiler.dart2js, Mode.debug, Runtime.vm, System.linux)));
      });

      test("required fields from both name and options", () {
        expect(
            Configuration.parse("dart2js-vm",
                {"architecture": "x64", "mode": "debug", "system": "linux"}),
            equals(Configuration("dart2js-vm", Architecture.x64,
                Compiler.dart2js, Mode.debug, Runtime.vm, System.linux)));
      });

      test("'none' is not treated as compiler or runtime name", () {
        expect(
            Configuration.parse("none-x64-dart2js-debug-vm-linux", {}),
            equals(Configuration(
                "none-x64-dart2js-debug-vm-linux",
                Architecture.x64,
                Compiler.dart2js,
                Mode.debug,
                Runtime.vm,
                System.linux)));
      });

      test("architecture defaults to 'x64'", () {
        expect(Configuration.parse("dart2js-debug-vm-linux", {}).architecture,
            equals(Architecture.x64));
      });

      test("compiler defaults to runtime's default compiler", () {
        expect(Configuration.parse("vm", {}).compiler, equals(Compiler.none));
      });

      test("mode defaults to compiler's default mode", () {
        expect(Configuration.parse("dartkp-vm-linux", {}).mode,
            equals(Mode.debug));

        expect(Configuration.parse("dart2js-vm-linux", {}).mode,
            equals(Mode.release));
      });

      test("runtime defaults to compiler's default runtime", () {
        expect(Configuration.parse("dartdevc", {}).runtime,
            equals(Runtime.chrome));
      });

      test("runtime defaults to compiler's default runtime from option", () {
        expect(Configuration.parse("wat", {"compiler": "dartdevc"}).runtime,
            equals(Runtime.chrome));
      });

      test("system defaults to the host os", () {
        expect(
            Configuration.parse("dart2js-vm", {}).system, equals(System.host));
      });

      test("other options from map", () {
        expect(
            Configuration.parse("dart2js", {
              "nnbd": "weak",
              "builder-tag": "the tag",
              "vm-options": ["vm stuff", "more vm stuff"],
              "dart2js-options": ["dart2js stuff", "more dart2js stuff"],
              "enable-experiment": ["semicolons", "interrobangs"],
              "enable-asserts": true,
              "checked": true,
              "csp": true,
              "host-checked": true,
              "minified": true,
              "hot-reload": true,
              "hot-reload-rollback": true,
              "use-sdk": true
            }),
            equals(Configuration("dart2js", Architecture.x64, Compiler.dart2js,
                Mode.release, Runtime.d8, System.host,
                nnbdMode: NnbdMode.weak,
                builderTag: "the tag",
                vmOptions: ["vm stuff", "more vm stuff"],
                dart2jsOptions: ["dart2js stuff", "more dart2js stuff"],
                experiments: ["semicolons", "interrobangs"],
                enableAsserts: true,
                isChecked: true,
                isCsp: true,
                isHostChecked: true,
                isMinified: true,
                useHotReload: true,
                useHotReloadRollback: true,
                useSdk: true)));
      });

      test("neither compiler nor runtime specified", () {
        expectParseError(
            "debug",
            {},
            'Must specify at least one of compiler or runtime in options or '
                'configuration name.');
      });

      test("empty string", () {
        expectParseError("", {}, 'Name must not be empty.');
      });

      test("redundant field", () {
        expectParseError("dart2js-debug", {"mode": "debug"},
            'Redundant mode in configuration name "debug" and options.');
      });

      test("duplicate field", () {
        expectParseError(
            "dart2js-debug",
            {"mode": "release"},
            'Found mode "release" in options and "debug" in configuration '
                'name.');
      });

      test("multiple values for same option in name", () {
        expectParseError(
            "dart2js-debug-release",
            {},
            'Found multiple values for mode ("debug" and "release"), in '
                'configuration name.');
      });

      test("null bool option", () {
        expectParseError("dart2js", {"enable-asserts": null},
            'Option "enable-asserts" was null.');
      });

      test("wrong type for bool option", () {
        expectParseError("dart2js", {"enable-asserts": "false"},
            'Option "enable-asserts" had value "false", which is not a bool.');
      });

      test("null string option", () {
        expectParseError(
            "dart2js", {"builder-tag": null}, 'Option "builder-tag" was null.');
      });

      test("wrong type for string option", () {
        expectParseError("dart2js", {"builder-tag": true},
            'Option "builder-tag" had value "true", which is not a string.');
      });

      test("unknown option", () {
        expectParseError("dart2js", {"wat": "???"}, 'Unknown option "wat".');
      });
    });

    group("constructor", () {});

    group("optionsEqual()", () {
      var debugWithAsserts = Configuration(
        "name",
        Architecture.x64,
        Compiler.dart2js,
        Mode.debug,
        Runtime.vm,
        System.linux,
        enableAsserts: true,
      );

      var debugWithAsserts2 = Configuration(
        "different name",
        Architecture.x64,
        Compiler.dart2js,
        Mode.debug,
        Runtime.vm,
        System.linux,
        enableAsserts: true,
      );

      var debugNoAsserts = Configuration(
        "name",
        Architecture.x64,
        Compiler.dart2js,
        Mode.debug,
        Runtime.vm,
        System.linux,
      );

      var releaseNoAsserts = Configuration(
        "name",
        Architecture.x64,
        Compiler.dart2js,
        Mode.release,
        Runtime.vm,
        System.linux,
      );

      test("different options are not equal", () {
        expect(debugWithAsserts.optionsEqual(debugNoAsserts), isFalse);
        expect(debugNoAsserts.optionsEqual(releaseNoAsserts), isFalse);
        expect(releaseNoAsserts.optionsEqual(debugWithAsserts), isFalse);
      });

      test("same options are equal", () {
        expect(debugWithAsserts.optionsEqual(debugWithAsserts2), isTrue);
      });

      test("list elements are considered unordered", () {
        var aThenB = Configuration("name", Architecture.x64, Compiler.dart2js,
            Mode.release, Runtime.vm, System.linux,
            vmOptions: ["a", "b"]);

        var bThenA = Configuration("name", Architecture.x64, Compiler.dart2js,
            Mode.release, Runtime.vm, System.linux,
            vmOptions: ["b", "a"]);

        expect(aThenB.optionsEqual(bThenA), isTrue);
      });
    });

    group("visualCompare()", () {
      var a = Configuration("dartdevc", Architecture.ia32, Compiler.dartdevc,
          Mode.debug, Runtime.chrome, System.android,
          builderTag: "a tag",
          vmOptions: ["vm a1", "vm a2"],
          dart2jsOptions: ["dart2js a1", "dart2js a2"],
          experiments: ["experiment a1", "experiment a2"],
          timeout: 1);

      var b = Configuration(
        "dart2js",
        Architecture.x64,
        Compiler.dart2js,
        Mode.release,
        Runtime.d8,
        System.fuchsia,
        nnbdMode: NnbdMode.strong,
        builderTag: "b tag",
        vmOptions: ["vm b1", "vm b2"],
        dart2jsOptions: ["dart2js b1", "dart2js b2"],
        experiments: ["experiment b1", "experiment b2"],
        timeout: 2,
        enableAsserts: true,
        isChecked: true,
        isCsp: true,
        isHostChecked: true,
        isMinified: true,
        useAnalyzerCfe: true,
        useAnalyzerFastaParser: true,
        useElf: true,
        useHotReload: true,
        useHotReloadRollback: true,
        useSdk: true,
      );

      test("everything different", () {
        expect(a.visualCompare(b), equals("""
dartdevc
dart2js
architecture: ia32 x64
   compiler: dartdevc dart2js
   mode: debug release
   runtime: chrome d8
   system: android fuchsia
   nnbd: legacy strong
   sanitizer: none none
   builder-tag: a tag b tag
   vm-options: [vm a1, vm a2] [vm b1, vm b2]
   dart2js-options: [dart2js a1, dart2js a2] [dart2js b1, dart2js b2]
   experiments: [experiment a1, experiment a2] [experiment b1, experiment b2]
   timeout: 1 2
   enable-asserts: false true
   checked: false true
   csp: false true
   host-checked: false true
   minified: false true
   use-cfe: false true
   analyzer-use-fasta-parser: false true
   host-checked: false true
   hot-reload: false true
   hot-reload-rollback: false true
   use-sdk: false true
"""));
      });

      test("everything the same", () {
        expect(a.visualCompare(a), equals("""
dartdevc
dartdevc
architecture: ia32 ia32
   compiler: dartdevc dartdevc
   mode: debug debug
   runtime: chrome chrome
   system: android android
   nnbd: legacy legacy
   sanitizer: none none
   builder-tag: a tag a tag
   vm-options: [vm a1, vm a2] [vm a1, vm a2]
   dart2js-options: [dart2js a1, dart2js a2] [dart2js a1, dart2js a2]
   experiments: [experiment a1, experiment a2] [experiment a1, experiment a2]
   timeout: 1 1
"""));
      });
    });
  });
}
