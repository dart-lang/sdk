import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Position;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentChangesTest);
  });
}

@reflectiveTest
class DocumentChangesTest extends AbstractLspAnalysisServerTest {
  String get content => '''
class Foo {
  String get bar => 'baz';
}
''';

  String get contentAfterUpdate => '''
class Bar {
  String get bar => 'updated';
}
''';

  Future<void> test_documentChange_notifiesPlugins() async {
    await _initializeAndOpen();
    await changeFile(2, mainFileUri, [
      TextDocumentContentChangeEvent(
        Range(Position(0, 6), Position(0, 9)),
        0,
        'Bar',
      ),
      TextDocumentContentChangeEvent(
        Range(Position(1, 21), Position(1, 24)),
        0,
        'updated',
      ),
    ]);

    final notifiedChanges = pluginManager.analysisUpdateContentParams
        .files[mainFilePath] as ChangeContentOverlay;

    expect(
      applySequenceOfEdits(content, notifiedChanges.edits),
      contentAfterUpdate,
    );
  }

  Future<void> test_documentChange_updatesOverlay() async {
    await _initializeAndOpen();
    await changeFile(2, mainFileUri, [
      TextDocumentContentChangeEvent(
        Range(Position(0, 6), Position(0, 9)),
        0,
        'Bar',
      ),
      TextDocumentContentChangeEvent(
        Range(Position(1, 21), Position(1, 24)),
        0,
        'updated',
      ),
    ]);

    expect(server.resourceProvider.hasOverlay(mainFilePath), isTrue);
    expect(server.resourceProvider.getFile(mainFilePath).readAsStringSync(),
        equals(contentAfterUpdate));
  }

  Future<void> test_documentClose_deletesOverlay() async {
    await _initializeAndOpen();
    await closeFile(mainFileUri);

    expect(server.resourceProvider.hasOverlay(mainFilePath), isFalse);
  }

  Future<void> test_documentClose_notifiesPlugins() async {
    await _initializeAndOpen();
    await closeFile(mainFileUri);

    expect(pluginManager.analysisUpdateContentParams.files,
        equals({mainFilePath: RemoveContentOverlay()}));
  }

  Future<void> test_documentOpen_createsOverlay() async {
    await _initializeAndOpen();

    expect(server.resourceProvider.hasOverlay(mainFilePath), isTrue);
    expect(server.resourceProvider.getFile(mainFilePath).readAsStringSync(),
        equals(content));
  }

  Future<void> test_documentOpen_notifiesPlugins() async {
    await _initializeAndOpen();

    expect(pluginManager.analysisUpdateContentParams.files,
        equals({mainFilePath: AddContentOverlay(content)}));
  }

  Future<void> _initializeAndOpen() async {
    await initialize();
    await openFile(mainFileUri, content);
  }
}
