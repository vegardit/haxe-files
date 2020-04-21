/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files;

import hx.strings.Char;
import hx.strings.StringBuilder;
import hx.strings.collection.StringArray;
import hx.strings.internal.Either2;

using hx.strings.Strings;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@immutable
class Path {

   /**
    * Constructs a path object compatible with for the local filesystem.
    *
    * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
    */
   public static function of(path:String, trimWhiteSpaces = true):Path {
      if(hx.strings.internal.OS.isWindows)
         return Path.win(path, trimWhiteSpaces);
      return Path.unix(path, trimWhiteSpaces);
   }


   /**
    * Constructs a Unix style path. Alias for `Path.unix()`.
    *
    * <pre><code>
    * >>> Path.unix("/dir/file"    ).toString() == "/dir/file"
    * >>> Path.unix("/dir/file/"   ).toString() == "/dir/file"
    * >>> Path.unix("/dir///file//").toString() == "/dir/file"
    * >>> Path.unix("\\dir\\file"  ).toString() == "/dir/file"
    * >>> Path.unix("c:\\dir\\file").toString() == "c:/dir/file"
    * >>> Path.unix("c:\\"         ).toString() == "c:"
    * >>> Path.unix("/"            ).toString() == "/"
    * >>> Path.unix(".."           ).toString() == ".."
    * >>> Path.unix("."            ).toString() == "."
    * >>> Path.unix(""             ).toString() == ""
    * >>> Path.unix(null           ).toString() == null
    *
    * >>> Path.unix("  /  dir/// file  //"       ).toString() == "/dir/file"
    * >>> Path.unix("  /  dir/// file  //", false).toString() == "  /  dir/ file  "
    * </code></pre>
    *
    * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
    */
   inline
   public static function unix(path:String, trimWhiteSpaces = true):UnixPath
       return UnixPath.of(path, trimWhiteSpaces);


   /**
    * Constructs a Windows style path. Alias for `Path.win()`.
    *
    * <pre><code>
    * >>> Path.win("\\dir\\file"        ).toString() == "\\dir\\file"
    * >>> Path.win("\\dir\\file\\"      ).toString() == "\\dir\\file"
    * >>> Path.win("\\dir\\\\\\file\\\\").toString() == "\\dir\\file"
    * >>> Path.win("/dir/file"          ).toString() == "\\dir\\file"
    * >>> Path.win("c:\\dir\\file"      ).toString() == "C:\\dir\\file"
    * >>> Path.win("c:\\"               ).toString() == "C:\\"
    * >>> Path.win("c:"                 ).toString() == "C:\\"
    * >>> Path.win("\\"                 ).toString() == "\\"
    * >>> Path.win(".."                 ).toString() == ".."
    * >>> Path.win("."                  ).toString() == "."
    * >>> Path.win(""                   ).toString() == ""
    * >>> Path.win(null                 ).toString() == null
    *
    * >>> Path.win("\\\\server\\dir"        ).toString() == "\\\\server\\dir"
    * >>> Path.win("\\\\server"             ).toString() == "\\\\server\\"
    * >>> Path.win("\\\\"                   ).toString() throws '[path] UNC path "\\\\" is missing hostname.'
    * >>> Path.win("\\\\?\\UNC\\server\\dir").toString() == "\\\\server\\dir"
    * >>> Path.win("\\\\?\\UNC\\server"     ).toString() == "\\\\server\\"
    * >>> Path.win("\\\\?\\C:\\dir"         ).toString() == "C:\\dir"
    * >>> Path.win("\\\\?\\C:"              ).toString() == "C:\\"
    * >>> Path.win("\\\\?\\server\\dir"     ).toString() == "\\\\server\\dir"
    * >>> Path.win("\\\\?\\server"          ).toString() == "\\\\server\\"
    * >>> Path.win("\\\\.\\C:\\dir"         ).toString() == "C:\\dir"
    * >>> Path.win("\\\\.\\C:"              ).toString() == "C:\\"
    * </code></pre>
    *
    * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
    */
   inline
   public static function win(path:String, trimWhiteSpaces = true):WindowsPath
      return WindowsPath.of(path, trimWhiteSpaces);


   /**
    * The operating system specific directory separator (Unix: slash or Windows: backslash).
    *
    * <pre><code>
    * >>> Path.win("C:\\foo").dirSep == "\\"
    * >>> Path.unix("/foo"   ).dirSep == "/"
    * </code></pre>
    */
   public var dirSep(default, null):String;


   /**
    * The operating system specific directory separator (Unix: colon or Windows: semicolon).
    *
    * <pre><code>
    * >>> Path.win("C:\\foo").pathSep == ";"
    * >>> Path.unix("/foo"   ).pathSep == ":"
    * </code></pre>
    */
   public var pathSep(default, null):String;


   /**
    * The file name extension separator (dot).
    *
    * <pre><code>
    * >>> Path.win("C:\\foo").extSep == "."
    * >>> Path.unix("/foo"   ).extSep == "."
    * </code></pre>
    */
   public var extSep(default, null):String = ".";


   /**
    * Indicates if the given path is a absolute.
    *
    * <pre><code>
    * >>> Path.win("C:"           ).isAbsolute == true
    * >>> Path.win("C:\\"         ).isAbsolute == true
    * >>> Path.win("C:\\dir\\file").isAbsolute == true
    * >>> Path.win("C:D"          ).isAbsolute == false
    * >>> Path.win("\\"           ).isAbsolute == false
    * >>> Path.win("1:\\"         ).isAbsolute == false
    * >>> Path.win("dir\\file"    ).isAbsolute == false
    * >>> Path.win("..\\dir"      ).isAbsolute == false
    * >>> Path.win(".\\dir"       ).isAbsolute == false
    * >>> Path.win(".."           ).isAbsolute == false
    * >>> Path.win("."            ).isAbsolute == false
    * >>> Path.win(""             ).isAbsolute == false
    * >>> Path.win(null           ).isAbsolute == false
    * >>> Path.win("\\\\server\\dir"        ).isAbsolute == true
    * >>> Path.win("\\\\?\\UNC\\server\\dir").isAbsolute == true
    * >>> Path.win("\\\\?\\C:\\dir"         ).isAbsolute == true
    * >>> Path.win("\\\\?\\server\\dir"     ).isAbsolute == true
    * >>> Path.win("\\\\.\\C:\\dir"         ).isAbsolute == true
    *
    * >>> Path.unix("/"           ).isAbsolute == true
    * >>> Path.unix("/dir/../file").isAbsolute == true
    * >>> Path.unix("dir/file"    ).isAbsolute == false
    * >>> Path.unix("../dir"      ).isAbsolute == false
    * >>> Path.unix("./dir"       ).isAbsolute == false
    * >>> Path.unix(".."          ).isAbsolute == false
    * >>> Path.unix("."           ).isAbsolute == false
    * >>> Path.unix(""            ).isAbsolute == false
    * >>> Path.unix(null          ).isAbsolute == false
    * </code></pre>
    */
   public var isAbsolute(get, never):Bool;
   inline function get_isAbsolute():Bool
       return root != null;


