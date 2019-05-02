# Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.


def CheckChangeOnUpload(input_api, output_api):
    return _CommonChecks(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
    return _CommonChecks(input_api, output_api)


def _CommonChecks(input_api, output_api):
    tests = input_api.canned_checks.CheckLucicfgGenOutput(
        input_api, output_api, "main.star")
    results = []
    results.extend(
        input_api.canned_checks.CheckChangedLUCIConfigs(input_api, output_api))
    results.extend(input_api.RunTests(tests))
    return results
