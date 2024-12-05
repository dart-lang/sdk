// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Selection of methods used during bootstrapping.

// ignore_for_file: unused_element, unused_field

// -----------------------------------------------------------------

external void _printString(String s);

void _print(arg) {
  _printString(arg.toString());
}

_getPrintClosure() => _print;

// -----------------------------------------------------------------

typedef _ScheduleImmediateClosure = void Function(void Function() callback);

class _ScheduleImmediate {
  static _ScheduleImmediateClosure? _closure;
}

void _setScheduleImmediateClosure(_ScheduleImmediateClosure closure) {
  _ScheduleImmediate._closure = closure;
}

// -----------------------------------------------------------------

base class _NamespaceImpl implements _Namespace {
  _NamespaceImpl._();

  external static _NamespaceImpl _create(_NamespaceImpl namespace, var n);
  external static int _getPointer(_NamespaceImpl namespace);
  external static int _getDefault();

  static _NamespaceImpl? _cachedNamespace = null;
  static void _setupNamespace(var namespace) {
    _cachedNamespace = _create(new _NamespaceImpl._(), namespace);
  }

  static _NamespaceImpl get _namespace {
    if (_cachedNamespace == null) {
      _cachedNamespace = _create(new _NamespaceImpl._(), _getDefault());
    }
    return _cachedNamespace!;
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

class Stdin {}

final Stdin _stdin = _StdIOUtils._getStdioInputStream(_stdinFD);

int _stdinFD = 0;
int _stdoutFD = 1;
int _stderrFD = 2;

void _setStdioFDs(int stdin, int stdout, int stderr) {
  _stdinFD = stdin;
  _stdoutFD = stdout;
  _stderrFD = stderr;
}

class _StdIOUtils {
  external static Stdin _getStdioInputStream(int fd);
}

// -----------------------------------------------------------------

class Timer {}

class SendPort {}

class VMLibraryHooks {
  // Example: "dart:isolate _Timer._factory"
  static Timer Function(int, void Function(Timer), bool)? timerFactory;

  // Example: "dart:io _EventHandler._sendData"
  static late void Function(Object?, SendPort, int) eventHandlerSendData;

  // A nullary closure that answers the current clock value in milliseconds.
  // Example: "dart:io _EventHandler._timerMillisecondClock"
  static late int Function() timerMillisecondClock;

  // Implementation of package root/map provision.
  static String? packageRootString;
  static String? packageConfigString;
  static Uri? Function()? packageConfigUriSync;
  static Uri? Function(Uri)? resolvePackageUriSync;

  static Uri Function()? _computeScriptUri;
  static Uri? _cachedScript;
  static set platformScript(Object? f) {
    _computeScriptUri = f as Uri Function()?;
    _cachedScript = null;
  }

  static Uri? get platformScript {
    return _cachedScript ??= _computeScriptUri?.call();
  }
}

// -----------------------------------------------------------------

main() {}
