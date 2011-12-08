# Overview

Fixi is a command-line utility, written in Ruby, that indexes, verifies, and
updates checksum information for collections of files.

Tracking fixity is an important part of any digital preservation strategy,
and fixi aims to help with that in as unobtrusive a manner as possible.

## Features

* Works with any pre-existing directory layout scheme.
* Keeps the index in a single ".fixi" directory at the root of the collection
* Supports regular expression-based includes and excludes
* Supports any combination of md5, sha1, sha256, sha384, and sha512
* Supports shallow (fast) and deep (checksum-based) fixity checking
* Supports fast lookups of files by checksum

# Installation

Releases of Fixi are published to rubygems.org, so you can install them the
usual way:

    [sudo] gem install fixi

Or you can install from source via:

    [sudo] rake install

*NOTE: Fixi uses sqlite3, which will need to be built if it's not already on
your system.*

If you are using Ubuntu and you get an error about building sqlite, you may
need to install both the ruby1.9.1-dev and the libsqlite3-dev packages:

    [sudo] apt-get install ruby1.9.1-dev libsqlite3-dev

Similar steps may be necessary for other distros and operating systems.

# General Usage
    fixi [--version] [--help] <command> [<options>] [<args>]

Most commands accept a path to a directory or file as an argument.
If unspecified, the current directory (".") is assumed.

## Global Options:
    --version, -v:   Display the version and exit.
       --help, -h:   Show general or command-specific help

See below for command-specific usage and options.

# add: Add new files to the index

## Usage:
    fixi add [<options>] [<dir> | <file>]

## Options:
    --absolute, -a:   Show absolute paths. By default, paths are reported
                      relative to the index root.
     --dry-run, -d:   Don't do anything; just report what would be done

# check: Verify the fixity of files in the index

## Usage:
    fixi check [<options>] [<dir> | <file>]

## Options:
    --absolute, -a:   Show absolute paths. By default, paths are reported
                      relative to the index root.
     --shallow, -s:   Do shallow comparisons when determining which files have
                      changed. If specified, only file sizes and mtimes will be
                      used. By default, checksums will also be computed and
                      compared if necessary.
     --verbose, -v:   For modified files, show which attribute changed. By
                      default, only the path is shown.

# commit: Commit modified files to the index

## Usage:
    fixi commit [<options>] [<dir> | <file>]

## Options:
    --absolute, -a:   Show absolute paths. By default, paths are reported
                      relative to the index root.
     --dry-run, -d:   Don't do anything; just report what would be done
     --shallow, -s:   Do shallow comparisons when determining which files have
                      changed. If specified, only file sizes and mtimes will be
                      used. By default, checksums will also be computed and
                      compared if necessary.
     --verbose, -v:   For modified files, show which attribute changed. By
                      default, only the path is shown.

# info: Display a summary of the index

## Usage:
    fixi info [path]

# init: Create a new, empty index

## Usage:
    fixi init [<options>] [<dir>]

## Options:
    --algorithms, -l <s>:   Checksum algorithm(s) to use for the index. This is 
                            a comma-separated list, which may include md5, sha1,
                            sha256, sha384, and sha512. (Default: sha256)

# ls: List contents of the index

## Usage:
    fixi ls [<options>] [<dir> | <file>]

## Options:
    --absolute, -a:   Show absolute paths. By default, paths are reported
                      relative to the index root.
        --json, -j:   Like --verbose, but outputs the result as a json array.
         --md5 <s>:   Restrict list to files with the given md5 checksum
        --sha1 <s>:   Restrict list to files with the given sha1 checksum
      --sha256 <s>:   Restrict list to files with the given sha256 checksum
      --sha384 <s>:   Restrict list to files with the given sha384 checksum
      --sha512 <s>:   Restrict list to files with the given sha512 checksum
     --verbose, -v:   Include all information known about each file. By default,
                      only paths will be listed.

# rm: Delete old files from the index

## Usage:
    fixi rm [<options>] [<dir> | <file>]

## Options:
    --absolute, -a:   Show absolute paths. By default, paths are reported
                      relative to the index root.
     --dry-run, -d:   Don't do anything; just report what would be done

# sum: Calculate checksum(s) of a file

## Usage:
    fixi sum [<options>] <file>

## Options:
    --algorithms, -l <s>:   Checksum algorithm(s) to use. This is a
                            comma-separated list, which may include md5, sha1,
                            sha256, sha384, and sha512. At least one must be
                            specified.
 