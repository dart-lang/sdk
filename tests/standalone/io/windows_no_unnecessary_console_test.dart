// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that we don't accidentally end up creating a console window for a
// dartvm.exe process spawned from dart.exe process which itself was spawned
// without console.

import 'dart:convert';
import 'dart:io';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';

typedef HANDLE = Pointer<Void>;
typedef DWORD = Int32;
typedef BOOL = Int32;

final class SECURITY_ATTRIBUTES extends Opaque {}

@Native<
  HANDLE Function(
    Pointer<Uint8>,
    DWORD,
    DWORD,
    Pointer<SECURITY_ATTRIBUTES>,
    DWORD,
    DWORD,
    HANDLE,
  )
>(isLeaf: true)
external HANDLE CreateFileA(
  Pointer<Uint8> lpFileName,
  int dwDesiredAccess,
  int dwShareMode,
  Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
  int dwCreationDisposition,
  int dwFlagsAndAttributes,
  HANDLE hTemplateFile,
);

@Native<BOOL Function(HANDLE)>()
external int CloseHandle(HANDLE h);

@Native<Pointer<Void> Function()>()
external Pointer<Void> GetConsoleWindow();

/// Returns `true` is current process is attached to a console.
///
/// This is different from [Stdout.hasTerminal], because
/// standard output can be redirected but console can still
/// exist.
///
/// Note: this detect both visible and invisible consoles
/// (e.g. if process spawned with `CREATE_NO_WINDOW`).
bool get hasConsole {
  const int GENERIC_WRITE = 0x40000000;
  const int GENERIC_READ = 0x80000000;
  const int FILE_SHARE_WRITE = 0x00000002;
  const int OPEN_EXISTING = 3;

  final conOut = CreateFileA(
    utf8.encode(r"CONOUT$").address,
    GENERIC_WRITE | GENERIC_READ,
    FILE_SHARE_WRITE,
    nullptr,
    OPEN_EXISTING,
    0,
    nullptr,
  );
  final INVALID_HANDLE_VALUE = Pointer<Void>.fromAddress(-1);
  if (conOut != INVALID_HANDLE_VALUE) {
    CloseHandle(conOut);
    return true;
  }
  return false;
}

bool get hasConsoleWindow => GetConsoleWindow() != nullptr;

Future<void> testLaunch({
  required ProcessStartMode mode,
  required Map<String, bool> expected,
}) async {
  final process = await Process.start(Platform.executable, [
    Platform.script.toFilePath(),
    'child',
  ], mode: mode);
  final data = (
    process.stdout.transform(utf8.decoder).join(),
    process.stderr.transform(utf8.decoder).join(),
  );

  process.stdin.writeln('hello');
  process.stdin.close();

  final (stdoutText, stderrText) = await data.wait;
  Expect.mapEquals(expected, jsonDecode(stdoutText));
  Expect.equals('''
STDERR
''', stderrText.replaceAll('\r\n', '\n'));
}

void main(List<String> arguments) async {
  if (!Platform.isWindows) {
    return;
  }

  if (arguments.contains('child')) {
    Expect.equals('hello', stdin.readLineSync()?.trim());
    print(
      jsonEncode({
        'hasConsole': hasConsole,
        'hasConsoleWindow': hasConsoleWindow,
        'hasTerminal': stdout.hasTerminal,
      }),
    );
    stderr.write('STDERR\n');
    return;
  }

  await testLaunch(
    mode: .normal,
    expected: {
      'hasConsole': true,
      'hasConsoleWindow': false,
      'hasTerminal': false,
    },
  );

  await testLaunch(
    mode: .detachedWithStdio,
    expected: {
      'hasConsole': false,
      'hasConsoleWindow': false,
      'hasTerminal': false,
    },
  );
}
