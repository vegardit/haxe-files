/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.executor.Executor;
import hx.concurrent.internal.Dates;
import hx.concurrent.lock.RLock;
import hx.doctest.DocTestRunner;
import hx.files.internal.OS;
#if filesystem_support
import hx.files.watcher.FileWatcher.FileSystemEvent;
import hx.files.watcher.PollingFileWatcher;
#end

@:build(hx.doctest.DocTestGenerator.generateDocTests())
@:keep // prevent DCEing of manually created testXYZ() methods
class TestRunner extends DocTestRunner {

   #if threads
   @:keep
   static final __static_init = {
      /*
       * synchronize trace calls
       */
      final sync = new RLock();
      final old = haxe.Log.trace;
      haxe.Log.trace = function(v:Dynamic, ?pos: haxe.PosInfos ):Void {
         sync.execute(function() old(v, pos));
      }
   }
   #end


   public static function main() {
      final runner = new TestRunner();
      runner.runAndExit();
   }


   #if java
   public function testJavaFileWatcher():Void {
      if (OS.isMacOS) {
         trace("Skipping test of JavaFileWatcher on MacOS.");
         return;
      }

      var ex = Executor.create();
      var fw = new hx.files.watcher.JavaFileWatcher(ex);

      var events = new Array<FileSystemEvent>();
      fw.subscribe(function (event) {
         var path = switch(event) {
            case DIR_CREATED(dir): dir.path;
            case DIR_DELETED(dir): dir.path;
            case DIR_MODIFIED(dir, _): dir.path;
            case FILE_CREATED(file): file.path;
            case FILE_DELETED(file): file.path;
            case FILE_MODIFIED(file, _): file.path;
         }
         trace('EVENT: ${event.getName()}: $path');
         events.push(event);
      });

      var dir = Dir.of("target/filewatcher_test");
      dir.delete(true);
      dir.create();

      fw.watch(dir.path);

      Sys.sleep(0.2); dir.path.join("foo").toDir().create();
      Sys.sleep(0.2); dir.path.join(OS.isWindows ? "foo/test.txt" : "text.txt").toFile().writeString("123");
      Sys.sleep(0.2); dir.path.join(OS.isWindows ? "foo/test.txt" : "text.txt").toFile().appendString("456");
      Sys.sleep(0.2); dir.path.join("foo").toDir().delete(true);
      Sys.sleep(0.6);

      assertEquals(Lambda.count(events, e -> e.match(DIR_CREATED(_))), 1);
      assertEquals(Lambda.count(events, e -> e.match(DIR_DELETED(_))), 1);
      assertEquals(Lambda.count(events, e -> e.match(FILE_CREATED(_))), 1);
      assertMin(Lambda.count(events, e -> e.match(FILE_MODIFIED(_))), 2);
      assertEquals(Lambda.count(events, e -> e.match(FILE_DELETED(_))), 0);

      // deleting a standalone file must emit FILE_DELETED
      events = new Array<FileSystemEvent>();
      var singleFile = dir.path.join(OS.isWindows ? "test2.txt" : "single.txt").toFile();
      Sys.sleep(0.2); singleFile.writeString("123");
      Sys.sleep(0.4); singleFile.appendString("456");
      Sys.sleep(0.4); singleFile.delete();
      Sys.sleep(0.8);
      assertEquals(Lambda.count(events, e -> e.match(FILE_DELETED(_))), 1);

      fw.unwatch(dir.path);

      events = new Array<FileSystemEvent>();
      Sys.sleep(0.2); dir.path.join("foo").toDir().create();
      Sys.sleep(0.2); dir.path.join("test.txt").toFile().writeString("123");
      Sys.sleep(0.6);

      assertEquals(events.length, 0);

      fw.stop();
      ex.stop();

      dir.delete(true);
   }
   #end


   #if filesystem_support
   public function testPollingFileWatcher_SingleFile():Void {
      var ex = Executor.create();
      var fw = new PollingFileWatcher(ex, 200);

      var events = new Array<FileSystemEvent>();
      fw.subscribe(function (event) {
         var path = switch(event) {
            case DIR_CREATED(dir): dir.path;
            case DIR_DELETED(dir): dir.path;
            case DIR_MODIFIED(dir, _): dir.path;
            case FILE_CREATED(file): file.path;
            case FILE_DELETED(file): file.path;
            case FILE_MODIFIED(file, _): file.path;
         }
         trace('EVENT: ${event.getName()}: $path');
         events.push(event);
      });

      var file = File.of("target/filewatcher_test.txt");
      file.delete();
      fw.watch(file.path);

      _later(1000, function() { file.writeString("123");    trace("-> create: "  + file ); });
      _later(2000, function() { file.appendString("456");   trace("-> append: "  + file ); });
      _later(3000, function() { file.writeString("12345_"); trace("-> replace: " + file ); }); // using larger delay because some FileSystems (ext3) and/or targets (e.g. HL) do not support ms-precision of mtime
      _later(4000, function() { file.delete();              trace("-> delete: "  + file ); });
      _later(5000, function() {
         fw.stop();
         ex.stop();

         assertEquals(Lambda.count(events, e -> e.match(FILE_CREATED(_))), 1);
         assertMin(Lambda.count(events, e -> e.match(FILE_MODIFIED(_))), 2);
         assertEquals(Lambda.count(events, e -> e.match(FILE_DELETED(_))), 1);
      });
   }


