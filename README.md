 <div>
  <h3 align="center"><img src="logo/cobalt-logo.png"/><br>A FreeDOS-based operating system designed to be light, simple and easy to use. </h3>
</div>



## Introduction

Cobalt is a new operating system based on FreeDOS, designed to be easy to use. Unlike FreeDOS, Cobalt is designed for users with no previous DOS experience. Cobalt uses the FreeDOS 1.1 kernel, ensuring 100% compatibility with DOS programs and games.

Cobalt currently includes:

 * FAT12/16/32 file system support
 * Optional [OpenGEM desktop environment](http://www.opendawn.com/opengem/)
 * Out the box network/internet support 
 * Support for CD/DVD drives
 * Built-in mouse driver
 * Support for [Long file names](https://en.wikipedia.org/wiki/Long_filename)
 * Include [DOS-Coreutils](https://github.com/Atnode/FreeDOS-Coreutils) (different utilities inspired by GNU Coreutils)

If you have an existing computer (or virtual machine) with a DOS-based operating system, Cobalt will allow you to 'upgrade' over the existing OS and keep all your files.

## Download Cobalt

Cobalt 1.2 is available to download [here](https://github.com/corbindavenport/cobalt/releases/tag/1.2). Download the zip file, unzip it, and either burn the ISO to a disc or mount it in a virtual machine to run.

## What's new?

New in Cobalt 1.3:

 * OpenGEM has replaced FreeDOS Shell as the desktop environment
 * Now under the MIT license
 * Bash compiler now supports Debian
 * BASE and DESKTOP packages are now zipped during the compilation process

## How to compile

Cobalt is easy to compile into a bootable .iso file. First, make sure you have the entire repo downloaded/cloned. If you are on Windows, just run the `compile.bat` file. If you are using Linux or Mac, run the `compile.sh` file. On Linux/Mac you may have to mark it as executable first, with `chmod +x ./compile.sh`.

When the script is done, it will create a `cobalt.iso` file within the main folder. Simply burn that image using any tool you like to a CD/DVD, or mount it into a virtual machine to try out Carbon.

Compiling Cobalt is only supported on Windows, Linux, and Mac. Other Unix-based operating systems may work, but they are untested. [Mkisofs](http://wiki.osdev.org/Mkisofs) is required to compile Cobalt, which can be found in the package repositories for most Linux distributions:

**Ubuntu**: `sudo apt-get install mkisofs`

**Debian**: `sudo apt-get install genisoimage`

**Arch Linux**: `pacman -S cdrkit`

If Mkisofs is not installed on your system, the compile script will use the binaries included in the Cobalt repository (the Linux binary only works on x86 systems).

***

Copyright 2017 Corbin Davenport

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.