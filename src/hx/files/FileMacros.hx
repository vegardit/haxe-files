/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files;

import haxe.macro.Context;
import haxe.macro.Expr.ExprOf;

class FileMacros {

   #if macro
   inline //
   static function toExpr<T>(value:T):ExprOf<T> {
      return Context.makeExpr(value, Context.currentPos());
   }
   #end


   /**
    * @return the current project's root directory including a trailing slash
    */
   macro //
   public static function getProjectRoot():ExprOf<String> {
      final cwd = Sys.getCwd();
      return toExpr(cwd);
   }


   /**
    * @return the absolute path
    */
   macro //
   public static function resolvePath(relativePath:String):ExprOf<String> {
      final absPath = Path.of(Context.resolvePath(relativePath)).getAbsolutePath();
      return toExpr(absPath.toString());
   }


   macro //
   public static function readString(filePath:String):ExprOf<String> {
      final file = File.of(Context.resolvePath(filePath));
      final content = file.readAsString();
      return toExpr(content);
   }


   /**
    * Reads the content of the given file and ensures that it is XML parseable.
    */
   macro //
   public static function readXmlString(filePath:String):ExprOf<String> {
      final file = File.of(Context.resolvePath(filePath));
      final content = file.readAsString();
      try
         Xml.parse(content)
      catch (e:Dynamic) {
         haxe.macro.Context.error('Invalid XML in [$filePath]: $e', Context.currentPos());
      }
      return toExpr(content);
   }
}
