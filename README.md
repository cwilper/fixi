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
* Supports export and import of BagIt bags
* Supports fast lookups of files by checksum

# Installation

Note: Fixi has been tested with Ruby 1.9 on Mac OS X, Ubuntu, and Windows.

Releases of Fixi are published to rubygems.org, so you can install them the
usual way:

    > [sudo] gem install fixi

Or you can install from source via:

    > [sudo] rake install

*NOTE: Fixi should generally work in any environment where Ruby 1.9 has been
installed. It has been tested on OS X, Ubuntu, and Windows.*

*NOTE: Fixi uses sqlite3, which may need to be built if it's not already on
your system.*

If you are using Ubuntu and you get an error about building sqlite, you may
need to install both the ruby1.9.1-dev and the libsqlite3-dev packages:

    > [sudo] apt-get install ruby1.9.1-dev libsqlite3-dev

Similar steps may be necessary for other distros and operating systems.

# Quick Example

Say you have a growing collection of photos you keep organized on your laptop.
You keep a backup in the cloud, but you also want to start tracking the 
bit-level integrity of the files. You're particularly concerned that files on
your laptop may become corrupt over time, and if you don't notice soon enough,
 the problem might eventually be propogated to your backup copy!

First, create a fixity index. Let's say you decide you want to keep md5 and
sha1 checksums of each file rather than using the default single hash algorithm,
sha256.

    > cd ~/Pictures
    > fixi init -l md5,sha1

Now you have an empty index. To populate it for the first time:

    > fixi add

Let's say after a couple weeks, you have more pictures. You've also intentionally
deleted a few older pictures you don't care about anymore. To get a quick report
of what has changed, without having to actually compute any checksums (the -s
option is short for --shallow), you can run:

    > fixi check -s

The check command reports on each file that has been added (A), modified (M),
or deleted (D).  After verifying that the reported adds and deletes are expected,
you can update the index via:

    > fixi add
    > fixi rm

Now let's say a couple more weeks have passed, and you've intentionally changed
the EXIF metadata in a bunch of old photos. After doing another shallow check and
verifying the reported modifications are expected, you can update the index via:

    > fixi commit

Note: Anytime you want to do a full fixity check of all files, or even just a 
single file, you can run:

    > fixi check [/path/to/indexed/dir-or-file]

These are just the basics. For more information about all the commands fixi
supports, run:

    > fixi --help

# General Usage
    fixi [--version] [--help] <command> [<options>] [<args>]

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

# bag: Export files as a new BagIt bag

## Usage:
    fixi bag [<options>] <input-dir> <output-dir>

## Where:
    input-dir is an indexed directory whose content should be exported.
    output-dir is the base directory of the bag to be created.

## Options:
    --algorithms, -l <s>:   Checksum algorithm(s) to use for the bag. This is a
                            comma-separated list, which may include md5, sha1,
                            sha256, sha384, sha512, and must be a subset of the
                            indexed algorithms. If unspecified, manifests will be
                            created for all indexed algorithms.

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

# unbag: Import files from a BagIt bag

## Usage:
    fixi unbag [<options>] <input-dir> <output-dir>

## Where:
    input-dir is the base directory of the bag.
    output-dir is the directory in which to import it.

## Options:
    --absolute, -a:   Show absolute paths. By default, paths are reported
                      relative to the index root.
