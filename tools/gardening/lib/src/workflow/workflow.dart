// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';

/// An abstract class describing a workflow action.
abstract class WorkflowAction {}

/// [WaitForInputWorkflowAction] signals to the workflow engine that the current
/// step is waiting for user input.
class WaitForInputWorkflowAction extends WorkflowAction {}

/// [NavigateStepWorkflowAction] signals to the workflow engine that a
/// transition to a new step [nextStep] should happen. It is possible to send
/// state along by using the [payload].
class NavigateStepWorkflowAction<T> extends WorkflowAction {
  WorkflowStep nextStep;
  T payload;
  NavigateStepWorkflowAction(this.nextStep, this.payload);
}

/// [BackWorkflowAction] signals to the workflow engine that it should pop the
/// current step and return focus to the previous step.
class BackWorkflowAction extends WorkflowAction {}

/// Base class for a single step in a larger [Workflow].
abstract class WorkflowStep<T> {
  /// The [onShow] is called whenever the step receives focus from the workflow
  /// engine. This happens both when transitioning and when going back. When
  /// going back [payload] is null.
  Future<WorkflowAction> onShow(T payload);

  /// The [onLeave] is called on the current step, before the workflow engine
  /// transitions to a new step. The transition can be cancelled by returning
  /// true.
  Future<bool> onLeave();

  /// Input received by the workflow engine. The step should return what
  /// workflow action to take after processing the input.
  Future<WorkflowAction> input(String input);
}

/// [Workflow] is a class that makes it easy to create workflows. A workflow is
/// a collection of steps, with transitions between the steps to complete the
/// workflow. Viewed steps are kept track of by a stack, which makes it easy for
/// steps to transition back.
///
/// All access to navigation is hidden, thereby making steps unaware of the
/// workflow it is in. Navigation can only be changed by workflow actions.
class Workflow {
  final List<WorkflowStep> _lastSteps = [];

  WorkflowStep get currentStep {
    return _lastSteps.length > 0 ? _lastSteps.last : null;
  }

  /// Start the workflow by providing the first step to show.
  Future start(WorkflowStep firstStep) {
    return _navigate(firstStep, null);
  }

  /// Handling the leaving of a step and asks the step if it is ok to leave.
  Future _navigateLeave() async {
    if (currentStep != null) {
      var result = await currentStep.onLeave();
      if (result == true) {
        // Cancel the navigation. We should wait for input.
        return _handleWorkflowAction(new WaitForInputWorkflowAction());
      }
    }
  }

  /// Handling the navigation to a step and adding the new step as the current.
  Future _navigate<T>(WorkflowStep navigateTo, T payload) async {
    await _navigateLeave();
    _lastSteps.add(navigateTo);
    await _handleWorkflowAction(await currentStep.onShow(payload));
  }

  /// Handling the workflow actions a feedback recursive loop.
  Future _handleWorkflowAction(WorkflowAction action) async {
    if (action is WaitForInputWorkflowAction) {
      String input = stdin.readLineSync();
      return _handleWorkflowAction(await currentStep.input(input));
    } else if (action is NavigateStepWorkflowAction) {
      return _navigate(action.nextStep, action.payload);
    } else if (action is BackWorkflowAction) {
      await _navigateLeave();
      var lastStep = _lastSteps.removeLast();
      while (lastStep != null && lastStep is! ComputeStep) {
        lastStep = _lastSteps.removeLast();
      }
      if (currentStep != null) {
        return _handleWorkflowAction(await currentStep.onShow(null));
      }
    }
  }
}

/// [ComputeStepPayload] is the payload for doing [ComputeStep].
class ComputeStepPayload {
  final Future action;
  final String message;
  final WorkflowStep completedStep;
  ComputeStepPayload(this.action, this.message, this.completedStep);
}

/// [ComputeStep] is similar to a loading screen, showing a dot every second
/// until the computation in the future [action] in the payload is completed.
/// When completed, it will ask for a transition by returning
/// [NavigateStepWorkflowAction].
class ComputeStep extends WorkflowStep<ComputeStepPayload> {
  @override
  Future<bool> onLeave() async {
    // Do nothing.
    return false;
  }

  @override
  Future<WorkflowAction> onShow(ComputeStepPayload payload) async {
    stdout.write(payload.message);
    var timer = new Timer(new Duration(seconds: 1), () {
      stdout.write(".");
    });
    var result = await payload.action;
    timer.cancel();
    stdout.write("\n");
    return new NavigateStepWorkflowAction(payload.completedStep, result);
  }

  @override
  Future<WorkflowAction> input(String input) {
    // Do nothing.
    return null;
  }
}
