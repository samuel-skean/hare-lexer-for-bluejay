use fmt;
use strings;

fn lex_indent(l: *lexer) state_fn = {
    for (let char => next(l)) {
        switch (char) {
        case '\t' =>
            l.current_loc.indentation_chars += 4;
        case ' ' =>
            l.current_loc.indentation_chars += 1;
        case '\n' =>
            return &lex_indent;
        case =>
            return &lex_general;
        };
    };
    return null;
};

fn lex_general(l: *lexer) state_fn = {
    if (strings::hasprefix(strings::fromutf8(l.input[l.current_loc.pos..])!, _return)) {
        emit(l, token_kind::RETURN);
    };
    return null;
};