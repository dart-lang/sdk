// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:_internal" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:core" hide Symbol;

import "dart:typed_data" show Int32List;

/// These are the additional parts of this patch library:
// part "class_id_fasta.dart";
// part "print_patch.dart";
// part "symbol_patch.dart";

@patch
List<T> makeListFixedLength<T>(List<T> growableList)
    native "Internal_makeListFixedLength";

@patch
List<T> makeFixedListUnmodifiable<T>(List<T> fixedLengthList)
    native "Internal_makeFixedListUnmodifiable";

@patch
Object extractTypeArguments<T>(T instance, Function extract)
    native "Internal_extractTypeArguments";

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
  static var packageRootUriFuture;
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

@pragma("vm:entry-point")
@pragma("vm:exact-result-type", bool)
bool _classRangeCheck(int cid, int lowerLimit, int upperLimit) {
  return cid >= lowerLimit && cid <= upperLimit;
}

bool _classRangeCheckNegative(int cid, int lowerLimit, int upperLimit) {
  return cid < lowerLimit || cid > upperLimit;
}

// Utility class now only used by the VM.
class Lists {
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
@pragma("vm:entry-point")
_prependTypeArguments(functionTypeArguments, parentTypeArguments, parentLen,
    totalLen) native "Internal_prependTypeArguments";

// Check that a set of type arguments satisfy the type parameter bounds on a
// closure.
@pragma("vm:entry-point")
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
T unsafeCast<T>(Object v) native "Internal_unsafeCast";
