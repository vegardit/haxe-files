/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files;

import hx.concurrent.ConcurrentException;
import hx.strings.internal.Either2;

#if (sys || macro)
import sys.io.FileInput;
import sys.io.FileOutput;
#end

#if (sys || macro || nodejs)
import sys.FileSystem;
#end

using hx.strings.Strings;

/**
 * Represents a regular file.
 */
class File {

   /**
    * This method does not check if the path actually exists and if it currently points to a directory or a file
    *
    * <pre><code>
    * >>> File.of(null) throws "[path] must not be null"
    * </code></pre>
    *
    * @param trimWhiteSpaces controls if leading/trailing whitespaces of path elements shall be removed automatically
    */
   public static function of(path:Either2<String, Path>, trimWhiteSpaces = true):File {
      if (path == null)
         throw "[path] must not be null";

      return switch(path.value) {
         case a(str): new File(Path.of(str, trimWhiteSpaces));
         case b(obj): new File(obj);
      }
   }


   public final path:Path;


   inline
   private function new(path:Path) {
      this.path = path;
   }

   #if (filesystem_support || macro)

   function assertValidPath(mustExist = true) {
      if (path.filename.isEmpty())
         throw "[path.filename] must not be empty!";

      if (path.exists()) {
         if (!path.isFile()) throw '[path] "$path" exists but is not a file!';
      } else {
         if (mustExist) throw '[path] "$path" does not exist!';
      }
   }


   #if (sys || macro)
   public function openInput(binary = true):FileInput
      return sys.io.File.read(toString(), binary);


   public function openOutput(mode:FileWriteMode, binary = true):FileOutput
      return switch(mode) {
         case REPLACE: sys.io.File.write(toString(), binary);
         case UPDATE:  sys.io.File.update(toString(), binary);
         case APPEND:  sys.io.File.append(toString(), binary);
      }
   #end


   /**
    * <pre><code>
    * >>> File.of("target/test.txt").writeString("HEY!", true)           throws nothing
    * >>> File.of("target/test.txt").appendString("HO!")                 throws nothing
    * >>> File.of("target/test.txt").readAsString().indexOf("HEY!") > -1 == true
    * >>> File.of("target/test.txt").delete()                            == true
    * >>> File.of(""               ).appendString("")                    throws "[path.filename] must not be empty!"
    * </code></pre>
    */
   public function appendString(content:Null<String>):Void {

      assertValidPath(false);

      if (content == null)
         return;

      #if (sys || macro)
         var ex:Null<ConcurrentException> = null;
         var out = sys.io.File.append(path.toString());
         try {
            out.writeString(content);
         } catch (e:Dynamic) {
            ex = ConcurrentException.capture(e);
         }
         out.close();
         if (ex != null)
            ex.rethrow();
      #elseif nodejs
         js.node.Fs.appendFileSync(path.toString(), content);
      #elseif phantomjs
         js.phantomjs.FileSystem.write(path.toString(), content, "a");
      #else
         throw "Operation not supported on current target.";
      #end
   }


   /**
    * Delete the file.
    *
    * <pre><code>
    * >>> File.of("target/test.txt").writeString("HEY!", true) throws nothing
    * >>> File.of("target/test.txt").delete() == true
    * >>> File.of("target"         ).delete() throws '[path] "target" exists but is not a file!'
    * >>> File.of(""               ).delete() == false
    * <code></pre>
    *
    * @return false if path does not exist
    *
    * @throws if path is not a file
    */
   public function delete():Bool {

      if (!path.exists())
         return false;

      assertValidPath();

      #if (sys || macro || nodejs)
         FileSystem.deleteFile(path.toString());
         return true;
      #elseif phantomjs
         js.phantomjs.FileSystem.remove(path.toString());
         return true;
      #else
         throw "Operation not supported on current target.";
      #end
   }


