-file("/Users/dparfitt/erlang_R15B01/lib/erlang/lib/parsetools-2.0.7/include/leexinc.hrl", 0).
%% The source of this file is part of leex distribution, as such it
%% has the same Copyright as the other files in the leex
%% distribution. The Copyright is defined in the accompanying file
%% COPYRIGHT. However, the resultant scanner generated by leex is the
%% property of the creator of the scanner and is not covered by that
%% Copyright.

-module(riak_cql_scanner).

-export([string/1,string/2,token/2,token/3,tokens/2,tokens/3]).
-export([format_error/1]).

%% User code. This is placed here to allow extra attributes.
-file("src/riak_cql_scanner.xrl", 54).
%% Copyright (c) 2013
%% Basho Technologies, Inc. <dev@basho.com>
%
%% Copyright (c) 2013
%% Sean Cribbs
%%   https://github.com/seancribbs/epb
%%
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use,
%% copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following
%% conditions:
%%
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.
%%
%% @doc Lexical analysis for Protocol Buffers definitions
%% Field types
-define(TYPE, ["map", "set", "register", "counter"]).

%% Other keywords
-define(KEYWORD, ["keys", "values", "count", "type"]).

-export([file/1, main/1]).

%% Flip through the reserved words and create tokens of the proper type.
select_id_type(T, Line) ->
    select_id_type(T, Line, [{type, ?TYPE},
                             {keyword, ?KEYWORD}]).

%% When none of the keywords match, it's a regular identifier
select_id_type(T, Line, []) ->
    {identifier, Line, T};
%% special-casing other keywords so they come out as terminals
select_id_type(T, Line, [{keyword, K}|Rest]) ->
    case lists:member(T, K) of
        true ->
            {list_to_atom(T), Line};
        false ->
            select_id_type(T, Line, Rest)
    end;
select_id_type(T, Line, [{NT, Toks}|Rest]) ->
    case lists:member(T, Toks) of
        true ->
            {NT, Line, list_to_atom(T)};
        false ->
            select_id_type(T, Line, Rest)
    end.

unquote(Str) ->
    %% Quote is at beginning and end of the string, strip them off.
    Stripped = lists:sublist(Str, 2, length(Str)-2),
    unescape(Stripped, []).

unescape([], Acc) ->
    lists:reverse(Acc);
unescape([$\\|Rest0], Acc) ->
    {Char, Rest} = unescape_char(Rest0),
    unescape(Rest, [Char|Acc]);
unescape([C|Rest], Acc) ->
    unescape(Rest, [C|Acc]).

unescape_char([$n|T]) -> {$\n, T};
unescape_char([$r|T]) -> {$\r, T};
unescape_char([$t|T]) -> {$\t, T};
unescape_char([$v|T]) -> {$\v, T};
unescape_char([$b|T]) -> {$\b, T};
unescape_char([$f|T]) -> {$\f, T};
unescape_char([$e|T]) -> {$\e, T};
unescape_char([$s|T]) -> {$\s, T};
unescape_char([$d|T]) -> {$\d, T};
unescape_char([C|T]) ->  {C, T}.



file(Filename) ->
    {ok, Bin} = file:read_file(Filename),
    string(unicode:characters_to_list(Bin)).

main([Filename]) ->
    io:format("~p~n", [file(Filename)]).

-file("/Users/dparfitt/erlang_R15B01/lib/erlang/lib/parsetools-2.0.7/include/leexinc.hrl", 14).

format_error({illegal,S}) -> ["illegal characters ",io_lib:write_string(S)];
format_error({user,S}) -> S.

string(String) -> string(String, 1).

string(String, Line) -> string(String, Line, String, []).

%% string(InChars, Line, TokenChars, Tokens) ->
%% {ok,Tokens,Line} | {error,ErrorInfo,Line}.
%% Note the line number going into yystate, L0, is line of token
%% start while line number returned is line of token end. We want line
%% of token start.

string([], L, [], Ts) ->                     % No partial tokens!
    {ok,yyrev(Ts),L};
