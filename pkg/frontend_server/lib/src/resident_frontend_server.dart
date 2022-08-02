// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.9
import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, InternetAddress, ServerSocket, Socket;
import 'dart:typed_data' show Uint8List;

import 'package:args/args.dart';

// front_end/src imports below that require lint `ignore_for_file`
// are a temporary state of things until frontend team builds better api
// that would replace api used below. This api was made private in
// an effort to discourage further use.
// ignore_for_file: implementation_imports
import 'package:front_end/src/api_unstable/vm.dart';

import '../frontend_server.dart';

extension on DateTime {
  /// Truncates by [amount]
  DateTime floorTime(Duration amount) {
    return DateTime.fromMillisecondsSinceEpoch(this.millisecondsSinceEpoch -
        this.millisecondsSinceEpoch % amount.inMilliseconds);
  }
}

enum _ResidentState {
  WAITING_FOR_FIRST_COMPILE,
  COMPILING,
  WAITING_FOR_RECOMPILE,
}

/// A wrapper around the FrontendCompiler, along with all the state needed
/// to perform incremental compilations
///
/// TODO: Fix the race condition that occurs when the ResidentCompiler returns
///   a kernel file to the CLI and another compilation request is given before
///   the VM is able to launch from the kernel that was returned in the first
///   compile request. The ResidentCompiler will be in the state of waiting for
///   a recompile request and will subsequently process the request and modify
///   the kernel file. However, it should be waiting for the VM to finish
///   launching itself from this kernel until it modifies the kernel.
///   As far as I can tell this race also exists in the current CLI run
///   command when using pub's precompile pipeline.
///
/// TODO Fix the race condition that occurs when the same entry point is
///   compiled concurrently.
class ResidentCompiler {
  File _entryPoint;
  File _outputDill;
  File _currentPackage;
  ArgResults _compileOptions;
  FrontendCompiler _compiler;
  DateTime _lastCompileStartTime =
      DateTime.now().floorTime(Duration(seconds: 1));
  _ResidentState _state = _ResidentState.WAITING_FOR_FIRST_COMPILE;
  final StringBuffer _compilerOutput = StringBuffer();
  final Set<Uri> trackedSources = <Uri>{};
  final List<String> _formattedOutput = <String>[];

  ResidentCompiler(this._entryPoint, this._outputDill, this._compileOptions) {
    _compiler = FrontendCompiler(_compilerOutput);
    updateState(_compileOptions);
  }

  /// The [ResidentCompiler] will use the [newOptions] for future compilation
  /// requests.
  void updateState(ArgResults newOptions) {
    final packages = newOptions['packages'];
    _compileOptions = newOptions;
    _currentPackage = packages == null ? null : File(packages);
    // Refresh the compiler's output for the next compile
    _compilerOutput.clear();
    _formattedOutput.clear();
    _state = _ResidentState.WAITING_FOR_FIRST_COMPILE;
  }

  /// Determines whether the current compile options are outdated with respect
  /// to the [newOptions]
  ///
  /// TODO: account for all compiler options. See vm/bin/kernel_service.dart:88
  bool areOptionsOutdated(ArgResults newOptions) {
    final packagesPath = newOptions['packages'];
    return (packagesPath != null && _currentPackage == null) ||
        (packagesPath == null && _currentPackage != null) ||
        (_currentPackage != null && _currentPackage.path != packagesPath) ||
        (_currentPackage != null &&
            !_lastCompileStartTime.isAfter(_currentPackage
                .statSync()
                .modified
                .floorTime(Duration(seconds: 1))));
  }

  /// Compiles the entry point that this ResidentCompiler is hooked to.
  /// Will perform incremental compilations when possible.
  /// If the options are outdated, must use updateState to get a correct
  /// compile.
  Future<String> compile() async {
    var incremental = false;

    // If this entrypoint was previously compiled on this compiler instance,
    // check which source files need to be recompiled in the incremental
    // compilation request. If no files have been modified, we can return
    // the cached kernel. Otherwise, perform an incremental compilation.
    if (_state == _ResidentState.WAITING_FOR_RECOMPILE) {
      var invalidatedUris =
          await _getSourceFilesToRecompile(_lastCompileStartTime);
      // No changes to source files detected and cached kernel file exists
      // If a kernel file is removed in between compilation requests,
      // fall through to procude the kernel in recompileDelta.
      if (invalidatedUris.isEmpty && _outputDill.existsSync()) {
        return _encodeCompilerOutput(
            _outputDill.path, _formattedOutput, _compiler.errors.length,
            usingCachedKernel: true);
      }
      _state = _ResidentState.COMPILING;
      incremental = true;
      invalidatedUris
          .forEach((invalidatedUri) => _compiler.invalidate(invalidatedUri));
      _compiler.errors.clear();
      _lastCompileStartTime = DateTime.now().floorTime(Duration(seconds: 1));
      await _compiler.recompileDelta(entryPoint: _entryPoint.path);
    } else {
      _state = _ResidentState.COMPILING;
      _lastCompileStartTime = DateTime.now().floorTime(Duration(seconds: 1));
      _compiler.errors.clear();
      await _compiler.compile(_entryPoint.path, _compileOptions);
    }

    _interpretCompilerOutput(LineSplitter()
        .convert(_compilerOutput.toString())
        .where((line) => line.isNotEmpty)
        .toList());
    _compilerOutput.clear();
    // forces the compiler to produce complete kernel files on each
    // request, even when incrementally compiled.
    _compiler
      ..acceptLastDelta()
      ..resetIncrementalCompiler();
    _state = _ResidentState.WAITING_FOR_RECOMPILE;

    return _encodeCompilerOutput(
        _outputDill.path, _formattedOutput, _compiler.errors.length,
        incrementalCompile: incremental);
  }

