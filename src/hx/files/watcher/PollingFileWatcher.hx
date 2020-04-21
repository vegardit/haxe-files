/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files.watcher;

import hx.concurrent.executor.Executor;
import hx.concurrent.executor.Schedule;
import hx.concurrent.lock.RLock;
import hx.files.watcher.FileWatcher;
import hx.strings.collection.SortedStringMap;
import hx.strings.collection.StringArray;
import hx.strings.collection.StringMap;
import hx.strings.internal.Either2;

#if (filesystem_support || macro)

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class PollingFileWatcher extends AbstractFileWatcher {

   var intervalMS:Int;

   var scanTask:TaskFuture<Void> = null;

   var watched = new StringMap<FSEntry>();
   var watchedSync = new RLock();

   /**
     * @param executor the executor to be used for scheduling/executing the background polling task and for notifying subscribers of FileSystemEvents (optional, defaults to hx.concurrent.event.SyncEventDispatcher)
     * @param intervalMS polling interval in milliseconds
     */
   public function new(executor:Executor, intervalMS:Int, autostart = true) {
      super(executor);

      if (intervalMS < 1)
         throw "[intervalMS] must be a positive value";

      this.intervalMS = intervalMS;

      if (autostart)
         start();
   }


   override
   public function onStart():Void {
      scanTask = executor.submit(this.scanAll, Schedule.FIXED_DELAY(intervalMS, 0));
   }


   override
   public function onStop():Void {
      scanTask.cancel();
      scanTask = null;
   }


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

         if (scanTask == null)
            watched.set(pathStr, FSEntry.UNSCANNED(pathObj));
         else
            scanPath(FSEntry.UNSCANNED(pathObj));
      });
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
         watched.remove(pathStr);
      });
   }


   private function scanAll():Void {
      var paths:StringArray = watchedSync.execute(function() {
         return [ for (k in watched.keys()) k ];
      });

      for (path in paths) {
         watchedSync.execute(function() {
            var fsEntry = watched.get(path);
            if (fsEntry == null) // if null, then the path has been unwachted in the meantime
               return;
            scanPath(fsEntry);
         });
      }
   }


   private function compareFSEntry(old:FSEntry, now:FSEntry):Void {
      switch(old:FSEntry) {
         case DIR(dir, attrs, children):
            switch(now) {
               case DIR(_, attrsNow, childrenNow): {
                  if(!attrs.equals(attrsNow))
                     eventDispatcher.fire(FileSystemEvent.DIR_MODIFIED(dir, attrs, attrsNow));

                  for (childName in children.keys()) {
                     var child = children.get(childName);
                     var childNow = childrenNow.get(childName);

                     if (childNow == null)
                        childNow = FSEntry.NONEXISTANT(null);
                     compareFSEntry(child, childNow);
                  }

                  for (childName in childrenNow.keys()) {
                     var child = children.get(childName);
                     if (child == null) {
                        var childNow = childrenNow.get(childName);
                        compareFSEntry(FSEntry.NONEXISTANT(null), childNow);
                     }
                  }
               }
               case FILE(file, _):
                  eventDispatcher.fire(FileSystemEvent.DIR_DELETED(dir));
                  eventDispatcher.fire(FileSystemEvent.FILE_CREATED(file));
               case NONEXISTANT(_) | UNKNOWN(_):
                  eventDispatcher.fire(FileSystemEvent.DIR_DELETED(dir));
               case UNSCANNED(_):
                  // nothing to do
            }
         case FILE(file, attrs):
            switch(now) {
               case DIR(dir, _, _):
                  eventDispatcher.fire(FileSystemEvent.FILE_DELETED(file));
                  compareFSEntry(FSEntry.NONEXISTANT(dir.path), now);
               case FILE(_, attrsNow):
                  if (!attrs.equals(attrsNow)) {
                     eventDispatcher.fire(FileSystemEvent.FILE_MODIFIED(file, attrs, attrsNow));
                  }
               case NONEXISTANT(_) | UNKNOWN(_):
                  eventDispatcher.fire(FileSystemEvent.FILE_DELETED(file));
               case UNSCANNED(_):
                  // nothing to do
            }
         case NONEXISTANT(_) | UNKNOWN(_):
            switch(now) {
               case DIR(dir, _, children):
                  eventDispatcher.fire(FileSystemEvent.DIR_CREATED(dir));
                  var work = [ children ];
                  while((children = work.pop()) != null) {
                     for (child in children) {
                        switch(child) {
                           case DIR(dir, _, childChildren):
                              eventDispatcher.fire(FileSystemEvent.DIR_CREATED(dir));
                              work.push(childChildren);
                           case FILE(file, _):
                              eventDispatcher.fire(FileSystemEvent.FILE_CREATED(file));
                           default:
                              // nothing to do
                        }
                     }
                  }
               case FILE(file, _):
                  eventDispatcher.fire(FileSystemEvent.FILE_CREATED(file));
               default:
                  // nothing to do
            }
         case UNSCANNED(_):
             // nothing to do
      }
   }

   private function scanPath(fsEntry:FSEntry):Void {

      switch(fsEntry) {
         case DIR(dir, attrs, children): {
            var fsEntryNow = dir.path.exists() ? createFSEntry_DIR(dir) : FSEntry.NONEXISTANT(dir.path);
            compareFSEntry(fsEntry, fsEntryNow);
            watched.set(dir.path.toString(), fsEntryNow);
         }

         case FILE(file, attrs): {
            var fsEntryNow = file.path.exists() ? createFSEntry_FILE(file) : FSEntry.NONEXISTANT(file.path);
            compareFSEntry(fsEntry, fsEntryNow);
            watched.set(file.path.toString(), fsEntryNow);
         }

         case NONEXISTANT(path): {
            if (!path.exists())
                return;

            if (path.isDirectory()) {
               var fsEntryNow = createFSEntry_DIR(path.toDir());
               compareFSEntry(fsEntry, fsEntryNow);
               watched.set(path.toString(), fsEntryNow);
            } else if (path.isFile()) {
               var fsEntryNow = createFSEntry_FILE(path.toFile());
               compareFSEntry(fsEntry, fsEntryNow);
               watched.set(path.toString(), fsEntryNow);
            } else {
               trace('WARN: Filesystem object at [$path] is of unknown type.');
            }
         }

         case UNSCANNED(path): {
            if (!path.exists()) {
               watched.set(path.toString(), FSEntry.NONEXISTANT(path));
               return;
            }

            if (path.isDirectory()) {
               watched.set(path.toString(), createFSEntry_DIR(path.toDir()));
            } else if (path.isFile()) {
               watched.set(path.toString(), createFSEntry_FILE(path.toFile()));
            } else {
               watched.set(path.toString(), FSEntry.UNKNOWN(path));
            }
         }

         case UNKNOWN(path): {
            if (!path.exists()) {
               watched.set(path.toString(), FSEntry.NONEXISTANT(path));
               return;
            }

            scanPath(FSEntry.NONEXISTANT(path));
         }
      }
   }


   private function createFSEntry_DIR(dir:Dir):FSEntry {

      var children = new SortedStringMap<FSEntry>();

      for (path in dir.list()) {
         if (path.isDirectory()) {
            children.set(path.filename, createFSEntry_DIR(path.toDir()));
         } else if (path.isFile()) {
            children.set(path.filename, createFSEntry_FILE(path.toFile()));
         } else {
            trace('WARN: Filesystem object at [$path] is of unknown type.');
         }
      }

      return FSEntry.DIR(dir, DirAttrs.fromDir(dir), children);
   }


   inline
   private function createFSEntry_FILE(file:File):FSEntry
      return FSEntry.FILE(file, FileAttrs.fromFile(file));
}

private enum FSEntry {
   DIR(dir:Dir, attrs:DirAttrs, children:SortedStringMap<FSEntry>);
   FILE(file:File, attrs:FileAttrs);
   NONEXISTANT(path:Path);
   UNSCANNED(path:Path);
   UNKNOWN(path:Path);
}
#end //filesystem_support