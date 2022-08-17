import '../common/metrics.dart';

class SsaMetrics extends MetricsBase {
  final countInlinesDone = CountMetric('count.inlines.done');
  final countInlinesSkipped = CountMetric('count.inlines.skipped');
  final countInlineConstantsDone = CountMetric('count.inlineConstants.done');
  final countInlineConstantsSkipped =
      CountMetric('count.inlineConstants.skipped');

  @override
  String get namespace => 'ssa';

  @override
  Iterable<Metric> get primary => [];

  @override
  Iterable<Metric> get secondary => [
        countInlinesDone,
        countInlinesSkipped,
        countInlineConstantsDone,
        countInlineConstantsSkipped
      ];
}
