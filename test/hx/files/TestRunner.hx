/*
 * Copyright (c) 2016-2019 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.executor.Executor;
import hx.concurrent.internal.Dates;
import hx.concurrent.lock.RLock;
import hx.doctest.DocTestRunner;
#if filesystem_support
import hx.files.watcher.FileWatcher.FileSystemEvent;
import hx.files.watcher.PollingFileWatcher;
#end
import hx.strings.internal.OS;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:build(hx.doctest.DocTestGenerator.generateDocTests())
@:keep // prevent DCEing of manually created testXYZ() methods
class TestRunner extends DocTestRunner {

    #if threads
    @:keep
    static var __static_init = {
        /*
         * synchronize trace calls
         */
        var sync = new RLock();
        var old = haxe.Log.trace;
        haxe.Log.trace = function(v:Dynamic, ?pos: haxe.PosInfos ):Void {
            sync.execute(function() old(v, pos));
        }
    }
    #end


    public static function main() {
        var runner = new TestRunner();
        runner.runAndExit();
    }


    #if java
    public function testJavaFileWatcher():Void {
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
        Sys.sleep(0.2);

        assertMin(events.length, 4);

        fw.unwatch(dir.path);

        events = new Array<FileSystemEvent>();
        Sys.sleep(0.2); dir.path.join("foo").toDir().create();
        Sys.sleep(0.2); dir.path.join("test.txt").toFile().writeString("123");
        Sys.sleep(0.2);

        assertEquals(events.length, 0);

        fw.stop();
        ex.stop();

        dir.delete(true);
    }
    #end


    #if filesystem_support
    public function testPollingFileWatcher_SingleFile():Void {
        var ex = Executor.create();
        var fw = new PollingFileWatcher(ex, 100);

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

        _later(  50, function() { file.writeString("123");    trace("-> create: "  + file ); });
        _later( 400, function() { file.appendString("456");   trace("-> append: "  + file ); });
        _later(1800, function() { file.writeString("12345_"); trace("-> replace: " + file ); }); // using larger delay because some FileSystems (ext3) and/or targets (e.g. HL) do not support ms-precision of mtime
        _later(2000, function() { file.delete();              trace("-> delete: "  + file ); });
        _later(2200, function() {
            fw.stop();
            ex.stop();

            assertInRange(events.length, 4, 5);
            assertTrue(switch(events[0]) { case FILE_CREATED(_):  true; default: false; });
            if (events.length == 4) {
                assertTrue(switch(events[1]) { case FILE_MODIFIED(_): true; default: false; });
                assertTrue(switch(events[2]) { case FILE_MODIFIED(_): true; default: false; });
                assertTrue(switch(events[3]) { case FILE_DELETED(_):  true; default: false; });
            } else {
                assertTrue(switch(events[1]) { case FILE_MODIFIED(_): true; default: false; });
                assertTrue(switch(events[2]) { case FILE_MODIFIED(_): true; default: false; });
                assertTrue(switch(events[3]) { case FILE_MODIFIED(_): true; default: false; });
                assertTrue(switch(events[4]) { case FILE_DELETED(_):  true; default: false; });
            }
        });
    }


    public function testPollingFileWatcher_DirTree():Void {
        var ex = Executor.create();
        var fw = new PollingFileWatcher(ex, 100);

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

        _later(50, function() {
            dir.create();
            subdir.create();
            file.writeString("123");
            trace("-> create: "  + file );
        });
        _later( 400, function() { file.appendString("456"); trace("-> append: "  + file  ); });
        _later(1500, function() { subdir.delete(true);      trace("-> delete: "  + subdir); });
        _later(1800, function() { dir.delete(true);         trace("-> delete: "  + dir   ); });
        _later(2200, function() {
            fw.stop();
            ex.stop();

            assertTrue(events.length > 5);
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


    var _asyncExecutor = Executor.create(10);
    var _asyncTests = new AtomicInt(0);
    function _later(delayMS:Int, fn:Void->Void) {
        _asyncTests++;
        var future:TaskFuture<Dynamic> = _asyncExecutor.submit(function() {
            try fn() catch (ex:Dynamic) trace(ex);
            _asyncTests--;
        }, ONCE(delayMS));
    }


    override
    function runAndExit(expectedMinNumberOfTests = 0):Void {
        results = new ThreadSafeDocTestResults();
        var startTime = Dates.now();
        run(expectedMinNumberOfTests, false);

        var t = new haxe.Timer(100);
        t.run = function() {
            if(_asyncTests.value == 0) {
                t.stop();
                var timeSpent = Std.int((Dates.now() - startTime) / 1000);

                if (results.getSuccessCount() + results.getFailureCount() == 0) {
                    // no tests defined, DocTestRunner will display warning
                } else if (results.getFailureCount() == 0) {
                    hx.doctest.internal.Logger.log(INFO, '**********************************************************');
                    hx.doctest.internal.Logger.log(INFO, 'All ${results.getSuccessCount()} test(s) were SUCCESSFUL within $timeSpent seconds.');
                    hx.doctest.internal.Logger.log(INFO, '**********************************************************');
                } else {
                    hx.doctest.internal.Logger.log(ERROR, '**********************************************************');
                    hx.doctest.internal.Logger.log(ERROR, '${results.getFailureCount()} of ${results.getSuccessCount() + results.getFailureCount()} test(s) FAILED:');
                    results.logFailures();
                }

                var exitCode = results.getFailureCount() == 0 ? 0 : 1;
                hx.doctest.DocTestRunner.exit(exitCode);
            }
        };
    }
}


private class ThreadSafeDocTestResults extends hx.doctest.DocTestRunner.DefaultDocTestResults {

    var _sync = new RLock();

    function super_add(success:Bool, msg:String, loc:hx.doctest.internal.Logger.SourceLocation, pos:haxe.PosInfos) {
        super.add(success, msg, loc, pos);
    }
    function super_logFailures() {
        super.logFailures();
    }

    override
    public function add(success:Bool, msg:String, loc:hx.doctest.internal.Logger.SourceLocation, pos:haxe.PosInfos) {
        _sync.execute(function() super_add(success, msg, loc, pos));
    }

    override
    public function getSuccessCount():Int {
        return _sync.execute(function() return _testsOK);
    }

    override
    public function getFailureCount():Int {
        return _sync.execute(function() return _testsFailed.length);
    }

    override
    public function logFailures():Void {
        return _sync.execute(function() super_logFailures());
    }
}