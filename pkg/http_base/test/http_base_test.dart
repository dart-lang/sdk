library http_base.http_base_test;

import 'package:http_base/http_base.dart';
import 'package:unittest/unittest.dart';

main() {
  group('headers-impl', () {
    test('empty', () {
      for (HeadersImpl emptyHeaders in [HeadersImpl.Empty,
                                        new HeadersImpl({})]) {
        expect(emptyHeaders.names, isEmpty);
        expect(emptyHeaders['foo'], isNull);
        expect(emptyHeaders.getMultiple('foo'), isNull);
      }
    });

    test('multi-value', () {
      var headers = new HeadersImpl({
        'Single' : 'single-value',
        'Mul' : ['mul-1', 'mul-2', 'mul-3,mul-4'],
        'Mul-Inline' : 'mi-1,mi-2,mi-3',
      });

      expect(headers.names, hasLength(3));
      expect(headers.names, contains('single'));
      expect(headers.names, contains('mul'));
      expect(headers.names, contains('mul-inline'));

      for (var key in ['Single', 'single']) {
        expect(headers[key], equals('single-value'));
        expect(headers.getMultiple(key), equals(['single-value']));
      }

      for (var key in ['Mul', 'mul']) {
        expect(headers[key], equals('mul-1,mul-2,mul-3,mul-4'));
        expect(headers.getMultiple(key),
               equals(['mul-1','mul-2','mul-3','mul-4']));
      }

      for (var key in ['Mul-Inline', 'mul-inline']) {
        expect(headers[key], equals('mi-1,mi-2,mi-3'));
        expect(headers.getMultiple(key), equals(['mi-1','mi-2','mi-3']));
      }
    });

    test('cookie-headers', () {
      var headers = new HeadersImpl({
        'Set-Cookie' : [
            'lang=en-US; Expires=Wed, 09 Jun 2021 10:18:14 GMT',
            'lang=de-DE; Expires=Wed, 09 Jun 2021 10:18:14 GMT',],
        'Cookie' : ['name1=value1; name2=value2', 'name3=value3'],
      });

      expect(() => headers['set-cookie'], throwsArgumentError);
      expect(() => headers['cookie'], throwsArgumentError);

      expect(headers.getMultiple('set-cookie').toList(), equals([
          'lang=en-US; Expires=Wed, 09 Jun 2021 10:18:14 GMT',
          'lang=de-DE; Expires=Wed, 09 Jun 2021 10:18:14 GMT']));

      expect(headers.getMultiple('cookie').toList(),
             equals(['name1=value1; name2=value2', 'name3=value3']));
    });

    test('replace', () {
      var headers = new HeadersImpl({
        'Single' : 'single-value',
        'Mul' : ['mul-1', 'mul-2', 'mul-3,mul-4'],
        'Mul-Inline' : 'mi-1,mi-2,mi-3',
      }).replace({
        'single' : 'foo',
        'mul' : null,
        'mul-inline' : 'bar',
      });

      expect(headers.names, hasLength(2));
      expect(headers['single'], equals('foo'));
      expect(headers['mul-inline'], equals('bar'));
    });
  });
}
