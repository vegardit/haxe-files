package hx.files.internal.externs.java.nio.file;

@:native("java.nio.file.WatchEvent")
extern interface WatchEvent {
   function kind():WatchEvent_Kind;
   function context():Dynamic;
}

@:native("java.nio.file.WatchEvent$Modifier")
extern interface WatchEvent_Modifier {
   function name():String;
}

@:native("java.nio.file.WatchEvent$Kind")
extern interface WatchEvent_Kind {
   function name():String;
}
