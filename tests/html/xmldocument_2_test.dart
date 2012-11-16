library XmlDocument2Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('Document.query', () {
    Document doc = new DOMParser().parseFromString(
    '''<ResultSet>
         <Row>A</Row>
         <Row>B</Row>
         <Row>C</Row>
       </ResultSet>''','text/xml');

    var rs = doc.query('ResultSet');
    expect(rs, isNotNull);
  });
}
