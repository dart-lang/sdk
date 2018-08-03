// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library FormDataTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

void main() {
  // TODO(efortuna): This is a bad test. Revisit when we have tests that can run
  // both a server and fire up a browser.
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(FormData.supported, isTrue);
    });
  });

  group('functional', () {
    test('unsupported throws', () {
      var expectation = FormData.supported ? returnsNormally : throws;
      expect(() {
        new FormData();
      }, expectation);
    });

    var isFormData = predicate((x) => x is FormData, 'is a FormData');

    if (FormData.supported) {
      test('constructorTest1', () {
        var form = new FormData();
        expect(form, isNotNull);
        expect(form, isFormData);
      });

      test('constructorTest2', () {
        var form = new FormData(new FormElement());
        expect(form, isNotNull);
        expect(form, isFormData);
      });

      test('appendTest', () {
        var form = new FormData();
        form.append('test', '1');
        form.append('username', 'Elmo');
        form.append('address', '1 Sesame Street');
        form.append('password', '123456');
        expect(form, isNotNull);
      });

      test('appendBlob', () {
        var form = new FormData();
        var blob = new Blob(
            ['Indescribable... Indestructible! Nothing can stop it!'],
            'text/plain');
        form.appendBlob('theBlob', blob, 'theBlob.txt');
      });

      test('send', () {
        var form = new FormData();
        var blobString =
            'Indescribable... Indestructible! Nothing can stop it!';
        var blob = new Blob([blobString], 'text/plain');
        form.appendBlob('theBlob', blob, 'theBlob.txt');

        var xhr = new HttpRequest();
        xhr.open('POST',
            '${window.location.protocol}//${window.location.host}/echo');

        xhr.onLoad.listen(expectAsync((e) {
          expect(xhr.responseText, contains(blobString));
        }));
        xhr.onError.listen((e) {
          fail('$e');
        });
        xhr.send(form);
      });
    }
  });
}
