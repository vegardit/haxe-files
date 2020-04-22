/*
 * Copyright (c) 2016-2020 Vegard IT GmbH (https://vegardit.com) and contributors.
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.files;

import hx.strings.Char;
import hx.strings.Pattern;
import hx.strings.StringBuilder;
import hx.strings.internal.Either3;

using hx.strings.Strings;

/**
 * Utility class to convert glob patterns to regex patterns.
 *
 * See https://en.wikipedia.org/wiki/Glob_(programming)
 *
 * @author Sebastian Thomschke, Vegard IT GmbH
 */
class GlobPatterns {

   /**
    * Creates a regular expression EReg object from the given globbing/wildcard pattern.
    *
    * <pre><code>
    * >>> GlobPatterns.toEReg("*.txt").match("file.txt")           == true
    * >>> GlobPatterns.toEReg("*.txt").match("file.pdf")           == false
    * >>> GlobPatterns.toEReg("*.{pdf,txt}").match("file.txt")     == true
    * >>> GlobPatterns.toEReg("*.{pdf,txt}").match("file.pdf")     == true
    * >>> GlobPatterns.toEReg("*.{pdf,txt}").match("file.xml")     == false
    * >>> GlobPatterns.toEReg("file[0-9].txt" ).match("file1.txt") == true
    * >>> GlobPatterns.toEReg("file[!0-9].txt").match("file1.txt") == false
    * >>> GlobPatterns.toEReg("file[!0-9].txt").match("fileA.txt") == true
    * >>> GlobPatterns.toEReg("aa/bb/file1.txt").match("aa/bb/file1.txt"  ) == true
    * >>> GlobPatterns.toEReg("aa/bb/file1.txt").match("aa\\bb\\file1.txt") == true
    * >>> GlobPatterns.toEReg("**"+"/file?.txt").match("aa/bb/file1.txt"  ) == true
    * >>> GlobPatterns.toEReg("**"+"/file?.txt").match("aa\\bb\\file1.txt") == true
    *
    * @param globPattern Pattern in the Glob syntax style, see https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob
    *
    * @return an EReg object
    */
   inline
   public static function toEReg(globPattern:String, regexOptions:String = ""):EReg
      return toRegEx(globPattern).toEReg(regexOptions);


   /**
    * Creates a regular expression Pattern object from the given globbing/wildcard pattern.
    *
    * <pre><code>
    * >>> GlobPatterns.toPattern("*.txt"          ).matcher("file.txt" ).matches() == true
    * >>> GlobPatterns.toPattern("*.txt"          ).matcher("file.pdf" ).matches() == false
    * >>> GlobPatterns.toPattern("*.{pdf,txt}"    ).matcher("file.txt" ).matches() == true
    * >>> GlobPatterns.toPattern("*.{pdf,txt}"    ).matcher("file.pdf" ).matches() == true
    * >>> GlobPatterns.toPattern("*.{pdf,txt}"    ).matcher("file.xml" ).matches() == false
    * >>> GlobPatterns.toPattern("file[0-9].txt"  ).matcher("file1.txt").matches() == true
    * >>> GlobPatterns.toPattern("file[!0-9].txt" ).matcher("file1.txt").matches() == false
    * >>> GlobPatterns.toPattern("file[!0-9].txt" ).matcher("fileA.txt").matches() == true
    * >>> GlobPatterns.toPattern("aa/bb/file1.txt").matcher("aa/bb/file1.txt"  ).matches() == true
    * >>> GlobPatterns.toPattern("aa/bb/file1.txt").matcher("aa\\bb\\file1.txt").matches() == true
    * >>> GlobPatterns.toPattern("**"+"/file?.txt").matcher("aa/bb/file1.txt"  ).matches() == true
    * >>> GlobPatterns.toPattern("**"+"/file?.txt").matcher("aa\\bb\\file1.txt").matches() == true
    * </code></pre>
    *
    * @param globPattern Pattern in the Glob syntax style, see https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob
    *
    * @return a hx.strings.Pattern object
    */
   inline
   public static function toPattern(globPattern:String, options:Either3<String, MatchingOption, Array<MatchingOption>> = null):Pattern
      return toRegEx(globPattern).toPattern(options);


