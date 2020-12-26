% Include the knowledge base in the file.
:- include('KB.pl').

%==============================================
% GRID DIMENSIONS
grid_dimensions(Height, Width):-
  % Get member locations
  members_loc(M),
  % Get ethan's initial location
  ethan_loc(EY, EX),
  % Get the submarine location
  submarine(SY, SX), 
  % Combine all locations into one list
  Locations = [[EY, EX], [SY, SX]|M], 
  % Get the maximum Y and maximum X positions from the helper
  grid_dimensions_helper(Locations, Height, Width). 

% GRID DIMENSIONS HELPER
grid_dimensions_helper([[Y, X]], Y, X). % Base case: The maximum of one element is itself
grid_dimensions_helper([[Y, X] | T], MaxY, MaxX):-
  % Get the maximum of the remaining elements
  grid_dimensions_helper(T, NextMaxY, NextMaxX),
  % Assign the max y as the max y of the maximum of remaining and the current y
  MaxY is max(Y, NextMaxY),
  % Assign the max x as the max x of the maximum of remaining and the current x
  MaxX is max(X, NextMaxX).

%==============================================
% ON GRID
on_grid(Y, X):-
  % Get grid dimensions
  grid_dimensions(Height, Width),
  % Check if Y, X are within 0 and the grid dimensions
  between(0, Height, Y),
  between(0, Width, X).

%==============================================
% IN
% Base case: Y is in a list of one element if that element is Y
in(Y, [Y|_]).
in(Y, [X|T]):-
  % Check if Y is in T
  in(Y, T),
  % Y is not the first element (to avoid unnecessary searches)
  Y \= X.

%==============================================
% AGENT AT AYIOMS
% Checks if an agent exists at Y, X
agent_at(Y, X):-
  % Get the list of all members M
  members_loc(M),
  % Check if [Y, X] exists in M
  in([Y, X], M).

%==============================================
% FLUENT
% Base case: at the initial state ethan's position is the same as the initial position,
% no members were carried, the capacity is max and the state is s0.
fluent(Y, X, [], C, s0):- ethan_loc(Y, X), capacity(C). 

% The state is the result of a left action on a State
fluent(Y, X, L, C, result(left, State)):-
  % Calculating the previous X location
  XOld is X + 1,
  % Checking if the previous X location is on the grid (along with the Y)
  on_grid(Y, XOld),
  % Searching for the previous state
  fluent(Y, XOld, L, C, State).

% The state is the result of a right action
fluent(Y, X, L, C, result(right, State)):-
  % Calculating the previous X location
  XOld is X - 1,
  % Checking if the previous X location is on the grid (along with the Y)
  on_grid(Y, XOld),
  % Searching for the previous state
  fluent(Y, XOld, L, C, State).

% The state is the result of a down action
fluent(Y, X, L, C, result(down, State)):-
  % Calculating the previous Y location
  YOld is Y - 1,
  % Checking if the previous Y location is on the grid (along with the X)
  on_grid(YOld, X),
  % Searching for the previous state
  fluent(YOld, X, L, C, State).

% The state is the result of a up action
fluent(Y, X, L, C, result(up, State)):-
  % Calculating the previous Y location
  YOld is Y + 1,
  % Checking if the previous Y location is on the grid (along with the X)
  on_grid(YOld, X),
  % Searching for the previous state
  fluent(YOld, X, L, C, State).

% The state is the result of a carry action
fluent(Y, X, [[Y, X]|L], C, result(carry, State)):-
  % Check if there is an agent at the current position
  agent_at(Y, X),
  % Check if the agent was not previously carried
  \+ in([Y, X], L),
  % Get the maximum capacity Cap
  capacity(Cap),
  % Calculate the previous capacity
  between(0, Cap, COld),
  COld is C + 1,
  % Make sure the current capacity is between the maximum and Cap - 1
  % Searching for the previous state.
  fluent(Y, X, L, COld, State).

% The state is the result of a drop action
fluent(Y, X, L, Cap, result(drop, State)):-
  % Check if the submarine is at the same location
  submarine(Y, X),
  % Check if the current capacity is the maximum capacity
  capacity(Cap),
  % Get the length of the previously dropped members
  length(L, Length),
  % Calculate the minimum possible carrying capacity
  Min is max(0, Cap - Length),
  % Make sure the old capacity COld is between min and max
  between(Min, Cap, COld),
  % Search for the previous state
  fluent(Y, X, L, COld, State).


%==============================================
%==============================================
% DRIVER CODE

%==============================================
% SOLVE
% Defines the requirements of a goal state S
solve(S):-
  % Get the maximum capacity C
  capacity(C),
  % Get the submarine position EthY, EthX
  submarine(EthY, EthX),
  % Get the list of members
  members_loc(L),
  % Generate permutations of the list of members LPermutaion
  permutation(L, LPermutation),
  % Search for a state where:
  % Ethan's location is the same as the submarine,
  % The list of previously carried members is a permuation of the list of all members, and
  % The carrying capacity is the same as the maximum capacity
  fluent(EthY, EthX, LPermutation, C, S).

%==============================================
% GOAL
% Check goal using IDS
goal(S):- ids(S, 0).
goal(S, M):- ids(S, 0, M). % Check goal with max depth

%==============================================
% IDS
ids(S, D):-
  (
    % Search for a solution at the current depth
    call_with_depth_limit(solve(S), D, R),
    % Check if the result depth is not "depth limit exceeded" (meaning a solution was found)
    R \= depth_limit_exceeded
  ); % Otherwise
  (
    % Calculate the next depth
    D1 is D + 1,
    % Search for a solution at the next depth
    ids(S, D1)
  ).

% IDS with max depth
ids(S, D, M):-
  (
    % Search for a solution at the current depth
    call_with_depth_limit(solve(S), D, R),
    % Check if the result depth is not "depth limit exceeded" (meaning a solution was found)
    R \= depth_limit_exceeded
  ); % Otherwise
  (
    D < M,
    % Calculate the next depth
    D1 is D + 1,
    % Search for a solution at the next depth
    ids(S, D1, M)
  ).