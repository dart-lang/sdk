// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
  });
}

@reflectiveTest
class FormatTest extends AbstractLspAnalysisServerTest {
  Future<List<TextEdit>> expectFormattedContents(
      Uri uri, String original, String expected) async {
    final formatEdits = await formatDocument(uri.toString());
    final formattedContents = applyTextEdits(original, formatEdits);
    expect(formattedContents, equals(expected));
    return formatEdits;
  }

  Future<List<TextEdit>> expectRangeFormattedContents(
      Uri uri, String original, String expected) async {
    final formatEdits =
        await formatRange(uri.toString(), rangeFromMarkers(original));
    final formattedContents =
        applyTextEdits(withoutMarkers(original), formatEdits);
    expect(formattedContents, equals(expected));
    return formatEdits;
  }

  Future<void> test_alreadyFormatted() async {
    const contents = '''main() {
  print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, contents);

    final formatEdits = await formatDocument(mainFileUri.toString());
    expect(formatEdits, isNull);
  }

  Future<void> test_complex() async {
    const contents = '''
ErrorOr<Pair<A, List<B>>> c(
  String d,
  List<
          Either2<E,
              F>>
      g, {
  h = false,
}) {
}


    ''';
    final expected = '''
ErrorOr<Pair<A, List<B>>> c(
  String d,
  List<Either2<E, F>> g, {
  h = false,
}) {}
''';
    await initialize();
    await openFile(mainFileUri, contents);
    await expectFormattedContents(mainFileUri, contents, expected);
  }

  /// Ensures we use the same registration ID when unregistering even if the
  /// server has regenerated registrations multiple times.
  Future<void> test_dynamicRegistration_correctIdAfterMultipleChanges() async {
    final registrations = <Registration>[];
    // Provide empty config and collect dynamic registrations during
    // initialization.
    await provideConfig(
      () => monitorDynamicRegistrations(
        registrations,
        () => initialize(
            textDocumentCapabilities: withDocumentFormattingDynamicRegistration(
                emptyTextDocumentClientCapabilities),
            workspaceCapabilities:
                withDidChangeConfigurationDynamicRegistration(
                    withConfigurationSupport(
                        emptyWorkspaceClientCapabilities))),
      ),
      {},
    );

    Registration registration(Method method) =>
        registrationFor(registrations, method);

    // By default, the formatters should have been registered.
    expect(registration(Method.textDocument_formatting), isNotNull);
    expect(registration(Method.textDocument_onTypeFormatting), isNotNull);
    expect(registration(Method.textDocument_rangeFormatting), isNotNull);

    // Sending config updates causes the server to rebuild its list of registrations
    // which exposes a previous bug where we'd retain newly-built registrations
    // that may not have been sent to the client (because they had previously
    // been sent), resulting in the wrong ID being used for unregistration.
    await updateConfig({'foo1': true});
    await updateConfig({'foo1': null});

    // They should be unregistered if we change the config to disabled.
    await monitorDynamicUnregistrations(
      registrations,
      () => updateConfig({'enableSdkFormatter': false}),
    );
    expect(registration(Method.textDocument_formatting), isNull);
    expect(registration(Method.textDocument_onTypeFormatting), isNull);
    expect(registration(Method.textDocument_rangeFormatting), isNull);
  }

  Future<void> test_dynamicRegistration_forConfiguration() async {
    final registrations = <Registration>[];
    // Provide empty config and collect dynamic registrations during
    // initialization.
    await provideConfig(
      () => monitorDynamicRegistrations(
        registrations,
        () => initialize(
            textDocumentCapabilities: withDocumentFormattingDynamicRegistration(
                emptyTextDocumentClientCapabilities),
            workspaceCapabilities:
                withDidChangeConfigurationDynamicRegistration(
                    withConfigurationSupport(
                        emptyWorkspaceClientCapabilities))),
      ),
      {},
    );

    Registration registration(Method method) =>
        registrationFor(registrations, method);

    // By default, the formatters should have been registered.
    expect(registration(Method.textDocument_formatting), isNotNull);
    expect(registration(Method.textDocument_onTypeFormatting), isNotNull);
    expect(registration(Method.textDocument_rangeFormatting), isNotNull);

    // They should be unregistered if we change the config to disabled.
    await monitorDynamicUnregistrations(
      registrations,
      () => updateConfig({'enableSdkFormatter': false}),
    );
    expect(registration(Method.textDocument_formatting), isNull);
    expect(registration(Method.textDocument_onTypeFormatting), isNull);
    expect(registration(Method.textDocument_rangeFormatting), isNull);

    // They should be reregistered if we change the config to enabled.
    await monitorDynamicRegistrations(
      registrations,
      () => updateConfig({'enableSdkFormatter': true}),
    );
    expect(registration(Method.textDocument_formatting), isNotNull);
    expect(registration(Method.textDocument_onTypeFormatting), isNotNull);
    expect(registration(Method.textDocument_rangeFormatting), isNotNull);
  }

  Future<void> test_formatOnType_simple() async {
    const contents = '''
    main  ()
    {

        print('test');
    ^}
    ''';
    final expected = '''main() {
  print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));

