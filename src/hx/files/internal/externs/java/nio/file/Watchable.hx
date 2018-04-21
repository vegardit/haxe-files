package hx.files.internal.externs.java.nio.file;

import java.NativeArray;

@:native("java.nio.file.Watchable")
extern interface Watchable {

    @:throws("java.io.IOException")
    public function register(arg0:WatchService, arg1:NativeArray<WatchEvent.WatchEvent_Kind>, arg2:NativeArray<WatchEvent.WatchEvent_Modifier>):WatchKey;
}
