// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin_common;
import 'package:analyzer_plugin/protocol/protocol_generated.dart'
    as analyzer_plugin;
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(JsonTest);
    defineReflectiveTests(JsonWithConvertedFilePathsTest);
  });
}

@reflectiveTest
class JsonTest {
  final decoder = ResponseDecoder(null);

  void test_fromJson() {
    var json = {'offset': 0, 'length': 1, 'label': 'x'};
    var label = ClosingLabel.fromJson(
      decoder,
      '',
      json,
      clientUriConverter: null,
    );
    expect(label.label, 'x');
    expect(label.offset, 0);
    expect(label.length, 1);
  }

  void test_toJson() {
    var closingLabel = ClosingLabel(0, 1, 'x');
    var json = closingLabel.toJson(clientUriConverter: null);

    expect(json, {'offset': 0, 'length': 1, 'label': 'x'});
  }
}

@reflectiveTest
class JsonWithConvertedFilePathsTest with ResourceProviderMixin {
  final decoder = ResponseDecoder(null);
  late ClientUriConverter clientUriConverter;

  void setUp() {
    // These tests use a dummy encoder that just prefixes the FilePaths with
    // "Encoded" and "Decoded" to simplify testing. The real implementation will
    // convert between file paths and URI strings.
    clientUriConverter = _PrefixingUriConverter();
  }

  void tearDown() {
    // Because this is currently global, restore after the tests.
    clientUriConverter = ClientUriConverter.noop(pathContext);
  }

  void test_fromJson_filePath_list() {
    var json = {
      'files': ['/my/file/1', '/my/file/2'],
    };
    var params = AnalysisFlushResultsParams.fromJson(
      decoder,
      '',
      json,
      clientUriConverter: clientUriConverter,
    );
    expect(params.files, ['Decoded /my/file/1', 'Decoded /my/file/2']);
  }

  void test_fromJson_filePath_map_keyValue() {
    var json = {
      'included': [],
      'excluded': [],
      'packageRoots': {'/my/file/key': '/my/file/value'},
    };
    var params = AnalysisSetAnalysisRootsParams.fromJson(
      decoder,
      '',
      json,
      clientUriConverter: clientUriConverter,
    );
    expect(params.packageRoots, {
      'Decoded /my/file/key': 'Decoded /my/file/value',
    });
  }

  void test_fromJson_filePath_map_value_list() {
    var json = {
      'subscriptions': {
        'CLOSING_LABELS': ['/my/file/value'],
      },
    };
    var params = AnalysisSetSubscriptionsParams.fromJson(
      decoder,
      '',
      json,
      clientUriConverter: clientUriConverter,
    );
    expect(params.subscriptions, {
      AnalysisService.CLOSING_LABELS: ['Decoded /my/file/value'],
    });
  }

  void test_fromJson_filePath_nested() {
    var json = {
      'fixes': [
        {
          'error': {
            'severity': 'INFO',
            'type': 'LINT',
            'location': {
              'file': '/my/file',
              'offset': 0,
              'length': 1,
              'startLine': 2,
              'startColumn': 3,
            },
            'message': 'x',
            'code': 'y',
          },
          'fixes': [],
        },
      ],
    };
    var result = EditGetFixesResult.fromJson(
      decoder,
      '',
      json,
      clientUriConverter: clientUriConverter,
    );
    expect(result.fixes.single.error.location.file, 'Decoded /my/file');
  }

  void test_fromJson_filePath_topLevel() {
    var json = {'file': '/my/file', 'labels': []};
    var params = AnalysisClosingLabelsParams.fromJson(
      decoder,
      '',
      json,
      clientUriConverter: clientUriConverter,
    );
    expect(params.file, 'Decoded /my/file');
  }

  /// Verify that when a Path/URI encoder is set (done in [setUp]), it does not
  /// apply to common classes used within plugin protocol classes.
  void test_nestedCommonClasses_analyzerPlugin_noEncoder_fromJson_noDecoding() {
    var fixes = analyzer_plugin.AnalysisErrorFixes.fromJson(decoder, '', {
      'error': {
        'severity': 'ERROR',
        'type': 'COMPILE_TIME_ERROR',
        'location': {
          'file': '/my/file',
          'offset': 1,
          'length': 2,
          'startLine': 3,
          'startColumn': 4,
        },
        'message': 'message',
        'code': 'code',
      },
      'fixes': [],
    });
    // Expect file was not prefixed with "Decoded".
    expect(fixes.error.location.file, '/my/file');
  }