   /**
    * <pre><code>
    * >>> File.of("CHANGELOG.md").readAsBytes().length > 0
    * >>> File.of("nonexistent" ).readAsBytes() == null
    * >>> File.of(""            ).readAsBytes() == null
    * >>> File.of("."           ).readAsBytes() throws '[path] "." exists but is not a file!'
    * >>> File.of("src"         ).readAsBytes() throws '[path] "src" exists but is not a file!'
    * </code></pre>
    *
    * @return null in case the file does not exist
    *
    * @throws if path is not a file
    */
   public function readAsBytes():Null<haxe.io.Bytes> {
      if (!path.exists())
         return null;

      assertValidPath();

      #if (sys || macro || nodejs)
         return sys.io.File.getBytes(path.toString());
      #elseif phantomjs
         return haxe.io.Bytes.ofString(js.phantomjs.FileSystem.read(path.toString()));
      #else
         throw "Operation not supported on current target.";
      #end
   }


   /**
    * <pre><code>
    * >>> File.of("CHANGELOG.md").readAsString().indexOf("Initial release") > -1 == true
    * >>> File.of("nonexistent" ).readAsString() == null
    * >>> File.of(""            ).readAsString() == null
    * >>> File.of("."           ).readAsString() throws '[path] "." exists but is not a file!'
    * >>> File.of("src"         ).readAsString() throws '[path] "src" exists but is not a file!'
    * </code></pre>
    *
    * @param defaultValue string to be returned in case the file does not exist
    *
    * @throws if path is not a file
    */
   public function readAsString(?defaultValue:String):Null<String> {
      if (!path.exists())
         return defaultValue;

      assertValidPath();

      #if (sys || macro || nodejs)
         return sys.io.File.getContent(path.toString());
      #elseif phantomjs
         return js.phantomjs.FileSystem.read(path.toString());
      #else
         throw "Operation not supported on current target.";
      #end
   }


   /**
    * Copies the given file.
    *
    * <pre><code>
    * >>> File.of("target/foo.txt").writeString("HEY!") throws nothing
    * >>> File.of("target/foo.txt").copyTo("target/bar.txt") throws nothing
    * >>> File.of("target/foo.txt").copyTo("target/bar.txt") throws '[newPath] "target' + Path.of("").dirSep + 'bar.txt" already exists!'
    * >>> File.of("target/foo.txt").copyTo("target/bar.txt", [OVERWRITE]) throws nothing
    * >>> File.of("target/foo.txt").path.exists()            == true
    * >>> File.of("target/bar.txt").path.exists()            == true
    * >>> File.of("target/foo.txt").delete()                 == true
    * >>> File.of("target/bar.txt").delete()                 == true
    *
    * >>> File.of("README.md"  ).copyTo(null) throws "[newPath] must not be null!"
    * >>> File.of("README.md"  ).copyTo("")   throws "[newPath] must not be empty!"
    * >>> File.of("nonexistent").copyTo("")   throws '[path] "nonexistent" does not exist!'
    * >>> File.of(""           ).copyTo("")   throws "[path.filename] must not be empty!"
    * </code></pre>
    *
    * @return a File instance pointing to the copy target
    */
   public function copyTo(newPath:Either2<String, Path>, ?options:Array<FileCopyOption>):File {
      if (newPath == null)
         throw "[newPath] must not be null!";

      assertValidPath();

      var trimWhiteSpaces = true;
      var overwrite = false;

      if (options != null) for (o in options) {
         switch(o) {
            case OVERWRITE: overwrite = true;
            case NO_WHITESPACE_TRIMMING: trimWhiteSpaces = false;
         }
      }

      final targetPath:Path = switch(newPath.value) {
         case a(str): Path.of(str, trimWhiteSpaces);
         case b(obj): obj;
      }

      if (targetPath.filename == "")
         throw "[newPath] must not be empty!";

      if (path.getAbsolutePath() == targetPath.getAbsolutePath())
         return this;

      final targetFile = targetPath.toFile();

      if (targetPath.exists()) {
         if (!overwrite)
            throw '[newPath] "$targetPath" already exists!';

         if (!targetPath.isFile())
            throw '[newPath] "$targetPath" already exists and is not a file!';

         targetFile.delete();
      }

      #if (sys || macro || nodejs)
         sys.io.File.copy(path.toString(), targetPath.toString());
      #elseif phantomjs
         js.phantomjs.FileSystem.copy(path.toString(), targetPath.toString());
      #else
         throw "Operation not supported on current target.";
      #end

      return targetFile;
   }


