// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:front_end/src/api_prototype/compilation_message.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/binary/limited_ast_to_binary.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/target/vm.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:vm/incremental_compiler.dart';
import 'package:web_socket_channel/io.dart';

main() {
  final platformKernel =
      computePlatformBinariesLocation().resolve('vm_platform_strong.dill');
  final sdkRoot = computePlatformBinariesLocation();
  final options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..strongMode = true
    ..target = new VmTarget(new TargetFlags(strongMode: true))
    ..linkedDependencies = <Uri>[platformKernel]
    ..reportMessages = true
    ..onError = (CompilationMessage error) {
      fail("Compilation error: ${error}");
    };

  group('basic', () {
    test('compile', () async {
      var systemTempDir = Directory.systemTemp;
      var file = new File('${systemTempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");

      IncrementalCompiler compiler = new IncrementalCompiler(options, file.uri);
      Program program = await compiler.compile();

      final StringBuffer buffer = new StringBuffer();
      new Printer(buffer, showExternal: false, showMetadata: true)
          .writeLibraryFile(program.mainMethod.enclosingLibrary);
      expect(
          buffer.toString(),
          equals('library;\n'
              'import self as self;\n'
              '\n'
              'static method main() → dynamic {}\n'));
    });
  });

  group('reload', () {
    test('picks up after rejected delta', () async {
      var systemTempDir = Directory.systemTemp;
      var file = new File('${systemTempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("import 'bar.dart';\n"
          "import 'baz.dart';\n"
          "main() {\n"
          "  new A();\n"
          "  openReceivePortSoWeWontDie();"
          "}\n");

      var fileBar = new File('${systemTempDir.path}/bar.dart')..createSync();
      fileBar.writeAsStringSync("class A<T> { int _a; }\n");

      var fileBaz = new File('${systemTempDir.path}/baz.dart')..createSync();
      fileBaz.writeAsStringSync("import 'dart:isolate';\n"
          "openReceivePortSoWeWontDie() { new RawReceivePort(); }\n");

      IncrementalCompiler compiler = new IncrementalCompiler(options, file.uri);
      Program program = await compiler.compile();

      File outputFile = new File('${systemTempDir.path}/foo.dart.dill');
      await _writeProgramToFile(program, outputFile);

      final List<String> vmArgs = [
        '--trace_reload',
        '--trace_reload_verbose',
        '--enable-vm-service=0', // Note: use 0 to avoid port collisions.
        '--pause_isolates_on_start',
        outputFile.path
      ];
      final vm = await Process.start(Platform.executable, vmArgs);

      final splitter = new LineSplitter();

      vm.exitCode.then((exitCode) {
        print("Compiler terminated with $exitCode exit code");
      });

      Completer<String> portLineCompleter = new Completer<String>();
      vm.stdout.transform(UTF8.decoder).transform(splitter).listen((String s) {
        print("vm stdout: $s");
        if (!portLineCompleter.isCompleted) {
          portLineCompleter.complete(s);
        }
      });

      vm.stderr
          .transform(UTF8.decoder)
          .transform(splitter)
          .toList()
          .then((err) {
        print(err.join('\n'));
        expect(err.isEmpty, isTrue,
            reason: "Should be no errors, but got ${err.join('\n')}");
      });

      String portLine = await portLineCompleter.future;

      final RegExp observatoryPortRegExp =
          new RegExp("Observatory listening on http://127.0.0.1:\([0-9]*\)/");
      expect(observatoryPortRegExp.hasMatch(portLine), isTrue);
      final match = observatoryPortRegExp.firstMatch(portLine);
      final port = int.parse(match.group(1));

      var remoteVm = new RemoteVm(port);
      await remoteVm.resume();
      compiler.accept();

      // Confirm that without changes VM reloads nothing.
      program = await compiler.compile();
      await _writeProgramToFile(program, outputFile);
      var reloadResult = await remoteVm.reload(new Uri.file(outputFile.path));
      expect(reloadResult['success'], isTrue);
      expect(reloadResult['details']['loadedLibraryCount'], equals(0));

      // Introduce a change that force VM to reject the change.
      fileBar.writeAsStringSync("class A<T,U> { int _a; }\n");
      compiler.invalidate(fileBar.uri);
      program = await compiler.compile();
      await _writeProgramToFile(program, outputFile);
      reloadResult = await remoteVm.reload(new Uri.file(outputFile.path));
      expect(reloadResult['success'], isFalse);

      // Fix a change so VM is happy to accept the change.
      fileBar.writeAsStringSync("class A<T> { int _a; hi() => _a; }\n");
      compiler.invalidate(fileBar.uri);
      program = await compiler.compile();
      await _writeProgramToFile(program, outputFile);
      reloadResult = await remoteVm.reload(new Uri.file(outputFile.path));
      expect(reloadResult['success'], isTrue);
      expect(reloadResult['details']['loadedLibraryCount'], equals(2));
      compiler.accept();

      vm.kill();
    });
  });
}

_writeProgramToFile(Program program, File outputFile) async {
  final IOSink sink = outputFile.openWrite();
  final BinaryPrinter printer = new LimitedBinaryPrinter(
      sink, (_) => true /* predicate */, false /* excludeUriToSource */);
  printer.writeProgramFile(program);
  await sink.close();
}

/// APIs to communicate with a remote VM via the VM's service protocol.
///
/// Only supports APIs to resume the program execution (when isolates are paused
/// at startup) and to trigger hot reloads.
class RemoteVm {
  /// Port used to connect to the vm service protocol, typically 8181.
  final int port;

  /// An peer point used to send service protocol messages. The service
  /// protocol uses JSON rpc on top of web-sockets.
  json_rpc.Peer get rpc => _rpc ??= _createPeer();
  json_rpc.Peer _rpc;

  /// The main isolate ID of the running VM. Needed to indicate to the VM which
  /// isolate to reload.
  FutureOr<String> get mainId async => _mainId ??= await _computeMainId();
  String _mainId;

  RemoteVm([this.port = 8181]);

  /// Establishes the JSON rpc connection.
  json_rpc.Peer _createPeer() {
    StreamChannel socket =
        new IOWebSocketChannel.connect('ws://127.0.0.1:$port/ws');
    var peer = new json_rpc.Peer(socket);
    peer.listen().then((_) {
      print('connection to vm-service closed');
      return disconnect();
    }).catchError((e) {
      print('error connecting to the vm-service');
      return disconnect();
    });
    return peer;
  }

  /// Retrieves the ID of the main isolate using the service protocol.
  Future<String> _computeMainId() async {
    var vm = await rpc.sendRequest('getVM');
    var isolates = vm['isolates'];
    for (var isolate in isolates) {
      if (isolate['name'].contains(r'$main')) {
        return isolate['id'];
      }
    }
    return isolates.first['id'];
  }

  /// Send a request to the VM to reload sources from [entryUri].
  ///
  /// This will establish a connection with the VM assuming it is running on the
  /// local machine and listening on [port] for service protocol requests.
  ///
  /// The result is the JSON map received from the reload request.
  Future<Map> reload(Uri entryUri) async {
    print("reload($entryUri)");
    var id = await mainId;
    print("got $id, sending reloadSources rpc request");
    var result = await rpc.sendRequest('reloadSources', {
      'isolateId': id,
      'rootLibUri': entryUri.toString(),
    });
    print("got rpc result $result");
    return result;
  }

  Future resume() async {
    var id = await mainId;
    await rpc.sendRequest('resume', {'isolateId': id});
  }

  /// Close any connections used to communicate with the VM.
  Future disconnect() async {
    if (_rpc == null) return null;
    this._mainId = null;
    if (!_rpc.isClosed) {
      var future = _rpc.close();
      _rpc = null;
      return future;
    }
    return null;
  }
}