   /**
    * Indicates if this object represents a path compatible with the local operating/file system.
    */
   public var isLocal(default, null):Bool;


   /**
    * <pre><code>
    * >>> Path.win("C:\\foo").isRoot         == false
    * >>> Path.win("C:\\foo").parent.isRoot  == true
    * >>> Path.unix("/foo"   ).isRoot        == false
    * >>> Path.unix("/foo"   ).parent.isRoot == true
    * </code></pre>
    */
   public var isRoot(get, never):Bool;
   inline function get_isRoot():Bool
       return isAbsolute && parent == null;


   /**
    * Indicates if this object represents a Unix style path.
    *
    * <pre><code>
    * >>> Path.win("C:\\foo").isUnix == false
    * >>> Path.unix("/foo"   ).isUnix == true
    * </code></pre>
    */
   public var isUnix(default, null):Bool;


   /**
    * Indicates if this object represents a Windows style path.
    *
    * <pre><code>
    * >>> Path.win("C:\\foo").isWindows == true
    * >>> Path.unix("/foo"   ).isWindows == false
    * </code></pre>
    */
   public var isWindows(default, null):Bool;


   /**
    * Protected constructor.
    */
   function new(parent:Path, filename:String) {
      this.parent = parent;
      this.filename = filename;
   }


   function assertIsLocal() {
      if (!isLocal) {
         var className = Type.getClassName(Type.getClass(this));
         throw 'This path object of type "$className" is not compatible with the local operating/file system';
      }
   }


   #if (filesystem_support || macro)
   /**
    * <b>IMPORTANT:</b> Performs I/O operation.
    *
    * <pre><code>
    * >>> Path.of("CHANGELOG.md"  ).exists() == true
    * >>> Path.of("./CHANGELOG.md").exists() == true
    * >>> Path.of("src"           ).exists() == true
    * >>> Path.of("./src"         ).exists() == true
    * >>> Path.of("foobar.txt"    ).exists() == false
    * >>> Path.of("./foobar.txt"  ).exists() == false
    * >>> Path.of(".."            ).exists() == true
    * >>> Path.of("."             ).exists() == true
    * >>> Path.of(""              ).exists() == false
    * >>> Path.of(null            ).exists() == false
    * </code></pre>
    *
    * @return true if the path exists (does not check wether it points to a file or a directory)
    *
    * @throws if path is not compatible with local operating/file system
    */
   public function exists():Bool {
      if(filename == null)
         return false;

      assertIsLocal();

      var path = toString();

      #if php
         // workaround for https://github.com/HaxeFoundation/haxe/issues/6960
         #if (haxe_ver >= 4)
            php.Syntax.code("clearstatcache({0})", path);
         #else
            untyped __php__("clearstatcache($path)");
         #end
      #end

      #if lua
         // workaround for https://github.com/HaxeFoundation/haxe/issues/6946
         return lua.lib.luv.fs.FileSystem.stat(path).result != null;
      #elseif (sys || macro || nodejs)
         return sys.FileSystem.exists(path);
      #elseif phantomjs
         return js.phantomjs.FileSystem.exists(path);
      #else
         throw "Operation not supported on current target.";
      #end
   }
   #end


   /**
    * The filename (without parent directory).
    *
    * <pre><code>
    * >>> Path.win("C:\\file.txt"     ).filename == "file.txt"
    * >>> Path.win("C:\\foo\\file.txt").filename == "file.txt"
    * >>> Path.win("foo\\file.txt"    ).filename == "file.txt"
    * >>> Path.win(".\\foo\\file.txt" ).filename == "file.txt"
    * >>> Path.win("..\\..\\file.txt" ).filename == "file.txt"
    * >>> Path.win("C:\\"             ).filename == "C:\\"
    * >>> Path.win("\\"               ).filename == "\\"
    * >>> Path.win(".."               ).filename == ".."
    * >>> Path.win("."                ).filename == "."
    * >>> Path.win(""                 ).filename == ""
    * >>> Path.win(null               ).filename == null
    * >>> Path.win("\\\\server\\dir\\"        ).filename == "dir"
    * >>> Path.win("\\\\?\\C:\\dir\\"         ).filename == "dir"
    * >>> Path.win("\\\\?\\UNC\\server\\dir\\").filename == "dir"
    * >>> Path.win("\\\\?\\server\\dir\\"     ).filename == "dir"
    * >>> Path.win("\\\\.\\C:\\dir\\"         ).filename == "dir"
    *
    * >>> Path.unix("/file.txt"     ).filename == "file.txt"
    * >>> Path.unix("/foo/file.txt" ).filename == "file.txt"
    * >>> Path.unix("foo/file.txt"  ).filename == "file.txt"
    * >>> Path.unix("./foo/file.txt").filename == "file.txt"
    * >>> Path.unix("../../file.txt").filename == "file.txt"
    * >>> Path.unix("/"             ).filename == "/"
    * >>> Path.unix(".."            ).filename == ".."
    * >>> Path.unix("."             ).filename == "."
    * >>> Path.unix(""              ).filename == ""
    * >>> Path.unix(null            ).filename == null
    * </code></pre>
    */
   public var filename(default, null):String;


