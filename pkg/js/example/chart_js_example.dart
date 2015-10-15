// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library chart.example;

// Based off the Javascript example
// https://github.com/nnnick/Chart.js/blob/b8691c9581bff0eeecb34f98e678dc045a18f33e/samples/line.html
// On 2015-10-15

import 'dart:html';
import 'dart:math';

import 'chart.dart';

void main() {
  var ctx = (querySelector('#canvas') as CanvasElement).context2D;

  var rnd = new Random();

  var data = new Data(labels: [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July"
  ], datasets: <DataSet>[
    new DataSet(
        label: "My First dataset",
        fillColor: "rgba(220,220,220,0.2)",
        strokeColor: "rgba(220,220,220,1)",
        pointColor: "rgba(220,220,220,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        data: [
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100)
        ]),
    new DataSet(
        label: "My Second dataset",
        fillColor: "rgba(151,187,205,0.2)",
        strokeColor: "rgba(151,187,205,1)",
        pointColor: "rgba(151,187,205,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(151,187,205,1)",
        data: [
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100),
          rnd.nextInt(100)
        ])
  ]);

  new Chart(ctx).Line(data, new Options(responsive: true));
}