  /// Reads the compiler's [outputLines] to keep track of which files
  /// need to be tracked. Adds correctly ANSI formatted output to
  /// the [_formattedOutput] list.
  void _interpretCompilerOutput(List<String> outputLines) {
    _formattedOutput.clear();
    var outputLineIndex = 0;
    var acceptingErrorsOrVerboseOutput = true;
    final boundaryKey = outputLines[outputLineIndex]
        .substring(outputLines[outputLineIndex++].indexOf(' ') + 1);
    var line = outputLines[outputLineIndex++];

    while (acceptingErrorsOrVerboseOutput || !line.startsWith(boundaryKey)) {
      if (acceptingErrorsOrVerboseOutput) {
        if (line == boundaryKey) {
          acceptingErrorsOrVerboseOutput = false;
        } else {
          _formattedOutput.add(line);
        }
      } else {
        final diffUri = line.substring(1);
        if (line.startsWith('+')) {
          trackedSources.add(Uri.parse(diffUri));
        } else if (line.startsWith('-')) {
          trackedSources.remove(Uri.parse(diffUri));
        }
      }
      line = outputLines[outputLineIndex++];
    }
  }

  /// Returns a list of uris that need to be recompiled, based on the
  /// [lastkernelCompileTime] timestamp.
  /// Due to Windows timestamp granularity, all timestamps are truncated by
  /// the second. This has no effect on correctness but may result in more
  /// files being marked as invalid than are strictly required.
  Future<List<Uri>> _getSourceFilesToRecompile(
      DateTime lastKernelCompileTime) async {
    final sourcesToRecompile = <Uri>[];
    for (Uri uri in trackedSources) {
      final sourceModifiedTime = File(uri.toFilePath())
          .statSync()
          .modified
          .floorTime(Duration(seconds: 1));
      if (!lastKernelCompileTime.isAfter(sourceModifiedTime)) {
        sourcesToRecompile.add(uri);
      }
    }
    return sourcesToRecompile;
  }

  /// Encodes [outputDillPath] and any [formattedErrors] in JSON to
  /// be sent over the socket.
  static String _encodeCompilerOutput(
    String outputDillPath,
    List<String> formattedErrors,
    int errorCount, {
    bool usingCachedKernel = false,
    bool incrementalCompile = false,
  }) {
    return jsonEncode(<String, Object>{
      "success": errorCount == 0,
      "errorCount": errorCount,
      "compilerOutputLines": formattedErrors,
      "output-dill": outputDillPath,
      if (usingCachedKernel) "returnedStoredKernel": true, // used for testing
      if (incrementalCompile) "incremental": true, // used for testing
    });
  }
}

/// Maintains [FrontendCompiler] instances for kernel compilations, meant to be
/// used by the Dart CLI via sockets.
///
/// The [ResidentFrontendServer] manages compilation requests for VM targets
/// between any number of dart entrypoints, and utilizes incremental
/// compilation and existing kernel files for faster compile times.
///
/// Communication is handled on the socket set up by the
/// residentListenAndCompile method.
class ResidentFrontendServer {
  static const _commandString = 'command';
  static const _executableString = 'executable';
  static const _packageString = 'packages';
  static const _outputString = 'output-dill';
  static const _shutdownString = 'shutdown';
  static const _compilerLimit = 3;

  static final shutdownCommand =
      jsonEncode(<String, Object>{_commandString: _shutdownString});
  static final _shutdownJsonResponse =
      jsonEncode(<String, Object>{_shutdownString: true});
  static final _sdkBinariesUri = computePlatformBinariesLocation();
  static final _sdkUri = _sdkBinariesUri.resolve('../../');
  static final _platformKernelUri =
      _sdkBinariesUri.resolve('vm_platform_strong.dill');
  static final Map<String, ResidentCompiler> compilers = {};