   public function testPollingFileWatcher_DirTree():Void {
      var ex = Executor.create();
      var fw = new PollingFileWatcher(ex, 200);

      var events = new Array<FileSystemEvent>();
      fw.subscribe(function (event) {
         var path = switch(event) {
            case DIR_CREATED(dir): dir.path;
            case DIR_DELETED(dir): dir.path;
            case DIR_MODIFIED(dir, _): dir.path;
            case FILE_CREATED(file): file.path;
            case FILE_DELETED(file): file.path;
            case FILE_MODIFIED(file, _): file.path;
         }
         trace('EVENT: ${event.getName()}: $path');
         events.push(event);
      });

      var dir = Dir.of("target/filewatcher_test");
      dir.delete(true);
      var subdir = dir.path.join("abc/def").toDir();
      var file = subdir.path.join("test.txt").toFile();

      fw.watch(dir.path);

      _later(100, function() {
         dir.create();
         subdir.create();
         file.writeString("123");
      });
      _later(1000, function() { file.appendString("456"); trace("-> append: "  + file  ); });
      _later(2000, function() { subdir.delete(true);      trace("-> delete: "  + subdir); });
      _later(3000, function() { dir.delete(true);         trace("-> delete: "  + dir   ); });
      _later(4000, function() {
         fw.stop();
         ex.stop();

         assertEquals(Lambda.count(events, e -> e.match(DIR_CREATED(_))), 3);
         assertEquals(Lambda.count(events, e -> e.match(DIR_DELETED(_))), 3);
         assertEquals(Lambda.count(events, e -> e.match(FILE_CREATED(_))), 1);
         assertMin(Lambda.count(events, e -> e.match(FILE_MODIFIED(_))), 1);
         assertEquals(Lambda.count(events, e -> e.match(FILE_DELETED(_))), 1);
      });
   }
   #end // filesystem_support

   public function testFileMacros() {
      assertMin(Dir.of(FileMacros.getProjectRoot()).toString().length, 2);

      #if filesystem_support
         assertEquals(Dir.getCWD().toString(), Dir.of(FileMacros.getProjectRoot()).toString());
      #end

      var targetPath:String = FileMacros.resolvePath("test");
      assertMin(targetPath.length, 7);

      var license:String = FileMacros.readString("LICENSE.txt");
      assertMin(license.indexOf("Apache"), 0);
   }


   final _asyncExecutor = Executor.create(10);
   var _asyncTests = new AtomicInt(0);
   function _later(delayMS:Int, fn:Void->Void) {
      _asyncTests++;
      final future:TaskFuture<Dynamic> = _asyncExecutor.submit(function() {
         try fn() catch (ex:Dynamic) trace(ex);
         _asyncTests--;
      }, ONCE(delayMS));
   }


   override
   function runAndExit(expectedMinNumberOfTests = 0):Void {
      results = new ThreadSafeDocTestResults(this);
      final startTime = Dates.now();
      run(expectedMinNumberOfTests, true, false);

      final t = new haxe.Timer(1000);
      t.run = function() {
         if(_asyncTests.value == 0) {
            t.stop();

            final timeSpent = Std.int((Dates.now() - startTime) / 1000);

            if (results.testsPassed + results.testsFailed == 0) {
               // no tests defined, DocTestRunner will display warning
            } else if (results.testsFailed == 0) {
               hx.doctest.internal.Logger.log(INFO, '**********************************************************');
               hx.doctest.internal.Logger.log(INFO, 'All ${results.testsPassed} test(s) PASSED within $timeSpent seconds.');
               hx.doctest.internal.Logger.log(INFO, '**********************************************************');
            } else {
               hx.doctest.internal.Logger.log(ERROR, '**********************************************************');
               hx.doctest.internal.Logger.log(ERROR, '${results.testsFailed} of ${results.testsPassed + results.testsFailed} test(s) FAILED:');
               results.logFailures();
            }

            #if python
               Sys.sleep(5); // https://bugs.python.org/issue42717
            #end
            final exitCode = results.testsFailed == 0 ? 0 : 1;
            hx.doctest.DocTestRunner.exit(exitCode);
         }
      };
   }
}


private class ThreadSafeDocTestResults extends hx.doctest.DocTestRunner.DefaultDocTestResults {

   final _sync = new RLock();

   function super_add(success:Bool, msg:String, pos:haxe.PosInfos):Void
      super.add(success, msg, pos);

   function super_logFailures():Void
      super.logFailures();

   override
   public function add(success:Bool, msg:String, pos:haxe.PosInfos):Void
      _sync.execute(() -> super_add(success, msg, pos));

   override
   public function logFailures():Void
      _sync.execute(() -> super_logFailures());
}