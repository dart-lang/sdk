// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:_internal" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:core" hide Symbol;

import "dart:isolate" show SendPort;
import "dart:typed_data" show Int32List, Uint8List;

/// These are the additional parts of this patch library:
// part "class_id_fasta.dart";
// part "print_patch.dart";
// part "symbol_patch.dart";

// On the VM, we don't make the entire legacy weak mode check
// const to avoid having a constant in the platform libraries
// which evaluates differently in weak vs strong mode.
@patch
bool typeAcceptsNull<T>() => (const <Null>[]) is List<int> || null is T;

@patch
List<T> makeListFixedLength<T>(List<T> growableList)
    native "Internal_makeListFixedLength";

@patch
List<T> makeFixedListUnmodifiable<T>(List<T> fixedLengthList)
    native "Internal_makeFixedListUnmodifiable";

@patch
Object? extractTypeArguments<T>(T instance, Function extract)
    native "Internal_extractTypeArguments";

/// The returned string is a [_OneByteString] with uninitialized content.
@pragma("vm:recognized", "asm-intrinsic")
String allocateOneByteString(int length)
    native "Internal_allocateOneByteString";

/// The [string] must be a [_OneByteString]. The [index] must be valid.
@pragma("vm:recognized", "asm-intrinsic")
void writeIntoOneByteString(String string, int index, int codePoint)
    native "Internal_writeIntoOneByteString";

/// It is assumed that [from] is a native [Uint8List] class and [to] is a
/// [_OneByteString]. The [fromStart] and [toStart] indices together with the
/// [length] must specify ranges within the bounds of the list / string.
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
void copyRangeFromUint8ListToOneByteString(
    Uint8List from, String to, int fromStart, int toStart, int length) {
  for (int i = 0; i < length; i++) {
    writeIntoOneByteString(to, toStart + i, from[fromStart + i]);
  }
}

/// The returned string is a [_TwoByteString] with uninitialized content.
@pragma("vm:recognized", "asm-intrinsic")
String allocateTwoByteString(int length)
    native "Internal_allocateTwoByteString";

/// The [string] must be a [_TwoByteString]. The [index] must be valid.
@pragma("vm:recognized", "asm-intrinsic")
void writeIntoTwoByteString(String string, int index, int codePoint)
    native "Internal_writeIntoTwoByteString";

class VMLibraryHooks {
  // Example: "dart:isolate _Timer._factory"
  static var timerFactory;

  // Example: "dart:io _EventHandler._sendData"
  static var eventHandlerSendData;

  // A nullary closure that answers the current clock value in milliseconds.
  // Example: "dart:io _EventHandler._timerMillisecondClock"
  static var timerMillisecondClock;

  // Implementation of Resource.readAsBytes.
  static var resourceReadAsBytes;

  // Implementation of package root/map provision.
  static var packageRootString;
  static var packageConfigString;
  static var packageConfigUriFuture;
  static var resolvePackageUriFuture;

  static var _computeScriptUri;
  static var _cachedScript;
  static set platformScript(var f) {
    _computeScriptUri = f;
    _cachedScript = null;
  }

  static get platformScript {
    if (_cachedScript == null && _computeScriptUri != null) {
      _cachedScript = _computeScriptUri();
    }
    return _cachedScript;
  }
}

final bool is64Bit = _inquireIs64Bit();

bool _inquireIs64Bit() native "Internal_inquireIs64Bit";

@pragma("vm:recognized", "other")
@pragma("vm:entry-point", "call")
@pragma("vm:exact-result-type", bool)
@pragma("vm:prefer-inline")
bool _classRangeCheck(int cid, int lowerLimit, int upperLimit) {
  return cid >= lowerLimit && cid <= upperLimit;
}

// Utility class now only used by the VM.
class Lists {
  @pragma("vm:prefer-inline")
  static void copy(List src, int srcStart, List dst, int dstStart, int count) {
    if (srcStart < dstStart) {
      for (int i = srcStart + count - 1, j = dstStart + count - 1;
          i >= srcStart;
          i--, j--) {
        dst[j] = src[i];
      }
    } else {
      for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
        dst[j] = src[i];
      }
    }
  }
}

// Prepend the parent type arguments (maybe null) of length 'parentLen' to the
// function type arguments (may be null). The result is null if both input
// vectors are null or is a newly allocated and canonicalized vector of length
// 'totalLen'.
@pragma("vm:entry-point", "call")
_prependTypeArguments(functionTypeArguments, parentTypeArguments, parentLen,
    totalLen) native "Internal_prependTypeArguments";

// Check that a set of type arguments satisfy the type parameter bounds on a
// closure.
@pragma("vm:entry-point", "call")
_boundsCheckForPartialInstantiation(closure, typeArgs)
    native "Internal_boundsCheckForPartialInstantiation";

// Called by IRRegExpMacroAssembler::GrowStack.
Int32List _growRegExpStack(Int32List stack) {
  final newStack = new Int32List(stack.length * 2);
  for (int i = 0; i < stack.length; i++) {
    newStack[i] = stack[i];
  }
  return newStack;
}

// This function can be used to skip implicit or explicit checked down casts in
// the parts of the core library implementation where we know by construction the
// type of a value.
//
// Important: this is unsafe and must be used with care.
T unsafeCast<T>(Object? v) native "Internal_unsafeCast";

// This function can be used to keep an object alive til that point.
//
@pragma("vm:recognized", "other")
@pragma('vm:prefer-inline')
void reachabilityFence(Object object) native "Internal_reachabilityFence";

void sendAndExit(SendPort sendPort, var message)
    native "SendPortImpl_sendAndExitInternal_";

void spawnFunction(
    SendPort readyPort,
    String uri,
    Function topLevelFunction,
    var message,
    bool paused,
    bool errorsAreFatal,
    SendPort? onExit,
    SendPort? onError,
    String? packageConfig,
    bool newIsolateGroup,
    String? debugName) native "Isolate_spawnFunction";

// Collection of functions which should only be used for testing purposes.
abstract class VMInternalsForTesting {
  // This function can be used by tests to enforce garbage collection.
  static void collectAllGarbage() native "Internal_collectAllGarbage";
}

@patch
T createSentinel<T>() => throw UnsupportedError('createSentinel');

@patch
bool isSentinel(dynamic value) => throw UnsupportedError('isSentinel');

@patch
class LateError {
  @pragma("vm:entry-point")
  static _throwFieldAlreadyInitialized(String fieldName) {
    throw new LateError.fieldAI(fieldName);
  }

  @pragma("vm:entry-point")
  static _throwLocalNotInitialized(String localName) {
    throw new LateError.localNI(localName);
  }

  @pragma("vm:entry-point")
  static _throwLocalAlreadyInitialized(String localName) {
    throw new LateError.localAI(localName);
  }

  @pragma("vm:entry-point")
  static _throwLocalAssignedDuringInitialization(String localName) {
    throw new LateError.localADI(localName);
  }
}