   /**
    * The file base name (i.e. without extension).
    *
    * <pre><code>
    * >>> Path.win("C:\\file"            ).filenameStem == "file"
    * >>> Path.win("C:\\foo\\file.txt"   ).filenameStem == "file"
    * >>> Path.win("foo\\file.tar.gz"    ).filenameStem == "file.tar"
    * >>> Path.win(".\\dir.cfg\\file.txt").filenameStem == "file"
    * >>> Path.win("C:\\"                ).filenameStem == "C:\\"
    * >>> Path.win("\\"                  ).filenameStem == "\\"
    * >>> Path.win(".."                  ).filenameStem == ".."
    * >>> Path.win("."                   ).filenameStem == "."
    * >>> Path.win(""                    ).filenameStem == ""
    * >>> Path.win(null                  ).filenameStem == null
    * >>> Path.win("\\\\server\\dir\\"        ).filenameStem == "dir"
    * >>> Path.win("\\\\?\\C:\\dir\\"         ).filenameStem == "dir"
    * >>> Path.win("\\\\?\\server\\dir\\"     ).filenameStem == "dir"
    * >>> Path.win("\\\\?\\UNC\\server\\dir\\").filenameStem == "dir"
    * >>> Path.win("\\\\.\\C:\\dir\\"         ).filenameStem == "dir"
    *
    * >>> Path.unix("/file"             ).filenameStem == "file"
    * >>> Path.unix("/foo/file.txt"     ).filenameStem == "file"
    * >>> Path.unix("foo/file.tar.gz"   ).filenameStem == "file.tar"
    * >>> Path.unix("./dir.cfg/file.txt").filenameStem == "file"
    * >>> Path.unix("/"                 ).filenameStem == "/"
    * >>> Path.unix(".."                ).filenameStem == ".."
    * >>> Path.unix("."                 ).filenameStem == "."
    * >>> Path.unix(""                  ).filenameStem == ""
    * >>> Path.unix(null                ).filenameStem == null
    * </code></pre>
    */
   public var filenameStem(get, never):String;
   function get_filenameStem() {
      if (filename == null)
         return null;
      if (filename.length == 1 || filename == "..")
         return filename;
      return filename.substringBeforeLast(extSep, INPUT);
   }


   /**
    * The filename extension.
    *
    * <pre><code>
    * >>> Path.win("C:\\file"            ).filenameExt == ""
    * >>> Path.win("C:\\foo\\file.txt"   ).filenameExt == "txt"
    * >>> Path.win("foo\\file.tar.gz"    ).filenameExt == "gz"
    * >>> Path.win(".\\dir.cfg\\file.txt").filenameExt == "txt"
    * >>> Path.win("C:\\"                ).filenameExt == ""
    * >>> Path.win("\\"                  ).filenameExt == ""
    * >>> Path.win(".."                  ).filenameExt == ""
    * >>> Path.win("."                   ).filenameExt == ""
    * >>> Path.win(""                    ).filenameExt == ""
    * >>> Path.win(null                  ).filenameExt == null
    * >>> Path.win("\\\\server\\dir\\"        ).filenameExt == ""
    * >>> Path.win("\\\\?\\C:\\dir\\"         ).filenameExt == ""
    * >>> Path.win("\\\\?\\server\\dir\\"     ).filenameExt == ""
    * >>> Path.win("\\\\?\\UNC\\server\\dir\\").filenameExt == ""
    * >>> Path.win("\\\\.\\C:\\dir\\"         ).filenameExt == ""
    *
    * >>> Path.unix("/file"             ).filenameExt == ""
    * >>> Path.unix("/foo/file.txt"     ).filenameExt == "txt"
    * >>> Path.unix("foo/file.tar.gz"   ).filenameExt == "gz"
    * >>> Path.unix("./dir.cfg/file.txt").filenameExt == "txt"
    * >>> Path.unix("/"                 ).filenameExt == ""
    * >>> Path.unix(".."                ).filenameExt == ""
    * >>> Path.unix("."                 ).filenameExt == ""
    * >>> Path.unix(""                  ).filenameExt == ""
    * >>> Path.unix(null                ).filenameExt == null
    * </code></pre>
    */
   public var filenameExt(get, never):String;
   function get_filenameExt() {
      if (filename == null)
         return null;
      if (filename.length == 1 || filename == "..")
         return "";
      return filename.substringAfterLast(extSep, EMPTY);
   }


   /**
    * <b>IMPORTANT:</b> Performs I/O operation.
    *
    * <pre><code>
    * >>> Path.of(".."                    ).getAbsolutePath() != ".."
    * >>> Path.of("."                     ).getAbsolutePath() != "."
    * >>> Path.of("src"                   ).getAbsolutePath() != "src"
    * >>> Path.of(null                    ).getAbsolutePath() == null
    *
    * >>> Path.win("C:\\test\\foo\\..\\bar").getAbsolutePath() == "C:\\test\\bar"
    *
    * >>> Path.unix("/test/foo/../bar"      ).getAbsolutePath() == "/test/bar"
    * </code></pre>
    */
   public function getAbsolutePath():String {

      if (filename == null)
         return null;

      if (isAbsolute)
         return normalize().toString();

      assertIsLocal();

      var path = toString();

      #if (sys || macro || nodejs)
         return sys.FileSystem.absolutePath(path);
      #elseif phantomjs
         return js.phantomjs.FileSystem.absolute(path);
      #else
         throw "Operation not supported on current target.";
      #end
   }

   #if (filesystem_support || macro)

   #if (sys || macro || nodejs)
   /**
     *
     * @return null if no filesystem object exists on the path
     */
   inline
   public function stat():sys.FileStat {
      if (!exists())
          return null;
      return sys.FileSystem.stat(toString());
   }
   #end