   /**
    * Moves the given file.
    *
    * <pre><code>
    * >>> File.of("target/foo.txt").writeString("HEY!") throws nothing
    * >>> File.of("target/foo.txt").moveTo("target/bar.txt") throws nothing
    * >>> File.of("target/bar.txt").moveTo("target/bar.txt") throws nothing
    * >>> File.of("target/foo.txt").path.exists()            == false
    * >>> File.of("target/bar.txt").path.exists()            == true
    *
    * >>> File.of("target/bar.txt").moveTo(null) throws "[newPath] must not be null!"
    * >>> File.of("target/bar.txt").moveTo("")   throws "[newPath] must not be empty!"
    * >>> File.of("target/bar.txt").delete()     == true
    * >>> File.of(""              ).moveTo("")   throws "[path.filename] must not be empty!"
    * </code></pre>
    *
    * @return a File instance pointing to the new location
    */
   public function moveTo(newPath:Either2<String, Path>, ?options:Array<FileMoveOption>):File {
      if (newPath == null)
         throw "[newPath] must not be null!";

      assertValidPath();

      var trimWhiteSpaces = true;
      var overwrite = false;

      if (options != null) for (o in options) {
         switch(o) {
            case OVERWRITE: overwrite = true;
            case NO_WHITESPACE_TRIMMING: trimWhiteSpaces = false;
         }
      }

      final targetPath:Path = switch(newPath.value) {
         case a(str): Path.of(str, trimWhiteSpaces);
         case b(obj): obj;
      }

      if (targetPath.filename == "")
         throw "[newPath] must not be empty!";

      final targetFile = targetPath.toFile();

      if (targetPath.exists()) {

         if (path.getAbsolutePath() == targetPath.getAbsolutePath())
            return this;

         if (!overwrite)
            throw '[newPath] "$targetPath" already exists!';

         if (targetPath.isDirectory())
            throw '[newPath] "$targetPath" already exists and is a directory!';

         targetFile.delete();
      }

      #if (sys || macro || nodejs)
         FileSystem.rename(path.toString(), targetPath.toString());
      #elseif phantomjs
         js.phantomjs.FileSystem.move(path.toString(), targetPath.toString());
      #else
         throw "Operation not supported on current target.";
      #end

      return targetFile;
   }


   /**
    * Renames the given file within it's current parent directory.
    *
    * <pre><code>
    * >>> File.of("target/foo.txt").writeString("HEY!") throws nothing
    * >>> File.of("target/foo.txt").renameTo("bar.txt") throws nothing
    * >>> File.of("target/foo.txt").path.exists()       == false
    * >>> File.of("target/bar.txt").path.exists()       == true
    * >>> File.of("target/bar.txt").delete()            == true
    *
    * >>> File.of("target/foo.txt").renameTo("target/bar.txt") throws '[newFileName] "target/bar.txt" must not contain directory separators!'
    * >>> File.of("target/foo.txt").renameTo("")               throws "[newFileName] must not be null or empty!"
    * >>> File.of(""              ).renameTo("")               throws "[newFileName] must not be null or empty!"
    * </code></pre>
    *
    * @param newDirName the new directory name (NOT the full path!)
    *
    * @return a File instance pointing to the new location
    */
   public function renameTo(newFileName:String, ?options:Array<FileRenameOption>):File {
      if (newFileName.isEmpty())
         throw "[newFileName] must not be null or empty!";

      if (newFileName.containsAny([Path.UnixPath.DIR_SEP, Path.WindowsPath.DIR_SEP]))
         throw '[newFileName] "$newFileName" must not contain directory separators!';

      var opts:Null<Array<FileMoveOption>> = null;

      if (options != null) for (o in options) {
         switch(o) {
            case OVERWRITE: opts = [OVERWRITE];
         }
      }

      if (path.parent == null)
         return moveTo(newFileName, opts);

      @:nullSafety(Off)
      return moveTo(path.parent.join(newFileName), opts);
   }


