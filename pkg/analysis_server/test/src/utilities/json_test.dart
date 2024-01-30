// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart'
    show clientUriConverter;
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
    var json = {
      'offset': 0,
      'length': 1,
      'label': 'x',
    };
    var label = ClosingLabel.fromJson(decoder, '', json);
    expect(label.label, 'x');
    expect(label.offset, 0);
    expect(label.length, 1);
  }

  void test_toJson() {
    var closingLabel = ClosingLabel(0, 1, 'x');
    var json = closingLabel.toJson();

    expect(json, {
      'offset': 0,
      'length': 1,
      'label': 'x',
    });
  }
}

@reflectiveTest
class JsonWithConvertedFilePathsTest with ResourceProviderMixin {
  final decoder = ResponseDecoder(null);

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
      'files': ['/my/file/1', '/my/file/2']
    };
    var params = AnalysisFlushResultsParams.fromJson(decoder, '', json);
    expect(params.files, ['Decoded /my/file/1', 'Decoded /my/file/2']);
  }

  void test_fromJson_filePath_map_keyValue() {
    var json = {
      'included': [],
      'excluded': [],
      'packageRoots': {
        '/my/file/key': '/my/file/value',
      }
    };
    var params = AnalysisSetAnalysisRootsParams.fromJson(decoder, '', json);
    expect(params.packageRoots, {
      'Decoded /my/file/key': 'Decoded /my/file/value',
    });
  }

  void test_fromJson_filePath_map_value_list() {
    var json = {
      'subscriptions': {
        'CLOSING_LABELS': ['/my/file/value']
      }
    };
    var params = AnalysisSetSubscriptionsParams.fromJson(decoder, '', json);
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
              'startColumn': 3
            },
            'message': 'x',
            'code': 'y'
          },
          'fixes': []
        }
      ]
    };
    var result = EditGetFixesResult.fromJson(decoder, '', json);
    expect(result.fixes.single.error.location.file, 'Decoded /my/file');
  }

  void test_fromJson_filePath_topLevel() {
    var json = {'file': '/my/file', 'labels': []};
    var params = AnalysisClosingLabelsParams.fromJson(decoder, '', json);
    expect(params.file, 'Decoded /my/file');
  }

  void test_toJson_list() {
    var params = AnalysisFlushResultsParams(['/my/file/1', '/my/file/2']);
    var json = params.toJson();

    expect(
      json,
      {
        'files': ['Encoded /my/file/1', 'Encoded /my/file/2']
      },
    );
  }

  void test_toJson_map_keyValue() {
    var params = AnalysisSetAnalysisRootsParams(
      [],
      [],
      packageRoots: {
        '/my/file/key': '/my/file/value',
      },
    );
    var json = params.toJson();
    expect(json, {
      'included': [],
      'excluded': [],
      'packageRoots': {
        'Encoded /my/file/key': 'Encoded /my/file/value',
      }
    });
  }

  void test_toJson_map_value_list() {
    var params = AnalysisSetSubscriptionsParams(
      {
        AnalysisService.CLOSING_LABELS: ['/my/file/value'],
      },
    );
    var json = params.toJson();
    expect(json, {
      'subscriptions': {
        'CLOSING_LABELS': ['Encoded /my/file/value']
      }
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
      )
    ]);
    var json = result.toJson();
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
              'startColumn': 3
            },
            'message': 'x',
            'code': 'y'
          },
          'fixes': []
        }
      ]
    });
  }

  void test_toJson_topLevel() {
    var closingLabelParams = AnalysisClosingLabelsParams('/my/file', []);
    var json = closingLabelParams.toJson();

    expect(
      json,
      {'file': 'Encoded /my/file', 'labels': []},
    );
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
