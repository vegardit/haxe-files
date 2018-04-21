package hx.files.internal.externs.java.nio.file;

@:native("java.nio.file.WatchEvent")
extern interface WatchEvent {
    public function kind():WatchEvent_Kind;
    public function context():Dynamic;
}

@:native("java.nio.file.WatchEvent.Modifier")
extern interface WatchEvent_Modifier {
    public function name():String;
}

@:native("java.nio.file.WatchEvent.Kind")
extern interface WatchEvent_Kind {
    public function name():String;
}
