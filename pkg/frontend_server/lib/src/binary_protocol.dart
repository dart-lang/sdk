// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.15
import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/compiler/request_channel.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart' as fe;
import 'package:front_end/src/api_prototype/file_system.dart' as fe;
import 'package:front_end/src/api_prototype/kernel_generator.dart' as fe;
import 'package:front_end/src/fasta/kernel/utils.dart' as fe;
import 'package:kernel/ast.dart' as fe;
import 'package:kernel/target/targets.dart' as fe;
import 'package:vm/kernel_front_end.dart' as vm;
import 'package:vm/target/vm.dart' as vm;

Future<void> runBinaryProtocol(String addressStr) async {
  final parsedAddress = _ParsedAddress.parse(addressStr);
  final socket = await io.Socket.connect(
    parsedAddress.host,
    parsedAddress.port,
  );

  _Client(
    RequestChannel(socket),
    () {
      socket.destroy();
    },
  );
}

class _Client {
  final RequestChannel _channel;
  final void Function() _stopHandler;
  final Map<Uri, Uint8List> _dills = {};

  _Client(this._channel, this._stopHandler) {
    _channel.add('dill.put', _dillPut);
    _channel.add('dill.remove', _dillRemove);
    _channel.add('exit', _exit);
    _channel.add('kernelForModule', _kernelForModule);
    _channel.add('kernelForProgram', _kernelForProgram);
    _channel.add('stop', _stop);
  }

  Future<void> _dillPut(Object? argumentObject) async {
    final arguments = argumentObject.argumentAsMap;
    final uriStr = arguments.required<String>('uri');
    final bytes = arguments.required<Uint8List>('bytes');

    final uri = Uri.parse(uriStr);
    _dills[uri] = bytes;
  }

  Future<void> _dillRemove(Object? argumentObject) async {
    final arguments = argumentObject.argumentAsMap;
    final uriStr = arguments.required<String>('uri');

    final uri = Uri.parse(uriStr);
    _dills.remove(uri);
  }

  Future<void> _exit(Object? argument) async {
    io.exit(0);
  }

  fe.CompilerOptions _getCompilerOptions(Map<Object?, Object?> arguments) {
    final sdkSummaryUriStr = arguments.required<String>('sdkSummary');

    final compilerOptions = fe.CompilerOptions()
      ..environmentDefines = {}
      ..fileSystem = _FileSystem(_channel, _dills)
      ..sdkSummary = Uri.parse(sdkSummaryUriStr)
      ..target = vm.VmTarget(fe.TargetFlags(enableNullSafety: true));

    final additionalDills = arguments['additionalDills'].asListOf<String>();
    if (additionalDills != null) {
      compilerOptions.additionalDills.addAll(
        additionalDills.map(Uri.parse),
      );
    }

    return compilerOptions;
  }

  Future<Object?> _kernelForModule(Object? argumentObject) async {
    final arguments = argumentObject.argumentAsMap;
    final packagesFileUriStr = arguments.required<String>('packagesFileUri');

    final compilerOptions = _getCompilerOptions(arguments)
      ..packagesFileUri = Uri.parse(packagesFileUriStr);

    final uriStrList = arguments['uris'].asListOf<String>();
    if (uriStrList == null) {
      throw ArgumentError('Missing field: uris');
    }

    final compilationResults = await fe.kernelForModule(
      uriStrList.map(Uri.parse).toList(),
      compilerOptions,
    );

    return _serializeComponentWithoutPlatform(
      compilationResults.component!,
    );
  }

  Future<Object?> _kernelForProgram(Object? argumentObject) async {
    final arguments = argumentObject.argumentAsMap;

    final compilerOptions = _getCompilerOptions(arguments);

    final packagesFileUriStr = arguments.optional<String>('packagesFileUri');
    if (packagesFileUriStr != null) {
      compilerOptions.packagesFileUri = Uri.parse(packagesFileUriStr);
    }

    final uriStr = arguments.required<String>('uri');

    final compilationResults = await vm.compileToKernel(
      Uri.parse(uriStr),
      compilerOptions,
      environmentDefines: {},
    );

    return _serializeComponentWithoutPlatform(
      compilationResults.component!,
    );
  }

  Future<void> _stop(Object? argument) async {
    _stopHandler();
  }

  static Uint8List _serializeComponentWithoutPlatform(fe.Component component) {
    return fe.serializeComponent(
      component,
      filter: (library) {
        return !library.importUri.isScheme('dart');
      },
      includeSources: false,
    );
  }
}

class _FileSystem implements fe.FileSystem {
  final RequestChannel _channel;
  final Map<Uri, Uint8List> _dills;

  _FileSystem(this._channel, this._dills);

  @override
  fe.FileSystemEntity entityForUri(Uri uri) {
    return _FileSystemEntity(this, uri);
  }
}

class _FileSystemEntity implements fe.FileSystemEntity {
  final _FileSystem _fileSystem;

  @override
  final Uri uri;

  _FileSystemEntity(this._fileSystem, this.uri);

  RequestChannel get _channel => _fileSystem._channel;

  String get _uriStr => uri.toString();

  @override
  Future<bool> exists() async {
    if (_fileSystem._dills.containsKey(uri)) {
      return true;
    }
    return _channel.sendRequest<bool>('file.exists', _uriStr);
  }

  @override
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  Future<List<int>> readAsBytes() async {
    final storedBytes = _fileSystem._dills[uri];
    if (storedBytes != null) {
      return storedBytes;
    }

    return _channel.sendRequest<Uint8List>('file.readAsBytes', _uriStr);
  }

  @override
  Future<List<int>> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  Future<String> readAsString() async {
    return _channel.sendRequest<String>('file.readAsString', _uriStr);
  }
}

class _ParsedAddress {
  final String host;
  final int port;

  factory _ParsedAddress.parse(String str) {
    final colonOffset = str.lastIndexOf(':');
    if (colonOffset == -1) {
      throw FormatException("Expected ':' in: $str");
    }

    return _ParsedAddress._(
      str.substring(0, colonOffset),
      int.parse(str.substring(colonOffset + 1)),
    );
  }

  _ParsedAddress._(this.host, this.port);
}

extension on Object? {
  Map<Object?, Object?> get argumentAsMap {
    final self = this;
    if (self is Map<Object?, Object?>) {
      return self;
    }
    throw ArgumentError('The argument must be a map.');
  }
}

extension on Map<Object?, Object?> {
  T? optional<T extends Object>(String name) {
    final value = this[name];
    if (value == null) {
      return null;
    }
    if (value is T) {
      return value;
    }
    throw ArgumentError('Must be null or $T: $name');
  }

  T required<T>(String name) {
    final value = this[name];
    if (value is T) {
      return value;
    }
    throw ArgumentError('Must be $T: $name');
  }
}

extension on Object? {
  List<T>? asListOf<T>() {
    final self = this;
    if (self is List<Object?>) {
      final result = <T>[];
      for (final element in self) {
        if (element is T) {
          result.add(element);
        } else {
          return null;
        }
      }
      return result;
    }
    return null;
  }
}
