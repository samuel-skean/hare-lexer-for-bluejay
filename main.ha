use fmt;
use os;
use io;

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

const l_paren    = "(",
      r_paren    = ")",
      l_bracket  = "[",
      r_bracket  = "]",
      l_brace    = "{",
      r_brace    = "}",
      plus       = "+",
      minus      = "-",
      mul        = "*",
      div        = "/",
      rem        = "%",
      eq         = "==",
      ne         = "<>",
      lt         = "<",
      le         = "<=",
      gt         = ">",
      ge         = ">=",
      not        = "!",
      band       = "&",
      bor        = "|",
      xor        = "^",
      and        = "&&",
      or         = "||",
      assign     = ":=",
      _return    = "return",
      _if        = "if",
      _else      = "else",
      _while     = "while",
      otherwise  = "otherwise",
      repeat     = "repeat",
      semicolon  = ";",
      var        = "var",
      implicit   = "implicit",
      fun        = "fun",
      _int_kw    = "int",
      _string_kw = "string",
      _void      = "void";


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
    text: []u8,
};

type lexer = struct {
    input: []u8,
    // Start of current token:
    start_loc: location,
    // Current position in file:
    current_loc: location,
    tokens: []token,
};

// TODO: It's not super obvious to me which of the newline behaviors should be handled here and which should be handled in the relevant state_fns.
fn next(l: *lexer) (u8 | done) = {
    if (l.current_loc.pos == len(l.input)) {
        return done;
    };
    if (l.input[l.current_loc.pos] == '\n') {
        l.current_loc.line += 1;
        l.current_loc.col = 1;
        l.current_loc.indentation_chars = 0;
    };
    let char = l.input[l.current_loc.pos];
    l.current_loc.pos += 1;
    return char;
};

fn emit(l: *lexer, t: token_kind) void = {
    append(l.tokens, token {
        loc = l.start_loc,
        block_depth = 0,
        kind = t,
        text = l.input[l.start_loc.pos..l.current_loc.pos],
    });
    l.start_loc = l.current_loc;
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
    let input_file = os::open(os::args[1])!;
    defer io::close(input_file)!;
    let input = io::drain(input_file)!;
    defer free(input);

    let l = lexer {
        input = input,
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

    for (let state: state_fn = &lex_indent; state != null) {
        state = match (state) {
            case let state: *fn(*lexer) state_fn =>
                yield state(&l);
            case null =>
                abort();
        };
    };
    fmt::printfln("Tokens: {}", len(l.tokens))!;
};