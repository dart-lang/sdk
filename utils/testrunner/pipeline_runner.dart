// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A [PipelineRunner] represents the execution of our pipeline for
 * one test file.
 */
class PipelineRunner {
  /** The path of the test file. */
  Path _path;

  /** The pipeline template. */
  List _pipelineTemplate;

  /** String lists used to capture output. */
  List _stdout;
  List _stderr;

  /** Whether the output should be verbose. */
  bool _verbose;

  /** Which stage of the pipeline is being executed. */
  int _stageNum;

  /** The handler to call when the pipeline is done. */
  Function _completeHandler;

  PipelineRunner(
      this._pipelineTemplate,
      String test,
      this._verbose,
      this._completeHandler) {
    _path = new Path(test);
    _stdout = new List();
    _stderr = new List();
  }

  /** Kick off excution with the first stage. */
  void execute() {
    _runStage(_stageNum = 0);
  }

  /** Execute a stage of the pipeline. */
  void _runStage(int stageNum) {
    _pipelineTemplate[stageNum].
        execute(_path, _stdout, _stderr, _verbose, _handleExit);
  }

  /**
   * [_handleExit] is called at the end of each stage. It will execute the
   * next stage or call the completion handler if all are done.
   */
  void _handleExit(int exitCode) {
    int totalStages = _pipelineTemplate.length;
    _stageNum++;
    String suffix = _verbose ? ' (step $_stageNum of $totalStages)' : '';

    if (_verbose && exitCode != 0) {
      _stderr.add('Test failed$suffix, exit code $exitCode\n');
    }

    if (_stageNum == totalStages || exitCode != 0) { // Done with pipeline.
      for (var i = 0; i < _stageNum; i++) {
        _pipelineTemplate[i].cleanup(_path, _stdout, _stderr, _verbose,
            config.keepTests);
      }
      completeHandler(makePathAbsolute(_path.toString()), exitCode,
          _stdout, _stderr);
    } else {
      if (_verbose) {
        _stdout.add('Finished $suffix\n');
      }
      _runStage(_stageNum);
    }
  }
}
