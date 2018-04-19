/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files;

import hx.strings.internal.Either2;

#if (sys || macro || nodejs)
import sys.FileStat;
import sys.FileSystem;
#end

using hx.strings.Strings;

/**
 * Represents a directory.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class Dir {


    /**
      * @return the current working directory
      */
    public static function getCWD():Dir {
        #if sys
            return of(Sys.getCwd());
        #elseif phantomjs
            return of(js.phantomjs.FileSystem.workingDirectory());
        #else
            throw "Operation not supported on current target.";
        #end
    }


    /**
     * This method does not check if the path actually exists and if it currently points to a directory or a file
     *
     * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
     */
    public static function of(path:Either2<String, Path>, trimWhiteSpaces = true):Dir {
        if (path == null)
            return new Dir(Path.of(null));

        return switch(path.value) {
            case a(str): new Dir(Path.of(str, trimWhiteSpaces));
            case b(obj): new Dir(obj);
        }
    }


    public var path(default, null):Path;


    inline
    function new(path:Path) {
        this.path = path;
    }


    function assertValidPath(mustExist = true) {
        if (path.filename.isEmpty())
            throw "[path.filename] must not be null or empty!";

        if (path.exists()) {
            if (!path.isDirectory()) throw '[path] "$path" exists but is not a directory!';
        } else {
            if (mustExist) throw '[path] "$path" does not exist!';
        }
    }


    /**
     * Creates the given directory incl. all parent directories in case they don't exist yet
     *
     * <pre><code>
     * >>> Dir.of(null                ).create() throws "[path.filename] must not be null or empty!"
     * >>> Dir.of("target/foo/bar/dog").create() throws nothing
     * >>> Dir.of("target/foo/bar"    ).create() == false
     * >>> Dir.of("README.md"         ).create() throws '[path] "README.md" exists but is not a directory!'
     * </code></pre>
     *
     * @return true if dir was created, false if exists already
     * @throws if path is not a directory
     */
    public function create():Bool {

        assertValidPath(false);

        if (path.exists())
            return false;

        #if (sys || macro || nodejs)
            FileSystem.createDirectory(path.toString());
            return true;
        #elseif js
            js.phantomjs.FileSystem.makeTree(path.toString());
            return true;
        #else
            throw "Operation not supported on current target.";
        #end
    }


    public function isEmpty() {
        assertValidPath(false);

        if (!path.exists())
            return true;

        #if (sys || macro || nodejs)
            return FileSystem.readDirectory(path.toString()).length == 0;
        #elseif phantomjs
            return [for (entry in js.phantomjs.FileSystem.list(path.toString())) if (entry != "." && entry != "..") entry].length == 0;
        #else
            throw "Operation not supported on current target.";
        #end
    }


    /**
     * Recursively deletes the given directory.
     *
     * <pre><code>
     * >>> Dir.of(null       ).delete() == false
     * >>> Dir.of(""         ).delete() == false
     * >>> Dir.of("README.md").delete() throws '[path] "README.md" exists but is not a directory!'
     *
     * >>> Dir.of("target/foo/bar/dog").create() throws nothing
     * >>> File.of("target/foo/bar/dog/test.txt").writeString("test") throws nothing
     * >>> Dir.of("target/foo").delete()         throws 'Cannot delete directory "target' + Path.of("").dirSep + 'foo" because it is not empty!'
     * >>> Dir.of("target/foo").delete(true)     == true
     * >>> Dir.of("target/foo").delete()         == false
     *
     * <code></pre>
     *
     * @return false if path does not exist
     *
     * @throws if path is not a directory
     */
    public function delete(recursively = false):Bool {

        if (!path.exists())
            return false;

        assertValidPath();

        if (!recursively && !isEmpty())
            throw 'Cannot delete directory "$path" because it is not empty!';

        #if phantomjs
            js.phantomjs.FileSystem.removeTree(path.toString());
            return true;
        #end

        var dirs:Array<Dir> = [];
        walk(
            function(file) file.delete(),
            function(dir) { dirs.push(dir); return true; }
        );
        dirs.reverse();
        dirs.push(this);
        for (dir in dirs) {
            #if (sys || macro || nodejs)
                FileSystem.deleteDirectory(dir.path.toString());
            #else
                throw "Operation not supported on current target.";
            #end
        }

        return true;
    }


    /**
     * @param globPattern Pattern in the Glob syntax style, see https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob
     */
    public function find(globPattern:String, onFileMatch:File -> Void, onDirMatch:Dir -> Void) {

        if (!path.exists())
            return;

        assertValidPath();

        var p = path.toString();
        var searchRootPath = p + globPattern.substringBefore("*").substringBeforeLast("/");
        var filePattern = GlobPatterns.toEReg(globPattern);
        var searchRootOffset = p.endsWith(path.dirSep) ? p.length8() : p.length8() + 1;

        Dir.of(searchRootPath).walk(
            function(file) {
                if (filePattern.match(file.path.toString().substr8(searchRootOffset))) {
                    if (onFileMatch != null) onFileMatch(file);
                }
            },
            function(dir) {
                if (filePattern.match(dir.path.toString().substr8(searchRootOffset))) {
                    if (onDirMatch != null) onDirMatch(dir);
                }
                return true;
            }
        );
    }


    /**
     * <pre><code>
     * >>> [ for (d in Dir.of(".").findDirs("*"           )) d.path.filename ].indexOf("src")   > -1
     * >>> [ for (d in Dir.of(".").findDirs("*" + "/hx/f*")) d.path.filename ].indexOf("files") > -1
     * >>> [ for (d in Dir.of(".").findDirs("**" + "/fi*" )) d.path.filename ].indexOf("files") > -1
     *
     * >>> [ for (d in Dir.of(".").findFiles("*"           )) d.path.filename ].indexOf("README.md") >  -1
     * >>> [ for (d in Dir.of(".").findFiles("**" + "/*.hx")) d.path.filename ].indexOf("Dir.hx")    >  -1
     * >>> [ for (d in Dir.of(".").findFiles("*"  + "/*.hx")) d.path.filename ].indexOf("Dir.hx")    == -1
     *
     * >>> Dir.of(null).findDirs("*").length == 0
     * >>> Dir.of(""  ).findDirs("*").length  == 0
     * </code></pre>
     */
    public function findDirs(globPattern:String):Array<Dir> {
        var dirs = new Array<Dir>();
        find(globPattern, null, function(dir) dirs.push(dir));
        return dirs;
    }


    /**
     * <pre><code>
     * >>> [ for (f in Dir.of(".").findFiles("*"           )) f.path.filename ].indexOf("src")   == -1
     * >>> [ for (f in Dir.of(".").findFiles("*" + "/hx/f*")) f.path.filename ].indexOf("files") == -1
     * >>> [ for (f in Dir.of(".").findFiles("**" + "/fi*" )) f.path.filename ].indexOf("files") == -1
     *
     * >>> [ for (f in Dir.of(".").findFiles("*"           )) f.path.filename ].indexOf("README.md") >  -1
     * >>> [ for (f in Dir.of(".").findFiles("**" + "/*.hx")) f.path.filename ].indexOf("Dir.hx")    >  -1
     * >>> [ for (f in Dir.of(".").findFiles("*"  + "/*.hx")) f.path.filename ].indexOf("Dir.hx")    == -1
     *
     * >>> Dir.of(null).findFiles("*").length == 0
     * >>> Dir.of(""  ).findFiles("*").length == 0
     * </code></pre>
     */
    public function findFiles(globPattern:String):Array<File> {
        var files = new Array<File>();
        find(globPattern, function(file) files.push(file), null);
        return files;
    }


    /**
     * <pre><code>
     * >>> Dir.of(".").list().length > 1
     *
     * >>> [ for (p in Dir.of(".").list()) p.filename ].indexOf("src"      ) > -1
     * >>> [ for (p in Dir.of(".").list()) p.filename ].indexOf("README.md") > -1
     *
     * >>> Dir.of(null).list()          == []
     * >>> Dir.of("nonexistent").list() == []
     * >>> Dir.of("README.md").list()   throws '[path] "README.md" exists but is not a directory!'
     * <code></pre>
     */
    public function list():Array<Path> {
        if (!path.exists())
            return [];

        assertValidPath();

        var entries:Array<String>;

        #if (sys || macro || nodejs)
            var entries = FileSystem.readDirectory(path.toString());
        #elseif phantomjs
            var entries = [for (entry in js.phantomjs.FileSystem.list(path.toString())) if (entry != "." && entry != "..") entry];
        #else
            throw "Operation not supported on current target.";
        #end

        haxe.ds.ArraySort.sort(entries, Strings.compare);
        return [ for (entry in entries) @:privateAccess path.newPathForChild(entry) ];
    }


    /**
     * <pre><code>
     * >>> Dir.of(".").listDirs().length > 1
     *
     * >>> [ for (f in Dir.of(".").listDirs()) f.path.filename ].indexOf("src"      ) >  -1
     * >>> [ for (f in Dir.of(".").listDirs()) f.path.filename ].indexOf("README.md") ==  -1
     *
     * >>> Dir.of(null).listDirs()          == []
     * >>> Dir.of("nonexistent").listDirs() == []
     * >>> Dir.of("README.md").listDirs()   throws '[path] "README.md" exists but is not a directory!'
     * <code></pre>
     */
    public function listDirs():Array<Dir> {
        return [ for (entry in list()) if (entry.isDirectory()) entry.toDir() ];
    }


    /**
     * <pre><code>
     * >>> Dir.of(".").listFiles().length > 1
     *
     * >>> [ for (f in Dir.of(".").listFiles()) f.path.filename ].indexOf("src"      ) == -1
     * >>> [ for (f in Dir.of(".").listFiles()) f.path.filename ].indexOf("README.md") >  -1
     *
     * >>> Dir.of(null).listFiles()          == []
     * >>> Dir.of("nonexistent").listFiles() == []
     * >>> Dir.of("README.md").listFiles()   throws '[path] "README.md" exists but is not a directory!'
     * <code></pre>
     */
    public function listFiles():Array<File> {
        return [ for (entry in list()) if (entry.isFile()) entry.toFile() ];
    }


    /**
     * Moves the given directory and adjusts the path attribute accordingly.
     *
     * <pre><code>
     * >>> Dir.of("target/foo").create()             throws nothing
     * >>> Dir.of("target/foo").moveTo("target/bar") throws nothing
     * >>> Dir.of("target/bar").moveTo("target/bar") throws nothing
     * >>> Dir.of("target/foo").path.exists()        == false
     * >>> Dir.of("target/bar").path.exists()        == true
     * >>> Dir.of("target/bar").moveTo("")           throws "[newPath] must not be null or empty!"
     * >>> Dir.of("target/bar").delete()             == true
     * >>> Dir.of("").moveTo("")                     throws "[path.filename] must not be null or empty!"
     * </code></pre>
     *
     * @param overwrite if set to true any file or directory already existing at newPath will be deleted automatically
     * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
     *
     * @return a Dir instance pointing to the new location
     */
    public function moveTo(newPath:Either2<String, Path>, overwrite = false, trimWhiteSpaces = true):Dir {
        assertValidPath();

        if (newPath == null)
            throw "[newPath] must not be null or empty!";

        var targetPath:Path = switch(newPath.value) {
            case a(str): Path.of(str, trimWhiteSpaces);
            case b(obj): obj;
        }

        if (targetPath.filename == "")
            throw "[newPath] must not be null or empty!";

        var targetDir = targetPath.toDir();

        if (targetPath.exists()) {

            if (path.getAbsolutePath() == targetPath.getAbsolutePath())
                return this;

            if (!overwrite)
                throw '[newPath] "$targetPath" already exists!';

            if (targetPath.isFile())
                targetPath.toFile().delete();
            else if (targetPath.isDirectory())
                targetDir.delete();
            else
                throw '[newPath] "$targetPath" points to an unknown file system entry!';
        }

        #if (sys || macro || nodejs)
            FileSystem.rename(path.toString(), targetPath.toString());
        #elseif phantomjs
            js.phantomjs.FileSystem.copyTree(path.toString(), targetPath.toString());
            js.phantomjs.FileSystem.removeTree(path.toString());
        #else
            throw "Operation not supported on current target.";
        #end

        return targetDir;
    }


    /**
     * Renames the given directory within it's current parent directory.
     *
     * <pre><code>
     * >>> Dir.of("target/foo").create()        throws nothing
     * >>> Dir.of("target/foo").renameTo("bar") throws nothing
     * >>> Dir.of("target/bar").path.exists()   == true
     * >>> Dir.of("target/foo").path.exists()   == false
     * >>> Dir.of("target/bar").delete()        == true
     *
     * >>> Dir.of("target/foo").renameTo("target/bar") throws '[newDirName] "target/bar" must not contain directory separators!'
     * >>> Dir.of("target/foo").renameTo("")           throws "[newDirName] must not be null or empty!"
     * >>> Dir.of(""          ).renameTo("")           throws "[newDirName] must not be null or empty!"
     * </code></pre>
     *
     * @param overwrite if set to true any file or directory already existing at newPath will be deleted automatically
     * @param newDirName the new directory name (NOT the full path!)
     *
     * @return a Dir instance pointing to the new location
     */
    public function renameTo(newDirName:String, overwrite = false):Dir {
        if (newDirName.isEmpty())
            throw "[newDirName] must not be null or empty!";

        if (newDirName.containsAny([Path.UnixPath.DIR_SEP, Path.WindowsPath.DIR_SEP]))
            throw '[newDirName] "$newDirName" must not contain directory separators!';

        if (path.parent == null)
            moveTo(newDirName, overwrite);

        return moveTo(path.parent.join(newDirName), overwrite);
    }


    /**
     * Changes into the directory, i.e. sets this directory as the current working directory
     */
    public function setCWD():Void {
        assertValidPath();

        #if sys
            Sys.setCwd(path.toString());
        #elseif phantomjs
            js.phantomjs.FileSystem.changeWorkingDirectory(path.toString());
        #else
            throw "Operation not supported on current target.";
        #end
    }


    /**
     * <pre><code>
     * >>> Dir.of("test"       ).size() > 100
     * >>> Dir.of("nonexistent").size() throws '[path] "nonexistent" doesn\'t exists!'
     * </code></pre>
     *
     * @return size in bytes
     */
    public function size():Int {
        if (!path.exists())
            throw '[path] "$path" doesn\'t exists!';

        var size:Int = 0;
        walk(function(file:File) {
            size += file.size();
        });
        return size;
    }


    /**
     * <pre><code>
     * >>> Dir.of("." ).walk(function (file) {}, function (dir) return true) throws nothing
     * >>> Dir.of("." ).walk(function (file) {})                             throws nothing
     * >>> Dir.of("." ).walk(null)                                           throws nothing
     * >>> Dir.of(null).walk(null)                                           throws nothing
     * </code></pre>
     *
     * @param onFile callback function that is invoked on each found file
     * @param onDir callback function that is invoked on each found directory, if returns false, traversing stops
     */
    public function walk(onFile:File -> Void, ?onDir:Dir -> Bool):Void {
        var nodes:Array<Path> = list();
        while (nodes.length > 0) {
            var node = nodes.shift();
            if (node.isDirectory()) {
                var dir = node.toDir();
                if (onDir == null || onDir(dir)) {
                    nodes = nodes.concat(dir.list());
                }
            } else if (onFile != null) {
                onFile(node.toFile());
            }
        }
    }

    inline
    public function toString():String {
        return path.toStringWithTrailingSeparator();
    }
}
