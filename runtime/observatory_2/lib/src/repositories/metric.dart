// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class Metric implements M.Metric {
  final String id;
  String get name => internal.name;
  String get description => internal.description;
  final internal;

  Metric(this.id, this.internal);
}

class MetricSample implements M.MetricSample {
  final double value;
  final DateTime time = new DateTime.now();
  MetricSample(this.value);
}

class MetricRepository implements M.MetricRepository {
  final Map<S.Isolate, Map<Metric, List<M.MetricSample>>> _samples =
      <S.Isolate, Map<Metric, List<M.MetricSample>>>{};
  final Map<S.Isolate, Map<Metric, int>> _rates =
      <S.Isolate, Map<Metric, int>>{};
  final Map<S.Isolate, Map<Metric, int>> _sizes =
      <S.Isolate, Map<Metric, int>>{};
  Timer _timer;
  int count = 0;

  Future<Iterable<Metric>> list(M.IsolateRef i) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    if (_samples.containsKey(isolate)) {
      return _samples[isolate].keys;
    }
    return const [];
  }

  Future startSampling(M.IsolateRef i) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    if (!_samples.containsKey(isolate)) {
      await isolate.refreshMetrics();
      final samples = _samples[isolate] = <Metric, List<M.MetricSample>>{};
      final rates = _rates[isolate] = <Metric, int>{};
      final sizes = _sizes[isolate] = <Metric, int>{};
      final metrics = []
        ..addAll(isolate.dartMetrics.keys
            .map((name) => new Metric(name, isolate.dartMetrics[name]))
            .toList())
        ..addAll(isolate.nativeMetrics.keys
            .map((name) => new Metric(name, isolate.nativeMetrics[name]))
            .toList());
      for (final metric in metrics) {
        samples[metric] = [new MetricSample(metric.internal.value)];
        rates[metric] = _rateToInteger(M.MetricSamplingRate.off);
        sizes[metric] = _sizeToInteger(M.MetricBufferSize.n100samples);
      }
      if (_samples.length == 1) {
        count = 0;
        _timer = new Timer.periodic(new Duration(milliseconds: 100), _update);
      }
    }
  }

  Future stopSampling(M.IsolateRef isolate) async {
    if (_samples.containsKey(isolate)) {
      _samples.remove(isolate);
      _rates.remove(isolate);
      _sizes.remove(isolate);
      if (_samples.isEmpty) {
        _timer.cancel();
      }
    }
  }

  M.MetricSamplingRate getSamplingRate(M.IsolateRef i, M.Metric m) {
    if (_rates.containsKey(i)) {
      final metrics = _rates[i];
      if (metrics.containsKey(m)) {
        switch (metrics[m]) {
          case 0:
            return M.MetricSamplingRate.off;
          case 1:
            return M.MetricSamplingRate.e100ms;
          case 10:
            return M.MetricSamplingRate.e1s;
          case 20:
            return M.MetricSamplingRate.e2s;
          case 40:
            return M.MetricSamplingRate.e4s;
          case 80:
            return M.MetricSamplingRate.e8s;
        }
      }
    }
    throw new Exception('Sampling for isolate ${i.id} is not started');
  }

  void setSamplingRate(M.IsolateRef i, M.Metric m, M.MetricSamplingRate r) {
    if (_rates.containsKey(i)) {
      final metrics = _rates[i];
      if (metrics.containsKey(m)) {
        metrics[m] = _rateToInteger(r);
      }
    } else {
      throw new Exception('Sampling for isolate ${i.id} is not started');
    }
  }

  M.MetricBufferSize getBufferSize(M.IsolateRef i, M.Metric m) {
    if (_sizes.containsKey(i)) {
      final metrics = _sizes[i];
      if (metrics.containsKey(m)) {
        switch (metrics[m]) {
          case 10:
            return M.MetricBufferSize.n10samples;
          case 100:
            return M.MetricBufferSize.n100samples;
          case 1000:
            return M.MetricBufferSize.n1000samples;
        }
      }
    }
    throw new Exception('Sampling for isolate ${i.id} is not started');
  }

  void setBufferSize(M.IsolateRef i, M.Metric m, M.MetricBufferSize s) {
    if (_sizes.containsKey(i)) {
      final metrics = _sizes[i];
      if (metrics.containsKey(m)) {
        metrics[m] = _sizeToInteger(s);
      }
    } else {
      throw new Exception('Sampling for isolate ${i.id} is not started');
    }
  }

  static int _rateToInteger(M.MetricSamplingRate r) {
    switch (r) {
      case M.MetricSamplingRate.off:
        return 0;
      case M.MetricSamplingRate.e100ms:
        return 1;
      case M.MetricSamplingRate.e1s:
        return 10;
      case M.MetricSamplingRate.e2s:
        return 20;
      case M.MetricSamplingRate.e4s:
        return 40;
      case M.MetricSamplingRate.e8s:
        return 80;
    }
    throw new Exception('Unknown MetricSamplingRate ($r)');
  }

  static int _sizeToInteger(M.MetricBufferSize s) {
    switch (s) {
      case M.MetricBufferSize.n10samples:
        return 10;
      case M.MetricBufferSize.n100samples:
        return 100;
      case M.MetricBufferSize.n1000samples:
        return 1000;
    }
    throw new Exception('Unknown MetricBufferSize ($s)');
  }

  Iterable<M.MetricSample> getSamples(M.IsolateRef i, M.Metric m) {
    if (_samples.containsKey(i)) {
      final metrics = _samples[i];
      if (metrics.containsKey(m)) {
        return metrics[m];
      }
    }
    return null;
  }

  double getMinValue(M.IsolateRef i, M.Metric m) {
    Metric metric = m as Metric;
    assert(metric != null);
    return metric.internal.min;
  }

  double getMaxValue(M.IsolateRef i, M.Metric m) {
    Metric metric = m as Metric;
    assert(metric != null);
    return metric.internal.max;
  }

  void _update(_) {
    for (final isolate in _rates.keys) {
      final metrics = _rates[isolate];
      for (final metric in metrics.keys) {
        final rate = metrics[metric];
        if (rate != 0 && count % rate == 0) {
          final size = _sizes[isolate][metric];
          final samples = _samples[isolate][metric];
          metric.internal.reload().then((m) {
            if (samples.length >= size) {
              samples.removeRange(0, samples.length - size + 1);
            }
            samples.add(new MetricSample(m.value));
          });
        }
      }
    }
    ++count;
  }
}
