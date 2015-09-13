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

| Platform | Architecture | Supported? | Docker Container         |
|----------|--------------|------------|--------------------------|
|  Linux   |     x86      |    no      |                          |
|  Linux   |    x86_64    |    yes     | `andrewd/musl-cross`     |
|  Linux   |     arm      |    yes     | `andrewd/musl-cross-arm` |
|  Darwin  |     x86      |    no      |                          |
|  Darwin  |    x86_64    |    yes     | `andrewd/osxcross`       |


To actually use the tool, clone this repository and do the following inside the
resulting directory:

```
$ docker run --rm -t -i -v `pwd`:/make CONTAINER_NAME /bin/bash
# cd /make
# ./bbuild -b /tmp/build -k -p PLATFORM -a ARCHITECTURE RECIPE_TO_BUILD
```

For more information, run `./bbuild -h`.

## Contributing

If you have any recipes to contribute, please feel free to send me a pull
request.  If you'd like to request that I add a recipe, feel free to open an
issue - if it's possible to add, I'll do my best to add a recipe for it.

## Things Not Included

There are certain things that are very difficult / nearly impossible to compile
as static binaries - either because they don't support cross-compilation,
because they need dynamic linking, or other issues.  Here's a short list of
things that I will probably not be adding:

- ruby


[1]: https://github.com/andrew-d/static-binaries
