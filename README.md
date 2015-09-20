# bbuild

## What Is This?

This repository contains `bbuild` a pseudo-package manager that is designed to
help with building statically-linked binaries of various tools.  It's an
extension of the work that I started over in my [static-binaries][sb]
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
|  Windows<sup>1</sup> |     x86      |    no      |                          |
|  Windows<sup>1</sup> |    x86_64    |    yes     | `andrewd/mingw-w64`      |

<sub>1 - Most tools will not compile properly on Windows.  Buyer beware,
your mileage may vary, etc.</sub>

To actually use the tool, clone this repository and do the following inside the
resulting directory (the `$` prompt is the host, `#` is inside the container):

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
- GNU screen (doesn't really support cross compiling)


## Known Bugs and Notes

### file

You need to pass the correct magic database to file - one is provided named
`magic.mgc`.  Run `file` as such: `file -m /path/to/magic.mgc myfile.foo`.

### Git

You must provide the `--exec-path` option to Git to tell it where the various
binaries it needs are.  This should point to the subdirectory `exec-path` that
is produced as part of the build.

You may need to explicitly configure the CA certificate location for git to be
able to clone HTTPS repositories:

    git config --global http.sslCAinfo /etc/ssl/certs/ca-certificates.crt

If you don't have a CA certificate bundle, or you can't install one, you can
get one from the curl website at: http://curl.haxx.se/docs/caextract.html

### nmap

In order to do script scans, Nmap must know where the various Lua files live.
You can do this by setting the `NMAPDIR` environment variable:

    NMAPDIR=/usr/share/nmap nmap -vvv -A www.target.com`

### Python

You must run Python using the following command:

    PYTHONPATH=/path/to/python2.7.zip python -sS


[sb]: https://github.com/andrew-d/static-binaries
