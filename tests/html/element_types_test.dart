// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library element_types;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported_content', () {
    test('supported', () {
      expect(ContentElement.supported, true);
    });
  });

  group('supported_datalist', () {
    test('supported', () {
      expect(DataListElement.supported, true);
    });
  });

  group('supported_details', () {
    test('supported', () {
      expect(DetailsElement.supported, true);
    });
  });

  group('supported_embed', () {
    test('supported', () {
      expect(EmbedElement.supported, true);
    });
  });

  group('supported_keygen', () {
    test('supported', () {
      expect(KeygenElement.supported, true);
    });
  });

  group('supported_meter', () {
    test('supported', () {
      expect(MeterElement.supported, true);
    });
  });

  group('supported_object', () {
    test('supported', () {
      expect(ObjectElement.supported, true);
    });
  });

  group('supported_output', () {
    test('supported', () {
      expect(OutputElement.supported, true);
    });
  });

  group('supported_progress', () {
    test('supported', () {
      expect(ProgressElement.supported, true);
    });
  });

  group('supported_shadow', () {
    test('supported', () {
      expect(ShadowElement.supported, true);
    });
  });

  group('supported_template', () {
    test('supported', () {
      expect(TemplateElement.supported, true);
    });
  });

  group('supported_track', () {
    test('supported', () {
      expect(TrackElement.supported, true);
    });
  });
}