   /**
    * <b>IMPORTANT:</b> Performs I/O operation.
    *
    * <pre><code>
    * >>> Path.of("README.md"   ).getModificationTime() > 0
    * >>> Path.of("src"         ).getModificationTime() > 0
    * >>> Path.of(".."          ).getModificationTime() > 0
    * >>> Path.of("."           ).getModificationTime() > 0
    * >>> Path.of(""            ).getModificationTime() == -1
    * >>> Path.of("non-existing").getModificationTime() == -1
    * >>> Path.of(null          ).getModificationTime() == -1
    * <code></pre>
    *
    * @return -1 if path does not exist
    */
   public function getModificationTime():Float {
      if (!exists())
         return -1;

      assertIsLocal();

      var path = toString();

      #if (sys || macro || nodejs)
         #if python
            // workaround to get ms precision
            return 1000 * python.lib.Os.stat(path).st_mtime;
         #else
            var stat = sys.FileSystem.stat(path);
            return stat.mtime == null ? stat.ctime.getTime() : stat.mtime.getTime();
         #end
      #elseif phantomjs
         return js.Lib.require('fs').lastModified(path);
      #else
         throw "Operation not supported on current target.";
      #end
   }


   /**
    * <b>IMPORTANT:</b> Performs I/O operation.
    *
    * Determines if this path currently points to an existing directory.
    *
    * <pre><code>
    * >>> Path.of("README.md"   ).isDirectory() == false
    * >>> Path.of("src"         ).isDirectory() == true
    * >>> Path.of(".."          ).isDirectory() == true
    * >>> Path.of("."           ).isDirectory() == true
    * >>> Path.of(""            ).isDirectory() == false
    * >>> Path.of("non-existing").isDirectory() == false
    * >>> Path.of(null          ).isDirectory() == false
    * <code></pre>
    */
   public function isDirectory():Bool {
      if (!exists())
         return false;

      assertIsLocal();

      var path = toString();

      #if (sys || macro || nodejs)
         return sys.FileSystem.isDirectory(path);
      #elseif phantomjs
         return js.phantomjs.FileSystem.isDirectory(path);
      #else
         throw "Operation not supported on current target.";
      #end
   }


   /**
    * <b>IMPORTANT:</b> Performs I/O operation.
    *
    * Determines if this path currently points to an existing regular file.
    *
    * <pre><code>
    * >>> Path.of("README.md"   ).isFile() == true
    * >>> Path.of("src"         ).isFile() == false
    * >>> Path.of(".."          ).isFile() == false
    * >>> Path.of("."           ).isFile() == false
    * >>> Path.of(""            ).isFile() == false
    * >>> Path.of("non-existing").isFile() == false
    * >>> Path.of(null          ).isFile() == false
    * <code></pre>
    */
   public function isFile():Bool {
      if (!exists())
         return false;

      #if cpp
         return "file" == untyped __cpp__('_hx_std_sys_file_type(toString())');
      #elseif cs
         return untyped __cs__("global::System.IO.File.Exists(toString())");
      #elseif java
         return untyped __java__("new java.io.File(toString()).isFile()");
      #elseif (nodejs && !macro)
         return js.node.Fs.statSync(toString()).isFile();
      #elseif (phantomjs && !macro)
         return js.phantomjs.FileSystem.isFile(toString());
      #elseif php
         #if (haxe_ver >= 4)
            return php.Syntax.code("is_file({0})", toString());
         #else
            return untyped __php__("is_file($this->toString())");
         #end
      #elseif python
         return python.lib.os.Path.isfile(toString());
      #else
         return !isDirectory();
      #end
   }
   #end // filesystem_support

   /**
    * Joins the given parts.
    *
    * <pre><code>
    * >>> Path.win("C:" ).join("file"     ).toString() == "C:\\file"
    * >>> Path.win("dir").join("file"     ).toString() == "dir\\file"
    * >>> Path.win("dir").join("dir\\file").toString() == "dir\\dir\\file"
    * >>> Path.win("dir").join(".."       ).toString() == "dir\\.."
    * >>> Path.win("dir").join(""         ).toString() == "dir"
    * >>> Path.win("dir").join(null       ).toString() == "dir"
    * >>> Path.win(""   ).join("dir"      ).toString() == "dir"
    * >>> Path.win(null ).join("dir"      ).toString() == null
    *
    * >>> Path.unix("/"  ).join("file"    ).toString() == "/file"
    * >>> Path.unix("dir").join("file"    ).toString() == "dir/file"
    * >>> Path.unix("dir").join("dir/file").toString() == "dir/dir/file"
    * >>> Path.unix("dir").join(".."      ).toString() == "dir/.."
    * >>> Path.unix("dir").join(""        ).toString() == "dir"
    * >>> Path.unix("dir").join(null      ).toString() == "dir"
    * >>> Path.unix(""   ).join("dir"     ).toString() == "dir"
    * >>> Path.unix(""   ).join("dir/file").toString() == "dir/file"
    * >>> Path.unix(null ).join("dir"     ).toString() == null
    * </code><pre>
    *
    * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
    */
   public function join(path:Either2<String, Path>, trimWhiteSpaces = true):Path {
      if (path == null || filename == null)
         return this;

      if (filename.isEmpty()) {
         return switch(path.value) {
            case a(str): newPathForString(str, trimWhiteSpaces);
            case b(obj): obj;
         }
      }

      var joinWith = switch(path.value) {
         case a(str): str;
         case b(obj): obj.toString();
      }

      if (joinWith.contains(UnixPath.DIR_SEP) || joinWith.contains(WindowsPath.DIR_SEP)) {
         var thisPath = toString();
         if (thisPath.endsWith(dirSep))
            return newPathForString(thisPath + joinWith, trimWhiteSpaces);

         return newPathForString(thisPath + dirSep + joinWith, trimWhiteSpaces);
      }

      var file = trimWhiteSpaces ? joinWith.trim() : joinWith;
      if (file.isEmpty())
         return this;
      return newPathForChild(file);
   }


