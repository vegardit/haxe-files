package hx.files.internal.externs.java.nio.file;

@:native("java.nio.file.WatchKey")
extern interface WatchKey {

   function cancel():Void;
   function pollEvents():java.util.List<Dynamic>;
   function reset():Bool;
   function watchable():Watchable;
}