string(Ics0, L0, Tcs, Ts) ->
    case yystate(yystate(), Ics0, L0, 0, reject, 0) of
        {A,Alen,Ics1,L1} ->                  % Accepting end state
            string_cont(Ics1, L1, yyaction(A, Alen, Tcs, L0), Ts);
        {A,Alen,Ics1,L1,_S1} ->              % Accepting transistion state
            string_cont(Ics1, L1, yyaction(A, Alen, Tcs, L0), Ts);
        {reject,_Alen,Tlen,_Ics1,L1,_S1} ->  % After a non-accepting state
            {error,{L0,?MODULE,{illegal,yypre(Tcs, Tlen+1)}},L1};
        {A,Alen,_Tlen,_Ics1,L1,_S1} ->
            string_cont(yysuf(Tcs, Alen), L1, yyaction(A, Alen, Tcs, L0), Ts)
    end.

%% string_cont(RestChars, Line, Token, Tokens)
%% Test for and remove the end token wrapper. Push back characters
%% are prepended to RestChars.

string_cont(Rest, Line, {token,T}, Ts) ->
    string(Rest, Line, Rest, [T|Ts]);
string_cont(Rest, Line, {token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    string(NewRest, Line, NewRest, [T|Ts]);
string_cont(Rest, Line, {end_token,T}, Ts) ->
    string(Rest, Line, Rest, [T|Ts]);
string_cont(Rest, Line, {end_token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    string(NewRest, Line, NewRest, [T|Ts]);
string_cont(Rest, Line, skip_token, Ts) ->
    string(Rest, Line, Rest, Ts);
string_cont(Rest, Line, {skip_token,Push}, Ts) ->
    NewRest = Push ++ Rest,
    string(NewRest, Line, NewRest, Ts);
string_cont(_Rest, Line, {error,S}, _Ts) ->
    {error,{Line,?MODULE,{user,S}},Line}.

%% token(Continuation, Chars) ->
%% token(Continuation, Chars, Line) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% Must be careful when re-entering to append the latest characters to the
%% after characters in an accept. The continuation is:
%% {token,State,CurrLine,TokenChars,TokenLen,TokenLine,AccAction,AccLen}

token(Cont, Chars) -> token(Cont, Chars, 1).

token([], Chars, Line) ->
    token(yystate(), Chars, Line, Chars, 0, Line, reject, 0);
token({token,State,Line,Tcs,Tlen,Tline,Action,Alen}, Chars, _) ->
    token(State, Chars, Line, Tcs ++ Chars, Tlen, Tline, Action, Alen).

%% token(State, InChars, Line, TokenChars, TokenLen, TokenLine,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% The argument order is chosen to be more efficient.

token(S0, Ics0, L0, Tcs, Tlen0, Tline, A0, Alen0) ->
    case yystate(S0, Ics0, L0, Tlen0, A0, Alen0) of
        %% Accepting end state, we have a token.
        {A1,Alen1,Ics1,L1} ->
            token_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline));
        %% Accepting transition state, can take more chars.
        {A1,Alen1,[],L1,S1} ->                  % Need more chars to check
            {more,{token,S1,L1,Tcs,Alen1,Tline,A1,Alen1}};
        {A1,Alen1,Ics1,L1,_S1} ->               % Take what we got
            token_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline));
        %% After a non-accepting state, maybe reach accept state later.
        {A1,Alen1,Tlen1,[],L1,S1} ->            % Need more chars to check
            {more,{token,S1,L1,Tcs,Tlen1,Tline,A1,Alen1}};
        {reject,_Alen1,Tlen1,eof,L1,_S1} ->     % No token match
            %% Check for partial token which is error.
            Ret = if Tlen1 > 0 -> {error,{Tline,?MODULE,
                                          %% Skip eof tail in Tcs.
                                          {illegal,yypre(Tcs, Tlen1)}},L1};
                     true -> {eof,L1}
                  end,
            {done,Ret,eof};
        {reject,_Alen1,Tlen1,Ics1,L1,_S1} ->    % No token match
            Error = {Tline,?MODULE,{illegal,yypre(Tcs, Tlen1+1)}},
            {done,{error,Error,L1},Ics1};
        {A1,Alen1,_Tlen1,_Ics1,L1,_S1} ->       % Use last accept match
            token_cont(yysuf(Tcs, Alen1), L1, yyaction(A1, Alen1, Tcs, Tline))
    end.

%% token_cont(RestChars, Line, Token)
%% If we have a token or error then return done, else if we have a
%% skip_token then continue.

token_cont(Rest, Line, {token,T}) ->
    {done,{ok,T,Line},Rest};
token_cont(Rest, Line, {token,T,Push}) ->
    NewRest = Push ++ Rest,
    {done,{ok,T,Line},NewRest};
token_cont(Rest, Line, {end_token,T}) ->
    {done,{ok,T,Line},Rest};
token_cont(Rest, Line, {end_token,T,Push}) ->
    NewRest = Push ++ Rest,
    {done,{ok,T,Line},NewRest};
token_cont(Rest, Line, skip_token) ->
    token(yystate(), Rest, Line, Rest, 0, Line, reject, 0);
token_cont(Rest, Line, {skip_token,Push}) ->
    NewRest = Push ++ Rest,
    token(yystate(), NewRest, Line, NewRest, 0, Line, reject, 0);
token_cont(Rest, Line, {error,S}) ->
    {done,{error,{Line,?MODULE,{user,S}},Line},Rest}.

%% tokens(Continuation, Chars, Line) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% Must be careful when re-entering to append the latest characters to the
%% after characters in an accept. The continuation is:
%% {tokens,State,CurrLine,TokenChars,TokenLen,TokenLine,Tokens,AccAction,AccLen}
%% {skip_tokens,State,CurrLine,TokenChars,TokenLen,TokenLine,Error,AccAction,AccLen}

tokens(Cont, Chars) -> tokens(Cont, Chars, 1).

tokens([], Chars, Line) ->
    tokens(yystate(), Chars, Line, Chars, 0, Line, [], reject, 0);
tokens({tokens,State,Line,Tcs,Tlen,Tline,Ts,Action,Alen}, Chars, _) ->
    tokens(State, Chars, Line, Tcs ++ Chars, Tlen, Tline, Ts, Action, Alen);
tokens({skip_tokens,State,Line,Tcs,Tlen,Tline,Error,Action,Alen}, Chars, _) ->
    skip_tokens(State, Chars, Line, Tcs ++ Chars, Tlen, Tline, Error, Action, Alen).

%% tokens(State, InChars, Line, TokenChars, TokenLen, TokenLine, Tokens,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.

tokens(S0, Ics0, L0, Tcs, Tlen0, Tline, Ts, A0, Alen0) ->
    case yystate(S0, Ics0, L0, Tlen0, A0, Alen0) of
        %% Accepting end state, we have a token.
        {A1,Alen1,Ics1,L1} ->
            tokens_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Ts);
        %% Accepting transition state, can take more chars.
        {A1,Alen1,[],L1,S1} ->                  % Need more chars to check
            {more,{tokens,S1,L1,Tcs,Alen1,Tline,Ts,A1,Alen1}};
        {A1,Alen1,Ics1,L1,_S1} ->               % Take what we got
            tokens_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Ts);
        %% After a non-accepting state, maybe reach accept state later.
        {A1,Alen1,Tlen1,[],L1,S1} ->            % Need more chars to check
            {more,{tokens,S1,L1,Tcs,Tlen1,Tline,Ts,A1,Alen1}};
        {reject,_Alen1,Tlen1,eof,L1,_S1} ->     % No token match
            %% Check for partial token which is error, no need to skip here.
            Ret = if Tlen1 > 0 -> {error,{Tline,?MODULE,
                                          %% Skip eof tail in Tcs.
                                          {illegal,yypre(Tcs, Tlen1)}},L1};
                     Ts == [] -> {eof,L1};
                     true -> {ok,yyrev(Ts),L1}
                  end,
            {done,Ret,eof};
        {reject,_Alen1,Tlen1,_Ics1,L1,_S1} ->
            %% Skip rest of tokens.
            Error = {L1,?MODULE,{illegal,yypre(Tcs, Tlen1+1)}},
            skip_tokens(yysuf(Tcs, Tlen1+1), L1, Error);
        {A1,Alen1,_Tlen1,_Ics1,L1,_S1} ->
            Token = yyaction(A1, Alen1, Tcs, Tline),
            tokens_cont(yysuf(Tcs, Alen1), L1, Token, Ts)
    end.