   /**
    * @return size in bytes
    */
   public function size():Int {
      if (!path.exists())
         throw '[path] "$path" doesn\'t exists!';

      #if (sys || macro || nodejs)
         final stat = sys.FileSystem.stat(path.toString());
         return stat.size;
      #elseif phantomjs
         return js.phantomjs.FileSystem.size(path.toString());
      #else
         throw "Operation not supported on current target.";
      #end
   }


   /**
    * Creates the file if it does not exist yet or updates the modification timestamp.
    *
    * <pre><code>
    * >>> File.of("target/touch.txt").path.exists() == false
    * >>> File.of("target/touch.txt").touch()       throws nothing
    * >>> File.of("target/touch.txt").path.exists() == true
    * >>> File.of("target/touch.txt").delete()      throws nothing
    * </code></pre>
    */
   public function touch():Void {
      assertValidPath(false);

      #if (sys || macro || nodejs)
         if (path.exists()) {
            if (hx.files.internal.OS.isWindows) {
               Sys.command('copy /b "${path.toString()}"+,,'); // https://superuser.com/a/764721
            } else {
               Sys.command('touch "${path.toString()}"');
            }
         } else {
            writeString("", false);
         }
      #elseif phantomjs
         js.phantomjs.FileSystem.touch(path.toString());
      #else
         throw "Operation not supported on current target.";
      #end
   }


   public function writeBytes(content:haxe.io.Bytes, overwrite = true):Void {

      assertValidPath(false);

      if (path.exists() && !overwrite)
         throw '[path] "$path" already exists!';

      #if (sys || macro || nodejs)
         sys.io.File.saveBytes(path.toString(), content);
      #elseif phantomjs
         js.phantomjs.FileSystem.write(path.toString(), content.toString(), "w");
      #else
         throw "Operation not supported on current target.";
      #end
   }


   /**
    * <pre><code>
    * >>> File.of("target/test.txt").writeString("HEY!")                 throws nothing
    * >>> File.of("target/test.txt").readAsString().indexOf("HEY!") > -1 == true
    * >>> File.of("target/test.txt").writeString("HEY!", false)          throws '[path] "target' + Path.of("").dirSep + 'test.txt" already exists!'
    * >>> File.of("target/test.txt").delete()                            throws nothing
    * >>> File.of(""               ).writeString("")                     throws "[path.filename] must not be empty!"
    * </code></pre>
    */
   public function writeString(content:String, overwrite = true):Void {

      assertValidPath(false);

      if (path.exists() && !overwrite)
         throw '[path] "$path" already exists!';

      if (content == null)
         return;

      #if (sys || macro || nodejs)
         #if (flash || openfl)
         //before writing a string, make sure path's parent exists.
         //if it doesn't, it needs to be created to write the content for OpenFL and AIR/Flash.
         var dir:String = haxe.io.Path.directory(path.toString());
         if (!FileSystem.exists(dir))
            FileSystem.createDirectory(dir);
         var output = sys.io.File.write(path.toString(), false);
         output.writeString(content);
         output.close();
         #else
         //on other targets, this check is unnecessary.
         sys.io.File.saveContent(path.toString(), content);
         #end
      #elseif phantomjs
         js.phantomjs.FileSystem.write(path.toString(), content, "w");
      #else
         throw "Operation not supported on current target.";
      #end
   }

   #end // filesystem_support

   /**
     * @return the file's path
     */
   inline
   public function toString():String
      return path.toString();
}


enum FileWriteMode {
   REPLACE;
   UPDATE;
   APPEND;
}


enum FileRenameOption {
   /**
    * if a file already existing at `newPath` it will be deleted automatically
    */
   OVERWRITE;
}


enum FileCopyOption {
   /**
    * if a file already existing at `newPath` it will be deleted automatically
    */
   OVERWRITE;

   /**
    * If `newPath` is a string do not automatically remove leading/trailing whitespaces of path elements
    */
   NO_WHITESPACE_TRIMMING;
}


enum FileMoveOption {
   /**
    * if a file already existing at `newPath` it will be deleted automatically
    */
   OVERWRITE;

   /**
    * If `newPath` is a string do not automatically remove leading/trailing whitespaces of path elements
    */
   NO_WHITESPACE_TRIMMING;
}
