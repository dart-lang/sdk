import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingTextSpanLibrary = MockLibraryUnit(
  'src/painting/text_span.dart',
  r'''
class TextSpan {
  final String? text;
  final List<TextSpan>? children;

  const TextSpan({this.text, this.children});
}
''',
);
