import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final widgetsMediaQueryLibrary = MockLibraryUnit(
  'src/widgets/media_query.dart',
  r'''
class MediaQuery extends InheritedWidget {
  final MediaQueryData data;

  const MediaQuery({
    super.key,
    required this.data,
    required super.child,
  });

  static MediaQueryData of(BuildContext context) =>
      throw UnimplementedError();
}

class MediaQueryData {
  const MediaQueryData();
}
''',
);
