// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

typedef HANDLE = Pointer<Void>;

final class SECURITY_ATTRIBUTES extends Struct {
  @Int32()
  external int length;

  external Pointer<Void> securityDescriptor;

  @Int32()
  external int inheritHandle;
}

@Native<HANDLE Function(Pointer<SECURITY_ATTRIBUTES>, Pointer<Char>)>(
  isLeaf: true,
)
external HANDLE CreateJobObjectA(
  Pointer<SECURITY_ATTRIBUTES> sa,
  Pointer<Char> name,
);

@Native<Int32 Function(HANDLE)>(isLeaf: true)
external int CloseHandle(HANDLE hObject);

final class UNICODE_STRING extends Struct {
  @Uint16()
  external int length;

  @Uint16()
  external int maximumLength;

  external Pointer<Utf16> buffer;
}

final class PUBLIC_OBJECT_TYPE_INFORMATION extends Struct {
  external UNICODE_STRING typeName;

  @Array(22)
  external Array<Int32> reserved;
}

final class PUBLIC_OBJECT_BASIC_INFORMATION extends Struct {
  @Uint32()
  external int attributes;

  @Uint32()
  external int grantedAccess;

  @Uint32()
  external int handleCount;

  @Uint32()
  external int pointerCount;

  @Array(10)
  external Array<Uint32> reserved;
}

@Native<
  Uint32 Function(HANDLE, Uint32, Pointer<Uint8>, Uint32, Pointer<Uint32>)
>(isLeaf: true)
external int NtQueryObject(
  HANDLE handle,
  int objectInformationClass,
  Pointer<Uint8> objectInformation,
  int objectInformationLength,
  Pointer<Uint32> returnLength,
);

const ObjectBasicInformation = 0;
const ObjectTypeInformation = 2;

T? queryObject<T>(
  HANDLE h,
  int queryType,
  int bufferSize,
  T Function(TypedData) ctor,
) {
  const STATUS_SUCCESS = 0;
  const STATUS_INFO_LENGTH_MISMATCH = 0xC0000004;

  while (true) {
    final buffer = Uint8List(bufferSize);
    final resultingSize = Uint32List(1);

    final status = NtQueryObject(
      h,
      queryType,
      buffer.address,
      buffer.length,
      resultingSize.address,
    );
    if (status == STATUS_SUCCESS) {
      return ctor(buffer);
    } else if (status != STATUS_INFO_LENGTH_MISMATCH) {
      return null;
    }
    if (bufferSize == 0) {
      return null;
    }

    bufferSize = resultingSize[0];
    // Retry
  }
}

String? handleType(HANDLE h) {
  return queryObject(h, ObjectTypeInformation, 120, (td) {
    final info = Struct.create<PUBLIC_OBJECT_TYPE_INFORMATION>(td);
    return info.typeName.buffer
        .toDartString(length: info.typeName.length ~/ sizeOf<WChar>())
        .toLowerCase();
  });
}

PUBLIC_OBJECT_BASIC_INFORMATION? handleInfo(HANDLE h) {
  return queryObject(
    h,
    ObjectBasicInformation,
    sizeOf<PUBLIC_OBJECT_BASIC_INFORMATION>(),
    (td) => Struct.create<PUBLIC_OBJECT_BASIC_INFORMATION>(td),
  );
}

Future<void> testHandleNotInherited(ProcessStartMode mode) async {
  final attrs = Struct.create<SECURITY_ATTRIBUTES>()
    ..length = sizeOf<SECURITY_ATTRIBUTES>()
    ..securityDescriptor = nullptr
    ..inheritHandle = 1;

  final job = CreateJobObjectA(attrs.address, nullptr);
  try {
    Expect.equals('job', handleType(job));
    Expect.equals(1, handleInfo(job)?.handleCount);

    final child = await Process.start(Platform.executable, [
      ...Platform.executableArguments,
      Platform.script.toFilePath(),
      '--child',
      job.address.toString(),
    ], mode: mode);

    // Not expecting to see more handles here.
    Expect.equals(1, handleInfo(job)?.handleCount);

    final exitCode = await child.exitCode;
    Expect.equals(
      0,
      exitCode,
      'Child process spawned with $mode inherited the job handle!',
    );
  } finally {
    CloseHandle(job);
  }
}

void main(List<String> args) async {
  if (!Platform.isWindows) return;

  final _ = DynamicLibrary.open('kernel32.dll');
  final _ = DynamicLibrary.open('ntdll.dll');

  if (args.length == 2 && args[0] == '--child') {
    final handle = int.parse(args[1]);
    Expect.equals(null, handleType(HANDLE.fromAddress(handle)));
    return;
  }

  asyncStart();
  for (final mode in [ProcessStartMode.normal, ProcessStartMode.inheritStdio]) {
    await testHandleNotInherited(mode);
  }
  asyncEnd();
}
