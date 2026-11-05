// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages/file_io_timing_page.dart';
import 'package:analyzer/src/file_system/timing_resource_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';
import 'test_socket_server.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileIoTimingPageTest);
  });
}

@reflectiveTest
class FileIoTimingPageTest extends PubPackageAnalysisServerTest {
  late FileIoTimingPage page;

  @override
  void setUp() {
    super.setUp();
    var site = DiagnosticsSite(TestSocketServer(server), []);
    page = site.pages.whereType<FileIoTimingPage>().single;
  }

  Future<void> test_accumulatesAcrossRefreshes() async {
    var file = newFile('$testPackageLibPath/test.dart', 'é');
    var timedFile = server.resourceProvider.getFile(file.path);
    timedFile.readAsBytesSync();
    timedFile.readAsStringSync();
    expect(timedFile.exists, isTrue);

    var html = await page.generate({});
    expect(html, contains('accumulated since startup'));
    expect(html, contains('File.readAsStringSync'));
    expect(html, contains('File.exists'));
    expect(html, contains('File.readAsBytesSync'));
    expect(html, contains('<td class="right">2</td>'));
    expect(html, contains('Time (ms)'));

    timedFile.readAsBytesSync();
    html = await page.generate({});
    expect(html, contains('<td class="right">4</td>'));
    expect(
      server
          .timingResourceProvider
          .timings[ResourceProviderOperation.fileReadAsBytesSync]!
          .count,
      2,
    );
  }

  Future<void> test_overlayIsExcluded() async {
    var file = newFile('$testPackageLibPath/test.dart', 'disk');
    var before =
        server
            .timingResourceProvider
            .timings[ResourceProviderOperation.fileReadAsStringSync]
            ?.count ??
        0;
    server.resourceProvider.setOverlay(
      file.path,
      content: 'editor',
      modificationStamp: 42,
    );
    expect(
      server.resourceProvider.getFile(file.path).readAsStringSync(),
      'editor',
    );
    await page.generate({});
    expect(
      server
              .timingResourceProvider
              .timings[ResourceProviderOperation.fileReadAsStringSync]
              ?.count ??
          0,
      before,
    );
  }
}
