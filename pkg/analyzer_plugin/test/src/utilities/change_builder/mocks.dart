import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';

class MockAnalysisSession implements AnalysisSession {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockEditBuilderImpl implements EditBuilderImpl {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
