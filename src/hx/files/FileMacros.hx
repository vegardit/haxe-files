/*
 * Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files;

import haxe.macro.Context;
import haxe.macro.Expr.ExprOf;

/**
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class FileMacros {

    #if macro
    inline
    static function toExpr<T>(value:T):ExprOf<T> {
        return Context.makeExpr(value, Context.currentPos());
    }
    #end


    /**
     * @return the current project's root directory including a trailing slash
     */
    macro
    public static function getProjectRoot():ExprOf<String> {
        var cwd = Sys.getCwd();
        return toExpr(cwd);
    }


    /**
     * @return the absolute path
     */
    macro
    public static function resolvePath(relativePath:String):ExprOf<String> {
        var absPath = Path.of(Context.resolvePath(relativePath)).getAbsolutePath();
        return toExpr(absPath);
    }


    macro
    public static function readString(filePath:String):ExprOf<String> {
        var file = File.of(Context.resolvePath(filePath));
        var content = file.readAsString();
        return toExpr(content);
    }


    macro
    public static function readXmlString(filePath:String):ExprOf<String> {
        var file = File.of(Context.resolvePath(filePath));
        var content = file.readAsString();
        try Xml.parse(content) catch (e:Dynamic) {
            haxe.macro.Context.error('Invalid XML in [$filePath]: $e', Context.currentPos());
        }
        return toExpr(content);
    }
}
