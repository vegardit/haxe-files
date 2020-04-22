/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files.internal;

import haxe.macro.*;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
@:noCompletion
class Macros {

   static final __static_init = {
      #if (haxe_ver < 4)
         throw 'ERROR: As of haxe-files 2.0.0, Haxe 4.x or higher is required!';
      #end
   };

   macro
   public static function addDefines() {
      final def = Context.getDefines();
      if (def.exists("cpp") ||
          def.exists("cs") ||
          def.exists("hl") ||
          def.exists("eval") ||
          def.exists("java") ||
          def.exists("neko") ||
          def.exists("nodejs") ||
          def.exists("phantomjs") ||
          def.exists("php") ||
          def.exists("python")
      ) {
         trace("[INFO] Setting compiler define 'filesystem_support'.");
         Compiler.define("filesystem_support");
      } else {
         trace("[INFO] NOT setting compiler define 'filesystem_support'.");
      }

      if (def.exists("java") && !def.exists("jvm")) {
         trace("[INFO] Setting compiler define 'java_src'.");
         Compiler.define("java_src");
      }
      return macro {}
   }
}
