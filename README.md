# bbuild

## What Is This?

This repository contains `bbuild` a pseudo-package manager that is designed to
help with building statically-linked binaries of various tools.  It's an
extension of the work that I started over in my [static-binaries][1]
repository, except as a proper tool rather than a bunch of shell scripts.


## How Do I Use It?

You need a recent version of bash, and the appropriate cross-compilation
toolchain installed.  I've also created a set of Docker containers that have
the correct toolchains installed.  A summary can be found below:

| Platform | Architecture | Supported? | Docker Container       |
|----------|--------------|------------|------------------------|
|  Linux   |     x86      |    no      |                        |
|  Linux   |    x86_64    |    yes     | andrewd/musl-cross     |
|  Linux   |     arm      |    yes     | andrewd/musl-cross-arm |
|  Darwin  |     x86      |    no      |                        |
|  Darwin  |    x86_64    |    yes     | andrewd/osxcross       |


[1]: https://github.com/andrew-d/static-binaries
