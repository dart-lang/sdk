#!/usr/bin/python
"""
Converts an image into its Base-64 data string
Useful for embedding images in HTML or CSS without having a separate file
"""

import sys,base64

if __name__ == "__main__":
  if(len(sys.argv) < 2):
    print "Usage: img2base64.py <image>"
    exit(1)
  try:
    fName = sys.argv[1]
    data = base64.encodestring(open(fName,"rb").read()).replace('\n', '')
    fType = fName[-3:] #Use last 3 chars as file type
    print "data:image/%s;base64,%s"%(fType,data)
  except IOError as e:
    print "Failed to open file:", sys.argv[1]
