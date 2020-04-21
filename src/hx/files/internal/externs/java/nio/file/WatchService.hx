package hx.files.internal.externs.java.nio.file;

@:native("java.nio.file.WatchService")
extern interface WatchService {

   @:throws("java.io.IOException")
   function close():Void;
}