   /**
    * Joins the given parts.
    *
    * <pre><code>
    * >>> Path.win("C:" ).joinAll(["dir", "file"     ]).toString() == "C:\\dir\\file"
    * >>> Path.win("dir").joinAll(["dir", "file"     ]).toString() == "dir\\dir\\file"
    * >>> Path.win("dir").joinAll(["dir", "dir\\file"]).toString() == "dir\\dir\\dir\\file"
    * >>> Path.win("dir").joinAll(["dir", ".."       ]).toString() == "dir\\dir\\.."
    * >>> Path.win("dir").joinAll(["dir", ""         ]).toString() == "dir\\dir"
    * >>> Path.win("dir").joinAll(["dir", null       ]).toString() == "dir\\dir"
    * >>> Path.win(""   ).joinAll(["dir", "dir"      ]).toString() == "dir\\dir"
    * >>> Path.win(null ).joinAll(["dir", "dir"      ]).toString() == null
    *
    * >>> Path.unix("/"  ).joinAll(["dir", "file"    ]).toString() == "/dir/file"
    * >>> Path.unix("dir").joinAll(["dir", "file"    ]).toString() == "dir/dir/file"
    * >>> Path.unix("dir").joinAll(["dir", "dir/file"]).toString() == "dir/dir/dir/file"
    * >>> Path.unix("dir").joinAll(["dir", ".."      ]).toString() == "dir/dir/.."
    * >>> Path.unix("dir").joinAll(["dir", ""        ]).toString() == "dir/dir"
    * >>> Path.unix("dir").joinAll(["dir", null      ]).toString() == "dir/dir"
    * >>> Path.unix(""   ).joinAll(["dir", "dir"     ]).toString() == "dir/dir"
    * >>> Path.unix(null ).joinAll(["dir", "dir"     ]).toString() == null
    * </code><pre>
    *
    * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
    */
   public function joinAll(paths:Array<Either2<String, Path>>, trimWhiteSpaces = true):Path {
      if (filename == null || paths == null || paths.length == 0)
         return this;

      if (paths.length == 1)
         return join(paths[0], trimWhiteSpaces);

      var sb = new StringBuilder();
      var thisPath = toString();
      if (thisPath.isNotEmpty())
         sb.add(thisPath).add(dirSep);

      for (path in paths) {
         if (path == null) continue;
         var joinWith = switch(path.value) {
            case a(str): str;
            case b(obj): obj.toString();
         }
         if (trimWhiteSpaces)
            joinWith = joinWith.trim();
         if(joinWith.isNotEmpty())
            sb.add(joinWith).add(dirSep);
     }

      return newPathForString(sb.toString(), trimWhiteSpaces);
   }


   /**
    * The parent directory, may be null.
    *
    * <pre><code>
    * >>> Path.win("C:\\file"            ).parent.toString() == "C:\\"
    * >>> Path.win("C:\\foo\\file.txt"   ).parent.toString() == "C:\\foo"
    * >>> Path.win("foo\\file.tar.gz"    ).parent.toString() == "foo"
    * >>> Path.win(".\\dir.cfg\\file.txt").parent.toString() == ".\\dir.cfg"
    * >>> Path.win("\\dir.cfg\\file.txt" ).parent.toString() == "\\dir.cfg"
    * >>> Path.win("C:\\"                ).parent == null
    * >>> Path.win("\\"                  ).parent == null
    * >>> Path.win(".."                  ).parent == null
    * >>> Path.win("."                   ).parent == null
    * >>> Path.win(""                    ).parent == null
    * >>> Path.win(null                  ).parent == null
    * >>> Path.win("\\\\server\\dir"        ).parent.toString() == "\\\\server\\"
    * >>> Path.win("\\\\server"             ).parent == null
    * >>> Path.win("\\\\?\\C:\\dir"         ).parent.toString() == "C:\\"
    * >>> Path.win("\\\\?\\server\\dir"     ).parent.toString() == "\\\\server\\"
    * >>> Path.win("\\\\?\\server"          ).parent == null
    * >>> Path.win("\\\\?\\UNC\\server\\dir").parent.toString() == "\\\\server\\"
    * >>> Path.win("\\\\?\\UNC\\server"     ).parent == null
    * >>> Path.win("\\\\.\\C:\\dir"         ).parent.toString() == "C:\\"
    *
    * >>> Path.unix("/file"             ).parent.toString() == "/"
    * >>> Path.unix("/foo/file.txt"     ).parent.toString() == "/foo"
    * >>> Path.unix("foo/file.tar.gz"   ).parent.toString() == "foo"
    * >>> Path.unix("./dir.cfg/file.txt").parent.toString() == "./dir.cfg"
    * >>> Path.unix("/"                 ).parent == null
    * >>> Path.unix(".."                ).parent == null
    * >>> Path.unix("."                 ).parent == null
    * >>> Path.unix(""                  ).parent == null
    * >>> Path.unix(null                ).parent == null
    * </code></pre>
    */
   public var parent(default, null):Path;


   /**
    * The root directory or null if the path is not absolute.
    *
    * <pre><code>
    * >>> Path.win("C:\\file"            ).root.toString() == "C:\\"
    * >>> Path.win("C:\\foo\\file.txt"   ).root.toString() == "C:\\"
    * >>> Path.win("foo\\file.tar.gz"    ).root == null
    * >>> Path.win(".\\dir.cfg\\file.txt").root == null
    * >>> Path.win("\\dir.cfg\\file.txt" ).root == null
    * >>> Path.win("C:\\"                ).root.toString() == "C:\\"
    * >>> Path.win("\\"                  ).root == null
    * >>> Path.win(".."                  ).root == null
    * >>> Path.win("."                   ).root == null
    * >>> Path.win(""                    ).root == null
    * >>> Path.win(null                  ).root == null
    * >>> Path.win("\\\\server\\dir"        ).root.toString() == "\\\\server\\"
    * >>> Path.win("\\\\server"             ).root.toString() == "\\\\server\\"
    * >>> Path.win("\\\\?\\UNC\\server\\dir").root.toString() == "\\\\server\\"
    * >>> Path.win("\\\\?\\UNC\\server"     ).root.toString() == "\\\\server\\"
    * >>> Path.win("\\\\?\\server\\dir"     ).root.toString() == "\\\\server\\"
    * >>> Path.win("\\\\?\\server"          ).root.toString() == "\\\\server\\"
    * >>> Path.win("\\\\?\\C:\\dir"         ).root.toString() == "C:\\"
    * >>> Path.win("\\\\?\\C:"              ).root.toString() == "C:\\"
    * >>> Path.win("\\\\.\\C:\\dir"         ).root.toString() == "C:\\"
    * >>> Path.win("\\\\.\\C:"              ).root.toString() == "C:\\"
    *
    * >>> Path.unix("/file"             ).root.toString() == "/"
    * >>> Path.unix("/foo/file.txt"     ).root.toString() == "/"
    * >>> Path.unix("foo/file.tar.gz"   ).root == null
    * >>> Path.unix("./dir.cfg/file.txt").root == null
    * >>> Path.unix("/"                 ).root.toString() == "/"
    * >>> Path.unix(".."                ).root == null
    * >>> Path.unix("."                 ).root == null
    * >>> Path.unix(""                  ).root == null
    * >>> Path.unix(null                ).root == null
    * </code></pre>
    */
   public var root(get, null):Path;
   function get_root():Path throw "Not implemented";


