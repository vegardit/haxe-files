package hx.files.internal.externs.java.nio.file;

@:native("java.nio.file.StandardWatchEventKinds")
extern class StandardWatchEventKinds {

    @:final public static var OVERFLOW:WatchEvent.WatchEvent_Kind;
    @:final public static var ENTRY_CREATE:WatchEvent.WatchEvent_Kind;
    @:final public static var ENTRY_DELETE:WatchEvent.WatchEvent_Kind;
    @:final public static var ENTRY_MODIFY:WatchEvent.WatchEvent_Kind;

}

@:native("java.nio.file.StandardWatchEventKinds.StdWatchEventKind")
extern class StandardWatchEventKinds_StdWatchEventKind implements WatchEvent.WatchEvent_Kind {
    public function name():String;
}
