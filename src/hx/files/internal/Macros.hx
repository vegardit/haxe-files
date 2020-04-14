/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files.internal;

import haxe.macro.Compiler;
import haxe.macro.Context;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
@:noDoc @:dox(hide)
class Macros {

    macro
    public static function addDefines() {
        var def = Context.getDefines();
        if (def.exists("cpp") ||
            def.exists("cs") ||
            def.exists("hl") ||
            def.exists("java") ||
            def.exists("neko") ||
            def.exists("nodejs") ||
            def.exists("phantomjs") ||
            def.exists("php") ||
            def.exists("php7") ||
            def.exists("python")
        ) {
            trace("[INFO] Setting compiler define 'filesystem_support'.");
            Compiler.define("filesystem_support");
        } else {
            trace("[INFO] NOT setting compiler define 'filesystem_support'.");
        }
        return macro {}
    }
}
