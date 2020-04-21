/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files.watcher;

#if java
import hx.concurrent.ConcurrentException;
import hx.concurrent.executor.Executor;
import hx.concurrent.executor.Schedule;
import hx.concurrent.lock.RLock;
import hx.files.watcher.FileWatcher;
import hx.files.internal.externs.java.nio.file.ExtendedWatchEventModifier;
import hx.files.internal.externs.java.nio.file.FileSystems;
import hx.files.internal.externs.java.nio.file.StandardWatchEventKinds;
import hx.files.internal.externs.java.nio.file.WatchService;
import hx.files.internal.externs.java.nio.file.WatchEvent;
import hx.files.internal.externs.java.nio.file.WatchKey;
import hx.strings.internal.Either2;
import hx.strings.collection.SortedStringMap;
import hx.strings.collection.StringArray;
import hx.strings.collection.StringMap;
import hx.strings.internal.OS;

using hx.strings.Strings;

typedef JPath = hx.files.internal.externs.java.nio.file.Path;

/**
 * Java 7 WatchService based implementation. See https://docs.oracle.com/javase/tutorial/essential/io/notification.html
 *
 * Current limitations:
 * a) Only directories, not single files directly can be watched.
 * b) The directory to watch must exist.
 * c) Recursive watching (sub-directories) only works on Windows. See https://stackoverflow.com/questions/18701242/how-to-watch-a-folder-and-subfolders-for-changes
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class JavaFileWatcher extends AbstractFileWatcher {

   var pollTask:TaskFuture<Void> = null;

   var watched = new StringMap<WatchEntry>();
   var watchedSync = new RLock();

   var watchService:WatchService;

   /**
     * @param executor the executor to be used for scheduling/executing the background polling task and for notifying subscribers of FileSystemEvents (optional, defaults to hx.concurrent.event.SyncEventDispatcher)
     * @param intervalMS polling interval in milliseconds
     */
   public function new(executor:Executor, autostart = true) {
      super(executor);

      if (autostart)
         start();
   }


   override
   public function onStart():Void {
      watchService = FileSystems.getDefault().newWatchService();

      for (entry in watched) {
         entry.collectExistingDirs();
         entry.watchKey = createWatchKey(entry.jpath);
      }

      pollTask = executor.submit(this.pollEvents, Schedule.FIXED_DELAY(50, 0));
   }


   override
   public function onStop():Void {
      watchService.close();
      watchService = null;
   }


   function pollEvents() {
      watchedSync.execute(function() {
         for (entry in watched) {
            var events = entry.watchKey.pollEvents().iterator();
            while (events.hasNext()) {
               var event:WatchEvent = events.next();
               var relPath = Std.string(event.context());
               var path = entry.path.join(relPath);
               switch(event.kind().name()) {
                  case "ENTRY_CREATE":
                     if (path.isDirectory()) {
                        entry.existingDirs.push(relPath);
                        eventDispatcher.fire(FileSystemEvent.DIR_CREATED(path.toDir()));
                     } else if (path.isFile()) {
                        eventDispatcher.fire(FileSystemEvent.FILE_CREATED(path.toFile()));
                     }
                  case "ENTRY_MODIFY":
                     if (path.isDirectory()) {
                        eventDispatcher.fire(FileSystemEvent.DIR_MODIFIED(path.toDir(), null, null));
                     } else if (path.isFile()) {
                        eventDispatcher.fire(FileSystemEvent.FILE_MODIFIED(path.toFile(), null, null));
                     }
                  case "ENTRY_DELETE": {
                     if (entry.existingDirs.contains(relPath)) {
                        entry.existingDirs.remove(relPath);
                        eventDispatcher.fire(FileSystemEvent.DIR_DELETED(path.toDir()));
                     } else if (path.isFile()) {
                        eventDispatcher.fire(FileSystemEvent.FILE_DELETED(path.toFile()));
                     }
                  }
                  default:
                      trace("Unexpected WatchEvent type: " + event.kind().name());
               }
            }
         }
      });
   }


   /**
     * @param path must point to an existing directory
     */
   override
   public function watch(path:Either2<Path, String>):Void {
      if (path == null)
         throw "[path] must not be null";

      var pathObj:Path = (switch(path.value) {
         case a(obj): obj;
         case b(str): Path.of(str);
      }).normalize();

      trace('Watching [$pathObj]...');
      watchedSync.execute(function() {
         var pathStr = pathObj.toString();

         if (watched.exists(pathStr))
            return;

         var entry = new WatchEntry();
         entry.path = pathObj;
         entry.jpath = FileSystems.getDefault().getPath(pathStr);
         entry.collectExistingDirs();
         entry.watchKey = createWatchKey(entry.jpath);
         watched.set(pathStr, entry);
      });
   }


   private function createWatchKey(jpath:JPath):WatchKey {
      var kinds = new java.NativeArray(3);
      kinds[0] = StandardWatchEventKinds.ENTRY_CREATE;
      kinds[1] = StandardWatchEventKinds.ENTRY_MODIFY;
      kinds[2] = StandardWatchEventKinds.ENTRY_DELETE;

      if (OS.isWindows) {
         var opts = new java.NativeArray<WatchEvent_Modifier>(1);
         opts[0] = ExtendedWatchEventModifier.FILE_TREE;
         return jpath.register(watchService, kinds, opts);
      }
       return jpath.register(watchService, kinds, new java.NativeArray(0));
   }


   override
   public function unwatch(path:Either2<Path, String>):Void {
      if (path == null)
         return;

      watchedSync.execute(function() {
         var pathStr = (
            switch(path.value) {
               case a(obj): obj;
               case b(str): Path.of(str);
            }
         ).normalize().toString();

         trace('Unwatching [$pathStr]...');
         var entry = watched.get(pathStr);
         if (entry == null)
            return;

         entry.watchKey.cancel();
         watched.remove(pathStr);
      });
   }
}


private class WatchEntry {
   public function new() {};
   public var watchKey:WatchKey;
   public var jpath:JPath;
   public var path:Path;

   public var existingDirs = new StringArray();

   public function collectExistingDirs() {
      // workaround for https://stackoverflow.com/questions/13924754/determining-type-of-deleted-file-from-watchevent
      existingDirs.clear();
      if (path.isDirectory()) {
         var dir = path.toDir();
         var pathLen = dir.toString().length;
         dir.walk(null, function(dir) {
            existingDirs.push(dir.toString().substring(pathLen));
            return true;
         });
      }
   }
}
#end