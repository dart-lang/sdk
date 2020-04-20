// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Selection of methods used during bootstrapping.

// ignore_for_file: native_function_body_in_non_sdk_code
// ignore_for_file: unused_element, unused_field

// -----------------------------------------------------------------

void _printString(String s) native "Builtin_PrintString";

void _print(arg) {
  _printString(arg.toString());
}

_getPrintClosure() => _print;

// -----------------------------------------------------------------

typedef void _ScheduleImmediateClosure(void callback());

class _ScheduleImmediate {
  static _ScheduleImmediateClosure _closure;
}

void _setScheduleImmediateClosure(_ScheduleImmediateClosure closure) {
  _ScheduleImmediate._closure = closure;
}

// -----------------------------------------------------------------

class _NamespaceImpl implements _Namespace {
  _NamespaceImpl._();

  static _NamespaceImpl _create(_NamespaceImpl namespace, var n)
      native "Namespace_Create";
  static int _getPointer(_NamespaceImpl namespace)
      native "Namespace_GetPointer";
  static int _getDefault() native "Namespace_GetDefault";

  // If the platform supports "namespaces", this method is called by the
  // embedder with the platform-specific namespace information.
  static _NamespaceImpl _cachedNamespace = null;
  static void _setupNamespace(var namespace) {
    _cachedNamespace = _create(new _NamespaceImpl._(), namespace);
  }

  static _NamespaceImpl get _namespace {
    if (_cachedNamespace == null) {
      // The embedder has not supplied a namespace before one is needed, so
      // instead use a safe-ish default value.
      _cachedNamespace = _create(new _NamespaceImpl._(), _getDefault());
    }
    return _cachedNamespace;
  }

  static int get _namespacePointer => _getPointer(_namespace);
}

class _Namespace {
  static void _setupNamespace(var namespace) {
    _NamespaceImpl._setupNamespace(namespace);
  }

  static _Namespace get _namespace => _NamespaceImpl._namespace;

  static int get _namespacePointer => _NamespaceImpl._namespacePointer;
}

// -----------------------------------------------------------------

// These may be set to different values by the embedder by calling
// _setStdioFDs when initializing dart:io.
int _stdinFD = 0;
int _stdoutFD = 1;
int _stderrFD = 2;

// This is an embedder entrypoint.
void _setStdioFDs(int stdin, int stdout, int stderr) {
  _stdinFD = stdin;
  _stdoutFD = stdout;
  _stderrFD = stderr;
}

// -----------------------------------------------------------------

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

String _rawScript;
Uri _scriptUri() {
  if (_rawScript.startsWith('http:') ||
      _rawScript.startsWith('https:') ||
      _rawScript.startsWith('file:')) {
    return Uri.parse(_rawScript);
  } else {
    return Uri.base.resolveUri(new Uri.file(_rawScript));
  }
}

_setupHooks() {
  VMLibraryHooks.platformScript = _scriptUri;
}

class Stdin {}

Stdin _stdin;

class _StdIOUtils {
  static Stdin _getStdioInputStream(int fd) => null;
}

Stdin get stdin {
  _stdin ??= _StdIOUtils._getStdioInputStream(_stdinFD);
  return _stdin;
}

// -----------------------------------------------------------------

main() {}
