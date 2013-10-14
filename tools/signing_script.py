#!/usr/bin/env python
# 
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import hashlib
import imp
import optparse
import os
import subprocess
import sys

DART_DIR = os.path.dirname(os.path.dirname(__file__))
GSUTIL = os.path.join(DART_DIR, 'third_party', 'gsutil', 'gsutil')
BOT_UTILS = os.path.join(DART_DIR, 'tools', 'bots', 'bot_utils.py')
BASENAME_PATTERN = 'darteditor-%(system)s-%(bits)s'
FILENAME_PATTERN = BASENAME_PATTERN + '.zip'
BUCKET_PATTERN = (
    'gs://dart-editor-archive-trunk/%(revision)s/' + FILENAME_PATTERN)

DRY_RUN = False

bot_utils = imp.load_source('bot_utils', BOT_UTILS)

class ChangedWorkingDirectory(object):
  def __init__(self, working_directory):
    self._working_directory = working_directory

  def __enter__(self):
    self._old_cwd = os.getcwd()
    print "Enter directory = ", self._working_directory
    if not DRY_RUN:
      os.chdir(self._working_directory)

  def __exit__(self, *_):
    print "Enter directory = ", self._old_cwd
    os.chdir(self._old_cwd)

def GetOptionsParser():
  parser = optparse.OptionParser("usage: %prog [options]")
  parser.add_option("--scratch-dir",
                    help="Scratch directory to use.")
  parser.add_option("--revision", type="int",
                    help="Revision we want to sign.")
  parser.add_option("--channel", type="string",
                    default=None,
                    help="Channel we want to sign.")
  parser.add_option("--dry-run", action="store_true", dest="dry_run",
                    default=False,
                    help="Do a dry run and do not execute any commands.")
  parser.add_option("--prepare", action="store_true", dest="prepare",
                    default=False,
                    help="Prepare the .exe/.zip files to sign.")
  parser.add_option("--deploy", action="store_true", dest="deploy",
                    default=False,
                    help="Pack the signed .exe/.zip files and deploy.")
  return parser

def die(msg, withOptions=True):
  print msg
  if withOptions:
    GetOptionsParser().print_usage()
  sys.exit(1)

def run(command):
  """We use run() instead of builtin python methods, because not all
  functionality can easily be done by python and we can support --dry-run"""

  print "Running: ", command
  if not DRY_RUN:
    process = subprocess.Popen(command,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)
    (stdout, stderr) = process.communicate()
    if process.returncode != 0:
      print "DEBUG: failed to run command '%s'" % command
      print "DEBUG: stdout = ", stdout
      print "DEBUG: stderr = ", stderr
      print "DEBUG: returncode = ", process.returncode
      raise OSError(process.returncode)

def clean_directory(directory):
  if os.path.exists(directory):
    run(['rm', '-r', directory])
  run(['mkdir', '-p', directory])

def rm_tree(directory):
  if os.path.exists(directory):
    run(['rm', '-r', directory])

def copy_tree(from_dir, to_dir):
  if os.path.exists(to_dir):
    run(['rm', '-r', to_dir])
  run(['cp', '-Rp', from_dir, to_dir])

def copy_file(from_file, to_file):
  if os.path.exists(to_file):
    run(['rm', to_file])
  run(['cp', '-p', from_file, to_file])

def copy_and_zip(from_dir, to_dir):
  rm_tree(to_dir)
  copy_tree(from_dir, to_dir)

  dirname = os.path.basename(to_dir)
  with ChangedWorkingDirectory(os.path.dirname(to_dir)):
    run(['zip', '-r9', dirname + '.zip', dirname])

def unzip_and_copy(extracted_zipfiledir, to_dir):
  rm_tree(extracted_zipfiledir)
  run(['unzip', extracted_zipfiledir + '.zip', '-d',
       os.path.dirname(extracted_zipfiledir)])
  rm_tree(to_dir)
  copy_tree(extracted_zipfiledir, to_dir)

def download_from_old_location(config, destination):
  bucket = BUCKET_PATTERN % config
  run([GSUTIL, 'cp', bucket, destination])

def upload_to_old_location(config, source_zip):
  if not DRY_RUN:
    bot_utils.CreateChecksumFile(
        source_zip, mangled_filename=os.path.basename(source_zip))
  md5_zip_file = source_zip + '.md5sum'
  
  bucket = BUCKET_PATTERN % config
  run([GSUTIL, 'cp', source_zip, bucket])
  run([GSUTIL, 'cp', md5_zip_file, bucket + '.md5sum'])
  run([GSUTIL, 'setacl', 'public-read', bucket])
  run([GSUTIL, 'setacl', 'public-read', bucket + '.md5sum'])

def download_from_new_location(channel, config, destination):
  namer = bot_utils.GCSNamer(channel,
                             bot_utils.ReleaseType.RAW)
  bucket = namer.editor_zipfilepath(config['revision'], config['system'],
                                    config['bits'])
  run([GSUTIL, 'cp', bucket, destination])