   inline
   public function toDir():Dir
      return Dir.of(this);


   inline
   public function toFile():File
      return File.of(this);


   /**
    * The string representation of this path instance with a trailing directory separator.
    *
    * <pre><code>
    * >>> Path.win("\\dir\\file"        ).toStringWithTrailingSeparator() == "\\dir\\file\\"
    * >>> Path.win("\\dir\\file\\"      ).toStringWithTrailingSeparator() == "\\dir\\file\\"
    * >>> Path.win("\\dir\\\\\\file\\\\").toStringWithTrailingSeparator() == "\\dir\\file\\"
    * >>> Path.win("/dir/file"          ).toStringWithTrailingSeparator() == "\\dir\\file\\"
    * >>> Path.win("c:\\dir\\file"      ).toStringWithTrailingSeparator() == "C:\\dir\\file\\"
    * >>> Path.win("c:\\"               ).toStringWithTrailingSeparator() == "C:\\"
    * >>> Path.win("c:"                 ).toStringWithTrailingSeparator() == "C:\\"
    * >>> Path.win("\\"                 ).toStringWithTrailingSeparator() == "\\"
    * >>> Path.win(".."                 ).toStringWithTrailingSeparator() == "..\\"
    * >>> Path.win("."                  ).toStringWithTrailingSeparator() == ".\\"
    * >>> Path.win(""                   ).toStringWithTrailingSeparator() == ""
    * >>> Path.win(null                 ).toStringWithTrailingSeparator() == null
    *
    * >>> Path.unix("/dir/file"    ).toStringWithTrailingSeparator() == "/dir/file/"
    * >>> Path.unix("/dir/file/"   ).toStringWithTrailingSeparator() == "/dir/file/"
    * >>> Path.unix("/dir///file//").toStringWithTrailingSeparator() == "/dir/file/"
    * >>> Path.unix("\\dir\\file"  ).toStringWithTrailingSeparator() == "/dir/file/"
    * >>> Path.unix("c:\\dir\\file").toStringWithTrailingSeparator() == "c:/dir/file/"
    * >>> Path.unix("/"            ).toStringWithTrailingSeparator() == "/"
    * >>> Path.unix(".."           ).toStringWithTrailingSeparator() == "../"
    * >>> Path.unix("."            ).toStringWithTrailingSeparator() == "./"
    * >>> Path.unix(""             ).toStringWithTrailingSeparator() == ""
    * >>> Path.unix(null           ).toStringWithTrailingSeparator() == null
    * </code></pre>
    */
   public function toStringWithTrailingSeparator():String {
      if (filename.isEmpty())
         return filename;

      var path = toString();
      if (path.endsWith(dirSep))
         return path;
      return path + dirSep;
   }


   public function toString():String {
      if (filename == null)
         return null;

      var parts = new StringArray();
      var part = this;
      while (part != null) {
         parts.push(part.filename);

         var parent = part.parent;

         if (parent != null && !parent.filename.endsWith(dirSep))
            parts.push(dirSep);

         part = parent;
      }

      parts.reverse();
      return parts.join("");
   }


   /**
    * Returns a path instance with all redundant "." and ".." elements removed.
    *
    * <pre><code>
    * >>> Path.win("a\\b\\..\\c\\"   ).normalize().toString() == "a\\c"
    * >>> Path.win("a\\..\\b\\c\\"   ).normalize().toString() == "b\\c"
    * >>> Path.win("a\\..\\..\\b"    ).normalize().toString() == "..\\b"
    * >>> Path.win("C:\\a\\..\\b"    ).normalize().toString() == "C:\\b"
    * >>> Path.win("C:\\..\\..\\b"   ).normalize().toString() == "C:\\b"
    * >>> Path.win("C:\\a\\..\\..\\b").normalize().toString() == "C:\\b"
    * >>> Path.win("C:\\"            ).normalize().toString() == "C:\\"
    * >>> Path.win("C:"              ).normalize().toString() == "C:\\"
    * >>> Path.win(".."              ).normalize().toString() == ".."
    * >>> Path.win("."               ).normalize().toString() == "."
    * >>> Path.win(""                ).normalize().toString() == ""
    * >>> Path.win(null              ).normalize().toString() == null
    *
    * >>> Path.unix("a/b/../c/" ).normalize().toString() == "a/c"
    * >>> Path.unix("a/../b/c/" ).normalize().toString() == "b/c"
    * >>> Path.unix("a/../../b" ).normalize().toString() == "../b"
    * >>> Path.unix("/"         ).normalize().toString() == "/"
    * >>> Path.unix("~"         ).normalize().toString() == "~"
    * >>> Path.unix(".."        ).normalize().toString() == ".."
    * >>> Path.unix("."         ).normalize().toString() == "."
    * >>> Path.unix(""          ).normalize().toString() == ""
    * >>> Path.unix(null        ).normalize().toString() == null
    * </code></pre>
    */
   public function normalize():Path {
      if (parent == null)
         return this;

      var isAbsolute = this.isAbsolute;

      var parts = new StringArray();
      var part = this;
      while (part != null) {
         var parent = part.parent;
         if(parent == null && isAbsolute) break;
         parts.insert(0, part.filename);
         part = parent;
      }

      var resultParts = new StringArray();
      for(part in parts) {
         if(part == ".") {
            if(resultParts.length > 0 || isAbsolute)
               continue;
         } else if(part == "..") {
            var canGoUp = isAbsolute || resultParts.length > 0;
            if (canGoUp && resultParts.last == "..")
               canGoUp = false;

            if (canGoUp) {
               resultParts.pop();
               continue;
            }
         }
         resultParts.push(part);
      }

      return newPathForString(isAbsolute ? root + resultParts.join(dirSep) : resultParts.join(dirSep), false);
   }