  /// Verify that when a Path/URI encoder is set (done in [setUp]), it does not
  /// apply to common classes used within plugin protocol classes.
  void test_nestedCommonClasses_analyzerPlugin_noEncoder_toJson_noEncoding() {
    var fixes = analyzer_plugin.AnalysisErrorFixes(
      plugin_common.AnalysisError(
        plugin_common.AnalysisErrorSeverity.ERROR,
        plugin_common.AnalysisErrorType.COMPILE_TIME_ERROR,
        plugin_common.Location('/my/file', 1, 2, 3, 4),
        'message',
        'code',
      ),
    );
    // Expect file was not prefixed with "Encoded".
    expect(
      (fixes.toJson() as dynamic)['error']['location']['file'],
      '/my/file',
    );
  }

  /// Verify that when a Path/URI encoder is set (done in [setUp]), it does
  /// apply to common classes used within server protocol classes.
  void test_nestedCommonClasses_server_withEncoder_fromJson_hasDecoding() {
    var fixes = server.AnalysisErrorFixes.fromJson(decoder, '', {
      'error': {
        'severity': 'ERROR',
        'type': 'COMPILE_TIME_ERROR',
        'location': {
          'file': '/my/file',
          'offset': 1,
          'length': 2,
          'startLine': 3,
          'startColumn': 4,
        },
        'message': 'message',
        'code': 'code',
      },
      'fixes': [],
    }, clientUriConverter: clientUriConverter);
    // Expect file was prefixed with "Decoded".
    expect(fixes.error.location.file, 'Decoded /my/file');
  }

  /// Verify that when a Path/URI encoder is set (done in [setUp]), it does
  /// apply to common classes used within server protocol classes.
  void test_nestedCommonClasses_server_withEncoder_toJson_hasEncoding() {
    var fixes = server.AnalysisErrorFixes(
      plugin_common.AnalysisError(
        plugin_common.AnalysisErrorSeverity.ERROR,
        plugin_common.AnalysisErrorType.COMPILE_TIME_ERROR,
        plugin_common.Location('/my/file', 1, 2, 3, 4),
        'message',
        'code',
      ),
    );
    // Expect file was prefixed with "Encoded".
    expect(
      (fixes.toJson(clientUriConverter: clientUriConverter)
          as dynamic)['error']['location']['file'],
      'Encoded /my/file',
    );
  }

  void test_toJson_list() {
    var params = AnalysisFlushResultsParams(['/my/file/1', '/my/file/2']);
    var json = params.toJson(clientUriConverter: clientUriConverter);

    expect(json, {
      'files': ['Encoded /my/file/1', 'Encoded /my/file/2'],
    });
  }

  void test_toJson_map_keyValue() {
    var params = AnalysisSetAnalysisRootsParams(
      [],
      [],
      packageRoots: {'/my/file/key': '/my/file/value'},
    );
    var json = params.toJson(clientUriConverter: clientUriConverter);
    expect(json, {
      'included': [],
      'excluded': [],
      'packageRoots': {'Encoded /my/file/key': 'Encoded /my/file/value'},
    });
  }

  void test_toJson_map_value_list() {
    var params = AnalysisSetSubscriptionsParams({
      AnalysisService.CLOSING_LABELS: ['/my/file/value'],
    });
    var json = params.toJson(clientUriConverter: clientUriConverter);
    expect(json, {
      'subscriptions': {
        'CLOSING_LABELS': ['Encoded /my/file/value'],
      },
    });
  }

  void test_toJson_nested() {
    var result = EditGetFixesResult([
      AnalysisErrorFixes(
        AnalysisError(
          AnalysisErrorSeverity.INFO,
          AnalysisErrorType.LINT,
          Location('/my/file', 0, 1, 2, 3),
          'x',
          'y',
        ),
      ),
    ]);
    var json = result.toJson(clientUriConverter: clientUriConverter);
    expect(json, {
      'fixes': [
        {
          'error': {
            'severity': 'INFO',
            'type': 'LINT',
            'location': {
              'file': 'Encoded /my/file',
              'offset': 0,
              'length': 1,
              'startLine': 2,
              'startColumn': 3,
            },
            'message': 'x',
            'code': 'y',
          },
          'fixes': [],
        },
      ],
    });
  }

  void test_toJson_topLevel() {
    var closingLabelParams = AnalysisClosingLabelsParams('/my/file', []);
    var json = closingLabelParams.toJson(
      clientUriConverter: clientUriConverter,
    );

    expect(json, {'file': 'Encoded /my/file', 'labels': []});
  }
}

/// A [ClientUriConverter] that just prefixes the input string for testing.
class _PrefixingUriConverter implements ClientUriConverter {
  @override
  String fromClientFilePath(String filePathOrUri) => 'Decoded $filePathOrUri';

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  String toClientFilePath(String filePath) => 'Encoded $filePath';
}
