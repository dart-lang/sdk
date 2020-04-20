#!/usr/bin/env python3
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
"""Tool to automatically update the DartFuzzStats spreadsheet

Requires a one-time authentication step with a @google account.
"""
from __future__ import print_function
import pickle
import os.path
import subprocess
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request

# This script may require a one time install of Google API libraries:
# pip3 install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib

# If modifying these scopes, delete the file token.pickle.
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']

# The ID and range of a spreadsheet.
SPREADSHEET_ID = '1nDoK-dCuEmf6yo55a303UClRd7AwjbzPkRr37ijWcC8'
RANGE_NAME = 'Sheet1!A3:H'

VERIFY_CURRENT_ROW_FORMULA = '=B:B-C:C-D:D-E:E-F:F'


def authenticate():
    dir_path = os.path.dirname(os.path.realpath(__file__))
    creds = None
    # The file token.pickle stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    pickle_path = os.path.join(dir_path, 'token.pickle')
    if os.path.exists(pickle_path):
        with open(pickle_path, 'rb') as token:
            creds = pickle.load(token)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                os.path.join(dir_path, 'credentials.json'), SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open(pickle_path, 'wb') as token:
            pickle.dump(creds, token)
    return build('sheets', 'v4', credentials=creds)


# Returns the next run ID based on the last run ID found in the fuzzing
# spreadsheet.
def get_next_run_id(sheet):
    result = sheet.values().get(
        spreadsheetId=SPREADSHEET_ID, range=RANGE_NAME).execute()
    values = result.get('values', [])
    return int(values[-1][0]) + 1


# Inserts a new entry into the fuzzing spreadsheet.
def add_new_fuzzing_entry(sheet, run, tests, success, rerun, skipped, timeout,
                          divergences):

    entry = [run, tests, success, skipped, timeout, divergences, rerun]
    print(
        'Adding entry for run %d. Tests: %d Successes: %d Skipped: %d Timeouts: %d, Divergences: %d Re-runs: %d'
        % tuple(entry))

    values = {'values': [entry + [VERIFY_CURRENT_ROW_FORMULA]]}
    sheet.values().append(
        spreadsheetId=SPREADSHEET_ID,
        range=RANGE_NAME,
        body=values,
        valueInputOption='USER_ENTERED').execute()


# Scrapes the fuzzing shards for fuzzing run statistics.
#
# Returns a list of statistics in the following order:
#
# - # of tests
# - # of successes
# - # of re-runs
# - # of skipped runs
# - # of timeouts
# - # of divergences
#
def get_run_statistic_summary(run):
    dir_path = os.path.dirname(os.path.realpath(__file__))
    output = subprocess.check_output([
        'python3',
        os.path.join(dir_path, 'collect_data.py'), '--output-csv', '--type=sum',
        'https://ci.chromium.org/p/dart/builders/ci.sandbox/fuzz-linux/%d' % run
    ])
    return list(map(int, output.decode('UTF-8').rstrip().split(',')))


def main():
    service = authenticate()
    # Call the Sheets API
    sheet = service.spreadsheets()
    while True:
        try:
            next_id = get_next_run_id(sheet)
            summary = get_run_statistic_summary(next_id)
            add_new_fuzzing_entry(sheet, next_id, *summary)
        except:
            # get_run_statistic_summary exits with non-zero exit code if we're out
            # of runs to check.
            print('No more runs to process. Exiting.')
            break


if __name__ == '__main__':
    main()
