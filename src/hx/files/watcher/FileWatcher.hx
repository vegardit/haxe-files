/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files.watcher;

import hx.concurrent.Service;
import hx.concurrent.event.AsyncEventDispatcher;
import hx.concurrent.event.EventDispatcher;
import hx.concurrent.event.EventListenable;
import hx.concurrent.executor.Executor;
import hx.strings.internal.Either2;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
interface FileWatcher extends EventListenable<FileSystemEvent> extends Service<Int> {

    function watch(path:Either2<Path, String>):Void;

    function unwatch(path:Either2<Path, String>):Void;
}


enum FileSystemEvent {
    DIR_CREATED(dir:Dir);

    DIR_DELETED(dir:Dir);

    /**
     * @param old attributes at the time before the event occured, may be null depending on implementation
     * @param now attributes at the time when the event occured, may be null depending on implementation
     */
    DIR_MODIFIED(dir:Dir, old:DirAttrs, now:DirAttrs);

    FILE_CREATED(file:File);

    FILE_DELETED(file:File);

    /**
     * @param old attributes at the time before the event occured, may be null depending on implementation
     * @param now attributes at the time when the event occured, may be null depending on implementation
     */
    FILE_MODIFIED(file:File, old:FileAttrs, now:FileAttrs);
}


@immutable
class DirAttrs {
    public var mtime(default, null):Float;
    public var uid(default, null):Int;
    public var gid(default, null):Int;
    public var mode(default, null):Int;

    inline
    public static function fromDir(dir:Dir) {
        #if (sys || macro || nodejs)
            var stat = dir.path.stat();
            return new DirAttrs(dir.path.getModificationTime(), stat.uid, stat.gid, stat.mode);
        #else
            return new DirAttrs(dir.path.getModificationTime(), -1, -1, -1);
        #end
    }

    inline
    public function new(mtime:Float, uid:Int, gid:Int, mode:Int) {
        this.mtime = mtime;
        this.uid = uid;
        this.gid = gid;
        this.mode = mode;
    }

    inline
    public function equals(attrs:DirAttrs):Bool {
        return attrs.mtime == mtime && attrs.uid  == uid && attrs.gid  == gid && attrs.mode == mode;
    }
}


@immutable
class FileAttrs {
    public var mtime(default, null):Float;
    public var uid(default, null):Int;
    public var gid(default, null):Int;
    public var mode(default, null):Int;
    public var size(default, null):Int;

    inline
    public static function fromFile(file:File) {
        #if (sys || macro || nodejs)
            var stat = file.path.stat();
            return new FileAttrs(file.path.getModificationTime(), stat.uid, stat.gid, stat.mode, stat.size);
        #else
            return new FileAttrs(file.path.getModificationTime(), -1, -1, -1, file.size());
        #end
    }

    inline
    public function new(mtime:Float, uid:Int, gid:Int, mode:Int, size:Int) {
        this.mtime = mtime;
        this.uid = uid;
        this.gid = gid;
        this.mode = mode;
        this.size = size;
    }

    inline
    public function equals(attrs:FileAttrs):Bool {
        return attrs.mtime == mtime && attrs.size == size && attrs.uid  == uid && attrs.gid  == gid && attrs.mode == mode;
    }
}


@:abstract
class AbstractFileWatcher extends ServiceBase implements EventListenable<FileSystemEvent> implements FileWatcher {

    var executor:Executor;
    var eventDispatcher:EventDispatcher<FileSystemEvent>;


    public function new(executor:Executor) {
        super();

        if (executor == null)
            throw "[executor] must not be null";

        this.executor = executor;
        eventDispatcher = new AsyncEventDispatcher(executor);
    }


    inline
    public function subscribe(listener:FileSystemEvent->Void):Bool {
        return eventDispatcher.subscribe(listener);
    }


    inline
    public function unsubscribe(listener:FileSystemEvent->Void):Bool {
        return eventDispatcher.unsubscribe(listener);
    }


    public function watch(path:Either2<Path, String>):Void throw "Not implemented.";
    public function unwatch(path:Either2<Path, String>):Void throw "Not implemented.";
}