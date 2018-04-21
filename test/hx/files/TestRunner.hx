/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files;

import hx.concurrent.atomic.AtomicInt;
import hx.concurrent.executor.Executor;
import hx.concurrent.internal.Dates;
import hx.concurrent.lock.RLock;
import hx.doctest.DocTestRunner;
import hx.files.watcher.FileWatcher.FileSystemEvent;
import hx.files.watcher.PollingFileWatcher;


/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:build(hx.doctest.DocTestGenerator.generateDocTests("src", ".*\\.hx"))
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


    public function testFileWatcher_SingleFile():Void {
        var ex = Executor.create();

        var file = File.of("target/filewatcher_test.txt");
        file.delete();

        var fw = new PollingFileWatcher(ex, 100);

        var events = new Array<FileSystemEvent>();
        fw.subscribe(function (event) {
            trace('EVENT: ${event.getName()}');
            events.push(event);
        });

        fw.watch(file.path);

        _later(  50, function() { file.writeString("123");    trace("-> create: "  + file ); });
        _later( 400, function() { file.appendString("456");   trace("-> append: "  + file ); });
        _later(1800, function() { file.writeString("12345_"); trace("-> replace: " + file ); }); // using larger delay because some FileSystems (ext3) and/or targets (e.g. HL) do not support ms-precision of mtime
        _later(2000, function() { file.delete();              trace("-> delete: "  + file ); });
        _later(2200, function() {
            fw.stop();
            ex.stop();

            assertEquals(4, events.length);
            assertTrue(switch(events[0]) { case FILE_CREATED(_):  true; default: false; });
            assertTrue(switch(events[1]) { case FILE_MODIFIED(_): true; default: false; });
            assertTrue(switch(events[2]) { case FILE_MODIFIED(_): true; default: false; });
            assertTrue(switch(events[3]) { case FILE_DELETED(_):  true; default: false; });
        });
    }


    public function testFileWatcher_DirTree():Void {
        var ex = Executor.create();

        var dir = Dir.of("target/filewatcher_test");
        var subdir = dir.path.join("abc/def").toDir();
        var file = subdir.path.join("test.txt").toFile();
        dir.delete(true);

        var fw = new PollingFileWatcher(ex, 100);

        var events = new Array<FileSystemEvent>();
        fw.subscribe(function (event) {
            trace('EVENT: ${event.getName()}');
            events.push(event);
        });

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
        _later(2000, function() {
            fw.stop();
            ex.stop();

            assertTrue(events.length > 6);
        });
    }


    public function testFileMacros() {
        assertEquals(Sys.getCwd(), FileMacros.getProjectRoot());

        var targetPath:String = FileMacros.resolvePath("target");
        assertTrue(targetPath.length > 6);

        var license:String = FileMacros.readString("LICENSE.txt");
        assertTrue(license.indexOf("Apache") > 0);
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
                #if travix
                    travix.Logger.exit(exitCode);
                #else
                    #if sys
                        Sys.exit(exitCode);
                    #elseif js
                        var isPhantomJS = untyped __js__("(typeof phantom !== 'undefined')");
                        if(isPhantomJS) {
                            untyped __js__("phantom.exit(exitCode)");
                        } else {
                            untyped __js__("process.exit(exitCode)");
                        }
                    #elseif flash
                        flash.system.System.exit(exitCode);
                    #end
                #end
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