  /// Takes in JSON [input] from the socket and compiles the request,
  /// using incremental compilation if possible. Returns a JSON string to be
  /// sent back to the client socket containing either an error message or the
  /// kernel file to be used.
  ///
  /// If the command is compile, paths the source file, package_config.json,
  /// and the output-dill file must be provided via "executable", "packages",
  /// and "output-dill".
  static Future<String> handleRequest(String input) async {
    Map<String, dynamic> request;
    try {
      request = jsonDecode(input);
    } on FormatException {
      return _encodeErrorMessage('$input is not valid JSON.');
    }

    switch (request[_commandString]) {
      case 'compile':
        if (request[_executableString] == null ||
            request[_outputString] == null) {
          return _encodeErrorMessage(
              'compilation requests must include an $_executableString and an $_outputString path.');
        }
        final executablePath = request[_executableString];
        final cachedDillPath = request[_outputString];
        final options = argParser.parse(<String>[
          '--sdk-root=${_sdkUri.toFilePath()}',
          '--incremental',
          if (request.containsKey(_packageString))
            '--packages=${request[_packageString]}',
          '--platform=${_platformKernelUri.path}',
          '--output-dill=$cachedDillPath',
          '--target=vm',
          '--filesystem-scheme',
          'org-dartlang-root',
          if (request['verbose'] == true) '--verbose',
        ]);

        var residentCompiler = compilers[executablePath];
        if (residentCompiler == null) {
          // Avoids using too much memory
          if (compilers.length >= ResidentFrontendServer._compilerLimit) {
            compilers.remove(compilers.keys.first);
          }
          residentCompiler = ResidentCompiler(
              File(executablePath), File(cachedDillPath), options);
          compilers[executablePath] = residentCompiler;
        } else if (residentCompiler.areOptionsOutdated(options)) {
          residentCompiler.updateState(options);
        }

        return await residentCompiler.compile();
      case 'shutdown':
        return _shutdownJsonResponse;
      default:
        return _encodeErrorMessage(
            'Unsupported command: ${request[_commandString]}.');
    }
  }

  /// Encodes the [message] in JSON to be sent over the socket.
  static String _encodeErrorMessage(String message) =>
      jsonEncode(<String, Object>{"success": false, "errorMessage": message});

  /// Used to create compile requests for the ResidentFrontendServer.
  /// Returns a JSON string that the resident compiler will be able to
  /// interpret.
  static String createCompileJSON(
      {String executable,
      String packages,
      String outputDill,
      bool verbose = false}) {
    return jsonEncode(<String, Object>{
      "command": "compile",
      "executable": executable,
      if (packages != null) "packages": packages,
      "output-dill": outputDill,
      "verbose": verbose,
    });
  }
}

/// Sends the JSON string [request] to the resident frontend server
/// and returns server's response in JSON
///
/// Clients must use this function when wanting to interact with a
/// ResidentFrontendServer instance.
Future<Map<String, dynamic>> sendAndReceiveResponse(
    InternetAddress address, int port, String request) async {
  try {
    final client = await Socket.connect(address, port);
    client.write(request);
    final data = await client.first;
    client.destroy();
    return jsonDecode(String.fromCharCodes(data));
  } catch (e) {
    return <String, Object>{"success": false, "errorMessage": e.toString()};
  }
}

/// Listens for compilation commands from socket connections on the
/// provided [address] and [port].
Future<StreamSubscription<Socket>> residentListenAndCompile(
    InternetAddress address, int port, File serverInfoFile) async {
  ServerSocket server;
  try {
    // TODO: have server shut itself off after period of inactivity
    server = await ServerSocket.bind(address, port);
    serverInfoFile
      ..writeAsStringSync(
          'address:${server.address.address} port:${server.port}');
  } catch (e) {
    print('Error: $e\n');
    return null;
  }
  print(
      'Resident Frontend Compiler is listening at ${server.address.address}:${server.port}');
  return server.listen((client) {
    client.listen((Uint8List data) async {
      String result = await ResidentFrontendServer.handleRequest(
          String.fromCharCodes(data));
      client.write(result);
      if (result == ResidentFrontendServer._shutdownJsonResponse) {
        if (serverInfoFile.existsSync()) {
          serverInfoFile.deleteSync();
        }
        await server.close();
      }
    }, onError: (error) {
      client.close();
    }, onDone: () {
      client.close();
    });
  }, onError: (_) {
    if (serverInfoFile.existsSync()) {
      serverInfoFile.deleteSync();
    }
  });
}
