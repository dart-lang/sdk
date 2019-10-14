// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:quiver/check.dart';
import 'package:tflite_native/tflite.dart' as tfl;

/// Interface to TensorFlow-based Dart language model for next-token prediction.
class LanguageModel {
  static const _defaultCompletions = 100;
  static final _numeric = RegExp(r'^\d+(.\d+)?$');

  final tfl.Interpreter _interpreter;
  final Map<String, int> _word2idx;
  final Map<int, String> _idx2word;
  final int _lookback;

  LanguageModel._(
      this._interpreter, this._word2idx, this._idx2word, this._lookback);

  /// Number of previous tokens to look at during predictions.
  int get lookback => _lookback;

  /// Number of completion results to return during predictions.
  int get completions => _defaultCompletions;

  /// Load model from directory.
  factory LanguageModel.load(String directory) {
    // Load model.
    final interpreter =
        tfl.Interpreter.fromFile(path.join(directory, 'model.tflite'));
    interpreter.allocateTensors();

    // Load word2idx mapping for input.
    final word2idx = json
        .decode(File(path.join(directory, 'word2idx.json')).readAsStringSync())
        .cast<String, int>();

    // Load idx2word mapping for output.
    final idx2word = json
        .decode(File(path.join(directory, 'idx2word.json')).readAsStringSync())
        .map<int, String>((k, v) => MapEntry<int, String>(int.parse(k), v));

    // Get lookback size from model input tensor shape.
    final tensorShape = interpreter.getInputTensors().single.shape;
    checkArgument(tensorShape.length == 2 && tensorShape.first == 1,
        message:
            'tensor shape $tensorShape does not match the expected [1, X]');
    final lookback = tensorShape.last;

    return LanguageModel._(interpreter, word2idx, idx2word, lookback);
  }

  /// Tear down the interpreter.
  void close() {
    _interpreter.delete();
  }

  /// Predicts the next token to follow a list of precedent tokens
  ///
  /// Returns a list of tokens, sorted by most probable first.
  List<String> predict(List<String> tokens) =>
      predictWithScores(tokens).keys.toList();

  /// Predicts the next token with confidence scores.
  ///
  /// Returns an ordered map of tokens to scores, sorted by most probable first.
  Map<String, double> predictWithScores(List<String> tokens) {
    final tensorIn = _interpreter.getInputTensors().single;
    tensorIn.data = _transformInput(tokens);
    _interpreter.invoke();
    final tensorOut = _interpreter.getOutputTensors().single;
    return _transformOutput(tensorOut.data, tokens);
  }

  /// Transforms tokens to data bytes that can be used as interpreter input.
  List<int> _transformInput(List<String> tokens) {
    // Replace out of vocabulary tokens.
    final sanitizedTokens = tokens.map((token) {
      if (_word2idx.containsKey(token)) {
        return token;
      }
      if (_numeric.hasMatch(token)) {
        return '<num>';
      }
      if (_isString(token)) {
        return '<str>';
      }
      return '<unk>';
    });
    // Get indexes (as floats).
    final indexes = Float32List(lookback)
      ..setAll(0, sanitizedTokens.map((token) => _word2idx[token].toDouble()));
    // Get bytes
    return Uint8List.view(indexes.buffer);
  }

  /// Transforms interpreter output data to map of tokens to scores.
  Map<String, double> _transformOutput(
      List<int> databytes, List<String> tokens) {
    // Get bytes.
    final bytes = Uint8List.fromList(databytes);

    // Get scores (as floats)
    final probabilities = Float32List.view(bytes.buffer);

    final scores = Map<String, double>();
    probabilities.asMap().forEach((k, v) {
      // x in 0, 1, ..., |V| - 1 correspond to specific members of the vocabulary.
      // x in |V|, |V| + 1, ..., |V| + 49 are pointers to reference positions along the
      // network input.
      if (k >= _idx2word.length + tokens.length) {
        return;
      }
      final lexeme =
          k < _idx2word.length ? _idx2word[k] : tokens[k - _idx2word.length];
      final sanitized = lexeme.replaceAll('"', '\'');
      scores[sanitized] = (scores[sanitized] ?? 0.0) + v;
    });

    final entries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.sublist(0, completions));
  }

  bool _isString(String token) {
    return token.indexOf('"') != -1 || token.indexOf("'") != -1;
  }
}
