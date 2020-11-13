// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' hide File;
import 'dart:math';

import 'package:cli_util/cli_logging.dart';

/// A facility for drawing a progress bar in the terminal.
///
/// The bar is instantiated with the total number of "ticks" to be completed,
/// and progress is made by calling [tick]. The bar is drawn across one entire
/// line, like so:
///
///     [----------                                                   ]
///
/// The hyphens represent completed progress, and the whitespace represents
/// remaining progress.
///
/// If there is no terminal, the progress bar will not be drawn.
class ProgressBar {
  /// Whether the progress bar should be drawn.
  /*late*/ bool _shouldDrawProgress;

  /// The width of the terminal, in terms of characters.
  /*late*/ int _width;

  final Logger _logger;

  /// The inner width of the terminal, in terms of characters.
  ///
  /// This represents the number of characters available for drawing progress.
  /*late*/ int _innerWidth;

  final int _totalTickCount;

  int _tickCount = 0;

  ProgressBar(this._logger, this._totalTickCount) {
    if (!stdout.hasTerminal) {
      _shouldDrawProgress = false;
    } else {
      _shouldDrawProgress = true;
      _width = stdout.terminalColumns;
      _innerWidth = stdout.terminalColumns - 2;
      _logger.write('[' + ' ' * _innerWidth + ']');
    }
  }

  /// Clear the progress bar from the terminal, allowing other logging to be
  /// printed.
  void clear() {
    if (!_shouldDrawProgress) {
      return;
    }
    _logger.write('\r' + ' ' * _width + '\r');
  }

  /// Draw the progress bar as complete, and print two newlines.
  void complete() {
    if (!_shouldDrawProgress) {
      return;
    }
    _logger.write('\r[' + '-' * _innerWidth + ']\n\n');
  }

  /// Progress the bar by one tick.
  void tick() {
    if (!_shouldDrawProgress) {
      return;
    }
    _tickCount++;
    var fractionComplete =
        max(0, _tickCount * _innerWidth ~/ _totalTickCount - 1);
    var remaining = _innerWidth - fractionComplete - 1;
    _logger.write('\r[' + // Bring cursor back to the start of the line.
        '-' * fractionComplete + // Print complete work.
        AnsiProgress.kAnimationItems[_tickCount % 4] + // Print spinner.
        ' ' * remaining + // Print remaining work.
        ']');
  }
}
