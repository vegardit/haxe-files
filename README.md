# haxe-files - cross-platform filesystem operations

[![Build Status](https://travis-ci.org/vegardit/haxe-files.svg?branch=master)](https://travis-ci.org/vegardit/haxe-files)
[![Release](https://img.shields.io/github/release/vegardit/haxe-files.svg)](http://lib.haxe.org/p/haxe-files)
[![License](https://img.shields.io/github/license/vegardit/haxe-files.svg?label=license)](#license)

1. [What is it?](#what-is-it)
1. [The `Path` class](#path-class)
1. [The `File` class](#file-class)
1. [The `Dir` class](#dir-class)
1. [The `GlobPatterns` class](#globpatterns-class)
1. [File watching](#file-watching)
1. [Installation](#installation)
1. [Using the latest code](#latest)
1. [License](#license)


## <a name="what-is-it"></a>What is it?

A [haxelib](http://lib.haxe.org/documentation/using-haxelib/) for consistent cross-platform filesystem operations and proper Windows-/Unix-style path handling.

All classes are located in the package `hx.files` or below.,

The library has been extensively unit tested (over 500 individual test cases) on the targets C++, C#, HashLink, Java, JavaScript (Node.js and PhantomJS),
Neko, PHP 5, PHP 7 and Python 3.

Requires Haxe 3.4 or higher.

**Note:**
* When targeting [Node.js](https://nodejs.org) the [hxnodejs](https://lib.haxe.org/p/hxnodejs) haxelib is required.
* When targeting [PhantomJS](https://phantomjs.org) the [phantomjs](https://lib.haxe.org/p/phantomjs) haxelib is required.
* Flash/Air is currently not supported.


## <a name="path-class"></a>The `Path` class

Instances of the [hx.files.Path](https://github.com/vegardit/haxe-files/blob/master/src/hx/files/Path.hx)  class represent the path to a file or directory on the local file system.
It can be seen as an improved and extended version of the built-in [haxe.io.Path](http://api.haxe.org/haxe/io/Path.html) class.
In contrast to functions provided by haxe.io.Path, there are no situations where the result of a function is unspecified.

There exist two implementations:
- `haxe.io.Path.WindowsPath` for Windows path, i.e. backslash is used as directory separator and paths starting with a drive letter or a UNC path are considered absolute
- `haxe.io.Path.UnixPath` for Unix/Linux style paths, i.e. slash is used as directory separator and paths starting with a slash are considered absolute.

```haxe
package com.example;

import hx.files.*;

class MyClass {

    static function main() {
        var p = Path.of("./mydir/myfile.txt");   // constructing a path compatible with the local operating/file-system
        var p = Path.unix("/mydir/myfile.txt");     // constructing a Unix-style path
        var p = Path.win("C:\\mydir\\myfile.txt"); // constructing a Windows-style path

        p.filename;      // returns "myfile.txt"
        p.filenameExt;   // returns "txt"
        p.filenameStem;  // returns "myfile"
        p.isAbsolute;    // returns true
        p.exists();      // returns true or false depending on physical existance of the path
        p.isFile();      // returns true if exits and points to a file
        p.isDirectory(); // returns true if exits and points to a directory
        p.parent;        // returns Path object pointing to "C:\\mydir"
        p.root;          // returns Path object pointing to "C:\\"

        // path joining
        var p = Path.win("C:\\mydir");
        p.join("project1\src");  // returns Path object pointing to "C:\\mydir\\project1\\src"

        // getting absolute path
        var p = Path.of("mydir");
        p.getAbsolutePath();   // returns the absolute path as string

        // normalizing a path
        var p = Path.unix("aaa/bbb/ccc/../../ddd");
        p.normalize();   // returns Path object pointing to "aaa/ddd"

        // ellipszing
        Path.unix("/home/user/foo/bar").ellipsize(15);           // returns "/home/.../bar"
        Path.win("C:\\Users\\Default\\Desktop\\").ellipsize(15); // returns "C:\...\Desktop"
    }
}
```


## <a name="file-class"></a>The `File` class

Instances of the [hx.files.File](https://github.com/vegardit/haxe-files/blob/master/src/hx/files/File.hx)  class represent regular files on the local file system.

```haxe
package com.example;

import hx.files.*;

class MyClass {

    static function main() {

        var f = Path.of("mydir/myfile.txt").toFile(); // converting a Path instance to a File instance
        var f = File.of("mydir/myfile.txt");          // creating a File instance from a String path

        f.touch();                // create an empty file or update the modification timestamp
        f.writeString("Hello ");  // sets the file's content
        f.appendString("world!");

        f.size(); // returns the file size

        f.copyTo("mydir/myfile2.txt");               // throws an exception if myfile2.txt exists already
        f.copyTo("mydir/myfile2.txt", [OVERWRITE]);  // replaces myfile2.txt if it exists already

        f.delete();  // deletes the file

        var f2 = f.moveTo("otherdir/MY_FILE.txt");
        f.exists();  // returns false
        f2.exists(); // returns true
    }
}
```


## <a name="dir-class"></a>The `Dir` class

Instances of the [hx.files.Dir](https://github.com/vegardit/haxe-files/blob/master/src/hx/files/Dir.hx)  class represent directories on the local file system.

```haxe
package com.example;

import hx.files.*;

class MyClass {

    static function main() {

        var d = Path.of("myproject").toDir(); // converting a Path instance to a Dir instance
        var d = Dir.of("myproject");          // creating a Dir instance from a String path

        p.setCWD();    // changes the current working directory
        d.listDirs();  // returns an array of Dir instances for contained directories (non-recursive)
        d.listFiles(); // returns an array of File instances for contained files (non-recursive)

        d.findFiles("src/**/*.hx");          // returns an array with all Haxe files in the src dir
        d.findFiles("assets/**/*.{js,css}"); // returns an array with all JS/CSS files in the assets dir

        // recursively visit all contained files and directories
        d.walk(
           function(file) {
               trace(file);
           },
           function(dir) {
               trace(dir);
           }
        );

        d.copyTo("myproject2");                     // recursively copy the directory
        d.copyTo("myproject2", [OVERWRITE]);        // delete myproject2 and recursively copy the directory
        d.copyTo("myproject2", [MERGE]);            // merge the files and folders into myproject2 but skip conflicting files
        d.copyTo("myproject2", [MERGE, OVERWRITE]); // merge the files and folders into myproject2 and replace conflicting files

        d.delete(true);  // recursively delete the directory
    }
}
```


## <a name="globpatterns-class"></a>The `GlobPatterns` class

The [hx.files.GlobPatterns](https://github.com/vegardit/haxe-files/blob/master/src/hx/files/GlobPatterns.hx) contains static methods to convert
(glob patterns)[https://en.wikipedia.org/wiki/Glob_(programming)] into regular expressions.

```haxe
package com.example;

import hx.files.*;

class MyClass {

    static function main() {
        GlobPatterns.toRegEx("*.txt");       // returns == "^[^\\\\^\\/]*\\.txt$"
        GlobPatterns.toRegEx("*file*");      // returns "^[^\\\\^\\/]*file[^\\\\^\\/]*$"
        GlobPatterns.toRegEx("file?.txt");   // returns "^file[^\\\\^\\/]\\.txt$"
        GlobPatterns.toRegEx("file[A-Z]");   // returns "^file[A-Z]$"
        GlobPatterns.toRegEx("file[!A-Z]");  // returns "^file[^A-Z]$"

        GlobPatterns.toEreg("src/**/*.hx").match("src/haxe/strings/Char.hx");            // returns true
        GlobPatterns.toEreg("assets/**/*.{js,css}").match("assets/theme/dark/dark.css"); // returns true
        GlobPatterns.toEreg("SystemOut[0-9].log").match("SystemOut1.log");               // returns true
        GlobPatterns.toEreg("SystemOut[!0-9].log").match("SystemOut1.log");              // returns false
    }
}
```


## <a name="file-watching"></a>File watching

Implementations of the [hx.files.watcher.FileWatcher](https://github.com/vegardit/haxe-files/blob/master/src/hx/files/watcher/FileWatcher.hx)
interface allow you to monitor the file system for create/delete/change events.

The [hx.files.watcher.PollingFileWatcher](https://github.com/vegardit/haxe-files/blob/master/src/hx/files/watcher/PollingFileWatcher.hx) class
scans the file system in intervalls to recursively determine file changes. This is a rather inefficient way but works cross-target.

With Java7 or higher the [hx.files.watcher.JavaFileWatcher](https://github.com/vegardit/haxe-files/blob/master/src/hx/files/watcher/JavaFileWatcher.hx)
based on [WatcherService](https://docs.oracle.com/javase/7/docs/api/java/nio/file/WatchService.html) is available.
It is more efficient but has some limitations as documented in the source code.

Other target-specific implementations can be provided in the future:
* For C++ based on [fswatch](https://emcrisostomo.github.io/fswatch/)
* For Python based on [watchdog](https://pypi.org/project/watchdog/)

```haxe
package com.example;

import hx.concurrent.executor.Executor;
import hx.files.*;
import hx.files.watcher.*;

class MyClass {

    static function main() {

        var ex = new Executor(); // executor is used to schedule scanning tasks and
        var fw = new PollingFileWatcher(ex, 100 /*polling interval in MS*/);

        // register an event listener
        fw.subscribe(function (event) {
            switch(event) {
                case DIR_CREATED(dir):       trace('Dir created: $dir');
                case DIR_DELETED(dir):       trace('Dir deleted: $dir');
                case DIR_MODIFIED(dir, _):   trace('Dir modified: $dir');
                case FILE_CREATED(file);     trace('File created: $file');
                case FILE_DELETED(file);     trace('File deleted: $file');
                case FILE_MODIFIED(file, _); trace('File modified: $file');
            }
        });

        fw.watch("myconfig.cfg"); // watch a file
        fw.watch("assets/foo");   // recursively watch a directory

        // do some file modifications...

        // cleanup
        fw.stop();
        ex.stop();
    }
}
```
## <a name="installation"></a>Installation

1. install the library via haxelib using the command:
    ```
    haxelib install haxe-files
    ```

2. use in your Haxe project

   * for [OpenFL](http://www.openfl.org/)/[Lime](https://github.com/openfl/lime) projects add `<haxelib name="haxe-files" />` to your [project.xml](http://www.openfl.org/documentation/projects/project-files/xml-format/)
   * for free-style projects add `-lib haxe-files`  to `your *.hxml` file or as command line option when running the [Haxe compiler](http://haxe.org/manual/compiler-usage.html)


## <a name="latest"></a>Using the latest code

### Using `haxelib git`

```
haxelib git haxe-files https://github.com/vegardit/haxe-files master D:\haxe-projects\haxe-files
```

###  Using Git

1. check-out the master branch
    ```
    git clone https://github.com/vegardit/haxe-files --branch master --single-branch D:\haxe-projects\haxe-files
    ```

2. register the development release with haxe
    ```
    haxelib dev haxe-doctest D:\haxe-projects\haxe-files
    ```

###  Using Subversion

1. check-out the trunk
    ```
    svn checkout https://github.com/vegardit/haxe-files/trunk D:\haxe-projects\haxe-files
    ```

2. register the development release with haxe
    ```
    haxelib dev haxe-files D:\haxe-projects\haxe-files
    ```


## <a name="license"></a>License

All files are released under the [Apache License 2.0](https://github.com/vegardit/haxe-files/blob/master/LICENSE.txt).
