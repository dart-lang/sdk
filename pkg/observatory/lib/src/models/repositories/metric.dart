// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

enum MetricBufferSize { n10samples, n100samples, n1000samples }

enum MetricSamplingRate { off, e100ms, e1s, e2s, e4s, e8s }

abstract class MetricRepository {
  Future<Iterable<Metric>> list(IsolateRef isolate);
  void setSamplingRate(IsolateRef isolate, Metric metric, MetricSamplingRate r);
  MetricSamplingRate getSamplingRate(IsolateRef isolate, Metric metric);
  void setBufferSize(IsolateRef isolate, Metric metric, MetricBufferSize r);
  MetricBufferSize getBufferSize(IsolateRef isolate, Metric metric);
  Iterable<MetricSample>? getSamples(IsolateRef isolate, Metric metric);
  double getMinValue(IsolateRef isolate, Metric metric);
  double getMaxValue(IsolateRef isolate, Metric metric);
}
