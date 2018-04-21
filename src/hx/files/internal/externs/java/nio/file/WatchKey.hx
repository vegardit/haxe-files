package hx.files.internal.externs.java.nio.file;

@:native("java.nio.file.WatchKey")
extern interface WatchKey {

    public function watchable():Watchable;
    public function pollEvents():java.util.List<Dynamic>;
    public function cancel():Void;
}
