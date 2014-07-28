# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This python script compiles a set of java files and puts them all into a
# single .jar file.

import os
import shutil
import sys
import tempfile
from optparse import OptionParser

# Filters out all arguments until the next '--' argument
# occurs.
def ListArgCallback(option, value, parser):
   if value is None:
     value = []

   for arg in parser.rargs:
     if arg[:2].startswith('--'):
       break
     value.append(arg)

   del parser.rargs[:len(value)]
   setattr(parser.values, option.dest, value)


# Compiles all the java source files in srcDir.
def javaCompile(javac, srcDirectories, srcList, classpath,
                classOutputDir, buildConfig, javacArgs,
                sources):
  # Check & prepare directories.
  for srcDir in srcDirectories:
    if not os.path.exists(srcDir):
      sys.stderr.write('source directory not found: ' + srcDir + '\n')
      return False

  if os.path.exists(classOutputDir):
    shutil.rmtree(classOutputDir)
  os.makedirs(classOutputDir)

  # Find all java files and write them in a temp file.
  (tempFileDescriptor, javaFilesTempFileName) = tempfile.mkstemp()
  javaFilesTempFile = os.fdopen(tempFileDescriptor, "w")
  try:
    if srcDirectories:
      def findJavaFiles(dirName, names):
        for fileName in names:
          (base, ext) = os.path.splitext(fileName)
          if ext == '.java':
            javaFilesTempFile.write(os.path.join(dirName, fileName) + '\n')
      for srcDir in srcDirectories:
        os.path.walk(srcDir, findJavaFiles, None)

    if srcList:
      f = open(srcList, 'r')
      for line in f:
        javaFilesTempFile.write(os.path.abspath(line))
      f.close()

    javaFilesTempFile.flush()
    javaFilesTempFile.close()

    # Prepare javac command.
    # Use a large enough heap to be able to compile all of the classes in one
    # big compilation step.
    command = [javac, '-J-Xmx256m']

    if buildConfig == 'Debug':
      command.append('-g')

    if srcDirectories:
      command.append('-sourcepath')
      command.append(os.pathsep.join(srcDirectories))

    if classpath:
      command.append('-classpath')
      command.append(os.pathsep.join(classpath))

    command.append('-d')
    command.append(classOutputDir)

    if srcDirectories or srcList:
      command.append('@' + javaFilesTempFileName)

    command = command + javacArgs

    abs_sources = [os.path.abspath(source) for source in sources]

    command = [' '.join(command)] + abs_sources

    # Compile.
    sys.stdout.write(' \\\n  '.join(command) + '\n')
    if os.system(' '.join(command)):
      sys.stderr.write('java compilation failed\n')
      return False
    return True
  finally:
    os.remove(javaFilesTempFileName)

def copyProperties(propertyFiles, classOutputDir):
  for property_file in propertyFiles:
    if not os.path.isfile(property_file):
      sys.stderr.write('property file not found: ' + property_file + '\n')
      return False

  if not os.path.exists(classOutputDir):
    sys.stderr.write('classes dir not found: ' + classOutputDir + '\n')
    return False

  if not propertyFiles:
    return True

  command = ['cp'] + propertyFiles + [classOutputDir]
  commandStr = ' '.join(command)
  sys.stdout.write(commandStr + '\n')
  if os.system(commandStr):
    sys.stderr.write('property file copy failed\n')
    return False
  return True

def createJar(classOutputDir, jarFileName):
  if not os.path.exists(classOutputDir):
    sys.stderr.write('classes dir not found: ' + classOutputDir + '\n')
    return False

  command = ['jar', 'cf', jarFileName, '-C', classOutputDir, '.']
  commandStr = ' '.join(command)
  sys.stdout.write(commandStr + '\n')
  if os.system(commandStr):
    sys.stderr.write('jar creation failed\n')
    return False
  return True


def main():
  try:
    # Parse input.
    parser = OptionParser()
    parser.add_option("--javac", default="javac",
                      action="store", type="string",
                      help="location of javac command")
    parser.add_option("--sourceDir", dest="sourceDirs", default=[],
                      action="callback", callback=ListArgCallback,
                      help="specify a list of directories to look for " +
                      ".java files to compile")
    parser.add_option("--sources", dest="sources", default=[],
                      action="callback", callback=ListArgCallback,
                      help="specify a list of source files to compile")
    parser.add_option("--sourceList", dest="sourceList",
                      action="store", type="string",
                      help="specify the file that contains the list of Java source files")
    parser.add_option("--classpath", dest="classpath", default=[],
                      action="append", type="string",
                      help="specify referenced jar files")
    parser.add_option("--classesDir",
                      action="store", type="string",
                      help="location of intermediate .class files")
    parser.add_option("--jarFileName",
                      action="store", type="string",
                      help="name of the output jar file")
    parser.add_option("--buildConfig",
                      action="store", type="string", default='Release',
                      help="Debug or Release")
    parser.add_option("--javacArgs", dest="javacArgs", default=[],
                      action="callback", callback=ListArgCallback,
                      help="remaining args are passed directly to javac")
    parser.add_option("--propertyFiles", dest="propertyFiles", default=[],
                      action="callback", callback=ListArgCallback,
                      help="specify a list of property files to copy")

    (options, args) = parser.parse_args()
    if not options.classesDir:
      sys.stderr.write('--classesDir not specified\n')
      return -1
    if not options.jarFileName:
      sys.stderr.write('--jarFileName not specified\n')
      return -1
    if len(options.sourceDirs) > 0 and options.sourceList:
      sys.stderr.write("--sourceDir and --sourceList cannot be both specified")
      return -1

    # Compile and put into .jar file.
    if not javaCompile(options.javac, options.sourceDirs,
                       options.sourceList, options.classpath,
                       options.classesDir, options.buildConfig,
                       options.javacArgs, options.sources):
      return -1
    if not copyProperties(options.propertyFiles, options.classesDir):
      return -1
    if not createJar(options.classesDir, options.jarFileName):
      return -1

    return 0
  except Exception, inst:
    sys.stderr.write('compile_java.py exception\n')
    sys.stderr.write(str(inst))
    return -1

if __name__ == '__main__':
  sys.exit(main())
