#!/usr/bin/env python

import sys
import json
import subprocess
import time
import threading


def run_command(name, executable, arguments, timeout_in_seconds):
    print "Running %s: '%s'" % (name, [executable] + arguments)

    # The timeout_handler will set this to True if the command times out.
    timeout_value = {'did_timeout': False}

    start = time.time()

    process = subprocess.Popen(
        [executable] + arguments,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)

    def timeout_handler():
        timeout_value['did_timeout'] = True
        process.kill()

    timer = threading.Timer(timeout_in_seconds, timeout_handler)
    timer.start()

    stdout, stderr = process.communicate()
    exit_code = process.wait()
    timer.cancel()

    end = time.time()

    return (exit_code, stdout, stderr, end - start,
            timeout_value['did_timeout'])


def main(args):
    recording_file = args[0]
    result_file = args[1]

    with open(recording_file) as fd:
        test_cases = json.load(fd)

    for test_case in test_cases:
        name = test_case['name']
        command = test_case['command']
        executable = command['executable']
        arguments = command['arguments']
        timeout_limit = command['timeout_limit']

        exit_code, stdout, stderr, duration, did_timeout = (run_command(
            name, executable, arguments, timeout_limit))

        test_case['command_output'] = {
            'exit_code': exit_code,
            'stdout': stdout,
            'stderr': stderr,
            'duration': duration,
            'did_timeout': did_timeout,
        }
    with open(result_file, 'w') as fd:
        json.dump(test_cases, fd)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print >> sys.stderr, (
            "Usage: %s <input-file.json> <output-file.json>" % sys.argv[0])
        sys.exit(1)
    sys.exit(main(sys.argv[1:]))
