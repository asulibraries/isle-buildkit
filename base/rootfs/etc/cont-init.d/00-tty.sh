#!/usr/bin/env bash
set -e

# If the container is started without allocating a tty, i.e. without `-t`.
# It can cause issues for non-root processes that want to write directly to
# standard out.
#
# If a tty is allocated /dev/stdout will indirectly point to it /dev/pts/0.
# This file allows members of the tty group to write to it.
#
# If no tty is allocated /dev/stdout will point to /proc/self/fd/1 which 
# will be a pipe to the hosts users active terminal. This pipe is owned 
# root with read/write access only permitted to the root user.
#
# To permit the containers to be started without `tty` we allow all users
# to read/write to the stdout,stderr,stdin pipes.
chmod o+rw /dev/std{in,out,err}
