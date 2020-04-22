package hx.files.internal.externs.java.nio.file;

@:native("java.nio.file.FileSystem")
extern class FileSystem {

   @:throws("java.io.IOException")
   public function newWatchService():WatchService;

   public function getPath(path:String, more:java.NativeArray<String>):Path;
}
