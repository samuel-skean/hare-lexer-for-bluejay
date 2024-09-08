use fmt;

// TODO: I could do all the token-specific info through type unions, by
// declaring a bunch of aliases for done, but that kinda sounds like it sucks...
// You can even make multiple type aliases with one type keyword by just listing
// each assignment separated by commas.
type _int = int;
type _type_name = []u8;
type _ident = []u8;
type _str = []u8;

type token_data = (_int | _type_name | _ident | _str | done);

type token_kind = enum {
    L_PAREN,     // (
    R_PAREN,     // )
    L_BRACKET,   // [
    R_BRACKET,   // ]
    L_BRACE,     // {
    R_BRACE,     // }
    PLUS,        // +
    MINUS,       // -
    MUL,         // *
    DIV,         // /
    REM,         // %
    EQ,          // ==
    NE,          // <>
    LT,          // <
    LE,          // <=
    GT,          // >
    GE,          // >=
    NOT,         // !
    BAND,        // &
    BOR,         // |
    XOR,         // ^
    AND,         // &&
    OR,          // ||
    // Statements:
    ASSIGN,    // :=
    RETURN,    // return
    IF,        // if
    ELSE,      // else
    WHILE,     // while
    OTHERWISE, // otherwise
    REPEAT,    // repeat
    SEMICOLON, // ;
    // other keywords:
    VAR,      // var
    IMPLICIT, // implicit
    FUN,      // fun
    TYPE,     // int, string, or void
    // Identifiers:
    NAME, // <variable name>
    // Constants:
    INT,    // <integer> (could be in decimal, hexadecimal, or octal)
    STRING, // "<some characters>"
};

type location = struct {
    indentation_chars: uint,
    line: uint,
    col: uint,
    pos: uint,
};

type token = struct {
    loc: location,
    block_depth: uint,
    kind: token_kind,
    value: token_data,
};

type lexer = struct {
    input: str,
    // Start of current token:
    start_loc: location,
    // Current position in file:
    current_loc: location,
    tokens: []token,
};

// Inspired by https://go.dev/talks/2011/lex.slide#1
type state_fn = nullable *fn(*lexer) state_fn;

// This is ugly because `nullable` must occur directly before a pointer type -
// not a type alias of a pointer type. I could use instead make the return type
// a union with done, making the code a bit prettier, but I still couldn't use
// the for-each iterator syntax because you can't modify the values that way.
// Either way, I could change the match to casting away nullable (unsafely) or
// done (safely, with `as`). Alternatively, I could make a function that simply
// advances a state by virtue of a static variable, and use it with the for-each
// iterator syntax, but that might be even uglier.

export fn main() void = {
    let l = lexer {
        input = "",
        start_loc = location {
            indentation_chars = 0,
            line = 1,
            col = 1,
            pos = 0,
        },
        current_loc = location {
            indentation_chars = 0,
            line = 1,
            col = 1,
            pos = 0,
        },
        tokens = [],
    };

    for (let state: state_fn = &lex_return; state != null) {
        state = match (state) {
            case let state: *fn(*lexer) state_fn =>
                yield state(&l);
            case null =>
                abort();
        };
    };
};