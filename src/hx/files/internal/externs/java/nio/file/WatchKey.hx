package hx.files.internal.externs.java.nio.file;

@:native("java.nio.file.WatchKey")
extern interface WatchKey {

   function watchable():Watchable;
   function pollEvents():java.util.List<Dynamic>;
   function cancel():Void;
}