   /**
    * <pre><code>
    * >>> Path.win("C:\\Users\\Default\\Desktop\\"     ).ellipsize(15)        == "C:\\...\\Desktop"
    * >>> Path.win("C:\\Users\\Default\\Desktop\\"     ).ellipsize(3)         == "..."
    * >>> Path.win("C:\\Users\\Default\\Desktop\\"     ).ellipsize(7)         == "C:\\..."
    * >>> Path.win("C:\\Users\\Default\\Desktop\\"     ).ellipsize(7,  false) == "..."
    * >>> Path.win("C:\\Users\\Default\\Desktop\\"     ).ellipsize(12, false) == "...\\Desktop"
    * >>> Path.win("C:\\Users\\Default\\Desktop\\..\\..\\John").ellipsize(15) == "C:\\Users\\John"
    * >>> Path.win("\\\\winserver\\documents\\text.doc").ellipsize(25)        == "\\\\winserver\\...\\text.doc"
    * >>> Path.win(""  ).ellipsize(3) == ""
    * >>> Path.win("." ).ellipsize(0) throws "[maxLength] must not be smaller than 1"
    * >>> Path.win(null).ellipsize(3) == null
    * >>> Path.win(null).ellipsize(0) == null
    *
    * >>> Path.unix("/home/user/foo/bar"     ).ellipsize(15)        == '/home/.../bar'
    * >>> Path.unix("/home/user/foo/bar"     ).ellipsize(3)         == '...'
    * >>> Path.unix("/home/user/foo/bar"     ).ellipsize(9)         == '/home/...'
    * >>> Path.unix("/home/user/foo/bar"     ).ellipsize(12, false) == '/.../bar'
    * >>> Path.unix(""  ).ellipsize(3) == ""
    * >>> Path.unix("." ).ellipsize(0) throws "[maxLength] must not be smaller than 1"
    * >>> Path.unix(null).ellipsize(3) == null
    * >>> Path.unix(null).ellipsize(0) == null
    * </code></pre>
    *
    * @throws exception if maxLength < ellipsis.length
    */
   public function ellipsize(maxLength:Int, startFromLeft = true, ellipsis = "..."):String {

      var path = normalize().toString();

      if (path.length8() <= maxLength)
         return path;

      var ellipsisLen = ellipsis.length8();
      if (maxLength < ellipsisLen) {
         if (ellipsisLen > path.length8())
            throw '[maxLength] must not be smaller than ${path.length8()}';
         throw '[maxLength] must not be smaller than ${ellipsisLen}';
      }

      var processLeftSide = startFromLeft;
      var leftPart = new StringBuilder();
      var leftPartsCount = 0;
      var rightPart = new StringBuilder();
      var rightPartsCount = 0;
      var pathParts = path.split8(dirSep);
      var dirSepLen = dirSep.length8();

      for (i in 0...pathParts.length) {
         var partToAdd = processLeftSide ? pathParts[leftPartsCount] : pathParts[pathParts.length - rightPartsCount - 1];
         var newTotalLength = leftPart.length + rightPart.length + ellipsisLen + partToAdd.length8() + dirSepLen;

         if (newTotalLength > maxLength)
            break;

         if (processLeftSide) {
            leftPart.add(partToAdd);
            leftPart.add(dirSep);
            leftPartsCount++;

            // handle special case of Windows network share \\server\folder
            if ((i == 0 || i == 1) && partToAdd.isEmpty())
               continue;

         } else {
            rightPart.insert(0, partToAdd);
            rightPart.insert(0, dirSep);
            rightPartsCount++;
         }
         processLeftSide = !processLeftSide;
      }

      return leftPart + ellipsis + rightPart;
   }


   function newPathForString(path:String, trimWhiteSpaces:Bool):Path
      throw "Not implemented";

   function newPathForChild(filename:String):Path
      throw "Not implemented";
}


@immutable
class UnixPath extends Path {

   /**
    * Unix-flavor directory separator (slash)
    */
   public static inline var DIR_SEP = "/";


   static var NULL(default, never)    = new UnixPath(null, null);
   static var EMPTY(default, never)   = new UnixPath(null, "");
   static var ROOT(default, never)    = new UnixPath(null, "/");
   static var HOME(default, never)    = new UnixPath(null, "~");
   static var CURRENT(default, never) = new UnixPath(null, ".");
   static var PARENT(default, never)  = new UnixPath(null, "..");


   /**
    * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
    */
   public static function of(path:String, trimWhiteSpaces = true):UnixPath {

      if (path == null)
         return NULL;

      var parts = clean(path, trimWhiteSpaces);

      if (parts.length == 0)
         return EMPTY;

      var p:UnixPath = null;
      for (i in 0...parts.length) {
         var part = parts[i];
         if (i == 0) {
            p = switch(part) {
               case "/":  ROOT;
               case "~":  HOME;
               case "..": PARENT;
               default:   new UnixPath(null, part);
            }
         } else
            p = new UnixPath(p, part);
      }
      return p;
   }


   static function clean(path:String, trimWhiteSpaces:Bool):StringArray {
      var parts = path.split8([DIR_SEP, WindowsPath.DIR_SEP]);
      var cleaned = new StringArray();

      for(i in 0...parts.length) {
         var part = parts[i];
         if (trimWhiteSpaces)
            part = part.trim();
         if (i == 0) {
            if (part.isEmpty()) // handles absolute /foo
               cleaned.push("/");
            else
               cleaned.push(part);
         } else if (part.isNotEmpty())
            cleaned.push(part);
      }

      return cleaned;
   }


   function new(parent:Path, file:String) {
      super(parent, file);
      dirSep = DIR_SEP;
      pathSep = ":";
      isLocal = !hx.strings.internal.OS.isWindows;
      isUnix = true;
      isWindows = false;
   }