%% tokens_cont(RestChars, Line, Token, Tokens)
%% If we have an end_token or error then return done, else if we have
%% a token then save it and continue, else if we have a skip_token
%% just continue.

tokens_cont(Rest, Line, {token,T}, Ts) ->
    tokens(yystate(), Rest, Line, Rest, 0, Line, [T|Ts], reject, 0);
tokens_cont(Rest, Line, {token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    tokens(yystate(), NewRest, Line, NewRest, 0, Line, [T|Ts], reject, 0);
tokens_cont(Rest, Line, {end_token,T}, Ts) ->
    {done,{ok,yyrev(Ts, [T]),Line},Rest};
tokens_cont(Rest, Line, {end_token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    {done,{ok,yyrev(Ts, [T]),Line},NewRest};
tokens_cont(Rest, Line, skip_token, Ts) ->
    tokens(yystate(), Rest, Line, Rest, 0, Line, Ts, reject, 0);
tokens_cont(Rest, Line, {skip_token,Push}, Ts) ->
    NewRest = Push ++ Rest,
    tokens(yystate(), NewRest, Line, NewRest, 0, Line, Ts, reject, 0);
tokens_cont(Rest, Line, {error,S}, _Ts) ->
    skip_tokens(Rest, Line, {Line,?MODULE,{user,S}}).

%%skip_tokens(InChars, Line, Error) -> {done,{error,Error,Line},Ics}.
%% Skip tokens until an end token, junk everything and return the error.

skip_tokens(Ics, Line, Error) ->
    skip_tokens(yystate(), Ics, Line, Ics, 0, Line, Error, reject, 0).

%% skip_tokens(State, InChars, Line, TokenChars, TokenLen, TokenLine, Tokens,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.

skip_tokens(S0, Ics0, L0, Tcs, Tlen0, Tline, Error, A0, Alen0) ->
    case yystate(S0, Ics0, L0, Tlen0, A0, Alen0) of
        {A1,Alen1,Ics1,L1} ->                  % Accepting end state
            skip_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Error);
        {A1,Alen1,[],L1,S1} ->                 % After an accepting state
            {more,{skip_tokens,S1,L1,Tcs,Alen1,Tline,Error,A1,Alen1}};
        {A1,Alen1,Ics1,L1,_S1} ->
            skip_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Error);
        {A1,Alen1,Tlen1,[],L1,S1} ->           % After a non-accepting state
            {more,{skip_tokens,S1,L1,Tcs,Tlen1,Tline,Error,A1,Alen1}};
        {reject,_Alen1,_Tlen1,eof,L1,_S1} ->
            {done,{error,Error,L1},eof};
        {reject,_Alen1,Tlen1,_Ics1,L1,_S1} ->
            skip_tokens(yysuf(Tcs, Tlen1+1), L1, Error);
        {A1,Alen1,_Tlen1,_Ics1,L1,_S1} ->
            Token = yyaction(A1, Alen1, Tcs, Tline),
            skip_cont(yysuf(Tcs, Alen1), L1, Token, Error)
    end.

%% skip_cont(RestChars, Line, Token, Error)
%% Skip tokens until we have an end_token or error then return done
%% with the original rror.

skip_cont(Rest, Line, {token,_T}, Error) ->
    skip_tokens(yystate(), Rest, Line, Rest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {token,_T,Push}, Error) ->
    NewRest = Push ++ Rest,
    skip_tokens(yystate(), NewRest, Line, NewRest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {end_token,_T}, Error) ->
    {done,{error,Error,Line},Rest};
skip_cont(Rest, Line, {end_token,_T,Push}, Error) ->
    NewRest = Push ++ Rest,
    {done,{error,Error,Line},NewRest};
skip_cont(Rest, Line, skip_token, Error) ->
    skip_tokens(yystate(), Rest, Line, Rest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {skip_token,Push}, Error) ->
    NewRest = Push ++ Rest,
    skip_tokens(yystate(), NewRest, Line, NewRest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {error,_S}, Error) ->
    skip_tokens(yystate(), Rest, Line, Rest, 0, Line, Error, reject, 0).

yyrev(List) -> lists:reverse(List).
yyrev(List, Tail) -> lists:reverse(List, Tail).
yypre(List, N) -> lists:sublist(List, N).
yysuf(List, N) -> lists:nthtail(N, List).

%% yystate() -> InitialState.
%% yystate(State, InChars, Line, CurrTokLen, AcceptAction, AcceptLen) ->
%% {Action, AcceptLen, RestChars, Line} |
%% {Action, AcceptLen, RestChars, Line, State} |
%% {reject, AcceptLen, CurrTokLen, RestChars, Line, State} |
%% {Action, AcceptLen, CurrTokLen, RestChars, Line, State}.
%% Generated state transition functions. The non-accepting end state
%% return signal either an unrecognised character or end of current
%% input.

-file("src/riak_cql_scanner.erl", 369).
yystate() -> 21.

yystate(24, [92|Ics], Line, Tlen, _, _) ->
    yystate(22, Ics, Line, Tlen+1, 7, Tlen);
yystate(24, [39|Ics], Line, Tlen, _, _) ->
    yystate(20, Ics, Line, Tlen+1, 7, Tlen);
yystate(24, [10|Ics], Line, Tlen, _, _) ->
    yystate(16, Ics, Line+1, Tlen+1, 7, Tlen);
yystate(24, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(16, Ics, Line, Tlen+1, 7, Tlen);
yystate(24, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 38 ->
    yystate(16, Ics, Line, Tlen+1, 7, Tlen);
yystate(24, [C|Ics], Line, Tlen, _, _) when C >= 40, C =< 91 ->
    yystate(16, Ics, Line, Tlen+1, 7, Tlen);
yystate(24, [C|Ics], Line, Tlen, _, _) when C >= 93 ->
    yystate(16, Ics, Line, Tlen+1, 7, Tlen);
yystate(24, Ics, Line, Tlen, _, _) ->
    {7,Tlen,Ics,Line,24};
yystate(23, [10|Ics], Line, Tlen, _, _) ->
    yystate(23, Ics, Line+1, Tlen+1, 0, Tlen);
yystate(23, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(23, Ics, Line, Tlen+1, 0, Tlen);
yystate(23, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 25 ->
    yystate(23, Ics, Line, Tlen+1, 0, Tlen);
yystate(23, Ics, Line, Tlen, _, _) ->
    {0,Tlen,Ics,Line,23};
yystate(22, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(22, Ics, Line, Tlen+1, Action, Alen);
yystate(22, [39|Ics], Line, Tlen, Action, Alen) ->
    yystate(24, Ics, Line, Tlen+1, Action, Alen);
yystate(22, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(16, Ics, Line+1, Tlen+1, Action, Alen);
yystate(22, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(22, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 38 ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(22, [C|Ics], Line, Tlen, Action, Alen) when C >= 40, C =< 91 ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(22, [C|Ics], Line, Tlen, Action, Alen) when C >= 93 ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(22, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,22};
yystate(21, [125|Ics], Line, Tlen, Action, Alen) ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [123|Ics], Line, Tlen, Action, Alen) ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [95|Ics], Line, Tlen, Action, Alen) ->
    yystate(17, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [48|Ics], Line, Tlen, Action, Alen) ->
    yystate(9, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [47|Ics], Line, Tlen, Action, Alen) ->
    yystate(5, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [46|Ics], Line, Tlen, Action, Alen) ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [45|Ics], Line, Tlen, Action, Alen) ->
    yystate(18, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [44|Ics], Line, Tlen, Action, Alen) ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [43|Ics], Line, Tlen, Action, Alen) ->
    yystate(18, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [42|Ics], Line, Tlen, Action, Alen) ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [39|Ics], Line, Tlen, Action, Alen) ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [36|Ics], Line, Tlen, Action, Alen) ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [35|Ics], Line, Tlen, Action, Alen) ->
    yystate(4, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [34|Ics], Line, Tlen, Action, Alen) ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [32|Ics], Line, Tlen, Action, Alen) ->
    yystate(15, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [9|Ics], Line, Tlen, Action, Alen) ->
    yystate(19, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(19, Ics, Line+1, Tlen+1, Action, Alen);
yystate(21, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 8 ->
    yystate(23, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 13 ->
    yystate(19, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [C|Ics], Line, Tlen, Action, Alen) when C >= 14, C =< 25 ->
    yystate(23, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [C|Ics], Line, Tlen, Action, Alen) when C >= 49, C =< 57 ->
    yystate(13, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [C|Ics], Line, Tlen, Action, Alen) when C >= 58, C =< 63 ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [C|Ics], Line, Tlen, Action, Alen) when C >= 65, C =< 90 ->
    yystate(17, Ics, Line, Tlen+1, Action, Alen);
yystate(21, [C|Ics], Line, Tlen, Action, Alen) when C >= 97, C =< 122 ->
    yystate(17, Ics, Line, Tlen+1, Action, Alen);
yystate(21, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,21};
yystate(20, Ics, Line, Tlen, _, _) ->
    {7,Tlen,Ics,Line};
yystate(19, [32|Ics], Line, Tlen, _, _) ->
    yystate(15, Ics, Line, Tlen+1, 0, Tlen);
yystate(19, [9|Ics], Line, Tlen, _, _) ->
    yystate(19, Ics, Line, Tlen+1, 0, Tlen);
yystate(19, [10|Ics], Line, Tlen, _, _) ->
    yystate(19, Ics, Line+1, Tlen+1, 0, Tlen);
yystate(19, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 8 ->
    yystate(23, Ics, Line, Tlen+1, 0, Tlen);
yystate(19, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 13 ->
    yystate(19, Ics, Line, Tlen+1, 0, Tlen);
yystate(19, [C|Ics], Line, Tlen, _, _) when C >= 14, C =< 25 ->
    yystate(23, Ics, Line, Tlen+1, 0, Tlen);
yystate(19, Ics, Line, Tlen, _, _) ->
    {0,Tlen,Ics,Line,19};
yystate(18, [C|Ics], Line, Tlen, _, _) when C >= 49, C =< 57 ->
    yystate(13, Ics, Line, Tlen+1, 9, Tlen);
yystate(18, Ics, Line, Tlen, _, _) ->
    {9,Tlen,Ics,Line,18};
yystate(17, [95|Ics], Line, Tlen, _, _) ->
    yystate(17, Ics, Line, Tlen+1, 5, Tlen);
yystate(17, [C|Ics], Line, Tlen, _, _) when C >= 48, C =< 57 ->
    yystate(17, Ics, Line, Tlen+1, 5, Tlen);
yystate(17, [C|Ics], Line, Tlen, _, _) when C >= 65, C =< 90 ->
    yystate(17, Ics, Line, Tlen+1, 5, Tlen);
yystate(17, [C|Ics], Line, Tlen, _, _) when C >= 97, C =< 122 ->
    yystate(17, Ics, Line, Tlen+1, 5, Tlen);
yystate(17, Ics, Line, Tlen, _, _) ->
    {5,Tlen,Ics,Line,17};
yystate(16, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(22, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [39|Ics], Line, Tlen, Action, Alen) ->
    yystate(20, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(16, Ics, Line+1, Tlen+1, Action, Alen);
yystate(16, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 38 ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [C|Ics], Line, Tlen, Action, Alen) when C >= 40, C =< 91 ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [C|Ics], Line, Tlen, Action, Alen) when C >= 93 ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(16, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,16};
yystate(15, [32|Ics], Line, Tlen, _, _) ->
    yystate(15, Ics, Line, Tlen+1, 1, Tlen);
yystate(15, [9|Ics], Line, Tlen, _, _) ->
    yystate(15, Ics, Line, Tlen+1, 1, Tlen);
yystate(15, [10|Ics], Line, Tlen, _, _) ->
    yystate(15, Ics, Line+1, Tlen+1, 1, Tlen);
yystate(15, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 13 ->
    yystate(15, Ics, Line, Tlen+1, 1, Tlen);
yystate(15, Ics, Line, Tlen, _, _) ->
    {1,Tlen,Ics,Line,15};
yystate(14, Ics, Line, Tlen, _, _) ->
    {4,Tlen,Ics,Line};
yystate(13, [C|Ics], Line, Tlen, _, _) when C >= 48, C =< 57 ->
    yystate(13, Ics, Line, Tlen+1, 8, Tlen);
yystate(13, Ics, Line, Tlen, _, _) ->
    {8,Tlen,Ics,Line,13};
yystate(12, Ics, Line, Tlen, _, _) ->
    {9,Tlen,Ics,Line};
yystate(11, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(0, Ics, Line, Tlen+1, Action, Alen);
yystate(11, [34|Ics], Line, Tlen, Action, Alen) ->
    yystate(7, Ics, Line, Tlen+1, Action, Alen);
yystate(11, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(11, Ics, Line+1, Tlen+1, Action, Alen);
yystate(11, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(11, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 33 ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(11, [C|Ics], Line, Tlen, Action, Alen) when C >= 35, C =< 91 ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(11, [C|Ics], Line, Tlen, Action, Alen) when C >= 93 ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(11, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,11};
yystate(10, [47|Ics], Line, Tlen, Action, Alen) ->
    yystate(14, Ics, Line, Tlen+1, Action, Alen);
yystate(10, [42|Ics], Line, Tlen, Action, Alen) ->
    yystate(10, Ics, Line, Tlen+1, Action, Alen);
yystate(10, [13|Ics], Line, Tlen, Action, Alen) ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(10, [11|Ics], Line, Tlen, Action, Alen) ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(10, [12|Ics], Line, Tlen, Action, Alen) ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(10, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(6, Ics, Line+1, Tlen+1, Action, Alen);
yystate(10, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(10, [C|Ics], Line, Tlen, Action, Alen) when C >= 14, C =< 41 ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(10, [C|Ics], Line, Tlen, Action, Alen) when C >= 43, C =< 46 ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(10, [C|Ics], Line, Tlen, Action, Alen) when C >= 48 ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(10, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,10};
yystate(9, Ics, Line, Tlen, _, _) ->
    {8,Tlen,Ics,Line};
yystate(8, [13|Ics], Line, Tlen, _, _) ->
    yystate(8, Ics, Line, Tlen+1, 2, Tlen);
yystate(8, [10|Ics], Line, Tlen, _, _) ->
    yystate(8, Ics, Line+1, Tlen+1, 2, Tlen);
yystate(8, Ics, Line, Tlen, _, _) ->
    {2,Tlen,Ics,Line,8};
yystate(7, Ics, Line, Tlen, _, _) ->
    {6,Tlen,Ics,Line};
yystate(6, [42|Ics], Line, Tlen, Action, Alen) ->
    yystate(10, Ics, Line, Tlen+1, Action, Alen);
yystate(6, [13|Ics], Line, Tlen, Action, Alen) ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(6, [11|Ics], Line, Tlen, Action, Alen) ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(6, [12|Ics], Line, Tlen, Action, Alen) ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(6, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(6, Ics, Line+1, Tlen+1, Action, Alen);
yystate(6, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(6, [C|Ics], Line, Tlen, Action, Alen) when C >= 14, C =< 41 ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(6, [C|Ics], Line, Tlen, Action, Alen) when C >= 43 ->
    yystate(6, Ics, Line, Tlen+1, Action, Alen);
yystate(6, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,6};
yystate(5, [47|Ics], Line, Tlen, _, _) ->
    yystate(1, Ics, Line, Tlen+1, 9, Tlen);
yystate(5, [42|Ics], Line, Tlen, _, _) ->
    yystate(6, Ics, Line, Tlen+1, 9, Tlen);
yystate(5, Ics, Line, Tlen, _, _) ->
    {9,Tlen,Ics,Line,5};
yystate(4, [13|Ics], Line, Tlen, _, _) ->
    yystate(4, Ics, Line, Tlen+1, 2, Tlen);
yystate(4, [11|Ics], Line, Tlen, _, _) ->
    yystate(4, Ics, Line, Tlen+1, 2, Tlen);
yystate(4, [12|Ics], Line, Tlen, _, _) ->
    yystate(4, Ics, Line, Tlen+1, 2, Tlen);
yystate(4, [10|Ics], Line, Tlen, _, _) ->
    yystate(8, Ics, Line+1, Tlen+1, 2, Tlen);
yystate(4, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(4, Ics, Line, Tlen+1, 2, Tlen);
yystate(4, [C|Ics], Line, Tlen, _, _) when C >= 14 ->
    yystate(4, Ics, Line, Tlen+1, 2, Tlen);
yystate(4, Ics, Line, Tlen, _, _) ->
    {2,Tlen,Ics,Line,4};
yystate(3, [92|Ics], Line, Tlen, _, _) ->
    yystate(0, Ics, Line, Tlen+1, 6, Tlen);
yystate(3, [34|Ics], Line, Tlen, _, _) ->
    yystate(7, Ics, Line, Tlen+1, 6, Tlen);
yystate(3, [10|Ics], Line, Tlen, _, _) ->
    yystate(11, Ics, Line+1, Tlen+1, 6, Tlen);
yystate(3, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(11, Ics, Line, Tlen+1, 6, Tlen);
yystate(3, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 33 ->
    yystate(11, Ics, Line, Tlen+1, 6, Tlen);
yystate(3, [C|Ics], Line, Tlen, _, _) when C >= 35, C =< 91 ->
    yystate(11, Ics, Line, Tlen+1, 6, Tlen);
yystate(3, [C|Ics], Line, Tlen, _, _) when C >= 93 ->
    yystate(11, Ics, Line, Tlen+1, 6, Tlen);
yystate(3, Ics, Line, Tlen, _, _) ->
    {6,Tlen,Ics,Line,3};
yystate(2, [13|Ics], Line, Tlen, _, _) ->
    yystate(2, Ics, Line, Tlen+1, 3, Tlen);
yystate(2, [10|Ics], Line, Tlen, _, _) ->
    yystate(2, Ics, Line+1, Tlen+1, 3, Tlen);
yystate(2, Ics, Line, Tlen, _, _) ->
    {3,Tlen,Ics,Line,2};
yystate(1, [13|Ics], Line, Tlen, _, _) ->
    yystate(1, Ics, Line, Tlen+1, 3, Tlen);
yystate(1, [11|Ics], Line, Tlen, _, _) ->
    yystate(1, Ics, Line, Tlen+1, 3, Tlen);
yystate(1, [12|Ics], Line, Tlen, _, _) ->
    yystate(1, Ics, Line, Tlen+1, 3, Tlen);
yystate(1, [10|Ics], Line, Tlen, _, _) ->
    yystate(2, Ics, Line+1, Tlen+1, 3, Tlen);
yystate(1, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(1, Ics, Line, Tlen+1, 3, Tlen);
yystate(1, [C|Ics], Line, Tlen, _, _) when C >= 14 ->
    yystate(1, Ics, Line, Tlen+1, 3, Tlen);
yystate(1, Ics, Line, Tlen, _, _) ->
    {3,Tlen,Ics,Line,1};
yystate(0, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(0, Ics, Line, Tlen+1, Action, Alen);
yystate(0, [34|Ics], Line, Tlen, Action, Alen) ->
    yystate(3, Ics, Line, Tlen+1, Action, Alen);
yystate(0, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(11, Ics, Line+1, Tlen+1, Action, Alen);
yystate(0, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(0, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 33 ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(0, [C|Ics], Line, Tlen, Action, Alen) when C >= 35, C =< 91 ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(0, [C|Ics], Line, Tlen, Action, Alen) when C >= 93 ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(0, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,0};
yystate(S, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,S}.

%% yyaction(Action, TokenLength, TokenChars, TokenLine) ->
%% {token,Token} | {end_token, Token} | skip_token | {error,String}.
%% Generated action function.

yyaction(0, _, _, _) ->
    yyaction_0();
yyaction(1, _, _, _) ->
    yyaction_1();
yyaction(2, _, _, _) ->
    yyaction_2();
yyaction(3, _, _, _) ->
    yyaction_3();
yyaction(4, _, _, _) ->
    yyaction_4();
yyaction(5, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_5(TokenChars, TokenLine);
yyaction(6, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_6(TokenChars, TokenLine);
yyaction(7, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_7(TokenChars, TokenLine);
yyaction(8, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_8(TokenChars, TokenLine);
yyaction(9, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_9(TokenChars, TokenLine);
yyaction(_, _, _, _) -> error.

-compile({inline,yyaction_0/0}).
-file("src/riak_cql_scanner.xrl", 41).
yyaction_0() ->
     skip_token .

-compile({inline,yyaction_1/0}).
-file("src/riak_cql_scanner.xrl", 42).
yyaction_1() ->
     skip_token .

-compile({inline,yyaction_2/0}).
-file("src/riak_cql_scanner.xrl", 43).
yyaction_2() ->
     skip_token .

-compile({inline,yyaction_3/0}).
-file("src/riak_cql_scanner.xrl", 44).
yyaction_3() ->
     skip_token .

-compile({inline,yyaction_4/0}).
-file("src/riak_cql_scanner.xrl", 45).
yyaction_4() ->
     skip_token .

-compile({inline,yyaction_5/2}).
-file("src/riak_cql_scanner.xrl", 46).
yyaction_5(TokenChars, TokenLine) ->
     { token, select_id_type (TokenChars, TokenLine) } .

-compile({inline,yyaction_6/2}).
-file("src/riak_cql_scanner.xrl", 47).
yyaction_6(TokenChars, TokenLine) ->
     { token, { string, TokenLine, unquote (TokenChars) } } .

-compile({inline,yyaction_7/2}).
-file("src/riak_cql_scanner.xrl", 48).
yyaction_7(TokenChars, TokenLine) ->
     { token, { string, TokenLine, unquote (TokenChars) } } .

-compile({inline,yyaction_8/2}).
-file("src/riak_cql_scanner.xrl", 49).
yyaction_8(TokenChars, TokenLine) ->
     { token, { integer, TokenLine, list_to_integer (TokenChars) } } .

-compile({inline,yyaction_9/2}).
-file("src/riak_cql_scanner.xrl", 50).
yyaction_9(TokenChars, TokenLine) ->
     { token, { list_to_atom (TokenChars), TokenLine } } .

-file("/Users/dparfitt/erlang_R15B01/lib/erlang/lib/parsetools-2.0.7/include/leexinc.hrl", 282).
