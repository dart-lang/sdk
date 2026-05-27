#!/usr/bin/env python3
# Copyright 2025 The Dart Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
import multiprocessing
import sys

_logger = logging.getLogger(__name__)

def get_num_cpus():
    try:
        return multiprocessing.cpu_count()
    except NotImplementedError:
        _logger.error(
            "multiprocessing.cpu_count() is not implemented on this system."
        )
        sys.exit(1)
    except Exception as e:
        _logger.exception(
            "An unexpected error occurred while getting the number of CPUs."
        )
        sys.exit(1)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    print(get_num_cpus())