   /**
    * Creates a regular expression pattern from the given globbing/wildcard pattern.
    *
    * <pre><code>
    * >>> GlobPatterns.toRegEx("file")        == "^file$"
    * >>> GlobPatterns.toRegEx("*.txt")       == "^[^\\\\^\\/]*\\.txt$"
    * >>> GlobPatterns.toRegEx("*file*")      == "^[^\\\\^\\/]*file[^\\\\^\\/]*$"
    * >>> GlobPatterns.toRegEx("file?.txt")   == "^file[^\\\\^\\/]\\.txt$"
    * >>> GlobPatterns.toRegEx("file[A-Z]")   == "^file[A-Z]$"
    * >>> GlobPatterns.toRegEx("file[!A-Z]")  == "^file[^A-Z]$"
    * >>> GlobPatterns.toRegEx("")            == ""
    * >>> GlobPatterns.toRegEx(null)          == null
    * </code></pre>
    *
    * @param globPattern Pattern in the Glob syntax style, see https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob
    *
    * @return regular expression string
    */
   public static function toRegEx(globPattern:String):String {
      if (globPattern.isEmpty())
         return globPattern;

      final sb = new StringBuilder();
      sb.addChar(Char.CARET);
      final chars = globPattern.toChars();
      final charsLenMinus1 = chars.length - 1;
      var chPrev:Char = -1;
      var groupDepth = 0;
      var idx = -1;
      while(idx < charsLenMinus1) {
         idx++;
         var ch = chars[idx];

         switch (ch) {
            case Char.BACKSLASH:
               if (chPrev == Char.BACKSLASH)
                  sb.add("\\\\"); // "\\" => "\\"
            case Char.SLASH:
               // "/" => "[\/\\]"
               sb.add("[\\/\\\\]");
            case Char.DOLLAR:
               // "$" => "\$"
               sb.add("\\$");
            case Char.QUESTION_MARK:
               if (chPrev == Char.BACKSLASH)
                  sb.add("\\?"); // "\?" => "\?"
               else
                  sb.add("[^\\\\^\\/]"); // "?" => "[^\\^\/]"
            case Char.DOT:
               // "." => "\."
               sb.add("\\.");
            case Char.BRACKET_ROUND_LEFT:
               // "(" => "\("
               sb.add("\\(");
            case Char.BRACKET_ROUND_RIGHT:
               // ")" => "\)"
               sb.add("\\)");
            case Char.BRACKET_CURLY_LEFT:
               if (chPrev == Char.BACKSLASH)
                  sb.add("\\{"); // "\{" => "\{"
               else {
                  groupDepth++;
                  sb.addChar(Char.BRACKET_ROUND_LEFT);
               }
            case Char.BRACKET_CURLY_RIGHT:
               if (chPrev == Char.BACKSLASH)
                  sb.add("\\}"); // "\}" => "\}"
               else {
                  groupDepth--;
                  sb.addChar(Char.BRACKET_ROUND_RIGHT);
               }
            case Char.COMMA:
               if (chPrev == Char.BACKSLASH)
                   sb.add("\\,"); // "\," => "\,"
               else {
                  // "," => "|" if in group or => "," if not in group
                  sb.addChar(groupDepth > 0 ? Char.PIPE : Char.COMMA);
               }
            case Char.EXCLAMATION_MARK:
               if (chPrev == Char.BRACKET_SQUARE_LEFT)
                  sb.addChar(Char.CARET);  // "[!" => "[^"
               else
                  sb.addChar(ch);
            case Char.ASTERISK:
               if (chars[idx + 1] == Char.ASTERISK) { // **
                  if (chars[idx + 2] == Char.SLASH) { // **/
                     if (chars[idx + 3] == Char.ASTERISK) {
                        // "**/*" => ".*"
                        sb.add(".*");
                        idx += 3;
                     } else {
                        // "**/" => "(.*[\/\\])?"
                        sb.add("(.*[\\/\\\\])?");
                        idx += 2;
                         ch = Char.SLASH;
                     }
                  } else {
                     sb.add(".*"); // "**" => ".*"
                     idx++;
                  }
               } else {
                  sb.add("[^\\\\^\\/]*"); // "*" => "[^\\^\/]*"
               }
            default:
               if (chPrev == Char.BACKSLASH) {
                  sb.addChar(Char.BACKSLASH);
               }
               sb.addChar(ch);
         }

         chPrev = ch;
      }
      sb.addChar(Char.DOLLAR);
      return sb.toString();
   }
}