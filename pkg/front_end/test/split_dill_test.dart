// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, Platform, Process, ProcessResult;

import 'dart:typed_data' show Uint8List;

import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;

import 'package:kernel/ast.dart' show Component, Library;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/target/targets.dart' show TargetFlags;

import "package:vm/target/vm.dart" show VmTarget;

import 'incremental_load_from_dill_suite.dart'
    show getOptions, normalCompileToComponent;

import 'utils/io_utils.dart' show computeRepoDir;

main() async {
  final Uri dart2jsUrl = Uri.base.resolve("pkg/compiler/bin/dart2js.dart");
  Stopwatch stopwatch = new Stopwatch()..start();
  Component component = await normalCompileToComponent(dart2jsUrl,
      options: getOptions()
        ..target = new VmTarget(new TargetFlags())
        ..omitPlatform = false);
  print("Compiled dart2js in ${stopwatch.elapsedMilliseconds} ms");

  component.computeCanonicalNames();

  stopwatch.reset();
  List<List<int>> libComponents = <List<int>>[];
  for (Library lib in component.libraries) {
    Component libComponent = new Component(nameRoot: component.root);
    libComponent.libraries.add(lib);
    libComponent.uriToSource.addAll(component.uriToSource);
    libComponent.setMainMethodAndMode(
        component.mainMethodName, true, component.mode);
    libComponents.add(serializeComponent(libComponent));
  }
  print("Serialized ${libComponents.length} separate library components "
      "in ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  int totalLength = 0;
  for (List<int> libComponent in libComponents) {
    totalLength += libComponent.length;
  }
  Uint8List combined = new Uint8List(totalLength);
  int index = 0;
  for (List<int> libComponent in libComponents) {
    combined.setRange(index, index + libComponent.length, libComponent);
    index += libComponent.length;
  }
  print("Combined in ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  Component combinedComponent = new Component();
  new BinaryBuilder(combined).readComponent(combinedComponent);
  print("Read combined in ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  Uint8List merged = serializeComponent(combinedComponent);
  print("Serialized combined component in ${stopwatch.elapsedMilliseconds} ms");

  for (Uint8List data in [combined, merged]) {
    stopwatch.reset();
    Directory out = Directory.systemTemp.createTempSync("split_dill_test");
    try {
      File f = new File.fromUri(out.uri.resolve("out.dill"));
      f.writeAsBytesSync(data);

      ProcessResult result = await Process.run(
          dartVm,
          [
            "--compile_all",
            f.path,
            "-h",
          ],
          workingDirectory: out.path);
      print("stdout: ${result.stdout}");
      print("stderr: ${result.stderr}");
      print("Exit code: ${result.exitCode}");
      if (result.exitCode != 0) {
        throw "Got exit code ${result.exitCode}";
      }
      print("Ran VM on dill in ${stopwatch.elapsedMilliseconds} ms");
    } finally {
      out.deleteSync(recursive: true);
    }
  }
}

final String repoDir = computeRepoDir();

String get dartVm => Platform.resolvedExecutable;