def upload_to_new_location(channel, config, source_zip):
  namer = bot_utils.GCSNamer(channel,
                             bot_utils.ReleaseType.SIGNED)
  zipfilename = namer.editor_zipfilename(config['system'], config['bits'])
  bucket = namer.editor_zipfilepath(config['revision'], config['system'],
                                    config['bits'])

  if not DRY_RUN:
    bot_utils.CreateChecksumFile(source_zip, mangled_filename=zipfilename)
  md5_zip_file = source_zip + '.md5sum'
  
  run([GSUTIL, 'cp', source_zip, bucket])
  run([GSUTIL, 'cp', md5_zip_file, bucket + '.md5sum'])
  run([GSUTIL, 'setacl', 'public-read', bucket])
  run([GSUTIL, 'setacl', 'public-read', bucket + '.md5sum'])

def main():
  if sys.platform != 'linux2':
    print "This script was only tested on linux. Please run it on linux!"
    sys.exit(1)

  parser = GetOptionsParser()
  (options, args) = parser.parse_args()

  if not options.scratch_dir:
    die("No scratch directory given.")
  if not options.revision:
    die("No revision given.")
  if not options.prepare and not options.deploy:
    die("No prepare/deploy parameter given.")
  if options.prepare and options.deploy:
    die("Can't have prepare and deploy parameters at the same time.")
  if len(args) > 0:
    die("Invalid additional arguments: %s." % args)

  if options.channel:
    assert options.channel in bot_utils.Channel.ALL_CHANNELS

  global DRY_RUN
  DRY_RUN = options.dry_run

  downloads_dir = os.path.join(options.scratch_dir, 'downloads')
  presign_dir = os.path.join(options.scratch_dir, 'presign')
  postsign_dir = os.path.join(options.scratch_dir, 'postsign')
  uploads_dir = os.path.join(options.scratch_dir, 'uploads')

  if options.prepare:
    # Clean all directories
    clean_directory(downloads_dir)
    clean_directory(presign_dir)
    clean_directory(postsign_dir)
    clean_directory(uploads_dir)
  elif options.deploy:
    clean_directory(uploads_dir)

  # These are the locations where we can find the *.app folders and *.exe files
  # and the names we use inside the scratch directory.
  locations = {
    'macos' : {
      'editor' : os.path.join('dart', 'DartEditor.app'),
      'chrome' : os.path.join('dart', 'chromium', 'Chromium.app'),
      'content_shell' : os.path.join('dart', 'chromium',
                                     'Content Shell.app'),

      'editor_scratch' : 'DartEditor%(bits)s.app',
      'chrome_scratch' : 'Chromium%(bits)s.app',
      'content_shell_scratch' : 'ContentShell%(bits)s.app',

      'zip' : True,
    },
    'win32' : {
      'editor' : os.path.join('dart', 'DartEditor.exe'),
      'chrome' : os.path.join('dart', 'chromium', 'chrome.exe'),
      'content_shell' : os.path.join('dart', 'chromium',
                                     'content_shell.exe'),

      'editor_scratch' : 'DartEditor%(bits)s.exe',
      'chrome_scratch' : 'chromium%(bits)s.exe',
      'content_shell_scratch' : 'content_shell%(bits)s.exe',

      'zip' : False,
    },
  }

  # Desitination of zip files we download
  for system in ('macos', 'win32'):
    for bits in ('32', '64'):
      config = {
        'revision' : options.revision,
        'system' : system,
        'bits' : bits,
      }

      destination = os.path.join(downloads_dir, FILENAME_PATTERN % config)
      destination_dir = os.path.join(downloads_dir, BASENAME_PATTERN % config)

      deploy = os.path.join(uploads_dir, FILENAME_PATTERN % config)
      deploy_dir = os.path.join(uploads_dir, BASENAME_PATTERN % config)

      if options.prepare:
        # Download *.zip files from GCS buckets
        if options.channel:
          download_from_new_location(options.channel, config, destination)
        else:
          download_from_old_location(config, destination)

        run(['unzip', destination, '-d', destination_dir])

        for name in ['editor', 'chrome', 'content_shell']:
          from_path = os.path.join(destination_dir, locations[system][name])
          to_path = os.path.join(
              presign_dir, locations[system]['%s_scratch' % name] % config)

          if locations[system]['zip']:
            # We copy a .app directory directory and zip it
            copy_and_zip(from_path, to_path)
          else:
            # We copy an .exe file
            copy_file(from_path, to_path)
      elif options.deploy:
        copy_tree(destination_dir, deploy_dir)
  
        for name in ['editor', 'chrome', 'content_shell']:
          from_path = os.path.join(
              postsign_dir, locations[system]['%s_scratch' % name] % config)
          to_path = os.path.join(deploy_dir, locations[system][name])

          if locations[system]['zip']:
            # We unzip a zip file and copy the resulting signed .app directory
            unzip_and_copy(from_path, to_path)
          else:
            # We copy the signed .exe file
            copy_file(from_path, to_path)

        deploy_zip_file = os.path.abspath(deploy)
        with ChangedWorkingDirectory(deploy_dir):
          run(['zip', '-r9', deploy_zip_file, 'dart'])

        # Upload *.zip/*.zip.md5sum and set 'public-read' ACL
        if options.channel:
          upload_to_new_location(options.channel, config, deploy_zip_file)
        else:
          upload_to_old_location(config, deploy_zip_file)

if __name__ == '__main__':
  main()

