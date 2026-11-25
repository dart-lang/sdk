// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

Future<ProcessResult> run(String exec, List<String> args) async {
  print("+ $exec ${args.join(' ')}");
  var p = await Process.run(exec, args);
  print("$exec exitCode: ${p.exitCode}");
  print("$exec stdout:");
  print(p.stdout);
  print("$exec stderr:");
  print(p.stderr);
  return p;
}

Future<ProcessResult> runDocker(List<String> args) async {
  await run("docker", ["--version"]);

  var cwd = Directory.current.path;
  return run("docker", [
    "run",
    "--volume",
    "$cwd:$cwd",
    "--workdir",
    "$cwd",
    "--rm", // Delete on exit
    ...args,
    "ubuntu:latest",
    Platform.executable,
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--child",
  ]);
}

Future<ProcessResult> runSystemdRun(List<String> args) async {
  await run("systemd-run", ["--version"]);

  return run("systemd-run", [
    "--user",
    "--scope",
    "--quiet",
    ...args,
    "--",
    Platform.executable,
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--child",
  ]);
}

Future<ProcessResult> runTaskset(List<String> args) async {
  return run("taskset", [
    ...args,
    Platform.executable,
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--child",
  ]);
}

Future<ProcessResult> runJobRun(List<String> args) async {
  print(Platform.operatingSystemVersion);

  var job_run = Uri.file(Platform.executable)
      .resolve("job_run.exe")
      .toFilePath();
  return run(job_run, [
    ...args,
    "--",
    Platform.executable,
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--child",
  ]);
}

Future<ProcessResult> runStart(List<String> args) async {
  print(Platform.operatingSystemVersion);

  return run("cmd.exe", [
    "/c",
    "start",
    "/b", // Don't open new Command Prompt window.
    "/wait",
    ...args,
    Platform.executable,
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--child",
  ]);
}