    final formatEdits = await formatOnType(
        mainFileUri.toString(), positionFromMarker(contents), '}');
    expect(formatEdits, isNotNull);
    final formattedContents =
        applyTextEdits(withoutMarkers(contents), formatEdits);
    expect(formattedContents, equals(expected));
  }

  Future<void> test_formatRange_editsOverlapRange() async {
    // Only ranges that are fully contained by the range should be applied,
    // not those that intersect the start/end.
    const contents = '''
main()
{
    [[    print('test');
        print('test');
    ]]    print('test');
}
''';
    final expected = '''
main()
{
        print('test');
  print('test');
        print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    await expectRangeFormattedContents(mainFileUri, contents, expected);
  }

  Future<void> test_formatRange_invalidRange() async {
    const contents = '''
main()
{
        print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    final formatRangeRequest = formatRange(
      mainFileUri.toString(),
      Range(
          start: Position(line: 0, character: 0),
          end: Position(line: 10000, character: 0)),
    );
    await expectLater(formatRangeRequest,
        throwsA(isResponseError(ServerErrorCodes.InvalidFileLineCol)));
  }

  Future<void> test_formatRange_simple() async {
    const contents = '''
main  ()
{

    print('test');
}

[[main2  ()
{

    print('test');
}]]

main3  ()
{

    print('test');
}
''';
    final expected = '''
main  ()
{

    print('test');
}

main2() {
  print('test');
}

main3  ()
{

    print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(contents));
    await expectRangeFormattedContents(mainFileUri, contents, expected);
  }

  Future<void> test_invalidSyntax() async {
    const contents = '''main(((( {
  print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, contents);

    final formatEdits = await formatDocument(mainFileUri.toString());
    expect(formatEdits, isNull);
  }

  Future<void> test_lineLength() async {
    const contents = '''
    main() =>
    print(
    '123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789'
    );
    ''';
    final expectedDefault = '''main() => print(
    '123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789');\n''';
    final expectedLongLines =
        '''main() => print('123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789');\n''';

    // Initialize with config support, supplying an empty config when requested.
    await provideConfig(
      () => initialize(
          workspaceCapabilities: withDidChangeConfigurationDynamicRegistration(
              withConfigurationSupport(emptyWorkspaceClientCapabilities))),
      {}, // empty config
    );
    await openFile(mainFileUri, contents);

    await expectFormattedContents(mainFileUri, contents, expectedDefault);
    await updateConfig({'lineLength': 500});
    await expectFormattedContents(mainFileUri, contents, expectedLongLines);
  }

  Future<void> test_minimalEdits_addWhitespace() async {
    // Check we only get one edit to add the required whitespace and not
    // an entire document replacement.
    const contents = '''
main(){}
''';
    const expected = '''
main() {}
''';
    await initialize();
    await openFile(mainFileUri, contents);
    final formatEdits =
        await expectFormattedContents(mainFileUri, contents, expected);
    expect(formatEdits, hasLength(1));
    expect(formatEdits[0].newText, ' ');
    expect(formatEdits[0].range.start, equals(Position(line: 0, character: 6)));
  }

  Future<void> test_minimalEdits_removeFileLeadingWhitespace() async {
    // Check whitespace before the first token is handled.
    const contents = '''



main() {}
''';
    const expected = '''
main() {}
''';
    await initialize();
    await openFile(mainFileUri, contents);
    final formatEdits =
        await expectFormattedContents(mainFileUri, contents, expected);
    expect(formatEdits, hasLength(1));
    expect(formatEdits[0].newText, '');
    expect(formatEdits[0].range.start, equals(Position(line: 0, character: 0)));
    expect(formatEdits[0].range.end, equals(Position(line: 3, character: 0)));
  }

  Future<void> test_minimalEdits_removeFileTrailingWhitespace() async {
    // Check whitespace after the last token is handled.
    const contents = '''
main() {}




''';
    const expected = '''
main() {}
''';
    await initialize();
    await openFile(mainFileUri, contents);
    final formatEdits =
        await expectFormattedContents(mainFileUri, contents, expected);
    expect(formatEdits, hasLength(1));
    expect(formatEdits[0].newText, '');
    expect(formatEdits[0].range.start, equals(Position(line: 1, character: 0)));
    expect(formatEdits[0].range.end, equals(Position(line: 5, character: 0)));
  }

  Future<void> test_minimalEdits_removePartialWhitespaceAfter() async {
    // Check we get an edit only to remove the unnecessary trailing whitespace
    // and not to replace the whole whitespace with a single space.
    const contents = '''
main()       {}
''';
    const expected = '''
main() {}
''';
    await initialize();
    await openFile(mainFileUri, contents);
    final formatEdits =
        await expectFormattedContents(mainFileUri, contents, expected);
    expect(formatEdits, hasLength(1));
    expect(
        formatEdits[0],
        equals(TextEdit(
          range: Range(
              start: Position(line: 0, character: 7),
              end: Position(line: 0, character: 13)),
          newText: '',
        )));
  }

  Future<void> test_minimalEdits_removePartialWhitespaceBefore() async {
    // Check we get an edit only to remove the unnecessary leading whitespace
    // and not to replace the whole whitespace with a single space.
    const contents = '''
main()


 {}
''';
    const expected = '''
main() {}
''';
    await initialize();
    await openFile(mainFileUri, contents);
    final formatEdits =
        await expectFormattedContents(mainFileUri, contents, expected);
    expect(formatEdits, hasLength(1));
    expect(
        formatEdits[0],
        equals(TextEdit(
          range: Range(
              start: Position(line: 0, character: 6),
              end: Position(line: 3, character: 0)),
          newText: '',
        )));
  }

  Future<void> test_minimalEdits_removeWhitespace() async {
    // Check we only get two edits to remove the unwanted whitespace and not
    // an entire document replacement.
    const contents = '''
main( ) { }
''';
    const expected = '''
main() {}
''';
    await initialize();
    await openFile(mainFileUri, contents);
    final formatEdits =
        await expectFormattedContents(mainFileUri, contents, expected);
    expect(formatEdits, hasLength(2));
    expect(formatEdits[0].newText, isEmpty);
    expect(formatEdits[0].range.start, equals(Position(line: 0, character: 5)));
    expect(formatEdits[1].newText, isEmpty);
    expect(formatEdits[1].range.start, equals(Position(line: 0, character: 9)));
  }

  Future<void> test_minimalEdits_withComments() async {
    // Check we can get edits that span a comment (which does not appear in the
    // main token list).
    const contents = '''
main() {
        var a = 1;
        // Comment
        print(a);
}
''';
    const expected = '''
main() {
  var a = 1;
  // Comment
  print(a);
}
''';
    await initialize();
    await openFile(mainFileUri, contents);
    final formatEdits =
        await expectFormattedContents(mainFileUri, contents, expected);
    expect(formatEdits, hasLength(3));
    expect(
        formatEdits[0],
        equals(TextEdit(
          range: Range(
              start: Position(line: 1, character: 2),
              end: Position(line: 1, character: 8)),
          newText: '',
        )));
    expect(
        formatEdits[1],
        equals(TextEdit(
          range: Range(
              start: Position(line: 2, character: 2),
              end: Position(line: 2, character: 8)),
          newText: '',
        )));
    expect(
        formatEdits[2],
        equals(TextEdit(
          range: Range(
              start: Position(line: 3, character: 2),
              end: Position(line: 3, character: 8)),
          newText: '',
        )));
  }

  Future<void> test_nonDartFile() async {
    await initialize();
    await openFile(pubspecFileUri, simplePubspecContent);

    final formatEdits =
        await formatOnType(pubspecFileUri.toString(), startOfDocPos, '}');
    expect(formatEdits, isNull);
  }

  Future<void> test_path_doesNotExist() async {
    await initialize();

    await expectLater(
      formatDocument(
          Uri.file(join(projectFolderPath, 'missing.dart')).toString()),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)),
    );
  }

  Future<void> test_path_invalidFormat() async {
    await initialize();

    await expectLater(
      // Add some invalid path characters to the end of a valid file:// URI.
      formatDocument(mainFileUri.toString() + '***.dart'),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)),
    );
  }

  Future<void> test_path_notFileScheme() async {
    await initialize();

    await expectLater(
      formatDocument('a:/a.dart'),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)),
    );
  }

  Future<void> test_simple() async {
    const contents = '''
    main  ()
    {

        print('test');
    }
    ''';
    final expected = '''main() {
  print('test');
}
''';
    await initialize();
    await openFile(mainFileUri, contents);
    await expectFormattedContents(mainFileUri, contents, expected);
  }

  Future<void> test_unopenFile() async {
    const contents = '''
    main  ()
    {

        print('test');
    }
    ''';
    final expected = '''main() {
  print('test');
}
''';
    newFile(mainFilePath, content: contents);
    await initialize();
    await expectFormattedContents(mainFileUri, contents, expected);
  }

  Future<void> test_validSyntax_withErrors() async {
    // We should still be able to format syntactically valid code even if it has analysis
    // errors.
    const contents = '''main() {
       print(a);
}
''';
    const expected = '''main() {
  print(a);
}
''';
    await initialize();
    await openFile(mainFileUri, contents);

    await expectFormattedContents(mainFileUri, contents, expected);
  }
}