   override
   function get_root():Path {
      var p:Path = this;
      while (p != null) {
         if (p == ROOT)
            return ROOT;
         p = p.parent;
      }
      return null;
   }


   override
   function newPathForString(path:String, trimWhiteSpaces:Bool):Path
      return of(path, trimWhiteSpaces);


   override
   function newPathForChild(filename:String):Path
      return new UnixPath(this, filename);
}


@immutable
class WindowsPath extends Path {

   /**
    * Windows directory separator (backslash)
    */
   public static inline var DIR_SEP = "\\";
   public static inline var UNC_PREFIX = "\\\\";


   static var NULL(default, never)       = new WindowsPath(null, null);
   static var DRIVE_ROOT(default, never) = new WindowsPath(null, "\\");
   static var EMPTY(default, never)      = new WindowsPath(null, "");
   static var CURRENT(default, never)    = new WindowsPath(null, ".");
   static var PARENT(default, never)     = new WindowsPath(null, "..");


   /**
    * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
    */
   public static function of(path:String, trimWhiteSpaces = true):WindowsPath {

      if (path == null)
         return NULL;

      var parts = clean(path, trimWhiteSpaces);

      if (parts == null || parts.isEmpty())
         return EMPTY;

      var p:WindowsPath = null;
      for (i in 0...parts.length) {
         var part = parts[i];
         if (i == 0) {
            p = switch(part) {
               case "\\": DRIVE_ROOT;
               case "..": PARENT;
               default:   new WindowsPath(null, part);
            }
         } else
             p = new WindowsPath(p, part);
      }
      return p;
   }


   static function clean(path:String, trimWhiteSpaces:Bool):StringArray {
      if (trimWhiteSpaces)
         path = path.trim();

      if (path.isEmpty())
         return null;

      var parts = path.split8([DIR_SEP, UnixPath.DIR_SEP]);
      var cleaned = new StringArray();

      for (i in 0...parts.length) {
         var part = parts[i];
         if (trimWhiteSpaces)
            part = part.trim();
         switch(i) {
            case 0:
               // handle drive relative root \foo
               cleaned.push(part.isEmpty() ? DIR_SEP : part);
            case 1:
               if (part.isEmpty()) {
                  // handle UNC path \\foo
                  if (parts.length > 2 && cleaned[0] == DIR_SEP)
                     cleaned[0] = UNC_PREFIX;
               } else
                  cleaned.push(part);
            default:
               if (part.isNotEmpty()) cleaned.push(part);
         }
      }

      if (cleaned.isEmpty())
         return null;

      // UNC path handling, see https://en.wikipedia.org/wiki/Path_(computing)#Representations_of_paths_by_operating_system_and_shell
      if(cleaned[0] == UNC_PREFIX) {

         if (cleaned.length == 1)
            throw '[path] UNC path "$path" is missing hostname.';

         var part2 = cleaned[1];
         switch(part2) {
            case "?":
               if (cleaned.length == 2)
                  throw '[path] UNC path "$path" is missing hostname or absolute path.';

               var part3 = cleaned[2];

               // \\?\UNC\server\foo\bar\bla.txt
               if (part3.equalsIgnoreCase("UNC")) {
                  if (cleaned.length == 3)
                     throw '[path] UNC path "$path" is missing hostname.';

                  var part4 = cleaned[3];

                  cleaned.shift(); // remove \\
                  cleaned.shift(); // remove ?
                  cleaned.shift(); // remove UNC

                  cleaned[0] = UNC_PREFIX + part4 + DIR_SEP;

               // \\?\C:\foo\bar.txt
               } else if (part3.length == 2 && part3.charCodeAt8(0).isAsciiAlpha() && part3.charCodeAt8(1) == Char.COLON) {

                  cleaned.shift(); // remove \\
                  cleaned.shift(); // remove ?

                  // set drive letter to upper case
                  cleaned[0] = part3.charAt8(0).toUpperCase() + Char.COLON + DIR_SEP;

               // \\?\server\foo\bar.txt
               } else {
                  cleaned.shift(); // remove \\
                  cleaned.shift(); // remove ?

                  cleaned[0] = UNC_PREFIX + part3 + DIR_SEP;
               }

            // \\.\C:\foo\bar.txt
            case ".":
               if (cleaned.length == 2)
                  throw '[path] UNC path "$path" is missing absolute path.';

               var part3 = cleaned[2];
               if (part3.length == 2 && part3.charCodeAt8(0).isAsciiAlpha() && part3.charCodeAt8(1) == Char.COLON) {

                  cleaned.shift(); cleaned.shift();

                  // set drive letter to upper case
                  cleaned[0] = part3.charAt8(0).toUpperCase() + Char.COLON + DIR_SEP;
               } else
                  throw '[path] UNC path "$path" is missing absolute path.';

            default:
               cleaned.shift();

               // \\server\foo\bar.txt
               cleaned[0] = UNC_PREFIX + part2 + DIR_SEP;
         }
      } else {
            var part1 = cleaned[0];
            if (part1.length == 2 && part1.charCodeAt8(0).isAsciiAlpha() && part1.charCodeAt8(1) == Char.COLON)
               // set drive letter to upper case
               cleaned[0] = part1.charAt8(0).toUpperCase() + Char.COLON + DIR_SEP;
        }

        return cleaned;
    }


   function new(parent:Path, file:String) {
      super(parent, file);
      dirSep = DIR_SEP;
      pathSep = ";";
      isLocal = hx.strings.internal.OS.isWindows;
      this.isUnix = false;
      this.isWindows = true;
   }


   override
   function get_root():Path {
      var p:Path = this;
      while (p != null) {
         if (p.parent == null && p != DRIVE_ROOT && p.filename.endsWith(dirSep))
            return p;
         p = p.parent;
      }
      return null;
   }


   override
   function newPathForString(path:String, trimWhiteSpaces:Bool):Path
      return of(path, trimWhiteSpaces);


   override
   function newPathForChild(filename:String):Path
      return new WindowsPath(this, filename);
}
