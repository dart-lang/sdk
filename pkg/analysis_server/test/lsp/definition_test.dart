// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart' as lsp;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefinitionTest);
  });
}

@reflectiveTest
class DefinitionTest extends AbstractLspAnalysisServerTest {
  Future<void> test_acrossFiles() async {
    final mainContents = '''
    import 'referenced.dart';

    main() {
      fo^o();
    }
    ''';

    final referencedContents = '''
    /// Ensure the function is on a line that
    /// does not exist in the mainContents file
    /// to ensure we're translating offsets to line/col
    /// using the correct file's LineInfo
    /// ...
    /// ...
    /// ...
    /// ...
    /// ...
    [[foo]]() {}
    ''';

    final referencedFileUri =
        Uri.file(join(projectFolderPath, 'lib', 'referenced.dart'));

    await initialize();
    await openFile(mainFileUri, withoutMarkers(mainContents));
    await openFile(referencedFileUri, withoutMarkers(referencedContents));
    final res = await getDefinitionAsLocation(
        mainFileUri, positionFromMarker(mainContents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(rangeFromMarkers(referencedContents)));
    expect(loc.uri, equals(referencedFileUri.toString()));
  }

  Future<void> test_comment_adjacentReference() async {
    /// Computing Dart navigation locates a node at the provided offset then
    /// returns all navigation regions inside it. This test ensures we filter
    /// out any regions that are in the same target node (the comment) but do
    /// not span the requested offset.
    final contents = '''
    /// Te^st
    ///
    /// References [String].
    main() {}
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    final res = await getDefinitionAsLocation(
        mainFileUri, positionFromMarker(contents));

    expect(res, hasLength(0));
  }

  Future<void> test_fromPlugins() async {
    final pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.foo');
    final pluginAnalyzedFileUri = Uri.file(pluginAnalyzedFilePath);
    final pluginResult = plugin.AnalysisGetNavigationResult(
      [pluginAnalyzedFilePath],
      [NavigationTarget(ElementKind.CLASS, 0, 0, 5, 0, 0)],
      [
        NavigationRegion(0, 5, [0])
      ],
    );
    configureTestPlugin(respondWith: pluginResult);

    newFile(pluginAnalyzedFilePath);
    await initialize();
    final res = await getDefinitionAsLocation(
        pluginAnalyzedFileUri, lsp.Position(line: 0, character: 0));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(
        loc.range,
        equals(lsp.Range(
            start: lsp.Position(line: 0, character: 0),
            end: lsp.Position(line: 0, character: 5))));
    expect(loc.uri, equals(pluginAnalyzedFileUri.toString()));
  }

  Future<void> test_locationLink_field() async {
    final mainContents = '''
    import 'referenced.dart';

    main() {
      Icons.[[ad^d]]();
    }
    ''';

    final referencedContents = '''
    void unrelatedFunction() {}

    class Icons {
      /// `targetRange` should not include the dartDoc but should include the full
      /// function body. `targetSelectionRange` will be just the name.
      [[String add = "Test"]];
    }

    void otherUnrelatedFunction() {}
    ''';

    final referencedFileUri =
        Uri.file(join(projectFolderPath, 'lib', 'referenced.dart'));

    await initialize(
        textDocumentCapabilities:
            withLocationLinkSupport(emptyTextDocumentClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(mainContents));
    await openFile(referencedFileUri, withoutMarkers(referencedContents));
    final res = await getDefinitionAsLocationLinks(
        mainFileUri, positionFromMarker(mainContents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(rangeFromMarkers(mainContents)));
    expect(loc.targetUri, equals(referencedFileUri.toString()));
    expect(loc.targetRange, equals(rangeFromMarkers(referencedContents)));
    expect(
      loc.targetSelectionRange,
      equals(rangeOfString(referencedContents, 'add')),
    );
  }

  Future<void> test_locationLink_function() async {
    final mainContents = '''
    import 'referenced.dart';

    main() {
      [[fo^o]]();
    }
    ''';

    final referencedContents = '''
    void unrelatedFunction() {}

    /// `targetRange` should not include the dartDoc but should include the full
    /// function body. `targetSelectionRange` will be just the name.
    [[void foo() {
      // Contents of function
    }]]

    void otherUnrelatedFunction() {}
    ''';

    final referencedFileUri =
        Uri.file(join(projectFolderPath, 'lib', 'referenced.dart'));

    await initialize(
        textDocumentCapabilities:
            withLocationLinkSupport(emptyTextDocumentClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(mainContents));
    await openFile(referencedFileUri, withoutMarkers(referencedContents));
    final res = await getDefinitionAsLocationLinks(
        mainFileUri, positionFromMarker(mainContents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(rangeFromMarkers(mainContents)));
    expect(loc.targetUri, equals(referencedFileUri.toString()));
    expect(loc.targetRange, equals(rangeFromMarkers(referencedContents)));
    expect(
      loc.targetSelectionRange,
      equals(rangeOfString(referencedContents, 'foo')),
    );
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize();

    final res = await getDefinitionAsLocation(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  /// Failing due to incorrect range because _DartNavigationCollector._getCodeLocation
  /// does not handle parts.
  @failingTest
  Future<void> test_part() async {
    final mainContents = '''
    import 'lib.dart';

    main() {
      Icons.[[ad^d]]();
    }
    ''';

    final libContents = '''
    part 'part.dart';
    ''';

    final partContents = '''
    part of 'lib.dart';

    void unrelatedFunction() {}

    class Icons {
      /// `targetRange` should not include the dartDoc but should include the full
      /// function body. `targetSelectionRange` will be just the name.
      [[String add = "Test"]];
    }

    void otherUnrelatedFunction() {}
    ''';

    final libFileUri = Uri.file(join(projectFolderPath, 'lib', 'lib.dart'));
    final partFileUri = Uri.file(join(projectFolderPath, 'lib', 'part.dart'));

    await initialize(
        textDocumentCapabilities:
            withLocationLinkSupport(emptyTextDocumentClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(mainContents));
    await openFile(libFileUri, withoutMarkers(libContents));
    await openFile(partFileUri, withoutMarkers(partContents));
    final res = await getDefinitionAsLocationLinks(
        mainFileUri, positionFromMarker(mainContents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(rangeFromMarkers(mainContents)));
    expect(loc.targetUri, equals(partFileUri.toString()));
    expect(loc.targetRange, equals(rangeFromMarkers(partContents)));
    expect(
      loc.targetSelectionRange,
      equals(rangeOfString(partContents, 'add')),
    );
  }

  Future<void> test_sameLine() async {
    final contents = '''
    int plusOne(int [[value]]) => 1 + val^ue;
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    final res = await getDefinitionAsLocation(
        mainFileUri, positionFromMarker(contents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(rangeFromMarkers(contents)));
    expect(loc.uri, equals(mainFileUri.toString()));
  }

  Future<void> test_singleFile() async {
    final contents = '''
    [[foo]]() {
      fo^o();
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    final res = await getDefinitionAsLocation(
        mainFileUri, positionFromMarker(contents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(rangeFromMarkers(contents)));
    expect(loc.uri, equals(mainFileUri.toString()));
  }

  Future<void> test_unopenFile() async {
    final contents = '''
    [[foo]]() {
      fo^o();
    }
    ''';

    newFile(mainFilePath, content: withoutMarkers(contents));
    await initialize();
    final res = await getDefinitionAsLocation(
        mainFileUri, positionFromMarker(contents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(rangeFromMarkers(contents)));
    expect(loc.uri, equals(mainFileUri.toString()));
  }

  Future<void> test_varKeyword() async {
    final contents = '''
    va^r a = MyClass();

    class [[MyClass]] {}
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    final res = await getDefinitionAsLocation(
        mainFileUri, positionFromMarker(contents));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(rangeFromMarkers(contents)));
    expect(loc.uri, equals(mainFileUri.toString()));
  }
}
