#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# This script dumps the content of a shared memory block
# used by Linux/Cdorked.A into a file named httpd_cdorked_config.bin
# when the machine is infected.
#
# Marc-Etienne M.Léveillé, leveille at eset.com

from ctypes import *

SHM_SIZE = 6118512
SHM_KEY = 63599

OUTFILE="httpd_cdorked_config.bin"

try:
  rt = CDLL('librt.so')
except:
  rt = CDLL('librt.so.1')

shmget = rt.shmget
shmget.argtypes = [c_int, c_size_t, c_int]
shmget.restype = c_int
shmat = rt.shmat
shmat.argtypes = [c_int, POINTER(c_void_p), c_int]
shmat.restype = c_void_p

shmid = shmget(SHM_KEY, SHM_SIZE, 0o666)
if shmid < 0:
  print "System not infected"
else:
  addr = shmat(shmid, None, 0)

  f = file(OUTFILE, 'wb')
  f.write(string_at(addr,SHM_SIZE))
  f.close()

  print "Dumped %d bytes in %s" % (SHM_SIZE, OUTFILE)
