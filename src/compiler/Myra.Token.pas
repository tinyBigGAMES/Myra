{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Token;

{$I Myra.Defines.inc}

interface

type
  { TTokenKind }
  TTokenKind = (
    // Keywords
    tkModule,
    tkImport,
    tkPublic,
    tkConst,
    tkType,
    tkVar,
    tkRoutine,
    tkBegin,
    tkEnd,
    tkIf,
    tkThen,
    tkElse,
    tkCase,
    tkOf,
    tkWhile,
    tkDo,
    tkRepeat,
    tkUntil,
    tkFor,
    tkTo,
    tkDownto,
    tkReturn,
    tkArray,
    tkRecord,
    tkSet,
    tkPointer,
    tkNil,
    tkAnd,
    tkOr,
    tkNot,
    tkDiv,
    tkMod,
    tkIn,
    tkIs,
    tkAs,
    tkTry,
    tkExcept,
    tkFinally,
    tkTest,
    tkExternal,
    tkMethod,
    tkSelf,
    tkInherited,
    tkParamCount,
    tkParamStr,

    // Symbols
    tkLParen,
    tkRParen,
    tkLBracket,
    tkRBracket,
    tkLBrace,
    tkRBrace,
    tkDot,
    tkComma,
    tkColon,
    tkSemicolon,
    tkAssign,
    tkEquals,
    tkNotEquals,
    tkLess,
    tkGreater,
    tkLessEq,
    tkGreaterEq,
    tkPlus,
    tkMinus,
    tkStar,
    tkSlash,
    tkCaret,
    tkDotDot,
    tkEllipsis,

    // Literals and identifiers
    tkIdentifier,
    tkInteger,
    tkFloat,
    tkString,
    tkChar,
    tkWideString,
    tkWideChar,

    // Special
    tkDirective,
    tkStartCpp,
    tkEndCpp,
    tkCppBlock,
    tkEOF
  );

  { TToken }
  TToken = record
    Kind: TTokenKind;
    Text: string;
    Filename: string;
    Line: Integer;
    Column: Integer;
  end;

implementation

end.
