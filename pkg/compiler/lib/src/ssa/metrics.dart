import '../common/metrics.dart';

class SsaMetrics extends MetricsBase {
  final countMethodInlined = CountMetric('count.method.inlined');
  final countMethodNotInlined = CountMetric('count.method.notInlined');
  final countSpecializations = CountMetric('count.specializations');
  final countOperationFolded = CountMetric('count.operation.folded');
  final countLengthOptimized = CountMetric('count.length.optimized');
  final countFieldGetFolded = CountMetric('count.fieldGet.folded');
  final countIndexFolded = CountMetric('count.index.folded');
  final countGetLengthFolded = CountMetric('count.getLength.folded');
  final countGettersTotal = CountMetric('count.getters.total');
  final countGettersInlined = CountMetric('count.getters.inlined');
  final countGettersElided = CountMetric('count.getters.elided');
  final countSettersTotal = CountMetric('count.setters.total');
  final countSettersInlined = CountMetric('count.setters.inlined');
  final countSettersElided = CountMetric('count.setters.elided');
  final countConditionDecided = CountMetric('count.if.decided');
  final countIsTestDecided = CountMetric('count.isTest.decided');
  final countIsTestSimplified = CountMetric('count.isTest.simplified');
  final countLateSentinelCheckDecided =
      CountMetric('count.lateSentinel.decided');

  @override
  String get namespace => 'ssa';

  @override
  Iterable<Metric> get primary => [];

  @override
  Iterable<Metric> get secondary => [
        countMethodInlined,
        countMethodNotInlined,
        countSpecializations,
        countLengthOptimized,
        countFieldGetFolded,
        countIndexFolded,
        countGetLengthFolded,
        countGettersTotal,
        countGettersInlined,
        countGettersElided,
        countSettersTotal,
        countSettersInlined,
        countSettersElided,
        countConditionDecided,
        countIsTestDecided,
        countIsTestSimplified,
        countLateSentinelCheckDecided
      ];
}
